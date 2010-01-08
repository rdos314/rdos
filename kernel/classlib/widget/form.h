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
# form.h
# Form control class
#
########################################################################*/

#ifndef _FORM_CTL_H
#define _FORM_CTL_H

#include "panel.h"
#include "label.h"
#include "button.h"
#include "fileview.h"
#include "listbox.h"
#include "scroll.h"
#include "image.h"

class TFormControlEntry
{
public:
    TFormControlEntry(TControl *control, const char *name, int type);
    ~TFormControlEntry();

    TString FName;
    TControl *FControl;
    TFormControlEntry *FNext;
    
    int FType;
    int FStartX;
    int FStartY;
    int FSizeX;
    int FSizeY;
};

class TFormControl : public TPanelControl
{
public:
    TFormControl(TControlThread *dev);
    TFormControl(TControl *control);
    
    void LoadControls(const char *IniName);
    void Add(const char *name, TControl *control);

    virtual void NotifyChanged(TControl *control);
    
protected:
    virtual ~TFormControl();

    virtual void OnCreatePanel(const char *name, TPanelControl *panel);
    virtual void OnCreateLabel(const char *name, TLabelControl *label);
    virtual void OnCreateButton(const char *name, TButtonControl *button);
    virtual void OnCreateFileView(const char *name, TFileViewControl *fileview);
    virtual void OnCreateList(const char *name, TListControl *list);
    virtual void OnCreateVerScroll(const char *name, TVerScrollControl *scroll);
    virtual void OnCreateHorScroll(const char *name, THorScrollControl *scroll);
    virtual void OnCreateImage(const char *name, TImageControl *image);

    void RecalcInner();
    void Add(const char *name, TControl *control, int type);
    void Remove(TFormControlEntry *entry);

    TControl *GetControl(const char *name);
    TLabelControl *GetLabel(const char *name);
    TButtonControl *GetButton(const char *name);
    TFileViewControl *GetFileView(const char *name);
    TListControl *GetList(const char *name);
    TVerScrollControl *GetVerScroll(const char *name);
    THorScrollControl *GetHorScroll(const char *name);
    TImageControl *GetImage(const char *name);

    void LoadLabel(const char *IniName, const char *Name);
    void LoadButton(const char *IniName, const char *Name);
    void LoadFileView(const char *IniName, const char *Name);
    void LoadList(const char *IniName, const char *Name);
    void LoadVerScroll(const char *IniName, const char *Name);
    void LoadHorScroll(const char *IniName, const char *Name);
    void LoadImage(const char *IniName, const char *Name);

    void LoadControl(const char *IniName, const char *Name);

    TFormControlEntry *FControlList;

    static TSection FSection;

    int FInnerWidth;
    int FInnerHeight;

private:
    void Init();
    
};

#endif
