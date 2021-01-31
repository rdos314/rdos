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
#include "device.h"

class TModbusDevice;

class TModbus
{
friend class TModbusDevice;
friend class TSerialModbusDevice;
friend class TSocketModbusDevice;
public:
    TModbus(TModbusDevice *dev, char adr);
    ~TModbus();

    TModbusDevice *GetDevice();
    char GetAddress();

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
    int GetBufferedHoldingRegister(int Reg, int *Val);
    int GetBufferedHoldingRegisterABCD(int Reg, float *Val);

    void StartWritePresetRegisters(int Reg, int Count, int Default);
    void AddPresetRegister(int Reg, int val);
    void AddPresetRegisterABCD(int Reg, float val);
    int DoWritePresetRegisters();

protected:
    int FBigEndian;

    int FStartReg;
    int FRegCount;
    char FReplyBuf[100];
    int FReplySize;

    char FWriteBuf[100];
    int FWriteSize;

    TModbusDevice *FDevice;
    char FAddress;
};

class TModbusDevice : public TThread
{
friend class TModbus;
public:
    TModbusDevice();
    virtual ~TModbusDevice();

    void SetTimeout(int ms);
    void Add(int Address, TModbus *Modbus);
    int IsUsed(int Address);

protected:
    virtual int Session(TModbus *modbus, int code, const char *buf, int size) = 0;

    TModbus *FModbusArr[0x80];
    int FTimeout;

    TSection FSection;
};

class TSerialModbusDevice : public TModbusDevice
{
public:
    TSerialModbusDevice(TSerialDevice *serial);
    virtual ~TSerialModbusDevice();

    void Reset();

    void EnableEcho();
    void DisableEcho();

    TSerialDevice *GetSerial();

protected:
    virtual int Session(TModbus *modbus, int code, const char *buf, int size);

    void CalcCrc(const char *buf, int size, char crc[2]);

    char FRecBuf[266];
    char FSendBuf[266];

    int FHasEcho;

    TSerialDevice *FSerial;
};

class TSocketModbusDevice : public TModbusDevice
{
public:
    TSocketModbusDevice(long Ip);
    TSocketModbusDevice(long Ip, int Port);
    virtual ~TSocketModbusDevice();

protected:
    void Init();
    bool Connect();

    virtual void Execute();
    virtual int Session(TModbus *modbus, int code, const char *buf, int size);

    char FRecBuf[266];
    char FSendBuf[266];

    short int FTransId;
    long FIp;
    int FPort;
    int FPushCounter;
    TTcpSocket *FSocket;
};

#endif
