#!/bin/bash

export LC_ALL=C

REPORAW="https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master"

ERR='\033[0;31m'
INFO='\033[0;32m'
NC='\033[0m' # No Color

if [ $EUID -ne 0 ]; then
    echo -e "$ERR ERROR: This script should be run as root. $NC" 1>&2
    exit 1
fi

lsb_release -a 2>1 | grep "Raspbian GNU/Linux" || (echo -e "$ERR ERROR: Raspbian GNU/Linux required! $NC" 1>&2; exit 1;)

KERNEL=$(uname -r)

KERNELMAJ=$(echo $KERNEL | cut -d. -f1)
KERNELMIN=$(echo $KERNEL | cut -d. -f2)
KERNELVER=$(($KERNELMAJ*100+$KERNELMIN));

if [ $KERNELVER -le 408 ]; then
 
 echo -e "$ERR WARNING: kernel is outdated - $NC" 1>&2
 if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "WARNING: kernel is outdated ($KERNEL < 4.9.0)\n\nDo you want to continue anyway?" 10 60) then
    echo ""
 else
   exit 0
 fi

fi

YEAR=$[`date +'%Y'`]
if [ $YEAR -le 2016 ] ; then
        echo -e "$ERR ERROR: invalid date. set current date and time! $NC" 1>&2
        exit 1
fi
if [ $YEAR -ge 2020 ] ; then
        echo -e "$ERR ERROR: invalid date. set current date and time! $NC" 1>&2
        exit 1
fi

FREE=`df $PWD | awk '/[0-9]%/{print $(NF-2)}'`
if [[ $FREE -lt 1048576 ]]; then
  echo -e "$ERR ERROR: 1GB free disk space required (run raspi-config, 'Expand Filesystem') $NC" > /dev/stderr
  exit 1
fi

KERNEL=$(uname -r)

clear
WELCOME="These drivers will be compiled and installed:\n
- CAN driver (SocketCAN)
- Serial driver (RS232/RS485)
- SPI driver\n
These software components will be installed:\n
- libncurses5-dev, gcc, build-essential, raspberrypi-kernel-headers, lib, autoconf, libtool, libsocketcan, can-utils\n
continue installation?"

if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "$WELCOME" 20 60) then
    echo ""
else
    exit 0
fi


# get installed gcc version
GCCVERBACKUP=$(gcc --version | egrep -o '[0-9]+\.[0-9]+' | head -n 1)
# get gcc version of installed kernel
GCCVER=$(cat /proc/version | egrep -o 'gcc version [0-9]+\.[0-9]+' | egrep -o '[0-9.]+')

apt-get update -y
apt-get -y install libncurses5-dev bc build-essential raspberrypi-kernel-headers device-tree-compiler gcc-$GCCVER g++-$GCCVER

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


rm -rf /tmp/empc-arpi-linux-drivers
mkdir -p /tmp/empc-arpi-linux-drivers
cd /tmp/empc-arpi-linux-drivers


# compile driver modules

wget -nv https://raw.githubusercontent.com/torvalds/linux/v$KERNELMAJ.$KERNELMIN/drivers/net/can/spi/mcp251x.c -O mcp251x.c
wget -nv https://raw.githubusercontent.com/torvalds/linux/v$KERNELMAJ.$KERNELMIN/drivers/tty/serial/sc16is7xx.c -O sc16is7xx.c
wget -nv https://raw.githubusercontent.com/torvalds/linux/v$KERNELMAJ.$KERNELMIN/drivers/spi/spi-bcm2835.c -O spi-bcm2835.c


OPTIMIZATIONS="Optimizations of mainline drivers are available:\n
- SPI driver (spi-bcm2835.c)
 - higher polling time limit for lower latency
 - enable real time priority for work queue\n
- SocketCan driver (mcp251x.c)
 - higher ost delay timeout to prevent can detection problems after soft-reboots\n
