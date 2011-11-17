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
