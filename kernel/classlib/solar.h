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

