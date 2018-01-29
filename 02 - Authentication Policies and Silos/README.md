## What is this?
Authentication Policies and Silos allow us to restrict user accounts from accessing remote servers as long as the connection is initiated from specified hosts.  In the following example configuration, we will create a silo containing all Domain controllers and other Tier 0 servers, Tier 0 user accounts, and Tier 0 PAWs.  This will only allow Tier 0 user accounts to login to Tier 0 servers (and DCs) from their Tier 0 PAW.  All other connections will be denied.

## Enable Dynamic Access Control (DAC) on Domain Controllers
Create a GPO and apply it to the Domain Controller's OU called **Security - Allow Dynamic Access Control - DCs** with the following settings:

*Computer Configuration > Policies > Admin Templates > System > KDC*
* KDC support for claims, compound authentication and Kerberos armoring: **Enabled, Always provide claims**

On the scope tab:
* Ensure the Link is Enabled.  
* Ensure **Authenticated Users** is selected under **Security Filtering**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Enable DAC on PAWs
Create a GPO and apply it to the DOMAIN.COM\Company\Computers OU called **Security - Allow Dynamic Access Control - PAW** with the following settings:

*Computer Configuration > Policies > Admin Templates > System > Kerberos*
* Kerberos client support for claims, compound authentication and Kerberos armoring: **Enabled**

## Configure the Authentication Policy and Silo
1. Create the policy by opening Active Directory Administrative Center and navigate to **Authentication > Policies > right click and create new policy**.
2. Name it: **Allow Tier0 users access to Tier0 servers from Tier0 PAW**
