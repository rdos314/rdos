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
#include "appini.h"

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
    virtual ~TFormControl();

    static void UpdateTouch();

    static void UseTouch();
    static void IgnoreTouch();
    static void UseKeyboard();
    static void IgnoreKeyboard();

    static int IsFormControl(TControl *control);
    
    void LoadControls(TAppIniFile *Ini);
    void LoadControls(const char *IniName);
    void Add(const char *name, TControl *control);

    virtual void NotifyChanged(TControl *control);
    
protected:
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
    TPanelControl *GetPanel(const char *name);
    TLabelControl *GetLabel(const char *name);
    TButtonControl *GetButton(const char *name);
    TFileViewControl *GetFileView(const char *name);
    TListControl *GetList(const char *name);
    TVerScrollControl *GetVerScroll(const char *name);
    THorScrollControl *GetHorScroll(const char *name);
    TImageControl *GetImage(const char *name);

    void LoadPanel(TAppIniFile *Ini, const char *Name);
    void LoadLabel(TAppIniFile *Ini, const char *Name);
    void LoadButton(TAppIniFile *Ini, const char *Name);
    void LoadFileView(TAppIniFile *Ini, const char *Name);
    void LoadList(TAppIniFile *Ini, const char *Name);
    void LoadVerScroll(TAppIniFile *Ini, const char *Name);
    void LoadHorScroll(TAppIniFile *Ini, const char *Name);
    void LoadImage(TAppIniFile *Ini, const char *Name);

    void LoadControl(TAppIniFile *Ini, const char *Name);

    TFormControlEntry *FControlList;

    static TSection FSection;
    static int FUseTouch;
    static int FUseKeyboard;

    int FInnerWidth;
    int FInnerHeight;

private:
    void Init();
    
};

#endif
