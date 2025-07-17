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
# button.h
# Button control class
#
########################################################################*/

#ifndef _BUTTONCTL_H
#define _BUTTONCTL_H

#include "bitdev.h"
#include "control.h"
#include "str.h"
#include "appini.h"

class TButtonControl;

class TButtonFactoryParam
{
public:
    TButtonFactoryParam();
        TButtonFactoryParam(const TButtonFactoryParam &source);
        TButtonFactoryParam &operator=(const TButtonFactoryParam &l);
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

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
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

        TButtonControl *Create(TControlThread *dev, const char *text, char ch, TAppIniFile *Ini, const char *IniSection);
        TButtonControl *Create(TControl *control, const char *text, char ch, TAppIniFile *Ini, const char *IniSection);

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

    static int IsButtonControl(TControl *control);

    void SetText(const char *text);
    void SetText(TString &text);
    const char *GetText();

    void SetUpperText(const char *text);
    void SetUpperText(TString &text);
    const char *GetUpperText();

    void SetLowerText(const char *text);
    void SetLowerText(TString &text);
    const char *GetLowerText();

    void SetKey(char key);

    void DefineUp(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineUp(TBitmapGraphicDevice *bitmap);

    void DefineDown(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineDown(TBitmapGraphicDevice *bitmap);

    void DefineDisabled(TBitmapGraphicDevice *bitmap, int x, int y);
    void DefineDisabled(TBitmapGraphicDevice *bitmap);

    virtual void Hide();

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void SetUpShift(int x, int y);
    void SetDownShift(int x, int y);
    void SetDisabledShift(int x, int y);

    void SetFont(int height);
    void SetFont(TFont *Font);
	void SetFontAliased(int aliased);
    TFont *GetFont();

    void SetUpperFont(int height);
    void SetUpperFont(TFont *Font);
	void SetUpperFontAliased(int aliased);
    TFont *GetUpperFont();

    void SetLowerFont(int height);
    void SetLowerFont(TFont *Font);
	void SetLowerFontAliased(int aliased);
    TFont *GetLowerFont();
    
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
    void DrawAliasedText(TGraphicDevice *dev, TButtonFactoryParam &Param, int xstart, int ystart, int xsize, int ysize, const char *text, TFont *font);
    void DrawNonAliasedText(TGraphicDevice *dev, TButtonFactoryParam &Param, int xstart, int ystart, int xsize, int ysize, const char *text, TFont *font);
    void DrawText(TGraphicDevice *dev, TButtonFactoryParam &Param, int xstart, int ystart, int xsize, int ysize);

    void PaintDescrButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);
    void PaintButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state);

    virtual void NotifyResize();

    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
    virtual int OnMouseMove(int x, int y, int ButtonState, int KeyState);
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
    TFont *FLowerFont;
    TFont *FUpperFont;

    TString FText;
    TString FLowerText;
    TString FUpperText;
        char FKey;
    int FPressed;
    int FKeepDown;
    int FActive;
	
	int FFontAliased;
	int FLowerFontAliased;
	int FUpperFontAliased;
};        

#endif
