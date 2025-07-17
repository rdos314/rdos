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
