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
#include "path.h"
#include "env.h"
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
    _asm int 3

    int handle;
    char fname[256];
    char mode = GetByte();

    GetString(fname, 255);

    handle = RdosOpenFile(fname, 0);

    if (handle)
    {
        PutDword(0);
        PutDword(handle);
    }
    else
    {
        PutDword(MSG_FILE_NOT_FOUND);
        PutDword(0);
    }        
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
    _asm int 3

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
    _asm int 3
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
    _asm int 3
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
#   Name       : TWdFileService::CheckFileExt
#
#   Purpose....: Check if path is valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWdFileService::CheckFileExt(const char *path, const char *ext)
{
	TPathName FFullPath = TString(path);
	FFullPath += ext;

	if (FFullPath.IsFile())
	{
		PutDword(0);
		PutString(FFullPath.Get().GetData());
		return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TWdFileService::CheckFileExt
#
#   Purpose....: Check if path + name is a valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWdFileService::CheckFileExt(const char *path, const char *name, const char *ext)
{
	TPathName pn(path);
	pn += name;

	return CheckFileExt(pn.Get().GetData(), ext);
}

/*##########################################################################
#
#   Name       : TWdFileService::CheckPathFileExt
#
#   Purpose....: Find file through with path env var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWdFileService::CheckPathFileExt(char *path, const char *name, const char *ext)
{
	char *ptr;

	if (CheckFileExt(name, ext))
	    return TRUE;

	while (*path)
	{
		ptr = strchr(path, ';');
		if (ptr)
		{
			*ptr = 0;
			if (CheckFileExt(path, name, ext))
			    return TRUE;

			path = ptr + 1;
		}
		else
			return CheckFileExt(path, name, ext);
	}

	return FALSE;
}

/*##########################################################################
#
#   Name       : TWdFileService::CheckFile
#
#   Purpose....: Check if file is executable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWdFileService::CheckFile(char *name, const char *ext)
{
	char *path;
	TEnv *env;
	int ok;
	
	if (strchr(name, '\\'))
		if (CheckFileExt(name, ext))
		    return TRUE;

	if (strchr(name, '/'))
		if (CheckFileExt(name, ext))
			 return TRUE;

	if (strchr(name, ':'))
		if (CheckFileExt(name, ext))
			 return TRUE;

	path = new char[512];
	env = TEnv::OpenSysEnv();
	if (env->Find("PATH", path))
	{
	    ok = CheckPathFileExt(path, name, ext);
	    delete env;
		delete path;
		if (ok)
			return TRUE;
	 }
	 else
	 {
		  delete env;
		  delete path;
	 }

	 return CheckFileExt(name, ext);
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
    int ok;
    int handle;
    char FileType;
    char FileName[256];

    FileType = GetByte();
    GetString(FileName, 255);

    handle = RdosOpenFile(FileName, 0);
    if (handle)
    {
        PutDword(0);
        PutString(FileName);

        RdosCloseFile(handle);
    }
    else
    {
        if (FileType == 0)
        {
			ok = CheckFile(FileName, ".com");
				if (!ok)
					 ok = CheckFile(FileName, ".exe");

            if (!ok)                
                PutDword(MSG_FILE_NOT_FOUND);

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
            ReqGetConfig();
            break;

        case 1:
            ReqOpen();
            break;

        case 2:
            ReqSeek();
            break;

        case 3:
            ReqRead();
            break;

        case 4:
            ReqWrite();
            break;

        case 5:
            ReqWriteConsole();
            break;

        case 6:
            ReqClose();
            break;

        case 7:
            ReqErase();
            break;

        case 8:
            ReqStrToFullPath();
            break;

        case 9:
            ReqRun();
            break;

        default:
            ReqError();
            break;
    }
}
