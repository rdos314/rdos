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

    if (Coil > 0)
    {
        temp = (short int)(Coil - 1);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 1, msg, 4);

        if (len > 0)
            if (FReplyBuf[1] & 1)
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

    if (Input > 10000)
    {
        temp = (short int)(Input - 10001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 2, msg, 4);

        if (len >= 1)
        {
            temp = (unsigned char)FReplyBuf[1];
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

    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 3, msg, 4);

        if (len >= 2)
        {
            memcpy(&temp, FReplyBuf + 1, 2);
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

    if (Reg > 30000)
    {
        temp = (short int)(Reg - 30001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 4, msg, 4);

        if (len >= 2)
        {
            memcpy(&temp, FReplyBuf + 1, 2);
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

    if (Coil > 0)
    {
        temp = (short int)(Coil - 1);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 1, msg, 4);

        if (len > 0)
        {
            if (FReplyBuf[1] & 1)
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

    if (Input > 10000)
    {
        temp = (short int)(Input - 10001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 2, msg, 4);

        if (len >= 1)
        {
            temp = (unsigned char)FReplyBuf[1];
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

    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 3, msg, 4);

        if (len >= 2)
        {
            memcpy(&temp, FReplyBuf + 1, 2);
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

    if (Reg > 30000)
    {
        temp = (short int)(Reg - 30001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 1;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 4, msg, 4);

        if (len >= 2)
        {
            memcpy(&temp, FReplyBuf + 1, 2);
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

    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = (short int)Val;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 6, msg, 4);

        if (len == 4)
            if (memcmp(msg, FReplyBuf, 4) == 0)
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

    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 2;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        len = FDevice->Session(this, 3, msg, 4);

        if (len >= 4)
        {
            memcpy(&itemp, FReplyBuf + 1, 4);
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

    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = 2;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        msg[4] = 4;

        memcpy(&itemp, &Val, 4);
        if (FBigEndian)
            itemp = RdosSwapLong(itemp);
        memcpy(msg + 5, &itemp, 4);

        len = FDevice->Session(this, 16, msg, 9);

        if (len == 4)
            if (memcmp(msg, FReplyBuf, 4) == 0)
                return TRUE;
    }
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
        memcpy(FWriteBuf, &temp, 2);

        temp = Count;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(FWriteBuf + 2, &temp, 2);

        FWriteBuf[4] = 2 * Count;

        temp = Default;
        if (FBigEndian)
            temp = RdosSwapShort(temp);

        for (i = 0; i < Count; i++)
            memcpy(FWriteBuf + 5 + 2 * i, &temp, 2);
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

        memcpy(FWriteBuf + 5 + 2 * RelReg, &temp, 2);
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
        memcpy(FWriteBuf + 5 + 2 * RelReg, &itemp, 4);
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

    len = FDevice->Session(this, 16, FWriteBuf, 5 + 2 * FRegCount);

    if (len == 4)
        if (memcmp(FWriteBuf, FReplyBuf, 4) == 0)
            return TRUE;

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
    int len;
    short int temp;
    char msg[256];
    int datalen;
    int ok = FALSE;

    if (Reg > 40000)
    {
        temp = (short int)(Reg - 40001);
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg, &temp, 2);

        temp = Count;
        if (FBigEndian)
            temp = RdosSwapShort(temp);
        memcpy(msg + 2, &temp, 2);

        datalen = FDevice->Session(this, 3, msg, 4);

        if (datalen >= 2)
        {
            FStartReg = Reg;
            FRegCount = Count;
            return TRUE;
        }
    }
    FReplySize = 0;
    return FALSE;
}

/*##################  TModbusDevice::TModbusDevice  ###############
*   Purpose....: Constructor for TModbusDevice                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TModbusDevice::TModbusDevice()
 : FSection("Modbus")
{
    int i;

    FTimeout = 250;

    for (i = 0; i < 0x80; i++)
        FModbusArr[i] = 0;
}

/*##################  TModbusDevice::~TModbusDevice  ###############
*   Purpose....: Destructor for TModbusDevice                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TModbusDevice::~TModbusDevice()
{
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

/*##########################################################################
#
#   Name       : TModbusDevice::SetTimeout
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

/*##################  TSerialModbusDevice::TSerialModbusDevice  ###############
*   Purpose....: Constructor for TSerialModbusDevice                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TSerialModbusDevice::TSerialModbusDevice(TSerialDevice *serial)
{
    FSerial = serial;
    FHasEcho = FALSE;
}

/*##################  TSerialModbusDevice::~TSerialModbusDevice  ###############
*   Purpose....: Destructor for TSerialModbusDevice                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TSerialModbusDevice::~TSerialModbusDevice()
{
}

/*##################  TSerialModbusDevice::GetSerial  ###############
*   Purpose....: Get serial device                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TSerialDevice *TSerialModbusDevice::GetSerial()
{
    return FSerial;
}

/*##################  TSerialModbusDevice::Reset  ###############
*   Purpose....: Reset serial device                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TSerialModbusDevice::Reset()
{
    FSerial->Reset();
}

/*##########################################################################
#
#   Name       : TSerialModbusDevice::EnableEcho
#
#   Purpose....: Enable echo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialModbusDevice::EnableEcho()
{
    FHasEcho = TRUE;
}

/*##########################################################################
#
#   Name       : TSerialModbusDevice::DisableEcho
#
#   Purpose....: Disable echo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialModbusDevice::DisableEcho()
{
    FHasEcho = FALSE;
}

/*##########################################################################
#
#   Name       : TSerialModbusDevice::CalcCrc
#
#   Purpose....: Calc CRC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialModbusDevice::CalcCrc(const char *buf, int size, char crc[2])
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
#   Name       : TSerialModbusDevice::Session
#
#   Purpose....: Send message & receive answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialModbusDevice::Session(TModbus *modbus, int code, const char *buf, int size)
{
    char crc[2];
    char ch;
    int pos;
    int len;
    int datalen = 0;
    int i;
    int ok = FALSE;

    FSection.Enter();

    FSendBuf[0] = modbus->FAddress;
    FSendBuf[1] = code;

    if (size < 256)
    {
        memcpy(FSendBuf + 2, buf, size);
        CalcCrc(FSendBuf, size + 2, crc);
        memcpy(FSendBuf + size + 2, crc, 2);

        FSerial->Write(FSendBuf, size + 4);

        if (FHasEcho)
        {
            pos = 0;
            while (ok && pos < size + 4 && ch == FSendBuf[pos])
            {
                ok = FSerial->WaitForChar(FTimeout);
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
            while (ok && ch != FSendBuf[0])
            {
                ok = FSerial->WaitForChar(FTimeout);
                if (ok)
                    ch = FSerial->Read();
            }

            if (ok)
            {
                ok = FSerial->WaitForChar(FTimeout);
                if (ok)
                {
                    ch = FSerial->Read();
                    if (ch != FSendBuf[1])
                        ok = FALSE;
                }
            }
        }

        if (ok)
        {
            FRecBuf[0] = FSendBuf[0];
            FRecBuf[1] = FSendBuf[1];

            ok = FSerial->WaitForChar(250);
            if (ok)
                FRecBuf[2] = FSerial->Read();
        }

        if (ok)
        {
            switch (FRecBuf[1])
            {
                case 1:
                case 2:
                case 3:
                case 4:
                    datalen = (unsigned int)FRecBuf[2];
                    len = datalen + 5;
                    break;

                case 5:
                case 6:
                case 15:
                case 16:
                    datalen = 4;
                    len = 8;
                    break;

                default:
                    ok = FALSE;
                    break;
            }

            pos = 3;

            while (ok && pos < len)
            {
                ok = FSerial->WaitForChar(250);
                if (ok)
                {
                    FRecBuf[pos] = FSerial->Read();
                    pos++;
                }
            }

            if (ok)
            {
                CalcCrc(FRecBuf, len - 2, crc);

                if (FRecBuf[len - 2] != crc[0])
                    ok = FALSE;

                if (FRecBuf[len - 1] != crc[1])
                    ok = FALSE;
            }
        }
    }

    if (ok)
    {
        memcpy(modbus->FReplyBuf, FRecBuf + 2, len - 4);
        modbus->FReplySize = len - 4;
    }
    else
    {
        while (FSerial->WaitForChar(2 * FTimeout))
            FSerial->Read();

        modbus->FReplySize = 0;
        datalen = 0;
    }

    FSection.Leave();

    return datalen;
}

/*##########################################################################
#
#   Name       : TSocketModbusDevice::TSocketModbusDevice
#
#   Purpose....: Constructor for TSocketModbusDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketModbusDevice::TSocketModbusDevice(long Ip)
{
    FIp = Ip;
    FPort = 502;
    Init();
}

/*##########################################################################
#
#   Name       : TSocketModbusDevice::TSocketModbusDevice
#
#   Purpose....: Constructor for TSocketModbusDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketModbusDevice::TSocketModbusDevice(long Ip, int Port)
{
    FIp = Ip;
    FPort = Port;
    Init();
}

/*##########################################################################
#
#   Name       : TSocketModbusDevice::~TSocketModbusDevice
#
#   Purpose....: Destructor for TSocketModbusDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketModbusDevice::~TSocketModbusDevice()
{
    if (FSocket)
        delete FSocket;
}

/*##########################################################################
#
#   Name       : TSocketModbusDevice::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketModbusDevice::Init()
{
    FPushCounter = 0;
    FSocket = 0;
    FTransId = (short int)RdosGetRandom(65535);
    if (FTransId == 0)
        FTransId++;

    Start("Modbus TCP", 0x8000);
}

/*##########################################################################
#
#   Name       : TSocketModbusDevice::Connect
#
#   Purpose....: Connect socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TSocketModbusDevice::Connect()
{
    TTcpSocket *socket;
    bool open;

    if (FSocket)
        open = !FSocket->IsOpen();
    else
        open = true;

    if (open)
    {
        FPushCounter = 0;

        if (FSocket)
        {
            delete FSocket;
            FSocket = 0;
        }

        socket = new TTcpSocket(FIp, FPort, 5000, 0x2000);
        socket->WaitForConnection(5000);

        if (socket->IsOpen())
        {
            FSocket = socket;
            return true;
        }
        else
        {
            delete socket;
            return false;
        }
    }
    else
        return true;
}

/*##########################################################################
#
#   Name       : TSocketModbusDevice::Session
#
#   Purpose....: Send message & receive answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSocketModbusDevice::Session(TModbus *modbus, int code, const char *buf, int size)
{
    char ch;
    int pos;
    int len;
    int datalen = 0;
    int i;
    short int temp;
    bool ok = false;

    FSection.Enter();

    FPushCounter = 0;

    FTransId++;
    if (FTransId == 0)
        FTransId++;

    temp = RdosSwapShort(FTransId);
    memcpy(FSendBuf, &temp, 2);

    FSendBuf[2] = 0;
    FSendBuf[3] = 0;

    temp = size + 2;
    temp = RdosSwapShort(temp);
    memcpy(FSendBuf + 4, &temp, 2);

    FSendBuf[5] = modbus->FAddress;
    FSendBuf[6] = code;

    if (Connect() && size < 256)
    {
        memcpy(FSendBuf + 7, buf, size);

        FSocket->Write(FSendBuf, size + 7);
        FSocket->Push();

        pos = 0;

    }

    if (ok)
    {
        memcpy(modbus->FReplyBuf, FRecBuf + 2, len - 4);
        modbus->FReplySize = len - 4;
    }
    else
    {

        modbus->FReplySize = 0;
        datalen = 0;
    }

    FSection.Leave();

    return datalen;
}

/*##########################################################################
#
#   Name       : TSocketModbusDevice::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketModbusDevice::Execute()
{
    for (;;)
    {
        if (FSocket)
        {
            FPushCounter++;
            if (FPushCounter == 30)
            {
                FSection.Enter();

                if (FSocket && FSocket->IsOpen())
                    FSocket->Push();

                FSection.Leave();
            }
        }
        RdosWaitMilli(1000);
    }
}
