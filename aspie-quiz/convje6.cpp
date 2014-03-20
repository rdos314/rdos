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
# convje6.cpp
# Convert exported quiz-je6 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdje6.h"

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

    printf("JE6: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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
                 Row.Quiz[150] = atoi(valstr);
                 break;

            case 16:
                 val = atoi(valstr);
                 if (val < 5)
                    val = 0;
                 else
                 {
                     if (val < 45)
                        val = 1;
                     else
                     {
                        if (val > 90)
                            val = 3;
                        else
                            val = 2;
                     }
                 }
                 Row.Quiz[151] = val;
                 break;

            case 17:
                 Row.Quiz[152] = atoi(valstr);
                 break;

            case 18:
                 val = atoi(valstr);
                 if (val < 5)
                    val = 0;
                 else
                 {
                     if (val < 45)
                        val = 1;
                     else
                     {
                        if (val > 90)
                            val = 3;
                        else
                            val = 2;
                     }
                 }
                 Row.Quiz[153] = val;
                 break;

            case 19:
                 Row.Quiz[154] = atoi(valstr);
                 break;

            case 20:
                 val = atoi(valstr);
                 if (val < 5)
                    val = 0;
                 else
                 {
                     if (val < 45)
                        val = 1;
                     else
                     {
                        if (val > 90)
                            val = 3;
                        else
                            val = 2;
                     }
                 }
                 Row.Quiz[155] = val;
                 break;

            case 21:
                 Row.Quiz[156] = atoi(valstr);
                 break;

            case 22:
                 val = atoi(valstr);
                 if (val < 5)
                    val = 0;
                 else
                 {
                     if (val < 45)
                        val = 1;
                     else
                     {
                        if (val > 90)
                            val = 3;
                        else
                            val = 2;
                     }
                 }
                 Row.Quiz[157] = val;
                 break;

            default:
                 i = fieldno - 23;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 158);
}

/*################## ConvJE6 ##########################
*   Purpose....: Convert quiz je6                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvJE6()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-je6.csv");
    TFile outfile("bin\\quizje6.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("JE6");

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
