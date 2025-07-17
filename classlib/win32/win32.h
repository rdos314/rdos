/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# win32.h
# Low level functions
#
########################################################################*/

#ifndef _WIN32_H
#define _WIN32_H

void WaitMilli(long MilliSec);

#ifdef __cplusplus
extern "C" {
#endif

void __stdcall Win32GetTics(unsigned long wintick, unsigned long *msb, unsigned long *lsb);
void __stdcall Win32TicsToRecord(unsigned long msb, unsigned long lsb, int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);
void __stdcall Win32RecordToTics(unsigned long *msb, unsigned long *lsb, int year, int month, int day, int hour, int min, int sec, int milli);
void __stdcall Win32AddTics(unsigned long *msb, unsigned long *lsb, long tics);
void __stdcall Win32AddMilli(unsigned long *msb, unsigned long *lsb, long ms);
void __stdcall Win32AddSec(unsigned long *msb, unsigned long *lsb, long sec);
void __stdcall Win32AddMin(unsigned long *msb, unsigned long *lsb, long min);
void __stdcall Win32AddHour(unsigned long *msb, unsigned long *lsb, long hour);
void __stdcall Win32AddDay(unsigned long *msb, unsigned long *lsb, long day);

void __stdcall Win32InitCrc(unsigned short int *buf, unsigned short int poly);
unsigned short int __stdcall Win32CalcCrc(unsigned short int *buf, unsigned short int crcin, const char *data, int size);


#ifdef __cplusplus
}
#endif

#endif

