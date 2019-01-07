# emPC-A/RPI, emVIEW-7/RPI by Janz Tec AG

This script installs and configures Linux **Socket CAN**, **Serial port RS232/RS485** and **RTC** drivers


## :white_check_mark: Installation Instructions:

## :large_orange_diamond: Not compatible with emPC-A/RPI3+ and emVIEW-7/RPI3+! Use empc-arpi3-linux-drivers repository!

https://github.com/janztec/empc-arpi3-linux-drivers


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






<br />
<br />


## Product pages
https://www.janztec.com/en/embedded-pc/embedded-computer/empc-arpi3/

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

https://www.janztec.com/en/embedded-pc/panel-pc/emview-7rpi3/

![emVIEW-7/RPI3](https://www.janztec.com/fileadmin/user_upload/Produkte/embedded/emVIEW-7-RPI3/janz_tec_produkte_embedded_emVIEW-7_RPI3_front_schraeg_800x8001.jpg)

**FEATURES emVIEW-7/RPI3**
* LCD Display
   * 7.0" WSVGA display size
   * LED backlight technology
   * Resolution 800 x 480
   * Projected capacitive touch screen (PCAP) (with multitouch capabilities)
   * Glass surface
* Same I/O as emPC-A/RPI3
