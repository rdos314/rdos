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
    OnChar = 0;    

    FPort = Port;
    FBaudrate = Baudrate;
    FParity = Parity;
    FDataBits = DataBits;
    FStopBits = StopBits;
	FDebugFile = 0;
	FUseCts = FALSE;
	
	OpenPort();
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice()
{
    OnChar = 0;    
    FPort = 0;
    FBaudrate = 0;
    FParity = 0;
    FDataBits = 0;
    FStopBits = 0;
    FUseCts = FALSE;
    FHandle = 0;
}

/*##########################################################################
#
#   Name       : TSerialDevice::TSerialDevice
#
#   Purpose....: Constructor
#
#   In params..: *
#   Returns....: *
#
##########################################################################*/
TSerialDevice::TSerialDevice(const char *IniSection)
 : TWaitDevice(IniSection)
{
    OnChar = 0;    
    FPort = 0;
    FBaudrate = 0;
    FParity = 0;
    FDataBits = 0;
    FStopBits = 0;
    FUseCts = FALSE;
    FHandle = 0;
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
	: TWaitDevice(IniSection)
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
	: TWaitDevice(IniSection)
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
#   Name       : TSerialDevice::Add
#
#   Purpose....: Add object to wait
#
#   In params..: wait
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForCom(Wait->GetHandle(), FHandle, this);
}

/*##########################################################################
#
#   Name       : TSerialDevice::StartDebug
#
#   Purpose....: Start debugging on device
#
#   In params..: Handle debug file handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::StartDebug(TFile *File, int InChannel, int OutChannel)
{
    FDebugFile = File;
    FInChannel = InChannel;
    FOutChannel = OutChannel;
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
    if (FPort)
    	FHandle = RdosOpenCom(FPort - 1, FBaudrate, FParity, FDataBits, FStopBits, 0x4000, 0x4000);
    else
        FHandle = 0;
        
    if (FHandle)
    {
        if (FUseCts)
            RdosEnableCts(FHandle);
        else
            RdosDisableCts(FHandle);
    }
}

/*##################  TSerialDevice::IsOpen  ############################
*   Purpose....: Opens serial com channel			                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::IsOpen() const
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
	{
		RdosCloseCom(FHandle);
        FHandle = 0;
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
    if (FHandle)
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
    return 1000;
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
    return 1000;
}

/*##########################################################################
#
#   Name       : TSerialDevice::EnableCts
#
#   Purpose....: Enable CTS signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::EnableCts()
{
    FUseCts = TRUE;
    
    if (FHandle)
    	RdosEnableCts(FHandle);
}

/*##########################################################################
#
#   Name       : TSerialDevice::DisableCts
#
#   Purpose....: Disable CTS signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::DisableCts()
{
    FUseCts = FALSE;

    if (FHandle)
    	RdosDisableCts(FHandle);
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
    if (FHandle)
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
    if (FHandle)
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
    if (FHandle)
        RdosResetRts(FHandle);
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
    if (FHandle)
        RdosSetRts(FHandle);
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
    if (FHandle)
        RdosEnableAutoRts(FHandle);
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
    if (FHandle)
        RdosDisableAutoRts(FHandle);
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
    TSerialDebug Debug;

    if (FHandle)
    {
    	RdosWriteCom(FHandle, ch);

    	if (FDebugFile && FOutChannel)
	    {
    	    RdosGetTics(&Debug.TimeMSB, &Debug.TimeLSB);
	        Debug.Channel = FOutChannel;
	        Debug.ch = ch;
    	    FDebugFile->Write(&Debug, sizeof(Debug));
	    }
	}	
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
		Write(*buf);
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
		Write(*str);
		str++;
	}
}

/*##########################################################################
#
#   Name       : TSerialDevice::WaitForSendCompleted
#
#   Purpose....: Wait until send buffer is empty
#
#   In params..: *
#   Out params.: *
#   Returns....: character
#
##########################################################################*/
void TSerialDevice::WaitForSendCompleted()
{
    if (FHandle)
        RdosWaitForSendCompletedCom(FHandle);
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
int TSerialDevice::WaitForChar(long Timeout)
{
    if (!FWait)
        CreateWait();

	if (FWait)
		if (FWait->WaitTimeout(Timeout) == this)
			return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : TSerialDevice::Poll
#
#   Purpose....: Poll port
#
#   In params..: *
#   Out params.: *
#   Returns....: true if successful
#
##########################################################################*/
int TSerialDevice::Poll()
{
    return WaitForChar(25);
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
    char ch = 0;
    TSerialDebug Debug;

    if (FHandle)
    {
    	ch = RdosReadCom(FHandle);

    	if (FDebugFile && FInChannel)
	    {
    	    RdosGetTics(&Debug.TimeMSB, &Debug.TimeLSB);
	        Debug.Channel = FInChannel;
	        Debug.ch = ch;
    	    FDebugFile->Write(&Debug, sizeof(Debug));
	    }	
    }
    
	return ch;
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
