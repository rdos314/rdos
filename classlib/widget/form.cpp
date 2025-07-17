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
# form.cpp
# Form control class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "form.h"

#define FALSE   0
#define TRUE    !FALSE

#define FORM_TYPE_CONTROL       1
#define FORM_TYPE_LABEL         2
#define FORM_TYPE_BUTTON        3
#define FORM_TYPE_FILE_VIEW     4
#define FORM_TYPE_LIST          5
#define FORM_TYPE_VER_SCROLL    6
#define FORM_TYPE_HOR_SCROLL    7
#define FORM_TYPE_IMAGE         8
#define FORM_TYPE_PANEL         9

TSection TFormControl::FSection("Form");
int TFormControl::FUseTouch = RdosHasTouch();
int TFormControl::FUseKeyboard = !RdosHasTouch();

/*##########################################################################
#
#   Name       : ControlChanged
#
#   Purpose....: Control changed callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ControlChanged(TControl *Control)
{
    TFormControl *form = (TFormControl *)Control->Owner;

    form->NotifyChanged(Control);
}

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
TFormControlEntry::TFormControlEntry(TControl *control, const char *name, int type)
  : FName(name)
{
    FControl = control;
    FNext = 0;
    FType = type;
    FStartX = 0;
    FStartY = 0;
    FSizeX = 0;
    FSizeY = 0;
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
    Protect();
    while (FControlList)
        Remove(FControlList);
    Unprotect();
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
    FInnerWidth = 0;
    FInnerHeight = 0;

    ControlType += TString(".FORM");
}

    /*##########################################################################
#
#   Name       : TFormControl::UpdateTouch
#
#   Purpose....: Update touch
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::UpdateTouch()
{
   FUseTouch = RdosHasTouch();
   FUseKeyboard = !RdosHasTouch();
}
    
/*##########################################################################
#
#   Name       : TFormControl::UseTouch
#
#   Purpose....: Force use of touch interface
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::UseTouch()
{
    FUseTouch = TRUE;
}
    
/*##########################################################################
#
#   Name       : TFormControl::IgnoreTouch
#
#   Purpose....: Ignore touch interface
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::IgnoreTouch()
{
    FUseTouch = FALSE;
    FUseKeyboard = TRUE;
}
    
/*##########################################################################
#
#   Name       : TFormControl::UseKeyboard
#
#   Purpose....: Force use of keyboard interface
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::UseKeyboard()
{
    FUseKeyboard = TRUE;
}
    
/*##########################################################################
#
#   Name       : TFormControl::IgnoreKeyboard
#
#   Purpose....: Ignore keyboard interface
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::IgnoreKeyboard()
{
    FUseKeyboard = FALSE;
    FUseTouch = TRUE;
}
    
/*##########################################################################
#
#   Name       : TFormControl::IsFormControl
#
#   Purpose....: Check if control is a form
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFormControl::IsFormControl(TControl *control)
{
    if (strstr(control->ControlType.GetData(), ".FORM"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFormControl::RecalcInner
#
#   Purpose....: Recalculate inner width
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::RecalcInner()
{
    int xstart, ystart;
    int xsize, ysize;

    TFormControlEntry *p;

    FSection.Enter();

    FInnerWidth = 0;
    FInnerHeight = 0;
    
    p = FControlList;

    while (p)
    {
        p->FControl->GetPos(&xstart, &ystart);
        p->FControl->GetSize(&xsize, &ysize);

        if (FInnerWidth < xstart + xsize - 1)
           FInnerWidth = xstart + xsize - 1;

        if (FInnerHeight < ystart + ysize - 1)
            FInnerHeight = ystart + ysize - 1;

                  p = p->FNext;
         }
    FSection.Leave();
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
void TFormControl::Add(const char *name, TControl *control, int type)
{
    TFormControlEntry *entry;
    int xsize, ysize;
    int xstart, ystart;
    
    control->GetPos(&xstart, &ystart);
    control->GetSize(&xsize, &ysize);

    entry = new TFormControlEntry(control, name, type);
    entry->FStartX = xstart;
    entry->FStartY = ystart;
    entry->FSizeX = xsize;
    entry->FSizeY = ysize;

    FSection.Enter();

    if (FInnerWidth < xstart + xsize - 1)
        FInnerWidth = xstart + xsize - 1;

    if (FInnerHeight < ystart + ysize - 1)
        FInnerHeight = ystart + ysize - 1;

    entry->FNext = FControlList;
    FControlList = entry;

    FSection.Leave();
    
    control->Owner = this;
    control->OnChanged = ControlChanged;
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
void TFormControl::Add(const char *name, TControl *control)
{
    Add(name, control, FORM_TYPE_CONTROL);
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

    entry->FControl->OnChanged = 0;

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

    RecalcInner();
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
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_LABEL && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (TLabelControl *)p->FControl;
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
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_BUTTON && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (TButtonControl *)p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetPanel
#
#   Purpose....: Get a panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPanelControl *TFormControl::GetPanel(const char *name)
{
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_PANEL && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (TPanelControl *)p->FControl;
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
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_FILE_VIEW && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (TFileViewControl *)p->FControl;
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
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_LIST && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (TListControl *)p->FControl;
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
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_VER_SCROLL && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (TVerScrollControl *)p->FControl;
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
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_HOR_SCROLL && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (THorScrollControl *)p->FControl;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFormControl::GetImage
#
#   Purpose....: Get an image control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TImageControl *TFormControl::GetImage(const char *name)
{
    TFormControlEntry *p;

    FSection.Enter();

    p = FControlList;

    while (p)
    {
        if (p->FType == FORM_TYPE_IMAGE && p->FName == name)
            break;
        else
            p = p->FNext;
    }

    FSection.Leave();

    if (p)
        return (TImageControl *)p->FControl;
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
#   Name       : TFormControl::OnCreateImage
#
#   Purpose....: Create image notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::OnCreateImage(const char *name, TImageControl *image)
{
}

/*##########################################################################
#
#   Name       : TFormControl::LoadPanel
#
#   Purpose....: Load a panel control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadPanel(TAppIniFile *Ini, const char *Name)
{
    TPanelControl *panel;

    panel = new TPanelControl(this);
    panel->Set(Ini, Name);
    OnCreatePanel(Name, panel); 

    Add(Name, panel, FORM_TYPE_PANEL);
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
void TFormControl::LoadLabel(TAppIniFile *Ini, const char *Name)
{
    TLabelControl *label;

    label = new TLabelControl(this);
    label->Set(Ini, Name);
    OnCreateLabel(Name, label);    

    Add(Name, label, FORM_TYPE_LABEL);
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
void TFormControl::LoadButton(TAppIniFile *Ini, const char *Name)
{
    TButtonControl *button;

    button = new TButtonControl(this);
    button->Set(Ini, Name);
    OnCreateButton(Name, button); 

    Add(Name, button, FORM_TYPE_BUTTON);

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
void TFormControl::LoadFileView(TAppIniFile *Ini, const char *Name)
{
    TFileViewControl *fileview;

    fileview = new TFileViewControl(this);
    fileview->Set(Ini, Name);
    OnCreatePanel(Name, fileview); 
    OnCreateFileView(Name, fileview); 

    Add(Name, fileview, FORM_TYPE_FILE_VIEW);
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
void TFormControl::LoadList(TAppIniFile *Ini, const char *Name)
{
    TListControl *list;

    list = new TListControl(this);
    list->Set(Ini, Name);
    OnCreatePanel(Name, list); 
    OnCreateList(Name, list); 

    Add(Name, list, FORM_TYPE_LIST);
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
void TFormControl::LoadVerScroll(TAppIniFile *Ini, const char *Name)
{
    TVerScrollControl *scroll;

    scroll = new TVerScrollControl(this);
    scroll->Set(Ini, Name);
    OnCreateVerScroll(Name, scroll);

    Add(Name, scroll, FORM_TYPE_VER_SCROLL);
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
void TFormControl::LoadHorScroll(TAppIniFile *Ini, const char *Name)
{
    THorScrollControl *scroll;

    scroll = new THorScrollControl(this);
    scroll->Set(Ini, Name);
    OnCreateHorScroll(Name, scroll); 

    Add(Name, scroll, FORM_TYPE_HOR_SCROLL);
}

/*##########################################################################
#
#   Name       : TFormControl::LoadImage
#
#   Purpose....: Load an image control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::LoadImage(TAppIniFile *Ini, const char *Name)
{
    TImageControl *image;

    image = new TImageControl(this);
    image->Set(Ini, Name);
    OnCreateImage(Name, image); 

    Add(Name, image, FORM_TYPE_IMAGE);
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
void TFormControl::LoadControl(TAppIniFile *Ini, const char *Name)
{
    char str[256];
    int use = TRUE;

    Ini->GotoSection(Name);

    if (Ini->ReadVar("Touch", str, 255))
    {
        if (FUseTouch)
        {
            if (atoi(str) == 0)
                use = FALSE;
        }
        else
        {
            if (atoi(str) == 1)
                use = FALSE;
        }
    }

    if (use)
    {            
        if (Ini->ReadVar("Type", str, 255))
        {
            if (!strcmp(str, "Label"))
                LoadLabel(Ini, Name);

            if (!strcmp(str, "Button"))
                LoadButton(Ini, Name);

            if (!strcmp(str, "FileView"))
                LoadFileView(Ini, Name);

            if (!strcmp(str, "List"))
                LoadList(Ini, Name);

            if (!strcmp(str, "VerScroll"))
                LoadVerScroll(Ini, Name);

            if (!strcmp(str, "HorScroll"))
                LoadHorScroll(Ini, Name);
    
            if (!strcmp(str, "Image"))
                LoadImage(Ini, Name);

            if (!strcmp(str, "Panel"))
                LoadPanel(Ini, Name);
        }
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
void TFormControl::LoadControls(TAppIniFile *Ini)
{
    char varstr[40];
    char str[256];
    int i;
    int done;

    TPanelControl::Set(Ini, "Load");

    i = 1;
    done = FALSE;
    
    while (!done)
    {
        Ini->GotoSection("Load");

        sprintf(varstr, "Control%d", i);
    
        if (Ini->ReadVar(varstr, str, 255))
        {
            LoadControl(Ini, str);
            i++;
        }
        else
            done = TRUE;
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
    TAppIniFile Ini(IniName);
    LoadControls(&Ini);
}

/*##########################################################################
#
#   Name       : TFormControl::NotifyChanged
#
#   Purpose....: Control changed callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFormControl::NotifyChanged(TControl *Control)
{
}
