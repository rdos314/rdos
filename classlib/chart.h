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

#define MAX_CURVES 256

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

    TChartCoord *Get() const;

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

class TChartList : public TListBase
{
public:
	TChartList();
	TChartList(const TChartList &source);
	virtual ~TChartList();

	int operator==(const TChartList &dest) const;
	int operator!=(const TChartList &dest) const;
	int operator>(const TChartList &dest) const;
	int operator>=(const TChartList &dest) const;
	int operator<(const TChartList &dest) const;
	int operator<=(const TChartList &dest) const;
	TChartList &operator=(const TChartList &l);
	
	int Find(TChartCoord *coord);
	void AddFirst(TChartCoord *coord);
	void AddLast(TChartCoord *coord);
	void AddAt(int n, TChartCoord *coord);
    int Replace(int n, TChartCoord *coord);

    TChartCoord *Get();

protected:
	virtual TChartListNode *Clone(const TChartListNode *ln) const;
	virtual TListBaseNode *Clone(const TListBaseNode *ln) const;

};

class TChart
{
public:
	TChart(TGraphicDevice *dev, TXAxis *x, TYAxis *y);
    virtual ~TChart();

    void SetLineColor(int line, int r, int g, int b);

    void SetXAxis(long double xmin, long double xmax);
    void SetYAxis(long double ymin, long double ymax);

    void SetWindow(int xmin, int ymin, int xmax, int ymax);
    void SetBackColor(int r, int g, int b);

    void Add(int line, long double x, long double y);
    void Remove(int line);
    void Clear(int line); 
    void Clear();

    void GetXAxis(long double *xmin, long double *xmax);
    void GetYAxis(long double *ymin, long double *ymax);

    void Draw();

protected:
    int CalcLimits();

	TGraphicDevice *FDev;
	TXAxis *FXAxis;
    TYAxis *FYAxis;
    TChartList *FList[MAX_CURVES];
	int FR[MAX_CURVES];
	int FG[MAX_CURVES];
	int FB[MAX_CURVES];
	int FRBack;
	int FGBack;
	int FBBack;
	int FXMin;
	int FYMin;
	int FXMax;
	int FYMax;

	int FXAxisFixed;
	long double FXAxisMin;
	long double FXAxisMax;

	int FYAxisFixed;
	long double FYAxisMin;
	long double FYAxisMax;

	int FNewLimits;

private:
};

#endif
