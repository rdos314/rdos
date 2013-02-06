/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# hdcodec.c
# HD Audio Codec device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

extern void InitHda();
extern void InitPciHda();

extern int GetFunctionCount();
#pragma aux GetFinctionCount value [eax]

extern void StartFunction(int id);
#pragma aux StartFunction parm routine [ebx]

extern int GetCodecMask(int id);
#pragma aux GetCodecMask parm routine [ebx] value [eax]

extern int QueryCodec(int id, int codec, int node, int data);
#pragma aux QueryCodec parm routine [ebx] [esi] [edi] [edx] value [eax]

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

#define MAX_FUNCTIONS     16
#define MAX_CODECS        14

struct TCodec
{
    int Address;
};

struct TFunction
{
    int Id;
    int CodecCount;
    struct TCodec *CodecArr[MAX_CODECS];    
};

static int FunctionCount = 0;
static struct TFunction *FunctionArr[MAX_FUNCTIONS];

void __far ImplTestGate(const char *msg)
{
    int val = QueryCodec(0, 0, 0, 0xF0004);
}

/*##########################################################################
#
#   Name       : AddFunction
#
#   Purpose....: Add a new function
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddFunction(int Id, int CodecMask)
{
    struct TFunction *function;
    struct TCodec *codec;
    int count;
    int m;
    int i;

    function = (struct TFunction*)RdosAllocateSmallGlobalMem(sizeof(struct TFunction));
    function->Id = Id;
    function->CodecCount = 0;

    for (i = 0; i < MAX_CODECS; i++)
        function->CodecArr[i] = 0;

    m = 1;    

    for (i = 0; i < MAX_CODECS; i++)
    {
        if (m & CodecMask)
        {
            codec = (struct TCodec*)RdosAllocateSmallGlobalMem(sizeof(struct TCodec));
            codec->Address = i;
            function->CodecArr[function->CodecCount] = codec;
            function->CodecCount++;
        }
        m = m << 1;
    }

    FunctionArr[FunctionCount] = function;
    FunctionCount++;    
}

/*##########################################################################
#
#   Name       : Start
#
#   Purpose....: Start all functions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Start()
{
    int i;
    int count = GetFunctionCount();
    int mask;

    for (i = 0; i < count; i++)
        StartFunction(i);

    for (i = 0; i < count; i++)
    {
        mask = GetCodecMask(i);
        if (mask)
            AddFunction(i, mask);
    }            
}
    
/*##########################################################################
#
#   Name       : HdaThread
#
##########################################################################*/
#pragma aux HdaThread "*" rdosdev parm routine [es edi]
void __far HdaThread(void *param)
{
    Start();
    
    for (;;)
    {
        RdosWaitMilli(250);
    }
}

/*##########################################################################
#
#   Name       : InitPci
#
#   Purpose....: Init PCI callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitPci "*" rdosdev parm routine
void __far InitPci()
{
    InitPciHda();
    RdosCreateKernelThread(5, 0x1000, &HdaThread, "HDA", 0);
} 

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    RdosHookInitPci(&InitPci);
    InitHda();
    RdosRegisterBimodalUserGate(usergate_test_gate, &ImplTestGate, "Test Gate"); 
}
