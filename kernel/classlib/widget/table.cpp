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
#   Name       : TTableColumnFactory::TTableColumnFactory
#
#   Purpose....: Table column factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableColumnFactory::TTableColumnFactory(TPanelFactory *factory, int width)
{
    FFactory = factory;
    FWidth = width;
}
    
/*##########################################################################
#
#   Name       : TTableColumnFactory::~TTableColumnFactory
#
#   Purpose....: Table column factory desctructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTableColumnFactory::~TTableColumnFactory()
{
}
    
/*##########################################################################
#
#   Name       : TTableColumnFactory::GetWidth
#
#   Purpose....: Get control width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableColumnFactory::GetWidth()
{
    return FWidth;
}
    
/*##########################################################################
#
#   Name       : TTableColumnFactory::Create
#
#   Purpose....: Create element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TTableColumnFactory::Create(TTableControl *control, int xstart, int ystart, int height)
{
    return FFactory->CreatePanel(control, xstart, ystart, FWidth, height);
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

	FTable = Table;
	FRow = Row;

	FStartY = StartY;
    
    FMinHeight = MinHeight;
    FMaxHeight = MaxHeight;
    FSizeY = MinHeight;

    for (col = 0; col < MAX_TABLE_COLUMNS; col++)
    {
        FStartX[col] = StartX;
        FSizeX[col] = 0;
        FArr[col] = 0;
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
        if (FArr[col])
            delete FArr[col];
}
    
/*##########################################################################
#
#   Name       : TTableRow::AddColumn
#
#   Purpose....: Add column control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTableRow::AddColumn(TTableColumnFactory *fact)
{
    int col;
    int xstart;
	TPanelControl *control;
    int width = fact->GetWidth();

    col = FCount;

    if (col)
        xstart = FStartX[col - 1]  + FSizeX[col - 1];
    else
        xstart = FStartX[0];

    FStartX[col] = xstart;
    FSizeX[col] = width;

    control = fact->Create(FTable, xstart, FStartY, FSizeY);        
    FArr[col] = control;
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
#   Name       : TTableRow::GetControl
#
#   Purpose....: Get column control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TTableRow::GetControl(int column)
{   
    if (column >= 0 && column < MAX_TABLE_COLUMNS)
        return FArr[column];
    else
        return 0;
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
        if (FArr[col]->GetMinHeight() > height)
            height = FArr[col]->GetMinHeight();
            
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
	Show();
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
	Show();
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
        if (FColFactArr[i])
            delete FColFactArr[i];

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
}
    
/*##########################################################################
#
#   Name       : TTableControl::AddColumn
#
#   Purpose....: Add column to table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTableControl::AddColumn(TPanelFactory *factory, int width)
{
    int row;
    int col = FColFactCount;
    TTableColumnFactory *fact;
    
    if (FColFactCount < MAX_TABLE_COLUMNS)
    {
        fact = new TTableColumnFactory(factory, width); 
        FColFactArr[FColFactCount] = fact;
        FColFactCount++;

        for (row = 0; row < FRowCount; row++)
            FRowArr[row]->AddColumn(fact);
        
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
		row->AddColumn(FColFactArr[col]);

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
