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
# label.cpp
# Label control class
#
########################################################################*/

#include <string.h>

#include "label.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TLabelFactory::TLabelFactory
#
#   Purpose....: Button factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelFactory::TLabelFactory()
{
    Init();
}

/*##########################################################################
#
#   Name       : TLabelFactory::~TLabelFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelFactory::~TLabelFactory()
{
    if (FFont)
        delete FFont;
}

/*##########################################################################
#
#   Name       : TLabelFactory::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::Init()
{
    FFont = 0;
    FFontId = 0;
    FFontHeight = 0;
    FAllowScale = TRUE;

    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;

    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;
}

/*##########################################################################
#
#   Name       : TLabelFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;
    int id;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Font.Id", str, 255))
    {
        id = atoi(str);

        if (id != FFontId)
            SetFont(id, FFontHeight);
    }

    if (Ini->ReadVar("Font.Size", str, 255))
    {
        size = atoi(str);

        if (size && size != FFontHeight)
            SetFont(FFontId, size);
    }

    if (Ini->ReadVar("Align", str, 255))
    {
        strupr(str);

        if (!strcmp(str, "TOPLEFT"))
            AlignTopLeft();

        if (!strcmp(str, "TOP"))
            AlignTop();

        if (!strcmp(str, "TOPRIGHT"))
            AlignTopRight();

        if (!strcmp(str, "LEFT"))
            AlignLeft();

        if (!strcmp(str, "CENTER"))
            AlignCenter();

        if (!strcmp(str, "RIGHT"))
            AlignRight();

        if (!strcmp(str, "BOTTOMLEFT"))
            AlignBottomLeft();

        if (!strcmp(str, "BOTTOM"))
            AlignBottom();

        if (!strcmp(str, "BOTTOMRIGHT"))
            AlignBottomRight();
    }


    if (Ini->ReadVar("DrawColor.R", str, 255))
        FDrawR = atoi(str);

    if (Ini->ReadVar("DrawColor.G", str, 255))
        FDrawG = atoi(str);

    if (Ini->ReadVar("DrawColor.B", str, 255))
        FDrawB = atoi(str);


    if (Ini->ReadVar("Space.X", str, 255))
        FStartX = atoi(str);

    if (Ini->ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);

    TPanelFactory::Set(Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TLabelFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetFont(int height)
{
    if (FFontHeight != height)
    {
        if (FFont)
            delete FFont;

        FFontHeight = height;
        FFont = new TFont(FFontId, height);
    }
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetFont(int id, int height)
{
    if (FFontId != id || FFontHeight != height)
    {
        if (FFont)
            delete FFont;

        FFontId = id;
        FFontHeight = height;
        FFont = new TFont(id, height);
    }
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignTopLeft
#
#   Purpose....: Align text top, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignTopLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignTop
#
#   Purpose....: Align text top, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignTop()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignTopRight
#
#   Purpose....: Align text top, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignTopRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignLeft
#
#   Purpose....: Align text center, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignCenter
#
#   Purpose....: Align text center, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignCenter()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignRight
#
#   Purpose....: Align text center, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignBottomLeft
#
#   Purpose....: Align text bottom, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignBottomLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignBottom
#
#   Purpose....: Align text bottom, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignBottom()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AlignBottomRight
#
#   Purpose....: Align text bottom, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AlignBottomRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelFactory::ForceNoScale
#
#   Purpose....: Force ReformatText to use orignial font size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::ForceNoScale()
{
    FAllowScale = FALSE;
}

/*##########################################################################
#
#   Name       : TLabelFactory::AllowScale
#
#   Purpose....: Allow ReformatText to change font size to fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::AllowScale()
{
    FAllowScale = TRUE;
}

/*##########################################################################
#
#   Name       : TLabelFactory::SetDefault
#
#   Purpose....: Set default panel properties from factory settings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelFactory::SetDefault(TLabelControl *label, int xstart, int ystart, int xsize, int ysize)
{
    switch (FVerAlign)
    {
        case VER_TOP:
            switch (FHorAlign)
            {
                case HOR_LEFT:
                    label->AlignTopLeft();
                    break;

                case HOR_CENTER:
                    label->AlignTop();
                    break;

                case HOR_RIGHT:
                    label->AlignTopRight();
                    break;
            }
            break;

        case VER_CENTER:
            switch (FHorAlign)
            {
                case HOR_LEFT:
                    label->AlignLeft();
                    break;

                case HOR_CENTER:
                    label->AlignCenter();
                    break;

                case HOR_RIGHT:
                    label->AlignRight();
                    break;
            }
            break;

        case VER_BOTTOM:
            switch (FHorAlign)
            {
                case HOR_LEFT:
                    label->AlignBottomLeft();
                    break;

                case HOR_CENTER:
                    label->AlignBottom();
                    break;

                case HOR_RIGHT:
                    label->AlignBottomRight();
                    break;
            }
            break;
    }

    if (FFont)
        label->SetFont(FFont);

    label->SetSpace(FStartX, FStartY);
    label->SetDrawColor(FDrawR, FDrawG, FDrawB);

    if (FAllowScale)
        label->AllowScale();
    else
        label->ForceNoScale();

    TPanelFactory::SetDefault(label, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::Create
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    TLabelControl *label;

    label = new TLabelControl(dev, xstart, ystart, xsize, ysize);

    SetDefault(label, xstart, ystart, xsize, ysize);

        return label;
}

/*##########################################################################
#
#   Name       : TLabelFactory::Create
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::Create(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    TLabelControl *label;

    label = new TLabelControl(control, xstart, ystart, xsize, ysize);

    SetDefault(label, xstart, ystart, xsize, ysize);

    return label;
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TLabelFactory::CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TLabelFactory::CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreateLabel
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::CreateLabel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelFactory::CreateLabel
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TLabelFactory::CreateLabel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TLabelControl::TLabelControl
#
#   Purpose....: Label control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::TLabelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(dev),
   FSection("Label")
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
    Show();
}

/*##########################################################################
#
#   Name       : TLabelControl::TLabelControl
#
#   Purpose....: Label control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::TLabelControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(control),
   FSection("Label")
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
    Show();
}

/*##########################################################################
#
#   Name       : TLabelControl::TLabelControl
#
#   Purpose....: Label control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::TLabelControl(TControlThread *dev)
 : TPanelControl(dev),
   FSection("Label")
{
    Init();
}

/*##########################################################################
#
#   Name       : TLabelControl::TLabelControl
#
#   Purpose....: Label control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::TLabelControl(TControl *control)
 : TPanelControl(control),
   FSection("Label")
{
    Init();
}

/*##########################################################################
#
#   Name       : TLabelControl::~TLabelControl
#
#   Purpose....: Panel control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl::~TLabelControl()
{
    if (FOrgText)
        delete FOrgText;

    if (FText)
        delete FText;

    if (FFont)
        delete FFont;

    if (FScaleFont)
        delete FScaleFont;
}

/*##########################################################################
#
#   Name       : TLabelControl::Init
#
#   Purpose....: Init label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::Init()
{
    FOrgText = 0;
    FText = 0;
    FFont = 0;
    FScaleFont = 0;
    FFontId = 0;
    FFontHeight = 0;

    FForceSingle = FALSE;
    FAllowScale = TRUE;

    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;

    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;

    ControlType += TString(".LABEL");
}

/*##########################################################################
#
#   Name       : TLabelControl::IsLabelControl
#
#   Purpose....: Check if control is a label
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLabelControl::IsLabelControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".LABEL"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TLabelControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;
    int id;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Font.Id", str, 255))
    {
        id = atoi(str);

        if (id != FFontId)
            SetFont(id, FFontHeight);
    }

    if (Ini->ReadVar("Font.Size", str, 255))
    {
        size = atoi(str);

        if (size != FFontHeight)
            SetFont(FFontId, size);
    }

    if (Ini->ReadVar("Single", str, 255))
    {
        if (str[0] == '0')
            AllowMultiple();
        else
            ForceSingle();
    }

    if (Ini->ReadVar("Align", str, 255))
    {
        strupr(str);

        if (!strcmp(str, "TOPLEFT"))
            AlignTopLeft();

        if (!strcmp(str, "TOP"))
            AlignTop();

        if (!strcmp(str, "TOPRIGHT"))
            AlignTopRight();

        if (!strcmp(str, "LEFT"))
            AlignLeft();

        if (!strcmp(str, "CENTER"))
            AlignCenter();

        if (!strcmp(str, "RIGHT"))
            AlignRight();

        if (!strcmp(str, "BOTTOMLEFT"))
            AlignBottomLeft();

        if (!strcmp(str, "BOTTOM"))
            AlignBottom();

        if (!strcmp(str, "BOTTOMRIGHT"))
            AlignBottomRight();
    }


    if (Ini->ReadVar("DrawColor.R", str, 255))
        FDrawR = atoi(str);

    if (Ini->ReadVar("DrawColor.G", str, 255))
        FDrawG = atoi(str);

    if (Ini->ReadVar("DrawColor.B", str, 255))
        FDrawB = atoi(str);


    if (Ini->ReadVar("Space.X", str, 255))
        FStartX = atoi(str);

    if (Ini->ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);


    if (Ini->ReadVar("Text", str, 255))
        SetText(str);

    TPanelControl::Set(Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TLabelControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TLabelControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetFont(int height)
{
    if (FFontHeight != height)
    {
        if (FFont)
            delete FFont;

        FFontHeight = height;
        FFont = new TFont(FFontId, height);

        FSection.Enter();
        ReformatText();
        FSection.Leave();
    }
}

/*##########################################################################
#
#   Name       : TLabelControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetFont(int id, int height)
{
    if (FFontId != id || FFontHeight != height)
    {
        if (FFont)
            delete FFont;

        FFontId = id;
        FFontHeight = height;
        FFont = new TFont(id, height);

        FSection.Enter();
        ReformatText();
        FSection.Leave();
    }
}

/*##########################################################################
#
#   Name       : TLabelControl::SetScaleFont
#
#   Purpose....: Set scale font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetScaleFont(int id, int height)
{
    if (FScaleFont)
        delete FScaleFont;

    FScaleFont = new TFont(id, height);

    FSection.Enter();
    ReformatText();
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TLabelControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetFont(TFont *font)
{
    if (FFont)
        delete FFont;

    FFont = new TFont(*font);

    FSection.Enter();
    ReformatText();
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TLabelControl::GetFont
#
#   Purpose....: Get font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont *TLabelControl::GetFont()
{
    return FFont;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;

    FSection.Enter();
    ReformatText();
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TLabelControl::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TLabelControl::GetDrawColor
#
#   Purpose....: Get draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::GetDrawColor(int *r, int *g, int *b)
{
    *r = FDrawR;
    *g = FDrawG;
    *b = FDrawB;
}

/*##########################################################################
#
#   Name       : TLabelControl::ForceSingle
#
#   Purpose....: Force single-line use
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::ForceSingle()
{
    FForceSingle = TRUE;
}

/*##########################################################################
#
#   Name       : TLabelControl::AllowMultiple
#
#   Purpose....: Allow breakup into multiple rows
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AllowMultiple()
{
    FForceSingle = FALSE;
}

/*##########################################################################
#
#   Name       : TLabelControl::ForceNoScale
#
#   Purpose....: Force ReformatText to use orignial font size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::ForceNoScale()
{
    FAllowScale = FALSE;
}

/*##########################################################################
#
#   Name       : TLabelControl::AllowScale
#
#   Purpose....: Allow ReformatText to change font size to fit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AllowScale()
{
    FAllowScale = TRUE;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignTopLeft
#
#   Purpose....: Align text top, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignTopLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignTop
#
#   Purpose....: Align text top, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignTop()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignTopRight
#
#   Purpose....: Align text top, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignTopRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_TOP;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignLeft
#
#   Purpose....: Align text center, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignCenter
#
#   Purpose....: Align text center, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignCenter()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignRight
#
#   Purpose....: Align text center, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_CENTER;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignBottomLeft
#
#   Purpose....: Align text bottom, left
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignBottomLeft()
{
    FHorAlign = HOR_LEFT;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignBottom
#
#   Purpose....: Align text bottom, center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignBottom()
{
    FHorAlign = HOR_CENTER;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelControl::AlignBottomRight
#
#   Purpose....: Align text bottom, right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::AlignBottomRight()
{
    FHorAlign = HOR_RIGHT;
    FVerAlign = VER_BOTTOM;
}

/*##########################################################################
#
#   Name       : TLabelControl::GetAlign
#
#   Purpose....: Get alignment
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::GetAlign(int *hor, int *ver)
{
    *hor = FHorAlign;
    *ver = FVerAlign;
}

/*##########################################################################
#
#   Name       : TLabelControl::ReformatText
#
#   Purpose....: Reformat text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::ReformatText()
{
    int row;
    char *ptr;
    char *start;
    char *prev;
    char ch;
    int width;
    int height;
    int xsize;
    int ysize;
    int xoffs, yoffs;
    int xdiff, ydiff;

    if (FText == 0)
        return;

    for (row = 0; row < MAX_LABEL_ROWS; row++)
        FTextRow[row] = 0;

    if (!FFont)
        SetFont(12);

    GetSize(&xsize, &ysize);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    if (xsize == 0 || ysize == 0)
        return;

    xsize -= 2 * FStartX;
    xsize -= xdiff;

    if (xsize <= 0 || ysize <= 0)
        return;

    row = 0;
    start = FText;
    prev = 0;

    FTextRow[row] = start;
    ptr = start;

    if (FForceSingle)
        return;

    while (*ptr != 0)
    {
        while (*ptr != 0 && *ptr != ' ' && *ptr != 0xd && *ptr != 0xa && *ptr != ' ')
            ptr++;

        switch (*ptr)
        {
            case 0xd:
                *ptr = 0;
                ptr++;

                if (*ptr == 0xa)
                    ptr++;

                if (row < MAX_LABEL_ROWS)
                    row++;

                while (*ptr == ' ' || *ptr == ' ')
                    ptr++;

                FTextRow[row] = ptr;
                start = ptr;
                prev = 0;
                break;

            case 0xa:
                *ptr = 0;
                ptr++;

                if (*ptr == 0xd)
                    ptr++;

                if (row < MAX_LABEL_ROWS)
                    row++;

                while (*ptr == ' ' || *ptr == ' ')
                    ptr++;

                FTextRow[row] = ptr;
                start = ptr;
                prev = 0;
                break;

            default:
                ch = *ptr;
                *ptr = 0;

                if (FScaleFont)
                    FScaleFont->GetStringMetrics(start, &width, &height);
                else
                    FFont->GetStringMetrics(start, &width, &height);

                if (width > xsize)
                {
                    if (prev)
                    {
                        *ptr = ch;
                        *prev = 0;

                        if (row < MAX_LABEL_ROWS)
                            row++;

                        ptr = prev;

                        ptr++;

                        while (*ptr == ' ' || *ptr == ' ')
                            ptr++;

                        FTextRow[row] = ptr;
                        start = ptr;
                        prev = 0;
                    }
                    else
                    {
                        if (row < MAX_LABEL_ROWS)
                            row++;

                        if (ch != 0)
                        {
                            ptr++;

                            while (*ptr == ' ' || *ptr == ' ')
                                ptr++;
                        }

                        FTextRow[row] = ptr;
                        start = ptr;
                    }
                }
                else
                {
                    prev = ptr;

                    *ptr = ch;
                    while (*ptr == ' ' || *ptr == ' ')
                        ptr++;
                }
                break;
        }
    }

    if (FTextRow[row])
        if (strlen(FTextRow[row]) == 0)
            FTextRow[row] = 0;
}

/*##########################################################################
#
#   Name       : TLabelControl::SetText
#
#   Purpose....: Set text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetText(const char *Text)
{
    int same = FALSE;
    int len = strlen(Text);
    int xsize, ysize;
    int xoffs, yoffs;
    int xdiff, ydiff;
    int fontHeight, fontId;
    TFont *font;

    FSection.Enter();

    GetSize(&xsize, &ysize);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    ysize -= ydiff;

    if (FOrgText && len > 0)
        if (!strcmp(Text, FOrgText))
            same = TRUE;

    if (!same)
    {
        if (FScaleFont)
        {
            delete FScaleFont;
            FScaleFont = 0;
        }

        if (FText)
            delete FText;

        FText = new char[len + 1];
        strcpy(FText, Text);

        if (FOrgText)
            delete FOrgText;

        FOrgText = new char[len + 1];
        strcpy(FOrgText, Text);

        ReformatText();

        if (FAllowScale)
        {
            font = FFont;
            fontId = font->GetId();

            while(GetMinHeight() > ysize)
            {
                strcpy(FText, FOrgText);
                fontHeight = font->GetHeight();
                fontHeight--;
                if (fontHeight > 10)
                {
                    SetScaleFont(fontId, fontHeight);
                    font = FScaleFont;
                }
                else
                    break;
            }
        }
    }

    FSection.Leave();

    if (!same)
    {
        if (IsTransparent() && HasParent())
            RedrawParent();
        else
            Redraw(1);
    }
}

/*##########################################################################
#
#   Name       : TLabelControl::SetText
#
#   Purpose....: Set text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::SetText(TString &Text)
{
    SetText(Text.GetData());
}

/*##########################################################################
#
#   Name       : TLabelControl::GetText
#
#   Purpose....: Get text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TLabelControl::GetText()
{
    if (FOrgText)
        return FOrgText;
    else
        return "";
}

/*##########################################################################
#
#   Name       : TLabelControl::GetMinHeight
#
#   Purpose....: Get minimum height
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLabelControl::GetMinHeight()
{
    int xsize, ysize;
    int row;
    int height = TPanelControl::GetMinHeight();

    if (FScaleFont)
        FScaleFont->GetStringMetrics("", &xsize, &ysize);
    else if (FFont)
        FFont->GetStringMetrics("", &xsize, &ysize);
    else
        ysize = 0;

    for (row = 0; row < MAX_LABEL_ROWS; row++)
        if (FTextRow[row] != 0)
            height += ysize;
        else
            break;

    return height;
}

/*##########################################################################
#
#   Name       : TLabelControl::NotifyResize
#
#   Purpose....: Notify resize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::NotifyResize()
{
    FSection.Enter();
    ReformatText();
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TLabelControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLabelControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int xstart;
    int ystart;
    int xsize;
    int ysize;
    int xmax, ymax;
    int row;
    int xoffs, yoffs;
    int xdiff, ydiff;
    int redraw;
    TFont *font;

    if (IsTransparent())
    {
        UpdateTransparent();
        RedrawBackground(dev);
    }

    FRedrawBack = TRUE;

    TPanelControl::Paint(dev, xmin, ymin, width, height);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    xmin += xoffs;
    ymin += yoffs;
    width -= xdiff;
    height -= ydiff;

    FSection.Enter();

    if (FScaleFont)
        font = FScaleFont;
    else
        font = FFont;

    xmax = xmin + width - 1;
    ymax = ymin + height - 1;

    redraw = IsVisible();

    if (width == 0 || height == 0)
        redraw = FALSE;

    if (redraw)
    {
        dev->SetLgopNone();
        dev->SetFilledStyle();

        SetClipRect(    dev,
                        xmin, ymin,
                        xmax, ymax);

        if (FOrgText)
        {

            font->GetStringMetrics("", &xsize, &ysize);

            for (row = 0; row < MAX_LABEL_ROWS; row++)
                if (FTextRow[row] == 0)
                    break;

            ysize = ysize * row;

            switch (FVerAlign)
            {
                case VER_TOP:
                    ystart = ymin + FStartY;
                    break;

                case VER_CENTER:
                    ystart = ymin + (height - ysize) / 2;
                    break;

                case VER_BOTTOM:
                    ystart = ymin + height - ysize - FStartY;
                    break;
            }

            for (row = 0; row < MAX_LABEL_ROWS; row++)
            {
                if (FTextRow[row])
                {
                        font->GetStringMetrics(FTextRow[row], &xsize, &ysize);

                        switch (FHorAlign)
                        {
                                case HOR_LEFT:
                                    xstart = xmin + FStartX;
                                    break;

                                case HOR_CENTER:
                                            xstart = xmin + (width - xsize) / 2;
                                        break;

                                case HOR_RIGHT:
                                        xstart = xmin + width - xsize - FStartX;
                                            break;
                    }

                    dev->SetFont(font);
                    dev->SetDrawColor(FDrawR, FDrawG, FDrawB);
                    dev->DrawString(xstart, ystart, FTextRow[row]);
                }
                else
                    break;

                ystart += ysize;
            }
        }
    }
    FSection.Leave();

}
