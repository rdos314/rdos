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

long long CodeLongLong(int Lsb, int Msb);

#pragma aux CodeLongLong = \
    parm [eax] [edx] \
    value [edx eax];

#define FALSE   0
#define TRUE  !FALSE

#define MAX_FUNCTIONS       16
#define MAX_CODECS          14
#define MAX_WIDGETS         128
#define MAX_CONNECTIONS     128
#define MAX_OUTPUTS         16
#define MAX_INPUTS          16

struct TAmp
{
    int StepSize;
    int NumSteps;
    int Offset;
    int Mutable;
};

struct TWidget
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TAudioOutput
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TAudioInput
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TAudioMixer
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TAudioSelector
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TPinComplex
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];

    int PinCap;
    int Connectivity;
    int Location;
    int Device;
    int ConnType;
    int Color;
    int Misc;
    int Association;
    int Sequence;
};

struct TPowerWidget
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TCodec
{
    int Id;
    int Address;
    int AudioNode;

    struct TWidget *WidgetArr[MAX_WIDGETS];
};

struct TFunction
{
    int Id;
    int CodecCount;
    struct TCodec *CodecArr[MAX_CODECS];    
};

static int FunctionCount = 0;
static struct TFunction *FunctionArr[MAX_FUNCTIONS];

static struct TPinComplex *FixedSpeaker;

static int OutputCount = 0;
static struct TPinComplex *OutputArr[MAX_OUTPUTS];

static int InputCount = 0;
static struct TPinComplex *InputArr[MAX_INPUTS];

static int ForceFixed = FALSE;
static int ForceOutput = -1;

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
#   Name       : GetConnectionList
#
#   Purpose....: Get connection list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetConnectionList(struct TCodec *codec, struct TWidget *widget)
{
    int i;
    int j;
    int val;
    int node;
    
    for (i = 0; i < widget->ConnectionCount; i += 4)
    {
        val = Query(codec, widget->Node, 0xF0200 + i);        

        for (j = 0; j < 4; j++)
        {
            if (i + j < widget->ConnectionCount)
            {
                node = val & 0x7F;
                widget->ConnectionList[i + j] = codec->WidgetArr[node];
            }
            val = val >> 8;
        }
    }
}

