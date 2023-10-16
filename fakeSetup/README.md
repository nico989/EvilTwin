# Set up the Fake Rogue Access Point
Steps to be run as sudo:
1. Install dependencies and press always Yes
```bash
apt install dnsmasq iptables-persistent nginx
```
2. Stop dnsmasq:
```bash
systemctl stop dnsmasq
```
3. Move wpa_supplicant.conf to wpa_supplicat-wlan0.conf:
```bash
mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
```
4. Create /etc/wpa_supplicant/wpa_supplicant-wlan1.conf to set up the Access Point:
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="Internet4guests"
    mode=2
    key_mgmt=NONE
    frequency=2412
}
```
5. Add the following lines at the end of /etc/dhcpcd.conf:
```
interface wlan1
static ip_address=10.64.164.1/24
```
6. Enable IP forwarding:
```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```
7. Add the following iptables rules:
```bash
iptables -A INPUT -i wlan1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i wlan1 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i wlan1 -p udp --dport 67 -j ACCEPT
iptables -A INPUT -i wlan1 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i wlan1 -j REJECT
```
8. Create /etc/dnsmasq.conf:
```
listen-address=10.64.164.1
no-hosts
dhcp-range=10.64.164.50,10.64.164.150,12h
dhcp-option=option:router,10.64.164.1
dhcp-authoritative
dhcp-option=114,http://internet4guests

address=/#/10.64.164.1
```
9. Add the following at the end of /etc/default/dnsmasq:
```
DNSMASQ_EXCEPT=lo
```
10. Enable and Start dnsmasq:
```bash
systemctl enable dnsmasq
systemctl start dnsmasq
```

# Add Captive Portal
Steps to be run as sudo:
1. Remove /etc/nginx/sites-available/default with the default in the repo.
2. Add the internet4guests file to /etc/nginx/sites-available.
3. Create internet4guests nginx simlink:
```bash
ln -s /etc/nginx/sites-available/internet4guests /etc/nginx/sites-enabled/internet4guests
```
4. Install flask:
```bash
pip3 install flask
```
5. Run the Flask application:
```bash
python3 app.py > /dev/null &
```
6. Restart nginx:
```bash
systemctl restart nginx
```