- Serial RS232/RS485 (sc16is7xx.c)
 - added delay in startup to prevent message: unexpected interrupt: 8
\nDo you want these optimizations?"

if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "$OPTIMIZATIONS" 22 60) then
 
 # TODO: create patches 
 echo -e "$INFO INFO: patching spi-bcm2835.c with higher polling limit $NC" 1>&2
 sed -i 's/#define BCM2835_SPI_POLLING_LIMIT_US.*/#define BCM2835_SPI_POLLING_LIMIT_US (200)/w /tmp/changelog.txt' spi-bcm2835.c
 if [[ ! -s /tmp/changelog.txt ]]; then
    echo -e "$ERR Error: Patch failed! spi-bcm2835.c $NC" 1>&2
    whiptail --title "Error" --msgbox "Patch 1 failed! spi-bcm2835.c" 10 60
    exit 1
 fi  
 
 echo -e "$INFO INFO: patching spi-bcm2835 with RT priority $NC" 1>&2
 sed -i 's/platform_set_drvdata(pdev, master);/platform_set_drvdata(pdev, master); master->rt = 1;/w /tmp/changelog.txt' spi-bcm2835.c
 if [[ ! -s /tmp/changelog.txt ]]; then
    echo -e "$ERR Error: Patch failed! spi-bcm2835.c $NC" 1>&2
    whiptail --title "Error" --msgbox "Patch 2 failed! spi-bcm2835.c" 10 60
    exit 1
 fi   
 
 echo -e "$INFO INFO: patching mcp251x.c with higher timeout to prevent can detection problems after soft-reboots $NC" 1>&2
 sed -i 's/#define MCP251X_OST_DELAY_MS.*/#define MCP251X_OST_DELAY_MS	(25)/w /tmp/changelog.txt' mcp251x.c
 if [[ ! -s /tmp/changelog.txt ]]; then
    echo -e "$ERR Error: Patch failed! mcp251x.c $NC" 1>&2
    whiptail --title "Error" --msgbox "Patch failed! mcp251x.c" 10 60
    exit 1
 fi  
  
# fixed error message "unexpected interrupt: 8" in dmesg by added mdelay(1)
# without delay, after enabling the interrupts in IER, set_baud/set_termios is immediatly called, 
# enables enhanced register ("config mode") with LCR = 0xBF and the first interrupt occurs at
# the same time, resulting in reading the IIR interrupt status register in the wrong mode.  
# This problematic time window, from enabling the interrupts to handling them, is about 100µs, so a
# delay of 1000µs=1ms was choosen 
 
 echo -e "$INFO INFO: patching sc16is7xx.c with delay in startup to prevent message: unexpected interrupt: 8 $NC" 1>&2
 sed -i 's/sc16is7xx_port_write(port, SC16IS7XX_IER_REG, val);/sc16is7xx_port_write(port, SC16IS7XX_IER_REG, val); mdelay(1);/w /tmp/changelog.txt' sc16is7xx.c
 if [[ ! -s /tmp/changelog.txt ]]; then
    echo -e "$ERR Error: Patch failed! sc16is7xx.c $NC" 1>&2
    whiptail --title "Error" --msgbox "Patch failed! sc16is7xx.c" 10 60
    exit 1
 fi

fi


echo "obj-m += sc16is7xx.o" >Makefile
echo "obj-m += mcp251x.o" >>Makefile
echo "obj-m += spi-bcm2835.o" >>Makefile

echo "all:">>Makefile
echo -e "\tmake -C /lib/modules/$KERNEL/build M=/tmp/empc-arpi-linux-drivers modules" >>Makefile

make

if [ ! -f "mcp251x.ko" ] || [ ! -f "sc16is7xx.ko" ] || [ ! -f "spi-bcm2835.ko" ]; then
 echo -e "$ERR Error: Installation failed! (driver modules build failed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (driver modules build failed)" 10 60
 exit 1
fi

# compile device tree files

