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

/*##########################################################################
#
#   Name       : TSerialCommand::TSerialCommand
#
#   Purpose....: Constructor
#
#   In params..: serial     serial device
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialCommand::TSerialCommand(TSerialDevice *serial)
{
	FSerial = serial;
}

/*##########################################################################
#
#   Name       : TSerialCommand::~TSerialCommand
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSerialCommand::~TSerialCommand()
{
}

/*##########################################################################
#
#   Name       : TSerialCommand::Block
#
#   Purpose....: Block for exclusive access
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::Block()
{
	FSerial->Block();
}

/*##########################################################################
#
#   Name       : TSerialCommand::Unblock
#
#   Purpose....: Unblock for exclusive access
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::Unblock()
{
	FSerial->Unblock();
}

/*##########################################################################
#
#   Name       : TSerialCommand::Run
#
#   Purpose....: Run commands
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if successful
#
##########################################################################*/
int TSerialCommand::Run()
{
	int stat;

	FSerial->Block();
	stat = Execute();
	FSerial->Unblock();
	return stat;
}

/*##########################################################################
#
#   Name       : TSerialCommand::Clear
#
#   Purpose....: Clear receive and transmit buffers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::Clear()
{
	FSerial->Clear();
}

/*##########################################################################
#
#   Name       : TSerialCommand::ResetDtr
#
#   Purpose....: Reset DTR signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::ResetDtr()
{
	FSerial->ResetDtr();
}

/*##########################################################################
#
#   Name       : TSerialCommand::SetDtr
#
#   Purpose....: Set DTR signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::SetDtr()
{
	FSerial->SetDtr();
}

/*##########################################################################
#
#   Name       : TSerialCommand::ResetRts
#
#   Purpose....: Reset RTS signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::ResetRts()
{
	FSerial->ResetRts();
}

/*##########################################################################
#
#   Name       : TSerialCommand::SetRts
#
#   Purpose....: Set RTS signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::SetRts()
{
	FSerial->SetRts();
}

/*##########################################################################
#
#   Name       : TSerialCommand::EnableAutoRts
#
#   Purpose....: Enable use of RTS in half-duplex as send control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::EnableAutoRts()
{
	FSerial->EnableAutoRts();
}

/*##########################################################################
#
#   Name       : TSerialCommand::DisableAutoRts
#
#   Purpose....: Disable use of RTS in half-duplex as send control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::DisableAutoRts()
{
	FSerial->DisableAutoRts();
}

/*##########################################################################
#
#   Name       : TSerialCommand::Write
#
#   Purpose....: Write a char
#
#   In params..: ch     char to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::Write(char ch)
{
	FSerial->Write(ch);
}

/*##########################################################################
#
#   Name       : TSerialCommand::Write
#
#   Purpose....: Write a buffer
#
#   In params..: buf     buffer to write
#                count   number of bytes
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::Write(const char *buf, int count)
{
	FSerial->Write(buf, count);
}

/*##########################################################################
#
#   Name       : TSerialCommand::Write
#
#   Purpose....: Write a string
#
#   In params..: str     string to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialCommand::Write(const char *str)
{
	FSerial->Write(str);
}

/*##########################################################################
#
#   Name       : TSerialCommand::Poll
#
#   Purpose....: Poll receive buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if any character in buffer
#
##########################################################################*/
int TSerialCommand::Poll()
{
	return FSerial->Poll();
}

/*##########################################################################
#
#   Name       : TSerialCommand::Read
#
#   Purpose....: Read a character from buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: returned character
#
##########################################################################*/
char TSerialCommand::Read()
{
	return FSerial->Read();
}

