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
# listbox.h
# Listbox control class
#
########################################################################*/

#ifndef _LISTBOX_CTL_H
#define _LISTBOX_CTL_H

#include "bitdev.h"
#include "panel.h"
#include "strarr.h"

class TListControl;

class TListFactory : public TPanelFactory
{
public:
    TListFactory();
    ~TListFactory();

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

    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int height);
    void SetFont(TFont *font);
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
