#!/bin/bash

if [[ $EUID -ne 0 ]];
then
   echo "This script must be run as root"
   exit 1
fi

APIFACE="wlan1"
APIP="10.64.164.1"
APINET="10.64.164.1/24"
SSID="Internet4Guests"
APIPRANGE="10.64.164.50,10.64.164.150"
DOMAIN="internet4guests"

printf "Updating and Upgrading\n"
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
 
printf "Install dependencies and press always Yes\n"
apt install dnsmasq iptables nginx -y > /dev/null 2>&1

printf "Stop dnsmasq\n"
systemctl stop dnsmasq

printf "Move wpa_supplicant.conf to wpa_supplicat-wlan0.conf\n"
mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

printf "Create wpa_supplicant-wlan1.conf to set up the Access Point"
cat > /etc/wpa_supplicant/wpa_supplicant-wlan1.conf << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=SE

network={
    ssid=$SSID
    mode=2
    key_mgmt=NONE
    frequency=2412
}
EOF

printf "Update /etc/dhcpcd.conf and restart dhcpcd\n"
printf "interface %s\n\tstatic ip_address=%s\n" $APIFACE $APINET >> /etc/dhcpcd.conf
systemctl restart dhcpcd

printf "Enable IP forwarding\n"
echo 1 > /proc/sys/net/ipv4/ip_forward

printf "Add the iptables rules:\n"
iptables -A INPUT -i $APIFACE -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i $APIFACE -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i $APIFACE -p udp --dport 67 -j ACCEPT
iptables -A INPUT -i $APIFACE -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i $APIFACE -j REJECT

printf "Create dnsmasq.conf\n"
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat > /etc/dnsmasq.conf << EOF
listen-address=$APIP
no-hosts
dhcp-range=$APIPRANGE,12h
dhcp-option=option:router,$APIP
dhcp-authoritative
dhcp-option=114,http://$DOMAIN

address=/#/$APIP
EOF

printf "Update /etc/default/dnsmasq\n"
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i "s/#DNSMASQ_EXCEPT=lo/DNSMASQ_EXCEPT=lo/g" /etc/default/dnsmasq

printf "Enable and Start dnsmasq\n"
systemctl enable dnsmasq
systemctl start dnsmasq

printf "Set up default nginx configuration\n"
rm /etc/nginx/sites-available/default
mv ./nginx/default /etc/nginx/sites-available/default

printf "Add internet4guests nginx configuration\n"
mv ./nginx/$DOMAIN /etc/nginx/sites-available/$DOMAIN

printf "Create internet4guests nginx simlink\n"
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

printf "Install flask\n"
pip3 install flask > /dev/null 2>&1

printf "Run Flask application in background\n"
mv flask/ /var/www/html/
python3 /var/www/html/app.py > /dev/null 2>&1 &

printf "Restart nginx"
systemctl restart nginx

read -r -p "Do you want to persist the actual settings?[y/n]" CHOICE
if [[ $CHOICE == [yY] ]];
then
   printf "Persist IP forwarding in sysctl.conf\n"
   sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf

   printf "Save iptables\n"
   iptables-save > /etc/iptables.ipv4.rules

   printf "Persist flaks and iptables in rc.local\n"
   sed -i "s/exit 0/iptables-restore < \/etc\/iptables.ipv4.rules\npython3 \/var\/www\/html\/app.py > \/dev\/null &\nexit 0\n/g" /etc/rc.local

   exit 0
elif [[ $CHOICE == [nN] ]];
then
   printf "Configuration done WITHOUT persistency.\n"
   exit 0
else
   printf "Wrong choice.\n"
   exit 1
fi
