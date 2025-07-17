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
#include "appini.h"

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
    virtual void Set(TAppIniFile *Ini, const char *IniSection);

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

    int GetWidth() const;
    int GetHeight() const;

    void PutKey(char ch);
    
    void Update();
    void Redraw();
    void Redraw(int millisec);
    void ClearRedraw();

    void SetTransparent();
    void ClearTransparent();
    int IsTransparent();

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

    void UpdateTransparent();
    void RedrawBackground(TGraphicDevice *dev);
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

    void SaveBackground();
    void RestoreBackground();

    TControlThread *GetControlThread();
    TBitmapGraphicDevice *FTransBitmap;
    int FTransChanged;

    TControl *GetSiblingControlById(int Index);

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

    int FTransparent;

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

    void SetBackground(TBitmapGraphicDevice *bitmap);

    virtual TSprite *SetMouseMarker(TGraphicDevice *MouseBitmap, TGraphicDevice *MouseMask, int HotX, int HotY);
    virtual void RestoreMouseMarker(TSprite *Sprite);

    void EnumerateControls(void *Data, void (*CallBack)(void *Data, TControl *Control));
    TControl *GetControl(int ControlId);

protected:
    virtual void Protect();
    virtual void Unprotect();

    void CreateBackground();
    void SaveBackground(TBitmapGraphicDevice *bitmap, int x, int y, int width, int height);
    void RestoreBackground(TBitmapGraphicDevice *bitmap, int x, int y, int width, int height);

    void Signal();
    void Add(TControl *control);
    void Delete(TControl *control);
    void Update(TControl *control);

    virtual void DefaultRedraw(TControl *control);
    virtual int IsRedrawEnabled();
    virtual void PutKey(char ch);

    TGraphicDevice *FGraphic;
    TGraphicDevice *FVbe;
    TBitmapGraphicDevice *FBackground;

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
