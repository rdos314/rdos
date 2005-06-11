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
* EMPIC.CPP
* Emulate PIC16F84
*
*##########################################################################*/

#include <rdos.h>
#include <stdio.h>
#include "pic16f84.h"

void OpenScreen(const char *FileName);
void CloseScreen();

#define STACK_SIZE	0x4000

TPic16F84 Cpu;

/*##################  main  ###############
*   Purpose....: main				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void main(void)
{
	TFile ProgFile("c:\\rdos\\pic\\home104\\sernet.obj");

	OpenScreen("f:\\sim.log");

    Cpu.Load(&ProgFile);
	Cpu.Reset();

	for (;;)
	{
		Cpu.Show();
		switch (RdosReadKeyboard() & 0xFF)
		{
			case 'q':
			case 'Q':
				return;

			case 't':
			case 'T':
				Cpu.Trace();
				break;

			case 'p':
			case 'P':
				Cpu.Pace();
				break;

			case 'g':
			case 'G':
				Cpu.Go();
				break;

			case 'u':
			case 'U':
				Cpu.ShowInstruction(20);
				RdosReadKeyboard();
				break;

		}
	}
	CloseScreen();
}
