del freecom.zip
pkzip -P freecom.zip *.cpp *.h *.ide *.def *.exe 
pkzip -P freecom.zip lib\*.cpp lib\*.h
pkzip -P freecom.zip lang\*.cpp lang\*.h lang\*.ide lang\*.def lang\*.exe lang\*.dll lang\*.rc lang\*.lng
