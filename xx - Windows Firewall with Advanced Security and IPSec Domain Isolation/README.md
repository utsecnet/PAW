## What is this?
We want to ensure that the only traffic entering a PAW is traffic we can verify comes from a source that is trusted.  This typically includes all equivalent Tier traffic and higher.  For example, a Tier 0 PAW should only allow inbound traffic from Tier 0 devices.  A Tier 1 PAW should only allow inbound traffic from Tier 1 device and Tier 0 devices.  It might even be said that the only traffic that should be allowed to all PAWs is authenticated traffic from Tier 0 devices only.  It depends on your environment.

To authenticate traffic means we must use IPSec to ensure traffic comes from specific devices and/or users.  This means simple inbound/outbound rules based on IP address or ports are out!

NOTE: It is outside the scope of this document to explain how IPSec works in Windows Firewall.  Go Google stuff.

## What this guide will provide
This guide will help achieve the following:
1. For all servers, configure a Windows Firewall baseline policy (adapted from the CIS baseline for Server 2016)
2. On Domain Controllers, configure Domain Isolation policies
3. On Tier 0 servers, configure Domain Isolation policies
4. On Tier 1 servers, configure Domain Isolation policies
5. On all workstations, configure a Windows Firewall baseline policy (adapted from the CIS baseline for Windows 10 1709)
6. On all workstations, configure Domain Isolation policies
7. On all PAWs, configure Domain Isolation policies
8. Configure authentication exception policies for RADIUS
9. Configure authentication exception policies for Certificate Authorities


Of course, there will be more things you will want to do in your production environment, but I am afraid if I share all the steps I take in my environment, it will not work in yours.  Instead, we will just build the above items, then I will refer you to several online resources.

# Word of Warning

### Regarding Domain Controllers
It is important to know that IPSec rules can be configured to *require inbound/outbound authentication* or *request inbound/outbound authentication*.  If you require authentication on the domain controllers, you will most likely kill all network traffic to and from devices that are not joined to the domain.  Don't do this.  Ensure any policy that is set on the domain controllers is configured to *request inbound/outbound authentication* only.

### Regarding Require vs. Request (on domain clients, member servers & workstations)
Due to the nature of how machines refresh group policy (randomly at 90-120 minute intervals) it is recommended that you set all your policies to request inbound and outbound authentication first.  If you set it to require first, it will be likely that machines will not have received the update and authentication will fail, effectively stopping network traffic.  Only after you have confirmed all machines are authenticating correctly, set the policies to require.  

Consider Require inbound and request outbound.  If you set it to require inbound and outbound, you wont be able to do much if you take your PAW off the corporate network.  In this case you could set require inbound and outbound on only the domain profile then request outbound on public/private profiles.  However, we will not be covering this in this guide.

## 1. For all servers, configure a Windows Firewall baseline policy

Create a new GPO and link it to the DOMAIN.COM\Domain Controllers OU called **Security - CIS Baseline - Server 2016 - Windows Firewall** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the "firewall_2016.wfw" configuration file.

### What does this policy set?  
You will notice that there are no Inbound or Outbound rules, nor Connection Security Rules.  Instead, we are simply creating the baseline firewall properties found under the *Windows Firewall Properties* link.  

#### Under the *Domain Profile* tab, we set:
* Firewall State: **On (recommended)**
* Inbound connections: **Block (default)**
* Outbound connections: **Allow (default)**
* Settings > Customize ...
 	* Display a notification: **No**
	* Allow unicast response: **Not configured**
	* Apply local firewall rules: **Yes (default)** (Note: this will be over-ridden with the IPSec policy later.  This is simply a baseline.)
	* Apply local connection security rules: **No**
* Logging > Customize ...
	* Name: **%systemroot%\System32\LogFiles\Firewall\domain.txt**
	* Not configured: **unchecked**
	* Size limit (KB): 16384
	* Not configured: **unchecked**
	* Log dropped packets: **Yes**
	* Log successful connections: **Yes**

#### Under the *Private Profile* tab, we set:
* Firewall State: **On (recommended)**
* Inbound connections: **Block (default)**
* Outbound connections: **Allow (default)**
* Settings > Customize ...
 	* Display a notification: **No**
	* Allow unicast response: **Not configured**
	* Apply local firewall rules: **Yes (default)** (Note: this will be over-ridden with the IPSec policy later.  This is simply a baseline.)
	* Apply local connection security rules: **No**
