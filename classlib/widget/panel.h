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
# panel.h
# Panel control class
#
########################################################################*/

#ifndef _PANELCTL_H
#define _PANELCTL_H

#include "control.h"
#include "scroll.h"
#include "bitdev.h"
#include "str.h"
#include "appini.h"

class TPanelControl;

class TVerPanelScrollControl;
class THorPanelScrollControl;

class TPanelScrollFactory : public TScrollFactory
{
public:
    TPanelScrollFactory(int width);
    virtual ~TPanelScrollFactory();

        TVerPanelScrollControl *CreateVer(TPanelControl *panel);
        THorPanelScrollControl *CreateHor(TPanelControl *panel);

        int FScrollWidth;
};      

class TVerPanelScrollControl : public TVerScrollControl
{
    friend class TPanelControl;
public:
    TVerPanelScrollControl(TPanelControl *panel, int width);
    ~TVerPanelScrollControl();

    int GetWidth();

protected:
        virtual void OnScrollUp();
        virtual void OnScrollDown();
        virtual void OnScrollPageUp();
        virtual void OnScrollPageDown();
        virtual void OnMove(long double relpos);

    TPanelControl *FPanel;      
    int FCreateWidth;
};

class THorPanelScrollControl : public THorScrollControl
{
    friend class TPanelControl;
public:
    THorPanelScrollControl(TPanelControl *panel, int width);
    ~THorPanelScrollControl();

    int GetWidth();

protected:
        virtual void OnScrollLeft();
        virtual void OnScrollRight();
        virtual void OnScrollPageLeft();
        virtual void OnScrollPageRight();
        virtual void OnMove(long double relpos);

    TPanelControl *FPanel;      
    int FCreateWidth;
};

class TPanelFactory
{
public:
    TPanelFactory();
    ~TPanelFactory();

    void DefineScroll(TPanelScrollFactory *fact);

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetBackground(TBitmapGraphicDevice *bitmap, int xstart, int ystart);

    void SetBackColor(int r, int g, int b);
    void SetBackTransparent();
    void SetDisabledColor(int r, int g, int b);

    void SetUpperWidth(int width);
    void SetLowerWidth(int width);
    void SetLeftWidth(int width);
    void SetRightWidth(int width);
    void SetBorderWidth(int width);
    void SetBorderColor(int r, int g, int b);
    void SetBorderTransparent();

    TPanelControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TPanelControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);

    virtual TPanelControl *CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    virtual TPanelControl *CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize);
        
protected:
    void Init();
    void SetDefault(TPanelControl *panel, int xstart, int ystart, int xsize, int ysize);

    int FUpperWidth;
    int FLowerWidth;
    int FLeftWidth;
    int FRightWidth;
    
    int FBackR;
    int FBackG;
    int FBackB;

    int FBackTrans;

    int FBorderR;
    int FBorderG;
    int FBorderB;

    int FBorderTrans;

    TBitmapGraphicDevice *FBackground;

    int FBitStartX;
    int FBitStartY;

    int FDisabledColorUsed;

    int FDisabledR;
    int FDisabledG;
    int FDisabledB;

    TPanelScrollFactory *FScrollFact;
};

class TPanelControl : public TControl
{
    friend class TVerPanelScrollControl;
    friend class THorPanelScrollControl;
public:
    TPanelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TPanelControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TPanelControl(TControlThread *dev);
    TPanelControl(TControl *control);
    ~TPanelControl();

    static int IsPanel(TControl *control);

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void DefineScroll(TPanelScrollFactory *fact);
    void DefineScroll(int width);
    void DefineScroll(TAppIniFile *Ini, const char *IniSection);
    void DefineScroll(const char *IniName, const char *IniSection);

    void EnableVerScroll();
    void EnableHorScroll();

    void DisableVerScroll();
    void DisableHorScroll();

    void SetVerLeft();
    void SetVerRight();
    void SetHorTop();
    void SetHorBottom();

    void SetBackground(TBitmapGraphicDevice *bitmap, int xstart, int ystart);

    void SetBackColor(int r, int g, int b);
    void GetBackColor(int *r, int *g, int *b);

    void SetBackTransparent();
    void SetDisabledColor(int r, int g, int b);

    void SetUpperWidth(int width);
    void SetLowerWidth(int width);
    void SetLeftWidth(int width);
    void SetRightWidth(int width);
    void SetBorderWidth(int width);
    void SetBorderColor(int r, int g, int b);
    void SetBorderTransparent();

    virtual int GetMinHeight();

    void SetBackColor(TGraphicDevice *dev);

    void SetKey(char key);

protected:
    virtual void ScrollLeft();
    virtual void ScrollRight();
    virtual void PageLeft();
    virtual void PageRight();
    virtual void HorMove(long double pos);

    virtual void ScrollUp();
    virtual void ScrollDown();
    virtual void PageUp();
    virtual void PageDown();
    virtual void VerMove(long double pos);

    virtual void UpdateChild(TControl *control, int level);
    virtual void RedrawChild(TControl *control, int level);

    virtual void ChildChange();

    virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);
    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);

    void UpdateScroll();
    void GetInner(int *xstart, int *ystart, int *xdiff, int *ydiff) const;
    int IsInsidePanel(int x, int y) const;

    THorPanelScrollControl *FHorScroll;
    TVerPanelScrollControl *FVerScroll;

    int FRedrawBack;
    
    int FBackR;
    int FBackG;
    int FBackB;

        char FKey;

private:
    void Init(int border);

    int FUpperWidth;
    int FLowerWidth;
    int FLeftWidth;
    int FRightWidth;

    int FBorderR;
    int FBorderG;
    int FBorderB;

    int FBorderTrans;

    TBitmapGraphicDevice *FBackground;

    int FBitStartX;
    int FBitStartY;

    int FDisabledColorUsed;

    int FDisabledR;
    int FDisabledG;
    int FDisabledB;

    int FScrollChanged;

    int FVerLeft;
    int FHorUp;
};        

#endif
