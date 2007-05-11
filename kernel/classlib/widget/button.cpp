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
# keyctl.cpp
# Graphics keyboard control class
#
########################################################################*/

#include <string.h>

#include "keyctl.h"

#define FALSE	0
#define TRUE	!FALSE

/*##########################################################################
#
#   Name       : TButtonFactory::TButtonFactory
#
#   Purpose....: Button factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactory::TButtonFactory()
{
    FWidth = 0;
    FUpShiftX = 0;
    FUpShiftY = 0;
    FDownShiftX = 4;
    FDownShiftY = 4;
    FDisabledShiftX = 0;
    FDisabledShiftY = 0;        

    FTextR = 0;
    FTextG = 0;
    FTextB = 0;

    FShadowR = 210;
    FShadowG = 210;
    FShadowB = 210;

    FHeight = FLeft->GetHeight();

    if (FHeight < FMid->GetHeight())
        FHeight = FMid->GetHeight();

    if (FHeight < FRight->GetWidth())
        FHeight = FRight->GetWidth();

	FFont = new TFont(FMid->GetHeight() * 2 / 3);

	CreateDefaultBitmaps();
}

/*##########################################################################
#
#   Name       : TButtonFactory::~TButtonFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactory::~TButtonFactory()
{
    DeleteUp();
    DeleteDown();
    DeleteDisabled();
    
    delete FFont;
}

/*##########################################################################
#
#   Name       : TButtonFactory::DeleteUp
#
#   Purpose....: Delete up button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DeleteUp()
{
    if (FUpLeft)
    {
        delete FUpLeft;
        FUpLeft = 0;
    }

    if (FUpMid)
    {
        delete FUpMid;    
        FUpMid = 0;
    }

    if (FUpRight)
    {
        delete FUpRight;
        FUpRight = 0;
    }
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineUp
#
#   Purpose....: Define up button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineUp(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right)
{
    DeleteUp();

    FUpLeft = new TBitmapGraphicDevice(*Left);
    FUpMid = new TBitmapGraphicDevice(*Mid);
    FUpRight = new TBitmapGraphicDevice(*Right);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DeleteDown
#
#   Purpose....: Delete down button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DeleteDown()
{
    if (FDownLeft)
    {
        delete FDownLeft;
        FDownLeft = 0;
    }

    if (FDownMid)
    {
        delete FDownMid;    
        FDownMid = 0;
    }

    if (FDownRight)
    {
        delete FDownRight;
        FDownRight = 0;
    }
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineDown
#
#   Purpose....: Define down button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineDown(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right)
{
    DeleteDown();

    FDownLeft = new TBitmapGraphicDevice(*Left);
    FDownMid = new TBitmapGraphicDevice(*Mid);
    FDwnRight = new TBitmapGraphicDevice(*Right);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DeleteDisabled
#
#   Purpose....: Delete disabled button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DeleteDisabled()
{
    if (FDisabledLeft)
    {
        delete FDisabledLeft;
        FDisabledLeft = 0;
    }

    if (FDisabledMid)
    {
        delete FDisabledMid;    
        FDisabledMid = 0;
    }

    if (FDisabledRight)
    {
        delete FDisabledRight;
        FDisabledRight = 0;
    }
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineDisabled
#
#   Purpose....: Define disabled button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineDisabled(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right)
{
    DeleteDisabled();

    FDisabledLeft = new TBitmapGraphicDevice(*Left);
    FDisabledMid = new TBitmapGraphicDevice(*Mid);
    FDisabledRight = new TBitmapGraphicDevice(*Right);
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetWidth
#
#   Purpose....: Set fixed button width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetWidth(int width)
{
    FWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpShift
#
#   Purpose....: Set text shift for up-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpShift(int x, int y)
{
    FUpShiftX = x;
    FUpShifyY = y;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownShift
#
#   Purpose....: Set text shift for down-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownShift(int x, int y)
{
    FDownShiftX = x;
    FDownShifyY = y;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledShift
#
#   Purpose....: Set text shift for disabled-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledShift(int x, int y)
{
    FDisabledShiftX = x;
    FDisabledShifyY = y;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetFont(TFont *Font)
{
    delete FFont;
    FFont = Font;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetTextColor
#
#   Purpose....: Set text color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetTextColor(int r, int g, int b)
{
    FTextR = r;
    FTextG = g;
    FTextB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetShadowColor
#
#   Purpose....: Set shadow color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetShadowColor(int r, int g, int b)
{
    FShadowR = r;
    FShadowG = g;
    FShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::GetWidth
#
#   Purpose....: Get button width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonFactory::GetWidth(const char *text)
{
    int width;
    int xsize;
    int ysize;

    if (FWidth)
        width = FWidth;
    else
    {
        width = Left->GetWidth() + Right->GetWidth();
    	FFont->GetStringMetrics(text, &xsize, &ysize);
    	width += xsize;
    }

    return width;
}

/*##########################################################################
#
#   Name       : TButtonFactory::GetTextStart
#
#   Purpose....: Get start position of text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::GetTextStart(const char *text, int *x, int *y)
{
    int xsize;
    int ysize;
    int midsize;
    int left;

    FFont->GetStringMetrics(text, &xsize, &ysize);

    *x = FLeft->GetWidth();
    *y = (FHeight - ysize) / 2;

    if (FWidth)
    {
        midsize = FWidth - FLeft->GetWidth() - FRight->GetWidth();
        left = (midsize - xsize) / 2;
        *x += left;
    }
}

/*##########################################################################
#
#   Name       : TButtonFactory::CreateBitmap
#
#   Purpose....: Create a bitmap with the background buttons
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDecive *TButtonFactory::CreateBitmap(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right, int width)
{
	TBitmapGraphicDevice *bitmap;
	int midsize;
	int i;
	int left;
	int right;

    if (Left && Mid && Right)
    {
        left = Left->GetWidth();
        right = Right->GetWidth();
    	midsize = width - left - right;

    	bitmap = new TBitmapGraphicDevice(24, width, FHeight);
	    bitmap->SetLgopNone();

    	bitmap->Blit(Left, 0, 0, 0, 0, left, FHeight);
	    bitmap->Blit(Right, 0, 0, width - right, 0, right, FHeight);

    	for (i = 0; i < midsize; i++)
            bitmap->Blit(Mid, 0, 0, i + left, 0, 1, FHeight);

        return bitmap;
    }
    else
        return 0;
}
    
/*##########################################################################
#
#   Name       : TButtonFactory::DrawText
#
#   Purpose....: Draw text on bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DrawText(TBitmapGraphicDecive *bitmap, const char *text, int x, int y)
{
	bitmap->SetFont(FFont);
    bitmap->SetDrawColor(FShadowR, FShadowG, FShadowB);
    bitmap->DrawString(x, y, text);
    bitmap->DrawString(x + 1, y, text);
	bitmap->DrawString(x - 1, y, text);
	bitmap->DrawString(x, y + 1, text);
	bitmap->DrawString(x, y - 1, text);
	bitmap->DrawString(x + 1, y + 1, text);
	bitmap->DrawString(x - 1, y - 1, text);
	bitmap->DrawString(x - 1, y + 1, text);
	bitmap->DrawString(x + 1, y - 1, text);

	bitmap->SetDrawColor(FTextR, FTextG, FTextB);
	bitmap->DrawString(x, y, text);
}

/*##########################################################################
#
#   Name       : TButtonFactory::CreateUpButton
#
#   Purpose....: Create up button bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *TButtonFactory::CreateUpButton(const char *text)
{
	TBitmapGraphicDevice *bitmap;
	int xstart;
	int ystart;
	int width

	width = GetWidth(text);
	bitmap = CreateBitmap(FUpLeft, FUpMid, FUpRight, width);
	GetTextStart(text, &xstart, &ystart);

    xstart += FUpShiftX;
    ystart += FUpShiftY;

	DrawText(bitmap, text, xstart, ystart);

    return bitmap;
}

/*##########################################################################
#
#   Name       : TButtonFactory::CreateDownButton
#
#   Purpose....: Create down button bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *TButtonFactory::CreateDownButton(const char *text)
{
	TBitmapGraphicDevice *bitmap;
	int xstart;
	int ystart;
	int width

	width = GetWidth(text);
	bitmap = CreateBitmap(FDownLeft, FDownMid, FDownRight, width);
	GetTextStart(text, &xstart, &ystart);

    xstart += FDownShiftX;
    ystart += FDownShiftY;

	DrawText(bitmap, text, xstart, ystart);

    return bitmap;
}

/*##########################################################################
#
#   Name       : TButtonFactory::CreateDisabledButton
#
#   Purpose....: Create disabled button bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *TButtonFactory::CreateDisabledButton(const char *text)
{
	TBitmapGraphicDevice *bitmap;
	int xstart;
	int ystart;
	int width

	width = GetWidth(text);
	bitmap = CreateBitmap(FDisabledLeft, FDisabledMid, FDisabledRight, width);
	GetTextStart(text, &xstart, &ystart);

    xstart += FDownShiftX;
    ystart += FDownShiftY;

	DrawText(bitmap, text, xstart, ystart);

    return bitmap;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControlThread *dev, const char *text, char ch, int xstart, int ystart)
{
    TBitmapGraphicDevice *Up;
    TBitmapGraphicDevice *Down;
    TBitmapGraphicDevice *Disabled;
    TButtonControl *button;

    Up = CreateUpButton(text);
    Down = CreateDownButton(text);
    Disabled = CreateDisabledButton(text);

    button = new TButtonControl(dev, Up, Down, Disabled, ch, xstart, ystart);

    delete Up;
    delete Down;
    delete Disabled;

    return button;        
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControl *control, const char *text, char ch, int xstart, int ystart)
{
    TBitmapGraphicDevice *Up;
    TBitmapGraphicDevice *Down;
    TBitmapGraphicDevice *Disabled;
    TButtonControl *button;

    Up = CreateUpButton(text);
    Down = CreateDownButton(text);
    Disabled = CreateDisabledButton(text);

    button = new TButtonControl(control, Up, Down, Disabled, ch, xstart, ystart);

    delete Up;
    delete Down;
    delete Disabled;

    return button;        
}
    
/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControlThread *dev, const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, char ch, int xstart, int ystart)
 : TControl(dev)
{
	 Init(Up, Down, Disable, ch, xstart, ystart);
}

/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControl *control, const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, char ch, int xstart, int ystart)
 : TControl(control)
{
	 Init(Up, Down, Disable, ch, xstart, ystart);
}

/*##########################################################################
#
#   Name       : TButtonControl::~TButtonControl
#
#   Purpose....: Key control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::~TButtonControl()
{
    DeleteKeys();
}

/*##########################################################################
#
#   Name       : TButtonControl::Init
#
#   Purpose....: Init key control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::Init(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, char ch, int xstart, int ystart)
{
	FUp = 0;
	FDown = 0;
	FDisabled = 0;

    FPressed = FALSE;
    FKey = ch;
    FKeepDown = FALSE;
    FActive = FALSE;

    FStartX = xstart;
    FStartY = ystart;

    UpdateKeys(Up, Down, Disable);
}

/*##########################################################################
#
#   Name       : TButtonControl::DeleteKeys
#
#   Purpose....: Delete key bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DeleteKeys()
{
    if (FUp)
    {
        delete FUp;
        FUp = 0;
    }

    if (FDown)
    {
        delete FDown;
        FDown = 0;
    }
    
    if (FDisabled)
    {
        delete FDisabled;
        FDisabled = 0;
    }
}

/*##########################################################################
#
#   Name       : TButtonControl::UpdateKeys
#
#   Purpose....: Update key bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::UpdateKeys(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable)
{
	TFont Font(30);
	int xstart;
	int ystart;
	int xsize;
    int ysize;
	int key_xsize;
	int key_ysize;
	const char *text;

    DeleteKeys();

    if (Up)    
		FUp = new TBitmapGraphicDevice(*Up);
    else
        FUp = 0;

    if (Down)          
		FDown = new TBitmapGraphicDevice(*Down);
	else
		FDown = 0;

	if (Disable)
    	FDisabled = new TBitmapGraphicDevice(*Disable);
    else
        FDisabled = 0;

    FSizeX = 0;
    FSizeY = 0;

    if (FUp)
    {
        xsize = FUp->GetWidth();
        ysize = FUp->GetHeight();

        if (xsize > FSizeX)
            FSizeX = xsize;

        if (ysize > FSizeY)
            FSizeY = ysize;
    }

    if (FDown)
    {
        xsize = FDown->GetWidth();
        ysize = FDown->GetHeight();

        if (xsize > FSizeX)
            FSizeX = xsize;

        if (ysize > FSizeY)
            FSizeY = ysize;
    }

    if (FDisabled)
    {
        xsize = FDisabled->GetWidth();
        ysize = FDisabled->GetHeight();

        if (xsize > FSizeX)
            FSizeX = xsize;

        if (ysize > FSizeY)
            FSizeY = ysize;
    }

    if (FUp || FDown || FDisabled)
    {
    	Resize(FSizeX, FSizeY);
	    Move(FStartX, FStartY);
	}
}

/*##########################################################################
#
#   Name       : TButtonControl::EnableKeepDown
#
#   Purpose....: Enable keep key down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::EnableKeepDown()
{
    FKeepDown = TRUE;
}

/*##########################################################################
#
#   Name       : TButtonControl::ChangeImage
#
#   Purpose....: Init key control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::ChangeImage(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable)
{
    UpdateKeys(Up, Down, Disable);
}

/*##########################################################################
#
#   Name       : TButtonControl::OnLeftUp
#
#   Purpose....: Handle left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    if (FPressed)
    {
        FPressed = FALSE;
        Redraw();
    }
    
    return FALSE;
}

/*##########################################################################
#
#   Name       : TButtonControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    if (IsInside(x, y))
    {
        PutKey(FKey);
        if (!FKeepDown)
        {
            FPressed = TRUE;
            Redraw();
        }
        return TRUE;
    }
    else
    {
        if (FPressed && !FKeepDown)
        {
            FPressed = FALSE;
            Redraw();
        }
        return FALSE;
    }
}

/*##########################################################################
#
#   Name       : TButtonControl::OnKeyPressed
#
#   Purpose....: Handle key pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    if (VirtualKey == FKey)
    {
        if (!FPressed)
        {
            FPressed = TRUE;
            if (FKeepDown)
                FActive = TRUE;
                
            Redraw();
        }
    }
    else
    {
        if (FKeepDown && FActive)
        {
            FActive = FALSE;
            Redraw();
        }        
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TButtonControl::OnKeyReleased
#
#   Purpose....: Handle key released
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    if (VirtualKey == FKey)
    {
        if (FPressed)
        {
            FPressed = FALSE;
            Redraw();
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TButtonControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    TBitmapGraphicDevice *bitmap;

	if (IsVisible())
	{
    	dev->SetLgopNone();

        if (IsEnabled())
        {
            if (FPressed || FActive)
                bitmap = FDown;
            else
                bitmap = FUp;
        }
        else
            bitmap = FDisabled;

        if (bitmap)
            dev->Blit(bitmap, 0, 0, xmin, ymin, width, height);
        else
        {
            dev->SetFilledStyle();
            dev->SetDrawColor(150, 150, 150);
            dev->DrawRect(xmin, ymin, xmin + width, ymin + height);
        }
    }
}
