#!/bin/sh
setpci -s c1:00.0 COMMAND=0x102 # replace c1:00.0 with FPGA_DEVICE_ID in your OS
echo 1 > /sys/bus/pci/devices/0000\:c1\:00.0/remove #:c1\00.0  ---> FPGA_DEVICE_ID in your OS
echo 1 > /sys/bus/pci/devices/0000\:c0\:01.1/rescan # scan previous device