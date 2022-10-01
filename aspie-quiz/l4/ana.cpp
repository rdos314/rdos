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
  74, 61, 68, 56, 56, 80, 74, 52, 70, 63,
  72, 64, 64, 51, -61, 51, 60, 51, 34, 74,
  64, 74, 68, 83, 79, 68, 78, 69, 72, 65,
  55, 58, -75, 87, 35, -56, -43, 58, 57, 80,
  68, 74, 73, 57, 71, 77, 47, 69, 65, 51,
  54, 68, 61, 62, 51, 65, 80, 85, 78, 60,
  84, 75, 88, 71, 69, 61, 70, 54, 44, 78,
  62, 64, 63, 67, 62, 62, 52, 41, 58, 58,
  58, 61, 56, 43, 27, 35, -48, -45, 19, -29,
  -34, -23, 48, 65, 44, 56, 65, 57, 52, 38,
  43, 43, 62, 86, 76, 51, 49, -48, 71, 61,
  48, -52, 59, 48, -48, 45, 51
};

static int FemaleWeightArr[] =
{
  81, 73, 68, 60, 62, 71, 78, 46, 69, 63,
  69, 64, 51, 47, -56, 51, 59, 49, 52, 63,
  55, 59, 63, 60, 78, 62, 74, 66, 60, 63,
  65, 40, -74, 81, 37, -55, -47, 58, 62, 86,
  80, 86, 79, 61, 79, 79, 46, 78, 71, 63,
  63, 60, 67, 70, 47, 60, 86, 88, 78, 76,
  83, 79, 90, 72, 68, 53, 72, 65, 38, 77,
  68, 73, 71, 74, 63, 60, 62, 40, 60, 68,
  62, 63, 58, 45, 25, 38, -41, -41, 27, -32,
 -33, -21, 48, 58, 45, 52, 62, 47, 48, 39,
  44, 44, 58, 80, 68, 51, 42, -37, 71, 58,
  45, -56, 44, 43, -49, 36, 45
};

static int ScoreArr[] =
{
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  2, 2, 2, 2, 3, 3, 3, 4, 4, 5,
  5, 6, 7, 8, 9, 10, 11, 12, 13, 15,
  16, 18, 20, 22, 24, 26, 28, 30, 33, 36,
  38, 41, 44, 47, 49, 52, 55, 58, 61, 63,
  66, 68, 71, 73, 75, 77, 79, 81, 83, 84,
  86, 87, 88, 89, 90, 91, 92, 93, 94, 94,
  95, 95, 96, 96, 97, 97, 97, 98, 98, 98,
  98, 98, 99, 99, 99, 99, 99, 99, 99, 99,
  99, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100
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

static int MaleArr[201];
static int FemaleArr[201];

static int MaleNdArr[201];
static int MaleNtArr[201];
static int FemaleNdArr[201];
static int FemaleNtArr[201];

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
    int i;

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
static double CalcDiff(double ndu, double ntu, double ndsd, double ntsd, double mndscale, double fndscale, double mntscale, double fntscale)
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

    SubNorm(DiffArr, ndu, ndsd, mndscale);
    SubNorm(DiffArr, ntu, ntsd, mntscale);

    for (i = 0; i < 201; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    for (i = 0; i < 50; i++)
        DiffArr[i] = 0.0;

    for (i = 0; i < 201; i++)
        DiffArr[i+50] = (double)FemaleArr[i];

    for (i = 251; i < 301; i++)
        DiffArr[i] = 0.0;

    SubNorm(DiffArr, ndu, ndsd, fndscale);
    SubNorm(DiffArr, ntu, ntsd, fntscale);

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
    double ndu = 125;
    double ntu = 75;
    double ndsd = 10;
    double ntsd = 10;
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

    diff = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale, fndscale, mntscale, fntscale);

    for (i = 0; i < 8; i++)
    {
        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale + dsc, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                mndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale - dsc, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    mndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale, fndscale + dsc, mntscale, fntscale);
            if (val < diff)
            {
                fndscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale, fndscale - dsc, mntscale, fntscale);
                if (val < diff)
                {
                    fndscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale, fndscale, mntscale + dsc, fntscale);
            if (val < diff)
            {
                mntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale, fndscale, mntscale - dsc, fntscale);
                if (val < diff)
                {
                    mntscale -= dsc;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale, fndscale, mntscale, fntscale + dsc);
            if (val < diff)
            {
                fntscale += dsc;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu, ntu, ndsd, ntsd, mndscale, fndscale, mntscale, fntscale - dsc);
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

            val = CalcDiff(ndu, ntu, ndsd + dsd, ntsd, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                ndsd += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu, ntu, ndsd - dsd, ntsd, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    ndsd -= dsd;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(ndu, ntu, ndsd, ntsd + dsd, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                ntsd += dsd;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu, ntu, ndsd, ntsd - dsd, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    ntsd -= dsd;
                    diff = val;
                    changed = true;
                }
            }
        }

        changed = true;
        while (changed)
        {
            changed = false;

            val = CalcDiff(ndu + du, ntu, ndsd, ntsd, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                ndu += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu - du, ntu, ndsd, ntsd, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    ndu -= du;
                    diff = val;
                    changed = true;
                }
            }

            val = CalcDiff(ndu, ntu + du, ndsd, ntsd, mndscale, fndscale, mntscale, fntscale);
            if (val < diff)
            {
                ntu += du;
                diff = val;
                changed = true;
            }
            else
            {
                val = CalcDiff(ndu, ntu - du, ndsd, ntsd, mndscale, fndscale, mntscale, fntscale);
                if (val < diff)
                {
                    ntu -= du;
                    diff = val;
                    changed = true;
                }
            }
        }

        du = du / 2.0;
        dsc = dsc / 2.0;
        dsd = dsd / 2.0;
    }

    printf("ND u: %d, sd: %d\r\n", (int)ndu, (int)ndsd);
    printf("NT u: %d, sd: %d\r\n", (int)ntu, (int)ntsd);

    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, ndu, ndsd, mndscale);
        MaleNdArr[i] = (int)val;

        val = CalcNorm(x, ntu, ntsd, mntscale);
        MaleNtArr[i] = (int)val;

        x = (double)i;
        val = CalcNorm(x, ndu, ndsd, fndscale);
        FemaleNdArr[i] = (int)val;

        val = CalcNorm(x, ntu, ntsd, fntscale);
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
    char str[80];
    TFile file("item.csv", 0);

    for (i = 0; i < 117; i++)
    {
        sprintf(str, "%d;%d;%d;%d;%d;%d;%d;%d;%d\r\n", i, NdMaleScore[i], NdMaleCount[i], NdFemaleScore[i], NdFemaleCount[i], NtMaleScore[i], NtMaleCount[i], NtFemaleScore[i], NtFemaleCount[i]);
        file.Write(str);
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
    int ndprob;
    int ntprob;
    int sum;
    int score;
    int val;
    int w;

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
                }

                if (Row->Gender == 2)
                {
                    NdFemaleCount[i] += ndprob;
                    NdFemaleScore[i] += ndprob * (Row->Quiz[i] - 1);

                    NtFemaleCount[i] += ntprob;
                    NtFemaleScore[i] += ntprob * (Row->Quiz[i] - 1);
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
}
