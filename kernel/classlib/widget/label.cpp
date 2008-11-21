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

#define HOR_LEFT    0
#define HOR_CENTER  1
#define HOR_RIGHT   2

#define VER_TOP     0
#define VER_CENTER  1
#define VER_BOTTOM  2
    
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
    if (FOrgText)
        delete FOrgText;

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
    FOrgText = 0;
    FText = 0;
    FFont = 0;
    FBackground = 0;

    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;
    
    FStartX = 0;
    FStartY = 0;

    FUpperWidth = 0;
    FLowerWidth = 0;
    FLeftWidth = 0;
    FRightWidth = 0;

    FBackR = 255;
    FBackG = 255;
    FBackG = 255;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;

    FBorderR = 0;
    FBorderG = 0;
    FBorderB = 0;
    
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
#   Name       : TLabelControl::SetUpperWidth
#
#   Purpose....: Set upper border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetUpperWidth(int width)
{
    FUpperWidth = width;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetLowerWidth
#
#   Purpose....: Set lower border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetLowerWidth(int width)
{
    FLowerWidth = width;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetLeftWidth
#
#   Purpose....: Set left border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetLeftWidth(int width)
{
    FLeftWidth = width;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetRightWidth
#
#   Purpose....: Set right border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetRightWidth(int width)
{
    FRightWidth = width;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetBorderColor
#
#   Purpose....: Set border color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetBorderColor(int r, int g, int b)
{
    FBorderR = r;
    FBorderG = g;
    FBorderB = b;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignTopLeft
#
#   Purpose....: Align text top, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignTopLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignTop
#
#   Purpose....: Align text top, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignTop()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignTopRight
#
#   Purpose....: Align text top, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignTopRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignLeft
#
#   Purpose....: Align text center, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignCenter
#
#   Purpose....: Align text center, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignCenter()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignRight
#
#   Purpose....: Align text center, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignBottomLeft
#
#   Purpose....: Align text bottom, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignBottomLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignBottom
#
#   Purpose....: Align text bottom, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignBottom()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignBottomRight
#
#   Purpose....: Align text bottom, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignBottomRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_BOTTOM;
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

    if (FOrgText && len > 0)
        if (!strcmp(Text, FOrgText))
            return;

    for (row = 0; row < MAX_LABEL_ROWS; row++)
        FTextRow[row] = 0;

    if (!FFont)
        SetFont(12);

    if (FText)
        delete FText;

    FText = new char[len + 1];
    strcpy(FText, Text);

    if (FOrgText)
        delete FOrgText;

    FOrgText = new char[len + 1];
    strcpy(FOrgText, Text);

    GetSize(&xsize, &ysize);

    xsize -= 2 * FStartX;
    xsize -= FLeftWidth;
    xsize -= FRightWidth;

    row = 0;
    start = FText;
    prev = 0;

    FTextRow[row] = start;
    ptr = start;

    while (*ptr != 0)
    {
        while (*ptr != 0 && *ptr != ' ' && *ptr != 0xd && *ptr != 0xa && *ptr != ' ')
            ptr++;

        switch (*ptr)
        {
            case 0xd:
                *ptr = 0;
                ptr++;

                if (*ptr == 0xa)
                    ptr++;

                if (row < MAX_LABEL_ROWS)
                    row++;

                while (*ptr == ' ' || *ptr == ' ')
                    ptr++;
                
                FTextRow[row] = ptr;
                start = ptr;
                prev = 0;
                break;

            case 0xa:
                *ptr = 0;
                ptr++;

                if (*ptr == 0xd)
                    ptr++;

                if (row < MAX_LABEL_ROWS)
                    row++;

                while (*ptr == ' ' || *ptr == ' ')
                    ptr++;
                
                FTextRow[row] = ptr;
                start = ptr;
                prev = 0;
                break;

            default:            
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

                        ptr = prev;
    
                        ptr++;
    
                        while (*ptr == ' ' || *ptr == ' ')
                            ptr++;
                                
                        FTextRow[row] = ptr;
                        start = ptr;
                        prev = 0;
                    }
                    else
                    {
                        if (row < MAX_LABEL_ROWS)
                            row++;
    
                        if (ch != 0)
                        {
                            ptr++;
    
                            while (*ptr == ' ' || *ptr == ' ')
                                ptr++;
                        }

                        FTextRow[row] = ptr;
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
                break;
        }
    }

    if (FTextRow[row])
		if (strlen(FTextRow[row]) == 0)
            FTextRow[row] = 0;

    Redraw();
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
	int xstart;
    int ystart;
    int xsize;
    int ysize;
    int i;
    int row;
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

		if (FOrgText)
        {

            FFont->GetStringMetrics("", &xsize, &ysize);

            for (row = 0; row < MAX_LABEL_ROWS; row++)
                if (FTextRow[row] == 0)
                    break;

            ysize = ysize * row;

            switch (FVerAlign)
            {
                case VER_TOP:
                    ystart = ymin + FStartY + FUpperWidth;
                    break;

                case VER_CENTER:
                    ystart = ymin + (height - ysize) / 2;
                    break;

                case VER_BOTTOM:
                    ystart = ymin + height - ysize - FStartY - FLowerWidth;
                    break;        
            }

            for (row = 0; row < MAX_LABEL_ROWS; row++)
            {
                if (FTextRow[row])
                {
              		FFont->GetStringMetrics(FTextRow[row], &xsize, &ysize);
    
    				switch (FHorAlign)
	    	        {
		    	        case HOR_LEFT:
    		    		    xstart = xmin + FStartX + FLeftWidth;
	    		    	    break;

        		       	case HOR_CENTER:
	        			    xstart = xmin + (width - xsize) / 2;
    	        			break;
    
	        	    	case HOR_RIGHT:
		        	    	xstart = xmin + width - xsize - FStartX - FRightWidth;
			        	    break;
                    }
        
                    dev->SetFont(FFont);
                    dev->SetDrawColor(FDrawR, FDrawG, FDrawB);
                    dev->DrawString(xstart, ystart, FTextRow[row]);
                }
                else
                    break;

                ystart += ysize;
            }
        }
    }

    TControl::Paint(dev, xmin, ymin, width, height);
}
