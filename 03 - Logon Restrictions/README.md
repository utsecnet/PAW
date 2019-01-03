## What is this?
Here, we will be enforcing logon restrictions to all the domain joined devices.  This will involve several GPOs.

## Prerequisites
* Ensure you have a functioning Shadow Group script
* Ensure the **Domain Controllers** group is a member of the **All-Tier0-Servers** group.

## Logon Restrictions for Domain Controllers

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Domain Controllers** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * **BUILTIN\Administrators**
  * **DOMAIN\PAW-Tier0-Admins**

* Allow log on through Terminal Services
  * **DOMAIN\PAW-Tier0-Admins**

* Log on as batch job
  * **Administrators**
  * **DOMAIN\task-shadowgroup** - This user is responsible for running the shadowgroup script every 10 minutes or so
  
* Deny access to this computer from the network
  * **DOMAIN\Administrator**
  
* Deny log on as a batch job
  * **DOMAIN\Administrator**
  
* Deny log on as a service
  * **DOMAIN\Administrator**
  
* Deny log on locally
  * **DOMAIN\Administrator**
  
* Deny log on through Terminal Services/Remote Desktop Services
  * **DOMAIN\Administrator**

Close the policy window.

On the scope tab:
* Ensure the Link to the Domain Controllers OU is Enabled.
* Ensure **Authenticated Users** is added to the Security Filter
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Logon Restrictions for Tier 0 PAWs

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - PAW Tier 0** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * **BUILTIN\Administrators**
  * **BUILTIN\Users**
  * **DOMAIN\PAW-Tier0-Users**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\PAW-Tier2-Admins**

* Allow log on through Terminal Services
  * Define the settings, but do not add any users or groups to the list.  This will prevent any user from being able to logon to PAWs over RDP.

* Deny access to this computer from the network
  * **DOMAIN\Administrator**
  * **BUILTIN\Guests**
  * **NT AUTHORITY\Local account**
  * **NT AUTHORITY\Local account and member of Administrators group**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\PAW-Tier2-Admins**
  
* Deny log on as a batch job
  * **DOMAIN\Administrator**
  
* Deny log on as a service
  * **DOMAIN\Administrator**
  
* Deny log on locally
  * **DOMAIN\Administrator**
  
* Deny log on through Terminal Services/Remote Desktop Services
  * **DOMAIN\Administrator**

***NOTE***: *It is questionable if "Deny access to this computer from the network" is even needed since we lock down all inbound network traffic via the Windows Firewall with Advanced Security using IPSec to authenticate connections.  I leave it here for future testing.*

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **PAW-Tier0Computers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Logon Restrictions for Tier 0 Servers

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Servers Tier 0** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * **BUILTIN\Administrators**
  * **DOMAIN\PAW-Tier0-Admins**

* Allow log on through Terminal Services
  * **DOMAIN\PAW-Tier0-Admins**

* Log on as batch job
  * **BUILTIN\Administrators**
  * **LogOnAsBatch - This is a local group that we will create in a subsequent GPO.**

* Log on as a service
  * **NT SERVICE\ALL Services**
  * **LogOnAsService** - This is a local group that we will create in a subsequent GPO.
  
* Deny access to this computer from the network
  * **DOMAIN\Administrator**
  
* Deny log on as a batch job
  * **DOMAIN\Administrator**
  
* Deny log on as a service
  * **DOMAIN\Administrator**
  
* Deny log on locally
  * **DOMAIN\Administrator**
  
* Deny log on through Terminal Services/Remote Desktop Services
  * **DOMAIN\Administrator**

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **All-Tier0-Servers** server Shadow Group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Logon Restrictions for Tier 1 PAWs

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - PAW Tier 1** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * **BUILTIN\Administrators**
  * **BUILTIN\Users**
  * **DOMAIN\PAW-Tier1-Users**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\PAW-Tier2-Admins**

* Allow log on through Terminal Services
  * Define the settings, but do not add any users or groups to the list.  This will prevent any user from being able to logon to PAWs over RDP.

* Deny access to this computer from the network
  * **BUILTIN\Guests**
  * **NT AUTHORITY\Local account**
  * **NT AUTHORITY\Local account and member of Administrators group**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier2-Admins**

* Deny log on as a batch job
  * **DOMAIN\Administrator**
  
* Deny log on as a service
  * **DOMAIN\Administrator**
  
* Deny log on locally
  * **DOMAIN\Administrator**
  
* Deny log on through Terminal Services/Remote Desktop Services
  * **DOMAIN\Administrator**

