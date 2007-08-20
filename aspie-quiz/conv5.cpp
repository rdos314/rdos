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

#include "file.h"
#include "quizdb5.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-5 VALUES (";

TFile quizfile("quiz5.bin", 0);

static int Gw[113][8] = 
{
    {43, 66, 52, 40, 50, 56, 47, 51},
    {44, 67, 52, 42, 44, 59, 51, 50},
    {33, 44, 35, 24, 32, 42, 42, 35},
    {37, 56, 48, 32, 41, 54, 46, 44},
    {35, 62, 44, 33, 43, 54, 44, 45},
    {38, 61, 40, 32, 39, 52, 40, 40},
    {27, 56, 40, 24, 27, 42, 35, 33},
    {32, 42, 36, 24, 31, 40, 46, 34},
    {30, 56, 40, 26, 29, 43, 38, 32},
    {37, 45, 34, 34, 35, 48, 47, 41},
    {31, 47, 31, 27, 29, 47, 32, 28},
    {33, 57, 38, 29, 34, 44, 35, 34},
    {28, 43, 32, 27, 27, 40, 44, 34},
    {30, 44, 36, 27, 35, 42, 33, 37},
    {37, 50, 42, 35, 37, 49, 42, 42},
    {13, 39, 35, 15, 23, 33, 31, 25},
    {58, 52, 38, 36, 38, 51, 47, 47},
    {57, 39, 32, 30, 37, 39, 32, 44},
    {52, 39, 33, 42, 39, 44, 36, 45},
    {52, 43, 29, 37, 35, 45, 38, 43},
    {53, 36, 26, 28, 29, 34, 29, 37},
    {44, 44, 35, 29, 27, 40, 37, 35},
    {48, 49, 49, 43, 60, 58, 51, 72},
    {-38, -35, -29, -34, -51, -43, -31, -69},
    {-44, -33, -36, -32, -64, -45, -34, -72},
    {-38, -23, -22, -27, -53, -36, -27, -68},
    {37, 40, 42, 32, 49, 49, 44, 61},
    {44, 53, 53, 45, 58, 62, 52, 65},
    {42, 51, 55, 39, 52, 59, 47, 61},
    {-38, -31, -30, -29, -56, -41, -32, -69},
    {-35, -29, -21, -29, -48, -38, -24, -63},
    {40, 49, 43, 33, 45, 53, 39, 59},
    {40, 42, 39, 36, 47, 50, 48, 58},
    {40, 51, 50, 40, 53, 58, 50, 67},
    {40, 48, 38, 37, 44, 46, 39, 53},
    {37, 52, 50, 33, 39, 54, 44, 53},
    {37, 39, 31, 48, 43, 46, 42, 54},
    {-30, -21, -19, -26, -50, -32, -24, -60},
    {40, 42, 42, 35, 43, 51, 46, 63},
    {-31, -28, -20, -31, -38, -34, -27, -49},
    {-35, -28, -30, -26, -49, -38, -29, -65},
    {30, 51, 63, 27, 43, 48, 42, 46},
    {36, 52, 59, 38, 52, 58, 46, 55},
    {31, 47, 52, 16, 38, 50, 36, 42},
    {30, 43, 58, 29, 51, 52, 40, 50},
    {26, 48, 60, 20, 39, 49, 40, 40},
    {22, 37, 52, 16, 32, 39, 29, 33},
    {26, 47, 59, 24, 37, 47, 38, 38},
    {17, 37, 57, 8, 28, 36, 29, 29},
    {23, 38, 46, 7, 32, 41, 35, 38},
    {37, 46, 49, 38, 53, 58, 46, 54},
    {45, 57, 51, 49, 53, 67, 52, 60},
    {50, 57, 46, 52, 58, 67, 53, 59},
    {19, 36, 38, 15, 20, 36, 29, 22},
    {39, 53, 47, 37, 50, 62, 46, 53},
    {38, 49, 36, 29, 31, 51, 41, 35},
    {36, 51, 46, 33, 48, 56, 39, 45},
    {34, 49, 47, 29, 44, 58, 44, 49},
    {-40, -39, -35, -31, -64, -43, -33, -58},
    {39, 42, 40, 33, 60, 49, 37, 55},
    {43, 54, 58, 39, 65, 62, 45, 61},
    {42, 43, 45, 40, 65, 54, 44, 63},
    {39, 52, 48, 36, 59, 57, 42, 53},
    {-38, -34, -34, -34, -57, -43, -33, -57},
    {38, 49, 43, 32, 55, 52, 42, 53},
    {-34, -34, -30, -22, -68, -32, -25, -51},
    {40, 51, 54, 35, 55, 58, 40, 51},
    {-41, -38, -31, -26, -55, -39, -24, -42},
    {-35, -29, -23, -35, -52, -35, -27, -46},
    {34, 41, 44, 32, 64, 50, 36, 54},
    {40, 46, 43, 33, 42, 52, 41, 46},
    {25, 38, 45, 23, 49, 46, 33, 40},
    {41, 54, 45, 41, 47, 63, 45, 48},
    {-25, -29, -31, -20, -56, -32, -23, -43},
    {30, 43, 48, 30, 52, 52, 45, 51},
    {-14, -11, -19, -10, -45, -14, -14, -29},
    {-13, -11, -10, -9, -40, -7, -7, -22},
    {-9, -16, -22, -12, -43, -15, -13, -29},
    {-14, -6, -7, -7, -40, -6, -7, -31},
    {-8, -7, -6, -4, -36, -5, -3, -22},
    {-15, -20, -18, -14, -51, -21, -13, -28},
    {-11, -16, -15, -8, -38, -11, -9, -20},
    {24, 32, 24, 45, 26, 41, 33, 33},
    {42, 42, 37, 48, 37, 46, 41, 46},
    {29, 33, 26, 46, 32, 37, 33, 37},
    {30, 32, 19, 42, 20, 32, 32, 23},
    {-20, -5, 2, -30, -19, -8, -9, -20},
    {31, 29, 17, 46, 16, 32, 31, 23},
    {15, 19, 11, 32, 11, 19, 25, 14},
    {29, 24, 21, 38, 16, 31, 27, 23},
    {-12, -4, 10, -29, -12, -7, -5, -17},
    {6, 9, 13, -19, 0, 0, 0, 0},
    {28, 21, 10, 45, 14, 25, 20, 20},
    {26, 30, 16, 46, 24, 34, 25, 27},
    {29, 25, 9, 45, 14, 28, 21, 17},
    {-10, -3, 17, -29, 4, -3, 0, 3},
    {9, 12, 6, 30, 10, 17, 14, 11},
    {-14, -5, 6, -32, -17, -10, -10, -22},
    {46, 49, 40, 55, 47, 57, 46, 58},
    {36, 50, 39, 30, 53, 48, 38, 51},
    {46, 51, 39, 51, 45, 61, 45, 55},
    {-35, -33, -34, -34, -56, -40, -35, -62},
    {25, 40, 32, 24, 26, 38, 27, 32},
    {29, 43, 38, 30, 33, 51, 36, 41},
    {35, 48, 39, 42, 35, 50, 39, 41},
    {32, 41, 33, 42, 37, 47, 33, 41},
    {31, 39, 31, 35, 29, 42, 45, 41},
    {-27, -25, -20, -17, -38, -29, -18, -39},
    {21, 33, 42, 9, 27, 35, 24, 32},
    {20, 26, 15, 21, 13, 30, 25, 23},
    {31, 40, 34, 28, 29, 42, 36, 32},
    {-31, -35, -24, -29, -39, -41, -23, -42},
    {-14, -17, 4, -22, 5, -12, -13, 0}
};

