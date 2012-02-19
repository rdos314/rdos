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
# conv5.cpp
# Convert exported quiz-5 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdb5.h"
#include "conv5.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000

void WritePca(TFile *PcaFile, char *ValArr, int Count);

static TFile quizfile("bin\\quiz5.bin", 0);
static TFile pcafile("pca\\quiz5.csv", 0);

/*##################  HandleRow ##########################
*   Purpose....: Handle a row       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    quizfile.Write(Row, sizeof(TQuizRow));

    printf("5: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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

	static int Asw[113] = {
			 12,   12,    7,   14,   11,   10,    9,    6,    3,    6,
			 11,    8,    4,    8,    8,    8,    7,    7,    7,    8,
			  3,    4,   10,    9,    6,    7,    9,   12,    8,    7,
			  6,    8,    8,    9,    8,    9,    9,    6,    6,   12,
			  8,   12,   12,   10,   12,   13,    9,   13,   12,    7,
			 10,   12,   11,    8,    8,    5,   10,    9,    5,   10,
			 12,   13,   13,    7,    8,    6,   14,    4,    6,   12,
			 11,   15,   13,    7,   12,    5,    7,    6,    6,    4,
			  7,    9,    9,    8,    8,    3,    6,    5,    4,   10,
			 10,   13,    6,    8,    5,    8,    4,    8,   11,    7,
			 11,    9,   10,   12,   10,   13,    4,    6,    9,    9,
			  8,    6,    9};

	static int Ntw[113] = {
			 -5,   -3,   -3,    2,   -3,   -2,   -2,   -3,   -2,   -5,
			  0,   -3,   -3,   -4,   -5,    1,   -6,   -6,   -6,   -5,
			 -4,   -4,  -11,   18,   19,   18,   -9,   -7,   -8,   18,
			 16,   -6,   -9,   -9,   -7,   -4,   -7,   15,   -9,   17,
			 17,    0,   -5,   -3,   -3,    0,   -3,    0,    3,   -4,
			 -9,   -8,   -8,    0,   -9,   -5,   -5,   -6,   17,   -6,
             -8,   -7,   -4,   16,   -8,   16,   -3,   13,   15,   -5,
             -3,    3,   -2,   18,   -3,   14,   18,   18,   10,    7,
             22,   21,   -3,   -6,   -4,   -2,    8,   -2,   -1,    0,
             10,    7,   -1,   -1,   -1,    5,    0,   10,   -8,   -7,
             -6,   22,   -2,    0,   -4,   -1,   -4,   12,   -1,    0,
             -2,   13,    7};


	for (i = 0; i < 112; i++)
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

        for (i = 0; i < 112; i++)
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
				Row.Autism = atoi(valstr);
				break;

			case 5:
				Row.Aspie = atoi(valstr);
				break;

			case 6:
				Row.ADHD = atoi(valstr);
				break;

			case 7:
				Row.IQ = atoi(valstr);
				break;

			case 8:
				Row.AsResult = atoi(valstr);
				break;

			case 9:
				Row.NtResult = atoi(valstr);
				break;

			case 10:
				Row.DdResult = atoi(valstr);
				break;

			case 11:
				Row.IqResult = atoi(valstr);
				break;

			default:
				i = fieldno - 12;

				if (i >= 18)
				{
					i -= 18;
					Row.Quiz[i] = atoi(valstr);
				}
				else
					Row.IqArr[i] = atoi(valstr);
				break;

        }                    
    }

    UpdateScore(&Row);
    HandleRow(&Row);
    WritePca(&pcafile, &Row.Quiz[0], i + 1);
}

/*################## Conv5 ##########################
*   Purpose....: Convert quiz 5	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void Conv5()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-5.csv");
    char *ptr;

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
}
