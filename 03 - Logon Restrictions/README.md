## What is this?
Here, we will be enforcing logon restrictions to all the domain joined devices.  This will involve several GPOs

## Prerequisites
* Ensure you have a functioning Shadow Group script
* Ensure the Domain **Controllers group** is a member of the **All-Tier0-Servers** group.

## Logon Restrictions for Tier 0 PAWs

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Tier 0 PAW** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

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

## Logon Restrictions for Tier 0 Servers

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Tier 0 Servers** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * BUILTIN\Administrators
  * DOMAIN\PAW-Tier0Users

* Allow log on through Terminal Services
  * DOMAIN\PAW-Tier0Users

* Log on as batch job
  * BUILTIN\Administrators
  * LogOnAsBatch - This is a local group that we will create in a subsequent GPO.
  * taskrunner-shadowgroup - This will allow this user to run the Shadow Group script on your DC.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Link this policy to the **Domain Controllers** OU and ensure the Link is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **All-Tier0-Servers** server Shadow Group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Logon Restrictions for Tier 1 PAWs

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Tier 1 PAW** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * BUILTIN\Administrators
  * BUILTIN\Users
  * DOMAIN\PAW-Tier1Users

* Allow log on through Terminal Services
  * Define the settings, but do not add any users or groups to the list.  This will prevent any user from being able to logon to PAWs over RDP.

* Deny access to this computer from the network
  * BUILTIN\Guests
  * NT AUTHORITY\Local account
  * NT AUTHORITY\Local account and member of Administrators group

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

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Tier 1 Servers** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * BUILTIN\Administrators

* Allow log on through Terminal Services
  * BUILTIN\Administrators
  * DOMAIN\PAW-Tier0Users

* Deny access to this computer from the network
  * BUILTIN\Guests
  * NT AUTHORITY\Local account
  * NT AUTHORITY\Local account and member of Administrators group

* Log on as batch job
  * BUILTIN\Administrators
  * LogOnAsBatch - This is a local group that we will create in a subsequent GPO.

* Log on as a service
  * NT SERVICE\ALL Services
  * LogOnAsService - This is a local group that we will create in a subsequent GPO.

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

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Tier 2 PAW** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * BUILTIN\Administrators
  * BUILTIN\Users
  * DOMAIN\PAW-Tier2Users

* Allow log on through Terminal Services
  * Define the settings, but do not add any users or groups to the list.  This will prevent any user from being able to logon to PAWs over RDP.

* Deny access to this computer from the network
  * BUILTIN\Guests
  * NT AUTHORITY\Local account
  * NT AUTHORITY\Local account and member of Administrators group

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

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Logon Restrictions - Tier 2 Workstations** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

* Allow log on locally:
  * BUILTIN\Administrators
  * BUILTIN\Users
  * DOMAIN\PAW-Tier2Users

* Allow log on through Terminal Services
  * Administrator

* Deny access to this computer from the network
  * BUILTIN\Guests
  * NT AUTHORITY\Local account
  * NT AUTHORITY\Local account and member of Administrators group

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **All-Workstations** group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.
