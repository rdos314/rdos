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
# solar.cpp
# Solar system class
#
########################################################################*/

#include <stdio.h>
#include <math.h>

#include "solar.h"

#define FALSE   0
#define TRUE    !FALSE

#ifdef __WATCOMC__

#define M_PI    3.14159265358979323846264
#define cosl cos
#define sinl sin
#define atan2l atan2
#define asinl asin
#define acosl acos
#define tanl tan
#define atanl tanl
#define sqrtl sqrt

#endif

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
    CalcPlanets();
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
         topDecl = topDecl * M_PI / 180.0;

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
#   Name       : TSolar::GetFv
#
#   Purpose....: Get phase angle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetFv(long double SolarR, long double GeoR)
{
    return 180.0 / M_PI * acosl((SolarR * SolarR + GeoR * GeoR - SunR * SunR) / (2.0 * SolarR * GeoR)); 
}

/*##########################################################################
#
#   Name       : TSolar::FvToPhase
#
#   Purpose....: Convert phase angle to phase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::FvToPhase(long double Fv)
{
    Fv = Fv * M_PI / 180.0;
    return (1.0  + cosl(Fv)) / 2.0; 
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
    SunLon = lon; 

    lon = lon * M_PI / 180.0;

    SunR = r;
    SunX = r * cosl(lon);
    SunY = r * sinl(lon);

    x = SunX;
    y = SunY * cosl(oblecl);
        z = SunY * sinl(oblecl);
    
    SunRA =  atan2l(y, x);
    SunDecl = asinl(z / r);

    SunRA = SunRA * 180.0 / M_PI;
    SunDecl = SunDecl * 180 / M_PI;

    GMST0 = SunL / 15.0 + 12.0;

         days = (int)FDiffTime;
    days++;
    
         UT = (FDiffTime - (long double)days) * 360.0 / 15.0;

        SIDTIME = GMST0 + UT + FMyLong / 15.0;

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

     MoonLon = lon;
         MoonLat = lat;

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

/*##########################################################################
#
#   Name       : TSolar::CalcMercury
#
#   Purpose....: Calculate position of mercury
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcMercury()
{
    long double N = rev(48.3313 + 3.24587e-5 * FDiffTime);
    long double i = rev(7.0047 + 5.00e-8 * FDiffTime);
    long double w = rev(29.1241 + 1.01444e-5 * FDiffTime);
    long double a = 0.387098;
    long double e = 0.205635 + 5.59e-10 * FDiffTime;
    long double M = rev(168.6562 + 4.0923344368 * FDiffTime);
        long double E;
        long double x, y, z;
        long double v;
        long double r;
        long double lon, lat;
    long double rx, ry, rz;
        long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;

        M = M * M_PI / 180.0;
        E = M + e * sinl(M) * (1 + e * cosl(M));
        E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

        x = a * (cosl(E) - e);
        y = a * sqrtl(1 - e * e) * sinl(E);

        r = sqrtl(x * x + y * y);
        v = atan2l(y, x);

        N = N * M_PI / 180.0;
        w = w * M_PI / 180.0;
        i = i * M_PI / 180.0;

        x = r * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
        y = r * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
        z = r * sinl(v + w) * sin(i);

        lon =  atan2l(y, x);
        lat = asinl(z / r);

        x = r * cosl(lon) * cosl(lat);
        y = r * sinl(lon) * cosl(lat);
    z = r * sinl(lat);

    x += SunX;
    y += SunY;

    MercurySolarR = r;
    MercuryGeoR = sqrtl(x * x + y * y + z * z);
    
    oblecl = oblecl * M_PI / 180.0;

        rx = x;
        ry = y * cosl(oblecl) - z * sinl(oblecl);
        rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    MercuryRA =  atan2l(ry, rx);
    MercuryDecl = asinl(rz / MercuryGeoR);

    MercuryRA = MercuryRA * 180.0 / M_PI;
        MercuryDecl = MercuryDecl * 180 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcVenus
#
#   Purpose....: Calculate position of venus
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcVenus()
{
    long double N = rev(76.6799 + 2.46590e-5 * FDiffTime);
    long double i = rev(3.3946 + 2.75e-8 * FDiffTime);
    long double w = rev(54.8910 + 1.38374e-5 * FDiffTime);
    long double a = 0.723330;
    long double e = 0.006773 - 1.302e-9 * FDiffTime;
    long double M = rev(48.0052 + 1.6021302244 * FDiffTime);
        long double E;
        long double x, y, z;
        long double v;
        long double r;
        long double lon, lat;
    long double rx, ry, rz;
        long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;

        M = M * M_PI / 180.0;
        E = M + e * sinl(M) * (1 + e * cosl(M));
        E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

        x = a * (cosl(E) - e);
        y = a * sqrtl(1 - e * e) * sinl(E);

        r = sqrtl(x * x + y * y);
        v = atan2l(y, x);

        N = N * M_PI / 180.0;
        w = w * M_PI / 180.0;
        i = i * M_PI / 180.0;

        x = r * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
        y = r * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
        z = r * sinl(v + w) * sin(i);

        lon =  atan2l(y, x);
        lat = asinl(z / r);

        x = r * cosl(lon) * cosl(lat);
        y = r * sinl(lon) * cosl(lat);
    z = r * sinl(lat);

    x += SunX;
    y += SunY;

    VenusSolarR = r;
    VenusGeoR = sqrtl(x * x + y * y + z * z);
    
    oblecl = oblecl * M_PI / 180.0;

        rx = x;
        ry = y * cosl(oblecl) - z * sinl(oblecl);
        rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    VenusRA =  atan2l(ry, rx);
    VenusDecl = asinl(rz / VenusGeoR);

    VenusRA = VenusRA * 180.0 / M_PI;
        VenusDecl = VenusDecl * 180 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcMars
#
#   Purpose....: Calculate position of mars
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcMars()
{
        long double N = rev(49.5574 + 2.11081e-5 * FDiffTime);
        long double i = rev(1.8497 - 1.78e-8 * FDiffTime);
        long double w = rev(286.5016 + 2.92961e-5 * FDiffTime);
        long double a = 1.523688;
        long double e = 0.093405 + 2.516e-9 * FDiffTime;
        long double M = rev(18.6021 + 0.5240207766 * FDiffTime);
        long double E;
        long double x, y, z;
        long double v;
        long double r;
        long double lon, lat;
    long double rx, ry, rz;
        long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;

        M = M * M_PI / 180.0;
        E = M + e * sinl(M) * (1 + e * cosl(M));
        E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

        x = a * (cosl(E) - e);
        y = a * sqrtl(1 - e * e) * sinl(E);

        r = sqrtl(x * x + y * y);
        v = atan2l(y, x);

        N = N * M_PI / 180.0;
        w = w * M_PI / 180.0;
        i = i * M_PI / 180.0;

        x = r * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
        y = r * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
        z = r * sinl(v + w) * sin(i);

        lon =  atan2l(y, x);
        lat = asinl(z / r);

        x = r * cosl(lon) * cosl(lat);
        y = r * sinl(lon) * cosl(lat);
    z = r * sinl(lat);

    x += SunX;
    y += SunY;

    MarsSolarR = r;
    MarsGeoR = sqrtl(x * x + y * y + z * z);
    
    oblecl = oblecl * M_PI / 180.0;

        rx = x;
        ry = y * cosl(oblecl) - z * sinl(oblecl);
        rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    MarsRA =  atan2l(ry, rx);
         MarsDecl = asinl(rz / MarsGeoR);

    MarsRA = MarsRA * 180.0 / M_PI;
        MarsDecl = MarsDecl * 180 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcJupiter
#
#   Purpose....: Calculate position of jupiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcJupiter()
{
    long double N = rev(100.4542 + 2.76854e-5 * FDiffTime);
    long double i = rev(1.3030 - 1.557e-7 * FDiffTime);
    long double w = rev(273.8777 + 1.64505e-5 * FDiffTime);
    long double a = 5.20256;
    long double e = 0.048498 + 4.469e-9 * FDiffTime;
    long double M = rev(19.8950 + 0.0830853001 * FDiffTime);
        long double E;
        long double x, y, z;
        long double v;
        long double r;
        long double lon, lat;
    long double rx, ry, rz;
        long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;

        M = M * M_PI / 180.0;
        E = M + e * sinl(M) * (1 + e * cosl(M));
        E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

        x = a * (cosl(E) - e);
        y = a * sqrtl(1 - e * e) * sinl(E);

        r = sqrtl(x * x + y * y);
        v = atan2l(y, x);

        N = N * M_PI / 180.0;
        w = w * M_PI / 180.0;
        i = i * M_PI / 180.0;

        x = r * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
        y = r * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
        z = r * sinl(v + w) * sin(i);

        lon =  atan2l(y, x);
        lat = asinl(z / r);

        lon = lon * 180.0 / M_PI;

        lon -= 0.332 * sinl(2.0 * Mj - 5.0 * Ms - 67.6 * M_PI / 180.0);
        lon -= 0.056 * sinl(2.0 * Mj - 2.0 * Ms + 21.0 * M_PI / 180.0);
        lon += 0.042 * sinl(3.0 * Mj - 5.0 * Ms + 21.0 * M_PI / 180.0);
        lon -= 0.036 * sinl(Mj - 2.0 * Ms);
        lon += 0.022 * cosl(Mj - Ms);
        lon += 0.023 * sinl(2.0 * Mj - 3.0 * Ms + 52.0 * M_PI / 180.0);
        lon -= 0.016 * sinl(Mj - 5.0 * Ms - 69.0 * M_PI / 180.0);

    lon = lon * M_PI / 180.0;
    
        x = r * cosl(lon) * cosl(lat);
        y = r * sinl(lon) * cosl(lat);
    z = r * sinl(lat);

    x += SunX;
    y += SunY;

    JupiterSolarR = r;
    JupiterGeoR = sqrtl(x * x + y * y + z * z);
    
    oblecl = oblecl * M_PI / 180.0;

        rx = x;
        ry = y * cosl(oblecl) - z * sinl(oblecl);
        rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    JupiterRA =  atan2l(ry, rx);
         JupiterDecl = asinl(rz / JupiterGeoR);

    JupiterRA = JupiterRA * 180.0 / M_PI;
        JupiterDecl = JupiterDecl * 180 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcSaturn
#
#   Purpose....: Calculate position of saturn
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcSaturn()
{
    long double N = rev(113.6634 + 2.38980e-5 * FDiffTime);
    long double i = rev(2.4886 - 1.081e-7 * FDiffTime);
    long double w = rev(339.3939 + 2.97661e-5 * FDiffTime);
    long double a = 9.55475;
    long double e = 0.055546 - 9.499e-9 * FDiffTime;
    long double M = rev(316.9670 + 0.0334442282 * FDiffTime);   
        long double E;
        long double x, y, z;
        long double v;
        long double r;
        long double lon, lat;
    long double rx, ry, rz;
        long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;

        M = M * M_PI / 180.0;
        E = M + e * sinl(M) * (1 + e * cosl(M));
        E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

        x = a * (cosl(E) - e);
        y = a * sqrtl(1 - e * e) * sinl(E);

        r = sqrtl(x * x + y * y);
        v = atan2l(y, x);

        N = N * M_PI / 180.0;
        w = w * M_PI / 180.0;
        i = i * M_PI / 180.0;

        x = r * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
        y = r * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
        z = r * sinl(v + w) * sin(i);

        lon =  atan2l(y, x);
        lat = asinl(z / r);

        lon = lon * 180.0 / M_PI;
        lat = lat * 180.0 / M_PI;

        lon += 0.812 * sinl(2.0 * Mj - 5.0 * Ms - 67.6 * M_PI / 180.0);
        lon -= 0.229 * cosl(2.0 * Mj - 4.0 * Ms - 2.0 * M_PI / 180.0);
        lon += 0.119 * sinl(Mj - 2.0 * Ms - 3.0 * M_PI / 180.0);
        lon += 0.046 * sinl(2.0 * Mj - 6.0 * Ms - 69.0 * M_PI / 180.0);
        lon += 0.014 * sinl(Mj - 3.0 * Ms + 32.0 * M_PI / 180.0);

        lat -= 0.020 * cosl(2.0 * Mj - 4.0 * Ms - 2.0 * M_PI / 180.0);
        lat += 0.018 * sinl(2.0 * Mj - 6.0 * Ms - 49.0 * M_PI / 180.0);

    lon = lon * M_PI / 180.0;
    lat = lat * M_PI / 180.0;
    
        x = r * cosl(lon) * cosl(lat);
        y = r * sinl(lon) * cosl(lat);
    z = r * sinl(lat);

    x += SunX;
    y += SunY;

    SaturnSolarR = r;
    SaturnGeoR = sqrtl(x * x + y * y + z * z);
    
    oblecl = oblecl * M_PI / 180.0;

        rx = x;
        ry = y * cosl(oblecl) - z * sinl(oblecl);
        rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    SaturnRA =  atan2l(ry, rx);
         SaturnDecl = asinl(rz / SaturnGeoR);

    SaturnRA = SaturnRA * 180.0 / M_PI;
        SaturnDecl = SaturnDecl * 180 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcUranus
#
#   Purpose....: Calculate position of uranus
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcUranus()
{
    long double N = rev(74.0005 + 1.3978e-5 * FDiffTime);
    long double i = rev(0.7733 + 1.9e-8 * FDiffTime);
    long double w = rev(96.6612 + 3.0565e-5 * FDiffTime);
        long double a = 19.18171 - 1.55e-8 * FDiffTime;
    long double e = 0.047318 + 7.45e-9 * FDiffTime;
    long double M = rev(142.5905 + 0.011725806 * FDiffTime);    
        long double E;
        long double x, y, z;
        long double v;
        long double r;
        long double lon, lat;
    long double rx, ry, rz;
        long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;

        M = M * M_PI / 180.0;
        E = M + e * sinl(M) * (1 + e * cosl(M));
        E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

        x = a * (cosl(E) - e);
        y = a * sqrtl(1 - e * e) * sinl(E);

        r = sqrtl(x * x + y * y);
        v = atan2l(y, x);

        N = N * M_PI / 180.0;
        w = w * M_PI / 180.0;
        i = i * M_PI / 180.0;

        x = r * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
        y = r * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
        z = r * sinl(v + w) * sin(i);

        lon =  atan2l(y, x);
        lat = asinl(z / r);

        lon = lon * 180.0 / M_PI;

        lon += 0.040 * sinl(Ms - 2.0 * Mu + 6.0 * M_PI / 180.0);
        lon += 0.035 * sinl(Ms - 3.0 * Mu + 33.0 * M_PI / 180.0);
        lon -= 0.015 * sinl(Mj - Mu + 20.0 * M_PI / 180.0);

        lon = lon * M_PI / 180.0;

        x = r * cosl(lon) * cosl(lat);
        y = r * sinl(lon) * cosl(lat);
    z = r * sinl(lat);

    x += SunX;
    y += SunY;

    UranusSolarR = r;
    UranusGeoR = sqrtl(x * x + y * y + z * z);
    
    oblecl = oblecl * M_PI / 180.0;

        rx = x;
        ry = y * cosl(oblecl) - z * sinl(oblecl);
        rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    UranusRA =  atan2l(ry, rx);
         UranusDecl = asinl(rz / UranusGeoR);

    UranusRA = UranusRA * 180.0 / M_PI;
        UranusDecl = UranusDecl * 180 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcNeptune
#
#   Purpose....: Calculate position of neptune
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcNeptune()
{
        long double N = rev(131.7806 + 3.0173e-5 * FDiffTime);
        long double i = rev(1.7700 - 2.55e-7 * FDiffTime);
        long double w = rev(272.8461 - 6.027e-6 * FDiffTime);
        long double a = 30.05826 + 3.313e-8 * FDiffTime;
        long double e = 0.008606 + 2.15e-9 * FDiffTime;
        long double M = rev(260.2471 + 0.005995147 * FDiffTime);
        long double E;
        long double x, y, z;
        long double v;
        long double r;
        long double lon, lat;
    long double rx, ry, rz;
        long double oblecl = 23.4393 - 3.563e-7 * FDiffTime;

        M = M * M_PI / 180.0;
        E = M + e * sinl(M) * (1 + e * cosl(M));
        E = E - (E - e * sinl(E) - M) / (1 - e * cosl(E));

        x = a * (cosl(E) - e);
        y = a * sqrtl(1 - e * e) * sinl(E);

        r = sqrtl(x * x + y * y);
        v = atan2l(y, x);

        N = N * M_PI / 180.0;
        w = w * M_PI / 180.0;
        i = i * M_PI / 180.0;

        x = r * (cosl(N) * cosl(v + w) - sinl(N) * sinl(v + w) * cosl(i));
        y = r * (sinl(N) * cosl(v + w) + cosl(N) * sinl(v + w) * cosl(i));
        z = r * sinl(v + w) * sin(i);

        lon =  atan2l(y, x);
        lat = asinl(z / r);

        x = r * cosl(lon) * cosl(lat);
        y = r * sinl(lon) * cosl(lat);
    z = r * sinl(lat);

    x += SunX;
    y += SunY;

    NeptuneSolarR = r;
    NeptuneGeoR = sqrtl(x * x + y * y + z * z);
    
    oblecl = oblecl * M_PI / 180.0;

        rx = x;
        ry = y * cosl(oblecl) - z * sinl(oblecl);
        rz = y * sinl(oblecl) + z * cosl(oblecl);
    
    NeptuneRA =  atan2l(ry, rx);
    NeptuneDecl = asinl(rz / NeptuneGeoR);

    NeptuneRA = NeptuneRA * 180.0 / M_PI;
        NeptuneDecl = NeptuneDecl * 180 / M_PI;
}

/*##########################################################################
#
#   Name       : TSolar::CalcPlanets
#
#   Purpose....: Calculate planet positions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::CalcPlanets()
{
    Mj = rev(19.8950 + 0.0830853001 * FDiffTime);
    Ms = rev(316.9670 + 0.0334442282 * FDiffTime);
    Mu = rev(142.5905 + 0.011725806 * FDiffTime);

    Mj = Mj * M_PI / 180.0;
    Ms = Ms * M_PI / 180.0;
    Mu = Mu * M_PI / 180.0;
    
    CalcMercury();
    CalcVenus();
    CalcMars();
    CalcJupiter();
    CalcSaturn();
    CalcUranus();
    CalcNeptune();
}

/*##########################################################################
#
#   Name       : TSolar::GetMercuryPosition
#
#   Purpose....: Get the mercury's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetMercuryPosition(long double *altitude, long double *azimuth)
{
         GetMyPos(MercuryRA, MercuryDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::GetVenusPosition
#
#   Purpose....: Get the venus's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetVenusPosition(long double *altitude, long double *azimuth)
{
         GetMyPos(VenusRA, VenusDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::GetMarsPosition
#
#   Purpose....: Get the mars's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetMarsPosition(long double *altitude, long double *azimuth)
{
         GetMyPos(MarsRA, MarsDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::GetJupiterPosition
#
#   Purpose....: Get the jupiter's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetJupiterPosition(long double *altitude, long double *azimuth)
{
         GetMyPos(JupiterRA, JupiterDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::GetSaturnPosition
#
#   Purpose....: Get the saturn's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetSaturnPosition(long double *altitude, long double *azimuth)
{
         GetMyPos(SaturnRA, SaturnDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::GetUranusPosition
#
#   Purpose....: Get the uranus's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetUranusPosition(long double *altitude, long double *azimuth)
{
         GetMyPos(UranusRA, UranusDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::GetNeptunePosition
#
#   Purpose....: Get the neptune's current position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSolar::GetNeptunePosition(long double *altitude, long double *azimuth)
{
         GetMyPos(NeptuneRA, NeptuneDecl, altitude, azimuth);
}    

/*##########################################################################
#
#   Name       : TSolar::GetMoonPhase
#
#   Purpose....: Get the moons current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetMoonPhase()
{
    long double mlon = MoonLon * M_PI / 180.0;
    long double mlat = MoonLat * M_PI / 180.0;
    long double slon = SunLon * M_PI / 180.0;
    long double elong;
    long double fv;

    elong = acosl(cosl(slon - mlon) * cosl(mlat));
    fv = 180.0 - elong * 180.0 / M_PI;

        return FvToPhase(fv);
}    

/*##########################################################################
#
#   Name       : TSolar::GetMercuryPhase
#
#   Purpose....: Get the mercurys current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetMercuryPhase()
{
        return FvToPhase(GetFv(MercurySolarR, MercuryGeoR));
}    

/*##########################################################################
#
#   Name       : TSolar::GetVenusPhase
#
#   Purpose....: Get the venus current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetVenusPhase()
{
        return FvToPhase(GetFv(VenusSolarR, VenusGeoR));
}    

/*##########################################################################
#
#   Name       : TSolar::GetMarsPhase
#
#   Purpose....: Get the mars current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetMarsPhase()
{
        return FvToPhase(GetFv(MarsSolarR, MarsGeoR));
}    

/*##########################################################################
#
#   Name       : TSolar::GetJupiterPhase
#
#   Purpose....: Get the jupiter current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetJupiterPhase()
{
        return FvToPhase(GetFv(JupiterSolarR, JupiterGeoR));
}    

/*##########################################################################
#
#   Name       : TSolar::GetSaturnPhase
#
#   Purpose....: Get the saturn current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetSaturnPhase()
{
        return FvToPhase(GetFv(SaturnSolarR, SaturnGeoR));
}    

/*##########################################################################
#
#   Name       : TSolar::GetUranusPhase
#
#   Purpose....: Get the uranus current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetUranusPhase()
{
        return FvToPhase(GetFv(UranusSolarR, UranusGeoR));
}    

/*##########################################################################
#
#   Name       : TSolar::GetNeptunePhase
#
#   Purpose....: Get the neptune current phase (0..1)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TSolar::GetNeptunePhase()
{
        return FvToPhase(GetFv(NeptuneSolarR, NeptuneGeoR));
}    
