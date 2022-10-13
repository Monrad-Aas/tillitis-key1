# Toolchain setup

Here are instructions for setting up the tools required to build the project.
Tested on Ubuntu 22.04 LTS.

## Gateware: icestorm toolchain

These steps are used to build and install the
[icestorm](http://bygone.clairexen.net/icestorm/) toolchain (in
`/usr/local`). Note that nextpnr replaces Arachne-PNR.

    sudo apt install build-essential clang lld bison flex libreadline-dev \
                         gawk tcl-dev libffi-dev git mercurial graphviz   \
                         xdot pkg-config python3 libftdi-dev \
                         python3-dev libboost-dev libeigen3-dev \
                         libboost-dev libboost-filesystem-dev \
                         libboost-thread-dev libboost-program-options-dev \
                         libboost-iostreams-dev cmake libhidapi-dev \
                         ninja-build libglib2.0-dev libpixman-1-dev

    git clone https://github.com/YosysHQ/icestorm
    cd icestorm
    make -j$(nproc)
    sudo make install
    cd ..

    # Custom iceprog for the RPi 2040-based programmer (will be upstreamed).
    git clone -b interfaces https://github.com/tillitis/icestorm tillitis--icestorm
    cd tillitis--icestorm/iceprog
    make
    sudo make PROGRAM_PREFIX=tillitis- install
    cd ../..

    git clone https://github.com/YosysHQ/yosys
    cd yosys
    # Avoiding current issue with yosys & icebram, filed in:
    # https://github.com/YosysHQ/yosys/issues/3478
    git checkout 06ef3f264afaa3eaeab45cc0404d8006c15f02b1
    make -j$(nproc)
    sudo make install
    cd ..

    git clone https://github.com/YosysHQ/nextpnr
    cd nextpnr
    # Use nextpnr-0.4. Aa few commits later we got issues, like on f4e6bbd383f6c43.
    git checkout nextpnr-0.4
    cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
    make -j$(nproc)
    sudo make install

For macOS, you will need to build a separate branch of iceprog:

    # Custom iceprog for the RPi 2040-based programmer (will be upstreamed).
    git clone -b interfaces https://github.com/tillitis/icestorm tillitis--icestorm
    cd tillitis--icestorm/iceprog
    git checkout -b iceprog_tillitis_macos origin/iceprog_tillitis_macos
    make
    sudo make PROGRAM_PREFIX=tillitis- install
    cd ../..


References:
* http://bygone.clairexen.net/icestorm/

### Updating the pico programmer firmware (for macOS / Windows compatibility)

If you received your [programming board](https://github.com/tillitis/tillitis-key1/blob/main/hw/boards/README.md#mta1-usb-v1-programmer) from the OSFC conference, it may need to be updated to work with macOS and Windows. To do so, you will need a computer (running any OS), the programming board, and a USB A to micro cable. Follow these steps:

1. Download the [firmware update](https://github.com/Blinkinlabs/ice40_flasher/blob/main/bin/main.uf2) from the [ice40 flasher library.](https://github.com/Blinkinlabs/ice40_flasher)
2. Disconnect the programmer from the computer, if it was attached.
3. Find the small white 'BOOT SEL' button on the programmer board, and press it down.
4. While holding the button down, connect the programmer board to the computer using the USB cable.
5. The computer should identify the programming board as a USB disk. Copy the 'main.u2f' firmware file to this USB disk.
6. After the file finishes copying, the programmer will reboot automatically, causing the USB disk to disappear.
7. The programming board is now updated and ready to use.


## Firmware: riscv toolchain

The Tillitis Key 1 implements a
[picorv32](https://github.com/YosysHQ/picorv32) soft core CPU, which
is a RISC-V microcontroller with the M and C instructions (RV32IMC).
You can read
[more](https://www.sifive.com/blog/all-aboard-part-1-compiler-args)
about it.

The project uses the LLVM/Clang suite, where version 14 is the latest
stable (as of writing). Usually the LLVM/Clang packages that are part
of your distro will work, if not, there are installations instructions
for "Install (stable branch)" at https://apt.llvm.org/ for Debian and
Ubuntu.

References:
* https://github.com/YosysHQ/picorv32

## Optional

These tools are used for specific sub-components of the project, and
are not required for general development

### Kicad 6.0: Circuit board designs

The circuit board designs were all created in [KiCad
6.0](https://www.kicad.org/).

### mta1-usb-v1-programmer: RPi 2040 toolchain

These tools are needed to build the programmer firmware for the
mta1-usb-v1-programmer

#### FW update of the programmer
The programmer runs a FW needed to program the devices, the source code
is available on Githun:

https://github.com/Blinkinlabs/ice40_flasher

There is also a pre built FW binary for the programmer:
https://github.com/Blinkinlabs/ice40_flasher/tree/main/bin

Download the file programmer FW file "main.uf2" to your host computer.

To program do the following.

1. Press the "BOOTSEL" button on the RPi2040 board while connecting the board to the host
2. Release the button after cvonnecting the board to the host. The board will now appear to the host as a USB connected storage device
3. Open the storage device and drop the FW file ("main.uf2") into the storage device

The programmer will update its FW with the file and restart itself.


### mta1-usb-v1: ch552 USB to Serial firmware

The USB to Serial firmware runs on the CH552 microcontroller, and
provides a USB CDC profile which should work with the default drivers
on all major operating systems.

TODO

References:
* source code: https://github.com/tillitis/tillitis-key1/tree/main/hw/boards/mta1-usb-v1/ch552_fw
* Compiler: [SDCC](http://sdcc.sourceforge.net/)
* Library: https://github.com/Blinkinlabs/ch554_sdcc
* Flashing tool: https://github.com/ole00/chprog
