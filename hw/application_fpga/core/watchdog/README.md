# watchdog
A simple watchdog written in Verilog.

## Introduction
This core implements a simple watchdog. When enabled by SW it will count down to zero
unless being poked by SW. When the watchdog reaches zero it will trigger a reset
of the FPGA device.
