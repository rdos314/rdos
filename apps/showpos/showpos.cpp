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
# showpos.cpp
# Show sun and planetary positions
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "solar.h"

#define FALSE   0
#define TRUE    !FALSE

int main(int argc, char **argv)
{
    long double altitude;
    long double azimuth;
    long double phase;
    int ph;
    TDateTime currtime;

    int i;
    TDateTime time(2008, 12, 29, 0, 0, 0);

    TSolar solar(55, 49, 5, 13, 14, 43);
//  TSolar solar(60, 0, 0, 15, 0, 0);

//  solar.SetTime(TDateTime(1990, 4, 19, 0, 0, 0), 0);
    solar.SetTime(currtime, 1);

    solar.GetSunPosition(&altitude, &azimuth);
    printf("Sun Alt: %5.2Lf, Azi: %5.2Lf\r\n", altitude, azimuth);

    solar.GetMoonPosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetMoonPhase();
    ph = (int)phase;
    printf("Moon Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    solar.GetMercuryPosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetMercuryPhase();
    ph = (int)phase;
    printf("Mercury Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    solar.GetVenusPosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetVenusPhase();
    ph = (int)phase;
    printf("Venus Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    solar.GetMarsPosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetMarsPhase();
    ph = (int)phase;
    printf("Mars Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    solar.GetJupiterPosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetJupiterPhase();
    ph = (int)phase;
    printf("Jupiter Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    solar.GetSaturnPosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetSaturnPhase();
    ph = (int)phase;
    printf("Saturn Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    solar.GetUranusPosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetUranusPhase();
    ph = (int)phase;
    printf("Uranus Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    solar.GetNeptunePosition(&altitude, &azimuth);
    phase = 100.0 * solar.GetNeptunePhase();
    ph = (int)phase;
    printf("Neptune Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

    return 0;
}