wget -nv $REPORAW/src/mcp2515-can0-overlay.dts -O mcp2515-can0-overlay.dts
wget -nv $REPORAW/src/sc16is7xx-ttysc0-rs232-overlay.dts -O sc16is7xx-ttysc0-rs232-overlay.dts
wget -nv $REPORAW/src/sc16is7xx-ttysc0-rs485-overlay.dts -O sc16is7xx-ttysc0-rs485-overlay.dts

dtc -@ -H epapr -O dtb -W no-unit_address_vs_reg -o mcp2515-can0.dtbo -b 0 mcp2515-can0-overlay.dts
dtc -@ -H epapr -O dtb -W no-unit_address_vs_reg -o sc16is7xx-ttysc0-rs232.dtbo -b 0 sc16is7xx-ttysc0-rs232-overlay.dts
dtc -@ -H epapr -O dtb -W no-unit_address_vs_reg -o sc16is7xx-ttysc0-rs485.dtbo -b 0 sc16is7xx-ttysc0-rs485-overlay.dts

if [ ! -f "sc16is7xx-ttysc0-rs232.dtbo" ] || [ ! -f "sc16is7xx-ttysc0-rs485.dtbo" ] || [ ! -f "mcp2515-can0.dtbo" ]; then
 echo -e "$ERR Error: Installation failed! (driver device tree build failed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (driver device tree build failed)" 10 60
 exit 1
fi

/bin/cp -rf mcp251x.ko /lib/modules/$KERNEL/kernel/drivers/net/can/spi/mcp251x.ko
/bin/cp -rf sc16is7xx.ko /lib/modules/$KERNEL/kernel/drivers/tty/serial/sc16is7xx.ko
/bin/cp -rf spi-bcm2835.ko /lib/modules/$KERNEL/kernel/drivers/spi/spi-bcm2835.ko

/bin/cp -rf mcp2515-can0.dtbo /boot/overlays/mcp2515-can0.dtbo
/bin/cp -rf sc16is7xx-ttysc0-rs232.dtbo /boot/overlays/sc16is7xx-ttysc0-rs232.dtbo
/bin/cp -rf sc16is7xx-ttysc0-rs485.dtbo /boot/overlays/sc16is7xx-ttysc0-rs485.dtbo

# register new driver modules
depmod -a



WELCOME2="These configuration settings will automatically be made:\n
- Install default config.txt
- Install SocketCAN initialization as service
- Install RTC initialization as service
- Increase USB max. current
- Enable I2C and SPI drivers
- Set green LED as SD card activity LED\n"
cat /proc/cpuinfo | grep Revision | grep "082" >/dev/null
if (($? == 0)); then
        WELCOME2=$WELCOME2"- Disable Bluetooth (enable serial console)\n"
        WELCOME2=$WELCOME2"- Set CPU frequency to fixed 600MHZ\n"
fi

WELCOME2=$WELCOME2"\ncontinue installation?"


if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "$WELCOME2" 18 60) then
    echo ""
else

    update-alternatives --set gcc "/usr/bin/gcc-$GCCVERBACKUP"
    update-alternatives --set g++ "/usr/bin/g++-$GCCVERBACKUP"

    exit 0
fi


DATE=$(date +"%Y%m%d_%H%M%S")
echo -e "$INFO INFO: creating backup copy of config: /boot/config-backup-$DATE.txt $NC" 1>&2
/bin/cp -rf /boot/config.txt /boot/config-backup-$DATE.txt

echo -e "$INFO INFO: Using default config.txt $NC" 1>&2
wget -nv $REPORAW/src/config.txt -O /boot/config.txt

# if J301 is configured to RS485 mode
echo "24" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio24/direction
cat /sys/class/gpio/gpio24/value | grep "1" && sed -i 's/dtoverlay=sc16is7xx-ttysc0-rs232/dtoverlay=sc16is7xx-ttysc0-rs485/' /boot/config.txt

