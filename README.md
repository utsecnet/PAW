##FAQ

Q: What is the purpose of this repository?
A: To provide Systems and Security Administrators a resource for building out their PAW environment.  This repository has several scripts, GPO settings, and tutorials that will guide you to building a baseline PAW deployment adhearing to the Clean Source Principal.

Q: What is a PAW?
A: https://4sysops.com/archives/understand-the-microsoft-privileged-access-workstation-paw-security-model/



Micorosoft has provided several baseline resources for aiding administrators setting up a PAW environment.  These files can be found here:

https://gallery.technet.microsoft.com/Privileged-Access-3d072563

However, they have negelected to release the windows firewall configuration settings, which is pivital in adhearing to the Clean Source Principal.

The prupose of these files is to provide PAW administrators a functional baseline firewall configuration that only permits inbound authenticated traffic from other Tier 0 servers and devices.  This is done using IPSec with Windows Defender Firewall with Advanced Security.

What is a PAW? 

