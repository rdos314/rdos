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
# bar.cpp
# Bar protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "bar.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TBarProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next bar message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TBarProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	TSerialDebug Debug;
	int StartPos;
	int Pos;
	int done;

	if (FRawFile->GetSize() <= FRawFile->GetPos())
        return FALSE;

    if (FTime)
        delete FTime;
    FTime = 0;

	str = FMsg;
	*str = 0;
	FSize = 0;

	done = FALSE;

	StartPos = FRawFile->GetPos();

    done = FALSE;
    
	if (FRawFile->GetSize() > FRawFile->GetPos() && !done)
	{
        Pos = FRawFile->GetPos();
	    FRawFile->Read(&Debug, sizeof(TSerialDebug));

        FTime = new TDateTime(Debug.TimeMSB, Debug.TimeLSB);
        Channel = Debug.Channel;
        LastTime = Debug.TimeLSB;
		ch = Debug.ch;
		*str = ch;
		str++;
		*str = 0;
		
        done = FALSE;
    }
    else
        done = TRUE;

    
	while (FRawFile->GetSize() > FRawFile->GetPos() && !done)
	{

        Pos = FRawFile->GetPos();
	    FRawFile->Read(&Debug, sizeof(TSerialDebug));

		if (Channel != Debug.Channel)
		{
		    FRawFile->SetPos(StartPos);
			return TRUE;
		}

		Elapsed = Debug.TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
		{
		    FRawFile->SetPos(Pos);
			return TRUE;
		}

		ch = Debug.ch;

		if (ch != '\r' && ch != '\n')
		{
    		*str = ch;
	    	str++;
		    *str = 0;
    		FSize++;
		}

        if (ch == '\n')
            return TRUE;

		LastTime = Debug.TimeLSB;
	}

	FRawFile->SetPos(StartPos);
	return FALSE;
}

/*##################  TBarProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show CBUS msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TBarProtocolAnalyser::ShowMsg()
{
	char tempstr[15];
	int i;
	char ch;
	char *str;
	
    if (FTime)
        ShowLongTime(FTime);

	str = FMsg;

	ch = *str;
	sprintf(tempstr, "%04hX", ch);
	tempstr[0] = ' ';
	tempstr[1] = tempstr[2];
	tempstr[2] = tempstr[3];
	tempstr[3] = ' ';
	tempstr[4] = 0;
	Write(tempstr);

	str++;
	
	Write(str);
	Write("\r\n");
}

/*##################  TBarProtocolAnalyser::TBarProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TBarProtocolAnalyser::TBarProtocolAnalyser(TFile *RawFile, int MaxSize)
  : TProtocolAnalyser(RawFile, MaxSize)
{
}

/*##################  TBarProtocolAnalyser::~TBarProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TBarProtocolAnalyser::~TBarProtocolAnalyser()
{
}
