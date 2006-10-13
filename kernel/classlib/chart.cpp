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
# chart.cpp
# Chart class
#
########################################################################*/

#include "chart.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TChartListNode::TChartListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartListNode::TChartListNode()
{
}

/*##########################################################################
#
#   Name       : TChartListNode::TChartListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartListNode::TChartListNode(TChartCoord *coord)
  : TListBaseNode(coord, sizeof(TChartCoord)
{
}

/*##########################################################################
#
#   Name       : TChartListNode::TChartListNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartListNode::TChartListNode(const TChartListNode &src)
  : TListBaseNode(src)
{
}

/*##########################################################################
#
#   Name       : TChartListNode::~TChartListNode
#
#   Purpose....: Destructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartListNode::~TChartListNode()
{
}

/*##########################################################################
#
#   Name       : TChartListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::Compare(const TChartListNode &n2) const
{
    long double d1, d2;
    TChartCoord *coord;

    coord = Get();
    d1 = coord->x;
    coord = n2.Get();
    d2 = coord->y;

    if (d1 < d2)
        return -1;
    else
    {
        if (d1 > d2)
            return 1;
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : TChartListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::Compare(const TListBaseNode &n2) const
{
    TChartListNode *p = (TChartListNode *)&n2;
    return Compare(*p);    
}

/*##########################################################################
#
#   Name       : TChartListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChartListNode::Load(const TChartListNode &src)
{
    FData->Load(*src.FData);
}

/*##########################################################################
#
#   Name       : TChartListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChartListNode::Load(const TListBaseNode &src)
{
	TChartListNode *p = (TChartListNode *)&src;
}

/*##########################################################################
#
#   Name       : TChartListNode::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TChartListNode &TChartListNode::operator=(const TChartListNode &src)
{
	Load(src);
	return *this;
}

/*##########################################################################
#
#   Name       : TChartListNode::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::operator==(const TChartListNode &ln) const
{
	if (Compare(ln) == 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartListNode::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::operator!=(const TChartListNode &ln) const
{
	if (Compare(ln) == 0)
		return FALSE;
	else
		return TRUE;
}

/*##########################################################################
#
#   Name       : TChartListNode::operator>
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::operator>(const TChartListNode &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartListNode::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::operator<(const TChartListNode &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartListNode::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::operator>=(const TChartListNode &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartListNode::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartListNode::operator<=(const TChartListNode &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChart::TChart
#
#   Purpose....: Constructor for TChart
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChart::TChart(TGraphicDevice *dev, TXAxis *x, TYAxis *y)
{
	FDev = dev;
	FXAxis = x;
	FYAxis = y;
	x->Define(dev);
	y->Define(dev);
	SetWindow(0, 0, 1, 1);
	FCurrValid = FALSE;
	FCurrX = 0.0;
	FCurrY = 0.0;
}

/*##########################################################################
#
#   Name       : TChart::~TChart
#
#   Purpose....: Destructor for TChart
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChart::~TChart()
{
}

/*##########################################################################
#
#   Name       : TChart::SetWindow
#
#   Purpose....: Set chart window
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::SetWindow(int xmin, int ymin, int xmax, int ymax)
{
	FXMin = xmin;
	FYMin = ymin;
	FXMax = xmax;
	FYMax = ymax;
	FXAxis->SetWindow(xmin, 0, xmax, 0);
	FYAxis->SetWindow(0, ymin, 0, ymax);
}

/*##########################################################################
#
#   Name       : TChart::SetColor
#
#   Purpose....: Set color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::SetColor(int r, int g, int b)
{
	FR = r;
	FG = g;
	FB = b;
}

/*##########################################################################
#
#   Name       : TChart::SetupForDraw
#
#   Purpose....: Prepare for drawing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::SetupForDraw()
{
	FDev->SetClipRect(FXMin, FYMin, FXMax, FYMax);
	FDev->SetLgopNone();
	FDev->SetDrawColor(FR, FG, FB);
}

/*##########################################################################
#
#   Name       : TChart::Plot
#
#   Purpose....: Plot a single pixel
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::Plot(long double x, long double y)
{
	int xpix, ypix;

	xpix = FXAxis->PhysToPixel(x);
	ypix = FYAxis->PhysToPixel(y);

	SetupForDraw();
	FDev->SetPixel(xpix, ypix);
	
	FCurrX = x;
	FCurrY = y;
	FCurrValid = TRUE;
}

/*##########################################################################
#
#   Name       : TChart::LineTo
#
#   Purpose....: Draw a line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::LineTo(long double x, long double y)
{
	int xpix1, ypix1;
	int xpix2, ypix2;

	if (!FCurrValid)
		Plot(x, y);
	else
	{
		xpix1 = FXAxis->PhysToPixel(FCurrX);
		ypix1 = FYAxis->PhysToPixel(FCurrY);

		xpix2 = FXAxis->PhysToPixel(x);
		ypix2 = FYAxis->PhysToPixel(y);

		SetupForDraw();
		FDev->DrawLine(xpix1, ypix1, xpix2, ypix2);
	
		FCurrX = x;
		FCurrY = y;
	}
}
