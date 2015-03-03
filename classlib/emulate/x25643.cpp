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
    FStatus = 0x30;
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
    FCmdCount = 0;
    FCmdVal = 0;
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
    if (FClk == 0 && FEnable == 0)
        NotifySetClk();
         
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
    if (FClk == 1 && FEnable == 0)
        NotifyResetClk();
         
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

/*##################  TX25643::ExecuteCmd  ###############
*   Purpose....: ExecuteCmd                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::ExecuteCmd()
{
    FDataCount = 0;
    FDataVal = 0;

    switch (FCmdVal)
    {
        case 4:
            FStatus &= 0xBD;
            break;

        case 5:
            FDataVal = FStatus;
            break;
            
        case 6:
            FStatus |= 2;
            break;

    }
}

/*##################  TX25643::ExecuteWrite  ###############
*   Purpose....: ExecuteWrite                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::ExecuteWrite()
{
    switch (FCmdVal && (FStatus & 2))
    {
        case 1:
            FStatus = FDataVal & 0x7F;
            break;
    }
}

/*##################  TX25643::NotifySetClk  ###############
*   Purpose....: Notify set CLK trigger                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::NotifySetClk()
{
    if (FCmdCount < 8)
    {
        FCmdVal = FCmdVal << 1;
        FCmdVal |= FSin;
        FCmdCount++;

        if (FCmdCount == 8)
            ExecuteCmd();
    } 
    else
    {
        switch (FCmdVal)
        {
            case 1:
            case 2:
                if (FDataCount < 8)
                {                
                    FDataVal = FDataVal << 1;
                    FDataVal |= FSin;
                    FDataCount++;

                    if (FDataCount == 8)
                        ExecuteWrite();
                }
                break;
        }    
    }
}

/*##################  TX25643::NotifyResetClk  ###############
*   Purpose....: Notify reset CLK trigger                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TX25643::NotifyResetClk()
{
    if (FCmdCount == 8)
    {    
        switch (FCmdVal)
        {
            case 5:
                if (FDataCount < 8)
                {                
                    if (FDataVal & 0x80)
                        FSout = 1;
                    else
                        FSout = 0;
                        
                    FDataVal = FDataVal << 1;
                    FDataCount++;
                }
                break;
        }    
    }
}
