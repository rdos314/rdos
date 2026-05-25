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
# serial.h
# Basic serial device class
#
########################################################################*/

#ifndef _SERIAL_H
#define _SERIAL_H

#include "waitdev.h"
#include "file.h"
#include "str.h"
#include "sigdev.h"

struct TSerialDebug
{
public:
    short int Channel;
    long long Time;
    char ch;
};

#ifndef __RDOS__

class TLinuxSerial
{
public:
    TLinuxSerial();
    ~TLinuxSerial();

    virtual bool IsStdSerial();
    virtual bool IsUsbSerial();
    virtual bool IsCanSerial();

    virtual bool Open(long Baudrate, char Parity, int DataBits, int StopBits) = 0;
    virtual void Close() = 0;
    virtual bool IsOpen() = 0;

    virtual int GetSendBufferSpace();
    virtual int GetReceiveBufferSpace();
    virtual void Reset();

    virtual void Clear() = 0;
    virtual bool GetCts() = 0;
    virtual bool GetDsr() = 0;
    virtual void ResetDtr() = 0;
    virtual void SetDtr() = 0;
    virtual void ResetRts() = 0;
    virtual void SetRts() = 0;

    virtual void EnableAutoRts() = 0;
    virtual void DisableAutoRts() = 0;
    virtual bool IsAutoRtsOn() = 0;

    virtual void SendBreak(char CharCount) = 0;

    virtual void Write(char ch) = 0;
    virtual void Write(const char *buf, int count) = 0;
    virtual void Write(const char *str) = 0;
    virtual void WaitForSendCompleted() = 0;
    virtual bool Poll() = 0;
    virtual char Read() = 0;
    virtual bool WaitForChar(long Timeout) = 0;
    virtual bool SupportsFullDuplex() = 0;

    virtual void EnableCts() = 0;
    virtual void DisableCts() = 0;

    bool IsUsed;
};

class TLinuxTtySerial : public TLinuxSerial
{
public:
    TLinuxTtySerial(const char *dev);
    ~TLinuxTtySerial();

    virtual bool Open(long Baudrate, char Parity, int DataBits, int StopBits);
    virtual void Close();
    virtual bool IsOpen();
    virtual bool Reopen();

    virtual void Clear();
    virtual bool GetCts();
    virtual bool GetDsr();
    virtual void ResetDtr();
    virtual void SetDtr();
    virtual void ResetRts();
    virtual void SetRts();

    virtual void EnableAutoRts();
    virtual void DisableAutoRts();
    virtual bool IsAutoRtsOn();

    virtual void SendBreak(char CharCount);

    virtual void Write(char ch);
    virtual void Write(const char *buf, int count);
    virtual void Write(const char *str);
    virtual void WaitForSendCompleted();
    virtual bool Poll();
    virtual char Read();
    virtual bool WaitForChar(long Timeout);
    virtual bool SupportsFullDuplex();

    virtual void EnableCts();
    virtual void DisableCts();

protected:
    TString FDev;
    int FHandle;
    long FBaudrate;
    char FParity;
    int FDataBits;
    int FStopBits;
};

class TLinuxStdSerial : public TLinuxTtySerial
{
public:
    TLinuxStdSerial(const char *dev, int base, int irq);
    ~TLinuxStdSerial();

    virtual bool IsStdSerial();
    int GetBase();
    int GetIrq();

protected:
    int FIoBase;
    int FIrq;
};

class TLinuxUsbSerial : public TLinuxTtySerial
{
public:
    TLinuxUsbSerial(const char *dev, int bus, int device, int vendor, int product);
    ~TLinuxUsbSerial();

    virtual bool IsUsbSerial();
    virtual void Reset();

    int GetBus();
    int GetDevice();
    int GetVendor();
    int GetProduct();

protected:
    int FBus;
    int FDevice;
    int FVendor;
    int FProduct;
};

#endif

class TSerialDevice : public TWaitDevice
{
public:
    TSerialDevice();
    TSerialDevice(int Port, long Baudrate);
    TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits);

#ifdef __RDOS__
    TSerialDevice(int Handle);
#endif

    ~TSerialDevice();

    void SetBufferSize(int size);

    void StartDebug(TFile *File, int InChannel, int OutChannel);
    void StopDebug();

    bool DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel);
    bool DumpEvents();
    
    virtual bool IsOpen();
    virtual void Open();
    virtual void Close();
        
    void Block();
    void Unblock();

#ifdef __RDOS__
    int GetHandle();
#endif
        
    void SetBaudrate(long Baudrate);
    void SetParity(char Parity);
    void SetDataBits(int Bits);
    void SetStopBits(int Bits);
    long GetBaudrate() const;
    int GetPort() const;
    char GetParity() const;
    int GetDataBits() const;
    int GetStopBits() const;
    int GetSendBufferSpace();
    int GetReceiveBufferSpace();
    void Reset();
    void Clear();
    bool GetCts();
    bool GetDsr();
    void ResetDtr();
    void SetDtr();
    void ResetRts();
    void SetRts();

    void EnableAutoRts();
    void DisableAutoRts();
    bool IsAutoRtsOn();

    void SendBreak(char CharCount);

    void Write(char ch);
    void Write(const char *buf, int count);
    void Write(const char *str);
    void WaitForSendCompleted();
    bool Poll();
    char Read();
    bool WaitForChar(long Timeout);
    bool SupportsFullDuplex();

    void EnableCts();
    void DisableCts();

    void (*OnChar)(TSerialDevice *Serial, char ch);

protected:
    virtual void SignalNewData();

#ifdef __RDOS__
    virtual void Add(TWait *Wait);
#else
    virtual bool WaitForever();
    virtual bool WaitTimeout(int Timeout);
    virtual bool WaitUntil(TDateTime &DateTime);
#endif

    virtual void Execute();

private:
    void Init();
    void Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
    void OpenPort();
    void CheckFileCount();
    void InitFiles();

    TSection FSection;

#ifdef __RDOS__
    int FHandle;
#else
    TLinuxSerial *FSerial;
#endif

    int FBufferSize;

    int FPort;
    long FBaudrate;
    char FParity;
    int FDataBits;
    int FStopBits;
    int FDataMask;
    int FAutoRts;
    int FUseCts;
    int FSupportsFullDuplex;
        
    TFile *FDebugFile;
    int FInChannel;
    int FOutChannel;

    int FEntryCount;
    struct TSerialDebug *FEntryArr;

    TSection FEventSection;
    int FCurrId;
    TFile *FCurrFile;
    int FFileCount;
    int FNextPos;
    bool FNewData;
    TString FLogPath;
};

class TSerialCommand
{
public:
    TSerialCommand(TSerialDevice *serial);
    virtual ~TSerialCommand();
    int Run();
    bool DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel);
    bool DumpEvents();

protected:
    void Block();
    void Unblock();
    virtual int Execute() = 0;
    void Clear();
    void ResetDtr();
    void SetDtr();
    void ResetRts();
    void SetRts();
    void EnableAutoRts();
    void DisableAutoRts();
    void Write(char ch);
    void Write(const char *buf, int count);
    void Write(const char *str);
    char Read();
    bool WaitForChar(long MaxWait);

    TSerialDevice *FSerial;

private:

};

#endif

