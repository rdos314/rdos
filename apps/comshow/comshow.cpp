#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

struct TComMsg
{
	int Channel;
	int TimeLSB;
	int TimeMSB;
	char ch;
};

struct TCbusMsg
{
	char Adr;
	char MessCode;
	char MsgTime[80];
	char MsgCode[80];
	char MsgData[128];
};

int FileHandle = 0;

TCbusMsg *CbusReqMsg = 0;
TCbusMsg *CbusReplyMsg = 0;

/* Macro to convert an ascii hex-value ('0' - 'F') to a binary value (0 - 15) */
#define     HexBin1(x)      (((x) >= 'A') ? (((x) - 'A' + 10) & 0x0f) : (((x) - '0') & 0x0f))
#define     HexBin2(x)      (((x) >= 'A') ? ((((x) - 'A' + 10) & 0x0f) << 4 ) : ((((x) - '0') & 0x0f) << 4 ))

/* Macro to convert a binary value (0 - 15) to an ascii hex-value ('0' - 'F') */
#define     BinHex1(x)      ((((x) & 0xf) > 9) ? (((x) & 0xf) + 'A' - 10) : (((x) & 0xf) + '0'))
#define     BinHex2(x)      (((((x) >> 4) & 0xf) > 9) ? ((((x) >> 4) & 0xf) + 'A' - 10) : ((((x) >> 4) & 0xf) + '0'))

/*##################  HexToBinaryByte          ##########################
*   Purpose....: Primitive for hex_to_binary_byte and fast in-line function #
*                to be used internally in module.                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 95-11-13 an                                                #
*                All code from old hex_to_binary_byte() (by JS).            #
*##########################################################################*/
static int HexToBinaryByte(const char ConvertStr[])
{
	unsigned char a;
	unsigned char b;

	a = ConvertStr[0];

	/* if check that chars are 0 - 9 or A - F use these tests 	*/
	/* and make a and b and return value int					*/

	if ((a < '0' || a > 'F') || (a > '9' && a < 'A'))
		return (-1000);
	else
	{
		if (a > '9')
			a -= 'A' - 0xA;
		else
			a -= '0';
	}

	b = ConvertStr[1];

	if ((b < '0' || b > 'F') || (b > '9' && b < 'A'))
		return (-1000);
	else
	{
		if (b > '9')
			b -= 'A' - 0xA;
		else
			b -= '0';
	}

	return ((a << 4) | b);
}

