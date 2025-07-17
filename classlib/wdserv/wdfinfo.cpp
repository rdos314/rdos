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
# wdfinfo.cpp
# WD file info supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdfinfo.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdFileInfoFactory::TWdFileInfoFactory
#
#   Purpose....: Supplementary file info factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoFactory::TWdFileInfoFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "FileInfo")
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoFactory::~TWdFileInfoFactory
#
#   Purpose....: Supplementary file info factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoFactory::~TWdFileInfoFactory()
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdFileInfoFactory::Create(TWdSocketServer *server)
{
    return new TWdFileInfoService(server);
}

/*##########################################################################
#
#   Name       : TWdFileInfoService::TWdFileInfoService
#
#   Purpose....: Supplementary file info service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoService::TWdFileInfoService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoService::~TWdFileInfoService
#
#   Purpose....: Supplementary file info service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoService::~TWdFileInfoService()
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileInfoService::NotifyMsg()
{
    char ch;

    DebugLog("WdFileInfo");

    ch = GetByte();

    _asm int 3
}
