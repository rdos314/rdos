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

#include "button.h"

#define FALSE	0
#define TRUE	!FALSE

/*##########################################################################
#
#   Name       : TButtonFactoryParam::TButtonFactoryParam
#
#   Purpose....: Button factory parameters constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactoryParam::TButtonFactoryParam()
{
    ShiftX = 0;
    ShiftY = 0;

    TextR = 0;
    TextG = 0;
    TextB = 0;

    ShadowR = 210;
    ShadowG = 210;
    ShadowB = 210;

    Left = 0;
    Mid = 0;
    Right = 0;
}

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
    FFont = 0;

    FDown.ShiftX = 4;
    FDown.ShiftY = 4;
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
    Delete(FUp);
    Delete(FDown);
    Delete(FDisabled);

    if (FFont)    
        delete FFont;
}

/*##########################################################################
#
#   Name       : TButtonFactory::GetHeight
#
#   Purpose....: Get height of button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonFactory::GetHeight(TButtonFactoryParam &Param)
{
    int height;
    
    height = Param.Left->GetHeight();

    if (height < Param.Mid->GetHeight())
        height = Param.Mid->GetHeight();

    if (height < Param.Right->GetHeight())
        height = Param.Right->GetHeight();

    return height;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Delete
#
#   Purpose....: Delete button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::Delete(TButtonFactoryParam &Param)
{
    if (Param.Left)
    {
        delete Param.Left;
        Param.Left = 0;
    }

    if (Param.Mid)
    {
        delete Param.Mid;    
        Param.Mid = 0;
    }

    if (Param.Right)
    {
        delete Param.Right;
        Param.Right = 0;
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
    Delete(FUp);

    FUp.Left = new TBitmapGraphicDevice(*Left);
    FUp.Mid = new TBitmapGraphicDevice(*Mid);
    FUp.Right = new TBitmapGraphicDevice(*Right);
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
    Delete(FDown);

    FDown.Left = new TBitmapGraphicDevice(*Left);
    FDown.Mid = new TBitmapGraphicDevice(*Mid);
    FDown.Right = new TBitmapGraphicDevice(*Right);
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
    Delete(FDisabled);

    FDisabled.Left = new TBitmapGraphicDevice(*Left);
    FDisabled.Mid = new TBitmapGraphicDevice(*Mid);
    FDisabled.Right = new TBitmapGraphicDevice(*Right);
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
    FUp.ShiftX = x;
    FUp.ShiftY = y;
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
    FDown.ShiftX = x;
	FDown.ShiftY = y;
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
    FDisabled.ShiftX = x;
	FDisabled.ShiftY = y;
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
    if (FFont)
        delete FFont;

    FFont = new TFont(*Font);
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpTextColor
#
#   Purpose....: Set text color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpTextColor(int r, int g, int b)
{
    FUp.TextR = r;
    FUp.TextG = g;
    FUp.TextB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownTextColor
#
#   Purpose....: Set text color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownTextColor(int r, int g, int b)
{
    FDown.TextR = r;
    FDown.TextG = g;
    FDown.TextB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledTextColor
#
#   Purpose....: Set text color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledTextColor(int r, int g, int b)
{
    FDisabled.TextR = r;
    FDisabled.TextG = g;
    FDisabled.TextB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpShadowColor
#
#   Purpose....: Set shadow color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpShadowColor(int r, int g, int b)
{
    FUp.ShadowR = r;
    FUp.ShadowG = g;
    FUp.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownShadowColor
#
#   Purpose....: Set shadow color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownShadowColor(int r, int g, int b)
{
    FDown.ShadowR = r;
    FDown.ShadowG = g;
    FDown.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledShadowColor
#
#   Purpose....: Set shadow color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledShadowColor(int r, int g, int b)
{
    FDisabled.ShadowR = r;
    FDisabled.ShadowG = g;
    FDisabled.ShadowB = b;
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
int TButtonFactory::GetWidth(TButtonFactoryParam &Param, const char *text)
{
    int width;
    int xsize;
    int ysize;

    if (FWidth)
        width = FWidth;
    else
    {
        width = Param.Left->GetWidth() + Param.Right->GetWidth();
    	FFont->GetStringMetrics(text, &xsize, &ysize);
    	width += xsize;
    }

    return width;
}

/*##########################################################################
#
#   Name       : TButtonFactory::CreateFont
#
#   Purpose....: Create a font if it is missing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::CreateFont()
{
    int h1, h2, h3;
    int height;

    if (!FFont)
    {
        h1 = GetHeight(FUp);
        h2 = GetHeight(FDown);
        h3 = GetHeight(FDisabled);

        height = h1;

        if (height < h2)
            height = h2;

        if (height < h3)
            height = h3;

        FFont = new TFont(2 * height / 3);
    }
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
void TButtonFactory::GetTextStart(TButtonFactoryParam &Param, const char *text, int *x, int *y)
{
    int xsize;
    int ysize;
    int midsize;
    int left;
    int height;

    FFont->GetStringMetrics(text, &xsize, &ysize);

    height = GetHeight(Param);

    *x = Param.Left->GetWidth();
    *y = (height - ysize) / 2;

    if (FWidth)
    {
        midsize = FWidth - Param.Left->GetWidth() - Param.Right->GetWidth();
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
TBitmapGraphicDevice *TButtonFactory::CreateBitmap(TButtonFactoryParam &Param, int width)
{
	TBitmapGraphicDevice *bitmap;
	int midsize;
	int i;
	int left;
	int right;
	int height;

	if (Param.Left && Param.Mid && Param.Right)
	{
	    height = GetHeight(Param);
		left = Param.Left->GetWidth();
		right = Param.Right->GetWidth();
		midsize = width - left - right;

		bitmap = new TBitmapGraphicDevice(24, width, height);
	    bitmap->SetLgopNone();

		bitmap->Blit(Param.Left, 0, 0, 0, 0, left, height);
		bitmap->Blit(Param.Right, 0, 0, width - right, 0, right, height);

		for (i = 0; i < midsize; i++)
		    bitmap->Blit(Param.Mid, 0, 0, i + left, 0, 1, height);

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
void TButtonFactory::DrawText(TButtonFactoryParam &Param, TBitmapGraphicDevice *bitmap, const char *text, int x, int y)
{
	bitmap->SetFont(FFont);
    bitmap->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
    bitmap->DrawString(x, y, text);
    bitmap->DrawString(x + 1, y, text);
	bitmap->DrawString(x - 1, y, text);
	bitmap->DrawString(x, y + 1, text);
	bitmap->DrawString(x, y - 1, text);
	bitmap->DrawString(x + 1, y + 1, text);
	bitmap->DrawString(x - 1, y - 1, text);
	bitmap->DrawString(x - 1, y + 1, text);
	bitmap->DrawString(x + 1, y - 1, text);

	bitmap->SetDrawColor(Param.TextR, Param.TextG, Param.TextB);
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
TBitmapGraphicDevice *TButtonFactory::CreateButton(TButtonFactoryParam &Param, const char *text)
{
	TBitmapGraphicDevice *bitmap;
	int xstart;
	int ystart;
	int width;

	width = GetWidth(Param, text);
	bitmap = CreateBitmap(Param, width);
	GetTextStart(Param, text, &xstart, &ystart);

    xstart += Param.ShiftX;
    ystart += Param.ShiftY;

	DrawText(Param, bitmap, text, xstart, ystart);

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

    CreateFont();

    Up = CreateButton(FUp, text);
    Down = CreateButton(FDown, text);
    Disabled = CreateButton(FDisabled, text);

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

    CreateFont();

    Up = CreateButton(FUp, text);
    Down = CreateButton(FDown, text);
    Disabled = CreateButton(FDisabled, text);

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
	int xsize;
   int ysize;

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
        {
            bitmap = FDisabled;
            FPressed = FALSE;
            FActive = FALSE;
        }

        if (bitmap)
            dev->Blit(bitmap, 0, 0, xmin, ymin, width, height);
        else
        {
            dev->SetFilledStyle();
            dev->SetDrawColor(150, 150, 150);
            dev->DrawRect(xmin, ymin, xmin + width, ymin + height);
        }
    }
    else
    {
        FPressed = FALSE;
        FActive = FALSE;
    }
}
