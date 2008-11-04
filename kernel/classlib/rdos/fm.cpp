/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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

