@echo off
REM *****************************************************************
REM SETVARS.BAT - Windows NT version
REM *****************************************************************
REM NOTE: Do not use this batch file directly, but copy it and
REM       modify it as necessary for your own use!!

REM Change this to point to your Open Watcom source tree - must be an 8.3 name!
set OWROOT=\rdos\watcom\bld

REM Change this to point to your existing Open Watcom installation
set WATCOM=c:\ow\openwatcom\rel2

REM Set this variable to 1 to get debug build
set DEBUG_BUILD=0

REM Set this variable to 1 to get default windowing support in clib
set DEFAULT_WINDOWING=0

REM Set this variable to 0 to suppress documentation build
set DOC_BUILD=0

REM Documentation related variables
REM set appropriate variables to blank for help compilers which you haven't installed
set WIN95HC=hcrtf
set OS2HC=ipfc

REM Subdirectory to be used for bootstrapping
set OBJDIR=bootstrp

REM Subdirectory to be used for building prerequisite utilities
set PREOBJDIR=prebuild

REM Invoke the batch file for the common environment
call %OWROOT%\cmnvars.bat

cd %DEVDIR%
