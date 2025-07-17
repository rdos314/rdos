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
# serial.cpp
# Serial port class
#
########################################################################*/

#include <string.h>
#include "serial.h"
#include "win32.h"

#define         SEND_BUF_SIZE           1200
#define         REC_BUF_SIZE            1200

/*##################  TSerialCommand::TSerialCommand ############
*   Purpose....: Constructor for TSerialCommand                     #
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
*   Purpose....: Destructor for TSerialCommand                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialCommand::~TSerialCommand()
{
}

/*##################  TSerialCommand::Block   #########################
*   Purpose....: Block com port                                                                                     #
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
*   Purpose....: Unblock com port                                                                                           #
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
*   Purpose....: Run commands                                                                                       #
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
*   Purpose....: Clear buffers in serial device                                     #
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
*   Purpose....: Resets DTR in serial device                                        #
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
*   Purpose....: Sets DTR in serial device                                                  #
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
*   Purpose....: Resets RTS in serial device                                        #
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
*   Purpose....: Sets RTS in serial device                                                  #
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
*   Purpose....: Enable use of RTS for RS485 tx enable                      #
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
*   Purpose....: Disable use of RTS for RS485 tx enable                     #
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
*   Purpose....: Write a char to serial device                                      #
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
*   Purpose....: Write a buffer to serial device                                            #
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
*   Purpose....: Write a string to serial device                                        #
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
*   Purpose....: Check if char available at serial device                               #
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
*   Purpose....: Read a char from serial device             #
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
*   Purpose....: Wait for char with timeout from serial device              #
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
*   Purpose....: Constructor for TSerialDevice                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialDevice::TSerialDevice(int Port, long Baudrate)
{
        Init(Port, Baudrate, 'N', 8, 1);
}

/*##################  TSerialDevice::TSerialDevice ############
*   Purpose....: Constructor for TSerialDevice                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialDevice::TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits)
{
        Init(Port, Baudrate, Parity, DataBits, StopBits);
}

/*##################  TSerialDevice::TSerialDevice ############
*   Purpose....: Constructor for TSerialDevice                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSerialDevice::TSerialDevice()
{
        Init(0, 9600, 'N', 8, 1);
}

/*##################  TSerialDevice::~TSerialDevice ############
*   Purpose....: Destructor for TSerialDevice                                       #
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
*   Purpose....: Begin exclusive access to serial channel                       #
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
*   Purpose....: End exclusive access to serial channel                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Unblock()
{
        FSection.Leave();
}

/*##################  TSerialDevice::Init ####################################
*   Purpose....: Init for TSerialDevice                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits)
{
        FPortHandle = 0;
        FPort = Port;
        FBaudrate = Baudrate;
        FParity = Parity;
        FDataBits = DataBits;
        FStopBits = StopBits;
        if (IsOpen())
    {
                TDevice::Close();
                Open();
    }
}

/*##################  TSerialDevice::DeviceName  ####################
*   Purpose....: Returns device name                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::DeviceName(char *Name, int MaxLen) const
{
        strncpy(Name,"WIN32 COM",MaxLen);
}

/*##################  TSerialDevice::SetComPort  #######################
*   Purpose....: Change com port                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetComPort(int Port)
{
        if (IsOpen())
    {
                Close();
                FPort = Port;
                Open();
    }
        else
    {
                FPort = Port;
    }
}

/*##################  TSerialDevice::GetPort  #######################
*   Purpose....: Get com port                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetPort() const
{
        return FPort;
}

/*##################  TSerialDevice::SetBaudrate  #####################
*   Purpose....: Change com port baudrate                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetBaudrate(long Baudrate)
{
        FBaudrate = Baudrate;
        if (IsOpen())
    {
            FCommDCB.BaudRate = FBaudrate;
        SetCommState(FPortHandle, &FCommDCB);
         }
}

/*##################  TSerialDevice::GetBaudrate  #######################
*   Purpose....: Get baudrate                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long TSerialDevice::GetBaudrate() const
{
        return FBaudrate;
}

/*##################  TSerialDevice::SetParity  #####################
*   Purpose....: Change com port parity                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetParity(char Parity)
{
        char NewParity;

        switch (Parity)
        {
                case 'N':
                case 'E':
                case 'O':
                        NewParity = Parity;
                        break;

                default:
                        NewParity = FParity;
                        break;
        }

        if (IsOpen())
        {
                Close();
                FParity = NewParity;
                Open();
        }
        else
                FParity = NewParity;
}

/*##################  TSerialDevice::GetParity  #######################
*   Purpose....: Get parity                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char TSerialDevice::GetParity() const
{
        return FParity;
}

/*##################  TSerialDevice::SetDataBits  #####################
*   Purpose....: Change com port number of data bits                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetDataBits(int DataBits)
{
        int NewDataBits;

        switch (DataBits)
        {
                case 5:
                case 6:
                case 7:
                case 8:
                        NewDataBits = DataBits;
                        break;

                default:
                        NewDataBits = FDataBits;
                        break;
        }

        if (IsOpen())
        {
                Close();
                FDataBits = NewDataBits;
                Open();
        }
        else
                FDataBits = NewDataBits;
}

/*##################  TSerialDevice::GetDataBits  #######################
*   Purpose....: Get # of data bits                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetDataBits() const
{
        return FDataBits;
}

/*##################  TSerialDevice::SetStopBits  #####################
*   Purpose....: Change com port number of stop bits                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetStopBits(int StopBits)
{
        int NewStopBits;

        switch (StopBits)
        {
                case 1:
                case 2:
                        NewStopBits = StopBits;
                        break;

                default:
                        NewStopBits = FStopBits;
                        break;

        }

        if (IsOpen())
        {
                Close();
                FStopBits = NewStopBits;
                Open();
        }
        else
                FStopBits = NewStopBits;
}

/*##################  TSerialDevice::GetStopBits  #######################
*   Purpose....: Get # of stop bits                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetStopBits() const
{
        return FStopBits;
}

/*##################  TSerialDevice::GetSendBufferSpace  #######################
*   Purpose....: Get send buffer space                                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetSendBufferSpace()
{
        return 0;
}

/*##################  TSerialDevice::GetReceiveBufferSpace  #######################
*   Purpose....: Get receive buffer space                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::GetReceiveBufferSpace()
{
        return 0;
}

/*##################  TSerialDevice::OpenPort  #######################
*   Purpose....: Opens win32 comport                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::OpenPort()
{
        COMMTIMEOUTS comm_timeouts;
    HANDLE result;
    char com_name[20];

    FPortHandle = 0;
        wsprintf( com_name, "\\\\.\\COM%d", FPort );

        result = CreateFile(com_name,
                                                GENERIC_READ | GENERIC_WRITE,
                                                0,
                                                NULL,
                                                OPEN_EXISTING,
                        0,
                                                NULL);

        if (result != INVALID_HANDLE_VALUE)
        FPortHandle = result;

    if (FPortHandle)
    {
                SetupComm(FPortHandle, REC_BUF_SIZE, SEND_BUF_SIZE);
            SetCommMask(FPortHandle, 0);

                GetCommState(FPortHandle, &FCommDCB );

            FCommDCB.BaudRate = FBaudrate;
        FCommDCB.ByteSize = FDataBits;
        FCommDCB.fOutX = 0;
                FCommDCB.fOutxCtsFlow = 1;

                switch (FParity)
                {
                        case 'N':
                        FCommDCB.Parity = NOPARITY;
                                break;

                        case 'E':
                        FCommDCB.Parity = EVENPARITY;
                                break;

                        case 'O':
                        FCommDCB.Parity = ODDPARITY;
                                break;
                }

                switch (FStopBits)
                {
                        case 1:
                        FCommDCB.StopBits = ONESTOPBIT;
                                break;

                        case 2:
                        FCommDCB.StopBits = TWOSTOPBITS;
                                break;
                                
                }
        FCommDCB.fOutxCtsFlow = 0;
        FCommDCB.fOutxDsrFlow = 0;
        FCommDCB.fDtrControl = DTR_CONTROL_ENABLE;
        FCommDCB.fRtsControl = RTS_CONTROL_ENABLE;

        FCommDCB.fBinary = 1;
        FCommDCB.fNull = 0;
        FCommDCB.EofChar = 0;
        FCommDCB.EvtChar = 0;
        FCommDCB.fInX = 0;
        FCommDCB.fOutX = 0;
        FCommDCB.XonChar = 0x11;
        FCommDCB.XoffChar = 0x13;
        FCommDCB.XonLim = (unsigned short)(REC_BUF_SIZE/4);
        FCommDCB.XoffLim = 10;

            comm_timeouts.ReadIntervalTimeout = MAXDWORD;
        comm_timeouts.ReadTotalTimeoutConstant = 0;
        comm_timeouts.ReadTotalTimeoutMultiplier = 0;
        comm_timeouts.WriteTotalTimeoutMultiplier = 0;
        comm_timeouts.WriteTotalTimeoutConstant = 0;
        SetCommTimeouts(FPortHandle, &comm_timeouts);

            SetCommState( FPortHandle, &FCommDCB);
        }
}

/*##################  TSerialDevice::ClosePort  #######################
*   Purpose....: Closes win32 comport                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::ClosePort()
{
        Clear();
        EscapeCommFunction(FPortHandle, CLRDTR);
        EscapeCommFunction(FPortHandle, CLRRTS);
        CloseHandle(FPortHandle);
}

/*##################  TSerialDevice::Open  ############################
*   Purpose....: Opens serial com channel                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Open()
{
        if (!IsOpen())
    {
        FPortHandle = 0;
                OpenPort();
        if (FPortHandle)
        {
            Offline();
                TDevice::Open();
        }
    }
}

/*##################  TSerialDevice::Close  ###########################
*   Purpose....: Closes serial com channel                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-15 le                                                #
*##########################################################################*/
void TSerialDevice::Close()
{
        if (IsOpen())
    {
        TDevice::Close();
                ClosePort();
        FPortHandle = 0;
    }
}

