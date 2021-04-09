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
# discreq.cpp
# Disc req class
#
########################################################################*/

#include <rdos.h>
#include <serv.h>
#include "discreq.h"

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
TDiscReq::TDiscReq()
{
    int i;

    if (!handle)
        GetVfsHandle();

    FReq = ServCreateVfsReq(handle);

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

    for (i = 0; i < MAX_DISC_REQ_ENTRIES; i++)
        if (FEntryArr[i])
            delete FEntryArr[i];

    ServCloseVfsReq(FReq);
}

/*##########################################################################
#
#   Name       : TDiscReq::GetVfsHandle
#
#   Purpose....: Get VFS handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDiscReq::GetVfsHandle()
{
    if (handle == 0)
        handle = ServGetVfsHandle();

    return handle;
}

/*##########################################################################
#
#   Name       : TDiscReq::GetPartSectors
#
#   Purpose....: Get partition sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDiscReq::GetPartSectors()
{
    if (!handle)
        GetVfsHandle();
    
    return ServGetVfsSectors(handle);
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
