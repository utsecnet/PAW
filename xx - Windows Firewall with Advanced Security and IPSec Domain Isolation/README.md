## What is this?
We want to ensure that the only traffic entering a PAW is traffic we can verify comes from a source that is trusted.  This typically includes all equivalent Tier traffic and higher.  For example, a Tier 0 PAW should only allow inbound traffic from Tier 0 devices.  A Tier 1 PAW should only allow inbound traffic from Tier 1 device and Tier 0 devices.  It might even be said that the only traffic that should be allowed to all PAWs is authenticated traffic from Tier 0 devices only.  It depends on your environment.

To authenticate traffic means we must use IPSec to ensure traffic comes from specific devices and/or users.  This means rules based on IP address are out!

NOTE: It is outside the scope of this document to explain how IPSec works in Windows Firewall.  Go Google stuff.

## What this guide will provide
We will be doing two things here:
1. Configuring basic Domain Isolation rules
2. Enforce inbound authentication to PAWs from Tier 0 servers (including Domain Controllers)

Of course, there will be more things you will want to do in a production environment, but I am afraid if I share all the steps I take in my environment, it will not work in yours.  Instead, we will just build the above items, then I will refer you to several online resources.

# Word of Warning

### Regarding Domain Controllers
It is important to know that IPSec rules can be configured to *require inbound/outbound authentication* or *request inbound/outbound authentication*.  If you require authentication on the domain controllers, you will most likely kill all network traffic to and from devices that are not joined to the domain.  Don't do this.  Ensure any policy that is set on the domain controllers is configured to *request inbound/outbound authentication* only.

### Regarding Require vs. Request
Due to the nature of how machines refresh group policy (randomly at 90-120 minuted intervals) it is recommended that you set all your policies to request inbound and outbound authentication first.  If you set it to require first, it will be likely that machines will not have received the update and authentication will fail authentication, effectively stopping network traffic.  Only after you have confirmed all machines are authenticating correctly, set the policies to require.  

Consider Require inbound and request outbound.  If you set it to require inbound and outbound, you wont be able to do much if you take your PAW off the corporate network.

## Firewall Policies on Domain Controllers

Create a new GPO on the DOMAIN.COM\Domain Controllers OU called **Security - Firewall - IPSec - Domain Controllers** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the Isolation.wfw configuration file.

### What does this policy set?  
You can see there is only one setting under Connection Security Rules called **Computer and User - Request inbound and outbound**.  Double click on this rule to open the properties and click on the *Authentication* tab.  Notice it is configured to Request inbound and outbound, and applies to Users and Computers.  This allows us to use inbound/outbound rules that can target specific users/groups for computers and users.  Everything else is default.

Close the policy window.

On the scope tab:
* Ensure the Link to the Domain Controllers OU is Enabled.
* Ensure **Authenticated Users** is listed under Security Filtering
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Firewall Policies on PAWs
Create a new GPO on the DOMAIN.COM\Domain Controllers OU called **Security - Firewall - IPSec - PAW** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the PAWs.wfw configuration file.

### What does this policy set?  
You can see there is only one Connection Security Rule called **Computer and User - Require inbound and request outbound**.  Double click on this rule to open the properties and click on the *Authentication* tab.  Notice it is configured to Require inbound and outbound, and applies to Users and Computers.  This allows us to use inbound/outbound rules that can target specific users/groups for computers and users.  Everything else is default.

Click on Inbound Rules.  Notice there are two rules:
* **Deny All -- Any**: This denies all inbound traffic on any port/protocol/program/service from any computer/ip address/user.  It is your default deny.
* **Allow Tier 0 Servers -- Any**: Open this rule. Notice under *General > Action* there is a bullet in *Allow the connection if it is secure*?  Click on *Customize...*.  Notice we are only requiring connections to be authenticated and not encrypted, and we are overriding the above **Deny All -- Any** rule because we have checked *Override block rules*.  Click *OK* on this window and navigate to the *Remote Computers* tab.  Notice we have checked *Only allow connections from these computers:* and we have selected the **DOMAIN\All-Tier0-Servers** group.  If you imported this policy, you may have to update the group and point it to your group since the SID will be incorrect for your environment.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **PAW-AllPAWComputers** group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## What else?
This will enforce inbound authentication on our PAWs.  I would recommend hardening the rest of your domain by enforcing Domain Isolation across the rest of your servers and workstations.  Hopefully the below links will help you in your quest.

## Resources
* [Configuring a test environment](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc754522%28v%3dws.10%29)
* [Because sometimes people learn better via video](https://www.youtube.com/watch?v=taUdRQHfjMQ)