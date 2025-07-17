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
# mp3tag.h
# Mp3 xing and lame tag class
#
########################################################################*/

#ifndef _MP3TAG_H
#define _MP3TAG_H

#include "fixed.h"
#include "bit.h"
#include "stream.h"
#include "frame.h"

enum {
	TAG_XING_FRAMES = 0x00000001L,
	TAG_XING_BYTES  = 0x00000002L,
	TAG_XING_TOC    = 0x00000004L,
	TAG_XING_SCALE  = 0x00000008L
};

enum {
	TAG_XING = 0x0001,
	TAG_LAME = 0x0002,
	TAG_VBRI = 0x0004,
	TAG_VBR  = 0x0100
};


class TMp3TagXing
{
public:
    TMp3TagXing();
    ~TMp3TagXing();

    int Parse(TMadBit *bitptr, unsigned int *bitlen);

	long flags;		   /* valid fields (see above) */
	unsigned long frames;	   /* total number of frames */
	unsigned long bytes;	   /* total number of bytes */
	unsigned char toc[100];  /* 100-point seek table */
	long scale;		   /* VBR quality indicator (0 best - 100 worst) */
};


enum rgain_name {
  RGAIN_NAME_NOT_SET    = 0x0,
  RGAIN_NAME_RADIO      = 0x1,
  RGAIN_NAME_AUDIOPHILE = 0x2
};

enum rgain_originator {
  RGAIN_ORIGINATOR_UNSPECIFIED = 0x0,
  RGAIN_ORIGINATOR_PRESET      = 0x1,
  RGAIN_ORIGINATOR_USER        = 0x2,
  RGAIN_ORIGINATOR_AUTOMATIC   = 0x3
};


class TMp3RGain
{
public:
    TMp3RGain();
    ~TMp3RGain();

    int Parse(TMadBit *bitptr);

    enum rgain_name name;			/* profile (see above) */
    enum rgain_originator originator;	/* source (see above) */
    signed short adjustment;		/* in units of 0.1 dB */
};


enum tag_lame_vbr {
	TAG_LAME_VBR_CONSTANT      = 1,
	TAG_LAME_VBR_ABR           = 2,
	TAG_LAME_VBR_METHOD1       = 3,
	TAG_LAME_VBR_METHOD2       = 4,
	TAG_LAME_VBR_METHOD3       = 5,
	TAG_LAME_VBR_METHOD4       = 6,
	TAG_LAME_VBR_CONSTANT2PASS = 8,
	TAG_LAME_VBR_ABR2PASS      = 9
};

enum tag_lame_source {
	TAG_LAME_SOURCE_32LOWER  = 0x00,
	TAG_LAME_SOURCE_44_1     = 0x01,
	TAG_LAME_SOURCE_48       = 0x02,
	TAG_LAME_SOURCE_HIGHER48 = 0x03
};

enum tag_lame_mode {
	TAG_LAME_MODE_MONO      = 0x00,
	TAG_LAME_MODE_STEREO    = 0x01,
	TAG_LAME_MODE_DUAL      = 0x02,
	TAG_LAME_MODE_JOINT     = 0x03,
	TAG_LAME_MODE_FORCE     = 0x04,
	TAG_LAME_MODE_AUTO      = 0x05,
	TAG_LAME_MODE_INTENSITY = 0x06,
	TAG_LAME_MODE_UNDEFINED = 0x07
};

enum tag_lame_surround {
	TAG_LAME_SURROUND_NONE      = 0,
	TAG_LAME_SURROUND_DPL       = 1,
	TAG_LAME_SURROUND_DPL2      = 2,
	TAG_LAME_SURROUND_AMBISONIC = 3
};

enum tag_lame_preset {
	TAG_LAME_PRESET_NONE          =    0,
	TAG_LAME_PRESET_V9            =  410,
	TAG_LAME_PRESET_V8            =  420,
	TAG_LAME_PRESET_V7            =  430,
	TAG_LAME_PRESET_V6            =  440,
	TAG_LAME_PRESET_V5            =  450,
	TAG_LAME_PRESET_V4            =  460,
	TAG_LAME_PRESET_V3            =  470,
	TAG_LAME_PRESET_V2            =  480,
	TAG_LAME_PRESET_V1            =  490,
	TAG_LAME_PRESET_V0            =  500,
	TAG_LAME_PRESET_R3MIX         = 1000,
	TAG_LAME_PRESET_STANDARD      = 1001,
	TAG_LAME_PRESET_EXTREME       = 1002,
	TAG_LAME_PRESET_INSANE        = 1003,
	TAG_LAME_PRESET_STANDARD_FAST = 1004,
	TAG_LAME_PRESET_EXTREME_FAST  = 1005,
	TAG_LAME_PRESET_MEDIUM        = 1006,
	TAG_LAME_PRESET_MEDIUM_FAST   = 1007,
	TAG_LAME_PRESET_PORTABLE      = 1010,
	TAG_LAME_PRESET_RADIO         = 1015
};


class TMp3TagLame
{
public:
    TMp3TagLame();
	~TMp3TagLame();

	int Parse(TMadBit *bitptr, unsigned int *bitlen, unsigned short crc);

	unsigned char revision;
	unsigned char flags;

	enum tag_lame_vbr vbr_method;
	unsigned short lowpass_filter;

	mad_fixed_t peak;
	TMp3RGain replay_gain[2];

	unsigned char ath_type;
	unsigned char bitrate;

	int start_delay;
	int end_padding;

	enum tag_lame_source source_samplerate;
	enum tag_lame_mode stereo_mode;
	unsigned char noise_shaping;

	signed char gain;
	enum tag_lame_surround surround;
	enum tag_lame_preset preset;

	unsigned long music_length;
	unsigned short music_crc;
};


class TMp3Tag
{
public:
    TMp3Tag();
    ~TMp3Tag();

    int Parse(TMadStream *stream, TMadFrame *frame);

	int flags;
	TMp3TagXing xing;
	TMp3TagLame lame;
	char encoder[21];
};    

#endif
