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
# sernet.cpp
# SERNET protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "sernet.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TSernetProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next CBUS message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSernetProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	int count;
	int Size;
	TComMsg *CurrMsg = FComMsg;

	count = *FRawCount - FRawPos;

	if (count == 0)
		return FALSE;

    if (FTime)
        delete FTime;

    FTime = new TDateTime(CurrMsg->TimeMSB, FComMsg->TimeLSB);

	str = FMsg;
	*str = 0;
	Size = 0;

	Channel = CurrMsg->Channel;
	LastTime = CurrMsg->TimeLSB;
	ch = CurrMsg->ch;
	Size++;
	CurrMsg++;

	while (count > Size && ch != 0x9B)
	{
		if (Channel != CurrMsg->Channel)
		{
		    FComMsg = CurrMsg;
		    FSize = Size;
			return TRUE;
		}
		LastTime = CurrMsg->TimeLSB;
		ch = CurrMsg->ch;
		Size++;
		CurrMsg++;
	}

	if (Size > 1)
	{
        FComMsg = CurrMsg - 1;
		FSize = Size - 1;
		return TRUE;
	}

	while (count > Size)
	{
		*str = ch;
		str++;
		*str = 0;

		if (Channel != CurrMsg->Channel)
		{
		    FComMsg = CurrMsg;
		    FSize = Size;
			return TRUE;
		}
		
		Elapsed = CurrMsg->TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
		{
		    FComMsg = CurrMsg;
		    FSize = Size;
			return TRUE;
		}

		LastTime = CurrMsg->TimeLSB;
		ch = CurrMsg->ch;
		Size++;
		CurrMsg++;
	}

	return FALSE;
}

/*##################  TSernetProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show CBUS msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowMsg()
{
    ShowHexMsg();
}

/*##################  TSernetProtocolAnalyser::TSernetProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSernetProtocolAnalyser::TSernetProtocolAnalyser(const char *MemMapName, int MaxSize)
  : TProtocolAnalyser(MemMapName, MaxSize)
{
}

/*##################  TSernetProtocolAnalyser::~TSernetProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSernetProtocolAnalyser::~TSernetProtocolAnalyser()
{
}
