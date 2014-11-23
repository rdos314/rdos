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
# convk6.cpp
# Convert exported quiz-k6 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdk6.h"

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
    int grp;

    quizfile->Write(Row, sizeof(TQuizRow));

    printf("K6: %d AS: %d, NT: %d", Row->ID, Row->AsResult, Row->NtResult);
    
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
    int Age;

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
                 Age = atoi(valstr);
                 break;

            case 16:
                 Row.Quiz[130] = 0;
                 Row.Quiz[131] = 0;
                 Row.Quiz[132] = 0;
                 Row.Quiz[133] = 0;

                 if (Age)
                 {
                     val = atoi(valstr);

                     switch (Age)
                     {
                        case 12:
                        case 13:
                        case 14:
                            Row.Quiz[130] = val;
                            break;

                        case 15:
                        case 16:
                        case 17:
                        case 18:
                        case 19:
                            Row.Quiz[131] = val;
                            break;

                        case 20:
                        case 21:
                        case 22:
                        case 23:
                        case 24:
                            Row.Quiz[132] = val;
                            break;

                        case 25:
                        case 26:
                        case 27:
                        case 28:
                        case 29:
                        case 30:
                            Row.Quiz[133] = val;
                            break;
                    }
                 }
                 break;

            case 17:
                 Row.Quiz[134] = 0;
                 Row.Quiz[135] = 0;
                 Row.Quiz[136] = 0;
                 Row.Quiz[137] = 0;

                 if (Age)
                 {
                     val = atoi(valstr);

                     if (val > 40)
                         val = 40;

                     val = val / 4;

                     switch (Age)
                     {
                        case 12:
                        case 13:
                        case 14:
                            Row.Quiz[134] = val;
                            break;

                        case 15:
                        case 16:
                        case 17:
                        case 18:
                        case 19:
                            Row.Quiz[135] = val;
                            break;

                        case 20:
                        case 21:
                        case 22:
                        case 23:
                        case 24:
                            Row.Quiz[136] = val;
                            break;

                        case 25:
                        case 26:
                        case 27:
                        case 28:
                        case 29:
                        case 30:
                            Row.Quiz[137] = val;
                            break;
                    }
                 }
                 break;

            default:
                 i = fieldno - 18;

                 if (i == 128)
                 {  
                    if (Row.Gender == 1)
                    {
                        Row.Quiz[128] = atoi(valstr);
                        Row.Quiz[129] = 0;
                    }
                    else
                    {
                        Row.Quiz[129] = atoi(valstr);
                        Row.Quiz[128] = 0;
                    }
                 }
                 else
                    Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 138);
}

/*################## ConvK6 ##########################
*   Purpose....: Convert quiz k6                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvK6()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-k6.csv");
    TFile outfile("bin\\quizk6.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("k6");

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
