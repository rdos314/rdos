
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
# tatsuno.cpp
# Tatsuno protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "tatsuno.h"

#define ENQ		5
#define ACK		6
#define STX		0x82

#define FUEL_DATA_CMD	0
#define QACK_CMD        1
#define PRESET_CMD		2

#define FALSE	0
#define TRUE	!FALSE

/*##################  TTatsunoProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next Tatsuno message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTatsunoProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	unsigned char cmd;
	TSerialDebug Debug;
	int Pos;
	int size;

	if (FRawFile->GetSize() <= FRawFile->GetPos())
		return FALSE;

	if (FTime)
		delete FTime;
	FTime = 0;

	str = FMsg;
	*str = 0;
	FSize = 0;
	LastTime = 0;
	Channel = 0;

	Pos = FRawFile->GetPos();
	FRawFile->Read(&Debug, sizeof(TSerialDebug));
	FRawFile->SetPos(Pos);
	cmd = (unsigned char)Debug.ch;
	FTime = new TDateTime(Debug.TimeMSB, Debug.TimeLSB);
	LastTime = Debug.TimeLSB;
	Channel = Debug.Channel;

	switch (cmd)
	{
		case ENQ:
			size = 6;
			break;

		case ACK:
			size = 5;
			break;

		case STX:
			size = 4;
			break;

		default:
			size = 1;
	}

	FLrc = 0;

	while (FRawFile->GetSize() > FRawFile->GetPos())
	{
		Pos = FRawFile->GetPos();
		FRawFile->Read(&Debug, sizeof(TSerialDebug));

		if (Channel != Debug.Channel)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		Elapsed = Debug.TimeLSB - LastTime;
		if (Elapsed > 1193 * 250)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		LastTime = Debug.TimeLSB;
		ch = Debug.ch;
		FLrc = FLrc ^ ch;

		*str = ch;
		str++;
		*str = 0;

		FSize++;

		size--;

		if (size == 0)
		{
			if (FLrc == 0)
				return TRUE;
			else
			{
				if (cmd == STX)
				{
					switch (FMsg[2])
					{
						case FUEL_DATA_CMD:
							size = 19 - 4;
							break;

						case PRESET_CMD:
							size = 19 - 4;
							break;

						default:
							return TRUE;
					}
				}
				else
					return TRUE;
			}
		}
	}

	return TRUE;
}

/*##################  TTatsunoProtocolAnalyser::ShowAddress ##########################
*   Purpose....: Show message address  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowAddress(char adr)
{
	char str[30];

	sprintf(str, " %d ", adr + 1);
	Write(str);
}

/*##################  TTatsunoProtocolAnalyser::ShowControl ##########################
*   Purpose....: Show control vector  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowControl(const char *vect)
{
    char str[10];
    char ch;
    int has;
    char mask;
    int i;

    has = FALSE;
    mask = 1;

    ch = *vect;
	for (i = 0; i < 8; i++)
    {
        if (ch & mask)
        {
			if (has)
                Write(",");

            sprintf(str, " %d", i + 1);
            Write(str);
            has = TRUE;
        }
        mask = mask << 1;
    }
    
    ch = *(vect + 1);
    for (i = 0; i < 8; i++)
    {
        if (ch & mask)
        {
            if (!has)
                Write(",");

            sprintf(str, " %d", i + 9);
            Write(str);
            has = TRUE;
		}
        mask = mask << 1;
    }

    if (has)
        Write(" ON ");
}

/*##################  TTatsunoProtocolAnalyser::ShowStatus ##########################
*   Purpose....: Show pump status  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowStatus(char stat)
{
    if (stat & 1)
        Write(" OFF");

    if (stat & 2)
        Write(" LIFTED");

    if (stat & 4)
        Write(" FILL");

    if (stat & 8)
        Write(" COMPLETED");

    if (stat & 0x40)
        Write(" PRESET-REQ");
}

/*##################  TTatsunoProtocolAnalyser::UpdateEnq ##########################
*   Purpose....: Show ENQ/ACK msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::UpdateEnq()
{
    if (FEnq[0] || FAck[0])
    {
    	ShowLongTime(FTime);
	    Write("ENQ");

    	if (FEnq[0])
	    {
            ShowAddress(FEnq[1]);
            ShowControl(&FEnq[3]);
        }
        else
        {
            ShowAddress(FAck[1]);            
            Write(" ** NO REQ ** ");
        }

        if (FAck[0])
            ShowStatus(FAck[2]);
        else
            Write(" ** NO ANSWER ** ");
                
		Write("\r\n");

		FEnq[0] = 0;
		FAck[0] = 0;
    }
}

/*##################  TTatsunoProtocolAnalyser::ShowBcdValue ##########################
*   Purpose....: Show a BCD-code value  					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowBcdValue(const char *valstr)
{
    char str[12];
    const char *ptr = valstr;

    str[0] = ((*ptr >> 4) & 0xF) + '0';
    str[1] = (*ptr & 0xF) + '0'; 
    ptr++;
    
    str[2] = ((*ptr >> 4) & 0xF) + '0';
    str[3] = (*ptr & 0xF) + '0'; 
    ptr++;

    str[4] = ((*ptr >> 4) & 0xF) + '0';
    str[5] = (*ptr & 0xF) + '0'; 
    ptr++;

    str[6] = '.';

    str[7] = ((*ptr >> 4) & 0xF) + '0';
    str[8] = (*ptr & 0xF) + '0'; 
    ptr++;
    
//    str[9] = ((*ptr >> 4) & 0xF) + '0';
//    str[10] = (*ptr & 0xF) + '0'; 
//    ptr++;

    str[9] = 0;

    ptr = str;

    while (*ptr == '0')
        ptr++;

    if (*ptr == '.')
        ptr--;

    Write(ptr);
}

/*##################  TTatsunoProtocolAnalyser::ShowValues ##########################
*   Purpose....: Show preset / fill values					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowValues(const char *valstr)
{
    Write("VOL:");
    ShowBcdValue(valstr);
    
    Write(", PRICE:");
    ShowBcdValue(valstr + 5);

    Write(", AMOUNT:");    
    ShowBcdValue(valstr + 10);
}

/*##################  TTatsunoProtocolAnalyser::ShowStxReq ##########################
*   Purpose....: Show STX req					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowStxReq()
{
    if (FStxReq[2] == PRESET_CMD)
        ShowValues(&FStxReq[3]);
}

/*##################  TTatsunoProtocolAnalyser::ShowStxAck ##########################
*   Purpose....: Show STX ack					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowStxAck()
{
    if (FStxAck[2] == FUEL_DATA_CMD)
        ShowValues(&FStxAck[3]);
}

/*##################  TTatsunoProtocolAnalyser::ShowCommand ##########################
*   Purpose....: Show STX command					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowCommand(char cmd)
{
    switch (cmd)
    {
        case FUEL_DATA_CMD:
            Write("FUEL");
            break;

        case QACK_CMD:
            Write("QACK");
            break;

        case PRESET_CMD:
            Write("PRESET");
            break;
    }
}

/*##################  TTatsunoProtocolAnalyser::UpdateStx ##########################
*   Purpose....: Show STX msg req + reply					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::UpdateStx()
{
    if (FStxReq[0] || FStxAck[0])
    {
    	ShowLongTime(FTime);

    	if (FStxReq[0])
	    {
	        ShowCommand(FStxReq[2]);
            ShowAddress(FStxReq[1]);
            ShowStxReq();
        }
        else
        {
	        ShowCommand(FStxAck[2]);
            ShowAddress(FStxAck[1]);            
            Write(" ** NO REQ ** ");
        }

        if (FStxAck[0])
            ShowStxAck();
        else
            Write(" ** NO ANSWER ** ");
                
		Write("\r\n");

		FStxReq[0] = 0;
		FStxAck[0] = 0;
    }
}

/*##################  TTatsunoProtocolAnalyser::ShowEnq ##########################
*   Purpose....: Show ENQ msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowEnq()
{
    UpdateEnq();
    
    if (FLrc == 0)
        memcpy(FEnq, FMsg, 6);
    else
    {
		ShowLongTime(FTime);
        ShowHexMsg();
    }
}

/*##################  TTatsunoProtocolAnalyser::ShowAck ##########################
*   Purpose....: Show ACK msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowAck()
{
    if (FLrc == 0)
    {
		if (FEnq[1] != FMsg[1])
            UpdateEnq();
            
        memcpy(FAck, FMsg, 5);
        UpdateEnq();
    }
    else
    {
        ShowLongTime(FTime);
        ShowHexMsg();
    }
}

/*##################  TTatsunoProtocolAnalyser::ShowStx ##########################
*   Purpose....: Show STX msg       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowStx()
{
    UpdateEnq();

    if (FLrc == 0)
        switch (FMsg[2])
        {
            case FUEL_DATA_CMD:
                if (FSize == 4)
                {
                    UpdateStx();
                    memcpy(FStxReq, FMsg, FSize);
                }
                else
                {
                    if (FStxReq[1] != FMsg[1] || FStxReq[2] != FMsg[2])
                        UpdateStx();

                    memcpy(FStxAck, FMsg, FSize);
                    UpdateStx();
                }
                break;

            case QACK_CMD:
                UpdateStx();
                memcpy(FStxReq, FMsg, FSize);
                UpdateStx();
                break;

            case PRESET_CMD:
                if (FSize == 4)
                {
                    if (FStxReq[1] != FMsg[1] || FStxReq[2] != FMsg[2])
                        UpdateStx();

                    memcpy(FStxAck, FMsg, FSize);
                    UpdateStx();
                }
                else
                {
                    UpdateStx();
                    memcpy(FStxReq, FMsg, FSize);
                }
                break; 

            default:               
            	ShowLongTime(FTime);
	            ShowHexMsg();
	            break;

        }                
    else
    {   
    	ShowLongTime(FTime);
	    ShowHexMsg();
	}
}

/*##################  TTatsunoProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTatsunoProtocolAnalyser::ShowMsg()
{
    switch (FMsg[0])
    {
        case ENQ:
            ShowEnq();
            break;

        case ACK:
            ShowAck();
            break;

		case STX:
			ShowStx();
            break;

        default:
            ShowLongTime(FTime);
        	ShowHexMsg();
        	break;
    }
}

/*##################  TTatsunoProtocolAnalyser::TTatsunoProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TTatsunoProtocolAnalyser::TTatsunoProtocolAnalyser(TFile *RawFile)
  : TProtocolAnalyser(RawFile, 0x100)
{
	FEnq[0] = 0;
	FAck[0] = 0;
	FStxReq[0] = 0;
	FStxAck[0] = 0;
}

/*##################  TTatsunoProtocolAnalyser::~TTatsunoProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TTatsunoProtocolAnalyser::~TTatsunoProtocolAnalyser()
{
}
