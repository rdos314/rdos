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
# mouse.cpp
# Mouse device class
#
########################################################################*/

#include <string.h>
#include "mouse.h"

#include <rdos.h>

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TMouseDevice::TMouseDevice
#
#   Purpose....: Constructor for TMouseDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMouseDevice::TMouseDevice()
{
	Init();
}

/*##########################################################################
#
#   Name       : TMouseDevice::TMouseDevice
#
#   Purpose....: Constructor for TMouseDevice
#
#   In params..: IniSection to read parameters from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMouseDevice::TMouseDevice(const char *IniSection)
  : TWaitDevice(IniSection)
{
	Init();
}

/*##########################################################################
#
#   Name       : TMouseDevice::~TMouseDevice
#
#   Purpose....: Destructor for TMouseDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMouseDevice::~TMouseDevice()
{
}

/*##########################################################################
#
#   Name       : TMouseDevice::Init
#
#   Purpose....: Init method for class
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::Init()
{
	OnMove = 0;
	OnLeftUp = 0;
	OnLeftDown = 0;
	OnRightUp = 0;
	OnRightDown = 0;
	FState = 0;
}

/*##########################################################################
#
#   Name       : TMouseDevice::Add
#
#   Purpose....: Add object to wait
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::Add(TWait *Wait)
{
	RdosAddWaitForMouse(Wait->GetHandle(), this);
}

/*##########################################################################
#
#   Name       : TMouseDevice::DeviceName
#
#   Purpose....: Device name		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name, "MOUSE", MaxLen);
}

/*##########################################################################
#
#   Name       : TMouseDevice::SetWindow
#
#   Purpose....: Set mouse window                      
#
#   In params..: StartX, StartY, EndX, EndY
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::SetWindow(int StartX, int StartY, int EndX, int EndY)
{
	RdosSetMouseWindow(StartX, StartY, EndX, EndY);
}

/*##########################################################################
#
#   Name       : TMouseDevice::SetMickey
#
#   Purpose....: Set number of mouse tics per position              
#
#   In params..: xdir, ydir
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::SetMickey(int xdir, int ydir)
{
	RdosSetMouseMickey(xdir, ydir);
}

/*##########################################################################
#
#   Name       : TMouseDevice::SetPosition
#
#   Purpose....: Set mouse position
#
#   In params..: x, y
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::SetPosition(int x, int y)
{
	RdosSetMousePosition(x, y);
}

/*##########################################################################
#
#   Name       : TMouseDevice::GetPosition
#
#   Purpose....: Get mouse position
#
#   In params..: *
#   Out params.: x, y
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::GetPosition(int *x, int *y)
{
	RdosGetMousePosition(x, y);
}

/*##########################################################################
#
#   Name       : TMouseDevice::IsLeftButtonPressed
#
#   Purpose....: Check if left button is pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if pressed
#
##########################################################################*/
int TMouseDevice::IsLeftButtonPressed()
{
	return RdosGetLeftButton();
}

/*##########################################################################
#
#   Name       : TMouseDevice::IsRightButtonPressed
#
#   Purpose....: Check if right button is pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if pressed
#
##########################################################################*/
int TMouseDevice::IsRightButtonPressed()
{
	return RdosGetRightButton();
}

