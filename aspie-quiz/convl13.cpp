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
#include "quizdl13.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

static int EyeScore[37][4] =
  {
    {66, 28, 23, 0},
    {0, 17, 56, 58},
    {7, -4, 0, 25},
    {76, 52, 0, 25},
    {4, -8, 33, 0},
    {14, 54, 0, 6},
    {0, 23, 8, 62},
    {0, -16, 11, 40},
    {12, 25, 26, 0},
    {54, 39, 32, 0},
    {0, 38, 28, 29},
    {24, 7, 3, 0},
    {0, 20, 18, 49},
    {10, 21, 59, 0},
    {32, 40, 6, 0},
    {-1, -8, 23, 0},
    {0, 40, 8, 5},
    {-5, -56, 31, 0},
    {34, 41, 0, 41},
    {59, -1, 0, 38},
    {0, 16, 44, 64},
    {14, 0, 46, 24},
    {0, 24, 17, 20},
    {12, -2, 24, 0},
    {0, 58, 17, 72},
    {19, 41, 0, 40},
    {29, -26, -19, 0},
    {39, 0, 36, 24},
    {38, 25, 0, 45},
    {15, 34, 19, 0},
    {0, 27, 45, 41},
    {14, 35, 0, 26},
    {31, 21, 34, 0},
    {0, 36, 23, 22},
    {18, 14, 36, 0},
    {0, 18, 30, 48},
    {0, 18, 12, 26}
  };


static int EyeCorrect[37] = {4, 1, 3, 3, 4, 3, 1, 1, 4, 4, 1, 4, 1, 4, 4, 4, 1, 4, 3, 3, 1, 2, 1, 4, 1, 3, 4, 2, 3, 4, 1, 3, 4, 1, 4, 1, 4};

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

    printf("%d", Row->EyeScore);

//    printf("L13: %d AS: %d, NT: %d", Row->ID, Row->AsResult, Row->NtResult);
    printf("\n");
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
    int corr_count = 0;

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

            default:
                 i = fieldno - 15;
                 if (i < 37)
                 {
                    val = atoi(valstr);
                    Row.EyeArr[i] = val;

                    if (EyeCorrect[i] == val)
                        corr_count++;

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

                        Row.Quiz[121 + i] = val + 1;
                                         
                        score += EyeScore[i][j];
                        count++;
                    }
                 }
                 else
                 {
                    i -= 37;                    

                    if (i < 37)
                    {
                        val = atoi(valstr);
                        Row.Quiz[158 + i] = val;
                    }
                    else
                    {
                        i -= 37;                    
                        Row.Quiz[i] = atoi(valstr);
                    }
                 }
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
        Row.Quiz[195] = score;
    }
    else
    {
        Row.EyeResult = -1;
        Row.Quiz[195] = 0;
    }

    Row.EyeScore = corr_count;
        
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 121);
}

/*################## ConvL13 ##########################
*   Purpose....: Convert quiz l13                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvL13()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-l13.csv");
    TFile outfile("bin\\quizl13.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("L13");

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
