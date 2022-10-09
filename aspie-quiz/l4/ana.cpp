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

static int MaleWeightArr[] =
{
  76, 62, 69, 58, 56, 81, 73, 54, 70, 62,
  71, 64, 66, 52, -61, 52, 59, 52, 33, 75,
  64, 75, 68, 84, 79, 68, 77, 68, 72, 64,
  54, 58, -75, 87, 35, -56, -42, 58, 56, 80,
  66, 73, 72, 58, 70, 77, 48, 69, 65, 50,
  54, 68, 62, 62, 52, 65, 81, 86, 80, 61,
  83, 75, 87, 71, 69, 62, 69, 55, 44, 79,
  63, 64, 63, 67, 63, 62, 52, 42, 59, 58,
  57, 62, 56, 44, 28, 36, -49, -46, 19, -28,
  -34, -23, 48, 66, 44, 56, 65, 57, 52, 37,
  43, 44, 62, 85, 77, 52, 50, -48, 72, 61,
  49, -53, 60, 49, -48, 46, 50
};

static int FemaleWeightArr[] =
{
  84, 75, 70, 62, 63, 74, 78, 48, 70, 63,
  71, 65, 54, 49, -57, 53, 60, 51, 52, 66,
  56, 61, 64, 62, 79, 63, 76, 67, 61, 64,
  66, 42, -75, 82, 36, -55, -46, 59, 63, 88,
  80, 87, 79, 64, 80, 80, 48, 78, 72, 62,
  63, 62, 68, 72, 48, 62, 88, 90, 81, 77,
  83, 79, 91, 73, 69, 55, 72, 66, 37, 80,
  71, 74, 72, 75, 65, 62, 63, 42, 62, 69,
  63, 66, 58, 47, 26, 40, -43, -42, 27, -32,
  -33, -21, 49, 60, 47, 53, 63, 48, 49, 39,
  45, 45, 59, 81, 70, 53, 44, -38, 72, 59,
  47, -57, 45, 44, -50, 37, 45
};

static int ScoreArr[] =
{
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 2, 2, 2, 2, 3, 3,
  3, 4, 4, 5, 5, 6, 6, 7, 8, 9,
  10, 11, 12, 13, 15, 16, 18, 20, 21, 23,
  25, 28, 30, 32, 35, 38, 40, 43, 46, 49,
  51, 54, 57, 60, 62, 65, 68, 70, 72, 75,
  77, 79, 80, 82, 84, 85, 87, 88, 89, 90,
  91, 92, 93, 94, 94, 95, 95, 96, 96, 97,
  97, 97, 98, 98, 98, 98, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100
};

static int NdMaleMean[] =
{
  171, 155, 157, 162, 129, 165, 105, 176, 124,  91,
  123, 133, 165, 161,  60, 163, 110, 160,  47, 159,
  137, 151, 130, 152, 136, 113, 119, 117, 136, 111,
   71, 132,  66, 144,  53,  88, 121, 103,  88, 140,
   89, 104, 108, 172, 105, 126, 177, 100, 105,  75,
   92, 142, 150, 118, 157, 115, 157, 144, 166, 160,
  133, 114, 128, 144, 140, 151, 111, 149,  89, 159,
  157, 116, 103, 106, 151, 126, 107, 157, 149,  98,
   94, 150,  94, 159,  84, 128,  50,  50,  32, 119,
  110,  84, 114, 154, 160,  93, 101, 123, 104,  56,
   85, 169, 148, 138, 155, 163, 175,  41, 147, 107,
  168,  40, 152, 166,  88, 149, 105
};

static int NdFemaleMean[] =
{
  164, 151, 153, 156, 121, 176, 114, 181, 139,  92,
  147, 126, 177, 170,  48, 172, 139, 164,  82, 174,
  151, 170, 138, 179, 152, 141, 149, 136, 158, 135,
  110, 160,  57, 152,  64,  99, 114, 119, 138, 154,
  105, 126, 119, 178, 116, 134, 183, 121, 117,  89,
   91, 168, 137, 131, 163, 152, 153, 141, 164, 147,
  125, 114, 133, 127, 137, 152, 103, 129,  59, 168,
  165, 129, 123, 119, 164, 150,  99, 168, 141, 112,
  120, 151,  85, 161,  72, 119,  46,  47,  52,  78,
  120,  97,  99, 168, 157, 105,  99, 145, 105,  54,
  106, 164, 142, 148, 161, 172, 179,  40, 146, 110,
  170,  46, 168, 158,  90, 143, 108
};

