del *.bak
del *.obj
del *.exe
del *.rdv
del *.map
del *.zip
cd os
command /c clean
cd ..

cd device
command /c clean
cd ..

cd win
command /c clean
cd ..

cd win32
command /c clean
cd ..

cd tools
command /c clean
cd ..

cd classlib
command /c clean
cd ..
