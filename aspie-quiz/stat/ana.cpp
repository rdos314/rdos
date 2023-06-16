/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# ana.cpp
# Analyse L4
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

static bool HasMean = false;
static double ScoreArr[201];
static double NdMaleMean[117];
static double NdFemaleMean[117];
static double NtMaleMean[117];
static double NtFemaleMean[117];
static double MaleMean[117];
static double FemaleMean[117];
static double Mean[117];

struct TQuizRow
{
    long ID;
    long UserID;
    int  BirthYear;
    int  BirthMonth;
    int Gender;
    long AsResult;
    long NtResult;
    double Quiz[121];
};

struct TGroup
{
    int FirstItem;
    int LastItem;
};

static TGroup GroupArr[10];

static double NdMaleCount[117];
static double NdMaleScore[117];
static double NdFemaleCount[117];
static double NdFemaleScore[117];
static double NtMaleCount[117];
static double NtMaleScore[117];
static double NtFemaleCount[117];
static double NtFemaleScore[117];

static int GroupCorrCount[10][10];
static double GroupCorrArr[10][10];

static int CovCount[117][117];
static double CovSum[117][117];
static double CovOrg[117][117];
static double CorrArr[117][117];

static int MaleArr[201];
static int FemaleArr[201];

static int MaleDiff[201];
static int FemaleDiff[201];

static double MaleNdArr[201];
static double MaleNtArr[201];
static double FemaleNdArr[201];
static double FemaleNtArr[201];

static double MaleNormArr[201];
static double FemaleNormArr[201];

static double r2pi = sqrt(2.0 * 3.14159265358979323846);

