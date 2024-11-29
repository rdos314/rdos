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
# fixedtxt.cpp
# Fixed text control class
#
########################################################################*/

#include <string.h>

#include "fixedtxt.h"

#define FALSE   0
#define TRUE    !FALSE
    
/*##########################################################################
#
#   Name       : TFixedTextControl::TFixedTextControl
#
#   Purpose....: Fixed text control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFixedTextControl::TFixedTextControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize, int fontid)
 : TPanelControl(dev),
   FSection("FixedText")
{
    FFixedFont = fontid;
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
    Show();
}

/*##########################################################################
#
#   Name       : TFixedTextControl::TFixedTextControl
#
#   Purpose....: Fixed text control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFixedTextControl::TFixedTextControl(TControl *control, int xstart, int ystart, int xsize, int ysize, int fontid)
 : TPanelControl(control),
   FSection("FixedText")
{
    FFixedFont = fontid;
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
    Show();
}
    
/*##########################################################################
#
#   Name       : TFixedTextControl::TFixedTextControl
#
#   Purpose....: Fixed text control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFixedTextControl::TFixedTextControl(TControlThread *dev, int fontid)
 : TPanelControl(dev),
   FSection("FixedText")
{
    FFixedFont = fontid;
    Init();
}

/*##########################################################################
#
#   Name       : TFixedTextControl::TFixedTextControl
#
#   Purpose....: Fixed text control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFixedTextControl::TFixedTextControl(TControl *control, int fontid)
 : TPanelControl(control),
   FSection("FixedText")
{
    FFixedFont = fontid;
    Init();
}

/*##########################################################################
#
#   Name       : TFixedTextControl::~TFixedTextControl
#
#   Purpose....: Panel control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFixedTextControl::~TFixedTextControl()
{
    ResetDisp();
}

/*##########################################################################
#
#   Name       : TFixedTextControl::Init
#
#   Purpose....: Init label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::Init()
{
    FDisp = 0;
    FRows = 0;
    FCols = 0;
    FFont = 0;
    FFontHeight = 0;
    FCellWidth = 0;
    FCellHeight = 0;

    ControlType += TString(".FIXEDTEXT");
}

/*##########################################################################
#
#   Name       : TFixedTextControl::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TFixedTextControl::ResetDisp
#
#   Purpose....: Reset display
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::ResetDisp()
{
    int row;

    if (FDisp)
    {
        for (row = 0; row < FDisp->Rows; row++)
            delete FDisp->RowArr[row];

        delete FDisp->RowArr;
        delete FDisp;
    }        
}

/*##########################################################################
#
#   Name       : TFixedTextControl::SetSize
#
#   Purpose....: Set row & col count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::SetSize(int rows, int cols)
{
    int row;
    int col;
    int height;
    int width;
    char str[2] = {' ', 0};

    if (FRows != rows || FCols != cols)
    {
        ResetDisp();

        FDisp = new TFixedTextDisp;
        FDisp->Rows = rows;
        FDisp->RowArr = new TFixedTextChar*[rows];

        for (row = 0; row < FDisp->Rows; row++)
        {
            FDisp->RowArr[row] = new TFixedTextChar[cols];

            for (col = 0; col < cols; col++)
            {
                FDisp->RowArr[row][col].ForeColor = 7;
                FDisp->RowArr[row][col].BackColor = 0;
                FDisp->RowArr[row][col].ch = ' ';
            }
        }

        FRows = rows;
        FCols = cols;

        height = GetHeight();
        FFontHeight = height / rows;

        if (FFont)
            delete FFont;

        FFont = new TFont(FFixedFont, FFontHeight);
        FFont->GetStringMetrics(str, &FCellWidth, &FCellHeight);

        width = GetWidth();
        while (FCellWidth * cols > width)
        {
            delete FFont;
            FFontHeight--;
            FFont = new TFont(FFixedFont, FFontHeight);
            FFont->GetStringMetrics(str, &FCellWidth, &FCellHeight);
        }
    }
}

/*##########################################################################
#
#   Name       : TFixedTextControl::SetRowCount
#
#   Purpose....: Get row count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFixedTextControl::GetRowCount()
{
    return FRows;
}

/*##########################################################################
#
#   Name       : TFixedTextControl::SetColCount
#
#   Purpose....: Get col count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFixedTextControl::GetColCount()
{
    return FCols;
}

/*##########################################################################
#
#   Name       : TFixedTextControl::SetChar
#
#   Purpose....: Set character
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::SetChar(int Row, int Col, char ForeColor, char BackColor, char ch)
{
    if (Row < FRows && Row >= 0 && Col < FCols && Col >= 0)
    {
        FDisp->RowArr[Row][Col].ForeColor = ForeColor;
        FDisp->RowArr[Row][Col].BackColor = BackColor;
        FDisp->RowArr[Row][Col].ch = ch;
    }
}

/*##########################################################################
#
#   Name       : TFixedTextControl::GetChar
#
#   Purpose....: Get character
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFixedTextControl::GetChar(int Row, int Col, char *ForeColor, char *BackColor, char *ch)
{
    if (Row < FRows && Row >= 0 && Col < FCols && Col >= 0)
    {
        *ForeColor = FDisp->RowArr[Row][Col].ForeColor;
        *BackColor = FDisp->RowArr[Row][Col].BackColor;
        *ch = FDisp->RowArr[Row][Col].ch;
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFixedTextControl::GetTextArea
#
#   Purpose....: Get text area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::GetTextArea(int *x, int *y, int *width, int *height)
{

    int xsize;
    int ysize;
    int xmin, ymin;
    int xmax, ymax;
    int xoffs, yoffs;
    int xdiff, ydiff;

    GetAbsPos(&xmin, &ymin);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    xmin += xoffs;
    ymin += yoffs;

    GetSize(&xsize, &ysize);

    xsize -= xdiff;
    ysize -= ydiff;

    xmax = xmin + xsize - 1;
    ymax = ymin + ysize - 1;

    xdiff = xmax - xmin + 1;
    ydiff = ymax - ymin + 1;

    xdiff = (xdiff - FCellWidth * FCols) / 2;
    ydiff = (ydiff - FFontHeight * FRows) / 2;

    xmin += xdiff;
    ymin += ydiff;

    *x = xmin;
    *y = ymin;
    *width = FCellWidth * FCols;
    *height = FFontHeight * FRows;
}

/*##########################################################################
#
#   Name       : TFixedTextControl::ConvColor
#
#   Purpose....: Convert CGA colors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::ConvColor(char color, int *r, int *g, int *b)
{
    switch (color)
    {
        case 0:
            *r = 0;
            *g = 0;
            *b = 0;
            break;

        case 1:
            *r = 0;
            *g = 0;
            *b = 0xA8;
            break;

        case 2:
            *r = 0;
            *g = 0xA8;
            *b = 0;
            break;

        case 3:
            *r = 0;
            *g = 0xA8;
            *b = 0xA8;
            break;

        case 4:
            *r = 0xA8;
            *g = 0;
            *b = 0;
            break;

        case 5:
            *r = 0xA8;
            *g = 0;
            *b = 0xA8;
            break;

        case 6:
            *r = 0xA8;
            *g = 0x54;
            *b = 0;
            break;

        case 7:
            *r = 0xA8;
            *g = 0xA8;
            *b = 0xA8;
            break;

        case 8:
            *r = 0x54;
            *g = 0x54;
            *b = 0x54;
            break;

        case 9:
            *r = 0x54;
            *g = 0x54;
            *b = 0xFE;
            break;

        case 10:
            *r = 0x54;
            *g = 0xFE;
            *b = 0x54;
            break;

        case 11:
            *r = 0x54;
            *g = 0xFE;
            *b = 0xFE;
            break;

        case 12:
            *r = 0xFE;
            *g = 0x54;
            *b = 0x54;
            break;

        case 13:
            *r = 0xFE;
            *g = 0x54;
            *b = 0xFE;
            break;

        case 14:
            *r = 0xFE;
            *g = 0xFE;
            *b = 0x54;
            break;

        case 15:
            *r = 0xFE;
            *g = 0xFE;
            *b = 0xFE;
            break;

        default:
            *r = 0;
            *g = 0;
            *b = 0;
            break;
    }
}

/*##########################################################################
#
#   Name       : TFixedTextControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFixedTextControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int xmax, ymax;
    int xoffs, yoffs;
    int xdiff, ydiff;
    int redraw;
    int row, col;
    int ForeR, ForeG, ForeB;
    int BackR, BackG, BackB;
    int x, y;
    char str[2];

    if (IsTransparent())
    {
        UpdateTransparent();
        RedrawBackground(dev);
    }

    FRedrawBack = TRUE;

    TPanelControl::Paint(dev, xmin, ymin, width, height);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    xmin += xoffs;
    ymin += yoffs;
    width -= xdiff;
    height -= ydiff;

    FSection.Enter();

    xmax = xmin + width - 1;
    ymax = ymin + height - 1;

    redraw = IsVisible();

    if (width == 0 || height == 0)
        redraw = FALSE;    
    
    if (redraw)
    {
        dev->SetLgopNone();
        dev->SetFilledStyle();
        dev->SetFont(FFont);

        SetClipRect(    dev,
                        xmin, ymin,
                        xmax, ymax);

        xdiff = xmax - xmin + 1;
        ydiff = ymax - ymin + 1;

        xdiff = (xdiff - FCellWidth * FCols) / 2;
        ydiff = (ydiff - FFontHeight * FRows) / 2;

        xmin += xdiff;
        ymin += ydiff;

        for (row = 0; row < FRows; row++)
        {
            for (col = 0; col < FCols; col++)
            {
                ConvColor(FDisp->RowArr[row][col].ForeColor, &ForeR, &ForeG, &ForeB);
                ConvColor(FDisp->RowArr[row][col].BackColor, &BackR, &BackG, &BackB);

                x = xmin + FCellWidth * col;
                y = ymin + FFontHeight * row;

                dev->SetDrawColor(BackR, BackG, BackB);
                dev->DrawRect(x, y, x + FCellWidth, y + FFontHeight);      

                dev->SetDrawColor(ForeR, ForeG, ForeB);
                str[0] = FDisp->RowArr[row][col].ch;
                str[1] = 0;
                dev->DrawString(x, y, str);
            }
        }
    }
    FSection.Leave();

}
