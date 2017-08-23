# emPC-A/RPI3, emPC-A/RPI & emVIEW-7/RPI3 by Janz Tec AG
This script installs and configures Linux **Socket CAN**, **serial port** and **RTC** drivers

## :white_check_mark: Installation Instructions:

Our pre-installed images are based on Raspbian Jessie with Linux kernel version 4.4 and drivers installed by our _install.sh_ script. If you want to use newer kernel versions, you can try our "Installation Instructions (Experimental)" below.

_create a backup copy of your µSD card before applying these steps!_

**Step 1:**

Install one of the listed RASPBIAN operating system versions from below: 

(Raspbian Jessie Lite, or Raspbian Jessie recommended. NOOBS installation **not** supported)

1) **_emPC-A/RPI3_: Raspbian Jessie version 2016-09-28**
   * Lite:
https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2016-09-28/
   * Desktop:
https://downloads.raspberrypi.org/raspbian/images/raspbian-2016-09-28/


2) **_emPC-A/RPI_: Raspbian Jessie Lite version 2015-11-24** 
   * Lite:
   https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2015-11-24/ 
   * Desktop:
   https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-11-24/

 
**Step 2:**

```
sudo bash
cd /tmp
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/install.sh -O install.sh
bash install.sh
```

-------



## :large_orange_diamond: Installation Instructions (Experimental):

**:heavy_exclamation_mark:  WARNING!! EXPERIMENTAL**

In newer Raspbian images the Linux kernel is installed in version 4.9 (or later) and therefore our previous script _install.sh_ will no longer work correctly. For this newer Linux kernel versions, our new driver installation script _install-experimental.sh_ is still under development. Your feedback is welcome!

_create a backup copy of your µSD card before applying these steps!_

**Step 1:**

Install one of the listed RASPBIAN operating system versions from below: 

3) **Experimental: Raspbian Stretch version 2017-08-16 or later**

   _install-experimental.sh_ script uses the mainline kernel driver sources with only a few source code patches, see _install-experimental.sh_ for more details. Our performance optimizations of the CAN, UART and SPI drivers are currently not included in these mainline drivers.   

   https://www.raspberrypi.org/downloads/raspbian/


**Step 2:**


```
sudo bash
cd /tmp
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/install-experimental.sh -O install-experimental.sh
bash install-experimental.sh
```


<br />
<br />

## Product pages
https://www.janztec.com/en/products/embedded-computing/empc/empc-arpi3/

**emPC-A/RPI3**

![emPC-A/RPI3](https://www.janztec.com/fileadmin/user_upload/Produkte/embedded/emPC-A-RPI2/janztec_produkte_embedded_emPC_RPI_raspberry_front.jpg)

**FEATURES emPC-A/RPI3**
* Processor 
  * Based on Raspberry Pi 3, Model B 
  * Broadcom BCM2837 processor 
  * Quad-Core CPU based on ARM Cortex-A53 
  * Fanless cooling concept 
  * Realtime clock, battery buffered 
* Memory 
  * System memory 1 GB 
  * External accessible µSD card slot  
* Graphics 
  * HDMI graphic interface  
* Connectors  
  * 1 x 10/100 MBit/s Ethernet 
  * 4 x USB (v2.0) 
  * 1 x 9-pin D-SUB connector for serial debug console 
  * 1 x CAN (ISO/DIS 11989-2, opto-isolated, termination settings via jumper) 
  * 1 x RS232 (Rx, Tx, RTS, CTS) or switchable to RS485 (half duplex; termination settings via jumper)  
  * Internal I/O  
    * 4 x digital inputs (12 - 24VDC) 
    * 4 x digital outputs (12 - 24VDC)  
* Power Supply  
  * Input 9 … 32 VDC 
* DIN rail, wall mounting or desktop 

-------

**emVIEW-7/RPI3**

https://www.janztec.com/en/products/embedded-computing/panel-pc/emview-7rpi3/

![emVIEW-7/RPI3](https://www.janztec.com/fileadmin/user_upload/Produkte/embedded/emVIEW-7-RPI3/janz_tec_produkte_embedded_emVIEW-7_RPI3_front_schraeg_800x8001.jpg)

**FEATURES emVIEW-7/RPI3**
* LCD Display
   * 7.0" WSVGA display size
   * LED backlight technology
   * Resolution 800 x 480
   * Projected capacitive touch screen (PCAP) (with multitouch capabilities)
   * Glass surface
* Same I/O as emPC-A/RPI3