static int NtMaleMean[] =
{
   95,  94,  88, 105,  73,  84,  32, 122,  53,  29,
   51,  69,  99, 109, 122, 111,  51, 108,  14,  84,
   74,  76,  62,  68,  57,  45,  42,  48,  64,  47,
   18,  73, 141,  58,  19, 144, 163,  45,  32,  60,
   23,  30,  36, 114,  36,  49, 128,  32,  40,  25,
   38,  74,  88,  57, 104,  51,  76,  58,  87, 100,
   50,  40,  41,  72,  71,  89,  42,  94,  45,  80,
   94,  52,  40,  39,  89,  64,  55, 115,  90,  40,
   37,  88,  39, 115,  56,  92,  99,  96,  13, 147,
  144, 107,  66,  88, 116,  37,  36,  67,  52,  18,
   43, 125,  86,  53,  78, 111, 125,  90,  75,  46,
  119,  93,  92, 116, 136, 103,  54
};

static int NtFemaleMean[] =
{
   80,  77,  83,  94,  57, 102,  36, 134,  69,  29,
   76,  61, 124, 121, 105, 119,  80, 113,  30, 109,
   95, 109,  73, 116,  73,  78,  73,  68,  97,  71,
   44, 118, 133,  70,  28, 154, 161,  60,  76,  66,
   25,  40,  40, 114,  37,  54, 135,  42,  45,  26,
   27, 106,  68,  60, 115,  89,  65,  51,  83,  70,
   42,  36,  43,  54,  69,  97,  31,  63,  21,  89,
   94,  55,  50,  44,  98,  88,  36, 126,  79,  43,
   57,  86,  26, 114,  47,  80,  88,  89,  25, 110,
  153, 119,  50, 108, 110,  52,  36,  97,  56,  15,
   62, 118,  83,  67,  91, 119, 135,  78,  74,  52,
  123, 103, 122, 114, 139, 106,  62
};

static int NdMaleSd[] =
{
  54, 67, 65, 59, 81, 60, 82, 51, 79, 81,
  81, 79, 59, 61, 68, 61, 83, 65, 71, 64,
  73, 71, 75, 68, 75, 81, 77, 82, 77, 84,
  80, 75, 72, 68, 73, 74, 78, 78, 83, 77,
  82, 85, 84, 54, 80, 80, 50, 87, 81, 82,
  84, 77, 72, 85, 66, 85, 63, 67, 54, 59,
  76, 79, 73, 71, 69, 65, 84, 72, 82, 64,
  69, 79, 82, 84, 69, 80, 84, 66, 68, 84,
  87, 69, 86, 70, 84, 78, 71, 68, 61, 83,
  79, 76, 79, 65, 59, 80, 80, 72, 79, 68,
  80, 55, 69, 70, 70, 61, 52, 63, 69, 78,
  57, 64, 72, 61, 82, 67, 87
};

static int NdFemaleSd[] =
{
  59, 69, 67, 63, 83, 51, 82, 45, 75, 81,
  73, 80, 49, 54, 61, 54, 76, 62, 84, 52,
  68, 58, 71, 47, 68, 74, 66, 77, 66, 79,
  83, 62, 68, 64, 77, 72, 77, 77, 77, 71,
  84, 82, 83, 49, 79, 77, 43, 85, 80, 85,
  83, 62, 78, 82, 62, 74, 66, 68, 56, 64,
  78, 79, 72, 76, 69, 64, 86, 79, 74, 57,
  63, 76, 80, 84, 62, 71, 84, 58, 70, 84,
  85, 68, 86, 67, 84, 81, 68, 64, 74, 80,
  74, 74, 78, 56, 61, 79, 79, 66, 77, 66,
  79, 58, 71, 66, 65, 54, 48, 59, 69, 77,
  55, 66, 62, 65, 81, 68, 87
};

static int NtMaleSd[] =
{
  78, 82, 80, 76, 82, 77, 60, 75, 72, 57,
  72, 79, 78, 75, 72, 76, 71, 79, 42, 79,
  74, 80, 72, 76, 73, 68, 64, 72, 79, 71,
  46, 76, 71, 69, 48, 67, 63, 65, 60, 76,
  51, 60, 63, 76, 59, 70, 73, 62, 65, 54,
  64, 81, 82, 77, 78, 73, 76, 70, 73, 75,
  70, 64, 62, 77, 73, 73, 67, 81, 69, 78,
  83, 70, 64, 65, 79, 76, 75, 77, 77, 66,
  66, 79, 67, 86, 74, 77, 80, 78, 41, 72,
  71, 74, 73, 75, 72, 61, 61, 70, 68, 43,
  64, 71, 80, 68, 82, 76, 78, 79, 74, 66,
  76, 79, 83, 78, 77, 75, 77
};