/*##################  HandleRow ##########################
*   Purpose....: Handle a row       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void HandleRow(TQuizRow *Row)
{
    int grp;

	quizfile.Write(Row, sizeof(TQuizRow));

	printf("%d AS: %d, NT: %d, [", Row->ID, Row->AsResult, Row->NtResult);

	for (grp = 0; grp < 8; grp++)
	{
	    printf("%d", Row->GroupResult[grp]);
	    if (grp != 7)
	        printf(", ");
	}

	printf("], Ref: %s\n", Row->Referer);
}

/*##################  UpdateReferer ##########################
*   Purpose....: UpdateReferer    	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char *UpdateReferer(char *Referer)
{
	char *ptr;
	 const char http[] = "http://";
	 const char www[] = "www.";
	char str[10];

	ptr = strchr(Referer, '&');
	if (ptr)
		*ptr = 0;

	memcpy(str, Referer, strlen(http));
	str[strlen(http)] = 0;

	if (!strcmp(str, http))
		Referer += strlen(http);

	memcpy(str, Referer, strlen(www));
	str[strlen(www)] = 0;

	if (!strcmp(str, www))
		Referer += strlen(www);

	return Referer;
}

/*##################  GetQuoted ##########################
*   Purpose....: Get quoted string    	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char *GetQuoted(char *str)
{
	char *ptr;
	char *res;

	res = strchr(str, 0x27);
	if (res)
	{
		res++;
		ptr = strchr(res, 0x27);
		if (ptr)
		{
			*ptr = 0;
			return res;
		}
	}
	return 0;
}

/*##################  UpdateScore ##########################
*   Purpose....: Calculate & update a modified score based on current quiz-weights	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void UpdateScore(TQuizRow *row)
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

    for (grp = 0; grp < 8; grp++)
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

                sum += val * w * w;
				totsum += 2 * w * w;
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
void ProcessRow(char *str)
{
	char *valstr;
	char *ptr;
	int fieldno;
	int i;
	TQuizRow Row;
	int quote;

	for (fieldno = 0; fieldno < 143; fieldno++)
	{
		valstr = str;

		quote = FALSE;
		ptr = str;
		while (*ptr && (quote || *ptr != ','))
		{
			if (*ptr == 0x27)
				quote = !quote;

			ptr++;
		}

		if (*ptr == ',')
		{
			*ptr = 0;
			str = ptr + 1;

			switch (fieldno)
			{
				case 0:
					Row.ID = atol(valstr);
					break;

				case 1:
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
					valstr = GetQuoted(valstr);
					if (valstr)
					{
						valstr = UpdateReferer(valstr);
						if (strlen(valstr) >= 100)
							valstr[99] = 0;
						strcpy(Row.Referer, valstr);
					}
					else
						Row.Referer[0] = 0;
					break;

				case 9:
					Row.AsResult = atoi(valstr);
					break;

				case 10:
					Row.NtResult = atoi(valstr);
					break;

				case 11:
					Row.DdResult = atoi(valstr);
					break;

				case 12:
					Row.IqResult = atoi(valstr);
					Row.Quiz[112] = Row.IqResult;
					break;

				default:
					i = fieldno - 13;

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
	}

    UpdateScore(&Row);
	HandleRow(&Row);
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	TFile infile("quiz5.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 112; i++)
	{
	    max = 0;

        for (grp = 0; grp < 8; grp++)
        {        
            w = Gw[i][grp];
            w = w * w;
			if (w > max)
				max = w;
		}

		for (grp = 0; grp < 8; grp++)
		{
			if (max)
			{
				w = Gw[i][grp];
				w = w * w / max;

				if (w >= 0.64)
					Gw[i][grp] = (int)((long double)Gw[i][grp] * w);
				else
					Gw[i][grp] = 0;
			}
			else
				Gw[i][grp] = 0;

		}
	}

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		rowstr = strstr(buf, InsertString);
		if (rowstr)
		{
			rowstr += strlen(InsertString);
			ptr = strstr(rowstr, ")");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
			ProcessRow(rowstr);
	}
}

