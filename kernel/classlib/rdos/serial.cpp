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
# serial.cpp
# Serial device class
#
########################################################################*/

#include <string.h>
#include "serial.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSerialDevice::CalcBase
#
#   Purpose....: Calculate io address for port based on port nr            
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::CalcBase(int Port)
{
	switch (Port)
	{
		case 1:
			return 0x3F8;

		case 2:
			return 0x2F8;

		case 3:
			return 0x3E8;

		case 4:
			return 0x2E8;

		case 5:
			return 0x3A8;

		case 6:
			return 0x2A8;

		default:
		    return 0;
	}
}

/*##########################################################################
#
#   Name       : TSerialDevice::CalcIrq
#
#   Purpose....: Calculate irq nr for port based on port nr      	       
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::CalcIrq(int Port)
{
	switch (Port)
	{
		case 1:
			return 4;

		case 2:
			return 3;

		case 3:
			return 9;

		case 4:
			return 10;

		case 5:
			return 11;

		case 6:
			return 12;

		default:
			return 0;
	}
}

/*##########################################################################
#
#   Name       : TSerialDevice::Init
#
#   Purpose....: Init device
#
#   In params..: Port       port number (ie COM1 = 1)
#                Baudrate   baudrate
#                Parity     parity
#                DataBits   databits
#                StopBits   stopbits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Init(TWait *Wait, int Port, long Baudrate, char Parity, int DataBits, int StopBits)
{
    int Irq;
    int Base;

    OnChar = 0;    

	Irq = CalcIrq(Port);
	Base = CalcBase(Port);
	FHandle = RdosOpenCom(Base, Irq, (int)(115200L / Baudrate), Parity, DataBits, StopBits, 0x4000, 0x4000);
	RdosAddWaitForCom(RegisterWait(Wait), FHandle, this);
}

/*##########################################################################
#
#   Name       : TSerialDevice::Init
#
#   Purpose....: Init device
#
#   In params..: Port       port number (ie COM1 = 1)
#                Irq        irq line
#                Baudrate   baudrate
#                Parity     parity
#                DataBits   databits
#                StopBits   stopbits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Init(TWait *Wait, int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits)
{
    int Base;

    OnChar = 0;    
    
	Base = CalcBase(Port);
	FHandle = RdosOpenCom(Base, Irq, (int)(115200L / Baudrate), Parity, DataBits, StopBits, 0x4000, 0x4000);
	RdosAddWaitForCom(RegisterWait(Wait), FHandle, this);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: IniSection Parameter section
#                Port       port number (ie COM1 = 1)
#                Baudrate   baudrate
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(const char *IniSection, TWait *Wait, int Port, long Baudrate)
	: TWaitDevice(IniSection)
{
	Init(Wait, Port, Baudrate, 'N', 8, 1);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: IniSection Parameter section
#                Port       port number (ie COM1 = 1)
#                Baudrate   baudrate
#                Parity     parity
#                DataBits   databits
#                StopBits   stopbits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(const char *IniSection, TWait *Wait, int Port, long Baudrate, char Parity, int DataBits, int StopBits)
	: TWaitDevice(IniSection)
{
	Init(Wait, Port, Baudrate, Parity, DataBits, StopBits);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: IniSection Parameter section
#                Port       port number (ie COM1 = 1)
#                Irq        IRQ line
#                Baudrate   baudrate
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(const char *IniSection, TWait *Wait, int Port, int Irq, long Baudrate)
	: TWaitDevice(IniSection)
{
	Init(Wait, Port, Irq, Baudrate, 'N', 8, 1);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: IniSection Parameter section
#                Port       port number (ie COM1 = 1)
#                Irq        IRQ line
#                Baudrate   baudrate
#                Parity     parity
#                DataBits   databits
#                StopBits   stopbits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(const char *IniSection, TWait *Wait, int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits)
	: TWaitDevice(IniSection)
{
	Init(Wait, Port, Irq, Baudrate, Parity, DataBits, StopBits);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie COM1 = 1)
#                Baudrate   baudrate
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(TWait *Wait, int Port, long Baudrate)
{
	Init(Wait, Port, Baudrate, 'N', 8, 1);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie COM1 = 1)
#                Baudrate   baudrate
#                Parity     parity
#                DataBits   databits
#                StopBits   stopbits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(TWait *Wait, int Port, long Baudrate, char Parity, int DataBits, int StopBits)
{
	Init(Wait, Port, Baudrate, Parity, DataBits, StopBits);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie COM1 = 1)
#                Irq        IRQ line
#                Baudrate   baudrate
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(TWait *Wait, int Port, int Irq, long Baudrate)
{
	Init(Wait, Port, Irq, Baudrate, 'N', 8, 1);
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie COM1 = 1)
#                Irq        IRQ line
#                Baudrate   baudrate
#                Parity     parity
#                DataBits   databits
#                StopBits   stopbits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(TWait *Wait, int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits)
{
	Init(Wait, Port, Irq, Baudrate, Parity, DataBits, StopBits);
}

/*##########################################################################
#
#   Name       : TSerialDevice::~TSerialDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::~TSerialDevice()
{
    if (FHandle)
        RdosCloseCom(FHandle);
}

/*##########################################################################
#
#   Name       : TSerialDevice::Block
#
#   Purpose....: Block for exclusive access
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Block()
{
	FSection.Enter();
}

/*##########################################################################
#
#   Name       : TSerialDevice::Unblock
#
#   Purpose....: Unblock for exclusive access
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Unblock()
{
	FSection.Leave();
}

/*##########################################################################
#
#   Name       : TSerialDevice::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"Serial device",MaxLen);
}

/*##########################################################################
#
#   Name       : TSerialDevice::Clear
#
#   Purpose....: Clear buffers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Clear()
{
	RdosFlushCom(FHandle);
}

/*##########################################################################
#
#   Name       : TSerialDevice::GetSendBufferSpace
#
#   Purpose....: Get free space in send buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: Number of bytes free space
#
##########################################################################*/
int TSerialDevice::GetSendBufferSpace()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TSerialDevice::GetReceiveBufferSpace
#
#   Purpose....: Get free space in receive buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: Number of bytes free space
#
##########################################################################*/
int TSerialDevice::GetReceiveBufferSpace()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TSerialDevice::ResetDtr
#
#   Purpose....: Reset DTR signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::ResetDtr()
{
	RdosResetDtr(FHandle);
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetDtr
#
#   Purpose....: Set DTR signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetDtr()
{
	RdosSetDtr(FHandle);
}

/*##########################################################################
#
#   Name       : TSerialDevice::ResetRts
#
#   Purpose....: Reset RTS signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::ResetRts()
{
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetRts
#
#   Purpose....: Set RTS signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetRts()
{
}

/*##########################################################################
#
#   Name       : TSerialDevice::EnableAutoRts
#
#   Purpose....: Enable automatic RTS generation during send
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::EnableAutoRts()
{
}

/*##########################################################################
#
#   Name       : TSerialDevice::DisableAutoRts
#
#   Purpose....: Disable automatic RTS generation during send
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::DisableAutoRts()
{
}

/*##########################################################################
#
#   Name       : TSerialDevice::Write
#
#   Purpose....: Write a char
#
#   In params..: ch     char to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Write(char ch)
{
	RdosWriteCom(FHandle, ch);
}

/*##########################################################################
#
#   Name       : TSerialDevice::Write
#
#   Purpose....: Write a buffer
#
#   In params..: buf     buffer to write
#                count   count to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Write(const char *buf, int count)
{
	int i;
	for (i = 0; i < count; i++)
	{
		RdosWriteCom(FHandle, *buf);
		buf++;
	}
}

/*##########################################################################
#
#   Name       : TSerialDevice::Write
#
#   Purpose....: Write a string
#
#   In params..: str    string to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Write(const char *str)
{
	while (*str != 0)
	{
		RdosWriteCom(FHandle, *str);
		str++;
	}
}

/*##########################################################################
#
#   Name       : TSerialDevice::WaitForChar
#
#   Purpose....: Read a single character
#
#   In params..: *
#   Out params.: *
#   Returns....: character
#
##########################################################################*/
int TSerialDevice::WaitForChar(int Timeout)
{
	TWait *Wait = GetWait();

	if (Wait)
		if (Wait->WaitTimeout(Timeout) == this)
			return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : TSerialDevice::Read
#
#   Purpose....: Read a single character
#
#   In params..: *
#   Out params.: *
#   Returns....: character
#
##########################################################################*/
char TSerialDevice::Read()
{
	return RdosReadCom(FHandle);
}

/*##########################################################################
#
#   Name       : TSerialDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SignalNewData()
{
    if (OnChar)
        (*OnChar)(this, Read());
}