/*##########################################################################
#
#   Name       : TMouseDevice::GetLeftButtonPressPosition
#
#   Purpose....: Get left button press position
#
#   In params..: *
#   Out params.: x, y
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::GetLeftButtonPressPosition(int *x, int *y)
{
	RdosGetLeftButtonPressPosition(x, y);
}

/*##########################################################################
#
#   Name       : TMouseDevice::GetLeftButtonReleasePosition
#
#   Purpose....: Get left button release position
#
#   In params..: *
#   Out params.: x, y
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::GetLeftButtonReleasePosition(int *x, int *y)
{
	RdosGetLeftButtonReleasePosition(x, y);
}

/*##########################################################################
#
#   Name       : TMouseDevice::GetRightButtonPressPosition
#
#   Purpose....: Get right button press position
#
#   In params..: *
#   Out params.: x, y
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::GetRightButtonPressPosition(int *x, int *y)
{
	RdosGetRightButtonPressPosition(x, y);
}

/*##########################################################################
#
#   Name       : TMouseDevice::GetRightButtonReleasePosition
#
#   Purpose....: Get right button release position
#
#   In params..: *
#   Out params.: x, y
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::GetRightButtonReleasePosition(int *x, int *y)
{
	RdosGetRightButtonReleasePosition(x, y);
}

/*##########################################################################
#
#   Name       : TMouseDevice::Move
#
#   Purpose....: Called when mouse has moved
#
#   In params..: x, y			Position
#				 ButtonState	State of mouse buttons
#				 KeyState		State of keyboard
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::Move(int x, int y, int ButtonState, int KeyState)
{
	if (OnMove)
		(*OnMove)(this, x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TMouseDevice::LeftUp
#
#   Purpose....: Called when left button is released
#
#   In params..: x, y			Position
#				 ButtonState	State of mouse buttons
#				 KeyState		State of keyboard
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::LeftUp(int x, int y, int ButtonState, int KeyState)
{
	if (OnLeftUp)
		(*OnLeftUp)(this, x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TMouseDevice::LeftDown
#
#   Purpose....: Called when left button is pressed
#
#   In params..: x, y			Position
#				 ButtonState	State of mouse buttons
#				 KeyState		State of keyboard
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::LeftDown(int x, int y, int ButtonState, int KeyState)
{
	if (OnLeftDown)
		(*OnLeftDown)(this, x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TMouseDevice::RightUp
#
#   Purpose....: Called when right button is released
#
#   In params..: x, y			Position
#				 ButtonState	State of mouse buttons
#				 KeyState		State of keyboard
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::RightUp(int x, int y, int ButtonState, int KeyState)
{
	if (OnRightUp)
		(*OnRightUp)(this, x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TMouseDevice::RightDown
#
#   Purpose....: Called when right button is pressed
#
#   In params..: x, y			Position
#				 ButtonState	State of mouse buttons
#				 KeyState		State of keyboard
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::RightDown(int x, int y, int ButtonState, int KeyState)
{
	if (OnRightDown)
		(*OnRightDown)(this, x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TMouseDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMouseDevice::SignalNewData()
{
	int MouseState;
	int Diff;
	int KeyState;
	int x, y;
	long msb, lsb;

	KeyState = RdosGetKeyboardState();
	
	MouseState = 0;
	if (RdosGetLeftButton())
		MouseState |= MOUSE_LEFT_BUTTON;

	if (RdosGetRightButton())
		MouseState |= MOUSE_RIGHT_BUTTON;

	Diff = MouseState ^ FState;
	if (Diff)
	{
		if (Diff & MOUSE_LEFT_BUTTON)
		{
			if (MouseState & MOUSE_LEFT_BUTTON)
			{		
				RdosGetLeftButtonPressPosition(&x, &y);
				LeftDown(x, y, MouseState, KeyState);
			}
			else
			{
				RdosGetLeftButtonReleasePosition(&x, &y);
				LeftUp(x, y, MouseState, KeyState);
			}
		}

		if (Diff & MOUSE_RIGHT_BUTTON)
		{
			if (MouseState & MOUSE_RIGHT_BUTTON)
			{
				RdosGetRightButtonPressPosition(&x, &y);
				RightDown(x, y, MouseState, KeyState);
			}
			else
			{
				RdosGetRightButtonReleasePosition(&x, &y);
				RightUp(x, y, MouseState, KeyState);
			}
		}
	}
	else
	{
		RdosGetMousePosition(&x, &y);
		Move(x, y, MouseState, KeyState);
	}
	FState = MouseState;
}