/*##################  BccCalc  ##########################
*   Purpose....: TO CREATE A BCC CHECK SUM STRING					        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
static void BccCalc(const char *indata, char *bcc, int len )
{
	int value;
	int i;
	int temp;

	value = 0;
	for (i = 1; i <= len; i++)
	{
		temp = (int)*indata;
		value ^= temp;
		indata++;
	};
	bcc[0]	= (char)BinHex2(value);
	bcc[1] = (char)BinHex1(value);
}

/*##################  FormatLongTime ##########################
*   Purpose....: Format long time string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void FormatLongTime(char *str, TComMsg *Msg)
{
	int year, month, day;
	int hour, min, sec, milli;

	RdosConvertTics(Msg->TimeMSB, Msg->TimeLSB, &year, &month, &day, &hour, &min, &sec, &milli);
	sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d,%03d", year, month, day, hour, min, sec, milli);
}

/*##################  Write ##########################
*   Purpose....: Write a string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void Write(const char *str)
{
	printf(str);
	if (FileHandle)
		RdosWriteFile(FileHandle, str, strlen(str));
}

/*##################  FormatShortTime ##########################
*   Purpose....: Format short time string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void FormatShortTime(char *str, TComMsg *Msg)
{
	int year, month, day;
	int hour, min, sec, milli;

	RdosConvertTics(Msg->TimeMSB, Msg->TimeLSB, &year, &month, &day, &hour, &min, &sec, &milli);
	sprintf(str, "%02d.%02d.%02d,%03d", hour, min, sec, milli);
}

/*##################  GetMsg ##########################
*   Purpose....: Get next message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int GetMsg(char *str, TComMsg *Msg, int count)
{
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	int used;

	if (count == 0)
		return 0;

	used = 0;
	Channel = Msg->Channel;
	LastTime = Msg->TimeLSB;
	ch = Msg->ch;
	used++;
	Msg++;

	*str = 0;

	while (count > used)
	{
		*str = ch;
		str++;
		*str = 0;

		if (Channel != Msg->Channel)
			return used;

		Elapsed = Msg->TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
			return used;

		LastTime = Msg->TimeLSB;
		ch = Msg->ch;
		used++;
		Msg++;
	}

	return used;
}

/*##################  GetCbusMsg ##########################
*   Purpose....: Get next CBUS message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int GetCbusMsg(char *str, TComMsg *Msg, int count)
{
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	int used;

	if (count == 0)
		return 0;

	used = 0;
	Channel = Msg->Channel;
	LastTime = Msg->TimeLSB;
	ch = Msg->ch;
	used++;
	Msg++;

	*str = 0;

	while (count > used && ch != ':')
	{
		if (Channel != Msg->Channel)
			return used;

		Elapsed = Msg->TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
			return used;

		LastTime = Msg->TimeLSB;
		ch = Msg->ch;
		used++;
		Msg++;
	}

	while (count > used && ch != '\r')
	{
		*str = ch;
		str++;
		*str = 0;

		if (Channel != Msg->Channel)
			return used;
		
		Elapsed = Msg->TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
			return used;

		LastTime = Msg->TimeLSB;
		ch = Msg->ch;
		used++;
		Msg++;
	}

	return used;
}

/*##################  GetDefault ##########################
*   Purpose....: Get default CBUS pump msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void GetDefault(char *str, TCbusMsg *Msg)
{
	sprintf(str, "%02X <%s>", Msg->MessCode, Msg->MsgData);
}

/*##################  GetCbusPumpReqText ##########################
*   Purpose....: Get cbus pump req text	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void GetCbusPumpReqText(char *str)
{
	int MaxPulses;
	int MaxAmount;
	int Price0;
	int Price1;
	int Price2;

	switch (CbusReqMsg->MessCode)
	{
		case 0x51:
			if (strlen(CbusReqMsg->MsgData) == 1)
				switch (CbusReqMsg->MsgData[0])
				{
					case '0':
						strcpy(str, "Stop");
						break;

					case '1':
						strcpy(str, "Start");
						break;

					default:
						GetDefault(str, CbusReqMsg);
						break;
				}
			else
				GetDefault(str, CbusReqMsg);
			break;

		case 0x53:
			if (sscanf(	CbusReqMsg->MsgData,
						"%06d%06d%04d%04d%04d",
						&MaxPulses,
						&MaxAmount,
						&Price0,
						&Price1,
						&Price2) == 5)
				sprintf(	str,
							"Max vol=%d, Max amount=%d, Price1=%03d, Price2=%03d, Price3=%03d",
							MaxPulses,
							MaxAmount,
							Price0,
							Price1,
							Price2);
			else
				GetDefault(str, CbusReqMsg);
			break;

		case 0x55:
			str[0] = 0;
			break;

		case 0x57:
			str[0] = 0;
			break;

		default:
			GetDefault(str, CbusReqMsg);
			break;
	}

	delete CbusReqMsg;
	CbusReqMsg = 0;
}

/*##################  GetCbusPumpReplyText ##########################
*   Purpose....: Get cbus pump reply text	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void GetCbusPumpReplyText(char *str)
{
	int data;
	char ErrorMsg[32];
	int Pulses;
	int Amount;
	int FillGrade;
	int Price;

	switch (CbusReplyMsg->MessCode)
	{
		case 0x51:
		case 0x52:
			if (strlen(CbusReplyMsg->MsgData) == 4)
			{
				data = HexToBinaryByte(&CbusReplyMsg->MsgData[0]);
				if (data & 1)
					strcpy(str, "Lifted");
				else
					strcpy(str, "Not lifted");

				if (data & 2)
					strcat(str, ", Fuel on");

				switch ((data >> 2) & 3)
				{
					case 0:
						strcat(str, ", Idle");
						break;

					case 1:
						strcat(str, ", Fill");
						break;

					case 2:
						strcat(str, ", Fill-end");
						break;
				}

				data = HexToBinaryByte(&CbusReplyMsg->MsgData[2]);
				if (data)
				{
					sprintf(ErrorMsg, ", Error=%02X", data);
					strcat(str, ErrorMsg);
				}
			}
			else
				GetDefault(str, CbusReplyMsg);
			break;

		case 0x53:
		case 0x54:
			str[0] = 0;
			break;

		case 0x55:
		case 0x56:
			if (sscanf(	CbusReplyMsg->MsgData,
						"%6d %6d %1d %4d",
						&Pulses,
						&Amount,
						&FillGrade,
						&Price) == 4)
				sprintf(str, "Vol=%d, Amount=%d, Prod=%d, Price=%03d",
						Pulses,
						Amount,
						FillGrade,
						Price);
			else
				GetDefault(str, CbusReplyMsg);
			break;

		case 0x57:
		case 0x58:
			str[0] = 0;
			break;

		default:
			GetDefault(str, CbusReplyMsg);
			break;
	}

	delete CbusReplyMsg;
	CbusReplyMsg = 0;
}

/*##################  UpdateCbusPump ##########################
*   Purpose....: Update CBUS pump msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void UpdateCbusPump()
{
	char MsgTime[256];
	char MsgCode[256];
	char DispMess[256];
	char ReqText[256];
	char ReplyText[256];
	char Adr;

	MsgTime[0] = 0;

	if (CbusReqMsg || CbusReplyMsg)
	{
		if (CbusReqMsg)
		{
			Adr = CbusReqMsg->Adr;
			strcpy(MsgTime, CbusReqMsg->MsgTime);
			strcpy(MsgCode, CbusReqMsg->MsgCode);
			GetCbusPumpReqText(ReqText);
		}
		else
			strcpy(ReqText, "*** NO REQ ***");

		if (CbusReplyMsg)
		{
			if (MsgTime[0] == 0)
			{
				Adr = CbusReplyMsg->Adr;
				strcpy(MsgTime, CbusReplyMsg->MsgTime);
				strcpy(MsgCode, CbusReplyMsg->MsgCode);
			}
			GetCbusPumpReplyText(ReplyText);
		}
		else
			strcpy(ReplyText, "*** NO ANSWER ***");

		sprintf(DispMess, "%s %02X %s %s %s\r\n",
						MsgTime,
						Adr,
						MsgCode,
						ReqText,
						ReplyText);
		Write(DispMess);

	}
}

/*##################  DecodeCbusPump ##########################
*   Purpose....: Decode CBUS pump msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void DecodeCbusPump(const char *TimeStr, char ToAdr, char FromAdr, char MessCode, const char *MsgData)
{
	char DispMess[256];
	char MessText[80];
	TCbusMsg *CbusMsg;

	CbusMsg = new TCbusMsg;
	CbusMsg->MessCode = MessCode;

	switch (MessCode)
	{
		case 0x51:
			strcpy(CbusMsg->MsgCode, "POLL");
			CbusMsg->Adr = FromAdr;
			break;

		case 0x52:
			strcpy(CbusMsg->MsgCode, "POLL");
			CbusMsg->Adr = ToAdr;
			break;

		case 0x53:
			strcpy(CbusMsg->MsgCode, "PRESET");
			CbusMsg->Adr = FromAdr;
			break;

		case 0x54:
			strcpy(CbusMsg->MsgCode, "PRESET");
			CbusMsg->Adr = ToAdr;
			break;

		case 0x55:
			strcpy(CbusMsg->MsgCode, "DATA");
			CbusMsg->Adr = FromAdr;
			break;

		case 0x56:
			strcpy(CbusMsg->MsgCode, "DATA");
			CbusMsg->Adr = ToAdr;
			break;

		case 0x57:
			strcpy(CbusMsg->MsgCode, "END");
			CbusMsg->Adr = FromAdr;
			break;

		case 0x58:
			strcpy(CbusMsg->MsgCode, "END");
			CbusMsg->Adr = ToAdr;
			break;

		default:
			sprintf(CbusMsg->MsgCode, "%02X", MessCode);
			if (MessCode & 1)
				CbusMsg->Adr = FromAdr;
			else
				CbusMsg->Adr = ToAdr;
			break;
	}

	strcpy(CbusMsg->MsgTime, TimeStr);
	strcpy(CbusMsg->MsgData, MsgData);
	if (MessCode & 1)
	{
		if (CbusReqMsg)
			UpdateCbusPump();
		CbusReqMsg = CbusMsg;
	}
	else
	{
		if (CbusReplyMsg)
			UpdateCbusPump();
		CbusReplyMsg = CbusMsg;
		UpdateCbusPump();
	}
}

/*##################  DecodeCbusMsg ##########################
*   Purpose....: Decode CBUS msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void DecodeCbusMsg(const char *TimeStr, const char *str)
{
	int Len;
	int MsgLen;
	char Bcc[2];
	char DispMess[256];
	char MsgData[256];
	char ToAdr;
	char FromAdr;
	char MessCode;

	DispMess[0] = 0;

	MsgLen = strlen(str);

	if (MsgLen >= 9 + 2)
	{
		Len = HexBin2(*(str+7)) + HexBin1(*(str+8));
		MsgLen -= 9 + 2;
		if (Len == MsgLen)
		{
			BccCalc(str+1, Bcc, 8 + Len);
			if (*(str+Len+9) == Bcc[0] && *(str+Len+10) == Bcc[1])
			{
				FromAdr = HexBin2(*(str+1)) + HexBin1(*(str+2));
				ToAdr = HexBin2(*(str+3)) + HexBin1(*(str+4));
				MessCode = HexBin2(*(str+5)) + HexBin1(*(str+6));
				memcpy(MsgData, str+9, Len);
				MsgData[Len] = 0;
				if (MessCode >= 0x50 && MessCode < 0x60)
					DecodeCbusPump(TimeStr, ToAdr, FromAdr, MessCode, MsgData);
				else
					sprintf(DispMess, "%s %02hX->%02hX %02hX <%s>\r\n", TimeStr, ToAdr, FromAdr, MessCode, MsgData);
			}
			else
				sprintf(DispMess, "%s Wrong checksum <%s>\r\n", TimeStr, str);
		}
		else
			sprintf(DispMess, "%s Size mismatch <%s>\r\n", TimeStr, str);
	}
	else
	{
		if (MsgLen)
			sprintf(DispMess, "%s Too short <%s>\r\n", TimeStr, str);
	}

	if (DispMess[0])
	{
		UpdateCbusPump();
		Write(DispMess);
	}
}

/*##################  DecodeHexMsg ##########################
*   Purpose....: Decode HEX msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void DecodeHexMsg(const char *TimeStr, const char *str, int count)
{
	char tempstr[15];
	int i;
	char ch;

	Write(TimeStr);
	Write("  ");
	for (i = 0; i < count; i++)
	{
		ch = *str;
		if (ch >= 0x20)
			sprintf(tempstr, "%c", ch);
		else
			sprintf(tempstr, " <%02X> ", ch);
		Write(tempstr);
		str++;
	}
	Write("\r\n");
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
	int remains;
	int count;
	int ok;
	int pos;
	char Str[40];
	char MsgText[4192];
	int Mapping;
	char *Buf;
	int *BufSize;
	TComMsg *BufMsg;

	RdosWaitMilli(200);
	Mapping = RdosOpenNamedMapping("comlog");
	Buf = (char *)RdosAllocateMem(0x200000);
	BufSize = (int *)Buf;
	BufMsg = (TComMsg *)(Buf + 4);
	RdosMapView(Mapping, 0, Buf, 0x200000);

	FileHandle = RdosCreateFile("c:\\comshow.log", 0);

	if (BufSize)
	{
		FormatLongTime(Str, BufMsg);
		sprintf(MsgText, "Start time: %s\r\n", Str);
		Write(MsgText);
	}

	pos = 0;

	for (;;)
	{
		while (!RdosPollKeyboard())
		{
			FormatShortTime(Str, BufMsg);
			remains = *BufSize - pos;
			count = GetMsg(MsgText, BufMsg, remains);
			ok = (remains != count);

			if (ok)
				ok = (count != 0);

			if (ok)
			{
				BufMsg += count;
				pos += count;
				DecodeHexMsg(Str, MsgText, count);
			}
			else
				RdosWaitMilli(50);
		}

		if ((RdosReadKeyboard() & 0xFF) == 0x1B)
		{
			RdosCloseFile(FileHandle);
			exit(0);
		}
	}
}

