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
# redustor.cpp
# Redundant storage list class
#
########################################################################*/

#ifdef __GNUC__
#include <string.h>
#else
#include <mem.h>
#endif

#include "redustor.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRedundanceStorageList::TRedundanceStorageList
#
#   Purpose....: Constructor for list (no recover)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRedundanceStorageList::TRedundanceStorageList(int DataSize, unsigned short int ListID)
  : TStorageList(DataSize, ListID)
{
    FRedCount = 0;
}

/*##########################################################################
#
#   Name       : TRedundanceStorageList::TRedundanceStorageList
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRedundanceStorageList::TRedundanceStorageList(const TRedundanceStorageList &src)
  : TStorageList(src)
{
    int i;
    
	FRedCount = src.FRedCount;

    for (i = 0; i < FRedCount; i++)
        FRedArr[i] = src.FRedArr[i];
}

/*##########################################################################
#
#   Name       : TRedundanceStorageList::~TRedundanceStorageList
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRedundanceStorageList::~TRedundanceStorageList()
{
}

/*##########################################################################
#
#   Name       : TRedundanceStorageList::Add
#
#   Purpose....: Add redundance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRedundanceStorageList::Add(TStorage *store)
{
    if (FRedCount < MAX_REDUNDANCE)
    {
        FRedArr[FRedCount] = store;
        FRedCount++;
    }
}

/*##########################################################################
#
#   Name       : TRedundanceStorageList::Recover
#
#   Purpose....: Recover list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRedundanceStorageList::Recover()
{
    int i;

	if (FRedArr[0])
		FMaxEntries = FRedArr[0]->Size() / (long)FEntrySize;
	else
		FMaxEntries = 0;

	for (i = 0; i < FRedCount; i++)
		if (FRedArr[i]->Size() / (long)FEntrySize < FMaxEntries)
			FMaxEntries = FRedArr[0]->Size() / (long)FEntrySize;
    
    FRecover = TRUE;
    TStorageList::Recover();
    FRecover = FALSE;
}

/*##########################################################################
#
#   Name       : TRedundanceStorageList::Read
#
#   Purpose....: Read an entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRedundanceStorageList::Read(int entry, char *buf)
{
	int i;
	int ok = FALSE;
	long pos;
	int ValidArr[MAX_REDUNDANCE];
	int ValidPos;
    unsigned short int crc;

	pos = (long)entry * (long)FEntrySize;

    if (FRecover)
    {
        ValidPos = -1;
        
    	for (i = 0; i < FRedCount; i++)
    	{
	    	ok = FRedArr[i]->Read(pos, buf, FEntrySize);
	    	if (ok)
            {
    			crc = CalcCrc(buf, FDataSize);
	    		ok = crc == *(unsigned short int *)(buf + FDataSize);
	        }
	        
            if (ok)	    	
	    	{
	    	    ValidArr[i] = TRUE;
	    	    ValidPos = i;
	    	}
	    	else
	    	    ValidArr[i] = FALSE;
	    }

	    if (ValidPos == -1)
	        ok = FALSE;
	    else
	    	ok = FRedArr[ValidPos]->Read(pos, buf, FEntrySize);

        if (ok)
        {
            for (i = 0; i < FRedCount; i++)
                if (!ValidArr[i])
                    FRedArr[i]->Write(pos, buf, FEntrySize);
        }
        else
        {
            memset(buf, 0xFF, FEntrySize);
            for (i = 0; i < FRedCount; i++)
                FRedArr[i]->Write(pos, buf, FEntrySize);
        }

    }
    else
    {
    	for (i = 0; i < FRedCount && !ok; i++)
    	{
	    	ok = FRedArr[i]->Read(pos, buf, FEntrySize);
	    	if (ok)
            {
    			crc = CalcCrc(buf, FDataSize);
	    		ok = crc == *(unsigned short int *)(buf + FDataSize);
	        }
	    }

    }

    if (!ok && FRedCount)
    	ok = FRedArr[0]->Read(pos, buf, FEntrySize);        
    
	return ok;
}

/*##########################################################################
#
#   Name       : TRedundanceStorageList::Write
#
#   Purpose....: Write an entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRedundanceStorageList::Write(int entry, const char *buf)
{
	int i;
	int ok = FALSE;
	long pos;

	pos = (long)entry * (long)FEntrySize;

	for (i = 0; i < FRedCount; i++)
		if (FRedArr[i]->Write(pos, buf, FEntrySize))
			ok = TRUE;

	return ok;
}
