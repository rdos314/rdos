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
# fm.cpp
# FM synthesis class
#
########################################################################*/

#include "rdos.h"
#include "fm.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TFm::TFm
#
#   Purpose....: Constructor for FM
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFm::TFm(int SampleRate)
{
	 FSampleRate = SampleRate;
	 FmHandle = RdosOpenFm(SampleRate);
}

/*##########################################################################
#
#   Name       : TFm::~TFm
#
#   Purpose....: Destructor for FM
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFm::~TFm()
{
	RdosCloseFm(FmHandle);
}

/*##########################################################################
#
#   Name       : TFm::Wait
#
#   Purpose....: Wait a number of ms on the FM stream
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFm::Wait(long double ms)
{
	int Duration;
	long double Samples;

	Samples = (long double)FSampleRate * ms / 1000.0;

	if (Samples < 1.0)
		Duration = 0;
	else
	{
		if (Samples > 0x7FFFFFFF)
			Duration = 0x7FFFFFF;
		else
			Duration = (int)Samples;
	}

	RdosFmWait(FmHandle, Duration);
}

/*##########################################################################
#
#   Name       : TFm::Create
#
#   Purpose....: Create an instrument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmInstrument *TFm::Create(int C, int M, long double Beta)
{
	return new TFmInstrument(FmHandle, FSampleRate, C, M, Beta);
}

/*##########################################################################
#
#   Name       : TFmInstrument::TFmInstrument
#
#   Purpose....: Constructor for Instrument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmInstrument::TFmInstrument(int FmHandle, int SampleRate, int C, int M, long double Beta)
{
	FSampleRate = SampleRate;
	FHandle = RdosCreateFmInstrument(FmHandle, C, M, Beta);
}

/*##########################################################################
#
#   Name       : TFmInstrument::~TFmInstrument
#
#   Purpose....: Destructor for Instrument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmInstrument::~TFmInstrument()
{
	 RdosFreeFmInstrument(FHandle);
}

/*##########################################################################
#
#   Name       : TFmInstrument::SetAttack
#
#   Purpose....: Set attack time in ms
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::SetAttack(long double DurationMs)
{
	 int Duration;
	 long double Samples;

	 Samples = (long double)FSampleRate * DurationMs / 1000.0;

	 if (Samples < 1.0)
		  Duration = 0;
	 else
	 {
		  if (Samples > 0x7FFFFFFF)
				Duration = 0x7FFFFFF;
		  else
				Duration = (int)Samples;
	 }
	 RdosSetFmAttack(FHandle, Duration);
}

/*##########################################################################
#
#   Name       : TFmInstrument::SetSustain
#
#   Purpose....: Set sustain params
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::SetSustain(long double VolHalfMs, long double BetaHalfMs)
{
	 int VolSamples;
	 int ModSamples;
	 long double Samples;

	 Samples = (long double)FSampleRate * VolHalfMs / 1000.0;

	 if (Samples < 1.0)
		  VolSamples = 0;
	 else
	 {
		  if (Samples > 0x7FFFFFFF)
				VolSamples = 0x7FFFFFF;
		  else
				VolSamples = (int)Samples;
	 }

	 Samples = (long double)FSampleRate * BetaHalfMs / 1000.0;

	 if (Samples < 1.0)
		  ModSamples = 0;
	 else
	 {
		  if (Samples > 0x7FFFFFFF)
				ModSamples = 0x7FFFFFF;
		  else
				ModSamples = (int)Samples;
	 }
	 RdosSetFmSustain(FHandle, VolSamples, ModSamples);
}

/*##########################################################################
#
#   Name       : TFmInstrument::SetRelease
#
#   Purpose....: Set release params
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::SetRelease(long double VolHalfMs, long double BetaHalfMs)
{
	 int VolSamples;
	 int ModSamples;
	 long double Samples;

	 Samples = (long double)FSampleRate * VolHalfMs / 1000.0;

	 if (Samples < 1.0)
		  VolSamples = 0;
	 else
	 {
		  if (Samples > 0x7FFFFFFF)
				VolSamples = 0x7FFFFFF;
		  else
				VolSamples = (int)Samples;
	 }

	 Samples = (long double)FSampleRate * BetaHalfMs / 1000.0;

	 if (Samples < 1.0)
		  ModSamples = 0;
	 else
	 {
		  if (Samples > 0x7FFFFFFF)
				ModSamples = 0x7FFFFFF;
		  else
				ModSamples = (int)Samples;
	 }
	 RdosSetFmRelease(FHandle, VolSamples, ModSamples);
}


/*##########################################################################
#
#   Name       : TFmInstrument::Play
#
#   Purpose....: Play a note
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::Play(long double Freq, long double LeftVolume, long double RightVolume, long double SustainMs)
{
	 int Duration;
	 long double Samples;
	 long double Temp;
	 int LeftVol;
	 int RightVol;

	 if (LeftVolume >= 100.0)
		LeftVol = 0x7FFFFFFF;
	 else
	 {
		if (LeftVolume <= 0.0)
			LeftVol = 0;
		else
		{
			Temp = LeftVolume / 100.0 * 0x7FFFFFFF;
			LeftVol = (int)Temp;
		}
	 }

	 if (RightVolume >= 100.0)
		RightVol = 0x7FFFFFFF;
	 else
	 {
		if (RightVolume <= 0.0)
			RightVol = 0;
		else
		{
			Temp = RightVolume / 100.0 * 0x7FFFFFFF;
			RightVol = (int)Temp;
		}
	 }

	 Samples = (long double)FSampleRate * SustainMs / 1000.0;

	 if (Samples < 1.0)
		  Duration = 0;
	 else
	 {
		  if (Samples > 0x7FFFFFFF)
				Duration = 0x7FFFFFF;
		  else
				Duration = (int)Samples;
	 }

	RdosPlayFmNote(FHandle, Freq, LeftVol, RightVol, Duration);
}

/*##########################################################################
#
#   Name       : TFmInstrument::GetBase
#
#   Purpose....: Get base of A
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFmInstrument::GetBase(int Octave)
{
    switch (Octave)
    {
        case -4:
            return 27.5;
            
        case -3:
            return 55.0;
                        
        case -2:
            return 110.0;
            
        case -1:
            return 220.0;
            
        case 0:
            return 440.0;

        case 1:
            return 880.0;

        case 2:
            return 1760.0;

        case 3:
            return 3520.0;

        case 4:
            return 7040.0;

        case 5:
            return 14080.0;

        default:
            return 0.0;        
            
    }
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayA
#
#   Purpose....: Play A
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayA(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayBFlat
#
#   Purpose....: Play B flat
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayBFlat(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.05946 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayB
#
#   Purpose....: Play B
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayB(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.12246 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayC
#
#   Purpose....: Play C
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayC(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.18921 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayCSharp
#
#   Purpose....: Play C sharp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayCSharp(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.25992 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayD
#
#   Purpose....: Play D
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayD(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.33484 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayDSharp
#
#   Purpose....: Play D sharp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayDSharp(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.41421 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayE
#
#   Purpose....: Play E
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayE(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.49831 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayF
#
#   Purpose....: Play F
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayF(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.58740 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayFSharp
#
#   Purpose....: Play F Sharp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayFSharp(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.68179 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayG
#
#   Purpose....: Play G
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayG(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.78180 * base, LeftVolume, RightVolume, SustainMs);
}

/*##########################################################################
#
#   Name       : TFmInstrument::PlayAFlat
#
#   Purpose....: Play A flat
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFmInstrument::PlayAFlat(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs)
{
    long double base = GetBase(Octave);

    Play(1.88775 * base, LeftVolume, RightVolume, SustainMs);
}
