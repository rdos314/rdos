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
# ftp.cpp
# FTP class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "ftp.h"

#include "rdos.h"

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
    FPassw(passw)
{
    FIp = IP;
    FPort = port;
    FSocket = 0;
    FDataSocket = 0;
    OnMsg = 0;
    FLastCode = -1;
    FEntryList = 0;
    
    FCloseData = FALSE;
    FGetDir = FALSE;
    
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
        FCloseData = TRUE;
        FDataSocket->Push();
        FDataSocket->Close();

        while (FDataSocket)
            RdosWaitMilli(50);
    }

    ClearEntries();
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

    FSocket->Write("USER ");
    FSocket->Write(FUser.GetData());
    FSocket->Write("\r\n");
    FSocket->Push();
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

    FSocket->Write("PASS ");
    FSocket->Write(FPassw.GetData());
    FSocket->Write("\r\n");
    FSocket->Push();
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

    FSocket->Write("PWD\r\n");
    FSocket->Push();
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

    FSocket->Write("LIST\r\n");
    FSocket->Push();
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
    NotifyMsg("PASV\r\n");

    FSocket->Write("PASV\r\n");
    FSocket->Push();
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

    FCurrDir = TString(dir);
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
        FCloseData = TRUE;
        FDataSocket->Push();
        FDataSocket->Close();

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

            FDataSocket = new TSocket(IP, port, 6000, 0x4000);
            FDataSocket->WaitForConnection(6000);

            if (FDataSocket->IsOpen())
            {
                FDataSocket->Push();
                RdosCreateThread(DataSocketThread, "FTP data", this, STACK_SIZE);
                NotifyMsg("Data socket established\r\n");
            }
            else
                NotifyMsg("Data socket failed\r\n");
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
        case 220:
            SendUser();
            break;

        case 227:
            DecodePasv(param);

            if (FGetDir)
                SendList();
            break;

        case 230:
            SendPwd();
            break;

        case 257:
            DecodePwd(param);
            SendPasv();
            FGetDir = TRUE;
            break;

        case 331:
            SendPassword();
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
    
    count = FSocket->Read(str, 1024);
    str[count] = 0;
    HandleResponse(str);
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
    if (FSocket)
        delete FSocket;

    if (FDataSocket)
        FDataSocket->Close();

    NotifyMsg("Connecting\r\n");

    FSocket = new TSocket(FIp, FPort, 6000, 0x1000);
    FSocket->WaitForConnection(6000);
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
    TFtpEntry *entry;

    FSection.Enter();

    while (FEntryList)
    {
        entry = FEntryList->next;
        delete FEntryList;
        FEntryList = entry;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFtp::AddEntry
#
#   Purpose....: Add decoded entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::AddEntry(TFtpEntry *entry)
{   
    FSection.Enter();

    entry->next = FEntryList;
    FEntryList = entry;

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
    TFtpEntry *entry;

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
            entry = new TFtpDirEntry(year, month, day, hour, min, data);
        else
            entry = new TFtpFileEntry(year, month, day, hour, min, data, size);

        AddEntry(entry);
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
    char row[257];
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
            
            if (FDirData)
                strcpy(row, FDirData);
            else
                row[0] = 0;
            strcat(row, curr);
            HandleDirEntry(row);

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
    }    
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

    FDirData = 0;
    
    while (FInstalled && FDataSocket && FDataSocket->IsOpen() && !FCloseData)
    {
        count = FDataSocket->Read(buf, 512);
        if (count)
        {
            if (FGetDir)
                HandleDirData(buf, count);
        }
    }

    FCloseData = FALSE;

    if (FDirData)
        delete FDirData;
    FDirData = 0;

    if (FDataSocket)
    {
        delete FDataSocket;
        FDataSocket = 0;
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
        if (FSocket && FSocket->IsOpen())
            HandleOpen();
        else
            HandleClosed();
    }
}
