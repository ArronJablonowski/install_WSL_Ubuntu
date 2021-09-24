<#
.Synopsis
    install_WSL_Ubuntu.ps1 - Script installs WSLv1 or WSLv2 & Ubuntu 
.EXAMPLE
        .\InstallWLS.ps1 -WSLv1
        Install WSL version 1
.EXAMPLE
        .\InstallWLS.ps1 -WSLv2
        Install WSL version 2  
        Requires virtualization is enabled for hyperV. 
        * HyperV (type 1 hypervisor/bare metal) does not agree with other virtualization software being installed (VMWare, VirtualBox, etc.)
.LINK
   
#>

#Install WSL Version Switches 
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
        [Switch]$WSLv1,
    [Parameter(Mandatory=$False)]
        [Switch]$WSLv2        
)


function isntall_Ubuntu_WSLv1(){
    #APPX Path
    $appxPath = "C:\Ubuntu\Ubuntu.appx"

    #Enable WSL 
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

    #Get Ubuntu 18  - #Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ~\Debian.zip -UseBasicParsing
    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ~\Ubuntu.appx -UseBasicParsing

    #make Ubuntu Dir 
    mkdir C:\Ubuntu\

    #Move the appx, 
    Move-Item ~\Ubuntu.appx $appxPath

    #add the appx package 
    Add-AppxPackage -Path $appxPath

    If(Test-Path -Path $appxPath){ #run ubuntu to complete install 
        #Call Ubuntu.appx
        & $appxPath
    }

}


function isntall_Ubuntu_WSLv2(){
    #enabling the Virtual Machine Platform 
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    #enabling WSL 
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

    #Set WSL version 2 as default 
    wsl --set-default-version 2    

    
    #Add (self cleaning) files to startup folder to finish WSL/Ubuntu install. 
    #-------------------------------------------------------------------------
        #batch file - to easily call powershell 
    $batchFile = "~\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\InstallUbuntuWSL.cmd"
    Add-Content -Path $batchFile -Value '@echo off '
    Add-Content -Path $batchFile -Value ''
    Add-Content -Path $batchFile -Value ':: BatchGotAdmin'
    Add-Content -Path $batchFile -Value ':-------------------------------------'
    Add-Content -Path $batchFile -Value 'REM  --> Check for permissions'
    Add-Content -Path $batchFile -Value "IF '%PROCESSOR_ARCHITECTURE%' EQU 'amd64' ("
    Add-Content -Path $batchFile -Value '   >nul 2>&1 "%SYSTEMROOT%\SysWOW64\icacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"'
    Add-Content -Path $batchFile -Value ' ) ELSE ('
    Add-Content -Path $batchFile -Value ''
    Add-Content -Path $batchFile -Value '   >nul 2>&1 "%SYSTEMROOT%\system32\icacls.exe" "%SYSTEMROOT%\system32\config\system"'
    Add-Content -Path $batchFile -Value ')'
    Add-Content -Path $batchFile -Value 'REM --> If error flag set, we do not have admin.'
    Add-Content -Path $batchFile -Value "if '%errorlevel%' NEQ '0' ("
    Add-Content -Path $batchFile -Value '  echo Requesting Administrative Privileges to Complete Install of WSL.'
    Add-Content -Path $batchFile -Value ''
    Add-Content -Path $batchFile -Value '   timeout 4'
    Add-Content -Path $batchFile -Value '  goto UACPrompt'
    Add-Content -Path $batchFile -Value ') else ( goto gotAdmin )'
    Add-Content -Path $batchFile -Value ''
    Add-Content -Path $batchFile -Value ':UACPrompt'
    Add-Content -Path $batchFile -Value '   echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"'
    Add-Content -Path $batchFile -Value '   set params = %*:"=""'
    Add-Content -Path $batchFile -Value '   echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"'
    Add-Content -Path $batchFile -Value ''
    Add-Content -Path $batchFile -Value '   "%temp%\getadmin.vbs"'
    Add-Content -Path $batchFile -Value '   del "%temp%\getadmin.vbs"'
    Add-Content -Path $batchFile -Value '   exit /B'
    Add-Content -Path $batchFile -Value ''
    Add-Content -Path $batchFile -Value ':gotAdmin'
    Add-Content -Path $batchFile -Value '   pushd "%CD%" '
    Add-Content -Path $batchFile -Value '   CD /D "%~dp0"'
    Add-Content -Path $batchFile -Value ':--------------------------------------'
    Add-Content -Path $batchFile -Value ''
    Add-Content -Path $batchFile -Value 'START powershell.exe -executionpolicy bypass -Command "~\APPDATA\Local\Temp\InstallUbuntuWSL.ps1 "'
        
        #powershell file that completes the isntall 
    $powershellFile = "~\AppData\Local\Temp\InstallUbuntuWSL.ps1"
    Add-Content -Path $powershellFile -Value 'wsl --install -d Ubuntu'
    Add-Content -Path $powershellFile -Value 'Remove-Item -Path ".\InstallUbuntuWSL.cmd" -Force' #remove startup batch script 
    Add-Content -Path $powershellFile -Value 'Remove-Item -Path "~\Appdata\Local\Temp\InstallUbuntuWSL.ps1" -Force' # remove ps1 script. 
    
    #Message to user to Reboot System 
    Write-Host "You must reboot for the system changes to take effect."
    $reboot = Read-Host "Would you like to reboot the system now?"
    If($reboot -eq 'y' -or $reboot -eq 'yes'){
        Restart-Computer -computername localhost
    }
    Else{
        Write-Host "Please reboot to finish Installing." 
    }

}

#Catch Switch 
If($WSLv1){ 
    isntall_WSLv1 # IF version 1 
}
elseif($WSLv2){ 
    isntall_WSLv2 # IF version 2
}
else{
    Write-host "!!! ERROR !!!"
    Write-host "Please see examples and try again. "
    get-help ./install_WSL_Ubuntu.ps1 -EXAMPLE

}
