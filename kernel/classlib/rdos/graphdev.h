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

