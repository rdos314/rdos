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
# convh16.cpp
# Convert exported quiz-h16 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdh16.h"
#include "convg.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

static int IntentScore[6][6] =
  {
    {0, -12, 29, -1, 4, -30},
    {41, 0, 43, 13, 24, -1},
    {-25, -55, 0, -27, -36, -70},
    {26, -6, 14, 0, 11, 3},
    {13, -13, 29, 14, 0, -18},
    {57, -6, 51, 14, 55, 0}
  };

/*##################  HandleRow ##########################
*   Purpose....: Handle a row       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    quizfile->Write(Row, sizeof(TQuizRow));

//    printf("H16: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
    printf("%d\n", Row->Result);
}

/*##################  UpdateScore ##########################
*   Purpose....: Calculate & update a modified score based on current quiz-weights	   					      	        #
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
                Row.CueId = atoi(valstr);
                break;

            case 16:
                Row.CueResult = atoi(valstr);
                break;

            default:
                i = fieldno - 17;
                Row.Quiz[i] = atoi(valstr);
                break;
             
        }
    }

    if (Row.CueResult)
        Row.Result = IntentScore[Row.CueId][Row.CueResult - 1];
    else
        Row.Result = 0;

    for (i = 0; i < 6; i++)
    {
        if (Row.CueResult == i + 1)
            Row.Quiz[150+i] = 2;
        else
            Row.Quiz[150+i] = 1;
    }

    UpdateScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 150);
}

/*################## ConvH16 ##########################
*   Purpose....: Convert quiz h16                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvH16()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-h16.csv");
    TFile outfile("bin\\quizh16.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("H16");

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
