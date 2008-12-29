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

protected:    
	 void GetMyPos(long double RA, long double decl, long double *altitude, long double *azimuth);
	 void GetMyNearPos(long double r, long double RA, long double decl, long double *altitude, long double *azimuth);
    void CalcSun();
    void CalcMoon();

    long double SIDTIME;

    long double SunL;
    long double SunM;
    long double SunRA;
    long double SunDecl;

    long double MoonR;
    long double MoonL;
    long double MoonRA;
    long double MoonDecl;    

	long double FMyLat;
    long double FMyLong;
    long double FDiffTime;

};

#endif

