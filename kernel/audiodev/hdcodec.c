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
# hdcodec.c
# HD Audio Codec device
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "rdosdev.h"

extern void InitHda();
extern void InitPciHda();
extern void DebugStream();

extern int GetFunctionCount();
#pragma aux GetFinctionCount value [eax]

extern void StartFunction(int id);
#pragma aux StartFunction parm routine [ebx]

extern int GetCodecMask(int id);
#pragma aux GetCodecMask parm routine [ebx] value [eax]

extern int QueryCodec(int id, int codec, int node, int data);
#pragma aux QueryCodec parm routine [ebx] [esi] [edi] [edx] value [eax]

extern void SetOutputFormat(int function, int codec, int format, int width);
#pragma aux SetOutputFormat parm routine [ebx] [esi] [eax] [ecx]

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
#define MAX_VOLUME_CONTROLS 8

#define OUTPUT_STREAM       1

struct TCodec;

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
    int InPath;
    struct TCodec *Codec;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TVolumeControl
{
    int IsInputAmp;
    int InputEntry;
    struct TWidget *Widget;

    int MinVol;
    int MaxVol;
    int CurrVol;
};

struct TAudioOutput
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    int InPath;
    struct TCodec *Codec;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];

    int PcmRates;
    int Format;
    int Width;
};

struct TAudioInput
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    int InPath;
    struct TCodec *Codec;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];

    int PcmRates;
    int Format;
    int Width;
};

struct TAudioMixer
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    int InPath;
    struct TCodec *Codec;
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
    int InPath;
    struct TCodec *Codec;
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
    int InPath;
    struct TCodec *Codec;
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
    int InPath;
    struct TCodec *Codec;
    struct TAmp InputAmp;
    struct TAmp OutputAmp;
    int ConnectionCount;
    struct TWidget *ConnectionList[MAX_CONNECTIONS];
};

struct TBeepWidget
{
    int Type;
    int Id;
    int Address;
    int Node;
    int Cap;
    int Channels;
    int InPath;
    struct TCodec *Codec;
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
    int VendorID;
    int DeviceID;

    struct TWidget *WidgetArr[MAX_WIDGETS];
};

struct TFunction
{
    int Id;
    int CodecCount;
    struct TCodec *CodecArr[MAX_CODECS];    
};

static int Vendor;
static int SubSys;
static int PowerState;

static int FunctionCount = 0;
static struct TFunction *FunctionArr[MAX_FUNCTIONS];

static struct TPinComplex *FixedSpeaker;

struct TKernelSection OutputSection;

static int OutputCount = 0;
static struct TPinComplex *OutputArr[MAX_OUTPUTS];

int OutputVolumeControls = 0;
struct TVolumeControl *OutputVolumeArr[MAX_VOLUME_CONTROLS];
struct TPinComplex *CurrentOutput = 0;
struct TAudioOutput *OutputWidget = 0;

static int InputCount = 0;
static struct TPinComplex *InputArr[MAX_INPUTS];

static int OutputMute = FALSE;
static int OutputLVol = 0;
static int OutputRVol = 0;

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
    widget->InPath = FALSE;
    widget->Codec = codec;
    widget->PcmRates = GetParam(codec, node, 0xA);

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
        widget->InPath = FALSE;
        widget->Codec = codec;
        widget->PcmRates = GetParam(codec, node, 0xA);

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
        widget->InPath = FALSE;
        widget->Codec = codec;

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
        widget->InPath = FALSE;
        widget->Codec = codec;

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

//    if (conn == 1 && connections == 0)
//        use = FALSE;

