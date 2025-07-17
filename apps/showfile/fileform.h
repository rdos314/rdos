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
# fileform.h
# File form control class
#
########################################################################*/

#ifndef _FILEFORM_CTL_H
#define _FILEFORM_CTL_H

#include "form.h"
#include "sigdev.h"

class TFileFormControl : public TFormControl
{
public:
    TFileFormControl(TControlThread *dev);
    TFileFormControl(TControl *control);
    ~TFileFormControl();

    void Run(const char *FileName);
    
protected:
    virtual void OnCreatePanel(const char *name, TPanelControl *panel);
    virtual void OnCreateLabel(const char *name, TLabelControl *label);
    virtual void OnCreateButton(const char *name, TButtonControl *button);
    virtual void OnCreateFileView(const char *name, TFileViewControl *fileview);

	virtual int OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode);
	virtual int OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode);

    TFileViewControl *FFileView;
	TSignalDevice FSignal;
};

#endif