* Logging > Customize ...
	* Name: **%systemroot%\System32\LogFiles\Firewall\private.txt**
	* Not configured: **unchecked**
	* Size limit (KB): 16384
	* Not configured: **unchecked**
	* Log dropped packets: **Yes**
	* Log successful connections: **Yes**

#### Under the *Public Profile* tab, we set:
* Firewall State: **On (recommended)**
* Inbound connections: **Block (default)**
* Outbound connections: **Allow (default)**
* Settings > Customize ...
 	* Display a notification: **No**
	* Allow unicast response: **Not configured**
	* Apply local firewall rules: **No** (Note: this will be over-ridden with the IPSec policy later.  This is simply a baseline.)
	* Apply local connection security rules: **No**
* Logging > Customize ...
	* Name: **%systemroot%\System32\LogFiles\Firewall\public.txt**
	* Not configured: **unchecked**
	* Size limit (KB): 16384
	* Not configured: **unchecked**
	* Log dropped packets: **Yes**
	* Log successful connections: **Yes**

Close the policy window.

On the scope tab:
* Ensure the Link to the **Domain Controllers** OU is Enabled.
* Ensure the Link to the **Computers** OU is Enabled.
* Ensure **Authenticated Users** is listed under Security Filtering
* Since this will be used to target all Server 2016 machines, you want a WMI filter that does exactly that:

Namespace: root\CIMv2
Query: select * from Win32_OperatingSystem where Name like "%Server 2016%"

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## 2. On Domain Controllers, configure Domain Isolation policies

Create a new GPO and link it to the DOMAIN.COM\Domain Controllers OU called **Security - Firewall - IPSec - Domain Controllers** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the "firewall_ipsec_dc.wfw" configuration file.

### What does this policy set?  
Under the *Windows Firewall Properties* link, we override several settings we set in the baseline.  Namely, under the *Domain and Private Profile > Settings > Customize ...* we set:
* Apply local firewall rules: **No**

This forces you to set all inbound rules via group policy and effectively disables any default rules created.  Once this is set, navigate to *Inbound Rules* to see the rules we are creating.  

***NOTE*** *These policies are best viewed from a Domain Controller.  Otherwise you may see things like* ***@ntdsmsg.dll*** *in the policy name.*

Ensure that management of the DCs is performed from Tier 0 PAWs, and all other inbound traffic is unauthenticated.  Review the Policies to ensure the correct groups are set in the *Authorized Users* and *Authorized Computers* fields of the IPSec rules (lock icon).

You can see there is only one setting under Connection Security Rules called **Computer and User - Request inbound and outbound**.  Double click on this rule to open the properties and click on the *Authentication* tab.  Notice it is configured to Request inbound and outbound, and applies to Users and Computers.  This allows us to use inbound/outbound rules that can target specific users/groups for computers and users.  Everything else is default.

Close the policy window.

On the scope tab:
* Ensure the Link to the **Domain Controllers** OU is Enabled.
* Ensure **Authenticated Users** is listed under Security Filtering
* Ensure that **WMI Filtering** is set to **None**.

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## 3. On Tier 0 servers, configure Domain Isolation policies

Create a new GPO and link it to the DOMAIN.COM\Domain Controllers OU called **Security - Firewall - IPSec - Servers Tier 0** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the "firewall_ipsec_tier0.wfw" configuration file.

### What does this policy set?  
Under the *Windows Firewall Properties* link, we override several settings we set in the baseline.  Namely, under the *Domain and Private Profile > Settings > Customize ...* we set:
* Apply local firewall rules: **No**

Not all servers in a corporate network can force inbound authentication when remote hosts attempt to access resources on the server.  Here are a few examples:

* A mac client connects to a Windows file share (unless you are using something like Centrify)
* A non-domain joined server (think DMZ) needs access to a domain resource
* Contractors or guests that need internal resources like printers through the print servers
* A standalone server that has a agent on it that communicates to the master server which is domain joined

Because of this, I find it best practice to not force inbound authentication.  But rather, request inbound and outbound and force inbound authentication on management protocols like RDP or WMI.  We do this be creating IPSec rules that require authentication over these management ports, and use standard inbound rules for everything else that is benign. In this GPO we have a small handful of rules that require authentication:

