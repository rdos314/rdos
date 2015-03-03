/*###########################################################################
* RDOS operating system 
* Copyright (C) 1998-2000, Leif Ekblad
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version. The only exception to this rule
* is for commercial usage. For information on commercial usage,
* contact em486@rdos.net.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
* The author of this program may be contacted at leif@rdos.net
*
* X25643.CPP
* X25643 emulation
*
*##########################################################################*/

#include "x25643.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TX25643::TX25643  ###############
*   Purpose....: Constructor for X25643                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TX25643::TX25643()
{
    int i;

    for (i = 0; i < 0x2000; i++)
        FData[i] = 0;

    FEnable = 1;
    FClk = 1;
    FSin = 1;
    FSout = 1;
}

/*##################  TX25643::~TX25643  ###############
*   Purpose....: Destructor for RAM                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TX25643::~TX25643()
{
}

/*##################  TX25643::Load  ###############
*   Purpose....: Load file                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::Load(TFile *File)
{
    File->SetPos(0);
    File->Read(FData, 0x2000);
}

/*##################  TX25643::SetCs  ###############
*   Purpose....: Set CS signal                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::SetCs()
{
    FEnable = 1;
}

/*##################  TX25643::ResetCs  ###############
*   Purpose....: Reset CS signal                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::ResetCs()
{
    FEnable = 0;
}

/*##################  TX25643::SetClk  ###############
*   Purpose....: Set CLK signal                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::SetClk()
{
    FClk = 1;
}

/*##################  TX25643::ResetClk  ###############
*   Purpose....: Reset CLK signal                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::ResetClk()
{
    FClk = 0;
}

/*##################  TX25643::SetSin  ###############
*   Purpose....: Set SIN signal                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::SetSin()
{
    FSin = 1;
}

/*##################  TX25643::ResetSin  ###############
*   Purpose....: Reset SIN signal                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::ResetSin()
{
    FSin = 0;
}

/*##################  TX25643::ReadSout  ###############
*   Purpose....: Read SOUT signal                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TX25643::ReadSout()
{
    return FSout;
}
