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
#include "ini.h"

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
void TFileViewFactory::Set(const char *IniName, const char *IniSection)
{
    TIniFile Ini(IniName);
    char str[256];
    int size;

    Ini.GotoSection(IniSection);

    if (Ini.ReadVar("Font.Size", str, 255))
    {    
        size = atoi(str);

        if (size)
            SetFont(size);
    }
            
    if (Ini.ReadVar("DrawColor.R", str, 255))
        FDrawR = atoi(str);
    
    if (Ini.ReadVar("DrawColor.G", str, 255))
        FDrawG = atoi(str);

    if (Ini.ReadVar("DrawColor.B", str, 255))
        FDrawB = atoi(str);


    if (Ini.ReadVar("Space.X", str, 255))
        FStartX = atoi(str);
    
    if (Ini.ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);

    TPanelFactory::Set(IniName, IniSection);
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
void TFileViewFactory::SetDefault(TFileViewControl *label, int xstart, int ystart, int xsize, int ysize)
{
    if (FFont)
        label->SetFont(FFont);
        
    label->SetSpace(FStartX, FStartY);
    label->SetDrawColor(FDrawR, FDrawG, FDrawB);            

    TPanelFactory::SetDefault(label, xstart, ystart, xsize, ysize);
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
    FreeTextRows();

    if (FFilePos)
        delete FFilePos;

    if (FFileSize)
        delete FFileSize;

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
    FStartRow = 0;
    FLastRow = 0;
    FLastPos = 0;
    FViewRows = 0;
    FFileRows = 0;
    FTextData = 0;
    FFilePos = 0;
    FFileSize = 0;
    FFont = 0;
    FFile = 0;
    
    FStartX = 0;
    FStartY = 0;

    FDrawR = 0;
    FDrawG = 0;
    FDrawB = 0;
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
    int xsize, ysize;
    int xcontr, ycontr;
    int rows;

    FreeTextRows();

    if (FFont)
        FFont->GetStringMetrics("", &xsize, &ysize);
    else
        ysize = 0;

    if (ysize)
    {
        GetSize(&xcontr, &ycontr);

        rows = ycontr / ysize;

        CreateTextRows(rows);
        BufferTexts(FStartRow);
    }
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
    TIniFile Ini(IniName);
    char str[256];
    int size;

    Ini.GotoSection(IniSection);

    if (Ini.ReadVar("Font.Size", str, 255))
    {    
        size = atoi(str);

        if (size)
            SetFont(size);
    }

    if (Ini.ReadVar("DrawColor.R", str, 255))
        FDrawR = atoi(str);
    
    if (Ini.ReadVar("DrawColor.G", str, 255))
        FDrawG = atoi(str);

    if (Ini.ReadVar("DrawColor.B", str, 255))
        FDrawB = atoi(str);


    if (Ini.ReadVar("Space.X", str, 255))
        FStartX = atoi(str);
    
    if (Ini.ReadVar("Space.Y", str, 255))
        FStartY = atoi(str);

    TPanelControl::Set(IniName, IniSection);
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
#   Name       : TFileViewControl::FreeTextRows
#
#   Purpose....: Free text rows
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::FreeTextRows()
{
    int i; 

    if (FTextData)
    {
        for (i = 0; i < FViewRows; i++)
            if (FTextData[i])
                delete FTextData[i];

        delete FTextData;

        FTextData = 0;
    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::ClearTextRows
#
#   Purpose....: Clear text rows
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::ClearTextRows()
{
    int i; 

    if (FTextData)
    {
        for (i = 0; i < FViewRows; i++)
        {
            if (FTextData[i])
                delete FTextData[i];
            FTextData[i] = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::CreateTextRows
#
#   Purpose....: Create text rows
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::CreateTextRows(int rows)
{
    int i;
    
    FTextData = new char *[rows];

    for (i = 0; i < rows; i++)
        FTextData[i] = 0;

    FViewRows = rows;
}

/*##########################################################################
#
#   Name       : TFileViewControl::CacheRows
#
#   Purpose....: Cache rows in file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::CacheRows(int rows)
{
    long *NewPos;
    int *NewSize;
    char *buf;
    char *dbuf;
    long fsize;
    int bsize;
    int dsize;
    int done;
    int row;
    int count;
    long pos;

    if (rows)
    {
        NewPos = new long[rows];
        NewSize = new int[rows];
    }
    else
    {
        NewPos = 0;
        NewSize = 0;
    }

    count = rows;
    if (count > FFileRows)
        count = FFileRows;

    for (row = 0; row < count; row++)
    {
        NewPos[row] = FFilePos[row];
        NewSize[row] = FFileSize[row];
    }

    if (count)
    {
        for (row = count; row < rows; row++)
        {
            NewPos[row] = FFilePos[count - 1];
            NewSize[row] = 0;
        }
        pos = NewPos[count - 1] + NewSize[count - 1];
    }
    else
    {
        for (row = count; row < rows; row++)
        {
            NewPos[row] = 0;
            NewSize[row] = 0;
        }
        pos = 0;
    }

    if (FFilePos)
        delete FFilePos;

    if (FFileSize)
        delete FFileSize;
    
    FFilePos = NewPos;
    FFileSize = NewSize;
    FFileRows = rows;

    if (FFile && rows)
    {
        buf = new char[4097];
        dbuf = new char[17000];
    
        fsize = FFile->GetSize();
        if (fsize < pos)
            pos = fsize;

        if (FLastRow > fsize)
        {
            FLastRow = 0;
            FLastPos = 0;
        }
            
        for (row = count; row < rows; row++)
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

            FFilePos[row] = pos;
            FFileSize[row] = dsize;

            pos += fsize;

            if (bsize)
            {
                if (row > FLastRow)
                {
                    FLastRow = row;
                    FLastPos = pos;
                }
            }
        }

        delete buf;
        delete dbuf;
                
    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::BufferTexts
#
#   Purpose....: Buffer texts for display
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::BufferTexts(int StartRow)
{
    char *buf;
    char *dbuf;
    int rows;
    int row;
    int i;
    int size;
    int src;
	 int dest;
    char ch;

    FStartRow = StartRow;

    ClearTextRows();
    
    if (StartRow + FViewRows > FFileRows)
    {
        rows = 2 * FFileRows;
        if (rows < StartRow + FViewRows)
            rows = StartRow + FViewRows;
            
        CacheRows(rows);    
    }

    if (FFile)
    {

        buf = new char[4097];
        dbuf = new char[17000];

        row = StartRow;
        for (i = 0; i < FViewRows; i++)       
        {
            FFile->SetPos(FFilePos[row]);
            size = FFile->Read(buf, FFileSize[row]);

            if (size)
            {
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

                FTextData[i] = new char[dest + 1];
                strcpy(FTextData[i], dbuf);
            }

            row++;            
        }

        delete buf;
        delete dbuf;
    }
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
    CacheRows(0);

    if (FFile)
        delete FFile;

    FFile = new TFile(FileName);

    BufferTexts(0);
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
    CacheRows(0);

    if (FFile)
        delete FFile;

    FFile = new TFile(FileName.GetData());

    BufferTexts(0);
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
    int wastrans = FBackTrans;

    FBackTrans = TRUE;
    Redraw();
    FBackTrans = wastrans;
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
    BufferTexts(0);
    RedrawTrans();
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
    if (FFile)
        while (FLastPos < FFile->GetSize())
            CacheRows(2 * FFileRows + 16);    

    if (FLastRow < FViewRows)
        BufferTexts(0);
    else
        BufferTexts(FLastRow - FViewRows + 1);

    RedrawTrans();
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
    if (FFile)
    {
        if (row + FViewRows > FLastRow)
            if (FLastPos < FFile->GetSize())
                CacheRows(row + FViewRows);
                
        if (row + FViewRows - 1 >= FLastRow)
            row = FLastRow - FViewRows + 1;

        if (row < 0)
            row = 0;

        BufferTexts(row);
        RedrawTrans();
    }
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
    int row;

    row = FStartRow;

    if (FFile)
    {
        if (FLastPos < FFile->GetSize())
            row++;
        else
        {
            if (FStartRow + FViewRows - 1 < FLastRow)
                row++;
        }
    }

    if (row != FStartRow)
    {
        BufferTexts(row);
        RedrawTrans();
    }
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
    if (FStartRow)
    {
        BufferTexts(FStartRow - 1);
        RedrawTrans();
    }
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
    int row;

    if (FFile)
    {
        row = FStartRow + FViewRows;

        if (row + FViewRows > FLastRow)
            if (FLastPos < FFile->GetSize())
                CacheRows(FFileRows + FViewRows);    
        
        if (row + FViewRows - 1 >= FLastRow)
            row = FLastRow - FViewRows + 1;

        BufferTexts(row);
        RedrawTrans();
    }
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
    int row;

    if (FStartRow)
    {
        row = FStartRow - FViewRows;

        if (row < 0)
            row = 0;
            
        BufferTexts(row);
        RedrawTrans();
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
    int xsize;
    int ysize;
    int xmax, ymax;
    int row;
    int xoffs, yoffs;
    int xdiff, ydiff;
    int redraw;

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

        dev->SetClipRect(  xmin, ymin,
                           xmax, ymax);

        FFont->GetStringMetrics("", &xsize, &ysize);

        xstart = xmin + FStartX;
        ystart = ymin + FStartY;

        dev->SetFont(FFont);
        dev->SetDrawColor(FDrawR, FDrawG, FDrawB);
        
        for (row = 0; row < FViewRows; row++)
        {
			if (FTextData[row])
			    dev->DrawString(xstart, ystart, FTextData[row]);

            ystart += ysize;
        }
    }
}
