del src.zip
pkzip -P *.inc *.def *.h
pkzip -P src.zip os\*.asm os\*.inc os\*.def os\makefile os\*.bat
pkzip -P src.zip device\*.asm device\*.inc device\*.def device\makefile device\*.bat
pkzip -P src.zip win\*.asm win\*.inc win\*.def win\makefile win\*.bat win\*.zip win\*.dll win\*.h
pkzip -P src.zip win32\*.asm win32\*.inc win32\*.def win32\makefile win32\*.bat win32\*.dll win32\*.h
pkzip -P src.zip tools\*.asm tools\*.inc tools\*.def tools\makefile tools\*.cfg tools\*.bat tools\ndos.* tools\*.gft
pkzip -P src.zip classlib\*.cpp classlib\*.h
pkzip -P src.zip classlib\jpeg\*.cpp classlib\jpeg\*.h
pkzip -P src.zip classlib\png\*.cpp classlib\png\*.h
pkzip -P src.zip classlib\zlib\*.cpp classlib\zlib\*.h
