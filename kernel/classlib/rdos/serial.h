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

class TSerialDevice : public TWaitDevice
{
public:
	TSerialDevice(const char *IniSection, TWait *Wait, int Port, long Baudrate);
	TSerialDevice(const char *IniSection, TWait *Wait, int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	TSerialDevice(const char *IniSection, TWait *Wait, int Port, int Irq, long Baudrate);
	TSerialDevice(const char *IniSection, TWait *Wait, int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits);
	TSerialDevice(TWait *Wait, int Port, long Baudrate);
	TSerialDevice(TWait *Wait, int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	TSerialDevice(TWait *Wait, int Port, int Irq, long Baudrate);
	TSerialDevice(TWait *Wait, int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits);
	~TSerialDevice();

	virtual void DeviceName(char *Name, int MaxLen) const;

	void Block();
	void Unblock();
	int GetSendBufferSpace();
	int GetReceiveBufferSpace();
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
	int WaitForChar(int Timeout);

	void (*OnChar)(TSerialDevice *Serial, char ch);

protected:
	virtual void SignalNewData();

private:
	void Init(TWait *Wait, int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	void Init(TWait *Wait, int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits);
	int CalcBase(int Port);
	int CalcIrq(int Port);

	TSection FSection;
	int FHandle;
};

#endif