* Allow Tier 0 PAWs/admins -- Any: allows all traffic so long as it comes from a Tier 0 admin on a Tier 0 PAWs
* Allow Tier 0 Servers -- Any: allows all traffic from Tier 0 server, regardless of who is logged in.  
* Remote Desktop: allows any Tier 0 PAW to RDP regardless of who is logged in.  I have noticed sometimes RDP does not connect if I dont have this rule.  So it's more of a backup for when the top rule above fails.

And a handful of rules that do not require authentication.

Review the Policies to ensure the correct groups are set in the *Authorized Users* and *Authorized Computers* fields of the IPSec rules (lock icon).

You can see there is only one setting under Connection Security Rules called **Computer and User - Request inbound and outbound**.  Double click on this rule to open the properties and click on the *Authentication* tab.  Notice it is configured to Request inbound and outbound, and applies to Users and Computers.

Close the policy window.

On the scope tab:
* Ensure the Link to the **Computers** OU is Enabled.
* Ensure **All-Tier0-Servers** is listed under Security Filtering
* Ensure that **WMI Filtering** is set to **None**.

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## 4. On Tier 1 servers, configure Domain Isolation policies

Create a new GPO and link it to the DOMAIN.COM\Domain Controllers OU called **Security - Firewall - IPSec - Servers Tier 1** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the "firewall_ipsec_tier1.wfw" configuration file.

### What does this policy set?  
Under the *Windows Firewall Properties* link, we override several settings we set in the baseline.  Namely, under the *Domain and Private Profile > Settings > Customize ...* we set:
* Apply local firewall rules: **No**

Not all servers in a corporate network can force inbound authentication when remote hosts attempt to access resources on the server.  Here are a few examples:

* A mac client connects to a Windows file share (unless you are using something like Centrify)
* A non-domain joined server (think DMZ) needs access to a domain resource
* Contractors or guests that need internal resources like printers through the print servers
* A standalone server that has a agent on it that communicates to the master server which is domain joined

Because of this, I find it best practice to not force inbound authentication.  But rather, request inbound and outbound and force inbound authentication on management protocols like RDP or WMI.  We do this be creating IPSec rules that require authentication over these management ports, and use standard inbound rules for everything else that is benign. In this GPO we have a small handful of rules that require authentication:

* Allow Tier 0 PAWs/admins -- Any: allows all traffic so long as it comes from a Tier 0 admin on a Tier 0 PAWs
* Allow Tier 1 PAWs/admins -- Any: allows all traffic so long as it comes from a Tier 1 admin on a Tier 1 PAWs
* Allow Tier 0 Servers -- Any: allows all traffic from Tier 0 server, regardless of who is logged in.  
* Windows Defender Firewall Remote Management ...: ALlows management of the server's firewall from a Tier0/Tier1 PAW.

And a handful of rules that do not require authentication.

Review the Policies to ensure the correct groups are set in the *Authorized Users* and *Authorized Computers* fields of the IPSec rules (lock icon).

You can see there is only one setting under Connection Security Rules called **Computer and User - Request inbound and outbound**.  Double click on this rule to open the properties and click on the *Authentication* tab.  Notice it is configured to Request inbound and outbound, and applies to Users and Computers.

Close the policy window.

On the scope tab:
* Ensure the Link to the **Computers** OU is Enabled.
* Ensure **All-Tier1-Servers** is listed under Security Filtering
* Ensure that **WMI Filtering** is set to **None**.

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## 5. On all workstations, configure a Windows Firewall baseline policy

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - CIS baseline - Win 10 - Windows Firewall** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the firewall_win10.wfw configuration file.

### What does this policy set?
This policy configures the firewall to be enabled on all three profiles, and sets logging parameters for each.

Click on *Windows Firewall Properties*.  Under the each profile tab, notice we make the following settings:
#### Under the *Domain Profile* tab, we set:
* Firewall State: **On (recommended)**
* Inbound connections: **Block (default)**
* Outbound connections: **Allow (default)**
* Settings > Customize ...
 	* Display a notification: **No**
	* Allow unicast response: **Yes (default)**
	* Apply local firewall rules: **Yes (default)** (Note: this will be over-ridden with the IPSec policy later.  This is simply a baseline.)
	* Apply local connection security rules: **No**
