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
 # scroll.cpp
 # Scroll control class
 #
 ########################################################################*/

#include <string.h>

#include "scroll.h"

#define FALSE   0
#define TRUE    !FALSE

#define STATE_UP        1
#define STATE_DOWN      2
#define STATE_DISABLED  3

#define START_TIMEOUT   450
#define REPEAT_TIMEOUT  50

/*##########################################################################
#
#   Name       : TScrollParam::TScrollParam
#
#   Purpose....: Scroll parameters constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TScrollParam::TScrollParam()
{
    ShiftX = 0;
    ShiftY = 0;

    BorderWidth = 1;

    BackR = 128;
    BackG = 128;
    BackB = 128;
    
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
#   Name       : TScrollFactory::TScrollFactory
#
#   Purpose....: Scroll factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TScrollFactory::TScrollFactory()
{
    FWidth = 16;

    FDown.ShiftX = 2;
    FDown.ShiftY = 2;

    FDown.BackR = 128;
    FDown.BackG = 128;
    FDown.BackB = 255;

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
#   Name       : TScrollFactory::~TScrollFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TScrollFactory::~TScrollFactory()
{
}

/*##########################################################################
#
#   Name       : TScrollFactory::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];

    Ini->GotoSection(IniSection);


    if (Ini->ReadVar("Width", str, 255))
        FWidth = atoi(str);


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


    if (Ini->ReadVar("Up.BackColor.R", str, 255))
        FUp.BackR = atoi(str);

    if (Ini->ReadVar("Up.BackColor.G", str, 255))
        FUp.BackG = atoi(str);

    if (Ini->ReadVar("Up.BackColor.B", str, 255))
        FUp.BackB = atoi(str);


    if (Ini->ReadVar("Down.BackColor.R", str, 255))
        FDown.BackR = atoi(str);

    if (Ini->ReadVar("Down.BackColor.G", str, 255))
        FDown.BackG = atoi(str);

    if (Ini->ReadVar("Down.BackColor.B", str, 255))
        FDown.BackB = atoi(str);


    if (Ini->ReadVar("Disabled.BackColor.R", str, 255))
        FDisabled.BackR = atoi(str);

    if (Ini->ReadVar("Disabled.BackColor.G", str, 255))
        FDisabled.BackG = atoi(str);

    if (Ini->ReadVar("Disabled.BackColor.B", str, 255))
        FDisabled.BackB = atoi(str);


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
#   Name       : TScrollFactory::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetWidth
#
#   Purpose....: Set fixed button width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetWidth(int width)
{
    FWidth = width;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpShift
#
#   Purpose....: Set text shift for up-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpShift(int x, int y)
{
    FUp.ShiftX = x;
    FUp.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownShift
#
#   Purpose....: Set text shift for down-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownShift(int x, int y)
{
    FDown.ShiftX = x;
    FDown.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledShift
#
#   Purpose....: Set text shift for disabled-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledShift(int x, int y)
{
    FDisabled.ShiftX = x;
    FDisabled.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpBackColor
#
#   Purpose....: Set back color for up scroll-bar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpBackColor(int r, int g, int b)
{
    FUp.BackR = r;
    FUp.BackG = g;
    FUp.BackB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownButtonColor
#
#   Purpose....: Set back color for down scroll-bar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownBackColor(int r, int g, int b)
{
    FDown.BackR = r;
    FDown.BackG = g;
    FDown.BackB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledBackColor
#
#   Purpose....: Set back color for disabled scroll-bar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledBackColor(int r, int g, int b)
{
    FDisabled.BackR = r;
    FDisabled.BackG = g;
    FDisabled.BackB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpButtonColor
#
#   Purpose....: Set button color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpButtonColor(int r, int g, int b)
{
    FUp.ButtonR = r;
    FUp.ButtonG = g;
    FUp.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownButtonColor
#
#   Purpose....: Set button color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownButtonColor(int r, int g, int b)
{
    FDown.ButtonR = r;
    FDown.ButtonG = g;
    FDown.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledButtonColor
#
#   Purpose....: Set button color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledButtonColor(int r, int g, int b)
{
    FDisabled.ButtonR = r;
    FDisabled.ButtonG = g;
    FDisabled.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpDrawColor
#
#   Purpose....: Set draw color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpDrawColor(int r, int g, int b)
{
    FUp.DrawR = r;
    FUp.DrawG = g;
    FUp.DrawB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownDrawColor
#
#   Purpose....: Set draw color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownDrawColor(int r, int g, int b)
{
    FDown.DrawR = r;
    FDown.DrawG = g;
    FDown.DrawB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledDrawColor
#
#   Purpose....: Set draw color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledDrawColor(int r, int g, int b)
{
    FDisabled.DrawR = r;
    FDisabled.DrawG = g;
    FDisabled.DrawB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpShadowColor
#
#   Purpose....: Set shadow color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpShadowColor(int r, int g, int b)
{
    FUp.ShadowR = r;
    FUp.ShadowG = g;
    FUp.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownShadowColor
#
#   Purpose....: Set shadow color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownShadowColor(int r, int g, int b)
{
    FDown.ShadowR = r;
    FDown.ShadowG = g;
    FDown.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledShadowColor
#
#   Purpose....: Set shadow color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledShadowColor(int r, int g, int b)
{
    FDisabled.ShadowR = r;
    FDisabled.ShadowG = g;
    FDisabled.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpBorderWidth
#
#   Purpose....: Set up button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpBorderWidth(int width)
{
    FUp.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownBorderWidth
#
#   Purpose....: Set down button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownBorderWidth(int width)
{
    FDown.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledBorderWidth
#
#   Purpose....: Set disabled button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledBorderWidth(int width)
{
    FDisabled.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpLightBorderColor
#
#   Purpose....: Set light border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpLightBorderColor(int r, int g, int b)
{
    FUp.BorderLightR = r;
    FUp.BorderLightG = g;
    FUp.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownLightBorderColor
#
#   Purpose....: Set light border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownLightBorderColor(int r, int g, int b)
{
    FDown.BorderLightR = r;
    FDown.BorderLightG = g;
    FDown.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledLightBorderColor
#
#   Purpose....: Set light border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledLightBorderColor(int r, int g, int b)
{
    FDisabled.BorderLightR = r;
    FDisabled.BorderLightG = g;
    FDisabled.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetUpDarkBorderColor
#
#   Purpose....: Set drak border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetUpDarkBorderColor(int r, int g, int b)
{
    FUp.BorderDarkR = r;
    FUp.BorderDarkG = g;
    FUp.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDownDarkBorderColor
#
#   Purpose....: Set dark border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDownDarkBorderColor(int r, int g, int b)
{
         FDown.BorderDarkR = r;
         FDown.BorderDarkG = g;
         FDown.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetDisabledDarkBorderColor
#
#   Purpose....: Set dark border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetDisabledDarkBorderColor(int r, int g, int b)
{
         FDisabled.BorderDarkR = r;
         FDisabled.BorderDarkG = g;
         FDisabled.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TScrollFactory::SetParam
#
#   Purpose....: Set parameters for scroll-control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollFactory::SetParam(TScrollControl *scroll)
{
        scroll->FUp = FUp;
        scroll->FDown = FDown;
        scroll->FDisabled = FDisabled;
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateVer
#
#   Purpose....: Create vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl *TScrollFactory::CreateVer(TControlThread *dev, int xstart, int ystart, int len)
{
        TVerScrollControl *scroll;

        scroll = new TVerScrollControl(dev, xstart, ystart, FWidth, len);

        SetParam(scroll);

        return scroll;
}


/*##########################################################################
#
#   Name       : TScrollFactory::CreateVer
#
#   Purpose....: Create vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl *TScrollFactory::CreateVer(TControl *control, int xstart, int ystart, int len)
{
        TVerScrollControl *scroll;

        scroll = new TVerScrollControl(control, xstart, ystart, FWidth, len);

        SetParam(scroll);

        return scroll;
}


/*##########################################################################
#
#   Name       : TScrollFactory::CreateHor
#
#   Purpose....: Create horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl *TScrollFactory::CreateHor(TControlThread *dev, int xstart, int ystart, int len)
{
        THorScrollControl *scroll;

        scroll = new THorScrollControl(dev, xstart, ystart, FWidth, len);

        SetParam(scroll);

        return scroll;
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateHor
#
#   Purpose....: Create horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl *TScrollFactory::CreateHor(TControl *control, int xstart, int ystart, int len)
{
        THorScrollControl *scroll;

        scroll = new THorScrollControl(control, xstart, ystart, FWidth, len);

        SetParam(scroll);

    return scroll;
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateVer
#
#   Purpose....: Create vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl *TScrollFactory::CreateVer(TControlThread *dev, TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    TVerScrollControl *scroll;
    int x = 0;
    int y = 0;
    int len = 0;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Width", str, 255))
        FWidth = atoi(str);

    if (Ini->ReadVar("Len", str, 255))
        len = atoi(str);


    if (Ini->ReadVar("Start.X", str, 255))
        x = atoi(str);

    if (Ini->ReadVar("Start.Y", str, 255))
        y = atoi(str);

    scroll = new TVerScrollControl(dev, x, y, FWidth, len);

    SetParam(scroll);

    return scroll;
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateVer
#
#   Purpose....: Create vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl *TScrollFactory::CreateVer(TControl *control, TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    TVerScrollControl *scroll;
    int x = 0;
    int y = 0;
    int len = 0;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Width", str, 255))
        FWidth = atoi(str);

    if (Ini->ReadVar("Len", str, 255))
        len = atoi(str);


    if (Ini->ReadVar("Start.X", str, 255))
        x = atoi(str);

    if (Ini->ReadVar("Start.Y", str, 255))
        y = atoi(str);

    scroll = new TVerScrollControl(control, x, y, FWidth, len);

    SetParam(scroll);

    return scroll;
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateHor
#
#   Purpose....: Create horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl *TScrollFactory::CreateHor(TControlThread *dev, TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    THorScrollControl *scroll;
    int x = 0;
    int y = 0;
    int len = 0;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Width", str, 255))
        FWidth = atoi(str);

    if (Ini->ReadVar("Len", str, 255))
        len = atoi(str);


    if (Ini->ReadVar("Start.X", str, 255))
        x = atoi(str);

    if (Ini->ReadVar("Start.Y", str, 255))
        y = atoi(str);

    scroll = new THorScrollControl(dev, x, y, FWidth, len);

    SetParam(scroll);

    return scroll;
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateHor
#
#   Purpose....: Create horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl *TScrollFactory::CreateHor(TControl *control, TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    THorScrollControl *scroll;
    int x = 0;
    int y = 0;
    int len = 0;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Width", str, 255))
        FWidth = atoi(str);

    if (Ini->ReadVar("Len", str, 255))
        len = atoi(str);


    if (Ini->ReadVar("Start.X", str, 255))
        x = atoi(str);

    if (Ini->ReadVar("Start.Y", str, 255))
        y = atoi(str);

    scroll = new THorScrollControl(control, x, y, FWidth, len);

    SetParam(scroll);

    return scroll;
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateVer
#
#   Purpose....: Create vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl *TScrollFactory::CreateVer(TControlThread *dev, const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    return CreateVer(dev, &Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateVer
#
#   Purpose....: Create vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl *TScrollFactory::CreateVer(TControl *control, const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    return CreateVer(control, &Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateHor
#
#   Purpose....: Create horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl *TScrollFactory::CreateHor(TControlThread *dev, const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    return CreateHor(dev, &Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TScrollFactory::CreateHor
#
#   Purpose....: Create horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl *TScrollFactory::CreateHor(TControl *control, const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    return CreateHor(control, &Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TScrollControl::TScrollControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TScrollControl::TScrollControl(TControlThread *dev)
    : TControl(dev)
{
    Init();
}

/*##########################################################################
#
#   Name       : TScrollControl::TScrollControl
#
#   Purpose....: Key control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TScrollControl::TScrollControl(TControl *control)
    : TControl(control)
{
    Init();
}

/*##########################################################################
#
#   Name       : TScrollControl::~TScrollControl
#
#   Purpose....: Key control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TScrollControl::~TScrollControl()
{
}

/*##########################################################################
#
#   Name       : TScrollControl::Init
#
#   Purpose....: Init scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::Init()
{
    FDown.ShiftX = 2;
    FDown.ShiftY = 2;

    FDown.BackR = 128;
    FDown.BackG = 128;
    FDown.BackB = 255;

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

    FScrollSize = 0;
    FMinScrollButton = 0;
    FCurrScrollButton = 0;
    FScrollPos = 0; 

    FScrollDist = 0.01;
    FPageDist = 0.1;

    FRedrawButtons = TRUE;

    ControlType += TString(".SCROLL");
}
    
/*##########################################################################
#
#   Name       : TScrollControl::IsScrollControl
#
#   Purpose....: Check if control is a scroll
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TScrollControl::IsScrollControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".SCROLL"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TScrollControl::ChildChange
#
#   Purpose....: A significant change in a child occured
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::ChildChange()
{
    FRedrawButtons = TRUE;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetScrollDist
#
#   Purpose....: Set scroll arrow move distance for stand-alone control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetScrollDist(long double dist)
{
    FScrollDist = dist;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetPageDist
#
#   Purpose....: Set scroll page move distance for stand-alone control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetPageDist(long double dist)
{
    FPageDist = dist;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetScrollWidth
#
#   Purpose....: Set current width of scroll control button.
#                0.0 => min width
#                1.0 => no scroll area (full width)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetScrollWidth(long double relwidth)
{
    long double pos;
    int abswidth;

    if (FScrollSize - FCurrScrollButton > 0)
        pos = (long double)FScrollPos / (long double)(FScrollSize - FCurrScrollButton);
    else
        pos = 0.0;        

    abswidth = (int)(relwidth * (long double)FScrollSize);

    if (abswidth < FMinScrollButton)
        abswidth = FMinScrollButton;

    FCurrScrollButton = abswidth;

    SetScrollPos(pos);    
}

/*##########################################################################
#
#   Name       : TScrollControl::GetScrollWidth
#
#   Purpose....: Get current width of scroll control button.
#                0.0 => min width
#                1.0 => no scroll area (full width)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TScrollControl::GetScrollWidth()
{
    if (FScrollSize > 0)
        return (long double)FCurrScrollButton / (long double)FScrollSize;
    else
        return 0.0;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetScrollPos
#
#   Purpose....: Set current position of scroll control button.
#                0.0 => min position
#                1.0 => max position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetScrollPos(long double relpos)
{
    int availwidth;
    int abspos;

    if (relpos < 0.0)
        relpos = 0.0;

    if (relpos > 1.0)
        relpos = 1.0;

    availwidth = FScrollSize - FCurrScrollButton;

    if (availwidth > 0)
        abspos = (int)((long double)availwidth * relpos);        
    else
        abspos = 0;
    
    FScrollPos = abspos;

    Redraw();
    NotifyChanged();
}

/*##########################################################################
#
#   Name       : TScrollControl::GetScrollPos
#
#   Purpose....: Get current position of scroll control button.
#                0.0 => min position
#                1.0 => max position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TScrollControl::GetScrollPos()
{
    int availwidth;

    availwidth = FScrollSize - FCurrScrollButton;

    if (availwidth > 0)
        return (long double)FScrollPos / (long double)availwidth;
    else
        return 0.0;
}

/*##########################################################################
#
#   Name       : TScrollControl::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];

         Ini->GotoSection(IniSection);

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


    if (Ini->ReadVar("Up.BackColor.R", str, 255))
        FUp.BackR = atoi(str);

    if (Ini->ReadVar("Up.BackColor.G", str, 255))
        FUp.BackG = atoi(str);

    if (Ini->ReadVar("Up.BackColor.B", str, 255))
        FUp.BackB = atoi(str);


    if (Ini->ReadVar("Down.BackColor.R", str, 255))
        FDown.BackR = atoi(str);

    if (Ini->ReadVar("Down.BackColor.G", str, 255))
        FDown.BackG = atoi(str);

    if (Ini->ReadVar("Down.BackColor.B", str, 255))
        FDown.BackB = atoi(str);


    if (Ini->ReadVar("Disabled.BackColor.R", str, 255))
        FDisabled.BackR = atoi(str);

    if (Ini->ReadVar("Disabled.BackColor.G", str, 255))
        FDisabled.BackG = atoi(str);

    if (Ini->ReadVar("Disabled.BackColor.B", str, 255))
        FDisabled.BackB = atoi(str);


    if (Ini->ReadVar("Up.DrawColor.R", str, 255))
        FUp.DrawR = atoi(str);

    if (Ini->ReadVar("Up.DrawColor.G", str, 255))
        FUp.DrawG = atoi(str);

    if (Ini->ReadVar("Up.DraeColor.B", str, 255))
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

    TControl::Set(Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TScrollControl::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TScrollControl::SetUpShift
#
#   Purpose....: Set text shift for up-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpShift(int x, int y)
{
    FUp.ShiftX = x;
    FUp.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownShift
#
#   Purpose....: Set text shift for down-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownShift(int x, int y)
{
    FDown.ShiftX = x;
    FDown.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledShift
#
#   Purpose....: Set text shift for disabled-button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledShift(int x, int y)
{
    FDisabled.ShiftX = x;
    FDisabled.ShiftY = y;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetUpBackColor
#
#   Purpose....: Set back color for up scroll-bar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpBackColor(int r, int g, int b)
{
    FUp.BackR = r;
    FUp.BackG = g;
    FUp.BackB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownBackColor
#
#   Purpose....: Set back color for down scroll-bar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownBackColor(int r, int g, int b)
{
    FDown.BackR = r;
    FDown.BackG = g;
    FDown.BackB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledBackColor
#
#   Purpose....: Set back color for disabled scroll-bar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledBackColor(int r, int g, int b)
{
    FDisabled.BackR = r;
    FDisabled.BackG = g;
    FDisabled.BackB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetUpButtonColor
#
#   Purpose....: Set button color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpButtonColor(int r, int g, int b)
{
    FUp.ButtonR = r;
    FUp.ButtonG = g;
    FUp.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownButtonColor
#
#   Purpose....: Set button color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownButtonColor(int r, int g, int b)
{
    FDown.ButtonR = r;
    FDown.ButtonG = g;
    FDown.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledButtonColor
#
#   Purpose....: Set button color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledButtonColor(int r, int g, int b)
{
    FDisabled.ButtonR = r;
    FDisabled.ButtonG = g;
    FDisabled.ButtonB = b;
}

/*##########################################################################
#
#   Name       : TScrollContol::SetUpDrawColor
#
#   Purpose....: Set draw color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpDrawColor(int r, int g, int b)
{
    FUp.DrawR = r;
    FUp.DrawG = g;
    FUp.DrawB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownDrawColor
#
#   Purpose....: Set draw color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownDrawColor(int r, int g, int b)
{
    FDown.DrawR = r;
    FDown.DrawG = g;
    FDown.DrawB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledDrawColor
#
#   Purpose....: Set draw color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledDrawColor(int r, int g, int b)
{
    FDisabled.DrawR = r;
    FDisabled.DrawG = g;
    FDisabled.DrawB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetUpShadowColor
#
#   Purpose....: Set shadow color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpShadowColor(int r, int g, int b)
{
    FUp.ShadowR = r;
    FUp.ShadowG = g;
    FUp.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownShadowColor
#
#   Purpose....: Set shadow color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownShadowColor(int r, int g, int b)
{
    FDown.ShadowR = r;
    FDown.ShadowG = g;
    FDown.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledShadowColor
#
#   Purpose....: Set shadow color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledShadowColor(int r, int g, int b)
{
    FDisabled.ShadowR = r;
    FDisabled.ShadowG = g;
    FDisabled.ShadowB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetUpBorderWidth
#
#   Purpose....: Set up button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpBorderWidth(int width)
{
    FUp.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownBorderWidth
#
#   Purpose....: Set down button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownBorderWidth(int width)
{
    FDown.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledBorderWidth
#
#   Purpose....: Set disabled button border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledBorderWidth(int width)
{
    FDisabled.BorderWidth = width;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetUpLightBorderColor
#
#   Purpose....: Set light border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpLightBorderColor(int r, int g, int b)
{
    FUp.BorderLightR = r;
    FUp.BorderLightG = g;
    FUp.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownLightBorderColor
#
#   Purpose....: Set light border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownLightBorderColor(int r, int g, int b)
{
    FDown.BorderLightR = r;
    FDown.BorderLightG = g;
    FDown.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledLightBorderColor
#
#   Purpose....: Set light border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledLightBorderColor(int r, int g, int b)
{
    FDisabled.BorderLightR = r;
    FDisabled.BorderLightG = g;
    FDisabled.BorderLightB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetUpDarkBorderColor
#
#   Purpose....: Set drak border color for up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetUpDarkBorderColor(int r, int g, int b)
{
    FUp.BorderDarkR = r;
    FUp.BorderDarkG = g;
    FUp.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDownDarkBorderColor
#
#   Purpose....: Set dark border color for down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDownDarkBorderColor(int r, int g, int b)
{
    FDown.BorderDarkR = r;
    FDown.BorderDarkG = g;
    FDown.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::SetDisabledDarkBorderColor
#
#   Purpose....: Set dark border color for disabled button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::SetDisabledDarkBorderColor(int r, int g, int b)
{
    FDisabled.BorderDarkR = r;
    FDisabled.BorderDarkG = g;
    FDisabled.BorderDarkB = b;
}

/*##########################################################################
#
#   Name       : TScrollControl::GetParam
#
#   Purpose....: Get button params for a state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TScrollParam *TScrollControl::GetParam(int state)
{
    switch (state)
    {
        case STATE_UP:
            return &FUp;

        case STATE_DOWN:
            return &FDown;

        case STATE_DISABLED:
            return &FDisabled;
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TScrollControl::PaintButton
#
#   Purpose....: Paint a button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TScrollControl::PaintButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    int size;
    int i;

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
#   Name       : TVerScrollControl::TVerScrollControl
#
#   Purpose....: Vertical scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl::TVerScrollControl(TControlThread *dev, int xstart, int ystart, int width, int len)
 : TScrollControl(dev)
{
    Init();

    Resize(width, len);
    Move(xstart, ystart);
    Enable();
    Show();
}

/*##########################################################################
#
#   Name       : TVerScrollControl::TVerScrollControl
#
#   Purpose....: Vertical scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl::TVerScrollControl(TControl *control, int xstart, int ystart, int width, int len)
 : TScrollControl(control)
{
    Init();

    Resize(width, len);
    Move(xstart, ystart);
    Enable();
    Show();
}
    
/*##########################################################################
#
#   Name       : TVerScrollControl::TVerScrollControl
#
#   Purpose....: Vertical scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl::TVerScrollControl(TControlThread *dev)
 : TScrollControl(dev)
{
    Init();
}

/*##########################################################################
#
#   Name       : TVerScrollControl::TVerScrollControl
#
#   Purpose....: Vertical scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl::TVerScrollControl(TControl *control)
 : TScrollControl(control)
{
    Init();
}

/*##########################################################################
#
#   Name       : TVerScrollControl::~TVerScrollControl
#
#   Purpose....: Vertical scroll control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl::~TVerScrollControl()
{
}

/*##########################################################################
#
#   Name       : TVerScrollControl::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::Init()
{
    FWidth = 0;
    FSize = 0;
    FButtonSize = 0;

    FScrollPressed = FALSE;
    FUpScrollPressed = FALSE;
    FDownScrollPressed = FALSE;
    FUpPressed = FALSE;
    FDownPressed = FALSE;
}

/*##########################################################################
#
#   Name       : TVerScrollControl::DrawUpArrow
#
#   Purpose....: Draw up arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::DrawUpArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize)
{
    int width;
    int i;
    int xmid;
    int ymid;
    int xw;
    int yw;
    int w;
    
    if (xsize > 2 && ysize > 2)
    {
        width = (xsize + ysize) / 16;
        xmid = xsize / 2;
        xw = xmid - width - 1;
        yw = ysize - 2 * (width + 1);

        if (xw > yw)
            w = yw;
        else
            w = xw;

        ymid = ysize / 2 - 2 * w / 3;
         
                dev->DrawLine(xstart + xmid, ystart + ymid, xstart + xmid - w, ystart + ymid + w);
        dev->DrawLine(xstart + xmid, ystart + ymid, xstart + xmid + w, ystart + ymid + w);

                for (i = 0; i < width; i++)
                {
                dev->DrawLine(xstart + xmid, ystart + ymid + i, xstart + xmid - w, ystart + ymid + w + i);
            dev->DrawLine(xstart + xmid, ystart + ymid + i, xstart + xmid + w, ystart + ymid + w + i);

                dev->DrawLine(xstart + xmid, ystart + ymid - i, xstart + xmid - w, ystart + ymid + w - i);
            dev->DrawLine(xstart + xmid, ystart + ymid - i, xstart + xmid + w, ystart + ymid + w - i);
                  }

         }
}

/*##########################################################################
#
#   Name       : TVerScrollControl::DrawDownArrow
#
#   Purpose....: Draw down arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::DrawDownArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize)
{
    int width;
    int i;
    int xmid;
    int ymid;
    int xw;
    int yw;
    int w;
    
    if (xsize > 2 && ysize > 2)
    {
        width = (xsize + ysize) / 16;
        xmid = xsize / 2;
        xw = xmid - width - 1;
        yw = ysize - 2 * (width + 1);

        if (xw > yw)
            w = yw;
        else
            w = xw;

        ymid = ysize / 2 - 2 * w / 3;
         
                dev->DrawLine(xstart + xmid, ystart + ysize - 1 - ymid, xstart + xmid - w, ystart + ysize - 1 - ymid - w);
        dev->DrawLine(xstart + xmid, ystart + ysize - 1 - ymid, xstart + xmid + w, ystart + ysize - 1 - ymid - w);

                for (i = 0; i < width; i++)
                {
                dev->DrawLine(xstart + xmid, ystart + ysize - 1 - ymid + i, xstart + xmid - w, ystart + ysize - 1 - ymid - w + i);
            dev->DrawLine(xstart + xmid, ystart + ysize - 1 - ymid + i, xstart + xmid + w, ystart + ysize - 1 - ymid - w + i);

                dev->DrawLine(xstart + xmid, ystart + ysize - 1 - ymid - i, xstart + xmid - w, ystart + ysize - 1 - ymid - w - i);
            dev->DrawLine(xstart + xmid, ystart + ysize - 1 - ymid - i, xstart + xmid + w, ystart + ysize - 1 - ymid - w - i);
                 }
         }
}

/*##########################################################################
#
#   Name       : TVerScrollControl::DrawAliasedUpArrow
#
#   Purpose....: Draw aliased up arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::DrawAliasedUpArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize)
{
    xstart += Param.BorderWidth;
    ystart += Param.BorderWidth;
    xsize -= 2 * Param.BorderWidth;            
    ysize -= 2 * Param.BorderWidth;
        
    xstart += Param.ShiftX;
    ystart += Param.ShiftY;

    dev->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
    DrawUpArrow(dev, xstart, ystart, xsize, ysize);
    DrawUpArrow(dev, xstart + 1, ystart, xsize, ysize);
    DrawUpArrow(dev, xstart - 1, ystart, xsize, ysize);
    DrawUpArrow(dev, xstart, ystart + 1, xsize, ysize);
    DrawUpArrow(dev, xstart, ystart - 1, xsize, ysize);
    DrawUpArrow(dev, xstart + 1, ystart + 1, xsize, ysize);
    DrawUpArrow(dev, xstart - 1, ystart - 1, xsize, ysize);
    DrawUpArrow(dev, xstart - 1, ystart + 1, xsize, ysize);
    DrawUpArrow(dev, xstart + 1, ystart - 1, xsize, ysize);

    dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
    DrawUpArrow(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::DrawAliasedDownArrow
#
#   Purpose....: Draw aliased down arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::DrawAliasedDownArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize)
{
    xstart += Param.BorderWidth;
    ystart += Param.BorderWidth;
    xsize -= 2 * Param.BorderWidth;            
    ysize -= 2 * Param.BorderWidth;
        
    xstart += Param.ShiftX;
    ystart += FUp.ShiftY;

    dev->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
    DrawDownArrow(dev, xstart, ystart, xsize, ysize);
    DrawDownArrow(dev, xstart + 1, ystart, xsize, ysize);
    DrawDownArrow(dev, xstart - 1, ystart, xsize, ysize);
    DrawDownArrow(dev, xstart, ystart + 1, xsize, ysize);
    DrawDownArrow(dev, xstart, ystart - 1, xsize, ysize);
    DrawDownArrow(dev, xstart + 1, ystart + 1, xsize, ysize);
    DrawDownArrow(dev, xstart - 1, ystart - 1, xsize, ysize);
    DrawDownArrow(dev, xstart - 1, ystart + 1, xsize, ysize);
    DrawDownArrow(dev, xstart + 1, ystart - 1, xsize, ysize);

    dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
    DrawDownArrow(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::PaintUpButton
#
#   Purpose....: Paint up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintUpButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    PaintButton(dev, xstart, ystart, xsize, ysize, state);

    switch (state)
    {
        case STATE_UP:
            DrawAliasedUpArrow(dev, FUp, xstart, ystart, xsize, ysize);
            break;

        case STATE_DOWN:
            DrawAliasedUpArrow(dev, FDown, xstart, ystart, xsize, ysize);
            break;

        case STATE_DISABLED:
            DrawAliasedUpArrow(dev, FDisabled, xstart, ystart, xsize, ysize);
            break;
    }
}

/*##########################################################################
#
#   Name       : TVerScrollControl::PaintDownButton
#
#   Purpose....: Paint down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintDownButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    PaintButton(dev, xstart, ystart, xsize, ysize, state);

    switch (state)
    {
        case STATE_UP:
            DrawAliasedDownArrow(dev, FUp, xstart, ystart, xsize, ysize);
            break;

        case STATE_DOWN:
            DrawAliasedDownArrow(dev, FDown, xstart, ystart, xsize, ysize);
            break;

        case STATE_DISABLED:
            DrawAliasedDownArrow(dev, FDisabled, xstart, ystart, xsize, ysize);
            break;
    }
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintUpButton
#
#   Purpose....: Paint up button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintUpButton(TGraphicDevice *dev, int xstart, int ystart)
{
    if (IsEnabled())
    {
        if (FUpPressed)
            PaintUpButton(dev, xstart, ystart, FWidth, FButtonSize, STATE_DOWN);
        else
            PaintUpButton(dev, xstart, ystart, FWidth, FButtonSize, STATE_UP);
    }
    else
        PaintUpButton(dev, xstart, ystart, FWidth, FButtonSize, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintDownButton
#
#   Purpose....: Paint down button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintDownButton(TGraphicDevice *dev, int xstart, int ystart)
{
    if (IsEnabled())
    {
        if (FDownPressed)
            PaintDownButton(dev, xstart, ystart, FWidth, FButtonSize, STATE_DOWN);
        else
            PaintDownButton(dev, xstart, ystart, FWidth, FButtonSize, STATE_UP);
    }
    else
        PaintDownButton(dev, xstart, ystart, FWidth, FButtonSize, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::DrawScrollLine
#
#   Purpose....: Draw a single scroll line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::DrawScrollLine(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize)
{
    dev->SetFilledStyle();
    dev->DrawRect(xstart, ystart, xstart + xsize - 1, ystart + ysize - 1);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::DrawAliasedScrollLines
#
#   Purpose....: Draw aliased scroll lines
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::DrawAliasedScrollLines(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize)
{
    int width;
    int count;
    int linewidth;
    int totwidth;
    int i;
    int start;

    linewidth = FUp.BorderWidth;
    if (linewidth <= 0)
        linewidth = 1;

    width = linewidth + 3;
    count = ysize / width;

    if (count)
        count--;

    if (count > 4)
        count = 4;

    totwidth = count * width;
    start = (ysize - totwidth) / 2;
    ystart += start;

    start = xsize / 4;
    xstart += start;

    xstart += Param.ShiftX;
    ystart += Param.ShiftY;

    ystart++;
    xsize = xsize / 2;
    ysize = linewidth;

    for (i = 0; i < count; i++)
    {
        dev->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
        DrawScrollLine(dev, xstart, ystart, xsize, ysize);
        DrawScrollLine(dev, xstart + 1, ystart, xsize, ysize);
        DrawScrollLine(dev, xstart - 1, ystart, xsize, ysize);
        DrawScrollLine(dev, xstart, ystart + 1, xsize, ysize);
        DrawScrollLine(dev, xstart, ystart - 1, xsize, ysize);
        DrawScrollLine(dev, xstart + 1, ystart + 1, xsize, ysize);
        DrawScrollLine(dev, xstart - 1, ystart - 1, xsize, ysize);
        DrawScrollLine(dev, xstart - 1, ystart + 1, xsize, ysize);
        DrawScrollLine(dev, xstart + 1, ystart - 1, xsize, ysize);

        dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
        DrawScrollLine(dev, xstart, ystart, xsize, ysize);

        ystart += width;
    }
}

/*##########################################################################
#
#   Name       : TVerScrollControl::PaintScrollButton
#
#   Purpose....: Paint scroll button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    PaintButton(dev, xstart, ystart, xsize, ysize, state);

    switch (state)
    {
        case STATE_UP:
                    DrawAliasedScrollLines(dev, FUp, xstart, ystart, xsize, ysize);
                        break;

                case STATE_DOWN:
                        DrawAliasedScrollLines(dev, FDown, xstart, ystart, xsize, ysize);
                        break;

                case STATE_DISABLED:
            DrawAliasedScrollLines(dev, FDisabled, xstart, ystart, xsize, ysize);
            break;
    }
}

/*##########################################################################
#
#   Name       : TVerScrollControl::PaintScrollButton
#
#   Purpose....: Paint scroll button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart)
{
    if (IsEnabled())
    {
        if (FScrollPressed)
            PaintScrollButton(dev, xstart, ystart, FWidth, FCurrScrollButton, STATE_DOWN);
        else
            PaintScrollButton(dev, xstart, ystart, FWidth, FCurrScrollButton, STATE_UP);
    }
    else
        PaintScrollButton(dev, xstart, ystart, FWidth, FCurrScrollButton, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::PaintScrollArea
#
#   Purpose....: Paint scroll area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintScrollArea(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
         switch (state)
         {
                case STATE_UP:
                        dev->SetDrawColor(FUp.BackR, FUp.BackG, FUp.BackB);
                         break;

                case STATE_DOWN:
                        dev->SetDrawColor(FDown.BackR, FDown.BackG, FDown.BackB);
                        break;

                case STATE_DISABLED:
                        dev->SetDrawColor(FDisabled.BackR, FDisabled.BackG, FDisabled.BackB);
                        break;
         }
         
         dev->SetFilledStyle();
         dev->DrawRect(xstart, ystart, xstart + xsize - 1, ystart + ysize - 1);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::PaintUpScrollArea
#
#   Purpose....: Paint up scroll area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintUpScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size)
{
    if (IsEnabled())
    {
        if (FUpScrollPressed)
            PaintScrollArea(dev, xstart, ystart, FWidth, size, STATE_DOWN);
        else
            PaintScrollArea(dev, xstart, ystart, FWidth, size, STATE_UP);
    }
    else
        PaintScrollArea(dev, xstart, ystart, FWidth, size, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::PaintDownScrollArea
#
#   Purpose....: Paint down scroll area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::PaintDownScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size)
{
    if (IsEnabled())
    {
        if (FDownScrollPressed)
            PaintScrollArea(dev, xstart, ystart, FWidth, size, STATE_DOWN);
        else
            PaintScrollArea(dev, xstart, ystart, FWidth, size, STATE_UP);
    }
    else
                  PaintScrollArea(dev, xstart, ystart, FWidth, size, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::ClearButtons
#
#   Purpose....: Clear button states
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::ClearButtons()
{
    int redraw = FALSE;

    if (FScrollPressed)
    {
        redraw = TRUE;
        FScrollPressed = FALSE;
    }

    if (FUpScrollPressed)
    {
        redraw = TRUE;
        FUpScrollPressed = FALSE;
    }

    if (FDownScrollPressed)
    {
        redraw = TRUE;
        FDownScrollPressed = FALSE;
    }

    if (FUpPressed)
    {
        redraw = TRUE;
        FUpPressed = FALSE;
        FRedrawButtons = TRUE;        
    }

    if (FDownPressed)
    {
        redraw = TRUE;
        FDownPressed = FALSE;
        FRedrawButtons = TRUE;        
    }

    if (redraw)
        Redraw();
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnScrollUp
#
#   Purpose....: Scroll up with arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::OnScrollUp()
{
    long double pos = GetScrollPos();

    pos -= FScrollDist;
    SetScrollPos(pos);

    PutKey(VK_UP);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnScrollDown
#
#   Purpose....: Scroll down with arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::OnScrollDown()
{
    long double pos = GetScrollPos();

    pos += FScrollDist;
    SetScrollPos(pos);

    PutKey(VK_DOWN);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnScrollPageUp
#
#   Purpose....: Page up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::OnScrollPageUp()
{
    long double pos = GetScrollPos();

    pos -= FPageDist;
    SetScrollPos(pos);

    PutKey(VK_NUMPAD9);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnScrollPageDown
#
#   Purpose....: Page down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::OnScrollPageDown()
{
    long double pos = GetScrollPos();

    pos += FPageDist;
    SetScrollPos(pos);

    PutKey(VK_NUMPAD3);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnMove
#
#   Purpose....: Move ruler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::OnMove(long double relpos)
{
    SetScrollPos(relpos);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnMouseMove
#
#   Purpose....: On mouse move event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVerScrollControl::OnMouseMove(int x, int y, int ButtonState, int KeyState)
{
    int availwidth;
    int dcoord;
    long double dpos;
    int xstart, ystart;

    if (FScrollPressed && IsInside(x, y))
    {
        GetPos(&xstart, &ystart);
        y -= ystart;

        availwidth = FScrollSize - FCurrScrollButton;

        if (availwidth > 0)
        {
            dcoord = y - FPressedCoord;
            dpos = FPressedBase + (long double)dcoord / (long double)availwidth;

            if (dpos < 0.0)
                dpos = 0.0;

            if (dpos > 1.0)
                dpos = 1.0;
            
            OnMove(dpos);
        }    
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnLeftUp
#
#   Purpose....: Handle left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVerScrollControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    ClearButtons();
    return IsInside(x, y);
}

/*##########################################################################
#
#   Name       : TVerScrollControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVerScrollControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    int xstart, ystart;

    ClearButtons();
        
    if (IsInside(x, y))
    {
        GetPos(&xstart, &ystart);
        y -= ystart;

        FRepeatTime = TDateTime();
        FRepeatTime.AddMilli(START_TIMEOUT);

        if (y < FButtonSize)
        {
            FUpPressed = TRUE;
            FRedrawButtons = TRUE;
            OnScrollUp();
            return TRUE;
        }

        if (y > FSize - FButtonSize)
        {
            FDownPressed = TRUE;
            FRedrawButtons = TRUE;
            OnScrollDown();
            return TRUE;
        }

        if (y < FButtonSize + FScrollPos)
        {
            FUpScrollPressed = TRUE;
            OnScrollPageUp();
            return TRUE;
        }

        if (y < FButtonSize + FScrollPos + FCurrScrollButton)
        {
            FScrollPressed = TRUE;
            FPressedBase = GetScrollPos();
            FPressedCoord = y;
            Redraw();
            return TRUE;
        }

        FDownScrollPressed = TRUE;
        OnScrollPageDown();
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TVerScrollControl::NotifyResize
#
#   Purpose....: Notify control resize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::NotifyResize()
{
    int x, y;

    GetSize(&x, &y);

    FWidth = x;
    FSize = y;

    if (3 * y > x)
        FButtonSize = x;
    else
        FButtonSize = y / 3;

    FScrollSize = y - 2 * FButtonSize;  

    FMinScrollButton = FButtonSize / 3;
    
    if (FMinScrollButton < 3 * FUp.BorderWidth)
        FMinScrollButton = 3 * FUp.BorderWidth;

     FCurrScrollButton = FMinScrollButton;
}

/*##########################################################################
#
#   Name       : TVerScrollControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerScrollControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int xmax = xmin + width - 1;
    int ymax = ymin + height - 1;

    TControl::Paint(dev, xmin, ymin, width, height);

        if (IsVisible())
        {
        SetClipRect(    dev,
                        xmin, ymin,
                                xmax, ymax);

/*        if (FRedrawButtons) */
        {
            FRedrawButtons = FALSE;
            
            PaintUpButton(dev, xmin, ymin);
                PaintDownButton(dev, xmin, ymin + FSize - FButtonSize);
            }
            
            PaintUpScrollArea(dev, xmin, ymin + FButtonSize, FScrollPos);
            PaintDownScrollArea(dev, xmin, ymin + FButtonSize + FScrollPos + FCurrScrollButton, FScrollSize - FCurrScrollButton - FScrollPos);
            PaintScrollButton(dev, xmin, ymin + FButtonSize + FScrollPos);

        if (FUpPressed || FDownPressed || FUpScrollPressed || FDownScrollPressed)
        {
            if (FRepeatTime.HasExpired())
                {
                FRepeatTime = TDateTime();
                    FRepeatTime.AddMilli(REPEAT_TIMEOUT);

                if (FUpPressed)
                    OnScrollUp();

                if (FDownPressed)
                    OnScrollDown();

                if (FUpScrollPressed)
                    OnScrollPageUp();

                if (FDownScrollPressed)
                    OnScrollPageDown();

                }

            Redraw(REPEAT_TIMEOUT);
            }
        }
}
    
