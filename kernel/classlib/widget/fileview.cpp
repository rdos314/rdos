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

    if (FFont)
        delete FFont;
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
    FFont = 0;
    
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
    UpdateTextRows();
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
#   Name       : TFileViewControl::UpdateTextRows
#
#   Purpose....: Update text rows with current window size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileViewControl::UpdateTextRows()
{
    int xsize, ysize;
    int xcontr, ycontr;
    int i;

    FreeTextRows();    

    if (FFont)
        FFont->GetStringMetrics("", &xsize, &ysize);
    else
        ysize = 0;

    if (ysize)
    {
        GetSize(&xcontr, &ycontr);

        FRows = ycontr / ysize;

        FTextData = new char *[FRows];

        for (i = 0; i < FRows; i++)
            FTextData[i] = 0;
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
}
