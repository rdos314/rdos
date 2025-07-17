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
# tcpwd.cpp
# TCP-base remote server for WD
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "wdfact.h"
#include "wdfile.h"
#include "wdfinfo.h"
#include "wdenv.h"
#include "wdrtrd.h"
#include "wdcap.h"
#include "wdasync.h"

char LogFile[256];
TFile *File = 0;

static void OnMsg(TWdSocketServerFactory *fact, const char *msg)
{
    char timestr[128];
    unsigned long msb, lsb;
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    TString str;

    RdosGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us); 

    sprintf(timestr, "%4d-%02d-%02d %02d.%02d.%02d,%03d %03d ", 
                            year, month, day,
                            hour, min, sec,
                            ms, us);
    str = timestr;
    str += msg;
    str += "\r\n";        

    File->Write(str.GetData(), str.GetSize());
}

int main(int argc, char **argv)
{
    LogFile[0] = 0;
    
    if (argc > 1)
    {
        strcpy(LogFile, argv[1]);
        strlwr(LogFile);
        File = new TFile(LogFile, 0);
    }

    TWdSupplFactory *suppl;
    TWdSocketServerFactory fact(0xDEB, 16, 0x7000);

    if (File)
        fact.OnMsg = OnMsg;

    suppl = new TWdFileFactory(&fact);
    suppl = new TWdFileInfoFactory(&fact);
    suppl = new TWdEnvFactory(&fact);
    suppl = new TWdRunThreadFactory(&fact);
    suppl = new TWdCapFactory(&fact);
    suppl = new TWdAsyncFactory(&fact);

    for (;;)
        fact.WaitForever();
}
