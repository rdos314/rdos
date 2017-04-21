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
    int xoffs, yoffs;
    int xdiff, ydiff;
    int height;

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
                FDisp->RowArr[row][col].BackColor = 7;
                FDisp->RowArr[row][col].ch = ' ';
            }
        }

        FRows = rows;
        FCols = cols;

        GetInner(&xoffs, &yoffs, &xdiff, &ydiff);
        height = GetHeight();
        height -= ydiff;

        height = height / rows;

        if (FFont)
            delete FFont;

        FFont = new TFont(FFixedFont, height);

    }
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
    int xstart;
    int ystart;
    int xsize;
    int ysize;
    int xmax, ymax;
    int row;
    int xoffs, yoffs;
    int xdiff, ydiff;
    int redraw;

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

        SetClipRect(    dev,
                        xmin, ymin,
                        xmax, ymax);

    }
    FSection.Leave();

}
