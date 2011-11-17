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
