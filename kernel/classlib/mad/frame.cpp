/*
 * libmad - MPEG audio decoder library
 * Copyright (C) 2000-2004 Underbit Technologies, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Id: frame.c,v 1.29 2004/02/04 22:59:19 rob Exp $
 */

# ifdef HAVE_CONFIG_H
#  include "config.h"
# endif

# include "global.h"

# include <stdlib.h>

# include "bit.h"
# include "stream.h"
# include "frame.h"
# include "timer.h"
# include "layer12.h"
# include "layer3.h"

static
unsigned long const bitrate_table[5][15] = {
  /* MPEG-1 */
  { 0,  32000,  64000,  96000, 128000, 160000, 192000, 224000,  /* Layer I   */
       256000, 288000, 320000, 352000, 384000, 416000, 448000 },
  { 0,  32000,  48000,  56000,  64000,  80000,  96000, 112000,  /* Layer II  */
       128000, 160000, 192000, 224000, 256000, 320000, 384000 },
  { 0,  32000,  40000,  48000,  56000,  64000,  80000,  96000,  /* Layer III */
       112000, 128000, 160000, 192000, 224000, 256000, 320000 },

  /* MPEG-2 LSF */
  { 0,  32000,  48000,  56000,  64000,  80000,  96000, 112000,  /* Layer I   */
       128000, 144000, 160000, 176000, 192000, 224000, 256000 },
  { 0,   8000,  16000,  24000,  32000,  40000,  48000,  56000,  /* Layers    */
                64000,  80000,  96000, 112000, 128000, 144000, 160000 } /* II & III  */
};

static
unsigned int const samplerate_table[3] = { 44100, 48000, 32000 };

static
int (*const decoder_table[3])(TMadStream *, TMadFrame *) = {
  mad_layer_I,
  mad_layer_II,
  mad_layer_III
};

/*
 * NAME:        free_bitrate()
 * DESCRIPTION: attempt to discover the bitstream's free bitrate
 */
static
int free_bitrate(TMadStream *stream, const TMadHeader *header)
{
  TMadBit keep_ptr;
  unsigned long rate = 0;
  unsigned int pad_slot, slots_per_frame;
  unsigned char const *ptr = 0;

  keep_ptr = stream->ptr;

  pad_slot = (header->flags & MAD_FLAG_PADDING) ? 1 : 0;
  slots_per_frame = (header->layer == MAD_LAYER_III &&
                         (header->flags & MAD_FLAG_LSF_EXT)) ? 72 : 144;

  while (stream->Sync() == 0)
  {
        TMadStream peek_stream;
        TMadHeader peek_header;

        peek_stream = *stream;
        peek_header = *header;

        if (peek_header.Get(&peek_stream) == 0 &&
        peek_header.layer == header->layer &&
        peek_header.samplerate == header->samplerate) {
          unsigned int N;

          ptr = stream->ptr.GetNextByte();

          N = ptr - stream->this_frame;

          if (header->layer == MAD_LAYER_I) {
        rate = (unsigned long) header->samplerate *
          (N - 4 * pad_slot + 4) / 48 / 1000;
          }
          else {
        rate = (unsigned long) header->samplerate *
          (N - pad_slot + 1) / slots_per_frame / 1000;
          }

          if (rate >= 8)
        break;
        }

        stream->ptr.Skip(8);
  }

  stream->ptr = keep_ptr;

  if (rate < 8 || (header->layer == MAD_LAYER_III && rate > 640)) {
        stream->error = MAD_ERROR_LOSTSYNC;
        return -1;
  }

  stream->freerate = rate * 1000;

  return 0;
}


/*
 * NAME:        header->init()
 * DESCRIPTION: initialize header struct
 */
TMadHeader::TMadHeader()
{
  layer          = MAD_LAYER_I;
  mode           = MAD_MODE_SINGLE_CHANNEL;
  mode_extension = 0;
  emphasis       = MAD_EMPHASIS_NONE;

  bitrate        = 0;
  samplerate     = 0;

  crc_check      = 0;
  crc_target     = 0;

  flags          = 0;
  private_bits   = 0;

  duration       = mad_timer_zero;
}

TMadHeader::~TMadHeader()
{
}

/*
 * NAME:        decode_header()
 * DESCRIPTION: read header data and following CRC word
 */
