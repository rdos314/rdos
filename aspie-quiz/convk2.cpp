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
# convk2.cpp
# Convert exported quiz-k2 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdk2.h"

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

    printf("K2: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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
    int val;
    int year, month, day;
    int hour, min, sec;
    TDateTime *time;
    TQuizRow Row;

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
                 val = atoi(valstr); // place
                 if (val)
                     Row.HasFlashed = TRUE;
                 else                     
                     Row.HasFlashed = FALSE;
                 Row.Quiz[126] = val;
                 break;

            case 16:
                 if (Row.HasFlashed)
                 {
                     val = atoi(valstr); // my age
                     if (val != 1)
                         val = 2 + (val - 10) / 5;
                 }
                 else
                     val = 0;
                 Row.Quiz[127] = val;
                 break;

            case 17:
                 if (Row.HasFlashed)
                 {
                     val = atoi(valstr); // his age
                     val = 1 + (val - 22) / 5;
                 }
                 else
                     val = 0;

                 Row.Quiz[128] = val;
                 break;

            case 18:
                 if (Row.HasFlashed)
                     Row.Quiz[129] = 1 + atoi(valstr); // girls
                 else
                     Row.Quiz[129] = 0;
                 break;

            case 19:
                 if (Row.HasFlashed)
                     Row.Quiz[130] = 1 + atoi(valstr); // guys
                 else
                     Row.Quiz[130] = 0;
                 break;

            case 20:
                 if (Row.HasFlashed)
                     Row.Quiz[131] = atoi(valstr); // time
                 else
                     Row.Quiz[131] = 0;
                 break;

            case 21:
                 if (Row.HasFlashed)
                     Row.Quiz[132] = 1 + atoi(valstr); // he talk
                 else
                     Row.Quiz[132] = 0;
                 break;

            case 22:
                 if (Row.HasFlashed)
                     Row.Quiz[133] = 1 + atoi(valstr); // you talk
                 else
                     Row.Quiz[133] = 0;
                 break;

            case 23:
                 if (Row.HasFlashed)
                     Row.Quiz[134] = 1 + atoi(valstr); // he approach
                 else
                     Row.Quiz[134] = 0;
                 break;

            case 24:
                 if (Row.HasFlashed)
                     Row.Quiz[135] = 1 + atoi(valstr); // you approach
                 else
                     Row.Quiz[135] = 0;
                 break;

            case 25:
                 if (Row.HasFlashed)
                     Row.Quiz[136] = 1 + atoi(valstr); // notify
                 else
                     Row.Quiz[136] = 0;
                 break;

            case 26:
                 if (Row.HasFlashed)
                     Row.Quiz[137] = 1 + atoi(valstr); // report
                 else
                     Row.Quiz[137] = 0;
                 break;

            case 27:
                 if (Row.HasFlashed)
                     Row.Quiz[138] = atoi(valstr); // scared
                 else
                     Row.Quiz[138] = 0;
                 break;

            case 28:
                 if (Row.HasFlashed)
                     Row.Quiz[139] = atoi(valstr); // disgust
                 else
                     Row.Quiz[139] = 0;
                 break;

            case 29:
                 if (Row.HasFlashed)
                     Row.Quiz[140] = atoi(valstr); // trauma
                 else
                     Row.Quiz[140] = 0;
                 break;

            default:
                 i = fieldno - 30;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 141);
}

/*################## ConvK2 ##########################
*   Purpose....: Convert quiz k2                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvK2()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-k2.csv");
    TFile outfile("bin\\quizk2.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("K2");

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
