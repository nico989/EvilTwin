#!/bin/bash

if [[ $EUID -ne 0 ]];
then
   printf "This script must be run as root"
   exit 1
fi

APIFACE="wlan1"
APIP="10.64.164.1"
APINET="10.64.164.1/24"
SSID="Internet4Guests"
APIPRANGE="10.64.164.50,10.64.164.150"
ACTIVEIFACE="wlan0"

printf "Updating and Upgrading\n"
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1

printf "Install hostapd, dnsmasq, iptables\n"
apt install hostapd dnsmasq iptables -y > /dev/null 2>&1

printf "Stop hostapd and dnsmasq\n"
systemctl stop hostapd
systemctl stop dnsmasq

printf "Update /etc/dhcpcd.conf and restart dhcpcd\n"
printf "interface %s\n\tstatic ip_address=%s\n\tnohook wpa_supplicant\n" $APIFACE $APINET >> /etc/dhcpcd.conf
systemctl restart dhcpcd

printf "Create hostapd.conf\n"
cat > /etc/hostapd/hostapd.conf << EOF
interface=$APIFACE
driver=nl80211
hw_mode=g
ieee80211n=1
wmm_enabled=0
macaddr_acl=0
ignore_broadcast_ssid=0
channel=6
ssid=$SSID
EOF

printf "Set hostapd.conf file in /etc/default/hostapd\n"
sed -i "s/#DAEMON_CONF=\"\"/DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"/g" /etc/default/hostapd

printf "Create dnsmasq.conf\n"
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat > /etc/dnsmasq.conf << EOF
interface=$APIFACE  
server=$APIP
dhcp-range=$APIPRANGE,12h
EOF

printf "Enable IP forwarding\n"
echo 1 > /proc/sys/net/ipv4/ip_forward

printf "IPTables to redirect and mask all AP traffic to wlan0 connection\n"
iptables -t nat -A POSTROUTING -o $ACTIVEIFACE -j MASQUERADE

printf "Start hostapd and dnsmask\n"
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd
systemctl start dnsmasq

printf "Install nodogsplash dependencies packages\n"
apt install debhelper dpkg-dev libmicrohttpd-dev -y > /dev/null

printf "Clone and compile nodogsplash repo\n"
git clone https://github.com/nodogsplash/nodogsplash.git /opt/nodogsplash > /dev/null
cd /opt/nodogsplash || exit 1
make > /dev/null
make install > /dev/null

printf "Move auth.sh under /etc/nodogsplash\n"
mv auth.sh /etc/nodogsplash/
chmod +x /etc/nodogsplash/auth.sh

printf "Update /etc/nodogsplash/nodogsplash.conf\n"
sed -i "s/GatewayInterface br-lan/GatewayInterface $APIFACE/g" /etc/nodogsplash/nodogsplash.conf
sed -i "s/GatewayName NoDogSplash/GatewayName $SSID/g" /etc/nodogsplash/nodogsplash.conf
sed -i "s/# GatewayAddress 192.168.1.1/GatewayAddress $APIP/g" /etc/nodogsplash/nodogsplash.conf
sed -i "s/# RedirectURL http:\/\/www.ilesansfil.org\//RedirectURL https:\/\/www.google.com\//g" /etc/nodogsplash/nodogsplash.conf
sed -i "s/# BinAuth \/bin\/myauth.sh/BinAuth \/etc\/nodogsplash\/auth.sh/g" /etc/nodogsplash/nodogsplash.conf

printf "Update /etc/nodogsplash/htdocs/splash.html to change Captive Portal HTML Page\n"
rm -R /etc/nodogsplash/htdocs
mv htdocs/ /etc/nodogsplash

printf "Start nodogsplash\n"
nodogsplash

read -r -p "Do you want to persist the actual settings?[y/n]" CHOICE
if [[ $CHOICE == [yY] ]];
then
   printf "Persist IP forwarding in sysctl.conf\n"
   sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf

   printf "Save iptables\n"
   iptables-save > /etc/iptables.ipv4.nat

   printf "Persist hostapd, iptables and nodogsplash in rc.local\n"
   sed -i "s/exit 0/sudo hostapd \/etc\/hostapd\/hostapd.conf \&\niptables-restore < \/etc\/iptables.ipv4.nat\nnodogsplash\nexit 0\n/g" /etc/rc.local

   exit 0
elif [[ $CHOICE == [nN] ]];
then
   printf "Configuration done WITHOUT persistency.\n"
   exit 0
else
   printf "Wrong choice.\n"
   exit 1
fi
