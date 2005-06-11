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
* PIC16F84.H
* Pic16f84 emulation class
*
*##########################################################################*/

#ifndef	_PIC16F84_H
#define _PIC16F84_H

#define STATUS_C        1
#define STATUS_DC       2
#define STATUS_Z        4
#define STATUS_PD       8
#define STATUS_TO       0x10
#define STATUS_RP0      0x20
#define STATUS_RP1      0x40
#define STATUS_IRP      0x80

class TPic16F84
{
public:
	TPic16F84();
	~TPic16F84();

// don't change data members here, without also changing in pic16f84.inc file

    char Reg_IND;
    char Reg_TMR0;
    char Reg_OPTION;
    char Reg_PCL;
    char Reg_STATUS;
    char Reg_FSR;
    char Reg_PORTA;
    char Reg_TRISA;
    char Reg_PORTB;
    char Reg_TRISB;
    char Reg_EEDATA;
    char Reg_EEADR;
    char Reg_EECON1;
    char Reg_EECON2;
    char Reg_PCLATH;
    char Reg_INTCON;

    char DataArr[68];
    short int CodeArr[1024]; 
    short int StackArr[8];
    char EeArr[64];   

    char PendingInt;
    long TotalCycles;
    char Running;

// end of common variables with pic16f84.inc
};

#endif
