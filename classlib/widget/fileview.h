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
# fileview.h
# File-view control class
#
########################################################################*/

#ifndef _FILEVIEWCTL_H
#define _FILEVIEWCTL_H

#include "bitdev.h"
#include "panel.h"
#include "str.h"
#include "file.h"
#include "strarr.h"
#include "appini.h"

class TFileViewControl;

class TFileViewFactory : public TPanelFactory
{
public:
    TFileViewFactory();
    ~TFileViewFactory();

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int height);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);

        TFileViewControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        TFileViewControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TPanelControl *CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TPanelControl *CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TFileViewControl *CreateFileView(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TFileViewControl *CreateFileView(TControl *control, int xstart, int ystart, int xsize, int ysize);
                
protected:
    void Init();
    void SetDefault(TFileViewControl *fileview, int xstart, int ystart, int xsize, int ysize);

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    TFont *FFont;
};

class TFileViewControl : public TPanelControl
{
public:
    TFileViewControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TFileViewControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TFileViewControl(TControlThread *dev);
    TFileViewControl(TControl *control);
    virtual ~TFileViewControl();

    static int IsFileViewControl(TControl *control);

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int height);
    void SetFont(TFont *font);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);

    void Load(const char *FileName);
    void Load(TString &FileName);

    void GotoStart();
    void GotoEnd();
    void Goto(int row);
    
    virtual void ScrollDown();
    virtual void ScrollUp();
    virtual void PageDown();
    virtual void PageUp();
    virtual void VerMove(long double pos);
    
    virtual void ScrollLeft();
    virtual void ScrollRight();
    virtual void PageLeft();
    virtual void PageRight();
    virtual void HorMove(long double pos);
    
protected:
    void SetVerPos(int pos);
    void SetHorPos(int pos);
    void Load(int pos);
    
        virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
        virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);

    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);         
    virtual void NotifyResize();        

    void UpdateList();
    void UpdateVerPos();
    void UpdateHorPos();
    int AdjustHor();

    TStringArray FList;

private:
    void Init();
    void RedrawTrans();

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    TFont *FFont;
    TFile *FFile;

    int FRowHeight;
    int FRows;
    int FStartRow;
    int FStartCol;

    int FMaxWidth;
    int FControlWidth;
    
};

#endif
