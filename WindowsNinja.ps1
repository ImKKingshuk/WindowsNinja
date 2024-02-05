#  WindowsNinja
#  by ImKKingshuk
#  Git- https://github.com/ImKKingshuk/WindowsNinja.git
#  Copyright © 2024 , @ImKKingshuk | All Rights Reserved.
#  GNU General Public License v3.0 or later


function Print-Banner {
    Clear-Host
    Write-Host "******************************************"
    Write-Host "*               WindowsNinja             *"
    Write-Host "*        Windows System Info Tool        *"
    Write-Host "*      ----------------------------      *"
    Write-Host "*                        by @ImKKingshuk *"
    Write-Host "* Github- https://github.com/ImKKingshuk *"
    Write-Host "******************************************"
    Write-Host
}

function Show-Menu {
    Print-Banner
    Write-Host "======= WindowsNinja ========"
    Write-Host "1. General System Information"
    Write-Host "2. Hardware Information"
    Write-Host "3. Exit"
    Write-Host "============================="
}

function Get-GeneralSystemInfo {
    Clear-Host
    .\OS.ps1
    .\PC.ps1
    Read-Host "Press Enter to return to the main menu"
}

function Get-HardwareInfo {
    Clear-Host
    .\PC.ps1
    Read-Host "Press Enter to return to the main menu"
}

while ($true) {
    Show-Menu

    $choice = Read-Host "Enter your choice (1, 2, or 3)"

    switch ($choice) {
        "1" { Get-GeneralSystemInfo }
        "2" { Get-HardwareInfo }
        "3" { break }
        default { Write-Host "Invalid choice. Please try again." }
    }
}
