## What is this?
PAWs often requires software that the standard workstation does not.  Among these are remote administrative software and diagnostics software.  Unless you have a software deployment tool like PDQ Deploy or SCCM, Group Policy will be our main go to for deployment.  From a single GPO using Group Policy Preferences (GPP), we can schedule the installation and configuration of many software made easy by Item Level Targeting.  However, for this guide, and in the real world, I recommend splitting the software deployment to the different groups of computers.  

## What are the GPOs targeting?

This table indicates the GPOs and on which Groups they filter:

GPO | Security Filtering
----|----
Scheduled Task - Install Software - Servers | All-Servers, Domain Controllers
Scheduled Task - Install Software - PAW | PAW-AllPAWComputers
Scheduled Task - Install Software - workstations | All-Workstations

## Deploy software to Servers

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Scheduled Task - Install Software - Servers** with the following settings:

*Computer Configuration > Preferences > Windows Settings > Control Panel Settings > Scheduled Tasks*

Right Click > New > Scheduled Task (At least Windows 7)

### Install Hyper-V
General tab
* Action: Update
* Name: Install Feature - Hyper-V
* Description - Install the Hyper-V feature.
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
* Add argument(optional): **-executionpolicy bypass \\server\share\installHyperV.ps1**

Settings tab
* Allow task to be run on demand

Repeat this process for next


Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **PAW-Tier0Computers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.


## Deploy software to PAWs

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Tier 0 PAW** with the following settings:

*Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment*

* Allow log on locally:
  * BUILTIN\Administrators
  * BUILTIN\Users
  * DOMAIN\PAW-Tier0Users

* Allow log on through Terminal Services
  * Define the settings, but do not add any users or groups to the list.  This will prevent any user from being able to logon to PAWs over RDP.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **PAW-Tier0Computers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.
