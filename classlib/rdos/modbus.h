/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# modbus.h
# Modbus class
#
########################################################################*/

#ifndef _MODBUS_H
#define _MODBUS_H

#include "serial.h"

class TModbus
{
public:
    TModbus(TSerialDevice *Serial, char Address);
    ~TModbus();

    TSerialDevice *GetSerial();

    void EnableEcho();
    void DisableEcho();

    int ReadCoilStatus(int Coil);
    int ReadInputStatus(int Input);
    int ReadHoldingRegister(int Reg);
    int ReadInputRegister(int Reg);

    int ReadCoilStatus(int Coil, int *val);
    int ReadInputStatus(int Input, int *val);
    int ReadHoldingRegister(int Reg, int *val);
    int ReadInputRegister(int Reg, int *val);

    int PresetRegister(int Reg, int Val);

    int ReadHoldingRegisterABCD(int Reg, float *Val);
    int PresetRegisterABCD(int Reg, float Val);

    int ReqHoldingRegisters(int Reg, int Count);
    int GetReplySize();
    void GetReplyBuf(char *Buf);
    int SetBufferedRegisters(int Reg, int Count, const char *Buf, int Size);
    int GetBufferedHoldingRegister(int Reg, int *Val);
    int GetBufferedHoldingRegisterABCD(int Reg, float *Val);

protected:
    void CalcCrc(const char *buf, int size, char crc[2]);
    int SendAndReceive(const char *buf, int size, char *reply);
    int Session(char FunctionCode, const char *buf, int size, char *reply);

    TSection FSection;
    TSerialDevice *FSerial;
    char FAddress;
    int FBigEndian;
    int FHasEcho;

    int FStartReg;
    int FRegCount;
    char FReplyBuf[100];
    char FReplySize;
};

#endif
