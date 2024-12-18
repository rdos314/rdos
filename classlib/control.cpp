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
# along with this program; if not, write to the Free Softw
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# control.cpp
# Graphics control base class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "rdos.h"

#include "control.h"
#include "ini.h"
#include "bitdev.h"

#define     STACK_SIZE  0x1000

#define     FALSE       0
#define     TRUE        !FALSE

static int CurrId = 0;
static TSection IdSection("Control ID");

/*##########################################################################
#
#   Name       : DecodeKey
#
#   Purpose....: Decode key-string to VK-key
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char DecodeKey(const char *key)
{
    if (strlen(key) == 1)
        return key[0];

    if (!strcmp(key, "BACK"))
        return VK_BACK;    

    if (!strcmp(key, "TAB"))
        return VK_TAB;    

    if (!strcmp(key, "CLEAR"))
        return VK_CLEAR;    

    if (!strcmp(key, "RETURN"))
        return VK_RETURN;    

    if (!strcmp(key, "ESC"))
        return VK_ESCAPE;    

    if (!strcmp(key, "ESCAPE"))
        return VK_ESCAPE;    

    if (!strcmp(key, "SPACE"))
        return VK_SPACE;    

    if (!strcmp(key, "PRIOR"))
        return VK_PRIOR;    

    if (!strcmp(key, "NEXT"))
        return VK_NEXT;    

    if (!strcmp(key, "END"))
        return VK_END;    

    if (!strcmp(key, "HOME"))
        return VK_HOME;    

    if (!strcmp(key, "LEFT"))
        return VK_LEFT;    

    if (!strcmp(key, "UP"))
        return VK_UP;    

    if (!strcmp(key, "RIGHT"))
        return VK_RIGHT;    

    if (!strcmp(key, "DOWN"))
        return VK_DOWN;    

    if (!strcmp(key, "INSERT"))
        return VK_INSERT;    

    if (!strcmp(key, "DELETE"))
        return VK_DELETE;    

    if (key[0] == 'E')
        return VK_EXT + atoi(key + 1);

    return 0;        
}

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
    TDisplayControlThread *dev = (TDisplayControlThread *)Keyboard->Owner;

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
    TDisplayControlThread *dev = (TDisplayControlThread *)Keyboard->Owner;

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
    TDisplayControlThread *dev = (TDisplayControlThread *)Mouse->Owner;

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
    TDisplayControlThread *dev = (TDisplayControlThread *)Mouse->Owner;

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
    TDisplayControlThread *dev = (TDisplayControlThread *)Mouse->Owner;

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
    TDisplayControlThread *dev = (TDisplayControlThread *)Mouse->Owner;

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
    TDisplayControlThread *dev = (TDisplayControlThread *)Mouse->Owner;

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

    Init();

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

    Init();

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

    Init();

    FDev = 0;
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

    Init();

    FDev = 0;
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

    Protect();

    if (FTransBitmap)
        delete FTransBitmap;
        
    control = FControlList;

    while (control)
    {
        FControlList = control->FNext;
        delete control;

        control = FControlList;
    }

    if (FDelay)
    {
        delete FDelay;
        FDelay = 0;
    }

    if (FParent)
        FParent->Delete(this);

    if (FDev)
        FDev->Delete(this);

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::Init
#
#   Purpose....: Init control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Init()
{
    OnChanged = 0;
    Owner = 0;

    FControlList = 0;
    FDelay = 0;
    FDirty = TRUE;

    FTransparent = FALSE;
    FTransBitmap = 0;
    FTransChanged = TRUE;

    IdSection.Enter();
    ControlId = CurrId;
    CurrId++;
    IdSection.Leave();
}

/*##########################################################################
#
#   Name       : TControl::NotifyChanged
#
#   Purpose....: Notify control change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::NotifyChanged()
{
    if (OnChanged)
        (*OnChanged)(this);
}

/*##########################################################################
#
#   Name       : TControl::NotifyResize
#
#   Purpose....: Notify size-change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::NotifyResize()
{
}

/*##########################################################################
#
#   Name       : TControl::ChildChange
#
#   Purpose....: Notify a significant change in a child-control that requires
#                a complete redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::ChildChange()
{
}

/*##########################################################################
#
#   Name       : TControl::IsRedrawEnabled
#
#   Purpose....: Check if redraw is enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::IsRedrawEnabled()
{
    if (FDev)
        return FDev->IsRedrawEnabled();
    else
        return FParent->IsRedrawEnabled();
}

/*##########################################################################
#
#   Name       : TControl::Protect
#
#   Purpose....: Protect control during redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Protect()
{
    if (FDev)
        FDev->Protect();
    else
        FParent->Protect();
}

/*##########################################################################
#
#   Name       : TControl::Unprotect
#
#   Purpose....: Unprotect control during redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Unprotect()
{
    if (FDev)
        FDev->Unprotect();
    else
        FParent->Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::Apply
#
#   Purpose....: Apply bitmap to control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Apply(TGraphicDevice *dev)
{
    if (FDev)
        FDev->Apply(dev);
}

/*##########################################################################
#
#   Name       : TControl::DeleteDev
#
#   Purpose....: Delete control-device (used for auto-creation with new in constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::DeleteDev()
{
    if (FDev)
    {
        delete FDev;
        FDev = 0;
    }
}

/*##########################################################################
#
#   Name       : TControl::HasParent
#
#   Purpose....: Check if control has parent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::HasParent()
{
    if (FParent)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TControl::RedrawParent
#
#   Purpose....: Redraw parent control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::RedrawParent()
{
    if (FParent)
        FParent->Redraw();
}

/*##########################################################################
#
#   Name       : TControl::NotifyChildChange
#
#   Purpose....: Notify a change in a child control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::NotifyChildChange()
{
    TControl *parent;

    Protect();

    ChildChange();

    parent = FParent;

    while (parent)
    {
        parent->ChildChange();
        parent = parent->FParent;
    }

    Unprotect();
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

    Protect();

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

    Unprotect();    

    NotifyChildChange();
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

    Protect();

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

    control->FNext = 0;

    Unprotect();

    NotifyChildChange();
}        

/*##########################################################################
#
#   Name       : TControl::GetControlThread
#
#   Purpose....: Get control thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControlThread *TControl::GetControlThread()
{
    if (FDev)
        return FDev;
    else
    {
        if (FParent)
            return FParent->GetControlThread();
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : TControl::GetBpp
#
#   Purpose....: Get bits per pixel
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::GetBpp()
{
    TControlThread *ct = GetControlThread();

    if (ct)
        return ct->FGraphic->GetBpp();
    else
        return 1;
}        

/*##########################################################################
#
#   Name       : TControl::SetMouseMarker
#
#   Purpose....: Set mouse marker
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSprite *TControl::SetMouseMarker(TGraphicDevice *MouseBitmap, TGraphicDevice *MouseMask, int HotX, int HotY)
{
    TControlThread *ct = GetControlThread();

    if (ct)
        return ct->SetMouseMarker(MouseBitmap, MouseMask, HotX, HotY);
    else
        return 0;
}        

/*##########################################################################
#
#   Name       : TControl::RestoreMouseMarker
#
#   Purpose....: Restore mouse marker
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::RestoreMouseMarker(TSprite *Sprite)
{
    TControlThread *ct = GetControlThread();

    if (ct)
        ct->RestoreMouseMarker(Sprite);
}        

/*##########################################################################
#
#   Name       : TControl::SetTransparent
#
#   Purpose....: Set control to transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::SetTransparent()
{
    FTransparent = TRUE;
}

/*##########################################################################
#
#   Name       : TControl::ClearTransparent
#
#   Purpose....: Set control to non-transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::ClearTransparent()
{
    FTransparent = FALSE;

    if (FTransBitmap)
    {
        delete FTransBitmap;
        FTransBitmap = 0;
        FTransChanged = TRUE;
    }
}

/*##########################################################################
#
#   Name       : TControl::IsTransparent
#
#   Purpose....: Check if control is transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::IsTransparent()
{
    return FTransparent;
}

/*##########################################################################
#
#   Name       : TControl::Set
#
#   Purpose....: Set control parameters from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int StartX, StartY;
    int SizeX, SizeY;
    int SizeChanged;
    int PosChanged;

    StartX = FXMin;
    StartY = FYMin;
    SizeX = FWidth;
    SizeY = FHeight;

    SizeChanged = FALSE;
    PosChanged = FALSE;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Transparent", str, 255))
    {
        if (atoi(str))
            SetTransparent();
        else
            ClearTransparent();
    }

    if (Ini->ReadVar("Start.X", str, 255))
    {
        StartX = atoi(str);
        PosChanged = TRUE;
    }

    if (Ini->ReadVar("Start.Y", str, 255))
    {
        StartY = atoi(str);
        PosChanged = TRUE;
    }

    if (Ini->ReadVar("Size.X", str, 255))
    {
        SizeX = atoi(str);
        SizeChanged = TRUE;
    }

    if (Ini->ReadVar("Size.Y", str, 255))
    {
        SizeY = atoi(str);
        SizeChanged = TRUE;
    }


    if (SizeChanged)
        Resize(SizeX, SizeY);

    if (PosChanged)
        Move(StartX, StartY);

    if (Ini->ReadVar("Visible", str, 255))
    {
        if (atoi(str))
            Show();
        else
            Hide();
    }

    if (Ini->ReadVar("Enabled", str, 255))
    {
        if (atoi(str))
            Enable();
        else
            Disable();
    }
}

/*##########################################################################
#
#   Name       : TControl::Set
#
#   Purpose....: Set control parameters from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TControl::SaveBackground
#
#   Purpose....: Save background before drawing transparent control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::SaveBackground()
{
    int x, y;

    if (!FParent)
    {
        Protect();

        GetAbsPos(&x, &y);
           
        if (FTransBitmap)
        {
            if (FTransBitmap->GetWidth() != FWidth || FTransBitmap->GetHeight() != FHeight)
            {            
                delete FTransBitmap;
                FTransBitmap = 0;
            }
        }

        if (!FTransBitmap)
            FTransBitmap = new TBitmapGraphicDevice(GetBpp(), FWidth, FHeight);

        FDev->SaveBackground(FTransBitmap, x, y, FWidth, FHeight);

        Unprotect();
    }
}

/*##########################################################################
#
#   Name       : TControl::RestoreBackground
#
#   Purpose....: Restore background of transparent control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::RestoreBackground()
{
    int x, y;

    if (!FParent)
    {
        Protect();

        GetAbsPos(&x, &y);

        if (FTransBitmap)
            FDev->RestoreBackground(FTransBitmap, x, y, FWidth, FHeight);

        Unprotect();
    }
}

/*##########################################################################
#
#   Name       : TControl::RedrawBackground
#
#   Purpose....: Redraw background of transparent control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::RedrawBackground(TGraphicDevice *dev)
{
    int x,y;
    
    if (dev && FTransBitmap)
    {    
        GetAbsPos(&x, &y);
        dev->Blit(FTransBitmap, 0, 0, x, y, FWidth, FHeight);
    }
}

/*##########################################################################
#
#   Name       : TControl::UpdateTransparent
#
#   Purpose....: Update transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::UpdateTransparent()
{
    if (FTransChanged)
    {
        FTransChanged = FALSE;
        SaveBackground();
    }
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
    if (!FVisible)
    {
        FVisible = TRUE;
        NotifyChildChange();
        Redraw();
    }
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
    if (FVisible)
    {
        Protect();

        if (FTransparent)
            RestoreBackground();

        FVisible = FALSE;
        Unprotect();

        NotifyChildChange();

        if (FParent)
           FParent->Redraw();
    }
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
    TControl *parent;
    int enabled;

    parent = FParent;
    enabled = FEnabled;

    while (parent && enabled)
    {
        enabled = parent->IsEnabled();
        parent = parent->FParent;
    }

    return enabled;
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
    if (FWidth != xsize || FHeight != ysize)
    {
        Protect();
        
        if (FTransparent && FVisible)
            RestoreBackground();
    
        FWidth = xsize;
        FHeight = ysize;

        if (FTransparent && FVisible)
            FTransChanged = TRUE;

        Unprotect();

        NotifyResize();

        if (FVisible)
        {
            NotifyChildChange();

            if (FParent)
                FParent->Redraw();
            else
                Redraw();
        }
    }
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
    if (FXMin != xstart || FYMin != ystart)
    {
        Protect();
        
        if (FTransparent && FVisible)
            RestoreBackground();
    
        FXMin = xstart;
        FYMin = ystart;

        if (FTransparent && FVisible)
            FTransChanged = TRUE;

        Unprotect();
        
        if (FVisible)
        {
            NotifyChildChange();

            if (FParent)
                FParent->Redraw();
            else
                Redraw();
        }
    }
}

/*##########################################################################
#
#   Name       : TControl::GetPos
#
#   Purpose....: Get (relative) position of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::GetPos(int *x, int *y) const
{
    *x = FXMin;
    *y = FYMin;
}

/*##########################################################################
#
#   Name       : TControl::GetAbsPos
#
#   Purpose....: Get absolute position of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::GetAbsPos(int *x, int *y) const
{
    TControl *parent;
    int xstart, ystart;

    xstart = FXMin;
    ystart = FYMin;

    parent = FParent;
    while (parent)
    {
        xstart += parent->FXMin;
        ystart += parent->FYMin;
        parent = parent->FParent;
    }

    *x = xstart;
    *y = ystart;
}

/*##########################################################################
#
#   Name       : TControl::GetSize
#
#   Purpose....: Get size of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::GetSize(int *x, int *y) const
{
    *x = FWidth;
    *y = FHeight;
}

/*##########################################################################
#
#   Name       : TControl::GetWidth
#
#   Purpose....: Get width of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::GetWidth() const
{
    return FWidth;
}

/*##########################################################################
#
#   Name       : TControl::GetHeight
#
#   Purpose....: Get height of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::GetHeight() const
{
    return FHeight;
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
    if (FDev)
        FDev->PutKey(ch);
    else
        FParent->PutKey(ch);
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
    if (FEnabled && FVisible)
    {
        if (FXMin <= x && FXMin + FWidth > x && FYMin <= y && FYMin + FHeight > y)
        {
            if (FParent)
                return FParent->IsInside(FParent->FXMin + x, FParent->FYMin + y);
            else
                return TRUE;
        }
        else
            return FALSE;
    }
    else
        return FALSE;

}

/*##########################################################################
#
#   Name       : TControl::Unload
#
#   Purpose....: Unload
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Unload()
{
    TControl *control;

    Protect();

    control = FControlList;

    while (control)
    {
        FControlList = control->FNext;
        delete control;

        control = FControlList;
    }

    FControlList = 0;

    if (FParent)
        FParent->Delete(this);
    else
        FDev->Delete(this);

    FParent = 0;
    FDev = 0;

    Unprotect();

    delete this;
}

/*##########################################################################
#
#   Name       : TControl::IsDirty
#
#   Purpose....: Check if control needs to be redrawn
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControl::IsDirty()
{
    return FDirty;
}

/*##########################################################################
#
#   Name       : TControl::SetDirty
#
#   Purpose....: Invalidate control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::SetDirty()
{
    FDirty = TRUE;
}

/*##########################################################################
#
#   Name       : TControl::ResetDirty
#
#   Purpose....: Set control to painted
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::ResetDirty()
{
    FDirty = FALSE;
}

/*##########################################################################
#
#   Name       : TControl::UpdateChild
#
#   Purpose....: Update child control if needed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::UpdateChild(TControl *control, int level)
{
    if (FParent)
        FParent->UpdateChild(control, level + 1);
    else
        FDev->Update(control);
}

/*##########################################################################
#
#   Name       : TControl::Update
#
#   Purpose....: Redraw control if needed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Update()
{
    Protect();

    if (FParent)
        FParent->UpdateChild(this, 1);
    else
        FDev->Update(this);

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::EnumerateControls
#
#   Purpose....: List all controls under a protected environment
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::EnumerateControls(void *Data, void (*CallBack)(void *Data, TControl *Control))
{
    TControl *control;

    if (IsVisible())
    {
        Protect();

        control = FControlList;

        (*CallBack)(Data, this);

        while (control)
        {
            control->EnumerateControls(Data, CallBack);
            control = control->FNext;
        }

        Unprotect();
    }
}

/*##########################################################################
#
#   Name       : TControl::GetControl
#
#   Purpose....: Get control from ControlId
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControl *TControl::GetControl(int Id)
{
    TControl *control;
    TControl *c = 0;

    if (IsVisible())
    {
        Protect();

        control = FControlList;

        while (control && !c)
        {
            if (control->ControlId == Id)
                c = control;

            if (!c)
                c = control->GetControl(Id);

            if (!c)            
                control = control->FNext;
        }

        Unprotect();
    }

    return c;
}

/*##########################################################################
#
#   Name       : TControl::Redraw
#
#   Purpose....: Redraw control after specified time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Redraw(int millisec)
{
    Protect();

    SetDirty();

    if (FDelay)
    {
        delete FDelay;
        FDelay = 0;
    }

    if (millisec)
    {
        FDelay = new TDateTime;
        FDelay->AddMilli(millisec);
    }
    else
        Update();

    if (FDev)
        FDev->Signal();

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::RedrawChild
#
#   Purpose....: Redraw child control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::RedrawChild(TControl *control, int level)
{
    if (FParent)
        FParent->RedrawChild(control, level + 1);
    else
        FDev->DefaultRedraw(control);
}

/*##########################################################################
#
#   Name       : TControl::Redraw
#
#   Purpose....: Redraw control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::Redraw()
{
    Protect();

    SetDirty();

    if (FParent)
        FParent->RedrawChild(this, 1);
    else
        FDev->DefaultRedraw(this);

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::ClearRedraw
#
#   Purpose....: Clear redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::ClearRedraw()
{
    Protect();

    if (FDelay)
    {
        delete FDelay;
        FDelay = 0;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::GetRedrawTime
#
#   Purpose....: Get time for next redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TControl::GetRedrawTime()
{
    TDateTime LowTime;
    TDateTime RedrawTime;
    TControl *control;

    RedrawTime.AddYear(1);

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsVisible())
        {
            LowTime = control->GetRedrawTime();
            if (LowTime < RedrawTime)
                RedrawTime = LowTime;
        }            

        control = control->FNext;
    }

    if (FDelay)
        if (*FDelay < RedrawTime)
            RedrawTime = *FDelay;

    Unprotect();

    return RedrawTime;
}

/*##########################################################################
#
#   Name       : TControl::HandleUpdate
#
#   Purpose....: Handle update
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::HandleUpdate()
{
    TDateTime currtime;
    TControl *control;
    int redrawn;

    Protect();

    redrawn = FALSE;

    if (FDelay)
    {
        if (currtime > *FDelay)
        {
            Update();
            redrawn = TRUE;
        }
    }

    if (!redrawn)
    {
        control = FControlList;

        while (control)
        {
            if (control->IsVisible())
                if (currtime > control->GetRedrawTime())
                    control->HandleUpdate();

            control = control->FNext;
        }
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::HandleApply
#
#   Purpose....: Handle apply
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::HandleApply()
{
    TControl *control;

    Protect();

    NotifyChildChange();
    Update();

    control = FControlList;

    while (control)
    {
        if (control->IsVisible())
            control->HandleApply();
        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::SetClipRect
#
#   Purpose....: Set cliprec for control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::SetClipRect(TGraphicDevice *dev, int xmin, int ymin, int xmax, int ymax)
{
    /*    dev->SetClipRect(   xmin, ymin,
          xmax, ymax);
          */

    TControl *parent;
    int xstart, ystart;

    xstart = FXMin;
    ystart = FYMin;

    parent = FParent;
    while (parent)
    {
        xstart += parent->FXMin;
        ystart += parent->FYMin;
        parent = parent->FParent;
    }

    if (xstart > xmin)
        xmin = xstart;

    if (ystart > ymin)
        ymin = ystart;

    if (xstart + FWidth - 1 < xmax)
        xmax = xstart + FWidth - 1;

    if (ystart + FHeight - 1 < ymax)
        ymax = ystart + FHeight - 1;        

    if (FParent)
        FParent->SetClipRect(   dev, 
                xmin, ymin,
                xmax, ymax);        
    else
        dev->SetClipRect(   xmin, ymin,
                xmax, ymax);

}

