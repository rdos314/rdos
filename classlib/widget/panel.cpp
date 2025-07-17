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
# panel.cpp
# Graphics panel control class
#
########################################################################*/

#include <string.h>

#include "panel.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TPanelScrollFactory::TPanelScrollFactory
#
#   Purpose....: Panel scroll factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelScrollFactory::TPanelScrollFactory(int width)
{
    FScrollWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelScrollFactory::~TPanelScrollFactory
#
#   Purpose....: Panel scroll factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelScrollFactory::~TPanelScrollFactory()
{
}

/*##########################################################################
#
#   Name       : TPanelScrollFactory::CreateVer
#
#   Purpose....: Create vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerPanelScrollControl *TPanelScrollFactory::CreateVer(TPanelControl *panel)
{
        TVerPanelScrollControl *scroll;

        scroll = new TVerPanelScrollControl(panel, FScrollWidth);

        SetParam(scroll);

        return scroll;
}

/*##########################################################################
#
#   Name       : TPanelScrollFactory::CreateHor
#
#   Purpose....: Create horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorPanelScrollControl *TPanelScrollFactory::CreateHor(TPanelControl *panel)
{
        THorPanelScrollControl *scroll;

        scroll = new THorPanelScrollControl(panel, FScrollWidth);

    SetParam(scroll);

        return scroll;
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::TVerPanelScrollControl
#
#   Purpose....: Vertical panel scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerPanelScrollControl::TVerPanelScrollControl(TPanelControl *panel, int width)
 : TVerScrollControl(panel)
{
    FPanel = panel;
    FCreateWidth = width;
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::~TVerPanelScrollControl
#
#   Purpose....: Vertical panel scroll control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerPanelScrollControl::~TVerPanelScrollControl()
{
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::GetWidth
#
#   Purpose....: Get width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVerPanelScrollControl::GetWidth()
{
    return FCreateWidth;
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::OnScrollUp
#
#   Purpose....: Scroll up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerPanelScrollControl::OnScrollUp()
{
    FPanel->ScrollUp();
    Redraw();
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::OnScrollDown
#
#   Purpose....: Scroll down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerPanelScrollControl::OnScrollDown()
{
    FPanel->ScrollDown();
    Redraw();
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::OnScrollPageUp
#
#   Purpose....: Page up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerPanelScrollControl::OnScrollPageUp()
{
    FPanel->PageUp();
    Redraw();
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::OnScrollPageDown
#
#   Purpose....: Page down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerPanelScrollControl::OnScrollPageDown()
{
    FPanel->PageDown();
    Redraw();
}

/*##########################################################################
#
#   Name       : TVerPanelScrollControl::OnMove
#
#   Purpose....: Move ruler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVerPanelScrollControl::OnMove(long double relpos)
{
    FPanel->VerMove(relpos);
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::THorPanelScrollControl
#
#   Purpose....: Horisontal panel scroll control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorPanelScrollControl::THorPanelScrollControl(TPanelControl *panel, int width)
 : THorScrollControl(panel)
{
    FPanel = panel;
    FCreateWidth = width;
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::~THorPanelScrollControl
#
#   Purpose....: Horisontal panel scroll control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorPanelScrollControl::~THorPanelScrollControl()
{
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::GetWidth
#
#   Purpose....: Get width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THorPanelScrollControl::GetWidth()
{
    return FCreateWidth;
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::OnScrollLeft
#
#   Purpose....: Scroll left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorPanelScrollControl::OnScrollLeft()
{
    FPanel->ScrollLeft();
    Redraw();
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::OnScrollRight
#
#   Purpose....: Scroll right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorPanelScrollControl::OnScrollRight()
{
    FPanel->ScrollRight();
    Redraw();
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::OnScrollPageLeft
#
#   Purpose....: Page left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorPanelScrollControl::OnScrollPageLeft()
{
    FPanel->PageLeft();
    Redraw();
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::OnScrollPageRight
#
#   Purpose....: Page right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorPanelScrollControl::OnScrollPageRight()
{
    FPanel->PageRight();
    Redraw();
}

/*##########################################################################
#
#   Name       : THorPanelScrollControl::OnMove
#
#   Purpose....: Move ruler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THorPanelScrollControl::OnMove(long double relpos)
{
    FPanel->HorMove(relpos);
}

/*##########################################################################
#
#   Name       : TPanelFactory::TPanelFactory
#
#   Purpose....: Button factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelFactory::TPanelFactory()
{
    Init();
}

/*##########################################################################
#
#   Name       : TPanelFactory::~TPanelFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelFactory::~TPanelFactory()
{
}

/*##########################################################################
#
#   Name       : TPanelFactory::Init
#
#   Purpose....: Init default values
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::Init()
{
    FBackground = 0;

    FBackR = 255;
    FBackG = 255;
    FBackB = 255;

    FBackTrans = FALSE;
    
    FBorderR = 0;
    FBorderG = 0;
    FBorderB = 0;

    FBorderTrans = FALSE;
    
    FDisabledColorUsed = FALSE;

    FUpperWidth = 2;
    FLowerWidth = 2;
    FLeftWidth = 2;
    FRightWidth = 2;

    FScrollFact = 0;
}

/*##########################################################################
#
#   Name       : TPanelFactory::DefineScroll
#
#   Purpose....: Define scroll factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::DefineScroll(TPanelScrollFactory *fact)
{
    FScrollFact = fact;
}

/*##########################################################################
#
#   Name       : TPanelFactory::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int HasWidth;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("BackColor.R", str, 255))
    {
        FBackR = atoi(str);
        FBackTrans = FALSE;
    }
    
    if (Ini->ReadVar("BackColor.G", str, 255))
    {
        FBackG = atoi(str);
        FBackTrans = FALSE;
    }

    if (Ini->ReadVar("BackColor.B", str, 255))
    {
        FBackB = atoi(str);
        FBackTrans = FALSE;
    }
    
    if (Ini->ReadVar("Transparent", str, 255))
        FBackTrans = TRUE;

    if (Ini->ReadVar("BorderColor.R", str, 255))
        FBorderR = atoi(str);
    
    if (Ini->ReadVar("BorderColor.G", str, 255))
        FBorderG = atoi(str);

    if (Ini->ReadVar("BorderColor.B", str, 255))
        FBorderB = atoi(str);


    if (Ini->ReadVar("DisabledColor.R", str, 255))
    {
        FDisabledR = atoi(str);
        FDisabledColorUsed = TRUE;
    }
    
    if (Ini->ReadVar("DisabledColor.G", str, 255))
    {
        FDisabledG = atoi(str);
        FDisabledColorUsed = TRUE;
    }

    if (Ini->ReadVar("DisabledColor.B", str, 255))
    {
        FDisabledB = atoi(str);
        FDisabledColorUsed = TRUE;
    }

    HasWidth = Ini->ReadVar("Width", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("UpperWidth", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("LowerWidth", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("LeftWidth", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("RightWidth", str, 255);

    if (HasWidth)
    {
        FUpperWidth = 0;
        FLowerWidth = 0;
        FLeftWidth = 0;
        FRightWidth = 0;
    
        if (Ini->ReadVar("Width", str, 255))
            FLowerWidth = FUpperWidth = FLeftWidth = FRightWidth = atoi(str);
            
        if (Ini->ReadVar("UpperWidth", str, 255))
            FUpperWidth = atoi(str);
    
        if (Ini->ReadVar("LowerWidth", str, 255))
            FLowerWidth = atoi(str);
    
        if (Ini->ReadVar("LeftWidth", str, 255))
            FLeftWidth = atoi(str);
        
        if (Ini->ReadVar("RightWidth", str, 255))
            FRightWidth = atoi(str);
    }
}

/*##########################################################################
#
#   Name       : TPanelFactory::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBackground
#
#   Purpose....: Set background bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBackground(TBitmapGraphicDevice *bitmap, int xstart, int ystart)
{
    FBackground = bitmap;
    FBitStartX = xstart;
    FBitStartY = ystart;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBackColor
#
#   Purpose....: Set back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBackColor(int r, int g, int b)
{
    FBackR = r;
    FBackG = g;
    FBackB = b;
    
    FBackTrans = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBackTransparent
#
#   Purpose....: Set back color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBackTransparent()
{
    FBackTrans = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetDisabledColor
#
#   Purpose....: Set disabled color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetDisabledColor(int r, int g, int b)
{
    FDisabledColorUsed = TRUE;
    
    FDisabledR = r;
    FDisabledG = g;
    FDisabledB = b;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetUpperWidth
#
#   Purpose....: Set upper border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetUpperWidth(int width)
{
    FUpperWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetLowerWidth
#
#   Purpose....: Set lower border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetLowerWidth(int width)
{
    FLowerWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetLeftWidth
#
#   Purpose....: Set left border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetLeftWidth(int width)
{
    FLeftWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetRightWidth
#
#   Purpose....: Set right border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetRightWidth(int width)
{
    FRightWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBorderWidth
#
#   Purpose....: Set border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBorderWidth(int width)
{
    FUpperWidth = width;
    FLowerWidth = width;
    FLeftWidth = width;
    FRightWidth = width;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBorderColor
#
#   Purpose....: Set border color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBorderColor(int r, int g, int b)
{
    FBorderR = r;
    FBorderG = g;
    FBorderB = b;

    FBorderTrans = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetBorderTransparent
#
#   Purpose....: Set border color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetBorderTransparent()
{
    FBorderTrans = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelFactory::SetDefault
#
#   Purpose....: Set default panel properties from factory settings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelFactory::SetDefault(TPanelControl *panel, int xstart, int ystart, int xsize, int ysize)
{
    if (FBackground)
        panel->SetBackground(FBackground, FBitStartX + xstart, FBitStartY + ystart);

    if (FBackTrans)
        panel->SetBackTransparent();
    else
        panel->SetBackColor(FBackR, FBackG, FBackB);

    panel->SetUpperWidth(FUpperWidth);
    panel->SetLowerWidth(FLowerWidth);
    panel->SetLeftWidth(FLeftWidth);
    panel->SetRightWidth(FRightWidth);

    if (FBorderTrans)
        panel->SetBorderTransparent();
    else
        panel->SetBorderColor(FBorderR, FBorderG, FBorderB);

    if (FDisabledColorUsed)
        panel->SetDisabledColor(FDisabledR, FDisabledG, FDisabledB);
}

/*##########################################################################
#
#   Name       : TPanelFactory::Create
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    TPanelControl *panel;

    panel = new TPanelControl(dev, xstart, ystart, xsize, ysize);

    SetDefault(panel, xstart, ystart, xsize, ysize);

    if (FScrollFact)
        panel->DefineScroll(FScrollFact);

    return panel;        
}

/*##########################################################################
#
#   Name       : TPanelFactory::Create
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::Create(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    TPanelControl *panel;

    panel = new TPanelControl(control, xstart, ystart, xsize, ysize);

    SetDefault(panel, xstart, ystart, xsize, ysize);

    if (FScrollFact)
        panel->DefineScroll(FScrollFact);

    return panel;        
}

/*##########################################################################
#
#   Name       : TPanelFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TPanelFactory::CreatePanel
#
#   Purpose....: Create button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TPanelFactory::CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}
    
/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControlThread *dev)
 : TControl(dev)
{
    Init(0);
}

/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControl *control)
 : TControl(control)
{
    Init(0);
}
    
/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TControl(dev)
{
    Init(2);

    Resize(xsize, ysize);
    Move(xstart, ystart);
//      Show();
    Enable();
}

/*##########################################################################
#
#   Name       : TPanelControl::TPanelControl
#
#   Purpose....: Panel control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::TPanelControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TControl(control)
{
    Init(2);

    Resize(xsize, ysize);
    Move(xstart, ystart);
//      Show();
    Enable();
}

/*##########################################################################
#
#   Name       : TPanelControl::~TPanelControl
#
#   Purpose....: Panel control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl::~TPanelControl()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::Init
#
#   Purpose....: Init Panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::Init(int border)
{
    FBackground = 0;

    FBackR = 255;
    FBackG = 255;
    FBackG = 255;

    FBorderR = 200;
    FBorderG = 200;
    FBorderB = 200;

    FBorderTrans = FALSE;

    FDisabledColorUsed = FALSE;

    FUpperWidth = border;
    FLowerWidth = border;
    FLeftWidth = border;
    FRightWidth = border;

    FVerScroll = 0;
    FHorScroll = 0;
    FScrollChanged = FALSE;

    FVerLeft = FALSE;
    FHorUp = FALSE;

    FRedrawBack = TRUE;

    FKey = 0;

    ControlType += TString(".PANEL");
}

/*##########################################################################
#
#   Name       : TPanelControl::IsPanel
#
#   Purpose....: Check if this control is a panel
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPanelControl::IsPanel(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".PANEL"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetKey
#
#   Purpose....: Set key
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetKey(char ch)
{
    FKey = ch;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetVerLeft
#
#   Purpose....: Place vertical scroll to the left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetVerLeft()
{
    FVerLeft = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetVerRight
#
#   Purpose....: Place vertical scroll to the right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetVerRight()
{
    FVerLeft = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetHorTop
#
#   Purpose....: Place horisontal scroll at the top
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetHorTop()
{
    FHorUp = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetHorBottom
#
#   Purpose....: Place horisontal scroll at the bottom
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetHorBottom()
{
    FHorUp = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelControl::DefineScroll
#
#   Purpose....: Define scroll controls
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::DefineScroll(TPanelScrollFactory *fact)
{
    FVerScroll = fact->CreateVer(this);
    FHorScroll = fact->CreateHor(this);
}

/*##########################################################################
#
#   Name       : TPanelControl::DefineScroll
#
#   Purpose....: Define scroll controls
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::DefineScroll(int width)
{
    FVerScroll = new TVerPanelScrollControl(this, width);
    FHorScroll = new THorPanelScrollControl(this, width);
}

/*##########################################################################
#
#   Name       : TPanelControl::DefineScroll
#
#   Purpose....: Define scroll controls
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::DefineScroll(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int width = 16;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Width", str, 255))
        width = atoi(str);

    if (!FVerScroll)
        FVerScroll = new TVerPanelScrollControl(this, width);

    FVerScroll->Set(Ini, IniSection);

    if (!FHorScroll)       
        FHorScroll = new THorPanelScrollControl(this, width);

    FHorScroll->Set(Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TPanelControl::DefineScroll
#
#   Purpose....: Define scroll controls
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::DefineScroll(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    DefineScroll(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TPanelControl::EnableVerScroll
#
#   Purpose....: Enable vertical scrollbar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::EnableVerScroll()
{
    if (!FVerScroll)
    {
        FVerScroll = new TVerPanelScrollControl(this, 16);
        FVerScroll->Disable();
    }

    if (!FVerScroll->IsEnabled())
    {
        FVerScroll->Hide();
        FVerScroll->Enable();

        FScrollChanged = TRUE;
        Redraw();
    }
}

/*##########################################################################
#
#   Name       : TPanelControl::EnableHorScroll
#
#   Purpose....: Enable horisontal scrollbar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::EnableHorScroll()
{
    if (!FHorScroll)
    {
        FHorScroll = new THorPanelScrollControl(this, 16);
        FHorScroll->Disable();
    }

    if (!FHorScroll->IsEnabled())
    {
        FHorScroll->Hide();
        FHorScroll->Enable();

        FScrollChanged = TRUE;
        Redraw();
    }
}

/*##########################################################################
#
#   Name       : TPanelControl::DisableVerScroll
#
#   Purpose....: Disable vertical scrollbar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::DisableVerScroll()
{
    if (FVerScroll && FVerScroll->IsEnabled())
    {
        FVerScroll->Disable();
        FVerScroll->Hide();
        FScrollChanged = TRUE;
        Redraw();
    }
}

/*##########################################################################
#
#   Name       : TPanelControl::DisableHorScroll
#
#   Purpose....: Disable horisontal scrollbar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::DisableHorScroll()
{
    if (FHorScroll && FHorScroll->IsEnabled())
    {
        FHorScroll->Disable();
        FHorScroll->Hide();
        FScrollChanged = TRUE;
        Redraw();
    }
}

/*##########################################################################
#
#   Name       : TPanelControl::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int HasWidth;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("BackColor.R", str, 255))
        FBackR = atoi(str);
    
    if (Ini->ReadVar("BackColor.G", str, 255))
        FBackG = atoi(str);

    if (Ini->ReadVar("BackColor.B", str, 255))
        FBackB = atoi(str);

    if (Ini->ReadVar("BorderColor.R", str, 255))
        FBorderR = atoi(str);
    
    if (Ini->ReadVar("BorderColor.G", str, 255))
        FBorderG = atoi(str);

    if (Ini->ReadVar("BorderColor.B", str, 255))
        FBorderB = atoi(str);

    if (Ini->ReadVar("DisabledColor.R", str, 255))
    {
        FDisabledR = atoi(str);
        FDisabledColorUsed = TRUE;
    }
    
    if (Ini->ReadVar("DisabledColor.G", str, 255))
    {
        FDisabledG = atoi(str);
        FDisabledColorUsed = TRUE;
    }

    if (Ini->ReadVar("DisabledColor.B", str, 255))
    {
        FDisabledB = atoi(str);
        FDisabledColorUsed = TRUE;
    }

    HasWidth = Ini->ReadVar("Width", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("UpperWidth", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("LowerWidth", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("LeftWidth", str, 255);

    if (!HasWidth)
        HasWidth = Ini->ReadVar("RightWidth", str, 255);

    if (HasWidth)
    {
        FUpperWidth = 0;
        FLowerWidth = 0;
        FLeftWidth = 0;
        FRightWidth = 0;
    }
    
    if (Ini->ReadVar("Width", str, 255))
        FLowerWidth = FUpperWidth = FLeftWidth = FRightWidth = atoi(str);
            
    if (Ini->ReadVar("UpperWidth", str, 255))
        FUpperWidth = atoi(str);
    
    if (Ini->ReadVar("LowerWidth", str, 255))
        FLowerWidth = atoi(str);
    
    if (Ini->ReadVar("LeftWidth", str, 255))
        FLeftWidth = atoi(str);
        
    if (Ini->ReadVar("RightWidth", str, 255))
        FRightWidth = atoi(str);

    if (Ini->ReadVar("Scroll.Hor", str, 255))
    {
        if (!strcmp(str, "Top"))
            FHorUp = TRUE;

        if (!strcmp(str, "Bottom"))
            FHorUp = FALSE;
    }

    if (Ini->ReadVar("Scroll.Ver", str, 255))
    {
        if (!strcmp(str, "Left"))
            FVerLeft = TRUE;

        if (!strcmp(str, "Right"))
            FVerLeft = FALSE;
    }

    TControl::Set(Ini, IniSection);
    FRedrawBack = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackground
#
#   Purpose....: Set background bitmap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackground(TBitmapGraphicDevice *bitmap, int xstart, int ystart)
{
    FBackground = bitmap;
    FBitStartX = xstart;
    FBitStartY = ystart;
    FRedrawBack = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackColor
#
#   Purpose....: Set back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackColor(int r, int g, int b)
{
    FBackR = r;
    FBackG = g;
    FBackB = b;

    ClearTransparent();

    FRedrawBack = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::GetBackColor
#
#   Purpose....: Get back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::GetBackColor(int *r, int *g, int *b)
{
    *r = FBackR;
    *g = FBackG;
    *b = FBackB;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackTransparent
#
#   Purpose....: Set back color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackTransparent()
{
    SetTransparent();
}

/*##########################################################################
#
#   Name       : TPanelControl::SetDisabledColor
#
#   Purpose....: Set disabled color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetDisabledColor(int r, int g, int b)
{
    FDisabledColorUsed = TRUE;
    
    FDisabledR = r;
    FDisabledG = g;
    FDisabledB = b;
    FRedrawBack = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetUpperWidth
#
#   Purpose....: Set upper border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetUpperWidth(int width)
{
    FUpperWidth = width;

    FRedrawBack = TRUE;
    Redraw();
}

/*##########################################################################
#
#   Name       : TPanelControl::SetLowerWidth
#
#   Purpose....: Set lower border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetLowerWidth(int width)
{
    FLowerWidth = width;

    FRedrawBack = TRUE;
    Redraw();
}

/*##########################################################################
#
#   Name       : TPanelControl::SetLeftWidth
#
#   Purpose....: Set left border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetLeftWidth(int width)
{
    FLeftWidth = width;

    FRedrawBack = TRUE;
    Redraw();
}

/*##########################################################################
#
#   Name       : TPanelControl::SetRightWidth
#
#   Purpose....: Set right border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetRightWidth(int width)
{
    FRightWidth = width;

    FRedrawBack = TRUE;
    Redraw();
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBorderWidth
#
#   Purpose....: Set border width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBorderWidth(int width)
{
    FUpperWidth = width;
    FLowerWidth = width;
    FLeftWidth = width;
    FRightWidth = width;

    FRedrawBack = TRUE;
    Redraw();
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBorderColor
#
#   Purpose....: Set border color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBorderColor(int r, int g, int b)
{
    FBorderR = r;
    FBorderG = g;
    FBorderB = b;

    FBorderTrans = FALSE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBorderTransparent
#
#   Purpose....: Set border color as transparent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBorderTransparent()
{
    FBorderTrans = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::SetBackColor
#
#   Purpose....: Set back color into device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::SetBackColor(TGraphicDevice *dev)
{
    if (IsEnabled())
        dev->SetDrawColor(FBackR, FBackG, FBackB);
    else
    {
        if (FDisabledColorUsed)
            dev->SetDrawColor(FDisabledR, FDisabledG, FDisabledB);
        else
                dev->SetDrawColor(FBackR, FBackG, FBackB);
    }
}

/*##########################################################################
#
#   Name       : TPanelControl::GetMinHeight
#
#   Purpose....: Get minimum height
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPanelControl::GetMinHeight()
{
    return FUpperWidth + FLowerWidth;
}

/*##########################################################################
#
#   Name       : TPanelControl::GetInner
#
#   Purpose....: Get inner offsets
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::GetInner(int *xstart, int *ystart, int *xdiff, int *ydiff) const
{
    *xstart = FLeftWidth;
    *ystart = FUpperWidth;
    *xdiff = FLeftWidth + FRightWidth;
    *ydiff = FUpperWidth + FLowerWidth;

    if (FHorScroll && FHorScroll->IsEnabled())
    {
        *ydiff += FHorScroll->GetWidth();

        if (FHorUp)
            *ystart += FHorScroll->GetWidth();
    }
                  

        if (FVerScroll && FVerScroll->IsEnabled())
        {
        *xdiff += FVerScroll->GetWidth();

        if (FVerLeft)
            *xstart += FVerScroll->GetWidth();
    }
}

/*##########################################################################
#
#   Name       : TPanelControl::UpdateChild
#
#   Purpose....: Update child control if needed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::UpdateChild(TControl *control, int level)
{
    if (IsTransparent() && !FBackground && HasParent() && level == 1)
        RedrawParent();
    else
        TControl::UpdateChild(control, level);
}

/*##########################################################################
#
#   Name       : TPanelControl::RedrawChild
#
#   Purpose....: Redraw child control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::RedrawChild(TControl *control, int level)
{
    if (IsTransparent() && !FBackground && HasParent() && level == 1)
        RedrawParent();
    else
        TControl::RedrawChild(control, level);
}

/*##########################################################################
#
#   Name       : TPanelControl::ScrollLeft
#
#   Purpose....: Scroll left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::ScrollLeft()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::ScrollRight
#
#   Purpose....: Scroll right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::ScrollRight()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::PageLeft
#
#   Purpose....: Page left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::PageLeft()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::PageRight
#
#   Purpose....: Page right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::PageRight()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::HorMove
#
#   Purpose....: Move horisontally
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::HorMove(long double pos)
{
}

/*##########################################################################
#
#   Name       : TPanelControl::ScrollUp
#
#   Purpose....: Scroll up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::ScrollUp()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::ScrollDown
#
#   Purpose....: Scroll down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::ScrollDown()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::PageUp
#
#   Purpose....: Page up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::PageUp()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::PageDown
#
#   Purpose....: Page down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::PageDown()
{
}

/*##########################################################################
#
#   Name       : TPanelControl::VerMove
#
#   Purpose....: Move vertically
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::VerMove(long double pos)
{
}

/*##########################################################################
#
#   Name       : TPanelControl::IsInsidePanel
#
#   Purpose....: Check if position is inside control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPanelControl::IsInsidePanel(int x, int y) const
{
    int xstart, ystart;
    int xsize, ysize;
    int xoffs, yoffs;
    int xdiff, ydiff;

         GetPos(&xstart, &ystart);
    GetSize(&xsize, &ysize);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    xstart += xoffs;
    ystart += yoffs;
    xsize -= xdiff;
    ysize -= ydiff;

        return xstart <= x && xstart + xsize > x && ystart <= y && ystart + ysize > y;
}

/*##########################################################################
#
#   Name       : TPanelControl::ChildChange
#
#   Purpose....: Notification of a significant change in a child-control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::ChildChange()
{
    FRedrawBack = TRUE;
}

/*##########################################################################
#
#   Name       : TPanelControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPanelControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    if (FKey)
    {
        if (IsInside(x, y))
        {
            PutKey(FKey);
            return TRUE;
        }
    }
    return TControl::OnLeftDown(x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TPanelControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPanelControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int i;
    int xmax = xmin + width - 1;
    int ymax = ymin + height - 1;
    int ximin = xmin + FLeftWidth;
    int yimin = ymin + FUpperWidth;
    int ximax = xmax - FRightWidth;
    int yimax = ymax - FLowerWidth;
    int xscroll;
    int yscroll;
    int scrolls = 0;

    if (FHorScroll && FHorScroll->IsEnabled())
    {
        if (FHorUp)
            yimin += FHorScroll->GetWidth();
        else
            yimax -= FHorScroll->GetWidth();
        scrolls++;
    }

    if (FVerScroll && FVerScroll->IsEnabled())
    {
        if (FVerLeft)
            ximin += FVerScroll->GetWidth();
        else
            ximax -= FVerScroll->GetWidth();
        scrolls++;
    }

    if (FScrollChanged)
    {
        FRedrawBack = TRUE;
        FScrollChanged = FALSE;

        xscroll = ximax - ximin + 1;
        yscroll = yimax - yimin + 1;

        if (FVerScroll && FVerScroll->IsEnabled())
        {
            if (FVerLeft)
            {
                if (scrolls == 2 && FHorUp)
                    FVerScroll->Move(FLeftWidth, FUpperWidth + FHorScroll->GetWidth());
                else
                    FVerScroll->Move(FLeftWidth, FUpperWidth);
            }
            else
            {
                if (scrolls == 2 && FHorUp)
                    FVerScroll->Move(FLeftWidth + xscroll, FUpperWidth + FHorScroll->GetWidth());
                else
                    FVerScroll->Move(FLeftWidth + xscroll, FUpperWidth);
            }

            FVerScroll->Resize(FVerScroll->GetWidth(), yscroll);
            FVerScroll->Show();
            FVerScroll->Redraw();
        }

        if (FHorScroll && FHorScroll->IsEnabled())
        {
            if (FHorUp)
            {
                if (scrolls == 2 && FVerLeft)
                    FHorScroll->Move(FLeftWidth + FVerScroll->GetWidth(), FUpperWidth);
                else
                    FHorScroll->Move(FLeftWidth, FUpperWidth);
            }
            else
            {
                if (scrolls == 2 && FVerLeft)               
                    FHorScroll->Move(FLeftWidth + FVerScroll->GetWidth(), FUpperWidth + yscroll);
                else
                    FHorScroll->Move(FLeftWidth, FUpperWidth + yscroll);
            }

            FHorScroll->Resize(xscroll, FHorScroll->GetWidth());
            FHorScroll->Show();
            FHorScroll->Redraw();
        }

        NotifyResize();
    }

    TControl::Paint(dev, xmin, ymin, width, height);

    if (IsVisible() && FRedrawBack)
    {
        FRedrawBack = FALSE;
            
        dev->SetLgopNone();
        dev->SetFilledStyle();

        if (scrolls == 2 && !IsTransparent())
        {
            if (FVerLeft)
            {
                if (FHorUp)
                {
                    SetClipRect(    dev,
                                    ximin - FVerScroll->GetWidth(), 
                                    yimin - FHorScroll->GetWidth(),
                                    ximin,
                                    yimin);

                    SetBackColor(dev);
                    dev->DrawRect(      ximin - FVerScroll->GetWidth(), 
                                        yimin - FHorScroll->GetWidth(),
                                        ximin,
                                        yimin);
                }
                else
                {
                    SetClipRect(    dev,
                                    ximin - FVerScroll->GetWidth(), 
                                    yimax + 1,
                                    ximin,
                                    yimax + FHorScroll->GetWidth());

                    SetBackColor(dev);
                    dev->DrawRect(      ximin - FVerScroll->GetWidth(), 
                                        yimax + 1,
                                        ximin,
                                        yimax + FHorScroll->GetWidth());
                }
            }
            else
            {
                if (FHorUp)
                {
                    SetClipRect(    dev,
                                    ximax + 1, 
                                    yimin - FHorScroll->GetWidth(),
                                    ximax + FVerScroll->GetWidth(),
                                    yimin);

                    SetBackColor(dev);
                    dev->DrawRect(      ximax + 1, 
                                        yimin - FHorScroll->GetWidth(),
                                        ximax + FVerScroll->GetWidth(),
                                        yimin);
                }
                else
                {
                    SetClipRect(    dev,
                                    ximax + 1,
                                    yimax + 1,
                                    ximax + FVerScroll->GetWidth(),
                                    yimax + FHorScroll->GetWidth());

                    SetBackColor(dev);
                    dev->DrawRect(      ximax + 1,
                                        yimax + 1,
                                        ximax + FVerScroll->GetWidth(),
                                        yimax + FHorScroll->GetWidth());
                }
            }
        }

        SetClipRect(    dev,
                        ximin, yimin,
                        ximax, yimax);

        SetBackColor(dev);
        
        if (FBackground)
            dev->Blit(FBackground, FBitStartX, FBitStartY, ximin, yimin, FBackground->GetWidth(), FBackground->GetHeight());
        else
        {
            if (!IsTransparent())
                dev->DrawRect(ximin, yimin, ximax, yimax);
        }

        SetClipRect(    dev,
                        xmin, ymin,
                        xmax, ymax);

        if (!FBorderTrans)
        {
            if (FUpperWidth || FLowerWidth || FLeftWidth || FRightWidth)
            {
                dev->SetDrawColor(FBorderR, FBorderG, FBorderB);
                
                for (i = 0; i < FUpperWidth; i++)
                    dev->DrawLine(xmin, ymin + i, xmin + width - 1, ymin + i);
                
                for (i = 0; i < FLowerWidth; i++)
                    dev->DrawLine(xmin, ymin + height - i - 1, xmin + width, ymin + height - i - 1);

                for (i = 0; i < FLeftWidth; i++)
                    dev->DrawLine(xmin + i, ymin, xmin + i, ymin + height - 1);
                
                for (i = 0; i < FRightWidth; i++)
                    dev->DrawLine(xmin + width - i - 1, ymin, xmin + width - i - 1, ymin + height - 1);
            }
        } 
    }
}
