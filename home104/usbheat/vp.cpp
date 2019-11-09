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
# vp.h
# Heat pump class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "vp.h"
#include "lowset.h"
#include "midset.h"
#include "highset.h"
#include "table.h"

#define FALSE 0
#define TRUE !FALSE

#define VOLUME_TANK 500
#define VOLUME_HEAT 100

#define OFF_TIMEOUT   5 * 60

void LockGUI();
void UnlockGUI();

const int HistoryArr[] = {601, 541, 481, 421, 361, 301, 241, 181, 121, 91, 61, 0};

#define ROOT_DIR "e:/data/vp"
#define CSV_DAY_HEADER "time;temp;tank;circ;turb;on\r\n"

/*##########################################################################
#
#   Name       : TVp::TVp
#
#   Purpose....: VP constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVp::TVp(TControlThread *control)
  : FLog("TVp")
{
    int i;
    
    FControl = control;

    FTankTemp = 200;
    FHeatTemp = 200;

    FValidTank = FALSE;
    FValidHeat = FALSE;
    FValidPTank = FALSE;
    FValidPHeat = FALSE;
    FValidAmbient = FALSE;
    FHasLowTemp = FALSE;
    FIncCount = 0;
    FHasCirc = FALSE;
    FHistoryCount = 0;
    FMaxTank = 450;
    FOffCounter = OFF_TIMEOUT;

    FDayFile = 0;

    for (i = 0; i < 20; i++)
        ValidHeatArr[i] = FALSE;

    Start("Vp", 0x2000);
}

/*##########################################################################
#
#   Name       : TVp::~TVp
#
#   Purpose....: Circulation pump destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVp::~TVp()
{
}

/*##########################################################################
#
#   Name       : TVp::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::DeviceName(char *Name, int Size) const
{
        strcpy(Name, "VP");
}

/*##########################################################################
#
#   Name       : TVp::HasValidTankTemp
#
#   Purpose....: Check for valid tank temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidTankTemp()
{
    return FValidTank;
}

/*##########################################################################
#
#   Name       : TVp::HasValidHeatTemp
#
#   Purpose....: Check for valid heat temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidHeatTemp()
{
        return FValidHeat;
}

/*##########################################################################
#
#   Name       : TVp::GetTankTemp
#
#   Purpose....: Get tank temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::GetTankTemp()
{
    return FTankTemp;
}

/*##########################################################################
#
#   Name       : TVp::GetHeatTemp
#
#   Purpose....: Get heating system temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::GetHeatTemp()
{
        return FHeatTemp;
}

/*##########################################################################
#
#   Name       : TVp::HasValidTankP
#
#   Purpose....: Check for valid tank effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidTankP()
{
        return FValidPTank;
}

/*##########################################################################
#
#   Name       : TVp::GetTankP
#
#   Purpose....: Get current tank effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TVp::GetTankP()
{
        return PTank;
}

/*##########################################################################
#
#   Name       : TVp::HasValidHeatP
#
#   Purpose....: Check for valid heat effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVp::HasValidHeatP()
{
        return FValidPHeat;
}

/*##########################################################################
#
#   Name       : TVp::GetHeatP
#
#   Purpose....: Get current heat effect
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TVp::GetHeatP()
{
        return PHeat;
}

/*##########################################################################
#
#   Name       : TVp::SetTempError
#
#   Purpose....: Set current temp error
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetTempError(int diff)
{
    FSection.Enter();
    
    TempCount++;
        TempSum += diff;

    FSection.Leave();    
}

/*##########################################################################
#
#   Name       : TVp::SetPower
#
#   Purpose....: Set power
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetPower(long double val)
{
    FPower = val;
}

/*##########################################################################
#
#   Name       : TVp::SetAmbientDiff
#
#   Purpose....: Set ambient temp diff
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetAmbient(int ref, int ambient)
{
    long double fact;
    long double ambdiff;
    long double tankdiff;

    if (FValidTank)
    {

        FSection.Enter();

        FRef = ref;
        FAmbient = ambient;

        ambdiff = FRef - FAmbient;
        tankdiff = FTankTemp - FRef;

        fact = 1.5 * ambdiff / (ambdiff + 2.0 * tankdiff);

        AmbientSum += fact;
        AmbientCount++;
    
        FValidAmbient = TRUE;

        FMaxTank = 200;

        if (ambient < 150)
        {
            if (FPower >= 2000.0)
                FMaxTank = 480 - ambient;
            else
            {
                if (FPower >= 1000.0)
                    FMaxTank = 440 - ambient;
                else
                    FMaxTank = 400 - ambient;
            }

            if (FMaxTank > 410)
                FMaxTank = 410;
        }
        else
            FMaxTank = 200;

        if (FTankTemp > FMaxTank)
        {
            FLowTemp = FTankTemp - 30;
            FHasLowTemp = TRUE;
        }
           
        FSection.Leave();    
    }
}

/*##########################################################################
#
#   Name       : TVp::SetMaxMotor
#
#   Purpose....: Set current max motor
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetMaxMotor(int motor)
{
    FSection.Enter();
    
    FMotorCount++;
    FMotorSum += motor;

    FSection.Leave();    
}

/*##########################################################################
#
#   Name       : TVp::WriteCircValve
#
#   Purpose....: Write Circ valve
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::WriteCircValve(long double value)
{
    int temp;

    temp = (int)(value / 10.0 * (long double)0x7FFFFFFF);
    if (temp < 0)
        temp = 0x7FFFFFFF;

    RdosWriteSerialVal(1, 0, temp);
}

/*##########################################################################
#
#   Name       : TVp::UpdateCirc
#
#   Purpose....: Update circ
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::UpdateCirc(int diostat)
{
    int on;

    if ((diostat & 0x10) == 0)
        on = FALSE;
    else
        on = TRUE;

    if (FTankTemp > 270)
    {                
        if (FCirc == 0)
        {
            if (on)
            {
                FLog.Log(0, "UpdateCirc", "Circ off");
                RdosToggleSerialLine(1, 4);

                if (RdosReadSerialLines(1, &diostat))
                    if ((diostat & 0x10) == 0)
                        on = FALSE;
            }
        }

        if (FCirc > 25)
        {
            if (!on)
            {
                FLog.Log(0, "UpdateCirc", "Circ on");
                RdosToggleSerialLine(1, 4);

                if (RdosReadSerialLines(1, &diostat))
                    if ((diostat & 0x10) != 0)
                        on = TRUE;
            }                    
        }
    }

    if (on)
        WriteCircValve((long double)FCirc);
    else
        WriteCircValve(0.0);
}

/*##########################################################################
#
#   Name       : TVp::UpdateVp
#
#   Purpose....: Update VP on/off state
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::UpdateVp(int diff)
{
    int diostat;
    int on = FVpOn;

    FSection.Enter();

    if (on)
    {
        if (FTankTemp > FMaxTank)
        {
            if (FPrevOn)
                FLog.Log(0, "UpdateVp", "Temp off");
            on = FALSE;
        }
        else
        {
            on = FPrevOn;
            
            if (diff > 0)
            {
                FOffCounter = OFF_TIMEOUT;
                
                if (FIncCount)
                {
                    FLowTemp = FTankTemp - 30;
                    FHasLowTemp = TRUE;
                }

                FIncCount++;
            }
            else
            {
                if (FOffCounter)
                    FOffCounter--;
                    
                FIncCount = 0;
            
                if (!FHasLowTemp)
                {
                    FLowTemp = FTankTemp - 5;
                    FHasLowTemp = TRUE;
                }

                if (FOffCounter == 0)
                {
                    if (FTankTemp <= FLowTemp + 5)
                    {
                        if (!on)
                        {
                            FLog.Log(0, "UpdateVp", "Limit on");
                            FOffCounter = OFF_TIMEOUT;
                        }
                        on = TRUE;
                    }
                }
            }

        }
    }

    FPrevOn = on;
    
    if (RdosReadSerialLines(1, &diostat))
    {                
        if (on)
        {               
            if ((diostat & 0x40) == 0)
                RdosToggleSerialLine(1, 6);   // heat

            if ((diostat & 0x20) == 0)
                RdosToggleSerialLine(1, 5);   // cold
        }
        else
        {
            if ((diostat & 0x20) != 0)
                RdosToggleSerialLine(1, 5);   // cold

            if ((diostat & 0x40) != 0)
                RdosToggleSerialLine(1, 6);   // heat
                                               
        }
    }

    UpdateCirc(diostat);


    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TVp::CalcLinearRegression
#
#   Purpose....: Calculate linear regression parameters
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::CalcLinearRegression(int Size)
{
    int i;
    int j;
    long double xmean;
    long double xdiff2;
    long double sum;
    long double xydiff;
    long double val;
    long double sd;

        xmean = Size / 2;

    xdiff2 = 0;
    for (i = 0; i < Size; i++)
    {
        val = i - xmean;
        xdiff2 += val * val;
    }

    sum = 0;
        for (i = 0; i < Size; i++)
    {
        j = (i + FHistoryCount - Size) % MAX_LEVEL_HISTORY;
        sum += FHistory[j];
    }

    FCurrMean = sum / Size;

    sum = 0;
    sd = 0;
    for (i = 0; i < Size; i++)
    {
        j = (i + FHistoryCount - Size) % MAX_LEVEL_HISTORY;
        val = i - xmean;
        sum += (FHistory[j] - FCurrMean) * val;
        sd += FHistory[j] - FCurrMean;
    }

    xydiff = sum;        
    sd = sd / Size;

    FCurrFlow = xydiff / xdiff2;

    FCurrSlope = xydiff * Size / xdiff2;
    FCurrSl2 = xydiff * xydiff * Size / xdiff2 * Size / xdiff2;

    sum = 0;
    for (i = 0; i < Size; i++)
    {
        j = (i + FHistoryCount - Size) % MAX_LEVEL_HISTORY;
        val = i - xmean;
        val = FHistory[j] - FCurrMean - FCurrSlope * val / Size;
        sum += val * val;
    }

    FCurrSd2 = sum  / (Size - 2.0);

    if (sd < 0.1)
        FCurrSl2 = 0;

    if (FCurrSl2)
        FCurrTurbulence = 100.0 * FCurrSd2 / FCurrSl2;
    else
        FCurrTurbulence = 0.0;
}

/*##########################################################################
#
#   Name       : TVp::UpdateHistory
#
#   Purpose....: Update tank history
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::UpdateHistory(long double val)
{
    int i;
    int j;
    int index;
    int n;
    
    if (FHistoryCount < MAX_LEVEL_HISTORY)
    {
        FHistoryIndex = 0;

        FRawHistory[FHistoryCount] = val;
        FHistoryCount++;
    }
    else
    {
        FRawHistory[FHistoryIndex] = val;
        FHistoryIndex++;
        if (FHistoryIndex == MAX_LEVEL_HISTORY)
            FHistoryIndex = 0;
    }

    for (i = 0; i < FHistoryCount; i++)
    {
        j = (i + FHistoryIndex) % MAX_LEVEL_HISTORY;
        FHistory[i] = FRawHistory[j];
    }

 
    if (FHistoryCount > 60)
    {
        index = 0;

        if (FHistoryCount <= 600)
            CalcLinearRegression(FHistoryCount);
        else
        {
            n = HistoryArr[index];
            index++;
            CalcLinearRegression(n);
            
            while (HistoryArr[index] && FCurrTurbulence >= 20.0)
            {
                n = HistoryArr[index];
                index++;
                CalcLinearRegression(n);
            }
        }

        if (FCurrTurbulence < 20.0)
        {
            FValidPTank = TRUE;
            PTank = 4.186 * VOLUME_TANK * FCurrFlow;
            FCurrTemp = FCurrMean + FCurrSlope * 0.5;
            FTankTemp = (int)(FCurrTemp * 10.0);
            FValidTank = TRUE;
        
            if (FCurrSlope > 0.1)
                UpdateVp(1);
            else
            {
                if (FCurrSlope < -0.1)
                    UpdateVp(-1);
                else
                    UpdateVp(0);
            }
        }
        else
        {
            FValidPTank = FALSE;
            FCurrTemp = FCurrMean;
            FTankTemp = (int)(FCurrTemp * 10.0);
            FValidTank = TRUE;
        }

    } 
}

/*##########################################################################
#
#   Name       : TVp::CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::CreateDayFile(int year, int month, int day)
{
    char str[20];
    char filename[256];
    int i, j;
    int filesize;

    if (!RdosSetCurDir(ROOT_DIR))
        RdosMakeDir(ROOT_DIR);

    sprintf(str, "%d", year);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%d/%d", year, month);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (!RdosSetCurDir(filename))
        RdosMakeDir(filename);

    sprintf(str, "%d/%d/%d.csv", year, month, day);
    strcpy(filename, ROOT_DIR);
    strcat(filename, "/");
    strcat(filename, str);

    if (FDayFile)
        delete FDayFile;

    FDayFile = new TFile(filename);
    
    if (!FDayFile->IsOpen())
    {
        delete FDayFile;
        FDayFile = new TFile(filename, 0);
        FDayFile->Write(CSV_DAY_HEADER, strlen(CSV_DAY_HEADER));
    }

    if (FDayFile->IsOpen())
        FDayFile->SetPos(FDayFile->GetSize());
}

/*##########################################################################
#
#   Name       : TVp::GetTemp
#
#   Purpose....: Get ambient temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetTemp(char *str)
{
    int val;

    if (FValidTank)
    {
        val = FAmbient;

        if (val >= 0)
            sprintf(str, "%d.%01d", val / 10, val % 10);
        else
        {
            val = -val;
            sprintf(str, "-%d.%01d", val / 10, val % 10);
        }
    }
    else
        str[0] = 0;
}

/*##########################################################################
#
#   Name       : TVp::GetTank
#
#   Purpose....: Get tank temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetTank(char *str)
{
    if (FValidTank)
        sprintf(str, "%d.%01d", FTankTemp / 10, FTankTemp % 10);
    else
        str[0] = 0;
}

/*##########################################################################
#
#   Name       : TVp::GetCirc
#
#   Purpose....: Get circ
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetCirc(char *str)
{
    if (FHasCirc)
        sprintf(str, "%d.%01d", FCirc / 10, FCirc % 10);
    else
        str[0] = 0;
}

/*##########################################################################
#
#   Name       : TVp::GetTurbolence
#
#   Purpose....: Get turbolence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetTurbolence(char *str)
{
    int val;

    if (FHistoryCount > 60)
    {
        val = (int)(10.0 * FCurrTurbulence);
        sprintf(str, "%d.%01d", val / 10, val % 10);
    }
    else
        str[0] = 0;
}

/*##########################################################################
#
#   Name       : TVp::GetOn
#
#   Purpose....: Get on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::GetOn(char *str)
{
    if (FPrevOn)
        strcpy(str, "1");
    else
        strcpy(str, "0");
}

/*##########################################################################
#
#   Name       : TVp::UpdateDataStore
#
#   Purpose....: Update data store
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::UpdateDataStore(int hour, int min)
{
    char str[50];

    sprintf(str, "%02d:%02d;", hour, min);
    FDayFile->Write(str, strlen(str));

    GetTemp(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetTank(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetCirc(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetTurbolence(str);
    strcat(str, ";");
    FDayFile->Write(str, strlen(str));

    GetOn(str);
    strcat(str, "\r\n");
    FDayFile->Write(str, strlen(str));
}

/*##########################################################################
#
#   Name       : TVp::Execute
#
#   Purpose....: Handler thread
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::Execute()
{
    int i;
    TDateTime *CurrTime;
    int LastMin;
    int LastDay;
    int UsedDay;
    long double val;
    long double dT;
    int ival;
    int diostat;
    int Sum;
    int Count;
    int PrevCount;
    long double PrevVal;
    char str[50];
    long double E = 0.0;

    TLabelFactory CommentLabelFactory;
    TLabelFactory ValueLabelFactory;
    TLabelFactory UnitLabelFactory;


    CommentLabelFactory.SetSpace(4, 4);
    CommentLabelFactory.SetFont(35);
    CommentLabelFactory.SetBackColor(0, 20, 50);
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    
    ValueLabelFactory.SetSpace(4, 4);
    ValueLabelFactory.SetFont(35);
    ValueLabelFactory.SetBackColor(100, 100, 100);
    ValueLabelFactory.SetDrawColor(0, 0, 0);
    ValueLabelFactory.AlignRight();

    UnitLabelFactory.SetSpace(4, 4);
    UnitLabelFactory.SetFont(35);
    UnitLabelFactory.SetBackColor(0, 20, 50);
    UnitLabelFactory.SetDrawColor(0, 0, 0);
    UnitLabelFactory.AlignLeft();

    TTableControl *Table;

    LockGUI();

    Table = new TTableControl(FControl, 5, 275, 800, 350);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(10);
    Table->SetColSpacing(16);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentLabelFactory, 250);
    Table->AddLabelColumn(&ValueLabelFactory, 125);
    Table->AddLabelColumn(&UnitLabelFactory, 125);

    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);

    Table->SetText(0, 0, "Tank temp");
    Table->SetText(0, 2, "°C");

    Table->SetText(1, 0, "Förvärme temp");
    Table->SetText(1, 2, "°C");

    Table->SetText(2, 0, "Start");
    Table->SetText(2, 2, "°C");

    Table->SetText(3, 0, "Cirkulation");
    Table->SetText(3, 2, "V");

    Table->SetText(4, 0, "Förbrukning");
    Table->SetText(4, 2, "kWh");

    Table->SetText(5, 0, "Effekt");
    Table->SetText(5, 2, "kW");

    Table->SetText(6, 0, "Turbolence");

    Table->Show();

    UnlockGUI();

    TempSum = 0;
    TempCount = 0;
    AmbientSum = 0;
    AmbientCount = 0;

    FHeatSum = 0;
    FHeatCount = 0;
    FCurrTemp = 0;
    FCurrTurbulence = 0;
    PTank = 0;

    FMotorSum = 0;
    FMotorCount = 0;

    CurrTime = new TDateTime;
    LastMin = CurrTime->GetMin();
    LastDay = CurrTime->GetDay();
    UsedDay = LastDay;
    CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
    delete CurrTime;

    while (FInstalled)
    {
        if (RdosReadSerialLines(1, &diostat))
        {
            if ((diostat & 0x20) == 0)
                FVpOn = FALSE;
            else
                FVpOn = TRUE;

            FPrevOn = FVpOn;
        }
        break;
    }

    while (FInstalled)
    {
        if (RdosReadSerialRaw(1, 5, &ival))
        {
            if (ival > 100 && ival < 600)
            {
                val = (long double)ival / 10;
                UpdateHistory(val);

                sprintf(str, "%5.2Lf", val);
                Table->SetText(0, 1, str);
            }
            else
                FLog.printf(0, "", "Invalid heat %d", ival);

            if (FHistoryCount > 60)
            {
                sprintf(str, "%5.2Lf", FCurrTemp);
                Table->SetText(0, 1, str);

                sprintf(str, "%5.2Lf", PTank);
                Table->SetText(5, 1, str);

                sprintf(str, "%5.1Lf", FCurrTurbulence);
                Table->SetText(6, 1, str);
            }
            
        }

        if (RdosReadSerialRaw(1, 6, &ival))
        {
            FHeatSum += ival;
            FHeatCount++;

            if (FHeatCount >= 5)
            {
                FHeatTemp = FHeatSum / FHeatCount;

                val = (long double)FHeatTemp / 10;
                sprintf(str, "%5.1Lf", val);
                Table->SetText(1, 1, str);

                FValidHeat = TRUE;

                FHeatSum = 0;
                FHeatCount = 0;
            }
        }

        CurrTime = new TDateTime;

        if (LastMin != CurrTime->GetMin())
        {
            FSection.Enter();

            if (FMotorCount)
            {
                if (CurrTime->GetMonth() >= 6 && CurrTime->GetMonth() <= 8)
                    FCirc = 99;
                else
                    FCirc = FMotorSum / FMotorCount;

                FHasCirc = TRUE;

               if (FCirc < 25)
                   FVpOn = FALSE;

               if (FCirc > 75 && FTankTemp <= FMaxTank)
                   FVpOn = TRUE;
        
            }

            FMotorSum = 0;
            FMotorCount = 0;

            FSection.Leave();    
        }

        if (LastMin != CurrTime->GetMin() && TempCount)
        {
            if (FHasCirc)
            {
                val = (long double)FCirc / 10;
                sprintf(str, "%4.1Lf", val);
                Table->SetText(3, 1, str);
            }

            if (FHasLowTemp)
            {
                val = (long double)(FLowTemp) / 10;
                sprintf(str, "%5.1Lf", val);
                Table->SetText(2, 1, str);
            }

            if (FPrevOn)
                E += 0.055;
              
            sprintf(str, "%5.1Lf", E);
            Table->SetText(4, 1, str);

            for (i = 1; i < 20; i++)
            {
                HeatArr[i-1] = HeatArr[i];
                ValidHeatArr[i-1] = ValidHeatArr[i];
            }

            HeatArr[19] = FHeatTemp;
            ValidHeatArr[19] = FValidHeat;

            if (FValidHeat)
            {
                Sum = 0;
                PrevCount = 0;

                for (i = 0; i < 5; i++)
                {
                    if (ValidHeatArr[i])
                    {
                        Sum += HeatArr[i] * i;
                        PrevCount += i;
                    }
                }

                if (PrevCount)
                    PrevVal = (long double)Sum / (long double)PrevCount / 10.0;
                else
                    PrevVal = 0;

                Sum = 0;
                Count = 0;

                for (i = 0; i < 5; i++)
                {
                    if (ValidHeatArr[i + 15])
                    {
                        Sum += HeatArr[i + 15] * i;
                        Count += i;
                    }
                }

                if (Count)
                    val = (long double)Sum / (long double)Count / 10.0;
                else
                    val = 0;

                if (Count && PrevCount)
                {
                    dT = val - PrevVal;
                    PHeat = 0.07 * VOLUME_HEAT * dT / 15;
                    FValidPHeat = TRUE;
                }
            }

            FSection.Enter();

            TempSum = 0;
            TempCount = 0;
            AmbientSum = 0;
            AmbientCount = 0;

            if (LastDay != CurrTime->GetDay())
            {
                LastDay = CurrTime->GetDay();
                CreateDayFile(CurrTime->GetYear(), CurrTime->GetMonth(), CurrTime->GetDay());
            }

            LastMin = CurrTime->GetMin();
            UpdateDataStore(CurrTime->GetHour(), CurrTime->GetMin());

            FSection.Leave();
        }

        delete CurrTime;

        RdosWaitMilli(1000);
    }
}
