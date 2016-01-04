#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "This script should be run as root." > /dev/stderr
    exit 1
fi


FREE=`df -H | grep -E '^/dev/root' | awk '{ print $4 }' | cut -d'G' -f1 | awk -F '.' '{ print $1 }'`
if [[ $FREE -lt 1 ]]; then
  echo "Error: 1GB disk space required" > /dev/stderr
  exit 1
fi

KERNEL=$(uname -r)

clear
echo "--------------------------------------------------------------------------------"
echo ""
echo "                        emPC-A/RPI driver installer  "
echo ""
echo "Minimum system requirements:"
echo "- emPC-A/ARPI hardware version 1.1 or later"
echo "- Kernel 3.18.16-v7+ or later (currently running: $KERNEL)"
echo "- Internet connection (about 150MB will be downloaded)"
echo "- 1GB free disk space"
echo "These drivers will be compiled and installed:"
echo "- CAN driver (SocketCAN)"
echo "- Serial driver (RS232/RS485)"
echo "These software components will be installed:"
echo "- libncurses5-dev, gcc, lib, autoconf, libtool, libsocketcan, can-utils"
echo "These configuration settings will automatically be made:"
echo "- Install SocketCAN in auto start"
echo "- Install RTC in auto start"
echo "- Disable SWAP"
echo "- Increase USB max. current"
echo "- Enable I2C and SPI drivers"
echo "- Set Green LED as SD card activity LED"
echo "--------------------------------------------------------------------------------"
echo ""
echo "Import: create a backup copy of the system before starting this installation!"
echo ""
read -p "Continue installation (y/n)?" CONT
if [ "$CONT" == "y" ] || [ "$CONT" == "j" ]; then
        echo -n "starting installation in";
        sleep 1 && echo -n " (3) "
        sleep 1 && echo -n " (2) "
        sleep 1 && echo -n " (1) "
        echo ""
else
        echo "Info: installation canceled" 1>&2
        exit 2
fi


wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/imageversion.txt -O /root/imageversion.txt

# get installed gcc version
GCCVERBACKUP=$(gcc --version | egrep -o '[0-9]+\.[0-9]+' | head -n 1)
# get gcc version of installed kernel
GCCVER=$(cat /proc/version | egrep -o 'gcc version [0-9]+\.[0-9]+' | egrep -o '[0-9.]+')

apt-get update -y
apt-get -y install libncurses5-dev
apt-get -y install gcc-$GCCVER g++-$GCCVER

if [ ! -f "/usr/bin/gcc-$GCCVER" ] || [ ! -f "/usr/bin/g++-$GCCVER" ]; then
    echo "no such version gcc/g++ $GCCVER installed" 1>&2
    exit 1
fi

update-alternatives --remove-all gcc 
update-alternatives --remove-all g++

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCCVERBACKUP 10
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCCVERBACKUP 10

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCCVER 50
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCCVER 50

update-alternatives --set gcc "/usr/bin/gcc-$GCCVER"
update-alternatives --set g++ "/usr/bin/g++-$GCCVER"

mkdir -p /home/pi/empc-arpi-linux-drivers
cd /home/pi/empc-arpi-linux-drivers

wget https://raw.githubusercontent.com/notro/rpi-source/master/rpi-source -O /usr/bin/rpi-source && chmod +x /usr/bin/rpi-source && /usr/bin/rpi-source -q --tag-update

rpi-source --skip-gcc
cd /root/linux-*
INSTALLDIR=$(pwd)

wget https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/arch/arm/boot/dts/overlays/sc16is7xx-ttysc0-overlay.dts -O arch/arm/boot/dts/overlays/sc16is7xx-ttysc0-overlay.dts
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/arch/arm/boot/dts/overlays/mcp2515-can0-overlay.dts -O arch/arm/boot/dts/overlays/mcp2515-can0-overlay.dts
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/drivers/spi/spi-bcm2835.c -O drivers/spi/spi-bcm2835.c
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/drivers/net/can/spi/mcp251x.c -O drivers/net/can/spi/mcp251x.c
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/drivers/tty/serial/sc16is7xx.c -O drivers/tty/serial/sc16is7xx.c


