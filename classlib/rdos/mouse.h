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
