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
# sprite.cpp
# Sprite class
#
########################################################################*/

#include "rdos.h"
#include "sprite.h"
#include "graphdev.h"

/*##########################################################################
#
#   Name       : TSprite::TSprite
#
#   Purpose....: Constructor for TSprite
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSprite::TSprite()
{
    FSpriteHandle = 0;
}

/*##########################################################################
#
#   Name       : TSprite::TSprite
#
#   Purpose....: Constructor for TSprite
#
#   In params..: dest		Destination bitmap
#				 bitmap		Sprite bitmap
#				 mask		Mask bitmap
#				 HotX, HotY	Hotspot of bitmaps
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSprite::TSprite(TGraphicDevice *dest, TGraphicDevice *bitmap, TGraphicDevice *mask, int hotx, int hoty)
{
    FSpriteHandle = RdosCreateSprite(dest->FBitmapHandle, bitmap->FBitmapHandle, mask->FBitmapHandle, LGOP_NONE);
    FHotX = hotx;
    FHotY = hoty;
}

/*##########################################################################
#
#   Name       : TSprite::~TSprite
#
#   Purpose....: Destructor for TSprite
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSprite::~TSprite()
{
    if (FSpriteHandle)
        RdosCloseSprite(FSpriteHandle);
}

/*##########################################################################
#
#   Name       : TSprite::Define
#
#   Purpose....: Define sprite
#
#   In params..: dest		Destination bitmap
#				 bitmap		Sprite bitmap
#				 mask		Mask bitmap
#				 HotX, HotY	Hotspot of bitmaps
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSprite::Define(TGraphicDevice *dest, TGraphicDevice *bitmap, TGraphicDevice *mask, int hotx, int hoty)
{
    if (FSpriteHandle)
        RdosCloseSprite(FSpriteHandle);
        
    FSpriteHandle = RdosCreateSprite(dest->FBitmapHandle, bitmap->FBitmapHandle, mask->FBitmapHandle, LGOP_NONE);
    FHotX = hotx;
    FHotY = hoty;
}

/*##########################################################################
#
#   Name       : TSprite::Hide
#
#   Purpose....: Hide sprite
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSprite::Hide()
{
    RdosHideSprite(FSpriteHandle);
}

/*##########################################################################
#
#   Name       : TSprite::Show
#
#   Purpose....: Show sprite
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSprite::Show()
{
    RdosShowSprite(FSpriteHandle);
}

/*##########################################################################
#
#   Name       : TSprite::Move
#
#   Purpose....: Move sprite
#
#   In params..: x, y		New position
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSprite::Move(int x, int y)
{
    RdosMoveSprite(FSpriteHandle, x - FHotX, y - FHotY);
}
