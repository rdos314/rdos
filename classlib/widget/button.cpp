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
 # button.cpp
 # Button control class
 #
 ########################################################################*/

#include <string.h>

#include "button.h"

#define FALSE   0
#define TRUE    !FALSE

#define STATE_UP        1
#define STATE_DOWN      2
#define STATE_DISABLED  3

char DecodeKey(const char *key);

/*##########################################################################
#
#   Name       : TButtonFactoryParam::TButtonFactoryParam
#
#   Purpose....: Button factory parameters constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactoryParam::TButtonFactoryParam()
{
    Bitmap = 0;
    HotX = 0;
    HotY = 0;

    ShiftX = 0;
    ShiftY = 0;

    BorderWidth = 1;
    
    ButtonR = 205;
    ButtonG = 220;
    ButtonB = 255;

    DrawR = 0;
    DrawG = 0;
    DrawB = 0;

    ShadowR = 210;
    ShadowG = 210;
    ShadowB = 210;

    BorderLightR = 255;
    BorderLightG = 255;
    BorderLightB = 255;

    BorderDarkR = 180;
    BorderDarkG = 200;
    BorderDarkB = 255;
}

/*##########################################################################
#
#   Name       : TButtonFactoryParam::TButtonFactoryParam
#
#   Purpose....: Button factory param copy constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactoryParam::TButtonFactoryParam(const TButtonFactoryParam &src)
{
    if (src.Bitmap)
        Bitmap = new TBitmapGraphicDevice(*src.Bitmap);
    else
        Bitmap = 0;

    HotX = src.HotX;
    HotY = src.HotY;

    ShiftX = src.ShiftX;
    ShiftY = src.ShiftY;

    BorderWidth = src.BorderWidth;

    ButtonR = src.ButtonR;
    ButtonG = src.ButtonG;
    ButtonB = src.ButtonB;

    DrawR = src.DrawR;
    DrawG = src.DrawG;
    DrawB = src.DrawB;

    ShadowR = src.ShadowR;
    ShadowG = src.ShadowG;
    ShadowB = src.ShadowB;

    BorderLightR = src.BorderLightR;
    BorderLightG = src.BorderLightG;
    BorderLightB = src.BorderLightB;

    BorderDarkR = src.BorderDarkR;
    BorderDarkG = src.BorderDarkG;
    BorderDarkB = src.BorderDarkB;
}

/*##########################################################################
#
#   Name       : TButtonFactoryParam::operator=
#
#   Purpose....: Asignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactoryParam &TButtonFactoryParam::operator=(const TButtonFactoryParam &src)
{
    if (this != &src)
    {
        if (src.Bitmap)
            Bitmap = new TBitmapGraphicDevice(*src.Bitmap);
        else
            Bitmap = 0;

        HotX = src.HotX;
        HotY = src.HotY;

        ShiftX = src.ShiftX;
        ShiftY = src.ShiftY;

        BorderWidth = src.BorderWidth;

        ButtonR = src.ButtonR;
        ButtonG = src.ButtonG;
        ButtonB = src.ButtonB;

        DrawR = src.DrawR;
        DrawG = src.DrawG;
        DrawB = src.DrawB;

        ShadowR = src.ShadowR;
        ShadowG = src.ShadowG;
        ShadowB = src.ShadowB;

        BorderLightR = src.BorderLightR;
        BorderLightG = src.BorderLightG;
        BorderLightB = src.BorderLightB;

        BorderDarkR = src.BorderDarkR;
        BorderDarkG = src.BorderDarkG;
        BorderDarkB = src.BorderDarkB;
    }
    return *this;
}

/*##########################################################################
#
#   Name       : TButtonFactoryParam::~TButtonFactoryParam
#
#   Purpose....: Button factory parameters destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactoryParam::~TButtonFactoryParam()
{
    if (Bitmap)
        delete Bitmap;
    Bitmap = 0;
}

/*##########################################################################
#
#   Name       : TButtonFactoryParam::Delete
#
#   Purpose....: Delete bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactoryParam::Delete()
{
    if (Bitmap)
        delete Bitmap;
    Bitmap = 0;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Define
#
#   Purpose....: Define button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactoryParam::Define(TBitmapGraphicDevice *bitmap, int x, int y)
{
    Delete();
    
    Bitmap = new TBitmapGraphicDevice(*bitmap);
        HotX = x;
    HotY = y;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Define
#
#   Purpose....: Define button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactoryParam::Define(TBitmapGraphicDevice *bitmap)
{
    int x, y;

    x = bitmap->GetWidth() / 2;
    y = bitmap->GetHeight() / 2;

    Define(bitmap, x, y);
}

/*##########################################################################
#
#   Name       : TButtonFactory::TButtonFactory
#
#   Purpose....: Button factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactory::TButtonFactory()
{
    FHeight = 0;
    FWidth = 0;
    FFont = 0;

    FDown.ShiftX = 2;
    FDown.ShiftY = 2;

    FDisabled.BorderWidth = 0;
    
        FDisabled.ButtonR = 128;
        FDisabled.ButtonG = 128;
        FDisabled.ButtonB = 128;

        FDisabled.ShadowR = 128;
        FDisabled.ShadowG = 128;
        FDisabled.ShadowB = 128;

        FDisabled.DrawR = 150;
        FDisabled.DrawG = 150;
        FDisabled.DrawB = 150;
}

/*##########################################################################
#
#   Name       : TButtonFactory::~TButtonFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonFactory::~TButtonFactory()
{
    if (FFont)
        delete FFont;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Width", str, 255))
        FWidth = atoi(str);


    if (Ini->ReadVar("Font.Size", str, 255))
    {
        size = atoi(str);

        if (size)
        {
            if (FFont)
                delete FFont;

            FFont = new TFont(size);
        }
    }

    if (Ini->ReadVar("Up.Shift.X", str, 255))
        FUp.ShiftX = atoi(str);

    if (Ini->ReadVar("Up.Shift.Y", str, 255))
        FUp.ShiftY = atoi(str);


    if (Ini->ReadVar("Down.Shift.X", str, 255))
        FDown.ShiftX = atoi(str);

    if (Ini->ReadVar("Down.Shift.Y", str, 255))
        FDown.ShiftY = atoi(str);


    if (Ini->ReadVar("Disabled.Shift.X", str, 255))
        FDisabled.ShiftX = atoi(str);

    if (Ini->ReadVar("Disabled.Shift.Y", str, 255))
        FDisabled.ShiftY = atoi(str);


    if (Ini->ReadVar("Up.BorderWidth", str, 255))
        FUp.BorderWidth = atoi(str);

    if (Ini->ReadVar("Down.BorderWidth", str, 255))
        FDown.BorderWidth = atoi(str);

    if (Ini->ReadVar("Disabled.BorderWidth", str, 255))
        FDisabled.BorderWidth = atoi(str);


    if (Ini->ReadVar("Up.DrawColor.R", str, 255))
        FUp.DrawR = atoi(str);

    if (Ini->ReadVar("Up.DrawColor.G", str, 255))
        FUp.DrawG = atoi(str);

    if (Ini->ReadVar("Up.DrawColor.B", str, 255))
        FUp.DrawB = atoi(str);


    if (Ini->ReadVar("Down.DrawColor.R", str, 255))
        FDown.DrawR = atoi(str);

    if (Ini->ReadVar("Down.DrawColor.G", str, 255))
        FDown.DrawG = atoi(str);

    if (Ini->ReadVar("Down.DrawColor.B", str, 255))
        FDown.DrawB = atoi(str);


    if (Ini->ReadVar("Disabled.DrawColor.R", str, 255))
        FDisabled.DrawR = atoi(str);

    if (Ini->ReadVar("Disabled.DrawColor.G", str, 255))
        FDisabled.DrawG = atoi(str);

    if (Ini->ReadVar("Disabled.DrawColor.B", str, 255))
        FDisabled.DrawB = atoi(str);


    if (Ini->ReadVar("Up.ShadowColor.R", str, 255))
        FUp.ShadowR = atoi(str);

    if (Ini->ReadVar("Up.ShadowColor.G", str, 255))
        FUp.ShadowG = atoi(str);

    if (Ini->ReadVar("Up.ShadowColor.B", str, 255))
        FUp.ShadowB = atoi(str);


    if (Ini->ReadVar("Down.ShadowColor.R", str, 255))
        FDown.ShadowR = atoi(str);

    if (Ini->ReadVar("Down.ShadowColor.G", str, 255))
        FDown.ShadowG = atoi(str);

    if (Ini->ReadVar("Down.ShadowColor.B", str, 255))
        FDown.ShadowB = atoi(str);


    if (Ini->ReadVar("Disabled.ShadowColor.R", str, 255))
        FDisabled.ShadowR = atoi(str);

    if (Ini->ReadVar("Disabled.ShadowColor.G", str, 255))
        FDisabled.ShadowG = atoi(str);

    if (Ini->ReadVar("Disabled.ShadowColor.B", str, 255))
        FDisabled.ShadowB = atoi(str);


    if (Ini->ReadVar("Up.ButtonColor.R", str, 255))
        FUp.ButtonR = atoi(str);

    if (Ini->ReadVar("Up.ButtonColor.G", str, 255))
        FUp.ButtonG = atoi(str);

    if (Ini->ReadVar("Up.ButtonColor.B", str, 255))
        FUp.ButtonB = atoi(str);


    if (Ini->ReadVar("Down.ButtonColor.R", str, 255))
        FDown.ButtonR = atoi(str);

    if (Ini->ReadVar("Down.ButtonColor.G", str, 255))
        FDown.ButtonG = atoi(str);

    if (Ini->ReadVar("Down.ButtonColor.B", str, 255))
        FDown.ButtonB = atoi(str);


    if (Ini->ReadVar("Disabled.ButtonColor.R", str, 255))
        FDisabled.ButtonR = atoi(str);

    if (Ini->ReadVar("Disabled.ButtonColor.G", str, 255))
        FDisabled.ButtonG = atoi(str);

    if (Ini->ReadVar("Disabled.ButtonColor.B", str, 255))
        FDisabled.ButtonB = atoi(str);


    if (Ini->ReadVar("Up.BorderLightColor.R", str, 255))
        FUp.BorderLightR = atoi(str);

    if (Ini->ReadVar("Up.BorderLightColor.G", str, 255))
        FUp.BorderLightG = atoi(str);

    if (Ini->ReadVar("Up.BorderLightColor.B", str, 255))
        FUp.BorderLightB = atoi(str);


    if (Ini->ReadVar("Down.BorderLightColor.R", str, 255))
        FDown.BorderLightR = atoi(str);

    if (Ini->ReadVar("Down.BorderLightColor.G", str, 255))
        FDown.BorderLightG = atoi(str);

    if (Ini->ReadVar("Down.BorderLightColor.B", str, 255))
        FDown.BorderLightB = atoi(str);


    if (Ini->ReadVar("Disabled.BorderLightColor.R", str, 255))
        FDisabled.BorderLightR = atoi(str);

    if (Ini->ReadVar("Disabled.BorderLightColor.G", str, 255))
        FDisabled.BorderLightG = atoi(str);

    if (Ini->ReadVar("Disabled.BorderLightColor.B", str, 255))
        FDisabled.BorderLightB = atoi(str);


    if (Ini->ReadVar("Up.BorderDarkColor.R", str, 255))
        FUp.BorderDarkR = atoi(str);

    if (Ini->ReadVar("Up.BorderDarkColor.G", str, 255))
        FUp.BorderDarkG = atoi(str);

    if (Ini->ReadVar("Up.BorderDarkColor.B", str, 255))
        FUp.BorderDarkB = atoi(str);


    if (Ini->ReadVar("Down.BorderDarkColor.R", str, 255))
        FDown.BorderDarkR = atoi(str);

    if (Ini->ReadVar("Down.BorderDarkColor.G", str, 255))
        FDown.BorderDarkG = atoi(str);

    if (Ini->ReadVar("Down.BorderDarkColor.B", str, 255))
        FDown.BorderDarkB = atoi(str);


    if (Ini->ReadVar("Disabled.BorderDarkColor.R", str, 255))
        FDisabled.BorderDarkR = atoi(str);

    if (Ini->ReadVar("Disabled.BorderDarkColor.G", str, 255))
        FDisabled.BorderDarkG = atoi(str);

    if (Ini->ReadVar("Disabled.BorderDarkColor.B", str, 255))
        FDisabled.BorderDarkB = atoi(str);

}

/*##########################################################################
#
#   Name       : TButtonFactory::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineUp
#
#   Purpose....: Define up button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineUp(TBitmapGraphicDevice *bitmap, int x, int y)
{        
    FUp.Define(bitmap, x, y);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineUp
#
#   Purpose....: Define up button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineUp(TBitmapGraphicDevice *bitmap)
{        
    FUp.Define(bitmap);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineDown
#
#   Purpose....: Define down button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineDown(TBitmapGraphicDevice *bitmap, int x, int y)
{        
    FDown.Define(bitmap, x, y);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineDown
#
#   Purpose....: Define down button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineDown(TBitmapGraphicDevice *bitmap)
{        
    FDown.Define(bitmap);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineDisabled
#
#   Purpose....: Define disabled button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineDisabled(TBitmapGraphicDevice *bitmap, int x, int y)
{        
    FDisabled.Define(bitmap, x, y);
}

/*##########################################################################
#
#   Name       : TButtonFactory::DefineDisabled
#
#   Purpose....: Define disabled button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::DefineDisabled(TBitmapGraphicDevice *bitmap)
{        
    FDisabled.Define(bitmap);
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetWidth
#
#   Purpose....: Set fixed button width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetWidth(int width)
{
    FWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetHeight
#
#   Purpose....: Set fixed button height
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetHeight(int height)
{
    FHeight = height;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpShift
#
#   Purpose....: Set text shift for up-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpShift(int x, int y)
{
    FUp.ShiftX = x;
    FUp.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownShift
#
#   Purpose....: Set text shift for down-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownShift(int x, int y)
{
    FDown.ShiftX = x;
    FDown.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledShift
#
#   Purpose....: Set text shift for disabled-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledShift(int x, int y)
{
    FDisabled.ShiftX = x;
    FDisabled.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetFont(int height)
{
    if (FFont)
        delete FFont;

    FFont = new TFont(height);
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetFont(TFont *Font)
{
    if (FFont)
        delete FFont;

    FFont = new TFont(*Font);
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpButtonColor
#
#   Purpose....: Set button color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpButtonColor(int r, int g, int b)
{
    FUp.ButtonR = r;
    FUp.ButtonG = g;
    FUp.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownButtonColor
#
#   Purpose....: Set button color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownButtonColor(int r, int g, int b)
{
    FDown.ButtonR = r;
    FDown.ButtonG = g;
    FDown.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledButtonColor
#
#   Purpose....: Set button color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledButtonColor(int r, int g, int b)
{
    FDisabled.ButtonR = r;
    FDisabled.ButtonG = g;
    FDisabled.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpDrawColor
#
#   Purpose....: Set draw color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpDrawColor(int r, int g, int b)
{
    FUp.DrawR = r;
    FUp.DrawG = g;
    FUp.DrawB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownDrawColor
#
#   Purpose....: Set draw color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownDrawColor(int r, int g, int b)
{
    FDown.DrawR = r;
    FDown.DrawG = g;
    FDown.DrawB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledDrawColor
#
#   Purpose....: Set draw color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledDrawColor(int r, int g, int b)
{
    FDisabled.DrawR = r;
    FDisabled.DrawG = g;
    FDisabled.DrawB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpShadowColor
#
#   Purpose....: Set shadow color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpShadowColor(int r, int g, int b)
{
    FUp.ShadowR = r;
    FUp.ShadowG = g;
    FUp.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownShadowColor
#
#   Purpose....: Set shadow color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownShadowColor(int r, int g, int b)
{
    FDown.ShadowR = r;
    FDown.ShadowG = g;
    FDown.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledShadowColor
#
#   Purpose....: Set shadow color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledShadowColor(int r, int g, int b)
{
    FDisabled.ShadowR = r;
    FDisabled.ShadowG = g;
    FDisabled.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpBorderWidth
#
#   Purpose....: Set up button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpBorderWidth(int width)
{
    FUp.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownBorderWidth
#
#   Purpose....: Set down button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownBorderWidth(int width)
{
    FDown.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledBorderWidth
#
#   Purpose....: Set disabled button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledBorderWidth(int width)
{
    FDisabled.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpLightBorderColor
#
#   Purpose....: Set light border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpLightBorderColor(int r, int g, int b)
{
    FUp.BorderLightR = r;
    FUp.BorderLightG = g;
    FUp.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownLightBorderColor
#
#   Purpose....: Set light border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownLightBorderColor(int r, int g, int b)
{
    FDown.BorderLightR = r;
    FDown.BorderLightG = g;
    FDown.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledLightBorderColor
#
#   Purpose....: Set light border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledLightBorderColor(int r, int g, int b)
{
    FDisabled.BorderLightR = r;
    FDisabled.BorderLightG = g;
    FDisabled.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetUpDarkBorderColor
#
#   Purpose....: Set drak border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetUpDarkBorderColor(int r, int g, int b)
{
    FUp.BorderDarkR = r;
    FUp.BorderDarkG = g;
    FUp.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDownDarkBorderColor
#
#   Purpose....: Set dark border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDownDarkBorderColor(int r, int g, int b)
{
         FDown.BorderDarkR = r;
         FDown.BorderDarkG = g;
         FDown.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetDisabledDarkBorderColor
#
#   Purpose....: Set dark border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetDisabledDarkBorderColor(int r, int g, int b)
{
         FDisabled.BorderDarkR = r;
         FDisabled.BorderDarkG = g;
         FDisabled.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TButtonFactory::SetParam
#
#   Purpose....: Set parameters for scroll-control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonFactory::SetParam(TButtonControl *button)
{
        button->FUp = FUp;
        button->FDown = FDown;
        button->FDisabled = FDisabled;

    if (FFont)
        button->SetFont(FFont);

    button->CreateBitmapButtons();
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControlThread *dev, const char *text, char ch, int xstart, int ystart)
{
    TButtonControl *button;

    button = new TButtonControl(dev, FFont, text, ch, xstart, ystart, FWidth, FHeight);

    SetParam(button);

    return button;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControl *control, const char *text, char ch, int xstart, int ystart)
{
    TButtonControl *button;

    button = new TButtonControl(control, FFont, text, ch, xstart, ystart, FWidth, FHeight);

    SetParam(button);

    return button;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControlThread *dev, const char *text, char ch, TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;
    TButtonControl *button;
    int x = 0;
    int y = 0;
    int width = FWidth;
    int height = FHeight;

    Ini->GotoSection(IniSection);


    if (Ini->ReadVar("Font.Size", str, 255))
    {
        size = atoi(str);

        if (size)
        {
            if (FFont)
                delete FFont;

            FFont = new TFont(size);
        }
    }

    if (Ini->ReadVar("Start.X", str, 255))
        x = atoi(str);

    if (Ini->ReadVar("Start.Y", str, 255))
        y = atoi(str);

    if (Ini->ReadVar("Size.X", str, 255))
        width = atoi(str);

    if (Ini->ReadVar("Size.Y", str, 255))
        height = atoi(str);

    button = new TButtonControl(dev, FFont, text, ch, x, y, width, height);

    SetParam(button);

    if (Ini->ReadVar("LowerFont.Size", str, 255))
    {
        size = atoi(str);
        if (size)
            button->SetLowerFont(size);
    }

    if (Ini->ReadVar("UpperFont.Size", str, 255))
    {
        size = atoi(str);
        if (size)
            button->SetUpperFont(size);
    }
	
	if (Ini->ReadVar("Font.Aliased", str, 255))
        button->SetFontAliased(atoi(str));
	
	if (Ini->ReadVar("LowerFont.Aliased", str, 255))
        button->SetLowerFontAliased(atoi(str));
	
	if (Ini->ReadVar("UpperFont.Aliased", str, 255))
        button->SetUpperFontAliased(atoi(str));

    return button;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControl *control, const char *text, char ch, TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;
    TButtonControl *button;
    int x = 0;
    int y = 0;
    int width = FWidth;
    int height = FHeight;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Font.Size", str, 255))
    {
        size = atoi(str);

        if (size)
        {
            if (FFont)
                delete FFont;

            FFont = new TFont(size);
        }
    }

    if (Ini->ReadVar("Start.X", str, 255))
        x = atoi(str);

    if (Ini->ReadVar("Start.Y", str, 255))
        y = atoi(str);

    if (Ini->ReadVar("Size.X", str, 255))
        width = atoi(str);

    if (Ini->ReadVar("Size.Y", str, 255))
        height = atoi(str);

    button = new TButtonControl(control, FFont, text, ch, x, y, width, height);

    SetParam(button);

    if (Ini->ReadVar("LowerFont.Size", str, 255))
    {
        size = atoi(str);
        if (size)
            button->SetLowerFont(size);
    }

    if (Ini->ReadVar("UpperFont.Size", str, 255))
    {
        size = atoi(str);
        if (size)
            button->SetUpperFont(size);
    }
	
	if (Ini->ReadVar("Font.Aliased", str, 255))
        button->SetFontAliased(atoi(str));
	
	if (Ini->ReadVar("LowerFont.Aliased", str, 255))
        button->SetLowerFontAliased(atoi(str));
	
	if (Ini->ReadVar("UpperFont.Aliased", str, 255))
        button->SetUpperFontAliased(atoi(str));

    return button;
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControlThread *dev, const char *text, char ch, const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    return Create(dev, text, ch, &Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TButtonFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TButtonFactory::Create(TControl *control, const char *text, char ch, const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    return Create(control, text, ch, &Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControlThread *dev, TFont *font, const char *text, char ch, int xstart, int ystart, int xsize, int ysize)
  : TControl(dev),
    FText(text)
{
    Init(ch);

    FFont = new TFont(*font);

    SetSize(font, text, xsize, ysize);
    Move(xstart, ystart);
    Enable();
    Show();
}

/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControl *control, TFont *font, const char *text, char ch, int xstart, int ystart, int xsize, int ysize)
  : TControl(control),
    FText(text)
{
    Init(ch);

    FFont = new TFont(*font);

    SetSize(font, text, xsize, ysize);
    Move(xstart, ystart);
    Enable();
    Show();
}

/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControlThread *dev, const char *text, char ch)
  : TControl(dev),
    FText(text)
{
    Init(ch);
}

/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControl *control, const char *text, char ch)
  : TControl(control),
    FText(text)
{
    Init(ch);
}

/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControlThread *dev)
  : TControl(dev)
{
    Init(0);
}

/*##########################################################################
#
#   Name       : TButtonControl::TButtonControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::TButtonControl(TControl *control)
  : TControl(control)
{
    Init(0);
}

/*##########################################################################
#
#   Name       : TButtonControl::~TButtonControl
#
#   Purpose....: Key control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl::~TButtonControl()
{
    if (FFont)
        delete FFont;

    if (FLowerFont)
        delete FLowerFont;

    if (FUpperFont)
        delete FUpperFont;

    if (FUpBitmap)
        delete FUpBitmap;

    if (FDownBitmap)
        delete FDownBitmap;

    if (FDisabledBitmap)
        delete FDisabledBitmap;
}

/*##########################################################################
#
#   Name       : TButtonControl::Init
#
#   Purpose....: Init key control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::Init(char ch)
{
    FUpBitmap = 0;
    FDownBitmap = 0;
    FDisabledBitmap = 0;

    FFont = 0;
    FLowerFont = 0;
    FUpperFont = 0;
	
	FFontAliased = 1;
	FLowerFontAliased = 1;
	FUpperFontAliased = 1;

    FDown.ShiftX = 2;
    FDown.ShiftY = 2;

    FDisabled.BorderWidth = 0;
    
    FDisabled.ButtonR = 128;
    FDisabled.ButtonG = 128;
    FDisabled.ButtonB = 128;

    FDisabled.ShadowR = 128;
    FDisabled.ShadowG = 128;
    FDisabled.ShadowB = 128;

    FDisabled.DrawR = 150;
    FDisabled.DrawG = 150;
    FDisabled.DrawB = 150;
    
    FPressed = FALSE;
    FKey = ch;
    FKeepDown = FALSE;
    FActive = FALSE;

    ControlType += TString(".BUTTON");
}
    
/*##########################################################################
#
#   Name       : TButtonControl::IsButtonControl
#
#   Purpose....: Check if control is a button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::IsButtonControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".BUTTON"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetSize
#
#   Purpose....: Set size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetSize(TFont *font, const char *text, int width, int height)
{
    int xsize = 0;
    int ysize = 0;

    if (font)
        font->GetStringMetrics(text, &xsize, &ysize);

    xsize = 3 * xsize / 2 + 2;
    ysize = 3 * ysize / 2 + 2;

    if (width)
        xsize = width;    

    if (height)
        ysize = height;

    Resize(xsize, ysize);        
}

/*##########################################################################
#
#   Name       : TButtonControl::SetText
#
#   Purpose....: Set control text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetText(const char *text)
{
    FText = text;
    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetText
#
#   Purpose....: Set control text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetText(TString &text)
{
    FText = text;
    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::GetText
#
#   Purpose....: Get text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TButtonControl::GetText()
{
    return FText.GetData();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpperText
#
#   Purpose....: Set upper control text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpperText(const char *text)
{
    FUpperText = text;
    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpperText
#
#   Purpose....: Set upper control text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpperText(TString &text)
{
    FUpperText = text;
    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::GetUpperText
#
#   Purpose....: Get upper text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TButtonControl::GetUpperText()
{
    return FUpperText.GetData();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetLowerText
#
#   Purpose....: Set lower control text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetLowerText(const char *text)
{
    FLowerText = text;
    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetLowerText
#
#   Purpose....: Set lower control text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetLowerText(TString &text)
{
    FLowerText = text;
    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::GetLowerText
#
#   Purpose....: Get lower text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TButtonControl::GetLowerText()
{
    return FLowerText.GetData();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetKey
#
#   Purpose....: Set control key
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetKey(char key)
{
    FKey = key;
}

/*##########################################################################
#
#   Name       : TButtonControl::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;

    Ini->GotoSection(IniSection);


    if (Ini->ReadVar("Font.Size", str, 255))
    {
        size = atoi(str);

        if (size)
        {
            if (FFont)
                delete FFont;

            FFont = new TFont(size);
        }
    }

    if (Ini->ReadVar("LowerFont.Size", str, 255))
    {
        size = atoi(str);

        if (size)
        {
            if (FLowerFont)
                delete FLowerFont;

            FLowerFont = new TFont(size);
        }
    }

    if (Ini->ReadVar("UpperFont.Size", str, 255))
    {
        size = atoi(str);

        if (size)
        {
            if (FUpperFont)
                delete FUpperFont;

            FUpperFont = new TFont(size);
        }
    }

    if (Ini->ReadVar("Font.Aliased", str, 255))
        FFontAliased = atoi(str);
	
	if (Ini->ReadVar("LowerFont.Aliased", str, 255))
        FLowerFontAliased = atoi(str);
	
	if (Ini->ReadVar("UpperFont.Aliased", str, 255))
        FUpperFontAliased = atoi(str);

    if (Ini->ReadVar("Key", str, 255))
        FKey = DecodeKey(str);

    if (Ini->ReadVar("Up.Shift.X", str, 255))
        FUp.ShiftX = atoi(str);

    if (Ini->ReadVar("Up.Shift.Y", str, 255))
        FUp.ShiftY = atoi(str);


    if (Ini->ReadVar("Down.Shift.X", str, 255))
        FDown.ShiftX = atoi(str);

    if (Ini->ReadVar("Down.Shift.Y", str, 255))
        FDown.ShiftY = atoi(str);


    if (Ini->ReadVar("Disabled.Shift.X", str, 255))
        FDisabled.ShiftX = atoi(str);

    if (Ini->ReadVar("Disabled.Shift.Y", str, 255))
        FDisabled.ShiftY = atoi(str);


    if (Ini->ReadVar("Up.BorderWidth", str, 255))
        FUp.BorderWidth = atoi(str);

    if (Ini->ReadVar("Down.BorderWidth", str, 255))
        FDown.BorderWidth = atoi(str);

    if (Ini->ReadVar("Disabled.BorderWidth", str, 255))
        FDisabled.BorderWidth = atoi(str);


    if (Ini->ReadVar("Up.DrawColor.R", str, 255))
        FUp.DrawR = atoi(str);

    if (Ini->ReadVar("Up.DrawColor.G", str, 255))
        FUp.DrawG = atoi(str);

    if (Ini->ReadVar("Up.DrawColor.B", str, 255))
        FUp.DrawB = atoi(str);


    if (Ini->ReadVar("Down.DrawColor.R", str, 255))
        FDown.DrawR = atoi(str);

    if (Ini->ReadVar("Down.DrawColor.G", str, 255))
        FDown.DrawG = atoi(str);

    if (Ini->ReadVar("Down.DrawColor.B", str, 255))
        FDown.DrawB = atoi(str);


    if (Ini->ReadVar("Disabled.DrawColor.R", str, 255))
        FDisabled.DrawR = atoi(str);

    if (Ini->ReadVar("Disabled.DrawColor.G", str, 255))
        FDisabled.DrawG = atoi(str);

    if (Ini->ReadVar("Disabled.DrawColor.B", str, 255))
        FDisabled.DrawB = atoi(str);


    if (Ini->ReadVar("Up.ShadowColor.R", str, 255))
        FUp.ShadowR = atoi(str);

    if (Ini->ReadVar("Up.ShadowColor.G", str, 255))
        FUp.ShadowG = atoi(str);

    if (Ini->ReadVar("Up.ShadowColor.B", str, 255))
        FUp.ShadowB = atoi(str);


    if (Ini->ReadVar("Down.ShadowColor.R", str, 255))
        FDown.ShadowR = atoi(str);

    if (Ini->ReadVar("Down.ShadowColor.G", str, 255))
        FDown.ShadowG = atoi(str);

    if (Ini->ReadVar("Down.ShadowColor.B", str, 255))
        FDown.ShadowB = atoi(str);


    if (Ini->ReadVar("Disabled.ShadowColor.R", str, 255))
        FDisabled.ShadowR = atoi(str);

    if (Ini->ReadVar("Disabled.ShadowColor.G", str, 255))
        FDisabled.ShadowG = atoi(str);

    if (Ini->ReadVar("Disabled.ShadowColor.B", str, 255))
        FDisabled.ShadowB = atoi(str);


    if (Ini->ReadVar("Up.ButtonColor.R", str, 255))
        FUp.ButtonR = atoi(str);

    if (Ini->ReadVar("Up.ButtonColor.G", str, 255))
        FUp.ButtonG = atoi(str);

    if (Ini->ReadVar("Up.ButtonColor.B", str, 255))
        FUp.ButtonB = atoi(str);


    if (Ini->ReadVar("Down.ButtonColor.R", str, 255))
        FDown.ButtonR = atoi(str);

    if (Ini->ReadVar("Down.ButtonColor.G", str, 255))
        FDown.ButtonG = atoi(str);

    if (Ini->ReadVar("Down.ButtonColor.B", str, 255))
        FDown.ButtonB = atoi(str);


    if (Ini->ReadVar("Disabled.ButtonColor.R", str, 255))
        FDisabled.ButtonR = atoi(str);

    if (Ini->ReadVar("Disabled.ButtonColor.G", str, 255))
        FDisabled.ButtonG = atoi(str);

    if (Ini->ReadVar("Disabled.ButtonColor.B", str, 255))
        FDisabled.ButtonB = atoi(str);


    if (Ini->ReadVar("Up.BorderLightColor.R", str, 255))
        FUp.BorderLightR = atoi(str);

    if (Ini->ReadVar("Up.BorderLightColor.G", str, 255))
        FUp.BorderLightG = atoi(str);

    if (Ini->ReadVar("Up.BorderLightColor.B", str, 255))
        FUp.BorderLightB = atoi(str);


    if (Ini->ReadVar("Down.BorderLightColor.R", str, 255))
        FDown.BorderLightR = atoi(str);

    if (Ini->ReadVar("Down.BorderLightColor.G", str, 255))
        FDown.BorderLightG = atoi(str);

    if (Ini->ReadVar("Down.BorderLightColor.B", str, 255))
        FDown.BorderLightB = atoi(str);


    if (Ini->ReadVar("Disabled.BorderLightColor.R", str, 255))
        FDisabled.BorderLightR = atoi(str);

    if (Ini->ReadVar("Disabled.BorderLightColor.G", str, 255))
        FDisabled.BorderLightG = atoi(str);

    if (Ini->ReadVar("Disabled.BorderLightColor.B", str, 255))
        FDisabled.BorderLightB = atoi(str);


    if (Ini->ReadVar("Up.BorderDarkColor.R", str, 255))
        FUp.BorderDarkR = atoi(str);

    if (Ini->ReadVar("Up.BorderDarkColor.G", str, 255))
        FUp.BorderDarkG = atoi(str);

    if (Ini->ReadVar("Up.BorderDarkColor.B", str, 255))
        FUp.BorderDarkB = atoi(str);


    if (Ini->ReadVar("Down.BorderDarkColor.R", str, 255))
        FDown.BorderDarkR = atoi(str);

    if (Ini->ReadVar("Down.BorderDarkColor.G", str, 255))
        FDown.BorderDarkG = atoi(str);

    if (Ini->ReadVar("Down.BorderDarkColor.B", str, 255))
        FDown.BorderDarkB = atoi(str);


    if (Ini->ReadVar("Disabled.BorderDarkColor.R", str, 255))
        FDisabled.BorderDarkR = atoi(str);

    if (Ini->ReadVar("Disabled.BorderDarkColor.G", str, 255))
        FDisabled.BorderDarkG = atoi(str);

    if (Ini->ReadVar("Disabled.BorderDarkColor.B", str, 255))
        FDisabled.BorderDarkB = atoi(str);

    if (Ini->ReadVar("Text", str, 255))
        SetText(str);

    if (Ini->ReadVar("UpperText", str, 255))
        SetUpperText(str);

    if (Ini->ReadVar("LowerText", str, 255))
        SetLowerText(str);

    TControl::Set(Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TButtonControl::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TButtonControl::DefineUp
#
#   Purpose....: Define up button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DefineUp(TBitmapGraphicDevice *bitmap, int x, int y)
{
    FUp.Define(bitmap, x, y);

    if (FUpBitmap)
        delete FUpBitmap;
    FUpBitmap = CreateBitmap(FUp);

    if (IsEnabled() && !FPressed)
        NotifyResize();
}

/*##########################################################################
#
#   Name       : TButtonControl::DefineUp
#
#   Purpose....: Define up button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DefineUp(TBitmapGraphicDevice *bitmap)
{
    FUp.Define(bitmap);

    if (FUpBitmap)
        delete FUpBitmap;
    FUpBitmap = CreateBitmap(FUp);

    if (IsEnabled() && !FPressed)
        NotifyResize();
}

/*##########################################################################
#
#   Name       : TButtonControl::DefineDown
#
#   Purpose....: Define down button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DefineDown(TBitmapGraphicDevice *bitmap, int x, int y)
{
    FDown.Define(bitmap, x, y);

    if (FDownBitmap)
        delete FDownBitmap;
    FDownBitmap = CreateBitmap(FDown);

    if (IsEnabled() && FPressed)
        NotifyResize();
}

/*##########################################################################
#
#   Name       : TButtonControl::DefineDown
#
#   Purpose....: Define down button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DefineDown(TBitmapGraphicDevice *bitmap)
{
    FDown.Define(bitmap);

    if (FDownBitmap)
        delete FDownBitmap;
    FDownBitmap = CreateBitmap(FDown);

    if (IsEnabled() && FPressed)
        NotifyResize();
}

/*##########################################################################
#
#   Name       : TButtonControl::DefineDisabled
#
#   Purpose....: Define disabled button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DefineDisabled(TBitmapGraphicDevice *bitmap, int x, int y)
{
    FDisabled.Define(bitmap, x, y);

    if (FDisabledBitmap)
        delete FDisabledBitmap;
    FDisabledBitmap = CreateBitmap(FDisabled);

    if (!IsEnabled())
        NotifyResize();
}

/*##########################################################################
#
#   Name       : TButtonControl::DefineDisabled
#
#   Purpose....: Define disabled button bitmaps
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DefineDisabled(TBitmapGraphicDevice *bitmap)
{
    FDisabled.Define(bitmap);

    if (FDisabledBitmap)
        delete FDisabledBitmap;
    FDisabledBitmap = CreateBitmap(FDisabled);

    if (!IsEnabled())
        NotifyResize();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpShift
#
#   Purpose....: Set text shift for up-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpShift(int x, int y)
{
    FUp.ShiftX = x;
    FUp.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDownShift
#
#   Purpose....: Set text shift for down-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDownShift(int x, int y)
{
    FDown.ShiftX = x;
    FDown.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDisabledShift
#
#   Purpose....: Set text shift for disabled-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDisabledShift(int x, int y)
{
    FDisabled.ShiftX = x;
    FDisabled.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetFont(int height)
{
    if (FFont)
        delete FFont;

    FFont = new TFont(height);

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetFont(TFont *Font)
{
    if (FFont)
        delete FFont;

    FFont = new TFont(*Font);

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetFontAliased
#
#   Purpose....: Set font aliased
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetFontAliased(int aliased)
{
    FFontAliased = aliased;

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::GetFont
#
#   Purpose....: Get font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont *TButtonControl::GetFont()
{
    return FFont;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetLowerFont
#
#   Purpose....: Set lower font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetLowerFont(int height)
{
    if (FLowerFont)
        delete FLowerFont;

    FLowerFont = new TFont(height);

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetLowerFont
#
#   Purpose....: Set lower font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetLowerFont(TFont *Font)
{
    if (FLowerFont)
        delete FLowerFont;

    FLowerFont = new TFont(*Font);

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetLowerFontAliased
#
#   Purpose....: Set lower font aliased
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetLowerFontAliased(int aliased)
{
    FLowerFontAliased = aliased;

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::GetLowerFont
#
#   Purpose....: Get lower font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont *TButtonControl::GetLowerFont()
{
    return FLowerFont;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpperFont
#
#   Purpose....: Set upper font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpperFont(int height)
{
    if (FUpperFont)
        delete FUpperFont;

    FUpperFont = new TFont(height);

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpperFont
#
#   Purpose....: Set upper font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpperFont(TFont *Font)
{
    if (FUpperFont)
        delete FUpperFont;

    FUpperFont = new TFont(*Font);

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpperFontAliased
#
#   Purpose....: Set upper font aliased
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpperFontAliased(int aliased)
{
    FUpperFontAliased = aliased;

    Redraw();
}

/*##########################################################################
#
#   Name       : TButtonControl::GetUpperFont
#
#   Purpose....: Get upper font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont *TButtonControl::GetUpperFont()
{
    return FUpperFont;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpButtonColor
#
#   Purpose....: Set button color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpButtonColor(int r, int g, int b)
{
    FUp.ButtonR = r;
    FUp.ButtonG = g;
    FUp.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDownButtonColor
#
#   Purpose....: Set button color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDownButtonColor(int r, int g, int b)
{
    FDown.ButtonR = r;
    FDown.ButtonG = g;
    FDown.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDisabledButtonColor
#
#   Purpose....: Set button color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDisabledButtonColor(int r, int g, int b)
{
    FDisabled.ButtonR = r;
    FDisabled.ButtonG = g;
    FDisabled.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpDrawColor
#
#   Purpose....: Set draw color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpDrawColor(int r, int g, int b)
{
    FUp.DrawR = r;
    FUp.DrawG = g;
    FUp.DrawB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDownDrawColor
#
#   Purpose....: Set draw color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDownDrawColor(int r, int g, int b)
{
    FDown.DrawR = r;
    FDown.DrawG = g;
    FDown.DrawB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDisabledDrawColor
#
#   Purpose....: Set draw color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDisabledDrawColor(int r, int g, int b)
{
    FDisabled.DrawR = r;
    FDisabled.DrawG = g;
    FDisabled.DrawB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpShadowColor
#
#   Purpose....: Set shadow color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpShadowColor(int r, int g, int b)
{
    FUp.ShadowR = r;
    FUp.ShadowG = g;
    FUp.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDownShadowColor
#
#   Purpose....: Set shadow color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDownShadowColor(int r, int g, int b)
{
    FDown.ShadowR = r;
    FDown.ShadowG = g;
    FDown.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDisabledShadowColor
#
#   Purpose....: Set shadow color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDisabledShadowColor(int r, int g, int b)
{
    FDisabled.ShadowR = r;
    FDisabled.ShadowG = g;
    FDisabled.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpBorderWidth
#
#   Purpose....: Set up button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpBorderWidth(int width)
{
    FUp.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDownBorderWidth
#
#   Purpose....: Set down button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDownBorderWidth(int width)
{
    FDown.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDisabledBorderWidth
#
#   Purpose....: Set disabled button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDisabledBorderWidth(int width)
{
    FDisabled.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpLightBorderColor
#
#   Purpose....: Set light border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpLightBorderColor(int r, int g, int b)
{
    FUp.BorderLightR = r;
    FUp.BorderLightG = g;
    FUp.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDownLightBorderColor
#
#   Purpose....: Set light border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDownLightBorderColor(int r, int g, int b)
{
    FDown.BorderLightR = r;
    FDown.BorderLightG = g;
    FDown.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDisabledLightBorderColor
#
#   Purpose....: Set light border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDisabledLightBorderColor(int r, int g, int b)
{
    FDisabled.BorderLightR = r;
    FDisabled.BorderLightG = g;
    FDisabled.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetUpDarkBorderColor
#
#   Purpose....: Set drak border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetUpDarkBorderColor(int r, int g, int b)
{
    FUp.BorderDarkR = r;
    FUp.BorderDarkG = g;
    FUp.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDownDarkBorderColor
#
#   Purpose....: Set dark border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDownDarkBorderColor(int r, int g, int b)
{
         FDown.BorderDarkR = r;
         FDown.BorderDarkG = g;
         FDown.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::SetDisabledDarkBorderColor
#
#   Purpose....: Set dark border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::SetDisabledDarkBorderColor(int r, int g, int b)
{
         FDisabled.BorderDarkR = r;
         FDisabled.BorderDarkG = g;
         FDisabled.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TButtonControl::ForceUp
#
#   Purpose....: Force control to be up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::ForceUp()
{
    if (FPressed)
    {
        FPressed = FALSE;
        Redraw();
    }
}

/*##########################################################################
#
#   Name       : TButtonControl::EnableKeepDown
#
#   Purpose....: Enable keep key down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::EnableKeepDown()
{
    FKeepDown = TRUE;
}

/*##########################################################################
#
#   Name       : TButtonControl::CreateBitmap
#
#   Purpose....: Create a bitmap with the background buttons
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *TButtonControl::CreateBitmap(TButtonFactoryParam &Param)
{
    TBitmapGraphicDevice *bitmap;
    TBitmapGraphicDevice *temp;
    int i;
    int xsize, ysize;
    int xhot, yhot;
    int width, height;

    if (Param.Bitmap)
    {
        xhot = Param.HotX;
        yhot = Param.HotY;

        GetSize(&xsize, &ysize);
    
                height = Param.Bitmap->GetHeight();
                width = Param.Bitmap->GetWidth();
                  
                temp = new TBitmapGraphicDevice(24, width, ysize);
                temp->SetLgopNone();

                if (height > ysize)
                {
                    for (i = 0; i < ysize; i++)
                temp->Blit(Param.Bitmap, 0, i, 0, i, width, 1);

            for (i = ysize / 2; i < ysize; i++)
                temp->Blit(Param.Bitmap, 0, i + height - ysize, 0, i, width, 1);
        }
        else
        {
                    for (i = 0; i < yhot; i++)
                temp->Blit(Param.Bitmap, 0, i, 0, i, width, 1);

                    for (i = yhot; i < ysize - height + yhot; i++)
                temp->Blit(Param.Bitmap, 0, yhot, 0, i, width, 1);

                    for (i = yhot; i < height; i++)
                temp->Blit(Param.Bitmap, 0, i, 0, i + ysize - height, width, 1);
        }
                  
                bitmap = new TBitmapGraphicDevice(24, xsize, ysize);
                bitmap->SetLgopNone();

                if (width > xsize)
                {
                    for (i = 0; i < xsize; i++)
                bitmap->Blit(temp, i, 0, i, 0, 1, ysize);

            for (i = xsize / 2; i < xsize; i++)
                bitmap->Blit(temp, i + width - xsize, 0, i, 0, 1, ysize);
        }
        else
        {
                    for (i = 0; i < xhot; i++)
                bitmap->Blit(temp, i, 0, i, 0, 1, ysize);

                    for (i = xhot; i < xsize - width + xhot; i++)
                bitmap->Blit(temp, xhot, 0, i, 0, 1, ysize);

                    for (i = xhot; i < width; i++)
                bitmap->Blit(temp, i, 0, i + xsize - width, 0, 1, ysize);
        }

        delete temp;

        return bitmap;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TButtonControl::CreateBitmapButtons
#
#   Purpose....: Create bitmap buttons
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::CreateBitmapButtons()
{
    if (FUpBitmap)
        delete FUpBitmap;
    FUpBitmap = CreateBitmap(FUp);

    if (FDownBitmap)
        delete FDownBitmap;
    FDownBitmap = CreateBitmap(FDown);

    if (FDisabledBitmap)
        delete FDisabledBitmap;
    FDisabledBitmap = CreateBitmap(FDisabled);
}

/*##########################################################################
#
#   Name       : TButtonControl::PaintDescrButton
#
#   Purpose....: Paint a button from description
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::PaintDescrButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    int i;
    int size;

    if (xsize > ysize)
        size = ysize;
    else
        size = xsize;
        
    switch (state)
    {
        case STATE_UP:
            dev->SetFilledStyle();
            dev->SetDrawColor(FUp.ButtonR, FUp.ButtonG, FUp.ButtonB);
            dev->DrawRect(xstart, ystart, xstart + xsize - 1, ystart + ysize - 1);
            
            if (FUp.BorderWidth < size)
            {
                dev->SetDrawColor(FUp.BorderLightR, FUp.BorderLightG, FUp.BorderLightB);
                            for (i = 0; i < FUp.BorderWidth; i++)
                            {
                    dev->DrawLine(xstart + i, ystart + i, xstart + i, ystart + ysize - i - 1);
                    dev->DrawLine(xstart + i, ystart + i, xstart + xsize - i - 1, ystart + i);
                }

                dev->SetDrawColor(FUp.BorderDarkR, FUp.BorderDarkG, FUp.BorderDarkB);
                                for (i = 0; i < FUp.BorderWidth; i++)
                {
                    dev->DrawLine(xstart + xsize - i - 1, ystart + i, xstart + xsize - i - 1, ystart + ysize - i - 1);
                    dev->DrawLine(xstart + i, ystart + ysize - i - 1, xstart + xsize - i - 1, ystart + ysize - i - 1);
                }
            }
            break;

        case STATE_DOWN:
            dev->SetFilledStyle();
            dev->SetDrawColor(FDown.ButtonR, FDown.ButtonG, FDown.ButtonB);
            dev->DrawRect(xstart, ystart, xstart + xsize - 1, ystart + ysize - 1);
            
            if (FDown.BorderWidth < size)
            {
                dev->SetDrawColor(FDown.BorderDarkR, FDown.BorderDarkG, FDown.BorderDarkB);
                            for (i = 0; i < FDown.BorderWidth; i++)
                            {
                    dev->DrawLine(xstart + i, ystart + i, xstart + i, ystart + ysize - i - 1);
                    dev->DrawLine(xstart + i, ystart + i, xstart + xsize - i - 1, ystart + i);
                }
            }
            break;

        case STATE_DISABLED:
            dev->SetFilledStyle();
            dev->SetDrawColor(FDisabled.ButtonR, FDisabled.ButtonG, FDisabled.ButtonB);
            dev->DrawRect(xstart, ystart, xstart + xsize - 1, ystart + ysize - 1);
            
            if (FDisabled.BorderWidth < size)
            {
                dev->SetDrawColor(FDisabled.BorderLightR, FDisabled.BorderLightG, FDisabled.BorderLightB);
                            for (i = 0; i < FDisabled.BorderWidth; i++)
                            {
                    dev->DrawLine(xstart + i, ystart + i, xstart + i, ystart + ysize - i - 1);
                    dev->DrawLine(xstart + i, ystart + i, xstart + xsize - i - 1, ystart + i);
                }

                dev->SetDrawColor(FDisabled.BorderDarkR, FDisabled.BorderDarkG, FDisabled.BorderDarkB);
                                for (i = 0; i < FDisabled.BorderWidth; i++)
                {
                    dev->DrawLine(xstart + xsize - i - 1, ystart + i, xstart + xsize - i - 1, ystart + ysize - i - 1);
                    dev->DrawLine(xstart + i, ystart + ysize - i - 1, xstart + xsize - i - 1, ystart + ysize - i - 1);
                }
            }
            break;
    }
}

/*##########################################################################
#
#   Name       : TButtonControl::CreateFont
#
#   Purpose....: Create a font if it is missing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::CreateFont(int xsize, int ysize)
{
    if (!FFont)
        FFont = new TFont(2 * ysize / 3);
}

/*##########################################################################
#
#   Name       : TButtonControl::DrawAliasedText
#
#   Purpose....: Draw aliased text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DrawAliasedText(TGraphicDevice *dev, TButtonFactoryParam &Param, int xstart, int ystart, int xsize, int ysize, const char *text, TFont *font)
{
    int x, y;
    int xtext, ytext;

    font->GetStringMetrics(text, &xtext, &ytext);

    x = (xsize - xtext) / 2;
    y = (ysize - ytext) / 2;

    x += Param.ShiftX;
    y += Param.ShiftY;

    x += xstart;
    y += ystart;
        
    dev->SetFont(font);

    dev->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
    dev->DrawString(x, y, text);
    dev->DrawString(x + 1, y, text);
    dev->DrawString(x - 1, y, text);
    dev->DrawString(x, y + 1, text);
    dev->DrawString(x, y - 1, text);
    dev->DrawString(x + 1, y + 1, text);
    dev->DrawString(x - 1, y - 1, text);
    dev->DrawString(x - 1, y + 1, text);
    dev->DrawString(x + 1, y - 1, text);

    dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
    dev->DrawString(x, y, text);
}

/*##########################################################################
#
#   Name       : TButtonControl::DrawNonAliasedText
#
#   Purpose....: Draw non-aliased text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DrawNonAliasedText(TGraphicDevice *dev, TButtonFactoryParam &Param, int xstart, int ystart, int xsize, int ysize, const char *text, TFont *font)
{
    int x, y;
    int xtext, ytext;

    font->GetStringMetrics(text, &xtext, &ytext);

    x = (xsize - xtext) / 2;
    y = (ysize - ytext) / 2;

    x += Param.ShiftX;
    y += Param.ShiftY;

    x += xstart;
    y += ystart;
        
    dev->SetFont(font);

    dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
    dev->DrawString(x, y, text);
}

/*##########################################################################
#
#   Name       : TButtonControl::DrawText
#
#   Purpose....: Draw text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::DrawText(TGraphicDevice *dev, TButtonFactoryParam &Param, int xstart, int ystart, int xsize, int ysize)
{
    const char *text;
    int x;
    int y;

    if (FUpperFont)
    {
        text = FUpperText.GetData();
        if (strlen(text))
        {
            FUpperFont->GetStringMetrics(text, &x, &y);
            if (x < xsize && y < ysize)
            {
				if(FUpperFontAliased == 0)
					DrawNonAliasedText(dev, Param, xstart, ystart, xsize, y, text, FUpperFont);
                else if (y > 25)
                    DrawAliasedText(dev, Param, xstart, ystart, xsize, y, text, FUpperFont);
                else                    
                    DrawNonAliasedText(dev, Param, xstart, ystart, xsize, y, text, FUpperFont);

                ystart += y;
                ysize -= y;
            }
        }
    }

    if (FLowerFont)
    {
        text = FLowerText.GetData();
        if (strlen(text))
        {
            FLowerFont->GetStringMetrics(text, &x, &y);
            if (x < xsize && y < ysize)
            {
				if(FLowerFontAliased == 0)
					DrawNonAliasedText(dev, Param, xstart, ystart + ysize - y, xsize, y, text, FLowerFont);
                else if (y > 25)
                    DrawAliasedText(dev, Param, xstart, ystart + ysize - y, xsize, y, text, FLowerFont);
                else
                    DrawNonAliasedText(dev, Param, xstart, ystart + ysize - y, xsize, y, text, FLowerFont);

                ysize -= y;
            }
        }
    }

    if (ysize > 0 && xsize > 0)
    {
        text = FText.GetData();
        if (strlen(text))
        {
            if (FFont == 0)
                CreateFont(xsize, ysize);

			if(FFontAliased == 0)
				DrawNonAliasedText(dev, Param, xstart, ystart, xsize, ysize, text, FFont);
			else
				DrawAliasedText(dev, Param, xstart, ystart, xsize, ysize, text, FFont);
        }
    }            
}

/*##########################################################################
#
#   Name       : TButtonControl::PaintButton
#
#   Purpose....: Paint a button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::PaintButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    switch (state)
    {
        case STATE_UP:
            if (FUpBitmap)
                dev->Blit(FUpBitmap, 0, 0, xstart, ystart, xsize, ysize);
            else
                PaintDescrButton(dev, xstart, ystart, xsize, ysize, state);

            DrawText(dev, FUp, xstart, ystart, xsize, ysize);
            break;

        case STATE_DOWN:
            if (FDownBitmap)
                dev->Blit(FDownBitmap, 0, 0, xstart, ystart, xsize, ysize);
            else
                PaintDescrButton(dev, xstart, ystart, xsize, ysize, state);

            DrawText(dev, FDown, xstart, ystart, xsize, ysize);
            break;
        
        case STATE_DISABLED:
            if (FDisabledBitmap)
                dev->Blit(FDisabledBitmap, 0, 0, xstart, ystart, xsize, ysize);
            else
                PaintDescrButton(dev, xstart, ystart, xsize, ysize, state);

            DrawText(dev, FDisabled, xstart, ystart, xsize, ysize);
            break;
    }
}

/*##########################################################################
#
#   Name       : TButtonControl::Hide
#
#   Purpose....: Hide control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::Hide()
{
    FPressed = FALSE;

    TControl::Hide();
}


/*##########################################################################
#
#   Name       : TButtonControl::OnMouseMove
#
#   Purpose....: Handle mouse move
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnMouseMove(int x, int y, int ButtonState, int KeyState)
{
    if (ButtonState & MOUSE_LEFT_BUTTON)
    {
        if (IsInside(x, y))
        {
            if (!FKeepDown)
            {
                if (!FPressed)
                {  
                    if (FKey)
                        PutKey(FKey);

                    FPressed = TRUE;
                    Redraw();

                    NotifyChanged();
                }
            }
        }
    }

    return TControl::OnMouseMove(x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TButtonControl::OnLeftUp
#
#   Purpose....: Handle left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    if (FPressed)
    {
        FPressed = FALSE;
        Redraw();
        NotifyChanged();
    }

    return TControl::OnLeftUp(x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TButtonControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    if (IsInside(x, y))
    {
        if (FKey)
            PutKey(FKey);

        if (!FKeepDown)
        {
            FPressed = TRUE;
            Redraw();
        }
        NotifyChanged();
        return TRUE;
    }
    else
    {
        if (FPressed && !FKeepDown)
        {
            FPressed = FALSE;
            Redraw();
        }
        return TControl::OnLeftDown(x, y, ButtonState, KeyState);
    }
}

/*##########################################################################
#
#   Name       : TButtonControl::OnKeyPressed
#
#   Purpose....: Handle key pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    if (VirtualKey == FKey)
    {
        if (!FPressed)
        {
            FPressed = TRUE;
            if (FKeepDown)
                FActive = TRUE;

            Redraw();
            NotifyChanged();
        }
    }
    else
    {
        if (FKeepDown && FActive)
        {
            FActive = FALSE;
            Redraw();
        }
    }
    return TControl::OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TButtonControl::OnKeyReleased
#
#   Purpose....: Handle key released
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TButtonControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    if (VirtualKey == FKey)
    {
        if (FPressed)
        {
            FPressed = FALSE;
            Redraw();
            NotifyChanged();
        }
    }
    return TControl::OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TButtonControl::NotifyResize
#
#   Purpose....: Notify control resize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::NotifyResize()
{
    CreateBitmapButtons();
}

/*##########################################################################
#
#   Name       : TButtonControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TButtonControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int xmax = xmin + width - 1;
    int ymax = ymin + height - 1;

    if (IsVisible())
    {
        SetClipRect(    dev,
                        xmin, ymin,
                        xmax, ymax);

        dev->SetLgopNone();
        dev->SetFilledStyle();

        if (IsEnabled())
        {
            if (FPressed)
                PaintButton(dev, xmin, ymin, width, height, STATE_DOWN);
            else
                PaintButton(dev, xmin, ymin, width, height, STATE_UP);
        }
        else
            PaintButton(dev, xmin, ymin, width, height, STATE_DISABLED);
    }
    else
    {
        FPressed = FALSE;
        FActive = FALSE;
    }
}
