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
#   Name       : TFmInstrumentFactory::TFmInstrumentFactory
#
#   Purpose....: Constructor for Instrument factory		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmInstrumentFactory::TFmInstrumentFactory(int SampleRate, int Volume)
{
    FAudioHandle = RdosCreateAudioOutChannel(SampleRate, 31, Volume);

    FSampleRate = SampleRate;    
}

/*##########################################################################
#
#   Name       : TFmInstrumentFactory::~TFmInstrumentFactory
#
#   Purpose....: Destructor for Instrument factory		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmInstrumentFactory::~TFmInstrumentFactory()
{
    RdosCloseAudioOutChannel(FAudioHandle);
}

/*##########################################################################
#
#   Name       : TFmInstrumentFactory::Create
#
#   Purpose....: Create instrument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFmInstrument *TFmInstrumentFactory::Create(int C, int M, long double Beta)
{
    return new TFmInstrument(FAudioHandle, FSampleRate, C, M, Beta);
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
TFmInstrument::TFmInstrument(int AudioHandle, int SampleRate, int C, int M, long double Beta)
{
    FAudioHandle = AudioHandle;
    FSampleRate = SampleRate;

    FFmHandle = RdosCreateFmInstrument(C, M, Beta, SampleRate);
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
    RdosFreeFmInstrument(FFmHandle);
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
	 RdosSetFmAttack(FFmHandle, Duration);
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
	 RdosSetFmSustain(FFmHandle, VolSamples, ModSamples);
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
	 RdosSetFmRelease(FFmHandle, VolSamples, ModSamples);
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
void TFmInstrument::Play(long double Freq, long double Volume, long double SustainMs)
{
	 int Duration;
	 long double Samples;
	 long double Temp;
	 int IntVol;

	 if (Volume >= 100.0)
		IntVol = 0x7FFFFFFF;
	 else
	 {
		if (Volume <= 0.0)
			IntVol = 0;
		else
		{
			Temp = Volume / 100.0 * 0x7FFFFFFF;
			IntVol = (int)Temp;
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

	RdosPlayFmNote(FFmHandle, FAudioHandle, Freq, IntVol, Duration);
}

