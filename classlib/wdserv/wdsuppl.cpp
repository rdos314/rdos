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
# wdsuppl.cpp
# WD supplementary service base class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdsuppl.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdSupplFactory::TWdSupplFactory
#
#   Purpose....: Supplementary service factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplFactory::TWdSupplFactory(TWdSocketServerFactory *Factory, const char *Name)
{
    int len = strlen(Name);
    
    FName = new char[len + 1];
    strcpy(FName, Name);
    
    Factory->AddSuppl(this);
}

/*##########################################################################
#
#   Name       : TWdSupplFactory::~TWdSupplFactory
#
#   Purpose....: Supplementary service factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplFactory::~TWdSupplFactory()
{
    if (FName)
        delete FName;
}

/*##########################################################################
#
#   Name       : TWdSupplService::TWdSupplService
#
#   Purpose....: Supplementary service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService::TWdSupplService(TWdSocketServer *Server)
{
    FServer = Server;    
    Server->AddSuppl(this);
}

/*##########################################################################
#
#   Name       : TWdSupplService::~TWdSupplService
#
#   Purpose....: Supplementary service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService::~TWdSupplService()
{
}

/*##########################################################################
#
#   Name       : TWdSupplService::GetByte
#
#   Purpose....: Get byte
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TWdSupplService::GetByte()
{
    return FServer->GetByte();
}

/*##########################################################################
#
#   Name       : TWdSupplService::GetWord
#
#   Purpose....: Get word
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
short int TWdSupplService::GetWord()
{
    return FServer->GetWord();
}

/*##########################################################################
#
#   Name       : TWdSupplService::GetDword
#
#   Purpose....: Get dword
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long TWdSupplService::GetDword()
{
    return FServer->GetDword();
}

/*##########################################################################
#
#   Name       : TWdSupplService::GetString
#
#   Purpose....: Get string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::GetString(char *str, int maxsize)
{
    FServer->GetString(str, maxsize);
}

/*##########################################################################
#
#   Name       : TWdSupplService::PutByte
#
#   Purpose....: Put byte
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::PutByte(char val)
{
    FServer->PutByte(val);
}

/*##########################################################################
#
#   Name       : TWdSupplService::PutWord
#
#   Purpose....: Put word
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::PutWord(short int val)
{
    FServer->PutWord(val);
}

/*##########################################################################
#
#   Name       : TWdSupplService::PutDword
#
#   Purpose....: Put dword
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::PutDword(long val)
{
    FServer->PutDword(val);
}

/*##########################################################################
#
#   Name       : TWdSupplService::PutString
#
#   Purpose....: Put string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::PutString(const char *str)
{
    FServer->PutString(str);
}

/*##########################################################################
#
#   Name       : TWdSupplService::PutData
#
#   Purpose....: Put data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::PutData(void *ptr, int size)
{
    FServer->PutData(ptr, size);
}

/*##########################################################################
#
#   Name       : TWdSupplService::LogMsg
#
#   Purpose....: Log message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::LogMsg(const char *msg)
{
    FServer->LogMsg(msg);
}        

/*##########################################################################
#
#   Name       : TWdSupplService::DebugLog
#
#   Purpose....: Log debug message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::DebugLog(const char *msg)
{
    FServer->DebugLog(msg);
}        

/*##########################################################################
#
#   Name       : TWdSupplService::GetDebug
#
#   Purpose....: Get debug object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDebug *TWdSupplService::GetDebug()
{
    return FServer->GetDebug();
}

/*##########################################################################
#
#   Name       : TWdSupplService::SetCurrentThread
#
#   Purpose....: Set current thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSupplService::SetCurrentThread(TDebugThread *thread)
{
    FServer->FCurrentThread = thread;
}

/*##########################################################################
#
#   Name       : TWdSupplService::GetFullPathName
#
#   Purpose....: Get full pathname for file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TWdSupplService::GetFullPathName(char *name, const char *ext)
{
    return FServer->GetFullPathName(name, ext);
}
