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
# wdcap.cpp
# WD capabilities supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdcap.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdCapFactory::TWdCapFactory
#
#   Purpose....: Supplementary capabilities factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapFactory::TWdCapFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "Capabilities")
{
}

/*##########################################################################
#
#   Name       : TWdCapFactory::~TWdCapFactory
#
#   Purpose....: Supplementary capabilities factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapFactory::~TWdCapFactory()
{
}

/*##########################################################################
#
#   Name       : TWdCapFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdCapFactory::Create(TWdSocketServer *server)
{
    return new TWdCapService(server);
}

/*##########################################################################
#
#   Name       : TWdCapService::TWdCapService
#
#   Purpose....: Supplementary capabilities service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapService::TWdCapService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdCapService::~TWdCapService
#
#   Purpose....: Supplementary capabilities service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapService::~TWdCapService()
{
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqGetBp
#
#   Purpose....: Get 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqGetBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqSetBp
#
#   Purpose....: Set 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqSetBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqExactBp
#
#   Purpose....: Get exact 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqExactBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqSetExactBp
#
#   Purpose....: Set exact 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqSetExactBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::NotifyMsg()
{
    char ch;

    DebugLog("WdCap");

    ch = GetByte();

    switch (ch)
    {
        case 0:
            ReqGetBp();
            break;

        case 1:
            ReqSetBp();
            break;

        case 2:
            ReqExactBp();
            break;

        case 3:
            ReqSetExactBp();
            break;
    }

}
