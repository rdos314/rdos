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
# table.h
# Table control class
#
########################################################################*/

#ifndef _TABLECTL_H
#define _TABLECTL_H

#include "bitdev.h"
#include "panel.h"
#include "label.h"
#include "str.h"

#define MAX_TABLE_COLUMNS   256

class TTableControl;

class TTablePanelColumnFactory
{
public:
	TTablePanelColumnFactory(TPanelFactory *factory, int width);
	~TTablePanelColumnFactory();

	TPanelControl *Create(TTableControl *control, int xstart, int ystart, int height, int space);

	int GetWidth();

protected:
	TPanelFactory *FFactory;
	int FWidth;
};

class TTableLabelColumnFactory
{
public:
	TTableLabelColumnFactory(TLabelFactory *factory, int width);
	~TTableLabelColumnFactory();

    TLabelControl *Create(TTableControl *control, int xstart, int ystart, int height, int space);

    int GetWidth();
    
protected:
    TLabelFactory *FFactory;    
    int FWidth;
};

class TTableRow
{
friend class TTableControl;

public:
	TTableRow(TTableControl *Table, int Row, int StartX, int StartY, int MinHeight, int MaxHeight);
	~TTableRow();

	void AddPanelColumn(TTablePanelColumnFactory *fact);
	void AddLabelColumn(TTableLabelColumnFactory *fact);

	int GetColumns();

	TPanelControl *GetPanelControl(int Column);
	TLabelControl *GetLabelControl(int Column);

    void SetText(int col, TString &Text);
    void SetText(int col, const char *Text);

	void GetPos(int *x, int *y);
	void GetSize(int *x, int *y);

protected:
    void CheckHeight();
    void UpdateBorder(TPanelFactory *fact);

    TTableControl *FTable;
    int FRow;
    
    int FStartX[MAX_TABLE_COLUMNS];
    int FStartY;
    int FSizeX[MAX_TABLE_COLUMNS];
    int FSizeY;

    int FMinHeight;
    int FMaxHeight;

    int FCount;
	TPanelControl *FPanelArr[MAX_TABLE_COLUMNS];
	TLabelControl *FLabelArr[MAX_TABLE_COLUMNS];
};

class TTableControl : public TPanelControl
{
friend class TTableRow;
public:
    TTableControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TTableControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    virtual ~TTableControl();

	static int IsTableControl(TControl *control);

    int AddPanelColumn(TPanelFactory *factory, int width);
    int AddLabelColumn(TLabelFactory *factory, int width);
    
    int AddRow(int MinHeight, int MaxHeight);

    void SetText(int row, int col, TString &Text);
    void SetText(int row, int col, const char *Text);

    void SetRowSpacing(int space);
    void SetColSpacing(int space);

    void SetSpacingColor(int r, int g, int b);
    void SetSpacingTransparent();    

    TPanelControl *GetPanelControl(int row, int col);
    TLabelControl *GetLabelControl(int row, int col);

protected:
    void NotifyHeightChange(int row, int height);

private:
    void Init();
    void Grow();

    int FColFactCount;
	TTablePanelColumnFactory *FPanelColFactArr[MAX_TABLE_COLUMNS];
    TTableLabelColumnFactory *FLabelColFactArr[MAX_TABLE_COLUMNS];

    int FRowCount;
    int FRowSize;

    int FRowSpace;
    int FColSpace;

    int FSpaceR;
    int FSpaceG;
    int FSpaceB;
    int FSpaceTransparent;
    
    TTableRow **FRowArr;
};

#endif
