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
# fixedtxt.h
# Fixed text control class
#
########################################################################*/

#ifndef _FIXEDTEXT_H
#define _FIXEDTEXT_H

#include "bitdev.h"
#include "panel.h"
#include "str.h"
#include "ini.h"

struct TFixedTextChar
{
    char ForeColor;
    char BackColor;
    char ch;
};

struct TFixedTextDisp
{
    int Rows;
    TFixedTextChar **RowArr;
};

class TFixedTextControl : public TPanelControl
{
public:
    TFixedTextControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize, int fontid);
    TFixedTextControl(TControl *control, int xstart, int ystart, int xsize, int ysize, int fontid);
    TFixedTextControl(TControlThread *dev, int fontid);
    TFixedTextControl(TControl *control, int fontid);
    virtual ~TFixedTextControl();

    void SetSpace(int xspace, int yspace);

    void SetSize(int rows, int cols);
    int GetRowCount();
    int GetColCount();
    
    void SetChar(int Row, int Col, char ForeColor, char BackColor, char ch);
    int GetChar(int Row, int Col, char *ForeColor, char *BackColor, char *ch);

    void GetTextArea(int *x, int *y, int *width, int *height);
    
    static void ConvColor(char color, int *r, int *g, int *b);
    
protected:
    void ResetDisp();

    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);     

    TSection FSection;

    int FFixedFont;
    int FRows;
    int FCols;

    TFixedTextDisp *FDisp;
    TFont *FFont;

    int FFontHeight;
    int FCellWidth;
    int FCellHeight;

private:
    void Init();

    int FStartX;
    int FStartY;

};

#endif
