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

#define FALSE   0
#define TRUE    !FALSE

#define HOR_LEFT    0
#define HOR_CENTER  1
#define HOR_RIGHT   2

#define VER_TOP     0
#define VER_CENTER  1
#define VER_BOTTOM  2

/*##########################################################################
#
#   Name       : TLabelFactory::TLabelFactory
#
#   Purpose....: Button factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelFactory::TLabelFactory()
{
    FFont = 0;

    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;
}

/*##########################################################################
#
#   Name       : TLabelFactory::~TLabelFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelFactory::~TLabelFactory()
{
    if (FFont)
        delete FFont;
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetFont(int height)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(height);
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignTopLeft
#
#   Purpose....: Align text top, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignTopLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignTop
#
#   Purpose....: Align text top, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignTop()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignTopRight
#
#   Purpose....: Align text top, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignTopRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignLeft
#
#   Purpose....: Align text center, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignCenter
#
#   Purpose....: Align text center, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignCenter()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignRight
#
#   Purpose....: Align text center, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignBottomLeft
#
#   Purpose....: Align text bottom, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignBottomLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignBottom
#
#   Purpose....: Align text bottom, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignBottom()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignBottomRight
#
#   Purpose....: Align text bottom, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignBottomRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetDefault
#
#   Purpose....: Set default panel properties from factory settings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetDefault(TLabelControl *label, int xstart, int ystart, int xsize, int ysize)
{
    switch (FVerAlign)
    {
        case VER_TOP:
            switch (FHorAlign)
            {
                case HOR_LEFT:
                    label->AlignTopLeft();
                    break;

                case HOR_CENTER:
                    label->AlignTop();
                    break;

                case HOR_RIGHT:
                    label->AlignTopRight();
                    break;
            }
            break;

        case VER_CENTER:
            switch (FHorAlign)
            {
                case HOR_LEFT:
                    label->AlignLeft();
                    break;

                case HOR_CENTER:
                    label->AlignCenter();
                    break;

                case HOR_RIGHT:
                    label->AlignRight();
                    break;
            }
            break;

        case VER_BOTTOM:
            switch (FHorAlign)
            {
                case HOR_LEFT:
                    label->AlignBottomLeft();
                    break;

                case HOR_CENTER:
                    label->AlignBottom();
                    break;

                case HOR_RIGHT:
                    label->AlignBottomRight();
                    break;
            }
            break;
    }

    if (FFont)
        label->SetFont(FFont);
        
    label->SetSpace(FStartX, FStartY);
    label->SetDrawColor(FDrawR, FDrawG, FDrawB);            

    TPanelFactory::SetDefault(label, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::Create
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    TLabelControl *label;

    label = new TLabelControl(dev, xstart, ystart, xsize, ysize);

    SetDefault(label, xstart, ystart, xsize, ysize);

    return label;        
}

/*##########################################################################
#
#   Name       : TLabelFactory::Create
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::Create(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    TLabelControl *label;

    label = new TLabelControl(control, xstart, ystart, xsize, ysize);

    SetDefault(label, xstart, ystart, xsize, ysize);

    return label;        
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TLabelFactory::CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TLabelFactory::CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreateLabel
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::CreateLabel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreateLabel
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::CreateLabel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
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
TLabelControl::TLabelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(dev)
{
        Init();

    Resize(xsize, ysize);
        Move(xstart, ystart);
        Show();
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
 : TPanelControl(control)
{
        Init();

    Resize(xsize, ysize);
        Move(xstart, ystart);
        Show();
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
TLabelControl::TLabelControl(TControlThread *dev)
 : TPanelControl(dev)
{
        Init();
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
TLabelControl::TLabelControl(TControl *control)
 : TPanelControl(control)
{
        Init();
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
void TLabelControl::Init()
{
    FOrgText = 0;
    FText = 0;
    FFont = 0;

    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;
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
#   Name       : TLabelControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetFont(TFont *font)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(*font);
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
    int xoffs, yoffs;
    int xdiff, ydiff;

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
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    xsize -= 2 * FStartX;
    xsize -= xdiff;

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

    Redraw(1);
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
#   Name       : TLabelControl::GetMinHeight
#
#   Purpose....: Get minimum height
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLabelControl::GetMinHeight()
{
    int xsize, ysize;
    int row;
    int height = TPanelControl::GetMinHeight();

    if (FFont)
        FFont->GetStringMetrics("", &xsize, &ysize);
    else
        ysize = 0;

    for (row = 0; row < MAX_LABEL_ROWS; row++)
        if (FTextRow[row] != 0)
            height += ysize;
        else
            break;

    return height;
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
    int xmax, ymax;
    int row;
    int xoffs, yoffs;
    int xdiff, ydiff;

    TPanelControl::Paint(dev, xmin, ymin, width, height);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    xmin += xoffs;
    ymin += yoffs;
    width -= xdiff;
    height -= ydiff;

    xmax = xmin + width - 1;
    ymax = ymin + height - 1;

        if (IsVisible() && width > 0 && height > 0)
        {
        dev->SetLgopNone();
        dev->SetFilledStyle();

        dev->SetClipRect(  xmin, ymin,
                                   xmax, ymax);

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
                    ystart = ymin + FStartY;
                    break;

                case VER_CENTER:
                    ystart = ymin + (height - ysize) / 2;
                    break;

                case VER_BOTTOM:
                    ystart = ymin + height - ysize - FStartY;
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
                                    xstart = xmin + FStartX;
                                    break;

                                case HOR_CENTER:
                                            xstart = xmin + (width - xsize) / 2;
                                        break;
    
                                case HOR_RIGHT:
                                        xstart = xmin + width - xsize - FStartX;
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

}
