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
# keyboard.h
# Keyboard device class
#
########################################################################*/

#ifndef _KEYBOARD_H
#define _KEYBOARD_H

#define KEY_NUM_ACTIVE		0x200
#define KEY_CAPS_ACTIVE		0x100
#define KEY_PRINT_PRESSED	0x20
#define KEY_SCROLL_PRESSED	0x10
#define KEY_PAUSE_PRESSED	0x8
#define KEY_CTRL_PRESSED	0x4
#define KEY_ALT_PRESSED		0x2
#define KEY_SHIFT_PRESSED	0x1

#include "waitdev.h"

class TKeyboardDevice : public TWaitDevice
{
public:
	TKeyboardDevice(TWait *Wait);
	TKeyboardDevice(const char *IniSection, TWait *Wait);
	virtual ~TKeyboardDevice();

	virtual void DeviceName(char *Name, int MaxLen) const;

	void Clear();
	int PeekEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode);
	int ReadEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode);

	void (*OnKeyPress)(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	void (*OnKeyRelease)(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	
protected:
	virtual void KeyPress(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual void KeyRelease(int ExtKey, int KeyState, int VirtualKey, int ScanCode);

	virtual void SignalNewData();

private:
    void Init(TWait *Wait);
};

#endif

