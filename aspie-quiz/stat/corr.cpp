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

static double ScoreArr[201];
static double NdMaleMean[117];
static double NdFemaleMean[117];
static double NtMaleMean[117];
static double NtFemaleMean[117];
static double MaleMean[117];
static double FemaleMean[117];

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

static int CovCount[117][117];
static double CovSum[117][117];
static double CorrArr[117][117];

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

    for (i = 0; i < 117; i++)
    {
        for (j = 0; j < 117; j++)
        {
            CovCount[i][j] = 0;
            CovSum[i][j] = 0;
        }
    }
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

/*##################  ProcessMean ##########################
*   Purpose....: Process mean                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void ProcessMean(int item, char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i;
    int count = 0;

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
                NdMaleMean[item] = atof(valstr);
                break;

            case 1:
                NdFemaleMean[item] = atof(valstr);
                break;

            case 2:
                NtMaleMean[item] = atof(valstr);
                break;

            case 3:
                NtFemaleMean[item] = atof(valstr);
                break;
        }
    }
}

/*##################  ReadMean ##########################
*   Purpose....: Read mean                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void ReadMean()
{
    int i = 0;
    char *buf;
    int size;
    long pos;
    TFile infile("mean.csv");
    char *ptr;

    buf = new char[MAX_IN_ROW];

    if (infile.IsOpen())
    {
        size = infile.Read(buf, MAX_IN_ROW);
        buf[size] = 0;

        ptr = strchr(buf, 0xd);
        if (ptr)
            *ptr = 0;

        pos = strlen(buf) + 1;
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
            {
                ProcessMean(i, buf);
                i++;
            }
            else
                break;
        }
    }

    delete buf;
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
        if (NdFemaleMean[i] > NtFemaleMean[i])
            invy = false;
        else
            invy = true;

        for (j = 0; j < 117; j++)
        {
            if (NdFemaleMean[j] > NtFemaleMean[j])
                invi = false;
            else
                invi = true;

            if (invy ^ invi)
                val = -CorrArr[i][j];
            else
                val = CorrArr[i][j];

            if (i == j)
            {
                if (j == 116)
                    sprintf(str, "\r\n");
                else
                    sprintf(str, ";");
            }
            else
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

/*##################  HandleRow ##########################
*   Purpose....: Handle a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
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

    for (i = 0; i < 117; i++)
    {
        if (Row->Quiz[i])
        {
            if (Row->Gender == 1)
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

            if (Row->Gender == 2)
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
    }

    printf("%d, Diff: %d\r\n", Row->ID, diff);
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
            case 1:
                Row.Gender = atoi(valstr);
                break;

            case 2:
                 Row.AsResult = atoi(valstr);
                 break;

            case 3:
                 Row.NtResult = atoi(valstr);
                 break;

            default:
                 i = fieldno - 4;
                 Row.Quiz[i] = (double)atoi(valstr);
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
    TFile infile("filt.csv");
    char *ptr;

    InitArr();

    ReadScore();
    ReadMean();

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

     CalcCorr();
     WriteCorr();
}
