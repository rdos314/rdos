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
* SCREEN.CPP
* Screen write functions for debugger
*
*##########################################################################*/

#include <stdio.h>

extern "C"
{

void __stdcall ShowChar(char ch);
void __stdcall ShowSizeString(char *str, int Size);
void __stdcall ShowAsciiz(char *str);

}

/*##################  ShowChar  ###############
*   Purpose....: Write a char to screen							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall ShowChar(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;
	printf(str);
}

/*##################  ShowSizeString  ###############
*   Purpose....: Write a string with size on screen				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall ShowSizeString(char *str, int Size)
{
	char locstr[2];
	int i;

	locstr[1] = 0;
	for (i = 0; i < Size; i++)
	{
		locstr[0] = *str;
		str++;
		printf(locstr);
	}
}

/*##################  ShowAsciiz  ###############
*   Purpose....: Write a string on screen				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void __stdcall ShowAsciiz(char *str)
{
	printf(str);
}
