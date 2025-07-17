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
# Serial device class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include "serial.h"
#include "rdos.h"
#include "path.h"
#include "direntry.h"

#define FALSE 0
#define TRUE !FALSE

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

/*##################  TSerialCommand::DumpEvents ###########################
*   Purpose....: C                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialCommand::Clear()
{
        FSerial->Clear();
}

/*##########################################################################
#
#   Name       : TSerialCommand::DefineEventDebug
#
#   Purpose....: Define event debug
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialCommand::DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel)
{
    return FSerial->DefineEventDebug(LogPath, DumpFiles, EntryCount, InChannel, OutChannel);
}

/*##################  TSerialCommand::DumpEvents ###########################
*   Purpose....: Dump events                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSerialCommand::DumpEvents()
{
    return FSerial->DumpEvents();
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

/*##########################################################################
#
#   Name       : TSerialDevice::Init
#
#   Purpose....: Init device
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Init()
{
    OnChar = 0;    

    FPort = 0;
    FHandle = 0;
    FBaudrate = 9600;
    FParity = 'N';
    FDataBits = 8;
    FStopBits = 1;
    FDebugFile = 0;
    FCurrFile = 0;
    FCurrId = 0;
    FNextPos = 0;
    FEntryCount = 0;
    FFileCount = 0;
    FUseCts = FALSE;
    FBufferSize = 0x4000;
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
    Init();

    FPort = Port;
    FBaudrate = Baudrate;
    FParity = Parity;
    FDataBits = DataBits;
    FStopBits = StopBits;
       
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
 : FSection("Serial"),
   FEventSection("EvSerial")
{
    Init();
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
TSerialDevice::TSerialDevice(int Handle)
 : FSection("Serial"),
   FEventSection("EvSerial")
{
    Init();

    FPort = 0;
    FHandle = Handle;
    FSupportsFullDuplex = RdosSupportsFullDuplex(FHandle);
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
  : FSection("Serial"),
    FEventSection("EvSerial")
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
  : FSection("Serial"),
    FEventSection("EvSerial")
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
    Stop();

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
        RdosAddWaitForCom(Wait->GetHandle(), FHandle, (int)this);
}

/*##########################################################################
#
#   Name       : TSerialDevice::GetHandle
#
#   Purpose....: Get handle
#
#   In params..: 
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::GetHandle()
{
    return FHandle;
}

/*##########################################################################
#
#   Name       : TSerialDevice::SetBufferSize
#
#   Purpose....: Set buffer size
#
#   In params..: wait
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SetBufferSize(int Size)
{
    FBufferSize = Size;
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

/*##########################################################################
#
#   Name       : TSerialDevice::StopDebug
#
#   Purpose....: Stop debugging on device
#
#   In params..: Handle debug file handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::StopDebug()
{
    FDebugFile = 0;
}

/*##########################################################################
#
#   Name       : TSerialDevice::CheckFileCount
#
#   Purpose....: Check file count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::CheckFileCount()
{
    TDirList FileList;
    TDirEntry entry;
    TString basename;
    TPathName path;
    char *file;
    int count = 0;
    bool ok;

    file = new char[256];

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    ok = FileList.GotoLast();

    while (ok)
    {
        entry = FileList.Get();
        basename = entry.GetEntryName();
        strcpy(file, basename.GetData());
        if (strstr(file, ".sdd"))
        {
            if (entry.GetFileSize() == 0)
            {
                path = entry.GetPathName();
                if (path.IsFile())
                    path.DeleteFile();
            }
            else
            {
                count++;
                if (count > FFileCount)
                {
                    path = entry.GetPathName();
                    if (path.IsFile())
                        path.DeleteFile();
                }
            }
        }
            
        ok = FileList.GotoPrev();
    }    

    delete file;
}

/*##########################################################################
#
#   Name       : TSerialDevice::InitFiles
#
#   Purpose....: Init files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::InitFiles()
{
    bool ok;
    TDirList FileList;
    TDirEntry entry;
    TString basename;
    TPathName path;
    char *file;
    char *ptr;
    int index;
    TString str;

    CheckFileCount();        

    FCurrId = 0;

    file = new char[256];

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    ok = FileList.GotoFirst();

    while (ok)
    {
        entry = FileList.Get();
        basename = entry.GetEntryName();
        strcpy(file, basename.GetData());
        if (strstr(file, ".sdd"))
        {
            ptr = strchr(file, '.');
            if (ptr)
                *ptr = 0;

            index = atoi(file);            

            if (index > FCurrId)
                FCurrId = index;
        }
            
        ok = FileList.GotoNext();
    }    

    delete file;

    FCurrId++;
    str.printf("%s/%d.sdd", FLogPath.GetData(), FCurrId);
    FCurrFile = new TFile(str.GetData(), 0);
}

/*##########################################################################
#
#   Name       : TSerialDevice::DefineEventDebug
#
#   Purpose....: Define event debug
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel)
{
    int i;

    FLogPath = LogPath;
    FInChannel = InChannel;
    FOutChannel = OutChannel;
    FFileCount = DumpFiles;

    TPathName path(FLogPath);

    if (path.MakeDir())
    {        
        CheckFileCount();

        FEntryCount = EntryCount;
        FEntryArr = new struct TSerialDebug[EntryCount];

        // initialize cache to empty
        for (i = 0; i < EntryCount; i++) 
        {
            FEntryArr[i].Channel = 0;
            FEntryArr[i].Time = 0;
            FEntryArr[i].ch = 0;
        }

        return TRUE;
    }
    else
    {
        FFileCount = 0;
        return FALSE;
    }
}

/*##########################################################################
#
#   Name       : TSerialDevice::DumpEvents
#
#   Purpose....: Dump buffer to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::DumpEvents()
{
    TString str;

    if (FFileCount && FInChannel && FOutChannel && !IsRunning() && FNewData)
    {
        str.printf("ComLog %d", FPort);
        Start(str.GetData(), 0x4000);
        return TRUE;
    }
    else
        return FALSE;
}

/*##################  TSerialDevice::Execute  #######################
*   Purpose....: Dump thread                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::Execute()
{
    int pos;
    struct TSerialDebug *DumpArr;
    TPathName path(FLogPath);

    RdosWaitMilli(100);

    if (path.MakeDir())
    {        
        InitFiles();

        DumpArr = new struct TSerialDebug[FEntryCount];

        FEventSection.Enter();

        pos = FNextPos;

        for (int i = 0; i < FEntryCount; i++)
            DumpArr[i] = FEntryArr[i];

        FNewData = false;
        
        FEventSection.Leave();
        
        for (int i = pos; i < FEntryCount; i++) 
            if (DumpArr[i].Time)
                FCurrFile->Write(&DumpArr[i], sizeof(struct TSerialDebug));

        for (int i = 0; i < pos; i++)
            if (DumpArr[i].Time)
                FCurrFile->Write(&DumpArr[i], sizeof(struct TSerialDebug));

        delete DumpArr;
        delete FCurrFile;
        FCurrFile = 0;
    }
}

/*##################  TSerialDevice::OpenPort  #######################
*   Purpose....: Opens V25 comport                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSerialDevice::OpenPort()
{
    if (FPort)
        FHandle = RdosOpenCom(FPort - 1, FBaudrate, FParity, FDataBits, FStopBits, FBufferSize, FBufferSize);
    else
        FHandle = 0;
        
    if (FHandle)
    {
        FSupportsFullDuplex = RdosSupportsFullDuplex(FHandle);

        if (FUseCts)
            RdosEnableCts(FHandle);
        else
            RdosDisableCts(FHandle);
    }
}

/*##################  TSerialDevice::IsOpen  ############################
*   Purpose....: Opens serial com channel                                               #
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
*   Purpose....: Opens serial com channel                                               #
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
*   Purpose....: Closes serial com channel                                              #
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
*   Purpose....: Change com port baudrate                                               #
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
*   Purpose....: Change com port parity                                         #
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
*   Purpose....: Change com port number of data bits                                            #
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
*   Purpose....: Change com port number of stop bits                                            #
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
*   Purpose....: Get com port                                           #
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
*   Purpose....: Get com port baudrate                                          #
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
*   Purpose....: Get com port parity                                            #
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
*   Purpose....: Get com port number of data bits                                               #
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
*   Purpose....: Get com port number of stop bits                                               #
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
#   Name       : TSerialDevice::SupportsFullDuplex
#
#   Purpose....: Check if port supports full duplex
#
#   In params..: *
#   Out params.: *
#   Returns....: Number of bytes free space
#
##########################################################################*/
int TSerialDevice::SupportsFullDuplex()
{
    return FSupportsFullDuplex;
}

