/*###########################################################################
* Em486 CPU emulator
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
* PIC16F84.CPP
* PIC16F84 emulation
*
*##########################################################################*/

#include <stdio.h>
#include "pic16f84.h"

#define FALSE 0
#define TRUE !FALSE

extern "C"
{

}

/*##################  TPic16F84::TPic16F84  ###############
*   Purpose....: Constructor for CPU							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPic16F84::TPic16F84()
{
	Reset();
}

/*##################  TPic16F84::~TPic16F84  ###############
*   Purpose....: Destructor for CPU							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPic16F84::~TPic16F84()
{
}

/*##################  TPic16F84::Load  ###############
*   Purpose....: Load program                   				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPic16F84::Load(TFile *File)
{
    File->Read(CodeArr, 2048);
}

/*##################  TPic16F84::Reset  ###############
*   Purpose....: Set CPU registers to reset state				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPic16F84::Reset()
{
	Reg_TRISA = 0x1F;
	Reg_TRISB = 0xFF;
	Reg_OPTION = 0xFF;
	Reg_STATUS = 0x18;
	Reg_PCL = 0;
	Reg_PCLATH = 0;
	Reg_INTCON = 0;
	Reg_EECON1 = 0;

	Running = FALSE;
	PendingInt = 0;
}

/*##################  TPic16F84::Trace  ###############
*   Purpose....: Trace									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPic16F84::Trace()
{
}

/*##################  TPic16F84::Pace  ###############
*   Purpose....: Pace									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPic16F84::Pace()
{
}

/*##################  TPic16F84::Go  ###############
*   Purpose....: Go												            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPic16F84::Go()
{
}

/*##################  TPic16F84::Disassemble  ###############
*   Purpose....:  Disassemble 20 instruction    		            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 01-05-20                                                   #
*##########################################################################*/
void TPic16F84::ShowInstruction(int Count)
{
}

/*##################  TPic16F84::Show  ###############
*   Purpose....: Show registers									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPic16F84::Show()
{
}
