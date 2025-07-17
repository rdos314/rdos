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
# Serial port class
#
########################################################################*/

#ifndef _SERIAL_H
#define _SERIAL_H

#include "windows.h"
#include "device.h"

class TSerialDebug
{
public:
        short int Channel;
        unsigned long long Time;
        char ch;
};

class TSerialDevice : public TDevice
{
public:
        TSerialDevice(int Port, long Baudrate);
        TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
        TSerialDevice();
        virtual ~TSerialDevice();
        
        virtual void DeviceName(char *Name, int MaxLen) const;

        void Block();
        void Unblock();
        
        void SetComPort(int Port);
        virtual void SetBaudrate(long Baudrate);
        virtual void SetParity(char Parity);
        virtual void SetDataBits(int Bits);
        virtual void SetStopBits(int Bits);
        virtual long GetBaudrate() const;
        virtual char GetParity() const;
        virtual int GetDataBits() const;
        virtual int GetStopBits() const;
    virtual int GetSendBufferSpace();
    virtual int GetReceiveBufferSpace();
        virtual int GetPort() const;
        virtual void Open();
        virtual void Close();

        virtual void ResetDtr();
        virtual void SetDtr();
    virtual void ResetRts();
    virtual void SetRts();
        virtual void EnableAutoRts();
        virtual void DisableAutoRts();
        virtual void Clear();
        virtual void Write(char ch);
        virtual void Write(const char *buf, int count);
        virtual void Write(const char *str);
        virtual int Poll();
        virtual char Read();
        virtual int WaitForChar(long MaxWait);
        virtual int SupportsFullDuplex();


protected:

private:
        void Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
        void OpenPort();
    void ClosePort();
    void ReadPort();

        int FPort;
        long FBaudrate;
        char FParity;
        int FDataBits;
        int FStopBits;
        int FDataMask;
        HANDLE FPortHandle;
    DCB FCommDCB;
    OVERLAPPED FReadOverlapped;
    OVERLAPPED FWriteOverlapped;

        TSection FSection;
};

class TSerialCommand
{
public:
        TSerialCommand(TSerialDevice *serial);
        virtual ~TSerialCommand();
        int Run();

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
    int Poll();
        char Read();
    int WaitForChar(long MaxWait);

        TSerialDevice *FSerial;

private:

};

#endif

