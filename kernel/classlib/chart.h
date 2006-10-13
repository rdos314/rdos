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
# chart.h
# Chart class
#
########################################################################*/

#ifndef _CHART_H
#define _CHART_H

#include "xaxis.h"
#include "yaxis.h"
#include "listbase.h"

struct TChartCoord
{
    long double x;
    long double y;
};

class TChartListNode : public TListBaseNode
{
friend class TChart;
public:
	TChartListNode(TChartCoord *coord);
	TChartListNode(const TChartListNode &source);
	virtual ~TChartListNode();

    TChartCoord *Get();

	const TChartListNode &operator=(const TChartListNode &src);
	int operator==(const TChartListNode &dest) const;
	int operator!=(const TChartListNode &dest) const;
	int operator>(const TChartListNode &dest) const;
	int operator>=(const TChartListNode &dest) const;
	int operator<(const TChartListNode &dest) const;
	int operator<=(const TChartListNode &dest) const;

protected:
	virtual int Compare(const TChartListNode &n2) const;
	virtual int Compare(const TListBaseNode &n2) const;
	virtual void Load(const TChartListNode &src);
	virtual void Load(const TListBaseNode &src);
};

class TChart
{
public:
	TChart(TGraphicDevice *dev, TXAxis *x, TYAxis *y);
    virtual ~TChart();

    void SetWindow(int xmin, int ymin, int xmax, int ymax);
    void SetColor(int r, int g, int b);

    void Plot(long double x, long double y);
	void LineTo(long double x, long double y);

protected:
	void SetupForDraw();

	TGraphicDevice *FDev;
	TXAxis *FXAxis;
    TYAxis *FYAxis;
	int FR;
	int FG;
	int FB;
	int FXMin;
	int FYMin;
	int FXMax;
	int FYMax;
	int FCurrValid;
	long double FCurrX;
	long double FCurrY;

private:
};

#endif
