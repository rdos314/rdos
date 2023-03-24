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
# fileio.cpp
# File IO class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <rdos.h>
#include <serv.h>
#include "fileio.h"
#include "serv.h"
#include "fs.h"

/*##########################################################################
#
#   Name       : ThreadStartup
#
#   Purpose....: Startup procedure for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ThreadStartup(void *ptr)
{
    ((TFileIo *)ptr)->Execute();
}

/*##########################################################################
#
#   Name       : TFileIo::TFileIo
#
#   Purpose....: File IO constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileIo::TFileIo()
{
    FHandle = 0;
    Fs = 0;
    FActive = false;
}

/*##########################################################################
#
#   Name       : TFileIo::~TFileIo
#
#   Purpose....: File IO destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileIo::~TFileIo()
{
}

/*##########################################################################
#
#   Name       : TFileIo::IsRunning
#
#   Purpose....: Check if running
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFileIo::IsRunning()
{
    return FActive;
}

/*##########################################################################
#
#   Name       : TFileIo::Start
#
#   Purpose....: Start IO handler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileIo::Start(TFs *fs)
{
    char ThreadName[40];
    int Disc;
    int Part;

    Fs = fs;
    FHandle = Fs->GetVfsHandle();
    Disc = ServGetVfsDisc(FHandle);
    Part = ServGetVfsPart(FHandle);

    sprintf(ThreadName, "File IO %02hX.%02hX", Disc, Part);
    RdosCreateThread(ThreadStartup, ThreadName, this, 0x2000);
}

/*##########################################################################
#
#   Name       : TFileIo::HandleRead
#
#   Purpose....: Handle read file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileIo::HandleRead(long long pos, int size)
{
}

/*##########################################################################
#
#   Name       : TFileIo::HandleFreeReq
#
#   Purpose....: Handle free req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileIo::HandleFreeReq(int req)
{
}

/*##########################################################################
#
#   Name       : TFileIo::HandleCompletedReq
#
#   Purpose....: Handle completed req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileIo::HandleCompletedReq(int req)
{
}

/*##########################################################################
#
#   Name       : TFileIo::HandleMapReq
#
#   Purpose....: Handle map req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileIo::HandleMapReq(int req)
{
}

/*##########################################################################
#
#   Name       : TFileIo::HandleQueue
#
#   Purpose....: Handle queue entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFileIo::HandleQueue(struct TFileIoEntry *entry)
{
    switch (entry->Op)
    {
        case REQ_READ:
            HandleRead(entry->Par64, entry->Par32);
            break;

        case REQ_COMPLETED:
            HandleCompletedReq(entry->Par32);
            break;

        case REQ_MAP:
            HandleMapReq(entry->Par32);
            break;

        case REQ_FREE:
            HandleFreeReq(entry->Par32);
            break;

        case REQ_CLOSE:
            return false;
    }

    return true;
}

/*##########################################################################
#
#   Name       : TFileIo::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileIo::Execute()
{
    int index = 0;
    struct TFileIoEntry *entry;

    FActive = true;

    for (;;)
        RdosWaitMilli(50);

/*
    for (;;)
    {
        if (Req->QueueArr[index].Op)
        {
            entry = &Req->QueueArr[index];
            if (HandleQueue(entry))
            {
                entry->Op = 0;
                index = (index + 1) % 256;
            }
            else
                break;
        }
        else
            ServWaitVfsFileQueue(FHandle);
    }
*/

    FActive = false;

}
