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
# fileview.h
# File-view control class
#
########################################################################*/

#ifndef _FILEVIEWCTL_H
#define _FILEVIEWCTL_H

#include "bitdev.h"
#include "panel.h"
#include "str.h"
#include "file.h"

class TFileViewControl;

class TFileViewFactory : public TPanelFactory
{
public:
    TFileViewFactory();
    ~TFileViewFactory();

    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int height);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);

	TFileViewControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
	TFileViewControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);

	virtual TPanelControl *CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
	virtual TPanelControl *CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize);

	virtual TFileViewControl *CreateFileView(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
	virtual TFileViewControl *CreateFileView(TControl *control, int xstart, int ystart, int xsize, int ysize);
		
protected:
    void Init();
    void SetDefault(TFileViewControl *fileview, int xstart, int ystart, int xsize, int ysize);

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    TFont *FFont;
};

class TFileViewControl : public TPanelControl
{
public:
    TFileViewControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TFileViewControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TFileViewControl(TControlThread *dev);
    TFileViewControl(TControl *control);
    ~TFileViewControl();

    virtual void Set(const char *IniName, const char *IniSection);

    void SetFont(int height);
    void SetFont(TFont *font);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);

    void Load(const char *FileName);
    void Load(TString &FileName);
    
protected:
    virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height); 	
    virtual void NotifyResize(); 	

    void FreeTextRows();
    void UpdateTextRows();

private:
    void Init();

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    TFont *FFont;

    int FRows;
    char **FTextData;

};

#endif
