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
* 6117.CPP
* ALI6117 emulation
*
*##########################################################################*/

#include <windows.h>
#include "6117.h"

#define FALSE 0
#define TRUE !FALSE

int MemModeTable[32][4] =
{
	{18, 18, 0,	 0},
	{20, 20, 20, 0},
	{18, 18, 18, 18},
	{20, 20, 20, 20},
	{18, 18, 20, 0},
	{20, 20, 22, 0},
	{18, 18, 20, 20},
	{20, 20, 22, 22},
	{18, 18, 22, 0},
	{20, 22, 0,  0},
	{19, 0,	 0,  0},
	{20, 22, 22, 0},
	{19, 19, 0,  0},
	{20, 22, 22, 22},
	{19, 19, 20, 0},
	{21, 0,  0,  0},
	{19, 19, 20, 20},
	{21, 21, 0,  0},
	{19, 19, 22, 0},
	{21, 21, 22, 22},
	{19, 19, 22, 22},
	{21, 22, 0,  0},
	{19, 20, 0,  0},
	{22, 0,  0,  0},
	{19, 20, 20, 0},
	{22, 22, 0,  0},
	{19, 22, 0,  0},
	{22, 22, 22, 0},
	{20, 0,  0,  0},
	{22, 22, 22, 22},
	{20, 20, 0,  0},
	{24, 24, 0,  0}
};

