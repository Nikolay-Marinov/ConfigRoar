AVD_GI_AppsInstall.ps1

PowerShell Script Documentation
This PowerShell script is intended to automate the installation of Office 365, OneDrive for Business, Teams, and FSLogix Apps.

Parameters
The script has four parameters:

tenantid (optional): This is the tenant ID used for OneDrive configuration. If not specified, the value will be empty.

tempsourcepath (optional): This is the path where the installation files are stored. If not specified, the default value will be "c:\tmpavd".

O365ConfigFile (optional): This is the path to the Office 365 configuration file. If not specified, the default value will be "c:\tmp\configuration.xml".

O365SetupFile (optional): This is the path to the Office 365 setup file. If not specified, the default value will be "c:\tmp\setup.exe".

Installation Steps
1. The script checks if the tempsourcepath directory exists. If it does not, it creates it along with an "O365" subdirectory.

2. The script installs Office 365 (without OneDrive) by copying the setup and configuration files to the tempsourcepath\O365 directory, and running the setup file with the configuration file as an argument.

3. If the Office 365 installation fails, the script will display an error message and stop.

4. The script installs OneDrive for Business by downloading it, uninstalling any previous versions, installing it for all users, and setting various registry keys.

5. The script installs Teams by downloading the MSI file, and installing it with the silent flag. It also sets a registry key for WVDEnvironment.

6. The script installs FSLogix Apps by downloading the zip file and extracting it to a specified location.

Usage
To use this script, open PowerShell and run the script file. If you want to pass any parameters, add them after the filename. For example:

.\script.ps1 -tenantid "123456" -tempsourcepath "c:\installs" -O365ConfigFile "c:\config.xml" -O365SetupFile "c:\setup.exe"

Note: The script requires administrative privileges to run.
