/*####################################  SERIAL.CPP                      #################################################
##    Description: Serial communications base class                                          ##
##                                                                                                                  ##
##    Created....: 96-11-20 le                                                        Printed...: 90-10-25 an      ##
####################################################################################################################*/

#include <string.h>
#include "serial.h"
#include "kernel.h"

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

/*##################  TSerialCommand::Poll ############################
*   Purpose....: Check if char available at serial device	   		        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialCommand::Poll()
{
	return FSerial->Poll();
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

/*##################  TSerialDevice::TSerialDevice ############
*   Purpose....: Constructor for TSerialDevice			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialDevice::TSerialDevice()
{
}

/*##################  TSerialDevice::TSerialDevice ############
*   Purpose....: Constructor for TSerialDevice			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialDevice::TSerialDevice(const char *IniSection)
	: TDevice(IniSection)
{
}

/*##################  TSerialDevice::~TSerialDevice ############
*   Purpose....: Destructor for TSerialDevice			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialDevice::~TSerialDevice()
{
	if (IsOpen())
		Close();
}

/*##################  TSerialDevice::Block  #####################
*   Purpose....: Begin exclusive access to serial channel	                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Block()
{
	FSection.Enter();
}

/*##################  TSerialDevice::Unblock  #####################
*   Purpose....: End exclusive access to serial channel	                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Unblock()
{
	FSection.Leave();
}

/*##################  TSerialDevice::ResetDtr  ########################
*   Purpose....: Resets DTR on serial com channel		                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::ResetDtr()
{
}

/*##################  TSerialDevice::SetDtr  ##########################
*   Purpose....: Sets DTR on serial com channel			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetDtr()
{
}

/*##################  TSerialDevice::ResetRts  ########################
*   Purpose....: Resets RTS on serial com channel		                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::ResetRts()
{
}

/*##################  TSerialDevice::SetRts  ##########################
*   Purpose....: Sets RTS on serial com channel			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetRts()
{
}

/*##################  TSerialDevice::EnableAutoRts  ########################
*   Purpose....: Enable RTS to be used for RS485 tx enable	                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::EnableAutoRts()
{
}

/*##################  TSerialDevice::DisableAutoRts  ########################
*   Purpose....: Disable RTS to be used for RS485 tx enable	                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::DisableAutoRts()
{
}

