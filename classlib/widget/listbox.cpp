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
# listbox.cpp
# List control class
#
########################################################################*/

#include <string.h>

#include "listbox.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TListFactory::TListFactory
#
#   Purpose....: List factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListFactory::TListFactory()
{
    Init();
}

/*##########################################################################
#
#   Name       : TListFactory::~TListFactory
#
#   Purpose....: List factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListFactory::~TListFactory()
{
    if (FFont)
        delete FFont;
}
    
/*##########################################################################
#
#   Name       : TListFactory::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::Init()
{
    FFont = 0;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;

    FSelectedBackR = 150;
    FSelectedBackG = 150;
    FSelectedBackB = 255;

    FSelectedDrawR = 0;
    FSelectedDrawG = 0;
    FSelectedDrawB = 0;
}
    
/*##########################################################################
#
#   Name       : TListFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Font.Size", str, 255))
    {    
        size = atoi(str);

        if (size)
            SetFont(size);
    }
            
    if (Ini->ReadVar("DrawColor.R", str, 255))
        FDrawR = atoi(str);
    
    if (Ini->ReadVar("DrawColor.G", str, 255))
        FDrawG = atoi(str);

    if (Ini->ReadVar("DrawColor.B", str, 255))
        FDrawB = atoi(str);

            
    if (Ini->ReadVar("SelectedDrawColor.R", str, 255))
        FSelectedDrawR = atoi(str);
    
    if (Ini->ReadVar("SelectedDrawColor.G", str, 255))
        FSelectedDrawG = atoi(str);

    if (Ini->ReadVar("SelectedDrawColor.B", str, 255))
        FSelectedDrawB = atoi(str);

            
    if (Ini->ReadVar("SelectedBackColor.R", str, 255))
        FSelectedBackR = atoi(str);
    
    if (Ini->ReadVar("SelectedBackColor.G", str, 255))
        FSelectedBackG = atoi(str);

    if (Ini->ReadVar("SelectedBackColor.B", str, 255))
        FSelectedBackB = atoi(str);


    if (Ini->ReadVar("Space.X", str, 255))
        FStartX = atoi(str);
    
    if (Ini->ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);

    TPanelFactory::Set(Ini, IniSection);
}
    
/*##########################################################################
#
#   Name       : TListFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TListFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::SetFont(int height)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(height);
}

/*##########################################################################
#
#   Name       : TListFactory::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TListFactory::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TListFactory::SetSelectedBackColor
#
#   Purpose....: Set selected back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::SetSelectedBackColor(int r, int g, int b)
{
    FSelectedBackR = r;
    FSelectedBackG = g;
    FSelectedBackB = b;
}

/*##########################################################################
#
#   Name       : TListFactory::SetSelectedDrawColor
#
#   Purpose....: Set selected draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::SetSelectedDrawColor(int r, int g, int b)
{
    FSelectedDrawR = r;
    FSelectedDrawG = g;
    FSelectedDrawB = b;
}

/*##########################################################################
#
#   Name       : TListFactory::SetDefault
#
#   Purpose....: Set default panel properties from factory settings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListFactory::SetDefault(TListControl *list, int xstart, int ystart, int xsize, int ysize)
{
    if (FFont)
        list->SetFont(FFont);
        
    list->SetSpace(FStartX, FStartY);
    list->SetDrawColor(FDrawR, FDrawG, FDrawB);            
    list->SetSelectedBackColor(FSelectedBackR, FSelectedBackG, FSelectedBackB);
    list->SetSelectedDrawColor(FSelectedDrawR, FSelectedDrawG, FSelectedDrawB);

    TPanelFactory::SetDefault(list, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TListFactory::Create
#
#   Purpose....: Create list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl *TListFactory::Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    TListControl *list;

    list = new TListControl(dev, xstart, ystart, xsize, ysize);

    SetDefault(list, xstart, ystart, xsize, ysize);

        return list;
}

/*##########################################################################
#
#   Name       : TListFactory::Create
#
#   Purpose....: Create list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl *TListFactory::Create(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    TListControl *list;

    list = new TListControl(control, xstart, ystart, xsize, ysize);

    SetDefault(list, xstart, ystart, xsize, ysize);

    return list;        
}

/*##########################################################################
#
#   Name       : TListFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TListFactory::CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TListFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TListFactory::CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TListFactory::CreateList
#
#   Purpose....: Create list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl *TListFactory::CreateList(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TListFactory::CreateList
#
#   Purpose....: Create list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl *TListFactory::CreateList(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}
    
/*##########################################################################
#
#   Name       : TListControl::TListControl
#
#   Purpose....: List control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl::TListControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(dev)
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
}

/*##########################################################################
#
#   Name       : TListControl::TListControl
#
#   Purpose....: List control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl::TListControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(control)
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
}
    
/*##########################################################################
#
#   Name       : TListControl::TListControl
#
#   Purpose....: List control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl::TListControl(TControlThread *dev)
 : TPanelControl(dev)
{
    Init();
}

/*##########################################################################
#
#   Name       : TListControl::TListControl
#
#   Purpose....: List control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl::TListControl(TControl *control)
 : TPanelControl(control)
{
    Init();
}

/*##########################################################################
#
#   Name       : TListControl::~TListControl
#
#   Purpose....: List control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl::~TListControl()
{
    if (FFont)
        delete FFont;
}

/*##########################################################################
#
#   Name       : TListControl::Init
#
#   Purpose....: Init control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Init()
{
    FFont = 0;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;

    FSelectedBackR = 150;
    FSelectedBackG = 150;
    FSelectedBackB = 255;

    FSelectedDrawR = 0;
    FSelectedDrawG = 0;
    FSelectedDrawB = 0;

    FRows = 0;
    FStartRow = 0;
    FSelected = -1;

    ControlType += TString(".LISTBOX");
}
    
/*##########################################################################
#
#   Name       : TListControl::IsListControl
#
#   Purpose....: Check if control is a listbox
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListControl::IsListControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".LISTBOX"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TListControl::NotifyResize
#
#   Purpose....: Notify size-change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::NotifyResize()
{
    int xstart, ystart;
    int xdiff, ydiff;
    int xsize, ysize;
    int xcontr, ycontr;

    if (FFont)
        FFont->GetStringMetrics("", &xsize, &ysize);
    else
        ysize = 0;

    if (ysize)
    {
        TControl::GetSize(&xcontr, &ycontr);
        GetInner(&xstart, &ystart, &xdiff, &ydiff);
        ycontr -= ydiff;

        FRowHeight = ysize + FStartY;

        FRows = ycontr / FRowHeight;
    }
    else
        FRows = 0;

    UpdateList();
}
    
/*##########################################################################
#
#   Name       : TListControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Set(TAppIniFile *Ini, const char *IniSection)
{
    char str[256];
    int size;

    Ini->GotoSection(IniSection);

    if (Ini->ReadVar("Font.Size", str, 255))
    {    
        size = atoi(str);

        if (size)
            SetFont(size);
    }

    if (Ini->ReadVar("DrawColor.R", str, 255))
        FDrawR = atoi(str);
    
    if (Ini->ReadVar("DrawColor.G", str, 255))
        FDrawG = atoi(str);

    if (Ini->ReadVar("DrawColor.B", str, 255))
        FDrawB = atoi(str);

            
    if (Ini->ReadVar("SelectedDrawColor.R", str, 255))
        FSelectedDrawR = atoi(str);
    
    if (Ini->ReadVar("SelectedDrawColor.G", str, 255))
        FSelectedDrawG = atoi(str);

    if (Ini->ReadVar("SelectedDrawColor.B", str, 255))
        FSelectedDrawB = atoi(str);

            
    if (Ini->ReadVar("SelectedBackColor.R", str, 255))
        FSelectedBackR = atoi(str);
    
    if (Ini->ReadVar("SelectedBackColor.G", str, 255))
        FSelectedBackG = atoi(str);

    if (Ini->ReadVar("SelectedBackColor.B", str, 255))
        FSelectedBackB = atoi(str);


    if (Ini->ReadVar("Space.X", str, 255))
        FStartX = atoi(str);
    
    if (Ini->ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);

    TPanelControl::Set(Ini, IniSection);
    NotifyResize();
}
    
/*##########################################################################
#
#   Name       : TListControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TListControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetFont(int height)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(height);

    NotifyResize();
}

/*##########################################################################
#
#   Name       : TListControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetFont(TFont *font)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(*font);

    NotifyResize();
}

/*##########################################################################
#
#   Name       : TListControl::GetFont
#
#   Purpose....: Get font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont *TListControl::GetFont()
{
    return FFont;
}

/*##########################################################################
#
#   Name       : TListControl::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;

    NotifyResize();
}

/*##########################################################################
#
#   Name       : TListControl::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TListControl::SetSelectedDrawColor
#
#   Purpose....: Set selected draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetSelectedDrawColor(int r, int g, int b)
{
    FSelectedDrawR = r;
    FSelectedDrawG = g;
    FSelectedDrawB = b;
}

/*##########################################################################
#
#   Name       : TListControl::SetSelectedBackColor
#
#   Purpose....: Set selected back color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetSelectedBackColor(int r, int g, int b)
{
    FSelectedBackR = r;
    FSelectedBackG = g;
    FSelectedBackB = b;
}

/*##########################################################################
#
#   Name       : TListControl::RedrawTrans
#
#   Purpose....: Redraw without erasing background
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::RedrawTrans()
{
//    int wastrans = FBackTrans;

//    FBackTrans = TRUE;
    Redraw();
//    FBackTrans = wastrans;
}

/*##########################################################################
#
#   Name       : TListControl::UpdateList
#
#   Purpose....: Update list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::UpdateList()
{
    int size;
    long double pos;

    size = FList.GetSize();
    
    if (size > FRows)
    {
        EnableVerScroll();
        
        pos = (long double)FRows / (long double)size;
        FVerScroll->SetScrollWidth(pos);

        UpdatePos();
    }        
    else
        DisableVerScroll();

    Redraw();
}

/*##########################################################################
#
#   Name       : TListControl::UpdatePos
#
#   Purpose....: Update scroll pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::UpdatePos()
{
    int size;
    long double pos;

    size = FList.GetSize();
    
    if (size > FRows)
    {
        pos = (long double)FStartRow / (long double)(size - FRows);
        FVerScroll->SetScrollPos(pos);        
    }        
}

/*##########################################################################
#
#   Name       : TListControl::Clear
#
#   Purpose....: Clear list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Clear()
{
    FList.Clear();
    FSelected = -1;
    FStartRow = 0;
    UpdateList();
}

/*##########################################################################
#
#   Name       : TListControl::Add
#
#   Purpose....: Add item last to list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Add(const char *str)
{
    TString Str(str);

    FList.Add(Str);
    UpdateList();
}

/*##########################################################################
#
#   Name       : TListControl::Add
#
#   Purpose....: Add item last to list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Add(TString &str)
{
    FList.Add(str);
    UpdateList();
}

/*##########################################################################
#
#   Name       : TListControl::Add
#
#   Purpose....: Add item at position to list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Add(int pos, const char *str)
{
    TString Str(str);

    if (FSelected >= pos)
        FSelected++;

    FList.Add(pos, Str);
    UpdateList();
}

/*##########################################################################
#
#   Name       : TListControl::Add
#
#   Purpose....: Add item at position to list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Add(int pos, TString &str)
{
    if (FSelected >= pos)
        FSelected++;

    FList.Add(pos, str);
    UpdateList();
}

/*##########################################################################
#
#   Name       : TListControl::Remove
#
#   Purpose....: Remove last item from list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Remove()
{
    if (FList.GetSize() - 1 == FSelected)
        FSelected = -1;
        
    FList.Remove();
    SetPos(FStartRow);
    UpdateList();
}

/*##########################################################################
#
#   Name       : TListControl::Remove
#
#   Purpose....: Remove specified item from list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Remove(int pos)
{
    if (FSelected == pos)
        FSelected = -1;

    if (FSelected > pos)
        FSelected--;
        
    FList.Remove(pos);
    SetPos(FStartRow);
    UpdateList();
}

/*##########################################################################
#
#   Name       : TListControl::GetSelected
#
#   Purpose....: Get currently selected item
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListControl::GetSelected()
{
    return FSelected;
}

/*##########################################################################
#
#   Name       : TListControl::GetSize
#
#   Purpose....: Get size of list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListControl::GetSize()
{
    return FList.GetSize();
}

/*##########################################################################
#
#   Name       : TListControl::Get
#
#   Purpose....: Get element text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TListControl::Get(int pos)
{
    return FList[pos];
}

/*##########################################################################
#
#   Name       : TListControl::SetPos
#
#   Purpose....: Set new start pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetPos(int pos)
{
    int size = FList.GetSize();

    if (pos > size - FRows)
        pos = size - FRows;
    
    if (pos < 0)
        pos = 0;

    if (pos != FStartRow)
    {
        FStartRow = pos;
        
        UpdatePos();
        RedrawTrans();
        NotifyChanged();
    }
}

/*##########################################################################
#
#   Name       : TListControl::SetSelected
#
#   Purpose....: Set new selected position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::SetSelected(int pos)
{
    int size = FList.GetSize();
    
    if (pos < 0)
        pos = 0;

    if (pos >= size)
        pos = size - 1;

    if (pos < FStartRow)
        SetPos(pos);

    if (pos >= FStartRow + FRows)
        SetPos(pos - FRows + 1);

    if (pos != FSelected)
    {
        FSelected = pos;
        RedrawTrans();
        NotifyChanged();
    }
}

/*##########################################################################
#
#   Name       : TListControl::GotoStart
#
#   Purpose....: Goto start of list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::GotoStart()
{
    SetSelected(0);
}

/*##########################################################################
#
#   Name       : TListControl::GotoEnd
#
#   Purpose....: Goto end of list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::GotoEnd()
{
    SetSelected(FList.GetSize() - 1);
}

/*##########################################################################
#
#   Name       : TListControl::Goto
#
#   Purpose....: Goto specified line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Goto(int row)
{
    SetSelected(row);
}

/*##########################################################################
#
#   Name       : TListControl::ArrowDown
#
#   Purpose....: Move selection to next line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::ArrowDown()
{
    if (FSelected >= 0)
        SetSelected(FSelected + 1);
    else
        SetSelected(FStartRow + 1);
}

/*##########################################################################
#
#   Name       : TListControl::ArrowUp
#
#   Purpose....: Move selection to previous line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::ArrowUp()
{
    if (FSelected >= 0)
        SetSelected(FSelected - 1);
    else
        SetSelected(FStartRow - 1);
}

/*##########################################################################
#
#   Name       : TListControl::KeyPageDown
#
#   Purpose....: Move selection to next page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::KeyPageDown()
{
    if (FSelected >= 0)
        SetSelected(FSelected + FRows);
    else
        SetSelected(FStartRow + FRows);
}

/*##########################################################################
#
#   Name       : TListControl::KeyPageUp
#
#   Purpose....: Move selection to previous page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::KeyPageUp()
{
    if (FSelected >= 0)
        SetSelected(FSelected - FRows);
    else
        SetSelected(FStartRow - FRows);
}

/*##########################################################################
#
#   Name       : TListControl::ScrollUp
#
#   Purpose....: Goto previous line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::ScrollUp()
{
    SetPos(FStartRow - 1);
}

/*##########################################################################
#
#   Name       : TListControl::ScrollDown
#
#   Purpose....: Goto next line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::ScrollDown()
{
    SetPos(FStartRow + 1);
}

/*##########################################################################
#
#   Name       : TListControl::PageDown
#
#   Purpose....: Do page down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::PageDown()
{
    SetPos(FStartRow + FRows);
}

/*##########################################################################
#
#   Name       : TListControl::PageUp
#
#   Purpose....: Goto previous page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::PageUp()
{
    SetPos(FStartRow - FRows);
}

/*##########################################################################
#
#   Name       : TListControl::VerMove
#
#   Purpose....: Vertical scroll ruler moving
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::VerMove(long double pos)
{
    int size;
    int row;

    size = FList.GetSize();
    
    if (size > FRows)
    {
        row = (int)(pos * (long double)(size - FRows));
        SetPos(row);        
    }            
}

/*##########################################################################
#
#   Name       : TListControl::OnLeftUp
#
#   Purpose....: Handle left button up
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListControl::OnLeftUp(int x, int y, int ButtonState, int KeyState)
{
    if (IsInsidePanel(x, y))
        return TRUE;
    else
        return TControl::OnLeftUp(x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TListControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    int xstart, ystart;
    int xoffs, yoffs;
         int xdiff, ydiff;
    int row;
        
    if (FFont && IsInsidePanel(x, y))
    {
        GetPos(&xstart, &ystart);
        y -= ystart;

        GetInner(&xoffs, &yoffs, &xdiff, &ydiff);
        y -= yoffs;

        row = y / FRowHeight;
        row += FStartRow;

        if (row < FList.GetSize())
        {
            FSelected = row;
            UpdateList();
        }        
        return TRUE;
    }
    else
        return TControl::OnLeftDown(x, y, ButtonState, KeyState);
}

/*##########################################################################
#
#   Name       : TListControl::OnKeyPressed
#
#   Purpose....: Handle key pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    switch (VirtualKey)
    {
        case VK_HOME:
        case VK_NUMPAD7:
            GotoStart();
            return TRUE;

        case VK_END:
        case VK_NUMPAD1:
            GotoEnd();
            return TRUE;

        case VK_UP:
        case VK_NUMPAD8:
            ArrowUp();
            return TRUE;

        case VK_DOWN:
        case VK_NUMPAD2:
            ArrowDown();
            return TRUE;

        case VK_NEXT:
        case VK_NUMPAD3:
            KeyPageDown();
            return TRUE;

        case VK_PRIOR:
        case VK_NUMPAD9:
            KeyPageUp();
            return TRUE;

        default:
            return TControl::OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);

    }
}

/*##########################################################################
#
#   Name       : TListControl::OnKeyReleased
#
#   Purpose....: Handle key released
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    switch (VirtualKey)
    {
        case VK_HOME:
        case VK_NUMPAD7:
        case VK_END:
        case VK_NUMPAD1:
        case VK_UP:
        case VK_NUMPAD8:
        case VK_DOWN:
        case VK_NUMPAD2:
        case VK_NEXT:
        case VK_NUMPAD3:
        case VK_PRIOR:
        case VK_NUMPAD9:
            return TRUE;

        default:
                                return TControl::OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode);
         }
}

/*##########################################################################
#
#   Name       : TListControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int xstart;
    int ystart;
    int xmax, ymax;
    int row;
    int curr;
    int xoffs, yoffs;
    int xdiff, ydiff;
    int redraw;
    TString str;

    TPanelControl::Paint(dev, xmin, ymin, width, height);
    GetInner(&xoffs, &yoffs, &xdiff, &ydiff);

    xmin += xoffs;
    ymin += yoffs;
        width -= xdiff;
    height -= ydiff;

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

        xstart = xmin + FStartX;
        ystart = ymin + FStartY;

        dev->SetFont(FFont);
        
        for (row = 0; row < FRows; row++)
        {
            curr = FStartRow + row;

                        if (curr == FSelected)
                        {
                                dev->SetDrawColor(FSelectedBackR, FSelectedBackG, FSelectedBackB);
                dev->DrawRect(xmin, ystart, xmax, ystart + FRowHeight - 1);
                                dev->SetDrawColor(FSelectedDrawR, FSelectedDrawG, FSelectedDrawB);
            }                                           
                        else
                            dev->SetDrawColor(FDrawR, FDrawG, FDrawB);

            str = FList[curr];            
                        dev->DrawString(xstart, ystart, str.GetData());

            ystart += FRowHeight;
        }
    }
}
