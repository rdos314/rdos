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
# button.h
# Button control class
#
########################################################################*/

#ifndef _BUTTONCTL_H
#define _BUTTONCTL_H

#include "bitdev.h"
#include "control.h"
#include "str.h"

class TButtonControl;

class TButtonFactoryParam
{
public:
    TButtonFactoryParam();
	TButtonFactoryParam(const TButtonFactoryParam &source);
    ~TButtonFactoryParam();

    void Delete();

    void Define(TBitmapGraphicDevice *bitmap, int x, int y);
    void Define(TBitmapGraphicDevice *bitmap);

    TBitmapGraphicDevice *Bitmap;
    int HotX;
    int HotY;

    int ShiftX;
    int ShiftY;

    int BorderWidth;

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

class TButtonFactory
{
public:
    TButtonFactory();
    ~TButtonFactory();

    virtual void Set(const char *IniName, const char *IniSection);

    void DefineUp(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineUp(TBitmapGraphicDevice *bitmap);

    void DefineDown(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineDown(TBitmapGraphicDevice *bitmap);

    void DefineDisabled(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineDisabled(TBitmapGraphicDevice *bitmap);

    void SetWidth(int width);
    void SetHeight(int height);

    void SetUpShift(int x, int y);
    void SetDownShift(int x, int y);
    void SetDisabledShift(int x, int y);

    void SetFont(int height);
    void SetFont(TFont *Font);
    
    void SetUpButtonColor(int r, int g, int b);
    void SetDownButtonColor(int r, int g, int b);
    void SetDisabledButtonColor(int r, int g, int b);

    void SetUpDrawColor(int r, int g, int b);
    void SetDownDrawColor(int r, int g, int b);
    void SetDisabledDrawColor(int r, int g, int b);

    void SetUpBorderWidth(int width);
    void SetDownBorderWidth(int width);
    void SetDisabledBorderWidth(int width);

    void SetUpShadowColor(int r, int g, int b);
    void SetDownShadowColor(int r, int g, int b);
    void SetDisabledShadowColor(int r, int g, int b);
    
    void SetUpLightBorderColor(int r, int g, int b);
    void SetDownLightBorderColor(int r, int g, int b);
    void SetDisabledLightBorderColor(int r, int g, int b);
    
    void SetUpDarkBorderColor(int r, int g, int b);
    void SetDownDarkBorderColor(int r, int g, int b);
    void SetDisabledDarkBorderColor(int r, int g, int b);

	TButtonControl *Create(TControlThread *dev, const char *text, char ch, int xstart, int ystart);
	TButtonControl *Create(TControl *control, const char *text, char ch, int xstart, int ystart);

	TButtonControl *Create(TControlThread *dev, const char *text, char ch, const char *IniName, const char *IniSection);
	TButtonControl *Create(TControl *control, const char *text, char ch, const char *IniName, const char *IniSection);
	
protected:
    void SetParam(TButtonControl *button);

    TButtonFactoryParam FUp;
    TButtonFactoryParam FDown;
    TButtonFactoryParam FDisabled;
    
    TFont *FFont;
    int FWidth;
    int FHeight;
};

class TButtonControl : public TControl
{
friend class TButtonFactory;
public:
    TButtonControl(TControlThread *dev, TFont *font, const char *text, char ch, int xstart, int ystart, int width, int height);
    TButtonControl(TControl *control, TFont *font, const char *text, char ch, int xstart, int ystart, int width, int height);
    TButtonControl(TControlThread *dev, const char *text, char ch);
    TButtonControl(TControl *control, const char *text, char ch);
    TButtonControl(TControlThread *dev);
    TButtonControl(TControl *control);
    virtual ~TButtonControl();

    void SetText(const char *text);
    void SetText(TString &text);

    void DefineUp(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineUp(TBitmapGraphicDevice *bitmap);

    void DefineDown(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineDown(TBitmapGraphicDevice *bitmap);

    void DefineDisabled(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineDisabled(TBitmapGraphicDevice *bitmap);

    virtual void Set(const char *IniName, const char *IniSection);

    void SetUpShift(int x, int y);
    void SetDownShift(int x, int y);
    void SetDisabledShift(int x, int y);

    void SetFont(int height);
    void SetFont(TFont *Font);
    
    void SetUpButtonColor(int r, int g, int b);
    void SetDownButtonColor(int r, int g, int b);
    void SetDisabledButtonColor(int r, int g, int b);

    void SetUpDrawColor(int r, int g, int b);
    void SetDownDrawColor(int r, int g, int b);
    void SetDisabledDrawColor(int r, int g, int b);

    void SetUpBorderWidth(int width);
    void SetDownBorderWidth(int width);
    void SetDisabledBorderWidth(int width);

    void SetUpShadowColor(int r, int g, int b);
    void SetDownShadowColor(int r, int g, int b);
    void SetDisabledShadowColor(int r, int g, int b);
    
    void SetUpLightBorderColor(int r, int g, int b);
    void SetDownLightBorderColor(int r, int g, int b);
    void SetDisabledLightBorderColor(int r, int g, int b);
    
    void SetUpDarkBorderColor(int r, int g, int b);
    void SetDownDarkBorderColor(int r, int g, int b);
    void SetDisabledDarkBorderColor(int r, int g, int b);

    void EnableKeepDown();
    void ForceUp();    

protected:
    TBitmapGraphicDevice *CreateBitmap(TButtonFactoryParam &Param);
    void CreateBitmapButtons();

    void CreateFont(int xsize, int ysize);
    void DrawAliasedText(TGraphicDevice *dev, TButtonFactoryParam &Param, int xstart, int ystart, int xsize, int ysize);

    void PaintDescrButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);

    virtual void NotifyResize();

	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	virtual int OnLeftUp(int x, int y, int ButtonState, int KeyState);
	virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);
	virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);

private:
    void Init(char ch);
    void SetSize(TFont *font, const char *text, int xsize, int ysize);

    TButtonFactoryParam FUp;
    TButtonFactoryParam FDown;
    TButtonFactoryParam FDisabled;

    TBitmapGraphicDevice *FUpBitmap;
    TBitmapGraphicDevice *FDownBitmap;
    TBitmapGraphicDevice *FDisabledBitmap;
    
    TFont *FFont;

    TString FText;
	char FKey;
    int FPressed;
    int FKeepDown;
    int FActive;
    int FRecreate;
};        

#endif
