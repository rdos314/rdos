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
# graphdev.cpp
# Graphic device class
#
########################################################################*/

#include "rdos.h"
#include "graphdev.h"

#define FALSE	0
#define TRUE	!FALSE

/*##########################################################################
#
#   Name       : TGraphicDevice::TGraphicDevice
#
#   Purpose....: Constructor for TGraphicDevice		                          
#
#   In params..: 
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphicDevice::TGraphicDevice()
{
    FBpp = 0;
    FWidth = 0;
    FHeight = 0;
    FBitmapHandle = 0;
    FColor = 0;
    FLgop = LGOP_NONE;
    FFilledStyle = FALSE;
    FFontHandle = 0;

    InitDevice();
}

/*##########################################################################
#
#   Name       : TGraphicDevice::TGraphicDevice
#
#   Purpose....: Constructor for TGraphicDevice		                          
#
#   In params..: handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphicDevice::TGraphicDevice(int handle)
{
    FBpp = 0;
    FWidth = 0;
    FHeight = 0;
    FBitmapHandle = RdosDuplicateBitmapHandle(handle);
    FColor = 0;
    FLgop = LGOP_NONE;
    FFilledStyle = FALSE;
    FFontHandle = 0;

    InitDevice();
}

/*##########################################################################
#
#   Name       : TGraphicDevice::TGraphicDevice
#
#   Purpose....: Constructor for TGraphicDevice		                          
#
#   In params..: bpp		bits per pixel
#				 width
#				 height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphicDevice::TGraphicDevice(int bpp, int width, int height)
{
    FBpp = bpp;
    FWidth = width;
    FHeight = height;
    FBitmapHandle = 0;
    if (bpp == 1)
	FColor = 0xFFFFFF;
    else
	FColor = 0;
    FLgop = LGOP_NONE;
    FFilledStyle = FALSE;
    FFontHandle = 0;

    InitDevice();
}

/*##########################################################################
#
#   Name       : TGraphicDevice::TGraphicDevice
#
#   Purpose....: Copy constructor for TGraphicDevice
#
#   In params..: dev		graphic device to alias
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphicDevice::TGraphicDevice(const TGraphicDevice &dev)
{
    FBpp = dev.FBpp;
    FWidth = dev.FWidth;
    FHeight = dev.FHeight;
    FRowSize = dev.FRowSize;
    FLinear = dev.FLinear;
    if (FBpp == 1)
        FColor = 0xFFFFFF;
    else
        FColor = 0;
    FLgop = LGOP_NONE;
    FFilledStyle = FALSE;
    if (dev.FBitmapHandle)
        FBitmapHandle = RdosDuplicateBitmapHandle(dev.FBitmapHandle);
    else
        FBitmapHandle = 0;
    FFontHandle = 0;

    InitDevice();
}

/*##########################################################################
#
#   Name       : TGraphicDevice::operator=
#
#   Purpose....: Assignment operator for TGraphicDevice
#
#   In params..: dev		graphic device to alias
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphicDevice &TGraphicDevice::operator=(const TGraphicDevice &dev)
{
    if (this != &dev)
    {
    	FBpp = dev.FBpp;
	    FWidth = dev.FWidth;
    	FHeight = dev.FHeight;
	    FRowSize = dev.FRowSize;
    	FLinear = dev.FLinear;
	    if (FBpp == 1)
		    FColor = 0xFFFFFF;
    	else
	    	FColor = 0;
    	FLgop = LGOP_NONE;
	    FFilledStyle = FALSE;
    	if (dev.FBitmapHandle)
	    	FBitmapHandle = RdosDuplicateBitmapHandle(dev.FBitmapHandle);
    	else
	    	FBitmapHandle = 0;
        FFontHandle = 0;
        InitDevice();
    }
    return *this;
}

/*##########################################################################
#
#   Name       : TGraphicDevice::~TGraphicDevice
#
#   Purpose....: Destructor for TGraphicDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGraphicDevice::~TGraphicDevice()
{
    if (FBitmapHandle)
        RdosCloseBitmap(FBitmapHandle);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::InitDevice
#
#   Purpose....: Init device-settings
#
#   In params..: *
#   Out params.: *
#   Returns....: Bits per pixel
#
##########################################################################*/
void TGraphicDevice::InitDevice()
{
    if (FBitmapHandle)
    {
        RdosGetBitmapInfo(FBitmapHandle, &FBpp, &FWidth, &FHeight, &FRowSize, &FLinear);

        RdosSetDrawColor(FBitmapHandle, FColor);
        RdosSetLGOP(FBitmapHandle, FLgop);

        if (FFontHandle)
            RdosSetFont(FBitmapHandle, FFontHandle);

        if (FFilledStyle)
    	    RdosSetFilledStyle(FBitmapHandle);
        else
    	    RdosSetHollowStyle(FBitmapHandle);
    }
}

