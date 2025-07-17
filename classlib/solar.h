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
# solar.h
# Solar system calculations
#
########################################################################*/

#ifndef _SOLAR_H
#define _SOLAR_H

#include "datetime.h"

class TSolar
{
public:
    TSolar(int latdeg, int latmin, long double latsec, int longdeg, int longmin, long double longsec);
    ~TSolar();    

    void SetTime(TDateTime &time, int timezone);

    void GetSunPosition(long double *altitude, long double *azimuth);
    void GetMoonPosition(long double *altitude, long double *azimuth);
    void GetMercuryPosition(long double *altitude, long double *azimuth);
    void GetVenusPosition(long double *altitude, long double *azimuth);
    void GetMarsPosition(long double *altitude, long double *azimuth);
    void GetJupiterPosition(long double *altitude, long double *azimuth);
    void GetSaturnPosition(long double *altitude, long double *azimuth);
    void GetUranusPosition(long double *altitude, long double *azimuth);
    void GetNeptunePosition(long double *altitude, long double *azimuth);

    long double GetMoonPhase();
    long double GetMercuryPhase();
    long double GetVenusPhase();
    long double GetMarsPhase();
    long double GetJupiterPhase();
    long double GetSaturnPhase();
    long double GetUranusPhase();
    long double GetNeptunePhase();

protected:    
	void GetMyPos(long double RA, long double decl, long double *altitude, long double *azimuth);
	void GetMyNearPos(long double r, long double RA, long double decl, long double *altitude, long double *azimuth);
	long double GetFv(long double SolarR, long double GeoR);
    long double FvToPhase(long double Fv);
    void CalcSun();
    void CalcMoon();
    void CalcPlanets();
    void CalcMercury();
    void CalcVenus();
    void CalcMars();
    void CalcJupiter();
    void CalcSaturn();
    void CalcUranus();
    void CalcNeptune();

    long double SIDTIME;

    long double SunL;
    long double SunM;
    long double SunR;
    long double SunLon;
    long double SunRA;
    long double SunDecl;

    long double SunX;
    long double SunY;

    long double MoonR;
    long double MoonL;
    long double MoonLon;
    long double MoonLat;
    long double MoonRA;
    long double MoonDecl;    

    long double Mj;
    long double Ms;
    long double Mu;

    long double MercurySolarR;
    long double MercuryGeoR;
    long double MercuryRA;
    long double MercuryDecl;

    long double VenusSolarR;
    long double VenusGeoR;
    long double VenusRA;
    long double VenusDecl;

    long double MarsSolarR;
    long double MarsGeoR;
    long double MarsRA;
    long double MarsDecl;

    long double JupiterSolarR;
    long double JupiterGeoR;
    long double JupiterRA;
    long double JupiterDecl;

    long double SaturnSolarR;
    long double SaturnGeoR;
    long double SaturnRA;
    long double SaturnDecl;

    long double UranusSolarR;
    long double UranusGeoR;
    long double UranusRA;
    long double UranusDecl;

    long double NeptuneSolarR;
    long double NeptuneGeoR;
    long double NeptuneRA;
    long double NeptuneDecl;

	long double FMyLat;
    long double FMyLong;
    long double FDiffTime;

};

#endif

