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

class TFormControlEntry
{
public:
    TFormControlEntry(TControl *control, const char *Name);
    ~TFormControlEntry();

    TString FName;
    TControl *FControl;
    TFormControlEntry *FNext;
};

class TFormLabelEntry
{
public:
    TFormLabelEntry(TLabelControl *label, const char *Name);
    ~TFormLabelEntry();

    TString FName;
    TLabelControl *FControl;
    TFormLabelEntry *FNext;
};

class TFormButtonEntry
{
public:
    TFormButtonEntry(TButtonControl *button, const char *Name);
    ~TFormButtonEntry();

    TString FName;
    TButtonControl *FControl;
    TFormButtonEntry *FNext;
};

class TFormFileViewEntry
{
public:
    TFormFileViewEntry(TFileViewControl *fileview, const char *Name);
    ~TFormFileViewEntry();

    TString FName;
    TFileViewControl *FControl;
    TFormFileViewEntry *FNext;
};

class TFormListboxEntry
{
public:
    TFormListboxEntry(TListControl *list, const char *Name);
    ~TFormListboxEntry();

    TString FName;
    TListControl *FControl;
    TFormListboxEntry *FNext;
};

class TFormVerScrollEntry
{
public:
    TFormVerScrollEntry(TVerScrollControl *scroll, const char *Name);
    ~TFormVerScrollEntry();

    TString FName;
    TVerScrollControl *FControl;
    TFormVerScrollEntry *FNext;
};

class TFormHorScrollEntry
{
public:
    TFormHorScrollEntry(THorScrollControl *scroll, const char *Name);
    ~TFormHorScrollEntry();

    TString FName;
    THorScrollControl *FControl;
    TFormHorScrollEntry *FNext;
};

class TFormControl : public TPanelControl
{
public:
    TFormControl(TControlThread *dev);
    TFormControl(TControl *control);
    ~TFormControl();
    
    void LoadControls(const char *IniName);
    
protected:
    virtual void OnCreatePanel(const char *name, TPanelControl *panel);
    virtual void OnCreateLabel(const char *name, TLabelControl *label);
    virtual void OnCreateButton(const char *name, TButtonControl *button);
    virtual void OnCreateFileView(const char *name, TFileViewControl *fileview);
    virtual void OnCreateList(const char *name, TListControl *list);
    virtual void OnCreateVerScroll(const char *name, TVerScrollControl *list);
    virtual void OnCreateHorScroll(const char *name, THorScrollControl *list);

    void Add(TFormControlEntry *entry);
    void Add(TFormLabelEntry *entry);
    void Add(TFormButtonEntry *entry);
    void Add(TFormFileViewEntry *entry);
    void Add(TFormListboxEntry *entry);
    void Add(TFormVerScrollEntry *entry);
	void Add(TFormHorScrollEntry *entry);

    void Remove(TFormControlEntry *entry);
    void Remove(TFormLabelEntry *entry);
    void Remove(TFormButtonEntry *entry);
    void Remove(TFormFileViewEntry *entry);
    void Remove(TFormListboxEntry *entry);
    void Remove(TFormVerScrollEntry *entry);
    void Remove(TFormHorScrollEntry *entry);

    TControl *GetControl(const char *name);
    TLabelControl *GetLabel(const char *name);
    TButtonControl *GetButton(const char *name);
    TFileViewControl *GetFileView(const char *name);
    TListControl *GetList(const char *name);
    TVerScrollControl *GetVerScroll(const char *name);
    THorScrollControl *GetHorScroll(const char *name);

    void LoadLabel(const char *IniName, const char *Name);
    void LoadButton(const char *IniName, const char *Name);
    void LoadFileView(const char *IniName, const char *Name);
    void LoadList(const char *IniName, const char *Name);
    void LoadVerScroll(const char *IniName, const char *Name);
    void LoadHorScroll(const char *IniName, const char *Name);

    void LoadControl(const char *IniName, const char *Name);

    TFormControlEntry *FControlList;
    TFormLabelEntry *FLabelList;
    TFormButtonEntry *FButtonList;
    TFormFileViewEntry *FFileViewList;
    TFormListboxEntry *FListboxList;
    TFormVerScrollEntry *FVerScrollList;
    TFormHorScrollEntry *FHorScrollList;

    TSection FSection;

private:
    void Init();
    
};

#endif