int TMadHeader::Get(TMadStream *stream)
{
  unsigned int index;
  TMadBit *bitptr = &stream->ptr;

  flags        = 0;
  private_bits = 0;

  /* header() */

  /* syncword */
  bitptr->Skip(11);

  /* MPEG 2.5 indicator (really part of syncword) */
  if (bitptr->Read(1) == 0)
        flags |= MAD_FLAG_MPEG_2_5_EXT;

  /* ID */
  if (bitptr->Read(1) == 0)
        flags |= MAD_FLAG_LSF_EXT;
  else if (flags & MAD_FLAG_MPEG_2_5_EXT) {
        stream->error = MAD_ERROR_LOSTSYNC;
        return -1;
  }

  /* layer */
  layer = (enum mad_layer)(4 - bitptr->Read(2));

  if (layer == 4)
  {
        stream->error = MAD_ERROR_BADLAYER;
        return -1;
  }

  /* protection_bit */
  if (bitptr->Read(1) == 0)
  {
        flags    |= MAD_FLAG_PROTECTION;
        crc_check = bitptr->CalcCrc(16, 0xffff);
  }

  /* bitrate_index */
  index = bitptr->Read(4);

  if (index == 15) {
        stream->error = MAD_ERROR_BADBITRATE;
        return -1;
  }

  if (flags & MAD_FLAG_LSF_EXT)
        bitrate = bitrate_table[3 + (layer >> 1)][index];
  else
        bitrate = bitrate_table[layer - 1][index];

  /* sampling_frequency */
  index = bitptr->Read(2);

  if (index == 3)
  {
        stream->error = MAD_ERROR_BADSAMPLERATE;
        return -1;
  }

  samplerate = samplerate_table[index];

  if (flags & MAD_FLAG_LSF_EXT)
  {
        samplerate /= 2;

        if (flags & MAD_FLAG_MPEG_2_5_EXT)
          samplerate /= 2;
  }

  /* padding_bit */
  if (bitptr->Read(1))
        flags |= MAD_FLAG_PADDING;

  /* private_bit */
  if (bitptr->Read(1))
        private_bits |= MAD_PRIVATE_HEADER;

  /* mode */
  mode = (enum mad_mode)(3 - bitptr->Read(2));

  /* mode_extension */
  mode_extension = bitptr->Read(2);

  /* copyright */
  if (bitptr->Read(1))
        flags |= MAD_FLAG_COPYRIGHT;

  /* original/copy */
  if (bitptr->Read(1))
        flags |= MAD_FLAG_ORIGINAL;

  /* emphasis */
  emphasis = (enum mad_emphasis)bitptr->Read(2);

  /* error_check() */

  /* crc_check */
  if (flags & MAD_FLAG_PROTECTION)
        crc_target = bitptr->Read(16);

  return 0;
}


/*
 * NAME:        header->decode()
 * DESCRIPTION: read the next frame header from the stream
 */
