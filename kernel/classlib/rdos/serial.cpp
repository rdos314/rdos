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

/*##################  TSerialCommand::TSerialCommand ############
*   Purpose....: Constructor for TSerialCommand	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialCommand::TSerialCommand(TSerialDevice *serial)
{
	FSerial = serial;
}

/*##################  TSerialCommand::~TSerialCommand ############
*   Purpose....: Destructor for TSerialCommand	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialCommand::~TSerialCommand()
{
}

/*##################  TSerialCommand::Block   #########################
*   Purpose....: Block com port											    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-12-11 le                                                #
*##########################################################################*/
void TSerialCommand::Block()
{
	FSerial->Block();
}

/*##################  TSerialCommand::Unblock   #######################
*   Purpose....: Unblock com port											    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-12-11 le                                                #
*##########################################################################*/
void TSerialCommand::Unblock()
{
	FSerial->Unblock();
}

/*##################  TSerialCommand::Run   ###########################
*   Purpose....: Run commands											    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-12-11 le                                                #
*##########################################################################*/
int TSerialCommand::Run()
{
	int stat;

	FSerial->Block();
	stat = Execute();
	FSerial->Unblock();
	return stat;
}

/*##################  TSerialCommand::Clear ###########################
*   Purpose....: Clear buffers in serial device			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::Clear()
{
	FSerial->Clear();
}

/*##################  TSerialCommand::ResetDtr #######################
*   Purpose....: Resets DTR in serial device			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::ResetDtr()
{
	FSerial->ResetDtr();
}

/*##################  TSerialCommand::SetDtr #########################
*   Purpose....: Sets DTR in serial device				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::SetDtr()
{
	FSerial->SetDtr();
}

/*##################  TSerialCommand::ResetRts #######################
*   Purpose....: Resets RTS in serial device			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::ResetRts()
{
	FSerial->ResetRts();
}

/*##################  TSerialCommand::SetRts #########################
*   Purpose....: Sets RTS in serial device				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::SetRts()
{
	FSerial->SetRts();
}

/*##################  TSerialCommand::EnableAutoRts #######################
*   Purpose....: Enable use of RTS for RS485 tx enable	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::EnableAutoRts()
{
	FSerial->EnableAutoRts();
}

/*##################  TSerialCommand::DisableAutoRts #######################
*   Purpose....: Disable use of RTS for RS485 tx enable	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::DisableAutoRts()
{
	FSerial->DisableAutoRts();
}

/*##################  TSerialCommand::Write ###########################
*   Purpose....: Write a char to serial device			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::Write(char ch)
{
	FSerial->Write(ch);
}

/*##################  TSerialCommand::Write ###########################
*   Purpose....: Write a buffer to serial device			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::Write(const char *buf, int count)
{
	FSerial->Write(buf, count);
}

/*##################  TSerialCommand::Write ###########################
*   Purpose....: Write a string to serial device			                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::Write(const char *str)
{
	FSerial->Write(str);
}

/*##################  TSerialCommand::Read ###########################
*   Purpose....: Read a char from serial device	            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char TSerialCommand::Read()
{
	return FSerial->Read();
}

/*##################  TSerialCommand::WaitForChar ###########################
*   Purpose....: Wait for char with timeout from serial device	            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
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
    OnChar = 0;    

    FPort = Port;
	FBase = CalcBase(Port);
	FIrq = CalcIrq(Port);
    FBaudrate = Baudrate;
    FParity = Parity;
    FDataBits = DataBits;
    FStopBits = StopBits;
    FCurrWait = Wait;
	
	OpenPort();
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

    FPort = Port;
	FBase = CalcBase(Port);
	FIrq = Irq;
    FBaudrate = Baudrate;
    FParity = Parity;
    FDataBits = DataBits;
    FStopBits = StopBits;
    FCurrWait = Wait;
	
	OpenPort();
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

/*##################  TSerialDevice::OpenPort  #######################
*   Purpose....: Opens V25 comport			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::OpenPort()
{
	FHandle = RdosOpenCom(FBase, FIrq, (int)(115200L / FBaudrate), FParity, FDataBits, FStopBits, 0x4000, 0x4000);

    if (FHandle)
    	RdosAddWaitForCom(RegisterWait(FCurrWait), FHandle, this);
}

/*##################  TSerialDevice::IsOpen  ############################
*   Purpose....: Opens serial com channel			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::IsOpen()
{
	if (FHandle)
	    return TRUE;
	else
	    return FALSE;
}

/*##################  TSerialDevice::Open  ############################
*   Purpose....: Opens serial com channel			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Open()
{
	if (!FHandle)
		OpenPort();
}

/*##################  TSerialDevice::Close  ###########################
*   Purpose....: Closes serial com channel			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-15 le                                                #
*##########################################################################*/
void TSerialDevice::Close()
{
	if (FHandle)
        RdosCloseCom(FHandle);
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

/*##################  TSerialDevice::SetBaudrate  #####################
*   Purpose....: Change com port baudrate			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
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
}

/*##################  TSerialDevice::SetParity  #####################
*   Purpose....: Change com port parity			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
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

/*##################  TSerialDevice::SetDataBits  #####################
*   Purpose....: Change com port number of data bits			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
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

/*##################  TSerialDevice::SetStopBits  #####################
*   Purpose....: Change com port number of stop bits			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
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

/*##################  TSerialDevice::GetPort  #####################
*   Purpose....: Get com port			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetPort() const
{
	return FPort;
}

/*##################  TSerialDevice::GetBaudrate  #####################
*   Purpose....: Get com port baudrate			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long TSerialDevice::GetBaudrate() const
{
	return FBaudrate;
}

/*##################  TSerialDevice::GetParity  #####################
*   Purpose....: Get com port parity			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char TSerialDevice::GetParity() const
{
	return FParity;
}

/*##################  TSerialDevice::GetDataBits  #####################
*   Purpose....: Get com port number of data bits			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetDataBits() const
{
	return FDataBits;
}

/*##################  TSerialDevice::GetStopBits  #####################
*   Purpose....: Get com port number of stop bits			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetStopBits() const
{
	return FStopBits;
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
