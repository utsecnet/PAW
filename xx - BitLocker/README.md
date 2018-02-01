## What is this?
Bitlocker is drive encryption software. Configuring BitLocker includes setting up the backend policies, then manually enabling BitLocker on the device.  That is, unless you deploy an MBAM server in your environment.  That process is outside the scope of this document as it has been [fully documented on TechNet]https://docs.microsoft.com/en-us/microsoft-desktop-optimization-pack/mbam-v25/deploying-the-mbam-25-server-infrastructure).

## Configure AD
1. [Download the BitLocker scripts](https://technet.microsoft.com/en-us/library/dn466534.aspx#Sample#scripts) to your DC.
2. On the DC, run CMD as administrator
	```
	C:\ >cscript Add-TPMSelfWriteACE.vbs
	Microsoft (R) Windows Script Host Version 5.812
	Copyright (C) Microsoft Corporation. All rights reserved.

	Accessing object: DC=UPWELL,DC=COM
	SUCCESS!
	```
3. Delegate msTPM-OwnerInformation
	1. Open ADUC
	2. Navigate to the OU where all your Workstations are stored
	3. Right Click on it > Delegate Control...
	4. Click Next on the welcome screen
	5. Click Add... button
	6. Type SELF, hit the Check Names button, and click OK
	7. Click Next
	8. Click Create a custom task to delegate and click Next
	9. Check Only the following objects in the folder, check Computer Objects, click next
	10. Check Property-specific, scroll down and find Write msTPM-OwnerInformation and click Next
	11. Click Finish

## Add the MBAM Files to your Central Store
[Learn more about what a Central Store is](https://support.microsoft.com/en-us/help/3087759/how-to-create-and-manage-the-central-store-for-group-policy-administra).  You should be using it.

[Download the MDOP Policy Templates](https://www.microsoft.com/en-us/download/details.aspx?id=55531), and move ONLY the MBAM template files to your central store.  [Click here](https://docs.microsoft.com/en-us/microsoft-desktop-optimization-pack/mbam-v25/copying-the-mbam-25-group-policy-templates) to learn how.

## Configure Group Policy
Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - AppLocker - PAW** with the following settings:

***Computer Configuration > Policies > Admin Templates > System > Trusted Platform Module Services***
* Configure the system to use legacy Dictionary Attack Prevention Parameters settings for TPM 2.0: **Enabled**
* Standard User individual lockout threshold: **Enabled**
	* Maximum number of authentication failures per duration: **5**
* Standard user lockout duration: **Enabled**
	* Duration for counting TPM authorization failures (minutes): **2**
* Standard user total lockout threshold: **Enabled**
	Maximum number of authorization failures per duration: **5**

***Computer Configuration > Policies > Admin Templates > Windows Components > BitLocker Drive Encryption***
* Chose drive encryption method...Windows 10 1511 and later: **Enabled**
	* Select the encryption method of OS drives: **XTS-AES 256-bit**
	* Select the encryption method of fixed data drives: **XTS-AES 256-bit**
	* Select the encryption method of Removable data drives: **AES-CBC 256-bit**
* Choose drive encryption method...Windows 8...Windows 10 1507: **Enabled**
	* Select the encryption method: AES 256-bit
* Disable new DMA devices when this computer is locked: **Enabled**
* Store BitLocker recovery information in AD: **Enabled**
	* Require BitLocker backup to AD DS: **Enabled**

***Computer Configuration > Policies > Admin Templates > Windows Components > BitLocker Drive Encryption > Fixed Data Drives***
* Configure use of hardware encryption for fixed data drives: **Enabled**
	* Use BitLocker software-based encryption whn hardware encryption not available: **Enabled**
	* Restrict encryption algorithm... **Disabled**
	* Restrict crypto...: (Keep default settings)
* Enforce drive encryption type on fixed data drives: **Enabled**
	* Select the encryption type: Full encryption

***Computer Configuration > Policies > Admin Templates > Windows Components > BitLocker Drive Encryption > Fixed Data Drives***
* Configure use of hardware encryption for fixed data drives: **Enabled**
	* Use BitLocker software-based encryption whn hardware encryption not available: **Enabled**
	* Restrict encryption algorithm... **Disabled**
	* Restrict crypto...: (Keep default settings)
* Configure use of smart cards on removable data drives: **Enabled**
	* Require...: **Disabled** (We don't use smart cards)
* Enforce drive encryption type on removable data drives: **Enabled**
	* Select the encryption type: Full encryption

### If you do not see the following GPO Paths, it is because you did not import the MBAM policy templates into your central store and refresh GPMC.

***Computer Configuration > Policies > Admin Templates > Windows Components > BitLocker Drive Encryption > Fixed Data Drives***





Coming soon

Configure Domain Controllers
         
Install the Bitlocker Drive Encryption Feature on your DCs

      1- In Server Manager > Add Roles and Features
      2- Go through the Wizard to the Features page, and add the Bitlocker Drive Encryption feature
      3- Finish

Configure Pre-Existing Encrypted Clients
         
Push existing BitLocker protected machines to AD (OPTIONAL)

      1- On the client machine, opne CMD as administrator, and run the following command:
         
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
C:\> Manage-bde -protectors -adbackup c: -id {your numerical password ID}
...
Recovery information was successfully backed up to Active Directory.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      2- Verify in ADUC, find the computer, Right click > properties > BitLocker Recovery
