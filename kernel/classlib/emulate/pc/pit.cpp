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
* PIT.CPP
* PIT emulation
*
*##########################################################################*/

#include "pit.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TPitCounter::TPitCounter  ###############
*   Purpose....: Constructor for PIT							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TPitCounter::TPitCounter()
{
	OnSetOut = 0;
	OnResetOut = 0;
	FClk = 0;
	FGate = 1;
	FOut = 0;
	FMode = 0;
	FRunning = FALSE;
	FPeriod = 0;
	FCount = 0;
	FLatchedCount = 0;
	FLatched = FALSE;
	FByteCounter = 0;
	FRl = 0;
}

/*##################  TPitCounter::ModifyOut  ###############
*   Purpose....: Modify value of out						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::ModifyOut(char Value)
{
	if (Value != FOut)
	{
		FOut = Value;
		if (Value)
		{
			if (OnSetOut)
				(*OnSetOut)();
		}
		else
		{
			if (OnResetOut)
				(*OnResetOut)();
		}	
	}
}

/*##################  TPitCounter::SetClk  ###############
*   Purpose....: Set clock for a channel						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::SetClk()
{
	if (!FClk)
		FClk = 1;
}

/*##################  TPitCounter::ResetClk  ###############
*   Purpose....: Reset clock for a channel						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::ResetClk()
{
	if (FClk)
	{
		FClk = 0;
		if (FRunning)
			switch (FMode)
			{
				case 0:
				case 4:	
				case 5:
					if (FGate)
					{
						FCount--;
						if (!FCount)
						{
							FRunning = FALSE;
							ModifyOut(1);
						}
					}
					break;

				case 1:
					FCount--;
					if (!FCount)
					{
						FRunning = FALSE;
						ModifyOut(1);
					}
					break;

				case 2:
					if (FGate)
					{
						FCount--;
						if (!FCount)
						{
							ModifyOut(0);
							FCount = FPeriod;
						}
						else
							ModifyOut(1);
					}
					else
						ModifyOut(1);
					break;


				case 3:
					if (FGate)
					{
						if (FCount & 1)
						{
							if (FOut)
								FCount--;
							else
								FCount -= 3;
						}
						else
							FCount -= 2;

						if (!FCount)
						{
							if (FOut)
								ModifyOut(0);
							else
								ModifyOut(1);
							FCount = FPeriod;
						}
					}
					break;


			}
	}
}

/*##################  TPitCounter::SetGate  ###############
*   Purpose....: Set gate for a channel						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::SetGate()
{
	FGate = 1;
	switch (FMode)
	{
		case 1:
		case 2:
		case 3:
		case 5:
			FRunning = TRUE;
			FCount = FPeriod;
			break;

	}
}

/*##################  TPitCounter::ResetGate  ###############
*   Purpose....: Reset gate for a channel						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::ResetGate()
{
	FGate = 0;
}

/*##################  TPitCounter::LoadPeriod  ###############
*   Purpose....: Load a new period								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::LoadPeriod(char Value)
{
	switch (FRl)
	{
		case 1:
			FPeriod = (FPeriod & 0xFF00) | Value;
			if (!FRunning)
				FCount = FPeriod;
			FRunning = TRUE;
			break;

		case 2:
			FPeriod = (FPeriod & 0xFF) | (Value << 8);
			if (!FRunning)
				FCount = FPeriod;
			FRunning = TRUE;
			break;

		case 3:
			if (FByteCounter)
			{
				FPeriod = (FPeriod & 0xFF) | (Value << 8);
				FByteCounter = 0;
				if (!FRunning)
					FCount = FPeriod;
				FRunning = TRUE;
			}
			else
			{
				FPeriod = (FPeriod & 0xFF00) | Value;
				FByteCounter = 1;
			}
	}
}

/*##################  TPitCounter::LoadCounter  ###############
*   Purpose....: Load a new counter value								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::LoadCounter(char Value)
{
	switch (FRl)
	{
		case 1:
			FCount = (FCount & 0xFF00) | Value;
			FRunning = TRUE;
			break;

		case 2:
			FCount = (FCount & 0xFF) | (Value << 8);
			FRunning = TRUE;
			break;

		case 3:
			if (FByteCounter)
			{
				FCount = (FCount & 0xFF) | (Value << 8);
				FRunning = TRUE;
				FByteCounter = 0;
			}
			else
			{
				FCount = (FCount & 0xFF00) | Value;
				FRunning = FALSE;
				FByteCounter = 1;
			}
	}
}

/*##################  TPitCounter::SetMode  ###############
*   Purpose....: Set mode of counter							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::SetMode(char Mode)
{
	FByteCounter = 0;
	if ((Mode & 0x30) == 0)
	{
		FLatched = TRUE;
		FLatchedCount = FCount;
	}
	else
	{
		FMode = (Mode >> 1) & 7;
		FRl = (Mode >> 4) & 3;

		switch (FMode)
		{
			case 0:
				ModifyOut(0);
				break;

			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
				ModifyOut(1);
				break;
		}
	}
}

/*##################  TPitCounter::Load  ###############
*   Purpose....: Load a counter									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPitCounter::Load(char Value)
{
	switch (FMode)
	{
		case 0:
			LoadCounter(Value);
			ModifyOut(0);
			break;

		case 4:
			LoadCounter(Value);
			break;

		case 2:
		case 3:
		case 5:
			LoadPeriod(Value);
			break;

		case 1:
			LoadPeriod(Value);
			FRunning = FALSE;
			break;

	}
}

/*##################  TPitCounter::Read  ###############
*   Purpose....: Read a counter									            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
char TPitCounter::Read()
{
	if (FLatched)
	{
		switch (FRl)
		{
			case 1:
				return FLatchedCount & 0xFF;

			case 2:
				return (FLatchedCount >> 8) & 0xFF;

			case 3:
				if (FByteCounter)
				{
					FByteCounter = 0;
					return (FLatchedCount >> 8) & 0xFF;
				}
				else
				{
					FByteCounter = 1;
					return FLatchedCount & 0xFF;
				}
		}
	}
	else
	{
		switch (FRl)
		{
			case 1:
				return FCount & 0xFF;

			case 2:
				return (FCount >> 8) & 0xFF;

			case 3:
				if (FByteCounter)
				{
					FByteCounter = 0;
					return (FCount >> 8) & 0xFF;
				}
				else
				{
					FByteCounter = 1;
					return FCount & 0xFF;
				}			
		}		
	}
	return 0;
}

/*##################  TPit::TPit  ###############
*   Purpose....: Constructor for PIT							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TPit::TPit()
{
}

/*##################  TPit::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TPit::Out(int Port, char Value)
{
	int Channel;

	switch (Port & 3)
	{
		case 0:
			Counter[0].Load(Value);
			break;

		case 1:
			Counter[1].Load(Value);
			break;

		case 2:
			Counter[2].Load(Value);
			break;

		case 3:
			Channel = (Value >> 6) & 3;
			Counter[Channel].SetMode(Value & 0x3F);
			break;
			
	}
}

/*##################  TPit::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
char TPit::In(int Port)
{
	switch (Port & 3)
	{
		case 0:
			return Counter[0].Read();

		case 1:
			return Counter[1].Read();

		case 2:
			return Counter[2].Read();

	}
	return 0xFF;
}