/*##################  T6117::T6117  ###############
*   Purpose....: Constructor for 6117							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
T6117::T6117(TKeyb *Keyb)
{
	int i;

	FKeyb = Keyb;
	FDramConfigured = FALSE;
	FDram = 0;
	FDramSize = 0;
	FRom = 0;
	FRomSize = 0;
	for (i = 0; i < 4; i++)
		FDramBanks[i] = 0;

	Reset();
}

/*##################  T6117::Reset  ###############
*   Purpose....: Reset state									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::Reset()
{
	int i;

	for (i = 0; i < 0x80; i++)
		FData[i] = 0xFF;

	FClkCount = 0;
	FRefresh = FALSE;
	FLocked = TRUE;
	FPort = 0;

	FData[0x10] = 0;
	FData[0x11] = 0xF8;
	FData[0x12] = 0x10;
	FData[0x13] = 0;
	FData[0x14] = 0;
	FData[0x15] = 0;
	FData[0x16] = 0;
	FData[0x17] = 0xFF;
	FData[0x18] = 0xF0;
	FData[0x19] = 0;
	FData[0x1A] = 0xFF;
	FData[0x1B] = 0xF0;
	FData[0x1C] = 0;
	FData[0x1D] = 0xFF;
	FData[0x1E] = 0;
	FData[0x20] = 0x80;
	FData[0x30] = 0x8;
	FData[0x31] = 0x1;
	FData[0x32] = 0;
	FData[0x33] = 0;
	FData[0x34] = 0;
	FData[0x35] = 0;
	FData[0x36] = 0;
	FData[0x37] = 0;
	FData[0x38] = 0;
	FData[0x39] = 0;
	FData[0x3A] = 0;
	FData[0x3B] = 0;
	FData[0x3C] = 0;
	FData[0x3D] = 0;
	FData[0x3E] = 0;
	FData[0x3F] = 0;
	FData[0x55] = 0;
	FData[0x56] = 0;
	FData[0x57] = 0;
	FData[0x58] = 0;
	FData[0x59] = 0;
	FData[0x5A] = 0;
	FData[0x5B] = 0;
	FData[0x5C] = 0;
	FData[0x5D] = 0;
	FData[0x5E] = 0;
	FData[0x64] = 0;
	FData[0x66] = 0;
	FData[0x67] = 0;
	FData[0x68] = 0;
	FData[0x69] = 0;
	FData[0x6A] = 0;
	FData[0x6B] = 0;
	FData[0x6C] = 0;
	FData[0x6D] = 0;
	FData[0x6E] = 0;
	FData[0x6F] = 0;
	FData[0x70] = 0;
	FData[0x71] = 0;
	FData[0x72] = 0;
	FData[0x73] = 0;
}

/*##################  T6117::SetClk  ###############
*   Purpose....: Set clk										            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::SetClk()
{
	FClkCount++;
	if (FClkCount == 16)
	{
		FClkCount = 0;

		if (FData[0x20] & 0x80)
		{
			FRefresh = !FRefresh;
			FKeyb->SetRefresh(FRefresh);
		}
	}	
}

/*##################  T6117::ResetClk  ###############
*   Purpose....: Reset clk										            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::ResetClk()
{
}

/*##################  T6117::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::Out(int Port, char Value)
{
	if (Port & 1)
	{
		if (FPort == 0x13)
		{
			switch (Value)
			{
				case 0xC5:
					FLocked = FALSE;
					break;

				case 0:
					FLocked = TRUE;
					break;

				default:
					break;
			}
		}
		else
		{
			if (!FLocked)
				if (FPort >= 0)
				{
					FData[FPort] = Value;
					switch (FPort)
					{
						case 0x10:
							if ((int)((Value >> 3) & 0x1F) == FDramMode)
								FDramConfigured = TRUE;
							else
								FDramConfigured = FALSE;
							break;
					}
				}
		}
	}
	else
		FPort = Value;
}

/*##################  T6117::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char T6117::In(int Port)
{
	if (Port & 1)
	{
		if (FLocked || FPort < 0)
			return 0xFF;
		else
			return FData[FPort];
	}
	else
		return FPort;
}

/*##################  T6117::DefineRom  ###############
*   Purpose....: Define ROM contents							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::DefineRom(unsigned long Size, char *FileName)
{
	HFILE file;

	if (FRom)
		free(FRom);

	FRomSize = Size;
	FRom = (char *)malloc(Size);

	file = _lopen(FileName, 0);
	if (file)
	{
		_lread(file, FRom, Size);
		_lclose(file);
	}
}

/*##################  T6117::DefineDram  ###############
*   Purpose....: Define DRAM contents							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::DefineDram(int Bank, unsigned long Size)
{
	int i;
	int j;
	int Pot;
	long *LongPtr;
	long l;
	int Found;

	if (Bank < 0 || Bank >= 4)
		return;

	switch (Size)
	{
		case 0x80000:
			Pot = 18;
			break;

		case 0x100000:
			Pot = 19;
			break;

		case 0x200000:
			Pot = 20;
			break;

		case 0x400000:
			Pot = 21;
			break;

		case 0x800000:
			Pot = 22;
			break;

		default:
			return;	
	}		

	FDramBanks[Bank] = Pot;
	for (i = 0; i < 32; i++)
	{
		Found = TRUE;
		for (j = 0; j < 4; j++)
			if (FDramBanks[j] != MemModeTable[i][j])
			{
				Found = FALSE;
				break;
			}
		if (Found)
			break;
	}

	if (!Found)
		return;

	FDramMode = i;
	FDramSize += Size;

	if (FDram)
		free(FDram);

	FDram = (char *)malloc(Size);

	LongPtr = (long *)FDram;
	for (l = 0; l < Size / 4; l++)
	{
		*LongPtr = 0x77777777;
		LongPtr++;
	}
}

/*##################  T6117::ReadDram29  ###############
*   Purpose....: Read from DRAM mode 29							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char T6117::ReadDram29(unsigned long Address)
{
	unsigned long Low;
	unsigned long High;
	unsigned long Ads;

	Low = Address & 0xFFF;
	High = (Address & 0xFFFC000) >> 14;			

	if ((Address & 0x2000) == 0)
		return 0xFF;

	if (Address & 0x1000)
	{
		if (FDramBanks[3])
		{
			switch (FDramBanks[3])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return 0xFF;
			}
			return *(FDram + Ads);
		}
		else
			return 0xFF;
	}
	else
	{
		if (FDramBanks[2])
		{
			switch (FDramBanks[2])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return 0xFF;
			}
			return *(FDram + Ads);
		}
		else
			return 0xFF;
	}	
}

/*##################  T6117::ReadDram31  ###############
*   Purpose....: Read from DRAM mode 31							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char T6117::ReadDram31(unsigned long Address)
{
	unsigned long Low;
	unsigned long High;
	unsigned long Ads;

	Low = Address & 0x1FFF;
	High = (Address & 0xFFFC000) >> 14;			

	if (Address & 0x2000)
	{
		if (FDramBanks[1])
		{
			switch (FDramBanks[1])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 19:
					Ads = (Low & 0x3FF) + ((High & 0x3FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 21:
					Ads = (Low & 0x7FF) + ((High & 0x7FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return 0xFF;
			}
			return *(FDram + Ads);
		}
		else
			return 0xFF;
	}
	else
	{
		if (FDramBanks[0])
		{
			switch (FDramBanks[0])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 19:
					Ads = (Low & 0x3FF) + ((High & 0x3FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 21:
					Ads = (Low & 0x7FF) + ((High & 0x7FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return 0xFF;
			}
			return *(FDram + Ads);
		}
		else
			return 0xFF;
	}	
}

/*##################  T6117::WriteDram29  ###############
*   Purpose....: Write to DRAM mode 29							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::WriteDram29(unsigned long Address, char Data)
{
	unsigned long Low;
	unsigned long High;
	unsigned long Ads;

	Low = Address & 0xFFF;
	High = (Address & 0xFFFC000) >> 14;			

	if ((Address & 0x2000) == 0)
		return;

	if (Address & 0x1000)
	{
		if (FDramBanks[3])
		{
			switch (FDramBanks[3])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return;
			}
			*(FDram + Ads) = Data;
		}
	}
	else
	{
		if (FDramBanks[2])
		{
			switch (FDramBanks[2])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return;
			}
			*(FDram + Ads) = Data;
		}
	}	
}

/*##################  T6117::WriteDram31  ###############
*   Purpose....: Write to DRAM mode 31							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::WriteDram31(unsigned long Address, char Data)
{
	unsigned long Low;
	unsigned long High;
	unsigned long Ads;

	Low = Address & 0x1FFF;
	High = (Address & 0xFFFC000) >> 14;			

	if (Address & 0x2000)
	{
		if (FDramBanks[1])
		{
			switch (FDramBanks[1])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 19:
					Ads = (Low & 0x3FF) + ((High & 0x3FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 21:
					Ads = (Low & 0x7FF) + ((High & 0x7FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return;
			}
			*(FDram + Ads) = Data;
		}
	}
	else
	{
		if (FDramBanks[0])
		{
			switch (FDramBanks[0])
			{
				case 18:
					Ads = (Low & 0x3FF) + ((High & 0x1FF) << 9);
					break;

				case 19:
					Ads = (Low & 0x3FF) + ((High & 0x3FF) << 9);
					break;

				case 20:
					Ads = (Low & 0x7FF) + ((High & 0x3FF) << 10);
					break;

				case 21:
					Ads = (Low & 0x7FF) + ((High & 0x7FF) << 10);
					break;

				case 22:
					Ads = (Low & 0xFFF) + ((High & 0x7FF) << 11);
					break;

				default:
					return;
			}
			*(FDram + Ads) = Data;
		}
	}	
}

/*##################  T6117::ReadDram  ###############
*   Purpose....: Read from DRAM								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char T6117::ReadDram(unsigned long Address)
{
	int Mode;

	if (FData[0x3C] & 2)
		return 0xFF;

	if (FDramConfigured)
	{
		if (Address < FDramSize)
			return *(FDram + Address);
		else
			return 0xFF;
	}
	else
	{
		Mode = (int)((FData[0x10] >> 3) & 0x1F);
		switch (Mode)
		{
			case 29:
				return ReadDram29(Address);

			case 31:
				return ReadDram31(Address);

			default:
				return 0xFF;
		}
	}
}

/*##################  T6117::WriteDram  ###############
*   Purpose....: Write to DRAM								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::WriteDram(unsigned long Address, char Data)
{
	int Mode;

	if (FData[0x3C] & 2)
		return;

	if (FDramConfigured)
	{
		if (Address < FDramSize)
			*(FDram + Address) = Data;
	}
	else
	{
		Mode = (int)((FData[0x10] >> 3) & 0x1F);
		switch (Mode)
		{
			case 29:
				WriteDram29(Address, Data);
				return;

			case 31:
				WriteDram31(Address, Data);
				return;

			default:
				return;
		}
	}
}

/*##################  T6117::Read  ###############
*   Purpose....: Read from memory								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char T6117::Read(unsigned long Address)
{
	unsigned long Ads = Address & 0xFFFFFF;
	unsigned long Offset;

	if (Ads >= 0xFE0000)
	{
		Offset = Ads & 0x1FFFF;
		return *(FRom + Offset);
	}

	if (Ads >= 0x100000)
		return ReadDram(Address);

	if (Ads >= 0xE0000)
	{
		Offset = Ads & 0x1FFFF;
		return *(FRom + Offset);
	}

	return ReadDram(Address);
}

/*##################  T6117::Write  ###############
*   Purpose....: Write to memory								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void T6117::Write(unsigned long Address, char Data)
{
	unsigned long Ads = Address & 0xFFFFFF;
	unsigned long Offset;

	if (Ads >= 0xFE0000)
		return;

	if (Ads >= 0x100000)
	{
		WriteDram(Address, Data);
		return;
	}

	if (Ads >= 0xE0000)
		return;

	WriteDram(Address, Data);
}
