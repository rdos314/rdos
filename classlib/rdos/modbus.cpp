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
TModbus::TModbus(TModbusDevice *Device, char Address)
{
    FDevice = Device;
    FAddress = Address;
    FBigEndian = TRUE;
    FReplySize = 0;
    FRetryCount = 10;
}

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
TModbus::TModbus()
{
    FDevice = 0;
    FAddress = 0;
    FBigEndian = TRUE;
    FReplySize = 0;
    FRetryCount = 10;
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
#   Name       : TModbus::GetDevice
#
#   Purpose....: Get modbus device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TModbusDevice *TModbus::GetDevice()
{
    return FDevice;
}

/*##########################################################################
#
#   Name       : TModbus::DisableRetries
#
#   Purpose....: Disable retries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::DisableRetries()
{
    FRetryCount = 1;
}

/*##########################################################################
#
#   Name       : TModbus::EnableRetries
#
#   Purpose....: Enable retries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::EnableRetries(int count)
{
    FRetryCount = count;
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
    int datalen;
    int replylen;
    int ok = FALSE;
    int tries;

    for (tries = 0; tries < FRetryCount && !ok; tries++)
    {
        msg[0] = FAddress;
        msg[1] = FunctionCode;

        if (size < 252)
        {
            memcpy(&msg[2], buf, size);
            ok = FDevice->SendAndReceive(msg, size + 2, reply, &datalen, &replylen);
        }
    }

    if (ok)
        return datalen;
    else
    {
        FDevice->Reset();
        RdosWaitMilli(5000);

        for (tries = 0; tries < 10 && !ok; tries++)
        {
            msg[0] = FAddress;
            msg[1] = FunctionCode;

            if (size < 252)
            {
                memcpy(&msg[2], buf, size);
                ok = FDevice->SendAndReceive(msg, size + 2, reply, &datalen, &replylen);
            }
        }

        if (ok)
            return datalen;
        else
            return 0;
    }
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

/*##########################################################################
#
#   Name       : TModbus::ReqHoldingRegisters
#
#   Purpose....: Read multiple holding registers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::ReqHoldingRegisters(int Reg, int Count)
{
    short int temp;
    char msg[256];
    int datalen;
    int ok = FALSE;

    if (Reg > 40000)
    {
        msg[0] = FAddress;
        msg[1] = 3;

        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[2], &temp, 2);

        temp = Count;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&msg[4], &temp, 2);

        ok = FDevice->SendAndReceive(msg, 6, FReplyBuf, &datalen, &FReplySize);

        if (ok && datalen >= 2)
        {
            FStartReg = Reg;
            FRegCount = Count;
            return TRUE;
        }
    }
    FReplySize = 0;
    return FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::GetReplySize
#
#   Purpose....: Get reply size (multiple registers)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::GetReplySize()
{
    return FReplySize;
}

/*##########################################################################
#
#   Name       : TModbus::GetReplyBuf
#
#   Purpose....: Get reply buf (multiple registers)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::GetReplyBuf(char *buf)
{
    memcpy(buf, FReplyBuf, FReplySize);
}

/*##########################################################################
#
#   Name       : TModbus::SetBufferedRegisters
#
#   Purpose....: Set multiple registers buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::SetBufferedRegisters(int Reg, int Count, const char *Buf, int Size)
{
    int datalen = 0;
    int replylen = 0;
    int ok = FALSE;
    char crc[2];

    if (Size < 100 && Size >= 3)
    {
        switch (Buf[1])
        {
            case 1:
            case 2:
            case 3:
            case 4:
                datalen = (unsigned int)Buf[2];
                replylen = datalen + 5;
                break;

            case 5:
            case 6:
            case 15:
            case 16:
                datalen = 4;
                replylen = 8;
                break;
        }

        if (replylen == Size)
            ok = TRUE;

        if (ok)
        {
            FDevice->CalcCrc(Buf, replylen - 2, crc);

            if (Buf[replylen - 2] != crc[0])
                ok = FALSE;

            if (Buf[replylen - 1] != crc[1])
                ok = FALSE;
        }
    }

    if (ok)
    {
        FStartReg = Reg;
        FRegCount = Count;
        memcpy(FReplyBuf, Buf, Size);
        FReplySize = Size;
    }
    else
        FReplySize = 0;

    return ok;
}

/*##########################################################################
#
#   Name       : TModbus::GetBufferedHoldingRegister
#
#   Purpose....: Read buffered holding register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::GetBufferedHoldingRegister(int Reg, int *Val)
{
    int ok = FALSE;
    int RelReg = Reg - FStartReg;
    int len;
    short int temp;

    if (FReplySize >= 3)
        ok = TRUE;

    if (ok)
        if (FReplyBuf[1] != 3)
            ok = FALSE;

    if (ok)
        if (RelReg < 0 || RelReg >= FRegCount)
            ok = FALSE;

    if (ok)
    {
        len = (unsigned int)FReplyBuf[2];
        if (len != 2 * FRegCount)
            ok = FALSE;
    }

    if (ok)
    {
        memcpy(&temp, &FReplyBuf[3 + 2 * RelReg], 2);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        *Val = temp;
    }
    return ok;
}

/*##########################################################################
#
#   Name       : TModbus::GetBufferedHoldingRegisterABCD
#
#   Purpose....: Read buffered holding register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::GetBufferedHoldingRegisterABCD(int Reg, float *Val)
{
    int ok = FALSE;
    int RelReg = Reg - FStartReg;
    int len;
    int temp;

    if (FReplySize >= 3)
        ok = TRUE;

    if (ok)
        if (FReplyBuf[1] != 3)
            ok = FALSE;

    if (ok)
        if (RelReg < 0 || RelReg + 1 >= FRegCount)
            ok = FALSE;

    if (ok)
    {
        len = (unsigned int)FReplyBuf[2];
        if (len != 2 * FRegCount)
            ok = FALSE;
    }

    if (ok)
    {
        memcpy(&temp, &FReplyBuf[3 + 2 * RelReg], 4);
        if (FBigEndian)
            temp = RdosSwapLong(temp);
        memcpy(Val, &temp, 4);
    }
    return ok;
}

/*##########################################################################
#
#   Name       : TModbus::StartWritePresetRegisters
#
#   Purpose....: Start write multiple preset registers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::StartWritePresetRegisters(int Reg, int Count, int Default)
{
    int i;
    short int temp;

    if (Reg > 40000)
    {
        FStartReg = Reg;
        FRegCount = Count;

        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&FWriteBuf[0], &temp, 2);

        temp = Count;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(&FWriteBuf[2], &temp, 2);

        FWriteBuf[4] = 2 * Count;

        temp = Default;
        if (FBigEndian)
            temp = RdosSwapShort(temp);

        for (i = 0; i < Count; i++)
            memcpy(&FWriteBuf[5 + 2 * i], &temp, 2);
    }
}

/*##########################################################################
#
#   Name       : TModbus::AddPresetRegister
#
#   Purpose....: Add preset register to write req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::AddPresetRegister(int Reg, int Val)
{
    int RelReg = Reg - FStartReg;
    short int temp;

    if (RelReg < FRegCount)
    {
        temp = Val;
        if (FBigEndian)
            temp = RdosSwapShort(temp);

        memcpy(&FWriteBuf[5 + 2 * RelReg], &temp, 2);
    }
}

/*##########################################################################
#
#   Name       : TModbus::AddPresetRegisterABCD
#
#   Purpose....: Add ABCD preset register to write req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbus::AddPresetRegisterABCD(int Reg, float Val)
{
    int RelReg = Reg - FStartReg;
    int itemp;

    if (RelReg < FRegCount - 1)
    {
        memcpy(&itemp, &Val, 4);
        if (FBigEndian)
            itemp = RdosSwapLong(itemp);
        memcpy(&FWriteBuf[5 + 2 * RelReg], &itemp, 4);
    }
}

/*##########################################################################
#
#   Name       : TModbus::DoWritePresetRegisters
#
#   Purpose....: Do a multiple preset register write
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbus::DoWritePresetRegisters()
{
    int len;
    char reply[100];

    len = Session(16, FWriteBuf, 5 + 2 * FRegCount, reply);

    if (len == 4)
        if (memcmp(FWriteBuf, &reply[2], 4) == 0)
            return TRUE;

    return FALSE;
}

/*##################  TModbusDevice::TModbusDevice  ###############
*   Purpose....: Constructor for TModbusDevice                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TModbusDevice::TModbusDevice(TSerialDevice *serial)
 : FSection("Modbus")
{
    Init();

    FSerial = serial;
}

/*##################  TModbusDevice::TModbusDevice  ###############
*   Purpose....: Constructor for TModbusDevice                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TModbusDevice::TModbusDevice(long Ip, int Port)
 : FSection("Modbus")
{
    Init();

    FIp = Ip;
    FPort = Port;
}

/*##################  TModbusDevice::TModbusDevice  ###############
*   Purpose....: Destructor for TModbusDevice                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TModbusDevice::~TModbusDevice()
{
}

/*##################  TModbusDevice::Init  ###############
*   Purpose....: Init                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TModbusDevice::Init()
{
    int i;

    FSerial = 0;
    FIp = 0;
    FPort = 0;
    FSocket = 0;

    FHasEcho = FALSE;
    FTimeout = 250;

    for (i = 0; i < 0x80; i++)
        FModbusArr[i] = 0;
}

/*##################  TModbusDevice::Add  ###############
*   Purpose....: Add a specific address                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TModbusDevice::Add(int Address, TModbus *Modbus)
{
    if (Address < 0x80)
        FModbusArr[Address] = Modbus;
}

/*##################  TModbusDevice::IsUsed  ###############
*   Purpose....: Check if specific address is used                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TModbusDevice::IsUsed(int Address)
{
    if (Address < 0x80)
        if (FModbusArr[Address])
            return TRUE;
    return FALSE;
}

/*##################  TModbusDevice::GetSerial  ###############
*   Purpose....: Get serial device                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TSerialDevice *TModbusDevice::GetSerial()
{
    return FSerial;
}

/*##################  TModbusDevice::Reset  ###############
*   Purpose....: Reset serial device                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TModbusDevice::Reset()
{
    if (FSerial)
        FSerial->Reset();
    else
    {
        if (FSocket)
        {
            FSocket->Close();
            delete FSocket;
            FSocket = 0;
        }
    }
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
void TModbusDevice::EnableEcho()
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
void TModbusDevice::DisableEcho()
{
    FHasEcho = FALSE;
}

/*##########################################################################
#
#   Name       : TModbus::SetTimeout
#
#   Purpose....: Set timeout
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbusDevice::SetTimeout(int ms)
{
    FTimeout = ms;
}

/*##########################################################################
#
#   Name       : TModbusDevice::CalcCrc
#
#   Purpose....: Calc CRC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbusDevice::CalcCrc(const char *buf, int size, char crc[2])
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
#   Name       : TModbusDevice::Write
#
#   Purpose....: Write data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TModbusDevice::Write(const char *msg, int size)
{
    if (FSerial)
        FSerial->Write(msg, size);
    else
    {
        if (FSocket && !FSocket->IsOpen())
        {
            delete FSocket;
            FSocket = 0;
        }

        if (!FSocket)
        {
            FSocket = new TTcpSocket(FIp, FPort, 5000, 0x2000);
            FSocket->WaitForConnection(5000);
        }

        if (FSocket && FSocket->IsOpen())
            if (FSocket->GetWriteSpace() >= size)
                FSocket->Write(msg, size);
    }
}

/*##########################################################################
#
#   Name       : TModbusDevice::WaitForData
#
#   Purpose....: Wait for data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbusDevice::WaitForData(int timeout)
{
    if (FSerial)
        return FSerial->WaitForChar(timeout);
    else
    {
        if (FSocket && FSocket->IsOpen())
            return FSocket->WaitForData(timeout);
        else
            return FALSE;
    }
}

/*##########################################################################
#
#   Name       : TModbusDevice::Read
#
#   Purpose....: Read single char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TModbusDevice::Read()
{
    if (FSerial)
        return FSerial->Read();
    else
    {
        if (FSocket)
            return FSocket->Read();
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : TModbusDevice::SendAndReceive
#
#   Purpose....: Send message & receive answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TModbusDevice::SendAndReceive(const char *buf, int size, char *reply, int *datalen, int *replylen)
{
    char msg[256];
    char crc[2];
    char ch;
    int pos;
    int ok = FALSE;

    FSection.Enter();

    if (size < 254)
    {
        CalcCrc(buf, size, crc);
        memcpy(msg, buf, size);
        memcpy(msg+size, crc, 2);

        Write(msg, size + 2);

        if (FHasEcho)
        {
            pos = 0;
            while (ok && pos < size + 2 && ch == msg[pos])
            {
                ok = WaitForData(FTimeout);
                if (ok)
                {
                    ch = Read();
                    pos++;
                }
            }
        }

        pos = 0;

        ok = WaitForData(500);
        if (ok)
        {

            ch = Read();
            while (ok && ch != msg[0])
            {
                ok = WaitForData(FTimeout);
                if (ok)
                    ch = Read();
            }

            if (ok)
            {
                ok = WaitForData(FTimeout);
                if (ok)
                {
                    ch = Read();
                    if (ch != msg[1])
                        ok = FALSE;
                }
            }
        }

        if (ok)
        {
            reply[0] = msg[0];
            reply[1] = msg[1];

            ok = WaitForData(250);
            if (ok)
                reply[2] = Read();
        }

        if (ok)
        {
            switch (reply[1])
            {
                case 1:
                case 2:
                case 3:
                case 4:
                    *datalen = (unsigned int)reply[2];
                    *replylen = *datalen + 5;
                    break;

                case 5:
                case 6:
                case 15:
                case 16:
                    *datalen = 4;
                    *replylen = 8;
                    break;

                default:
                    ok = FALSE;
                    break;
            }

            pos = 3;

            while (ok && pos < *replylen)
            {
                ok = WaitForData(250);
                if (ok)
                {
                    reply[pos] = Read();
                    pos++;
                }
            }

            if (ok)
            {
                CalcCrc(reply, *replylen - 2, crc);

                if (reply[*replylen - 2] != crc[0])
                    ok = FALSE;

                if (reply[*replylen - 1] != crc[1])
                    ok = FALSE;
            }
        }
    }

    if (!ok)
        while (WaitForData(2 * FTimeout))
            Read();

    FSection.Leave();

    return ok;
}
