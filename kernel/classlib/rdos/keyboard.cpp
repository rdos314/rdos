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
	KeyPreview = 0;
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
#   Name       : TKeyboardDevice::IsStdKey
#
#   Purpose....: Check if scan is std key (dos compatible)
#
#   In params.: *
#   Out params.:*
#   Returns....: TRUE if std key
#
##########################################################################*/
int TKeyboardDevice::IsStdKey(int ExtKey, int VirtualKey)
{
    if (ExtKey & 0x8000)
        return FALSE;

    switch (VirtualKey)
    {
        case VK_SHIFT:
        case VK_CONTROL:
        case VK_MENU:
        case VK_CAPITAL:
        case VK_LWIN:
        case VK_RWIN:
        case VK_LSHIFT:
        case VK_RSHIFT:
        case VK_LCONTROL:
        case VK_RCONTROL:
        case VK_LMENU:
        case VK_RMENU:
            return FALSE;
    }
    return TRUE;
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Poll
#
#   Purpose....: Poll for key
#
#   In params.: *
#   Out params.:*
#   Returns....: TRUE if data available
#
##########################################################################*/
int TKeyboardDevice::Poll()
{
    int ExtKey;
    int KeyState;
    int VirtualKey;
    int ScanCode;
	int ok;

	ok = RdosPeekKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);

	while (ok && !IsStdKey(ExtKey, VirtualKey))
	{
		RdosReadKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
		ok = RdosPeekKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
		while (ok && !IsStdKey(ExtKey, VirtualKey))
		{
			RdosReadKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
			ok = RdosPeekKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
		}
	}

	return ok;
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Get
#
#   Purpose....: Read out a "standard key" only
#
#   In params.: *
#   Out params.: *
#   Returns....: Virtual key (alpha-num only)
#
##########################################################################*/
int TKeyboardDevice::Get()
{
    int ExtKey;
    int KeyState;
    int VirtualKey;
    int ScanCode;
    int ok;

    VirtualKey = 0;

    ok = FALSE;

    while (!ok)
    {      
    	ok = RdosReadKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
    	if (ok && !IsStdKey(ExtKey, VirtualKey))
    	    ok = FALSE;
    }

    return VirtualKey;
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Put
#
#   Purpose....: Put a "standard key" in the buffer (not supported)
#
#   In params.: Virtual key
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::Put(int ch)
{
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::IsPinPad
#
#   Purpose....: Read out a "standard key" only
#
#   In params.: *
#   Out params.: *
#   Returns....: Virtual key (alpha-num only)
#
##########################################################################*/
int TKeyboardDevice::IsPinPad()
{
    return FALSE;
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


    if (KeyPreview)
    {
    	if (RdosPeekKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode))
    	{
    		if (IsStdKey(ExtKey, VirtualKey))
    		{
				if ((*KeyPreview)(this, VirtualKey))
            	    RdosReadKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
            }
            else
          	    RdosReadKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
        }     	    
    }
    
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
