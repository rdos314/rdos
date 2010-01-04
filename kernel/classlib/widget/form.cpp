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
# form.cpp
# Form control class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "form.h"
#include "ini.h"

#define FALSE   0
#define TRUE    !FALSE
    
/*##########################################################################
#
#   Name       : TFormControlEntry::TFormControlEntry
#
#   Purpose....: Form control entry constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormControlEntry::TFormControlEntry(TControl *control, const char *Name)
  : FName(Name)
{
    FControl = control;
    FNext = 0;
}
    
/*##########################################################################
#
#   Name       : TFormControlEntry::~TFormControlEntry
#
#   Purpose....: Form control entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormControlEntry::~TFormControlEntry()
{
    if (FControl)
        delete FControl;
}
    
/*##########################################################################
#
#   Name       : TFormLabelEntry::TFormLabelEntry
#
#   Purpose....: Form label control entry constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormLabelEntry::TFormLabelEntry(TLabelControl *control, const char *Name)
  : FName(Name)
{
    FControl = control;
    FNext = 0;
}
    
/*##########################################################################
#
#   Name       : TFormLabelEntry::~TFormLabelEntry
#
#   Purpose....: Form label control entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormLabelEntry::~TFormLabelEntry()
{
    if (FControl)
        delete FControl;
}
    
/*##########################################################################
#
#   Name       : TFormButtonEntry::TFormButtonEntry
#
#   Purpose....: Form button control entry constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormButtonEntry::TFormButtonEntry(TButtonControl *control, const char *Name)
  : FName(Name)
{
    FControl = control;
    FNext = 0;
}
    
/*##########################################################################
#
#   Name       : TFormButtonEntry::~TFormButtonEntry
#
#   Purpose....: Form button control entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormButtonEntry::~TFormButtonEntry()
{
    if (FControl)
        delete FControl;
}
    
/*##########################################################################
#
#   Name       : TFormFileViewEntry::TFormFileViewEntry
#
#   Purpose....: Form file-view control entry constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormFileViewEntry::TFormFileViewEntry(TFileViewControl *control, const char *Name)
  : FName(Name)
{
    FControl = control;
    FNext = 0;
}
    
/*##########################################################################
#
#   Name       : TFormFileViewEntry::~TFormFileViewEntry
#
#   Purpose....: Form file-view entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormFileViewEntry::~TFormFileViewEntry()
{
    if (FControl)
        delete FControl;
}
    
/*##########################################################################
#
#   Name       : TFormListboxEntry::TFormListboxEntry
#
#   Purpose....: Form listbox control entry constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormListboxEntry::TFormListboxEntry(TListControl *control, const char *Name)
  : FName(Name)
{
    FControl = control;
    FNext = 0;
}
    
/*##########################################################################
#
#   Name       : TFormListboxEntry::~TFormListboxEntry
#
#   Purpose....: Form listbox control entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormListboxEntry::~TFormListboxEntry()
{
    if (FControl)
        delete FControl;
}
    
/*##########################################################################
#
#   Name       : TFormVerScrollEntry::TFormVerScrollEntry
#
#   Purpose....: Form vertical scroll control entry constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormVerScrollEntry::TFormVerScrollEntry(TVerScrollControl *control, const char *Name)
  : FName(Name)
{
    FControl = control;
    FNext = 0;
}
    
/*##########################################################################
#
#   Name       : TFormVerScrollEntry::~TFormVerScrollEntry
#
#   Purpose....: Form vertical scroll control entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormVerScrollEntry::~TFormVerScrollEntry()
{
    if (FControl)
        delete FControl;
}
    
/*##########################################################################
#
#   Name       : TFormHorScrollEntry::TFormHorScrollEntry
#
#   Purpose....: Form horisontal scroll control entry constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormHorScrollEntry::TFormHorScrollEntry(THorScrollControl *control, const char *Name)
  : FName(Name)
{
    FControl = control;
    FNext = 0;
}
    
/*##########################################################################
#
#   Name       : TFormHorScrollEntry::~TFormHorScrollEntry
#
#   Purpose....: Form horisontal scroll control entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormHorScrollEntry::~TFormHorScrollEntry()
{
    if (FControl)
        delete FControl;
}
    
/*##########################################################################
#
#   Name       : TFormControl::TFormControl
#
#   Purpose....: Form control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormControl::TFormControl(TControlThread *dev)
 : TPanelControl(dev)
{
    Init();
}

/*##########################################################################
#
#   Name       : TFormControl::TFormControl
#
#   Purpose....: Form control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormControl::TFormControl(TControl *control)
 : TPanelControl(control)
{
    Init();
}

/*##########################################################################
#
#   Name       : TFormControl::~TFormControl
#
#   Purpose....: Form control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFormControl::~TFormControl()
{
    while (FControlList)
        Remove(FControlList);
        
    while (FLabelList)
        Remove(FLabelList);
        
    while (FButtonList)
        Remove(FButtonList);
        
    while (FFileViewList)
        Remove(FFileViewList);
        
    while (FListboxList)
        Remove(FListboxList);

    while (FVerScrollList)
        Remove(FVerScrollList);

    while (FHorScrollList)
        Remove(FHorScrollList);
}

/*##########################################################################
#
#   Name       : TFormControl::Init
#
#   Purpose....: Init control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Init()
{
    FControlList = 0;
    FLabelList = 0;
    FButtonList = 0;
    FFileViewList = 0;
    FListboxList = 0;
    FVerScrollList = 0;
    FHorScrollList = 0;
}

/*##########################################################################
#
#   Name       : TFormControl::Add
#
#   Purpose....: Add control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Add(TFormControlEntry *entry)
{
    FSection.Enter();

    entry->FNext = FControlList;
    FControlList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Add
#
#   Purpose....: Add label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Add(TFormLabelEntry *entry)
{
    FSection.Enter();

    entry->FNext = FLabelList;
    FLabelList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Add
#
#   Purpose....: Add button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Add(TFormButtonEntry *entry)
{
    FSection.Enter();

    entry->FNext = FButtonList;
    FButtonList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Add
#
#   Purpose....: Add file-view control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Add(TFormFileViewEntry *entry)
{
    FSection.Enter();

    entry->FNext = FFileViewList;
    FFileViewList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Add
#
#   Purpose....: Add list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Add(TFormListboxEntry *entry)
{
    FSection.Enter();

    entry->FNext = FListboxList;
    FListboxList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Add
#
#   Purpose....: Add vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Add(TFormVerScrollEntry *entry)
{
    FSection.Enter();

    entry->FNext = FVerScrollList;
    FVerScrollList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Add
#
#   Purpose....: Add horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Add(TFormHorScrollEntry *entry)
{
    FSection.Enter();

    entry->FNext = FHorScrollList;
    FHorScrollList = entry;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Remove
#
#   Purpose....: Remove control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Remove(TFormControlEntry *entry)
{
    TFormControlEntry *p;

    FSection.Enter();

    if (entry == FControlList)
    {
        FControlList = entry->FNext;
        delete entry;
    }
    else
    {
        p = FControlList;

        while (p)
        {
            if (p->FNext == entry)
            {
                p->FNext = entry->FNext;
                delete entry;
                break;
            }
            else
                p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Remove
#
#   Purpose....: Remove label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Remove(TFormLabelEntry *entry)
{
    TFormLabelEntry *p;

    FSection.Enter();

    if (entry == FLabelList)
    {
        FLabelList = entry->FNext;
        delete entry;
    }
    else
    {
        p = FLabelList;

        while (p)
        {
            if (p->FNext == entry)
            {
                p->FNext = entry->FNext;
                delete entry;
                break;
            }
            else
                p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Remove
#
#   Purpose....: Remove button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Remove(TFormButtonEntry *entry)
{
    TFormButtonEntry *p;

    FSection.Enter();

    if (entry == FButtonList)
    {
        FButtonList = entry->FNext;
        delete entry;
    }
    else
    {
        p = FButtonList;

        while (p)
        {
            if (p->FNext == entry)
            {
                p->FNext = entry->FNext;
                delete entry;
                break;
            }
            else
                p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Remove
#
#   Purpose....: Remove file view control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Remove(TFormFileViewEntry *entry)
{
    TFormFileViewEntry *p;

    FSection.Enter();

    if (entry == FFileViewList)
    {
        FFileViewList = entry->FNext;
        delete entry;
    }
    else
    {
        p = FFileViewList;

        while (p)
        {
            if (p->FNext == entry)
            {
                p->FNext = entry->FNext;
                delete entry;
                break;
            }
            else
                p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Remove
#
#   Purpose....: Remove list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Remove(TFormListboxEntry *entry)
{
    TFormListboxEntry *p;

    FSection.Enter();

    if (entry == FListboxList)
    {
        FListboxList = entry->FNext;
        delete entry;
    }
    else
    {
        p = FListboxList;

        while (p)
        {
            if (p->FNext == entry)
            {
                p->FNext = entry->FNext;
                delete entry;
                break;
            }
            else
                p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Remove
#
#   Purpose....: Remove vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Remove(TFormVerScrollEntry *entry)
{
    TFormVerScrollEntry *p;

    FSection.Enter();

    if (entry == FVerScrollList)
    {
        FVerScrollList = entry->FNext;
        delete entry;
    }
    else
    {
        p = FVerScrollList;

        while (p)
        {
            if (p->FNext == entry)
            {
                p->FNext = entry->FNext;
                delete entry;
                break;
            }
            else
                p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::Remove
#
#   Purpose....: Remove horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::Remove(TFormHorScrollEntry *entry)
{
    TFormHorScrollEntry *p;

    FSection.Enter();

    if (entry == FHorScrollList)
    {
        FHorScrollList = entry->FNext;
        delete entry;
    }
    else
    {
        p = FHorScrollList;

        while (p)
        {
            if (p->FNext == entry)
            {
                p->FNext = entry->FNext;
                delete entry;
                break;
            }
            else
                p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TFormControl::GetControl
#
#   Purpose....: Get any kind of control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TControl *TFormControl::GetControl(const char *name)
{
    TFormControlEntry *p;
    TControl *control;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return p->FControl;
    else
    {
        control = GetLabel(name);
        if (control)
            return control;

        control = GetButton(name);
        if (control)
            return control;

        control = GetFileView(name);
        if (control)
            return control;

        control = GetList(name);
        if (control)
            return control;

        control = GetVerScroll(name);
        if (control)
            return control;

        control = GetHorScroll(name);
        if (control)
            return control;

    }
    return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetLabel
#
#   Purpose....: Get a label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLabelControl *TFormControl::GetLabel(const char *name)
{
    TFormLabelEntry *p;

    FSection.Enter();

    p = FLabelList;

    while (p)
    {
        if (p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetButton
#
#   Purpose....: Get a button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TButtonControl *TFormControl::GetButton(const char *name)
{
    TFormButtonEntry *p;

    FSection.Enter();

    p = FButtonList;

    while (p)
    {
        if (p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetFileView
#
#   Purpose....: Get a file-view control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileViewControl *TFormControl::GetFileView(const char *name)
{
    TFormFileViewEntry *p;

    FSection.Enter();

    p = FFileViewList;

    while (p)
    {
        if (p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetList
#
#   Purpose....: Get a list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListControl *TFormControl::GetList(const char *name)
{
    TFormListboxEntry *p;

    FSection.Enter();

    p = FListboxList;

    while (p)
    {
        if (p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetVerScroll
#
#   Purpose....: Get a vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVerScrollControl *TFormControl::GetVerScroll(const char *name)
{
    TFormVerScrollEntry *p;

    FSection.Enter();

    p = FVerScrollList;

    while (p)
    {
        if (p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetHorScroll
#
#   Purpose....: Get a horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THorScrollControl *TFormControl::GetHorScroll(const char *name)
{
    TFormHorScrollEntry *p;

    FSection.Enter();

    p = FHorScrollList;

    while (p)
    {
        if (p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::OnCreatePanel
#
#   Purpose....: Create panel notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreatePanel(const char *name, TPanelControl *label)
{
}

/*##########################################################################
#
#   Name       : TFormControl::OnCreateLabel
#
#   Purpose....: Create label notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreateLabel(const char *name, TLabelControl *label)
{
}

/*##########################################################################
#
#   Name       : TFormControl::OnCreateButton
#
#   Purpose....: Create button notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreateButton(const char *name, TButtonControl *button)
{
}

/*##########################################################################
#
#   Name       : TFormControl::OnCreateFileView
#
#   Purpose....: Create file-view notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreateFileView(const char *name, TFileViewControl *fileview)
{
}

/*##########################################################################
#
#   Name       : TFormControl::OnCreateList
#
#   Purpose....: Create listbox notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreateList(const char *name, TListControl *list)
{
}

/*##########################################################################
#
#   Name       : TFormControl::OnCreateVerScroll
#
#   Purpose....: Create vertical scroll notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreateVerScroll(const char *name, TVerScrollControl *scroll)
{
}

/*##########################################################################
#
#   Name       : TFormControl::OnCreateHorScroll
#
#   Purpose....: Create horisontal scroll notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreateHorScroll(const char *name, THorScrollControl *scroll)
{
}

/*##########################################################################
#
#   Name       : TFormControl::LoadLabel
#
#   Purpose....: Load a label control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadLabel(const char *IniName, const char *Name)
{
    TLabelControl *label;
    TFormLabelEntry *entry;

    label = new TLabelControl(this);
    label->Set(IniName, Name);

    entry = new TFormLabelEntry(label, Name);
    Add(entry);

    OnCreateLabel(Name, label);    
}

/*##########################################################################
#
#   Name       : TFormControl::LoadButton
#
#   Purpose....: Load a button control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadButton(const char *IniName, const char *Name)
{
    TButtonControl *button;
    TFormButtonEntry *entry;

    button = new TButtonControl(this);
    button->Set(IniName, Name);

    entry = new TFormButtonEntry(button, Name);
    Add(entry);

    OnCreateButton(Name, button); 
}

/*##########################################################################
#
#   Name       : TFormControl::LoadFileView
#
#   Purpose....: Load a file-view control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadFileView(const char *IniName, const char *Name)
{
    TFileViewControl *fileview;
    TFormFileViewEntry *entry;

    fileview = new TFileViewControl(this);
    fileview->Set(IniName, Name);

    entry = new TFormFileViewEntry(fileview, Name);
    Add(entry);

    OnCreatePanel(Name, fileview); 
    OnCreateFileView(Name, fileview); 
}

/*##########################################################################
#
#   Name       : TFormControl::LoadList
#
#   Purpose....: Load a list control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadList(const char *IniName, const char *Name)
{
    TListControl *list;
    TFormListboxEntry *entry;

	list = new TListControl(this);
    list->Set(IniName, Name);

    entry = new TFormListboxEntry(list, Name);
    Add(entry);

    OnCreatePanel(Name, list); 
    OnCreateList(Name, list); 
}

/*##########################################################################
#
#   Name       : TFormControl::LoadVerScroll
#
#   Purpose....: Load a vertical scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadVerScroll(const char *IniName, const char *Name)
{
    TVerScrollControl *scroll;
    TFormVerScrollEntry *entry;

    scroll = new TVerScrollControl(this);
    scroll->Set(IniName, Name);

	entry = new TFormVerScrollEntry(scroll, Name);
	Add(entry);

	OnCreateVerScroll(Name, scroll);
}

/*##########################################################################
#
#   Name       : TFormControl::LoadHorScroll
#
#   Purpose....: Load a horisontal scroll control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadHorScroll(const char *IniName, const char *Name)
{
	THorScrollControl *scroll;
	TFormHorScrollEntry *entry;

	scroll = new THorScrollControl(this);
	scroll->Set(IniName, Name);

	entry = new TFormHorScrollEntry(scroll, Name);
	Add(entry);

    OnCreateHorScroll(Name, scroll); 
}

/*##########################################################################
#
#   Name       : TFormControl::LoadControl
#
#   Purpose....: Load a control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadControl(const char *IniName, const char *Name)
{
    TIniFile Ini(IniName);
    char str[256];

    Ini.GotoSection(Name);
    
    if (Ini.ReadVar("Type", str, 255))
    {
        if (!strcmp(str, "Label"))
            LoadLabel(IniName, Name);

        if (!strcmp(str, "Button"))
            LoadButton(IniName, Name);

        if (!strcmp(str, "FileView"))
            LoadFileView(IniName, Name);

        if (!strcmp(str, "List"))
            LoadList(IniName, Name);

        if (!strcmp(str, "VerScroll"))
            LoadVerScroll(IniName, Name);

        if (!strcmp(str, "HorScroll"))
            LoadHorScroll(IniName, Name);
    }
}

/*##########################################################################
#
#   Name       : TFormControl::LoadControls
#
#   Purpose....: Load controls
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadControls(const char *IniName)
{
    TIniFile Ini(IniName);
    char varstr[40];
    char str[256];
    int i;
    int done;

    TPanelControl::Set(IniName, "Load");

    Ini.GotoSection("Load");

    i = 1;
    done = FALSE;
    
    while (!done)
    {
        sprintf(varstr, "Control%d", i);
    
        if (Ini.ReadVar(varstr, str, 255))
        {
            LoadControl(IniName, str);
            i++;
        }
        else
            done = TRUE;
    }    
}
