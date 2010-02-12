/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# ftp.cpp
# FTP class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "ftp.h"

#include "rdos.h"

#define STACK_SIZE  0x4000

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TFtp::TFtp
#
#   Purpose....: Constructor for FTP protocol
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtp::TFtp(long IP, int port, const char *user, const char *passw)
  : FUser(user),
    FPassw(passw)
{
    FIp = IP;
    FPort = port;
    FSocket = 0;

    Start("FTP", STACK_SIZE);
}

/*##########################################################################
#
#   Name       : TFtp::~TFtp
#
#   Purpose....: Destructor for FTP protocol
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtp::~TFtp()
{
    if (FSocket)
    {
        FSocket->Push();
        FSocket->Close();
        delete FSocket;
    }
}

/*##########################################################################
#
#   Name       : TFtp::HandleResponse
#
#   Purpose....: Handle response on default socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleResponse(const char *msg)
{
}

/*##########################################################################
#
#   Name       : TFtp::HandleOpen
#
#   Purpose....: Handle open socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleOpen()
{
    int count;
    char str[1025];
    
    count = FSocket->Read(str, 1024);
    str[count] = 0;
    HandleResponse(str);
}

/*##########################################################################
#
#   Name       : TFtp::HandleClosed
#
#   Purpose....: Handle closed socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::HandleClosed()
{
    if (FSocket)
        delete FSocket;

    FSocket = new TSocket(FIp, FPort, 6000, 0x1000);
    FSocket->WaitForConnection(6000);
}

/*##########################################################################
#
#   Name       : TFtp::Execute
#
#   Purpose....: FTP thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtp::Execute()
{
    while (FInstalled)
    {
        if (FSocket && FSocket->IsOpen())
            HandleOpen();
        else
            HandleClosed();
    }
}
