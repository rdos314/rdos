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
#   Name       : TIcsp87X::DoProgram
#
#   Purpose....: Do ICSP programming
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp87X::DoProgram()
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
