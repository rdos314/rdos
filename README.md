# rdos-kernel
RDOS operating system kernel

<h3>Purpose</h3>
A multicore, multi-process and multi-threaded protected mode OS for 386+ CPUs.
Written mostly in assembly. Use segment protection and paging to provide a stable and secure system. Configurable using a single image file so it can be ported to embedded environments that don't have a keyboard and / or screen. The source code is offered WITHOUT WARRANTY.

<h3>Related repositories</h3>
<ul>
    <li>EFI bootloader, https://github.com/rdos314/rdos-efi</li>
    <li>uACPI, https://github.com/rdos314/rdos-uACPI</li>
    <li>Virtual filesystem, https://github.com/rdos314/rdos-fs</li>
    <li>Application inferface, https://github.com/rdos314/rdos-user</li>
    <li>Standard applications, https://github.com/rdos314/rdos-apps</li>
</ul>

<h3>Supported platforms</h3>
Hardware with 386 or higher processor, including multicore support. 2MB RAM. Specific board support packages are included in the board directory of the source.

<h3>Hardware abstractions</h3>
<ul>
    <li>Drive and partition access (os/drive.rdv)</li>
    <li>Graphics, including mouse and keyboard support (os/guidev.rdv)</li>
    <li>Audio (os/audio.rdv)</li>
    <li>Com port (os/com.rdv)</li>
    <li>Printer (os/printer.rdv)</li>
    <li>Network (os/net.rdv)</li>
    <li>Lon (os/lon.rdv)</li>
    <li>USB (usbdev/usb.rdv)</li>
    <li>Kernel and crash debugger (debug/kdebug.rdv)</li>
</ul>
  
<h3>Software abstractions</h3>
<ul>
    <li>Legacy file system (os/fs.rdv)</li>
    <li>Executable loader (os/exec.rdv)</li>
    <li>Big number support (os/bignum.rdv)</li>
    <li>Inter process communication, including network support (os/ipc.rdv)</li>
    <li>64-bit support (os/longmode.bin)</li>
    <li>PC BIOS access (bios/pcbios.rdv)</li>
    <li>Emulator for V86 mode (dosemu/emulate.rdv)</li>
</ul>

<h3>Hardware drivers</h3>
<ul>
    <li>Real time CMOS clock (pcdev/rtc.rdv)</li>
    <li>VBE based graphics driver (bios/vga.rdv)</li>
    <li>PS/2 keyboard and mouse driver (pcdev/ps2keym.rdv)</li>
    <li>AC97 codec (pcdev/ac97.rdv)</li>
    <li>Floppy driver (pcdev/floppy.rdv)</li>
    <li>IDE and EIDE driver (pcdev/ide.rdv)</li>
    <li>AHCI disc driver (pcdev/ahci.rdv)</li>
    <li>SD card driver (pcdev/sdcard.rdv)</li>
    <li>Standard PC-platform com driver (pcdev/stcom.rdv)</li>
    <li>Realtek RTL8139 and compatible network driver (netdev/rtl8139.rdv)</li>
    <li>Realtek RTL8169 and compatible network driver (netdev/rtl8169.rdv)</li>
    <li>Intel 8255x and compatible network driver (netdev/8255x.rdv)</li>
    <li>Intel i2xx and compatible network driver (netdev/i2xx.rdv)</li>
    <li>CS5536 audio driver (audiodev/cs5536a.rdv)</li>
    <li>VIA82 audio driver (audiodev/via82a.rdv)</li>
    <li>HD audio driver (audiodev/hda.rdv)</li>
    <li>PCI CAN bus driver (pcdev/can.rdv)</li>
    <li>Plug and Play driver (pcdev/pnp.rdv)</li>
    <li>TS2003 driver (touchdev/ts2003.rdv)</li>
    <li>E-galax driver (touchdev/egalax.rdv)</li>
    <li>Pen mount 6000 driver (touchdev/dmc6000.rdv)</li>
    <li>Pen mount 9000 driver (touchdev/dmc9000.rdv)</li>
    <li>UHCI USB 1.0 driver (usbdev/uhci.rdv)</li>
    <li>OHCI USB 1.1 driver (usbdev/ohci.rdv)</li>
    <li>EHCI USB 2 driver (usbdev/ehci.rdv)</li>
    <li>XHCI USB 3 driver (usbdev/xhci.rdv)</li>
    <li>USB HUB driver (usbdev/hub.rdv)</li>
    <li>USB HID driver with support for touch, keyboard and mouse (usbdev/hid.rdv)</li>
    <li>USB com driver (usbdev/usbcom.rdv)</li>
    <li>USB disc driver (usbdev/usbdisc.rdv)</li>
</ul>
  
<h3>Software drivers</h3>
<ul>
    <li>32-bit flat memory model (PE) executable loader (os/pe.rdv)</li>
    <li>TCP, UDP, SMP, DHCP, DNS, ICMP, IP and ARP driver (os/ip.rdv)</li>
    <li>FAT12, FAT16 and FAT32 driver (os/fat.rdv)</li>
    <li>TrueType font driver (freetype/freetype.rdv)</li>
    <li>Ini file support (os/inifile.rdv)</li>
    <li>Thread list (os/tlist.rdv)</li>
    <li>DOS emulator (dosemu/dos.rdv)</li>
    <li>DPMI server (dosemu/dpmi.rdv)</li>
</ul>

<h3>Device driver API</h3>
To be able to link different device-drivers with each other, RDOS has a device driver API. Invalid far calls are built into the calling code. At run-time, these are patched to a far call to the registered destination procedure by the general protection fault handler. RegisterOsGate is used to register a handler. Currently supported APIs are in the kernel/os.inc file in the source distribution. There is also a C include file (kernel/rdosdev.h)

<h3>Application API</h3>
To be able to link application calls with an defined server procedure, RDOS has a device driver API. Invalid far calls are built into the calling code. At run-time, these are patched to call gates pointing to the registered destination procedure by the general protection fault handler. Device drivers can also call the application API, and when this happens, far calls are patched just as with the device driver API. RegisterUserGate is used to register a bimodal handler, RegisterUserGate16 is used for 16-bit handlers and RegisterUserGate32 is used for 32-bit handlers. Currently supported procedures are in the kernel/user.inc file in the source distribution. There is also a C/C++ include file (kernel/rdos.h)

