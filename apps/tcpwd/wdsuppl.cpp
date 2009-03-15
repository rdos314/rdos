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
