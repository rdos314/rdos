/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# ddns.cpp
# ddns service using dreamhost.com
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "rdos.h"
#include "ddns.h"
#include "ini.h"

/*##########################################################################
#
#   Name       : TDdns::TDdns
#
#   Purpose....: Ddns constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDdns::TDdns()
{
    int ok;
    char buf[50];

    TIniFile ini;

    ini.GotoSection("DDNS");

    ok = ini.ReadVar("IP", buf, 49);
    if (ok)
       FIp = buf;

    ok = ini.ReadVar("Key", buf, 49);
    if (ok)
       FKey = buf;
}

/*##########################################################################
#
#   Name       : TDdns::~TDdns
#
#   Purpose....: Ddns destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDdns::~TDdns()
{
}

/*##########################################################################
#
#   Name       : TDdns::GetJsonIp
#
#   Purpose....: Get json ip
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TDdns::GetJsonIp(const char *str)
{
    TString myip;

    TJsonDocument json(str);
    TJsonCollection *root = json.GetRoot();
    TJsonObject *obj;

    return myip;
}

/*##########################################################################
#
#   Name       : TDdns::GetMyIp
#
#   Purpose....: Get my public ip
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TDdns::GetMyIp()
{
    TTcpSocket socket(RdosNameToIp("api.dreamhost.com"), 80, 10000, 0x2000);
    char *buf = new char[2048];
    int size = 0;
    char *ptr;
    char *tempptr;
    TString myip;
    
    socket.WaitForConnection(10000);
    if (socket.IsOpen())
    {
        strcpy(buf, "GET /?key=YZKUY9NU86R56TV6&cmd=dns-list_records&type=A&format=json HTTP/1.1\r\n");
        strcat(buf, "Host: api.dreamhost.com\r\n");
        strcat(buf, "Accept: application/json\r\n");
        strcat(buf, "User-Agent: RDOS\r\n");
        strcat(buf, "\r\n");

        socket.Write(buf);
        socket.Push();

        socket.WaitForData(10000);

        while (socket.WaitForData(500) && size < 2047)
        { 
            buf[size] = socket.Read();
            size++;
        }

        buf[size] = 0;

        ptr = buf;
        while (ptr[1] != 0xd)
        {
            tempptr = strchr(ptr + 1, 0xd);
            if (tempptr)
                ptr = tempptr + 1;
            else
                break;
        }

        while (*ptr == 0xa || *ptr == 0xd)
            ptr++;

        if (*ptr)
            myip = GetJsonIp(ptr);
    }

    return myip;
}

/*##########################################################################
#
#   Name       : TDdns::UpdateIp
#
#   Purpose....: Update ip
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDdns::UpdateIp()
{
    TString currip = GetMyIp();
}
