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
# mouse.h
# Mouse device class
#
########################################################################*/

#ifndef _MOUSE_H
#define _MOUSE_H

#include "waitdev.h"

#define MOUSE_LEFT_BUTTON	1
#define MOUSE_RIGHT_BUTTON	2

class TMouseDevice : public TWaitDevice
{
public:
	TMouseDevice();
	TMouseDevice(const char *IniSection);
	virtual ~TMouseDevice();

	virtual void DeviceName(char *Name, int MaxLen) const;

	void SetWindow(int StartX, int StartY, int EndX, int EndY);
	void SetMickey(int xdir, int ydir);
	void SetPosition(int x, int y);
	void GetPosition(int *x, int *y);
	int IsLeftButtonPressed();
	int IsRightButtonPressed();
	void GetLeftButtonPressPosition(int *x, int *y);
	void GetLeftButtonReleasePosition(int *x, int *y);
	void GetRightButtonPressPosition(int *x, int *y);
	void GetRightButtonReleasePosition(int *x, int *y);

	void (*OnMove)(TMouseDevice *Mouse, int x, int y, int ButtonState, int KeyState);
	void (*OnLeftUp)(TMouseDevice *Mouse, int x, int y, int ButtonState, int KeyState);
	void (*OnLeftDown)(TMouseDevice *Mouse, int x, int y, int ButtonState, int KeyState);
	void (*OnRightUp)(TMouseDevice *Mouse, int x, int y, int ButtonState, int KeyState);
	void (*OnRightDown)(TMouseDevice *Mouse, int x, int y, int ButtonState, int KeyState);
	
protected:
	virtual void Move(int x, int y, int ButtonState, int KeyState);
	virtual void LeftDown(int x, int y, int ButtonState, int KeyState);
	virtual void LeftUp(int x, int y, int ButtonState, int KeyState);
	virtual void RightDown(int x, int y, int ButtonState, int KeyState);
	virtual void RightUp(int x, int y, int ButtonState, int KeyState);

	virtual void SignalNewData();
	virtual void Add(TWait *Wait);

private:
    void Init();

	int FState;
};

#endif
