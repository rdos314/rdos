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
# ftplang.cpp
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

