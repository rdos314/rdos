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
 * $Id: decoder.c,v 1.22 2004/01/23 09:41:32 rob Exp $
 */

# ifdef HAVE_CONFIG_H
#  include "config.h"
# endif

# include "global.h"

# ifdef HAVE_SYS_TYPES_H
#  include <sys/types.h>
# endif

# ifdef HAVE_SYS_WAIT_H
#  include <sys/wait.h>
# endif

# ifdef HAVE_UNISTD_H
#  include <unistd.h>
# endif

# ifdef HAVE_FCNTL_H
#  include <fcntl.h>
# endif

# include <stdlib.h>

# ifdef HAVE_ERRNO_H
#  include <errno.h>
# endif

# include "stream.h"
# include "frame.h"
# include "synth.h"
# include "decoder.h"

/*
 * NAME:	decoder->init()
 * DESCRIPTION:	initialize a decoder object with callback routines
 */
TMadDecoder::TMadDecoder()
{
  options      = 0;
  cb_data      = 0;
}
/*
 * NAME:	decoder->init()
 * DESCRIPTION:	initialize a decoder object with callback routines
 */
TMadDecoder::TMadDecoder(void *data)
{
  options      = 0;
  cb_data      = data;
}

TMadDecoder::~TMadDecoder()
{
}

enum mad_flow TMadDecoder::Input(void *data)
{
	return MAD_FLOW_STOP;
}

enum mad_flow TMadDecoder::Header(TMadHeader *header)
{
	return MAD_FLOW_CONTINUE;
}

enum mad_flow TMadDecoder::Filter()
{
	return MAD_FLOW_CONTINUE;
}

enum mad_flow TMadDecoder::Output(TMadHeader *, struct mad_pcm *)
{
	return MAD_FLOW_CONTINUE;
}

enum mad_flow TMadDecoder::Error(void *data)
{
	int *bad_last_frame = (int *)data;

	switch (stream.error)
	{
		case MAD_ERROR_BADCRC:
			if (*bad_last_frame)
				Frame.Mute();

			return MAD_FLOW_IGNORE;

		default:
			return MAD_FLOW_CONTINUE;
	}
}

int TMadDecoder::Run()
{
  int result = 0;

  mad_stream_options(&stream, options);

  do
  {
	switch (Input(cb_data))
	{
		case MAD_FLOW_STOP:
			goto done;

		case MAD_FLOW_BREAK:
			goto fail;

		case MAD_FLOW_IGNORE:
			continue;

		case MAD_FLOW_CONTINUE:
			break;
	}

	while (1)
	{
		if (Frame.Header.ReadAndDecode(&stream) == -1)
		{
			if (!MAD_RECOVERABLE(stream.error))
				break;

			switch (Error(&cb_data))
			{
				case MAD_FLOW_STOP:
					goto done;

				case MAD_FLOW_BREAK:
					goto fail;

				case MAD_FLOW_IGNORE:
				case MAD_FLOW_CONTINUE:
				default:
					continue;
			}
		}

		switch (Header(&Frame.Header))
		{
			case MAD_FLOW_STOP:
				goto done;

			case MAD_FLOW_BREAK:
				goto fail;

			case MAD_FLOW_IGNORE:
				continue;

			case MAD_FLOW_CONTINUE:
				break;
		}

		if (Frame.Decode(&stream) == -1)
		{
			if (!MAD_RECOVERABLE(stream.error))
				break;

			switch (Error(cb_data))
			{
				case MAD_FLOW_STOP:
					goto done;

				case MAD_FLOW_BREAK:
					goto fail;

				case MAD_FLOW_IGNORE:
					break;

				case MAD_FLOW_CONTINUE:
				default:
					continue;
			}
		}

		switch (Filter())
		{
			case MAD_FLOW_STOP:
				goto done;

			case MAD_FLOW_BREAK:
				goto fail;

			case MAD_FLOW_IGNORE:
				continue;

			case MAD_FLOW_CONTINUE:
				break;
		}

		synth.Synth(&Frame);

		switch (Output(&Frame.Header, &synth.pcm))
		{
			case MAD_FLOW_STOP:
				goto done;

			case MAD_FLOW_BREAK:
				goto fail;

			case MAD_FLOW_IGNORE:
			case MAD_FLOW_CONTINUE:
				break;
		}
	}
  }
  while (stream.error == MAD_ERROR_BUFLEN);

 fail:
  result = -1;

 done:

  return result;
}

