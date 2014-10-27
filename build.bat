ide2make -p kernel/acpi/acpi
wmake -f kernel/acpi/acpi.mk -h -e

ide2make -p kernel/audiodev/audiodev
wmake -f kernel/audiodev/audiodev.mk -h -e

ide2make -p kernel/boot/boot
wmake -f kernel/boot/boot.mk -h -e

ide2make -p kernel/dosemu/dosemu
wmake -f kernel/dosemu/dosemu.mk -h -e

ide2make -p kernel/freetype/freetype
wmake -f kernel/freetype/freetype.mk -h -e

ide2make -p kernel/netdev/netdev
wmake -f kernel/netdev/netdev.mk -h -e

ide2make -p kernel/os/os
wmake -f kernel/os/os.mk -h -e

ide2make -p kernel/pcdev/pcdev
wmake -f kernel/pcdev/pcdev.mk -h -e

ide2make -p kernel/printdev/printdev
wmake -f kernel/printdev/printdev.mk -h -e

ide2make -p kernel/touchdev/touchdev
wmake -f kernel/touchdev/touchdev.mk -h -e

ide2make -p kernel/usbdev/usbdev
wmake -f kernel/usbdev/usbdev.mk -h -e

ide2make -p classlib/rdos/rdos
wmake -f classlib/rdos/rdos.mk -h -e

ide2make -p classlib/win32/win32
wmake -f classlib/win32/win32.mk -h -e

ide2make -p apps/cfg2bin/cfg2bin
wmake -f apps/cfg2bin/cfg2bin.mk -h -e

ide2make -p apps/freecom/command
wmake -f apps/freecom/command.mk -h -e

ide2make -p apps/ftpd/ftpd
wmake -f apps/ftpd/ftpd.mk -h -e

ide2make -p apps/tcpwd/tcpwd
wmake -f apps/tcpwd/tcpwd.mk -h -e

ide2make -p apps/telnetd/telnetd
wmake -f apps/telnetd/telnetd.mk -h -e
