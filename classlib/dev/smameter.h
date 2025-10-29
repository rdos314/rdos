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
# smameter.h
# SMA energy meter
#
########################################################################*/

#ifndef _SMAMETER_H
#define _SMAMETER_H

#include "thread.h"
#include "rdos.h"
#include "section.h"
#include "sigdev.h"

class TSmaMeter : public TThread
{
public:
    TSmaMeter();
    virtual ~TSmaMeter();

    void WaitForMeassure();

    long double GetVolt(int Phase);
    long double GetCurrent(int Phase);
    long double GetConsumePower();
    long double GetConsumePower(int Phase);
    long double GetProducePower();
    long double GetProducePower(int Phase);
    long double GetConsumeEnergy();
    long double GetConsumeEnergy(int Phase);
    long double GetProduceEnergy();
    long double GetProduceEnergy(int Phase);

protected:
    virtual void Execute();

    long double FVolt[3];
    long double FCurrent[3];
    long double FConsumePower[4];
    long double FProducePower[4];
    long double FConsumeEnergy[4];
    long double FProduceEnergy[4];
    TSection FSection;
    TSignalDevice FSignal;
};

#endif

