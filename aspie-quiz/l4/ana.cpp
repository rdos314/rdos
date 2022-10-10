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

static int ScoreArr[] =
{
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   1,   1,   1,
    1,   1,   1,   1,   1,   2,   2,   2,   2,   2,
    3,   3,   4,   4,   4,   5,   6,   6,   7,   8,
    9,  10,  11,  12,  14,  15,  17,  18,  20,  22,
   24,  27,  29,  32,  34,  37,  40,  43,  46,  49,
   51,  54,  57,  60,  63,  66,  68,  71,  73,  76,
   78,  80,  82,  83,  85,  86,  88,  89,  90,  91,
   92,  93,  94,  94,  95,  96,  96,  96,  97,  97,
   98,  98,  98,  98,  98,  99,  99,  99,  99,  99,
   99,  99,  99, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100
};

static int NdMaleMean[] =
{
  171, 156, 158, 163, 130, 165, 106, 176, 124,  92,
  123, 133, 166, 161,  60, 163, 110, 160,  48, 160,
  138, 151, 130, 153, 136, 113, 120, 117, 137, 112,
   72, 132,  65, 145,  54,  88, 121, 103,  88, 140,
   89, 104, 108, 173, 106, 127, 177, 101, 106,  75,
   92, 143, 150, 119, 157, 116, 157, 144, 167, 161,
  133, 115, 129, 144, 140, 151, 112, 149,  89, 160,
  157, 116, 103, 107, 152, 126, 107, 157, 150,  98,
   94, 150,  95, 159,  84, 128,  50,  49,  32, 118,
  110,  84, 114, 154, 160,  93, 101, 123, 104,  56,
   85, 170, 149, 139, 155,  73, 175,  41, 147, 107,
  168,  39, 152, 166,  88, 149, 105
};

static int NdFemaleMean[] =
{
  164, 152, 153, 157, 121, 176, 115, 181, 140,  93,
  147, 126, 177, 170,  48, 172, 140, 164,  82, 175,
  151, 171, 138, 179, 153, 141, 149, 136, 159, 135,
  110, 160,  57, 152,  64,  98, 114, 119, 139, 155,
  105, 127, 120, 178, 117, 135, 184, 121, 118,  89,
   91, 168, 137, 132, 163, 152, 153, 141, 165, 148,
  126, 115, 134, 127, 138, 152, 104, 129,  59, 169,
  166, 130, 123, 120, 164, 150, 100, 168, 142, 112,
  121, 152,  85, 162,  72, 120,  45,  46,  52,  78,
  120,  97, 100, 168, 158, 105, 100, 145, 105,  54,
  107, 164, 142, 149, 161,  70, 179,  39, 146, 111,
  170,  45, 168, 159,  89, 143, 108
};

static int NtMaleMean[] =
{
   95,  94,  88, 105,  73,  84,  32, 122,  53,  29,
   51,  69, 100, 109, 122, 111,  51, 108,  14,  84,
   73,  77,  62,  69,  57,  45,  42,  48,  64,  47,
   18,  73, 141,  58,  19, 144, 163,  45,  32,  60,
   23,  30,  36, 114,  36,  49, 128,  32,  41,  25,
   38,  74,  88,  57, 104,  51,  75,  58,  87, 100,
   49,  40,  41,  72,  71,  89,  42,  94,  45,  80,
   94,  52,  40,  39,  89,  64,  55, 115,  91,  40,
   37,  88,  39, 115,  56,  92,  99,  96,  13, 147,
  144, 107,  66,  88, 116,  37,  36,  67,  52,  18,
   43, 125,  86,  53,  78, 130, 125,  90,  75,  46,
  119,  93,  92, 116, 136, 103,  54
};

static int NtFemaleMean[] =
{
   81,  78,  85,  97,  59, 104,  37, 137,  71,  30,
   78,  62, 126, 124, 107, 123,  81, 115,  31, 111,
   97, 112,  75, 119,  74,  80,  75,  70,  99,  73,
   45, 121, 135,  71,  28, 157, 164,  61,  77,  67,
   26,  41,  41, 117,  38,  55, 138,  43,  47,  27,
   28, 109,  70,  61, 117,  91,  66,  52,  85,  71,
   43,  36,  44,  55,  70,  99,  32,  64,  22,  91,
   96,  56,  52,  46, 101,  90,  37, 129,  81,  44,
   59,  88,  27, 117,  48,  81,  90,  91,  26, 112,
  157, 121,  51, 111, 113,  53,  37,  99,  57,  16,
   63, 121,  84,  69,  93, 126, 138,  80,  76,  53,
  126, 105, 125, 117, 142, 108,  64
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
static int NdFemaleCount[117];
static int NdFemaleScore[117];
static int NtMaleCount[117];
static int NtMaleScore[117];
static int NtFemaleCount[117];
static int NtFemaleScore[117];

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
        NdFemaleCount[i] = 0;
        NdFemaleScore[i] = 0;
        NtMaleCount[i] = 0;
        NtMaleScore[i] = 0;
        NtFemaleCount[i] = 0;
        NtFemaleScore[i] = 0;

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
        sprintf(str, "%d;%d;%d;%d;%d;%d;%d;%d\r\n", i,
          NdMaleScore[i], NdMaleCount[i],
          NdFemaleScore[i], NdFemaleCount[i],
          NtMaleScore[i], NtMaleCount[i],
          NtFemaleScore[i], NtFemaleCount[i]);

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

/*
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
*/

                    di = 100 * (Row->Quiz[i] - 1) - NtMaleMean[i];

/*
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
*/
                }

                if (Row->Gender == 2)
                {
                    NdFemaleCount[i] += ndprob;
                    NdFemaleScore[i] += ndprob * (Row->Quiz[i] - 1);

                    NtFemaleCount[i] += ntprob;
                    NtFemaleScore[i] += ntprob * (Row->Quiz[i] - 1);

                    di = 100 * (Row->Quiz[i] - 1) - NdFemaleMean[i];

/*
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
*/

                    di = 100 * (Row->Quiz[i] - 1) - NtFemaleMean[i];

/*
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
*/
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
