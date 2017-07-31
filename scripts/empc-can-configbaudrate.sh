#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "This script should be run as root." > /dev/stderr
    exit 1
fi

BAUDRATE=$(whiptail --title "Configure CAN baudrate" --radiolist \
"What is the baudrate of your CAN bus?" 15 60 8 \
"1000" "1000 kBit/s (not recommended)" OFF \
"500" "500 kBit/s" OFF \
"250" "250 kBit/s (default)" ON \
"125" "125 kBit/s" OFF \
"100" "100 kBit/s" OFF \
"50" "50 kBit/s" OFF \
"20" "20 kBit/s" OFF \
"10" "10 kBit/s" OFF 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ]; then

    while read -r line
    do
     [[ ! $s =~ can0 ]] && echo "$line"
    done </etc/network/interfaces > /tmp/interfaces
    mv /tmp/interfaces /etc/network/interfaces

    echo "# can0" >>/etc/network/interfaces
    echo "allow-hotplug can0" >>/etc/network/interfaces
    echo "iface can0 inet manual" >>/etc/network/interfaces
    echo -e "\tpre-up /sbin/ip link set can0 type can bitrate $BAUDRATE""000 triple-sampling on" >>/etc/network/interfaces
    echo -e "\tup /sbin/ifconfig can0 txqueuelen 1000" >>/etc/network/interfaces
    echo -e "\tup /sbin/ifconfig can0 up" >>/etc/network/interfaces
    echo -e "\tdown /sbin/ifconfig can0 down" >>/etc/network/interfaces

fi
