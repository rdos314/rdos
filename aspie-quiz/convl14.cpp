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
# convl14.cpp
# Convert exported quiz-l14 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdl14.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

static int EyeScore[8][4] =
  {
    {66, 28, 23, 0},
    {76, 58, 52, 0},
    {54, 39, 32, 0},
    {64, 44, 16, 0},
    {47, 30, 29, 0},
    {68, 61, 0, -16},
    {86, 38, 0, -15},
    {94, 0, -2, -6}
  };


static int EyeCorrect[8] = {4, 4, 4, 4, 4, 3, 3, 2};

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

    printf("%d", Row->EyeResult);

//    printf("L14: %d AS: %d, NT: %d", Row->ID, Row->AsResult, Row->NtResult);
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
                 if (i < 8)
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

                        Row.Quiz[144 + i] = val + 1;
                                         
                        score += EyeScore[i][j];
                        count++;
                    }
                 }
                 else
                 {
                    i -= 8;                    

                    if (i < 8)
                    {
                        val = atoi(valstr);
                        Row.Quiz[152 + i] = val;
                    }
                    else
                    {
                        i -= 8;                    
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
        Row.Quiz[160] = score;
    }
    else
    {
        Row.EyeResult = -1;
        Row.Quiz[160] = 0;
    }

    Row.EyeScore = corr_count;
        
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 144);
}

/*################## ConvL14 ##########################
*   Purpose....: Convert quiz l14                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvL14()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-l14.csv");
    TFile outfile("bin\\quizl14.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("L14");

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
