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
# spltstor.cpp
# Split storage list class
#
########################################################################*/

#include <mem.h>

#include "spltstor.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSplitStorageList::TSplitStorageList
#
#   Purpose....: Constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSplitStorageList::TSplitStorageList(int DataSize, unsigned short int ListID)
  : TStorageList(DataSize, ListID)
{
    FSplits = 0;
}

/*##########################################################################
#
#   Name       : TSplitStorageList::TSplitStorageList
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSplitStorageList::TSplitStorageList(const TSplitStorageList &src)
  : TStorageList(src)
{
    int i;
    
    FSplits = src.FSplits;

    for (i = 0; i < FSplits; i++)
        FStoreArr[i] = src.FStoreArr[i];
}

/*##########################################################################
#
#   Name       : TSplitStorageList::~TSplitStorageList
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSplitStorageList::~TSplitStorageList()
{
}

/*##########################################################################
#
#   Name       : TSplitStorageList::Add
#
#   Purpose....: Add a split
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSplitStorageList::Add(TStorage *Store)
{
    if (FSplits < MAX_STORE_SPLITS)
    {
        FStoreArr[FSplits] = Store;
        FSplits++;    
    }
}

/*##########################################################################
#
#   Name       : TSplitStorageList::Recover
#
#   Purpose....: Recover list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSplitStorageList::Recover()
{
    int i;

    FMaxEntries = 0;
    for (i = 0; i < FSplits; i++)
        FMaxEntries += FStoreArr[i]->Size() / (long)FEntrySize;

    TStorageList::Recover();
}

/*##########################################################################
#
#   Name       : TSplitStorageList::Read
#
#   Purpose....: Read an entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSplitStorageList::Read(int entry, char *buf)
{
	int i;
	long count;
	long lentry;

    lentry = (long)entry;

	for (i = 0; i < FSplits; i++)
	{
	    count = FStoreArr[i]->Size() / (long)FEntrySize;
	    
		if (lentry < count)
			return FStoreArr[i]->Read(lentry * (long)FEntrySize, buf, FEntrySize);
		else
			lentry -= count;
	}
	return FALSE;
}

/*##########################################################################
#
#   Name       : TSplitStorageList::Write
#
#   Purpose....: Write an entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSplitStorageList::Write(int entry, const char *buf)
{
	int i;
	long count;
	long lentry;

    lentry = (long)entry;

	for (i = 0; i < FSplits; i++)
	{
	    count = FStoreArr[i]->Size() / (long)FEntrySize;
	    
		if (lentry < count)
			return FStoreArr[i]->Write(lentry * (long)FEntrySize, buf, FEntrySize);
		else
			lentry -= count;
	}
	return FALSE;
}
