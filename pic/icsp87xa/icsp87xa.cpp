/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# icsp87x.cpp
# ICSP programming of Microship's PIC16F87x. Requires a device-driver that
# implements the ICSP related functions
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "file.h"

#define FALSE	0
#define	TRUE	!FALSE

#define CMD_LOAD_CONFIG		0x0
#define CMD_LOAD_PROGRAM	0x2
#define CMD_INCR_ADDRESS	0x6
#define CMD_CHIP_ERASE		0x1F
#define CMD_PROGRAM_ERASE   0x8
#define CMD_PROGRAM_ONLY    0x18
#define CMD_END_PROGRAM		0x17

int InConfig;

/*##########################################################################
#
#   Name       : ReadRecord
#
#   Purpose....: Read a single record from hex-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int ReadRecord(TFile &file, int *op, int *offset, char *buf)
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
		if (file.Read(&ch, 1) == 0)
		{
			printf("Unexpected end of hex-file\r\n");
			return 0;
		}
	}

	file.Read(str, 8);
	str[8] = 0;

	if (sscanf(str, "%2hX%4hX%2hX", &size, offset, op) == 3)
	{
		if (*op == 0)
		{
			ptr = buf;
			for (i = 0; i < size; i++)
			{
				val = 0;
				file.Read(str, 2);
				if (sscanf(str, "%2hX", &val) == 1)
					*ptr = (char)val;
				else
				{
					printf("Data error in hex-file\r\n");
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
		printf("Format error in hex-file\r\n");
	}

	return 0;
}

/*##########################################################################
#
#   Name       : SendCmd
#
#   Purpose....: Send ICSP command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SendCmd(int handle, int cmd)
{
	RdosWriteICSPCommand(handle, cmd);
	RdosWaitMicro(1);
}

/*##########################################################################
#
#   Name       : SendCmd
#
#   Purpose....: Send ICSP command & data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SendCmd(int handle, int cmd, int data)
{
	RdosWriteICSPCommand(handle, cmd);
	RdosWaitMicro(1);
	RdosWriteICSPData(handle, data);
	RdosWaitMicro(1);
}

/*##########################################################################
#
#   Name       : LoadConfig
#
#   Purpose....: Load configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LoadConfig(int handle, int data)
{
	int i;


	for (i = 0; i < 7; i++)
		SendCmd(handle, CMD_INCR_ADDRESS);

	SendCmd(handle, CMD_LOAD_PROGRAM, data);
	SendCmd(handle, CMD_PROGRAM_ERASE);
	RdosWaitMilli(8);
	SendCmd(handle, CMD_END_PROGRAM);
}

/*##########################################################################
#
#   Name       : DoICSP
#
#   Purpose....: Do ICSP programming
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DoICSP(int handle, TFile &file)
{
	int op;
	int offset;
	int size;
	char buf[256];
	int data;
	int i;
	char *ptr;
	int adr;

	adr = 0;
	op = 0;

	SendCmd(handle, CMD_CHIP_ERASE);
	RdosWaitMilli(8);

	while (op != 1)
	{
		size = ReadRecord(file, &op, &offset, buf);

		if (size && op == 0)
		{
			size = size / 2;
			offset = offset / 2;
			ptr = buf;

			if (offset >= 0x2000 && !InConfig)
			{
				SendCmd(handle, CMD_LOAD_CONFIG, 0x3FFF);
				adr = 0x2000;
				InConfig = TRUE;
			}

			while (offset > adr)
			{
				SendCmd(handle, CMD_INCR_ADDRESS);
				adr++;
			}

			if ((offset & 7 == 0) && size == 8)
			{
				for (i = 0; i < 8; i++)
				{
					data = 0;
					memcpy(&data, ptr, 2);
					SendCmd(handle, CMD_LOAD_PROGRAM, data);
					if (i != 7)
						SendCmd(handle, CMD_INCR_ADDRESS);

					ptr += 2;
					adr++;
				}
				SendCmd(handle, CMD_PROGRAM_ERASE);
				RdosWaitMilli(8);
				SendCmd(handle, CMD_END_PROGRAM);
				SendCmd(handle, CMD_INCR_ADDRESS);
			}
			else
			{
				for (i = 0; i < size; i++)
				{
					data = 0;
					memcpy(&data, ptr, 2);
					SendCmd(handle, CMD_LOAD_PROGRAM, data);
					SendCmd(handle, CMD_PROGRAM_ONLY);
					RdosWaitMilli(1);
					SendCmd(handle, CMD_END_PROGRAM);
					SendCmd(handle, CMD_INCR_ADDRESS);

					ptr += 2;
					adr++;
				}
			}
		}
	}
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Entry point
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main(int argc, char **argv)
{
	char DeviceStr[256];
	char FileName[256];
	int id;
	int handle;

	if (argc != 3)
	{
		printf("usage: icsp87x device-id hex-filename\r\n");
		return 1;
	}

	RdosWaitMilli(250);

	strcpy(DeviceStr, argv[1]);

	strcpy(FileName, argv[2]);
	strlwr(FileName);

	TFile file(FileName);

	InConfig = FALSE;

	if (file.IsOpen())
	{
		id = atoi(DeviceStr);

		if (id > 0)
			handle = RdosOpenICSP(id);
		else
			handle = 0;

		if (handle)
		{
			DoICSP(handle, file);
			RdosCloseICSP(handle);
		}
		else
			printf("Invalid device-id or no ICSP available\r\n");
	}
	else
		printf("File not found\r\n");

	return 0;
}
