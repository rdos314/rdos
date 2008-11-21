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
# label.cpp
# Label control class
#
########################################################################*/

#include <string.h>

#include "label.h"

#define FALSE	0
#define TRUE	!FALSE
    
/*##########################################################################
#
#   Name       : TLabelControl::TLabelControl
#
#   Purpose....: Label control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::TLabelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TControl(dev)
{
	 Init(xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelControl::TLabelControl
#
#   Purpose....: Label control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::TLabelControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TControl(control)
{
	 Init(xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelControl::~TLabelControl
#
#   Purpose....: Panel control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::~TLabelControl()
{
    if (FText)
        delete FText;

    if (FFont)
        delete FFont;
}

/*##########################################################################
#
#   Name       : TLabelControl::Init
#
#   Purpose....: Init label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::Init(int xstart, int ystart, int xsize, int ysize)
{
    FText = 0;
    FFont = 0;
    FBackground = 0;

    FStartX = 0;
    FStartY = 0;

    FBackR = 255;
    FBackG = 255;
    FBackG = 255;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;
    
    Resize(xsize, ysize);
	Move(xstart, ystart);
	Show();
}

/*##########################################################################
#
#   Name       : TLabelControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetFont(int height)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(height);
}

/*##########################################################################
#
#   Name       : TLabelControl::SetBackground
#
#   Purpose....: Set background bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetBackground(TBitmapGraphicDevice *bitmap, int xstart, int ystart)
{
	FBackground = bitmap;
    FBitStartX = xstart;
    FBitStartY = ystart;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetBackColor
#
#   Purpose....: Set back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetBackColor(int r, int g, int b)
{
    FBackR = r;
    FBackG = g;
    FBackB = b;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetText
#
#   Purpose....: Set text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetText(const char *Text)
{
    int row;
    int len = strlen(Text);
    char *ptr;
    char *start;
    char *prev;
    char ch;
    int width;
    int height;
    int xsize;
    int ysize;

    if (FText)
        if (!strcmp(Text, FText))
            return;

    for (row = 0; row < MAX_LABEL_ROWS; row++)
        FTextRow[row] = 0;

    if (!FFont)
        SetFont(12);

    if (FText)
        delete FText;

    FText = new char[len + 1];
    strcpy(FText, Text);

    GetSize(&xsize, &ysize);

    row = 0;
    start = FText;
    prev = 0;

    FTextRow[row] = start;
    ptr = start;

    while (*ptr != 0)
    {
        while (*ptr != 0 && *ptr != ' ' && *ptr != 0xd && *ptr != ' ')
            ptr++;

        if (*ptr == 0xd)
        {
            *ptr = 0;
            ptr++;

            if (*ptr == 0xa)
                ptr++;

            if (row < MAX_LABEL_ROWS)
                row++;
                
            FTextRow[row] = start;
            start = ptr;
            prev = 0;
        }
        else
        {
            ch = *ptr;
            *ptr = 0;

            FFont->GetStringMetrics(start, &width, &height);

            if (width > xsize)
            {
                if (prev)
                {
                    *ptr = ch;
                    *prev = 0;

                    if (row < MAX_LABEL_ROWS)
                        row++;
                
                    FTextRow[row] = start;
                    ptr = prev;
                    ptr++;
                    start = ptr;
                }
                else
                {
                    if (row < MAX_LABEL_ROWS)
                        row++;

                    FTextRow[row] = start;
                    ptr++;
                    start = ptr;
                }                     
            }
            else
            {
                prev = ptr;
                
                *ptr = ch;                
                while (*ptr == ' ' || *ptr == ' ')
                    ptr++;
            }                        
        }
    }
}

/*##########################################################################
#
#   Name       : TLabelControl::SetText
#
#   Purpose....: Set text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetText(TString &Text)
{
    SetText(Text.GetData());
}

/*##########################################################################
#
#   Name       : TLabelControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int i;
    int xmax = xmin + width - 1;
    int ymax = ymin + height - 1;

	if (IsVisible())
	{
    	dev->SetLgopNone();
        dev->SetFilledStyle();

        dev->SetClipRect(  xmin, ymin,
            			   xmax, ymax);

		if (FBackground)
			dev->Blit(FBackground, FBitStartX, FBitStartY, xmin, ymin, FBackground->GetWidth(), FBackground->GetHeight());
        else
        {
            dev->SetDrawColor(FBackR, FBackG, FBackB);
            dev->DrawRect(xmin, ymin, xmax, ymax);
        }
    }

    TControl::Paint(dev, xmin, ymin, width, height);
}
