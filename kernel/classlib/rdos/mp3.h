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
# mp3.h
# MP3 player class
#
########################################################################*/

#ifndef _MP3_H
#define _MP3_H

#include "mp3tag.h"
#include "decoder.h"

class TMp3Player : protected TMadDecoder
{
public:
	TMp3Player();
	~TMp3Player();

    void Close();
	void Load(const char *FileName);

	void SetPosition(int ms);
	
//	void Play();

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

//	virtual enum mad_flow Input(void *);
//	virtual enum mad_flow Header(TMadHeader *);
//	virtual enum mad_flow Filter();
//	virtual enum mad_flow Output(TMadHeader *, struct mad_pcm *);
//	virtual enum mad_flow Error(void *);

    int FFileHandle;
    int FMapHandle;
	unsigned char *FFileBuf;
    int FFileSize;
    int FValid;

    int FId3V1;
    int FId3V2;

	unsigned char *FMp3Start;
	int FMp3Size;

	unsigned char *FCurrentPos;

};

#endif
