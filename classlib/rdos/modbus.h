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
#include "sockobj.h"

class TModbus
{
public:
    TModbus();
    virtual ~TModbus();

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

    virtual int ReqHoldingRegisters(int Reg, int Count) = 0;
    virtual int SetBufferedRegisters(int Reg, int Count, const char *Buf, int Size) = 0;

    int GetReplySize();
    void GetReplyBuf(char *Buf);
    int GetBufferedHoldingRegister(int Reg, int *Val);
    int GetBufferedHoldingRegisterABCD(int Reg, float *Val);

    void StartWritePresetRegisters(int Reg, int Count, int Default);
    void AddPresetRegister(int Reg, int val);
    void AddPresetRegisterABCD(int Reg, float val);
    int DoWritePresetRegisters();

protected:
    virtual int Session(char FunctionCode, const char *buf, int size, char *reply) = 0;

    int FBigEndian;

    int FStartReg;
    int FRegCount;
    char FReplyBuf[100];
    int FReplySize;

    char FWriteBuf[100];
    int FWriteSize;
};

class TSerialModbusDevice;

class TSerialModbus : public TModbus
{
public:
    TSerialModbus(TSerialModbusDevice *dev, char Address);
    virtual ~TSerialModbus();

    TSerialModbusDevice *GetDevice();
    virtual int ReqHoldingRegisters(int Reg, int Count);
    virtual int SetBufferedRegisters(int Reg, int Count, const char *Buf, int Size);

protected:
    virtual int Session(char FunctionCode, const char *buf, int size, char *reply);

    TSerialModbusDevice *FDevice;
    char FAddress;
};

class TSerialModbusDevice
{
friend class TSerialModbus;
public:
    TSerialModbusDevice(TSerialDevice *serial);
    ~TSerialModbusDevice();

    void Reset();

    void EnableEcho();
    void DisableEcho();

    void SetTimeout(int ms);

    void Add(int Address, TSerialModbus *Modbus);
    int IsUsed(int Address);
    TSerialDevice *GetSerial();

protected:
    void CalcCrc(const char *buf, int size, char crc[2]);
    int SendAndReceive(const char *buf, int size, char *reply, int *datalen, int *replylen);

    int FHasEcho;
    int FTimeout;

    TSerialModbus *FModbusArr[0x80];
    TSerialDevice *FSerial;
    TSection FSection;
};

#endif
