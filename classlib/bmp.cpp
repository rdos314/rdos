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
# bmp.cpp
# Windows bmp interface
#
########################################################################*/

#include "rdos.h"
#include "bmp.h"
#include "file.h"

#define FALSE	0
#define TRUE	!FALSE

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
static void Reverse(const char *src, char *dest, int size)
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
#   Name       : TBmpBitmapDevice::TBmpBitmapDevice
#
#   Purpose....: Constructor for TBmpBitmapDevice
#
#   In params..: bpp		bits per pixel
#				 width
#				 height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBmpBitmapDevice::TBmpBitmapDevice(int bpp, int width, int height)
  : TBitmapGraphicDevice(bpp, width, height)
{
}

/*##########################################################################
#
#   Name       : TBmpBitmapDevice::TBmpBitmapDevice
#
#   Purpose....: Copy constructor for TBmpBitmapDevice
#
#   In params..: dev		bitmap to copy
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBmpBitmapDevice::TBmpBitmapDevice(const TBmpBitmapDevice &dev)
  : TBitmapGraphicDevice(dev)
{
}

/*##########################################################################
#
#   Name       : TBmpBitmapDevice::Create
#
#   Purpose....: Create a bitmap from a bmp file
#
#   In params..: FileName		File to read
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
TBmpBitmapDevice *TBmpBitmapDevice::Create(const char *FileName)
{
	TFile file(FileName);
	TBitmapFileHeader fh;
	TBitmapInfoHeader ih;
	TBmpBitmapDevice *dev;
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
						dev = new TBmpBitmapDevice(ih.BitCount,	ih.Width, ih.Height);
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
						dev = new TBmpBitmapDevice(ih.BitCount,	ih.Width, ih.Height);
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
#   Name       : TBmpBitmapDevice::Save
#
#   Purpose....: Save a bitmap to a bmp file
#
#   In params..: FileName		File to write
#              : bitmap
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TBmpBitmapDevice::Save(const char *FileName)
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
	long *pal;

	if (file.IsOpen())
	{
		file.SetSize(0);

		fh.Type[0] = 'B';
		fh.Type[1] = 'M';
		fh.Size = sizeof(fh) + sizeof(ih);
		fh.Reserved = 0;
		fh.BitOffset = fh.Size;

		ih.Size = sizeof(ih);
		ih.Width = GetWidth();
		ih.Height = GetHeight();
		ih.Planes = 1;
		ih.BitCount = GetBpp();
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
				bits = (char *)GetLinear();
				LineSize = GetLineSize();

			    ih.ClrUsed = 2;
				fh.BitOffset += 8;
				ih.ImageSize = FileLineSize * ih.Height;
				fh.Size += ih.ImageSize + 8;

				file.Write(&fh, sizeof(fh));
				file.Write(&ih, sizeof(ih));

				pal = new long[2];
				*pal = mkcolor(0, 0, 0);
				*(pal + 1) = mkcolor(255, 255, 255);
				file.Write(pal, 8);
				delete pal;

				buf = new char[LineSize];
				for (Line = GetHeight() - 1; Line >= 0; Line--)
				{
					Reverse(bits + Line * LineSize, buf, LineSize);
					file.Write(buf, FileLineSize);
				}
				delete buf;
				return TRUE;


		    case 24:
				FileLineSize = 3 * ih.Width;
				FileLineSize = (FileLineSize + 3) & (~3); 
				bits = (char *)GetLinear();
				LineSize = GetLineSize();

				ih.ImageSize = FileLineSize * ih.Height;
				fh.Size += ih.ImageSize;

				file.Write(&fh, sizeof(fh));
				file.Write(&ih, sizeof(ih));

				for (Line = GetHeight() - 1; Line >= 0; Line--)
					file.Write(bits + Line * LineSize, FileLineSize);
				return TRUE;

			case 32:
				ih.BitCount = 24;
				FileLineSize = 3 * ih.Width;
				FileLineSize = (FileLineSize + 3) & (~3);
				bits = (char *)GetLinear();
				LineSize = GetLineSize();

				ih.ImageSize = FileLineSize * ih.Height;
				fh.Size += ih.ImageSize;

				file.Write(&fh, sizeof(fh));
				file.Write(&ih, sizeof(ih));

				for (Line = GetHeight() - 1; Line >= 0; Line--)
				{
				    Count = 0;
				    for (Pixel = 0; Pixel < GetWidth(); Pixel++)
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
