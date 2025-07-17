/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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

class TModbusDevice;

class TModbus
{
public:
    TModbus(TModbusDevice *dev, char Address);
    TModbus();
    ~TModbus();

    TModbusDevice *GetDevice();

    void DisableRetries();
    void EnableRetries(int count);

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

    void StartWritePresetRegisters(int Reg, int Count, int Default);
    void AddPresetRegister(int Reg, int val);
    void AddPresetRegisterABCD(int Reg, float val);
    int DoWritePresetRegisters();

protected:
    int Session(char FunctionCode, const char *buf, int size, char *reply);

    TModbusDevice *FDevice;
    char FAddress;
    int FBigEndian;
    int FRetryCount;

    int FStartReg;
    int FRegCount;
    char FReplyBuf[100];
    int FReplySize;

    char FWriteBuf[100];
    int FWriteSize;
};

class TModbusDevice
{
friend class TModbus;
public:
    TModbusDevice(TSerialDevice *serial);
    TModbusDevice(long Ip, int port);
    ~TModbusDevice();

    void Reset();

    void EnableEcho();
    void DisableEcho();

    void SetTimeout(int ms);

    void Add(int Address, TModbus *Modbus);
    int IsUsed(int Address);
    TSerialDevice *GetSerial();

protected:
    void CalcCrc(const char *buf, int size, char crc[2]);
    void Write(const char *buf, int size);
    int WaitForData(int timeout);
    char Read();
    int SendAndReceive(const char *buf, int size, char *reply, int *datalen, int *replylen);

    int FHasEcho;
    int FTimeout;

    TModbus *FModbusArr[0x80];
    TSerialDevice *FSerial;

    long FIp;
    int FPort;
    TTcpSocket *FSocket;

    TSection FSection;

private:
    void Init();
};

#endif
