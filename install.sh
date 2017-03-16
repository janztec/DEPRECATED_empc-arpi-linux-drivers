#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "ERROR: This script should be run as root." > /dev/stderr
    exit 1
fi

YEAR=$[`date +'%Y'`]
if [ $YEAR -le 2015 ] ; then
        echo "ERROR: invalid date. set current date and time!";
        exit 2
fi
if [ $YEAR -ge 2023 ] ; then
        echo "ERROR: invalid date. set current date and time!";
        exit 2
fi

FREE=`df $PWD | awk '/[0-9]%/{print $(NF-2)}'`
if [[ $FREE -lt 1048576 ]]; then
  echo "ERROR: 1GB free disk space required (run raspi-config, 'Expand Filesystem')" > /dev/stderr
  exit 1
fi

KERNEL=$(uname -r)

clear
echo "--------------------------------------------------------------------------------"
echo ""
echo "                   Janz Tec AG emPC-A/RPI driver installer  "
echo ""
echo "Minimum installation requirements:"
echo "- emPC-A/RPI hardware version 1.1 or later"
echo "- Kernel 3.18.16-v7+ or later (currently running: $KERNEL)"
echo "- Internet connection (about 150MB will be downloaded)"
echo "- 1GB free disk space"
echo "These drivers will be compiled and installed:"
echo "- CAN driver (SocketCAN)"
echo "- Serial driver (RS232/RS485)"
echo "These software components will be installed:"
echo "- libncurses5-dev, gcc, lib, autoconf, libtool, libsocketcan, can-utils"
echo "These configuration settings will automatically be made:"
echo "- Install SocketCAN initialization as service"
echo "- Install RTC initialization as service"
echo "- Increase USB max. current"
echo "- Enable I2C and SPI drivers"
echo "- Set green LED as SD card activity LED"
cat /proc/cpuinfo | grep Revision | grep "082" >/dev/null
if (($? == 0)); then
	echo "- Disable Bluetooth (enable serial console)"
	echo "- Set CPU frequency to fixed 600MHZ"
fi
echo "--------------------------------------------------------------------------------"
echo ""
echo "Important: Create a backup copy of the system before starting this installation!"
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


cat /proc/cpuinfo | grep Revision | grep "082"
if (($? == 0)); then
	wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/imageversion3.txt -O /root/imageversion.txt
else
	wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/imageversion.txt -O /root/imageversion.txt
fi

# get installed gcc version
GCCVERBACKUP=$(gcc --version | egrep -o '[0-9]+\.[0-9]+' | head -n 1)
# get gcc version of installed kernel
GCCVER=$(cat /proc/version | egrep -o 'gcc version [0-9]+\.[0-9]+' | egrep -o '[0-9.]+')

apt-get update -y
apt-get -y install libncurses5-dev bc
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

mkdir -p /home/pi/empc-arpi-linux
cd /home/pi/empc-arpi-linux

modprobe configs
apt-get install -y pv

