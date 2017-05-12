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
# check.h
# Checkbox and radio control class
#
########################################################################*/

#ifndef _CHECKCTL_H
#define _CHECKCTL_H

#include "bitdev.h"
#include "panel.h"
#include "str.h"
#include "ini.h"

#define MAX_CHECK_ROWS    256

class TCheckControl;

class TCheckFactory : public TPanelFactory
{
public:
    TCheckFactory();
    ~TCheckFactory();

    virtual void Set(TIniFile *Ini, const char *IniSection);
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

    virtual void Set(TIniFile *Ini, const char *IniSection);
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
