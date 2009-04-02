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
# panel.cpp
# Graphics panel control class
#
########################################################################*/

#include <string.h>

#include "panel.h"

#define FALSE	0
#define TRUE	!FALSE

/*##########################################################################
#
#   Name       : TPanelFactory::TPanelFactory
#
#   Purpose....: Button factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelFactory::TPanelFactory()
{
    FBackground = 0;

    FBackR = 255;
    FBackG = 255;
    FBackB = 255;

    FBackTrans = FALSE;
    
    FBorderR = 0;
    FBorderG = 0;
    FBorderB = 0;

    FBorderTrans = FALSE;
    
    FDisabledColorUsed = FALSE;

    FUpperWidth = 2;
    FLowerWidth = 2;
    FLeftWidth = 2;
    FRightWidth = 2;
}

/*##########################################################################
#
#   Name       : TPanelFactory::~TPanelFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelFactory::~TPanelFactory()
{
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBackground
#
#   Purpose....: Set background bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBackground(TBitmapGraphicDevice *bitmap, int xstart, int ystart)
{
	FBackground = bitmap;
    FBitStartX = xstart;
    FBitStartY = ystart;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBackColor
#
#   Purpose....: Set back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBackColor(int r, int g, int b)
{
    FBackR = r;
    FBackG = g;
    FBackB = b;
    
    FBackTrans = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBackTransparent
#
#   Purpose....: Set back color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBackTransparent()
{
    FBackTrans = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetDisabledColor
#
#   Purpose....: Set disabled color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetDisabledColor(int r, int g, int b)
{
    FDisabledColorUsed = TRUE;
    
    FDisabledR = r;
    FDisabledG = g;
    FDisabledB = b;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetUpperWidth
#
#   Purpose....: Set upper border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetUpperWidth(int width)
{
    FUpperWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetLowerWidth
#
#   Purpose....: Set lower border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetLowerWidth(int width)
{
    FLowerWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetLeftWidth
#
#   Purpose....: Set left border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetLeftWidth(int width)
{
    FLeftWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetRightWidth
#
#   Purpose....: Set right border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetRightWidth(int width)
{
    FRightWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBorderWidth
#
#   Purpose....: Set border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBorderWidth(int width)
{
    FUpperWidth = width;
    FLowerWidth = width;
    FLeftWidth = width;
    FRightWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBorderColor
#
#   Purpose....: Set border color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBorderColor(int r, int g, int b)
{
    FBorderR = r;
    FBorderG = g;
    FBorderB = b;

    FBorderTrans = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBorderTransparent
#
#   Purpose....: Set border color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBorderTransparent()
{
	FBorderTrans = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetDefault
#
#   Purpose....: Set default panel properties from factory settings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetDefault(TPanelControl *panel, int xstart, int ystart, int xsize, int ysize)
{
    if (FBackground)
        panel->SetBackground(FBackground, FBitStartX + xstart, FBitStartY + ystart);

	if (FBackTrans)
		panel->SetBackTransparent();
	else
		panel->SetBackColor(FBackR, FBackG, FBackB);

	panel->SetUpperWidth(FUpperWidth);
	panel->SetLowerWidth(FLowerWidth);
	panel->SetLeftWidth(FLeftWidth);
	panel->SetRightWidth(FRightWidth);

	if (FBorderTrans)
        panel->SetBorderTransparent();
    else
        panel->SetBorderColor(FBorderR, FBorderG, FBorderB);

    if (FDisabledColorUsed)
        panel->SetDisabledColor(FDisabledR, FDisabledG, FDisabledB);
}

/*##########################################################################
#
#   Name       : TPanelFactory::Create
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    TPanelControl *panel;

    panel = new TPanelControl(dev, xstart, ystart, xsize, ysize);

    SetDefault(panel, xstart, ystart, xsize, ysize);

    return panel;        
}

/*##########################################################################
#
#   Name       : TPanelFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::Create(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    TPanelControl *panel;

    panel = new TPanelControl(control, xstart, ystart, xsize, ysize);

    SetDefault(panel, xstart, ystart, xsize, ysize);

    return panel;        
}

/*##########################################################################
#
#   Name       : TPanelFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TPanelFactory::CreatePanel
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}
    
/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControlThread *dev)
 : TControl(dev)
{
    Init(0);
}

/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControl *control)
 : TControl(control)
{
    Init(0);
}
    
/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TControl(dev)
{
    Init(2);

    Resize(xsize, ysize);
	Move(xstart, ystart);
//	Show();
	Enable();
}

/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TControl(control)
{
    Init(2);

    Resize(xsize, ysize);
	Move(xstart, ystart);
//	Show();
	Enable();
}

/*##########################################################################
#
#   Name       : TPanelControl::~TPanelControl
#
#   Purpose....: Panel control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::~TPanelControl()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::Init
#
#   Purpose....: Init Panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::Init(int border)
{
    FBackground = 0;

    FBackR = 255;
    FBackG = 255;
    FBackG = 255;

    FBackTrans = FALSE;

    FBorderR = 200;
    FBorderG = 200;
    FBorderB = 200;

    FBorderTrans = FALSE;

    FDisabledColorUsed = FALSE;

    FUpperWidth = border;
    FLowerWidth = border;
    FLeftWidth = border;
    FRightWidth = border;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackground
#
#   Purpose....: Set background bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackground(TBitmapGraphicDevice *bitmap, int xstart, int ystart)
{
	FBackground = bitmap;
    FBitStartX = xstart;
    FBitStartY = ystart;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackColor
#
#   Purpose....: Set back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackColor(int r, int g, int b)
{
    FBackR = r;
    FBackG = g;
    FBackB = b;

    FBackTrans = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackTransparent
#
#   Purpose....: Set back color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackTransparent()
{
    FBackTrans = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetDisabledColor
#
#   Purpose....: Set disabled color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetDisabledColor(int r, int g, int b)
{
    FDisabledColorUsed = TRUE;
    
    FDisabledR = r;
    FDisabledG = g;
    FDisabledB = b;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetUpperWidth
#
#   Purpose....: Set upper border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetUpperWidth(int width)
{
    FUpperWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetLowerWidth
#
#   Purpose....: Set lower border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetLowerWidth(int width)
{
    FLowerWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetLeftWidth
#
#   Purpose....: Set left border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetLeftWidth(int width)
{
    FLeftWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetRightWidth
#
#   Purpose....: Set right border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetRightWidth(int width)
{
    FRightWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBorderWidth
#
#   Purpose....: Set border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBorderWidth(int width)
{
    FUpperWidth = width;
    FLowerWidth = width;
    FLeftWidth = width;
    FRightWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBorderColor
#
#   Purpose....: Set border color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBorderColor(int r, int g, int b)
{
    FBorderR = r;
    FBorderG = g;
    FBorderB = b;

    FBorderTrans = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBorderTransparent
#
#   Purpose....: Set border color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBorderTransparent()
{
    FBorderTrans = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackColor
#
#   Purpose....: Set back color into device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackColor(TGraphicDevice *dev)
{
    if (IsEnabled())
        dev->SetDrawColor(FBackR, FBackG, FBackB);
    else
    {
        if (FDisabledColorUsed)
            dev->SetDrawColor(FDisabledR, FDisabledG, FDisabledB);
        else
           	dev->SetDrawColor(FBackR, FBackG, FBackB);
    }
}

/*##########################################################################
#
#   Name       : TPanelControl::GetMinHeight
#
#   Purpose....: Get minimum height
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPanelControl::GetMinHeight()
{
    return FUpperWidth + FLowerWidth;
}

/*##########################################################################
#
#   Name       : TPanelControl::GetInner
#
#   Purpose....: Get inner offsets
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::GetInner(int *xstart, int *ystart, int *xdiff, int *ydiff)
{
    *xstart = FLeftWidth;
    *ystart = FUpperWidth;
    *xdiff = FLeftWidth + FRightWidth;
    *ydiff = FUpperWidth + FLowerWidth;
}

/*##########################################################################
#
#   Name       : TPanelControl::UpdateChild
#
#   Purpose....: Update child control if needed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::UpdateChild(TControl *control, int level)
{
	if (FBackTrans && !FBackground && HasParent() && level == 1)
		RedrawParent();
	else
		TControl::UpdateChild(control, level);
}

/*##########################################################################
#
#   Name       : TPanelControl::RedrawChild
#
#   Purpose....: Redraw child control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::RedrawChild(TControl *control, int level)
{
	if (FBackTrans && !FBackground && HasParent() && level == 1)
		RedrawParent();
	else
		TControl::RedrawChild(control, level);
}

/*##########################################################################
#
#   Name       : TPanelControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int i;
    int xmax = xmin + width - 1;
    int ymax = ymin + height - 1;
    int ximin = xmin + FLeftWidth;
    int yimin = ymin + FUpperWidth;
    int ximax = xmax - FRightWidth;
    int yimax = ymax - FLowerWidth;

    TControl::Paint(dev, xmin, ymin, width, height);

	if (IsVisible())
	{
    	dev->SetLgopNone();
        dev->SetFilledStyle();

        dev->SetClipRect(  ximin, yimin,
            			   ximax, yimax);

        SetBackColor(dev);
        
		if (FBackground)
			dev->Blit(FBackground, FBitStartX, FBitStartY, ximin, yimin, FBackground->GetWidth(), FBackground->GetHeight());
        else
        {
            if (!FBackTrans)
                dev->DrawRect(ximin, yimin, ximax, yimax);
        }

        dev->SetClipRect(  xmin, ymin,
            			   xmax, ymax);

        if (!FBorderTrans)
        {
            if (FUpperWidth || FLowerWidth || FLeftWidth || FRightWidth)
            {
                dev->SetDrawColor(FBorderR, FBorderG, FBorderB);
                
                for (i = 0; i < FUpperWidth; i++)
                    dev->DrawLine(xmin, ymin + i, xmin + width - 1, ymin + i);
                
                for (i = 0; i < FLowerWidth; i++)
                    dev->DrawLine(xmin, ymin + height - i - 1, xmin + width, ymin + height - i - 1);

                for (i = 0; i < FLeftWidth; i++)
                    dev->DrawLine(xmin + i, ymin, xmin + i, ymin + height - 1);
                
                for (i = 0; i < FRightWidth; i++)
                    dev->DrawLine(xmin + width - i - 1, ymin, xmin + width - i - 1, ymin + height - 1);
            }
        } 
    }
}
