# emPC-A/RPI by Janz Tec AG
**Low Cost ARM Cortex-A7 Based Embedded Controller**

Product page: https://www.janztec.com/en/empc-a-rpi.html
![emPC-A/RPI](https://www.janztec.com/fileadmin/_processed_/csm_janztec_produkte_embedded_empc_a-pri_1_57fdb80040.jpg)

**FEATURES emPC-A/RPI**
* Processor 
  * Based on Raspberry Pi 2, Model B 
  * Broadcom BCM2836 processor 
  * Quad-Core CPU based on ARM Cortex-A7  with 900 MHz 
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
    * 4 x digital inputs (24VDC) 
    * 4 x digital outputs (24VDC)  
* Power Supply  
  * Input 9 … 32 VDC 


## Installation Instructions:

Step1:
Install latest RASPBIAN operating system from https://www.raspberrypi.org/downloads/ 

Step 2:
```
apt-get update
apt-get upgrade
```

Step 3:
Reboot system

Step 4:
```
sudo bash
cd /home/pi
wget https://raw.githubusercontent.com/janztec/empc-arpi-linux-drivers/master/install.sh
bash install.sh
```



