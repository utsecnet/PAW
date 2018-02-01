## What is this?
With traditional AV, typically a central console would have access to the endpoint with an agent that is running with administrative permissions on the endpoint.  This means that the console has indirect administrative access to the endpoint.  In the world of PAWs, this would require us to treat the central console as a Tier 0 server, and up our protections (cost) to bring that server in the same tier as our domain controllers.  

With all the surrounding security controls (e.g., AppLocker software white list, log on restrictions, etc...) I recommend sticking with Windows Defender (1709 or greater).  1709 came out with many additional security features that enhance the product and offer more of a competitive edge with other AV vendors.  Things like extended EMET protection, protected folders, and such.

## Group Policy

Create a new GPO on the DOMAIN.COM\Company\Users\PAW Accounts OU called **Security - Windows Defender - PAW** with the following settings:

***Computer Configuration > Policies > Admin Templates > System > Device Guard***
* Turn on Virtualization Based Security: **Enabled**
    * Select Platform Security level: **Secure Boot and DMA Protection**
    * Virtualization Based protection of code: **Cont configured**
    * Require UEFI memory attributes table: **Disabled**
    * Credential Guard Configuration: **Enabled with UEFI lock**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus***
* Turn off Windows Defender anti-virus: **Disabled**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Client interface***
* Display additional text to clients when they need to perform an action: **With great power comes great fun!**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > MAPS***
* Send sample files...: **Disabled**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Network Inspection System***
* Turn on definition retirement: **Enabled**
* Turn on protocol recognition: **Enabled**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Real-time protection***
* Monitor file and program activity...: **Enabled**
* Scan all downloaded files and attachments: **Enabled**
* Turn off real-time protection: **Disabled**
* Turn on behavior monitoring: **Enabled**
* Turn on process scanning whenever real-time protection is enabled: **Enabled**
* Turn on raw volume write notifications: **Enabled**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Scan***
* Allow user to pause scan: **Enabled**
* Check for the latest virus and spy-ware definitions before running a scan: **Enabled**
* Run full scan on mapped network drives: **Disabled**
* Scan archived files: **Enabled**
* Scan network files: **Disabled**
* Scan packed executables: **Enabled**
* Scan removable drives: **Enabled**
* Specify the maximum percentage of CPU...: **Enabled**
    * **20%**
* Turn on catch-up full scan: **Enabled**
* Turn on catch-up quick scan: **Enabled**
* Turn on heuristics: **Enabled**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Signature Updates***
* Define number of days before spy-ware definitions are out of date: **Enabled**
    * **7**
* Define number of days before virus definitions are out of date: **Enabled**
    * **7**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Windows Defender Exploit Guard > Controlled Folder Access***
* Configure the guard my folders feature: **Enabled**
* Configure protected folders: **Enabled**
    * **%userprofile%**
    * **C:\Users\Public**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > App and browser protection***
* Prevent users from modifying settings: **Enabled**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Enterprise Customization***
* Configure custom contact info: **Enabled**
* Configure custom notification: **Enabled**
* Specify contact company name: **Enabled**
    * Company Name: **Company**
* Specify contact email address: **Enabled**
    * **helpdesk@company.com**

***Computer Configuration > Policies > Admin Templates > Windows Components > Windows Defender Antivirus > Family Options***
* Hide the family options area: **Enabled**

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **PAW-AllPAWComputers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.