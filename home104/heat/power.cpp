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
#include "power.h"
#include "table.h"

#define FALSE 0
#define TRUE !FALSE

TTableControl *Table;
long double bat_u = 0;
int charger = FALSE;

/*##########################################################################
#
#   Name       : BatteryThread
#
#   Purpose....: Battery thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void BatteryThread(void *Param)
{
    int ival;
    long double fval;
    char str[256];
    int BatISum = 0;
    int BatICount = 0;
    int ChargeISum = 0;
    int ChargeICount = 0;
    int BatUSum = 0;
    int BatUCount = 0;    

    for (;;)
    {
        RdosWaitMilli(100);

        if (RdosReadSerialRaw(1, 2, &ival))
        {
            BatISum += ival;
            BatICount++;

            if (BatICount == 10)
            {
                fval = (long double)BatISum / 1000.0;
                sprintf(str, "%5.2Lf", fval);            
                Table->SetText(3, 5, str);            

                BatISum = 0;
                BatICount = 0;
            }
        }

        if (RdosReadSerialRaw(1, 3, &ival))
        {
            ChargeISum += ival;
            ChargeICount++;

            if (ChargeICount == 10)
            {            
                fval = (long double)ChargeISum / 1000.0;
                sprintf(str, "%5.2Lf", fval);            
                Table->SetText(2, 5, str);            

                ChargeISum = 0;
                ChargeICount = 0;
            }
        }

        if (RdosReadSerialRaw(1, 4, &ival))
        {
            BatUSum += ival;
            BatUCount++;

            if (BatUCount == 10)
            {
                fval = (long double)BatUSum / 1000.0;
                sprintf(str, "%5.1Lf", fval);            
                Table->SetText(3, 3, str);           

                BatUSum = 0;
                BatUCount = 0;

                if (charger)
                {
                    if (bat_u >= 25.0)
                        charger = FALSE;
                }
                else
                {
                    if (bat_u <= 24.5)
                        charger = TRUE;
                }

                if (charger)
                    RdosWriteSerialRaw(1, 3, 0xFF);
                else
                    RdosWriteSerialRaw(1, 3, 0);
            } 
        }
    }
}

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

    RdosCreateThread(BatteryThread, "Battery", 0, 0x4000);
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
#   Name       : TPower::HasPower
#
#   Purpose....: Check for valid power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPower::HasPower()
{
    return FHasPower;
}

/*##########################################################################
#
#   Name       : TPower::GetSolar12Power
#
#   Purpose....: Get current solar12 power value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TPower::GetSolar12Power()
{
    long double val = 0;

    FSection.Enter();

    if (FPower12Count)
        val = FPower12Sum / FPower12Count;

    FPower12Count = 0;
    FPower12Sum = 0;

    FSection.Leave();
    
    return val;
}

/*##########################################################################
#
#   Name       : TPower::GetSolar24Power
#
#   Purpose....: Get current solar24 power value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TPower::GetSolar24Power()
{
    long double val = 0;

    FSection.Enter();

    if (FPower24Count)
        val = FPower24Sum / FPower24Count;

    FPower24Count = 0;
    FPower24Sum = 0;

    FSection.Leave();
    
    return val;
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
    int count;
    TSerialDevice serial(1, 2400, 'N', 8, 1);
    char str[256];
    char ch;
    int i;
    int ok;

    int min, sec;
    int ms, us;
    unsigned long msb, lsb;
    int LastMin;

    long double solar12_power;
    long double solar24_power;
    long double solar12_ref;
    long double solar24_ref;
    long double solar12_u;
    long double solar24_u;
    long double solar12_i;
    long double solar24_i;

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

    Label = new TLabelControl(FControl, 25, 25, 200, 30);
    Label->SetFont(20);
    Label->SetBackTransparent();
    Label->SetDrawColor(0, 0, 0);
    Label->SetText("Energi");
    Label->Show();

    Table = new TTableControl(FControl, 50, 50, 750, 300);
    Table->SetRowSpacing(5);
    Table->SetColSpacing(8);
    Table->SetSpacingTransparent();
    Table->SetBackTransparent();
    Table->AddLabelColumn(&CommentLabelFactory, 100);
    Table->AddLabelColumn(&ValueLabelFactory, 100);
    Table->AddLabelColumn(&UnitLabelFactory, 70);
    Table->AddLabelColumn(&ValueLabelFactory, 100);
    Table->AddLabelColumn(&UnitLabelFactory, 70);
    Table->AddLabelColumn(&ValueLabelFactory, 100);
    Table->AddLabelColumn(&UnitLabelFactory, 70);

    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);

    Table->SetText(0, 0, "Sol 12");
    Table->SetText(0, 2, "W");
    Table->SetText(0, 4, "volt");
    Table->SetText(0, 6, "ampere");

    Table->SetText(1, 0, "Sol 24");
    Table->SetText(1, 2, "W");
    Table->SetText(1, 4, "volt");
    Table->SetText(1, 6, "ampere");

    Table->SetText(2, 0, "Batteri");
    Table->SetText(2, 4, "volt");
    Table->SetText(2, 6, "ampere");

    Table->SetText(3, 0, "Load");
    Table->SetText(3, 4, "volt");
    Table->SetText(3, 6, "ampere");

    serial.Open();
    serial.EnableAutoRts();

    FHasPower = FALSE;

    while (FInstalled)
    {        
        if (serial.WaitForChar(10000))
        {
            ok = TRUE;
            for (i = 0; i < 256 && ok; i++)
            {
                ch = serial.Read();
                str[i] = ch;
                if (ch == 0xd || ch == 0xa)
                    break;
                else                
                    ok = serial.WaitForChar(100);
            }
            str[i] = 0;

            if (i > 47)
            {
                count = sscanf(str, "%Lf %Lf %Lf %Lf %Lf %Lf %Lf %Lf %Lf", &solar12_power, &solar24_power, &solar12_ref, &solar24_ref, &solar12_u, &solar24_u, &bat_u, &solar12_i, &solar24_i);
                if (count == 9)
                {
                    FSection.Enter();
                    
                    FPower12Count++;
                    FPower12Sum += solar12_power;
                    
                    FPower24Count++;
                    FPower24Sum += solar24_power;

                    FHasPower = TRUE;

                    FSection.Leave();
                    
                
                    sprintf(str, "%6.3Lf", solar12_power);
                    Table->SetText(0, 1, str);

                    sprintf(str, "%5.1Lf", solar12_u);
                    Table->SetText(0, 3, str);

                    sprintf(str, "%5.2Lf", solar12_i);
                    Table->SetText(0, 5, str);

                    sprintf(str, "%6.3Lf", solar24_power);
                    Table->SetText(1, 1, str);

                    sprintf(str, "%5.1Lf", solar24_u);
                    Table->SetText(1, 3, str);

                    sprintf(str, "%5.1Lf", solar24_i);
                    Table->SetText(1, 5, str);

                    sprintf(str, "%5.1Lf", bat_u);
                    Table->SetText(2, 3, str);
                }
            }         
        }
    }
}
