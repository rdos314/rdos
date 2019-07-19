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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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
    
    virtual int IsOpen() const;
    virtual void Open();
    virtual void Close();
        
    void Block();
    void Unblock();
        
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
    void Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
    void OpenPort();
    int GetNextDumpFile();
    void DumpOnce();

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
    TSignalDevice FDumpSignal;
    int FDumpFiles;
    int FWriteDump;
    int FDumpStarted;
    int FNextPos;
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