if [ ! -f "linux-$KERNEL.tar.gz" ]; then
        rm -rf raspberrypi-linux-*

        LAYOUT=$(modprobe --dump-modversions /lib/modules/$KERNEL/kernel/drivers/net/dummy.ko | grep module_layout | awk '{print $1}')
        echo "INFO: Module layout: $LAYOUT"
       
        wget -nv https://github.com/raspberrypi/firmware/commits/master/extra/Module7.symvers -O - | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep tree | grep Module7.symvers >links.txt
        # pagination does no longer work! wget -nv https://github.com/raspberrypi/firmware/commits/master/extra/Module7.symvers?page=2 -O - | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep tree | grep Module7.symvers >>links.txt
	wget -nv https://github.com/raspberrypi/firmware/commits/master/extra/Module7.symvers?after=Y3Vyc29yOlCb6qsOECz23s8gmSJmlwDJrFV2KzM0 -O - | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep tree | grep Module7.symvers >>links.txt
	wget -nv https://github.com/raspberrypi/firmware/commits/master/extra/Module7.symvers?after=Y3Vyc29yOlCb6qsOECz23s8gmSJmlwDJrFV2KzY5 -O - | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep tree | grep Module7.symvers >>links.txt 
        
        link=""
        matchedlink="err"
        while read link; do
          echo "INFO: downloading: $link"
          if wget -nv "https://github.com$link" -O - | grep module_layout | grep $LAYOUT; then
            echo "INFO: found matching revision!"
            matchedlink=$(echo "$link")
            
	    fwhash=$(echo $matchedlink | cut -d/ -f 5)
            uname=$(wget -qO- https://raw.githubusercontent.com/raspberrypi/firmware/$fwhash/extra/uname_string7 -O -)
            if echo $uname | grep $KERNEL; then
              echo "INFO: found matching kernel with uname: $uname"
              break
            else
              echo "INFO: wrong kernel version, trying next"
            fi
	    
          fi
        done <links.txt
        rm -f links.txt
        
        if [ "$matchedlink" = "err" ]; then
            echo 
            echo "ERROR: unable to find matching firmware "
            echo
            exit 3
        fi
        
        fwhash=$(echo $matchedlink | cut -d/ -f 5)
        
        echo
        echo "firmware hash: $fwhash"
        echo
        
        kernhash=$(wget -qO- https://raw.github.com/raspberrypi/firmware/$fwhash/extra/git_hash -O -)
        wget https://github.com/raspberrypi/linux/tarball/$kernhash -O linux-$KERNEL.tar.gz

        echo "extracting kernel sources.."
        pv linux-$KERNEL.tar.gz | tar xzf -

        cd raspberrypi-linux-*        
        wget -nv https://raw.github.com/raspberrypi/firmware/$fwhash/extra/Module7.symvers -O Module.symvers
        zcat /proc/config.gz > .config
else
    cd raspberrypi-linux-*
fi


INSTALLDIR=$(pwd)

yes "" | make oldconfig
yes "" | make modules_prepare

wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/arch/arm/boot/dts/overlays/sc16is7xx-ttysc0-overlay.dts -O arch/arm/boot/dts/overlays/sc16is7xx-ttysc0-overlay.dts
wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/arch/arm/boot/dts/overlays/mcp2515-can0-overlay.dts -O arch/arm/boot/dts/overlays/mcp2515-can0-overlay.dts
wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/drivers/spi/spi-bcm2835.c -O drivers/spi/spi-bcm2835.c
wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/drivers/net/can/spi/mcp251x.c -O drivers/net/can/spi/mcp251x.c
wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux/rpi-3.18.y/drivers/tty/serial/sc16is7xx.c -O drivers/tty/serial/sc16is7xx.c


if grep -q "sc16is7xx" "arch/arm/boot/dts/overlays/Makefile"; then
        echo ""
else
        if grep -q ".dtbo" "arch/arm/boot/dts/overlays/Makefile"; then
            # starting with kernel 4.4.xxx use dtbo files
            sed -i 's/mcp2515-can1.dtbo/sc16is7xx-ttysc0.dtbo/g' arch/arm/boot/dts/overlays/Makefile
        else
            sed -i 's/mcp2515-can1-overlay/sc16is7xx-ttysc0-overlay/g' arch/arm/boot/dts/overlays/Makefile
        fi
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


if [ -f "arch/arm/boot/dts/overlays/mcp2515-can0.dtbo" ]; then
    rm -f /boot/overlays/mcp2515-can0-overlay.dtb
    rm -f /boot/overlays/sc16is7xx-ttysc0-overlay.dtb
    cp arch/arm/boot/dts/overlays/mcp2515-can0.dtbo /boot/overlays/mcp2515-can0.dtbo
    cp arch/arm/boot/dts/overlays/sc16is7xx-ttysc0.dtbo /boot/overlays/sc16is7xx-ttysc0.dtbo
fi

if [ -f "arch/arm/boot/dts/overlays/mcp2515-can0-overlay.dtb" ]; then
    cp arch/arm/boot/dts/overlays/mcp2515-can0-overlay.dtb /boot/overlays/mcp2515-can0-overlay.dtb
    cp arch/arm/boot/dts/overlays/sc16is7xx-ttysc0-overlay.dtb /boot/overlays/sc16is7xx-ttysc0-overlay.dtb
fi



cp drivers/spi/spi-bcm2835.ko /lib/modules/$KERNEL/kernel/drivers/spi/spi-bcm2835.ko
cp drivers/net/can/spi/mcp251x.ko /lib/modules/$KERNEL/kernel/drivers/net/can/spi/mcp251x.ko
cp drivers/tty/serial/sc16is7xx.ko /lib/modules/$KERNEL/kernel/drivers/tty/serial/sc16is7xx.ko

depmod -a


if [ ! -f "/lib/modules/$KERNEL/kernel/drivers/net/can/spi/mcp251x.ko" ] || [ ! -f "/lib/modules/$KERNEL/kernel/drivers/tty/serial/sc16is7xx.ko" ]; then
    echo "Error: Installation failed! (driver modules not installed)" 1>&2
    exit 7
fi

#rm -rf $INSTALLDIR
#rm -f $INSTALLDIR.tar.gz


# installing service to start can0 on boot
if [ ! -f "/bin/systemctl" ]; then
    echo "Warning: systemctl not found, cannot install can0.service" 1>&2
else
    wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/can0.service -O /lib/systemd/system/can0.service
    systemctl enable can0.service
fi


if grep -q "sc16is7xx" "/boot/config.txt"; then
        echo ""
else
        echo "INFO: Enabling I2C in /boot/config.txt"
        echo "" >>/boot/config.txt
        echo "dtparam=i2c_arm=on" >>/boot/config.txt
        echo "INFO: Enabling SPI in /boot/config.txt"
        echo "dtparam=spi=on" >>/boot/config.txt
fi

sed -i 's/dtoverlay=mcp2515/#dtoverlay=mcp2515/g' /boot/config.txt
sed -i 's/dtoverlay=sc16is7xx/#dtoverlay=sc16is7xx/g' /boot/config.txt
sed -i 's/dtoverlay=spi-bcm2835/#dtoverlay=spi-bcm2835/g' /boot/config.txt 

echo "INFO: Installing CAN and RS232/RS485 driver DT in /boot/cmdline.txt"
if [ -f "/boot/overlays/mcp2515-can0-overlay.dtb" ]; then
    echo "dtoverlay=mcp2515-can0-overlay,oscillator=16000000,interrupt=25" >>/boot/config.txt
    echo "dtoverlay=sc16is7xx-ttysc0-overlay" >>/boot/config.txt
    echo "dtoverlay=spi-bcm2835-overlay" >>/boot/config.txt
fi

if [ -f "/boot/overlays/mcp2515-can0.dtbo" ]; then
    echo "dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25" >>/boot/config.txt
    echo "dtoverlay=sc16is7xx-ttysc0" >>/boot/config.txt
    #echo "dtoverlay=spi-bcm2835" >>/boot/config.txt
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
wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/hwclock.service -O /lib/systemd/system/hwclock.service
systemctl unmask hwclock
systemctl reenable hwclock

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
fi

cat /proc/cpuinfo | grep Revision | grep "082" >/dev/null
if (($? == 0)); then
	# Raspberry Pi 3B
	echo "(Raspberry Pi 3B)"
	
	if grep -q "arm_freq=600" "/boot/config.txt"; then
		echo ""
	else
		echo "INFO: Set CPU frequency to fixed 600MHZ"
		echo "# Janz Tec AG: force 600MHZ" >>/boot/config.txt
		echo "arm_freq=600" >>/boot/config.txt	
	fi

	if grep -q "dtoverlay=pi3-act-led" "/boot/config.txt"; then
        	echo ""
	else
		echo "INFO: Enabling green LED as microSD activity LED"
		echo "dtoverlay=pi3-act-led,gpio=5,activelow=off" >>/boot/config.txt
	fi

	if grep -q "dtoverlay=pi3-miniuart-bt" "/boot/config.txt"; then
        	echo ""
	else
		echo "INFO: disabling Bluetooth to enable serial console with correct timing"
		echo "dtoverlay=pi3-miniuart-bt" >>/boot/config.txt
	fi
	
	if grep -q "dtoverlay=sdhost" "/boot/config.txt"; then
		echo "WARN: dtoverlay=sdhost found in /boot/config.txt. If this is enabled, then WLAN will not work. "
	        sed -i 's/dtoverlay=sdhost/#dtoverlay=sdhost/g' /boot/config.txt
	fi

else
	# Raspberry PI 2B
	echo "(Raspberry Pi 2B)"

	if grep -q "dtparam=act_led_gpio=5" "/boot/config.txt"; then
        	echo ""
	else
		echo "INFO: Enabling green LED as microSD activity LED"
		echo "dtparam=act_led_gpio=5" >>/boot/config.txt
	fi

	if grep -q "dtoverlay=sdhost" "/boot/config.txt"; then
	        echo ""
	else
        	echo "INFO: Enabling sdhost in /boot/config.txt"
	        echo "" >>/boot/config.txt
        	echo "dtoverlay=sdhost" >>/boot/config.txt
	fi

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


if [ ! -f "/etc/CODESYSControl.cfg" ]; then
    echo ""
else    
    echo "INFO: CODESYS installation found"
    wget -nv https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/codesys.sh -O /home/pi/codesys.sh
    bash /home/pi/codesys.sh
fi

# clean up
rm -rf /home/pi/empc-arpi-linux

echo
echo "-----------------------------------------------"
echo
echo "INFO: Installation completed! restart required!"
echo

