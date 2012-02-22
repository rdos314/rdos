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
# conv6.cpp
# Convert exported quiz-6 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdb6.h"
#include "conv6.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

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

    printf("6: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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
	int i;
	int assum = 0;
	int astotsum = 0;
	int ntsum = 0;
	int nttotsum = 0;
	int val;
	int aw;
	int nw;
	int grp;
	int dx;
	int w;
    int sum;
    int totsum;

    static int Asw[162] = {
             12,    7,   14,    9,   10,    6,   11,    6,    8,    3,
              8,    3,    6,    7,    6,    8,    3,    5,   10,    9,
              7,    9,    7,   12,    8,    8,    8,    8,    8,    7,
              7,    5,    9,    9,    6,    6,    8,    8,    9,   11,
             12,   12,   11,    7,    9,   13,   13,   12,    9,   10,
             13,   14,   14,    9,   12,   10,    9,    7,    9,    5,
             10,    8,    8,    9,    5,    7,   11,   11,   10,   13,
             13,    5,    5,   13,   14,    7,    8,    6,   15,    4,
             12,   11,   15,    7,   11,   10,   12,   11,    5,    7,
              7,    6,    6,    5,    9,    9,    5,    4,    7,    8,
              7,    3,   10,    5,    4,    8,    6,    3,    5,   11,
              3,   11,    6,   11,    9,   10,    5,    4,    9,    3,
              5,    2,    5,    6,    4,   10,   10,   10,   10,    9,
             13,   11,    7,    8,    4,    7,    3,    4,    6,    5,
              7,    6,    9,   12,   12,    5,    4,    2,    5,    4,
              0,    0,    1,    1,    0,    1,    0,    1,    1,    1,
              0,    1};

    static int Ntw[162] = {
             -4,   -2,    2,   -2,   -2,   -2,   -3,   -5,   -3,   -2,
             -5,   -3,   -5,   -5,   -6,   -5,   -4,   -4,  -11,   -9,
             19,   18,   -9,   -7,   -9,   -7,   -7,   18,   -7,   16,
             19,   -6,   -4,   -7,   -9,   15,   -6,   -8,   -5,   -2,
             -5,    0,   -4,   -4,   -3,    0,    0,    3,   -2,   -7,
              4,    7,    7,   -7,   -3,   -8,   -9,   -9,   -6,   -5,
             -6,   -4,   -7,   -1,   17,   -6,   -5,   -5,   -6,   -7,
             -3,   14,   22,   -4,   -2,   16,   -7,   15,    0,   13,
             -5,   -3,    2,   17,   -1,   -4,   -4,   -4,   13,   16,
             19,   17,   11,   14,   17,   18,   13,   14,   -6,   -3,
             -5,   -2,    0,   -2,   -1,   -2,   -1,   -1,   -1,    2,
			 11,   -3,   12,    9,    4,    0,   10,    3,   -4,    3,
             10,   -2,    0,   -1,    1,   -8,   -6,   -5,   -2,   21,
             -1,   -1,   12,   -2,    8,   13,   -4,   12,   14,   -4,
             14,   18,    2,   12,    0,    0,   -3,   -1,    0,   -1,
              0,    0,    2,    2,    0,    1,    0,    1,    2,    1,
              0,    1};

	for (i = 0; i < 150; i++)
	{
		if (row->Quiz[i])
		{
			val = row->Quiz[i];
			aw = Asw[i];
			nw = Ntw[i];

            if (aw > 0 && nw > 0)
            {
                if (aw > nw)
                {
                    aw = aw - nw;
                    nw = 0;
                }
                else
                {
                    nw = nw - aw;
                    aw = 0;
                }
            }
		        
			assum += aw * (val - 1);
			astotsum += aw;


			if (nw > 0)
			{
				val--;
				ntsum += nw * val;
				nttotsum += nw;
			}
			else
			{
				val = 3 - val;
				nw = -nw;
				ntsum += nw * val;
				nttotsum += nw;
			}
		}
	}

	row->AsResult = assum * 100 / astotsum;
	row->NtResult = ntsum * 100 / nttotsum;

    for (grp = 0; grp < 14; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 150; i++)
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
*   Purpose....: Process row        	   					      	        #
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
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.LsbTime = time->GetLsb();
                Row.MsbTime = time->GetMsb();
                delete time;
                break;

		    case 2:
				Row.BirthYear = atoi(valstr);
				break;

			case 3:
				Row.Gender = atoi(valstr);
				break;

			case 4:
				Row.Hair = atoi(valstr);
				break;

			case 5:
				Row.Eye = atoi(valstr);
				break;

			case 6:
				Row.Lang = atoi(valstr);
				break;

			case 7:
				Row.Ancestry = atoi(valstr);
				break;

			case 8:
				Row.Autism = atoi(valstr);
				break;

			case 9:
				Row.Aspie = atoi(valstr);
				break;

			case 10:
				Row.ADHD = atoi(valstr);
				break;

			case 11:
				Row.Schizophrenia = atoi(valstr);
				break;

			case 12:
				Row.AsResult = atoi(valstr);
				break;

			case 13:
				Row.NtResult = atoi(valstr);
				break;

			default:
				i = fieldno - 14;
				Row.Quiz[i] = atoi(valstr);
				break;

        }                    
    }

    UpdateScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], i + 1);
}

/*################## Conv6 ##########################
*   Purpose....: Convert quiz 6	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void Conv6()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-6.csv");
    TFile outfile("bin\\quiz6.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("6");

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

