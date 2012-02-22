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
# conv3.cpp
# Convert exported quiz-III to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdb3.h"
#include "conv3.h"

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

    printf("III: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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

    static int Asw[100] = {
             13,   13,   10,   12,    9,   12,    9,   16,    9,    4,
              1,    7,    9,    9,    9,    9,    7,    9,   13,   11,
             10,    2,    7,    8,    6,   11,   12,    9,   10,   11,
             11,    8,    5,   10,    9,   12,    9,   13,   13,   10,
              7,    4,    9,   11,   14,   13,   15,   13,   15,    6,
             13,   17,   14,   17,    7,    4,    4,    6,    6,    9,
             13,    9,    7,    2,    2,    3,    4,    7,    5,   13,
             14,   12,   14,   14,    8,   15,   14,   14,   15,   12,
             10,    9,    9,   10,   10,   11,   10,   13,    7,    4,
              6,    6,    7,    3,    3,    4,    5,    6,    3,   14};

    static int Ntw[100] = {
             -4,   -2,    0,    4,   -1,   -1,   -2,    9,    2,   -2,
              0,   -7,   -5,   -5,   -8,   -1,    0,   -5,    2,   -1,
              1,    1,    4,   -1,    4,  -14,  -12,   -8,  -13,  -11,
             -9,  -13,  -10,   -6,   -8,   -9,  -11,   -7,   -2,   -7,
             -6,   -5,   -3,    1,   -7,  -13,   -4,   -3,   -6,   25,
             -2,    8,   -1,    6,   20,   20,   15,   22,   17,   28,
             25,   26,   30,   -2,    1,    2,    2,    8,    7,    0,
             -2,   -1,   -1,    2,   -4,    4,    4,    9,    8,   -7,
			-10,  -10,   -9,   -7,   -4,   -3,   -2,    1,    1,    1,
              8,    2,    9,    0,    3,    3,    6,    5,    1,   18};

	for (i = 0; i < 100; i++)
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

        for (i = 0; i < 100; i++)
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
                Row.Diagnos = atoi(valstr);
                break;

            case 3:
                Row.BirthYear = atoi(valstr);
                break;

            case 4:
                Row.Gender = atoi(valstr);
                break;

            case 5:
                break;

            default:
                i = fieldno - 6;
                Row.Quiz[i] = atoi(valstr);
                break;

        }                    
    }

    UpdateScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], i + 1);
}

/*################## Conv3 ##########################
*   Purpose....: Conv quiz III	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void Conv3()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-III.csv");
    TFile outfile("bin\\quiz3.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("3");

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

