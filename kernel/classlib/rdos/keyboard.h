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

#define VK_BACK           0x08
#define VK_TAB            0x09
#define VK_CLEAR          0x0C
#define VK_RETURN         0x0D
#define VK_SHIFT          0x10
#define VK_CONTROL        0x11
#define VK_MENU           0x12
#define VK_PAUSE          0x13
#define VK_CAPITAL        0x14
#define VK_ESCAPE         0x1B
#define VK_SPACE          0x20
#define VK_PRIOR          0x21
#define VK_NEXT           0x22
#define VK_END            0x23
#define VK_HOME           0x24
#define VK_LEFT           0x25
#define VK_UP             0x26
#define VK_RIGHT          0x27
#define VK_DOWN           0x28
#define VK_SELECT         0x29
#define VK_PRINT          0x2A
#define VK_EXECUTE        0x2B
#define VK_SNAPSHOT       0x2C
#define VK_INSERT         0x2D
#define VK_DELETE         0x2E
#define VK_HELP           0x2F
#define VK_0              '0'
#define VK_1              '1'
#define VK_2              '2'
#define VK_3              '3'
#define VK_4              '4
#define VK_5              '5'
#define VK_6              '6'
#define VK_7              '7'
#define VK_8              '8'
#define VK_9              '9'
#define VK_A              'A'
#define VK_B              'B'
#define VK_C              'C'
#define VK_D              'D'
#define VK_E              'E'
#define VK_F              'F'
#define VK_G              'G'
#define VK_H              'H'
#define VK_I              'I'
#define VK_J              'J'
#define VK_K              'K'
#define VK_L              'L'
#define VK_M              'M'
#define VK_N              'N'
#define VK_O              'O'
#define VK_P              'P'
#define VK_Q              'Q'
#define VK_R              'R'
#define VK_S              'S'
#define VK_T              'T'
#define VK_U              'U'
#define VK_V              'V'
#define VK_W              'W'
#define VK_X              'X'
#define VK_Y              'Y'
#define VK_Z              'Z
#define VK_LWIN           0x5B
#define VK_RWIN           0x5C
#define VK_APPS           0x5D
#define VK_NUMPAD0        0x60
#define VK_NUMPAD1        0x61
#define VK_NUMPAD2        0x62
#define VK_NUMPAD3        0x63
#define VK_NUMPAD4        0x64
#define VK_NUMPAD5        0x65
#define VK_NUMPAD6        0x66
#define VK_NUMPAD7        0x67
#define VK_NUMPAD8        0x68
#define VK_NUMPAD9        0x69
#define VK_MULTIPLY       0x6A
#define VK_ADD            0x6B
#define VK_SEPARATOR      0x6C
#define VK_SUBTRACT       0x6D
#define VK_DECIMAL        0x6E
#define VK_DIVIDE         0x6F
#define VK_F1             0x70
#define VK_F2             0x71
#define VK_F3             0x72
#define VK_F4             0x73
#define VK_F5             0x74
#define VK_F6             0x75
#define VK_F7             0x76
#define VK_F8             0x77
#define VK_F9             0x78
#define VK_F10            0x79
#define VK_F11            0x7A
#define VK_F12            0x7B
#define VK_F13            0x7C
#define VK_F14            0x7D
#define VK_F15            0x7E
#define VK_F16            0x7F
#define VK_F17            0x80
#define VK_F18            0x81
#define VK_F19            0x82
#define VK_F20            0x83
#define VK_F21            0x84
#define VK_F22            0x85
#define VK_F23            0x86
#define VK_F24            0x87
#define VK_NUMLOCK        0x90
#define VK_SCROLL         0x91
#define VK_LSHIFT         0xA0
#define VK_RSHIFT         0xA1
#define VK_LCONTROL       0xA2
#define VK_RCONTROL       0xA3
#define VK_LMENU          0xA4
#define VK_RMENU          0xA5

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

