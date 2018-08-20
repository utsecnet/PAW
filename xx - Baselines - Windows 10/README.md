# Warning about Baselines

***WARNING***: *You cannot simply take the baselines and bolt them on into your environment!  Some of these settings may not be compatible with your environment.  You must read through the individual settings and understand what is happening.  If you are unsure what the effect will be, either test it or don't enable it (but note that you are not enabling it). You are the admin in your domain.  Not me.*

## What is this?
We will be applying the CIS baselines to Windows 10 client computers.  I have broken the baseline up into several GPOs for the ease of troubleshooting potential issues.  The GPOS are:

* Admin Templates
* Security settings
* System services
* User Rights Assignments
* Windows Firewall
* Users

## Prerequisites
* Ensure you have a functioning Shadow Group script
* Download the latest Windows 10 and Server 2016 CIS benchmarks from https://www.cisecurity.org/cis-benchmarks/.  These will be in PDF form.
* Read through these and understand what each setting does.  You will, on occasion need to make an exception.  You need to understand your environment and what these settings do.  
* I would recommend printing it out.  Yes, it will take hundreds of pieces of paper.  But it will make it easier to bookmark and note.
* Alternatively, you can use the attached *CIS baseline checklist.xlsx* file as a means to track your progress.  The downside is this file does not auto update when a new baseline is released.

## A note on GPO processing Order

GPOs are processed in a very specific order.  Generally, you want to apply the Default Domain Policy first, and then your Baseline policies, and finally everything else.  Remember this when you are creating your various policies because when you create a new policy, GPMC creates it at the bottom of the **Linked Group Policy Objects** list, which means it will be over-written by all the above polices. To summarize:

* Default Group Policy (DGP) goes at the bottom
* Baselines go above the DGP
* Everything Else goes above the baselines

## WMI Filters

Create a WMI filter for Windows 10:  
1. Navigate to ***GPMC > Forest > Domains > Company.com > WMI Filters***.
2. Right click > New...
3. Name: **Windows 10**
4. Click Add
  1. Namespace: **root\CIMv2**
  2. Query: **select * from Win32_OperatingSystem where Name like "%Windows 10%"**

Create a WMI filter for Server 2016:
1. Navigate to ***GPMC > Forest > Domains > Company.com > WMI Filters***.
2. Right click > New...
3. Name: **Server 2016**
4. Click Add
  1. Namespace: **root\CIMv2**
  2. Query: **select * from Win32_OperatingSystem where Name like "%Server 2016%"**

## Win 10 - Admin Templates

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - CIS baseline - Win 10 - Admin Templates**.

***Computer Configuration > Policies > Administrative Templates***

Create each of the policies.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Ensure **Authenticated Users** is targeted from the **Security Filtering**.
* Apply the **Windows 10** WMI Filter

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Win 10 - Security Settings

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - CIS baseline - Win 10 - Security Settings**.

***Computer Configuration > Policies > Windows Settings > Security Settings***

Create each of the policies.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Ensure **Authenticated Users** is targeted from the **Security Filtering**.
* Apply the **Windows 10** WMI Filter

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Win 10 - System Services

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - CIS baseline - Win 10 - System Services**.

***Computer Configuration > Policies > Windows Settings > Security Settings > System Services***

Create each of the policies.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Ensure **Authenticated Users** is targeted from the **Security Filtering**.
* Apply the **Windows 10** WMI Filter

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Win 10 - User Rights Assignment

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - CIS baseline - Win 10 - System Services**.

***Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment***

Create each of the policies.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Ensure **Authenticated Users** is targeted from the **Security Filtering**.
* Apply the **Windows 10** WMI Filter

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Win 10 - Windows Firewall

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - CIS baseline - Win 10 - System Services**.

***Computer Configuration > Policies > Windows Settings > Security Settings > Windows Defender Firewall with Advanced Security***

Create each of the policies.

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Ensure **Authenticated Users** is targeted from the **Security Filtering**.
* Apply the **Windows 10** WMI Filter

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

## Win 10 - Users

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - CIS Baseline - Users**.

***User Configuration > Policies***

Create each of the policies.

Close the policy window.

On the scope tab:
* Ensure the Link to the Users OU is Enabled.  
* Ensure **Authenticated Users** is targeted from the **Security Filtering**.
* Ensure there are no WMI filters applied.

On the Details tab:
* Set GPO status to: **Computer configuration settings disabled**