/*##########################################################################
#
#   Name       : TGraphicDevice::GetBpp
#
#   Purpose....: Get bits per pixel
#
#   In params..: *
#   Out params.: *
#   Returns....: Bits per pixel
#
##########################################################################*/
int TGraphicDevice::GetBpp()
{
	return FBpp;
}

/*##########################################################################
#
#   Name       : TGraphicDevice::GetWidth
#
#   Purpose....: Get width
#
#   In params..: *
#   Out params.: *
#   Returns....: Width
#
##########################################################################*/
int TGraphicDevice::GetWidth()
{
    return FWidth;
}

/*##########################################################################
#
#   Name       : TGraphicDevice::GetHeight
#
#   Purpose....: Get height
#
#   In params..: *
#   Out params.: *
#   Returns....: Height
#
##########################################################################*/
int TGraphicDevice::GetHeight()
{
    return FHeight;
}

/*##########################################################################
#
#   Name       : TGraphicDevice::GetLinear
#
#   Purpose....: Get linear
#
#   In params..: *
#   Out params.: *
#   Returns....: Linear address
#
##########################################################################*/
void *TGraphicDevice::GetLinear()
{
    return FLinear;
}

/*##########################################################################
#
#   Name       : TGraphicDevice::GetLineSize
#
#   Purpose....: Get size of a line
#
#   In params..: *
#   Out params.: *
#   Returns....: Size of line
#
##########################################################################*/
int TGraphicDevice::GetLineSize()
{
    return FRowSize;
}

