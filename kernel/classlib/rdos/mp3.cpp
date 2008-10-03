/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# mp3.cpp
# MP3 player class
#
########################################################################*/

#include <memory.h>

#include "rdos.h"
#include "mp3.h"

#define FALSE	0
#define TRUE	!FALSE

#define MIN_FRAME_SIZE 24 // minimal mp3 frame size
#define MAX_FRAME_SIZE 5761 // max frame size

#define GetFourByteSyncSafe(value1, value2, value3, value4) (((value1 & 255) << 21) | ((value2 & 255) << 14) | ((value3 & 255) << 7) | (value4 & 255))

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
    FMapHandle = 0;
    FFileBuf = 0;
    FFileSize = 0;
    FValid = FALSE;
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
void TMp3Player::Parse()
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
					FSongMs = (unsigned int) ( 1000.0 * (double) FSongFrames * (double) FSamplesPerFrame / (double) FSampleRate);
				
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
}

/*##########################################################################
#
#   Name       : TMp3Player::Load
#
#   Purpose....: Load an MP3 and create a file-mapping on it
#
#   In params..: FileName		File to load
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
        FFileSize = RdosGetFileSize(FFileHandle);
        
        FMapHandle = RdosCreateNamedFileMapping(FileName, FFileSize, FFileHandle);
        if (FMapHandle)
        {                 
            size = FFileSize;
            size--;
            size = size & 0xFFFFF000;
            size += 0x1000;
            
			FFileBuf = (char *)RdosAllocateMem(size);
            RdosMapView(FMapHandle, 0, FFileBuf, FFileSize);

            FindStart();
            Check();
            Parse();
        }
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
    FValid = FALSE;

    if (FFileHandle)
    {
        if (FMapHandle)
        {
            RdosUnmapView(FMapHandle);
            RdosCloseMapping(FMapHandle);
            FMapHandle = 0;
        }

        if (FFileBuf)
        {
            RdosFreeMem(FFileBuf);
            FFileBuf = 0;
        }
             
        RdosCloseFile(FFileHandle);
        FFileHandle = 0;
    }
}
