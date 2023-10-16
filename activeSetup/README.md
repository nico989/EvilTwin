# Set up the Active Rogue Access Point
Steps to be run as sudo:
1. Upgrade and update:
```bash
apt update && apt upgrade -y
```
2. Install hostapd, dnsmasq, iptables:
```bash
apt install hostapd dnsmasq iptables -y
```
3. Stop hostapd and dnsmasq:
```bash
systemctl stop hostapd
systemctl stop dnsmasq
```
4. Add at the end of /etc/dhcpcd.conf and restart dhcpcd:
```
interface wlan1
static ip_address=10.64.164.1/24
nohook wpa_supplicant
```
5. Restart dhcpcd:
```bash
systemctl restart dhcpcd
```
6. Create hostapd.conf:
```
interface=wlan1
driver=nl80211
hw_mode=g
ieee80211n=1
wmm_enabled=0
macaddr_acl=0
ignore_broadcast_ssid=0
channel=6
ssid=Internet4guests
```
7. Set hostapd.conf file in /etc/default/hostapd:
```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```
8. Create a new dnsmasq.conf:
```bash
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
```
```
interface=wlan1
server=10.64.164.1
dhcp-range=10.64.164.50,10.64.164.150,12h
```
9. Enable IP forwarding:
```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```
10. IPTables to redirect and mask all AP traffic to wlan0:
```bash
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
```
11. Start hostapd and dnsmask:
```bash
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd
service dnsmasq start
```

# Add Captive Portal
Steps to be run as sudo:
1. Install nodogsplash dependencies packages:
```bash
apt install debhelper dpkg-dev libmicrohttpd-dev -y
```
2. Clone and compile nodogsplash repo:
```bash
git clone https://github.com/nodogsplash/nodogsplash.git /opt/nodogsplash
cd /opt/nodogsplash
make
make install
```
3. Move auth.sh under /etc/nodogsplash:
```bash
mv auth.sh /etc/nodogsplash
chmod +x /etc/nodogsplash/auth.sh
```
4. Update /etc/nodogsplash/nodogsplash.conf:
```
GatewayInterface wlan1
GatewayName Internet4guests
GatewayAddress 10.64.164.1
RedirectURL https://www.google.com/
BinAuth /etc/nodogsplash/auth.sh
```
5. Update /etc/nodogsplash/htdocs to change Captive Portal HTML page:
```bash
rm -R /etc/nodogsplash/htdocs
mv htdocs/ /etc/nodogsplash
```
6. Start nodogsplash:
```bash
nodogsplash
```
