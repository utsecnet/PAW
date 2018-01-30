## What is this?
PAWs often requires software that the standard workstation does not.  Among these are remote administrative software and diagnostics software.  Unless you have a software deployment tool like PDQ Deploy or SCCM, Group Policy will be our main go to for deployment.  From a single GPO using Group Policy Preferences (GPP), we can schedule the installation and configuration of many software made easy by Item Level Targeting.  However, for this guide, and in the real world, I recommend splitting the software deployment to the different groups of computers.  

## What are the GPOs targeting?

This table indicates the GPOs and on which groups they filter:

GPO | Security Filtering
----|----
Scheduled Task - Install Software - Servers | All-Servers
Scheduled Task - Install Software - PAW | PAW-AllPAWComputers
Scheduled Task - Install Software - workstations | All-Workstations

## Deploy software to PAWs

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Scheduled Task - Install Software - PAWs**.

Configure the following software deployments according to the settings under **GPO Settings** (Bottom of page)

#### Hyper-V
* Name of software: Hyper-V
* Name of script: installHyperv.ps1

#### MBAM Client
* Name of software: MBAM Client
* Name of script: installMBAM.ps1

#### Nmap
* Name of software: Nmap
* Name of script: installNmap.ps1

#### RSAT
* Name of Software: RSAT
* Name of script: installRSAT.ps1

#### Sysinternals Suite
* Name of Software: Sysinternals Suite
* Name of script: installSysinternals.ps1

#### LAPS
* Name of Software: LAPS
* Name of script: installLAPS.ps1

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **PAW-AllPAWComputers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Deploy software to Servers

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Scheduled Task - Install Software - PAWs**.

Configure the following software deployments according to the settings under **GPO Settings** (Bottom of page)

#### LAPS
* Name of Software: LAPS
* Name of script: installLAPS.ps1

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **All-Servers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.
## GPO Settings

*Computer Configuration > Preferences > Windows Settings > Control Panel Settings > Scheduled Tasks*

Right Click > New > Scheduled Task (At least Windows 7)

General tab
* Action: Update
* Name: Install Feature - <Name of software>
* Description - Install <Name of software>.
* Run as: **NT AUTHORITY\System**, Run whether user is logged in or not
* Hidden: **checked**
* Do not run with highest privileges
* Configure for Windows Vista or Windows Server 2008

Triggers tab
* Begin the task: **On a Scheduled**
* Settings: **One time**
* Delay task for up to (random delay): **1 hour**
* Repeat the task every: **1 hour** for a duration of **Indefinitely**
* Enabled: **Checked**

Actions tab
* Action: Start a program
* Program: **powershell.exe**
* Add argument(optional): **-executionpolicy bypass \\server\share\<name of script>**

Settings tab
* Allow task to be run on demand
