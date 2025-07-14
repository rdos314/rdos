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
# ftp.cpp
# FTP client class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "ftp.h"

#include "rdos.h"

#define DEBUG 1

#define STACK_SIZE  0x4000

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : DataSocketThread
#
#   Purpose....: Startup procedure for data socket thread handler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void DataSocketThread(void *ptr)
{
        ((TFtp *)ptr)->HandleDataSocket();
}

/*##########################################################################
#
#   Name       : TFtpEntry::TFtpEntry
#
#   Purpose....: Constructor for FTP entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpEntry::TFtpEntry(int year, int month, int day, int hour, int min, const char *ename)
  : time(year, month, day, hour, min, 0),
    name(ename)
{
}

/*##########################################################################
#
#   Name       : TFtpEntry::~TFtpEntry
#
#   Purpose....: Destructor for FTP entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpEntry::~TFtpEntry()
{
}

/*##########################################################################
#
#   Name       : TFtpDirEntry::TFtpDirEntry
#
#   Purpose....: Constructor for FTP directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpDirEntry::TFtpDirEntry(int year, int month, int day, int hour, int min, const char *ename)
  : TFtpEntry(year, month, day, hour, min, ename)
{
}

/*##########################################################################
#
#   Name       : TFtpDirEntry::~TFtpDirEntry
#
#   Purpose....: Destructor for FTP directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpDirEntry::~TFtpDirEntry()
{
}

/*##########################################################################
#
#   Name       : TFtpDirEntry::IsDir
#
#   Purpose....: Check if entry is directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpDirEntry::IsDir()
{
    return TRUE;
}

/*##########################################################################
#
#   Name       : TFtpFileEntry::TFtpFileEntry
#
#   Purpose....: Constructor for FTP file entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpFileEntry::TFtpFileEntry(int year, int month, int day, int hour, int min, const char *ename, int esize)
  : TFtpEntry(year, month, day, hour, min, ename)
{
    size = esize;
}

/*##########################################################################
#
#   Name       : TFtpFileEntry::~TFtpFileEntry
#
#   Purpose....: Destructor for FTP file entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpFileEntry::~TFtpFileEntry()
{
}

/*##########################################################################
#
#   Name       : TFtpFileEntry::IsDir
#
#   Purpose....: Check if entry is directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpFileEntry::IsDir()
{
    return FALSE;
}

/*##########################################################################
#
#   Name       : TFtp::TFtp
#
#   Purpose....: Constructor for FTP protocol
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtp::TFtp(long IP, int port, const char *user, const char *passw)
  : FUser(user),
    FPassw(passw),
    FAppSection("FTP.App"),
    FSection("FTP.Gen")
{
    FIp = IP;
    FPort = port;
    FSocket = 0;
    FDataSocket = 0;
    OnMsg = 0;
    FLastCode = -1;
    FDirList = 0;
    FFileList = 0;

    FCurrDir = 0;
    FCurrFile = 0;
    
    FCloseData = FALSE;
    FDirCached = FALSE;
    FGetDir = FALSE;
    FSetDir = FALSE;
    FMkDir = FALSE;
    FGetFile = FALSE;
    FWriteFile = FALSE;
    FStorSent = FALSE;
    FWriteWait = FALSE;
    FReady = FALSE;
    FSuccess = FALSE;
    FFile = 0;
    FEnabled = FALSE;
    
    Start("FTP", STACK_SIZE);
}

/*##########################################################################
#
#   Name       : TFtp::~TFtp
#
#   Purpose....: Destructor for FTP protocol
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtp::~TFtp()
{
    if (FSocket)
    {
        FSocket->Push();
        FSocket->Close();
        delete FSocket;
    }

    if (FDataSocket)
    {
        FDataSocket->Push();
        FDataSocket->Close();
        FCloseData = TRUE;

        while (FDataSocket)
            RdosWaitMilli(50);
    }

    ClearEntries();
}

/*##########################################################################
#
#   Name       : TFtp::Enable
#
#   Purpose....: Enable client
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::Enable()
{
    int tries;
    
    FEnabled = TRUE;

    FAppSection.Enter();

    for (tries = 0; tries < 100 && !FSocket; tries++)
        RdosWaitMilli(100);

    if (!FReady)
        FAppSignal.WaitTimeout(15000);

    FAppSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::Disable
#
#   Purpose....: Disable client
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::Disable()
{
    if (FEnabled)
    {
        NotifyMsg("QUIT\r\n");

        if (FSocket)
            FSocket->Write("QUIT\r\n");

        if (FSocket)
            FSocket->Push();

        FEnabled = FALSE;
        FReady = FALSE;
    }        
}

/*##########################################################################
#
#   Name       : TFtp::SetDir
#
#   Purpose....: Set current directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::SetDir(const char *path)
{
    int ok = FALSE;

    FAppSection.Enter();
    ClearEntries();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);

    if (FReady)
    {
        FAppSignal.Clear();

        FSuccess = FALSE;
        FReady = FALSE;
        FSetDir = TRUE;

        SendCwd(path);
    
        FAppSignal.WaitTimeout(15000);

        ok = FSuccess;  
    }

    FAppSection.Leave();

    FSetDir = FALSE;

    return ok;
}

/*##########################################################################
#
#   Name       : TFtp::SetAsciiMode
#
#   Purpose....: Set ASCII file transfer mode
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SetAsciiMode()
{
    FAppSection.Enter();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);

    if (FReady)
        SendType('A');

    FAppSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::SetBinaryMode
#
#   Purpose....: Set binary file transfer mode
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SetBinaryMode()
{
    FAppSection.Enter();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);

    if (FReady)
        SendType('I');

    FAppSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::GetFile
#
#   Purpose....: Get a single file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::GetFile(const char *remote, TFile *file)
{
    int ok = FALSE;
    int tries;

    FAppSection.Enter();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);


    for (tries = 0; tries < 3 && FReady; tries++)
    {
        FAppSignal.Clear();
        FSuccess = FALSE;
        FAborted = FALSE;

        FFile = file;
        FFile->SetSize(0);
        FFile->SetPos(0);
        FRemoteFile = TString(remote);

        FReady = FALSE;
        FGetFile = TRUE;
        SendPasv();
    
        FAppSignal.WaitTimeout(10 * 60000);       

        if (FAborted)
        {
            if (FDataSocket)
            {
                FDataSocket->Push();
                FDataSocket->Close();
            }

            FCloseData = TRUE;

            NotifyMsg("Data socket closed\r\n");

            while (FDataSocket)
                RdosWaitMilli(50);

            FAborted = FALSE;
        }

        if (FSuccess)
            break;

    }
    ok = FSuccess;

    FGetFile = FALSE;

    FAppSection.Leave();
    return ok;
}

/*##########################################################################
#
#   Name       : TFtp::CreateFile
#
#   Purpose....: Create a single file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::CreateFile(const char *remote, TFile *file)
{
    int ok = FALSE;
    int tries;

    FAppSection.Enter();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);


    for (tries = 0; tries < 3 && FReady; tries++)
    {
        FAppSignal.Clear();
        FSuccess = FALSE;
        FAborted = FALSE;

        FFile = file;
        FFile->SetPos(0);
        FRemoteFile = TString(remote);

        FReady = FALSE;
        FStorSent = FALSE;
        FWriteWait = FALSE;
        FWriteFile = TRUE;
        SendPasv();
    
        FAppSignal.WaitTimeout(10 * 60000);       

        if (FAborted)
        {
            if (FDataSocket)
            {
                FDataSocket->Push();
                FDataSocket->Close();
            }
            
            FCloseData = TRUE;

            NotifyMsg("Data socket closed\r\n");

            while (FDataSocket)
                RdosWaitMilli(50);

            FAborted = FALSE;
        }

        if (FSuccess)
            break;

    }
    ok = FSuccess;

    FWriteFile = FALSE;

    FAppSection.Leave();
    return ok;
}

/*##########################################################################
#
#   Name       : TFtp::MkDir
#
#   Purpose....: Create remote directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::MkDir(const char *path)
{
    int ok = FALSE;

    FAppSection.Enter();
    ClearEntries();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);

    if (FReady)
    {
        FAppSignal.Clear();

        FSuccess = FALSE;
        FReady = FALSE;
        FMkDir = TRUE;
        SendMkd(path);
    
        FAppSignal.WaitTimeout(15000);     
        ok = FSuccess;  
    }

    FAppSection.Leave();

    FMkDir = FALSE;

    return ok;
}

/*##########################################################################
#
#   Name       : TFtp::CacheDir
#
#   Purpose....: Cache current directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::CacheDir()
{
    int tries;

    FAppSection.Enter();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);

    for (tries = 0; tries < 3 && FReady; tries++)
    {
        FAppSignal.Clear();
        FDirCached = FALSE;
        FAborted = FALSE;
        
        if (FReady)
        {
            FReady = FALSE;
            FGetDir = TRUE;
            SendPasv();
    
            FAppSignal.WaitTimeout(15000);       
        }

        if (FAborted)
        {
            if (FDataSocket)
            {
                FDataSocket->Push();
                FDataSocket->Close();
            }
            
            FCloseData = TRUE;

            NotifyMsg("Data socket closed\r\n");

            while (FDataSocket)
                RdosWaitMilli(50);

            FAborted = FALSE;
        }

        if (FDirCached)
            break;
    }

    FGetDir = FALSE;

    FAppSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::GetCurrDirName
#
#   Purpose....: Get name of current directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TFtp::GetCurrDirName()
{
    FAppSection.Enter();

    if (!FReady)
        FAppSignal.WaitTimeout(15000);

    FAppSection.Leave();

    if (FReady)
        return FCurrDirName;
    else
        return TString();
}

/*##########################################################################
#
#   Name       : TFtp::GotoFirstDir
#
#   Purpose....: Goto first directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::GotoFirstDir()
{
    FCurrDir = 0;
    
    if (!FDirCached)
        CacheDir();

    if (FDirCached)
        FCurrDir = FDirList;

    if (FCurrDir)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtp::GotoFirstFile
#
#   Purpose....: Goto first file entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::GotoFirstFile()
{
    FCurrFile = 0;
    
    if (!FDirCached)
        CacheDir();

    if (FDirCached)
        FCurrFile = FFileList;

    if (FCurrFile)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtp::GotoNextDir
#
#   Purpose....: Goto next directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::GotoNextDir()
{
    if (FCurrDir)
        FCurrDir = FCurrDir->next;

    if (FCurrDir)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtp::GotoNextFile
#
#   Purpose....: Goto next file entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::GotoNextFile()
{
    if (FCurrFile)
        FCurrFile = FCurrFile->next;

    if (FCurrFile)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtp::GetDir
#
#   Purpose....: Get info about current directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::GetDir(TString &name, TDateTime &time)
{
    if (FCurrDir)
    {
        name = FCurrDir->name;
        time = FCurrDir->time;
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtp::GetFile
#
#   Purpose....: Get info about current file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtp::GetFile(TString &name, TDateTime &time, int *size)
{
    if (FCurrFile)
    {
        name = FCurrFile->name;
        time = FCurrFile->time;

        while (time.GetMicroSec() != 0)
            time.AddMicro(1);
            
        *size = FCurrFile->size;
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtp::NotifyMsg
#
#   Purpose....: Notify new msg sent or received on socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::NotifyMsg(const char *msg)
{
    if (OnMsg)
        (*OnMsg)(this, msg);
}

/*##########################################################################
#
#   Name       : TFtp::SendUser
#
#   Purpose....: Send username
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendUser()
{
    NotifyMsg("USER\r\n");

    if (FSocket)
    {
        FSocket->Write("USER ");
        FSocket->Write(FUser.GetData());
        FSocket->Write("\r\n");
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendPassword
#
#   Purpose....: Send password
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendPassword()
{
    NotifyMsg("PASS\r\n");

    if (FSocket)
    {
        FSocket->Write("PASS ");
        FSocket->Write(FPassw.GetData());
        FSocket->Write("\r\n");
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendPwd
#
#   Purpose....: Send pwd
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendPwd()
{
    NotifyMsg("PWD\r\n");

    if (FSocket)
    {
        FSocket->Write("PWD\r\n");
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendCwd
#
#   Purpose....: Send cwd
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendCwd(const char *path)
{
    char str[260];

    strcpy(str, "CWD ");
    strcat(str, path);
    strcat(str, "\r\n");

//    NotifyMsg(str);

    if (FSocket)
    {
        FSocket->Write(str);
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::Sendmkd
#
#   Purpose....: Send mkd
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendMkd(const char *path)
{
    char str[260];

    strcpy(str, "MKD ");
    strcat(str, path);
    strcat(str, "\r\n");

    NotifyMsg(str);

    if (FSocket)
    {
        FSocket->Write(str);
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendList
#
#   Purpose....: Send list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendList()
{
    NotifyMsg("LIST\r\n");

    ClearEntries();

    if (FSocket)
    {
        FSocket->Write("LIST\r\n");
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendType
#
#   Purpose....: Send transfer type
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendType(char type)
{
    char str[10];

    strcpy(str, "TYPE ");
    str[5] = type;
    str[6] = 0;
    strcat(str,"\r\n");

//    NotifyMsg(str);

    if (FSocket)
    {
        FSocket->Write(str);
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendRetr
#
#   Purpose....: Send retr
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendRetr()
{
    char str[260];

    strcpy(str, "RETR ");
    strcat(str, FRemoteFile.GetData());
    strcat(str, "\r\n");

    NotifyMsg(str);

    if (FSocket)
    {
        FSocket->Write(str);
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendStor
#
#   Purpose....: Send stor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendStor()
{
    char str[260];

    strcpy(str, "STOR ");
    strcat(str, FRemoteFile.GetData());
    strcat(str, "\r\n");

    NotifyMsg(str);

    if (FSocket)
    {
        FSocket->Write(str);
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::SendPasv
#
#   Purpose....: Send pasv
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::SendPasv()
{
//    NotifyMsg("PASV\r\n");

    if (FSocket)
    {
        FSocket->Write("PASV\r\n");
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TFtp::DecodePwd
#
#   Purpose....: Decode current directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::DecodePwd(const char *param)
{
    const char *sptr;
    char dir[256];
    char *dptr;

    dir[0] = 0;

    sptr = param;

    while (*sptr && *sptr != 0x22)
        sptr++;

    if (*sptr)
    {
        sptr++;
        dptr = dir;

        while (*sptr && *sptr != 0x22)
        {
            *dptr = *sptr;
            dptr++;
            sptr++;
        }
        *dptr = 0;
    }

    FCurrDirName = TString(dir);
}

/*##########################################################################
#
#   Name       : TFtp::DecodePasv
#
#   Purpose....: Decode passive mode IP & port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::DecodePasv(const char *param)
{
    const char *sptr;
    char str[256];
    int arr[6];
    int i;
    char *dptr;
    long IP;
    int port;

    if (FDataSocket)
    {
        FDataSocket->Push();
        FDataSocket->Close();
        FCloseData = TRUE;

        NotifyMsg("Data socket closed\r\n");

        while (FDataSocket)
            RdosWaitMilli(50);
    }

    sptr = param;

    while (*sptr && *sptr != '(')
        sptr++;

    if (*sptr)
    {
        sptr++;

        for (i = 0; i < 6 && *sptr; i++)
        {
            dptr = str;
            while (*sptr && *sptr != ',' && *sptr != ')')
            {
                *dptr = *sptr;
                dptr++;
                sptr++;
            }
            *dptr = 0;
            arr[i] = atoi(str);

            if (*sptr)
                sptr++;
        }

        if (i == 6)
        {
            IP = (arr[3] << 24) | (arr[2] << 16) | (arr[1] << 8) | arr[0];
            port = (arr[4] << 8) | arr[5];

            FDataSocket = new TTcpSocket(IP, port, 15000, 0x4000);
            FDataSocket->WaitForConnection(15000);

            if (FDataSocket->IsOpen())
            {
                FDataSocket->Push();
                RdosCreateThread(DataSocketThread, "FTP data", this, STACK_SIZE);
                NotifyMsg("Data socket established\r\n");
            }
            else
            {
                NotifyMsg("Data socket failed\r\n");

                RdosWaitMilli(100);
                delete FDataSocket;
                FDataSocket = 0;
                FReady = TRUE;
                FAppSignal.Signal();
            }
        }        
    }
}

/*##########################################################################
#
#   Name       : TFtp::HandleResponse
#
#   Purpose....: Handle response code on control socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleResponse(int code, const char *param)
{
    switch (code)
    {
        case 125:
        case 150:
            if (FWriteFile && FWriteWait)
                FStorSent = TRUE;
            break;
        
        case 226:
            if (FWriteFile && FWriteWait)
            {
                FReady = TRUE;
                FSuccess = TRUE;
                FAppSignal.Signal();
            }                
            break;
            
        case 200:
            FReady = TRUE;
            break;
        
        case 220:
            SendUser();
            FReady = FALSE;    
            break;

        case 227:
            FReady = FALSE;    
            DecodePasv(param);

            if (FGetDir)
                SendList();

            if (FGetFile)
                SendRetr();

            if (FWriteFile)
            {
                FWriteWait = TRUE;
                SendStor();
            }
            break;

        case 230:
            FReady = FALSE;    
            SendPwd();
            break;

        case 250:
            FReady = FALSE;    
            if (FSetDir)
            {
                FSuccess = TRUE;
                SendPwd();
            }
            break;

        case 257:
            if (FMkDir)
                FSuccess = TRUE;
                
            DecodePwd(param);
            FReady = TRUE;
            FAppSignal.Signal();
            break;

        case 331:
            FReady = FALSE;    
            SendPassword();
            break;

        case 421:
            FAborted = TRUE;
            FSuccess = FALSE;
            FReady = FALSE;

            if (FDataSocket)
                FDataSocket->Close();

            if (FSocket)
                FSocket->Close();

            break;

        case 425:
            FAborted = TRUE;
            FSuccess = FALSE;
            FReady = TRUE;
            FAppSignal.Signal();
            break;

        case 426:
            FAborted = TRUE;
            FSuccess = FALSE;
            FReady = TRUE;

            if (FDataSocket)
                FDataSocket->Close();

            FAppSignal.Signal();
            break;

        case 550:
            if (FSetDir)
            {
                FSuccess = FALSE;
                FReady = TRUE;
                FAppSignal.Signal();
            }
            else
                FReady = FALSE;            
            break;

        default:
            FReady = FALSE;
            break;
    }
}

/*##########################################################################
#
#   Name       : TFtp::HandleResponse
#
#   Purpose....: Handle response on default socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleResponse(const char *msg)
{
    char codestr[4];
    int code;
    const char *ptr;

    NotifyMsg(msg);

    ptr = msg;

    while (ptr && strlen(ptr) >= 3)
    {
        memcpy(codestr, ptr, 3);
        codestr[3] = 0;
        code = atoi(codestr);

        if (code != FLastCode)
        {
            HandleResponse(code, ptr + 3);
            FLastCode = code;
        }

        ptr = strchr(ptr, 0xd);
        while (ptr && (*ptr == 0xd || *ptr == 0xa))
            ptr++;
    }
}

/*##########################################################################
#
#   Name       : TFtp::HandleOpen
#
#   Purpose....: Handle open socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleOpen()
{
    int count;
    char str[1025];

    if (FSocket)
        FSocket->Push();

    if (FSocket)
    {    
        if (FSocket->WaitForData(10 * 60000))
        {
            count = FSocket->Read(str, 1024);
            str[count] = 0;
            HandleResponse(str);
        }
        else
            FSocket->Close();
    }
}

/*##########################################################################
#
#   Name       : TFtp::HandleClosed
#
#   Purpose....: Handle closed socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleClosed()
{
    FGetDir = FALSE;
    FSetDir = FALSE;
    FMkDir = FALSE;
    FReady = FALSE;
    
    ClearEntries();

    RdosWaitMilli(100);

    if (FSocket)
        delete FSocket;

    if (FDataSocket)
        FDataSocket->Close();

    NotifyMsg("Connecting\r\n");

    FSocket = new TTcpSocket(FIp, FPort, 15000, 0x1000);
    FSocket->WaitForConnection(15000);
}

/*##########################################################################
#
#   Name       : TFtp::ClearEntries
#
#   Purpose....: Clear all entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::ClearEntries()
{   
    TFtpDirEntry *dir;
    TFtpFileEntry *file;

    FSection.Enter();

    FCurrDir = 0;
    FCurrFile = 0;
    FDirCached = FALSE;

    RdosWaitMilli(25);

    while (FDirList)
    {
        dir = FDirList->next;
        delete FDirList;
        FDirList = dir;
    }

    while (FFileList)
    {
        file = FFileList->next;
        delete FFileList;
        FFileList = file;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::AddDir
#
#   Purpose....: Add decoded dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::AddDir(TFtpDirEntry *entry)
{   
    FSection.Enter();

    entry->next = FDirList;
    FDirList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::AddFile
#
#   Purpose....: Add decoded file entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::AddFile(TFtpFileEntry *entry)
{   
    FSection.Enter();

    entry->next = FFileList;
    FFileList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::HandleDirEntry
#
#   Purpose....: Handle single directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleDirEntry(char *data)
{   
    int i;
    char dir;
    char attrib[10];
    char *ptr;
    int size;
    TDateTime time;
    int year, month, day;
    int hour, min;

    if (strlen(data) > 10)
    {
        dir = *data;
        data++;
        memcpy(attrib, data, 9);
        attrib[9] = 0;
        data += 9;
    }
    else
        return;

    if (*data)
    {
        for (i = 0; i < 3; i++)
        {
            while (*data && *data == ' ')
                data++;

            while (*data && *data != ' ')
                data++;
        }

        while (*data && *data == ' ')
            data++;

        ptr = data;
        
        while (*data && *data != ' ')
            data++;

        if (*data)
        {
            *data = 0;
            size = atoi(ptr);
            data++;
        }
        else
            size = 0;
        
    }

    if (strlen(data) > 3)
    {
        data[3] = 0;

        year = time.GetYear();
        month = 0;

        if (!strcmp(data, "Jan"))
            month = 1;

        if (!strcmp(data, "Feb"))
            month = 2;

        if (!strcmp(data, "Mar"))
            month = 3;

        if (!strcmp(data, "Apr"))
            month = 4;

        if (!strcmp(data, "May"))
            month = 5;

        if (!strcmp(data, "Jun"))
            month = 6;

        if (!strcmp(data, "Jul"))
            month = 7;

        if (!strcmp(data, "Aug"))
            month = 8;

        if (!strcmp(data, "Sep"))
            month = 9;

        if (!strcmp(data, "Oct"))
            month = 10;

        if (!strcmp(data, "Nov"))
            month = 11;

        if (!strcmp(data, "Dec"))
            month = 12;

        data += 4;

        if (!month)
            return;
    }

    if (*data)
    {
        while (*data && *data == ' ')
            data++;

        ptr = data;
        
        while (*data && *data != ' ')
            data++;

        if (*data)
        {
            *data = 0;
            day = atoi(ptr);
            data++;
        }
        else
            day = 0;
    }

    hour = 0;
    min = 0;

    if (*data)
    {
        while (*data && *data == ' ')
            data++;

        ptr = data;
        
        while (*data && *data != ':' && *data != ' ')
            data++;

        if (*data == ':')
        {
            *data = 0;
            hour = atoi(ptr);
            data++;
    
            if (*data)
            {
                while (*data && *data == ' ')
                    data++;

                ptr = data;
        
                while (*data && *data != ' ')
                    data++;

                if (*data)
                {
                    *data = 0;
                    min = atoi(ptr);
                    data++;
                }
                else
                    min = 0;
            }
        }
        else
        {
            *data = 0;
            year = atoi(ptr);
            data++;
        }

        if (dir == 'd' || dir == 'D')
            AddDir(new TFtpDirEntry(year, month, day, hour, min, data));
        else
            AddFile(new TFtpFileEntry(year, month, day, hour, min, data, size));

    }
}

/*##########################################################################
#
#   Name       : TFtp::HandleDirData
#
#   Purpose....: Handle directory data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleDirData(char *data, int size)
{   
    char *curr;
    char *ptr;
    int count;

    curr = data;
    ptr = data;
    count = 0;

    while (size)
    {
        if (*ptr == 0xd || *ptr == 0xa)
        {
            *ptr = 0;
            ptr++;
            size--;
            
            HandleDirEntry(curr);

            while (size && (*ptr == 0xd || *ptr == 0xa))
            {
                size--;
                ptr++;
            }

            curr = ptr;
            count = 0;
        }
        else
        {
            count++;
            size--;
            ptr++;
        }
    }

    if (FDirData)
    {
        delete FDirData;
        FDirData = 0;
    }

    if (count)
    {
        FDirData = new char[count];
        memcpy(FDirData, curr, count);
        FDirCount = count;
    }    
    else
        FDirCount = 0;
}

/*##########################################################################
#
#   Name       : TFtp::HandleDataSocket
#
#   Purpose....: Handle data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleDataSocket()
{
    char buf[512];
    int count;
    int tries = 0;

    FDirData = 0;
    FDirCount = 0;

    if (FWriteFile)
    {
        while (FWriteFile && !FStorSent && tries < 1000)
        {
            RdosWaitMilli(150);
            tries++;
        }

        if (FWriteFile && FStorSent)
        {            
            FFile->SetPos(0);
            count = FFile->Read(buf, 512);

            while (count && FDataSocket)
            {
                FDataSocket->Write(buf, count);
                count = FFile->Read(buf, 512);
            }

            if (FDataSocket)
            {
                FDataSocket->Push();
                FDataSocket->Close();
            }
        }
    }
    else
    {    
        while (FInstalled && FDataSocket && FDataSocket->IsOpen() && !FCloseData && !FAborted)
        {
            if (FDirData)
            {
                memcpy(buf, FDirData, FDirCount);
                delete FDirData;
                FDirData = 0;            

                count = FDataSocket->Read(buf + FDirCount, 512 - FDirCount);
            }
            else            
                count = FDataSocket->Read(buf, 512);

            if (count)
            {
                if (FGetDir)
                    HandleDirData(buf, count + FDirCount);

                if (FGetFile && FFile)
                    FFile->Write(buf, count);
            }
        }
    }

    FCloseData = FALSE;

    if (FDirData)
        delete FDirData;
    FDirData = 0;

    if (FDataSocket)
    {
        RdosWaitMilli(100);
        delete FDataSocket;
        FDataSocket = 0;
    }

    if (!FAborted)
    {
        FReady = TRUE;
            
        if (FGetDir)
            FDirCached = TRUE;

        if (FGetFile)
            FSuccess = TRUE;

        if (!FWriteFile)
            FAppSignal.Signal();
    }
}

/*##########################################################################
#
#   Name       : TFtp::Execute
#
#   Purpose....: FTP thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::Execute()
{
    RdosWaitMilli(25);

    while (FInstalled)
    {
        if (FEnabled)
        {
            if (FSocket && FSocket->IsOpen())
                HandleOpen();
            else
                HandleClosed();
        }
        else
        {
            if (FSocket && FSocket->IsOpen())
            {
                FSocket->Push();
                FSocket->Close();

                RdosWaitMilli(100);
                delete FSocket;
                FSocket = 0;
            }
            else
                RdosWaitMilli(100);
        }
    }
}
