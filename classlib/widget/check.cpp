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
# check.cpp
# Check control class
#
########################################################################*/

#include <string.h>

#include "check.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TCheckFactory::TCheckFactory
#
#   Purpose....: Checkbox factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckFactory::TCheckFactory()
{
    Init();
}

/*##########################################################################
#
#   Name       : TCheckFactory::~TCheckFactory
#
#   Purpose....: Checkbox factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckFactory::~TCheckFactory()
{
    if (FFont)
        delete FFont;
}
    
/*##########################################################################
#
#   Name       : TCheckFactory::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::Init()
{
    FFont = 0;
    FFontId = 0;
    FFontHeight = 0;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;
}
    
/*##########################################################################
#
#   Name       : TCheckFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::Set(TAppIniFile *Ini, const char *IniSection)
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
#   Name       : TCheckFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TCheckFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::SetFont(int height)
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
#   Name       : TCheckFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::SetFont(int id, int height)
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
#   Name       : TCheckFactory::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TCheckFactory::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TCheckFactory::SetDefault
#
#   Purpose....: Set default panel properties from factory settings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckFactory::SetDefault(TCheckControl *check, int xstart, int ystart, int xsize, int ysize)
{
    if (FFont)
        check->SetFont(FFont);
        
    check->SetSpace(FStartX, FStartY);
    check->SetDrawColor(FDrawR, FDrawG, FDrawB);            

    TPanelFactory::SetDefault(check, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TCheckFactory::Create
#
#   Purpose....: Create checkbox control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl *TCheckFactory::Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    TCheckControl *check;

    check = new TCheckControl(dev, xstart, ystart, xsize, ysize);

    SetDefault(check, xstart, ystart, xsize, ysize);

    return check;
}

/*##########################################################################
#
#   Name       : TCheckFactory::Create
#
#   Purpose....: Create checkbox control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl *TCheckFactory::Create(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    TCheckControl *check;

    check = new TCheckControl(control, xstart, ystart, xsize, ysize);

    SetDefault(check, xstart, ystart, xsize, ysize);

    return check;        
}

/*##########################################################################
#
#   Name       : TCheckFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TCheckFactory::CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TCheckFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TCheckFactory::CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TCheckFactory::CreateCheck
#
#   Purpose....: Create check control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl *TCheckFactory::CreateCheck(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TCheckFactory::CreateCheck
#
#   Purpose....: Create check control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl *TCheckFactory::CreateCheck(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}
    
/*##########################################################################
#
#   Name       : TCheckControl::TCheckControl
#
#   Purpose....: Check control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl::TCheckControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(dev),
   FSection("Check")
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
    Show();
}

/*##########################################################################
#
#   Name       : TCheckControl::TCheckControl
#
#   Purpose....: Check control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl::TCheckControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(control),
   FSection("Check")
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
    Show();
}
    
/*##########################################################################
#
#   Name       : TCheckControl::TCheckControl
#
#   Purpose....: Check control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl::TCheckControl(TControlThread *dev)
 : TPanelControl(dev),
   FSection("Check")
{
    Init();
}

/*##########################################################################
#
#   Name       : TCheckControl::TCheckControl
#
#   Purpose....: Check control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl::TCheckControl(TControl *control)
 : TPanelControl(control),
   FSection("Check")
{
    Init();
}

/*##########################################################################
#
#   Name       : TCheckControl::~TCheckControl
#
#   Purpose....: Check control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCheckControl::~TCheckControl()
{
    if (FOrgText)
        delete FOrgText;

    if (FText)
        delete FText;

    if (FFont)
        delete FFont;
}

/*##########################################################################
#
#   Name       : TCheckControl::Init
#
#   Purpose....: Init label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::Init()
{
    FOrgText = 0;
    FText = 0;
    FFont = 0;
    FFontId = 0;
    FFontHeight = 0;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;

    FChecked = FALSE;
    
    ControlType += TString(".CHECK");
}
    
/*##########################################################################
#
#   Name       : TCheckControl::IsCheckControl
#
#   Purpose....: Check if control is a checkbox
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCheckControl::IsCheckControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".CHECK"))
        return TRUE;
    else
        return FALSE;
}
    
/*##########################################################################
#
#   Name       : TCheckControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::Set(TAppIniFile *Ini, const char *IniSection)
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
#   Name       : TCheckControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TCheckControl::Check
#
#   Purpose....: Set checked
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::Check()
{
    FChecked = TRUE;
    if (IsTransparent() && HasParent())
        RedrawParent();
    else
        Redraw(1);
}


/*##########################################################################
#
#   Name       : TCheckControl::Uncheck
#
#   Purpose....: Reset checked
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::Uncheck()
{
    FChecked = FALSE;
    if (IsTransparent() && HasParent())
        RedrawParent();
    else
        Redraw(1);
}

/*##########################################################################
#
#   Name       : TCheckControl::IsChecked
#
#   Purpose....: Check if checked
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCheckControl::IsChecked()
{
    return FChecked;
}


/*##########################################################################
#
#   Name       : TCheckControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::SetFont(int height)
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
#   Name       : TCheckControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::SetFont(int id, int height)
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
#   Name       : TCheckControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::SetFont(TFont *font)
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
#   Name       : TCheckControl::GetFont
#
#   Purpose....: Get font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont *TCheckControl::GetFont()
{
    return FFont;
}

/*##########################################################################
#
#   Name       : TCheckControl::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;

    FSection.Enter();
    ReformatText();
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TCheckControl::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TCheckControl::GetDrawColor
#
#   Purpose....: Get draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::GetDrawColor(int *r, int *g, int *b)
{
    *r = FDrawR;
    *g = FDrawG;
    *b = FDrawB;
}

/*##########################################################################
#
#   Name       : TCheckControl::ReformatText
#
#   Purpose....: Reformat text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::ReformatText()
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

    for (row = 0; row < MAX_CHECK_ROWS; row++)
        FTextRow[row] = 0;

    if (!FFont)
        SetFont(12);

    GetSize(&xsize, &ysize);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    if (xsize == 0 || ysize == 0)
        return;

    xsize -= 2 * FStartX + ysize * 4 / 3;
    xsize -= xdiff;

    if (xsize <= 0 || ysize <= 0)
        return;

    row = 0;
    start = FText;
    prev = 0;

    FTextRow[row] = start;
    ptr = start;

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

                if (row < MAX_CHECK_ROWS)
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

                if (row < MAX_CHECK_ROWS)
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

                FFont->GetStringMetrics(start, &width, &height);

                if (width > xsize)
                {
                    if (prev)
                    {
                        *ptr = ch;
                        *prev = 0;
    
                        if (row < MAX_CHECK_ROWS)
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
                        if (row < MAX_CHECK_ROWS)
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
#   Name       : TCheckControl::SetText
#
#   Purpose....: Set text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::SetText(const char *Text)
{
    int same = FALSE;
    int len = strlen(Text);

    FSection.Enter();

    if (FOrgText && len > 0)
        if (!strcmp(Text, FOrgText))
            same = TRUE;

    if (!same)
    {    
        if (FText)
            delete FText;

        FText = new char[len + 1];
        strcpy(FText, Text);

        if (FOrgText)
            delete FOrgText;

        FOrgText = new char[len + 1];
        strcpy(FOrgText, Text);

        ReformatText();
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
#   Name       : TCheckControl::SetText
#
#   Purpose....: Set text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::SetText(TString &Text)
{
    SetText(Text.GetData());
}

/*##########################################################################
#
#   Name       : TCheckControl::GetText
#
#   Purpose....: Get text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TCheckControl::GetText()
{
    if (FOrgText)
        return FOrgText;
    else
        return "";
}

/*##########################################################################
#
#   Name       : TCheckControl::GetMinHeight
#
#   Purpose....: Get minimum height
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCheckControl::GetMinHeight()
{
    int xsize, ysize;
    int row;
    int height = TPanelControl::GetMinHeight();

    if (FFont)
        FFont->GetStringMetrics("", &xsize, &ysize);
    else
        ysize = 0;

    for (row = 0; row < MAX_CHECK_ROWS; row++)
        if (FTextRow[row] != 0)
            height += ysize;
        else
            break;

    return height;
}

/*##########################################################################
#
#   Name       : TCheckControl::NotifyResize
#
#   Purpose....: Notify resize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::NotifyResize()
{
    FSection.Enter();
    ReformatText();
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TCheckControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCheckControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    int i;
    TControl *control;
    TCheckControl *check;

    if (IsInside(x, y))
    {
        if (!IsChecked())
        {
            Check();

            for (i = 0;; i++)
            {
                control = GetSiblingControlById(i);
                if (control)
                {
                    if (IsCheckControl(control))
                    {
                        check = (TCheckControl *)control;
                        if (check != this)
                            check->Uncheck();
                    }
                }
                else
                    break;
            }
        }
        return TRUE;
    }
    return TPanelControl::OnLeftDown(x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TCheckControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCheckControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
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
    int r;
    int xc, yc;

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

    xmax = xmin + width - 1;
    ymax = ymin + height - 1;

    redraw = IsVisible();

    if (width == 0 || height == 0)
        redraw = FALSE;    
    
    if (redraw)
    {
        xsize = xmax - xmin;
        ysize = ymax - ymin;
        
        dev->SetLgopNone();
        dev->SetFilledStyle();

        SetClipRect(    dev,
                        xmin, ymin,
                        xmax, ymax);

        r = FFontHeight / 2;
        xc = xmin + r;
        yc = ymin + ysize / 2;

        dev->SetDrawColor(FDrawR, FDrawG, FDrawB);
        dev->DrawEllipse(xc, yc, r, r);        

        r = 4 * r / 5;
        dev->SetDrawColor(FBackR, FBackG, FBackB);
        dev->DrawEllipse(xc, yc, r, r);        

        if (FChecked)
        {
            r = 4 * r / 5;
            dev->SetDrawColor(FDrawR, FDrawG, FDrawB);
            dev->DrawEllipse(xc, yc, r, r);        
        }

        if (FOrgText)
        {

            FFont->GetStringMetrics("", &xsize, &ysize);

            for (row = 0; row < MAX_CHECK_ROWS; row++)
                if (FTextRow[row] == 0)
                    break;

            ysize = ysize * row;

            ystart = ymin + (height - ysize) / 2;

            for (row = 0; row < MAX_CHECK_ROWS; row++)
            {
                if (FTextRow[row])
                {
                    FFont->GetStringMetrics(FTextRow[row], &xsize, &ysize);
    
                    xstart = xmin + FStartX + (ymax - ymin) * 4 / 3;
        
                    dev->SetFont(FFont);
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
