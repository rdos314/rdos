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
# fm.h
# FM synthesis class
#
########################################################################*/

#ifndef _FM_H
#define _FM_H

class TFmInstrument;

class TFm
{
public:
	TFm(int SampleRate);
	~TFm();

	TFmInstrument *Create(int C, int M, long double Beta);
	void Wait(long double Ms);

private:
	int FSampleRate;
	int FmHandle;
};

class TFmInstrument
{
friend class TFm;

public:
	~TFmInstrument();

	void SetAttack(long double DurationMs);
	void SetSustain(long double VolHalfMs, long double BetaHalfMs);
	void SetRelease(long double VolHalfMs, long double BetaHalfMs);

	void Play(long double Freq, long double LeftVolume, long double RightVolume, long double SustainMs);

    void PlayA(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayBFlat(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayB(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayC(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayCSharp(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayD(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayDSharp(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayE(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayF(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayFSharp(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayG(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);
    void PlayAFlat(int Octave, long double LeftVolume, long double RightVolume, long double SustainMs);

protected:
	TFmInstrument(int FmHandle, int SampleRate, int C, int M, long double Beta);
    long double GetBase(int Octave);

	int FSampleRate;
	int FHandle;
};

#endif

