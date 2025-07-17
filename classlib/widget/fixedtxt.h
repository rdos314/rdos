/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