/*##########################################################################
#
#   Name       : TControl::SetClipRect
#
#   Purpose....: Set cliprec for control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::SetClipRect(TGraphicDevice *dev, int xstart, int ystart)
{
    SetClipRect(    dev,
            xstart, 
            ystart,
            xstart + FWidth - 1,
            ystart + FHeight - 1);
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
#   Name       : TControl::GetSiblingControlById
#
#   Purpose....: Get sibling control by ID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControl *TControl::GetSiblingControlById(int Index)
{
    TControl *Parent = FParent;    
    TControl *control = 0;
    int i;

    if (Parent)
    {
        control = Parent->FControlList;

        for (i = 0; i < Index && control; i++)
            control = control->FNext;
    }

    return control;
}

/*##########################################################################
#
#   Name       : TControl::RedrawChildren
#
#   Purpose....: Redraw children
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::RedrawChildren(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    TControl *control;
    int xstart;
    int ystart;

    Protect();

    if (IsVisible())
    {
        control = FControlList;

        while (control)
        {
            if (control->IsVisible() && IsRedrawEnabled())
            {
                xstart = xmin + control->FXMin;
                ystart = ymin + control->FYMin;

                SetClipRect(    dev, xstart, ystart,
                        xstart + control->FWidth - 1,
                        ystart + control->FHeight - 1);

                control->ResetDirty();
                control->Paint(dev, xstart, ystart, control->FWidth, control->FHeight);
                control->RedrawChildren(dev, xstart, ystart, control->FWidth, control->FHeight);
            }            

            control = control->FNext;
        }
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControl::UpdateChildren
#
#   Purpose....: Update children
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControl::UpdateChildren(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    TControl *control;
    int xstart;
    int ystart;

    Protect();

    if (IsVisible())
    {
        control = FControlList;

        while (control)
        {
            if (control->IsVisible() && IsRedrawEnabled())
            {
                xstart = xmin + control->FXMin;
                ystart = ymin + control->FYMin;

                SetClipRect(    dev, xstart, ystart,
                        xstart + control->FWidth - 1,
                        ystart + control->FHeight - 1);

                if (control->IsDirty())
                {
                    control->ResetDirty();
                    control->Paint(dev, xstart, ystart, control->FWidth, control->FHeight);
                    control->RedrawChildren(dev, xstart, ystart, control->FWidth, control->FHeight);
                }                    
                else
                    control->UpdateChildren(dev, xstart, ystart, control->FWidth, control->FHeight);
            }            

            control = control->FNext;
        }
    }

    Unprotect();
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

    Protect();

    control = FControlList;

    while (control && !handled)
    {
        if (control->IsEnabled())
            if (control->OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode))
                handled = TRUE;

        control = control->FNext;
    }

    Unprotect();

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

    Protect();

    control = FControlList;

    while (control && !handled)
    {
        if (control->IsEnabled())
            if (control->OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode))
                handled = TRUE;

        control = control->FNext;
    }

    Unprotect();

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

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnMouseMove(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    Unprotect();

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

    Protect();

    control = FControlList;

    while (control)
    {
        control->OnLeftUp(x - FXMin, y - FYMin, ButtonState, KeyState);
        control = control->FNext;
    }

    Unprotect();

    return FALSE;
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

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnLeftDown(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    Unprotect();

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

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightUp(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    Unprotect();

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

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightDown(x - FXMin, y - FYMin, ButtonState, KeyState))
                handled = FALSE;

        control = control->FNext;
    }

    Unprotect();

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
TControlThread::TControlThread()
 : FListSection("Control.List"),
   FPaintSection("Control.Paint")
{
    FGraphic = 0;
    Init();
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
TControlThread::TControlThread(TGraphicDevice *dev)
 : FListSection("Control.List"),
   FPaintSection("Control.Paint")
{
    FVbe = dev;
    FGraphic = new TGraphicDevice(*dev);
    Init();
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

    Protect();

    control = FControlList;

    while (control)
    {
        FControlList = control->FNext;
        delete control;

        control = FControlList;
    }

    Unprotect();

    if (FGraphic)
        delete FGraphic;

    if (FBackground)
        delete FBackground;
}

/*##########################################################################
#
#   Name       : TControlThread::Init
#
#   Purpose....: Init for control-thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Init()
{
    FControlList = 0;
    FBackground = 0;
}

/*##########################################################################
#
#   Name       : TControlThread::CreateBackground
#
#   Purpose....: Create background
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::CreateBackground()
{
    if (!FBackground && FVbe)
    {
        FBackground = new TBitmapGraphicDevice(32, FVbe->GetWidth(), FVbe->GetHeight());
        FBackground->SetFilledStyle();
        FBackground->SetDrawColor(0, 0, 0);
        FBackground->DrawRect(0, 0, FVbe->GetWidth(), FVbe->GetHeight());
    }        
}

/*##########################################################################
#
#   Name       : TControlThread::SetBackground
#
#   Purpose....: Set background
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::SetBackground(TBitmapGraphicDevice *bitmap)
{
    CreateBackground();

    if (FBackground)
    {
        FBackground->Blit(bitmap, 0, 0, 0, 0, bitmap->GetWidth(), bitmap->GetHeight());
        FVbe->Blit(FBackground, 0, 0, 0, 0, FBackground->GetWidth(), FBackground->GetHeight());  
    }
}

/*##########################################################################
#
#   Name       : TControlThread::SaveBackground
#
#   Purpose....: Save background
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::SaveBackground(TBitmapGraphicDevice *bitmap, int x, int y, int width, int height)
{
    CreateBackground();

    if (FBackground)
        bitmap->Blit(FBackground, x, y, 0, 0, width, height);    
}

/*##########################################################################
#
#   Name       : TControlThread::RestoreBackground
#
#   Purpose....: Restore background
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::RestoreBackground(TBitmapGraphicDevice *bitmap, int x, int y, int width, int height)
{
    CreateBackground();

    if (FBackground)
    {
        FGraphic->ClearClipRect();
        FGraphic->Blit(bitmap, 0, 0, x, y, width, height);
    }
}

/*##########################################################################
#
#   Name       : TControlThread::IsRedrawEnabled
#
#   Purpose....: Check if redraw is enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TControlThread::IsRedrawEnabled()
{
    return TRUE;
}

/*##########################################################################
#
#   Name       : TControlThread::SetMouseMarker
#
#   Purpose....: Set mouse marker
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSprite *TControlThread::SetMouseMarker(TGraphicDevice *MouseBitmap, TGraphicDevice *MouseMask, int HotX, int HotY)
{
    return 0;
}

/*##########################################################################
#
#   Name       : TControlThread::RestoreMouseMarker
#
#   Purpose....: Restore mouse marker
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::RestoreMouseMarker(TSprite *Sprite)
{
}

/*##########################################################################
#
#   Name       : TControlThread::Protect
#
#   Purpose....: Protect control during redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Protect()
{
    FListSection.Enter();
}

/*##########################################################################
#
#   Name       : TControlThread::Unprotect
#
#   Purpose....: Unprotect control during redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Unprotect()
{
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

    Protect();

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

    Unprotect();
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

    Protect();

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

    control->FNext = 0;

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControlThread::GetSize
#
#   Purpose....: Get size of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::GetSize(int *x, int *y) const
{
    if (FGraphic)
    {
        *x = FGraphic->GetWidth();
        *y = FGraphic->GetHeight();
    }
    else
    {
        *x = 0;
        *y = 0;
    }
}

/*##########################################################################
#
#   Name       : TControlThread::Update
#
#   Purpose....: Update control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Update(TControl *control)
{
    int xmin;
    int ymin;
    TControl *parent;
    int visible;

    xmin = control->FXMin;
    ymin = control->FYMin;

    parent = control->FParent;

    visible = control->IsVisible();

    while (parent && visible)
    {
        visible = parent->IsVisible();

        xmin += parent->FXMin;
        ymin += parent->FYMin;

        parent = parent->FParent;
    }

    if (FGraphic && visible && IsRedrawEnabled())
    {
        control->ClearRedraw();

        FPaintSection.Enter();
        FGraphic->SetClipRect(   xmin, ymin,
                xmin + control->FWidth - 1,
                ymin + control->FHeight - 1);

        if (control->IsDirty())
        {
            control->ResetDirty();
            control->Paint(FGraphic, xmin, ymin, control->FWidth, control->FHeight);
            control->RedrawChildren(FGraphic, xmin, ymin, control->FWidth, control->FHeight);
        }            
        else
            control->UpdateChildren(FGraphic, xmin, ymin, control->FWidth, control->FHeight);

        FPaintSection.Leave();
    }
}

/*##########################################################################
#
#   Name       : TControlThread::DefaultRedraw
#
#   Purpose....: Setup a default redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::DefaultRedraw(TControl *control)
{
    control->Redraw(1);
}

/*##########################################################################
#
#   Name       : TControlThread::EnumerateControls
#
#   Purpose....: List all controls under a protected environment
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::EnumerateControls(void *Data, void (*CallBack)(void *Data, TControl *Control))
{
    TControl *control;

    Protect();

    control = FControlList;

    while (control)
    {
        control->EnumerateControls(Data, CallBack);
        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TControlThread::GetControl
#
#   Purpose....: Get control from ControlId
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControl *TControlThread::GetControl(int Id)
{
    TControl *control;
    TControl *c = 0;

    Protect();

    control = FControlList;

    while (control && !c)
    {
        if (control->ControlId == Id)
            c = control;

        if (!c)
            c = control->GetControl(Id);

        if (!c)            
            control = control->FNext;
    }

    Unprotect();

    return c;
}

/*##########################################################################
#
#   Name       : TControlThread::Apply
#
#   Purpose....: Apply control-settings to bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Apply(TGraphicDevice *dev)
{
    TControl *control;
    TGraphicDevice *olddev;

    Protect();

    olddev = FGraphic;
    FGraphic = dev;

    control = FControlList;

    while (control)
    {
        if (control->IsVisible())
            control->HandleApply();

        control = control->FNext;
    }

    FGraphic = olddev;

    Unprotect();
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
}

/*##########################################################################
#
#   Name       : TControlThread::Signal
#
#   Purpose....: Signal wakeup to thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TControlThread::Signal()
{
    FSignal.Signal();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::TDisplayControlThread
#
#   Purpose....: Constructor for display control-thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
    TDisplayControlThread::TDisplayControlThread(const char *name, TGraphicDevice *dev)
: TControlThread(dev)
{
    Init(name);
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::~TDisplayControlThread
#
#   Purpose....: Destructor for display control-thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisplayControlThread::~TDisplayControlThread()
{
    if (FMouseSprite)
    {
        FMouseSprite->Hide();
        delete FMouseSprite;
    }
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::Init
#
#   Purpose....: Init display control-thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::Init(const char *name)
{
    FMouseSprite = 0;
    FKeyboard = 0;
    FMouse = 0;

    DefaultRedrawTimeout = 25;
    Enabled = TRUE;
    EnableDelay = 0;

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
#   Name       : TDisplayControlThread::IsRedrawEnabled
#
#   Purpose....: Check if redraw is enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisplayControlThread::IsRedrawEnabled()
{
    if (Enabled)
    {
        if (EnableDelay)
            return FALSE;
        else
            return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::EnableRedraw
#
#   Purpose....: Enable redraws
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::EnableRedraw(int Delay)
{
    EnableDelay = Delay;
    Enabled = TRUE;
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::DisableRedraw
#
#   Purpose....: Disable redraws
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::DisableRedraw()
{
    int i;

    for (i = 0; i < 15; i++)
    {
        FSignal.Signal();
        RdosWaitMilli(5);
    }

    Enabled = FALSE;
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::SetDefaultRedrawTimeout
#
#   Purpose....: Set default redraw timeout
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::SetDefaultRedrawTimeout(int milli)
{
    DefaultRedrawTimeout = milli;
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::Add
#
#   Purpose....: Add keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::Add(TKeyboardDevice *Keyboard)
{
    FKeyboard = Keyboard;

    Keyboard->Owner = this;
    Keyboard->OnKeyPress = KeyPress;
    Keyboard->OnKeyRelease = KeyRelease;
    FWait.Add(Keyboard);
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::Add
#
#   Purpose....: Add mouse
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::Add(TMouseDevice *Mouse)
{
    FMouse = Mouse;

    Mouse->Owner = this;
    Mouse->OnMove = MouseMove;
    Mouse->OnLeftUp = LeftUp;
    Mouse->OnLeftDown = LeftDown;
    Mouse->OnRightUp = RightUp;
    Mouse->OnRightDown = RightDown;

    Mouse->SetWindow(0, 0, FGraphic->GetWidth(), FGraphic->GetHeight());
    Mouse->SetMickey(1, 1);
    Mouse->SetPosition(FGraphic->GetWidth() / 2, FGraphic->GetHeight() / 2);

    FWait.Add(FMouse);
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::Protect
#
#   Purpose....: Protect control during redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::Protect()
{
    TControlThread::Protect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::Unprotect
#
#   Purpose....: Unprotect control during redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::Unprotect()
{
    TControlThread::Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::SetMouseMarker
#
#   Purpose....: Set mouse marker
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSprite *TDisplayControlThread::SetMouseMarker(TGraphicDevice *MouseBitmap, TGraphicDevice *MouseMask, int HotX, int HotY)
{
    TSprite *OldSprite = FMouseSprite;

    if (OldSprite)
        OldSprite->Hide();

    FMouseSprite = FVbe->CreateSprite(MouseBitmap, MouseMask, HotX, HotY);
    FMouseSprite->Move(FVbe->GetWidth() / 2, FGraphic->GetHeight() / 2);
    FMouseSprite->Show();

    return OldSprite;
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::RestoreMouseMarker
#
#   Purpose....: Restore mouse marker
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::RestoreMouseMarker(TSprite *Sprite)
{
    if (FMouseSprite)
    {
        FMouseSprite->Hide();
        delete FMouseSprite;
    }

    FMouseSprite = Sprite;
    if (FMouseSprite)
    {
        FMouseSprite->Move(FVbe->GetWidth() / 2, FVbe->GetHeight() / 2);
        FMouseSprite->Show();
    }        
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyKeyPressed
#
#   Purpose....: Key pressed callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;

    if (OnKeyPressed)
        (*OnKeyPressed)(this, ExtKey, KeyState, VirtualKey, ScanCode);

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode))
                break;

        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyKeyReleased
#
#   Purpose....: Key released callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    TControl *control;

    if (OnKeyReleased)
        (*OnKeyReleased)(this, ExtKey, KeyState, VirtualKey, ScanCode);

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode))
                break;

        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyMouseMove
#
#   Purpose....: Mouse move callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyMouseMove(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnMouseMove)
        (*OnMouseMove)(this, x, y, ButtonState, KeyState);

    if (FMouseSprite)
        FMouseSprite->Move(x, y);

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnMouseMove(x, y, ButtonState, KeyState))
                break;

        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyLeftDown
#
#   Purpose....: Left button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyLeftDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnLeftDown)
        (*OnLeftDown)(this, x, y, ButtonState, KeyState);

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnLeftDown(x, y, ButtonState, KeyState))
                break;

        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyLeftUp
#
#   Purpose....: Left button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyLeftUp(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnLeftUp)
        (*OnLeftUp)(this, x, y, ButtonState, KeyState);

    Protect();

    control = FControlList;

    while (control)
    {
        control->OnLeftUp(x, y, ButtonState, KeyState);    
        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyRightDown
#
#   Purpose....: Right button down callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyRightDown(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnRightDown)
        (*OnRightDown)(this, x, y, ButtonState, KeyState);

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightDown(x, y, ButtonState, KeyState))
                break;

        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyRightUp
#
#   Purpose....: Left button up callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyRightUp(int x, int y, int ButtonState, int KeyState)
{
    TControl *control;

    if (OnRightUp)
        (*OnRightUp)(this, x, y, ButtonState, KeyState);

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsEnabled())
            if (control->OnRightUp(x, y, ButtonState, KeyState))
                break;

        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::NotifyClick
#
#   Purpose....: Notify button clicked
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::NotifyClick(TControl *control, int x, int y)
{
    if (control->IsEnabled())
    {
        control->OnLeftDown(control->FXMin + x, control->FYMin + y, 0, 0);
        control->OnLeftUp(control->FXMin + x, control->FYMin + y, 0, 0);
    }
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::PutKey
#
#   Purpose....: Put key into buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::PutKey(char ch)
{
    if (FKeyboard)
        FKeyboard->Put(ch);
    else
        NotifyKeyPressed(ch, ch, ch, ch);
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::GetRedrawTime
#
#   Purpose....: Get next redraw time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TDisplayControlThread::GetRedrawTime()
{
    TDateTime LowTime;
    TDateTime RedrawTime;
    TControl *control;

    Protect();

    RedrawTime.AddYear(1);

    control = FControlList;

    while (control)
    {
        if (control->IsVisible())
        {
            LowTime = control->GetRedrawTime();
            if (LowTime < RedrawTime)
                RedrawTime = LowTime;
        }

        control = control->FNext;
    }

    Unprotect();

    return RedrawTime;
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::DefaultRedraw
#
#   Purpose....: Setup a default redraw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::DefaultRedraw(TControl *control)
{
    control->Redraw(DefaultRedrawTimeout);
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::HandleUpdate
#
#   Purpose....: Handle control update
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::HandleUpdate()
{
    TControl *control;
    TDateTime currtime;

    Protect();

    control = FControlList;

    while (control)
    {
        if (control->IsVisible())
            if (currtime > control->GetRedrawTime())
                control->HandleUpdate();

        control = control->FNext;
    }

    Unprotect();
}

/*##########################################################################
#
#   Name       : TDisplayControlThread::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisplayControlThread::Execute()
{
    TDateTime time;

    FWait.Add(&FSignal);

    while (FInstalled)
    {
        //        time = GetRedrawTime();

        //        FWait.WaitUntil(time);

        FWait.WaitTimeout(20);

        if (Enabled)
        {
            if (EnableDelay)
            {
                RdosWaitMilli(EnableDelay);
                EnableDelay = 0;
            }
            HandleUpdate();
        }
    }
}
