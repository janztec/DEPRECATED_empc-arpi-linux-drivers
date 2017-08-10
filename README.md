# emPC-A/RPI & emPC-A/RPI3 by Janz Tec AG
**Low Cost ARM Based Embedded Controller**

## Installation Instructions:

Step1:

Install one of the listed RASPBIAN operating system versions from below: 

(Raspbian Jessie Lite, or Raspbian Jessie recommended. NOOBS installation **not** supported)

**Raspbian Jessie Lite version 2016-09-28**

install.sh script is currently supported for **emPC-A/RPI3** **Raspbian Jessie Lite version 2016-09-28**: https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2016-09-28/


**Raspbian Jessie Lite version 2015-11-24** 

install.sh script is currently supported for **emPC-A/RPI** **Raspbian Jessie Lite version 2015-11-24**: https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2015-11-24/ 


**Experimental! Raspbian Jessie Lite or Raspbian Jessie Desktop 2017-07-05 or later**

In newer Raspbian images the Linux kernel is installed in version 4.9 (or later) and therefore the script install.sh will no longer work correctly. For this newer Linux kernel versions, our new driver installation script install-experimental.sh is still under development. 

install-experimental.sh script uses the mainline kernel driver sources with only a few source code patches, see install-experimental.sh for more details. Our performance optimizations of the CAN, UART and SPI drivers are currently not included in these mainline drivers.   


Step 2:
```
apt-get update
```

Step 3:
```
sudo bash

cd /home/pi

wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/install.sh -O /home/pi/install.sh

#wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/install-experimental.sh -O /home/pi/install-experimental.sh

bash install.sh
```

## Product page
https://www.janztec.com/en/products/embedded-computing/empc/empc-arpi3/
![emPC-A/RPI](https://www.janztec.com/fileadmin/user_upload/Produkte/embedded/emPC-A-RPI2/janztec_produkte_embedded_emPC_RPI_raspberry_front.jpg)

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
    * 4 x digital inputs (12, 24VDC) 
    * 4 x digital outputs (12, 24VDC)  
* Power Supply  
  * Input 9 … 32 VDC 
* DIN rail, wall mounting or desktop 






