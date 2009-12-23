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
    FreeFilePos();

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
    FRows = 0;
    FTextData = 0;
    FFilePos = 0;
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
    long pos = 0;

    if (FFilePos)
        pos = FFilePos[0];

    FreeTextRows();
    FreeFilePos();

    if (FFont)
        FFont->GetStringMetrics("", &xsize, &ysize);
    else
        ysize = 0;

    if (ysize)
    {
        GetSize(&xcontr, &ycontr);

        rows = ycontr / ysize;

        CreateTextRows(rows);
        CreateFilePos(rows);

        FRows = rows;

        LoadFromPos(pos);
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
        for (i = 0; i < FRows; i++)
            if (FTextData[i])
                delete FTextData[i];

        delete FTextData;

        FTextData = 0;
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
}

/*##########################################################################
#
#   Name       : TFileViewControl::FreeFilePos
#
#   Purpose....: Free file positions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::FreeFilePos()
{
    if (FFilePos)
    {
        delete FFilePos;
        FFilePos = 0;
    }
}

/*##########################################################################
#
#   Name       : TFileViewControl::CreateFilePos
#
#   Purpose....: Create file positions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::CreateFilePos(int rows)
{
    int i;
    
    FFilePos = new long[rows];

    for (i = 0; i < rows; i++)
        FFilePos[i] = 0;
}

/*##########################################################################
#
#   Name       : TFileViewControl::LoadFromPos
#
#   Purpose....: Load from specified position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::LoadFromPos(long pos)
{
    char *buf;
    char *dbuf;
    int src;
    int dest;
    long fsize;
    int bsize;
    int dsize;
    int done;
    int row;
    char ch;

    buf = new char[4097];
    dbuf = new char[17000];

    if (FFile)
    {
        fsize = FFile->GetSize();
        if (fsize < pos)
            pos = fsize;

        for (row = 0; row < FRows; row++)
        {        
            FFilePos[row] = pos;
            
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

            if (FTextData[row])
            {
                delete FTextData[row];
                FTextData[row] = 0;
            }

            if (dsize)
            {
                dest = 0;
                for (src = 0; src < dsize; src++)
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

                FTextData[row] = new char[dest + 1];
                strcpy(FTextData[row], dbuf);
            }

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
            pos += fsize;
        }
        FNextPos = pos;
                
    }
    else
    {
        for (row = 0; row < FRows; row++)
        {        
            FFilePos[row] = 0;

            if (FTextData[row])
            {
                delete FTextData[row];
                FTextData[row] = 0;
            }
        }
        FNextPos = 0;
    }

    delete buf;
    delete dbuf;
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
    if (FFile)
        delete FFile;

    FFile = new TFile(FileName);

    LoadFromPos(0);
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
    if (FFile)
        delete FFile;

    FFile = new TFile(FileName.GetData());

    LoadFromPos(0);
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
    LoadFromPos(0);
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
        
        for (row = 0; row < FRows; row++)
        {
				if (FTextData[row])
					 dev->DrawString(xstart, ystart, FTextData[row]);

            ystart += ysize;
        }
    }
}
