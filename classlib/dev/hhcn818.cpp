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
# hhcn818.cpp
# HHC-N818OP relay driver
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "rdos.h"
#include "hhcn818.h"

/*##########################################################################
#
#   Name       : THhcRelay::THhcRelay
#
#   Purpose....: HHC-N818 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THhcRelay::THhcRelay(char *HostStr)
{
    int size = strlen(HostStr);
    char *ptr;
    int i;

    FOnline = false;

    for (i = 0; i < 8; i++)
        FRelayArr[i] = false;

    FHostStr = new char[size + 1];
    strcpy(FHostStr, HostStr);

    ptr = strchr(FHostStr, ':');
    if (ptr)
    {
        *ptr = 0;
        ptr++;
        FPort = atoi(ptr);
    }
    else
        FPort = 5000;

    FIP = 0;

    Start("HHC-N818OP", 0x8000);
}

/*##########################################################################
#
#   Name       : THhcRelay::~THhcRelay
#
#   Purpose....: HHC-N818 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THhcRelay::~THhcRelay()
{
}

/*##########################################################################
#
#   Name       : THhcRelay::IsOnline
#
#   Purpose....: Is online?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THhcRelay::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleName
#
#   Purpose....: Handle device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleName(char *str)
{
    char *ptr;
    int size;

    if (str[4] == '=')
    {
        str[4] = 0;
        if (!strcmp(str, "name"))
        {
            ptr = str + 5;
            size = strlen(ptr);
            if (ptr[0] == '"' && ptr[size - 1] == '"')
            {
                ptr[size - 1] = 0;
                ptr++;
                FName = ptr;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleData
#
#   Purpose....: Handle device data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleData()
{
    char str[80];
    int count;
    int size = FSocket->GetSize();

    if (size > 0 && size < 80)
    {
        count = FSocket->Read(str, size);
        if (size == count)
        {
            str[size] = 0;

            switch (str[0])
            {
                case 'n':
                    HandleName(str);
                    break;
            }
        }
    }
    else
    {
        FSocket->Close();
        delete FSocket;
        FSocket = 0;
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::Execute()
{
    char ch;
    int size;
    char *ptr;
    int i;
    struct hostent *host;

    FOnline = false;

    while (FIP == 0)
    {
        host = gethostbyname(FHostStr);
        if (host)
            FIP = *(long *)host->h_addr_list[0];
        else
            RdosWaitMilli(500);
    }

    for (;;)
    {
        FSocket = new TTcpSocket(FIP, FPort, 5000, 0x2000);
        FSocket->WaitForConnection(5000);

        if (FSocket->IsOpen())
        {
            FSocket->Write("name");
            FSocket->Push();
            if (FSocket->WaitForData(1000))
                HandleData();

            FSocket->Write("read");
            FSocket->Push();
            if (FSocket->WaitForData(1000))
                HandleData();

            FSocket->Write("input");
            FSocket->Push();
            if (FSocket->WaitForData(1000))
                HandleData();
        }

        while (FSocket->IsOpen())
        {
            if (FSocket->WaitForData(1000))
                HandleData();
        }

        delete FSocket;
    }
}
