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
# convr5.cpp
# Convert exported quiz-r5 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr5.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r5 VALUES(";

TFile quizfile("quizr5.bin", 0);

static int Gw[144][8] = 
{
    {25, 36, 32, 30, 29, 39, 32, 33},
    {-40, -23, -32, -35, -40, -44, -46, -45},
    {-40, -10, -21, -29, -38, -26, -24, -43},
    {-14, -4, 4, -6, -6, -11, -11, -14},
    {-44, -23, -20, -36, -31, -33, -31, -40},
    {55, 34, 30, 33, 35, 38, 38, 40},
    {35, 62, 51, 39, 47, 55, 45, 46},
    {34, 58, 44, 39, 43, 55, 48, 42},
    {31, 60, 39, 31, 32, 44, 43, 28},
    {33, 59, 46, 36, 41, 50, 44, 35},
    {34, 52, 48, 36, 38, 52, 53, 41},
    {28, 47, 30, 34, 30, 42, 40, 28},
    {32, 59, 40, 33, 29, 43, 42, 22},
    {34, 45, 30, 34, 31, 44, 41, 35},
    {26, 55, 40, 26, 27, 42, 39, 31},
    {20, 47, 29, 29, 23, 39, 43, 16},
    {36, 51, 58, 44, 51, 63, 53, 53},
    {-24, -22, -30, -20, -41, -31, -32, -39},
    {29, 50, 56, 38, 49, 56, 44, 48},
    {35, 40, 50, 41, 46, 50, 47, 44},
    {19, 46, 62, 37, 36, 56, 47, 36},
    {32, 43, 59, 35, 48, 56, 45, 49},
    {31, 52, 55, 50, 39, 58, 54, 39},
    {30, 49, 64, 34, 42, 54, 48, 44},
    {26, 45, 54, 31, 39, 49, 40, 34},
    {26, 48, 62, 28, 39, 54, 48, 39},
    {32, 38, 48, 35, 35, 49, 44, 34},
    {14, 32, 39, 31, 30, 41, 35, 30},
    {30, 34, 33, 55, 36, 46, 39, 34},
    {27, 31, 29, 48, 35, 41, 37, 39},
    {28, 32, 22, 48, 27, 41, 33, 32},
    {45, 42, 47, 53, 68, 64, 57, 65},
    {45, 48, 47, 41, 59, 54, 43, 55},
    {38, 37, 43, 45, 60, 54, 50, 55},
    {37, 49, 46, 39, 61, 57, 43, 48},
    {36, 39, 42, 44, 60, 54, 49, 52},
    {-33, -23, -32, -31, -66, -45, -38, -56},
    {7, 19, 20, 18, 26, 25, 21, 21},
    {36, 47, 53, 40, 56, 59, 46, 48},
    {29, 42, 49, 36, 54, 55, 48, 53},
    {-3, 25, 22, 12, -2, 19, 18, 1},
    {-20, -7, -18, -18, -38, -18, -19, -31},
    {-15, -1, -18, -14, -35, -21, -20, -31},
    {-15, -25, -31, -21, -35, -34, -26, -26},
    {-30, -23, -32, -36, -68, -42, -39, -58},
    {41, 38, 33, 48, 49, 55, 43, 47},
    {-2, -10, -9, 6, -10, -2, 0, -2},
    {-28, -22, -33, -29, -53, -45, -39, -48},
    {-35, -32, -33, -31, -61, -41, -34, -53},
    {-38, -31, -35, -42, -56, -48, -42, -46},
    {29, 44, 36, 36, 48, 50, 40, 41},
    {31, 44, 41, 34, 39, 47, 40, 32},
    {34, 34, 30, 37, 55, 48, 38, 46},
    {30, 35, 39, 36, 60, 49, 39, 39},
    {-11, -7, -15, -24, -28, -21, -17, -27},
    {-21, -20, -24, -24, -42, -27, -24, -29},
    {-29, -28, -27, -22, -65, -33, -26, -46},
    {-28, -31, -40, -26, -50, -41, -34, -44},
    {-26, -23, -25, -19, -51, -36, -31, -45},
    {35, 49, 58, 46, 57, 65, 54, 51},
    {42, 51, 44, 52, 50, 62, 53, 48},
    {-41, -33, -39, -40, -58, -51, -50, -60},
    {32, 49, 48, 40, 56, 57, 53, 43},
    {37, 44, 44, 52, 44, 56, 53, 45},
    {37, 52, 45, 45, 44, 62, 55, 41},
    {35, 50, 49, 43, 41, 64, 55, 44},
    {33, 47, 49, 37, 45, 60, 50, 48},
    {35, 44, 49, 49, 44, 61, 55, 54},
    {33, 44, 45, 41, 52, 57, 49, 46},
    {34, 44, 48, 38, 44, 57, 50, 42},
    {43, 47, 46, 51, 44, 56, 57, 53},
    {35, 46, 43, 43, 41, 56, 55, 49},
    {37, 42, 44, 50, 48, 58, 54, 40},
    {32, 38, 36, 59, 32, 51, 45, 37},
    {-22, -24, -37, -25, -45, -41, -37, -40},
    {18, 37, 42, 40, 35, 46, 49, 33},
    {31, 41, 33, 49, 41, 52, 39, 42},
    {27, 42, 31, 45, 41, 56, 41, 35},
    {30, 38, 49, 38, 33, 52, 46, 32},
    {31, 37, 39, 44, 40, 52, 51, 44},
    {32, 41, 38, 49, 29, 50, 46, 35},
    {35, 44, 35, 36, 31, 46, 44, 41},
    {24, 47, 43, 33, 36, 51, 47, 36},
    {25, 31, 31, 32, 32, 46, 35, 34},
    {32, 36, 28, 35, 35, 42, 47, 37},
    {28, 35, 31, 35, 31, 48, 42, 35},
    {24, 36, 36, 33, 23, 52, 42, 30},
    {27, 33, 37, 37, 34, 43, 43, 31},
    {13, -3, 4, 6, 4, 3, 7, 9},
    {-17, -11, -8, -12, -26, -12, -15, -18},
    {29, 36, 29, 35, 26, 41, 45, 38},
    {15, 35, 36, 33, 27, 43, 38, 31},
    {16, 29, 27, 26, 30, 39, 31, 23},
    {18, 33, 32, 31, 20, 39, 42, 22},
    {30, 41, 38, 40, 34, 48, 56, 30},
    {32, 41, 42, 41, 37, 53, 63, 38},
    {30, 46, 43, 40, 34, 53, 58, 36},
    {32, 43, 39, 37, 35, 51, 59, 36},
    {32, 42, 42, 38, 37, 54, 58, 41},
    {30, 41, 45, 39, 36, 51, 59, 40},
    {25, 33, 39, 38, 31, 47, 54, 34},
    {30, 36, 41, 37, 32, 46, 53, 35},
    {25, 37, 33, 33, 28, 37, 45, 30},
    {29, 35, 36, 32, 32, 46, 49, 32},
    {29, 44, 47, 37, 40, 61, 63, 43},
    {27, 28, 26, 26, 26, 33, 50, 28},
    {24, 29, 26, 27, 23, 35, 44, 28},
    {29, 37, 33, 34, 30, 47, 51, 34},
    {20, 30, 27, 30, 24, 41, 49, 23},
    {27, 35, 26, 34, 24, 42, 46, 27},
    {-30, -27, -43, -43, -61, -55, -49, -58},
    {-39, -20, -34, -36, -60, -44, -45, -66},
    {47, 45, 46, 48, 58, 59, 54, 68},
    {41, 50, 54, 47, 51, 65, 60, 60},
    {-38, -27, -36, -53, -45, -49, -40, -50},
    {44, 43, 48, 57, 53, 61, 54, 57},
    {-29, -25, -41, -31, -45, -44, -40, -47},
    {37, 44, 46, 43, 46, 58, 56, 59},
    {31, 45, 54, 41, 47, 56, 50, 57},
    {-40, -30, -36, -33, -61, -46, -37, -68},
    {37, 38, 41, 43, 45, 53, 49, 50},
    {-31, -16, -27, -29, -45, -34, -35, -56},
    {30, 41, 33, 38, 46, 51, 49, 40},
    {-33, -14, -22, -35, -42, -32, -26, -46},
    {-36, -18, -30, -40, -56, -40, -37, -65},
    {34, 44, 47, 38, 37, 54, 48, 48},
    {44, 37, 38, 38, 44, 52, 53, 49},
    {-26, -11, -16, -33, -44, -25, -26, -40},
    {39, 48, 39, 41, 42, 48, 46, 48},
    {-22, -21, -21, -29, -36, -34, -20, -29},
    {-30, -9, -22, -32, -26, -26, -26, -35},
    {-33, -12, -25, -37, -41, -30, -27, -48},
    {37, 42, 40, 37, 38, 50, 42, 41},
    {29, 37, 34, 40, 30, 41, 42, 31},
    {-40, -18, -24, -31, -46, -32, -29, -49},
    {32, 31, 25, 35, 31, 37, 43, 36},
    {-31, -17, -25, -36, -43, -32, -22, -46},
    {23, 30, 29, 30, 24, 35, 32, 31},
    {-29, -10, -14, -23, -32, -17, -13, -40},
    {-21, -14, -15, -17, -48, -23, -21, -37},
    {-6, 24, 13, 14, -13, 10, 21, -7},
    {3, 26, 22, 17, 6, 26, 27, 6},
    {12, 27, 14, 12, 12, 20, 18, 9},
    {26, 36, 38, 32, 46, 56, 53, 41}
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

    static int Asw[144] = {
              8,    9,    4,    7,    7,    6,   11,    9,    8,    7,
             14,    8,    7,    5,    8,    5,   11,    4,   11,    8,
             10,   10,    9,   11,    9,   12,   10,   13,   13,    7,
              7,   10,   12,    8,   12,    8,    4,    7,   15,   11,
              7,    5,    7,    5,    3,    7,    4,    3,    5,    5,
              7,    9,   11,   13,    4,    3,    6,    4,    3,   10,
              9,    6,    9,   10,    6,    8,    8,    8,    9,    7,
              7,    6,   13,    9,    4,    9,   13,    9,    7,    9,
              8,    5,    6,    7,    6,    7,    8,    9,    5,    6,
              4,    7,   10,    4,    8,    7,    5,    5,    5,    5,
             11,    7,    5,    9,    7,    4,    4,    4,    6,    4,
              5,    6,    9,    7,    5,    8,    4,    7,    9,    6,
              8,    6,    8,    5,    5,    8,    6,    6,    7,    5,
              9,    6,   10,    8,    7,    5,    4,    5,    6,    5,
              7,    7,    9,    9};

    static int Ntw[144] = {
             -1,   19,   14,    7,   14,   -4,   -5,   -3,   -1,   -3,
              1,   -1,    0,   -5,   -2,    0,   -4,   12,   -3,   -3,
             -3,   -3,    0,   -1,    0,    0,    1,    2,    3,   -3,
             -2,   -6,   -6,   -5,   -4,   -5,   17,    1,    0,   -5,
              3,   13,   13,   13,   16,   -4,    5,   14,   16,   21,
             -6,    0,   -4,    2,   12,   13,   16,   15,   13,   -5,
             -4,   19,   -4,   -2,   -5,   -5,   -5,   -4,   -3,   -4,
             -5,   -5,    2,    0,   13,   -3,    0,   -1,   -2,   -1,
              0,   -5,   -4,    0,   -4,   -2,   -1,    1,    4,   10,
             -5,    1,    2,   -2,   -2,   -4,   -5,   -4,   -5,   -4,
              0,   -1,   -3,    0,   -4,   -2,   -4,   -5,   -1,   -3,
             18,   19,   -8,   -7,   16,   -6,   14,   -7,   -6,   19,
             -3,   15,   -4,   15,   17,   -2,   -7,   12,   -5,   11,
             14,   15,   -1,    0,   15,   -3,   15,   -2,   11,   13,
              6,    2,    2,   -3};


	for (i = 0; i < 144; i++)
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

        for (i = 0; i < 144; i++)
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
char *ProcessRow(char *str)
{
	char *valstr;
	char *ptr;
	int fieldno;
	int i;
   int j;
	TQuizRow Row;
	int quote;

	for (fieldno = 0; fieldno < 157; fieldno++)
	{
		valstr = str;

		quote = FALSE;
		ptr = str;
		while (*ptr && (quote || (*ptr != ',' && *ptr != ')')))
		{
		    switch (*ptr)
		    {
				case '\\':
                    ptr++;
                    if (*ptr == '\\')
                    {
                        ptr++;
                        if (*ptr == 0x27)
                        {
                            ptr++;
                            if (*ptr == 0x27)
                                ptr++;
                            else
                                quote = FALSE;
                        }
                    }
                    break;

                case 0x27:
                    quote = !quote;
                    ptr++;
                    break;

                default:
                    ptr++;
                    break;
            }
		}

		if (*ptr == ',' || *ptr == ')')
		{
			*ptr = 0;
			str = ptr + 1;

			switch (fieldno)
			{
				case 0:
					Row.ID = atol(valstr);
					break;

				case 1:
				case 2:
					break;

				case 3:
					Row.BirthYear = atoi(valstr);
					break;

				case 4:
					Row.BirthMonth = atoi(valstr);
					break;

				case 5:
					Row.Gender = atoi(valstr);
					break;

				case 6:
					Row.Lang = atoi(valstr);
					break;

				case 7:
					Row.Autism = atoi(valstr);
					break;

				case 8:
					Row.Aspie = atoi(valstr);
					break;

				case 9:
					Row.ADHD = atoi(valstr);
					break;

				case 10:
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

				case 11:
					Row.AsResult = atoi(valstr);
					break;

				case 12:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 13;
    			    Row.Quiz[i] = atoi(valstr);
					break;
			}
		}
	}

    UpdateScore(&Row);
	HandleRow(&Row);

	return str;
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
	TFile infile("quizr5.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 144; i++)
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
			ptr = ProcessRow(rowstr);

			pos += ptr - buf;
	    }
	    else
    		pos += strlen(buf) + 1;
    		
		infile.SetPos(pos);
	}
}
