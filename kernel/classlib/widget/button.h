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
# keyctl.h
# Basic key control class
#
########################################################################*/

#ifndef _KEYCTL_H
#define _KEYCTL_H

#include "bitdev.h"
#include "control.h"
#include "str.h"

class TButtonControl;

class TButtonFactoryParam
{
public:
    TButtonFactoryParam();

    TBitmapGraphicDevice *Left;
    TBitmapGraphicDevice *Mid;
    TBitmapGraphicDevice *Right;

    int ShiftX;
    int ShiftY;

    int TextR;
    int TextG;
    int TextB;

    int ShadowR;
    int ShadowG;
    int ShadowB;
};

class TButtonFactory
{
public:
    TButtonFactory();
    ~TButtonFactory();

    virtual void Set(const char *IniName, const char *IniSection);

    void DefineUp(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right);
    void DefineDown(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right);
    void DefineDisabled(TBitmapGraphicDevice *Left, TBitmapGraphicDevice *Mid, TBitmapGraphicDevice *Right);

    void SetWidth(int width);
    void SetUpShift(int x, int y);
    void SetDownShift(int x, int y);
    void SetDisabledShift(int x, int y);
    void SetFont(TFont *Font);
    void SetUpTextColor(int r, int g, int b);
    void SetDownTextColor(int r, int g, int b);
    void SetDisabledTextColor(int r, int g, int b);
    void SetUpShadowColor(int r, int g, int b);
    void SetDownShadowColor(int r, int g, int b);
    void SetDisabledShadowColor(int r, int g, int b);

	TButtonControl *Create(TControlThread *dev, const char *text, char ch, int xstart, int ystart);
	TButtonControl *Create(TControl *control, const char *text, char ch, int xstart, int ystart);

	TButtonControl *Create(TControlThread *dev, const char *text, char ch, const char *IniName, const char *IniSection);
	TButtonControl *Create(TControl *control, const char *text, char ch, const char *IniName, const char *IniSection);
	
protected:
    void CreateFont();
    void Delete(TButtonFactoryParam &Param);
    int GetHeight(TButtonFactoryParam &Param);
    int GetWidth(TButtonFactoryParam &Param, const char *text);
    void GetTextStart(TButtonFactoryParam &Param, const char *text, int *x, int *y);
	TBitmapGraphicDevice *CreateBitmap(TButtonFactoryParam &Param, int width);
	void DrawText(TButtonFactoryParam &Param, TBitmapGraphicDevice *bitmap, const char *text, int x, int y);
    TBitmapGraphicDevice *CreateButton(TButtonFactoryParam &Param, const char *text);

    TButtonFactoryParam FUp;
    TButtonFactoryParam FDown;
    TButtonFactoryParam FDisabled;
    
    TFont *FFont;
    int FWidth;
};

class TButtonControl : public TControl
{
public:
    TButtonControl(TControlThread *dev, const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, char ch, int xstart, int ystart);
    TButtonControl(TControl *control, const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, char ch, int xstart, int ystart);
    ~TButtonControl();

    void EnableKeepDown();
    void ChangeImage(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable);

protected:
	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
	virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);
	virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);

private:
    void Init(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable, char ch, int xstart, int ystart);
    void DeleteKeys();
    void UpdateKeys(const TBitmapGraphicDevice *Up, const TBitmapGraphicDevice *Down, const TBitmapGraphicDevice *Disable);

	char FKey;
    TBitmapGraphicDevice *FUp;
    TBitmapGraphicDevice *FDown;	
    TBitmapGraphicDevice *FDisabled;	
    int FPressed;
    int FStartX;
    int FStartY;
    int FSizeX;
    int FSizeY;
    int FKeepDown;
    int FActive;
};        

#endif
