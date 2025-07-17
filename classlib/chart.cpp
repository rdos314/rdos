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
TChartListNode::TChartListNode(TChartCoord *coord)
  : TListBaseNode(coord, sizeof(TChartCoord))
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
#   Name       : TChartListNode::Get
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartCoord *TChartListNode::Get() const
{
    return (TChartCoord *)GetData();
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
#   Name       : TChartList::TChartList
#
#   Purpose....: Constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartList::TChartList()
{
}

/*##########################################################################
#
#   Name       : TChartList::TChartList
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartList::TChartList(const TChartList &src)
  : TListBase(src)
{
}

/*##########################################################################
#
#   Name       : TChartList::~TChartList
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartList::~TChartList()
{
}

/*##########################################################################
#
#   Name       : TChartList::operator==
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::operator==(const TChartList &l) const
{
    if (Compare(l) == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TChartList::operator!=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::operator!= (const TChartList &l) const
{
    if (Compare(l) != 0)
        return TRUE;
    else
        return FALSE;
}    

/*##########################################################################
#
#   Name       : TChartList::operator>
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::operator>(const TChartList &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartList::operator<
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::operator<(const TChartList &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartList::operator>=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::operator>=(const TChartList &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartList::operator<=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::operator<=(const TChartList &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TChartList::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartList &TChartList::operator=(const TChartList &src)
{
	Load(src);
	return *this;
}

/*##########################################################################
#
#   Name       : TChartList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartListNode *TChartList::Clone(const TChartListNode *ln) const
{
	return new TChartListNode(*ln);
}

/*##########################################################################
#
#   Name       : TChartList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode *TChartList::Clone(const TListBaseNode *ln) const
{
    TChartListNode *p = (TChartListNode *)ln;
	return new TChartListNode(*p);
}

/*##########################################################################
#
#   Name       : TChartList::Get
#
#   Purpose....: Get current entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TChartCoord *TChartList::Get()
{
    if (FCurrPos)
		return (TChartCoord *)FCurrPos->GetData();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TChartList::Find
#
#   Purpose....: Find specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::Find(TChartCoord *coord)
{
	TChartListNode n = TChartListNode(coord);
	return TListBase::Find(&n);
}

/*##########################################################################
#
#   Name       : TChartList::AddFirst
#
#   Purpose....: Add entry as first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChartList::AddFirst(TChartCoord *coord)
{
	TChartListNode *p = new TChartListNode(coord);
	TListBase::AddFirst(p);
}

/*##########################################################################
#
#   Name       : TChartList::AddLast
#
#   Purpose....: Add entry as last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChartList::AddLast(TChartCoord *coord)
{
	TChartListNode *p = new TChartListNode(coord);
	TListBase::AddLast(p);
}

/*##########################################################################
#
#   Name       : TChartList::AddAt
#
#   Purpose....: Add entry at specified position, if possible.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChartList::AddAt(int n, TChartCoord *coord)
{
	TChartListNode *p = new TChartListNode(coord);
	TListBase::AddAt(n, p);
}

/*##########################################################################
#
#   Name       : TChartList::Replace
#
#   Purpose....: Replace specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChartList::Replace(int pos, TChartCoord *coord)
{
	TChartListNode n = TChartListNode(coord);
	return TListBase::Replace(pos, &n);
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
    int i;

    for (i = 0; i < MAX_CURVES; i++)
    {
        FList[i] = 0;
    	FR[i] = 255;
	    FG[i] = 255;
    	FB[i] = 255;
    }
    
	FDev = dev;
	FXAxis = x;
	FYAxis = y;
	x->Define(dev);
	y->Define(dev);
	SetWindow(0, 0, dev->GetWidth(), dev->GetHeight());

	FRBack = 0;
	FGBack = 0;
	FBBack = 0;

	FXAxisFixed = FALSE;
	FYAxisFixed = FALSE;

	FNewLimits = TRUE;
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
    int i;

    for (i = 0; i < MAX_CURVES; i++)
        if (FList[i])
            delete FList[i];
}

/*##########################################################################
#
#   Name       : TChart::SetXAxis
#
#   Purpose....: Set fixed x-axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::SetXAxis(long double xmin, long double xmax)
{
	FNewLimits = TRUE;
    FXAxisFixed = TRUE;
    FXAxisMin = xmin;
    FXAxisMax = xmax;
}

/*##########################################################################
#
#   Name       : TChart::SetYAxis
#
#   Purpose....: Set fixed y-axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::SetYAxis(long double ymin, long double ymax)
{
	FNewLimits = TRUE;
    FYAxisFixed = TRUE;
    FYAxisMin = ymin;
    FYAxisMax = ymax;
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
#   Name       : TChart::SetLineColor
#
#   Purpose....: Set line-color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::SetLineColor(int line, int r, int g, int b)
{
    if (line >= 0 && line < MAX_CURVES)
    {
		FR[line] = r;
		FG[line] = g;
		FB[line] = b;

		if (!FList[line])
			FList[line] = new TChartList;

	 }
}

/*##########################################################################
#
#   Name       : TChart::SetBackColor
#
#   Purpose....: Set back-color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::SetBackColor(int r, int g, int b)
{
	FRBack = r;
	FGBack = g;
	FBBack = b;
}

/*##########################################################################
#
#   Name       : TChart::Add
#
#   Purpose....: Add point
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::Add(int line, long double x, long double y)
{
	TChartCoord coord;

	if (line >= 0 && line < MAX_CURVES)
	{
    	FNewLimits = TRUE;
    	
		coord.x = x;
		coord.y = y;

		if (!FList[line])
			FList[line] = new TChartList;

		FList[line]->AddLast(&coord);
	}
}

/*##########################################################################
#
#   Name       : TChart::Remove
#
#   Purpose....: Remove point
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::Remove(int line)
{
	if (line >= 0 && line < MAX_CURVES)
	{
        if (FList[line])
		{
            FNewLimits = TRUE;
			FList[line]->RemoveFirst();
		}
    }
}

/*##########################################################################
#
#   Name       : TChart::Clear
#
#   Purpose....: Clear
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::Clear(int line)
{
	if (line >= 0 && line < MAX_CURVES)
	{
        if (FList[line])
		{
        	FNewLimits = TRUE;
			FList[line]->Clear();
	    }
	}
}

/*##########################################################################
#
#   Name       : TChart::Clear
#
#   Purpose....: Clear
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::Clear()
{
    int i;

	FNewLimits = TRUE;

	for (i = 0; i < MAX_CURVES; i++)
        if (FList[i])
		    FList[i]->Clear();
}

/*##########################################################################
#
#   Name       : TChart::CalcLimits
#
#   Purpose....: Calculate limits
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TChart::CalcLimits()
{
    int i;
	TChartCoord *coord;
    int ok;
    
    if (FXAxisFixed && FYAxisFixed)
        return TRUE;

    if (!FNewLimits)
        return TRUE;

    ok = FALSE;

    for (i = 0; i < MAX_CURVES; i++)
    {
        if (FList[i])
        {        
            if (FList[i]->GotoFirst())
            {
                coord = FList[i]->Get();
                if (!ok)
                {
                    if (!FXAxisFixed)
                    {
                        FXAxisMin = coord->x;
                        FXAxisMax = coord->x;
                    }

                    if (!FYAxisFixed)
                    {
                        FYAxisMin = coord->y;
                        FYAxisMax = coord->y;
                    }
                    
                    ok = TRUE;
                }
                else
                {
                    if (!FXAxisFixed)
                    {
                        if (FXAxisMin > coord->x)
                            FXAxisMin = coord->x;
        
                        if (FXAxisMax < coord->x)
                            FXAxisMax = coord->x;
                    }

                    if (!FYAxisFixed)
                    {
                        if (FYAxisMin > coord->y)
                            FYAxisMin = coord->y;

                        if (FYAxisMax < coord->y)
                            FYAxisMax = coord->y;
                    }
                }
                    
                while (FList[i]->GotoNext())
                {
                    coord = FList[i]->Get();
                    if (coord)
                    {
                        if (!FXAxisFixed)
                        {
                            if (FXAxisMin > coord->x)
                                FXAxisMin = coord->x;

                            if (FXAxisMax < coord->x)
                                FXAxisMax = coord->x;
                        }

                        if (!FYAxisFixed)
                        {
                            if (FYAxisMin > coord->y)
                                FYAxisMin = coord->y;
    
                            if (FYAxisMax < coord->y)
                                FYAxisMax = coord->y;
                        }
                    }
                }
            }
        }
    }

    if (ok)
        FNewLimits = FALSE;

    return ok;
}

/*##########################################################################
#
#   Name       : TChart::GetXAxis
#
#   Purpose....: Get X-axis limits
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::GetXAxis(long double *xmin, long double *xmax)
{
    if (CalcLimits())
    {
        *xmin = FXAxisMin;
        *xmax = FXAxisMax;
    }
    else
    {
        *xmin = 0.0;
        *xmax = 0.0;
    }
}

/*##########################################################################
#
#   Name       : TChart::GetYAxis
#
#   Purpose....: Get Y-axis limits
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::GetYAxis(long double *ymin, long double *ymax)
{
    if (CalcLimits())
    {
        *ymin = FYAxisMin;
        *ymax = FYAxisMax;
    }
    else
    {
        *ymin = 0.0;
        *ymax = 0.0;
    }
}

/*##########################################################################
#
#   Name       : TChart::Draw
#
#   Purpose....: Draw chart
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TChart::Draw()
{
	TChartCoord *coord;
	int height;
    int width;
    int x;
    int y;
    int xprev;
    int yprev;
    int i;

    CalcLimits();

    FXAxis->SetMin(FXAxisMin);
    FXAxis->SetMax(FXAxisMax);
    FYAxis->SetMin(FYAxisMin);
    FYAxis->SetMax(FYAxisMax);

	height = FXAxis->RequiredHeight();  

    y = FYMax - height;
    if (y <= FYMin)
        return; 

    FYAxis->SetWindow(FXMin, FYMin, FXMin, y);

    width = FYAxis->RequiredWidth();

    x = FXMin + width;
    if (x >= FXMax)
        return;

	FDev->SetClipRect(FXMin, FYMin, FXMax, FYMax);
	FDev->SetLgopNone();
	FDev->SetDrawColor(FRBack, FGBack, FBBack);
	FDev->SetFilledStyle();
	FDev->DrawRect(FXMin, FYMin, FXMax, FYMax);

    FYAxis->SetWindow(FXMin, FYMin, x, y);
    FXAxis->SetWindow(x, y, FXMax, FYMax);

    FXAxis->SetAxisOffset(width);

	for (i = 0; i < MAX_CURVES; i++)
	{
	    if (FList[i])
	    {
            if (FList[i]->GotoFirst())
            {
            	FDev->SetDrawColor(FR[i], FG[i], FB[i]);
        
                coord = FList[i]->Get();

            	x = FXAxis->PhysToPixel(coord->x);
            	y = FYAxis->PhysToPixel(coord->y);

            	FDev->SetPixel(x, y);

            	xprev = x;
            	yprev = y;
	
                while (FList[i]->GotoNext())
                {
                    coord = FList[i]->Get();
                    if (coord)
                    {
                    	x = FXAxis->PhysToPixel(coord->x);
                    	y = FYAxis->PhysToPixel(coord->y);
                		FDev->DrawLine(xprev, yprev, x, y);
                    	xprev = x;
                    	yprev = y;
                    }
                }
            }
        }
    }

	FXAxis->Draw();
	FYAxis->Draw();
}
