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
# scroll.h
# Scroll control class
#
########################################################################*/

#ifndef _SCROLLCTL_H
#define _SCROLLCTL_H

#include "bitdev.h"
#include "control.h"
#include "str.h"
#include "datetime.h"
#include "appini.h"

class TScrollControl;
class TVerScrollControl;
class THorScrollControl;

class TScrollParam
{
public:
    TScrollParam();

    int ShiftX;
    int ShiftY;

    int BorderWidth;

    int BackR;
    int BackG;
    int BackB;

    int ButtonR;
    int ButtonG;
    int ButtonB;

    int DrawR;
    int DrawG;
    int DrawB;

    int ShadowR;
    int ShadowG;
    int ShadowB;

    int BorderLightR;
    int BorderLightG;
    int BorderLightB;

    int BorderDarkR;
    int BorderDarkG;
    int BorderDarkB;
};

class TScrollFactory
{
public:
    TScrollFactory();
    virtual ~TScrollFactory();

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetWidth(int width);
    
    void SetUpShift(int x, int y);
    void SetDownShift(int x, int y);
    void SetDisabledShift(int x, int y);
    
    void SetUpBackColor(int r, int g, int b);
    void SetDownBackColor(int r, int g, int b);
    void SetDisabledBackColor(int r, int g, int b);
    
    void SetUpButtonColor(int r, int g, int b);
    void SetDownButtonColor(int r, int g, int b);
    void SetDisabledButtonColor(int r, int g, int b);
    
    void SetUpDrawColor(int r, int g, int b);
    void SetDownDrawColor(int r, int g, int b);
    void SetDisabledDrawColor(int r, int g, int b);
    
    void SetUpShadowColor(int r, int g, int b);
    void SetDownShadowColor(int r, int g, int b);
    void SetDisabledShadowColor(int r, int g, int b);

    void SetUpBorderWidth(int width);
    void SetDownBorderWidth(int width);
    void SetDisabledBorderWidth(int width);
    
    void SetUpLightBorderColor(int r, int g, int b);
    void SetDownLightBorderColor(int r, int g, int b);
    void SetDisabledLightBorderColor(int r, int g, int b);
    
    void SetUpDarkBorderColor(int r, int g, int b);
    void SetDownDarkBorderColor(int r, int g, int b);
    void SetDisabledDarkBorderColor(int r, int g, int b);

        TVerScrollControl *CreateVer(TControlThread *dev, int xstart, int ystart, int len);
        TVerScrollControl *CreateVer(TControl *control, int xstart, int ystart, int len);

        THorScrollControl *CreateHor(TControlThread *dev, int xstart, int ystart, int len);
        THorScrollControl *CreateHor(TControl *control, int xstart, int ystart, int len);

        TVerScrollControl *CreateVer(TControlThread *dev, TAppIniFile *Ini, const char *IniSection);
        TVerScrollControl *CreateVer(TControl *control, TAppIniFile *Ini, const char *IniSection);

        THorScrollControl *CreateHor(TControlThread *dev, TAppIniFile *Ini, const char *IniSection);
        THorScrollControl *CreateHor(TControl *control, TAppIniFile *Ini, const char *IniSection);

        TVerScrollControl *CreateVer(TControlThread *dev, const char *IniName, const char *IniSection);
        TVerScrollControl *CreateVer(TControl *control, const char *IniName, const char *IniSection);

        THorScrollControl *CreateHor(TControlThread *dev, const char *IniName, const char *IniSection);
        THorScrollControl *CreateHor(TControl *control, const char *IniName, const char *IniSection);
        
protected:
    void SetParam(TScrollControl *scroll);

    TScrollParam FUp;
    TScrollParam FDown;
    TScrollParam FDisabled;
    
    int FWidth;
};

class TScrollControl : public TControl
{
friend class TScrollFactory;
public:
    TScrollControl(TControlThread *dev);
    TScrollControl(TControl *control);

    static int IsScrollControl(TControl *control);

    void SetPageDist(long double dist);
    void SetScrollDist(long double dist);

    void SetScrollWidth(long double relwidth);
    long double GetScrollWidth();

    void SetScrollPos(long double relpos);
    long double GetScrollPos();

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetUpShift(int x, int y);
    void SetDownShift(int x, int y);
    void SetDisabledShift(int x, int y);
    
    void SetUpBackColor(int r, int g, int b);
    void SetDownBackColor(int r, int g, int b);
    void SetDisabledBackColor(int r, int g, int b);
    
    void SetUpButtonColor(int r, int g, int b);
    void SetDownButtonColor(int r, int g, int b);
    void SetDisabledButtonColor(int r, int g, int b);
    
