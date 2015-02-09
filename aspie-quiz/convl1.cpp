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
# convl1.cpp
# Convert exported quiz-l1 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdl1.h"

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

    printf("L1: %d AS: %d, NT: %d", Row->ID, Row->AsResult, Row->NtResult);
    printf("\r\n");
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
                 val = atoi(valstr); // your age
                 if (val)
                     Row.HasCatCall = TRUE;
                 else                     
                     Row.HasCatCall = FALSE;

                 if (val != 1)
                     val = 2 + (val - 10) / 5;
                 Row.Quiz[122] = val;
                 break;

            case 16:
                 if (Row.HasCatCall)
                 {
                     val = atoi(valstr); // their age
                     if (val != 1)
                         val = 2 + (val - 10) / 5;
                 }
                 else
                     val = 0;
                 Row.Quiz[123] = val;
                 break;

            case 17:
                 if (Row.HasCatCall)
                     Row.Quiz[124] = atoi(valstr); // catcall guys
                 else
                     Row.Quiz[124] = 0;
                 break;

            case 18:
                 if (Row.HasCatCall)
                     Row.Quiz[125] = 1 + atoi(valstr); // girls
                 else
                     Row.Quiz[125] = 0;
                 break;

            case 19:
                 if (Row.HasCatCall)
                     Row.Quiz[126] = 1 + atoi(valstr); // guys
                 else
                     Row.Quiz[126] = 0;
                 break;

            case 20:
                 if (Row.HasCatCall)
                     Row.Quiz[127] = 1 + atoi(valstr); // they approach
                 else
                     Row.Quiz[127] = 0;
                 break;

            case 21:
                 if (Row.HasCatCall)
                     Row.Quiz[128] = 1 + atoi(valstr); // you approach
                 else
                     Row.Quiz[128] = 0;
                 break;

            case 22:
                 if (Row.HasCatCall)
                     Row.Quiz[129] = atoi(valstr); // scared
                 else
                     Row.Quiz[129] = 0;
                 break;

            case 23:
                 if (Row.HasCatCall)
                     Row.Quiz[130] = atoi(valstr); // disgust
                 else
                     Row.Quiz[130] = 0;
                 break;

            case 24:
                 if (Row.HasCatCall)
                     Row.Quiz[131] = atoi(valstr); // trauma
                 else
                     Row.Quiz[131] = 0;
                 break;

            default:
                 i = fieldno - 25;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 130);
}

/*################## ConvL1 ##########################
*   Purpose....: Convert quiz l1                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvL1()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-l1.csv");
    TFile outfile("bin\\quizl1.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("L1");

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
