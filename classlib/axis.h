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
# axis.h
# Axis base class
#
########################################################################*/

#ifndef _AXIS_H
#define _AXIS_H

#include "graphdev.h"

class TAxis
{
public:
	TAxis();
    virtual ~TAxis();

	virtual int IsXAxis();
	virtual int IsYAxis();

    int IsVisible() const;
	void Hide();
	void Show();

	void Define(TGraphicDevice *dev);
	void SetWindow(int xmin, int ymin, int xmax, int ymax);
	void Define(long double min, long double max);
	void SetMin(long double min);
	void SetMax(long double max);

	void SetBackColor(int r, int g, int b);
	void SetForeColor(int r, int g, int b);
	
	virtual long double PhysToLog(long double val) = 0;
	virtual long double LogToPhys(long double rel) = 0;

	virtual int LogToPixel(long double rel);
	virtual long double PixelToLog(int pixel);

	virtual int PhysToPixel(long double val);
	virtual long double PixelToPhys(int pixel);

	virtual void Draw();

protected:
    virtual void Format(char *str, long double val);
    
	virtual void Update();

	TGraphicDevice *FDev;
	int FXMin;
	int FXMax;
	int FYMin;
	int FYMax;
	long double FValMin;
	long double FValMax;
	int FVisible;

	int FRBack;
	int FGBack;
	int FBBack;

	int FRFore;
	int FGFore;
	int FBFore;

    int FDigits;
    int FDecimals;

private:
};

#endif