if grep -q "sc16is7xx" "arch/arm/boot/dts/overlays/Makefile"; then
        echo ""
else
        sed -i 's/mcp2515-can1-overlay/sc16is7xx-ttysc0-overlay/g' arch/arm/boot/dts/overlays/Makefile
fi

if grep -q "obj-m += sc16is7xx.o" "drivers/tty/serial/Makefile"; then
        echo ""
else
        echo "obj-m += sc16is7xx.o" >>drivers/tty/serial/Makefile
fi


make SUBDIRS=arch/arm/boot/dts/overlays modules
make SUBDIRS=drivers/tty/serial modules
make SUBDIRS=drivers/net/can modules
make SUBDIRS=drivers/spi modules

KERNEL=$(uname -r)

mkdir -p /lib/modules/$KERNEL/kernel/drivers/net/can/spi
mkdir -p /lib/modules/$KERNEL/kernel/drivers/tty/serial

rm -f /lib/modules/$KERNEL/kernel/drivers/net/can/spi/mcp251x.ko
rm -f /lib/modules/$KERNEL/kernel/drivers/tty/serial/sc16is7xx.ko
rm -f /lib/modules/$KERNEL/kernel/drivers/spi/spi-bcm2835.ko

cp arch/arm/boot/dts/overlays/sc16is7xx-ttysc0-overlay.dtb /boot/overlays/sc16is7xx-ttysc0-overlay.dtb
cp arch/arm/boot/dts/overlays/mcp2515-can0-overlay.dtb /boot/overlays/mcp2515-can0-overlay.dtb
cp drivers/spi/spi-bcm2835.ko /lib/modules/$KERNEL/kernel/drivers/spi/spi-bcm2835.ko
cp drivers/net/can/spi/mcp251x.ko /lib/modules/$KERNEL/kernel/drivers/net/can/spi/mcp251x.ko
cp drivers/tty/serial/sc16is7xx.ko /lib/modules/$KERNEL/kernel/drivers/tty/serial/sc16is7xx.ko

depmod -a


if [ ! -f "/lib/modules/$KERNEL/kernel/drivers/net/can/spi/mcp251x.ko" ] || [ ! -f "/lib/modules/$KERNEL/kernel/drivers/tty/serial/sc16is7xx.ko" ]; then
    echo "Error: Installation failed! (driver modules not installed)" 1>&2
    exit 7
fi

rm -rf $INSTALLDIR
rm -f $INSTALLDIR.tar.gz


# installing service to start can0 on boot
if [ ! -f "/bin/systemctl" ]; then
    echo "Warning: systemctl not found, cannot install can0.service" 1>&2
else
    wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/can0.service -O /lib/systemd/system/can0.service
    systemctl enable can0.service
fi


if grep -q "spi-bcm2835" "/boot/config.txt"; then
        echo ""
else
        echo "INFO: Enabling I2C in /boot/config.txt"
        echo "" >>/boot/config.txt
        echo "dtparam=i2c_arm=on" >>/boot/config.txt

        echo "INFO: Installing CAN and RS232/RS485 driver DT in /boot/cmdline.txt"
        echo "dtparam=spi=on" >>/boot/config.txt
        echo "dtoverlay=mcp2515-can0-overlay,oscillator=16000000,interrupt=25" >>/boot/config.txt
        echo "dtoverlay=spi-bcm2835-overlay" >>/boot/config.txt
        echo "dtoverlay=sc16is7xx-ttysc0-overlay" >>/boot/config.txt
        echo "dtoverlay=sdhost" >>/boot/config.txt
fi

if grep -q "sc16is7xx" "/etc/modules"; then
        echo ""
else
        echo "INFO: Installing RS232/RS485 driver module in /etc/modules"
        echo "sc16is7xx" >>/etc/modules
fi

if grep -q "sc16is7xx.RS485" "/boot/cmdline.txt"; then
        echo ""
