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

#define FALSE	0
#define TRUE	!FALSE

const RLE_COMMAND     = 0;
const RLE_ENDOFLINE   = 0;
const RLE_ENDOFBITMAP = 1;
const RLE_DELTA       = 2;
const BI_RGB          = 0;
const BI_RLE8         = 1;
const BI_RLE4         = 2;
const BI_BITFIELDS    = 3;

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
#   Name       : Reverse
#
#   Purpose....: Reverse a byte
#
#   In params..: Byte ptr
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static Reverse(const char *src, char *dest, int size)
{
	int i, j;
	char ch1, ch2;
	int mask1, mask2;

	for (i = 0; i < size; i++)
	{
		ch1 = *(src + i);
		mask1 = 1;
		ch2 = 0;
		mask2 = 0x80;

		for (j = 0; j < 8; j++)
		{
			if (mask1 & ch1)
				ch2 |= mask2;
			mask1 = mask1 << 1;
			mask2 = mask2 >> 1;
		}
		*(dest + i) = ch2;
	}
}

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
	char *buf;

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

				file.SetPos(fh.BitOffset);

				switch (ih.BitCount)
				{
					case 1:
						dev = new TBitmapGraphicDevice(ih.BitCount,	ih.Width, ih.Height);
						FileLineSize = (ih.Width + 7) / 8;
						FileLineSize = (FileLineSize + 3) & (~3);
						bits = (char *)dev->GetLinear();
						LineSize = dev->GetLineSize();

						buf = new char[LineSize];
						for (Line = dev->GetHeight() - 1; Line >= 0; Line--)
						{
							file.Read(buf, FileLineSize);
							Reverse(buf, bits + Line * LineSize, LineSize);
						}
						delete buf;
						return dev;

					case 24:
						dev = new TBitmapGraphicDevice(ih.BitCount,	ih.Width, ih.Height);
						FileLineSize = 3 * ih.Width;
						FileLineSize = (FileLineSize + 3) & (~3);
						bits = (char *)dev->GetLinear();
						LineSize = dev->GetLineSize();

						for (Line = dev->GetHeight() - 1; Line >= 0; Line--)
							file.Read(bits + Line * LineSize, FileLineSize);
						return dev;

					default:
						return 0;
				}

			}
		}
	}
	return 0;
}

/*##########################################################################
#
#   Name       : SaveBmp
#
#   Purpose....: Save a bitmap to a bmp file
#
#   In params..: FileName		File to write
#              : bitmap
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int SaveBmp(const char *FileName, TBitmapGraphicDevice *bitmap)
{
	TFile file(FileName, FILE_ATTRIBUTE_ARCHIVE);
	TBitmapFileHeader fh;
	TBitmapInfoHeader ih;
	char *bits;
	int LineSize;
	int FileLineSize;
	int Line;
	int Count;
	int Pixel;
	char *buf;
	char *pal;

	if (file.IsOpen())
	{
		file.SetSize(0);

		fh.Type[0] = 'B';
		fh.Type[1] = 'M';
		fh.Size = sizeof(fh) + sizeof(ih);
		fh.Reserved = 0;
		fh.BitOffset = fh.Size;

		ih.Size = sizeof(ih);
		ih.Width = bitmap->GetWidth();
		ih.Height = bitmap->GetHeight();
		ih.Planes = 1;
		ih.BitCount = bitmap->GetBpp();
		ih.Compression = 0;
		ih.ImageSize = 0;
		ih.XPelsPerMeter = 0;
		ih.YPelsPerMeter = 0;
		ih.ClrUsed = 0;
		ih.ClrImportant = 0;

		switch (ih.BitCount)
		{
			case 1:
				FileLineSize = (ih.Width + 7) / 8;
				FileLineSize = (FileLineSize + 3) & (~3);
				bits = (char *)bitmap->GetLinear();
				LineSize = bitmap->GetLineSize();

			    ih.ClrUsed = 2;
			    fh.BitOffset += 6;
				ih.ImageSize = FileLineSize * ih.Height;
				fh.Size += ih.ImageSize + 6;

				file.Write(&fh, sizeof(fh));
				file.Write(&ih, sizeof(ih));

                pal = new char[6];
                *pal = 0;
                *(pal + 1) = 0;
                *(pal + 2) = 0;
                *(pal + 3) = 255;
                *(pal + 4) = 255;
                *(pal + 5) = 255;
                file.Write(pal, 6);
                delete pal;

				buf = new char[LineSize];
				for (Line = bitmap->GetHeight() - 1; Line >= 0; Line--)
				{
					Reverse(bits + Line * LineSize, buf, LineSize);
					file.Write(buf, FileLineSize);
				}
				delete buf;
				return TRUE;


		    case 24:
				FileLineSize = 3 * ih.Width;
				FileLineSize = (FileLineSize + 3) & (~3); 
				bits = (char *)bitmap->GetLinear();
				LineSize = bitmap->GetLineSize();

				ih.ImageSize = FileLineSize * ih.Height;
				fh.Size += ih.ImageSize;

				file.Write(&fh, sizeof(fh));
				file.Write(&ih, sizeof(ih));

				for (Line = bitmap->GetHeight() - 1; Line >= 0; Line--)
					file.Write(bits + Line * LineSize, FileLineSize);
				return TRUE;

			case 32:
				ih.BitCount = 24;
				FileLineSize = 3 * ih.Width;
				FileLineSize = (FileLineSize + 3) & (~3);
				bits = (char *)bitmap->GetLinear();
				LineSize = bitmap->GetLineSize();

				ih.ImageSize = FileLineSize * ih.Height;
				fh.Size += ih.ImageSize;

				file.Write(&fh, sizeof(fh));
				file.Write(&ih, sizeof(ih));

				for (Line = bitmap->GetHeight() - 1; Line >= 0; Line--)
				{
				    Count = 0;
				    for (Pixel = 0; Pixel < bitmap->GetWidth(); Pixel++)
				    {
				        Count += 3;
    					file.Write(bits + Line * LineSize + 4 * Pixel, 3);
    				}
    				if (Count != FileLineSize)
    				    file.Write(&Count, FileLineSize - Count);
    			}
				return TRUE;

			default:
				return FALSE;
		}
	}
	else
		return FALSE;
}
