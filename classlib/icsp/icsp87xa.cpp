/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# icsp87x.cpp
# ICSP programming of Microship's PIC16F87x. Requires a device-driver that
# implements the ICSP related functions
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "icsp87xa.h"

#define FALSE	0
#define	TRUE	!FALSE

#define CMD_LOAD_CONFIG		0x0
#define CMD_LOAD_PROGRAM	0x2
#define CMD_READ_PROGRAM	0x4
#define CMD_INCR_ADDRESS	0x6
#define CMD_CHIP_ERASE		0x1F
#define CMD_PROGRAM_ERASE   0x8
#define CMD_PROGRAM_ONLY    0x18
#define CMD_END_PROGRAM		0x17

/*##########################################################################
#
#   Name       : TIcsp87Xa::TIcsp87Xa
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIcsp87Xa::TIcsp87Xa()
{
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::~TIcsp87Xa
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIcsp87Xa::~TIcsp87Xa()
{
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::ReadRecord
#
#   Purpose....: Read a single record from hex-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87Xa::ReadRecord(int *op, int *offset, char *buf)
{
	char ch;
	char str[10];
	int size;
	char *ptr;
	int i;
	int val;

	*offset = 0;
	*op = 1;
	size = 0;

	ch = ' ';

	while (ch != ':')
	{
		if (FFile->Read(&ch, 1) == 0)
		{
			Info("Unexpected end of hex-file\r\n");
			return 0;
		}
	}

	FFile->Read(str, 8);
	str[8] = 0;

	if (sscanf(str, "%2hX%4hX%2hX", &size, offset, op) == 3)
	{
		if (*op == 0)
		{
			ptr = buf;
			for (i = 0; i < size; i++)
			{
				val = 0;
				FFile->Read(str, 2);
				if (sscanf(str, "%2hX", &val) == 1)
					*ptr = (char)val;
				else
				{
					Info("Data error in hex-file\r\n");
					*op = 1;
					return 0;
				}
				ptr++;
			}
			return size;
		}
		else
			return 0;
	}
	else
	{
		*op = 1;
		Info("Format error in hex-file\r\n");
	}

	return 0;
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::SendCmd
#
#   Purpose....: Send ICSP command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87Xa::SendCmd(int cmd)
{
	RdosWriteICSPCommand(FHandle, cmd);
	RdosWaitMicro(1);
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::SendCmd
#
#   Purpose....: Send ICSP command & data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87Xa::SendCmd(int cmd, int data)
{
	RdosWriteICSPCommand(FHandle, cmd);
	RdosWaitMicro(1);
	RdosWriteICSPData(FHandle, data);
	RdosWaitMicro(1);
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::ReadCmd
#
#   Purpose....: Read ICSP command & data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87Xa::ReadCmd(int cmd)
{
    int data = 0;
    
	RdosWriteICSPCommand(FHandle, cmd);
	RdosWaitMicro(1);
	RdosReadICSPData(FHandle, &data);
	RdosWaitMicro(1);

	return data;
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::DoProgram
#
#   Purpose....: Do ICSP programming
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87Xa::DoProgram()
{
	int op;
	int offset;
	int size;
	char buf[256];
	int data;
	int i;
	char *ptr;
	int adr;
	int ok;
	int val;

	adr = 0;
	op = 0;

	FInConfig = FALSE;

	while (op != 1)
	{
		size = ReadRecord(&op, &offset, buf);

		if (size && op == 0)
		{
			size = size / 2;
			offset = offset / 2;
			ptr = buf;

			if (offset >= 0x2000 && !FInConfig)
			{
				SendCmd(CMD_LOAD_CONFIG, 0x3FFF);
				adr = 0x2000;
				FInConfig = TRUE;
			}

			while (offset > adr)
			{
				SendCmd(CMD_INCR_ADDRESS);
				adr++;
			}

			if ((offset & 7) == 0)
			{
			    ok = TRUE;

                for (i = 0; i < size && ok; i++)
                {
					data = 0;
					memcpy(&data, ptr, 2);
                    val = ReadCmd(CMD_READ_PROGRAM);

                    if (val == data)
                    {
    				    SendCmd(CMD_INCR_ADDRESS);

	    				ptr += 2;
		    			adr++;
		    	    }
		    	    else
		    	        ok = FALSE;
                }

                if (!ok)
                {
                	RdosResetICSP(FHandle);
    				RdosWaitMilli(25);
                	adr = 0;
        			ptr = buf;
                            
        			while (offset > adr)
		        	{
				        SendCmd(CMD_INCR_ADDRESS);
        				adr++;
		        	}
			
    				for (i = 0; i < 8; i++)
	    			{
		    			data = 0;
		    			if (i < size)
    			    		memcpy(&data, ptr, 2);

				    	SendCmd(CMD_LOAD_PROGRAM, data);
    					if (i != 7)
	    					SendCmd(CMD_INCR_ADDRESS);
    
	    				ptr += 2;
		    			adr++;
			    	}
				    SendCmd(CMD_PROGRAM_ERASE);
    				RdosWaitMilli(25);
	    			SendCmd(CMD_END_PROGRAM);
		    		SendCmd(CMD_INCR_ADDRESS);
			    }
			}
			else
			{
				for (i = 0; i < size; i++)
				{
					data = 0;
					memcpy(&data, ptr, 2);
					SendCmd(CMD_LOAD_PROGRAM, data);

					if (FInConfig)
						SendCmd(CMD_PROGRAM_ERASE);
					else
						SendCmd(CMD_PROGRAM_ONLY);

					RdosWaitMilli(1);
					SendCmd(CMD_END_PROGRAM);
					SendCmd(CMD_INCR_ADDRESS);

					ptr += 2;
					adr++;
				}
			}
		}
	}

	return TRUE;
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::DoChipErase
#
#   Purpose....: Do chip erase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87Xa::DoChipErase()
{
	SendCmd(CMD_CHIP_ERASE);
	RdosWaitMilli(100);
	return TRUE;
}

/*##########################################################################
#
#   Name       : TIcsp87Xa::DoVerify
#
#   Purpose....: Do ICSP verify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87Xa::DoVerify()
{
	int op;
	int offset;
	int size;
	char buf[256];
	int data;
	int i;
	char *ptr;
	int adr;
	int val;

	adr = 0;
	op = 0;

	FInConfig = FALSE;

	while (op != 1)
	{
		size = ReadRecord(&op, &offset, buf);

		if (size && op == 0)
		{
			size = size / 2;
			offset = offset / 2;
			ptr = buf;

			if (offset >= 0x2000 && !FInConfig)
			{
				SendCmd(CMD_LOAD_CONFIG, 0x3FFF);
				adr = 0x2000;
				FInConfig = TRUE;
			}

			while (offset > adr)
			{
				SendCmd(CMD_INCR_ADDRESS);
				adr++;
			}

		    for (i = 0; i < size; i++)
			{
				data = 0;
				memcpy(&data, ptr, 2);
				val = ReadCmd(CMD_READ_PROGRAM);

                if (val != data)
                    return FALSE;

    			SendCmd(CMD_INCR_ADDRESS);

	    		ptr += 2;
		    	adr++;
            }
		}
	}

	return TRUE;
}
