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
# redustor.cpp
# Redundant storage list class
#
########################################################################*/

#include <string.h>

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