***NOTE***: *It is questionable if "Deny access to this computer from the network" is even needed since we lock down all inbound network traffic via the Windows Firewall with Advanced Security using IPSec to authenticate connections.  I leave it here for future testing.*

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **PAW-Tier1-Computers** group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Logon Restrictions for Tier 1 Servers

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Servers Tier 1** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * **BUILTIN\Administrators**

* Allow log on through Terminal Services
  * **BUILTIN\Administrators**
  * **DOMAIN\PAW-Tier1-Admins**

* Deny access to this computer from the network
  * **BUILTIN\Guests**
  * **NT AUTHORITY\Local account**
  * **NT AUTHORITY\Local account and member of Administrators group**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier2-Admins**

* Deny log on as a batch job
  * **DOMAIN\Administrator**
  
* Deny log on as a service
  * **DOMAIN\Administrator**
  
* Deny log on locally
  * **DOMAIN\Administrator**
  
* Deny log on through Terminal Services/Remote Desktop Services
  * **DOMAIN\Administrator**

* Log on as batch job
  * **BUILTIN\Administrators**
  * **LogOnAsBatch** - This is a local group that we will create in a subsequent GPO.

* Log on as a service
  * **NT SERVICE\ALL Services**
  * **LogOnAsService** - This is a local group that we will create in a subsequent GPO.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **All-Tier1-Servers** server Shadow Group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Logon Restrictions for Tier 2 PAWs

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - PAW Tier 2** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * **BUILTIN\Administrators**
  * **BUILTIN\Users**
  * **DOMAIN\PAW-Tier2-Users**
  * **DOMAIN\PAW-Tier2-Admins**

* Allow log on through Terminal Services
  * Define the settings, but do not add any users or groups to the list.  This will prevent any user from being able to logon to PAWs over RDP.

* Deny access to this computer from the network
  * **BUILTIN\Guests**
  * **NT AUTHORITY\Local account**
  * **NT AUTHORITY\Local account and member of Administrators group**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\Schema Admins**

* Deny log on as batch job
  * **BUILTIN\Guests**
  * **NT AUTHORITY\Local account**
  * **NT AUTHORITY\Local account and member of Administrators group**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\Schema Admins**

* Deny log on as service
  * **BUILTIN\Guests**
  * **NT AUTHORITY\Local account**
  * **NT AUTHORITY\Local account and member of Administrators group**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\Schema Admins**

* Deny log on locally
  * **BUILTIN\Guests**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\Schema Admins**
  
 * Deny log on through Remote Desktop Services
   * **DOMAIN\Administrator**

***NOTE***: *It is questionable if "Deny access to this computer from the network" is even needed since we lock down all inbound network traffic via the Windows Firewall with Advanced Security using IPSec to authenticate connections.  I leave it here for future testing.*

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **PAW-Tier2-Computers** group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Logon Restrictions for Tier 2 Workstations (employee workstations)

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Workstations Tier 2** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * **BUILTIN\Administrators**
  * **BUILTIN\Users**

* Allow log on through Terminal Services
  * **Administrator**

  ***NOTE***: *Helpdesk should never use their Tier 2 admin account with RDP using /RemoteCredentailGuard.  This is because if an RDP session is initiated to a compromised client that an attacker already controls, the attacker could use that open channel to create sessions on the user's behalf (without compromising credentials) to access any of the user’s resources for a limited time (a few hours) after the session disconnects.  Therefore, they should only ever log on through Terminal Services using the LAPS account. [(Source)](https://docs.microsoft.com/en-us/windows/access-protection/remote-credential-guard)*

* Deny access to this computer from the network
  * **BUILTIN\Guests**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\Group Policy Creator Owners**
  * **DOMAIN\Schema Admins**
  
* Deny log on as batch job
  * **BUILTIN\Guests**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\PAW-Tier2-Admins**
  * **DOMAIN\Schema Admins**
  
* Deny log on as a service
  * **BUILTIN\Guests**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\PAW-Tier2-Admins**
  * **DOMAIN\Schema Admins**
 
* Deny log on locally
  * **BUILTIN\Guests**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\PAW-Tier2-Admins**
  * **DOMAIN\Schema Admins**
  
* Deny log on through Remote Desktop Services
  * **BUILTIN\Guests**
  * **DOMAIN\Administrator**
  * **DOMAIN\Domain Admins**
  * **DOMAIN\Enterprise Admins**
  * **DOMAIN\PAW-Tier0-Admins**
  * **DOMAIN\PAW-Tier1-Admins**
  * **DOMAIN\PAW-Tier2-Admins**
  * **DOMAIN\Schema Admins**

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **All-Workstations** group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.
