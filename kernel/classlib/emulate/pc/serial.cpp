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
* SERIAL.CPP
* Serial port emulation
*
*##########################################################################*/

#include "serial.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TSerial::TSerial  ###############
*   Purpose....: Constructor									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TSerial::TSerial()
{
}

/*##################  TSerial::SetClk  ###############
*   Purpose....: Set clock										            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TSerial::SetClk()
{
}

/*##################  TSerial::ResetClk  ###############
*   Purpose....: Reset clock										            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TSerial::ResetClk()
{
}

/*##################  TSerial::DefineIrq  ###############
*   Purpose....: Define IRQ										            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TSerial::DefineIrq(TPic *Pic, int Channel)
{
	FPic = Pic;
	FChannel = Channel;
}

/*##################  TSerial::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TSerial::Out(int Port, char Value)
{
}

/*##################  TSerial::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
char TSerial::In(int Port)
{
	return 0xFF;
}