/*##########################################################################
#
#   Name       : UpdateConnectionList
#
#   Purpose....: Update connection list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void UpdateConnectionList(struct TCodec *codec)
{
    int i;
    struct TWidget *widget;

    for (i = 0; i < MAX_WIDGETS; i++)
    {
        widget = codec->WidgetArr[i];

        if (widget && widget->ConnectionCount)
            GetConnectionList(codec, widget);
    }
}

/*##########################################################################
#
#   Name       : ResetAmp
#
#   Purpose....: Reset amp parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ResetAmp(struct TAmp *amp)
{
    amp->StepSize = 0;
    amp->NumSteps = 0;
    amp->Offset = 0;
    amp->Mutable = FALSE;
}

/*##########################################################################
#
#   Name       : DefineAmp
#
#   Purpose....: Define amp parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DefineAmp(struct TAmp *amp, int val)
{
    if (val & 0x80000000)
        amp->Mutable = TRUE;
    else
        amp->Mutable = FALSE;

    amp->Offset = val & 0x7F;

    val = val >> 8;
    amp->NumSteps = (val & 0x7F) + 1;

    val = val >> 8;
    amp->StepSize = (val & 0x7F) + 1;
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
    int i;
    int val;

    widget = (struct TAudioOutput *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioOutput));
    widget->Type = AUDIO_WIDGET_TYPE_OUTPUT;
    widget->Id = codec->Id;
    widget->Address = codec->Address;
    widget->Node = node;
    widget->Cap = cap;
    widget->Channels = channels;

    for (i = 0; i < MAX_CONNECTIONS; i++)
        widget->ConnectionList[i] = 0;    

    ResetAmp(&widget->InputAmp);

    if (widget->Cap & 4)
    {
        val = GetParam(codec, node, 0x12);
        DefineAmp(&widget->OutputAmp, val);
    }
    else
        ResetAmp(&widget->OutputAmp);

    widget->ConnectionCount = 0;

    codec->WidgetArr[node] = (struct TWidget *)widget;
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
    int connections;
    int i;
    int val;

    connections = GetParam(codec, node, 0xE);

    if (connections < 0x80)
    {
        widget = (struct TAudioInput *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioInput));
        widget->Type = AUDIO_WIDGET_TYPE_INPUT;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;

        if (widget->Cap & 2)
        {
            val = GetParam(codec, node, 0xD);
            DefineAmp(&widget->InputAmp, val);
        }
        else
            ResetAmp(&widget->InputAmp);

        ResetAmp(&widget->OutputAmp);

        for (i = 0; i < MAX_CONNECTIONS; i++)
            widget->ConnectionList[i] = 0;    

        widget->ConnectionCount = connections;

        codec->WidgetArr[node] = (struct TWidget *)widget;
    }
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
    int connections;
    int i;
    int val;

    connections = GetParam(codec, node, 0xE);

    if (connections < 0x80)
    {
        widget = (struct TAudioMixer *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioMixer));
        widget->Type = AUDIO_WIDGET_TYPE_MIXER;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;

        if (widget->Cap & 2)
        {
            val = GetParam(codec, node, 0xD);
            DefineAmp(&widget->InputAmp, val);
        }
        else
            ResetAmp(&widget->InputAmp);

        if (widget->Cap & 4)
        {
            val = GetParam(codec, node, 0x12);
            DefineAmp(&widget->OutputAmp, val);
        }
        else
            ResetAmp(&widget->OutputAmp);

        for (i = 0; i < MAX_CONNECTIONS; i++)
            widget->ConnectionList[i] = 0;    

        widget->ConnectionCount = connections;

        codec->WidgetArr[node] = (struct TWidget *)widget;
    }
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
    int connections;
    int i;
    int val;

    connections = GetParam(codec, node, 0xE);

    if (connections < 0x80)
    {
        widget = (struct TAudioSelector *)RdosAllocateSmallGlobalMem(sizeof(struct TAudioSelector));
        widget->Type = AUDIO_WIDGET_TYPE_SELECTOR;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;

        ResetAmp(&widget->InputAmp);

        if (widget->Cap & 4)
        {
            val = GetParam(codec, node, 0x12);
            DefineAmp(&widget->OutputAmp, val);
        }
        else
            ResetAmp(&widget->OutputAmp);

        for (i = 0; i < MAX_CONNECTIONS; i++)
            widget->ConnectionList[i] = 0;    

        widget->ConnectionCount = connections;

        codec->WidgetArr[node] = (struct TWidget *)widget;
    }
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
    int val;
    int dev;
    int conn;
    int use;
    int connections;
    int i;

    val = Query(codec, node, 0xF1C00);
    dev = (val >> 20) & 0xF;
    conn = (val >> 30) & 3;

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
        connections = GetParam(codec, node, 0xE);
        if (connections >= 0x80)
            use = FALSE;
    }

    if (conn == 1 && connections == 0)
        use = FALSE;

    if ((cap & 0x6) == 0)
        use = FALSE;

    if (use)
    {
        widget = (struct TPinComplex *)RdosAllocateSmallGlobalMem(sizeof(struct TPinComplex));
        widget->Type = AUDIO_WIDGET_TYPE_PIN;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;
        widget->PinCap = GetParam(codec, node, 0xC);

        widget->Connectivity = conn;
        widget->Device = dev;
        widget->Location = (val >> 24) & 0x3F;
        widget->ConnType = (val >> 16) & 0xF;
        widget->Color = (val >> 12) & 0xF;
        widget->Misc = (val >> 8) & 0xF;
        widget->Association = (val >> 4) & 0xF;
        widget->Sequence = val & 0xF;

        if (widget->Cap & 2)
        {
            val = GetParam(codec, node, 0xD);
            DefineAmp(&widget->InputAmp, val);
        }
        else
            ResetAmp(&widget->InputAmp);

        if (widget->Cap & 4)
        {
            val = GetParam(codec, node, 0x12);
            DefineAmp(&widget->OutputAmp, val);
        }
        else
            ResetAmp(&widget->OutputAmp);

        for (i = 0; i < MAX_CONNECTIONS; i++)
            widget->ConnectionList[i] = 0;    

        widget->ConnectionCount = connections;

        codec->WidgetArr[node] = (struct TWidget *)widget;

        switch (widget->Connectivity)
        {
            case 0:
                if (widget->PinCap & 0x10)
                {
                    if (OutputCount < MAX_OUTPUTS)
                    {
                        OutputArr[OutputCount] = widget;
                        OutputCount++;
                    }
                }

                if (widget->PinCap & 0x20)
                {
                    if (InputCount < MAX_OUTPUTS)
                    {
                        InputArr[InputCount] = widget;
                        InputCount++;
                    }
                }
                break;

            case 1:
                if (widget->PinCap & 0x10)
                    if (widget->PinCap & 0x8)
                        FixedSpeaker = widget;
                break;
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
    int connections;
    int i;

    connections = GetParam(codec, node, 0xE);

    if (connections < 0x80)
    {
        widget = (struct TPowerWidget *)RdosAllocateSmallGlobalMem(sizeof(struct TPowerWidget));
        widget->Type = AUDIO_WIDGET_TYPE_POWER;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;

        ResetAmp(&widget->InputAmp);
        ResetAmp(&widget->OutputAmp);

        for (i = 0; i < MAX_CONNECTIONS; i++)
            widget->ConnectionList[i] = 0;    

        widget->ConnectionCount = connections;

        codec->WidgetArr[node] = (struct TWidget *)widget;
    }
}

/*##########################################################################
#
#   Name       : ProcessCodec
#
#   Purpose....: Process codec
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ProcessCodec(struct TCodec *codec)
{
    int val;
    int i;
    int count;
    int node;
    int type;
    int channels;

    val = GetParam(codec, 0, 4);
    count = val & 0xFF;
    node = (val >> 16) & 0xFF;

    codec->AudioNode = 0;

    for (i = 0; i < MAX_WIDGETS; i++)
        codec->WidgetArr[i] = 0;

    for (i = 0; i < count; i++)
    {
        val = GetParam(codec, node + i, 5);
        if ((val & 0xFF) == 1)
            codec->AudioNode = node + i;
    }
    
    if (codec->AudioNode)
    {                    
        val = GetParam(codec, codec->AudioNode, 4);
        count = val & 0xFF;
        if (count > MAX_WIDGETS)
            count = MAX_WIDGETS;
        node = (val >> 16) & 0xFF;

        for (i = 0; i < count; i++)
        {
            val = GetParam(codec, node + i, 9);
            type = (val >> 20) & 0xF;
            channels = (val >> 12) & 7;
            if (val & 1)
                channels++;
            channels++;

            switch (type)
            {
                case 0:
                    AddAudioOutput(codec, node + i, val, channels);
                    break;

                case 1:
                    AddAudioInput(codec, node + i, val, channels);
                    break;

                case 2:
                    AddAudioMixer(codec, node + i, val, channels);
                    break;

                case 3:
                    AddAudioSelector(codec, node + i, val, channels);
                    break;

                case 4:
                    AddPinComplex(codec, node + i, val, channels);
                    break;

                case 5:
                    AddPowerWidget(codec, node + i, val, channels);
                    break;
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
            ProcessCodec(codec);
            UpdateConnectionList(codec);
            
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
#   Name       : PresentDetect
#
#   Purpose....: Check for function present
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int PresentDetect(struct TPinComplex *pin)
{
    int val;

    val = QueryCodec(pin->Id, pin->Address, pin->Node, 0xF0900);

    if (val & 0x80000000)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : GetSelectedControl
#
#   Purpose....: Get currently selected control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetSelectedControl(struct TWidget *widget)
{
    int val;

    switch (widget->ConnectionCount)
    {
        case 0:
        case 1:
            return 0;

        default:
            val = QueryCodec(widget->Id, widget->Address, widget->Node, 0xF0100);
            return val & 0xFF;
    }
}

/*##########################################################################
#
#   Name       : GetInputAmpSetting
#
#   Purpose....: Get input amp setting
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetInputAmpSetting(struct TWidget *widget, int channel, int index)
{
    int verb;
    int val;

    verb = 0xB0000;
    verb |= channel << 13;
    verb |= index;
    
    val = QueryCodec(widget->Id, widget->Address, widget->Node, verb);
    if (val & 0x80)
        val = -1;

    return val;
}

/*##########################################################################
#
#   Name       : GetOutputAmpSetting
#
#   Purpose....: Get output amp setting
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetOutputAmpSetting(struct TWidget *widget, int channel)
{
    int verb;
    int val;

    verb = 0xB8000;
    verb |= channel << 13;
    
    val = QueryCodec(widget->Id, widget->Address, widget->Node, verb);
    if (val & 0x80)
        val = -1;

    return val;
}

/*##########################################################################
#
#   Name       : GetAudioDeviceCount
#
#   Purpose....: Get device count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioDeviceCount "*" rdosdev parm routine value [ecx]
long __far ImplGetAudioDeviceCount()
{
    RdosSetSuccess();
    return FunctionCount;
}

/*##########################################################################
#
#   Name       : GetAudioCodecCount
#
#   Purpose....: Get codec count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioCodecCount "*" rdosdev parm routine [eax] value [ecx]
long __far ImplGetAudioCodecCount(int device)
{
    int count = 0;

    if (device < FunctionCount)
    {
        count = FunctionArr[device]->CodecCount;
        RdosSetSuccess();
    }
    else
        RdosSetFailure();

    return count;
}

/*##########################################################################
#
#   Name       : GetWidget
#
#   Purpose....: Get widget
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TWidget *GetWidget(int Device, int CodecNr, int Node)
{
    struct TFunction *Function;
    struct TCodec *Codec;
    struct TWidget *Widget = 0;
    
    if (Device < FunctionCount)
    {
        Function = FunctionArr[Device];
        if (Function && CodecNr < Function->CodecCount)
        {
            Codec = Function->CodecArr[CodecNr];
            if (Codec && Node < MAX_WIDGETS)
                Widget = Codec->WidgetArr[Node];                
        }    
    }

    return Widget;
}

/*##########################################################################
#
#   Name       : GetAudioOutputInfo
#
#   Purpose....: Get audio output info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetAudioOutputInfo(struct TAudioOutput *widget, char *Info)
{
    strcpy(Info, "Audio Out");
}

/*##########################################################################
#
#   Name       : GetAudioInputInfo
#
#   Purpose....: Get audio input info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetAudioInputInfo(struct TAudioInput *widget, char *Info)
{
    strcpy(Info, "Audio In");
}

/*##########################################################################
#
#   Name       : GetAudioMixerInfo
#
#   Purpose....: Get audio mixer info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetAudioMixerInfo(struct TAudioMixer *widget, char *Info)
{
    strcpy(Info, "Audio Mixer");
}

/*##########################################################################
#
#   Name       : GetAudioSelectorInfo
#
#   Purpose....: Get audio selector info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetAudioSelectorInfo(struct TAudioSelector *widget, char *Info)
{
    strcpy(Info, "Audio Selector");
}

/*##########################################################################
#
#   Name       : GetPinComplexInfo
#
#   Purpose....: Get pin complex info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetPinComplexInfo(struct TPinComplex *widget, char *Info)
{
    char *LocStr;
    static char *LocationArr[] = {"Chassis", "Rear", "Front", "Left", "Right", "Top", "Bottom", "Rear panel", "Drive bay", 0, 0, 0, 0, 0, 0, 0,
                                  "Internal", 0, 0, 0, 0, 0, 0, "Riser", "Digital display", "ATAPI", 0, 0, 0, 0, 0, 0,
                                  "Box", "Box rear", "Box front", "Box left", "Box right", "Box top", "Box bottom", 0, 0, 0, 0, 0, 0, 0, 0,
                                  "Unknown", 0, 0, 0, 0, 0 , "Other bottom", "Mobile mic", "Mobile outside", 0, 0, 0, 0, 0, 0, 0}; 
    
    switch (widget->Connectivity)
    {
        case 0:
            strcpy(Info, "Jack");
            break;

        case 1:
            strcpy(Info, "Pin");
            break;

        case 2:
            strcpy(Info, "Fixed");
            break;

        case 3:
            strcpy(Info, "Fixed Jack");
            break;
    }

    if (widget->Connectivity != 1)
    {
        LocStr = LocationArr[widget->Location];
        if (LocStr)
        {
            strcat(Info, ", ");
            strcat(Info, LocStr);
        }

        switch (widget->Device)
        {
            case 0:
                strcat(Info, ", Line out");
                break;

            case 1:
                strcat(Info, ", Speaker");
                break;

            case 2:
                strcat(Info, ", HP out");
                break;

            case 3:
                strcat(Info, ", CD");
                break;

            case 8:
                strcat(Info, ", Line in");
                break;

            case 9:
                strcat(Info, ", AUX");
                break;

            case 10:
                strcat(Info, ", Mic");
                break;
        }

        switch (widget->ConnType)
        {
            case 1:
                strcat(Info, ", 1/8''");
                break;

            case 2:
                strcat(Info, ", 1/4''");
                break;

            case 3:
                strcat(Info, ", ATAPI");
                break;
        
            case 4:
                strcat(Info, ", RCA");
                break;
        
            case 5:
                strcat(Info, ", Optical");
                break;
        
            case 6:
                strcat(Info, ", Digital");
                break;
        
            case 7:
                strcat(Info, ", Analog");
                break;
        
            case 8:
                strcat(Info, ", DIN");
                break;
        
            case 9:
                strcat(Info, ", XLR");
                break;
        
            case 10:
                strcat(Info, ", RJ-11");
                break;
        }
    }        

    if (widget->Connectivity == 0 || widget->Connectivity == 3)
    {
        switch (widget->Color)
        {
            case 1:
                strcat(Info, ", Black");
                break;

            case 2:
                strcat(Info, ", Grey");
                break;

            case 3:
                strcat(Info, ", Blue");
                break;

            case 4:
                strcat(Info, ", Green");
                break;

            case 5:
                strcat(Info, ", Red");
                break;

            case 6:
                strcat(Info, ", Orange");
                break;

            case 7:
                strcat(Info, ", Yellow");
                break;

            case 8:
                strcat(Info, ", Purple");
                break;
    
            case 9:
                strcat(Info, ", Pink");
                break;

            case 14:
                strcat(Info, ", White");
                break;
        }
    }

    if (widget->PinCap & 0x10)
        if (widget->PinCap & 0x8)
            strcat(Info, ", Headphone");

    if (widget->PinCap & 0x4)
    {
        if ((widget->Misc & 0x1) == 0)
        {
            if (PresentDetect(widget))
                strcat(Info, ", Connected");
            else
                strcat(Info, ", Not connected");
        }
    }

    if (widget->PinCap & 0x40)
        strcat(Info, ", Balanced");

    if (widget->PinCap & 0x80)
        strcat(Info, ", HDMI");

    if (widget->PinCap & 0x10000)
        strcat(Info, ", EAPD");

    if (widget->PinCap & 0x1000000)
        strcat(Info, ", Display Port");
}

/*##########################################################################
#
#   Name       : GetPowerWidgetInfo
#
#   Purpose....: Get power widget info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetPowerWidgetInfo(struct TPowerWidget *widget, char *Info)
{
    strcpy(Info, "Power");
}

/*##########################################################################
#
#   Name       : GetAudioWidgetInfo
#
#   Purpose....: Get widget info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char GetAudioWidgetInfo(int Device, int CodecNr, int Node, char *Info)
{
    char Type = 0;
    struct TWidget *Widget;

    Widget = GetWidget(Device, CodecNr, Node);

    if (Widget)
    {
        Type = Widget->Type;

        switch (Type)
        {
            case AUDIO_WIDGET_TYPE_OUTPUT:
                GetAudioOutputInfo((struct TAudioOutput *)Widget, Info);
                break;

            case AUDIO_WIDGET_TYPE_INPUT:
                GetAudioInputInfo((struct TAudioInput *)Widget, Info);
                break;

            case AUDIO_WIDGET_TYPE_MIXER:
                GetAudioMixerInfo((struct TAudioMixer *)Widget, Info);
                break;

            case AUDIO_WIDGET_TYPE_SELECTOR:
                GetAudioSelectorInfo((struct TAudioSelector *)Widget, Info);
                break;

            case AUDIO_WIDGET_TYPE_PIN:
                GetPinComplexInfo((struct TPinComplex *)Widget, Info);
                break;

            case AUDIO_WIDGET_TYPE_POWER:
                GetPowerWidgetInfo((struct TPowerWidget *)Widget, Info);
                break;

            default:
                strcpy(Info, "Unknown");
                break;
        }
    }
    return Type;
}

/*##########################################################################
#
#   Name       : GetAudioWidgetInfo16
#
#   Purpose....: Get audio widget info, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioWidgetInfo16 "*" rdosdev parm routine [eax] [edx] [ebx] [es edi] value [al]
char __far ImplGetAudioWidgetInfo16(int Device, int Codec, int Node, char *Info)
{
    char Type;
    
    RdosExtendDi();

    Type = GetAudioWidgetInfo(Device, Codec, Node, Info);
    if (Type)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return Type;
}

/*##########################################################################
#
#   Name       : GetAudioWidgetInfo32
#
#   Purpose....: Get audio widget info, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioWidgetInfo32 "*" rdosdev parm routine [eax] [edx] [ebx] [es edi] value [al]
char __far ImplGetAudioWidgetInfo32(int Device, int Codec, int Node, char *Info)
{
    char Type;
    
    Type = GetAudioWidgetInfo(Device, Codec, Node, Info);
    if (Type)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return Type;
}

/*##########################################################################
#
#   Name       : GetAudioConnectionList
#
#   Purpose....: Get widget connection list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetAudioConnectionList(int Device, int CodecNr, int Node, int *ConnectionList)
{
    int Count = 0;
    int i;
    int size;
    struct TWidget *Widget;
    struct TWidget *w;

    Widget = GetWidget(Device, CodecNr, Node);

    if (Widget)
    {
        size = Widget->ConnectionCount;

        for (i = 0; i < size; i++)
        {
            w = Widget->ConnectionList[i];
            if (w && w->Node)
            {
                ConnectionList[Count] = w->Node;
                Count++;
            }
        }
    }

    return Count;
}

/*##########################################################################
#
#   Name       : GetAudioConnectionList16
#
#   Purpose....: Get audio widget connection list, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioConnectionList16 "*" rdosdev parm routine [eax] [edx] [ebx] [es edi] value [ecx]
int __far ImplGetAudioConnectionList16(int Device, int Codec, int Node, int *ConnectionList)
{
    int Count;
    
    RdosExtendDi();

    Count = GetAudioConnectionList(Device, Codec, Node, ConnectionList);
    if (Count)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return Count;
}

/*##########################################################################
#
#   Name       : GetAudioConnectionList32
#
#   Purpose....: Get audio widget connection list, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioConnectionList32 "*" rdosdev parm routine [eax] [edx] [ebx] [es edi] value [ecx]
int __far ImplGetAudioConnectionList32(int Device, int Codec, int Node, int *ConnectionList)
{
    int Count;

    Count = GetAudioConnectionList(Device, Codec, Node, ConnectionList);
    if (Count)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return Count;
}

/*##########################################################################
#
#   Name       : GetSelectedAudioConection
#
#   Purpose....: Get selected audio connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetSelectedAudioConnection "*" rdosdev parm routine [eax] [edx] [ebx] value [eax]
int __far ImplGetSelectedAudioConnection(int Device, int Codec, int Node)
{
    struct TWidget *Widget;
    int curr = 0;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
    {
        curr = GetSelectedControl(Widget);
        RdosSetSuccess();
    }
    else
        RdosSetFailure();
        
    return curr;
}

/*##########################################################################
#
#   Name       : GetAudioInputAmpCap
#
#   Purpose....: Get audio input amp range
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioInputAmpCap "*" rdosdev parm routine [eax] [edx] [ebx] value [edx eax]
long long __far ImplGetAudioInputAmpCap(int Device, int Codec, int Node)
{
    struct TWidget *Widget;
    int min;
    int max;
    long long val = 0;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
    {
        min = -Widget->InputAmp.Offset * Widget->InputAmp.StepSize;
        max = (Widget->InputAmp.NumSteps - Widget->InputAmp.Offset - 1) * Widget->InputAmp.StepSize;
        val = CodeLongLong(min, max);
        RdosSetSuccess();
    }
    else
        RdosSetFailure();
        
    return val;
}

/*##########################################################################
#
#   Name       : GetAudioOutputAmpCap
#
#   Purpose....: Get audio output amp range
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioOutputAmpCap "*" rdosdev parm routine [eax] [edx] [ebx] value [edx eax]
long long __far ImplGetAudioOutputAmpCap(int Device, int Codec, int Node)
{
    struct TWidget *Widget;
    int min;
    int max;
    long long val = 0;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
    {
        min = -Widget->OutputAmp.Offset * Widget->OutputAmp.StepSize;
        max = (Widget->OutputAmp.NumSteps - Widget->OutputAmp.Offset - 1) * Widget->OutputAmp.StepSize;
        val = CodeLongLong(min, max);
        RdosSetSuccess();
    }
    else
        RdosSetFailure();
        
    return val;
}

/*##########################################################################
#
#   Name       : HasAudioInputMute
#
#   Purpose....: Check for input amp mute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplHasAudioInputMute "*" rdosdev parm routine [eax] [edx] [ebx]
void __far ImplHasAudioInputMute(int Device, int Codec, int Node)
{
    struct TWidget *Widget;
    int ok = FALSE;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
        ok = Widget->InputAmp.Mutable;

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : HasAudioOutputMute
#
#   Purpose....: Check for output amp mute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplHasAudioOutputMute "*" rdosdev parm routine [eax] [edx] [ebx]
void __far ImplHasAudioOutputMute(int Device, int Codec, int Node)
{
    struct TWidget *Widget;
    int ok = FALSE;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
        ok = Widget->OutputAmp.Mutable;

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ReadAudioInputAmp
#
#   Purpose....: Read audio input amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplReadAudioInputAmp "*" rdosdev parm routine [eax] [edx] [ebx] [ecx] [esi] value [eax]
int __far ImplReadAudioInputAmp(int Device, int Codec, int Node, int Channel, int Input)
{
    struct TWidget *Widget;
    int val = 0;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
    {
        if (Widget->InputAmp.NumSteps > 1)
        {
            val = GetInputAmpSetting(Widget, Channel, Input);
            if (val >= 0)
                val = (val - Widget->InputAmp.Offset) * Widget->InputAmp.StepSize;
        }                
            
        RdosSetSuccess();
    }
    else
        RdosSetFailure();
        
    return val;
}

/*##########################################################################
#
#   Name       : ReadAudioOutputAmp
#
#   Purpose....: Read audio output amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplReadAudioOutputAmp "*" rdosdev parm routine [eax] [edx] [ebx] [ecx] value [eax]
int __far ImplReadAudioOutputAmp(int Device, int Codec, int Node, int Channel)
{
    struct TWidget *Widget;
    int val = 0;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
    {
        if (Widget->OutputAmp.NumSteps > 1)
        {
            val = GetOutputAmpSetting(Widget, Channel);
            if (val >= 0)
                val = (val - Widget->OutputAmp.Offset) * Widget->OutputAmp.StepSize;
        }                
            
        RdosSetSuccess();
    }
    else
        RdosSetFailure();
        
    return val;
}

/*##########################################################################
#
#   Name       : IsAudioInputAmpMuted
#
#   Purpose....: Check if audio input is muted
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplIsAudioInputAmpMuted "*" rdosdev parm routine [eax] [edx] [ebx] [ecx] [esi]
void __far ImplIsAudioInputAmpMuted(int Device, int Codec, int Node, int Channel, int Input)
{
    struct TWidget *Widget;
    int ok = FALSE;
    int val;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
    {
        if (Widget->InputAmp.NumSteps)
        {
            val = GetInputAmpSetting(Widget, Channel, Input);
            if (val < 0)
                ok = TRUE;
        }                
    }

    if (ok)            
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : IsAudioOutputAmpMuted
#
#   Purpose....: Check if audio output is muted
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplIsAudioOutputAmpMuted "*" rdosdev parm routine [eax] [edx] [ebx] [ecx] [esi]
void __far ImplIsAudioOutputAmpMuted(int Device, int Codec, int Node, int Channel, int Input)
{
    struct TWidget *Widget;
    int ok = FALSE;
    int val;

    Widget = GetWidget(Device, Codec, Node);

    if (Widget)
    {
        if (Widget->OutputAmp.NumSteps)
        {
            val = GetOutputAmpSetting(Widget, Channel);
            if (val < 0)
                ok = TRUE;
        }
    }

    if (ok)            
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : GetFixedOutput
#
#   Purpose....: Get fixed output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetFixedOutput "*" rdosdev parm routine value [dx eax]
struct TPinComplex *GetFixedOutput()
{
    return FixedSpeaker;
}

/*##########################################################################
#
#   Name       : GetOutputJack
#
#   Purpose....: Get output jack
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetOutputJack "*" rdosdev parm routine [ebx] value [dx eax]
struct TPinComplex *GetOutputJack(int num)
{
    if (num < OutputCount)
        return OutputArr[num];
    else
        return 0;
}

/*##########################################################################
#
#   Name       : GetInputJack
#
#   Purpose....: Get input jack
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetInputJack "*" rdosdev parm routine [ebx] value [dx eax]
struct TPinComplex *GetInputJack(int num)
{
    if (num < InputCount)
        return InputArr[num];
    else
        return 0;
}

/*##########################################################################
#
#   Name       : RawSeOutputAmp
#
#   Purpose....: Set raw output amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RawSetOutputAmp(struct TWidget *widget, struct TAmp *amp, int l, int r)
{
    int verb;

    if (l == r)
    {
        verb = 0x3B000;
        verb |= l;
        QueryCodec(widget->Id, widget->Address, widget->Node, verb);
    }
    else
    {
        verb = 0x39000;
        verb |= r;
        QueryCodec(widget->Id, widget->Address, widget->Node, verb);

        verb = 0x3A000;
        verb |= l;
        QueryCodec(widget->Id, widget->Address, widget->Node, verb);
    }
}

/*##########################################################################
#
#   Name       : SetOutputAmp
#
#   Purpose....: Set output amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetOutputAmp(struct TWidget *widget, int l, int r)
{
    int lval;
    int rval;
    struct TAmp *amp = &widget->OutputAmp;
    
    switch (amp->NumSteps)
    {
        case 0:
            break;

        case 1:
            RawSetOutputAmp(widget, amp, amp->Offset, amp->Offset);
            break;

        default:
            lval = l / amp->StepSize + amp->Offset;
            rval = r / amp->StepSize + amp->Offset;
            RawSetOutputAmp(widget, amp, lval, rval);
            break;
    }
}

/*##########################################################################
#
#   Name       : RawSetInputAmp
#
#   Purpose....: Set raw input amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RawSetInputAmp(struct TWidget *widget, struct TAmp *amp, int entry, int l, int r)
{
    int verb;

    if (l == r)
    {
        verb = 0x37000;
        verb |= entry << 8;
        verb |= l;
        
        QueryCodec(widget->Id, widget->Address, widget->Node, verb);
    }
    else
    {
        verb = 0x35000;
        verb |= entry << 8;
        verb |= r;
        QueryCodec(widget->Id, widget->Address, widget->Node, verb);

        verb = 0x36000;
        verb |= entry << 8;
        verb |= l;
        QueryCodec(widget->Id, widget->Address, widget->Node, verb);
    }
}

/*##########################################################################
#
#   Name       : SelectInput
#
#   Purpose....: Select input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SelectInput(struct TWidget *widget, int entry)
{
    int verb;

    verb = 0x70100;
    verb |= entry;
    QueryCodec(widget->Id, widget->Address, widget->Node, verb);
}

/*##########################################################################
#
#   Name       : MuteOutputAmp
#
#   Purpose....: Mute output amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void MuteOutputAmp(struct TWidget *widget, struct TAmp *amp)
{
    int verb;

    verb = 0x3B080;
    QueryCodec(widget->Id, widget->Address, widget->Node, verb);
}

/*##########################################################################
#
#   Name       : MuteInputAmp
#
#   Purpose....: Mute input amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void MuteInputAmp(struct TWidget *widget, struct TAmp *amp, int entry)
{
    int verb;

    verb = 0x37080;
    verb |= entry << 8;
    QueryCodec(widget->Id, widget->Address, widget->Node, verb);
}

/*##########################################################################
#
#   Name       : SetInputAmp
#
#   Purpose....: Set input amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetInputAmp(struct TWidget *widget, int entry, int l, int r)
{
    int i;
    int lval;
    int rval;
    struct TAmp *amp = &widget->InputAmp;

    switch (widget->Type)
    {
        case AUDIO_WIDGET_TYPE_SELECTOR:
        case AUDIO_WIDGET_TYPE_PIN:
            SelectInput(widget, entry);
            break;
    }

    if (amp->NumSteps)
    {
        for (i = 0; i < widget->ConnectionCount; i++)
        {
            if (i == entry)
            {
                if (amp->NumSteps == 1)
                    RawSetInputAmp(widget, amp, entry, amp->Offset, amp->Offset);
                else
                {
                    lval = l / amp->StepSize + amp->Offset;
                    rval = r / amp->StepSize + amp->Offset;
                    RawSetInputAmp(widget, amp, entry, lval, rval);
                }
            }
            else
            {
                if (widget->Type != AUDIO_WIDGET_TYPE_PIN)
                    MuteInputAmp(widget, amp, i);
            }
        }
    }
}

/*##########################################################################
#
#   Name       : FindSingleOutputPath
#
#   Purpose....: Find an output path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int FindSingleOutputPath(struct TWidget *widget, int MaxIterations)
{
    int i;
    int res;
    struct TWidget *w;

    if (MaxIterations == 0)
        return -1;

    switch (widget->Type)
    {
        case AUDIO_WIDGET_TYPE_OUTPUT:
        case AUDIO_WIDGET_TYPE_INPUT:
        case AUDIO_WIDGET_TYPE_SELECTOR:
            return -1;
    }

    for (i = 0; i < widget->ConnectionCount; i++)
    {
        w = widget->ConnectionList[i];
        if (w->Type == AUDIO_WIDGET_TYPE_OUTPUT)
            return i;

        res = FindSingleOutputPath(w, MaxIterations - 1);
        if (res >= 0)
            return i;                    
    }

    return -1;
}

/*##########################################################################
#
#   Name       : FindOutputPath
#
#   Purpose....: Find an output path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int FindOutputPath(struct TWidget *widget)
{
    int i;
    int res;

    for (i = 1; i < 8; i++)
    {
        res = FindSingleOutputPath(widget, i);
        if (res >= 0)
            return res;
    }

    return -1;
}

/*##########################################################################
#
#   Name       : DetermineActiveOutput
#
#   Purpose....: Determine active output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TPinComplex *DetermineActiveOutput()
{
    int i;
    int found = FALSE;
    struct TPinComplex *widget;

    if (ForceFixed && FixedSpeaker)
    {
        widget = FixedSpeaker;
        found = TRUE;
    }
    
    if (!found)
    {
        if (ForceOutput >= 0 && ForceOutput < OutputCount)
        {
            widget = OutputArr[ForceOutput];
            found = TRUE;
        }
    } 

    for (i = 0; i < OutputCount && !found; i++)
    {
        widget = OutputArr[i];
        if (widget->PinCap & 0x4)
            if ((widget->Misc & 0x1) == 0)
                if (PresentDetect(widget))
                    found = TRUE;
    }

    if (!found && FixedSpeaker)
    {
        widget = FixedSpeaker;
        found = TRUE;
    }

    for (i = 0; i < OutputCount && !found; i++)
    {
        widget = OutputArr[i];
        if ((widget->PinCap & 0x4) == 0)
            found = TRUE;
    }

    if (found)
        return widget;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : ActivateOutput
#
#   Purpose....: Activate output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ActivateOutput(struct TWidget *widget)
{
    int i;

    if (widget->Type == AUDIO_WIDGET_TYPE_OUTPUT)
        SetOutputAmp(widget, 0, 0);
    else
    {
        i = FindOutputPath(widget);
        if (i >= 0)
        {
            SetOutputAmp(widget, 0, 0);
            SetInputAmp(widget, i, 0, 0);
            ActivateOutput(widget->ConnectionList[i]);
        }
    }
}

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

void __far ImplTestGate(const char *msg)
{
    struct TWidget *widget;
    int i;

    widget = (struct TWidget *)DetermineActiveOutput();
    ActivateOutput(widget);
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
    RdosRegisterBimodalUserGate(usergate_get_audio_device_count, &ImplGetAudioDeviceCount, "Get Audio Device Count");
    RdosRegisterBimodalUserGate(usergate_get_audio_codec_count, &ImplGetAudioCodecCount, "Get Audio Device Count");
    RdosRegisterUserGate(usergate_get_audio_widget_info, &ImplGetAudioWidgetInfo16, &ImplGetAudioWidgetInfo32, "Get Audio Widget Info");
    RdosRegisterUserGate(usergate_get_audio_widget_connection_list, &ImplGetAudioConnectionList16, &ImplGetAudioConnectionList32, "Get Audio Connection List");
    RdosRegisterBimodalUserGate(usergate_get_selected_audio_connection, &ImplGetSelectedAudioConnection, "Get Selected Audio Connection");
    RdosRegisterBimodalUserGate(usergate_get_audio_input_amp_cap, &ImplGetAudioInputAmpCap, "Get Audio Input Amp Cap");
    RdosRegisterBimodalUserGate(usergate_get_audio_output_amp_cap, &ImplGetAudioOutputAmpCap, "Get Audio Output Amp Cap");
    RdosRegisterBimodalUserGate(usergate_has_audio_input_mute, &ImplHasAudioInputMute, "Has Audio Input Mute");
    RdosRegisterBimodalUserGate(usergate_has_audio_output_mute, &ImplHasAudioOutputMute, "Has Audio Output Mute");
    RdosRegisterBimodalUserGate(usergate_read_audio_input_amp, &ImplReadAudioInputAmp, "Read Audio Input Amp");
    RdosRegisterBimodalUserGate(usergate_read_audio_output_amp, &ImplReadAudioOutputAmp, "Read Audio Output Amp");
    RdosRegisterBimodalUserGate(usergate_is_audio_input_amp_muted, &ImplIsAudioInputAmpMuted, "Is Audio Input Amp Muted");
    RdosRegisterBimodalUserGate(usergate_is_audio_output_amp_muted, &ImplIsAudioOutputAmpMuted, "Is Audio Output Amp Muted");

    RdosRegisterBimodalUserGate(usergate_test_gate, &ImplTestGate, "Test Gate"); 
}
