#  PC
#  by ImKKingshuk
#  Git- https://github.com/ImKKingshuk/WindowsNinja.git
#  Copyright © 2024 , @ImKKingshuk | All Rights Reserved.
#  GNU General Public License v3.0 or later


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

function Get-FormattedPhysicalDisk {
    try {
        $formattedDisks = Get-PhysicalDisk | Select-Object -Property FriendlyName, MediaType, BusType, @{Name = 'Size, GB'; Expression = {[math]::Round($_.Size / 1GB, 2)}} | Format-Table | Out-String
        Write-Output $formattedDisks.Trim()
    } catch {
        Write-Host "Error retrieving Physical Disk information: $_"
    }
}

function Get-FormattedVideoControllers {
    try {
        
        $integratedGraphics = Get-CimInstance -ClassName CIM_VideoController | Where-Object {$_.AdapterDACType -eq "Internal"}

        if ($integratedGraphics) {
            $integratedGraphics | Select-Object -Property Caption, @{Name = 'VRAM, GB'; Expression = {[math]::Round($_.AdapterRAM / 1GB)}}
        }

       
        $qwMemorySize = (Get-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*" -Name HardwareInformation.qwMemorySize -ErrorAction SilentlyContinue)."HardwareInformation.qwMemorySize"

        if ($qwMemorySize) {
            $dedicatedGraphics = Get-CimInstance -ClassName CIM_VideoController | Where-Object {$_.AdapterDACType -ne "Internal"}

            foreach ($VRAM in $qwMemorySize) {
                $dedicatedGraphics | ForEach-Object {
                    [PSCustomObject] @{
                        Model      = $_.Caption
                        "VRAM, GB" = [math]::Round($VRAM / 1GB)
                    }
                }
            }
        }
    } catch {
        Write-Host "Error retrieving Video Controllers information: $_"
    }
}

Clear-Host


Write-Output "`nBIOS"
Get-FormattedCimInstance -ClassName CIM_BIOSElement -Properties @{
    Manufacturer = "Manufacturer"
    Version      = "Version"
}


Write-Output "`nMotherboard"
Get-FormattedCimInstance -ClassName Win32_BaseBoard -Properties @{
    Manufacturer = "Manufacturer"
    Product      = "Product"
}


Write-Output "`nSerial number"
(Get-CimInstance -ClassName Win32_BIOS).SerialNumber


Write-Output "`nCPU"
Get-FormattedCimInstance -ClassName CIM_Processor -Properties @{
    Name        = "Name"
    Cores       = "NumberOfCores"
    "L3, MB"    = {$_.L3CacheSize / 1024}
    Threads     = "NumberOfLogicalProcessors"
}


Write-Output "`nRAM"
Get-FormattedCimInstance -ClassName CIM_PhysicalMemory -Properties @{
    Manufacturer = "Manufacturer"
    PartNumber   = "PartNumber"
    "Speed, MHz" = "ConfiguredClockSpeed"
    "Capacity, GB" = {$_.Capacity / 1GB}
}


Write-Output "`nPhysical disks"
Get-FormattedPhysicalDisk


Write-Output "`nVideo controllers"
Get-FormattedVideoControllers