* Logging > Customize ...
	* Name: **%systemroot%\System32\LogFiles\Firewall\domain.txt**
	* Not configured: **unchecked**
	* Size limit (KB): 16384
	* Not configured: **unchecked**
	* Log dropped packets: **Yes**
	* Log successful connections: **Yes**

#### Under the *Private Profile* tab, we set:
* Firewall State: **On (recommended)**
* Inbound connections: **Block (default)**
* Outbound connections: **Allow (default)**
* Settings > Customize ...
 	* Display a notification: **No**
	* Allow unicast response: **Not configured**
	* Apply local firewall rules: **Yes (default)** (Note: this will be over-ridden with the IPSec policy later.  This is simply a baseline.)
	* Apply local connection security rules: **No**
* Logging > Customize ...
	* Name: **%systemroot%\System32\LogFiles\Firewall\private.txt**
	* Not configured: **unchecked**
	* Size limit (KB): 16384
	* Not configured: **unchecked**
	* Log dropped packets: **Yes**
	* Log successful connections: **Yes**

#### Under the *Public Profile* tab, we set:
* Firewall State: **On (recommended)**
* Inbound connections: **Block (default)**
* Outbound connections: **Allow (default)**
* Settings > Customize ...
 	* Display a notification: **No**
	* Allow unicast response: **Not configured**
	* Apply local firewall rules: **No**
	* Apply local connection security rules: **No**
* Logging > Customize ...
	* Name: **%systemroot%\System32\LogFiles\Firewall\public.txt**
	* Not configured: **unchecked**
	* Size limit (KB): 16384
	* Not configured: **unchecked**
	* Log dropped packets: **Yes**
	* Log successful connections: **Yes**

Close the policy window.

On the scope tab:
* Ensure the Link to the **Computers** OU is Enabled.
* Ensure **Authenticated Users** is added in the **Security Filtering** section.
* Since this will be used to target all Windows 10 machines, you want a WMI filter that does exactly that:

Namespace: root\CIMv2
Query: select * from Win32_OperatingSystem where Name like "%Windows 10%"

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## 6. On all workstations, configure Domain Isolation policies

Create a new GPO and link it to the DOMAIN.COM\Domain Controllers OU called **Security - Firewall - IPSec - Workstations Tier 2** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the "firewall_ipsec_tier2.wfw" configuration file.

### What does this policy set?  
Under the *Windows Firewall Properties* link, we override several settings we set in the baseline.  Namely, under the *Domain and Private Profile > Settings > Customize ...* we set:
* Apply local firewall rules: **No**

In previous IPSec policies, we configured the host to request inbound and outbound authentication, and then only forced authentication over management protocols, like RDP.  In this policy I will show you a second way to do the same thing.  First, notice under **Connection Security Rules** that we have two rules:

* **Computer and User - Require inbound and request outbound**: This policy is set to require inbound.  That means nothing can communicate with the host unless it is authenticated.
* **Authentication exception - Allow Surface Hub connection**: we exempt the subnet where surface hubs exist since hubs use miracast, which is a protocol that initiates a connection from the host to the Surface Hub, then the Hub connects back to the host.  At this time, Surface Hubs are unable to authenticate with IPSec.

Looking at the Inbound Rules, we see the following rules that require authentication:

* **Allow Tier 0 and 1 Servers -- Any**: Allows all servers inbound for management purposes
* **Allow Tier 0 or 2 PAWs -- Any**: Allows Tier 0 and 2 PAW admins to manage workstations
* **File and Print Shareing...**: Allows any PAW to access file or print shares on workstations
* **Windows Defender Firewall Remote Management**: Allows PAW admins remote firewall management

There is one rule that must not require authentication:

* **Allow Surface Hubs to connect to WUDFHost.exe**: Remember our CSR exempted the whole subnet of surface hubs from requiring authentitation.  Here we are limiting what that subnet can talk to a single process on the host.  So, it's not like if the user had a home network the same as the exempted hub network, they would have full firewall access to their work machine.  

Close the policy window.

On the scope tab:
* Ensure the Link to the **Computers** OU is Enabled.
* Ensure **All-Workstations** is listed under Security Filtering
* Ensure that **WMI Filtering** is set to **None**.

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## 8. Configure authentication exception policies for RADIUS



## 9. Configure authentication exception policies for Certificate Authorities






## 7. On all PAWs, configure Domain Isolation policies

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Firewall - IPSec - PAW** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the firewall_paw.wfw configuration file.

