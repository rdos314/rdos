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
 : FSection("Modbus")
{
    FSerial = Serial;
    FAddress = Address;
    FBigEndian = TRUE;
    FHasEcho = FALSE;
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
#   Name       : TModbus::GetSerial
#
#   Purpose....: Get serial device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice *TModbus::GetSerial()
{
    return FSerial;
}

/*##########################################################################
#
#   Name       : TModbus::EnableEcho
#
#   Purpose....: Enable echo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::EnableEcho()
{
    FHasEcho = TRUE;
}

/*##########################################################################
#
#   Name       : TModbus::DisableEcho
#
#   Purpose....: Disable echo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::DisableEcho()
{
    FHasEcho = FALSE;
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
    int replylen;
    int datalen;
    int ok = FALSE;

    FSection.Enter();

    if (size < 254)
    {
        CalcCrc(buf, size, crc);
        memcpy(msg, buf, size);
        memcpy(msg+size, crc, 2);

        FSerial->Write(msg, size + 2);

        if (FHasEcho)
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

        pos = 0;

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

            if (ok)
            {
                ok = FSerial->WaitForChar(250);
                if (ok)
                {
                    ch = FSerial->Read();
                    if (ch != msg[1])
                        ok = FALSE;
                }
            }
        }

        if (ok)
        {
            reply[0] = msg[0];
            reply[1] = msg[1];

            ok = FSerial->WaitForChar(250);
            if (ok)
                reply[2] = FSerial->Read();
        }

        if (ok)
        {
            switch (reply[1])
            {
                case 1:
                case 2:
                case 3:
                case 4:
                    datalen = (unsigned int)reply[2];
                    replylen = datalen + 5;
                    break;

                case 5:
                case 6:
                case 15:
                case 16:
                    datalen = 4;
                    replylen = 8;
                    break;

                default:
                    ok = FALSE;
                    break;
            }

            pos = 3;

            while (ok && pos < replylen)
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
                CalcCrc(reply, replylen - 2, crc);
  
                if (reply[replylen - 2] != crc[0])
                    ok = FALSE;

                if (reply[replylen - 1] != crc[1])
                    ok = FALSE;
            }
        }
    }

    FSection.Leave();

    if (ok)
        return datalen;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TModbus::Session
#
#   Purpose....: Do a session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::Session(char FunctionCode, const char *buf, int size, char *reply)
{
    char msg[256];
    int rlen = 0;

    msg[0] = FAddress;
    msg[1] = FunctionCode;

    if (size < 252)
    {
        memcpy(&msg[2], buf, size);
        rlen = SendAndReceive(msg, size + 2, reply);
    }
    return rlen;
}

/*##########################################################################
#
#   Name       : TModbus::ReadCoilStatus
#
#   Purpose....: Read status of single coil
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadCoilStatus(int Coil)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Coil > 0)
    {
        temp = (short int)(Coil - 1);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(1, msg, 4, reply);

        if (len > 0)
            if (reply[3] & 1)
                return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::ReadInputStatus
#
#   Purpose....: Read status of single input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadInputStatus(int Input)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Input > 10000)
    {
        temp = (short int)(Input - 10001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(2, msg, 4, reply);

        if (len >= 1)
        {
            temp = (unsigned char)reply[3];
            return temp;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TModbus::ReadHoldingRegister
#
#   Purpose....: Read single holding register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadHoldingRegister(int Reg)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(3, msg, 4, reply);

        if (len >= 2)
        {
            memcpy(&temp, &reply[3], 2);
            if (FBigEndian)
                temp = RdosSwapShort(temp);
            return temp;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TModbus::ReadInputRegister
#
#   Purpose....: Read single input register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadInputRegister(int Reg)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Reg > 30000)
    {
        temp = (short int)(Reg - 30001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(4, msg, 4, reply);

        if (len >= 2)
        {
            memcpy(&temp, &reply[3], 2);
            if (FBigEndian)
                temp = RdosSwapShort(temp);
            return temp;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TModbus::ReadCoilStatus
#
#   Purpose....: Read status of single coil
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadCoilStatus(int Coil, int *Val)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Coil > 0)
    {
        temp = (short int)(Coil - 1);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(1, msg, 4, reply);

        if (len > 0)
        {
            if (reply[3] & 1)
                *Val = TRUE;
            else
                *Val = FALSE;
            return TRUE;
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::ReadInputStatus
#
#   Purpose....: Read status of single input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadInputStatus(int Input, int *Val)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Input > 10000)
    {
        temp = (short int)(Input - 10001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(2, msg, 4, reply);

        if (len >= 1)
        {
            temp = (unsigned char)reply[3];
            *Val = temp;
            return TRUE;
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::ReadHoldingRegister
#
#   Purpose....: Read single holding register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadHoldingRegister(int Reg, int *Val)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(3, msg, 4, reply);

        if (len >= 2)
        {
            memcpy(&temp, &reply[3], 2);
            if (FBigEndian)
                temp = RdosSwapShort(temp);
            *Val = temp;
            return TRUE;
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::ReadInputRegister
#
#   Purpose....: Read single input register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadInputRegister(int Reg, int *Val)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Reg > 30000)
    {
        temp = (short int)(Reg - 30001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(4, msg, 4, reply);

        if (len >= 2)
        {
            memcpy(&temp, &reply[3], 2);
            if (FBigEndian)
                temp = RdosSwapShort(temp);
            *Val = temp;
            return TRUE;
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::PresetRegister
#
#   Purpose....: Preset single register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::PresetRegister(int Reg, int Val)
{
    int len;
    short int temp;
    char msg[4];
    char reply[100];
 
    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = (short int)Val;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(6, msg, 4, reply);

        if (len == 4)
            if (memcmp(msg, &reply[2], 4) == 0)
                return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::ReadHoldingRegisterABCD
#
#   Purpose....: Read single holding register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReadHoldingRegisterABCD(int Reg, float *Val)
{
    int len;
    short int temp;
    int itemp;
    char msg[4];
    char reply[100];
 
    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 2;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        len = Session(3, msg, 4, reply);

        if (len >= 4)
        {
            memcpy(&itemp, &reply[3], 4);
            if (FBigEndian)
                itemp = RdosSwapLong(itemp);
            memcpy(Val, &itemp, 4);
            return TRUE;
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::PresetRegisterABCD
#
#   Purpose....: Preset single register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::PresetRegisterABCD(int Reg, float Val)
{
    int len;
    short int temp;
    int itemp;
    char msg[9];
    char reply[100];
 
    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[0], &temp, 2);

        temp = 2;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        msg[4] = 4;

        memcpy(&itemp, &Val, 4);
        if (FBigEndian)
            itemp = RdosSwapLong(itemp);
        memcpy(&msg[5], &itemp, 4);

        len = Session(16, msg, 9, reply);

        if (len == 4)
            if (memcmp(msg, &reply[2], 4) == 0)
                return TRUE;
    }
    return FALSE;
}