static int NtFemaleSd[] =
{
  77, 80, 80, 77, 77, 80, 64, 72, 78, 57,
  81, 77, 76, 74, 72, 76, 81, 79, 61, 80,
  78, 82, 74, 77, 78, 80, 74, 81, 84, 81,
  68, 76, 73, 73, 58, 62, 65, 73, 81, 79,
  55, 67, 66, 78, 61, 73, 72, 70, 68, 56,
  56, 85, 79, 79, 77, 86, 73, 67, 73, 72,
  67, 61, 63, 71, 73, 73, 61, 76, 51, 80,
  84, 72, 71, 70, 81, 82, 65, 76, 76, 68,
  78, 80, 58, 85, 72, 78, 81, 76, 56, 82,
  65, 71, 67, 75, 72, 68, 61, 73, 69, 40,
  71, 72, 79, 73, 83, 76, 76, 76, 75, 69,
  76, 79, 82, 78, 76, 75, 81
};

struct TQuizRow
{
    long ID;
    long UserID;
    int  BirthYear;
    int  BirthMonth;
    int Gender;
    long AsResult;
    long NtResult;
    char Quiz[117];
};

static int NdMaleCount[117];
static int NdMaleScore[117];
static long long NdMaleSdSum[117];
static int NdFemaleCount[117];
static int NdFemaleScore[117];
static long long NdFemaleSdSum[117];
static int NtMaleCount[117];
static int NtMaleScore[117];
static long long NtMaleSdSum[117];
static int NtFemaleCount[117];
static int NtFemaleScore[117];
static long long NtFemaleSdSum[117];

static int NdMaleCorrCount[117][117];
static long long NdMaleCorrScore[117][117];
static int NdFemaleCorrCount[117][117];
static long long NdFemaleCorrScore[117][117];
static int NtMaleCorrCount[117][117];
static long long NtMaleCorrScore[117][117];
static int NtFemaleCorrCount[117][117];
static long long NtFemaleCorrScore[117][117];

static int NdMaleCorr[117][117];
static int NdFemaleCorr[117][117];
static int NtMaleCorr[117][117];
static int NtFemaleCorr[117][117];

static int MaleArr[201];
static int FemaleArr[201];

static int MaleNdArr[201];
static int MaleNtArr[201];
static int FemaleNdArr[201];
static int FemaleNtArr[201];

// static TFile outfile("score.csv", 0);

