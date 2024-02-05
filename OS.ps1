#  OS
#  by ImKKingshuk
#  Git-  https://github.com/ImKKingshuk/ClassifyX.git
#  Copyright © 2024 , @ImKKingshuk | All Rights Reserved.
#  GNU General Public License v3.0 or later


Clear-Host

function Get-FormattedCimInstance {
    param (
        [string]$ClassName,
        [hashtable]$Properties
    )

    try {
        $cimInstance = Get-CimInstance -ClassName $ClassName
        $formattedData = $cimInstance | Select-Object -Property $Properties | Format-Table | Out-String
        Write-Output $formattedData.Trim()
    } catch {
        Write-Host "Error retrieving information from $ClassName: $_"
    }
}

function Get-FormattedHotFix {
    try {
        $formattedHotFix = Get-HotFix | Select-Object -Property HotFixID, InstalledOn -Unique | Format-Table | Out-String
        Write-Output $formattedHotFix.Trim()
    } catch {
        Write-Host "Error retrieving HotFix information: $_"
    }
}

function Get-FormattedMappedDisks {
    try {
        $formattedMappedDisks = Get-SmbMapping | Select-Object -Property LocalPath, RemotePath | Format-Table | Out-String
        Write-Output $formattedMappedDisks.Trim()
    } catch {
        Write-Host "Error retrieving Mapped Disks information: $_"
    }
}

function Get-FormattedPrinters {
    try {
        $formattedPrinters = Get-CimInstance -ClassName CIM_Printer | Select-Object -Property Name, Default, PortName, DriverName, ShareName | Format-Table | Out-String
        Write-Output $formattedPrinters.Trim()
    } catch {
        Write-Host "Error retrieving Printers information: $_"
    }
}

function Get-FormattedLogicalDrives {
    try {
        $formattedLogicalDrives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -ne 4 } | Select-Object -Property DeviceID, @{Name = 'DriveType'; Expression = { [System.Enum]::GetName([DriveType], $_.DriveType) } }, @{Name = 'Size, GB'; Expression = { [math]::Round($_.Size / 1GB, 2) } }, @{Name = 'FreeSpace, GB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } } | Format-Table | Out-String
        Write-Output $formattedLogicalDrives.Trim()
    } catch {
        Write-Host "Error retrieving Logical Drives information: $_"
    }
}

function Get-FormattedNetwork {
    try {
        $networkAdapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration
        Write-Output "`nDefault IP gateway"
        Write-Output $networkAdapterConfig.DefaultIPGateway

        Write-Output "`nDNS"
        Write-Output (Get-DnsClientServerAddress -Family IPv4).ServerAddresses
    } catch {
        Write-Host "Error retrieving Network information: $_"
    }
}

function Get-FormattedMicrosoftDefenderThreats {
    try {
        enum ThreatStatusID {
            Unknown          = 0
            Detected         = 1
            Cleaned          = 2
            Quarantined      = 3
            Removed          = 4
            Allowed          = 5
            Blocked          = 6
            QuarantineFailed = 102
            RemoveFailed     = 103
            AllowFailed      = 104
            Abandoned        = 105
            BlockedFailed    = 107
        }

        $formattedDefenderThreats = Get-MpThreatDetection | ForEach-Object {
            [PSCustomObject] @{
                "Detected Threats Paths" = $_.Resources
                "ThreatID"             = $_.ThreatID
                "Status"               = [System.Enum]::GetName([ThreatStatusID], $_.ThreatStatusID)
                "Detection Time"       = $_.InitialDetectionTime
            }
        } | Sort-Object ThreatID -Unique | Format-Table -AutoSize -Wrap | Out-String
        Write-Output $formattedDefenderThreats.Trim()
    } catch {
        Write-Host "Error retrieving Microsoft Defender Threats information: $_"
    }
}

function Get-FormattedMicrosoftDefenderSettings {
    try {
        $formattedDefenderSettings = Get-MpPreference | ForEach-Object {
            [PSCustomObject] @{
                "Excluded IDs"                                  = $_.ThreatIDDefaultAction_Ids | Out-String
                "Excluded Process"                              = $_.ExclusionProcess | Out-String
                "Controlled Folder Access"                      = $_.EnableControlledFolderAccess | Out-String
                "Controlled Folder Access Protected Folders"    = $_.ControlledFolderAccessProtectedFolders | Out-String
                "Controlled Folder Access Allowed Applications" = $_.ControlledFolderAccessAllowedApplications | Out-String
                "Excluded Extensions"                           = $_.ExclusionExtension | Out-String
                "Excluded Paths"                                = $_.ExclusionPath | Out-String
            }
        } | Format-List | Out-String
        Write-Output $formattedDefenderSettings.Trim()
    } catch {
        Write-Host "Error retrieving Microsoft Defender Settings information: $_"
    }
}

try {
   
    Write-Output "User Information"

    $computerSystem = Get-CimInstance -ClassName CIM_ComputerSystem
    $localUser = Get-LocalUser

    $userInfo = [PSCustomObject]@{
        "Computer Name"    = $computerSystem.Name
        "Domain"           = $computerSystem.Domain
        "User Name"        = $computerSystem.UserName
        "Local Users"      = $localUser | Format-Table | Out-String
        "Group Membership" = If ($computerSystem.PartOfDomain) { Get-ADPrincipalGroupMembership $env:USERNAME | Select-Object -Property Name | Format-Table | Out-String }
    }

    $userInfo | Format-Table -AutoSize | Out-String | Write-Output

  
    Get-FormattedCimInstance -ClassName CIM_OperatingSystem -Properties @{
        Name       = "Product Name"
        Expression = {$_.Caption}
    }, @{
        Name       = "Install Date"
        Expression = {$_.InstallDate.ToString().Split("")[0]}
    }, @{
        Name       = "Architecture"
        Expression = {$_.OSArchitecture}
    }

    $currentVersion = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows nt\CurrentVersion" | Select-Object -Property @{
        Name       = "Build"
        Expression = {"$($_.CurrentMajorVersionNumber).$($_.CurrentMinorVersionNumber).$($_.CurrentBuild).$($_.UBR)"}
    }

    [PSCustomObject] @{
        "Product Name" = $operatingSystem."Product Name"
        "Install Date" = $operatingSystem."Install Date"
        Build          = $currentVersion.Build
        Architecture   = $operatingSystem.Architecture
    } | Out-String | Write-Output

   
    Write-Output "`nRegistered apps"
    (Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName | Sort-Object

   
    Write-Output "`nInstalled updates supplied by CBS"
    Get-FormattedHotFix

   
    Write-Output "`nLogical drives"
    Get-FormattedLogicalDrives

  
    Write-Output "`nMapped disks"
    Get-FormattedMappedDisks

   
    Write-Output "`nPrinters"
    Get-FormattedPrinters

   
    Get-FormattedNetwork

   
    Write-Output "`nMicrosoft Defender threats"
    Get-FormattedMicrosoftDefenderThreats

   
    Write-Output "`nMicrosoft Defender settings"
    Get-FormattedMicrosoftDefenderSettings

} catch {
    Write-Host "Error: $_"
}