/*##########################################################################
#
#   Name       : THorScrollControl::THorScrollControl
#
#   Purpose....: Horizontal scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl::THorScrollControl(TControlThread *dev, int xstart, int ystart, int width, int len)
 : TScrollControl(dev)
{
    Init();

    Resize(len, width);
    Move(xstart, ystart);
    Enable();
    Show();
}

/*##########################################################################
#
#   Name       : THorScrollControl::THorScrollControl
#
#   Purpose....: Horisontal scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl::THorScrollControl(TControl *control, int xstart, int ystart, int width, int len)
 : TScrollControl(control)
{
    Init();

    Resize(len, width);
    Move(xstart, ystart);
    Enable();
    Show();
}
    
/*##########################################################################
#
#   Name       : THorScrollControl::THorScrollControl
#
#   Purpose....: Horisontal scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl::THorScrollControl(TControlThread *dev)
 : TScrollControl(dev)
{
    Init();
}

/*##########################################################################
#
#   Name       : THorScrollControl::THorScrollControl
#
#   Purpose....: Horisontal scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl::THorScrollControl(TControl *control)
 : TScrollControl(control)
{
    Init();
}

/*##########################################################################
#
#   Name       : THorScrollControl::~THorScrollControl
#
#   Purpose....: Horisontal scroll control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl::~THorScrollControl()
{
}

/*##########################################################################
#
#   Name       : THorScrollControl::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::Init()
{
    FWidth = 0;
    FSize = 0;
    FButtonSize = 0;
    FScrollSize = 0;

    FScrollPressed = FALSE;
    FLeftScrollPressed = FALSE;
    FRightScrollPressed = FALSE;
    FLeftPressed = FALSE;
    FRightPressed = FALSE;
}

/*##########################################################################
#
#   Name       : THorScrollControl::DrawLeftArrow
#
#   Purpose....: Draw left arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::DrawLeftArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize)
{
    int width;
    int i;
    int xmid;
    int ymid;
    int xw;
    int yw;
    int w;
    
    if (xsize > 2 && ysize > 2)
    {
        width = (xsize + ysize) / 16;
        ymid = ysize / 2;
        yw = ymid - width - 1;
        xw = xsize - 2 * (width + 1);

        if (xw > yw)
            w = yw;
        else
            w = xw;

        xmid = xsize / 2 - 2 * w / 3;
         
                dev->DrawLine(xstart + xmid, ystart + ymid, xstart + xmid + w, ystart + ymid - w);
        dev->DrawLine(xstart + xmid, ystart + ymid, xstart + xmid + w, ystart + ymid + w);

                for (i = 0; i < width; i++)
                {
                dev->DrawLine(xstart + xmid + i, ystart + ymid, xstart + xmid + w + i, ystart + ymid - w);
            dev->DrawLine(xstart + xmid + i, ystart + ymid, xstart + xmid + w + i, ystart + ymid + w);

                dev->DrawLine(xstart + xmid - i, ystart + ymid, xstart + xmid + w - i, ystart + ymid - w);
            dev->DrawLine(xstart + xmid - i, ystart + ymid, xstart + xmid + w - i, ystart + ymid + w);
                  }

         }
}

/*##########################################################################
#
#   Name       : THorScrollControl::DrawRightArrow
#
#   Purpose....: Draw right arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::DrawRightArrow(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize)
{
    int width;
    int i;
    int xmid;
    int ymid;
    int xw;
    int yw;
    int w;
    
    if (xsize > 2 && ysize > 2)
    {
        width = (xsize + ysize) / 16;
        ymid = ysize / 2;
        yw = ymid - width - 1;
        xw = xsize - 2 * (width + 1);

        if (xw > yw)
            w = yw;
        else
            w = xw;

        xmid = xsize / 2 - 2 * w / 3;
         
                dev->DrawLine(xstart + xsize - 1 - xmid, ystart + ymid, xstart + xsize - 1 - xmid - w, ystart + ymid - w);
        dev->DrawLine(xstart + xsize - 1 - xmid, ystart + ymid, xstart + xsize - 1 - xmid - w, ystart + ymid + w);

                for (i = 0; i < width; i++)
                {
                dev->DrawLine(xstart + xsize - 1 - xmid + i, ystart + ymid, xstart + xsize - 1 - xmid - w + i, ystart + ymid - w);
            dev->DrawLine(xstart + xsize - 1 - xmid + i, ystart + ymid, xstart + xsize - 1 - xmid - w + i, ystart + ymid + w);

                dev->DrawLine(xstart + xsize - 1 - xmid - i, ystart + ymid, xstart + xsize - 1 - xmid - w - i, ystart + ymid - w);
            dev->DrawLine(xstart + xsize - 1 - xmid - i, ystart + ymid, xstart + xsize - 1 - xmid - w - i, ystart + ymid + w);
                 }
         }
}

/*##########################################################################
#
#   Name       : THorScrollControl::DrawAliasedLeftArrow
#
#   Purpose....: Draw aliased left button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::DrawAliasedLeftArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize)
{
         xstart += Param.BorderWidth;
         ystart += Param.BorderWidth;
         xsize -= 2 * Param.BorderWidth;
         ysize -= 2 * Param.BorderWidth;

         xstart += Param.ShiftX;
         ystart += Param.ShiftY;

         dev->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
         DrawLeftArrow(dev, xstart, ystart, xsize, ysize);
         DrawLeftArrow(dev, xstart + 1, ystart, xsize, ysize);
         DrawLeftArrow(dev, xstart - 1, ystart, xsize, ysize);
         DrawLeftArrow(dev, xstart, ystart + 1, xsize, ysize);
         DrawLeftArrow(dev, xstart, ystart - 1, xsize, ysize);
         DrawLeftArrow(dev, xstart + 1, ystart + 1, xsize, ysize);
         DrawLeftArrow(dev, xstart - 1, ystart - 1, xsize, ysize);
         DrawLeftArrow(dev, xstart - 1, ystart + 1, xsize, ysize);
         DrawLeftArrow(dev, xstart + 1, ystart - 1, xsize, ysize);

         dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
         DrawLeftArrow(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : THorScrollControl::DrawAliasedRightButton
#
#   Purpose....: Draw aliased right button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::DrawAliasedRightArrow(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize)
{
    xstart += Param.BorderWidth;
    ystart += Param.BorderWidth;
    xsize -= 2 * Param.BorderWidth;            
    ysize -= 2 * Param.BorderWidth;
        
    xstart += Param.ShiftX;
    ystart += Param.ShiftY;

    dev->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
    DrawRightArrow(dev, xstart, ystart, xsize, ysize);
    DrawRightArrow(dev, xstart + 1, ystart, xsize, ysize);
    DrawRightArrow(dev, xstart - 1, ystart, xsize, ysize);
    DrawRightArrow(dev, xstart, ystart + 1, xsize, ysize);
    DrawRightArrow(dev, xstart, ystart - 1, xsize, ysize);
    DrawRightArrow(dev, xstart + 1, ystart + 1, xsize, ysize);
    DrawRightArrow(dev, xstart - 1, ystart - 1, xsize, ysize);
    DrawRightArrow(dev, xstart - 1, ystart + 1, xsize, ysize);
    DrawRightArrow(dev, xstart + 1, ystart - 1, xsize, ysize);

    dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
    DrawRightArrow(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintLeftButton
#
#   Purpose....: Paint left button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintLeftButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    PaintButton(dev, xstart, ystart, xsize, ysize, state);

    switch (state)
    {
        case STATE_UP:
                                DrawAliasedLeftArrow(dev, FUp, xstart, ystart, xsize, ysize);
                                break;

                  case STATE_DOWN:
                                DrawAliasedLeftArrow(dev, FDown, xstart, ystart, xsize, ysize);
                                break;

                  case STATE_DISABLED:
                                DrawAliasedLeftArrow(dev, FDisabled, xstart, ystart, xsize, ysize);
            break;
    }
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintRightButton
#
#   Purpose....: Paint right button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintRightButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    PaintButton(dev, xstart, ystart, xsize, ysize, state);

    switch (state)
    {
        case STATE_UP:
                                DrawAliasedRightArrow(dev, FUp, xstart, ystart, xsize, ysize);
                                break;

                  case STATE_DOWN:
                                DrawAliasedRightArrow(dev, FDown, xstart, ystart, xsize, ysize);
                                break;

                  case STATE_DISABLED:
            DrawAliasedRightArrow(dev, FDisabled, xstart, ystart, xsize, ysize);
            break;
    }
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintLeftButton
#
#   Purpose....: Paint left button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintLeftButton(TGraphicDevice *dev, int xstart, int ystart)
{
    if (IsEnabled())
    {
        if (FLeftPressed)
            PaintLeftButton(dev, xstart, ystart, FButtonSize, FWidth, STATE_DOWN);
        else
            PaintLeftButton(dev, xstart, ystart, FButtonSize, FWidth, STATE_UP);
    }
    else
        PaintLeftButton(dev, xstart, ystart, FButtonSize, FWidth, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintRightButton
#
#   Purpose....: Paint right button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintRightButton(TGraphicDevice *dev, int xstart, int ystart)
{
    if (IsEnabled())
    {
        if (FRightPressed)
            PaintRightButton(dev, xstart, ystart, FButtonSize, FWidth, STATE_DOWN);
        else
            PaintRightButton(dev, xstart, ystart, FButtonSize, FWidth, STATE_UP);
    }
    else
        PaintRightButton(dev, xstart, ystart, FButtonSize, FWidth, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : THorScrollControl::DrawScrollLine
#
#   Purpose....: Draw a single scroll line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::DrawScrollLine(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize)
{
    dev->SetFilledStyle();
    dev->DrawRect(xstart, ystart, xstart + xsize - 1, ystart + ysize - 1);
}

/*##########################################################################
#
#   Name       : THorScrollControl::DrawAliasedScrollLines
#
#   Purpose....: Draw aliased scroll lines
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::DrawAliasedScrollLines(TGraphicDevice *dev, TScrollParam &Param, int xstart, int ystart, int xsize, int ysize)
{
    int width;
    int count;
    int linewidth;
    int totwidth;
    int i;
    int start;

         linewidth = FUp.BorderWidth;
    if (linewidth <= 0)
        linewidth = 1;

    width = linewidth + 3;
    count = xsize / width;

    if (count)
        count--;

    if (count > 4)
        count = 4;

    totwidth = count * width;
    start = (xsize - totwidth) / 2;
    xstart += start;

    start = ysize / 4;
    ystart += start;

    xstart += Param.ShiftX;
    ystart += Param.ShiftY;

    xstart++;
    ysize = ysize / 2;
    xsize = linewidth;

    for (i = 0; i < count; i++)
    {
        dev->SetDrawColor(Param.ShadowR, Param.ShadowG, Param.ShadowB);
        DrawScrollLine(dev, xstart, ystart, xsize, ysize);
        DrawScrollLine(dev, xstart + 1, ystart, xsize, ysize);
        DrawScrollLine(dev, xstart - 1, ystart, xsize, ysize);
        DrawScrollLine(dev, xstart, ystart + 1, xsize, ysize);
        DrawScrollLine(dev, xstart, ystart - 1, xsize, ysize);
        DrawScrollLine(dev, xstart + 1, ystart + 1, xsize, ysize);
        DrawScrollLine(dev, xstart - 1, ystart - 1, xsize, ysize);
        DrawScrollLine(dev, xstart - 1, ystart + 1, xsize, ysize);
        DrawScrollLine(dev, xstart + 1, ystart - 1, xsize, ysize);

        dev->SetDrawColor(Param.DrawR, Param.DrawG, Param.DrawB);
        DrawScrollLine(dev, xstart, ystart, xsize, ysize);

        xstart += width;
    }
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintScrollButton
#
#   Purpose....: Paint scroll button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
    PaintButton(dev, xstart, ystart, xsize, ysize, state);

    switch (state)
    {
        case STATE_UP:
                    DrawAliasedScrollLines(dev, FUp, xstart, ystart, xsize, ysize);
                        break;

                case STATE_DOWN:
                        DrawAliasedScrollLines(dev, FDown, xstart, ystart, xsize, ysize);
                        break;

                case STATE_DISABLED:
            DrawAliasedScrollLines(dev, FDisabled, xstart, ystart, xsize, ysize);
            break;
    }
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintScrollButton
#
#   Purpose....: Paint scroll button
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintScrollButton(TGraphicDevice *dev, int xstart, int ystart)
{
    if (IsEnabled())
    {
        if (FScrollPressed)
            PaintScrollButton(dev, xstart, ystart, FCurrScrollButton, FWidth, STATE_DOWN);
        else
            PaintScrollButton(dev, xstart, ystart, FCurrScrollButton, FWidth, STATE_UP);
    }
    else
        PaintScrollButton(dev, xstart, ystart, FCurrScrollButton, FWidth, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintScrollArea
#
#   Purpose....: Paint scroll area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintScrollArea(TGraphicDevice *dev, int xstart, int ystart, int xsize, int ysize, int state)
{
         switch (state)
         {
                case STATE_UP:
                        dev->SetDrawColor(FUp.BackR, FUp.BackG, FUp.BackB);
                         break;

                case STATE_DOWN:
                        dev->SetDrawColor(FDown.BackR, FDown.BackG, FDown.BackB);
                        break;

                case STATE_DISABLED:
                        dev->SetDrawColor(FDisabled.BackR, FDisabled.BackG, FDisabled.BackB);
                        break;
         }
         
         dev->SetFilledStyle();
         dev->DrawRect(xstart, ystart, xstart + xsize - 1, ystart + ysize - 1);
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintLeftScrollArea
#
#   Purpose....: Paint left scroll area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintLeftScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size)
{
    if (IsEnabled())
    {
        if (FLeftScrollPressed)
            PaintScrollArea(dev, xstart, ystart, size, FWidth, STATE_DOWN);
        else
            PaintScrollArea(dev, xstart, ystart, size, FWidth, STATE_UP);
    }
    else
        PaintScrollArea(dev, xstart, ystart, size, FWidth, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : THorScrollControl::PaintRightScrollArea
#
#   Purpose....: Paint right scroll area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::PaintRightScrollArea(TGraphicDevice *dev, int xstart, int ystart, int size)
{
    if (IsEnabled())
    {
        if (FRightScrollPressed)
            PaintScrollArea(dev, xstart, ystart, size, FWidth, STATE_DOWN);
        else
            PaintScrollArea(dev, xstart, ystart, size, FWidth, STATE_UP);
    }
    else
        PaintScrollArea(dev, xstart, ystart, size, FWidth, STATE_DISABLED);
}

/*##########################################################################
#
#   Name       : THorScrollControl::ClearButtons
#
#   Purpose....: Clear button states
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::ClearButtons()
{
    int redraw = FALSE;

    if (FScrollPressed)
    {
        redraw = TRUE;
        FScrollPressed = FALSE;
    }

    if (FLeftScrollPressed)
    {
        redraw = TRUE;
        FLeftScrollPressed = FALSE;
    }

    if (FRightScrollPressed)
    {
        redraw = TRUE;
        FRightScrollPressed = FALSE;
    }

    if (FLeftPressed)
    {
        redraw = TRUE;
        FLeftPressed = FALSE;
        FRedrawButtons = TRUE;    
    }

    if (FRightPressed)
    {
        redraw = TRUE;
        FRightPressed = FALSE;
        FRedrawButtons = TRUE;    
    }

    if (redraw)
        Redraw();
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnScrollLeft
#
#   Purpose....: Scroll left with arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::OnScrollLeft()
{
    long double pos = GetScrollPos();

    pos -= FScrollDist;
    SetScrollPos(pos);

    PutKey(VK_LEFT);
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnScrollRight
#
#   Purpose....: Scroll right with arrow
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::OnScrollRight()
{
    long double pos = GetScrollPos();

    pos += FScrollDist;
    SetScrollPos(pos);

    PutKey(VK_RIGHT);
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnScrollPageLeft
#
#   Purpose....: Page left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::OnScrollPageLeft()
{
    long double pos = GetScrollPos();

    pos -= FPageDist;
    SetScrollPos(pos);
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnScrollPageRight
#
#   Purpose....: Page right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::OnScrollPageRight()
{
    long double pos = GetScrollPos();

    pos += FPageDist;
    SetScrollPos(pos);
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnMove
#
#   Purpose....: Move ruler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::OnMove(long double relpos)
{
    SetScrollPos(relpos);
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnMouseMove
#
#   Purpose....: On mouse move event
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THorScrollControl::OnMouseMove(int x, int y, int ButtonState, int KeyState)
{
    int availwidth;
    int dcoord;
    long double dpos;
    int xstart, ystart;

    if (FScrollPressed && IsInside(x, y))
    {
        GetPos(&xstart, &ystart);
        x -= xstart;

        availwidth = FScrollSize - FCurrScrollButton;

        if (availwidth > 0)
        {
            dcoord = x - FPressedCoord;
            dpos = FPressedBase + (long double)dcoord / (long double)availwidth;

            if (dpos < 0.0)
                dpos = 0.0;

            if (dpos > 1.0)
                dpos = 1.0;
            
            OnMove(dpos);
        }    
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnLeftUp
#
#   Purpose....: Handle left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THorScrollControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    ClearButtons();
    return IsInside(x, y);
}

/*##########################################################################
#
#   Name       : THorScrollControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THorScrollControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    int xstart, ystart;

    ClearButtons();
        
    if (IsInside(x, y))
    {
        GetPos(&xstart, &ystart);
        x -= xstart;

        FRepeatTime = TDateTime();
        FRepeatTime.AddMilli(START_TIMEOUT);

        if (x < FButtonSize)
        {
            FLeftPressed = TRUE;
            FRedrawButtons = TRUE;    
            OnScrollLeft();
            return TRUE;
        }

        if (x > FSize - FButtonSize)
        {
            FRightPressed = TRUE;
            FRedrawButtons = TRUE;    
            OnScrollRight();
            return TRUE;
        }

        if (x < FButtonSize + FScrollPos)
        {
            FLeftScrollPressed = TRUE;
            OnScrollPageLeft();
            return TRUE;
        }

        if (x < FButtonSize + FScrollPos + FCurrScrollButton)
        {
            FScrollPressed = TRUE;
            FPressedBase = GetScrollPos();
            FPressedCoord = x;
            Redraw();
            return TRUE;
        }

        FRightScrollPressed = TRUE;
        OnScrollPageRight();
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : THorScrollControl::NotifyResize
#
#   Purpose....: Notify control resize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::NotifyResize()
{
    int x, y;

    GetSize(&x, &y);

    FWidth = y;
    FSize = x;

    if (3 * x > y)
        FButtonSize = y;
    else
        FButtonSize = x / 3;

    FScrollSize = x - 2 * FButtonSize;  

    FMinScrollButton = FButtonSize / 3;
    
    if (FMinScrollButton < 3 * FUp.BorderWidth)
        FMinScrollButton = 3 * FUp.BorderWidth;

     FCurrScrollButton = FMinScrollButton;
}

/*##########################################################################
#
#   Name       : THorScrollControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorScrollControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int xmax = xmin + width - 1;
    int ymax = ymin + height - 1;

    TControl::Paint(dev, xmin, ymin, width, height);

        if (IsVisible())
        {
        SetClipRect(    dev,
                        xmin, ymin,
                                xmax, ymax);

/*        if (FRedrawButtons) */
        {
            FRedrawButtons = FALSE;

            PaintLeftButton(dev, xmin, ymin);
            PaintRightButton(dev, xmin + FSize - FButtonSize, ymin);
        }
        
            PaintLeftScrollArea(dev, xmin + FButtonSize, ymin, FScrollPos);
            PaintRightScrollArea(dev, xmin + FButtonSize + FScrollPos + FCurrScrollButton, ymin, FScrollSize - FCurrScrollButton - FScrollPos);
            PaintScrollButton(dev, xmin + FButtonSize + FScrollPos, ymin);

        if (FLeftPressed || FRightPressed || FLeftScrollPressed || FRightScrollPressed)
        {
            if (FRepeatTime.HasExpired())
                {
                FRepeatTime = TDateTime();
                    FRepeatTime.AddMilli(REPEAT_TIMEOUT);

                if (FLeftPressed)
                    OnScrollLeft();

                if (FRightPressed)
                    OnScrollRight();

                if (FLeftScrollPressed)
                    OnScrollPageLeft();

                if (FRightScrollPressed)
                    OnScrollPageRight();
                }

            Redraw(REPEAT_TIMEOUT);
            }
        }
}
