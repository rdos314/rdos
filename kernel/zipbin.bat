del bin.zip
pkzip -P bin.zip *.inc *.def *.h
pkzip -P bin.zip os\*.rdv os\*.exe os\*.bat
pkzip -P bin.zip device\*.rdv device\*.exe device\*.bat
pkzip -P bin.zip win\*.bat win\*.dll win\*.h
pkzip -P bin.zip win32\*.bat win32\*.dll win32\*.h
pkzip -P bin.zip tools\*.bat tools\ndos.* tools\*.gft tools\*.exe
pkzip -P bin.zip classlib\*.lib classlib\*.h
pkzip -P bin.zip classlib\jpeg\*.lib classlib\jpeg\*.h
pkzip -P bin.zip classlib\png\*.lib classlib\png\*.h
pkzip -P bin.zip classlib\zlib\*.lib classlib\zlib\*.h
pkzip -P bin.zip classlib\emulate\*.lib classlib\emluate\*.h
pkzip -P bin.zip classlib\emulate\pic16f84\*.inc classlib\emluate\pic16f84\*.h
pkzip -P bin.zip classlib\emulate\x86\*.inc classlib\emulate\x86\*.h
pkzip -P bin.zip classlib\emulate\x86\zfx86\*.h
pkzip -P bin.zip classlib\ftpd\*.lib classlib\ftpd\*.h classlib\ftpd\*.dll
pkzip -P bin.zip classlib\httpd\*.lib classlib\httpd\*.h
pkzip -P bin.zip classlib\ws2300\*.lib classlib\ws2300\*.h
