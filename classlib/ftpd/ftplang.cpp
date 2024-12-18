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
# langstr.cpp
# Language string class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include "rdos.h"
#include "ftplang.h"

#define FALSE 0
#define TRUE !FALSE

#define DEFAULT_ID  502

int TFtpLangString::FHandle = 0;
int TFtpLangString::FIsLocalHandle = TRUE;

/*##########################################################################
#
#   Name       : TFtpLangString::TFtpLangString
#
#   Purpose....: Constructor for language string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpLangString::TFtpLangString()
{
     FID = DEFAULT_ID;
}

/*##########################################################################
#
#   Name       : TFtpLangString::TFtpLangString
#
#   Purpose....: Constructor for language string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpLangString::TFtpLangString(int ID)
{
    Load(ID);
}

/*##########################################################################
#
#   Name       : TFtpLangString::SetLanguage
#
#   Purpose....: Set new language
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpLangString::SetLanguage(const char *language)
{
    int Handle = RdosLoadDll(language);

     if (Handle)
     {
        if (FHandle && !FIsLocalHandle)
         {
             RdosFreeDll(FHandle);
            FHandle = 0;
         }
         FHandle = Handle;
        FIsLocalHandle = FALSE;
     }
}

/*##########################################################################
#
#   Name       : TFtpLangString::Load
#
#   Purpose....: Load language string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpLangString::Load(int ID)
{
    char str[257];
    int start;
    int count;
    int size;

    FID = ID;

    Release();

    start = 0;
    count = 0;

    if (FHandle == 0)
    {
        FIsLocalHandle = TRUE;
        FHandle = RdosGetModuleHandle();
    }

    if (FHandle)
    {
        size = RdosReadResource(FHandle, ID, str, 256);
        AllocBuffer(size + 1);

        size = RdosReadResource(FHandle, ID, FBuf, 256);
        *(FBuf+size) = 0;
    }
    else
    {
        sprintf(str, "Unknown msg ID %d", ID);
        size = strlen(str);
        AllocBuffer(size + 1);
        memcpy(FBuf, str, size);
        *(FBuf+size) = 0;

        FID = DEFAULT_ID;
    }
}

/*##########################################################################
#
#   Name       : TFtpLangString::printf
#
#   Purpose....: Load & printf on message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpLangString::printf(int ID, ...)
{
    va_list ap;
    TFtpLangString temp(ID);

    va_start(ap, ID);
    TString::prtf(temp.GetData(), ap);
    va_end(ap);
    FID = temp.FID;
}

/*##########################################################################
#
#   Name       : TFtpLangString::Write
#
#   Purpose....: Write message to socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpLangString::Write(TTcpSocket *Socket)
{
    char str[5];

    sprintf(str, "%03d ", FID);

    Socket->Write(str);
    Socket->Write(GetData());
    Socket->Push();
}

