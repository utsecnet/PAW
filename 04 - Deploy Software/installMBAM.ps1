<#
.NOTES
    NAME: installMBAM.ps1
    AUTHOR: Rich Johnson
    EMAIL: rjohnson@upwell.com
    Change Log:
        2018-01-08 - Initial creation 
        
.SYNOPSIS
    This script installs MBAM, needed for enabling Bitlocker
    This script is called via a scheduled task or an immediate task (via GPO) with the following details:
        General Tab
            - runas: SYSTEM (does not require 'run as highest privileges'
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\installMBAM.ps1 <org>

.DESCRIPTION 
    What does this script do?
    - Checks if installed, if not it installs and verifies successful installation
    - Checks service is running, if not it starts it and verifies successful start

    What do I need to do?
    - Deploy and configure your MBAM server architecture (https://goo.gl/fcZow9)
    - Search this script for <changeme> and replace it with the required data.

.PARAMETER location
    This script requires no parameters

.Example
    >.\installMBAM
    Installs MBAM on the client computer
#>

############
# Functions
############

# All actions are logged by calling this function
function logging ($level, $text) {
    if ($debug -ne "on" -and $level -eq "D") {
        return
    }
    $timeStamp = get-date -Format "yyyy-MM-dd HH:mm:ss.fff"

    if ($blurb -ne "yes") {
        # Override the existing log file so it does not grow out of control
        Write-Output "$timeStamp I New log created" > $logLocation
        $script:blurb = "yes"
    }

    Write-Output "$timeStamp $level $text" >> $logLocation
}

# Check if a service exists
function checkServiceExists ($serviceName) {
    # Check if service exists
    if (Get-Service $serviceName -EA SilentlyContinue) {
        $serviceExists = $true
    }
    else {
        $serviceExists = $false
    }
    logging "D" "serviceExists: $serviceExists"
    return $serviceExists
}

# Check if a service is running or not
function checkServiceStatus ($serviceName) {
    if ($(get-service $serviceName).Status -eq "Running") {
        $serviceStatus = $true
    }
    else {
        $serviceStatus = $false
    }
    logging "D" "serviceStatus: $serviceStatus"
    return $serviceStatus
}

function installMBAM {
    # Check that the path to the install file exists and install
    if (Test-Path $installPath) {
        logging "D" "install command: msiexec /qn /lvoicewarmupx $installLog /package $installPath REBOOT=ReallySuppress"
        Start-Process -FilePath msiexec -ArgumentList /qn, /lvoicewarmupx, $installLog, /package, $installPath, REBOOT=ReallySuppress -Wait
    }
    else {
        logging "E" "$installFilePath does not exist"
        #exit
    }
}

######################
# Set global variables
######################

# Location where this script will log to
# This is different than the msiexec installation log file, which you specify in the install command
$logLocation = "C:\ProgramData\installMBAM.txt"

# Turn this to on if you want additional debug logging.  Off will overwrite On if you uncomment the <debug = "off"> line.
# Debug logging will show you the value of all variables so you can see if varable logic problems exist
$debug = "on"
#$debug = "off"

# Program Name
$programName = "MBAM"
logging "D" "programName: $programName"

# Name of the MBAM Service
$serviceName = "MBAMAgent"
logging "D" "serviceName: $serviceName"

# Set the name of the file server.  For example: $fileServer = "serverdfs01"
$fileServer = "<changeme>"

# Location of the installation files
$remoteDir = "\\$fileServer\share\mbam"
logging "D" "remoteDir: $remoteDir"

# name of the installation file
$installFile = "MbamClientSetup2_5_1100.msi"
logging "D" "installFile: $installFile"

# Full path to install file
$installPath = "$remoteDir\$installFile"
logging "D" "installPath: $installPath"

# Path to the msi install logs
$installLog = "$env:programdata\installMBAM-msiLog.txt"
logging "D" "installLog: $installLog"

##################
# Aaaaaaad ACTION!
##################

try {

    # Is MBAM installed?
    ###################################
    if ($(checkServiceExists $serviceName) -eq $true) {
        logging "I" "$programName Agent is installed."
    }
    else {
        logging "I" "$programName is not currently installed."

        # Install
        installMBAM

        # Did it install correctly?
        if ($(checkServiceExists $serviceName) -eq $true) {
            logging "I" "$programName installed correctly."
        }
        else {
            logging "E" "$programName did not install correctly. Service $serviceName still not found."
        }
    }

    # Is the MBAM agent service started?
    #############################################
    if ($(checkServiceStatus $serviceName) -eq $true) {
        logging "I" "Service $serviceName is running."
    }
    else {
        logging "I" "Service $serviceName is not running."

        # Start Service
        Start-Service $serviceName

        # Did it start correctly?
        if ($(checkServiceStatus $serviceName) -eq $true) {
            logging "I" "Successfully started service $serviceName"
        }
        else {
            logging "E" "Failed to start service $serviceName."
        }
    }
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}
finally {
    logging "I" "Exiting script."
}