/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# wdserv.cpp
# WD socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdserv.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdSocketServer::TWdSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSocketServer::TWdSocketServer(const char *Name, int StackSize, TSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::~TWdSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSocketServer::~TWdSocketServer()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetByte
#
#   Purpose....: Read byte from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TWdSocketServer::GetByte()
{
    char ch = *FInPtr;
    FInPtr++;
    return ch;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetWord
#
#   Purpose....: Read word from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
short int TWdSocketServer::GetWord()
{
    short int val = *(short int *)FInPtr;
    FInPtr += 2;
    return val;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetDword
#
#   Purpose....: Read dword from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long TWdSocketServer::GetDword()
{
    long val = *(long *)FInPtr;
    FInPtr += 4;
    return val;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::GetString
#
#   Purpose....: Read string from input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::GetString(char *str, int maxsize)
{
    int len = FInPtr - FInBuf;

    len = FInSize - len;

    if (len >= maxsize)
        len = maxsize - 1;
    
    if (len > 0)
    {
        memcpy(str, FInPtr, len);
        FInPtr += len;
        str[len] = 0;
    }
    else
        str[0] = 0;        
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutByte
#
#   Purpose....: Write byte to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutByte(char val)
{
    *FOutPtr = val;
    FOutPtr++;
    FOutSize++;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutWord
#
#   Purpose....: Write word to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutWord(short int val)
{
    *(short int *)FOutPtr = val;
    FOutPtr += 2;
    FOutSize += 2;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutDword
#
#   Purpose....: Write dword to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutDword(long val)
{
    *(long *)FOutPtr = val;
    FOutPtr += 4;
    FOutSize += 4;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::PutString
#
#   Purpose....: Write string to output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::PutString(const char *str)
{
    int len = strlen(str);

    memcpy(FOutPtr, str, len + 1);
    FOutPtr += len + 1;
    FOutSize += len + 1;
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqError
#
#   Purpose....: Req error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqError()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqConnect
#
#   Purpose....: Req connect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqConnect()
{
    char ch;

    ch = GetByte();

    if (ch == 17)
    {
        PutWord(MAX_MSG_SIZE);
        PutByte(0);
    }
    else   
    {
        PutWord(0);
        PutString("Illegal version");
    }
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqDisconnect
#
#   Purpose....: Req disconnect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqDisconnect()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSuspend
#
#   Purpose....: Req suspend
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSuspend()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqResume
#
#   Purpose....: Req resume
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqResume()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetSupplService
#
#   Purpose....: Req get suppl service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetSupplService()
{
    char name[256];

    GetString(name, 255);
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqPerformSupplService
#
#   Purpose....: Req perform suppl service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqPerformSupplService()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetSysConfig
#
#   Purpose....: Req sys config
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetSysConfig()
{
    int major, minor, release;

    RdosGetVersion(&major, &minor, &release);
    
    PutByte(3);
    PutByte(3);
    PutByte((char)major);
    PutByte((char)minor);
    PutByte(0); 
    PutByte(0); 
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqMapAddr
#
#   Purpose....: Req map address
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqMapAddr()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqAddrInfo
#
#   Purpose....: Req address info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqAddrInfo()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqChecksumMem
#
#   Purpose....: Req checksum memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqChecksumMem()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadMem
#
#   Purpose....: Req read memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadMem()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteMem
#
#   Purpose....: Req write memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteMem()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadIo
#
#   Purpose....: Req read IO
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadIo()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteIo
#
#   Purpose....: Req write IO
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteIo()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadCpu
#
#   Purpose....: Req read CPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadCpu()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadFpu
#
#   Purpose....: Req read FPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadFpu()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteCpu
#
#   Purpose....: Req write CPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteCpu()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqWriteFpu
#
#   Purpose....: Req write FPU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqWriteFpu()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgGo
#
#   Purpose....: Req run program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgGo()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgStep
#
#   Purpose....: Req step program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgStep()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgLoad
#
#   Purpose....: Req load program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgLoad()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqProgKill
#
#   Purpose....: Req kill program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqProgKill()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetWatch
#
#   Purpose....: Req set watch
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetWatch()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqClearWatch
#
#   Purpose....: Req clear watch
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqClearWatch()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetBreak
#
#   Purpose....: Req set breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetBreak()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqClearBreak
#
#   Purpose....: Req clear breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqClearBreak()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetNextAlias
#
#   Purpose....: Req get next alias
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetNextAlias()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetUserScreen
#
#   Purpose....: Req set user screen
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetUserScreen()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSetDebugScreen
#
#   Purpose....: Req set debug screen
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSetDebugScreen()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqReadUserKeyboard
#
#   Purpose....: Req read user keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqReadUserKeyboard()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetLibName
#
#   Purpose....: Req get library name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetLibName()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetErrText
#
#   Purpose....: Req get error text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetErrText()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqGetMsgText
#
#   Purpose....: Req get msg text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqGetMsgText()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqRedirStdin
#
#   Purpose....: Req redirect stdin
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqRedirStdin()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqRedirStdout
#
#   Purpose....: Req redirect stdout
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqRedirStdout()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::ReqSplitCmd
#
#   Purpose....: Req split command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::ReqSplitCmd()
{
}

/*##########################################################################
#
#   Name       : TWdSocketServer::NotifyMsg
#
#   Purpose....: Notify message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {
        case 0:
            ReqConnect();
            break;

        case 1:
            ReqDisconnect();
            break;

        case 2:
            ReqSuspend();
            break;

        case 3:
            ReqResume();
            break;

        case 4:
            ReqGetSupplService();
            break;

        case 5:
            ReqPerformSupplService();
            break;

        case 6:
            ReqGetSysConfig();
            break;

        case 7:
            ReqMapAddr();
            break;

        case 8:
            ReqAddrInfo();
            break;

        case 9:
            ReqChecksumMem();
            break;

        case 10:
            ReqReadMem();
            break;

        case 11:
            ReqWriteMem();
            break;

        case 12:
            ReqReadIo();
            break;

        case 13:
            ReqWriteIo();
            break;

        case 14:
            ReqReadCpu();
            break;

        case 15:
            ReqReadFpu();
            break;

        case 16:
            ReqWriteCpu();
            break;

        case 17:
            ReqWriteFpu();
            break;

        case 18:
            ReqProgGo();
            break;

        case 19:
            ReqProgStep();
            break;

        case 20:
            ReqProgLoad();
            break;

        case 21:
            ReqProgKill();
            break;

        case 22:
            ReqSetWatch();
            break;

        case 23:
            ReqClearWatch();
            break;

        case 24:
            ReqSetBreak();
            break;

        case 25:
            ReqClearBreak();
            break;

        case 26:
            ReqGetNextAlias();
            break;

        case 27:
            ReqSetUserScreen();
            break;

        case 28:
            ReqSetDebugScreen();
            break;

        case 29:
            ReqReadUserKeyboard();
            break;

        case 30:
            ReqGetLibName();
            break;

        case 31:
            ReqGetErrText();
            break;

        case 32:
            ReqGetMsgText();
            break;

        case 33:
            ReqRedirStdin();
            break;

        case 34:
            ReqRedirStdout();
            break;

        case 35:
            ReqSplitCmd();
            break;

        default:
            ReqError();
            break;
    }    
}

/*##########################################################################
#
#   Name       : TWdSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServer::HandleSocket()
{
    int count;
    
	while (FSocket->IsOpen())
	{
	    FInSize = 0;
		if (FSocket->Read((char *)&FInSize, 2) == 2)
	    {
            count = FSocket->Read(FInBuf, FInSize);

            if (count == FInSize)
            {
                FInPtr = FInBuf;
                FOutPtr = FOutBuf;
                FOutSize = 0;

                NotifyMsg();

                FSocket->Write((char *)&FOutSize, 2);
                FSocket->Write(FOutBuf, FOutSize);
                FSocket->Push();
            }
		}
	}
}
