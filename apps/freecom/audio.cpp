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
# audio.cpp
# Audio command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "audio.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TAudioFactory::TAudioFactory
#
#   Purpose....: Constructor for TAudioFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAudioFactory::TAudioFactory()
  : TCommandFactory("AUDIO")
{
}

/*##########################################################################
#
#   Name       : TAudioFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TAudioFactory::Create(TSession *session, const char *param)
{
        return new TAudioCommand(session, param);
}

/*##########################################################################
#
#   Name       : TAudioCommand::TAudioCommand
#
#   Purpose....: Constructor for TAudioCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAudioCommand::TAudioCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_AUDIO);
}

/*##########################################################################
#
#   Name       : TAudioCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::InitOptions()
{
    FOptD = FALSE;
}

/*##########################################################################
#
#   Name       : TAudioCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAudioCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
    switch (ch)
    {
        case 'D':
            return OptScanBool(optstr, bool, strarg, &FOptD);
    }
    OptError(optstr);
    return E_Useage;
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteOutputAmp
#
#   Purpose....: Write output amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteOutputAmp(int dev, int codec, int node, const char *init)
{
    int mute;
    int min;
    int max;
    long double lmin;
    long double lmax;
    int val;
    long double r, l;
    int mr, ml;
    char str[40];

    mute = RdosHasAudioOutputMute(dev, codec, node);

    RdosGetAudioOutputAmpCap(dev, codec, node, &min, &max);
    if (mute || min || max)
    {
        Write(init);

        if (min || max)
        {
            val = RdosReadAudioOutputAmp(dev, codec, node, 0);
            r = (long double)val / 4.0;

            val = RdosReadAudioOutputAmp(dev, codec, node, 1);
            l = (long double)val / 4.0;

            if (mute)
            {
                mr = RdosIsAudioOutputAmpMuted(dev, codec, node, 0);
                ml = RdosIsAudioOutputAmpMuted(dev, codec, node, 1);
            }
            else
            {
                mr = FALSE;
                ml = FALSE;
            }

            if ((l == r) && (mr == ml))
            {
                if (mr)
                    Write("Off");
                else
                {
                    if (l == 0)
                        Write("On");
                    else
                    {
                        sprintf(str, "%0.1Lf", l);
                        Write(str);
                    }
                }
            }
            else
            {
                Write("L=");

                if (ml)
                    Write("Off");
                else
                {
                    sprintf(str, "%0.1Lf", l);
                    Write(str);
                }

                Write(", R=");

                if (mr)
                    Write("Off");
                else
                {
                    sprintf(str, "%0.1Lf", r);
                    Write(str);
                }
            }

            lmin = (long double)min / 4.0;
            lmax = (long double)max / 4.0;

            sprintf(str, " (%0.1Lf-%0.1Lf)", lmin, lmax, l);
            Write(str);
        }
        else
        {
            mr = RdosIsAudioOutputAmpMuted(dev, codec, node, 0);
            ml = RdosIsAudioOutputAmpMuted(dev, codec, node, 1);

            if (mr == ml)
            {
                if (mr)
                    Write("Off");
                else
                    Write("On");
            }
            else
            {
                Write("L=");

                if (ml)
                    Write("Off");
                else
                    Write("On");

                Write(", R=");

                if (mr)
                    Write("Off");
                else
                    Write("On");

            }
        }
    }
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteInputAmp
#
#   Purpose....: Write input amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteInputAmp(int dev, int codec, int node, int input, const char *init)
{
    int mute;
    int min;
    int max;
    int val;
    long double r, l;
    int mr, ml;
    char str[40];

    mute = RdosHasAudioInputMute(dev, codec, node);

    RdosGetAudioInputAmpCap(dev, codec, node, &min, &max);
    if (mute || min || max)
    {
        if (min || max)
        {
            val = RdosReadAudioInputAmp(dev, codec, node, 0, input);
            r = (long double)val / 4.0;

            val = RdosReadAudioInputAmp(dev, codec, node, 1, input);
            l = (long double)val / 4.0;

            if (mute)
            {
                mr = RdosIsAudioInputAmpMuted(dev, codec, node, 0, input);
                ml = RdosIsAudioInputAmpMuted(dev, codec, node, 1, input);
            }
            else
            {
                mr = FALSE;
                ml = FALSE;
            }

            if ((l == r) && (mr == ml))
            {
                if (!mr)
                {
                    if (l == 0)
                        Write("*");
                    else
                    {
                        Write(init);
                        sprintf(str, "%0.1Lf", l);
                        Write(str);
                    }
                }
            }
            else
            {
                Write(init);
                Write("L=");

                if (ml)
                    Write("Off");
                else
                {
                    sprintf(str, "%0.1Lf", l);
                    Write(str);
                }

                Write(", R=");

                if (mr)
                    Write("Off");
                else
                {
                    sprintf(str, "%0.1Lf", r);
                    Write(str);
                }
            }
        }
        else
        {
            mr = RdosIsAudioInputAmpMuted(dev, codec, node, 0, input);
            ml = RdosIsAudioInputAmpMuted(dev, codec, node, 1, input);

            if (mr == ml)
            {
                if (!mr)
                    Write("*");
            }
            else
            {
                Write(init);

                Write("L=");

                if (ml)
                    Write("Off");
                else
                    Write("On");

                Write(", R=");

                if (mr)
                    Write("Off");
                else
                    Write("On");

            }
        }
    }
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteInputAmpCommon
#
#   Purpose....: Write input amp common
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteInputAmpCommon(int dev, int codec, int node, const char *init)
{
    int min;
    int max;
    long double lmin;
    long double lmax;
    char str[40];

    RdosGetAudioInputAmpCap(dev, codec, node, &min, &max);
    if (min || max)
    {
        lmin = (long double)min / 4.0;
        lmax = (long double)max / 4.0;

        Write(init);
        sprintf(str, "%0.1Lf-%0.1Lf", lmin, lmax);
        Write(str);
    }
}

/*##########################################################################
#
#   Name       : TAudioCommand::HasInputAmp
#
#   Purpose....: Check for input amp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAudioCommand::HasInputAmp(int dev, int codec, int node)
{
    int mute;
    int min;
    int max;

    mute = RdosHasAudioInputMute(dev, codec, node);

    RdosGetAudioInputAmpCap(dev, codec, node, &min, &max);
    if (mute || min || max)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteInputList
#
#   Purpose....: Write input list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteInputList(int dev, int codec, int node)
{
    int Count;
    int i;
    int ConnectionList[256];
    char str[40];

    Count = RdosGetAudioWidgetConnectionList(dev, codec, node, ConnectionList);

    if (Count)
        Write(", (");

    for (i = 0; i < Count; i++)
    {
        sprintf(str, "%d", ConnectionList[i]);
        Write(str);
        strcpy(str, ": ");
        WriteInputAmp(dev, codec, node, i, str);

        if (i == Count - 1)
            Write(")");
        else
            Write(", ");
    }

    WriteInputAmpCommon(dev, codec, node, ", ");
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteSelectList
#
#   Purpose....: Write select list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteSelectList(int dev, int codec, int node)
{
    int Count;
    int CurrConn;
    int i;
    int ConnectionList[256];
    char str[40];

    Count = RdosGetAudioWidgetConnectionList(dev, codec, node, ConnectionList);

    if (Count)
    {
        Write(" (");
        CurrConn = RdosGetSelectedAudioConnection(dev, codec, node);
    }

    for (i = 0; i < Count; i++)
    {
        sprintf(str, "%d", ConnectionList[i]);
        Write(str);

        if (CurrConn == i)
            Write("*");

        if (i == Count - 1)
            Write(")");
        else
            Write(", ");
    }
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteAudioOutput
#
#   Purpose....: Write audio output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteAudioOutput(int dev, int codec, int node)
{
    WriteOutputAmp(dev, codec, node, ", ");
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteAudioInput
#
#   Purpose....: Write audio input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteAudioInput(int dev, int codec, int node)
{
    WriteInputList(dev, codec, node);
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteAudioMixer
#
#   Purpose....: Write audio mixer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteAudioMixer(int dev, int codec, int node)
{
    WriteOutputAmp(dev, codec, node, ", ");
    WriteInputList(dev, codec, node);
}

/*##########################################################################
#
#   Name       : TAudioCommand::WriteAudioSelector
#
#   Purpose....: Write audio selector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WriteAudioSelector(int dev, int codec, int node)
{
    WriteSelectList(dev, codec, node);
}

/*##########################################################################
#
#   Name       : TAudioCommand::WritePinComplex
#
#   Purpose....: Write pin complex
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::WritePinComplex(int dev, int codec, int node)
{
    WriteOutputAmp(dev, codec, node, ", ");
    WriteSelectList(dev, codec, node);
}

/*##########################################################################
#
#   Name       : TAudioCommand::ShowFull
#
#   Purpose....: Show full
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::ShowFull()
{
    int i;
    int j;
    int k;
    int FunctionCount;
    int CodecCount;
    char Info[512];
    char Type;
    char str[256];
    char *ptr;
    int VendorId;
    int DeviceId;

    FunctionCount = RdosGetAudioDeviceCount();

    for (i = 0; i < FunctionCount; i++)
    {
        sprintf(str, "Audio device: %d\r\n", i);
        Write(str);

        CodecCount = RdosGetAudioCodecCount(i);

        for (j = 0; j < CodecCount; j++)
        {
            sprintf(str, "Codec device: %d, ", j);
            Write(str);

            if (RdosGetAudioCodecVersion(i, j, &VendorId, &DeviceId))
            {
                switch (VendorId)
                {
                    case 0x10EC:
                        Write("ALC");
                        sprintf(str, "%04hX", DeviceId);
                        ptr = str;
                        while (*ptr == '0')
                            ptr++;
                        strcat(ptr, "\r\n");
                        Write(ptr);
                        break;

                    case 0:
                        Write("\r\n");
                        break;

                    default:
                        sprintf(str, "Vendor: %04hX, Device: %04hX\r\n", VendorId, DeviceId);
                        Write(str);
                        break;
                }
            }


            for (k = 0; k < 128; k++)
            {
                Type = RdosGetAudioWidgetInfo(i, j, k, Info);

                if (Type)
                {
                    sprintf(str, "%3d: ", k);
                    Write(str);
                    Write(Info);
                }

                switch (Type)
                {
                    case AUDIO_WIDGET_TYPE_OUTPUT:
                        WriteAudioOutput(i, j, k);
                        break;

                    case AUDIO_WIDGET_TYPE_INPUT:
                        WriteAudioInput(i, j, k);
                        break;

                    case AUDIO_WIDGET_TYPE_MIXER:
                        WriteAudioMixer(i, j, k);
                        break;

                    case AUDIO_WIDGET_TYPE_SELECTOR:
                        WriteAudioSelector(i, j, k);
                        break;

                    case AUDIO_WIDGET_TYPE_PIN:
                        WritePinComplex(i, j, k);
                        break;
                }

                if (Type)
                    Write("\r\n");
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TAudioCommand::ShowDevice
#
#   Purpose....: Show devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAudioCommand::ShowDevices()
{
    int ok;
    int i;
    int dev;
    int codec;
    int node;
    char Info[512];

    ok = RdosGetFixedAudioOutput(&dev, &codec, &node);
    if (ok)
    {
        Write("Fixed output:\r\n1: ");

        WriteOutputAmp(dev, codec, node, "");
        Write(", ");

        RdosGetAudioWidgetInfo(dev, codec, node, Info);
        Write(Info);

        sprintf(Info, " (%d.%d.%d)", dev, codec, node);
        Write(Info);
        Write("\r\n\r\n");
    }

    for (i = 0; i < 256; i++)
    {
        ok = RdosGetJackAudioOutput(i, &dev, &codec, &node);
        if (ok)
        {
            if (i == 0)
                Write("Jack output:\r\n");

            sprintf(Info, "%d: ", i + 1);
            Write(Info);

            WriteOutputAmp(dev, codec, node, "");
            Write(", ");

            RdosGetAudioWidgetInfo(dev, codec, node, Info);
            Write(Info);

            sprintf(Info, " (%d.%d.%d)", dev, codec, node);
            Write(Info);
            Write("\r\n");
        }
        else
        {
            if (i != 0)
                Write("\r\n");
            break;
        }
    }

    for (i = 0; i < 256; i++)
    {
        ok = RdosGetJackAudioInput(i, &dev, &codec, &node);
        if (ok)
        {
            if (i == 0)
                Write("Jack input:\r\n");

            sprintf(Info, "%d: ", i + 1);
            Write(Info);

            RdosGetAudioWidgetInfo(dev, codec, node, Info);
            Write(Info);
            sprintf(Info, " (%d.%d.%d)", dev, codec, node);
            Write(Info);
            Write("\r\n");
        }
        else
        {
            if (i != 0)
                Write("\r\n");
            break;
        }
    }
}

/*##########################################################################
#
#   Name       : TAudioCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAudioCommand::Execute(char *param)
{
    InitOptions();

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FOptD)
    {
        ShowFull();
        return 0;
    }
    else
    {
        ShowDevices();
        return 0;
    }
}
