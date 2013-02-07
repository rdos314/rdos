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

#define FALSE   0
#define TRUE  !FALSE

#define MAX_FUNCTIONS       16
#define MAX_CODECS          14
#define MAX_GROUPS          16
#define MAX_WIDGETS         256
#define MAX_CONNECTIONS     64

#define WIDGET_TYPE_OUTPUT      1
#define WIDGET_TYPE_INPUT       2
#define WIDGET_TYPE_MIXER       3
#define WIDGET_TYPE_SELECTOR    4
#define WIDGET_TYPE_PIN         5
#define WIDGET_TYPE_POWER       6

struct TWidget
{
    int Type;
    int Id;
    int Address;
    int Node;
};

struct TAudioOutput
{
    int Type;
    int Id;
    int Address;
    int Node;

    struct TAudioOutput *List;
    int Cap;
    int Channels;
};

struct TAudioInput
{
    int Type;
    int Id;
    int Address;
    int Node;

    struct TAudioInput *List;
    int Cap;
    int Channels;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TAudioMixer
{
    int Type;
    int Id;
    int Address;
    int Node;

    struct TAudioMixer *List;
    int Cap;
    int Channels;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TAudioSelector
{
    int Type;
    int Id;
    int Address;
    int Node;

    struct TAudioSelector *List;
    int Cap;
    int Channels;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TPinComplex
{
    int Type;
    int Id;
    int Address;
    int Node;

    struct TPinComplex *List;
    int Cap;
    int Channels;
    int PinCap;
    int Connectivity;
    int Location;
    int ConnType;
    int Color;
    int Misc;
    int Association;
    int Sequence;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TPowerWidget
{
    int Type;
    int Id;
    int Address;
    int Node;

    struct TPowerWidget *List;
    int Cap;
    int Channels;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TCodec
{
    int Id;
    int Address;
    int AudioNode;
    struct TAudioOutput *AudioOutputList;
    struct TAudioInput *AudioInputList;
    struct TAudioMixer *AudioMixerList;
    struct TAudioSelector *AudioSelectorList;
    struct TPowerWidget *PowerWidgetList;
    struct TPinComplex *LineOutList;
    struct TPinComplex *LineInList;
    struct TPinComplex *SpeakerList;
    struct TPinComplex *HpOutList;
    struct TPinComplex *CdList;
    struct TPinComplex *AuxList;
    struct TPinComplex *MicList;
};

struct TFunction
{
    int Id;
    int CodecCount;
    struct TCodec *CodecArr[MAX_CODECS];    
};

static int FunctionCount = 0;
static struct TFunction *FunctionArr[MAX_FUNCTIONS];

/*##########################################################################
#
#   Name       : Query
#
#   Purpose....: Do a query
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int Query(struct TCodec *codec, int node, int verb)
{
    return QueryCodec(codec->Id, codec->Address, node, verb);
}

/*##########################################################################
#
#   Name       : GetParam
#
#   Purpose....: Get a parameter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetParam(struct TCodec *codec, int node, int param)
{
    return Query(codec, node, 0xF0000 + param);
}

/*##########################################################################
#
#   Name       : GetLongConnectionList
#
#   Purpose....: Get long connection list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetLongConnectionList(struct TCodec *codec, int node, struct TWidget **list, int count)
{
    int i;

    for (i = 0; i < MAX_CONNECTIONS; i++)
        list[i] = 0;    
}

/*##########################################################################
#
#   Name       : GetShortConnectionList
#
#   Purpose....: Get short connection list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetShortConnectionList(struct TCodec *codec, int node, struct TWidget **list, int count)
{
    int i;

    for (i = 0; i < MAX_CONNECTIONS; i++)
        list[i] = 0;    
}

/*##########################################################################
#
#   Name       : AddAudioOutput
#
#   Purpose....: Add audio output widget
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddAudioOutput(struct TCodec *codec, int node, int cap, int channels)
{
    struct TAudioOutput *widget;
    struct TAudioOutput *p;

    widget = (struct TAudioOutput *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioOutput));
    widget->Type = WIDGET_TYPE_OUTPUT;
    widget->Id = codec->Id;
    widget->Address = codec->Address;
    widget->Node = node;
    widget->Cap = cap;
    widget->Channels = channels;
    widget->List = 0;

    p = codec->AudioOutputList;
    if (p)
    {
        while (p->List)
            p = p->List;

        p->List = widget;
    }
    else
        codec->AudioOutputList = widget;
}

/*##########################################################################
#
#   Name       : AddAudioInput
#
#   Purpose....: Add audio input widget
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddAudioInput(struct TCodec *codec, int node, int cap, int channels)
{
    struct TAudioInput *widget;
    struct TAudioInput *p;
    int count;

    widget = (struct TAudioInput *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioInput));
    widget->Type = WIDGET_TYPE_INPUT;
    widget->Id = codec->Id;
    widget->Address = codec->Address;
    widget->Node = node;
    widget->Cap = cap;
    widget->Channels = channels;
    widget->List = 0;

    count = GetParam(codec, node, 0xE);
    widget->ConnectionCount = count & 0x7F;
    if (count & 0x80)
        GetLongConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);
    else
        GetShortConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);

    p = codec->AudioInputList;
    if (p)
    {
        while (p->List)
            p = p->List;

        p->List = widget;
    }
    else
        codec->AudioInputList = widget;
}

/*##########################################################################
#
#   Name       : AddAudioMixer
#
#   Purpose....: Add audio mixer widget
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddAudioMixer(struct TCodec *codec, int node, int cap, int channels)
{
    struct TAudioMixer *widget;
    struct TAudioMixer *p;
    int count;

    widget = (struct TAudioMixer *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioMixer));
    widget->Type = WIDGET_TYPE_MIXER;
    widget->Id = codec->Id;
    widget->Address = codec->Address;
    widget->Node = node;
    widget->Cap = cap;
    widget->Channels = channels;
    widget->List = 0;

    count = GetParam(codec, node, 0xE);
    widget->ConnectionCount = count & 0x7F;
    if (count & 0x80)
        GetLongConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);
    else
        GetShortConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);

    p = codec->AudioMixerList;
    if (p)
    {
        while (p->List)
            p = p->List;

        p->List = widget;
    }
    else
        codec->AudioMixerList = widget;
}

/*##########################################################################
#
#   Name       : AddAudioSelector
#
#   Purpose....: Add audio selector widget
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddAudioSelector(struct TCodec *codec, int node, int cap, int channels)
{
    struct TAudioSelector *widget;
    struct TAudioSelector *p;
    int count;

    widget = (struct TAudioSelector *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioSelector));
    widget->Type = WIDGET_TYPE_SELECTOR;
    widget->Id = codec->Id;
    widget->Address = codec->Address;
    widget->Node = node;
    widget->Cap = cap;
    widget->Channels = channels;
    widget->List = 0;

    count = GetParam(codec, node, 0xE);
    widget->ConnectionCount = count & 0x7F;
    if (count & 0x80)
        GetLongConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);
    else
        GetShortConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);

    p = codec->AudioSelectorList;
    if (p)
    {
        while (p->List)
            p = p->List;

        p->List = widget;
    }
    else
        codec->AudioSelectorList = widget;
}

/*##########################################################################
#
#   Name       : AddPinComplex
#
#   Purpose....: Add pin complex
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddPinComplex(struct TCodec *codec, int node, int cap, int channels)
{
    struct TPinComplex *widget;
    struct TPinComplex *p;
    int val;
    int dev;
    int use;
    int count;

    val = Query(codec, node, 0xF1C00);
    dev = (val >> 20) & 0xF;

    use = FALSE;
    switch (dev)
    {
        case 0:
        case 1:
        case 2:
        case 3:
        case 8:
        case 9:
        case 10:
            use = TRUE;
            break;
    }

    if (use)
    {
        widget = (struct TPinComplex *)RdosAllocateSmallGlobalMem(sizeof(struct TPinComplex));
        widget->Type = WIDGET_TYPE_PIN;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;
        widget->List = 0;
        widget->PinCap = GetParam(codec, node, 0xC);

        widget->Connectivity = (val >> 30) & 3;
        widget->Location = (val >> 24) & 0x3F;
        widget->ConnType = (val >> 16) & 0xF;
        widget->Color = (val >> 12) & 0xF;
        widget->Misc = (val >> 8) & 0xF;
        widget->Association = (val >> 4) & 0xF;
        widget->Sequence = val & 0xF;

        count = GetParam(codec, node, 0xE);
        widget->ConnectionCount = count & 0x7F;
        if (count & 0x80)
            GetLongConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);
        else    
            GetShortConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);

        switch (dev)
        {
            case 0:
                p = codec->LineOutList;
                break;
                
            case 1:
                p = codec->SpeakerList;
                break;
                
            case 2:
                p = codec->HpOutList;
                break;
                
            case 3:
                p = codec->CdList;
                break;

            case 8:
                p = codec->LineInList;
                break;

            case 9:
                p = codec->AuxList;
                break;
                
            case 10:
                p = codec->MicList;
                break;
        }

        if (p)
        {
            while (p->List)
                p = p->List;

            p->List = widget;
        }
        else
        {
            switch (dev)
            {
                case 0:
                    codec->LineOutList = widget;
                    break;
                
                case 1:
                    codec->SpeakerList = widget;
                    break;
                
                case 2:
                    codec->HpOutList = widget;
                    break;
                
                case 3:
                    codec->CdList = widget;
                    break;

                case 8:
                    codec->LineInList = widget;
                    break;

                case 9:
                    codec->AuxList = widget;
                    break;
                
                case 10:
                    codec->MicList = widget;
                    break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : AddPowerWidget
#
#   Purpose....: Add power widget
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddPowerWidget(struct TCodec *codec, int node, int cap, int channels)
{
    struct TPowerWidget *widget;
    struct TPowerWidget *p;
    int count;

    widget = (struct TPowerWidget *)RdosAllocateSmallGlobalMem(sizeof(struct TPowerWidget));
    widget->Type = WIDGET_TYPE_POWER;
    widget->Id = codec->Id;
    widget->Address = codec->Address;
    widget->Node = node;
    widget->Cap = cap;
    widget->Channels = channels;
    widget->List = 0;

    count = GetParam(codec, node, 0xE);
    widget->ConnectionCount = count & 0x7F;
    if (count & 0x80)
        GetLongConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);
    else
        GetShortConnectionList(codec, node, &widget->ConnectionList[0], widget->ConnectionCount);

    p = codec->PowerWidgetList;
    if (p)
    {
        while (p->List)
            p = p->List;

        p->List = widget;
    }
    else
        codec->PowerWidgetList = widget;
}


#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

void __far ImplTestGate(const char *msg)
{
    int val;
    int i;
    int j;
    int k;
    int count;
    int node;
    int type;
    int channels;
    struct TFunction *function;
    struct TCodec *codec;

    for (i = 0; i < FunctionCount; i++)
    {
        function = FunctionArr[i];

        for (j = 0; j < function->CodecCount; j++)
        {
            codec = function->CodecArr[j];
                            
            val = GetParam(codec, 0, 4);
            count = val & 0xFF;
            if (count > MAX_GROUPS)
                count = MAX_GROUPS;
            node = (val >> 16) & 0xFF;
            codec->AudioNode = 0;
            codec->AudioOutputList = 0;
            codec->AudioInputList = 0;
            codec->AudioMixerList = 0;
            codec->AudioSelectorList = 0;
            codec->PowerWidgetList = 0;
            codec->LineOutList = 0;
            codec->LineInList = 0;
            codec->SpeakerList = 0;
            codec->HpOutList = 0;
            codec->CdList = 0;
            codec->AuxList = 0;
            codec->MicList = 0;

            for (k = 0; k < count; k++)
            {
                val = GetParam(codec, node + k, 5);
                if ((val & 0xFF) == 1)
                    codec->AudioNode = node + k;
            }

            if (codec->AudioNode)
            {                    
                val = GetParam(codec, codec->AudioNode, 4);
                count = val & 0xFF;
                if (count > MAX_WIDGETS)
                    count = MAX_WIDGETS;
                node = (val >> 16) & 0xFF;

                for (k = 0; k < count; k++)
                {
                    val = GetParam(codec, node + k, 9);
                    type = (val >> 20) & 0xF;
                    channels = (val >> 12) & 7;
                    if (val & 1)
                        channels++;
                    channels++;

                    switch (type)
                    {
                        case 0:
                            AddAudioOutput(codec, node + k, val, channels);
                            break;

                        case 1:
                            AddAudioInput(codec, node + k, val, channels);
                            break;

                        case 2:
                            AddAudioMixer(codec, node + k, val, channels);
                            break;

                        case 3:
                            AddAudioSelector(codec, node + k, val, channels);
                            break;

                        case 4:
                            AddPinComplex(codec, node + k, val, channels);
                            break;

                        case 5:
                            AddPowerWidget(codec, node + k, val, channels);
                            break;
                    }
                }
            }
        }
    }
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
            codec->Id = Id;
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
