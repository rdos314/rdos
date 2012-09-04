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
#include "icsp87x.h"

#define FALSE   0
#define TRUE    !FALSE

#define CMD_LOAD_CONFIG         0x0
#define CMD_LOAD_PROGRAM        0x2
#define CMD_INCR_ADDRESS        0x6
#define CMD_BULK_ERASE1         0x1
#define CMD_BULK_ERASE2         0x7
#define CMD_PROGRAM_ERASE   0x8
#define CMD_PROGRAM_ONLY    0x18

/*##########################################################################
#
#   Name       : TIcsp87X::TIcsp87X
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIcsp87X::TIcsp87X()
{
}

/*##########################################################################
#
#   Name       : TIcsp87X::~TIcsp87X
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIcsp87X::~TIcsp87X()
{
}

/*##########################################################################
#
#   Name       : TIcsp87X::ReadRecord
#
#   Purpose....: Read a single record from hex-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87X::ReadRecord(int *op, int *offset, char *buf)
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
#   Name       : TIcsp87X::SendCmd
#
#   Purpose....: Send ICSP command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87X::SendCmd(int cmd)
{
        RdosWriteICSPCommand(FHandle, cmd);
        RdosWaitMicro(1);
}

/*##########################################################################
#
#   Name       : TIcsp87X::SendCmd
#
#   Purpose....: Send ICSP command & data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87X::SendCmd(int cmd, int data)
{
        RdosWriteICSPCommand(FHandle, cmd);
        RdosWaitMicro(1);
        RdosWriteICSPData(FHandle, data);
        RdosWaitMicro(1);
}

/*##########################################################################
#
#   Name       : TIcsp87X::Erase
#
#   Purpose....: Erase flash chip
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87X::Erase()
{
        SendCmd(CMD_LOAD_PROGRAM, 0x3FFF);
        SendCmd(CMD_BULK_ERASE1);
        SendCmd(CMD_BULK_ERASE2);
        SendCmd(CMD_PROGRAM_ERASE);
        RdosWaitMilli(8);
        SendCmd(CMD_BULK_ERASE1);
        SendCmd(CMD_BULK_ERASE2);
}

/*##########################################################################
#
#   Name       : TIcsp87X::LoadConfig
#
#   Purpose....: Load configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87X::LoadConfig(int data)
{
        int i;

        SendCmd(CMD_LOAD_CONFIG, 0x3FFF);

        for (i = 0; i < 7; i++)
                SendCmd(CMD_INCR_ADDRESS);

        SendCmd(CMD_LOAD_PROGRAM, data);
        SendCmd(CMD_PROGRAM_ERASE);
        RdosWaitMilli(8);

}

/*##########################################################################
#
#   Name       : TIcsp87X::GotoNextAddress
#
#   Purpose....: Goto next chip address
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87X::GotoNextAddress()
{
        SendCmd(CMD_INCR_ADDRESS);
}

/*##########################################################################
#
#   Name       : TIcsp87X::WriteData
#
#   Purpose....: Write data word
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp87X::WriteData(int data)
{
        SendCmd(CMD_LOAD_PROGRAM, data);
        SendCmd(CMD_PROGRAM_ERASE);
        RdosWaitMilli(8);
}

/*##########################################################################
#
#   Name       : TIcsp87X::DoICSP
#
#   Purpose....: Do ICSP programming
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87X::DoICSP()
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

//      Erase(handle);

        while (op != 1)
        {
                size = ReadRecord(&op, &offset, buf);

                if (size && op == 0)
                {
                        size = size / 2;
                        offset = offset / 2;
                        ptr = buf;

                        while (offset > adr)
                        {
                                GotoNextAddress();
                                adr++;
                        }

                        for (i = 0; i < size; i++)
                        {
                                data = 0;
                                memcpy(&data, ptr, 2);
                                WriteData(data);
                                ptr += 2;
                                GotoNextAddress();
                                adr++;
                        }
                }
        }

        return TRUE;
}
