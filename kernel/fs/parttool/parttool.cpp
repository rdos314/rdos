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
# parttool.cpp
# Partition tool server
#
########################################################################*/

#include <rdos.h>
#include <serv.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discpart.h"
#include "mbrdisc.h"
#include "gptdisc.h"

#include "partinfo.h"
#include "discinit.h"
#include "partadd.h"

static TCommandFactory *info;
static TCommandFactory *init;
static TCommandFactory *addp;

static TDisc *Disc = 0;

/*##########################################################################
#
#   Name       : InitDisc
#
#   Purpose....: Init disc object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool InitDisc(TDiscServer *Server, const char *PartType)
{
    Disc = 0;

    if (!strcmp(PartType, "mbr"))
        Disc = new TMbrDisc(Server);

    if (!strcmp(PartType, "gpt"))
        Disc = new TGptDisc(Server);

    if (Disc)
        if (Disc->InitPart())
            return true;

    return false;
}

/*##########################################################################
#
#   Name       : CreateDisc
#
#   Purpose....: Create disc object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisc *CreateDisc(TDiscServer *Server)
{
    char *Buf;
    unsigned char Type;
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, 0, 1);
    TDisc *Disc = 0;

    req.WaitForever();

    Buf = (char *)e1.Map();
    if (Buf)
    {
        Type = Buf[0x1BE + 4];
        if (Type == 0xEE)
            Disc = new TGptDisc(Server);
        else
            Disc = new TMbrDisc(Server);
    }
    return Disc;
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main(int argc, char **argv)
{
    int dev;
    char *ptr;
    TDiscServer *Server;
    int handle;

    if (argc >= 2)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        printf("Part tool %d\r\n", dev);

        Server = new TDiscServer;
        Server->OnInit = InitDisc;

        init = new TInitFactory(Server);
        info = new TInfoFactory(Server);
        addp = new TAddPartitionFactory(Server);

        handle = Server->GetHandle();

        Disc = CreateDisc(Server);
        if (Disc)
        {
            ServInitPartitions(handle);
            Disc->LoadPart();
            ServPartitionsDone(handle);

            while (Server->IsActive())
                Server->Run(Disc);
        }
        else
            ServPartitionsDone(handle);
    }
    else
    {
        handle = ServGetVfsHandle();
        ServPartitionsDone(handle);
    }

}
