# Evil Twin and Captive Portal with Raspberry PI

## Hardware
- Raspberry PI 3B+.
- Integrated Raspberry WiFi.
- WiFi dongle Edimax or Ethernet connection.

## Active Rogue Access Point
The end user has fully Internet connectivity with the following setup. Credentials are stored by default in the file /tmp/captivePortalLog.txt when the end user inputs them.
<br/>
Assuming:
- wlan0 Internet connected.
- wlan1 interface to be set up as Access Point.
<br/>

The manual steps are at activeSetup/README.md.

To run the setup script:
```bash
chmod +x activeSetup/activeSetup.sh
./activeSetup/activeSetup.sh
```
Dependencies:
- hostapd: turn Raspberry PI into an Access Point.
- dnsmasq: set up DHCP and DNS for the Access Point.
- nodogsplash: for the Captive Portal.

## Fake Rogue Access Point
The end user does NOT have Internet connectivity with the following setup. Credentials are stored by default in the file /tmp/captivePortalLog.txt when the end user inputs them.
<br/>
Assuming:
- wlan0 Internet connected.
- wlan1 interface to be set up as Access Point.
<br/>

The manual steps are at fakeSetup/README.md.

To run the setup script:
```bash
chmod +x fakeSetup/fakeSetup.sh
./fakeSetup/fakeSetup.sh
```
Dependencies:
- dnsmasq: sets up DHCP and DNS for the fake Access Point.
- nginx: serves the Captive Portal.
- flask: used to build the Captive Portal.

## Credits
- PiMyLife: https://pimylifeup.com/raspberry-pi-wireless-access-point/
- nodogsplash: https://github.com/nodogsplash/nodogsplash
- rogueportal: https://github.com/jerryryle/rogueportal

## TODO:
- Improve scripts quality coding a proper menù.
- Add deauthentication/jamming attack.
