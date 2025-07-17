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