/*##################  InitGroup ##########################
*   Purpose....: Init group arr                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void InitGroup()
{
    GroupArr[0].FirstItem = 0;
    GroupArr[0].LastItem = 4;
    GroupArr[1].FirstItem = 5;
    GroupArr[1].LastItem = 18;
    GroupArr[2].FirstItem = 19;
    GroupArr[2].LastItem = 31;
    GroupArr[3].FirstItem = 32;
    GroupArr[3].LastItem = 38;
    GroupArr[4].FirstItem = 39;
    GroupArr[4].LastItem = 55;
    GroupArr[5].FirstItem = 56;
    GroupArr[5].LastItem = 68;
    GroupArr[6].FirstItem = 69;
    GroupArr[6].LastItem = 85;
    GroupArr[7].FirstItem = 86;
    GroupArr[7].LastItem = 91;
    GroupArr[8].FirstItem = 92;
    GroupArr[8].LastItem = 100;
    GroupArr[9].FirstItem = 101;
    GroupArr[9].LastItem = 116;
}

/*##################  GetGroup ##########################
*   Purpose....: Get group                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int GetGroup(int index)
{
    int i;

    for (i = 0; i < 10; i++)
        if (GroupArr[i].FirstItem <= index && GroupArr[i].LastItem >= index)
            return i;

    return -1;
}

/*##################  InitArr ##########################
*   Purpose....: Init count arr                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void InitArr()
{
    int i, j;

    for (i = 0; i < 201; i++)
    {
        MaleArr[i] = 0;
        FemaleArr[i] = 0;
        MaleDiff[i] = 0;
        FemaleDiff[i] = 0;
    }

    for (i = 0; i < 117; i++)
    {
        NdMaleCount[i] = 0;
        NdMaleScore[i] = 0;
        NdFemaleCount[i] = 0;
        NdFemaleScore[i] = 0;
        NtMaleCount[i] = 0;
        NtMaleScore[i] = 0;
        NtFemaleCount[i] = 0;
        NtFemaleScore[i] = 0;

        for (j = 0; j < 117; j++)
        {
            CovCount[i][j] = 0;
            CovSum[i][j] = 0;
            CovOrg[i][j] = 0;
        }
    }
}

/*##################  CalcNorm ##########################
*   Purpose....: Calculate normal distribution                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static double CalcNorm(double x, double u, double sd, double scale)
{
    double temp;

    temp = (x - u) / sd;
    temp = -0.5 * temp * temp;
    temp = exp(temp);
    temp = temp * scale;

    return temp;
}

/*##################  SubNorm ##########################
*   Purpose....: Subtract a normal distribution                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void SubNorm(double *arr, double u, double sd, double scale)
{
    int i;
    double x;
    double val;

    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, u, sd, scale);
        arr[i] -= val;
    }
}

/*##################  CalcNormDiff ##########################
*   Purpose....: Calculate normal difference                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static double CalcNormDiff(double u, double sd, double mscale, double fscale)
{
    int i;
    double DiffArr[201];
    double diff = 0;

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)MaleArr[i];

    SubNorm(DiffArr, u, sd, mscale);

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)FemaleArr[i];

    SubNorm(DiffArr, u, sd, fscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    return diff;
}

/*##################  CalcDiff ##########################
*   Purpose....: Calculate difference                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static double CalcDiff(double u, double sd, double mndscale, double fndscale, double mntscale, double fntscale)
{
    int i;
    double DiffArr[201];
    double diff = 0;

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)MaleArr[i];

    SubNorm(DiffArr, 100 + u, sd, mndscale);
    SubNorm(DiffArr, 100 - u, sd, mntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)FemaleArr[i];

    SubNorm(DiffArr, 100 + u, sd, fndscale);
    SubNorm(DiffArr, 100 - u, sd, fntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    return diff;
}

/*##################  CalcFullDiff ##########################
*   Purpose....: Calculate full difference                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static double CalcFullDiff(double ul, double sdl, double uh, double sdh, double mndscale, double fndscale, double mntscale, double fntscale)
{
    int i;
    double DiffArr[201];
    double diff = 0;

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)MaleArr[i];

    SubNorm(DiffArr, 100 + uh, sdh, mndscale);
    SubNorm(DiffArr, 100 - ul, sdl, mntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)FemaleArr[i];

    SubNorm(DiffArr, 100 + uh, sdh, fndscale);
    SubNorm(DiffArr, 100 - ul, sdl, fntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    return diff;
}

/*##################  CalcMaleFullDiff ##########################
*   Purpose....: Calculate male full difference                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static double CalcMaleFullDiff(double ul, double sdl, double uh, double sdh, double ndscale, double ntscale)
{
    int i;
    double DiffArr[201];
    double diff = 0;

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)MaleArr[i];

    SubNorm(DiffArr, 100 + uh, sdh, ndscale);
    SubNorm(DiffArr, 100 - ul, sdl, ntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    return diff;
}

/*##################  CalcFemaleFullDiff ##########################
*   Purpose....: Calculate female full difference                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static double CalcFemaleFullDiff(double ul, double sdl, double uh, double sdh, double ndscale, double ntscale)
{
    int i;
    double DiffArr[201];
    double diff = 0;

    for (i = 0; i < 201; i++)
        DiffArr[i] = (double)FemaleArr[i];

    SubNorm(DiffArr, 100 + uh, sdh, ndscale);
    SubNorm(DiffArr, 100 - ul, sdl, ntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    return diff;
}

/*##################  CalcScore ##########################
*   Purpose....: Calculate ND & NT probability                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcScore(double u, double sd)
{
    int i;
    double ndp[201];
    double ntp[201];
    double sum;
    double val;
    double x;
    double scale = 1.0 / sd / r2pi;

    sum = 0.0;
    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, 100 + u, sd, scale);
        sum += val;
        ndp[i] = sum;
    }

    sum = 0.0;
    for (i = 200; i >= 0; i--)
    {
        x = (double)i;
        val = CalcNorm(x, 100 - u, sd, scale);
        sum += val;
        ntp[i] = sum;
    }

    for (i = 0; i < 201; i++)
    {
        sum = ndp[i] + ntp[i];
        ScoreArr[i] = ndp[i] / sum;
    }
}

/*##################  CalcNormDist ##########################
*   Purpose....: Calculate normal distribution params                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcNormDist()
{
    bool changed;
    int i;
    double x;
    int maxval = 0;
    double val;
    double diff;
    double u = 100.0;
    double sd = 30.0;
    double mscale = 0;
    double fscale = 0;
    double dsc = 10;
    double dsd = 10;
    double du = 10;
    int count = 0;

    maxval = 0;

    for (i = 0; i < 201; i++)
    {
        count += MaleArr[i];
        if (MaleArr[i] > maxval)
            maxval = MaleArr[i];
    }

    mscale = (double)maxval;

    maxval = 0;

    for (i = 0; i < 201; i++)
    {
        count += FemaleArr[i];
        if (FemaleArr[i] > maxval)
            maxval = FemaleArr[i];
    }

    fscale = (double)maxval;

    diff = CalcNormDiff(u, sd, mscale, fscale);

    for (i = 0; i < 8; i++)
    {
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcNormDiff(u, sd, mscale + dsc, fscale);
            if (val < diff)
            {
                mscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcNormDiff(u, sd, mscale - dsc, fscale);
                if (val < diff)
                {
                    mscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcNormDiff(u, sd, mscale, fscale + dsc);
            if (val < diff)
            {
                fscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcNormDiff(u, sd, mscale, fscale - dsc);
                if (val < diff)
                {
                    fscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }
        }

        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcNormDiff(u, sd + dsd, mscale, fscale);
            if (val < diff)
            {
                sd += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcNormDiff(u, sd - dsd, mscale, fscale);
                if (val < diff)
                {
                    sd -= dsd;
                    diff = val;
                    changed = true;
                }
            }

        }

        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcNormDiff(u + du, sd, mscale, fscale);
            if (val < diff)
            {
                u += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcNormDiff(u - du, sd, mscale, fscale);
                if (val < diff)
                {
                    u -= du;
                    diff = val;
                    changed = true;
                }
            }
        }

        du = du / 2.0;
        dsc = dsc / 2.0;
        dsd = dsd / 2.0;
    }

    printf("u: %4.2Lf, sd: %4.2Lf\r\n", u, sd);
    printf("diff: %4.2Lf\r\n", diff / (double)count);
    printf("m: %d, f: %d\r\n", (int)mscale, (int)fscale);

    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, u, sd, mscale);
        MaleNormArr[i] = val;

        x = (double)i;
        val = CalcNorm(x, u, sd, fscale);
        FemaleNormArr[i] = val;
    }
}

/*##################  CalcDist ##########################
*   Purpose....: Calculate distribution params                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcDist()
{
    bool changed;
    int i;
    double x;
    int maxval = 0;
    double val;
    double diff;
    double u = 33.2;
    double sd = 28.2;
    double mndscale = 0;
    double mntscale = 0;
    double fndscale = 0;
    double fntscale = 0;
    double dsc = 10;
    double dsd = 10;
    double du = 10;
    int count = 0;

    maxval = 0;

    for (i = 0; i < 201; i++)
    {
        count += MaleArr[i];
        if (MaleArr[i] > maxval)
            maxval = MaleArr[i];
    }

    mndscale = (double)maxval;
    mntscale = (double)maxval;

    maxval = 0;

    for (i = 0; i < 201; i++)
    {
        count += FemaleArr[i];
        if (FemaleArr[i] > maxval)
            maxval = FemaleArr[i];
    }

    fndscale = (double)maxval;
    fntscale = (double)maxval;

    diff = CalcDiff(u, sd, mndscale, fndscale, mntscale, fntscale);

    for (i = 0; i < 8; i++)
    {
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcDiff(u, sd, mndscale + dsc, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                mndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(u, sd, mndscale - dsc, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    mndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(u, sd, mndscale, fndscale + dsc, mntscale, fntscale);
            if (val < diff)
            {
                fndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(u, sd, mndscale, fndscale - dsc, mntscale, fntscale);
                if (val < diff)
                {
                    fndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(u, sd, mndscale, fndscale, mntscale + dsc, fntscale);
            if (val < diff)
            {
                mntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(u, sd, mndscale, fndscale, mntscale - dsc, fntscale);
                if (val < diff)
                {
                    mntscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(u, sd, mndscale, fndscale, mntscale, fntscale + dsc);
            if (val < diff)
            {
                fntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(u, sd, mndscale, fndscale, mntscale, fntscale - dsc);
                if (val < diff)
                {
                    fntscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }
        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcDiff(u, sd + dsd, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                sd += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(u, sd - dsd, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    sd -= dsd;
                    diff = val;
                    changed = true;
                }
            }

        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcDiff(u + du, sd, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                u += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(u - du, sd, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    u -= du;
                    diff = val;
                    changed = true;
                }
            }
        }

        du = du / 2.0;
        dsc = dsc / 2.0;
        dsd = dsd / 2.0;
    }

    printf("u: %4.2Lf, sd: %4.2Lf\r\n", u, sd);
    printf("diff: %4.2Lf\r\n", diff / (double)count);
    printf("ND m: %d, f: %d\r\n", (int)mndscale, (int)fndscale);
    printf("NT m: %d, f: %d\r\n", (int)mntscale, (int)fntscale);

    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, 100 + u, sd, mndscale);
        MaleNdArr[i] = val;

        val = CalcNorm(x, 100 - u, sd, mntscale);
        MaleNtArr[i] = val;

        x = (double)i;
        val = CalcNorm(x, 100 + u, sd, fndscale);
        FemaleNdArr[i] = val;

        val = CalcNorm(x, 100 - u, sd, fntscale);
        FemaleNtArr[i] = val;
    }

    CalcScore(u, sd);
}

/*##################  CalcFullDist ##########################
*   Purpose....: Calculate full distribution params                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcFullDist()
{
    bool changed;
    int i;
    double x;
    int maxval = 0;
    double val;
    double diff;
    double ul, uh;
    double sdl, sdh;
    double mndscale = 0;
    double mntscale = 0;
    double fndscale = 0;
    double fntscale = 0;
    double dsc = 10;
    double dsd = 10;
    double du = 10;
    int count = 0;

    maxval = 0;

    ul = 33.2;
    uh = 33.2;
    sdl = 28.2;
    sdh = 28.2;

    for (i = 0; i < 201; i++)
    {
        count += MaleArr[i];
        if (MaleArr[i] > maxval)
            maxval = MaleArr[i];
    }

    mndscale = (double)maxval;
    mntscale = (double)maxval;

    maxval = 0;

    for (i = 0; i < 201; i++)
    {
        count += FemaleArr[i];
        if (FemaleArr[i] > maxval)
            maxval = FemaleArr[i];
    }

    fndscale = (double)maxval;
    fntscale = (double)maxval;

    diff = CalcFullDiff(ul, sdl, uh, sdh, mndscale, fndscale, mntscale, fntscale);

    for (i = 0; i < 8; i++)
    {
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcFullDiff(ul, sdl, uh, sdh, mndscale + dsc, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                mndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul, sdl, uh, sdh, mndscale - dsc, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    mndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFullDiff(ul, sdl, uh, sdh, mndscale, fndscale + dsc, mntscale, fntscale);
            if (val < diff)
            {
                fndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul, sdl, uh, sdh, mndscale, fndscale - dsc, mntscale, fntscale);
                if (val < diff)
                {
                    fndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFullDiff(ul, sdl, uh, sdh, mndscale, fndscale, mntscale + dsc, fntscale);
            if (val < diff)
            {
                mntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul, sdl, uh, sdh, mndscale, fndscale, mntscale - dsc, fntscale);
                if (val < diff)
                {
                    mntscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFullDiff(ul, sdl, uh, sdh, mndscale, fndscale, mntscale, fntscale + dsc);
            if (val < diff)
            {
                fntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul, sdl, uh, sdh, mndscale, fndscale, mntscale, fntscale - dsc);
                if (val < diff)
                {
                    fntscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }
        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcFullDiff(ul, sdl + dsd, uh, sdh, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                sdl += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul, sdl - dsd, uh, sdh, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    sdl -= dsd;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFullDiff(ul, sdl, uh, sdh + dsd, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                sdh += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul, sdl, uh, sdh - dsd, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    sdh -= dsd;
                    diff = val;
                    changed = true;
                }
            }

        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcFullDiff(ul + du, sdl, uh, sdh, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                ul += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul - du, sdl, uh, sdh, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    ul -= du;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFullDiff(ul, sdl, uh + du, sdh, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                uh += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFullDiff(ul, sdl, uh - du, sdh, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    uh -= du;
                    diff = val;
                    changed = true;
                }
            }
        }

        du = du / 2.0;
        dsc = dsc / 2.0;
        dsd = dsd / 2.0;
    }

    printf("ul: %4.2Lf, sdl: %4.2Lf\r\n", ul, sdl);
    printf("uh: %4.2Lf, sdh: %4.2Lf\r\n", uh, sdh);
    printf("diff: %4.2Lf\r\n", diff / (double)count);
    printf("ND m: %d, f: %d\r\n", (int)mndscale, (int)fndscale);
    printf("NT m: %d, f: %d\r\n", (int)mntscale, (int)fntscale);
}

/*##################  CalcMaleFullDist ##########################
*   Purpose....: Calculate male full distribution params                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcMaleFullDist()
{
    bool changed;
    int i;
    double x;
    int maxval = 0;
    double val;
    double diff;
    double ul, uh;
    double sdl, sdh;
    double ndscale = 0;
    double ntscale = 0;
    double dsc = 10;
    double dsd = 10;
    double du = 10;
    int count = 0;

    maxval = 0;

    ul = 33.2;
    uh = 33.2;
    sdl = 28.2;
    sdh = 28.2;

    for (i = 0; i < 201; i++)
    {
        count += MaleArr[i];
        if (MaleArr[i] > maxval)
            maxval = MaleArr[i];
    }

    ndscale = (double)maxval;
    ntscale = (double)maxval;

    diff = CalcMaleFullDiff(ul, sdl, uh, sdh, ndscale, ntscale);

    for (i = 0; i < 8; i++)
    {
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcMaleFullDiff(ul, sdl, uh, sdh, ndscale + dsc, ntscale);
            if (val < diff)
            {
                ndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcMaleFullDiff(ul, sdl, uh, sdh, ndscale - dsc, ntscale);
                if (val < diff)
                {
                    ndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcMaleFullDiff(ul, sdl, uh, sdh, ndscale, ntscale + dsc);
            if (val < diff)
            {
                ntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcMaleFullDiff(ul, sdl, uh, sdh, ndscale, ntscale - dsc);
                if (val < diff)
                {
                    ntscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }
        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcMaleFullDiff(ul, sdl + dsd, uh, sdh, ndscale, ntscale);
            if (val < diff)
            {
                sdl += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcMaleFullDiff(ul, sdl - dsd, uh, sdh, ndscale, ntscale);
                if (val < diff)
                {
                    sdl -= dsd;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcMaleFullDiff(ul, sdl, uh, sdh + dsd, ndscale, ntscale);
            if (val < diff)
            {
                sdh += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcMaleFullDiff(ul, sdl, uh, sdh - dsd, ndscale, ntscale);
                if (val < diff)
                {
                    sdh -= dsd;
                    diff = val;
                    changed = true;
                }
            }

        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcMaleFullDiff(ul + du, sdl, uh, sdh, ndscale, ntscale);
            if (val < diff)
            {
                ul += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcMaleFullDiff(ul - du, sdl, uh, sdh, ndscale, ntscale);
                if (val < diff)
                {
                    ul -= du;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcMaleFullDiff(ul, sdl, uh + du, sdh, ndscale, ntscale);
            if (val < diff)
            {
                uh += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcMaleFullDiff(ul, sdl, uh - du, sdh, ndscale, ntscale);
                if (val < diff)
                {
                    uh -= du;
                    diff = val;
                    changed = true;
                }
            }
        }

        du = du / 2.0;
        dsc = dsc / 2.0;
        dsd = dsd / 2.0;
    }

    printf("Male\r\n");
    printf("ul: %4.2Lf, sdl: %4.2Lf\r\n", ul, sdl);
    printf("uh: %4.2Lf, sdh: %4.2Lf\r\n", uh, sdh);
    printf("diff: %4.2Lf\r\n", diff / (double)count);
    printf("ND: %d, NT: %d\r\n", (int)ndscale, (int)ntscale);
}

/*##################  CalcFemaleFullDist ##########################
*   Purpose....: Calculate female full distribution params                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcFemaleFullDist()
{
    bool changed;
    int i;
    double x;
    int maxval = 0;
    double val;
    double diff;
    double ul, uh;
    double sdl, sdh;
    double ndscale = 0;
    double ntscale = 0;
    double dsc = 10;
    double dsd = 10;
    double du = 10;
    int count = 0;

    maxval = 0;

    ul = 33.2;
    uh = 33.2;
    sdl = 28.2;
    sdh = 28.2;

    for (i = 0; i < 201; i++)
    {
        count += FemaleArr[i];
        if (FemaleArr[i] > maxval)
            maxval = FemaleArr[i];
    }

    ndscale = (double)maxval;
    ntscale = (double)maxval;

    diff = CalcFemaleFullDiff(ul, sdl, uh, sdh, ndscale, ntscale);

    for (i = 0; i < 8; i++)
    {
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcFemaleFullDiff(ul, sdl, uh, sdh, ndscale + dsc, ntscale);
            if (val < diff)
            {
                ndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFemaleFullDiff(ul, sdl, uh, sdh, ndscale - dsc, ntscale);
                if (val < diff)
                {
                    ndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFemaleFullDiff(ul, sdl, uh, sdh, ndscale, ntscale + dsc);
            if (val < diff)
            {
                ntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFemaleFullDiff(ul, sdl, uh, sdh, ndscale, ntscale - dsc);
                if (val < diff)
                {
                    ntscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }
        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcFemaleFullDiff(ul, sdl + dsd, uh, sdh, ndscale, ntscale);
            if (val < diff)
            {
                sdl += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFemaleFullDiff(ul, sdl - dsd, uh, sdh, ndscale, ntscale);
                if (val < diff)
                {
                    sdl -= dsd;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFemaleFullDiff(ul, sdl, uh, sdh + dsd, ndscale, ntscale);
            if (val < diff)
            {
                sdh += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFemaleFullDiff(ul, sdl, uh, sdh - dsd, ndscale, ntscale);
                if (val < diff)
                {
                    sdh -= dsd;
                    diff = val;
                    changed = true;
                }
            }

        }

//        changed = false;
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcFemaleFullDiff(ul + du, sdl, uh, sdh, ndscale, ntscale);
            if (val < diff)
            {
                ul += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFemaleFullDiff(ul - du, sdl, uh, sdh, ndscale, ntscale);
                if (val < diff)
                {
                    ul -= du;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcFemaleFullDiff(ul, sdl, uh + du, sdh, ndscale, ntscale);
            if (val < diff)
            {
                uh += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcFemaleFullDiff(ul, sdl, uh - du, sdh, ndscale, ntscale);
                if (val < diff)
                {
                    uh -= du;
                    diff = val;
                    changed = true;
                }
            }
        }

        du = du / 2.0;
        dsc = dsc / 2.0;
        dsd = dsd / 2.0;
    }

    printf("Female\r\n");
    printf("ul: %4.2Lf, sdl: %4.2Lf\r\n", ul, sdl);
    printf("uh: %4.2Lf, sdh: %4.2Lf\r\n", uh, sdh);
    printf("diff: %4.2Lf\r\n", diff / (double)count);
    printf("ND: %d, NT: %d\r\n", (int)ndscale, (int)ntscale);
}

/*##################  ReadScore ##########################
*   Purpose....: Read score                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void ReadScore()
{
    int i = 0;
    char *buf;
    int size;
    long pos = 0;
    TFile infile("score.csv");
    char *ptr;

    buf = new char[MAX_IN_ROW];

    if (infile.IsOpen())
    {
        while (size = infile.Read(buf, MAX_IN_ROW))
        {
            buf[size] = 0;
            ptr = strchr(buf, 0xd);
            if (ptr)
                *ptr = 0;

            pos += strlen(buf) + 1;
            infile.SetPos(pos);

            if (ptr)
            {
                ScoreArr[i] = atof(buf);
                i++;
            }
            else
                break;
        }
    }

    delete buf;
}

/*##################  WriteScore ##########################
*   Purpose....: Write score arr                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteScore()
{
    int i;
    char str[80];
    TFile file("score.csv", 0);

    for (i = 0; i < 201; i++)
    {
        sprintf(str, "%5.3Lf\r\n", ScoreArr[i]);
        file.Write(str);
    }
}

/*##################  WriteConv ##########################
*   Purpose....: Write conv arr                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteConv()
{
    int i;
    char str[80];
    TFile file("conv.csv", 0);
    double m, f;

    for (i = 0; i < 201; i++)
    {
        m = (double)MaleDiff[i] / (double)MaleArr[i];
        f = (double)FemaleDiff[i] / (double)FemaleArr[i];
        sprintf(str, "%4.1Lf; %4.1Lf\r\n", m, f);
        file.Write(str);
    }
}

/*##################  WriteArr ##########################
*   Purpose....: Write count arr                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteArr(const char *FileName, int *Arr, double *NdArr, double *NtArr, double *NormArr)
{
    int i;
    char str[80];
    TFile file(FileName, 0);

    for (i = 0; i < 201; i++)
    {
        sprintf(str, "%d;%d;%d;%d;%d\r\n", i, Arr[i], (int)NdArr[i], (int)NtArr[i], (int)NormArr[i]);
        file.Write(str);
    }
}

/*##################  WriteArr ##########################
*   Purpose....: Write count arr                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteArr()
{
    WriteArr("male.csv", MaleArr, MaleNdArr, MaleNtArr, MaleNormArr);
    WriteArr("female.csv", FemaleArr, FemaleNdArr, FemaleNtArr, FemaleNormArr);
}

/*##################  ProcessItem ##########################
*   Purpose....: Process item                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static bool ProcessItem(char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i, j;
    int val;
    int count = 0;
    int score = 0;
    double ndmss, ndmsc;
    double ndfss, ndfsc;
    double ntmss, ntmsc;
    double ntfss, ntfsc;

    str++;

    ptr = str;
    for (fieldno = 0; ptr; fieldno++)
    {
        valstr = str;
        ptr = strstr(str, ";");
        if (ptr)
            *ptr = 0;

        str = ptr + 1;

        if (*valstr == '"')
            valstr++;

        switch (fieldno)
        {
            case 0:
                i = atol(valstr);
                break;

            case 1:
                ndmss = (double)atoi(valstr);
                break;

            case 2:
                ndmsc = (double)atoi(valstr);
                break;

            case 3:
                ndfss = (double)atoi(valstr);
                break;

            case 4:
                ndfsc = (double)atoi(valstr);
                break;

            case 5:
                ntmss = (double)atoi(valstr);
                break;

            case 6:
                ntmsc = (double)atoi(valstr);
                break;

            case 7:
                ntfss = (double)atoi(valstr);
                break;

            case 8:
                ntfsc = (double)atoi(valstr);
                break;
        }
    }

    if (fieldno == 9)
    {
        NdMaleMean[i] = ndmss / ndmsc;
        NdFemaleMean[i] = ndfss / ndfsc;
        NtMaleMean[i] = ntmss / ntmsc;
        NtFemaleMean[i] = ntfss / ntfsc;
        MaleMean[i] = (ndmss + ntmss) / (ndmsc + ntmsc);
        FemaleMean[i] = (ndfss + ntfss) / (ndfsc + ntfsc);
        Mean[i] = (ndmss + ntmss + ndfss + ntfss) / (ndmsc + ntmsc + ndfsc + ntfsc);
        return true;
    }
    else
        return false;
}

/*##################  ReadItems ##########################
*   Purpose....: Read items                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void ReadItems()
{
    int i = 0;
    char *buf;
    int size;
    long pos = 0;
    TFile infile("item.csv");
    char *ptr;

    buf = new char[MAX_IN_ROW];

    if (infile.IsOpen())
    {
        while (size = infile.Read(buf, MAX_IN_ROW))
        {
            buf[size] = 0;
            ptr = strchr(buf, 0xd);
            if (ptr)
                *ptr = 0;

            pos += strlen(buf) + 1;
            infile.SetPos(pos);

            if (ptr)
            {
                if (ProcessItem(buf))
                     i++;
                else
                     break;
            }
        }
    }

    delete buf;

    if (i == 117)
        HasMean = true;
    else
        HasMean = false;
}

/*##################  WriteItems ##########################
*   Purpose....: Write items                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteItems()
{
    int i;
    char str[160];
    TFile file("item.csv", 0);

    for (i = 0; i < 117; i++)
    {
        sprintf(str, "%d;%d;%d;%d;%d;%d;%d;%d;%d\r\n", i,
          (int)NdMaleScore[i], (int)NdMaleCount[i],
          (int)NdFemaleScore[i], (int)NdFemaleCount[i],
          (int)NtMaleScore[i], (int)NtMaleCount[i],
          (int)NtFemaleScore[i], (int)NtFemaleCount[i]);

        file.Write(str);
    }
}

/*##################  CalcCorr ##########################
*   Purpose....: Calc correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcCorr()
{
    int i,j;
    double sd[117];
    double dval;

    for (i = 0; i < 117; i++)
    {
        dval = CovSum[i][i] / (double)CovCount[i][i];
        sd[i] = sqrt(dval);
    }

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            dval = CovSum[i][j];
            dval = dval / sd[i];
            dval = dval / sd[j];
            dval = dval / CovCount[i][j];
            CorrArr[i][j] = dval;
        }
    }
}

/*##################  WriteCorr ##########################
*   Purpose....: Write correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteCorr()
{
    int i, j;
    char str[160];
    bool invy;
    bool invi;
    double val;
    TFile file("corr.csv", 0);

    for (i = 0; i < 117; i++)
    {
//        if (NdFemaleMean[i] > NtFemaleMean[i])
//            invy = false;
//        else
//            invy = true;

        for (j = 0; j < 117; j++)
        {
//            if (NdFemaleMean[j] > NtFemaleMean[j])
//                invi = false;
//            else
//                invi = true;

//            if (invy ^ invi)
//                val = -CorrArr[i][j];
//            else
                val = CorrArr[i][j];

//            if (i == j)
//            {
//                if (j == 116)
//                    sprintf(str, "\r\n");
//                else
//                    sprintf(str, ";");
//            }
//            else
            {
                if (j == 116)
                    sprintf(str, "%5.3Lf\r\n", val);
                else
                    sprintf(str, "%5.3Lf;", val);
            }

            file.Write(str);
        }
    }
}

/*##################  CalcCompGroup ##########################
*   Purpose....: Calc compensated group correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcCompGroup()
{
    int i,j;
    int gi, gj;
    bool ii, ij;
    double dval;

    for (gi = 0; gi < 10; gi++)
    {
        for (gj = 0; gj < 10; gj++)
        {
            GroupCorrCount[gi][gj] = 0;
            GroupCorrArr[gi][gj] = 0.0;
        }
    }

    for (i = 0; i < 117; i++)
    {
        gi = GetGroup(i);
        if (NdMaleMean[i] > NtMaleMean[i])
            ii = false;
        else
            ii = true;

        for (j = 0; j < 117; j++)
        {
            gj = GetGroup(j);
            if (NdFemaleMean[j] > NtFemaleMean[j])
                ij = false;
            else
                ij = true;

            if (i != j)
            {
                if (ii == ij)
                    dval = CorrArr[i][j];
                else
                    dval = -CorrArr[i][j];

                GroupCorrCount[gi][gj]++;
                GroupCorrArr[gi][gj] += dval;
            }
        }
    }
}

/*##################  WriteCompGroup ##########################
*   Purpose....: Write compensated group correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteCompGroup()
{
    int i, j;
    char str[160];
    bool invy;
    bool invi;
    double val;
    TFile file("gcorr.csv", 0);

    for (i = 0; i < 10; i++)
    {
        for (j = 0; j < 10; j++)
        {
            val = GroupCorrArr[i][j] / GroupCorrCount[i][j];
            if (j == 9)
                sprintf(str, "%5.3Lf\r\n", val);
            else
                sprintf(str, "%5.3Lf;", val);
            file.Write(str);
        }
    }
}

/*##################  CalcOrg ##########################
*   Purpose....: Calc non-corrected correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcOrg()
{
    int i,j;
    double sd[117];
    double dval;

    for (i = 0; i < 117; i++)
    {
        dval = CovOrg[i][i] / (double)CovCount[i][i];
        sd[i] = sqrt(dval);
    }

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            dval = CovOrg[i][j];
            dval = dval / sd[i];
            dval = dval / sd[j];
            dval = dval / CovCount[i][j];
            CorrArr[i][j] = dval;
        }
    }
}

/*##################  WriteOrg ##########################
*   Purpose....: Write original correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteOrg()
{
    int i, j;
    char str[160];
    bool invy;
    bool invi;
    double val;
    TFile file("org.csv", 0);

    for (i = 0; i < 117; i++)
    {
//        if (NdFemaleMean[i] > NtFemaleMean[i])
//            invy = false;
//        else
//            invy = true;

        for (j = 0; j < 117; j++)
        {
//            if (NdFemaleMean[j] > NtFemaleMean[j])
//                invi = false;
//            else
//                invi = true;

//            if (invy ^ invi)
//                val = -CorrArr[i][j];
//            else
                val = CorrArr[i][j];

//            if (i == j)
//            {
//                if (j == 116)
//                    sprintf(str, "\r\n");
//                else
//                    sprintf(str, ";");
//            }
//            else
            {
                if (j == 116)
                    sprintf(str, "%5.3Lf\r\n", val);
                else
                    sprintf(str, "%5.3Lf;", val);
            }

            file.Write(str);
        }
    }
}

/*##################  CalcNormGroup ##########################
*   Purpose....: Calc normal group correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcNormGroup()
{
    int i,j;
    int gi, gj;
    bool ii, ij;
    double dval;

    for (gi = 0; gi < 10; gi++)
    {
        for (gj = 0; gj < 10; gj++)
        {
            GroupCorrCount[gi][gj] = 0;
            GroupCorrArr[gi][gj] = 0.0;
        }
    }

    for (i = 0; i < 117; i++)
    {
        gi = GetGroup(i);
        if (NdMaleMean[i] > NtMaleMean[i])
            ii = false;
        else
            ii = true;

        for (j = 0; j < 117; j++)
        {
            gj = GetGroup(j);
            if (NdFemaleMean[j] > NtFemaleMean[j])
                ij = false;
            else
                ij = true;

            if (i != j)
            {
                if (ii == ij)
                    dval = CorrArr[i][j];
                else
                    dval = -CorrArr[i][j];

                GroupCorrCount[gi][gj]++;
                GroupCorrArr[gi][gj] += dval;
            }
        }
    }
}

/*##################  WriteNormGroup ##########################
*   Purpose....: Write normal group correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteNormGroup()
{
    int i, j;
    char str[160];
    bool invy;
    bool invi;
    double val;
    TFile file("gorg.csv", 0);

    for (i = 0; i < 10; i++)
    {
        for (j = 0; j < 10; j++)
        {
            val = GroupCorrArr[i][j] / GroupCorrCount[i][j];
            if (j == 9)
                sprintf(str, "%5.3Lf\r\n", val);
            else
                sprintf(str, "%5.3Lf;", val);
            file.Write(str);
        }
    }
}

/*##################  HandleRow ##########################
*   Purpose....: Handle a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TFile &outfile, TQuizRow *Row)
{
    int diff;
    int i;
    int j;
    double ndprob;
    double ntprob;
    double sum;
    double score;
    double val;
    double w;
    double ld;
    double nddi, ntdi, di, dj;
    char str[40];

    sum = 0.0;
    score = 0.0;

    if (HasMean)
    {
        for (i = 0; i < 117; i++)
        {
            if (Row->Quiz[i])
            {
                if (Row->Gender == 1)
                {
                   w = NdMaleMean[i] - NtMaleMean[i];
                   if (w >= 0)
                       val = Row->Quiz[i] - 1;
                   else
                   {
                       val = 3 - Row->Quiz[i];
                       w = -w;
                   }

                   sum += w;
                   score += val * w;
                }

                if (Row->Gender == 2)
                {
                   w = NdFemaleMean[i] - NtFemaleMean[i];
                   if (w >= 0)
                       val = Row->Quiz[i] - 1;
                   else
                   {
                       val = 3 - Row->Quiz[i];
                       w = -w;
                   }

                   sum += w;
                   score += val * w;
                }
            }
        }
        diff = 100.0 * score / sum;
        ndprob = ScoreArr[diff];
        ntprob = 1.0 - ndprob;
    }
    else
    {
        diff = (Row->AsResult - Row->NtResult) / 2 + 100;

        if (diff >= 35)
        {
           ndprob = 1.0;
           ntprob = 0.0;
        }
        else
        {
            if (diff <= -35)
            {
               ndprob = 0.0;
               ntprob = 1.0;
            }
            else
            {
                ndprob = (double)(diff + 35) / 70.0;
                ntprob = 1.0 - ndprob;
            }
        }
    }

    for (i = 0; i < 117; i++)
    {
        if (Row->Quiz[i])
        {
            if (Row->Gender == 1)
            {
                NdMaleCount[i] += ndprob;
                NdMaleScore[i] += ndprob * (Row->Quiz[i] - 1);

                NtMaleCount[i] += ntprob;
                NtMaleScore[i] += ntprob * (Row->Quiz[i] - 1);

                if (HasMean)
                {
                    nddi = (Row->Quiz[i] - 1) - NdMaleMean[i];
                    ntdi = (Row->Quiz[i] - 1) - NtMaleMean[i];

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = (Row->Quiz[j] - 1) - NdMaleMean[j];
                            ld = nddi;
                            ld = ld * dj * ndprob;
                            CovSum[i][j] += ld;

                            dj = (Row->Quiz[j] - 1) - NtMaleMean[j];
                            ld = ntdi;
                            ld = ld * dj * ntprob;
                            CovSum[i][j] += ld;

                            CovCount[i][j]++;
                        }
                    }
                }
            }

            if (Row->Gender == 2)
            {
                NdFemaleCount[i] += ndprob;
                NdFemaleScore[i] += ndprob * (Row->Quiz[i] - 1);

                NtFemaleCount[i] += ntprob;
                NtFemaleScore[i] += ntprob * (Row->Quiz[i] - 1);

                if (HasMean)
                {
                    nddi = (Row->Quiz[i] - 1) - NdFemaleMean[i];
                    ntdi = (Row->Quiz[i] - 1) - NtFemaleMean[i];

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = (Row->Quiz[j] - 1) - NdFemaleMean[j];
                            ld = nddi;
                            ld = ld * dj * ndprob;
                            CovSum[i][j] += ld;

                            dj = (Row->Quiz[j] - 1) - NtFemaleMean[j];
                            ld = ntdi;
                            ld = ld * dj * ntprob;
                            CovSum[i][j] += ld;

                            CovCount[i][j]++;
                        }
                    }
                }
            }

            if (HasMean)
            {
                di = (Row->Quiz[i] - 1) - Mean[i];

                for (j = 0; j < 117; j++)
                {
                    if (Row->Quiz[j])
                    {
                        dj = (Row->Quiz[j] - 1) - Mean[j];
                        ld = di * dj;
                        CovOrg[i][j] += ld;
                    }
                }
            }
        }
    }

    if (Row->Gender == 1)
    {
        MaleArr[diff]++;
        MaleDiff[diff] += Row->AsResult - Row->NtResult;
    }

    if (Row->Gender == 2)
    {
        FemaleArr[diff]++;
        FemaleDiff[diff] += Row->AsResult - Row->NtResult;
    }

    sprintf(str, "%d;%5.3Lf\r\n", diff, ndprob);
    outfile.Write(str);
    printf("%d, Diff: %d\r\n", Row->ID, diff);
}

/*##################  ProcessRow ##########################
*   Purpose....: Process row                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void ProcessRow(TFile &outfile, char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i;
    int count = 0;
    TQuizRow Row;
    int score = 0;

    str++;

    ptr = str;
    for (fieldno = 0; ptr; fieldno++)
    {
        valstr = str;
        ptr = strstr(str, ";");
        if (ptr)
            *ptr = 0;

        str = ptr + 1;

        if (*valstr == '"')
            valstr++;

        switch (fieldno)
        {
            case 0:
                Row.ID = atol(valstr);
                break;

            case 1:
                Row.BirthYear = atoi(valstr);
                break;

            case 2:
                Row.BirthMonth = atoi(valstr);
                break;

            case 3:
                Row.Gender = atoi(valstr);
                break;

            case 4:
                 Row.AsResult = atoi(valstr);
                 break;

            case 5:
                 Row.NtResult = atoi(valstr);
                 break;

            case 6:
                 break;

            default:
                 i = fieldno - 7;
                 Row.Quiz[i] = (double)atoi(valstr);
                 break;
        }
    }

    HandleRow(outfile, &Row);
}

/*################## main ##########################
*   Purpose....: main                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void main()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("filt.csv");
    TFile outfile("nscore.csv", 0);
    char *ptr;

    InitArr();
    InitGroup();

    ReadItems();
    if (HasMean)
        ReadScore();

    size = infile.Read(buf, MAX_IN_ROW);
    buf[size] = 0;
    ptr = strchr(buf, 0xd);
    if (ptr)
        *ptr = 0;

    pos += strlen(buf) + 1;
    infile.SetPos(pos);

    while (size = infile.Read(buf, MAX_IN_ROW))
    {
        buf[size] = 0;
        ptr = strchr(buf, 0xd);
        if (ptr)
            *ptr = 0;

        pos += strlen(buf) + 1;
        infile.SetPos(pos);

        if (ptr)
            ProcessRow(outfile, buf);
    }
    CalcDist();
    CalcFullDist();
    CalcMaleFullDist();
    CalcFemaleFullDist();
    CalcNormDist();
    WriteArr();
    WriteScore();
    WriteItems();
    WriteConv();

    if (HasMean)
    {
        CalcCorr();
        WriteCorr();
        CalcCompGroup();
        WriteCompGroup();

        CalcOrg();
        WriteOrg();
        CalcNormGroup();
        WriteNormGroup();
    }
}
