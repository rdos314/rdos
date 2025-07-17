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
# table.cpp
# Table control class
#
########################################################################*/

#include <string.h>

#include "table.h"

#define FALSE	0
#define TRUE	!FALSE

/*##########################################################################
#
#   Name       : TTablePanelColumnFactory::TTablePanelColumnFactory
#
#   Purpose....: Table panel column factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTablePanelColumnFactory::TTablePanelColumnFactory(TPanelFactory *factory, int width)
{
	FFactory = factory;
	FWidth = width;
}

/*##########################################################################
#
#   Name       : TTablePanelColumnFactory::~TTablePanelColumnFactory
#
#   Purpose....: Table panel column factory desctructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTablePanelColumnFactory::~TTablePanelColumnFactory()
{
}

/*##########################################################################
#
#   Name       : TTablePanelColumnFactory::GetWidth
#
#   Purpose....: Get control width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTablePanelColumnFactory::GetWidth()
{
	return FWidth;
}

/*##########################################################################
#
#   Name       : TTablePanelColumnFactory::Create
#
#   Purpose....: Create element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TTablePanelColumnFactory::Create(TTableControl *control, int xstart, int ystart, int height, int space)
{
	return FFactory->CreatePanel(control, xstart, ystart, FWidth + space, height);
}
/*##########################################################################
#
#   Name       : TTableLabelColumnFactory::TTableLabelColumnFactory
#
#   Purpose....: Table label column factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableLabelColumnFactory::TTableLabelColumnFactory(TLabelFactory *factory, int width)
{
	FFactory = factory;
	FWidth = width;
}

/*##########################################################################
#
#   Name       : TTableLabelColumnFactory::~TTableLabelColumnFactory
#
#   Purpose....: Table label column factory desctructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableLabelColumnFactory::~TTableLabelColumnFactory()
{
}

/*##########################################################################
#
#   Name       : TTableLabelColumnFactory::GetWidth
#
#   Purpose....: Get control width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableLabelColumnFactory::GetWidth()
{
	return FWidth;
}

/*##########################################################################
#
#   Name       : TTableLabelColumnFactory::Create
#
#   Purpose....: Create element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TTableLabelColumnFactory::Create(TTableControl *control, int xstart, int ystart, int height, int space)
{
	return FFactory->CreateLabel(control, xstart, ystart, FWidth + space, height);
}

/*##########################################################################
#
#   Name       : TTableRow::TTableRow
#
#   Purpose....: Table row constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableRow::TTableRow(TTableControl *Table, int Row, int StartX, int StartY, int MinHeight, int MaxHeight)
{
	int col;
	int space;

	FTable = Table;
	FRow = Row;

    if (Row == 0)
        space = 2 * FTable->FRowSpace;
    else
        space = FTable->FRowSpace;
    
    FMinHeight = MinHeight + space;
    FMaxHeight = MaxHeight + space;
    FSizeY = MinHeight + space;

    FStartY = StartY;
    
    for (col = 0; col < MAX_TABLE_COLUMNS; col++)
    {
        FStartX[col] = StartX;
        FSizeX[col] = 0;
		FPanelArr[col] = 0;
		FLabelArr[col] = 0;
	}

    FCount = 0;    
}
    
/*##########################################################################
#
#   Name       : TTableRow::~TTableRow
#
#   Purpose....: Table row destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableRow::~TTableRow()
{
    int col;

    for (col = 0; col < FCount; col++)
	{
		if (FLabelArr[col])
			delete FLabelArr[col];
		else
		{
			if (FPanelArr[col])
				delete FPanelArr[col];
		}
	}
}

/*##########################################################################
#
#   Name       : TTableRow::AddPanelColumn
#
#   Purpose....: Add panel column control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::AddPanelColumn(TTablePanelColumnFactory *fact)
{
	int col;
	int xstart;
	TPanelControl *control;
	int width = fact->GetWidth();
	int space;

	col = FCount;

    if (col)
    {
		xstart = FStartX[col - 1]  + FSizeX[col - 1];
        space = FTable->FColSpace;
	}
	else
	{
		xstart = FStartX[0];
	    space = 2 * FTable->FColSpace;
    }

    width += space;

	FStartX[col] = xstart;
	FSizeX[col] = width;

	control = fact->Create(FTable, xstart, FStartY, FSizeY, space);

    if (col == 0)
        control->SetLeftWidth(FTable->FColSpace);
    else
        control->SetLeftWidth(0);

    if (FRow == 0)
        control->SetUpperWidth(FTable->FRowSpace);
    else
        control->SetUpperWidth(0);

    control->SetLowerWidth(FTable->FRowSpace);
    control->SetRightWidth(FTable->FColSpace);
        	    
    if (FTable->FSpaceTransparent)
        control->SetBorderTransparent();
    else
        control->SetBorderColor(FTable->FSpaceR, FTable->FSpaceG, FTable->FSpaceB);

	FPanelArr[col] = control;
	FCount++;

	CheckHeight();
}

/*##########################################################################
#
#   Name       : TTableRow::AddLabelColumn
#
#   Purpose....: Add label column control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::AddLabelColumn(TTableLabelColumnFactory *fact)
{
	int col;
	int xstart;
	TLabelControl *control;
	int width = fact->GetWidth();
	int space;

	col = FCount;

    if (col)
    {
		xstart = FStartX[col - 1]  + FSizeX[col - 1];
        space = FTable->FColSpace;
	}
	else
	{
		xstart = FStartX[0];
	    space = 2 * FTable->FColSpace;
    }

    width += space;

	FStartX[col] = xstart;
	FSizeX[col] = width;

	control = fact->Create(FTable, xstart, FStartY, FSizeY, space);

    if (col == 0)
        control->SetLeftWidth(FTable->FColSpace);
    else
        control->SetLeftWidth(0);

    if (FRow == 0)
        control->SetUpperWidth(FTable->FRowSpace);
    else
        control->SetUpperWidth(0);

    control->SetLowerWidth(FTable->FRowSpace);
    control->SetRightWidth(FTable->FColSpace);
        	    
    if (FTable->FSpaceTransparent)
        control->SetBorderTransparent();
    else
        control->SetBorderColor(FTable->FSpaceR, FTable->FSpaceG, FTable->FSpaceB);
	
	FLabelArr[col] = control;
	FPanelArr[col] = control;
	FCount++;

	CheckHeight();
}

/*##########################################################################
#
#   Name       : TTableRow::GetColumns
#
#   Purpose....: Get column count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableRow::GetColumns()
{
    return FCount;
}
    
/*##########################################################################
#
#   Name       : TTableRow::GetPanelControl
#
#   Purpose....: Get panel column control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TTableRow::GetPanelControl(int column)
{
	if (column >= 0 && column < MAX_TABLE_COLUMNS)
		return FPanelArr[column];
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TTableRow::GetLabelControl
#
#   Purpose....: Get label column control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TTableRow::GetLabelControl(int column)
{
	if (column >= 0 && column < MAX_TABLE_COLUMNS)
		return FLabelArr[column];
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TTableRow::SetText
#
#   Purpose....: Set text for label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::SetText(int column, TString &Text)
{
	if (column >= 0 && column < MAX_TABLE_COLUMNS)
	    if (FLabelArr[column])
	        FLabelArr[column]->SetText(Text);
}

/*##########################################################################
#
#   Name       : TTableRow::SetText
#
#   Purpose....: Set text for label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::SetText(int column, const char *Text)
{
	if (column >= 0 && column < MAX_TABLE_COLUMNS)
	    if (FLabelArr[column])
	        FLabelArr[column]->SetText(Text);
}

/*##########################################################################
#
#   Name       : TTableRow::GetPos
#
#   Purpose....: Get start position of row
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::GetPos(int *x, int *y)
{
    *x = FStartX[0];
    *y = FStartY;
}
    
/*##########################################################################
#
#   Name       : TTableRow::GetSize
#
#   Purpose....: Get size of row
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::GetSize(int *x, int *y)
{
    if (FCount)
        *x = FStartX[FCount - 1] + FSizeX[FCount];
    else
        *x = 0;

    *y = FSizeY;
}
    
/*##########################################################################
#
#   Name       : TTableRow::CheckHeight
#
#   Purpose....: Check if current height is optimal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::CheckHeight()
{
    int col;
    int height;

    height = 0;

    for (col = 0; col < FCount; col++)
		if (FPanelArr[col]->GetMinHeight() > height)
			height = FPanelArr[col]->GetMinHeight();

	if (height < FMinHeight)
		height = FMinHeight;

	if (height > FMaxHeight)
		height = FMaxHeight;

	if (height != FSizeY)
		FTable->NotifyHeightChange(FRow, height);
}

/*##########################################################################
#
#   Name       : TTableControl::TTableControl
#
#   Purpose....: Table control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableControl::TTableControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(dev)
{
	Init();

    Resize(xsize, ysize);
	Move(xstart, ystart);
}
    
/*##########################################################################
#
#   Name       : TTableControl::TTableControl
#
#   Purpose....: Table control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableControl::TTableControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(control)
{
	Init();

    Resize(xsize, ysize);
	Move(xstart, ystart);
}
    
/*##########################################################################
#
#   Name       : TTableControl::~TTableControl
#
#   Purpose....: Table control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableControl::~TTableControl()
{
    int i;
    
	for (i = 0; i < FColFactCount; i++)
	{
		if (FLabelColFactArr[i])
			delete FLabelColFactArr[i];
		else
		{
			if (FPanelColFactArr[i])
				delete FPanelColFactArr[i];
		}
	}

	for (i = 0; i < FRowCount; i++)
		if (FRowArr[i])
			delete FRowArr[i];

	if (FRowArr)
		delete FRowArr;
}

/*##########################################################################
#
#   Name       : TTableControl::Init
#
#   Purpose....: Table control init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::Init()
{
    FColFactCount = 0;

    FRowCount = 0;
    FRowSize = 0;
    FRowArr = 0;

    FRowSpace = 2;
    FColSpace = 2;

    FSpaceR = 0;
    FSpaceG = 0;
    FSpaceB = 0;
    FSpaceTransparent = FALSE;

    ControlType += TString(".TABLE");
}
    
/*##########################################################################
#
#   Name       : TTableControl::IsTableControl
#
#   Purpose....: Check if control is a table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableControl::IsTableControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".TABLE"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TTableControl::AddPanelColumn
#
#   Purpose....: Add panel column to table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableControl::AddPanelColumn(TPanelFactory *factory, int width)
{
	int row;
	int col = FColFactCount;
	TTablePanelColumnFactory *fact;

	if (FColFactCount < MAX_TABLE_COLUMNS)
	{
		fact = new TTablePanelColumnFactory(factory, width);
		FPanelColFactArr[FColFactCount] = fact;
		FColFactCount++;

		for (row = 0; row < FRowCount; row++)
			FRowArr[row]->AddPanelColumn(fact);

		return col;
	}
	else
		return -1;
}

/*##########################################################################
#
#   Name       : TTableControl::AddLabelColumn
#
#   Purpose....: Add label column to table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableControl::AddLabelColumn(TLabelFactory *factory, int width)
{
	int row;
	int col = FColFactCount;
	TTableLabelColumnFactory *fact;

	if (FColFactCount < MAX_TABLE_COLUMNS)
	{
		fact = new TTableLabelColumnFactory(factory, width);
		FLabelColFactArr[FColFactCount] = fact;
		
		FColFactCount++;

		for (row = 0; row < FRowCount; row++)
			FRowArr[row]->AddLabelColumn(fact);

		return col;
	}
	else
		return -1;
}

/*##########################################################################
#
#   Name       : TTableControl::Grow
#
#   Purpose....: Grow row array by 25%
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::Grow()
{
    int newsize;
    TTableRow **newarr;
    int i;

    newsize = FRowSize + FRowSize / 4 + 1;
    newarr = new TTableRow *[newsize];

    for (i = 0; i < FRowCount; i++)
        newarr[i] = FRowArr[i];

    for (i = FRowCount; i < newsize; i++)
        newarr[i] = 0;

    if (FRowArr)
        delete FRowArr;

    FRowArr = newarr;
    FRowSize = newsize;
}
    
/*##########################################################################
#
#   Name       : TTableControl::AddRow
#
#   Purpose....: Add row to table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableControl::AddRow(int MinHeight, int MaxHeight)
{
    int startx, starty;
    int sizex, sizey;
    TTableRow *row;
    int ind;
    int col;
    
    if (FRowSize == FRowCount)
        Grow();

    if (FRowCount == 0)
    {
        startx = 0;
        starty = 0;
    }
    else
    {
        row = FRowArr[FRowCount - 1];
        row->GetPos(&startx, &starty);
        row->GetSize(&sizex, &sizey);

        starty += sizey;
    }        

    ind = FRowCount;

	row = new TTableRow(this, ind, startx, starty, MinHeight, MaxHeight);

    FRowArr[ind] = row;
    FRowCount++;

	for (col = 0; col < FColFactCount; col++)
	{
		if (FLabelColFactArr[col])
			row->AddLabelColumn(FLabelColFactArr[col]);
		else
		{
			if (FPanelColFactArr[col])
				row->AddPanelColumn(FPanelColFactArr[col]);
		}
	}

	return ind;
}
    
/*##########################################################################
#
#   Name       : TTableControl::NotifyHeightChange
#
#   Purpose....: Notify a needed change in height
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::NotifyHeightChange(int Row, int NewHeight)
{
}
    
/*##########################################################################
#
#   Name       : TTableControl::SetText
#
#   Purpose....: Set element text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::SetText(int row, int col, TString &Text)
{
    if (row >= 0 && row < FRowCount)
        FRowArr[row]->SetText(col, Text);
}
    
/*##########################################################################
#
#   Name       : TTableControl::SetText
#
#   Purpose....: Set element text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::SetText(int row, int col, const char *Text)
{
    if (row >= 0 && row < FRowCount)
        FRowArr[row]->SetText(col, Text);
}
    
/*##########################################################################
#
#   Name       : TTableControl::SetRowSpacing
#
#   Purpose....: Set spacing between rows
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::SetRowSpacing(int space)
{
    FRowSpace = space;
}
    
/*##########################################################################
#
#   Name       : TTableControl::SetColSpacing
#
#   Purpose....: Set spacing between columns
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::SetColSpacing(int space)
{
    FColSpace = space;
}
    
/*##########################################################################
#
#   Name       : TTableControl::SetSpacingColor
#
#   Purpose....: Set color of spacing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::SetSpacingColor(int r, int g, int b)
{
    FSpaceR = r;
    FSpaceG = g;
    FSpaceB = b;
    FSpaceTransparent = FALSE;
}
    
/*##########################################################################
#
#   Name       : TTableControl::SetSpacingTransparent
#
#   Purpose....: Set transparent spacing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableControl::SetSpacingTransparent()
{
    FSpaceTransparent = TRUE;
}
    
/*##########################################################################
#
#   Name       : TTableControl::GetPanelControl
#
#   Purpose....: Get panel control for element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TTableControl::GetPanelControl(int row, int col)
{
    if (row >= 0 && row < FRowCount)
        return FRowArr[row]->GetPanelControl(col);
    else
        return 0;
}
    
/*##########################################################################
#
#   Name       : TTableControl::GetLabelControl
#
#   Purpose....: Get label control for element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TTableControl::GetLabelControl(int row, int col)
{
    if (row >= 0 && row < FRowCount)
        return FRowArr[row]->GetLabelControl(col);
    else
        return 0;
}
