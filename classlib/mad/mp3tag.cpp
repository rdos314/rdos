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
# Builds on code from Zoran Cindori 2003-2008  ( zcindori@inet.hr )
#
# mp3tag.cpp
# Mp3 tag class
#
########################################################################*/

#include <memory.h>
#include <stdio.h>

#include "mp3tag.h"

#define FALSE   0
#define TRUE    !FALSE

enum {
        TAG_LAME_NSPSYTUNE    = 0x01,
        TAG_LAME_NSSAFEJOINT  = 0x02,
        TAG_LAME_NOGAP_NEXT   = 0x04,
        TAG_LAME_NOGAP_PREV   = 0x08,

        TAG_LAME_UNWISE       = 0x10
};


# define XING_MAGIC     (('X' << 24) | ('i' << 16) | ('n' << 8) | 'g')
# define INFO_MAGIC     (('I' << 24) | ('n' << 16) | ('f' << 8) | 'o')
# define LAME_MAGIC     (('L' << 24) | ('A' << 16) | ('M' << 8) | 'E')
# define VBRI_MAGIC     (('V' << 24) | ('B' << 16) | ('R' << 8) | 'I')
# define RGAIN_SET(rgain)       ((rgain)->name != RGAIN_NAME_NOT_SET)

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
#   In params..: bpp            bits per pixel
#                                width
#                                height
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
#   Name       : TMp3TagXing::Parse
#
#   Purpose....: Parse
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMp3TagXing::Parse(TMadBit *bitptr, unsigned int *bitlen)
{
    int lflags;

    flags = 0;

        if (*bitlen < 32)
                return -1;

    lflags = bitptr->Read(32);
        *bitlen -= 32;

        if (lflags & TAG_XING_FRAMES) 
        {
                if (*bitlen < 32)
                        return -1;

                frames = bitptr->Read(32);
                *bitlen -= 32;
        }

        if (lflags & TAG_XING_BYTES)
        {
                if (*bitlen < 32)
                        return -1;

                bytes = bitptr->Read(32);
                *bitlen -= 32;
        }

        if (lflags & TAG_XING_TOC)
        {
                int i;

                if (*bitlen < 800)
                        return -1;

                for (i = 0; i < 100; ++i)
                        toc[i] = (unsigned char) bitptr->Read(8);

                *bitlen -= 800;
        }

        if (lflags & TAG_XING_SCALE)
        {
                if (*bitlen < 32)
                        return -1;

                scale = bitptr->Read(32);
                *bitlen -= 32;
        }

    flags = lflags;
        return 0;
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
#   Name       : TMp3RGain::Parse
#
#   Purpose....: Rgain parse
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMp3RGain::Parse(TMadBit *bitptr)
{
  int negative;

  name       = (enum rgain_name) bitptr->Read(3);
  originator = (enum rgain_originator) bitptr->Read(3);

  negative          = bitptr->Read(1);
  adjustment = (short) bitptr->Read(9);

  if (negative)
        adjustment = (short) -adjustment;

  return 1;
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
#   Name       : TMp3TagLame::Parse
#
#   Purpose....: Parse
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMp3TagLame::Parse(TMadBit *bitptr, unsigned int *bitlen, unsigned short crc)
{
        TMadBit save = *bitptr;
        unsigned long magic;
        char const *version;

        if (*bitlen < 36 * 8)
                goto fail;

        /* bytes $9A-$A4: Encoder short VersionString */

        magic   = bitptr->Read(4 * 8);
        version = (const char *) bitptr->GetNextByte();

        bitptr->Skip(5 * 8);

        /* byte $A5: Info Tag revision + VBR method */

        revision = (unsigned char) bitptr->Read(4);
        if (revision == 15)
                goto fail;

        vbr_method = (enum tag_lame_vbr) bitptr->Read(4);

        /* byte $A6: Lowpass filter value (Hz) */

        lowpass_filter = (unsigned short) ( bitptr->Read(8) * 100);

        /* bytes $A7-$AA: 32 bit "Peak signal amplitude" */

        peak = bitptr->Read(32) << 5;

        /* bytes $AB-$AC: 16 bit "Radio Replay Gain" */

        replay_gain[0].Parse(bitptr);

        /* bytes $AD-$AE: 16 bit "Audiophile Replay Gain" */

    replay_gain[1].Parse(bitptr);

        //LAME 3.95.1 reference level changed from 83dB to 89dB and foobar seems to use 89dB
        if (magic == LAME_MAGIC)
        {
                char str[6];
                unsigned major = 0, minor = 0, patch = 0;
                int i;

                memcpy(str, version, 5);
                str[5] = 0;

                sscanf(str, "%u.%u.%u", &major, &minor, &patch);

                if (major == 3 && minor < 95) {
                        for (i = 0; i < 2; ++i) {
                                if (RGAIN_SET(&replay_gain[i]))
                                        replay_gain[i].adjustment += 6;  // 6.0 dB 
                        }
                }
        }

        /* byte $AF: Encoding flags + ATH Type */

        flags    = (unsigned char) bitptr->Read(4);
        ath_type = (unsigned char) bitptr->Read(4);

        /* byte $B0: if ABR {specified bitrate} else {minimal bitrate} */

        bitrate = (unsigned char) bitptr->Read(8);

        /* bytes $B1-$B3: Encoder delays */

        start_delay = bitptr->Read(12);
        end_padding = bitptr->Read(12);

        /* byte $B4: Misc */

        source_samplerate = (enum tag_lame_source) bitptr->Read(2);

        if (bitptr->Read(1))
                flags |= TAG_LAME_UNWISE;

        stereo_mode   = (enum tag_lame_mode) bitptr->Read(3);
        noise_shaping = (unsigned char) bitptr->Read(2);

        /* byte $B5: MP3 Gain */

        gain = (signed char) bitptr->Read(8);

        /* bytes $B6-B7: Preset and surround info */

        bitptr->Skip(2);

        surround = (enum tag_lame_surround) bitptr->Read(3);
        preset   = (enum tag_lame_preset) bitptr->Read(11);

        /* bytes $B8-$BB: MusicLength */

        music_length = bitptr->Read(32);

        /* bytes $BC-$BD: MusicCRC */

        music_crc = (unsigned short) bitptr->Read(16);

        /* bytes $BE-$BF: CRC-16 of Info Tag */

        if (bitptr->Read(16) != crc)
                goto fail;

        *bitlen -= 36 * 8;

        return 0;

fail:
        *bitptr = save;
        return -1;
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

/*##########################################################################
#
#   Name       : TMp3Tag::Parse
#
#   Purpose....: Parse tags
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMp3Tag::Parse(TMadStream *stream, TMadFrame *frame)
{
        TMadBit bitptr = stream->anc_ptr;
        TMadBit start = bitptr;
        unsigned int bitlen = stream->anc_bitlen;
        unsigned long magic;
        unsigned long magic2;
        int i;

        if (bitlen < 32)
                return -1;

        magic = bitptr.Read(32);
    
        bitlen -= 32;

        if (magic != XING_MAGIC &&
                magic != INFO_MAGIC &&
                magic != LAME_MAGIC) {
                        /*
                        * Due to an unfortunate historical accident, a Xing VBR tag may be
                        * misplaced in a stream with CRC protection. We check for this by
                        * assuming the tag began two octets prior and the high bits of the
                        * following flags field are always zero.
                        */

                        if (magic != ((XING_MAGIC << 16) & 0xffffffffL) &&
                                magic != ((INFO_MAGIC << 16) & 0xffffffffL))
                        {
                                //check for VBRI tag
                                if (bitlen >= 400)
                                {
                                        bitptr.Skip(256);
                                        magic2 = bitptr.Read(32);
                                        if (magic2 == VBRI_MAGIC)
                                        {
                                                bitptr.Read(16); //16 bits - version
                                                lame.start_delay = bitptr.Read(16); //16 bits - delay
                                                bitptr.Skip(16); //16 bits - quality
                                                xing.bytes = bitptr.Read(32); //32 bits - bytes
                                            xing.frames = bitptr.Read(32); //32 bits - frames
                                                unsigned int table_size = bitptr.Read(16);
                                                unsigned int table_scale = bitptr.Read(16);
                                                unsigned int entry_bytes = bitptr.Read(16);
                                                unsigned int entry_frames = bitptr.Read(16);
                                                {
                                                    unsigned int Entry = 0, PrevEntry = 0, Percent, SeekPoint = 0, i = 0;
                                                    float AccumulatedTime = 0;
                            float TotalDuration = (float) (1000.0 * xing.frames * ((frame->Header.flags & MAD_FLAG_LSF_EXT) ? 576 : 1152) / frame->Header.samplerate);
                                                    float DurationPerVbriFrames = TotalDuration / ((float)table_size + 1);
                                                    for (Percent=0;Percent<100;Percent++)
                                                    {
                                float EntryTimeInMilliSeconds = ((float)Percent/100) * TotalDuration;
                                while (AccumulatedTime <= EntryTimeInMilliSeconds)
                                {
                                    PrevEntry = Entry;
                                    Entry = bitptr.Read(entry_bytes * 8) * table_scale;
                                    i++;
                                    SeekPoint += Entry;
                                    AccumulatedTime += DurationPerVbriFrames;
                                    if (i >= table_size) break;
                                }
                                unsigned int fraction = ( (int)(((( AccumulatedTime - EntryTimeInMilliSeconds ) / DurationPerVbriFrames ) 
                                                                     + (1.0f/(2.0f*(float)entry_frames))) * (float)entry_frames));
                                            unsigned int SeekPoint2 = SeekPoint - (int)((float)PrevEntry * (float)(fraction) 
                                                                         / (float)entry_frames);
                                                unsigned int XingPoint = (256 * SeekPoint2) / xing.bytes;
                                                        

                                                if (XingPoint > 255) XingPoint = 255;
                                                xing.toc[Percent] = (unsigned char)(XingPoint & 0xFF);
                            }
                        }
                                                flags |= (TAG_XING | TAG_VBRI);
                                                xing.flags = (TAG_XING_FRAMES | TAG_XING_BYTES | TAG_XING_TOC);
                                        
                                                return 0;
                                        }
                                }
                                return -1;
                        }

                        magic >>= 16;

                        /* backtrack the bit pointer */

                        bitptr = start;
                        bitptr.Read(16);
                        bitlen += 16;
        }

        if ((magic & 0x0000ffffL) == (XING_MAGIC & 0x0000ffffL))
                flags |= TAG_VBR;

        /* Xing tag */

        if (magic == LAME_MAGIC)
        {
                bitptr = start;
                bitlen += 32;
        }
        else if (xing.Parse(&bitptr, &bitlen) == 0)
                flags |= TAG_XING;

        /* encoder string */

        if (bitlen >= 20 * 8)
        {
                start = bitptr;

                for (i = 0; i < 20; ++i) {
                        encoder[i] = (char)  bitptr.Read(8);

                        if (encoder[i] == 0)
                                break;

                        /* keep only printable ASCII chars */

                        if (encoder[i] < 0x20 || encoder[i] >= 0x7f)
                        {
                                encoder[i] = 0;
                                break;
                        }
                }

                encoder[20] = 0;
                bitptr = start;
        }

        /* LAME tag */

        if (memcmp(encoder, "LAME", 4) == 0 && stream->next_frame - stream->this_frame >= 192)
        {
            unsigned short crc = crc_compute((const char *) stream->this_frame, (frame->Header.flags & MAD_FLAG_LSF_EXT) ? 175 : 190, 0x0000);
                        if (lame.Parse(&bitptr, &bitlen, crc) == 0)
                        {
                flags |= TAG_LAME;
                            encoder[9] = 0;
            }
        }
        else 
        {
                for (i = 0; i < 20; ++i) {
                        if (encoder[i] == 0)
                                break;

                        /* stop at padding chars */

                        if (encoder[i] == 0x55)
                        {
                                encoder[i] = 0;
                                break;
                        }
                }
        }

        return 0;
}
