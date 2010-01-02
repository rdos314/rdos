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

    virtual void Set(const char *IniName, const char *IniSection);

    void DefineScroll(TPanelScrollFactory *fact);
    void DefineScroll(int width);
    void DefineScroll(const char *IniName, const char *IniSection);

    void EnableVerScroll();
    void EnableHorScroll();

    void DisableVerScroll();
    void DisableHorScroll();

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

    virtual int GetMinHeight();

    void SetBackColor(TGraphicDevice *dev);

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

    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);

    void UpdateScroll();
    void GetInner(int *xstart, int *ystart, int *xdiff, int *ydiff);
    int IsInsidePanel(int x, int y) const;

    int FBackTrans;

    THorPanelScrollControl *FHorScroll;
    TVerPanelScrollControl *FVerScroll;

private:
    void Init(int border);

    int FUpperWidth;
    int FLowerWidth;
    int FLeftWidth;
    int FRightWidth;
    
    int FBackR;
    int FBackG;
    int FBackB;

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
};        

#endif
