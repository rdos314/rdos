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
#   Name       : TDisplayKeyControl::TDisplayKeyControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisplayKeyControl::TDisplayKeyControl(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, const char *Text, char ch, TControlThread *dev, int xstart, int ystart)
 : TControl(dev)
{
	 Init(Up, Down, Disable, Text, ch, xstart, ystart);
}

/*##########################################################################
#
#   Name       : TDisplayKeyControl::TDisplayKeyControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisplayKeyControl::TDisplayKeyControl(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, const char *Text, char ch, TControl *control, int xstart, int ystart)
 : TControl(control)
{
	 Init(Up, Down, Disable, Text, ch, xstart, ystart);
}

/*##########################################################################
#
#   Name       : TDisplayKeyControl::~TDisplayKeyControl
#
#   Purpose....: Key control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisplayKeyControl::~TDisplayKeyControl()
{
    DeleteKeys();
}

/*##########################################################################
#
#   Name       : TDisplayKeyControl::Init
#
#   Purpose....: Init key control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayKeyControl::Init(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, const char *Text, char ch, int xstart, int ystart)
{
    FPressed = FALSE;
    FKey = ch;
    FKeepDown = FALSE;
    FActive = FALSE;

    if (Text)
        FText = Text;

    FStartX = xstart;
    FStartY = ystart;

    UpdateKeys(Up, Down, Disable);
}

/*##########################################################################
#
#   Name       : TDisplayKeyControl::DeleteKeys
#
#   Purpose....: Delete key bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayKeyControl::DeleteKeys()
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
#   Name       : TDisplayKeyControl::UpdateKeys
#
#   Purpose....: Update key bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayKeyControl::UpdateKeys(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable)
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

    text = FText.GetData();

    if (strlen(text))
    {
    	Font.GetStringMetrics(text, &xsize, &ysize);

    	FUp->SetFont(&Font);

    	key_xsize = FUp->GetWidth();
	    key_ysize = FUp->GetHeight();

    	xstart = (key_xsize - xsize) / 2;
	    ystart = (key_ysize - ysize) / 2;

    	FUp->SetDrawColor(150, 150, 150);
	    FUp->SetLgopNone();
		FUp->DrawString(xstart, ystart, text);
		FUp->DrawString(xstart + 1, ystart, text);
		FUp->DrawString(xstart - 1, ystart, text);
		FUp->DrawString(xstart, ystart + 1, text);
		FUp->DrawString(xstart, ystart - 1, text);
		FUp->DrawString(xstart + 1, ystart + 1, text);
		FUp->DrawString(xstart - 1, ystart - 1, text);
		FUp->DrawString(xstart - 1, ystart + 1, text);
		FUp->DrawString(xstart + 1, ystart - 1, text);

		FUp->SetDrawColor(0, 0, 0);
		FUp->DrawString(xstart, ystart, text);

		FDown->SetFont(&Font);

		key_xsize = FDown->GetWidth();
		key_ysize = FDown->GetHeight();

		xstart = (key_xsize - xsize) / 2;
		ystart = (key_ysize - ysize) / 2;

		xstart += 4;
		ystart += 4;

		FDown->SetDrawColor(150, 150, 150);
		FDown->SetLgopNone();
		FDown->DrawString(xstart, ystart, text);
		FDown->DrawString(xstart + 1, ystart, text);
		FDown->DrawString(xstart - 1, ystart, text);
		FDown->DrawString(xstart, ystart + 1, text);
		FDown->DrawString(xstart, ystart - 1, text);
		FDown->DrawString(xstart + 1, ystart + 1, text);
		FDown->DrawString(xstart - 1, ystart - 1, text);
		FDown->DrawString(xstart - 1, ystart + 1, text);
		FDown->DrawString(xstart + 1, ystart - 1, text);

		FDown->SetDrawColor(0, 0, 0);
	    FDown->DrawString(xstart, ystart, text);
	}

    if (FUp || FDown || FDisabled)
    {
    	Resize(FSizeX, FSizeY);
	    Move(FStartX, FStartY);
	}
}

/*##########################################################################
#
#   Name       : TDisplayKeyControl::EnableKeepDown
#
#   Purpose....: Enable keep key down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayKeyControl::EnableKeepDown()
{
    FKeepDown = TRUE;
}

/*##########################################################################
#
#   Name       : TDisplayKeyControl::ChangeImage
#
#   Purpose....: Init key control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayKeyControl::ChangeImage(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable)
{
    UpdateKeys(Up, Down, Disable);
}

/*##########################################################################
#
#   Name       : TDisplayKeyControl::OnLeftUp
#
#   Purpose....: Handle left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisplayKeyControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
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
#   Name       : TDisplayKeyControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisplayKeyControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
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
#   Name       : TDisplayKeyControl::OnKeyPressed
#
#   Purpose....: Handle key pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisplayKeyControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
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
#   Name       : TDisplayKeyControl::OnKeyReleased
#
#   Purpose....: Handle key released
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisplayKeyControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
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
#   Name       : TDisplayKeyControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayKeyControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
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