//    if ((cap & 0x6) == 0)
//        use = FALSE;

    if (use)
    {
        widget = (struct TPinComplex *)RdosAllocateSmallGlobalMem(sizeof(struct TPinComplex));
        widget->Type = AUDIO_WIDGET_TYPE_PIN;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;
        widget->InPath = FALSE;
        widget->Codec = codec;
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

        if (widget->Connectivity == 0)
        {
            switch (widget->Device)
            {
                case 0:
                case 1:
                case 2:
                    if (widget->PinCap & 0x10)
                    {
                        if (OutputCount < MAX_OUTPUTS)
                        {
                            OutputArr[OutputCount] = widget;
                            OutputCount++;
                        }
                    }
                    break;
                    
                case 8:
                case 10:
                    if (widget->PinCap & 0x20)
                    {
                        if (InputCount < MAX_OUTPUTS)
                        {
                            InputArr[InputCount] = widget;
                            InputCount++;
                        }
                    }
                    break;
            }
        }
        else
        {
            if (widget->Connectivity == 2 && widget->Device == 1)
               FixedSpeaker = widget;
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
        widget->InPath = FALSE;
        widget->Codec = codec;

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
#   Name       : AddBeepWidget
#
#   Purpose....: Add beep widget
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddBeepWidget(struct TCodec *codec, int node, int cap, int channels)
{
    struct TBeepWidget *widget;
    int connections;
    int i;

    connections = GetParam(codec, node, 0xE);

    if (connections < 0x80)
    {
        widget = (struct TBeepWidget *)RdosAllocateSmallGlobalMem(sizeof(struct TBeepWidget));
        widget->Type = AUDIO_WIDGET_TYPE_BEEP;
        widget->Id = codec->Id;
        widget->Address = codec->Address;
        widget->Node = node;
        widget->Cap = cap;
        widget->Channels = channels;
        widget->InPath = FALSE;
        widget->Codec = codec;

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

    codec->VendorID = Query(codec, 0, 0xF0000);
    codec->DeviceID = codec->VendorID & 0xFFFF;
    codec->VendorID = (codec->VendorID >> 16) & 0xFFFF;    

    Vendor = GetParam(codec, 0, 0);
    SubSys = GetParam(codec, 0, 1);

    Query(codec, 1, 0x70500);
    PowerState = Query(codec, 1, 0xF0500);

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

        Query(codec, codec->AudioNode, 0x70500);

        for (i = 0; i < count; i++)
        {
            Query(codec, node + i, 0x70500);

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

                case 7:
                    AddBeepWidget(codec, node + i, val, channels);
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
#   Name       : IsInputAmpMuted
#
#   Purpose....: Check if input amp is muted
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsInputAmpMuted(int id, int address, int node, int index)
{
    int val;
    int verb;
    
    verb = 0xB0000;
    verb |= index;
    
    val = QueryCodec(id, address, node, verb);
    if (val & 0x80)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : IsOutputAmpMuted
#
#   Purpose....: Check if output amp is muted
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsOutputAmpMuted(int id, int address, int node)
{
    int verb;
    int val;

    verb = 0xB8000;
    
    val = QueryCodec(id, address, node, verb);
    if (val & 0x80)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : ShowCap
#
#   Purpose....: Show cap info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowCap(int id, int address, int node, int Cap, char *Info)
{
    int verb;
    int val;

    if (Cap & 0x200)
        strcat(Info, ", Digital");

    if (Cap & 0x40)
        strcat(Info, ", Proc");

    if (Cap & 0x20)
        strcat(Info, ", Stripe");

    if ((Cap & 8) == 0)
        strcat(Info, ", Glob amp");

    verb = 0xF0500;    
    val = QueryCodec(id, address, node, verb);
    if (val & 0xF0)
        strcat(Info, ", Low Power");
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
    char str[40];
    int val;
    int stream;
    int channel;
    int channels;
    
    strcpy(Info, "Audio Out");

    val = QueryCodec(widget->Id, widget->Address, widget->Node, 0xA0000);
    sprintf(str, ", Format: %04hX", val);
    strcat(Info, str);

    val = QueryCodec(widget->Id, widget->Address, widget->Node, 0xF0600);
    stream = (val & 0xF0) >> 4;
    channel = val & 0xF;
    sprintf(str, ", Stream: %d, ", stream);
    strcat(Info, str);

    val = QueryCodec(widget->Id, widget->Address, widget->Node, 0xF0009);
    channels = (val >> 12) & 7;
    if (val & 1)
        channels++;
    channels++;
    sprintf(str, "Channel: %d-%d", channel, channel + channels - 1);
    strcat(Info, str);

    val = QueryCodec(widget->Id, widget->Address, widget->Node, 0xF000A);

    if (val & 0x100000)
        strcat(Info, ", 32-bit");
    else
    {
        if (val & 0x80000)
            strcat(Info, ", 24-bit");
        else
        {
            if (val & 0x40000)
                strcat(Info, ", 20-bit");
            else
            {
                if (val & 0x20000)
                    strcat(Info, ", 16-bit");
            }
        }
    }

    val = QueryCodec(widget->Id, widget->Address, widget->Node, 0xF2400);
    switch (val & 0x3)
    {
        case 1:
            strcat(Info, ", 2 SDOs");
            break;

        case 2:
            strcat(Info, ", 4 SDOs");
            break;
    }                    
    
    if ((widget->Cap & 0x10) == 0)
        strcat(Info, ", Global Format");

    ShowCap(widget->Id, widget->Address, widget->Node, widget->Cap, Info);
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

    if ((widget->Cap & 0x10) == 0)
        strcat(Info, ", Global Format");

    ShowCap(widget->Id, widget->Address, widget->Node, widget->Cap, Info);
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

    ShowCap(widget->Id, widget->Address, widget->Node, widget->Cap, Info);
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

    ShowCap(widget->Id, widget->Address, widget->Node, widget->Cap, Info);
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
    int val;
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

    val = QueryCodec(widget->Id, widget->Address, widget->Node, 0xF0700);

    if (val & 0x80)
        strcat(Info, ", HP On");

    if (val & 0x40)
        strcat(Info, ", Out enable");

    if (val & 0x20)
        strcat(Info, ", In enable");

    ShowCap(widget->Id, widget->Address, widget->Node, widget->Cap, Info);
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

    ShowCap(widget->Id, widget->Address, widget->Node, widget->Cap, Info);
}

/*##########################################################################
#
#   Name       : GetBeepWidgetInfo
#
#   Purpose....: Get beep widget info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetBeepWidgetInfo(struct TBeepWidget *widget, char *Info)
{
    strcpy(Info, "Beep");

    ShowCap(widget->Id, widget->Address, widget->Node, widget->Cap, Info);
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

            case AUDIO_WIDGET_TYPE_BEEP:
                GetBeepWidgetInfo((struct TBeepWidget *)Widget, Info);
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
#   Name       : GetAudioCodecVersion
#
#   Purpose....: Get audio codec version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioCodecVersion "*" rdosdev parm routine [eax] [edx] value [edx eax]
long long __far ImplGetAudioCodecVersion(int Device, int CodecNr)
{
    long long val = 0;
    struct TFunction *Function;
    struct TCodec *Codec = 0;
    
    if (Device < FunctionCount)
    {
        Function = FunctionArr[Device];
        if (Function && CodecNr < Function->CodecCount)
            Codec = Function->CodecArr[CodecNr];
    }

    if (Codec)
    {
        val = CodeLongLong(Codec->DeviceID, Codec->VendorID);
        RdosSetSuccess();
    }
    else
        RdosSetFailure();
        
    return val;
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
#   Name       : CreateInputVolumeControl
#
#   Purpose....: Create an input volume control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TVolumeControl *CreateInputVolumeControl(struct TWidget *widget, int entry)
{
    struct TVolumeControl *volume;
    
    volume = (struct TVolumeControl *)RdosAllocateSmallGlobalMem(sizeof(struct TVolumeControl));
    volume->IsInputAmp = TRUE;
    volume->InputEntry = entry;
    volume->Widget = widget;
    volume->MinVol = -widget->InputAmp.Offset * widget->InputAmp.StepSize;
    volume->MaxVol = (widget->InputAmp.NumSteps - widget->InputAmp.Offset - 1) * widget->InputAmp.StepSize;
    volume->CurrVol = 0;    
    return volume;
}

/*##########################################################################
#
#   Name       : CreateOutputVolumeControl
#
#   Purpose....: Create an output volume control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TVolumeControl *CreateOutputVolumeControl(struct TWidget *widget)
{
    struct TVolumeControl *volume;
    
    volume = (struct TVolumeControl *)RdosAllocateSmallGlobalMem(sizeof(struct TVolumeControl));
    volume->IsInputAmp = FALSE;
    volume->InputEntry = 0;
    volume->Widget = widget;
    volume->MinVol = -widget->OutputAmp.Offset * widget->OutputAmp.StepSize;
    volume->MaxVol = (widget->OutputAmp.NumSteps - widget->OutputAmp.Offset - 1) * widget->OutputAmp.StepSize;
    volume->CurrVol = 0;    
    return volume;
}

/*##########################################################################
#
#   Name       : FreeVolumeControl
#
#   Purpose....: Free volume control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void FreeVolumeControl(struct TVolumeControl *volume)
{
    int sel;

    sel = RdosPointerToSelector(volume);
    RdosFreeMem(sel);
}

/*##########################################################################
#
#   Name       : CheckOutputAmp
#
#   Purpose....: Check output amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CheckOutputAmp(struct TWidget *widget)
{
    struct TAmp *amp = &widget->OutputAmp;
    struct TVolumeControl *volume;
    
    if (amp->NumSteps > 1)
    {
        volume = CreateOutputVolumeControl(widget);
        OutputVolumeArr[OutputVolumeControls] = volume;
        OutputVolumeControls++;
    }
}

/*##########################################################################
#
#   Name       : CheckInputAmp
#
#   Purpose....: Check input amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CheckInputAmp(struct TWidget *widget, int entry)
{
    struct TAmp *amp = &widget->InputAmp;
    struct TVolumeControl *volume;
    
    if (amp->NumSteps > 1)
    {
        volume = CreateInputVolumeControl(widget, entry);
        OutputVolumeArr[OutputVolumeControls] = volume;
        OutputVolumeControls++;
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

    if (!found && OutputCount > 0)
    {
        widget = OutputArr[0];
        found = TRUE;
    }
    
    if (found)
        return widget;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : CreateOutputVolumeControls
#
#   Purpose....: Create output volume controls
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CreateOutputVolumeControls(struct TWidget *widget)
{
    int i;

    if (widget->Type == AUDIO_WIDGET_TYPE_OUTPUT)
        CheckOutputAmp(widget);
    else
    {
        i = FindOutputPath(widget);
        if (i >= 0)
        {
            CheckOutputAmp(widget);
            CheckInputAmp(widget, i);
            CreateOutputVolumeControls(widget->ConnectionList[i]);
        }
    }
}

/*##########################################################################
#
#   Name       : FreeOutputVolumeControls
#
#   Purpose....: Free output volume controls
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void FreeOutputVolumeControls()
{
    int i;

    for (i = 0; i < OutputVolumeControls; i++)
        FreeVolumeControl(OutputVolumeArr[i]);

    OutputVolumeControls = 0;
}

/*##########################################################################
#
#   Name       : UpdateVolume
#
#   Purpose....: Update output volume
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void UpdateOutputVolume()
{
    struct TVolumeControl *volume;
    struct TWidget *widget;
    int i;
    int lval = OutputLVol;
    int rval = OutputRVol;
    int set_l;
    int set_r;

    for (i = 0; i < OutputVolumeControls; i++)
    {
        volume = OutputVolumeArr[i];
        if (volume)
        {
            widget = volume->Widget;

            if (OutputMute)
            {
                if (volume->IsInputAmp)
                    MuteInputAmp(widget, &widget->InputAmp, volume->InputEntry);
                else                    
                    MuteOutputAmp(widget, &widget->OutputAmp);
            }
            else
            {
                set_l = 0;

                if (lval > 0)
                {
                    if (volume->MaxVol > 0)
                    {
                        if (volume->MaxVol > lval)
                            set_l = lval;
                        else
                            set_l = volume->MaxVol;

                        if (set_l < volume->MinVol)
                            set_l = volume->MinVol;
                    }
                }

                if (lval < 0)
                {
                    if (volume->MinVol < 0)
                    {
                        if (volume->MinVol < lval)
                            set_l = lval;
                        else
                            set_l = volume->MinVol;

                        if (set_l > volume->MaxVol)
                            set_l = volume->MaxVol;
                    }
                }

                set_r = 0;

                if (rval > 0)
                {
                    if (volume->MaxVol > 0)
                    {
                        if (volume->MaxVol > rval)
                            set_r = rval;
                        else
                            set_r = volume->MaxVol;

                        if (set_r < volume->MinVol)
                            set_r = volume->MinVol;
                    }
                }

                if (rval < 0)
                {
                    if (volume->MinVol < 0)
                    {
                        if (volume->MinVol < rval)
                            set_r = rval;
                        else
                            set_r = volume->MinVol;

                        if (set_r > volume->MaxVol)
                            set_r = volume->MaxVol;
                    }
                }

                if (volume->IsInputAmp)
                    SetInputAmp(widget, volume->InputEntry, set_l, set_r);
                else                    
                    SetOutputAmp(widget, set_l, set_r);

                lval -= set_l;
                rval -= set_r;
            }
            
        }
    }
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

    widget->InPath = TRUE;

    if (widget->Type == AUDIO_WIDGET_TYPE_OUTPUT)
    {
        if (widget->OutputAmp.NumSteps < 2)
            SetOutputAmp(widget, 0, 0);

        OutputWidget = (struct TAudioOutput *)widget;
    }
    else
    {
        i = FindOutputPath(widget);
        if (i >= 0)
        {
            if (widget->OutputAmp.NumSteps < 2)
                SetOutputAmp(widget, 0, 0);

            if (widget->InputAmp.NumSteps < 2)
                SetInputAmp(widget, i, 0, 0);

            ActivateOutput(widget->ConnectionList[i]);
        }
    }
}

/*##########################################################################
#
#   Name       : DeactivateOutput
#
#   Purpose....: Deactivate output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DeactivateOutput(struct TWidget *widget)
{
    int i;

    widget->InPath = FALSE;

    if (widget->Type == AUDIO_WIDGET_TYPE_OUTPUT)
        MuteOutputAmp(widget, &widget->OutputAmp);
    else
    {
        i = FindOutputPath(widget);
        if (i >= 0)
        {
            MuteOutputAmp(widget, &widget->OutputAmp);
            MuteInputAmp(widget, &widget->InputAmp, i);
            DeactivateOutput(widget->ConnectionList[i]);
        }
    }
}

/*##########################################################################
#
#   Name       : GetAudioOutputVolume
#
#   Purpose....: Get audio output volume
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAudioOutputVolume "*" rdosdev parm routine value [edx eax]
long long __far ImplGetAudioOutputVolume()
{
    int l, r;
    long long val = 0;

    if (OutputMute)
        l = -1;
    else
        l = (400 + OutputLVol) / 4;

    if (OutputMute)
        r = -1;
    else
        r = (400 + OutputRVol) / 4;

    val = CodeLongLong(l, r);
    RdosSetSuccess();
    return val;
}

/*##########################################################################
#
#   Name       : SetAudioOutputVolume
#
#   Purpose....: Set audio output volume
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplSetAudioOutputVolume "*" rdosdev parm routine [eax] [edx]
void __far ImplSetAudioOutputVolume(int l, int r)
{
    if (l < 0 && r < 0)
        OutputMute = TRUE;
    else
    {
        OutputMute = FALSE;

        if (l < 0)
            l = 0;

        OutputLVol = 4 * l - 400;

        if (r < 0)
            r  = 0;

        OutputRVol = 4 * r - 400;
    }

    RdosEnterKernelSection(&OutputSection);

    if (OutputVolumeControls)
        UpdateOutputVolume();

    RdosLeaveKernelSection(&OutputSection);

    RdosSetSuccess();
}

/*##########################################################################
#
#   Name       : TurnOnOutput
#
#   Purpose....: Turn on output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TurnOnOutput(struct TPinComplex *widget)
{
    int hp = FALSE;
    int verb;

    if (widget->PinCap & 0x10)
        if (widget->PinCap & 0x8)
            hp = TRUE;

    verb = 0x70700;
    if (hp)
        verb |= 0xC0;
    else
        verb |= 0x40;

    QueryCodec(widget->Id, widget->Address, widget->Node, verb);

    if (widget->PinCap & 0x10000)
    {
        verb = 0x70C02;
        QueryCodec(widget->Id, widget->Address, widget->Node, verb);
    }
}

/*##########################################################################
#
#   Name       : AssignOutput
#
#   Purpose....: Assign output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AssignOutput(struct TWidget *widget)
{
    struct TCodec *codec = widget->Codec;

    CreateOutputVolumeControls(widget);
    UpdateOutputVolume();
    ActivateOutput(widget);

    if (codec->VendorID == 0x10EC && codec->DeviceID == 0x892)
        if (widget == (struct TWidget *)FixedSpeaker)
            TurnOnOutput(OutputArr[0]);
}

/*##########################################################################
#
#   Name       : DeassignOutput
#
#   Purpose....: Deassign output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DeassignOutput(struct TWidget *widget)
{
    FreeOutputVolumeControls();
    DeactivateOutput(widget);
}

/*##########################################################################
#
#   Name       : UpdateOutput
#
#   Purpose....: Update output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void UpdateOutput()
{
    struct TPinComplex *pin;

    RdosEnterKernelSection(&OutputSection);

    pin = DetermineActiveOutput();
    if (pin != CurrentOutput)
    {
        if (CurrentOutput)
            DeassignOutput((struct TWidget *)CurrentOutput);

        AssignOutput((struct TWidget *)pin);
        TurnOnOutput(pin);
    }
    CurrentOutput = pin;    

    RdosLeaveKernelSection(&OutputSection);
}

/*##########################################################################
#
#   Name       : HasAudio
#
#   Purpose....: Check for audio
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplHasAudio "*" rdosdev parm routine
void __far ImplHasAudio()
{
    UpdateOutput();

    if (CurrentOutput)
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : SetDacRate
#
#   Purpose....: Try to set a DAC rate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplSetDacRate "*" rdosdev parm routine [eax]
void __far ImplSetDacRate(int rate)
{
    int verb;
    int format;
    int width = 4;

    UpdateOutput();

    if (OutputWidget)
    {
        verb = 0x72D00; 
        verb |= 2;
        QueryCodec(OutputWidget->Id, OutputWidget->Address, OutputWidget->Node, verb);

        verb = 0x70600; 
        verb |= (OUTPUT_STREAM << 4);
        QueryCodec(OutputWidget->Id, OutputWidget->Address, OutputWidget->Node, verb);

        if (rate == 44100)
            format = 0x4000;
        else
            format = 0;

        format |= 1; /* 2 channels for now */

        if (OutputWidget->PcmRates & 0x100000)
            format |= 0x40;
        else
        {
            if (OutputWidget->PcmRates & 0x80000)
                format |= 0x30;
            else
            {
                if (OutputWidget->PcmRates & 0x40000)
                    format |= 0x20;
                else
                {
                    width = 2;
                    if (OutputWidget->PcmRates & 0x20000)
                        format |= 0x10;
                }
            }
        }

        verb = 0x20000; 
        verb |= format;
        QueryCodec(OutputWidget->Id, OutputWidget->Address, OutputWidget->Node, verb);

        verb = 0x70301; 
        QueryCodec(OutputWidget->Id, OutputWidget->Address, OutputWidget->Node, verb);

        OutputWidget->Format = format;
        OutputWidget->Width = width;

        SetOutputFormat(OutputWidget->Id, OutputWidget->Address, format, width);
    
        RdosSetSuccess();
    }        
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : GetDacRate
#
#   Purpose....: Get DAC rate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetDacRate "*" rdosdev parm routine value [eax]
int __far ImplGetDacRate()
{
    int rate = 48000;
    
    if (OutputWidget)
    {
        if (OutputWidget->Format & 0x4000)
            rate = 44100;
            
        RdosSetSuccess();
    }
    else
        RdosSetFailure();

    return rate;
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
//        DebugStream();
        RdosWaitMilli(250);
//        UpdateOutput();
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
    RdosInitKernelSection(&OutputSection);

    RdosRegisterOsGate(osgate_get_audio_dac_rate, (__rdos_gate_callback *)&ImplGetDacRate, "Get Dac Rate");
    RdosRegisterOsGate(osgate_set_audio_dac_rate, (__rdos_gate_callback *)&ImplSetDacRate, "Set Dac Rate");
    
    RdosRegisterBimodalUserGate(usergate_has_audio, (__rdos_gate_callback *)&ImplHasAudio, "Has Audio?");
    RdosRegisterBimodalUserGate(usergate_get_audio_device_count, (__rdos_gate_callback *)&ImplGetAudioDeviceCount, "Get Audio Device Count");
    RdosRegisterBimodalUserGate(usergate_get_audio_codec_count, (__rdos_gate_callback *)&ImplGetAudioCodecCount, "Get Audio Device Count");
    RdosRegisterBimodalUserGate(usergate_get_audio_codec_version, (__rdos_gate_callback *)&ImplGetAudioCodecVersion, "Get Audio Codec Version");
    RdosRegisterUserGate(usergate_get_audio_widget_info, (__rdos_gate_callback *)&ImplGetAudioWidgetInfo16, (__rdos_gate_callback *)&ImplGetAudioWidgetInfo32, "Get Audio Widget Info");
    RdosRegisterUserGate(usergate_get_audio_widget_connection_list, (__rdos_gate_callback *)&ImplGetAudioConnectionList16, (__rdos_gate_callback *)&ImplGetAudioConnectionList32, "Get Audio Connection List");
    RdosRegisterBimodalUserGate(usergate_get_selected_audio_connection, (__rdos_gate_callback *)&ImplGetSelectedAudioConnection, "Get Selected Audio Connection");
    RdosRegisterBimodalUserGate(usergate_get_audio_input_amp_cap, (__rdos_gate_callback *)&ImplGetAudioInputAmpCap, "Get Audio Input Amp Cap");
    RdosRegisterBimodalUserGate(usergate_get_audio_output_amp_cap, (__rdos_gate_callback *)&ImplGetAudioOutputAmpCap, "Get Audio Output Amp Cap");
    RdosRegisterBimodalUserGate(usergate_has_audio_input_mute, (__rdos_gate_callback *)&ImplHasAudioInputMute, "Has Audio Input Mute");
    RdosRegisterBimodalUserGate(usergate_has_audio_output_mute, (__rdos_gate_callback *)&ImplHasAudioOutputMute, "Has Audio Output Mute");
    RdosRegisterBimodalUserGate(usergate_read_audio_input_amp, (__rdos_gate_callback *)&ImplReadAudioInputAmp, "Read Audio Input Amp");
    RdosRegisterBimodalUserGate(usergate_read_audio_output_amp, (__rdos_gate_callback *)&ImplReadAudioOutputAmp, "Read Audio Output Amp");
    RdosRegisterBimodalUserGate(usergate_is_audio_input_amp_muted, (__rdos_gate_callback *)&ImplIsAudioInputAmpMuted, "Is Audio Input Amp Muted");
    RdosRegisterBimodalUserGate(usergate_is_audio_output_amp_muted, (__rdos_gate_callback *)&ImplIsAudioOutputAmpMuted, "Is Audio Output Amp Muted");
    RdosRegisterBimodalUserGate(usergate_get_output_volume, (__rdos_gate_callback *)&ImplGetAudioOutputVolume, "Get Audio Output Volume");
    RdosRegisterBimodalUserGate(usergate_set_output_volume, (__rdos_gate_callback *)&ImplSetAudioOutputVolume, "Set Audio Output Volume");

//    RdosRegisterBimodalUserGate(usergate_test_gate, (__rdos_gate_callback *)&ImplTestGate, "Test Gate"); 
    return 0;
}
