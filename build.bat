@echo off

echo "Building ACPI"
ide2make -p kernel/acpi/acpi 1>nul
wmake -f kernel/acpi/acpi.mk -h -e 1>nul

echo "Building Audio Device"
ide2make -p kernel/audiodev/audiodev 1>nul
wmake -f kernel/audiodev/audiodev.mk -h -e 1>nul

echo "Building DosEmu"
ide2make -p kernel/dosemu/dosemu 1>nul
wmake -f kernel/dosemu/dosemu.mk -h -e 1>nul

echo "Building FreeType"
ide2make -p kernel/freetype/freetype 1>nul
wmake -f kernel/freetype/freetype.mk -h -e 1>nul

echo "Building Net Device"
ide2make -p kernel/netdev/netdev 1>nul
wmake -f kernel/netdev/netdev.mk -h -e 1>nul

echo "Building OS"
ide2make -p kernel/os/os 1>nul
wmake -f kernel/os/os.mk -h -e 1>nul

echo "Building Debug"
ide2make -p kernel/debug/kdebug 1>nul
wmake -f kernel/debug/kdebug.mk -h -e 1>nul

echo "Building PC Device"
ide2make -p kernel/pcdev/pcdev 1>nul
wmake -f kernel/pcdev/pcdev.mk -h -e 1>nul

echo "Building Printer device"
ide2make -p kernel/printdev/printdev 1>nul
wmake -f kernel/printdev/printdev.mk -h -e 1>nul

echo "Building Touch Device"
ide2make -p kernel/touchdev/touchdev 1>nul
wmake -f kernel/touchdev/touchdev.mk -h -e 1>nul

echo "Building USB Device"
ide2make -p kernel/usbdev/usbdev 1>nul
wmake -f kernel/usbdev/usbdev.mk -h -e 1>nul

echo "Building BIOS device"
ide2make -p kernel/bios/bios 1>nul
wmake -f kernel/bios/bios.mk -h -e 1>nul

echo "Building BIOS loaders"
ide2make -p kernel/bios/loader/loader 1>nul
wmake -f kernel/bios/loader/loader.mk -h -e 1>nul

echo "Building EFI 32-bit loader"
ide2make -p kernel/efi/loader/ia32/boot32 1>nul
wmake -f kernel/efi/loader/ia32/boot32.mk -h -e 1>nul

echo "Building EFI 64-bit loader"
ide2make -p kernel/efi/loader/x64/boot64 1>nul
wmake -f kernel/efi/loader/x64/boot64.mk -h -e 1>nul

echo "Building Rdos classlib"
ide2make -p classlib/rdos/rdos 1>nul
wmake -f classlib/rdos/rdos.mk -h -e 1>nul

echo "Building FS"
ide2make -p kernel/fs/fs 1>nul
wmake -f kernel/fs/fs.mk -h -e 1>nul

echo "Building Open SSL Lib"
ide2make -p classlib/ssl/openssl 1>nul
wmake -f classlib/ssl/openssl.mk -h -e 1>nul

echo "Building SSL server"
ide2make -p kernel/ssl/ssl 1>nul
wmake -f kernel/ssl/ssl.mk -h -e 1>nul

echo "Building Win32 classlib"
ide2make -p classlib/win32/win32 1>nul
wmake -f classlib/win32/win32.mk -h -e 1>nul

echo "Building Cfg2Bin"
ide2make -p apps/cfg2bin/cfg2bin 1>nul
wmake -f apps/cfg2bin/cfg2bin.mk -h -e 1>nul

echo "Building FreeCom"
ide2make -p apps/freecom/command 1>nul
wmake -f apps/freecom/command.mk -h -e 1>nul

echo "Building FTP Daemon"
ide2make -p apps/ftpd/ftpd 1>nul
wmake -f apps/ftpd/ftpd.mk -h -e 1>nul

echo "Building MB Edit"
ide2make -p apps/mbedit/mbedit 1>nul
wmake -f apps/mbedit/mbedit.mk -h -e 1>nul

echo "Building Watcom TCP Debugger"
ide2make -p apps/tcpwd/tcpwd 1>nul
wmake -f apps/tcpwd/tcpwd.mk -h -e 1>nul

echo "Building Telnet Daemon"
ide2make -p apps/telnetd/telnetd 1>nul
wmake -f apps/telnetd/telnetd.mk -h -e 1>nul

echo "Building longmode Device"
cd kernel/os
jwasm -10 -Zm -bin -Fllongmode.lst longmode.asm 

echo "Building realtime monitor"
jwasm -10 -Zm -bin -Flrealmon.lst realmon.asm 

cd ..
cd ..
