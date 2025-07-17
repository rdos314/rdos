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
# graphdev.h
# Graphic device class
#
########################################################################*/

#ifndef _GRAPHIC_DEVICE_H
#define _GRAPHIC_DEVICE_H

#include "font.h"
#include "sprite.h"

class TGraphicDevice
{
friend class TSprite;

public:
	TGraphicDevice(int bpp, int width, int height);
	TGraphicDevice(const TGraphicDevice &dev);
	virtual ~TGraphicDevice();
    
    int GetBpp();
    int GetWidth();
    int GetHeight();
	void *GetLinear();
	int GetLineSize();

    void SetFont(TFont *font);
    TSprite *CreateSprite(TGraphicDevice *bitmap, TGraphicDevice *mask, int hotx, int hoty);
    
    void ClearClipRect();
    void SetClipRect(int xmin, int ymin, int xmax, int ymax);
    void SetDrawColor(int r, int g, int b);
    void SetLgopNull();
    void SetLgopNone();
    void SetLgopOr();
    void SetLgopAnd();
    void SetLgopXor();
    void SetLgopInv();
    void SetLgopInvOr();
    void SetLgopInvAnd();
    void SetLgopInvXor();
    void SetLgopAdd();
    void SetLgopSub();
    void SetLgopMul();
    void SetHollowStyle();
    void SetFilledStyle();

    int GetPixel(int x, int y);
    void SetPixel(int x, int y);
    void Blit(TGraphicDevice *src, int srcx, int srcy, int x, int y, int width, int height);
    void DrawLine(int x1, int y1, int x2, int y2);
    void DrawString(int x, int y, const char *str);
    void DrawRect(int x1, int y1, int x2, int y2);
    void DrawEllipse(int x, int y, int rx, int ry);

protected:
    int FBitmapHandle;
    int FFontHandle;
    int FBpp;
    int FWidth;
    int FHeight;
    int FRowSize;
    void *FLinear;

    int FColor;
    int FLgop;
    int FFilledStyle;
};

#endif