int TMadHeader::ReadAndDecode(TMadStream *stream)
{
  register unsigned char const *ptr, *end;
  unsigned int pad_slot, N;

  size = 0;

  ptr = stream->next_frame;
  end = stream->bufend;

  if (ptr == 0) {
        stream->error = MAD_ERROR_BUFPTR;
        goto fail;
  }

  /* stream skip */
  if (stream->skiplen)
  {
        if (!stream->sync)
          ptr = stream->this_frame;

        if (end - ptr < stream->skiplen) {
          stream->skiplen   -= end - ptr;
          stream->next_frame = end;

          stream->error = MAD_ERROR_BUFLEN;
          goto fail;
        }

        ptr += stream->skiplen;
        stream->skiplen = 0;

        stream->sync = 1;
  }

 sync:
  /* synchronize */
  if (stream->sync)
  {
        if (end - ptr < MAD_BUFFER_GUARD)
        {
          stream->next_frame = ptr;

          stream->error = MAD_ERROR_BUFLEN;
          goto fail;
        }
        else if (!(ptr[0] == 0xff && (ptr[1] & 0xe0) == 0xe0))
        {
          /* mark point where frame sync word was expected */
          stream->this_frame = ptr;
          stream->next_frame = ptr + 1;

          stream->error = MAD_ERROR_LOSTSYNC;
          goto fail;
        }
  }
  else
  {
        stream->ptr.SetBuffer(ptr);

        if (stream->Sync() == -1)
        {
          if (end - stream->next_frame >= MAD_BUFFER_GUARD)
                stream->next_frame = end - MAD_BUFFER_GUARD;

          stream->error = MAD_ERROR_BUFLEN;
          goto fail;
        }

        ptr = stream->ptr.GetNextByte();
  }

  /* begin processing */
  stream->this_frame = ptr;
  stream->next_frame = ptr + 1;  /* possibly bogus sync word */

  stream->ptr.SetBuffer(stream->this_frame);

  if (Get(stream) == -1)
        goto fail;

  /* calculate frame duration */
  mad_timer_set(&duration, 0,
                32 * MAD_NSBSAMPLES(this), samplerate);

  /* calculate free bit rate */
  if (bitrate == 0)
  {
        if ((stream->freerate == 0 || !stream->sync ||
         (layer == MAD_LAYER_III && stream->freerate > 640000)) &&
        free_bitrate(stream, this) == -1)
          goto fail;

        bitrate = stream->freerate;
        flags  |= MAD_FLAG_FREEFORMAT;
  }

  /* calculate beginning of next frame */
  pad_slot = (flags & MAD_FLAG_PADDING) ? 1 : 0;

  if (layer == MAD_LAYER_I)
        N = ((12 * bitrate / samplerate) + pad_slot) * 4;
  else {
        unsigned int slots_per_frame;

        slots_per_frame = (layer == MAD_LAYER_III &&
                           (flags & MAD_FLAG_LSF_EXT)) ? 72 : 144;

        N = (slots_per_frame * bitrate / samplerate) + pad_slot;
  }

  size = N;

  /* verify there is enough data left in buffer to decode this frame */
  if (N + MAD_BUFFER_GUARD > end - stream->this_frame) {
        stream->next_frame = stream->this_frame;

        stream->error = MAD_ERROR_BUFLEN;
        goto fail;
  }

  stream->next_frame = stream->this_frame + N;

  if (!stream->sync) {
        /* check that a valid frame header follows this frame */

        ptr = stream->next_frame;
        if (!(ptr[0] == 0xff && (ptr[1] & 0xe0) == 0xe0)) {
          ptr = stream->next_frame = stream->this_frame + 1;
          goto sync;
        }

        stream->sync = 1;
  }

  flags |= MAD_FLAG_INCOMPLETE;

  return 0;

 fail:
  stream->sync = 0;

  return -1;
}



/*
 * NAME:        frame->init()
 * DESCRIPTION: initialize frame struct
 */

TMadFrame::TMadFrame()
{
  options = 0;
  Mute();
}

/*
 * NAME:        frame->finish()
 * DESCRIPTION: deallocate any dynamic memory associated with frame
 */

TMadFrame::~TMadFrame()
{
}

/*
 * NAME:        frame->decode()
 * DESCRIPTION: decode a single frame from a bitstream
 */
int TMadFrame::Decode(TMadStream *stream)
{
  options = stream->options;

  if (!(Header.flags & MAD_FLAG_INCOMPLETE) && Header.ReadAndDecode(stream) == -1)
        goto fail;

  /* audio_data() */

  Header.flags &= ~MAD_FLAG_INCOMPLETE;

  if (decoder_table[Header.layer - 1](stream, this) == -1)
  {
        if (!MAD_RECOVERABLE(stream->error))
          stream->next_frame = stream->this_frame;

        goto fail;
  }

  /* ancillary_data() */

  if (Header.layer != MAD_LAYER_III)
  {
        TMadBit next_frame(stream->next_frame);

        stream->anc_ptr    = stream->ptr;
        stream->anc_bitlen = TMadBit::GetDistance(&stream->ptr, &next_frame);
  }

  return 0;

 fail:
  stream->anc_bitlen = 0;
  return -1;
}

/*
 * NAME:        frame->mute()
 * DESCRIPTION: zero all subband values so the frame becomes silent
 */

void TMadFrame::Mute()
{
  unsigned int s, sb;

  for (s = 0; s < 36; ++s)
  {
        for (sb = 0; sb < 32; ++sb)
        {
          sbsample[0][s][sb] =
          sbsample[1][s][sb] = 0;
        }
  }

  for (s = 0; s < 18; ++s)
        for (sb = 0; sb < 32; ++sb)
          overlap[0][sb][s] = overlap[1][sb][s] = 0;
}

