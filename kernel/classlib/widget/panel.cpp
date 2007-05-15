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
    FBackR = 255;
    FBackG = 255;
    FBackG = 255;

    FBorderR = 200;
    FBorderG = 200;
    FBorderB = 200;

    FBorderWidth = 2;
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
    FBorderWidth = width;
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

    panel->SetBackColor(FBackR, FBackG, FBackB);
    panel->SetBorderColor(FBorderR, FBorderG, FBorderB);
    panel->SetBorderWidth(FBorderWidth);

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

    panel->SetBackColor(FBackR, FBackG, FBackB);
    panel->SetBorderColor(FBorderR, FBorderG, FBorderB);
    panel->SetBorderWidth(FBorderWidth);

    return panel;        
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
	 Init(xstart, ystart, xsize, ysize);
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
	 Init(xstart, ystart, xsize, ysize);
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
void TPanelControl::Init(int xstart, int ystart, int xsize, int ysize)
{
    FBackR = 255;
    FBackG = 255;
    FBackG = 255;

    FBorderR = 200;
    FBorderG = 200;
    FBorderB = 200;

    FBorderWidth = 2;
    FInnerWidth = FBorderWidth;

    Resize(xsize, ysize);
	Move(xstart, ystart);
	Show();
	Enable();
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
    FBorderWidth = width;
    FInnerWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelControl::GetBorderWidth
#
#   Purpose....: Get border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPanelControl::GetBorderWidth()
{
    return FInnerWidth;
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
    dev->SetDrawColor(FBackR, FBackG, FBackB);
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

	if (IsVisible())
	{
    	dev->SetLgopNone();
        dev->SetFilledStyle();

    	dev->SetDrawColor(FBackR, FBackG, FBackB);
    	dev->DrawRect(xmin + FBorderWidth, ymin + FBorderWidth, 
    	              xmax - FBorderWidth, ymax - FBorderWidth);

    	dev->SetDrawColor(FBorderR, FBorderG, FBorderB);

        for (i = 0; i < FBorderWidth; i++)
        {
        	dev->DrawLine(xmin + i, ymin + i, xmax - i, ymin + i);
        	dev->DrawLine(xmax - i, ymin + i, xmax - i, ymax - i);
        	dev->DrawLine(xmax - i, ymax - i, xmin + i, ymax - i);
			dev->DrawLine(xmin + i, ymax - i, xmin + i, ymin + i);
        }
    }

    TControl::Paint(dev, xmin, ymin, width, height);
}