/*##########################################################################
#
#   Name       : TGraphicDevice::GetHandle
#
#   Purpose....: Get RDOS handle for bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: Handle
#
##########################################################################*/
int TGraphicDevice::GetHandle()
{
    return FBitmapHandle;
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetFont
#
#   Purpose....: Set current font
#
#   In params..: font
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetFont(TFont *font)
{
    if (font && FFontHandle != font->FFontHandle)
    {
        FFontHandle = font->FFontHandle;
        RdosSetFont(FBitmapHandle, FFontHandle);
    }
}

/*##########################################################################
#
#   Name       : TGraphicDevice::CreateSprite
#
#   Purpose....: Create a new sprite
#
#   In params..: bitmap             Sprite bitmap
#              : mask               1-bit sprite mask
#              : hotx, hoty         hot-spot of sprite        
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSprite *TGraphicDevice::CreateSprite(TGraphicDevice *bitmap, TGraphicDevice *mask, int hotx, int hoty)
{
    TSprite *sprite;

    sprite = new TSprite(this, bitmap, mask, hotx, hoty);

    return sprite;    
}

/*##########################################################################
#
#   Name       : TGraphicDevice::ClearClipRect
#
#   Purpose....: Set clipping to entire device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::ClearClipRect()
{
    RdosClearClipRect(FBitmapHandle);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetClipRect
#
#   Purpose....: Set clip-rect to specified area   
#
#   In params..: xmin, ymin         One corner
#                xmax, ymax         Other corner  
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetClipRect(int xmin, int ymin, int xmax, int ymax)
{
    RdosSetClipRect(FBitmapHandle, xmin, ymin, xmax, ymax);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetDrawColor
#
#   Purpose....: Set draw color   
#
#   In params..: r, g, b            RGB value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetDrawColor(int r, int g, int b)
{
    int color = mkcolor(r, g, b);

    if (color != FColor)
    {
        FColor = color;
        RdosSetDrawColor(FBitmapHandle, FColor);
    }
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopNull
#
#   Purpose....: Set operation to ignore all operations    
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopNull()
{
    if (FLgop != LGOP_NULL)
    {
        FLgop = LGOP_NULL;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopNone
#
#   Purpose....: Set operation to copy. Default.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopNone()
{
    if (FLgop != LGOP_NONE)
    {
        FLgop = LGOP_NONE;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopOr
#
#   Purpose....: Set operation to bitwise OR colors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopOr()
{
	if (FLgop != LGOP_OR)
	{
		FLgop = LGOP_OR;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopAnd
#
#   Purpose....: Set operation to bitwise AND colors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopAnd()
{
	if (FLgop != LGOP_AND)
	{
		FLgop = LGOP_AND;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopXor
#
#   Purpose....: Set operation to bitwise XOR colors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopXor()
{
	if (FLgop != LGOP_XOR)
	{
		FLgop = LGOP_XOR;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopInv
#
#   Purpose....: Set operation to invert draw operand color and copy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopInv()
{
	if (FLgop != LGOP_INVERT)
	{
		FLgop = LGOP_INVERT;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopInvOr
#
#   Purpose....: Set operation to invert draw operand color and bitwise OR
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopInvOr()
{
	if (FLgop != LGOP_INVERT_OR)
	{
		FLgop = LGOP_INVERT_OR;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopInvAnd
#
#   Purpose....: Set operation to invert draw operand color and bitwise AND
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopInvAnd()
{
	if (FLgop != LGOP_INVERT_AND)
	{
		FLgop = LGOP_INVERT_AND;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopInvXor
#
#   Purpose....: Set operation to invert draw operand color and bitwise XOR
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopInvXor()
{
	if (FLgop != LGOP_INVERT_XOR)
	{
		FLgop = LGOP_INVERT_XOR;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopAdd
#
#   Purpose....: Set operation to saturate add operands
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopAdd()
{
	if (FLgop != LGOP_ADD)
	{
		FLgop = LGOP_ADD;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopSub
#
#   Purpose....: Set operation to saturate sub operands
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopSub()
{
	if (FLgop != LGOP_SUBTRACT)
	{
		FLgop = LGOP_SUBTRACT;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetLgopMul
#
#   Purpose....: Set operation to saturate multiply operands
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetLgopMul()
{
	if (FLgop != LGOP_MULTIPLY)
	{
		FLgop = LGOP_MULTIPLY;
		RdosSetLGOP(FBitmapHandle, FLgop);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetHollowStyle
#
#   Purpose....: Set hollow style (doesn't fill interior)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetHollowStyle()
{
	if (FFilledStyle)
	{
		FFilledStyle = FALSE;
		RdosSetHollowStyle(FBitmapHandle);
	}
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetFilledStyle
#
#   Purpose....: Set filled style (fill interior)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetFilledStyle()
{
	if (!FFilledStyle)
	{
		FFilledStyle = TRUE;
		RdosSetFilledStyle(FBitmapHandle);
    }
}

/*##########################################################################
#
#   Name       : TGraphicDevice::GetPixel
#
#   Purpose....: Get a single pixel
#
#   In params..: *
#   Out params.: *
#   Returns....: RGB-packed pixel
#
##########################################################################*/
int TGraphicDevice::GetPixel(int x, int y)
{
    return RdosGetPixel(FBitmapHandle, x, y);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::SetPixel
#
#   Purpose....: Set a single pixel using current color
#
#   In params..: x, y       coordinate
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::SetPixel(int x, int y)
{
    RdosSetPixel(FBitmapHandle, x, y);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::Blit
#
#   Purpose....: Copy from one bitmap to another   
#
#   In params..: src            source bitmap (this is destination)
#              : srcx, srcy     start point of source bitmap
#              : x, y           start point to blit to
#              : width          width of pixels to copy
#              : height         height of pixels to copy
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::Blit(TGraphicDevice *src, int srcx, int srcy, int x, int y, int width, int height)
{
    RdosBlit(   src->FBitmapHandle, FBitmapHandle,
                width, height,
                srcx, srcy,
                x, y);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::DrawLine
#
#   Purpose....: Draw a line using current color
#
#   In params..: x1, y1       one end-point
#              : x2, y2       the other end-point
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::DrawLine(int x1, int y1, int x2, int y2)
{
    RdosDrawLine(FBitmapHandle, x1, y1, x2, y2);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::DrawString
#
#   Purpose....: Draw a string using current font and color
#
#   In params..: x, y       upper left corner of string
#              : str        string
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::DrawString(int x, int y, const char *str)
{
    RdosDrawString(FBitmapHandle, x, y, str);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::DrawRect
#
#   Purpose....: Draw a rectangle using current fill-style and color    
#
#   In params..: x1, y1     one corner       
#              : x2, y2     the other corner
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::DrawRect(int x1, int y1, int x2, int y2)
{
    int w, h;
    int x, y;

    w = x2 - x1;
    if (w < 0)
    {
        x = x2;
        w = -w;
    }
    else
        x = x1;
    w++;

    h = y2 - y1;
    if (h < 0)
    {
        y = y2;
        h = -h;
    }
    else
        y = y1;
    h++;
    
    RdosDrawRect(FBitmapHandle, x, y, w, h);
}

/*##########################################################################
#
#   Name       : TGraphicDevice::DrawEllipse
#
#   Purpose....: Draw an ellipse using current fill-style and color 
#
*   In params..: x, y       center of ellipse       
*              : rx, ry     radius in x and y direction
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGraphicDevice::DrawEllipse(int x, int y, int rx, int ry)
{
    RdosDrawEllipse(FBitmapHandle, x - rx, y - ry, 2 * rx + 1, 2 * ry + 1);
}
