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

static int ScoreArr[] = {
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   2,
    2,   2,   2,   2,   2,   2,   2,   2,   3,   3,
    3,   3,   3,   3,   4,   4,   4,   4,   5,   5,
    5,   6,   6,   6,   7,   7,   7,   8,   8,   9,
    9,  10,  10,  11,  11,  12,  12,  13,  14,  14,
   15,  16,  17,  18,  18,  19,  20,  21,  22,  23,
   24,  25,  27,  28,  29,  30,  31,  33,  34,  35,
   37,  38,  39,  41,  42,  44,  45,  46,  48,  49,
   51,  52,  54,  55,  56,  58,  59,  61,  62,  63,
   65,  66,  67,  69,  70,  71,  72,  73,  75,  76,
   77,  78,  79,  80,  81,  82,  82,  83,  84,  85,
   86,  86,  87,  88,  88,  89,  89,  90,  90,  91,
   91,  92,  92,  93,  93,  93,  94,  94,  94,  95,
   95,  95,  96,  96,  96,  96,  97,  97,  97,  97,
   97,  97,  98,  98,  98,  98,  98,  98,  98,  98,
   98,  99,  99,  99,  99,  99,  99,  99,  99,  99,
   99,  99,  99,  99,  99,  99,  99,  99,  99, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
  100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
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

static int MaleArr[401];
static int FemaleArr[401];
static int MaleNdArr[401];
static int MaleNtArr[401];
static int FemaleNdArr[401];
static int FemaleNtArr[401];

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

    for (i = 0; i < 401; i++)
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

    for (i = 0; i < 601; i++)
    {
        x = (double)(i - 300);
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
    double DiffArr[601];
    double diff = 0;

    for (i = 0; i < 100; i++)
        DiffArr[i] = 0.0;

    for (i = 0; i < 401; i++)
        DiffArr[i+100] = (double)MaleArr[i];

    for (i = 501; i < 601; i++)
        DiffArr[i] = 0.0;

    SubNorm(DiffArr, ndu, ndsd, mndscale);
    SubNorm(DiffArr, ntu, ntsd, mntscale);

    for (i = 0; i < 401; i++)
        diff = diff + DiffArr[i] * DiffArr[i];

    for (i = 0; i < 100; i++)
        DiffArr[i] = 0.0;

    for (i = 0; i < 401; i++)
        DiffArr[i+100] = (double)FemaleArr[i];

    for (i = 501; i < 601; i++)
        DiffArr[i] = 0.0;

    SubNorm(DiffArr, ndu, ndsd, fndscale);
    SubNorm(DiffArr, ntu, ntsd, fntscale);

    for (i = 0; i < 601; i++)
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
    double ndu = 70;
    double ntu = -70;
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

    for (i = 0; i < 401; i++)
        if (MaleArr[i] > maxval)
            maxval = MaleArr[i];

    mndscale = (double)maxval;
    mntscale = (double)maxval;

    maxval = 0;

    for (i = 0; i < 401; i++)
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

    for (i = 0; i < 401; i++)
    {
        x = (double)(i - 200);
        val = CalcNorm(x, ndu, ndsd, mndscale);
        MaleNdArr[i] = (int)val;

        val = CalcNorm(x, ntu, ntsd, mntscale);
        MaleNtArr[i] = (int)val;

        x = (double)(i - 200);
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

    for (i = 0; i < 401; i++)
    {
        sprintf(str, "%d;%d;%d;%d\r\n", i - 200, Arr[i], NdArr[i], NtArr[i]);
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
    int diff = Row->AsResult - Row->NtResult;
    int index = 200 + diff;
    bool use = false;
    int i;
    int ndprob;
    int ntprob;

    if (Missing <= 5 && diff >= -200 && diff <= 200)
        use = true;

    if (use)
    {
        ndprob = ScoreArr[index];
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
            MaleArr[index]++;

        if (Row->Gender == 2)
            FemaleArr[index]++;

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
//    WriteArr();
    WriteItems();
}
