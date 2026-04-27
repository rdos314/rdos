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
 : TWaitDevice("Mouse")
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
        RdosAddWaitForMouse(Wait->GetHandle(), (int)this);
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
bool TMouseDevice::IsLeftButtonPressed()
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
bool TMouseDevice::IsRightButtonPressed()
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
#   In params..: x, y                   Position
#                                ButtonState    State of mouse buttons
#                                KeyState               State of keyboard
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
#   In params..: x, y                   Position
#                                ButtonState    State of mouse buttons
#                                KeyState               State of keyboard
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
#   In params..: x, y                   Position
#                                ButtonState    State of mouse buttons
#                                KeyState               State of keyboard
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
#   In params..: x, y                   Position
#                                ButtonState    State of mouse buttons
#                                KeyState               State of keyboard
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
#   In params..: x, y                   Position
#                                ButtonState    State of mouse buttons
#                                KeyState               State of keyboard
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
