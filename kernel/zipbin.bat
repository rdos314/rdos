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
