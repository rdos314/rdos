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
# mbrdisc.cpp
# MBR disc class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include <serv.h>
#include "mbrdisc.h"

/*##########################################################################
#
#   Name       : TMbrPartition::TMbrPartition
#
#   Purpose....: Mbr partition constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrPartition::TMbrPartition(const char *Data, unsigned int StartSector, unsigned int SectorCount)
  : TPartition((long long)StartSector, (long long)SectorCount)
{
    if (Data)
        memcpy(FPartData, Data, 16);
    else
        memset(FPartData, 0, 16);
}

/*##########################################################################
#
#   Name       : TMbrPartition::~TMbrPartition
#
#   Purpose....: Mbr partition destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrPartition::~TMbrPartition()
{
}

/*##########################################################################
#
#   Name       : TMbrPartition::IsTable
#
#   Purpose....: Check for table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMbrPartition::IsTable()
{
    return false;
}

/*##################  TMbrPartitionTable::TMbrPartitionTable  #############
*   Purpose....: Partition table constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TMbrPartitionTable::TMbrPartitionTable(const char *Data, unsigned int Start, unsigned int Size)
 : TMbrPartition(Data, Start, Size)
{
    int i;

    for (i = 0; i < 4; i++)
        PartArr[i] = 0;
}

/*##################  TMbrPartitionTable::~TMbrPartitionTable  #############
*   Purpose....: Partition table destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TMbrPartitionTable::~TMbrPartitionTable()
{
}

/*##################  TMbrPartitionTable::IsTable  #############
*   Purpose....: Check if entry is table                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
bool TMbrPartitionTable::IsTable()
{
    return true;
}

/*##################  TMbrPartitionTable::ProcessOne  #############
*   Purpose....: Process one entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TMbrPartitionTable::ProcessOne(TDiscServer *Server, int Entry, const char *Data)
{
    unsigned char Type;
    TMbrPartition *Part = 0;
    TMbrPartitionTable *TablePart = 0;
    unsigned int PStart;
    unsigned PSize;

    PStart = (unsigned int)FStartSector + *(unsigned int *)(Data + 8);
    PSize = *(unsigned int *)(Data + 0xC);

    Type = *(Data + 4);
    switch (Type)
    {
        case 0:
            break;

        case 5:
        case 0xF:
            TablePart = new TMbrPartitionTable(Data, PStart, PSize);
            Part = TablePart;
            break;

        default:
            Part = new TMbrPartition(Data, PStart, PSize);
            break;
    }

    if (TablePart)
        TablePart->Process(Server);

    PartArr[Entry] = Part;
}

/*##################  TMbrPartitionTable::Process  #############
*   Purpose....: Process partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TMbrPartitionTable::Process(TDiscServer *server)
{
    char *Buf;
    TDiscReq req(server);
    TDiscReqEntry e1(&req, FStartSector, 1);

    req.WaitForever();

    Buf = (char *)e1.Map();

    if (Buf[0x1FE] == 0x55 && Buf[0x1FF] == 0xAA)
    {
        ProcessOne(server, 0, &Buf[0x1BE]);
        ProcessOne(server, 1, &Buf[0x1CE]);
        ProcessOne(server, 2, &Buf[0x1DE]);
        ProcessOne(server, 3, &Buf[0x1EE]);
    }
}

/*##########################################################################
#
#   Name       : TMbrDisc::TMbrDisc
#
#   Purpose....: Mbr disc constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrDisc::TMbrDisc(TDiscServer *server)
  : TDisc(server),
    PartRoot(0, 0, 0)
{
}

/*##########################################################################
#
#   Name       : TMbrDisc::~TMbrDisc
#
#   Purpose....: Mbr disc destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMbrDisc::~TMbrDisc()
{
}

/*##########################################################################
#
#   Name       : TMbrDisc::LoadPart
#
#   Purpose....: Load partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::LoadPart()
{
    PartRoot.Process(FServer);
}

/*##########################################################################
#
#   Name       : TMbrDisc::Run
#
#   Purpose....: Run
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMbrDisc::Run()
{
    FServer->WaitForMsg(this);

}