### What does this policy set?  
You can see there is only one Connection Security Rule called **Computer and User - Require inbound and request outbound**.  Double click on this rule to open the properties and click on the *Authentication* tab.  Notice it is configured to Require inbound and reqwuest outbound, and applies to Users and Computers.  This allows us to use inbound/outbound rules that can target specific users/groups for computers and users.  Everything else is default.

Click on Inbound Rules.  Notice there are two rules:
* **File and Printer Sharing (Echo Request - ICMPv4-In)**: Allows anyone with a PAW to ping.  Useful for troubleshooting for those that need it.
* **Allow connections from all Tier 0 Devices -- Any**: Open this rule. Notice under *General > Action* there is a bullet in *Allow the connection if it is secure*.  Click on *Customize...*.  Notice we are only requiring connections to be authenticated and not encrypted, and we are overriding the above **Deny All -- Any** rule incase there ever needs to be a block rule, this will need to work.  Click *OK* on this window and navigate to the *Remote Computers* tab.  Notice we have checked *Only allow connections from these computers:* and we have selected the **DOMAIN\All-Tier0-Servers** and **DOMAIN\PAW-Tier0-Computers** groups.  If you imported this policy, you may have to update the group and point it to your group since the SID will be incorrect for your environment.

Close the policy window.

On the scope tab:
* Ensure the Link to the **Computers** OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the **PAW-AllPAWComputers** group.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.


## 8. Configure authentication exception policies for RADIUS
Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Firewall - IPSec - Servers Tier 0 - RADIUS** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the firewall_ipsec_radius.wfw configuration file.

### What does this policy set?
You can see there are two Connection Security Rules:
1. **Exempt Authentication -- RADIUS TCP**. Double click on this rule to open the properties and click on the *Protocols and Ports* tab.  Notice we are setting the RADIUS ports 1812 and 1813 in the *Endpoint 2 port* field.  Click on the *Authentication* tab.  Notice we set Authentication mode to *Do not authenticate*.  Because our RADIUS clients are not on the domain (mainly WAPs and switches), we must exempt them from having to authenticate to the RADIUS servers.  
2. **Exempt Authentication -- RADIUS UDP**. Same setting as TCP except for UDP ports (RADIUS uses both TCP and UDP).

There are three Inbound Rules:
* **Allow Any -- RADIUS**: This allows inbound unauthenticated RADIUS connections
* **Network Policy Server (2 rules)**: Should allow inbound management of the NPS server from Tier 0 admins on Tier 0 PAWs.

Close the policy window.

On the scope tab:
* Ensure the Link to the **Computers** OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and add the default AD group **RAS and IAS Servers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## 9. Configure authentication exception policies for Certificate Authorities
Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Firewall - IPSec - Servers Tier 0 - Certificate Authorities** with the following settings:

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Firewall with Advanced Security***

Right click **Windows Firewall with Advanced Security - LDAP://...** and select **Import Policy...**.  Import the firewall_ipsec_ca.wfw configuration file.

### What does this policy set?
You can see there is one Connection Security Rule:
1. **Exempt Authentication - Certificate Services**. Double click on this rule to open the properties and click on the *Protocols and Ports* tab.  Notice we are setting the TCP ports 135, 49152-65535 in the *Endpoint 2 port* field.  Click on the *Authentication* tab.  Notice we set Authentication mode to *Do not authenticate*.  Because our clients (especially MacOS) don't yet have a certificate when they request one, the request must be done unauthenticated.

There are six Inbound Rules:
* **Allow HTTP/HTTPS**: This forces clients that want to use the certificate enrollment web page to be authenticated.
* **Certificate Authority Enrollment and Management Protocol...**: These rules allow clients to request a certificate unauthenticated.

Close the policy window.

On the scope tab:
* Ensure the Link to the **Computers** OU is Enabled.
* Remove **Authenticated Users** from the **Security Filtering** section and either add your CA servers directly or add the AD group if you created one.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.

## Resources
* [Configuring a test environment](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc754522%28v%3dws.10%29)
* [Because sometimes people learn better via video](https://www.youtube.com/watch?v=taUdRQHfjMQ)

## Notes
* I have found if you configure the **Allow access to this computer from the network** Group policy, IPSec policies will not work.  Or maybe I just did it wrong.
