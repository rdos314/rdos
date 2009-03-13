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

#define FALSE 0
#define TRUE !FALSE

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
 : TWdSupplService("Files")
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

    GetString(fname, 255);

    handle = RdosOpenFile(fname, 0);

    if (handle)
    {
        PutDword(0);
        PutDword(handle);
    }
    else
    {
        PutDword(1);
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