/*##########################################################################
#
#   Name       : TSerialCommand::WaitForChar
#
#   Purpose....: Wait for a char with timeout
#
#   In params..: MaxWait        milliseconds timeout
#   Out params.: *
#   Returns....: TRUE if any character in buffer
#
##########################################################################*/
int TSerialCommand::WaitForChar(long MaxWait)
{
	return FSerial->WaitForChar(MaxWait);
}

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
void TSerialDevice::CalcBase()
{
	switch (FPort)
	{
		case 1:
			FBase = 0x3F8;
			break;

		case 2:
			FBase = 0x2F8;
			break;

		case 3:
			FBase = 0x3E8;
			break;

		case 4:
			FBase = 0x2E8;
			break;

		case 5:
			FBase = 0x3A8;
			break;

		case 6:
			FBase = 0x2A8;
			break;

		default:
			FBase = -1;
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
void TSerialDevice::CalcIrq()
{
	switch (FPort)
	{
		case 1:
			FIrq = 4;
			break;

		case 2:
			FIrq = 3;
			break;

		case 3:
			FIrq = 9;
			break;

		case 4:
			FIrq = 10;
			break;

		case 5:
			FIrq = 11;
			break;

		case 6:
			FIrq = 12;
			break;

		default:
			FIrq = -1;
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
void TSerialDevice::Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits)
{
	FPort = LoadProperty("Port", Port);
	FBaudrate = LoadProperty("Baudrate", Baudrate);
	FParity = Parity;
	FDataBits = DataBits;
	FStopBits = StopBits;
	CalcIrq();
	FIrq = LoadProperty("Irq", FIrq);
	CalcBase();
	if (IsOpen())
	{
		TDevice::Close();
		Open();
	}
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
void TSerialDevice::Init(int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits)
{
	FPort = LoadProperty("Port", Port);
	FIrq = LoadProperty("Irq", Irq);
	FBaudrate = LoadProperty("Baudrate", Baudrate);
	FParity = Parity;
	FDataBits = DataBits;
	FStopBits = StopBits;
	CalcBase();
	if (IsOpen())
	{
		TDevice::Close();
		Open();
	}
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
TSerialDevice::TSerialDevice(const char *IniSection, int Port, long Baudrate)
	: TDevice(IniSection)
{
	Init(Port, Baudrate, 'N', 8, 1);
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
TSerialDevice::TSerialDevice(const char *IniSection, int Port, long Baudrate, char Parity, int DataBits, int StopBits)
	: TDevice(IniSection)
{
	Init(Port, Baudrate, Parity, DataBits, StopBits);
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
TSerialDevice::TSerialDevice(const char *IniSection, int Port, int Irq, long Baudrate)
	: TDevice(IniSection)
{
	Init(Port, Irq, Baudrate, 'N', 8, 1);
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
TSerialDevice::TSerialDevice(const char *IniSection, int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits)
	: TDevice(IniSection)
{
	Init(Port, Irq, Baudrate, Parity, DataBits, StopBits);
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
TSerialDevice::TSerialDevice(int Port, long Baudrate)
{
	Init(Port, Baudrate, 'N', 8, 1);
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
TSerialDevice::TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits)
{
	Init(Port, Baudrate, Parity, DataBits, StopBits);
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
TSerialDevice::TSerialDevice(int Port, int Irq, long Baudrate)
{
	Init(Port, Irq, Baudrate, 'N', 8, 1);
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
TSerialDevice::TSerialDevice(int Port, int Irq, long Baudrate, char Parity, int DataBits, int StopBits)
{
	Init(Port, Irq, Baudrate, Parity, DataBits, StopBits);
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
	if (IsOpen())
		Close();
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
#   Name       : TSerialDevice::SetPort
#
#   Purpose....: Set a new port
#
#   In params..: Port   port number (ie COM1 = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetPort(int Port)
{
	if (IsOpen())
	{
		Close();
		FPort = Port;
		CalcBase();
		Open();
	}
	else
	{
		FPort = Port;
		CalcBase();
	}
	SaveProperty("Port", FPort);
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetIrq
#
#   Purpose....: Set a new IRQ
#
#   In params..: Irq   IRQ line
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetIrq(int Irq)
{
	if (IsOpen())
	{
		Close();
		FIrq = Irq;
		Open();
	}
	else
		FIrq = Irq;
	SaveProperty("Irq", FIrq);
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetBaudrate
#
#   Purpose....: Set a new baudrate
#
#   In params..: Baudrate       baudrate
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetBaudrate(long Baudrate)
{
	if (IsOpen())
	{
		Close();
		FBaudrate = Baudrate;
		Open();
	}
	else
		FBaudrate = Baudrate;
	SaveProperty("Baudrate", FBaudrate);
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetParity
#
#   Purpose....: Set a new parity
#
#   In params..: Parity
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetParity(char Parity)
{
	if (IsOpen())
	{
		Close();
		FParity = Parity;
		Open();
	}
	else
		FParity = Parity;
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetDataBits
#
#   Purpose....: Set a new data bit count
#
#   In params..: DataBits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetDataBits(int DataBits)
{
	if (IsOpen())
	{
		Close();
		FDataBits = DataBits;
		Open();
	}
	else
		FDataBits = DataBits;
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetStopBits
#
#   Purpose....: Set a new stop bit count
#
#   In params..: StopBits
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetStopBits(int StopBits)
{
	if (IsOpen())
	{
		Close();
		FStopBits = StopBits;
		Open();
	}
	else
		FStopBits = StopBits;
}

/*##########################################################################
#
#   Name       : TSerialDevice::OpenPort
#
#   Purpose....: Opens the port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::OpenPort()
{
	FHandle = RdosOpenCom(FBase, FIrq, (int)(115200L / FBaudrate), FParity, FDataBits, FStopBits, 0x4000, 0x4000);
}

/*##########################################################################
#
#   Name       : TSerialDevice::Open
#
#   Purpose....: Open device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Open()
{
	if (!IsOpen())
	{
		OpenPort();
		if (FHandle)
		{
			TDevice::Open();
			Offline();
		}
	}
}

/*##########################################################################
#
#   Name       : TSerialDevice::Close
#
#   Purpose....: Close device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Close()
{
	if (IsOpen())
	{
		RdosCloseCom(FHandle);
		FHandle = 0;
		TDevice::Close();
	}
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
#   Name       : TSerialDevice::Poll
#
#   Purpose....: Poll receive buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if any characters in buffer
#
##########################################################################*/
int TSerialDevice::Poll()
{
	return RdosPollCom(FHandle);
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
#   Name       : TSerialDevice::WaitForChar
#
#   Purpose....: Wait for a char with timeout
#
#   In params..: MaxWait    max number of milliseconds
#   Out params.: *
#   Returns....: TRUE if any characters in buffer
#
##########################################################################*/
int TSerialDevice::WaitForChar(long MaxWait)
{
	return RdosWaitForCom(FHandle, MaxWait);
}
