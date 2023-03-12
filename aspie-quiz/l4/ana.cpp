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

static bool HasMean = false;
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

static int CovCount[117][117];
static long long CovSum[117][117];
static long long CovOrg[117][117];
static int CorrArr[117][117];

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
    int ndmss, ndmsc;
    int ndfss, ndfsc;
    int ntmss, ntmsc;
    int ntfss, ntfsc;

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
                ndmss = atoi(valstr);
                break;

            case 2:
                ndmsc = atoi(valstr);
                break;

            case 3:
                ndfss = atoi(valstr);
                break;

            case 4:
                ndfsc = atoi(valstr);
                break;

            case 5:
                ntmss = atoi(valstr);
                break;

            case 6:
                ntmsc = atoi(valstr);
                break;

            case 7:
                ntfss = atoi(valstr);
                break;

            case 8:
                ntfsc = atoi(valstr);
                break;
        }
    }

    if (fieldno == 9)
    {
        NdMaleMean[i] = (double)ndmss / (double)ndmsc;
        NdFemaleMean[i] = (double)ndfss / (double)ndfsc;
        NtMaleMean[i] = (double)ntmss / (double)ntmsc;
        NtFemaleMean[i] = (double)ntfss / (double)ntfsc;
        MaleMean[i] = (double)(ndmss + ntmss) / (double)(ndmsc + ntmsc);
        FemaleMean[i] = (double)(ndfss + ntfss) / (double)(ndfsc + ntfsc);
        Mean[i] = (double)(ndmss + ntmss + ndfss + ntfss) / (double)(ndmsc + ntmsc + ndfsc + ntfsc);
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
static void CalcCorr()
{
    int i,j;
    long long lv;
    int sd[117];
    double dval;

    for (i = 0; i < 117; i++)
    {
        dval = (double)CovSum[i][i] / (double)CovCount[i][i];
        dval = sqrt(dval);
        sd[i] = (int)(10.0 * dval + 0.5);
    }

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            lv = CovSum[i][j];
            lv = lv / sd[i];
            lv = 100 * lv;
            lv = lv / sd[j];
            lv = 100 * lv;
            lv = lv / CovCount[i][j];
            CorrArr[i][j] = lv;
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
    TFile file("corr.csv", 0);

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            if (j == 116)
                sprintf(str, "%d\r\n", CorrArr[i][j]);
            else
                sprintf(str, "%d;", CorrArr[i][j]);

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
    long long lv;
    int sd[117];
    double dval;

    for (i = 0; i < 117; i++)
    {
        dval = (double)CovOrg[i][i] / (double)CovCount[i][i];
        dval = sqrt(dval);
        sd[i] = (int)(10.0 * dval + 0.5);
    }

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            lv = CovOrg[i][j];
            lv = lv / sd[i];
            lv = 100 * lv;
            lv = lv / sd[j];
            lv = 100 * lv;
            lv = lv / CovCount[i][j];
            CorrArr[i][j] = lv;
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
    TFile file("org.csv", 0);

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            if (j == 116)
                sprintf(str, "%d\r\n", CorrArr[i][j]);
            else
                sprintf(str, "%d;", CorrArr[i][j]);

            file.Write(str);
        }
    }
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
    int nddi, ntdi, di, dj;
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

                    nddi = 100 * (Row->Quiz[i] - 1) - NdMaleMean[i];
                    ntdi = 100 * (Row->Quiz[i] - 1) - NtMaleMean[i];

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = 100 * (Row->Quiz[j] - 1) - NdMaleMean[j];
                            ld = nddi;
                            ld = ld * dj * ndprob;
                            CovSum[i][j] += ld;

                            dj = 100 * (Row->Quiz[j] - 1) - NtMaleMean[j];
                            ld = ntdi;
                            ld = ld * dj * ntprob;
                            CovSum[i][j] += ld;

                            CovCount[i][j]++;
                        }
                    }
                }

                if (Row->Gender == 2)
                {
                    NdFemaleCount[i] += ndprob;
                    NdFemaleScore[i] += ndprob * (Row->Quiz[i] - 1);

                    NtFemaleCount[i] += ntprob;
                    NtFemaleScore[i] += ntprob * (Row->Quiz[i] - 1);

                    nddi = 100 * (Row->Quiz[i] - 1) - NdFemaleMean[i];
                    ntdi = 100 * (Row->Quiz[i] - 1) - NtFemaleMean[i];

                    for (j = 0; j < 117; j++)
                    {
                        if (Row->Quiz[j])
                        {
                            dj = 100 * (Row->Quiz[j] - 1) - NdFemaleMean[j];
                            ld = nddi;
                            ld = ld * dj * ndprob;
                            CovSum[i][j] += ld;

                            dj = 100 * (Row->Quiz[j] - 1) - NtFemaleMean[j];
                            ld = ntdi;
                            ld = ld * dj * ntprob;
                            CovSum[i][j] += ld;

                            CovCount[i][j]++;
                        }
                    }
                }

                di = 100 * (Row->Quiz[i] - 1) - Mean[i];

                for (j = 0; j < 117; j++)
                {
                    if (Row->Quiz[j])
                    {
                        dj = 100 * (Row->Quiz[j] - 1) - Mean[j];
                        ld = 100 * di * dj;
                        CovOrg[i][j] += ld;
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
    TFile infile("balanced.csv");
    char *ptr;

    InitArr();

    ReadItems();

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
    CalcCorr();
    WriteCorr();
    CalcOrg();
    WriteOrg();
}
