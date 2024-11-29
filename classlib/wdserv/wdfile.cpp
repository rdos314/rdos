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
# wdfile.cpp
# WD file supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdfile.h"
#include "wdmsg.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdFileFactory::TWdFileFactory
#
#   Purpose....: Supplementary file factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileFactory::TWdFileFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "Files")
{
}

/*##########################################################################
#
#   Name       : TWdFileFactory::~TWdFileFactory
#
#   Purpose....: Supplementary file factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileFactory::~TWdFileFactory()
{
}

/*##########################################################################
#
#   Name       : TWdFileFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdFileFactory::Create(TWdSocketServer *server)
{
    return new TWdFileService(server);
}

/*##########################################################################
#
#   Name       : TWdFileService::TWdFileService
#
#   Purpose....: Supplementary file service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileService::TWdFileService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdFileService::~TWdFileService
#
#   Purpose....: Supplementary file service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileService::~TWdFileService()
{
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqGetConfig
#
#   Purpose....: Get config
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqGetConfig()
{
    PutByte('.');
    PutByte('\\');
    PutByte('/');
    PutByte(':');
    PutByte(0xd);
    PutByte(0xa);
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqOpen
#
#   Purpose....: Open file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqOpen()
{
    int handle;
    char fname[256];
    char mode = GetByte();
    TString str;

    GetString(fname, 255);

    handle = RdosOpenHandle(fname, O_RDWR);

    if (handle > 0)
    {
        str.printf("Open '%s', ID=%d", fname, handle);
        PutDword(0);
        PutDword(handle);
    }
    else
    {
        str.printf("Open '%s' failed", fname);
        PutDword(MSG_FILE_NOT_FOUND);
        PutDword(0);
    }        
    DebugLog(str.GetData());
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqSeek
#
#   Purpose....: Seek in file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqSeek()
{
    int handle = GetDword();
    char mode = GetByte();
    int pos = GetDword();

	switch (mode)
	{
		case 0:
			RdosSetHandlePos(handle, pos);
			PutDword(0);
			PutDword(pos);
			break;

		case 1:
			pos += (int)RdosGetHandlePos(handle);
			RdosSetHandlePos(handle, pos);
			PutDword(0);
			PutDword(pos);
			break;

		case 2:
			pos += (int)RdosGetHandleSize(handle);
			RdosSetHandlePos(handle, pos);
			PutDword(0);
			PutDword(pos);
			break;

		default:
			 PutDword(MSG_FILE_MODE_ERROR);
		    break;
	}
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqRead
#
#   Purpose....: Read from file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqRead()
{
    int handle = GetDword();
    int size = GetWord();
    int count;
    char *buf;

    if (size)
    {
        buf = new char[size];
        count = RdosReadHandle(handle, buf, size);
        PutDword(0);
        PutData(buf, count);
        delete buf;
    }
    else
        PutDword(0);
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqWrite
#
#   Purpose....: Write to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqWrite()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqWriteConsole
#
#   Purpose....: Write to console output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqWriteConsole()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqClose
#
#   Purpose....: Close file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqClose()
{
    int handle = GetDword();

    RdosCloseHandle(handle);

    PutDword(0);
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqErase
#
#   Purpose....: Erase file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqErase()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdFileService::GetServer
#
#   Purpose....: Get server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWdFileService::GetServer(char *name)
{
    char NameBuf[100];
    char ModBuf[100];
    int i;
    int j;
    int ID;
    int ModId;
    unsigned short int IdBuf[1];
    int ModuleCount;
    int ProgramCount = RdosGetProgramCount();

    for (i = 0; i < ProgramCount; i++)
    {
        if (RdosGetProgramInfo(i, &ID, NameBuf, 100))
        {
            ModuleCount = RdosGetProgramModules(i, IdBuf, 1);
            if (ModuleCount)
            {
                ModuleCount = RdosGetModuleCount();

                for (j = 0; j < ModuleCount; j++)
                {
                    if (RdosGetModuleInfo(j, &ModId, ModBuf, 100))
                    {
                        if (ModId == IdBuf[0])
                        {
                            if (!strcmp(name, ModBuf))
                            {
                                strcpy(name, NameBuf);
                                return TRUE;
                            }
                            break;
                        }
                    }
                }
            }
        }
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqStrToFullPath
#
#   Purpose....: Convert name to full path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqStrToFullPath()
{
    int handle;
    char FileType;
    char FileName[256];
    TString str;

    FileType = GetByte();
    GetString(FileName, 255);

    handle = RdosOpenHandle(FileName, O_RDWR);
    if (handle > 0)
    {
        PutDword(0);
        PutString(FileName);

        RdosCloseHandle(handle);
    }
    else
    {
        if (FileType == 0)
        {
            str = GetFullPathName(FileName, ".com");

            if (str.GetSize() == 0)
                str =  GetFullPathName(FileName, ".exe");

            if (str.GetSize())  
            {
                PutDword(0);
                PutString(str.GetData());
            }
            else                
            {
                if (GetServer(FileName))
                {
                    PutDword(0);
                    PutString(FileName);
                }
                else
                    PutDword(MSG_FILE_NOT_FOUND);
            }
        }
        else
            PutDword(MSG_FILE_NOT_FOUND);
    }                    
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqRun
#
#   Purpose....: Run file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqRun()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdFileService::ReqError
#
#   Purpose....: Default error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::ReqError()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdSupplService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileService::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {
        case 0:
            DebugLog("GetConfig");
            ReqGetConfig();
            break;

        case 1:
            ReqOpen();
            break;

        case 2:
            DebugLog("Seek");
            ReqSeek();
            break;

        case 3:
            DebugLog("Read");
            ReqRead();
            break;

        case 4:
            DebugLog("Write");
            ReqWrite();
            break;

        case 5:
            DebugLog("WriteConsole");
            ReqWriteConsole();
            break;

        case 6:
            DebugLog("Close");
            ReqClose();
            break;

        case 7:
            DebugLog("Delete");
            ReqErase();
            break;

        case 8:
            DebugLog("FullPath");
            ReqStrToFullPath();
            break;

        case 9:
            DebugLog("Run");
            ReqRun();
            break;

        default:
            char str[40];
            sprintf(str, "FileError: %02hX", ch);
            LogMsg(str);
            ReqError();
            break;
    }
}
