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
# keyboard.cpp
# Keyboard device class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "keyboard.h"

#include <rdos.h>

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
TKeyboardDevice::TKeyboardDevice()
 : TWaitDevice("Keyboard")
{
        Init();
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
#   Name       : TKeyboardDevice::Init
#
#   Purpose....: Init method for class
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::Init()
{
        OnKeyPress = 0;
        OnKeyRelease = 0;
        KeyPreview = 0;
        Open();
        Online();
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Add
#
#   Purpose....: Add this object to wait list
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::Add(TWait *Wait)
{
        RdosAddWaitForKeyboard(Wait->GetHandle(), (int)this);
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
#   Out params.: ExtKey         DOS compatible character & extended code
#                                KeyState       State of keyboard
#                                VirtualKey     Virtual key (same as M$ windows)
#                                ScanCode       Scan code from keyboard
#   Returns....: TRUE if data available
#
##########################################################################*/
bool TKeyboardDevice::PeekEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode)
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
#   Out params.: ExtKey         DOS compatible character & extended code
#                                KeyState       State of keyboard
#                                VirtualKey     Virtual key (same as M$ windows)
#                                ScanCode       Scan code from keyboard
#   Returns....: TRUE if data available
#
##########################################################################*/
bool TKeyboardDevice::ReadEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode)
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
bool TKeyboardDevice::IsStdKey(int ExtKey, int VirtualKey) const
{
    if (ExtKey & 0x8000)
        return false;

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
            return false;
    }
    return true;
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
bool TKeyboardDevice::Poll() const
{
    int ExtKey;
    int KeyState;
    int VirtualKey;
    int ScanCode;
    bool ok;

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
    bool ok;

    VirtualKey = 0;

    ok = false;

    while (!ok)
    {
        ok = RdosReadKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
        if (ok && !IsStdKey(ExtKey, VirtualKey))
            ok = false;
    }

    return VirtualKey;
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Peek
#
#   Purpose....: Peek pending key
#
#   In params.: *
#   Out params.: *
#   Returns....: Virtual key (alpha-num only)
#
##########################################################################*/
int TKeyboardDevice::Peek()
{
    int ExtKey;
    int KeyState;
    int VirtualKey;
    int ScanCode;
    bool ok;

    ok = RdosPeekKeyEvent(&ExtKey, &KeyState, &VirtualKey, &ScanCode);
    if (ok && !IsStdKey(ExtKey, VirtualKey))
        ok = false;

    if (!ok)
        VirtualKey = 0;

    return VirtualKey;
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::Put
#
#   Purpose....: Put a "standard key" in the buffer
#
#   In params.: Virtual key
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TKeyboardDevice::Put(int ch)
{
    int keycode = ch << 8;

    keycode = keycode & 0xFF00;

    RdosPutKeyboard(keycode, ch, ch);
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
bool TKeyboardDevice::IsPinPad()
{
    return false;
}

/*##########################################################################
#
#   Name       : TKeyboardDevice::KeyPress
#
#   Purpose....: Called when key is pressed
#
#   In params..: ExtKey         DOS compatible character & extended code
#                                KeyState       State of keyboard
#                                VirtualKey     Virtual key (same as M$ windows)
#                                ScanCode       Scan code from keyboard
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
#   In params..: ExtKey         DOS compatible character & extended code
#                                KeyState       State of keyboard
#                                VirtualKey     Virtual key (same as M$ windows)
#                                ScanCode       Scan code from keyboard
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