static double r2pi = sqrt(2.0 * 3.14159265358979323846);

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
    }

    for (i = 0; i < 117; i++)
    {
        NdMaleCount[i] = 0;
        NdMaleScore[i] = 0;
        NdMaleSdSum[i] = 0;
        NdFemaleCount[i] = 0;
        NdFemaleScore[i] = 0;
        NdFemaleSdSum[i] = 0;
        NtMaleCount[i] = 0;
        NtMaleScore[i] = 0;
        NtMaleSdSum[i] = 0;
        NtFemaleCount[i] = 0;
        NtFemaleScore[i] = 0;
        NtFemaleSdSum[i] = 0;

        for (j = 0; j < 117; j++)
        {
            NdMaleCorrCount[i][j] = 0;
            NdMaleCorrScore[i][j] = 0;
            NdFemaleCorrCount[i][j] = 0;
            NdFemaleCorrScore[i][j] = 0;
            NtMaleCorrCount[i][j] = 0;
            NtMaleCorrScore[i][j] = 0;
            NtFemaleCorrCount[i][j] = 0;
            NtFemaleCorrScore[i][j] = 0;
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

    for (i = 0; i < 301; i++)
    {
        x = (double)(i - 50);
        val = CalcNorm(x, u, sd, scale);
        arr[i] -= val;
    }
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
    double DiffArr[301];
    double diff = 0;

    for (i = 0; i < 50; i++)
        DiffArr[i] = 0.0;

    for (i = 0; i < 201; i++)
        DiffArr[i+50] = (double)MaleArr[i];

    for (i = 251; i < 301; i++)
        DiffArr[i] = 0.0;

    SubNorm(DiffArr, 100 + u, sd, mndscale);
    SubNorm(DiffArr, 100 - u, sd, mntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    for (i = 0; i < 50; i++)
        DiffArr[i] = 0.0;

    for (i = 0; i < 201; i++)
        DiffArr[i+50] = (double)FemaleArr[i];

    for (i = 251; i < 301; i++)
        DiffArr[i] = 0.0;

    SubNorm(DiffArr, 100 + u, sd, fndscale);
    SubNorm(DiffArr, 100 - u, sd, fntscale);

    for (i = 0; i < 301; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    return diff;
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
    double u = 35;
    double sd = 27;
    double mndscale = 0;
    double mntscale = 0;
    double fndscale = 0;
    double fntscale = 0;
    double dsc = 10;
    double dsd = 10;
    double du = 10;

    maxval = 0;

    for (i = 0; i < 201; i++)
        if (MaleArr[i] > maxval)
            maxval = MaleArr[i];

    mndscale = (double)maxval;
    mntscale = (double)maxval;

    maxval = 0;

    for (i = 0; i < 201; i++)
        if (MaleArr[i] > maxval)
            maxval = FemaleArr[i];

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

    printf("u: %d, sd: %d\r\n", (int)u, (int)sd);
    printf("ND m: %d, f: %d\r\n", (int)mndscale, (int)fndscale);
    printf("NT m: %d, f: %d\r\n", (int)mntscale, (int)fntscale);

    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, 100 + u, sd, mndscale);
        MaleNdArr[i] = (int)val;

        val = CalcNorm(x, 100 - u, sd, mntscale);
        MaleNtArr[i] = (int)val;

        x = (double)i;
        val = CalcNorm(x, 100 + u, sd, fndscale);
        FemaleNdArr[i] = (int)val;

        val = CalcNorm(x, 100 - u, sd, fntscale);
        FemaleNtArr[i] = (int)val;
    }
}

/*##################  WriteArr ##########################
*   Purpose....: Write count arr                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteArr(const char *FileName, int *Arr, int *NdArr, int *NtArr)
{
    int i;
    char str[80];
    TFile file(FileName, 0);

    for (i = 0; i < 201; i++)
    {
        sprintf(str, "%d;%d;%d;%d\r\n", i, Arr[i], NdArr[i], NtArr[i]);
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
    CalcDist();

    WriteArr("male.csv", MaleArr, MaleNdArr, MaleNtArr);
    WriteArr("female.csv", FemaleArr, FemaleNdArr, FemaleNtArr);
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
        sprintf(str, "%d;%d;%lld;%d;%d;%lld;%d;%d;%lld;%d;%d;%lld;%d\r\n", i,
          NdMaleScore[i], NdMaleSdSum[i], NdMaleCount[i],
          NdFemaleScore[i], NdFemaleSdSum[i], NdFemaleCount[i],
          NtMaleScore[i], NtMaleSdSum[i], NtMaleCount[i],
          NtFemaleScore[i], NtFemaleSdSum[i], NtFemaleCount[i]);

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
static void CalcCorr(long long score[117][117], int count[117][117], long long sdsum[117], int sdcount[117], int res[117][117])
{
    int i,j;
    long long lv;
    int sd[117];
    double dval;

    for (i = 0; i < 117; i++)
    {
        dval = (double)(sdsum[i] / sdcount[i]);
        dval = sqrt(dval);
        sd[i] = (int)(10.0 * dval + 5.0);
    }

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            lv = score[i][j];
            lv = lv / sd[i];
            lv = 1000 * lv;
            lv = lv / sd[j];
            lv = 10 * lv;
            lv = lv / (count[i][j] - 50);
            res[i][j] = lv;
        }
    }
}

/*##################  WriteOneCorr ##########################
*   Purpose....: Write one correlation matrix                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void WriteOneCorr(const char *filename, int corr[117][117])
{
    int i, j;
    char str[160];
    TFile file(filename, 0);

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            if (j == 116)
                sprintf(str, "%d\r\n", corr[i][j]);
            else
                sprintf(str, "%d;", corr[i][j]);

            file.Write(str);
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
    CalcCorr(NdMaleCorrScore, NdMaleCorrCount, NdMaleSdSum, NdMaleCount, NdMaleCorr);
    CalcCorr(NdFemaleCorrScore, NdFemaleCorrCount, NdFemaleSdSum, NdFemaleCount, NdFemaleCorr);
    CalcCorr(NtMaleCorrScore, NtMaleCorrCount, NtMaleSdSum, NtMaleCount, NtMaleCorr);
    CalcCorr(NtFemaleCorrScore, NtFemaleCorrCount, NtFemaleSdSum, NtFemaleCount, NtFemaleCorr);

    WriteOneCorr("condm", NdMaleCorr);
    WriteOneCorr("condf", NdFemaleCorr);
    WriteOneCorr("contm", NtMaleCorr);
    WriteOneCorr("contf", NtFemaleCorr);
}

/*##################  GetMissing ##########################
*   Purpose....: Get missing count                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int GetMissing(TQuizRow *Row)
{
    int i;
    int count = 0;

    for (i = 0; i < 116; i++)
        if (Row->Quiz[i] == 0)
            count++;

    return count;
}

/*##################  HandleRow ##########################
*   Purpose....: Handle a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    int Missing = GetMissing(Row);
    int diff;
    bool use = false;
    int i;
    int j;
    int ndprob;
    int ntprob;
    int sum;
    int score;
    int val;
    int w;
    long long ld;
    int di, dj;
    char str[80];

    if (Missing <= 5 && (Row->Gender == 1 || Row->Gender == 2))
        use = true;

    if (use)
    {
        sum = 0;
        score = 0;

        for (i = 0; i < 117; i++)
        {
            if (Row->Quiz[i])
            {
                if (Row->Gender == 1)
                {
                   w = MaleWeightArr[i];
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
                   w = FemaleWeightArr[i];
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

        diff = 100 * score / sum;

//        sprintf(str, "%d,%d\r\n", Row->AsResult - Row->NtResult, diff);
//        outfile.Write(str);

        ndprob = ScoreArr[diff];
        ntprob = 100 - ndprob;

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

                    di = 100 * (Row->Quiz[i] - 1) - NdMaleMean[i];
                    ld = di;
                    ld = ld * ld * ndprob;
                    NdMaleSdSum[i] += ld;

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = 100 * (Row->Quiz[j] - 1) - NdMaleMean[j];
                            ld = di;
                            ld = ld * dj * ndprob;
                            NdMaleCorrCount[i][j] += ndprob;
                            NdMaleCorrScore[i][j] += ld;
                        }
                    }

                    di = 100 * (Row->Quiz[i] - 1) - NtMaleMean[i];
                    ld = di;
                    ld = ld * ld * ntprob;
                    NtMaleSdSum[i] += ld;

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = 100 * (Row->Quiz[j] - 1) - NtMaleMean[j];
                            ld = di;
                            ld = ld * dj * ntprob;
                            NtMaleCorrCount[i][j] += ntprob;
                            NtMaleCorrScore[i][j] += ld;
                        }
                    }
                }

                if (Row->Gender == 2)
                {
                    NdFemaleCount[i] += ndprob;
                    NdFemaleScore[i] += ndprob * (Row->Quiz[i] - 1);

                    NtFemaleCount[i] += ntprob;
                    NtFemaleScore[i] += ntprob * (Row->Quiz[i] - 1);

                    di = 100 * (Row->Quiz[i] - 1) - NdFemaleMean[i];
                    ld = di;
                    ld = ld * ld * ndprob;
                    NdFemaleSdSum[i] += ld;

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = 100 * (Row->Quiz[j] - 1) - NdFemaleMean[j];
                            ld = di;
                            ld = ld * dj * ndprob;
                            NdFemaleCorrCount[i][j] += ndprob;
                            NdFemaleCorrScore[i][j] += ld;
                        }
                    }

                    di = 100 * (Row->Quiz[i] - 1) - NtFemaleMean[i];
                    ld = di;
                    ld = ld * ld * ntprob;
                    NtFemaleSdSum[i] += ld;

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = 100 * (Row->Quiz[j] - 1) - NtFemaleMean[j];
                            ld = di;
                            ld = ld * dj * ntprob;
                            NtFemaleCorrCount[i][j] += ntprob;
                            NtFemaleCorrScore[i][j] += ld;
                        }
                    }
                }
            }
        }

        if (Row->Gender == 1)
            MaleArr[diff]++;

        if (Row->Gender == 2)
            FemaleArr[diff]++;

        printf("L4: %d, Diff: %d\r\n", Row->ID, diff);
    }
}

/*##################  ProcessRow ##########################
*   Purpose....: Process row                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void ProcessRow(char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i, j;
    int val;
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

            default:
                 i = fieldno - 6;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    HandleRow(&Row);
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
    TFile infile("l4.csv");
    char *ptr;

    InitArr();

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
            ProcessRow(buf);
    }
    WriteArr();
    WriteItems();
    WriteCorr();
}
