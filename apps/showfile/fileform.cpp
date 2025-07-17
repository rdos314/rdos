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
# fileform.cpp
# File form control class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "fileform.h"

#define FALSE   0
#define TRUE    !FALSE
    
/*##########################################################################
#
#   Name       : TFileFormControl::TFileFormControl
#
#   Purpose....: Form control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileFormControl::TFileFormControl(TControlThread *dev)
 : TFormControl(dev)
{
}

/*##########################################################################
#
#   Name       : TFileFormControl::TFileFormControl
#
#   Purpose....: Form control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileFormControl::TFileFormControl(TControl *control)
 : TFormControl(control)
{
}

/*##########################################################################
#
#   Name       : TFileFormControl::~TFileFormControl
#
#   Purpose....: Form control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileFormControl::~TFileFormControl()
{
}

/*##########################################################################
#
#   Name       : TFileFormControl::OnCreatePanel
#
#   Purpose....: Create panel notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileFormControl::OnCreatePanel(const char *name, TPanelControl *panel)
{
    panel->DefineScroll("style.ini", "Scroll");
}

/*##########################################################################
#
#   Name       : TFileFormControl::OnCreateLabel
#
#   Purpose....: Create label notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileFormControl::OnCreateLabel(const char *name, TLabelControl *label)
{
    label->Set("style.ini", "Form");
    label->Set("style.ini", "Label");
}

/*##########################################################################
#
#   Name       : TFileFormControl::OnCreateButton
#
#   Purpose....: Create button notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileFormControl::OnCreateButton(const char *name, TButtonControl *button)
{
	 button->Set("style.ini", "Form");
    button->Set("style.ini", "Button");
}

/*##########################################################################
#
#   Name       : TFileFormControl::OnCreateFileView
#
#   Purpose....: Create file-view notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileFormControl::OnCreateFileView(const char *name, TFileViewControl *fileview)
{
	 fileview->Set("style.ini", "Control");
	 fileview->Set("style.ini", "Button");
	 fileview->Set("style.ini", "FileView");

	 FFileView = fileview;
}

/*##########################################################################
#
#   Name       : TFileFormControl::OnKeyPressed
#
#   Purpose....: Handle key pressed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFileFormControl::OnKeyPressed(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	 if (VirtualKey == VK_ESCAPE)
		  FSignal.Signal();

	 return TFormControl::OnKeyPressed(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TFileFormControl::OnKeyReleased
#
#   Purpose....: Handle key released
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFileFormControl::OnKeyReleased(int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    return TFormControl::OnKeyReleased(ExtKey, KeyState, VirtualKey, ScanCode);
}

/*##########################################################################
#
#   Name       : TFileFormControl::Run
#
#   Purpose....: Run form
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFileFormControl::Run(const char *FileName)
{
	 Set("style.ini", "Form");
	 LoadControls("showfile.ini");

	if (FFileView)
	    FFileView->Load(FileName);
        
    FSignal.WaitForever();
    RdosWaitMilli(25);
}
