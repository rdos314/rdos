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
# dhcp.cpp
# DHCP command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include "rdos.h"

#include "datetime.h"
#include "cmdhelp.h"
#include "lang.h"
#include "dhcp.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDhcpFactory::TDhcpFactory
#
#   Purpose....: Constructor for TDhcpFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDhcpFactory::TDhcpFactory()
  : TCommandFactory("DHCP")
{
}

/*##########################################################################
#
#   Name       : TDhcpFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TDhcpFactory::Create(TSession *session, const char *param)
{
    return new TDhcpCommand(session, param);
}

/*##########################################################################
#
#   Name       : TDhcpCommand::TDhcpCommand
#
#   Purpose....: Constructor for TDhcpCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDhcpCommand::TDhcpCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_DHCP);
}

/*##########################################################################
#
#   Name       : TDhcpCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDhcpCommand::Execute(char *param)
{
    int i;
    long ip;
    unsigned long Temp;
    unsigned long n0, n1, n2, n3;
    unsigned long msb, lsb;
    char str[40];

    for (i = 0; i < 256; i++)
    {
        ip = RdosGetDhcpEntry(i, &msb, &lsb);

        if (ip)
        {
            TDateTime time(msb, lsb);

            Temp = (unsigned long)ip;
	    n3 = Temp & 0xFF;
            Temp = Temp >> 8;
            n2 = Temp & 0xFF;
            Temp = Temp >> 8;
            n1 = Temp & 0xFF;
            Temp = Temp >> 8;
            n0 = Temp & 0xFF;
            sprintf(str, "%d.%d.%d.%d, %04d-%02d-%02d %02d.%02d\r\n", n3, n2, n1, n0, time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin());
            Write(str);
        }
    }

    return 0;
}

