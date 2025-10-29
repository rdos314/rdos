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
# smameter.cpp
# SMA energy meter
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "rdos.h"
#include "smameter.h"

/*##########################################################################
#
#   Name       : TSmaMeter::TSmaMeter
#
#   Purpose....: SMA meter constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSmaMeter::TSmaMeter()
  : FSection("SMA Meter")
{
    int i;

    for (i = 0; i < 2; i++)
    {
       FVolt[i] = 0.0;
       FCurrent[i] = 0.0;
    }

    for (i = 0; i < 3; i++)
    {
        FConsumePower[i] = 0.0;
        FProducePower[i] = 0.0;
        FConsumeEnergy[i] = 0.0;
        FProduceEnergy[i] = 0.0;
    }

    Start("SMA Meter", 0x8000);
}

/*##########################################################################
#
#   Name       : TSmaMeter::~TSmaMeter
#
#   Purpose....: SMA meter destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSmaMeter::~TSmaMeter()
{
}

/*##########################################################################
#
#   Name       : TEch200::WaitForMeassure
#
#   Purpose....: Wait for new meassure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmaMeter::WaitForMeassure()
{
    FSignal.WaitForever();
}

/*##########################################################################
#
#   Name       : TEch200::GetVolt
#
#   Purpose....: Get phase voltage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetVolt(int Phase)
{
    long double val = 0.0;

    if (Phase >= 1 && Phase <= 3)
    {
        FSection.Enter();
        val = FVolt[Phase - 1];
        FSection.Leave();
    }

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetCurrent
#
#   Purpose....: Get phase current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetCurrent(int Phase)
{
    long double val = 0.0;

    if (Phase >= 1 && Phase <= 3)
    {
        FSection.Enter();
        val = FCurrent[Phase - 1];
        FSection.Leave();
    }

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetConsumePower
#
#   Purpose....: Get consume power sum
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetConsumePower()
{
    long double val;

    FSection.Enter();
    val = FConsumePower[0];
    FSection.Leave();

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetConsumePower
#
#   Purpose....: Get phase consumed power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetConsumePower(int Phase)
{
    long double val = 0.0;

    if (Phase >= 1 && Phase <= 3)
    {
        FSection.Enter();
        val = FConsumePower[Phase];
        FSection.Leave();
    }

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetProducePower
#
#   Purpose....: Get produce power sum
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetProducePower()
{
    long double val;

    FSection.Enter();
    val = FProducePower[0];
    FSection.Leave();

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetProducePower
#
#   Purpose....: Get phase produced power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetProducePower(int Phase)
{
    long double val = 0.0;

    if (Phase >= 1 && Phase <= 3)
    {
        FSection.Enter();
        val = FProducePower[Phase];
        FSection.Leave();
    }

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetConsumeEnergy
#
#   Purpose....: Get consume energy sum
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetConsumeEnergy()
{
    long double val;

    FSection.Enter();
    val = FConsumeEnergy[0];
    FSection.Leave();

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetConsumeEnergy
#
#   Purpose....: Get phase consumed energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetConsumeEnergy(int Phase)
{
    long double val = 0.0;

    if (Phase >= 1 && Phase <= 3)
    {
        FSection.Enter();
        val = FConsumeEnergy[Phase];
        FSection.Leave();
    }

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetProduceEnergy
#
#   Purpose....: Get produce energy sum
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetProduceEnergy()
{
    long double val;

    FSection.Enter();
    val = FProduceEnergy[0];
    FSection.Leave();

    return val;
}

/*##########################################################################
#
#   Name       : TEch200::GetProduceEnergy
#
#   Purpose....: Get phase produced energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSmaMeter::GetProduceEnergy(int Phase)
{
    long double val = 0.0;

    if (Phase >= 1 && Phase <= 3)
    {
        FSection.Enter();
        val = FProduceEnergy[Phase];
        FSection.Leave();
    }

    return val;
}

/*##########################################################################
#
#   Name       : TSmaMeter::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSmaMeter::Execute()
{
    char p;
    int ival;
    long long lval;
    long double val;

    for (;;)
    {
        RdosWaitAcMeassure();

        FSection.Enter();

        for (p = 1; p <= 3; p++)
        {
            ival = RdosGetAcVoltage(p);
            val = (long double)ival;
            FVolt[p - 1] = val / 1000.0;
        }

        for (p = 1; p <= 3; p++)
        {
            ival = RdosGetAcCurrent(p);
            val = (long double)ival;
            FCurrent[p - 1] = val / 1000.0;
        }

        for (p = 0; p <= 3; p++)
        {
            ival = RdosGetAcConsumePower(p);
            val = (long double)ival;
            FConsumePower[p] = val / 10.0;
        }

        for (p = 0; p <= 3; p++)
        {
            ival = RdosGetAcProducePower(p);
            val = (long double)ival;
            FProducePower[p] = val / 10.0;
        }

        for (p = 0; p <= 3; p++)
        {
            lval = RdosGetAcConsumeEnergy(p);
            val = (long double)lval;
            val = val / 1000.0;
            FConsumeEnergy[p] = val / 3600.0;
        }

        for (p = 0; p <= 3; p++)
        {
            lval = RdosGetAcProduceEnergy(p);
            val = (long double)lval;
            val = val / 1000.0;
            FProduceEnergy[p] = val / 3600.0;
        }
        FSection.Leave();
        FSignal.Signal();
    }
}
