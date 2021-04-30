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
# fatlfn.cpp
# FAT LFN class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include "fatlfn.h"
#include "fatdir.h"

/*##########################################################################
#
#   Name       : TFatLfn::TFatLfn
#
#   Purpose....: Fat lfn constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatLfn::TFatLfn(struct TFatLfnEntry *entry)
{
    ChkSum = entry->ChkSum;
    Count = entry->Ord & 0x3F;
    Buf = new short int[13 * Count];

    AddData(entry);
}

/*##########################################################################
#
#   Name       : TFatLfn::~TFatLfn
#
#   Purpose....: Fat lfn destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatLfn::~TFatLfn()
{
    delete Buf;
}

/*##########################################################################
#
#   Name       : TFatLfn::AddData
#
#   Purpose....: Add data from LFN entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatLfn::AddData(struct TFatLfnEntry *entry)
{
    short int *ptr;
    int i;

    Count--;
    ptr = Buf + 13 * Count;

    for (i = 0; i < 5; i++)
        ptr[i] = entry->Name1[i];

    ptr += 5;

    for (i = 0; i < 6; i++)
        ptr[i] = entry->Name2[i];

    ptr += 6;

    for (i = 0; i < 2; i++)
        ptr[i] = entry->Name3[i];

}

/*##########################################################################
#
#   Name       : TFatLfn::Add
#
#   Purpose....: Add LFN part
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatLfn::Add(struct TFatLfnEntry *entry)
{
    if (entry->ChkSum == ChkSum)
    {
        if (entry->Ord == Count)
        {
            AddData(entry);
            return true;
        }
    }
    return false;
}

/*##########################################################################
#
#   Name       : TFatLfn::Verify
#
#   Purpose....: Verify again short entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatLfn::Verify(struct TFatDirEntry *entry)
{
    char sum;
    int i;
    char *ptr = entry->Base;

    sum = 0;

    for (i = 0; i < 11; i++)
        sum = ((sum & 1) ? 0x80 : 0) + (sum >> 1) + ptr[i];

    return true;
}
