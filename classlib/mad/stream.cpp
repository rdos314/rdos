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
 * $Id: stream.c,v 1.12 2004/02/05 09:02:39 rob Exp $
 */

# ifdef HAVE_CONFIG_H
#  include "config.h"
# endif

# include "global.h"

# include <stdlib.h>

# include "bit.h"
# include "stream.h"

/*
 * NAME:	stream->init()
 * DESCRIPTION:	initialize stream struct
 */

TMadStream::TMadStream()
{
  buffer     = 0;
  bufend     = 0;
  skiplen    = 0;

  sync       = 0;
  freerate   = 0;

  this_frame = 0;
  next_frame = 0;
  anc_bitlen = 0;

  main_data  = 0;
  md_len     = 0;

  options    = 0;
  error      = MAD_ERROR_NONE;
}

/*
 * NAME:	stream->finish()
 * DESCRIPTION:	deallocate any dynamic memory associated with stream
 */
TMadStream::~TMadStream()
{
  if (main_data)
  {
	 delete main_data;
	 main_data = 0;
  }
}

/*
 * NAME:	stream->buffer()
 * DESCRIPTION:	set stream buffer pointers
 */
void TMadStream::SetBuffer(unsigned char const *buffer, unsigned long length)
{
  buffer = buffer;
  bufend = buffer + length;

  this_frame = buffer;
  next_frame = buffer;

  sync = 1;

  ptr.SetBuffer(buffer);
}

/*
 * NAME:	stream->skip()
 * DESCRIPTION:	arrange to skip bytes before the next frame
 */
void TMadStream::Skip(unsigned long length)
{
  skiplen += length;
}

/*
 * NAME:	stream->sync()
 * DESCRIPTION:	locate the next stream sync word
 */
int TMadStream::Sync()
{
  register unsigned char const *lptr, *end;

  lptr = ptr.GetNextByte();
  end = bufend;

  while (lptr < end - 1 &&
	 !(lptr[0] == 0xff && (lptr[1] & 0xe0) == 0xe0))
	++lptr;

  if (end - lptr < MAD_BUFFER_GUARD)
    return -1;

  ptr.SetBuffer(lptr);

  return 0;
}

/*
 * NAME:	stream->errorstr()
 * DESCRIPTION:	return a string description of the current error condition
 */
char const *TMadStream::GetErrorStr()
{
  switch (error)
  {
  case MAD_ERROR_NONE:		 return "no error";

  case MAD_ERROR_BUFLEN:	 return "input buffer too small (or EOF)";
  case MAD_ERROR_BUFPTR:	 return "invalid (null) buffer pointer";

  case MAD_ERROR_NOMEM:		 return "not enough memory";

  case MAD_ERROR_LOSTSYNC:	 return "lost synchronization";
  case MAD_ERROR_BADLAYER:	 return "reserved header layer value";
  case MAD_ERROR_BADBITRATE:	 return "forbidden bitrate value";
  case MAD_ERROR_BADSAMPLERATE:	 return "reserved sample frequency value";
  case MAD_ERROR_BADEMPHASIS:	 return "reserved emphasis value";

  case MAD_ERROR_BADCRC:	 return "CRC check failed";
  case MAD_ERROR_BADBITALLOC:	 return "forbidden bit allocation value";
  case MAD_ERROR_BADSCALEFACTOR: return "bad scalefactor index";
  case MAD_ERROR_BADMODE:	 return "bad bitrate/mode combination";
  case MAD_ERROR_BADFRAMELEN:	 return "bad frame length";
  case MAD_ERROR_BADBIGVALUES:	 return "bad big_values count";
  case MAD_ERROR_BADBLOCKTYPE:	 return "reserved block_type";
  case MAD_ERROR_BADSCFSI:	 return "bad scalefactor selection info";
  case MAD_ERROR_BADDATAPTR:	 return "bad main_data_begin pointer";
  case MAD_ERROR_BADPART3LEN:	 return "bad audio data length";
  case MAD_ERROR_BADHUFFTABLE:	 return "bad Huffman table select";
  case MAD_ERROR_BADHUFFDATA:	 return "Huffman data overrun";
  case MAD_ERROR_BADSTEREO:	 return "incompatible block_type for JS";
  }

  return 0;
}
