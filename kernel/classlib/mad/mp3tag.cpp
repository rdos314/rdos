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
# mp3tag.cpp
# Mp3 tag class
#
########################################################################*/

#include "rdos.h"
#include "mp3tag.h"

#define FALSE	0
#define TRUE	!FALSE

# define XING_MAGIC	(('X' << 24) | ('i' << 16) | ('n' << 8) | 'g')
# define INFO_MAGIC	(('I' << 24) | ('n' << 16) | ('f' << 8) | 'o')
# define LAME_MAGIC	(('L' << 24) | ('A' << 16) | ('M' << 8) | 'E')
# define VBRI_MAGIC	(('V' << 24) | ('B' << 16) | ('R' << 8) | 'I')

static
unsigned short const crc16_table[256] = {
	0x0000, 0xc0c1, 0xc181, 0x0140, 0xc301, 0x03c0, 0x0280, 0xc241,
	0xc601, 0x06c0, 0x0780, 0xc741, 0x0500, 0xc5c1, 0xc481, 0x0440,
	0xcc01, 0x0cc0, 0x0d80, 0xcd41, 0x0f00, 0xcfc1, 0xce81, 0x0e40,
	0x0a00, 0xcac1, 0xcb81, 0x0b40, 0xc901, 0x09c0, 0x0880, 0xc841,
	0xd801, 0x18c0, 0x1980, 0xd941, 0x1b00, 0xdbc1, 0xda81, 0x1a40,
	0x1e00, 0xdec1, 0xdf81, 0x1f40, 0xdd01, 0x1dc0, 0x1c80, 0xdc41,
	0x1400, 0xd4c1, 0xd581, 0x1540, 0xd701, 0x17c0, 0x1680, 0xd641,
	0xd201, 0x12c0, 0x1380, 0xd341, 0x1100, 0xd1c1, 0xd081, 0x1040,

	0xf001, 0x30c0, 0x3180, 0xf141, 0x3300, 0xf3c1, 0xf281, 0x3240,
	0x3600, 0xf6c1, 0xf781, 0x3740, 0xf501, 0x35c0, 0x3480, 0xf441,
	0x3c00, 0xfcc1, 0xfd81, 0x3d40, 0xff01, 0x3fc0, 0x3e80, 0xfe41,
	0xfa01, 0x3ac0, 0x3b80, 0xfb41, 0x3900, 0xf9c1, 0xf881, 0x3840,
	0x2800, 0xe8c1, 0xe981, 0x2940, 0xeb01, 0x2bc0, 0x2a80, 0xea41,
	0xee01, 0x2ec0, 0x2f80, 0xef41, 0x2d00, 0xedc1, 0xec81, 0x2c40,
	0xe401, 0x24c0, 0x2580, 0xe541, 0x2700, 0xe7c1, 0xe681, 0x2640,
	0x2200, 0xe2c1, 0xe381, 0x2340, 0xe101, 0x21c0, 0x2080, 0xe041,

	0xa001, 0x60c0, 0x6180, 0xa141, 0x6300, 0xa3c1, 0xa281, 0x6240,
	0x6600, 0xa6c1, 0xa781, 0x6740, 0xa501, 0x65c0, 0x6480, 0xa441,
	0x6c00, 0xacc1, 0xad81, 0x6d40, 0xaf01, 0x6fc0, 0x6e80, 0xae41,
	0xaa01, 0x6ac0, 0x6b80, 0xab41, 0x6900, 0xa9c1, 0xa881, 0x6840,
	0x7800, 0xb8c1, 0xb981, 0x7940, 0xbb01, 0x7bc0, 0x7a80, 0xba41,
	0xbe01, 0x7ec0, 0x7f80, 0xbf41, 0x7d00, 0xbdc1, 0xbc81, 0x7c40,
	0xb401, 0x74c0, 0x7580, 0xb541, 0x7700, 0xb7c1, 0xb681, 0x7640,
	0x7200, 0xb2c1, 0xb381, 0x7340, 0xb101, 0x71c0, 0x7080, 0xb041,

	0x5000, 0x90c1, 0x9181, 0x5140, 0x9301, 0x53c0, 0x5280, 0x9241,
	0x9601, 0x56c0, 0x5780, 0x9741, 0x5500, 0x95c1, 0x9481, 0x5440,
	0x9c01, 0x5cc0, 0x5d80, 0x9d41, 0x5f00, 0x9fc1, 0x9e81, 0x5e40,
	0x5a00, 0x9ac1, 0x9b81, 0x5b40, 0x9901, 0x59c0, 0x5880, 0x9841,
	0x8801, 0x48c0, 0x4980, 0x8941, 0x4b00, 0x8bc1, 0x8a81, 0x4a40,
	0x4e00, 0x8ec1, 0x8f81, 0x4f40, 0x8d01, 0x4dc0, 0x4c80, 0x8c41,
	0x4400, 0x84c1, 0x8581, 0x4540, 0x8701, 0x47c0, 0x4680, 0x8641,
	0x8201, 0x42c0, 0x4380, 0x8341, 0x4100, 0x81c1, 0x8081, 0x4040
};

