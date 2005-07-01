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

#ifndef	_SERIAL_H
#define _SERIAL_H

#include "waitdev.h"
#include "file.h"

class TSerialDebug
{
public:
	short int Channel;
	unsigned long TimeLSB;
	unsigned long TimeMSB;
	char ch;
};

class TSerialDevice : public TWaitDevice
{
public:
	TSerialDevice(const char *IniSection, int Port, long Baudrate);
	TSerialDevice(const char *IniSection, int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	TSerialDevice(int Port, long Baudrate);
	TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	TSerialDevice(const char *IniSection);
	TSerialDevice();
	~TSerialDevice();

	virtual void DeviceName(char *Name, int MaxLen) const;

    void StartDebug(TFile *File, int InChannel, int OutChannel);
    
	virtual int IsOpen() const;
	virtual void Open();
	virtual void Close();
	
	void Block();
	void Unblock();
	
	virtual void SetBaudrate(long Baudrate);
	virtual void SetParity(char Parity);
	virtual void SetDataBits(int Bits);
	virtual void SetStopBits(int Bits);
	virtual long GetBaudrate() const;
	virtual int GetPort() const;
	virtual char GetParity() const;
	virtual int GetDataBits() const;
	virtual int GetStopBits() const;
	virtual int GetSendBufferSpace();
	virtual int GetReceiveBufferSpace();
	virtual void Clear();
	virtual void ResetDtr();
    virtual void SetDtr();
	virtual void ResetRts();
	virtual void SetRts();
	virtual void EnableAutoRts();
    virtual void DisableAutoRts();
	virtual void Write(char ch);
    virtual void Write(const char *buf, int count);
	virtual void Write(const char *str);
	virtual void WaitForSendCompleted();
	virtual int Poll();
	virtual char Read();
	virtual int WaitForChar(long Timeout);

    void EnableCts();
    void DisableCts();

	void (*OnChar)(TSerialDevice *Serial, char ch);

protected:
	virtual void SignalNewData();
	virtual void Add(TWait *Wait);

private:
	void Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	void OpenPort();

	TSection FSection;
	int FHandle;

    int FPort;
	long FBaudrate;
	char FParity;
	int FDataBits;
	int FStopBits;
	int FDataMask;
	int FAutoRts;
	int FUseCts;
	
	TFile *FDebugFile;
	int FInChannel;
	int FOutChannel;
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
	char Read();
    int WaitForChar(long MaxWait);

	TSerialDevice *FSerial;

private:

};

#endif

