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
# check.h
# Checkbox and radio control class
#
########################################################################*/

#ifndef _CHECKCTL_H
#define _CHECKCTL_H

#include "bitdev.h"
#include "panel.h"
#include "str.h"
#include "appini.h"

#define MAX_CHECK_ROWS    256

class TCheckControl;

class TCheckFactory : public TPanelFactory
{
public:
    TCheckFactory();
    ~TCheckFactory();

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int id, int height);
    void SetFont(int height);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);

        TCheckControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        TCheckControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TPanelControl *CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TPanelControl *CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TCheckControl *CreateCheck(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TCheckControl *CreateCheck(TControl *control, int xstart, int ystart, int xsize, int ysize);
                
protected:
    void Init();
    void SetDefault(TCheckControl *label, int xstart, int ystart, int xsize, int ysize);

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    int FFontId;
    int FFontHeight;
    TFont *FFont;
};

class TCheckControl : public TPanelControl
{
public:
    TCheckControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TCheckControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TCheckControl(TControlThread *dev);
    TCheckControl(TControl *control);
    virtual ~TCheckControl();

    static int IsCheckControl(TControl *control);

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);
    
    void SetFont(int height);
    void SetFont(int id, int height);
    void SetFont(TFont *font);
    TFont *GetFont();
    
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);
    void GetDrawColor(int *r, int *g, int *b);

    void SetText(TString &Text);
    void SetText(const char *Text);

    const char *GetText();

    void Check();
    void Uncheck();
    int IsChecked();

    virtual int GetMinHeight();
    
protected:
    virtual void NotifyResize();
    virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);
    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);     

    TSection FSection;

private:
    void Init();
    void ReformatText();

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    int FFontId;
    int FFontHeight;
    TFont *FFont;

    int FChecked;

    char *FOrgText;
    char *FText;
    char *FTextRow[MAX_CHECK_ROWS];    

};

#endif