/*##################  TSerialDevice::Clear  ###########################
*   Purpose....: Clear serial com channel                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Clear()
{
        PurgeComm(FPortHandle, PURGE_RXCLEAR | PURGE_TXCLEAR);
}

/*##################  TSerialDevice::ResetDtr  ########################
*   Purpose....: Resets DTR on serial com channel                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::ResetDtr()
{
        FCommDCB.fDtrControl = DTR_CONTROL_DISABLE;
    SetCommState( FPortHandle, &FCommDCB);
}

/*##################  TSerialDevice::SetDtr  ########################
*   Purpose....: Sets DTR on serial com channel                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetDtr()
{
        FCommDCB.fDtrControl = DTR_CONTROL_ENABLE;
    SetCommState( FPortHandle, &FCommDCB);
}

/*##################  TSerialDevice::ResetRts  ########################
*   Purpose....: Reset RTS                                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::ResetRts()
{
        FCommDCB.fRtsControl = RTS_CONTROL_DISABLE;
    SetCommState( FPortHandle, &FCommDCB);
}

/*##################  TSerialDevice::SetRts  ########################
*   Purpose....: Set RTS                                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::SetRts()
{
        FCommDCB.fRtsControl = RTS_CONTROL_ENABLE;
    SetCommState(FPortHandle, &FCommDCB);
}

/*##################  TSerialDevice::EnableAutoRts  ########################
*   Purpose....: Enables auto-RTS control for RS485                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::EnableAutoRts()
{
        FCommDCB.fRtsControl = RTS_CONTROL_TOGGLE;
    SetCommState( FPortHandle, &FCommDCB);
}

/*##################  TSerialDevice::DisableAutoRts  ########################
*   Purpose....: Disables auto-RTS control for RS485                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::DisableAutoRts()
{
        FCommDCB.fRtsControl = RTS_CONTROL_ENABLE;
    SetCommState( FPortHandle, &FCommDCB);
}

/*##################  TSerialDevice::Write  ###########################
*   Purpose....: Write buffer to serial com channel                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Write(const char *buf, int count)
{
        COMSTAT que;
    DWORD comerr;
    int status;
    unsigned long written;

    ClearCommError(FPortHandle, &comerr, &que);
    status = WriteFile( FPortHandle,
                                        buf,
                                        count,
                        &written,
                        0);
    if (status == 0)
    {
        if ( (comerr = GetLastError()) != ERROR_IO_PENDING )
            ClearCommError(FPortHandle, &comerr, &que);
        }
}

/*##################  TSerialDevice::Write  ###########################
*   Purpose....: Write char to serial com channel                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Write(char ch)
{
        Write(&ch, 1);
}

/*##################  TSerialDevice::Write  ###########################
*   Purpose....: Write string to serial com channel                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Write(const char *str)
{
        Write(str, strlen(str));
}

/*##################  TSerialDevice::Poll    ###########################
*   Purpose....: Check if char is available                                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::Poll()
{
        COMSTAT que;
        DWORD comerr;

        if (!ClearCommError(FPortHandle, &comerr, &que))
        return FALSE;
        return (que.cbInQue > 0);
}

/*##################  TSerialDevice::Read    ###########################
*   Purpose....: Read a char from serial com channel                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char TSerialDevice::Read()
{
        COMSTAT que;
        DWORD comerr;
    char ch;
    unsigned long count;
    int result;

    ch = 0;
        ClearCommError(FPortHandle, &comerr, &que);

    result = ReadFile(  FPortHandle,
                                        &ch,
                        1,
                        &count,
                                        0);

    if (result == 0)
    {
        if ((comerr = GetLastError()) != ERROR_IO_PENDING)
                ClearCommError(FPortHandle, &comerr, &que);
        }
        return ch;
}

/*##################  TSerialDevice::WaitForChar    ###########################
*   Purpose....: Wait for char from port                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::WaitForChar(long MaxWait)
{
        COMSTAT que;
        DWORD comerr;
    DWORD stop = GetTickCount() + MaxWait;

        if (!ClearCommError(FPortHandle, &comerr, &que))
        return FALSE;

        while (que.cbInQue == 0)
    {
        if (GetTickCount() > stop)
                return FALSE;
        WaitMilli(1);
                ClearCommError(FPortHandle, &comerr, &que);
    }
    return TRUE;
}


/*##################  TSerialDevice::SupportsFullDuplex    ###########################
*   Purpose....: Check for full duplex suppport                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialDevice::SupportsFullDuplex()
{
    return TRUE;
}
