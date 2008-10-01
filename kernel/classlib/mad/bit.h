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
 * $Id: bit.h,v 1.12 2004/01/23 09:41:32 rob Exp $
 */

# ifndef LIBMAD_BIT_H
# define LIBMAD_BIT_H

class TMadBit
{
public:
  TMadBit();
  TMadBit(unsigned char const *lbyte);
  ~TMadBit();

  static unsigned int GetDistance(TMadBit const *begin, TMadBit const *end);

  void SetBuffer(unsigned char const *lbyte);
  unsigned char const *GetNextByte();
  unsigned long Read(unsigned int len);
  void Skip(unsigned int len);
  unsigned short CalcCrc(unsigned int len, unsigned short init);

  unsigned char const *byte;
  unsigned short cache;
  unsigned short left;
};

# define mad_bit_bitsleft(bitptr)  ((bitptr)->left)

# endif
