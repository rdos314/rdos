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
# panel.h
# Panel control class
#
########################################################################*/

#ifndef _PANELCTL_H
#define _PANELCTL_H

#include "bitdev.h"
#include "control.h"
#include "str.h"

class TPanelControl;

class TPanelFactory
{
public:
    TPanelFactory();
    ~TPanelFactory();

    void SetBackColor(int r, int g, int b);
    void SetBorderColor(int r, int g, int b);
    void SetBorderWidth(int width);

	TPanelControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
	TPanelControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);
	
protected:
    int FBackR;
    int FBackG;
    int FBackB;

    int FBorderR;
    int FBorderG;
    int FBorderB;

    int FBorderWidth;
};

class TPanelControl : public TControl
{
public:
    TPanelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TPanelControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    ~TPanelControl();

    void SetBackColor(int r, int g, int b);
    void SetBorderColor(int r, int g, int b);
    void SetBorderWidth(int width);
    int GetBorderWidth();

protected:
    void SetBackColor(TGraphicDevice *dev);

  	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height); 	

    int FInnerWidth;

private:
    void Init(int xstart, int ystart, int xsize, int ysize);

    int FBackR;
    int FBackG;
    int FBackB;

    int FBorderR;
    int FBorderG;
    int FBorderB;

    int FBorderWidth;
};        

#endif
