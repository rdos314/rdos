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
# convl35.cpp
# Convert exported quiz-l35 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdl36.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

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

    printf("L36: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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
                Row.UserID = atol(valstr);
                break;

            case 2:
                break;

            case 3:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.LsbTime = time->GetLsb();
                Row.MsbTime = time->GetMsb();
                delete time;
                break;

            case 4:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.FilloutTime = time->GetLsb() - Row.LsbTime;
                delete time;
                break;

            case 5:
                Row.BirthYear = atoi(valstr);
                break;

            case 6:
                Row.BirthMonth = atoi(valstr);
                break;

            case 7:
                Row.Gender = atoi(valstr);
                break;

            case 8:
                Row.Country = atoi(valstr);
                break;

            case 9:
                 Row.Ancestry = atoi(valstr);
                 break;

            case 10:
                 Row.Aspie = atoi(valstr);
                 break;

            case 11:
                 Row.ADHD = atoi(valstr);
                 break;

            case 12:
                 Row.OCD = atoi(valstr);
                 break;

            case 13:
                 Row.Social = atoi(valstr);
                 break;

            case 14:
                 break;

            case 15:
                 Row.AsResult = atoi(valstr);
                 break;

            case 16:
                 Row.NtResult = atoi(valstr);
                 break;

            case 17:
                 val = atoi(valstr);

                 if (val)
                 {
                     Row.Quiz[132] = 1;
                     Row.Quiz[133] = 1;
                     Row.Quiz[134] = 1;
                     Row.Quiz[135] = 1;
                     Row.Quiz[136] = 1;
                     Row.Quiz[137] = 1;
                     Row.Quiz[138] = 1;
                     Row.Quiz[139] = 1;
                     Row.Quiz[140] = 1;
                     Row.Quiz[141] = 1;

                     switch (val)
                     {
                         case 2:
                            Row.Quiz[132] = 2;
                            break;

                         case 4:
                            Row.Quiz[133] = 2;
                            break;

                         case 5:
                            Row.Quiz[134] = 2;
                            break;

                         case 6:
                            Row.Quiz[135] = 2;
                            break;

                         case 7:
                            Row.Quiz[136] = 2;
                            break;

                         case 8:
                            Row.Quiz[137] = 2;
                            break;

                         case 9:
                            Row.Quiz[138] = 2;
                            break;

                         case 10:
                            Row.Quiz[139] = 2;
                            break;

                         case 11:
                            Row.Quiz[140] = 2;
                            break;

                         case 14:
                            Row.Quiz[141] = 2;
                            break;
                     }
                 }
                 else
                 {
                     Row.Quiz[132] = 0;
                     Row.Quiz[133] = 0;
                     Row.Quiz[134] = 0;
                     Row.Quiz[135] = 0;
                     Row.Quiz[136] = 0;
                     Row.Quiz[137] = 0;
                     Row.Quiz[138] = 0;
                     Row.Quiz[139] = 0;
                     Row.Quiz[140] = 0;
                     Row.Quiz[141] = 0;
                 }

                 break;

            case 18: // projects
                 Row.Quiz[125] = atoi(valstr);
                 break;

            case 19: // lecture
                 Row.Quiz[126] = atoi(valstr);
                 break;

            case 20: // class
                 Row.Quiz[127] = atoi(valstr);
                 break;

            case 21: // labs
                 Row.Quiz[128] = atoi(valstr);
                 break;

            case 22: // party
                 Row.Quiz[129] = atoi(valstr);
                 break;

            case 23: // friends
                 Row.Quiz[130] = atoi(valstr);
                 break;

            case 24: // network
                 Row.Quiz[131] = atoi(valstr);
                 break;

            default:
                 i = fieldno - 25;
                 if (i < 125)
                     Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 142);
}

/*################## ConvL36 ##########################
*   Purpose....: Convert quiz l36                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvL36()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-l36.csv");
    TFile outfile("bin\\quizl36.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("L36");

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
