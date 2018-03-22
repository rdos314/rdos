/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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
