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

class TSerialDevice : public TWaitDevice
{
public:
    TSerialDevice(int Port, long Baudrate);
    TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
    TSerialDevice(int Port);
    TSerialDevice();
    ~TSerialDevice();

    void SetBufferSize(int size);

    virtual void DeviceName(char *Name, int MaxLen) const;

    void StartDebug(TFile *File, int InChannel, int OutChannel);
    void StopDebug();

    int DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel);
    int DumpEvents();
    
    virtual int IsOpen();
    virtual void Open();
    virtual void Close();
        
    void Block();
    void Unblock();

    int GetHandle();
        
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
    int GetCts();
    int GetDsr();
    void ResetDtr();
    void SetDtr();
    void ResetRts();
    void SetRts();

    void EnableAutoRts();
    void DisableAutoRts();
    int IsAutoRtsOn();

    void SendBreak(char CharCount);

    void Write(char ch);
    void Write(const char *buf, int count);
    void Write(const char *str);
    void WaitForSendCompleted();
    int Poll();
    char Read();
    int WaitForChar(long Timeout);
    int SupportsFullDuplex();

    void EnableCts();
    void DisableCts();

    void (*OnChar)(TSerialDevice *Serial, char ch);

protected:
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

    virtual void Execute();

private:
    void Init();
    void Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
    void OpenPort();
    void CheckFileCount();
    void InitFiles();

    TSection FSection;
    int FHandle;
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
    int DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel);
    int DumpEvents();

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
    int WaitForChar(long MaxWait);

    TSerialDevice *FSerial;

private:

};

#endif

