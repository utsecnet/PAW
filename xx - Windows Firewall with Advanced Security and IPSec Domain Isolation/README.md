## What is this?
We want to ensure that the only traffic entering a PAW is traffic we can verify comes from a source that is trusted.  This typically includes all equivallent Tier traffic and higher.  For example, a Tier 0 PAW should only allow inbound traffic from Tier 0 devices.  A Tier 1 PAW should only allow inbound traffic from Tier 1 device and Tier 0 devices.  It might even be said that the only traffic that should be allowed to all PAWs is authenticated traffic from Tier 0 devices only.  It depends on your environment.

To authenticate traffic means we must use IPSec to ensure traffic comes from specific devices and/or users.  This means rules based on IP address are out!

NOTE: It is outside the scope of this document to explain how IPSec works in Windows Firewall.  Go Google stuff.

# Word of Warning

### Regarding Domain Controllers
It is important to know that IPSec rules can be configured to *require inbound/outbound authentication* or *request inbound/outbound authentication*.  If you require authentication on the domain controllers, you will most likely kill all network traffic to and from devices that are not joined to the domain.  Don't do this.  Ensure any policy that is set on the domain controllers is configured to *request inbound/outbound authentication* only.

### Regarding Require vs. Request
Due to the nature of how machines refresh group policy (randomly at 90-120 minuted intervals) it is recommended that you set all your policies to request inbound and outbound authentication first.  If you require first, It will be likely that machines will not have received the update and authentication will fail authentication, effectivly stopping network traffic.  Only after you have confirmed all machines are authenticating correctly, set the policies to require.

## Firewall Policies on Domain Controllers



## Firewall Policies on PAWs