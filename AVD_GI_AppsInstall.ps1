<#    
.SYNOPSIS
    www.configroar.com 
    This script is used for initial application configuration for applications for Azure VIrtual Desktop  
.DESCRIPTION
    The script downloads some applications. The Office 365 setup.exe as well as configuration file, need to be prepared beforehand
.PARAMETER TenantID
    The ID of your Azure Tenant
    
.PARAMETER tempsourcepath
Path to temporary folder to save files. The size is approx. 4.5 GB

.PARAMETER O365ConfigFile
(optional): This is the path to the Office 365 configuration file. If not specified, the default value will be "c:\tmp\configuration.xml".

.PARAMETER O365SetupFile 
(optional): This is the path to the Office 365 setup file. If not specified, the default value will be "c:\tmp\setup.exe".

.NOTES
    Version:        1.5
    Author:         Nikolay Marinov
    Creation date:  23.01.2023
    Last modified:  08.03.2023

    History of Changes: 
    V 1.5 - Some additional optimization for Teams.
  
.EXAMPLE 
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    $tenantid="",

    [Parameter(Mandatory = $false)]
    $tempsourcepath="c:\tmpavd",

    [Parameter(Mandatory = $false)]
    $O365ConfigFile="c:\tmp\configuration.xml", 

    [Parameter(Mandatory = $false)]
    $O365SetupFile="c:\tmp\setup.exe"

)

if(!(Test-Path "$tempsourcepath\")){
New-Item "$tempsourcepath\" -ItemType Directory
New-Item "$tempsourcepath\O365\" -ItemType Directory
}


########################################
##INSTALLATION OF OFFICE 365 (No OneDrive)
########################################
try{

Copy-Item -Path $O365SetupFile -Destination "$tempsourcepath\O365\setup.exe" -Force -PassThru
Copy-Item -Path $O365ConfigXML -Destination "$tempsourcepath\O365\configuration.xml" -Force -PassThru

if(!(Test-Path "$tempsourcepath\O365\setup.exe")){throw 1}
if(!(Test-Path "$tempsourcepath\O365\configuration.xml")){throw 1}  

$proc = (Start-Process -FilePath "$tempsourcepath\O365\setup.exe" -ArgumentList "/configure '$tempsourcepath\O365\configuration.xml'" -PassThru);
$proc.WaitForExit();
$ExitCode = $proc.ExitCode
}
catch
{
write-host "Office 365 Installation cannot continue as the sources are missing"
}

########################################
##END OF INSTALLATION OF OFFICE 365
########################################


########################################
##INSTALLATION OF ONE DRIVE FOR BUSINESS
########################################

Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=844652" -OutFile "$tempsourcepath\onedrive.exe"
#remove all older OneDrive versions
$proc = (Start-Process -FilePath "$tempsourcepath\onedrive.exe" -ArgumentList "/uninstall" -PassThru);
$proc.WaitForExit();
$ExitCode = $proc.ExitCode

#OneDrive pre-configuration
New-Item -Path "HKLM:\Software\Microsoft\OneDrive\" -Force -ea SilentlyContinue
New-ItemProperty -Path "HKLM:\Software\Microsoft\OneDrive\" -Name "AllUsersInstall" -PropertyType DWORD -Value 1 -Force


#install OneDrive pre Machine
$proc = (Start-Process -FilePath "$tempsourcepath\onedrive.exe" -ArgumentList "/allusers" -PassThru);
$proc.WaitForExit();
$ExitCode = $proc.ExitCode

#OneDrive post-configuration
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -PropertyType String -Value "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe /background" -Force
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\" -Force -ea SilentlyContinue
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\" -Name "SilentAccountConfig" -PropertyType DWORD -Value 1 -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\" -Name "KFMSilentOptIn" -PropertyType DWORD -Value $tenantid -Force

########################################
##END OF ONE DRIVE INSTALLATION
########################################

########################################
##INSTALLATION AND OPTIMIZATION OF TEAMS 
########################################



Invoke-WebRequest -Uri "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true" -OutFile "$tempsourcepath\teams.msi"

Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vc_redist.x64.exe" -OutFile "$tempsourcepath\vc_redist.x64.exe" 
 
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt" -OutFile "$tempsourcepath\MsRdcWebRTCSvc_HostSetup.msi" 

Start-Process "$tempsourcepath\vc_redist.x64.exe" -ArgumentList @('/q', '/norestart') -NoNewWindow -Wait -PassThru 

Start-Process msiexec.exe -ArgumentList "/i $tempsourcepath\MsRdcWebRTCSvc_HostSetup.msi /l*v $tempsourcepath\MsRdcWebRTCSvc_HostSetup_Install.log /q /n" -Wait  

#pre-install configuration
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams\" -Force -ea SilentlyContinue
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams\" -Name "IsWVDEnvironment" -PropertyType DWORD -Value 1 -Force

$proc = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempsourcepath\teams.msi`" /l*v `"$env:TEMP\teams_msi_install.log`" /qn ALLUSERS=1 REBOOT=REALLYSUPPRESS" -Wait -PassThru);
$proc.WaitForExit()
$ExitCode = $proc.ExitCode

########################################
##END OF TEAMS INSTALLATION 
########################################


########################################
##INSTALLATION OF FSLOGIX APPS 
########################################

Invoke-WebRequest -Uri "https://aka.ms/fslogix/download" -OutFile "$tempsourcepath\fslogixapps.zip"
Expand-Archive "$tempsourcepath\fslogixapps.zip" -DestinationPath "$tempsourcepath\fslogixapps\" -Force

#Installation
$proc = (Start-Process -FilePath "$tempsourcepath\fslogixapps\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/install /quiet /norestart" -Wait -PassThru);
$proc.WaitForExit();
$ExitCode = $proc.ExitCode

########################################
##END OF FSLOGIX APPS  INSTALLATION 
########################################

#Cleanup (Optional)
#Remove-Item $tempsourcepath -Force -Confirm
