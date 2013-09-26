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
# convh9.cpp
# Convert exported quiz-h9 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdbh9.h"
#include "convg.h"
#include "es9.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

static int EyeScore[28][4] =
  {
    {45, 36, 0, 24},
    {32, 24, -6, 0},
    {0, 24, 30, 48},
    {-1, 0, -12, 9},
    {5, 0, -4, -12},
    {18, 34, 0, 20},
    {12, 18, 0, 5},
    {0, 1, 6, 39},
    {24, 22, 14, 0},
    {-32, -15, 0, -17},
    {29, 0, 30, 47},
    {31, 6, 19, 0},
    {0, 32, 7, -20},
    {-14, 0, 4, -13},
    {0, -13, 16, -7},
    {0, -2, 6, 25},
    {20, -16, 47, 0},
    {0, 24, 8, 9},
    {18, 18, 10, 0},
    {-8, -2, 0, 14},
    {0, 22, 14, 18},
    {-3, 7, 12, 0},
    {18, 0, -9, 20},
    {0, 34, -2, -17},
    {6, 22, 15, 0},
    {2, 6, 0, 28},
    {10, 8, 0, -25},
    {24, 16, 0, 25}
  };

/*##################  HandleRow ##########################
*   Purpose....: Handle a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    quizfile->Write(Row, sizeof(TQuizRow));

//    printf("H9: %d AS: %d, NT: %d, Eye: %d\r\n", Row->ID, Row->AsResult, Row->NtResult, Row->EyeResult);
    printf("%d\n", Row->EyeResult);
}

/*##################  UpdateScore ##########################
*   Purpose....: Calculate & update a modified score based on current quiz-weights                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void UpdateScore(TQuizRow *row)
{
        int grp;
        int dx;
        int i;
        int val;
        int w;
        int sum;
        int totsum;

        for (grp = 0; grp < 14; grp++)
        {
                sum = 0;
                totsum = 0;

                for (i = 0; i < 145; i++)
                {
                        val = row->Quiz[i];

                        if (val)
                        {
                                w = Gw[i][grp];

                                if (w < 0)
                                {
                                        w = -w;
                                        val = 3 - val;
                                }
                                else
                                        val--;

                                sum += val * w;
                                totsum += 2 * w;
                        }
                }


                if (totsum)
                        row->GroupResult[grp] = 100 * sum / totsum;
                else
                        row->GroupResult[grp] = 0;
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
    int minval, maxval;
    int range;
    int count = 0;
    int year, month, day;
    int hour, min, sec;
    TDateTime *time;
    TQuizRow Row;
    int score = 0;

    Row.EyeUnansw = 0;

    ptr = str;
    for (fieldno = 0; ptr; fieldno++)
    {
        valstr = str;
        ptr = strstr(str, ";");
        if (ptr)
            *ptr = 0;

        str = ptr + 1;

        switch (fieldno)
        {
            case 0:
                Row.ID = atol(valstr);
                break;

            case 1:
                Row.UserID = atol(valstr);
                break;

            case 2:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.LsbTime = time->GetLsb();
                Row.MsbTime = time->GetMsb();
                delete time;
                break;

            case 3:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.FilloutTime = time->GetLsb() - Row.LsbTime;
                delete time;
                break;

            case 4:
                Row.BirthYear = atoi(valstr);
                break;

            case 5:
                Row.BirthMonth = atoi(valstr);
                break;

            case 6:
                Row.Gender = atoi(valstr);
                break;

            case 7:
                Row.Country = atoi(valstr);
                break;

            case 8:
                 Row.Ancestry = atoi(valstr);
                 break;

            case 9:
                 Row.Aspie = atoi(valstr);
                 break;

            case 10:
                 Row.ADHD = atoi(valstr);
                 break;

            case 11:
                 Row.OCD = atoi(valstr);
                 break;

            case 12:
                 Row.Social = atoi(valstr);
                 break;

            case 13:
                 Row.AsResult = atoi(valstr);
                 break;

            case 14:
                 Row.NtResult = atoi(valstr);
                 break;

            case 15:
                 Row.EyeResult = atoi(valstr);
                 break;

            default:
                 i = fieldno - 16;
                 if (i < 28)
                 {
                    val = atoi(valstr);
                    Row.EyeArr[i] = val;

                    minval = maxval = EyeScore[i][0];
                    
                    for (j = 1; j < 4; j++)
                    {
                        if (EyeScore[i][j] > maxval)
                            maxval = EyeScore[i][j];

                        if (EyeScore[i][j] < minval)
                            minval = EyeScore[i][j];
                    }

                    if (val)
                    {
                        j = val - 1;
                    
                        val = EyeScore[i][j];
                        val = val - minval;
                        range = maxval - minval;
                        val = val * 3 / range;
                        if (val == 3)
                            val--;

                        Row.Quiz[150 + i] = val + 1;
                                         
                        score += EyeScore[i][j];
                        count++;
                    }
                    else                                     
                        Row.EyeUnansw++;

                 }
                 else
                    i -= 28;                    

                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    if (count)
    {
        Row.EyeResult = 100 * score / count;

        score = score / count;
        if (score > 3)
            score = 2;
        if (score < 0)
            score = 0;
        score++;
        Row.Quiz[178] = score;

    }
    else
    {
        Row.EyeResult = -1;
        Row.Quiz[178] = 0;
    }

    switch (Row.EyeUnansw)
    {
        case 0:
            Row.Quiz[179] = 1;
            break;

        case 1:
            Row.Quiz[179] = 2;
            break;

        default:
            Row.Quiz[179] = 3;
            break;
    }                
        
    UpdateScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 150);
}

/*################## ConvH9 ##########################
*   Purpose....: Convert quiz h9                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvH9()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-h9.csv");
    TFile outfile("bin\\quizh9.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("H9");

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
    ClosePca();
}
