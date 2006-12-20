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
# control.cpp
# Graphics control base class
#
########################################################################*/

#include "control.h"

#define     STACK_SIZE  0x1000

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : KeyPress
#
#   Purpose....: Key press callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void KeyPress(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControlThread *dev = (TControlThread *)Keyboard->Owner;

    dev->OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : KeyRelease
#
#   Purpose....: Key release callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControlThread *dev = (TControlThread *)Keyboard->Owner;

    dev->OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : MouseMove
#
#   Purpose....: Mouse move callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void MouseMove(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
    TControlThread *dev = (TControlThread *)Mouse->Owner;

    dev->OnMouseMove(x, y, MouseButton, KeyState);
}

/*##########################################################################
#
#   Name       : LeftUp
#
#   Purpose....: Left button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LeftUp(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
    TControlThread *dev = (TControlThread *)Mouse->Owner;

    dev->OnLeftUp(x, y, MouseButton, KeyState);
}

/*##########################################################################
#
#   Name       : LeftDown
#
#   Purpose....: Left button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LeftDown(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
    TControlThread *dev = (TControlThread *)Mouse->Owner;

    dev->OnLeftDown(x, y, MouseButton, KeyState);
}

/*##########################################################################
#
#   Name       : RightUp
#
#   Purpose....: Right button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RightUp(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
    TControlThread *dev = (TControlThread *)Mouse->Owner;

    dev->OnRightUp(x, y, MouseButton, KeyState);
}

/*##########################################################################
#
#   Name       : RightDown
#
#   Purpose....: Right button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RightDown(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
    TControlThread *dev = (TControlThread *)Mouse->Owner;

    dev->OnRightDown(x, y, MouseButton, KeyState);
}

/*##########################################################################
#
#   Name       : TControl::TControl
#
#   Purpose....: Control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControl::TControl(TControlThread *dev, int xmin, int ymin, int width, int height)
{
    FXMin = xmin;
    FYMin = ymin;
    FWidth = width;
    FHeight = height;

    FVisible = TRUE;
    FEnabled = TRUE;

    FDev = dev;
    FDev->Add(this);
}

/*##########################################################################
#
#   Name       : TControl::~TControl
#
#   Purpose....: Control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControl::~TControl()
{
    FDev->Delete(this);
}

/*##########################################################################
#
#   Name       : TControl::Show
#
#   Purpose....: Make control visible
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Show()
{
    FVisible = TRUE;
}

/*##########################################################################
#
#   Name       : TControl::Hide
#
#   Purpose....: Make control invisible
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Hide()
{
    FVisible = FALSE;
}

/*##########################################################################
#
#   Name       : TControl::IsVisible
#
#   Purpose....: Check if visible
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::IsVisible() const
{
    return FVisible;
}

/*##########################################################################
#
#   Name       : TControl::Enable
#
#   Purpose....: Enable control (make it process events)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Enable()
{
    FEnabled = TRUE;
}

/*##########################################################################
#
#   Name       : TControl::Disable
#
#   Purpose....: Disable control (make it ignore events)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Disable()
{
    FEnabled = FALSE;
}

/*##########################################################################
#
#   Name       : TControl::IsEnabled
#
#   Purpose....: Check if enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::IsEnabled() const
{
    return FEnabled;
}

/*##########################################################################
#
#   Name       : TControl::Redraw
#
#   Purpose....: Force redraw of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Redraw()
{
    FDev->Redraw(this);
}

/*##########################################################################
#
#   Name       : TControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
}

/*##########################################################################
#
#   Name       : TControl::OnKeyPressed
#
#   Purpose....: On key pressed event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
}

/*##########################################################################
#
#   Name       : TControl::OnKeyReleased
#
#   Purpose....: On key released event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
}

/*##########################################################################
#
#   Name       : TControl::OnMouseMove
#
#   Purpose....: On mouse move event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::OnMouseMove(int x, int y, int ButtonState, int KeyState)
{
}

/*##########################################################################
#
#   Name       : TControl::OnLeftUp
#
#   Purpose....: On left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
}

/*##########################################################################
#
#   Name       : TControl::OnLeftDown
#
#   Purpose....: On left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
}

/*##########################################################################
#
#   Name       : TControl::OnRightUp
#
#   Purpose....: On right button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::OnRightUp(int x, int y, int ButtonState, int KeyState)
{
}

/*##########################################################################
#
#   Name       : TControl::OnRightDown
#
#   Purpose....: On right button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::OnRightDown(int x, int y, int ButtonState, int KeyState)
{
}

/*##########################################################################
#
#   Name       : TControlThread::TControlThread
#
#   Purpose....: Constructor for control-thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControlThread::TControlThread(const char *name, TGraphicDevice *dev, TKeyboardDevice *keyboard, TMouseDevice *mouse)
  : TThread(name, STACK_SIZE)
{
    FGraphic = dev;
    FKeyboard = keyboard;
    FMouse = mouse;

    FControlList = 0;
}

/*##########################################################################
#
#   Name       : TControlThread::~TControlThread
#
#   Purpose....: Destructor for control-thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControlThread::~TControlThread()
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        FControlList = control->FNext;
        delete control;

        control = FControlList;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::Add
#
#   Purpose....: Add new control last into list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Add(TControl *control)
{
	TControl *curr;
    TControl *prev;

    control->FNext = 0;

    FListSection.Enter();
    
    prev = FControlList;

    if (prev)
    {
        curr = prev;
        while (curr)
        {
            prev = curr;
            curr = curr->FNext;
        }

        prev->FNext = control;
    }
    else
        FControlList = control;   

    FListSection.Leave();
}    

/*##########################################################################
#
#   Name       : TControlThread::Delete
#
#   Purpose....: Delete control from list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Delete(TControl *control)
{
    TControl *curr;
    TControl *prev;

    control->FNext = 0;

    FListSection.Enter();

    if (FControlList)
    {
        if (FControlList == control)
            FControlList = FControlList->FNext;
        else
        {
            prev = FControlList;
            curr = prev;
            
            while (curr && curr != control)
            {
                prev = curr;
                curr = curr->FNext;
            }

            if (curr == control)
                prev->FNext = curr->FNext;            
        }
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::Redraw
#
#   Purpose....: Redraw control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Redraw(TControl *control)
{
    FPaintSection.Enter();
    control->Paint(FGraphic, control->FXMin, control->FYMin, control->FWidth, control->FHeight);
    FPaintSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::OnKeyPressed
#
#   Purpose....: Key pressed callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            control->OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);

        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::OnKeyReleased
#
#   Purpose....: Key released callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            control->OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode);

        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::OnMouseMove
#
#   Purpose....: Mouse move callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::OnMouseMove(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            control->OnMouseMove(x, y, ButtonState, KeyState);

        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::OnLeftDown
#
#   Purpose....: Left button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
        {
            if (control->FXMin <= x && control->FXMin + control->FWidth > x &&
                control->FYMin <= y && control->FYMin + control->FHeight > y)
            {
                control->OnLeftDown(x, y, ButtonState, KeyState);
                break;
            }
        }
        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::OnLeftUp
#
#   Purpose....: Left button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            control->OnLeftUp(x, y, ButtonState, KeyState);
            
        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::OnRightDown
#
#   Purpose....: Right button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::OnRightDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
        {
            if (control->FXMin <= x && control->FXMin + control->FWidth > x &&
                control->FYMin <= y && control->FYMin + control->FHeight > y)
            {
                control->OnRightDown(x, y, ButtonState, KeyState);
                break;
            }
        }
        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::OnRightUp
#
#   Purpose....: Left button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::OnRightUp(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            control->OnRightUp(x, y, ButtonState, KeyState);
            
        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Execute()
{
    TWait Wait;

    if (FKeyboard)
    {
    	Wait.Add(FKeyboard);
    	FKeyboard->Owner = this;
    	FKeyboard->OnKeyPress = KeyPress;
	    FKeyboard->OnKeyRelease = KeyRelease;
	}

    if (FMouse)
    {
        Wait.Add(FMouse);
        FMouse->Owner = this;
    	FMouse->OnMove = MouseMove;
	    FMouse->OnLeftUp = LeftUp;
    	FMouse->OnLeftDown = LeftDown;
	    FMouse->OnRightUp = RightUp;
    	FMouse->OnRightDown = RightDown;
    }

    while (FInstalled)
        Wait.WaitForever();
}
