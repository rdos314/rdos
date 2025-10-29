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
# mp3.cpp
# MP3 player class
#
########################################################################*/

#include <memory.h>
#include <math.h>

#include "rdos.h"
#include "mp3.h"

#define FALSE   0
#define TRUE    !FALSE

#define MIN_FRAME_SIZE 24 // minimal mp3 frame size
#define MAX_FRAME_SIZE 5761 // max frame size

#define SEARCH_DEEP_VBR 200 // check next 200 mp3 frames to determine constant or variable bitrate if no XING header found

#define GetFourByteSyncSafe(value1, value2, value3, value4) (((value1 & 255) << 21) | ((value2 & 255) << 14) | ((value3 & 255) << 7) | (value4 & 255))

/*##########################################################################
#
#   Name       : ThreadStartup
#
#   Purpose....: Startup procedure for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ThreadStartup(void *ptr)
{
        ((TMp3Player *)ptr)->Thread();
}

/*##########################################################################
#
#   Name       : TMp3Player::TMp3Player
#
#   Purpose....: Constructor for TMp3Player
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3Player::TMp3Player()
{
    FFileHandle = 0;
    FFileBuf = 0;
    FFileSize = 0;
    FValid = FALSE;
    FVolume = 100;
    FThreadRunning = false;
    FReqStop = false;
}

/*##########################################################################
#
#   Name       : TMp3Player::~TMp3Player
#
#   Purpose....: Destructor for TMp3Player
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3Player::~TMp3Player()
{
    Close();
}

/*##########################################################################
#
#   Name       : TMp3Player::FindStart
#
#   Purpose....: Find first frame
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::FindStart()
{
    int tagsize;

    if (FFileBuf)
    {
        FId3V1 = FALSE;
        FId3V2 = FALSE;

        FMp3Start = FFileBuf;
        FMp3Size = FFileSize;

        if (FMp3Size > 128 && memcmp(FMp3Start + FMp3Size - 128, "TAG", 3) == 0)
        {
            FMp3Size -= 128;
            FId3V1 = TRUE;
        }

        if (    FMp3Size > 10 &&
                memcmp(FMp3Start, "ID3", 3) == 0 &&
                FMp3Start[6] < 0x80 &&
                FMp3Start[7] < 0x80 &&
                FMp3Start[8] < 0x80 &&
                FMp3Start[9] < 0x80)
        {

            tagsize = GetFourByteSyncSafe(FMp3Start[6], FMp3Start[7], FMp3Start[8], FMp3Start[9]);
            tagsize += 10;

            if (FMp3Size > (tagsize + MIN_FRAME_SIZE))
            {
                FId3V2 = TRUE;

                if (FMp3Start[tagsize] == 0xFF && (FMp3Start[tagsize + 1] & 0xE0) == 0xE0)
                {
                    FMp3Start += tagsize;
                    FMp3Size -= tagsize;
                }
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TMp3Player::Check
#
#   Purpose....: Check for valid frames
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::Check()
{
    unsigned char *FirstFrame;
    TMadStream stream;
    TMadFrame frame;

    stream.SetBuffer(FMp3Start, FMp3Size);

    FirstFrame = FMp3Start;

    for (;;)
    {
        if (frame.Decode(&stream))
            if (!MAD_RECOVERABLE(stream.error))
                return;

        FirstFrame =  (unsigned char*) stream.this_frame;

        FSampleRate = frame.Header.samplerate;
        FLayer = frame.Header.layer;
        FMode = frame.Header.mode;
        FChannels = ( frame.Header.mode == MAD_MODE_SINGLE_CHANNEL) ? 1 : 2;
        FEmphasis = frame.Header.emphasis;
        FModeExtension = frame.Header.mode_extension;
        FBitrate = frame.Header.bitrate;
        FHeaderFlags = frame.Header.flags;
        FAvgBitRate = 0;
        FDuration = frame.Header.duration;
        FSamplesPerFrame = (frame.Header.flags & MAD_FLAG_LSF_EXT) ? 576 : 1152;

        if (frame.Decode(&stream))
            if (!MAD_RECOVERABLE(stream.error))
                return;

        if (FSampleRate != frame.Header.samplerate || FLayer != frame.Header.layer)
            continue;

        break;
    }

    FMp3Size -= (FirstFrame - FMp3Start);
    FMp3Start = FirstFrame;

    FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TMp3Player::ParseTag
#
#   Purpose....: Parse tags
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMp3Player::ParseTag()
{
    TMadStream stream;
    TMadFrame frame;

    FValidTag = FALSE;

    stream.SetBuffer(FMp3Start, FMp3Size - MAD_BUFFER_GUARD);

    if (frame.Decode(&stream) == 0)
    {
        // check if first frame is XING frame

        if (FTag.Parse(&stream, &frame) == 0)
        {
            if (FTag.flags & TAG_XING)
            { // we have XING frame
                // calculate song length
                if ((FTag.xing.flags & TAG_XING_FRAMES) && FTag.xing.flags & TAG_XING_TOC)
                {
                    FSongFrames = (unsigned int) FTag.xing.frames;
                    FSongSamples = FSongFrames * FSamplesPerFrame;
                    FSongMs = (unsigned int) ( 1000.0 * (long double) FSongFrames * (long double) FSamplesPerFrame / (long double) FSampleRate);

                    // skip XING frame

                    FMp3Size -= ( stream.next_frame - FMp3Start);
                    FMp3Start = (unsigned char*) stream.next_frame;

                    FSongBytes = FMp3Size;
                    FAvgFrameSize = (long double) FSongBytes / (long double) FSongFrames;
                    FAvgBitRate = (long double) FSongBytes * 8 / (long double)FSongFrames *  (long double) FSampleRate / (long double) FSamplesPerFrame;

                    FTagFrameSize = stream.next_frame - stream.this_frame;
                    FValidTag = TRUE;

                }
            }
        }
    }

    return FValidTag;
}

/*##########################################################################
#
#   Name       : TMp3Player::GetSongParams
#
#   Purpose....: Parse for constant bitrate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::CalcSongParams()
{
    TMadStream stream;
    TMadHeader header;
    unsigned int FrameNum = 0;
    unsigned int size = 0;
    long double len;

    FConstantBitRate = TRUE;

    stream.SetBuffer(FMp3Start, FMp3Size);

    while (FrameNum < SEARCH_DEEP_VBR)
    {
        if (header.ReadAndDecode(&stream) == 0)
        {
            if (MAD_RECOVERABLE(stream.error) != 0)
                break;
        }

        if (FBitrate != header.bitrate)
            FConstantBitRate = FALSE;

        size += header.size;
        FrameNum++;
    }

    if (FConstantBitRate)
    {
        FAvgBitRate = (long double)FBitrate;
        len = (long double)FMp3Size * 8.0 / ((long double)FAvgBitRate / 1000.0);
        FSongMs = (unsigned int)len;
        FSongFrames = (unsigned int)ceil(len / 1000.0 * (long double)FSampleRate / (long double)FSamplesPerFrame);
        FSongSamples = FSongFrames * FSamplesPerFrame;
        FSongBytes = FMp3Size;
        FAvgFrameSize = (long double)FMp3Size / (long double)FSongFrames;
    }
    else
    {
        FSongFrames = (unsigned int)((long double)FrameNum * (long double)FMp3Size / (long double)size);
        FSongSamples = FSongFrames * FSamplesPerFrame;
        FSongMs = (unsigned int)(1000.0 * (long double)FSongFrames * (long double)FSamplesPerFrame / (long double)FSampleRate);
        FSongBytes = FMp3Size;
        FAvgFrameSize = (long double)size / (long double)FrameNum;
        FAvgBitRate = (long double)FSongBytes * 8.0 / (long double)FSongFrames * (long double)FSampleRate / (long double)FSamplesPerFrame;
    }
}

/*##########################################################################
#
#   Name       : TMp3Player::Load
#
#   Purpose....: Load an MP3 and create a file-mapping on it
#
#   In params..: FileName               File to load
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::Load(const char *FileName)
{
    int size;

    Close();

    FValid = FALSE;

    FFileHandle = RdosOpenFile(FileName, 0);

    if (FFileHandle)
    {
        FFileSize = (int)RdosGetFileSize(FFileHandle);
        size = FFileSize;
        size--;
        size = size & 0xFFFFF000;
        size += 0x1000;

        FFileBuf = (unsigned char *)RdosAllocateMem(size);
        RdosReadFile(FFileHandle, FFileBuf, FFileSize);

        FindStart();
        Check();
        if (!ParseTag())
            CalcSongParams();

        SetPosition(0);
    }
}

/*##########################################################################
#
#   Name       : TMp3Player::Close
#
#   Purpose....: Close MP3 file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::Close()
{
    Stop();

    FValid = FALSE;

    if (FFileHandle)
    {
        if (FFileBuf)
        {
            RdosFreeMem(FFileBuf);
            FFileBuf = 0;
        }

        RdosCloseFile(FFileHandle);
        FFileHandle = 0;
    }
}

/*##########################################################################
#
#   Name       : TMp3Player::SetVolume
#
#   Purpose....: Set volume (0..100)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::SetVolume(int val)
{
    FVolume = val;
}

/*##########################################################################
#
#   Name       : TMp3Player::SetPosition
#
#   Purpose....: Set play position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::SetPosition(int ms)
{
    long double pa, pb, px;
    long double percentage;
    int perc;

    if (FValid)
    {
        if (ms > FSongMs)
            ms = FSongMs;

        if (FValidTag)
        {
            if ((FTag.flags & TAG_XING) && (FTag.xing.flags & TAG_XING_TOC))
            {
                percentage = 100.0 * (long double)ms / (long double)FSongMs;
                perc = (int)percentage;

                if (perc > 99)
                    perc = 99;

                pa = FTag.xing.toc[perc];

                if (perc < 99)
                    pb = FTag.xing.toc[perc+1];
                else
                    pb = 256;

                px = pa + (pb - pa) * (percentage - perc);

                FCurrentPos = FMp3Start + (unsigned int)(( (long double)(FMp3Size + FTagFrameSize) / 256.0) * px);
            }
            else
                FCurrentPos = FMp3Start + (unsigned int)( (long double)ms / (long double)FSongMs * (long double)FMp3Size);
        }
        else
            FCurrentPos = FMp3Start + (unsigned int)( (long double)ms / (long double)FSongMs * (long double)FMp3Size);
    }
    else
        FCurrentPos = 0;

}

/*##########################################################################
#
#   Name       : TMp3Player::Play
#
#   Purpose....: Play
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::Play()
{
    TMadStream *stream;
    TMadFrame *frame;
    TMadSynth *synth;
    int size;

    stream = new TMadStream;
    frame = new TMadFrame;
    synth = new TMadSynth;

    FAudioHandle = RdosCreateAudioOutChannel(FSampleRate, 31, FVolume);

    stream->SetBuffer(FCurrentPos, FMp3Size - (FCurrentPos - FMp3Start));

    for (;;)
    {
        if (frame->Decode(stream) == 0)
            if (MAD_RECOVERABLE(stream->error)) // if recoverable error continue
                continue;

        if (stream->error == MAD_ERROR_BUFLEN)
            break;

        synth->Synth(frame);

        size = synth->pcm.length;
        if (synth->pcm.channels >= 2)
            RdosWriteAudio(FAudioHandle, size, (int *)synth->pcm.samples, (int *)(synth->pcm.samples+1));
        else
            RdosWriteAudio(FAudioHandle, size, (int *)synth->pcm.samples, (int *)synth->pcm.samples);

    }

    RdosCloseAudioOutChannel(FAudioHandle);

    delete synth;
    delete frame;
    delete stream;
}

/*##########################################################################
#
#   Name       : TMp3Player::Thread
#
#   Purpose....: Playing thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::Thread()
{
    TMadStream *stream;
    TMadFrame *frame;
    TMadSynth *synth;
    int size;

    stream = new TMadStream;
    frame = new TMadFrame;
    synth = new TMadSynth;

    FAudioHandle = RdosCreateAudioOutChannel(FSampleRate, 31, FVolume);

    stream->SetBuffer(FCurrentPos, FMp3Size - (FCurrentPos - FMp3Start));

    while (FThreadRunning && !FReqStop)
    {
        if (frame->Decode(stream) == 0)
            if (MAD_RECOVERABLE(stream->error)) // if recoverable error continue
                continue;

        if (stream->error == MAD_ERROR_BUFLEN)
            break;

        synth->Synth(frame);

        size = synth->pcm.length;
        if (synth->pcm.channels >= 2)
            RdosWriteAudio(FAudioHandle, size, (int *)synth->pcm.samples, (int *)(synth->pcm.samples+1));
        else
            RdosWriteAudio(FAudioHandle, size, (int *)synth->pcm.samples, (int *)synth->pcm.samples);
    }

    RdosCloseAudioOutChannel(FAudioHandle);

    delete stream;
    delete frame;
    delete synth;

    FThreadRunning = false;
    FSignal.Signal();

}

/*##########################################################################
#
#   Name       : TMp3Player::Start
#
#   Purpose....: Start playing thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::Start()
{
    if (!FThreadRunning)
    {
        FReqStop = false;
        FThreadRunning = true;
        RdosCreatePrioThread(ThreadStartup, 4, "MP3", this, 0x4000);
    }
}

/*##########################################################################
#
#   Name       : TMp3Player::Stop
#
#   Purpose....: Stop playing thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMp3Player::Stop()
{
    FReqStop = true;

    while (FThreadRunning)
        FSignal.WaitForever();
}

/*##########################################################################
#
#   Name       : TMp3Player::IsRunning
#
#   Purpose....: Check if thread is running
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMp3Player::IsRunning()
{
    return FThreadRunning;
}
