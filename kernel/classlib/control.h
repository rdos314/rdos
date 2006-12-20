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
# control.h
# Basic control class
#
########################################################################*/

#ifndef _CONTROL_H
#define _CONTROL_H

#include "control.h"
#include "graphdev.h"
#include "keyboard.h"
#include "mouse.h"

class TControlThread;

class TControl
{
friend class TControlThread;
public:
	TControl(TControlThread *dev, int xmin, int ymin, int width, int height);
    virtual ~TControl();

    void Show();
    void Hide();
    int IsVisible() const;

    void Enable();
    void Disable();
    int IsEnabled() const;

    void Redraw();

protected:
	 virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	virtual void OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual void OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
    virtual void OnMouseMove(int x, int y, int ButtonState, int KeyState);
	virtual void OnLeftUp(int x, int y, int ButtonState, int KeyState);
	virtual void OnLeftDown(int x, int y, int ButtonState, int KeyState);
	virtual void OnRightUp(int x, int y, int ButtonState, int KeyState);
	virtual void OnRightDown(int x, int y, int ButtonState, int KeyState);

private:
    int FXMin;
    int FYMin;
    int FWidth;
    int FHeight;

    int FEnabled;
    int FVisible;

    TControlThread *FDev;    
    TControl *FNext;    
};

class TControlThread : TThread
{
friend class TControl;
public:
	TControlThread(const char *name, TGraphicDevice *dev, TKeyboardDevice *keyboard, TMouseDevice *mouse);
    virtual ~TControlThread();

	void OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	void OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
    void OnMouseMove(int x, int y, int ButtonState, int KeyState);
	void OnLeftUp(int x, int y, int ButtonState, int KeyState);
    void OnLeftDown(int x, int y, int ButtonState, int KeyState);
	void OnRightUp(int x, int y, int ButtonState, int KeyState);
	void OnRightDown(int x, int y, int ButtonState, int KeyState);

protected:
    void Add(TControl *control);
    void Delete(TControl *control);
    void Redraw(TControl *control);
	virtual void Execute();

    TGraphicDevice *FGraphic;
    TKeyboardDevice *FKeyboard;
    TMouseDevice *FMouse; 

    TSection FListSection;       
    TSection FPaintSection;
    TControl *FControlList;
};

#endif