else
        echo "INFO: Configuring green LED as microSD-card activity LED in /boot/cmdline.txt"
        sed -i 's/rootwait/rootwait bcm2709.disk_led_gpio=5 bcm2709.disk_led_active_low=0/g' /boot/cmdline.txt

        echo "INFO: setting RS232/RS485 mode based on jumper J301 in /boot/cmdline.txt"
        sed -i 's/rootwait/rootwait sc16is7xx.RS485=2/g' /boot/cmdline.txt
fi


if grep -q "ssh_host_dsa_key" "/etc/rc.local"; then
        echo ""
else
        echo "INFO: Installating SSH key generation /etc/rc.local"
        sed -i 's/exit 0//g' /etc/rc.local
        echo "test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server" >>/etc/rc.local
        echo "exit 0" >>/etc/rc.local
fi


echo "INFO: Installating RTC hardware clock"
# disable fake clock (systemd)
systemctl disable fake-hwclock

# disable fake clock (init.d)
service fake-hwclock stop
apt-get -y remove fake-hwclock
rm -f /etc/cron.hourly/fake-hwclock
rm -f /etc/init.d/fake-hwclock
update-rc.d fake-hwclock remove


# enable hwclock (systemd)
rm -f /lib/systemd/system/hwclock.service
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/hwclock.service -O /lib/systemd/system/hwclock.service
systemctl enable hwclock

# init hwclock (init.d)
if grep -q "mcp7940x 0x6f" "/etc/init.d/hwclock.sh"; then
        echo ""
else
    sed -i 's/unset TZ/echo mcp7940x 0x6f > \/sys\/class\/i2c-adapter\/i2c-1\/new_device/g' /etc/init.d/hwclock.sh
fi
update-rc.d hwclock.sh enable




if grep -q "max_usb_current=1" "/boot/config.txt"; then
        echo ""
else
        echo "" >>/boot/config.txt
        echo "INFO: Configuring USB max current in /boot/config.txt"
        echo "max_usb_current=1" >>/boot/config.txt

        echo "INFO: Enabling green LED as microSD activity LED"
        echo "dtparam=act_led_gpio=5" >>/boot/config.txt
fi

if grep -q "triple-sampling" "/etc/network/interfaces"; then
        echo ""
else
        echo "INFO: Configuring auto start can0 at 500KBit in /etc/network/interfaces"
        echo "" >>/etc/network/interfaces
        echo "allow-hotplug can0" >>/etc/network/interfaces
        echo "iface can0 inet manual" >>/etc/network/interfaces
        echo -e "\tpre-up /sbin/ip link set can0 type can bitrate 500000 triple-sampling on" >>/etc/network/interfaces
        echo -e "\tup /sbin/ifconfig can0 txqueuelen 1000" >>/etc/network/interfaces
        echo -e "\tup /sbin/ifconfig can0 up" >>/etc/network/interfaces
        echo -e "\tdown /sbin/ifconfig can0 down" >>/etc/network/interfaces
fi



if [ ! -f "/usr/local/bin/cansend" ]; then

    echo ""
    echo "INFO: installing SocketCAN (libsocketcan) libraries and can-utils"
    echo ""
    
    apt-get -y install git
    apt-get -y install autoconf
    apt-get -y install libtool

    cd /home/pi
    
    wget http://www.pengutronix.de/software/libsocketcan/download/libsocketcan-0.0.10.tar.bz2
    tar xvjf libsocketcan-0.0.10.tar.bz2
    rm -rf libsocketcan-0.0.10.tar.bz2
    cd libsocketcan-0.0.10
    ./configure && make && make install

    cd /home/pi

    git clone https://github.com/linux-can/can-utils.git
    cd can-utils
    ./autogen.sh
    ./configure && make && make install

fi

update-alternatives --set gcc "/usr/bin/gcc-$GCCVERBACKUP"
update-alternatives --set g++ "/usr/bin/g++-$GCCVERBACKUP"




echo
echo
echo "INFO: Installation completed! restart required!"
echo

