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

    virtual int ReadCoilStatus(int Coil) = 0;
    virtual int ReadInputStatus(int Input) = 0;
    virtual int ReadHoldingRegister(int Reg) = 0;
    virtual int ReadInputRegister(int Reg) = 0;

    virtual int ReadCoilStatus(int Coil, int *val) = 0;
    virtual int ReadInputStatus(int Input, int *val) = 0;
    virtual int ReadHoldingRegister(int Reg, int *val) = 0;
    virtual int ReadInputRegister(int Reg, int *val) = 0;

    virtual int PresetRegister(int Reg, int Val) = 0;

    virtual int ReadHoldingRegisterABCD(int Reg, float *Val) = 0;
    virtual int PresetRegisterABCD(int Reg, float Val) = 0;

    virtual int ReqHoldingRegisters(int Reg, int Count) = 0;
    virtual int GetReplySize() = 0;
    virtual void GetReplyBuf(char *Buf) = 0;
    virtual int SetBufferedRegisters(int Reg, int Count, const char *Buf, int Size) = 0;
    virtual int GetBufferedHoldingRegister(int Reg, int *Val) = 0;
    virtual int GetBufferedHoldingRegisterABCD(int Reg, float *Val) = 0;

    virtual void StartWritePresetRegisters(int Reg, int Count, int Default) = 0;
    virtual void AddPresetRegister(int Reg, int val) = 0;
    virtual void AddPresetRegisterABCD(int Reg, float val) = 0;
    virtual int DoWritePresetRegisters() = 0;
};

class TSerialModbusDevice;

class TSerialModbus : public TModbus
{
public:
    TSerialModbus(TSerialModbusDevice *dev, char Address);
    TSerialModbus();
    virtual ~TSerialModbus();

    TSerialModbusDevice *GetDevice();

    virtual int ReadCoilStatus(int Coil);
    virtual int ReadInputStatus(int Input);
    virtual int ReadHoldingRegister(int Reg);
    virtual int ReadInputRegister(int Reg);

    virtual int ReadCoilStatus(int Coil, int *val);
    virtual int ReadInputStatus(int Input, int *val);
    virtual int ReadHoldingRegister(int Reg, int *val);
    virtual int ReadInputRegister(int Reg, int *val);

    virtual int PresetRegister(int Reg, int Val);

    virtual int ReadHoldingRegisterABCD(int Reg, float *Val);
    virtual int PresetRegisterABCD(int Reg, float Val);

    virtual int ReqHoldingRegisters(int Reg, int Count);
    virtual int GetReplySize();
    virtual void GetReplyBuf(char *Buf);
    virtual int SetBufferedRegisters(int Reg, int Count, const char *Buf, int Size);
    virtual int GetBufferedHoldingRegister(int Reg, int *Val);
    virtual int GetBufferedHoldingRegisterABCD(int Reg, float *Val);

    virtual void StartWritePresetRegisters(int Reg, int Count, int Default);
    virtual void AddPresetRegister(int Reg, int val);
    virtual void AddPresetRegisterABCD(int Reg, float val);
    virtual int DoWritePresetRegisters();

protected:
    int Session(char FunctionCode, const char *buf, int size, char *reply);

    TSerialModbusDevice *FDevice;
    char FAddress;
    int FBigEndian;

    int FStartReg;
    int FRegCount;
    char FReplyBuf[100];
    int FReplySize;

    char FWriteBuf[100];
    int FWriteSize;
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
