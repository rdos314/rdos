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
# label.h
# Label control class
#
########################################################################*/

#ifndef _LABELCTL_H
#define _LABELCTL_H

#include "bitdev.h"
#include "panel.h"
#include "str.h"
#include "appini.h"

#define MAX_LABEL_ROWS    256

#define HOR_LEFT    0
#define HOR_CENTER  1
#define HOR_RIGHT   2

#define VER_TOP     0
#define VER_CENTER  1
#define VER_BOTTOM  2

class TLabelControl;

class TLabelFactory : public TPanelFactory
{
public:
    TLabelFactory();
    ~TLabelFactory();

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int id, int height);
    void SetFont(int height);
    void SetSpace(int xspace, int yspace);

    void SetDrawColor(int r, int g, int b);

    void ForceNoScale();
    void AllowScale();

    void AlignTopLeft();
    void AlignTop();
    void AlignTopRight();
    void AlignLeft();
    void AlignCenter();
    void AlignRight();
    void AlignBottomLeft();
    void AlignBottom();
    void AlignBottomRight();

        TLabelControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        TLabelControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TPanelControl *CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TPanelControl *CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize);

        virtual TLabelControl *CreateLabel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
        virtual TLabelControl *CreateLabel(TControl *control, int xstart, int ystart, int xsize, int ysize);

protected:
    void Init();
    void SetDefault(TLabelControl *label, int xstart, int ystart, int xsize, int ysize);

    int FHorAlign;
    int FVerAlign;

    int FStartX;
    int FStartY;

    int FAllowScale;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    int FFontId;
    int FFontHeight;
    TFont *FFont;
};

class TLabelControl : public TPanelControl
{
public:
    TLabelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TLabelControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TLabelControl(TControlThread *dev);
    TLabelControl(TControl *control);
    virtual ~TLabelControl();

    static int IsLabelControl(TControl *control);

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void ForceSingle();
    void AllowMultiple();

    void ForceNoScale();
    void AllowScale();

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

    void AlignTopLeft();
    void AlignTop();
    void AlignTopRight();
    void AlignLeft();
    void AlignCenter();
    void AlignRight();
    void AlignBottomLeft();
    void AlignBottom();
    void AlignBottomRight();

    void GetAlign(int *Hor, int *Ver);

    virtual int GetMinHeight();

protected:
    void SetScaleFont(int id, int height);

    virtual void NotifyResize();
    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);

    TSection FSection;

private:
    void Init();
    void ReformatText();

    int FForceSingle;
    int FAllowScale;

    int FHorAlign;
    int FVerAlign;

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    int FFontId;
    int FFontHeight;
    TFont *FFont;
    TFont *FScaleFont;

    char *FOrgText;
    char *FText;
    char *FTextRow[MAX_LABEL_ROWS];

};

#endif
