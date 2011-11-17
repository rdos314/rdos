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
# control.h
# Basic control class
#
########################################################################*/

#ifndef _CONTROL_H
#define _CONTROL_H

#include "graphdev.h"
#include "keyboard.h"
#include "mouse.h"
#include "datetime.h"
#include "sigdev.h"
#include "sprite.h"
#include "str.h"

class TControlThread;

class TControl
{
friend class TControlThread;
friend class TDisplayControlThread;
public:
	TControl(TControlThread *dev);
	TControl(TControlThread *dev, int xmin, int ymin, int width, int height);
	TControl(TControl *Control);
	TControl(TControl *Control, int xmin, int ymin, int width, int height);
    virtual ~TControl();    

    virtual void Set(const char *IniName, const char *IniSection);

    int GetBpp();
    TSprite *SetMouseMarker(TGraphicDevice *MouseBitmap, TGraphicDevice *MouseMask, int HotX, int HotY);
    void RestoreMouseMarker(TSprite *Sprite);

    void Resize(int xsize, int ysize);
    void Move(int xstart, int ystart);
    
    virtual void Show();
    virtual void Hide();
    virtual int IsVisible() const;

    void Enable();
    void Disable();
    int IsEnabled() const;

    int IsInside(int x, int y) const;

    void GetPos(int *x, int *y) const;
    void GetSize(int *x, int *y) const;
    void GetAbsPos(int *x, int *y) const;

    void PutKey(char ch);
    
    void Update();
    void Redraw();
    void Redraw(int millisec);
    void ClearRedraw();

    void EnumerateControls(void *Data, void (*CallBack)(void *Data, TControl *Control));
    TControl *GetControl(int ControlId);

	void (*OnChanged)(TControl *control);

    void *Owner;

    TString ControlType;
    int ControlId;

protected:
	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
    virtual int OnMouseMove(int x, int y, int ButtonState, int KeyState);
	virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
	virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);
	virtual int OnRightUp(int x, int y, int ButtonState, int KeyState);
	virtual int OnRightDown(int x, int y, int ButtonState, int KeyState);

    virtual void NotifyResize();
    virtual void ChildChange();

    virtual void UpdateChild(TControl *control, int level);
    virtual void RedrawChild(TControl *control, int level);

    void Apply(TGraphicDevice *dev);
    void DeleteDev();

    void NotifyChanged();
    void NotifyChildChange();

    int IsRedrawEnabled();
    int IsDirty();
    void ResetDirty();
    void SetDirty();
    
    void Unload();
    void HandleUpdate();
    void HandleApply();
	void SetClipRect(TGraphicDevice *dev, int xmin, int ymin);
	void SetClipRect(TGraphicDevice *dev, int xmin, int ymin, int xmax, int ymax);
	void UpdateChildren(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	void RedrawChildren(TGraphicDevice *dev, int xmin, int ymin, int width, int height);

    int HasParent();
    void RedrawParent();

	void Protect();
	void Unprotect();

	TControlThread *GetControlThread();

private:
    void Init();
	void Add(TControl *Control);
	void Delete(TControl *Control);
    TDateTime GetRedrawTime();

	TDateTime *FDelay;

    int FXMin;
    int FYMin;
    int FWidth;
    int FHeight;

    int FEnabled;
    int FVisible;

    int FDirty;

    TControlThread *FDev;    
    TControl *FNext;    
    TControl *FControlList;
    TControl *FParent;
};

class TControlThread : public TThread
{
friend class TControl;
public:
	TControlThread();
	TControlThread(TGraphicDevice *dev);
    virtual ~TControlThread();

    void Apply(TGraphicDevice *dev);

    void GetSize(int *x, int *y) const;

    virtual TSprite *SetMouseMarker(TGraphicDevice *MouseBitmap, TGraphicDevice *MouseMask, int HotX, int HotY);
    virtual void RestoreMouseMarker(TSprite *Sprite);

    void EnumerateControls(void *Data, void (*CallBack)(void *Data, TControl *Control));
    TControl *GetControl(int ControlId);

protected:
	virtual void Protect();
	virtual void Unprotect();

    void Signal();
    void Add(TControl *control);
    void Delete(TControl *control);
    void Update(TControl *control);

	virtual void DefaultRedraw(TControl *control);
    virtual int IsRedrawEnabled();
    virtual void PutKey(char ch);

    TGraphicDevice *FGraphic;
    TGraphicDevice *FVbe;

    TWait FWait;
    TSignalDevice FSignal;
    TSection FListSection;       
    TSection FPaintSection;
    TControl *FControlList;

private:
    void Init();
};

class TDisplayControlThread : public TControlThread
{
public:
	TDisplayControlThread(const char *name, TGraphicDevice *dev);
    virtual ~TDisplayControlThread();

    void Add(TKeyboardDevice *Keyboard);
    void Add(TMouseDevice *Mouse);

    virtual TSprite *SetMouseMarker(TGraphicDevice *MouseBitmap, TGraphicDevice *MouseMask, int HotX, int HotY);
    virtual void RestoreMouseMarker(TSprite *Sprite);

    void SetDefaultRedrawTimeout(int millisec);
    void DisableRedraw();
    void EnableRedraw(int Delay);

    void NotifyClick(TControl *Control, int x, int y);

	void NotifyKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	void NotifyKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
    void NotifyMouseMove(int x, int y, int ButtonState, int KeyState);
	void NotifyLeftUp(int x, int y, int ButtonState, int KeyState);
    void NotifyLeftDown(int x, int y, int ButtonState, int KeyState);
	void NotifyRightUp(int x, int y, int ButtonState, int KeyState);
	void NotifyRightDown(int x, int y, int ButtonState, int KeyState);

	void (*OnKeyPressed)(TControlThread *dev, int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	void (*OnKeyReleased)(TControlThread *dev, int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	void (*OnMouseMove)(TControlThread *dev, int x, int y, int ButtonState, int KeyState);
	void (*OnLeftUp)(TControlThread *dev, int x, int y, int ButtonState, int KeyState);
	void (*OnLeftDown)(TControlThread *dev, int x, int y, int ButtonState, int KeyState);
	void (*OnRightUp)(TControlThread *dev, int x, int y, int ButtonState, int KeyState);
	void (*OnRightDown)(TControlThread *dev, int x, int y, int ButtonState, int KeyState);

protected:
	virtual void Protect();
	virtual void Unprotect();

    TDateTime GetRedrawTime();
    void HandleUpdate();
	virtual void Execute();

	virtual void DefaultRedraw(TControl *control);
    virtual int IsRedrawEnabled();
    virtual void PutKey(char ch);

    TKeyboardDevice *FKeyboard;
    TMouseDevice *FMouse; 
    TSprite *FMouseSprite;

    int DefaultRedrawTimeout;
    int Enabled;
    int EnableDelay;

private:
    void Init(const char *name);
};

#endif