# installing service to start can0 on boot
if [ ! -f "/bin/systemctl" ]; then
    echo -e "$ERR Warning: systemctl not found, cannot install can0.service $NC" 1>&2
else
    wget -nv $REPORAW/src/can0.service -O /lib/systemd/system/can0.service
    systemctl enable can0.service
fi



echo -e "$INFO INFO: Installing RTC hardware clock $NC" 1>&2
apt-get -y install i2c-tools
# disable fake clock (systemd)
systemctl disable fake-hwclock
systemctl mask fake-hwclock

# disable fake clock (init.d)
service fake-hwclock stop
apt-get -y remove fake-hwclock
rm -f /etc/cron.hourly/fake-hwclock
rm -f /etc/init.d/fake-hwclock
update-rc.d fake-hwclock remove


# enable hwclock (systemd)
rm -f /lib/systemd/system/hwclock.service
wget -nv $REPORAW/src/hwclock.service -O /lib/systemd/system/hwclock.service
systemctl unmask hwclock
systemctl reenable hwclock

# init hwclock (init.d)
if grep -q "mcp7940x 0x6f" "/etc/init.d/hwclock.sh"; then
        echo ""
else
    sed -i 's/unset TZ/echo mcp7940x 0x6f > \/sys\/class\/i2c-adapter\/i2c-1\/new_device/g' /etc/init.d/hwclock.sh
fi
update-rc.d hwclock.sh enable


echo -e "$INFO INFO: Disabling Bluetooth to use serial port $NC"
systemctl disable hciuart


if grep -q "ssh_host_dsa_key" "/etc/rc.local"; then
        echo ""
else
        echo -e "$INFO INFO: Installing SSH key generation /etc/rc.local $NC"
        sed -i 's/exit 0//g' /etc/rc.local
        echo "test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server" >>/etc/rc.local
        echo "exit 0" >>/etc/rc.local
fi




wget -nv $REPORAW/scripts/empc-can-configbaudrate.sh -O /usr/sbin/empc-can-configbaudrate.sh
chmod +x /usr/sbin/empc-can-configbaudrate.sh
/usr/sbin/empc-can-configbaudrate.sh



if [ ! -f "/usr/local/bin/cansend" ]; then
 if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "Third party SocketCan library and utilities\n\n- libsocketcan-0.0.10\n- can-utils\n - candump\n - cansend\n - cangen\n\ninstall?" 16 60) then

    apt-get -y install git
    apt-get -y install autoconf
    apt-get -y install libtool

    cd /usr/src/

    wget http://www.pengutronix.de/software/libsocketcan/download/libsocketcan-0.0.10.tar.bz2
    tar xvjf libsocketcan-0.0.10.tar.bz2
    rm -rf libsocketcan-0.0.10.tar.bz2
    cd libsocketcan-0.0.10
    ./configure && make && make install

    cd /usr/src/

    git clone https://github.com/linux-can/can-utils.git
    cd can-utils
    ./autogen.sh
    ./configure && make && make install

 fi
fi



if [ ! -f "/etc/CODESYSControl.cfg" ]; then
    echo ""
else
    echo -e "$INFO INFO: CODESYS installation found $NC"

 if (whiptail --title "CODESYS installation found" --yesno "CODESYS specific settings:\n- Set SYS_COMPORT1 to /dev/ttySC0\n- Install rts_set_baud.sh SocketCan script\n\ninstall?" 16 60) then

    wget -nv $REPORAW/src/codesys-settings.sh -O /tmp/codesys-settings.sh
    bash /tmp/codesys-settings.sh

 fi

fi


update-alternatives --set gcc "/usr/bin/gcc-$GCCVERBACKUP"
update-alternatives --set g++ "/usr/bin/g++-$GCCVERBACKUP"

cd /

if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "Installation completed! reboot required\n\nreboot now?" 12 60) then

    reboot

fi
