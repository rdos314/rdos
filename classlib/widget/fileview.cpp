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
# fileview.cpp
# File view control class
#
########################################################################*/

#include <string.h>

#include "fileview.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TFileViewFactory::TFileViewFactory
#
#   Purpose....: Button factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewFactory::TFileViewFactory()
{
    Init();
}

/*##########################################################################
#
#   Name       : TFileViewFactory::~TFileViewFactory
#
#   Purpose....: Button factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewFactory::~TFileViewFactory()
{
    if (FFont)
        delete FFont;
}
    
/*##########################################################################
#
#   Name       : TFileViewFactory::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewFactory::Init()
{
    FFont = 0;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;
}
    
/*##########################################################################
#
#   Name       : TFileViewFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewFactory::Set(TAppIniFile *Ini, const char *IniSection)
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


    if (Ini->ReadVar("Space.X", str, 255))
        FStartX = atoi(str);
    
    if (Ini->ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);

    TPanelFactory::Set(Ini, IniSection);
}
    
/*##########################################################################
#
#   Name       : TFileViewFactory::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewFactory::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TFileViewFactory::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewFactory::SetFont(int height)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(height);
}

/*##########################################################################
#
#   Name       : TFileViewFactory::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewFactory::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TFileViewFactory::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewFactory::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TFileViewFactory::SetDefault
#
#   Purpose....: Set default panel properties from factory settings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewFactory::SetDefault(TFileViewControl *view, int xstart, int ystart, int xsize, int ysize)
{
    if (FFont)
        view->SetFont(FFont);
        
    view->SetSpace(FStartX, FStartY);
    view->SetDrawColor(FDrawR, FDrawG, FDrawB);            

    TPanelFactory::SetDefault(view, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TFileViewFactory::Create
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl *TFileViewFactory::Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    TFileViewControl *fileview;

    fileview = new TFileViewControl(dev, xstart, ystart, xsize, ysize);

    SetDefault(fileview, xstart, ystart, xsize, ysize);

        return fileview;
}

/*##########################################################################
#
#   Name       : TFileViewFactory::Create
#
#   Purpose....: Create label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl *TFileViewFactory::Create(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    TFileViewControl *fileview;

    fileview = new TFileViewControl(control, xstart, ystart, xsize, ysize);

    SetDefault(fileview, xstart, ystart, xsize, ysize);

    return fileview;        
}

/*##########################################################################
#
#   Name       : TFileViewFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TFileViewFactory::CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TFileViewFactory::CreatePanel
#
#   Purpose....: Create panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TFileViewFactory::CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TFileViewFactory::CreateFileView
#
#   Purpose....: Create file-view control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl *TFileViewFactory::CreateFileView(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
{
    return Create(dev, xstart, ystart, xsize, ysize);
}

/*##########################################################################
#
#   Name       : TFileViewFactory::CreateFileView
#
#   Purpose....: Create file-view control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl *TFileViewFactory::CreateFileView(TControl *control, int xstart, int ystart, int xsize, int ysize)
{
    return Create(control, xstart, ystart, xsize, ysize);
}
    
/*##########################################################################
#
#   Name       : TFileViewControl::TFileViewControl
#
#   Purpose....: File-view control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl::TFileViewControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(dev)
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
}

/*##########################################################################
#
#   Name       : TFileViewControl::TFileViewControl
#
#   Purpose....: File-view control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl::TFileViewControl(TControl *control, int xstart, int ystart, int xsize, int ysize)
 : TPanelControl(control)
{
    Init();

    Resize(xsize, ysize);
    Move(xstart, ystart);
}
    
/*##########################################################################
#
#   Name       : TFileViewControl::TFileViewControl
#
#   Purpose....: File-view control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl::TFileViewControl(TControlThread *dev)
 : TPanelControl(dev)
{
    Init();
}

/*##########################################################################
#
#   Name       : TFileViewControl::TFileViewControl
#
#   Purpose....: File-view control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl::TFileViewControl(TControl *control)
 : TPanelControl(control)
{
    Init();
}

/*##########################################################################
#
#   Name       : TFileViewControl::~TFileViewControl
#
#   Purpose....: File-view control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl::~TFileViewControl()
{
    if (FFont)
        delete FFont;

    if (FFile)
        delete FFile;
}

/*##########################################################################
#
#   Name       : TFileViewControl::Init
#
#   Purpose....: Init control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Init()
{
    FFont = 0;
    FFile = 0;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;

    FRows = 0;
    FStartRow = 0;
    FStartCol = 0;
    FMaxWidth = 0;
    FControlWidth = 0;

    ControlType += TString(".FILEVIEW");
}
    
/*##########################################################################
#
#   Name       : TFileViewControl::IsFileViewControl
#
#   Purpose....: Check if control is a file-view
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFileViewControl::IsFileViewControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".FILEVIEW"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFileViewControl::NotifyResize
#
#   Purpose....: Notify size-change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::NotifyResize()
{
    UpdateList();
}
    
/*##########################################################################
#
#   Name       : TFileViewControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Set(TAppIniFile *Ini, const char *IniSection)
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


    if (Ini->ReadVar("Space.X", str, 255))
        FStartX = atoi(str);
    
    if (Ini->ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);

    TPanelControl::Set(Ini, IniSection);
    NotifyResize();
}
    
/*##########################################################################
#
#   Name       : TFileViewControl::Set
#
#   Purpose....: Load settings from ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Set(const char *IniName, const char *IniSection)
{
    TAppIniFile Ini(IniName);
    Set(&Ini, IniSection);
}

/*##########################################################################
#
#   Name       : TFileViewControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::SetFont(int height)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(height);

    NotifyResize();
}

/*##########################################################################
#
#   Name       : TFileViewControl::SetFont
#
#   Purpose....: Set font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::SetFont(TFont *font)
{
    if (FFont)
        delete FFont;
        
    FFont = new TFont(*font);

    NotifyResize();
}

/*##########################################################################
#
#   Name       : TFileViewControl::SetSpace
#
#   Purpose....: Set unused space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::SetSpace(int xstart, int ystart)
{
    FStartX = xstart;
    FStartY = ystart;
}

/*##########################################################################
#
#   Name       : TFileViewControl::SetDrawColor
#
#   Purpose....: Set draw color
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::SetDrawColor(int r, int g, int b)
{
    FDrawR = r;
    FDrawG = g;
    FDrawB = b;
}

/*##########################################################################
#
#   Name       : TFileViewControl::Load
#
#   Purpose....: Load file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Load(int pos)
{
    char *buf;
    char *dbuf;
    long fsize;
    int bsize;
    int dsize;
    int done;
    int src;
        int dest;
        char ch;
    int size;

    if (FFile)
    {
        buf = new char[4097];
        dbuf = new char[17000];

        fsize = (int)FFile->GetSize();
        if (fsize < pos)
            pos = fsize;

        while (fsize)
        {            

            FFile->SetPos(pos);
            bsize = FFile->Read(buf, 4096);

            for (dsize = 0; dsize < bsize; dsize++)
                if (buf[dsize] == 0xd)
                    break;

            fsize = dsize;            

            if (dsize && buf[dsize] == 0xd)
                dsize--;
                
            done = FALSE;
            while (dsize && !done)
            {
                switch (buf[dsize])
                {
                    case 0xa:
                    case ' ':
                                case 0x9:
                        dsize--;
                        break;

                    case 0xd:
                        dsize--;
                        done = TRUE;
                        break;

                    default:
                        done = TRUE;
                        break;
                }
            }
    
            if (fsize)
                dsize++;

            if (bsize && buf[fsize] == 0xd)
                fsize++;

            done = FALSE;
            while (fsize < bsize && !done)
            {
                switch (buf[fsize])
                {
                    case 0xa:
                        fsize++;
                        break;

                    default:
                        done = TRUE;
                        break;
                }
            }

            FFile->SetPos(pos);
            size = FFile->Read(buf, dsize);

            dest = 0;
            for (src = 0; src < size; src++)
            {
                ch = buf[src];
                if (ch == 0x9)
                {
                    dbuf[dest] = ' ';
                    dest++;
                            
                    while ((dest % 4) != 0)
                    {
                        dbuf[dest] = ' ';
                        dest++;
                    }                         
                }
                else
                {
                    dbuf[dest] = ch;
                    dest++;
                }
            }
            dbuf[dest] = 0;

            FList.Add(TString(dbuf));

            pos += fsize;
        }

        delete buf;
        delete dbuf;                
    }
    UpdateList();
}

/*##########################################################################
#
#   Name       : TFileViewControl::Load
#
#   Purpose....: Load a new file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Load(const char *FileName)
{
    FList.Clear();

    if (FFile)
        delete FFile;

    FFile = new TFile(FileName);

         Load(0);
}

/*##########################################################################
#
#   Name       : TFileViewControl::Load
#
#   Purpose....: Load a new file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Load(TString &FileName)
{
    FList.Clear();

    if (FFile)
        delete FFile;

    FFile = new TFile(FileName.GetData());

    Load(0);
}

/*##########################################################################
#
#   Name       : TFileViewControl::RedrawTrans
#
#   Purpose....: Redraw without erasing background
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::RedrawTrans()
{
//    int wastrans = FBackTrans;

//    FBackTrans = TRUE;
    Redraw();
//    FBackTrans = wastrans;
}

/*##########################################################################
#
#   Name       : TFileViewControl::UpdateList
#
#   Purpose....: Update list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::UpdateList()
{
    TString str;
    int i;
    int size = FList.GetSize();
    int xstart, ystart;
    int xsize, ysize;
    int xdiff, ydiff;
        int xcontr, ycontr;
    int maxwidth = 0;
    long double pos;

    ysize = 0;

    if (FFont)
    {
        for (i = 0; i < size; i++)
        {
            str = FList[i];
            FFont->GetStringMetrics(str.GetData(), &xsize, &ysize);

            if (xsize > maxwidth)
                maxwidth = xsize;
        }
    }

    TControl::GetSize(&xcontr, &ycontr);
    GetInner(&xstart, &ystart, &xdiff, &ydiff);

    if (FVerScroll && FVerScroll->IsEnabled())
        xdiff -= FVerScroll->GetWidth();

    if (FHorScroll && FHorScroll->IsEnabled())
        ydiff -= FHorScroll->GetWidth();

    xcontr -= xdiff;
    ycontr -= ydiff;

    if (ysize)
    {

        FRowHeight = ysize + FStartY;

        FRows = ycontr / FRowHeight;
    }
    else
        FRows = 0;
    
    if (size > FRows)
    {
        EnableVerScroll();
                xcontr -= FVerScroll->GetWidth();

                pos = (long double)FRows / (long double)size;
                FVerScroll->SetScrollWidth(pos);

                UpdateVerPos();
    }

        FMaxWidth = 0;

        if (maxwidth > xcontr)
    {
                 EnableHorScroll();
                ycontr -= FHorScroll->GetWidth();

                pos = (long double)xcontr / (long double)maxwidth;
                FHorScroll->SetScrollWidth(pos);
                FMaxWidth = maxwidth;
                FControlWidth = xcontr;
                FRows = ycontr / FRowHeight;

                UpdateHorPos();
         }
         else
            DisableHorScroll();

         if (size > FRows)
         {
            EnableVerScroll();
                pos = (long double)FRows / (long double)size;
                FVerScroll->SetScrollWidth(pos);

                UpdateVerPos();
    }    
    else
        DisableVerScroll();    

    Redraw();
}

/*##########################################################################
#
#   Name       : TFileViewControl::UpdateVerPos
#
#   Purpose....: Update vertical scroll pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::UpdateVerPos()
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
#   Name       : TFileViewControl::UpdateHorPos
#
#   Purpose....: Update horisontal scroll pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::UpdateHorPos()
{
        long double pos;

        if (FMaxWidth > FControlWidth)
    {
        pos = (long double)FStartCol / (long double)(FMaxWidth - FControlWidth);
        FHorScroll->SetScrollPos(pos);        
    }        
}

/*##########################################################################
#
#   Name       : TFileViewControl::SetVerPos
#
#   Purpose....: Set new vertical start pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::SetVerPos(int pos)
{
    int size = FList.GetSize();

    if (pos > size - FRows)
        pos = size - FRows;
    
    if (pos < 0)
        pos = 0;

    if (pos != FStartRow)
    {
        FStartRow = pos;
        
        UpdateVerPos();
        RedrawTrans();
        NotifyChanged();
    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::SetHorPos
#
#   Purpose....: Set new horisontal start pos
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::SetHorPos(int pos)
{
         if (pos > FMaxWidth - FControlWidth)
                  pos = FMaxWidth - FControlWidth;
    
    if (pos < 0)
        pos = 0;

    if (pos != FStartCol)
    {
        FStartCol = pos;
        
        UpdateHorPos();
        RedrawTrans();
        NotifyChanged();
    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::GotoStart
#
#   Purpose....: Goto start of file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::GotoStart()
{
    SetVerPos(0);
}

/*##########################################################################
#
#   Name       : TFileViewControl::GotoEnd
#
#   Purpose....: Goto end of file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::GotoEnd()
{
    SetVerPos(FList.GetSize() - 1);
}

/*##########################################################################
#
#   Name       : TFileViewControl::Goto
#
#   Purpose....: Goto specified line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Goto(int row)
{
    SetVerPos(row);
}

/*##########################################################################
#
#   Name       : TFileViewControl::ScrollDown
#
#   Purpose....: Goto next line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::ScrollDown()
{
    SetVerPos(FStartRow + 1);
}

/*##########################################################################
#
#   Name       : TFileViewControl::ScrollUp
#
#   Purpose....: Goto previous line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::ScrollUp()
{
    SetVerPos(FStartRow - 1);
}

/*##########################################################################
#
#   Name       : TFileViewControl::PageDown
#
#   Purpose....: Do page down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::PageDown()
{
    SetVerPos(FStartRow + FRows);
}

/*##########################################################################
#
#   Name       : TFileViewControl::PageUp
#
#   Purpose....: Goto previous page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::PageUp()
{
    SetVerPos(FStartRow - FRows);
}

/*##########################################################################
#
#   Name       : TFileViewControl::VerMove
#
#   Purpose....: Vertical scroll ruler moving
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::VerMove(long double pos)
{
    int size;
    int row;

    size = FList.GetSize();
    
    if (size > FRows)
    {
        row = (int)(pos * (long double)(size - FRows));
        SetVerPos(row);        
    }            
}

/*##########################################################################
#
#   Name       : TFileViewControl::AdjustHor
#
#   Purpose....: Adjust horisontal position to 4-tabs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFileViewControl::AdjustHor()
{
    int xsize, ysize;
    int count;

    if (FFont)
        FFont->GetStringMetrics("    ", &xsize, &ysize);
    else
        xsize = 10;

    count = (FStartCol + xsize / 2) / xsize;
    FStartCol = xsize * count;

    return xsize;
}

/*##########################################################################
#
#   Name       : TFileViewControl::ScrollRight
#
#   Purpose....: Goto next col
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::ScrollRight()
{
         int xsize;

         xsize = AdjustHor();
         SetHorPos(FStartCol + xsize);
}

/*##########################################################################
#
#   Name       : TFileViewControl::ScrollLeft
#
#   Purpose....: Goto previous col
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::ScrollLeft()
{
         int xsize;

         xsize = AdjustHor();
         SetHorPos(FStartCol - xsize);
}

/*##########################################################################
#
#   Name       : TFileViewControl::PageRight
#
#   Purpose....: Do page right
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::PageRight()
{
    SetHorPos(FStartCol + FControlWidth / 2);
}

/*##########################################################################
#
#   Name       : TFileViewControl::PageLeft
#
#   Purpose....: Goto previous page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::PageLeft()
{
    SetHorPos(FStartCol - FControlWidth / 2);
}

/*##########################################################################
#
#   Name       : TFileViewControl::HorMove
#
#   Purpose....: Horisontal scroll ruler moving
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::HorMove(long double pos)
{
        int val;

        if (FMaxWidth > FControlWidth)
    {
        val = (int)(pos * (long double)(FMaxWidth - FControlWidth));
        SetHorPos(val);        
    }            
}

/*##########################################################################
#
#   Name       : TFileViewControl::OnKeyPressed
#
#   Purpose....: Handle key pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFileViewControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
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
            ScrollUp();
            return TRUE;

        case VK_DOWN:
        case VK_NUMPAD2:
            ScrollDown();
            return TRUE;

        case VK_NEXT:
        case VK_NUMPAD3:
            PageDown();
            return TRUE;

        case VK_PRIOR:
        case VK_NUMPAD9:
            PageUp();
            return TRUE;

        case VK_NUMPAD4:
            ScrollLeft();
            return TRUE;

        case VK_NUMPAD6:
            ScrollRight();
            return TRUE;

        default:
            return TControl::OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);

    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::OnKeyReleased
#
#   Purpose....: Handle key released
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFileViewControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
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
        case VK_NUMPAD4:
        case VK_NUMPAD6:
            return TRUE;

        default:
            return TControl::OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);
    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
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

            str = FList[curr];            
                                SetBackColor(dev);
                                dev->DrawRect(xmin, ystart, xmax, ystart + FRowHeight - 1);

            dev->SetDrawColor(FDrawR, FDrawG, FDrawB);
                        dev->DrawString(xstart - FStartCol, ystart, str.GetData());

            ystart += FRowHeight;
        }
    }
}
