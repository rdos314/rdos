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
# mp3.h
# MP3 player class
#
########################################################################*/

#ifndef _MP3_H
#define _MP3_H

#include "mp3tag.h"
#include "decoder.h"
#include "sigdev.h"

class TMp3Player : protected TMadDecoder
{
public:
    TMp3Player();
    ~TMp3Player();

    void Close();
    void Load(const char *FileName);

    void SetVolume(int vol);
    void SetPosition(int ms);

    void Play();

    int IsRunning();
    void Start();
    void Stop();

    void Thread();

    int FChannels;
    unsigned int FSampleRate;		/* sampling frequency (Hz) */
    int FSamplesPerFrame;
    long double FAvgBitRate;
    long double FAvgFrameSize;

    enum mad_layer FLayer;			/* audio layer (1, 2, or 3) */
    enum mad_mode FMode;			/* channel mode (see above) */
    enum mad_emphasis FEmphasis;		/* de-emphasis to use (see above) */

    int FModeExtension;			/* additional mode info */

    unsigned long FBitrate;		/* stream bitrate (bps) */
    mad_timer_t FDuration;			/* audio playing time of frame */

    int FHeaderFlags;				/* flags (see below) */

    int FValidTag;
    int FConstantBitRate;

    int FTagFrameSize;
    int FSongFrames;
    int FSongSamples;
    unsigned int FSongMs;
    int FSongBytes;

    TMp3Tag FTag;

protected:
    void FindStart();
    void Check();
    int ParseTag();
    void CalcSongParams();

    bool FThreadRunning;
    bool FReqStop;

    int FAudioHandle;

    int FFileHandle;
    unsigned char *FFileBuf;
    int FFileSize;
    int FValid;
    int FVolume;

    int FId3V1;
    int FId3V2;

    unsigned char *FMp3Start;
    int FMp3Size;

    unsigned char *FCurrentPos;
    TSignalDevice FSignal;

};

#endif
