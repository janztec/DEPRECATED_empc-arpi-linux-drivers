#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "This script should be run as root." > /dev/stderr
    exit 1
fi

if grep -q "ttySC" "/etc/CODESYSControl.cfg"; then
        echo ""
else
    echo "INFO: configuring COMPORT1 to /dev/ttySC0"

    echo "" >>/etc/CODESYSControl.cfg
    echo "[SysCom]" >>/etc/CODESYSControl.cfg
    echo "Linux.Devicefile=/dev/ttySC" >>/etc/CODESYSControl.cfg
    echo "portnum := COM.SysCom.SYS_COMPORT1;" >>/etc/CODESYSControl.cfg  
fi    

if grep -q "CmpSocketCanDrv" "/etc/CODESYSControl.cfg"; then
        echo ""
else
    echo "" >>/etc/CODESYSControl.cfg
    echo "[CmpSocketCanDrv]" >>/etc/CODESYSControl.cfg
    echo "ScriptPath=/root/" >>/etc/CODESYSControl.cfg
    echo "ScriptName=rts_set_baud.sh" >>/etc/CODESYSControl.cfg
fi

if grep -q "armv6l" "/etc/CODESYSControl.cfg"; then
        echo ""
else
    echo "INFO: using CODESYS in single core mode"
    echo "" >>/etc/CODESYSControl.cfg
    echo "[CmpRasPi]" >>/etc/CODESYSControl.cfg
    echo "Architecture=armv6l" >>/etc/CODESYSControl.cfg
fi

sed -i 's/armv7l/armv6l/' /etc/CODESYSControl_User.cfg || true

echo "INFO: installing rts_set_baud.sh"

echo "#!/bin/sh" >/root/rts_set_baud.sh
echo "BITRATE=\`expr \$2 \\* 1000\`" >>/root/rts_set_baud.sh
echo "ifconfig can0 down">>/root/rts_set_baud.sh
echo "sleep 1">>/root/rts_set_baud.sh
echo "/sbin/ip link set can0 type can bitrate \$BITRATE triple-sampling on">>/root/rts_set_baud.sh
echo "/sbin/ifconfig can0 txqueuelen 1000">>/root/rts_set_baud.sh
echo "/sbin/ifconfig can0 up">>/root/rts_set_baud.sh
chmod 755 /root/rts_set_baud.sh

echo "INFO: disabling i2c and spi modules in /etc/modules"
sed -i 's/spi-bcm2708/#spi-bcm2708/g' /etc/modules
sed -i 's/i2c-bcm2708/#i2c-bcm2708/g' /etc/modules
sed -i 's/i2c-dev/#i2c-dev/g' /etc/modules

echo "INFO: disabling can0 startup service"
sed -i 's/pre-up \/sbin\/ip link set can0/#pre-up \/sbin\/ip link set can0/g' /etc/network/interfaces
sed -i 's/up \/sbin\/ifconfig can0/#up \/sbin\/ifconfig can0/g' /etc/network/interfaces
sed -i 's/down \/sbin\/ifconfig can0/#down \/sbin\/ifconfig can0/g' /etc/network/interfaces

systemctl disable can0.service
systemctl mask can0.service
