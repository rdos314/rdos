/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
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
# log.h
# Log class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "log.h"
#include "section.h"

#define STACK_SIZE      0x2000

#define LOG_SIGN        0xABEF1456
#define MAX_MSG_SIZE    0x10000

#define FALSE		    0
#define TRUE		    !FALSE

/*##########################################################################
#
#   Name       : TLogReader::TLogReader
#
#   Purpose....: LogReader constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLogReader::TLogReader(const char *filename)
{
    FFile = new TFile(filename);
    FCurrMsg = new TDeviceMsg(MAX_MSG_SIZE);
}

/*##########################################################################
#
#   Name       : TLogReader::~TLogReader
#
#   Purpose....: LogReader destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLogReader::~TLogReader()
{
    if (FFile)
        delete FFile;

    if (FCurrMsg)
        delete FCurrMsg;
}

/*##########################################################################
#
#   Name       : TLogReader::Reset
#
#   Purpose....: Reset memory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLogReader::Reset()
{
    if (FCurrMsg)
        delete FCurrMsg;
    FCurrMsg = new TDeviceMsg(MAX_MSG_SIZE);
}

/*##########################################################################
#
#   Name       : TLogReader::GetNext
#
#   Purpose....: Get next
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLogReader::GetNext()
{
    long pos;
    long sign;
    int size = 0;
    char *buf;

    pos = FFile->GetPos();

    for (;;)
    {
        FFile->Read(&sign, 4);

        while (sign != LOG_SIGN)
        {
            pos++;
            FFile->SetPos(pos);
            if (FFile->Read(&sign, 4) != 4)
                return FALSE;
        }

        FFile->Read(&size, 2);
        if (size > 0 && size < 0x4000)
        {
            Reset();
        
			buf = new char[size + 8];
			FFile->Read(buf + 6, size + 2);
			memcpy(buf, &sign, 4);
			memcpy(buf + 4, &size, 2);

			if (FCurrMsg->Parse(LOG_SIGN, buf, size + 8))
			{
				delete buf;
				return TRUE;
		    }
            delete buf;
        }

        pos++;
        FFile->SetPos(pos);
    }
}

/*##########################################################################
#
#   Name       : TLogReader::GotoFirst
#
#   Purpose....: Goto first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLogReader::GotoFirst()
{
    FFile->SetPos(0);

    if (FFile->IsOpen())
        return GetNext();
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TLogReader::GotoNext
#
#   Purpose....: Goto next entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLogReader::GotoNext()
{
    if (FFile->IsOpen())
        return GetNext();
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TLogReader::Get
#
#   Purpose....: Get current data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceMsg *TLogReader::Get()
{
    return FCurrMsg;
}
