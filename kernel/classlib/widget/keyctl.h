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
# keyctl.h
# Basic key control class
#
########################################################################*/

#ifndef _KEYCTL_H
#define _KEYCTL_H

#include "bitdev.h"
#include "control.h"
#include "str.h"

class TDisplayKeyControl : public TControl
{
public:
    TDisplayKeyControl(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, const char *Text, char ch, TControlThread *dev, int xstart, int ystart);
    TDisplayKeyControl(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, const char *Text, char ch, TControl *control, int xstart, int ystart);
    ~TDisplayKeyControl();

    void EnableKeepDown();
    void ChangeImage(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable);

	static TBitmapGraphicDevice *CreateButton(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right, const char *text, int shift);

protected:
	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
	virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);
	virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);

private:
    void Init(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, const char *Text, char ch, int xstart, int ystart);
    void DeleteKeys();
    void UpdateKeys(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable);

	char FKey;
    TBitmapGraphicDevice *FUp;
    TBitmapGraphicDevice *FDown;	
    TBitmapGraphicDevice *FDisabled;	
    TString FText;
    int FPressed;
    int FStartX;
    int FStartY;
    int FSizeX;
    int FSizeY;
    int FKeepDown;
    int FActive;
};        

#endif
