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
# convk9.cpp
# Convert exported quiz-k9 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdk9.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;
static TFile *csvfile;

/*##################  HandleRow ##########################
*   Purpose....: Handle a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    int i;
    char str[80];

    sprintf(str, "%d;", Row->ID);
    csvfile->Write(str);

    sprintf(str, "%d;%d;", Row->BirthYear, Row->BirthMonth);
    csvfile->Write(str);

    sprintf(str, "%d;", Row->Gender);
    csvfile->Write(str);

    sprintf(str, "%d;%d;", Row->Country, Row->Ancestry);
    csvfile->Write(str);

    sprintf(str, "%d;%d;", Row->Aspie, Row->ADHD);
    csvfile->Write(str);

    sprintf(str, "%d;%d;", Row->OCD, Row->Social);
    csvfile->Write(str);

    sprintf(str, "%d;%d;", Row->AsResult, Row->NtResult);
    csvfile->Write(str);
    
    for (i = 0; i < 198; i++)
    {
        if (i == 197)
            sprintf(str, "%d\r\n", Row->Quiz[i]);
        else
            sprintf(str, "%d;", Row->Quiz[i]);
        csvfile->Write(str);
    }
    
    quizfile->Write(Row, sizeof(TQuizRow));

    printf("K9: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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

            case 15: // 3,2,1
            case 19:
            case 24:
            case 26:
            case 28:
            case 34:
            case 35:
            case 38:
            case 39:
                 val = atoi(valstr);
                 switch (val)
                 {
                     case 1:
                        val = 3;
                        break;

                     case 2:
                        val = 2;
                        break;

                     case 3:
                        val = 1;
                        break;
                 }
                 i = fieldno - 15 + 168;
                 Row.Quiz[i] = val;
                 break;

            case 16: // 2,3,1
            case 21:
            case 22:
            case 32:
                 val = atoi(valstr);
                 switch (val)
                 {
                     case 1:
                        val = 2;
                        break;

                     case 2:
                        val = 3;
                        break;

                     case 3:
                        val = 1;
                        break;
                 }
                 i = fieldno - 15 + 168;
                 Row.Quiz[i] = val;
                 break;
                 
            case 17: // 2,1,3
            case 20:
            case 25:
            case 29:
            case 31:
            case 42:
            case 43:
            case 44:
                 val = atoi(valstr);
                 switch (val)
                 {
                     case 1:
                        val = 2;
                        break;

                     case 2:
                        val = 1;
                        break;

                     case 3:
                        val = 3;
                        break;
                 }
                 i = fieldno - 15 + 168;
                 Row.Quiz[i] = val;
                 break;
                 
            case 18: // 1,2,3
            case 23:
            case 27:
            case 37:
            case 40:
            case 41:
                 val = atoi(valstr);
                 i = fieldno - 15 + 168;
                 Row.Quiz[i] = val;
                 break;
                 
                 
            case 30: // 3,1,2
            case 33:
            case 36:
                 val = atoi(valstr);
                 switch (val)
                 {
                     case 1:
                        val = 3;
                        break;

                     case 2:
                        val = 1;
                        break;

                     case 3:
                        val = 2;
                        break;
                 }
                 i = fieldno - 15 + 168;
                 Row.Quiz[i] = val;
                 break;
                 

            default:
                 i = fieldno - 45;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 198);
}

/*################## ConvK9 ##########################
*   Purpose....: Convert quiz k9                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvK9()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-k9.csv");
    TFile outfile("bin\\quizk9.bin", 0);
    TFile rfile("res\\quizk9.csv", 0);
    char *ptr;
    int i;

    csvfile = &rfile;
    csvfile->Write("ID;");
    csvfile->Write("BirthYear;BirthMonth;");
    csvfile->Write("Gender;");
    csvfile->Write("Country;Ancestry;");
    csvfile->Write("AS;ADHD;");
    csvfile->Write("OCD;Social;");
    csvfile->Write("AsResult;NtResult;");
    
    for (i = 0; i < 198; i++)
    {
        if (i == 197)
            sprintf(buf, "F%03d\r\n", i);
        else
            sprintf(buf, "F%03d;", i);
        csvfile->Write(buf);
    }

    quizfile = &outfile;
    OpenPca("K9");

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
