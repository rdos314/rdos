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
# bmp.cpp
# Windows bmp interface
#
########################################################################*/

#include "rdos.h"
#include "bmp.h"
#include "file.h"

struct	TBitmapFileHeader
{
	char Type[2];
	long Size;
	long Reserved;
	long BitOffset;
};

struct TBitmapInfoHeader
{
	long Size;
	long Width;
	long Height;
	short int Planes;
	short int BitCount;
	long Compression;
	long ImageSize;
	long XPelsPerMeter;
	long YPelsPerMeter;
	long ClrUsed;
	long ClrImportant;
};

/*##########################################################################
#
#   Name       : CreateBmp
#
#   Purpose....: Create a bitmap from a bmp file
#
#   In params..: FileName		File to read
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
TBitmapGraphicDevice *CreateBmp(const char *FileName)
{
	TFile file(FileName);
	TBitmapFileHeader fh;
	TBitmapInfoHeader ih;
	TBitmapGraphicDevice *dev;
	char *bits;
	int LineSize;
	int FileLineSize;
	int Line;

	if (file.IsOpen())
	{
		if (file.Read(&fh, sizeof(fh)) == sizeof(fh))
		{
			if (fh.Type[0] != 'B' || fh.Type[1] != 'M')
				return 0;

			if (fh.Size != file.GetSize())
				return 0;

			if (file.Read(&ih, sizeof(ih)) == sizeof(ih))
			{
				if (ih.Size < sizeof(ih))
					return 0;

				if (ih.Planes != 1)
					return 0;

				if (ih.Compression)
					return 0;

				switch (ih.BitCount)
				{
					case 24:
						dev = new TBitmapGraphicDevice(ih.BitCount,	ih.Width, ih.Height);
						FileLineSize = 3 * ih.Width;
						if (FileLineSize % 4 != 0)
							FileLineSize = 4 * (FileLineSize / 4);
						bits = (char *)dev->GetLinear();
						LineSize = dev->GetLineSize();

						for (Line = dev->GetHeight() - 1; Line >= 0; Line--)
							file.Read(bits + Line * LineSize, FileLineSize);
						return dev;

					default:
						return 0;
				}

			}
			else
				return 0;
		}
	}
	else
		return 0;
}
