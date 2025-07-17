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
# listbox.h
# Listbox control class
#
########################################################################*/

#ifndef _LISTBOX_CTL_H
#define _LISTBOX_CTL_H

#include "bitdev.h"
#include "panel.h"
#include "strarr.h"
#include "appini.h"

class TListControl;

class TListFactory : public TPanelFactory
{
public:
    TListFactory();
    ~TListFactory();

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int height);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);
    void SetSelectedDrawColor(int r, int g, int b);
    void SetSelectedBackColor(int r, int g, int b);

        TListControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        TListControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TPanelControl *CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TPanelControl *CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TListControl *CreateList(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TListControl *CreateList(TControl *control, int xstart, int ystart, int xsize, int ysize);
                
protected:
    void Init();
    void SetDefault(TListControl *fileview, int xstart, int ystart, int xsize, int ysize);

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    int FSelectedDrawR;
    int FSelectedDrawG;
    int FSelectedDrawB;

    int FSelectedBackR;
    int FSelectedBackG;
    int FSelectedBackB;

    TFont *FFont;
};

class TListControl : public TPanelControl
{
public:
    TListControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TListControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TListControl(TControlThread *dev);
    TListControl(TControl *control);
    ~TListControl();

    static int IsListControl(TControl *control);

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int height);
    void SetFont(TFont *font);

    TFont *GetFont();

    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);
    void SetSelectedDrawColor(int r, int g, int b);
    void SetSelectedBackColor(int r, int g, int b);

    void Clear();

    void Add(const char *str);
    void Add(TString &str);

    void Add(int pos, const char *str);
    void Add(int pos, TString &str);

    void Remove();
    void Remove(int pos);

    int GetSelected();
    int GetSize();

    TString Get(int pos);

    void GotoStart();
    void GotoEnd();
    void Goto(int row);
    
protected:
    void SetPos(int pos);
    void SetSelected(int pos);

    void ArrowUp();
    void ArrowDown();
    void KeyPageDown();
    void KeyPageUp();
    
    virtual void ScrollDown();
    virtual void ScrollUp();
    virtual void PageDown();
    virtual void PageUp();
    virtual void VerMove(long double pos);

        virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
        virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
        virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
        virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);

    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);         
    virtual void NotifyResize();        

    void RedrawTrans();
    void UpdateList();
    void UpdatePos();

    TStringArray FList;

private:
    void Init();

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    int FSelectedDrawR;
    int FSelectedDrawG;
    int FSelectedDrawB;

    int FSelectedBackR;
    int FSelectedBackG;
    int FSelectedBackB;

    TFont *FFont;

    int FRowHeight;
    
    int FSelected;
    int FRows;
    int FStartRow;
    
};

#endif
