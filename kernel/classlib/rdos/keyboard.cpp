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
# keyboard.cpp
# Keyboard device class
#
########################################################################*/

#include <string.h>
#include "keyboard.h"

#include <rdos.h>

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TKeyboardDevice::TKeyboardDevice
#
#   Purpose....: Constructor for TKeyboardDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyboardDevice::TKeyboardDevice(TWait *Wait)
{
	Init(Wait);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::TKeyboardDevice
#
#   Purpose....: Constructor for TKeyboardDevice
#
#   In params..: IniSection to read parameters from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyboardDevice::TKeyboardDevice(const char *IniSection, TWait *Wait)
  : TWaitDevice(IniSection)
{
	Init(Wait);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Init
#
#   Purpose....: Init method for class
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::Init(TWait *Wait)
{
	OnKeyPress = 0;
	OnKeyRelease = 0;
	RdosAddWaitForKeyboard(RegisterWait(Wait), this);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::~TKeyboardDevice
#
#   Purpose....: Destructor for TKeyboardDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyboardDevice::~TKeyboardDevice()
{
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::DeviceName
#
#   Purpose....: Device name		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name, "KEYBOARD", MaxLen);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Clear
#
#   Purpose....: Clear
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::Clear()
{
	RdosClearKeyboard();
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::PeekEvent
#
#   Purpose....: Peek for pending events
#
#   In params.: *
#   Out params.: ExtKey		DOS compatible character & extended code
#				 KeyState	State of keyboard
#				 VirtualKey	Virtual key (same as M$ windows)
#				 ScanCode	Scan code from keyboard
#   Returns....: TRUE if data available
#
##########################################################################*/
int TKeyboardDevice::PeekEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode)
{
	return RdosPeekKeyEvent(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::ReadEvent
#
#   Purpose....: Read out pending event
#
#   In params.: *
#   Out params.: ExtKey		DOS compatible character & extended code
#				 KeyState	State of keyboard
#				 VirtualKey	Virtual key (same as M$ windows)
#				 ScanCode	Scan code from keyboard
#   Returns....: TRUE if data available
#
##########################################################################*/
int TKeyboardDevice::ReadEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode)
{
	return RdosReadKeyEvent(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::KeyPress
#
#   Purpose....: Called when key is pressed
#
#   In params..: ExtKey		DOS compatible character & extended code
#				 KeyState	State of keyboard
#				 VirtualKey	Virtual key (same as M$ windows)
#				 ScanCode	Scan code from keyboard
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::KeyPress(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	if (OnKeyPress)
		(*OnKeyPress)(this, ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::KeyRelease
#
#   Purpose....: Called when key is released
#
#   In params..: ExtKey		DOS compatible character & extended code
#				 KeyState	State of keyboard
#				 VirtualKey	Virtual key (same as M$ windows)
#				 ScanCode	Scan code from keyboard
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::KeyRelease(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	if (OnKeyRelease)
		(*OnKeyRelease)(this, ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::SignalNewData()
{
	int ExtKey;
	int KeyState;
	int VirtualKey;
	int ScanCode;

    if (OnKeyPress || OnKeyRelease)
    {
    	if (RdosReadKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode))
	    {
    		if (ExtKey & 0x8000)
	    		KeyRelease(ExtKey & 0x7FFF, KeyState, VirtualKey, ScanCode & 0x7F);
		    else
			    KeyPress(ExtKey & 0x7FFF, KeyState, VirtualKey, ScanCode & 0x7F);
    	}
    }
}
