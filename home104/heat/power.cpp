/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# power.cpp
# Renewable power class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "serial.h"
#include "vp.h"
#include "table.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPower::TPower
#
#   Purpose....: Power constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPower::TPower(TControlThread *control)
{
    FControl = control;

    Start("Power", 0x2000);
}

/*##########################################################################
#
#   Name       : TPower::~TPower
#
#   Purpose....: Power destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPower::~TPower()
{
}

/*##########################################################################
#
#   Name       : TPower::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPower::DeviceName(char *Name, int Size) const
{
    strcpy(Name, "Power");
}

/*##########################################################################
#
#   Name       : TPower::Execute
#
#   Purpose....: Handler thread
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPower::Execute()
{
    TSerialDevice serial(4, 2400, 'N', 8, 1)
    char str[256];
    int i;
    int ok;
    
    TLabelFactory CommentLabelFactory;
    TLabelFactory ValueLabelFactory;
    TLabelFactory UnitLabelFactory;

    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(20);
    CommentLabelFactory.SetBackTransparent();
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    
    ValueLabelFactory.SetSpace(4, 4);
    ValueLabelFactory.SetFont(20);
    ValueLabelFactory.SetBackColor(100, 100, 100);
    ValueLabelFactory.SetDrawColor(0, 0, 0);
    ValueLabelFactory.AlignRight();

    UnitLabelFactory.SetSpace(4, 4);
    UnitLabelFactory.SetFont(20);
    UnitLabelFactory.SetBackTransparent();
    UnitLabelFactory.SetDrawColor(0, 0, 0);
    UnitLabelFactory.AlignLeft();

    TLabelControl *Label;
    TTableControl *Table;

    Label = new TLabelControl(FControl, 25, 500, 200, 30);
    Label->SetFont(20);
    Label->SetBackTransparent();
    Label->SetDrawColor(0, 0, 0);
    Label->SetText("Energi");
    Label->Show();

    Table = new TTableControl(FControl, 50, 530, 400, 300);
    Table->SetRowSpacing(5);
    Table->SetColSpacing(8);
    Table->SetSpacingTransparent();
    Table->SetBackTransparent();
    Table->AddLabelColumn(&CommentLabelFactory, 220);
    Table->AddLabelColumn(&ValueLabelFactory, 80);
    Table->AddLabelColumn(&UnitLabelFactory, 70);

    Table->AddRow(24, 45);
    Table->AddRow(24, 45);

    Table->SetText(0, 0, "Vind");
    Table->SetText(0, 2, "W");

    Table->SetText(1, 0, "Sol");
    Table->SetText(1, 2, "W");

    serial.Open();

    while (FInstalled)
    {
        if (serial.WaitForChar(10000))
        {
            ok = TRUE;
            for (i = 0; i < 256 && ok; i++)
            {
                str[i] = serial.Read();
                ok = serial.WaitForChar(100);
            }
            str[i] = 0;            
        }
    }
}
