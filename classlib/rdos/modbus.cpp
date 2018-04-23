/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# along wit this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# modbus.cpp
# Modbus class
#
########################################################################*/

#include <string.h>
#include "modbus.h"

#include <rdos.h>

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TModbus::TModbus
#
#   Purpose....: Constructor for TModbus
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TModbus::TModbus(TSerialDevice *Serial, char Address)
{
    FSerial = Serial;
    FAddress = Address;
}

/*##########################################################################
#
#   Name       : TModbus::~TModbus
#
#   Purpose....: Destructor for TModbus
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TModbus::~TModbus()
{
}

/*##########################################################################
#
#   Name       : TModbus::CalcCrc
#
#   Purpose....: Calc CRC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::CalcCrc(const char *buf, int size, char crc[2])
{
    int lcrc = 0xFFFF;
    int pos;
    int i;

    for (pos = 0; pos < size; pos++)
    {
        lcrc ^= (int)buf[pos];

        for (i = 8; i != 0; i--)
        {
            if ((lcrc & 0x0001) != 0)
            { 
                lcrc >>= 1;
                lcrc ^= 0xA001;
            }
            else
                lcrc >>= 1;
        }
    }

    crc[0] = (char)lcrc;
    crc[1] = (char)(lcrc >> 8);
}


/*##########################################################################
#
#   Name       : TModbus::SendAndReceive
#
#   Purpose....: Send message & receive answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::SendAndReceive(const char *buf, int size, char *reply)
{
    char msg[256];
    char crc[2];
    char ch;
    int pos;
    int i;
    int len;
    int ok = FALSE;

    if (size < 254)
    {
        CalcCrc(buf, size, crc);
        memcpy(msg, buf, size);
        memcpy(msg+size, crc, 2);

        FSerial->Write(msg, size + 2);

        ok = FSerial->WaitForChar(500);
        if (ok)
        {
            ch = FSerial->Read();
            while (ok && ch != msg[0])
            {
                ok = FSerial->WaitForChar(250);
                if (ok)
                    ch = FSerial->Read();
            }

            pos = 0;

            while (ok && pos < size + 2 && ch == msg[pos])
            {
                ok = FSerial->WaitForChar(250);
                if (ok)
                {
                    ch = FSerial->Read();
                    pos++;
                }
            }

            if (ok)
            {
                if (pos == size + 2)
                {
                    pos = 0;

                    while (ok && pos < size + 2 && ch == msg[pos])
                    {
                        ok = FSerial->WaitForChar(250);
                        if (ok)
                        {
                            ch = FSerial->Read();
                            pos++;
                        }
                    }
                }
                else
                   for (i = 0; i < pos; i++)
                       reply[i] = msg[i];
            }
        }

        if (pos < 2)
            ok = FALSE;

        if (pos == size + 2)
            ok = FALSE;

        if (ok)
        {
            reply[pos] = ch;
            pos++;
        }

        while (ok && pos < 3)
        {
            ok = FSerial->WaitForChar(250);
            if (ok)
            {
                reply[pos] = FSerial->Read();
                pos++;
            }
        }

        switch (reply[1])
        {
            case 1:
            case 2:
            case 3:
            case 4:
                len = 5 + (unsigned int)reply[2];
                break;

            case 5:
            case 6:
            case 15:
            case 16:
                len = 8;
                break;

            default:
                ok = FALSE;
                break;
        }

        while (ok && pos < len)
        {
            ok = FSerial->WaitForChar(250);
            if (ok)
            {
                reply[pos] = FSerial->Read();
                pos++;
            }
        }

        if (ok)
        {
            CalcCrc(reply, len - 2, crc);

            if (reply[len - 2] != crc[0])
                ok = FALSE;

            if (reply[len - 1] != crc[1])
                ok = FALSE;
        }
    }

    if (ok)
        return len;
    else
        return 0;
}