/*##########################################################################
#
#   Name       : TSerialDevice::Reset
#
#   Purpose....: Reset port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::Reset()
{
    if (FHandle)
        RdosResetCom(FHandle);
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
#   Name       : TSerialDevice::GetCts
#
#   Purpose....: Get CTS state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::GetCts()
{
    if (FHandle)
        return RdosGetCts(FHandle);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TSerialDevice::GetDsr
#
#   Purpose....: Get DSR state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::GetDsr()
{
    if (FHandle)
        return RdosGetDsr(FHandle);
    else
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
#   Name       : TSerialDevice::IsAutoRtsOn
#
#   Purpose....: Check if automatic RTS generation during send is on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSerialDevice::IsAutoRtsOn()
{
    if (FHandle)
        return RdosIsAutoRtsOn(FHandle);
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TSerialDevice::SendBreak
#
#   Purpose....: Send com break
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSerialDevice::SendBreak(char CharCount)
{
    if (FHandle && CharCount > 0)
        RdosSendComBreak(FHandle, CharCount);
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
            Debug.Time = RdosGetLongTime();
            Debug.Channel = FOutChannel;
            Debug.ch = ch;
            FDebugFile->Write(&Debug, sizeof(Debug));
        }

        if (FFileCount && FEntryCount && FOutChannel)
        {
            FEventSection.Enter();

            FEntryArr[FNextPos].Time = RdosGetLongTime();
            FEntryArr[FNextPos].Channel = FOutChannel;
            FEntryArr[FNextPos].ch = ch;

            FNextPos++;
            if (FNextPos >= FEntryCount)
                FNextPos = 0;

            FNewData = true;

            FEventSection.Leave();
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
    TWaitDevice *wd;

    if (!FWait)
        CreateWait();

    if (FWait && FHandle)
    {
        wd = FWait->WaitTimeout(Timeout);
        if (wd == this)
            return TRUE;
        else
            return Poll();
    }

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
    if (RdosGetComRecCount(FHandle))
        return TRUE;
    else
        return FALSE;
//    return WaitForChar(25);
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
            Debug.Time = RdosGetLongTime();
            Debug.Channel = FInChannel;
            Debug.ch = ch;
            FDebugFile->Write(&Debug, sizeof(Debug));
        }   

        if (FFileCount && FEntryCount && FInChannel)
        {
            FEventSection.Enter();

            FEntryArr[FNextPos].Time = RdosGetLongTime();
            FEntryArr[FNextPos].Channel = FInChannel;
            FEntryArr[FNextPos].ch = ch;

            FNextPos++;
            if (FNextPos >= FEntryCount)
                FNextPos = 0;

            FNewData = true;

            FEventSection.Leave();
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
