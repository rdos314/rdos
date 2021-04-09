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
# discserv.cpp
# Disc server class
#
########################################################################*/

#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "discserv.h"

static int handle = 0;

/*##########################################################################
#
#   Name       : TDiscReqEntry::TDisReqEntry
#
#   Purpose....: Disc req entry contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReqEntry::TDiscReqEntry(long long StartSector, int SectorCount)
{
    FStartSector = StartSector;
    FSectorCount = SectorCount;
    FData = 0;
}

/*##########################################################################
#
#   Name       : TDiscReqEntry::~TDiscReqEntry
#
#   Purpose....: Disc req entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReqEntry::~TDiscReqEntry()
{
}

/*##########################################################################
#
#   Name       : TDiscReq::TDisReq
#
#   Purpose....: Disc req contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReq::TDiscReq(TDiscServer *server)
{
    int i;

    FServer = server;
    FReq = ServCreateVfsReq(handle);
    FServer->Add(FReq & 0xFF, this);

    for (i = 0; i < MAX_DISC_REQ_ENTRIES; i++)
        FEntryArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TDiscReq::~TDiscReq
#
#   Purpose....: Disc req destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscReq::~TDiscReq()
{
    int i;

    FServer->Remove(FReq & 0xFF);

    for (i = 0; i < MAX_DISC_REQ_ENTRIES; i++)
        if (FEntryArr[i])
            delete FEntryArr[i];

    ServCloseVfsReq(FReq);
}

/*##########################################################################
#
#   Name       : TDiscReq::Add
#
#   Purpose....: Add request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReq::Add(long long StartSector, int SectorCount)
{
    int id = ServReqVfsSectors(FReq, StartSector, SectorCount);

    if (id > 0 && id <= MAX_DISC_REQ_ENTRIES)
    {
        FEntryArr[id - 1] = new TDiscReqEntry(StartSector, SectorCount);
        return id;
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TDiscReq::Start
#
#   Purpose....: Start request
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscReq::Start()
{
    ServStartVfsReq(FReq);
}

/*##########################################################################
#
#   Name       : TDiscServer::TDiscServer
#
#   Purpose....: Disc server contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscServer::TDiscServer(int dev, int unit)
{
    char str[40];
    int i;

    if (!handle)
        handle = ServGetVfsHandle();

    for (i = 0; i < MAX_DISC_REQ_COUNT; i++)
        FReqArr[i] = 0;

    sprintf(str, "Disc Serv %02hX.%02hX", dev, unit);
    Start(str, 4, 0x4000);    
}

/*##########################################################################
#
#   Name       : TDiscServer::~TDiscServer
#
#   Purpose....: Disc server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscServer::~TDiscServer()
{
}

/*##########################################################################
#
#   Name       : TDiscServer::Add
#
#   Purpose....: Add disc req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::Add(int id, TDiscReq *req)
{
    if (id > 0 && id <= MAX_DISC_REQ_COUNT)
        FReqArr[id - 1] = req;
}

/*##########################################################################
#
#   Name       : TDiscServer::Remove
#
#   Purpose....: Remove disc req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::Remove(int id)
{
    if (id > 0 && id <= MAX_DISC_REQ_COUNT)
        FReqArr[id - 1] = 0;
}

/*##########################################################################
#
#   Name       : TDiscServer::GetPartSectors
#
#   Purpose....: Get partition sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDiscServer::GetPartSectors()
{
    return ServGetVfsSectors(handle);
}

/*##########################################################################
#
#   Name       : TDiscServer::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDiscServer::Execute()
{
    while (FInstalled)
    {
        RdosWaitMilli(250);
    }
}
