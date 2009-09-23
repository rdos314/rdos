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
# label.h
# Label control class
#
########################################################################*/

#ifndef _LABELCTL_H
#define _LABELCTL_H

#include "bitdev.h"
#include "panel.h"
#include "str.h"

#define MAX_LABEL_ROWS    256

class TLabelControl;

class TLabelFactory : public TPanelFactory
{
public:
    TLabelFactory();
    TLabelFactory(const char *IniName, const char *IniSection);
    ~TLabelFactory();

    void SetFont(int height);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);

    void AlignTopLeft();
    void AlignTop();
    void AlignTopRight();
    void AlignLeft();
    void AlignCenter();
    void AlignRight();
    void AlignBottomLeft();
    void AlignBottom();
    void AlignBottomRight();

	TLabelControl *Create(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
	TLabelControl *Create(TControl *control, int xstart, int ystart, int xsize, int ysize);

	TLabelControl *Create(TControlThread *dev);
	TLabelControl *Create(TControl *control);

	virtual TPanelControl *CreatePanel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
	virtual TPanelControl *CreatePanel(TControl *control, int xstart, int ystart, int xsize, int ysize);

	virtual TPanelControl *CreatePanel(TControlThread *dev);
	virtual TPanelControl *CreatePanel(TControl *control);

	virtual TLabelControl *CreateLabel(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
	virtual TLabelControl *CreateLabel(TControl *control, int xstart, int ystart, int xsize, int ysize);

	virtual TLabelControl *CreateLabel(TControlThread *dev);
	virtual TLabelControl *CreateLabel(TControl *control);
		
protected:
    void Init();
    virtual void LoadSettings(const char *IniName, const char *IniSection);
    void SetDefault(TLabelControl *label, int xstart, int ystart, int xsize, int ysize);

    int FHorAlign;
    int FVerAlign;

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    TFont *FFont;
};

class TLabelControl : public TPanelControl
{
public:
    TLabelControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TLabelControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TLabelControl(TControlThread *dev, const char *IniName, const char *IniSection);
    TLabelControl(TControl *control, const char *IniName, const char *IniSection);
    ~TLabelControl();

    void SetFont(int height);
    void SetFont(TFont *font);
    void SetSpace(int xspace, int yspace);
    
    void SetDrawColor(int r, int g, int b);

    void SetText(TString &Text);
    void SetText(const char *Text);

    void AlignTopLeft();
    void AlignTop();
    void AlignTopRight();
    void AlignLeft();
    void AlignCenter();
    void AlignRight();
    void AlignBottomLeft();
    void AlignBottom();
    void AlignBottomRight();

    virtual int GetMinHeight();
    
protected:
    TLabelControl(TControlThread *dev);
    TLabelControl(TControl *control);

  	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height); 	

private:
    void Init();
    void LoadSettings(const char *IniName, const char *IniSection);

    int FHorAlign;
    int FVerAlign;

    int FStartX;
    int FStartY;

    int FDrawR;
    int FDrawG;
    int FDrawB;

    TFont *FFont;

    char *FOrgText;
    char *FText;
    char *FTextRow[MAX_LABEL_ROWS];    

};

#endif
