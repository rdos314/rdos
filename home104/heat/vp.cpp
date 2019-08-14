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

void LockGUI();
void UnlockGUI();

const int HistoryArr[] = {601, 541, 481, 421, 361, 301, 241, 181, 121, 91, 61, 0};

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
    FOffCounter = 30;

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
#   Name       : TVp::SetSolarAlt
#
#   Purpose....: Set solar position
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetSolarAlt(long double val)
{
    FSolarAlt = val;
}

/*##########################################################################
#
#   Name       : TVp::SetSolarPower
#
#   Purpose....: Set solar power
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetSolarPower(long double val)
{
    FSolarPower = val;
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
            if (FSolarAlt >= 10.0)
                FMaxTank = 500 - ambient;
            else
                FMaxTank = 400 - ambient;

            if (FMaxTank > 450)
                FMaxTank = 450;
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
#   Name       : TVp::SetCirc
#
#   Purpose....: Set current max circulation value
#
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVp::SetCirc(int circ, long double speed)
{
    FSection.Enter();

    FCirc = circ;
    FCircSpeed = speed;
    FHasCirc = TRUE;
    
    if (FCirc < 25)
        FVpOn = FALSE;

    if (FCirc > 75 && FTankTemp <= FMaxTank)
        FVpOn = TRUE;
        
    FSection.Leave();    
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
            on = FALSE;
        else
        {
            on = FPrevOn;
            
            if (diff < 0)
            {
                if (FOffCounter)
                    FOffCounter--;
                    
                FIncCount = 0;
            
                if (!FHasLowTemp)
                {
                    FLowTemp = FTankTemp - 5;
                    FHasLowTemp = TRUE;
                }

                if (FOffCounter == 0 && FTankTemp > FLowTemp + 5)
                    on = FALSE;                
                else
                    on = TRUE;
            }

            if (diff > 0)
            {
                FOffCounter = 30;
                
                if (FIncCount)
                {
                    FLowTemp = FTankTemp - 30;
                    FHasLowTemp = TRUE;
                    on = TRUE;
                }

                FIncCount++;
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

        if (FTankTemp > 300)
        {                
            if (FCirc == 0)
                if ((diostat & 0x10) != 0)
                    RdosToggleSerialLine(1, 4);

            if (FCirc > 25)
                if ((diostat & 0x10) == 0)
                    RdosToggleSerialLine(1, 4);
        }
    }

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
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    unsigned long msb, lsb;
    int LastMin;
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
    CommentLabelFactory.SetFont(20);
    CommentLabelFactory.SetBackColor(0, 20, 50);
    CommentLabelFactory.SetDrawColor(0, 0, 0);
    CommentLabelFactory.AlignLeft();
    
    ValueLabelFactory.SetSpace(4, 4);
    ValueLabelFactory.SetFont(20);
    ValueLabelFactory.SetBackColor(100, 100, 100);
    ValueLabelFactory.SetDrawColor(0, 0, 0);
    ValueLabelFactory.AlignRight();

    UnitLabelFactory.SetSpace(4, 4);
    UnitLabelFactory.SetFont(20);
    UnitLabelFactory.SetBackColor(0, 20, 50);
    UnitLabelFactory.SetDrawColor(0, 0, 0);
    UnitLabelFactory.AlignLeft();

    TTableControl *Table;

    LockGUI();

    Table = new TTableControl(FControl, 850, 725, 400, 250);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(5);
    Table->SetColSpacing(8);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentLabelFactory, 220);
    Table->AddLabelColumn(&ValueLabelFactory, 80);
    Table->AddLabelColumn(&UnitLabelFactory, 70);

    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);
    Table->AddRow(24, 45);

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

    RdosGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &LastMin, &sec, &ms, &us);

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

            val = (long double)ival / 10;
            UpdateHistory(val);

            sprintf(str, "%5.2Lf", val);
            Table->SetText(0, 1, str);


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

        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

        if (LastMin != min && TempCount)
        {
            if (FHasCirc)
            {
                sprintf(str, "%4.1Lf", FCircSpeed);
                Table->SetText(3, 1, str);
            }

            LastMin = min;

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

            FSection.Leave();
        }

        RdosWaitMilli(1000);
    }
}