/*##########################################################################
#
#   Name       : crc_compute
#
#   Purpose....: Crc compute
#
#   In params..: bpp		bits per pixel
#				 width
#				 height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static unsigned short crc_compute(char const *data, unsigned int length, unsigned short init)
{
	register unsigned int crc;

	for (crc = init; length >= 8; length -= 8) {
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
		crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	}

	switch (length) {
	  case 7: crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	  case 6: crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	  case 5: crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	  case 4: crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	  case 3: crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	  case 2: crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	  case 1: crc = crc16_table[(crc ^ *data++) & 0xff] ^ (crc >> 8);
	  case 0: break;
	}

	return (unsigned short) crc;
}

/*##########################################################################
#
#   Name       : TMp3TagXing::TMp3TagXing
#
#   Purpose....: Xing tag constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3TagXing::TMp3TagXing()
{
    int i;

    flags = 0;
    frames = 0;
    bytes = 0;
    scale = 0;

    for (i = 0; i < 100; i++)
        toc[i] = 0;
    
}

/*##########################################################################
#
#   Name       : TMp3TagXing::~TMp3TagXing
#
#   Purpose....: Xing tag destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3TagXing::~TMp3TagXing()
{
}

/*##########################################################################
#
#   Name       : TMp3RGain::TMp3RGain
#
#   Purpose....: Rgain constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3RGain::TMp3RGain()
{
    name = RGAIN_NAME_NOT_SET;
    originator = RGAIN_ORIGINATOR_UNSPECIFIED;
    adjustment = 0;
}

/*##########################################################################
#
#   Name       : TMp3RGain::TMp3RGain
#
#   Purpose....: Rgain destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3RGain::~TMp3RGain()
{
}

/*##########################################################################
#
#   Name       : TMp3TagLame::TMp3TagLame
#
#   Purpose....: Lame tag constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3TagLame::TMp3TagLame()
{
    revision = 0;
    flags = 0;
    vbr_method = TAG_LAME_VBR_CONSTANT;
    lowpass_filter = 0;
    peak = 0;
    ath_type = 0;
    bitrate = 0;
    start_delay = 0;
    end_padding = 0;

    source_samplerate = TAG_LAME_SOURCE_44_1;
    stereo_mode = TAG_LAME_MODE_UNDEFINED;
    noise_shaping = 0;
    gain = 1;

	surround = TAG_LAME_SURROUND_NONE;
    preset = TAG_LAME_PRESET_NONE;

    music_length = 0;
    music_crc = 0;
}

/*##########################################################################
#
#   Name       : TMp3TagLame::~TMp3TagLame
#
#   Purpose....: Lame tag destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3TagLame::~TMp3TagLame()
{
}

/*##########################################################################
#
#   Name       : TMp3Tag::TMp3Tag
#
#   Purpose....: Mp3 tag constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3Tag::TMp3Tag()
{
	flags      = 0;
	encoder[0] = 0;
}

/*##########################################################################
#
#   Name       : TMp3Tag::~TMp3Tag
#
#   Purpose....: Mp3 tag destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMp3Tag::~TMp3Tag()
{
}

