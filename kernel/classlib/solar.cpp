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
# solar.cpp
# Solar system class
#
########################################################################*/

#include <stdio.h>
#include <math.h>

#include "solar.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : rev
#
#   Purpose....: rev function
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double rev(long double val)
{
    while (val < 0.0)
        val += 360.0;

    while (val >= 360.0)
        val -= 360.0;

    return val;
}

/*##########################################################################
#
#   Name       : TSolar::TSolar
#
#   Purpose....: Constructor solar system
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSolar::TSolar(int latdeg, int latmin, long double latsec, int longdeg, int longmin, long double longsec)
{
    FMyLat = (long double)latdeg + (long double)latmin / 60.0 + latsec / 3600.0;
    FMyLong = (long double)longdeg + (long double)longmin / 60.0 + longsec / 3600.0;
}

/*##########################################################################
#
#   Name       : TSolar::~TSolar
#
#   Purpose....: Destructor solar system
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSolar::~TSolar()
{
}

/*##########################################################################
#
#   Name       : TSolar::SetTime
#
#   Purpose....: Set current time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::SetTime(TDateTime &time, int timezone)
{
    FDiffTime = (long double)time - (long double)TDateTime(1999, 12, 31, 0, 0, 0);
    FDiffTime = (FDiffTime - (long double)timezone) / 24.0;

    CalcSun();
    CalcMoon();
}

/*##########################################################################
#
#   Name       : TSolar::GetMyPos
#
#   Purpose....: Convert to local position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetMyPos(long double RA, long double decl, long double *altitude, long double *azimuth)
{
	 long double HA;
	 long double x, y, z;
	 long double xh, yh, zh;
	 long double lat;
	 long double a;

	 HA = SIDTIME - RA / 15.0;

	HA = HA * M_PI / 12.0;
	 decl = decl * M_PI / 180.0;

	 x = cosl(HA) * cosl(decl);
	 y = sinl(HA) * cosl(decl);
	 z = sinl(decl);

	 lat = FMyLat * M_PI / 180.0;

	 xh = x * sinl(lat) - z * cosl(lat);
	 yh = y;
	 zh = x * cosl(lat) + z * sinl(lat);

	 a = atan2l(yh, xh);
	 *azimuth = a * 180.0 / M_PI + 180;

	 a = asinl(zh);
	 *altitude = a * 180.0 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::GetMyNearPos
#
#   Purpose....: Convert to local position from nearby objects
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetMyNearPos(long double r, long double RA, long double decl, long double *altitude, long double *azimuth)
{
	 long double gclat;
	 long double rho;
	 long double HA;
	 long double g;
	 long double topRA;
	 long double topDecl;
	 long double mpar;
	 long double DeclRad;
	 long double x, y, z;
	 long double xh, yh, zh;
	 long double lat;
	 long double a;

	 mpar = asinl(1 / r);
	 mpar = mpar * 180.0 / M_PI;

	 lat = FMyLat * M_PI / 180.0;

	 gclat = FMyLat - 0.1924 * sinl(2 * lat);
	 rho = 0.99833 + 0.00167 * cosl(2 * lat);

	 HA = SIDTIME - RA / 15.0;

	HA = HA * M_PI / 12.0;

	gclat = gclat * M_PI / 180.0;

	 g = atanl(tanl(gclat) / cosl(HA));

	 DeclRad = decl * M_PI / 180.0;

	 topRA = RA - mpar * rho * cosl(gclat) * sinl(HA) / cosl(DeclRad);
	 topDecl = decl - mpar * rho * sinl(gclat) * sinl(g - DeclRad) / sinl(g);

	 HA = SIDTIME - topRA / 15.0;

	HA = HA * M_PI / 12.0;

	 x = cosl(HA) * cosl(topDecl);
	 y = sinl(HA) * cosl(topDecl);
	 z = sinl(topDecl);

	 lat = FMyLat * M_PI / 180.0;

	 xh = x * sinl(lat) - z * cosl(lat);
	 yh = y;
	 zh = x * cosl(lat) + z * sinl(lat);

	 a = atan2l(yh, xh);
	 *azimuth = a * 180.0 / M_PI + 180;

	 a = asinl(zh);
	 *altitude = a * 180.0 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcSun
#
#   Purpose....: Calculate the sun's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcSun()
{
    long double w = 282.9404 + 4.70935e-5 * FDiffTime;
    long double e = 0.016709 - 1.151e-9 * FDiffTime;
    long double M = 356.0470 + 0.9856002585 * FDiffTime;
    long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;
    long double E;
    long double x;
    long double y;
    long double z;
    long double r;
    long double v;
    long double lon;
    long double GMST0;
    long double UT;
    int days;

    SunM = rev(M);

    SunL = w + SunM;
    SunL = rev(SunL);

    M = SunM * M_PI / 180.0;

    E = M + e * sinl(M) * (1.0 + e * cosl(M));

    oblecl = oblecl * M_PI / 180.0;
    
    x = cosl(E) - e;
    y = sinl(E) * sqrtl(1.0 - e * e);

    r = sqrtl(x * x + y * y);
    v = atan2l(y, x);

	 v = v * 180.0 / M_PI;
    
    lon = v + w;
    lon = rev(lon);

    lon = lon * M_PI / 180.0;

    x = r * cosl(lon);
    y = r * sinl(lon);

    z = y * sinl(oblecl);
    y = y * cosl(oblecl);
    
    SunRA =  atan2l(y, x);
    SunDecl = asinl(z / r);

    SunRA = SunRA * 180.0 / M_PI;
    SunDecl = SunDecl * 180 / M_PI;

    GMST0 = SunL / 15.0 + 12.0;

    days = (int)FDiffTime;
    days++;
    
	 UT = (FDiffTime - (long double)days) * 360.0 / 15.0;

	SIDTIME = GMST0 + UT + FMyLong / 15.0;
	SIDTIME = rev(SIDTIME);
}

/*##########################################################################
#
#   Name       : TSolar::GetSunPosition
#
#   Purpose....: Get the sun's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetSunPosition(long double *altitude, long double *azimuth)
{
	 GetMyPos(SunRA, SunDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::CalcMoon
#
#   Purpose....: Calculate the moon's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcMoon()
{
    long double N = rev(125.1228 - 0.0529538083 * FDiffTime);
    long double i = 5.1454;
    long double w = rev(318.0634 + 0.1643573223 * FDiffTime);
	long double a = 60.2666;
    long double e = 0.054900;
    long double M = rev(115.3654 + 13.0649929509 * FDiffTime);
    long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;
    long double E;
	long double x, y, z;
	long double rx, ry, rz;
    long double v;
    long double Ms;
    long double D;
    long double F;
    long double lat;
    long double lon;

    MoonL = N + w + M;
    D = MoonL - SunL;
    F = MoonL - N;

    M = M * M_PI / 180.0;
    E = M + e * sinl(M) * (1 + e * cosl(M));
	E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

	x = a * (cosl(E) - e);
	y = a * sqrtl(1 - e * e) * sinl(E);

	MoonR = sqrtl(x * x + y * y);
	v = atan2l(y, x);

	N = N * M_PI / 180.0;
	w = w * M_PI / 180.0;
	i = i * M_PI / 180.0;

	x = MoonR * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
	y = MoonR * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
	z = MoonR * sinl(v + w) * sin(i);

	lon =  atan2l(y, x);
	lat = asinl(z / MoonR);

    lon = lon * 180.0 / M_PI;
    lat = lat * 180.0 / M_PI;

    D = D * M_PI / 180.0;
    F = F * M_PI / 180.0;
    Ms = SunM * M_PI / 180.0;

    lon -= 1.274 * sinl(M - 2.0 * D); 
    lon += 0.658 * sinl(2.0 * D);
    lon -= 0.186 * sinl(Ms);
    lon -= 0.059 * sinl(2 * M - 2.0 * D);
    lon -= 0.057 * sinl(M - 2.0 * D + Ms);
    lon += 0.053 * sinl(M + 2.0 * D);
    lon += 0.046 * sinl(2.0 * D - Ms);
    lon += 0.041 * sinl(M - Ms);
    lon -= 0.035 * sinl(D);
    lon -= 0.031 * sinl(M + Ms);
    lon -= 0.015 * sinl(2.0 * F - 2.0 * D);
    lon += 0.011 * sinl(M - 4.0 * D);

    lat -= 0.173 * sinl(F - 2.0 * D);
    lat -= 0.055 * sinl(M - F - 2.0 * D);
    lat -= 0.046 * sinl(M + F - 2.0 * D);
    lat += 0.033 * sinl(F + 2.0 * D);
    lat += 0.017 * sinl(2.0 * M + F);

    MoonR -= 0.58 * cosl(M - 2.0 * D);
    MoonR -= 0.46 * cosl(2.0 * D);

    lon = rev(lon);

    lon = lon * M_PI / 180.0;
    lat = lat * M_PI / 180.0;

    x = cosl(lon) * cosl(lat);
    y = sinl(lon) * cosl(lat);
    z = sinl(lat);

    oblecl = oblecl * M_PI / 180.0;

    rx = x;
	ry = y * cosl(oblecl) - z * sinl(oblecl);
	rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    MoonRA =  atan2l(ry, rx);
    MoonDecl = asinl(rz);

    MoonRA = MoonRA * 180.0 / M_PI;
    MoonDecl = MoonDecl * 180 / M_PI;

}

/*##########################################################################
#
#   Name       : TSolar::GetMoonPosition
#
#   Purpose....: Get the moon's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetMoonPosition(long double *altitude, long double *azimuth)
{
	 GetMyNearPos(MoonR, MoonRA, MoonDecl, altitude, azimuth);
}
