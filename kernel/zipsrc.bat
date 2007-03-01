del src.zip
pkzip -P src.zip *.inc *.def *.h
pkzip -P src.zip os\*.asm os\*.inc os\*.def os\makefile os\*.bat
pkzip -P src.zip device\*.asm device\*.inc device\*.def device\makefile device\*.bat
pkzip -P src.zip win\*.asm win\*.inc win\*.def win\makefile win\*.bat win\*.zip win\*.dll win\*.h
pkzip -P src.zip win32\*.asm win32\*.inc win32\*.def win32\makefile win32\*.bat win32\*.dll win32\*.h
pkzip -P src.zip tools\*.asm tools\*.inc tools\*.def tools\makefile tools\*.cfg tools\*.bat tools\ndos.* tools\*.gft
pkzip -P src.zip classlib\*.cpp classlib\*.h classlib\*.ide classlib\*.def
pkzip -P src.zip classlib\jpeg\*.cpp classlib\jpeg\*.h classlib\jpeg\*.ide
pkzip -P src.zip classlib\png\*.cpp classlib\png\*.h classlib\png\*.ide
pkzip -P src.zip classlib\zlib\*.cpp classlib\zlib\*.h classlib\zlib\*.ide
pkzip -P src.zip classlib\emulate\*.cpp classlib\emluate\*.h classlib\emulate\*.ide
pkzip -P src.zip classlib\emulate\pic16f84\*.inc classlib\emluate\pic16f84\*.h
pkzip -P src.zip classlib\emulate\x86\*.asm classlib\emulate\x86\*.inc
pkzip -P src.zip classlib\emulate\x86\*.cpp classlib\emulate\x86\*.h
pkzip -P src.zip classlib\emulate\x86\zfx86\*.cpp classlib\emulate\x86\zfx86\*.h
pkzip -P src.zip classlib\ftpd\*.cpp classlib\ftpd\*.h classlib\ftpd\*.ide
pkzip -P src.zip classlib\httpd\*.cpp classlib\httpd\*.h classlib\httpd\*.ide
pkzip -P src.zip classlib\ws2300\*.cpp classlib\ws2300\*.h classlib\ws2300\*.ide
pkzip -P src.zip classlib\fuzzy\*.cpp classlib\fuzzy\*.h classlib\fuzzy\*.ide
