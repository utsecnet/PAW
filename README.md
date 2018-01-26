## Privileged Access Workstation (PAW)

**What is a PAW?**

In short, a PAW is one solution to the problem of credential theft, replay and pivoting attacks, and privilege escalation.  PAW is a method of administrating network devices in a more secure and more hardend environment than what most admins are used to.  

**Okay, but what is a PAW?**

A PAW is the workstation the admin uses to administrate the network.  It adhears to the [Clean Source Security Principal](https://docs.microsoft.com/en-us/windows-server/identity/securing-privileged-access/securing-privileged-access-reference-material#CSP_BM).  It allows outbound connections to 







Q: What is the purpose of this repository?
A: To provide Systems and Security Administrators a resource for building out their PAW environment.  This repository has several scripts, GPO settings, and tutorials that will guide you to building a baseline PAW deployment adhearing to the Clean Source Principal.

Q: What is a PAW?
A: https://4sysops.com/archives/understand-the-microsoft-privileged-access-workstation-paw-security-model/



Micorosoft has provided several baseline resources for aiding administrators setting up a PAW environment.  These files can be found here:

https://gallery.technet.microsoft.com/Privileged-Access-3d072563

However, they have negelected to release the windows firewall configuration settings, which is pivital in adhearing to the Clean Source Principal.

The prupose of these files is to provide PAW administrators a functional baseline firewall configuration that only permits inbound authenticated traffic from other Tier 0 servers and devices.  This is done using IPSec with Windows Defender Firewall with Advanced Security.

What is a PAW? 

