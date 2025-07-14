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
# convserv.cpp
# Convert server gates to C include files
#
########################################################################*/

#include <stdio.h>
#include <file.h>
#include <string.h>

#define MAX_SERV_SIZE   0x10000

int main()
{
    char Buffer[MAX_SERV_SIZE];
    char GateName[256];
    int GateId;
    char Macro[256];
    int Size;
    char *ptr;
    char *next;
    TFile InFile("serv.def");
    TFile OutFile("rds.h", 0);

    Size = InFile.Read(Buffer, MAX_SERV_SIZE);
    Buffer[Size] = 0;

    ptr = Buffer;
    next = strchr(ptr, 0xd);

    while (next)
    {
        if (*next == 0xd)
        {
            *next = 0;
            next++;
        }

        if (*next == 0xa)
        {
            *next = 0;
            next++;
        }

        if (strchr(ptr, '='))
        {
            if (sscanf(ptr, "%s = %d", GateName, &GateId) == 2)
            {
                if (strcmp(GateName, "serv_gate_entries") != 0)
                {
                    Size = strlen(GateName);

                    if (GateName[Size - 1] == 'r')
                        GateName[Size - 1] = 0;

                    if (GateName[Size - 2] == 'n')
                        GateName[Size - 2] = 0;

                    if (GateName[Size - 3] == '_')
                        GateName[Size - 3] = 0;

                    sprintf(Macro, "#define serv_gate_%s 0x%08hX\r\n",
                            GateName,
                            GateId);

                    OutFile.Write(Macro);
                }
            }
        }
        else
            OutFile.Write("\r\n");

        ptr = next;
        next = strchr(ptr, 0xd);
    }

    InFile.SetPos(0);
    Size = InFile.Read(Buffer, MAX_SERV_SIZE);
    Buffer[Size] = 0;

    ptr = Buffer;
    next = strchr(ptr, 0xd);

    while (next)
    {
        if (*next == 0xd)
        {
            *next = 0;
            next++;
        }

        if (*next == 0xa)
        {
            *next = 0;
            next++;
        }

        if (strchr(ptr, '='))
        {
            if (sscanf(ptr, "%s = %d", GateName, &GateId) == 2)
            {
                if (strcmp(GateName, "serv_gate_entries") != 0)
                {
                    Size = strlen(GateName);

                    if (GateName[Size - 1] == 'r')
                        GateName[Size - 1] = 0;

                    if (GateName[Size - 2] == 'n')
                        GateName[Size - 2] = 0;

                    if (GateName[Size - 3] == '_')
                        GateName[Size - 3] = 0;

                    sprintf(Macro, "#define ServGate_%s 0x55 0x67 0x9a %d %d %d %d 4 0 0x5d\r\n",
                            GateName,
                            GateId & 0xFF,
                            (GateId >> 8) & 0xFF,
                            (GateId >> 16) & 0xFF,
                            (GateId >> 24) & 0xFF);
                    OutFile.Write(Macro);
                }
            }
        }
        else
        {
            OutFile.Write("\r\n");
        }

        ptr = next;
        next = strchr(ptr, 0xd);
    }

    return 0;
}