    void SetUpDrawColor(int r, int g, int b);
    void SetDownDrawColor(int r, int g, int b);
    void SetDisabledDrawColor(int r, int g, int b);
    
    void SetUpShadowColor(int r, int g, int b);
    void SetDownShadowColor(int r, int g, int b);
    void SetDisabledShadowColor(int r, int g, int b);

    void SetUpBorderWidth(int width);
    void SetDownBorderWidth(int width);
    void SetDisabledBorderWidth(int width);
    
    void SetUpLightBorderColor(int r, int g, int b);
    void SetDownLightBorderColor(int r, int g, int b);
    void SetDisabledLightBorderColor(int r, int g, int b);
    
    void SetUpDarkBorderColor(int r, int g, int b);
    void SetDownDarkBorderColor(int r, int g, int b);
    void SetDisabledDarkBorderColor(int r, int g, int b);

protected:
    virtual ~TScrollControl();
    virtual void ChildChange();

    TScrollParam *GetParam(int state);
    void PaintButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);

    TScrollParam FUp;
    TScrollParam FDown;
    TScrollParam FDisabled;

    long double FScrollDist;
    long double FPageDist;

    int FScrollSize;
    int FMinScrollButton;
    int FCurrScrollButton;
    int FScrollPos;

    int FRedrawButtons;

private:
    void Init();
};

class TVerScrollControl : public TScrollControl
{
public:
    TVerScrollControl(TControlThread *dev, int xstart, int ystart, int width, int len);
    TVerScrollControl(TControl *control, int xstart, int ystart, int width, int len);
    TVerScrollControl(TControlThread *dev);
    TVerScrollControl(TControl *control);
    virtual ~TVerScrollControl();

protected:
        virtual void OnScrollUp();
        virtual void OnScrollDown();
        virtual void OnScrollPageUp();
        virtual void OnScrollPageDown();
        virtual void OnMove(long double relpos);

    virtual void NotifyResize();

    void ClearButtons();

    void DrawUpArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize);
    void DrawAliasedUpArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize);
    void PaintUpButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintUpButton(TGraphicDevice *dev, int xstart, int ystart);

    void DrawDownArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize);
    void DrawAliasedDownArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize);
    void PaintDownButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintDownButton(TGraphicDevice *dev, int xstart, int ystart);

    void PaintScrollArea(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintUpScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size);
    void PaintDownScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size);

    void DrawScrollLine(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize);
    void DrawAliasedScrollLines(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize);
    void PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart);
    
        virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);     
        virtual int OnMouseMove(int x, int y, int ButtonState, int KeyState);
        virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
        virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);

    int FWidth;
    int FSize;
    int FButtonSize;

    TDateTime FRepeatTime;

    long double FPressedBase;
    int FPressedCoord;

    int FScrollPressed;
    int FUpScrollPressed;
    int FDownScrollPressed;
    int FUpPressed;
    int FDownPressed;

private:
    void Init();
};

class THorScrollControl : public TScrollControl
{
public:
        THorScrollControl(TControlThread *dev, int xstart, int ystart, int width, int len);
        THorScrollControl(TControl *control, int xstart, int ystart, int width, int len);
        THorScrollControl(TControlThread *dev);
        THorScrollControl(TControl *control);
        virtual ~THorScrollControl();

protected:
        virtual void OnScrollLeft();
        virtual void OnScrollRight();
        virtual void OnScrollPageLeft();
        virtual void OnScrollPageRight();
        virtual void OnMove(long double relpos);

    virtual void NotifyResize();

    void ClearButtons();

    void DrawLeftArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize);
    void DrawAliasedLeftArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize);
    void PaintLeftButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintLeftButton(TGraphicDevice *dev, int xstart, int ystart);

    void DrawRightArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize);
    void DrawAliasedRightArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize);
    void PaintRightButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintRightButton(TGraphicDevice *dev, int xstart, int ystart);

    void PaintScrollArea(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintLeftScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size);
    void PaintRightScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size);

    void DrawScrollLine(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize);
    void DrawAliasedScrollLines(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize);
    void PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart);
    
        virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
        virtual int OnMouseMove(int x, int y, int ButtonState, int KeyState);
        virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
        virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);

    int FWidth;
    int FSize;
    int FButtonSize;

    TDateTime FRepeatTime;

    long double FPressedBase;
    int FPressedCoord;
    
    int FScrollPressed;
    int FLeftScrollPressed;
    int FRightScrollPressed;
    int FLeftPressed;
    int FRightPressed;

private:
    void Init();
};

#endif
