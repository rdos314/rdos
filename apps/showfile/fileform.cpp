/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2010, Leif Ekblad
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
