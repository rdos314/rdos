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

    dev->NotifyKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);
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

    dev->NotifyKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode);
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

    dev->NotifyMouseMove(x, y, MouseButton, KeyState);
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

    dev->NotifyLeftUp(x, y, MouseButton, KeyState);
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

    dev->NotifyLeftDown(x, y, MouseButton, KeyState);
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

    dev->NotifyRightUp(x, y, MouseButton, KeyState);
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

    dev->NotifyRightDown(x, y, MouseButton, KeyState);
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
TControl::TControl(TControlThread *dev)
{
    FXMin = 0;
    FYMin = 0;
    FWidth = 0;
    FHeight = 0;

    FVisible = FALSE;
    FEnabled = FALSE;
    FControlList = 0;

    FParent = 0;
    FDev = dev;
    FDev->Add(this);
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
    FControlList = 0;

    FParent = 0;
    FDev = dev;
    FDev->Add(this);
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
TControl::TControl(TControl *control)
{
    FXMin = 0;
    FYMin = 0;
    FWidth = 0;
    FHeight = 0;

    FVisible = FALSE;
    FEnabled = FALSE;
    FControlList = 0;

    FParent = control;
    FParent->Add(this);
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
TControl::TControl(TControl *control, int xmin, int ymin, int width, int height)
{
    FXMin = xmin;
    FYMin = ymin;
    FWidth = width;
    FHeight = height;

    FVisible = TRUE;
    FEnabled = TRUE;
    FControlList = 0;

    FParent = control;
    FParent->Add(this);
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

    if (FParent)
        FParent->Delete(this);
    else
        FDev->Delete(this);
}

/*##########################################################################
#
#   Name       : TControl::Add
#
#   Purpose....: Add child control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Add(TControl *control)
{
	TControl *curr;
    TControl *prev;

    control->FDev = FDev;
    
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
#   Name       : TControl::Delete
#
#   Purpose....: Delete child control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Delete(TControl *control)
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
#   Name       : TControl::Resize
#
#   Purpose....: Resize control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Resize(int xsize, int ysize)
{
    FWidth = xsize;
    FHeight = ysize;

    if (FVisible)
        Redraw();
}

/*##########################################################################
#
#   Name       : TControl::Move
#
#   Purpose....: Move control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Move(int xstart, int ystart)
{
    FXMin = xstart;
    FYMin = ystart;

    if (FVisible)
        Redraw();
}

/*##########################################################################
#
#   Name       : TControl::PutKey
#
#   Purpose....: Put key into buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::PutKey(char ch)
{
    FDev->PutKey(ch);
}

/*##########################################################################
#
#   Name       : TControl::IsInside
#
#   Purpose....: Check if position is inside control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::IsInside(int x, int y) const
{
	 return FXMin <= x && FXMin + FWidth > x && FYMin <= y && FYMin + FHeight > y;
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
    TControl *control;
    int xstart;
    int ystart;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsVisible())
        {
            xstart = xmin + control->FXMin;
            ystart = ymin + control->FYMin;
            
        	dev->SetClipRect(  xstart, ystart,
        					   xstart + control->FWidth - 1,
        					   ystart + control->FHeight - 1);

            control->Paint(dev, xstart, ystart, control->FWidth, control->FHeight);
        }            

        control = control->FNext;
    }

    FListSection.Leave();

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
int TControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;
    int handled = FALSE;

    FListSection.Enter();

    control = FControlList;

    while (control && !handled)
    {
        if (control->IsEnabled())
            if (control->OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode))
                handled = TRUE;

        control = control->FNext;
    }

    FListSection.Leave();

    return handled;
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
int TControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;
    int handled = FALSE;

    FListSection.Enter();

    control = FControlList;

    while (control && !handled)
    {
        if (control->IsEnabled())
            if (control->OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode))
                handled = TRUE;

        control = control->FNext;
    }

    FListSection.Leave();

    return handled;
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
int TControl::OnMouseMove(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;
    int handled = FALSE;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnMouseMove(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    FListSection.Leave();

    return handled;
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
int TControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;
    int handled = FALSE;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnLeftUp(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    FListSection.Leave();

    return handled;
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
int TControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;
    int handled = FALSE;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnLeftDown(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    FListSection.Leave();

    return handled;
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
int TControl::OnRightUp(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;
    int handled = FALSE;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightUp(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    FListSection.Leave();

    return handled;
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
int TControl::OnRightDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;
    int handled = FALSE;

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightDown(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    FListSection.Leave();

    return handled;
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
TControlThread::TControlThread(const char *name, TGraphicDevice *dev)
{
    FGraphic = new TGraphicDevice(*dev);
    FKeyboard = 0;
    FMouse = 0;

    FControlList = 0;

    OnKeyPressed = 0;
    OnKeyReleased = 0;
    OnMouseMove = 0;
    OnLeftUp = 0;
    OnLeftDown = 0;
    OnRightUp = 0;
    OnRightDown = 0;

	Start(name, STACK_SIZE);    
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

    delete FGraphic;
}

/*##########################################################################
#
#   Name       : TControlThread::Add
#
#   Purpose....: Add keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Add(TKeyboardDevice *Keyboard)
{
    FKeyboard = Keyboard;
    
    Keyboard->Owner = this;
    Keyboard->OnKeyPress = KeyPress;
	Keyboard->OnKeyRelease = KeyRelease;
    FWait.Add(Keyboard);
}

/*##########################################################################
#
#   Name       : TControlThread::Add
#
#   Purpose....: Add mouse
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Add(TMouseDevice *Mouse)
{
    FMouse = Mouse;

    Mouse->Owner = this;
    Mouse->OnMove = MouseMove;
	Mouse->OnLeftUp = LeftUp;
    Mouse->OnLeftDown = LeftDown;
	Mouse->OnRightUp = RightUp;
    Mouse->OnRightDown = RightDown;
    FWait.Add(FMouse);
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
    int xmin;
    int ymin;
    TControl *parent;

    xmin = control->FXMin;
    ymin = control->FYMin;

	 parent = control->FParent;

	 while (parent)
	 {
		  xmin += parent->FXMin;
		  ymin += parent->FYMin;

		  parent = parent->FParent;
    }
    
    FPaintSection.Enter();
	 FGraphic->SetClipRect(   xmin, ymin,
        			    xmin + control->FWidth - 1,
        			    ymin + control->FHeight - 1);

    control->Paint(FGraphic, xmin, ymin, control->FWidth, control->FHeight);
    FPaintSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::NotifyKeyPressed
#
#   Purpose....: Key pressed callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::NotifyKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;

    if (OnKeyPressed)
        (*OnKeyPressed)(this, ExtKey, KeyState, VirtualKey, ScanCode);

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode))
                break;

        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::NotifyKeyReleased
#
#   Purpose....: Key released callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::NotifyKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;

    if (OnKeyReleased)
        (*OnKeyReleased)(this, ExtKey, KeyState, VirtualKey, ScanCode);

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode))
                break;

        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::NotifyMouseMove
#
#   Purpose....: Mouse move callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::NotifyMouseMove(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnMouseMove)
        (*OnMouseMove)(this, x, y, ButtonState, KeyState);

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnMouseMove(x, y, ButtonState, KeyState))
                break;

        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::NotifyLeftDown
#
#   Purpose....: Left button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::NotifyLeftDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnLeftDown)
        (*OnLeftDown)(this, x, y, ButtonState, KeyState);

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnLeftDown(x, y, ButtonState, KeyState))
                break;
            
        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::NotifyLeftUp
#
#   Purpose....: Left button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::NotifyLeftUp(int x, int y, int ButtonState, int KeyState)
{
	 TControl *control;

    if (OnLeftUp)
        (*OnLeftUp)(this, x, y, ButtonState, KeyState);

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnLeftUp(x, y, ButtonState, KeyState))
                break;
            
        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::NotifyRightDown
#
#   Purpose....: Right button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::NotifyRightDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnRightDown)
        (*OnRightDown)(this, x, y, ButtonState, KeyState);

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightDown(x, y, ButtonState, KeyState))
                break;

        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::NotifyRightUp
#
#   Purpose....: Left button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::NotifyRightUp(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

	 if (OnRightUp)
        (*OnRightUp)(this, x, y, ButtonState, KeyState);

    FListSection.Enter();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightUp(x, y, ButtonState, KeyState))
                break;
            
        control = control->FNext;
    }

    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TControlThread::PutKey
#
#   Purpose....: Put key into buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::PutKey(char ch)
{
    if (FKeyboard)
        FKeyboard->Put(ch);
    else
		  NotifyKeyPressed(ch, ch, ch, ch);
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
    while (FInstalled)
        FWait.WaitForever();
}
