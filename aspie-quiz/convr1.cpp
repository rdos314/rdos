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
# conv7.cpp
# Convert exported quiz-8 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr1.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r1 VALUES(";

TFile quizfile("quizr1.bin", 0);

static int Gw[130][8] = 
{
    {37, 48, 54, 38, 56, 58, 42, 50},
    {29, 31, 27, 35, 31, 36, 27, 33},
    {33, 41, 39, 35, 63, 55, 37, 43},
    {39, 39, 43, 40, 66, 54, 41, 61},
    {30, 37, 41, 32, 62, 48, 34, 39},
    {39, 45, 45, 41, 49, 50, 38, 44},
    {26, 39, 46, 27, 53, 48, 35, 41},
    {37, 49, 47, 38, 60, 56, 40, 50},
    {25, 35, 26, 28, 44, 39, 19, 32},
    {39, 44, 40, 36, 39, 50, 39, 44},
    {36, 43, 41, 41, 64, 57, 42, 55},
    {45, 44, 47, 44, 61, 64, 51, 64},
    {43, 45, 48, 50, 45, 61, 46, 61},
    {36, 49, 41, 36, 38, 52, 37, 39},
    {-19, -26, -23, -17, -56, -27, -19, -31},
    {-22, -27, -30, -21, -51, -33, -19, -41},
    {-33, -30, -28, -30, -63, -39, -28, -50},
    {-39, -36, -30, -28, -53, -38, -26, -40},
    {-17, -22, -16, -12, -36, -15, -17, -23},
    {-28, -19, -19, -26, -47, -32, -24, -59},
    {-40, -31, -36, -33, -60, -45, -33, -68},
    {-14, -15, -11, -13, -20, -16, -9, -25},
    {27, 36, 33, 36, 51, 44, 35, 44},
    {38, 36, 36, 37, 45, 48, 44, 55},
    {33, 40, 29, 35, 35, 45, 45, 39},
    {46, 46, 46, 46, 57, 59, 50, 69},
    {34, 37, 37, 37, 54, 51, 38, 47},
    {29, 34, 36, 27, 39, 45, 30, 46},
    {28, 40, 51, 30, 28, 44, 30, 37},
    {31, 39, 43, 33, 63, 50, 35, 52},
    {46, 45, 49, 49, 58, 56, 51, 71},
    {40, 45, 46, 41, 60, 59, 44, 59},
    {-36, -28, -27, -35, -48, -41, -30, -66},
    {-19, -28, -36, -33, -46, -38, -27, -56},
    {-32, -32, -35, -35, -53, -44, -36, -62},
    {-13, -10, -13, -7, -42, -12, -8, -33},
    {-29, -24, -27, -21, -59, -32, -23, -50},
    {23, 26, 28, 21, 27, 31, 22, 26},
    {28, 31, 46, 25, 19, 35, 30, 26},
    {43, 46, 60, 44, 53, 58, 36, 51},
    {10, 27, 29, 28, 20, 34, 24, 11},
    {30, 26, 28, 33, 30, 39, 33, 36},
    {33, 46, 58, 42, 55, 58, 49, 53},
    {39, 51, 56, 46, 68, 61, 48, 53},
    {17, 37, 58, 11, 27, 37, 29, 27},
    {28, 50, 64, 31, 41, 50, 43, 45},
    {31, 43, 58, 32, 48, 53, 40, 49},
    {25, 48, 61, 24, 37, 49, 41, 38},
    {16, 28, 42, 5, 19, 27, 22, 15},
    {10, 22, 27, 4, 9, 20, 18, 7},
    {23, 35, 46, 11, 30, 41, 34, 37},
    {5, 27, 49, 14, 27, 30, 27, 27},
    {15, 31, 34, 10, 24, 30, 17, 21},
    {30, 43, 49, 20, 36, 49, 37, 39},
    {33, 42, 58, 35, 33, 41, 38, 41},
    {28, 45, 50, 34, 37, 46, 36, 37},
    {36, 52, 59, 42, 50, 60, 48, 54},
    {39, 41, 45, 48, 52, 57, 40, 52},
    {33, 47, 49, 35, 43, 60, 45, 49},
    {39, 49, 47, 45, 49, 63, 44, 51},
    {21, 45, 51, 28, 38, 52, 38, 37},
    {34, 49, 47, 40, 37, 59, 48, 43},
    {38, 50, 47, 40, 48, 62, 46, 51},
    {33, 43, 47, 38, 52, 57, 42, 52},
    {32, 53, 52, 39, 54, 56, 43, 40},
    {46, 51, 40, 52, 52, 64, 46, 56},
    {37, 47, 34, 32, 28, 48, 41, 34},
    {23, 39, 25, 30, 33, 43, 39, 25},
    {45, 61, 47, 45, 56, 62, 49, 55},
    {42, 61, 40, 37, 40, 50, 40, 40},
    {38, 48, 38, 39, 42, 47, 40, 50},
    {33, 54, 47, 33, 37, 51, 49, 41},
    {26, 60, 41, 31, 28, 44, 38, 30},
    {32, 49, 39, 33, 34, 47, 40, 36},
    {21, 58, 33, 26, 24, 38, 32, 24},
    {39, 65, 49, 42, 46, 51, 44, 43},
    {43, 42, 26, 29, 28, 32, 26, 27},
    {3, 29, 15, 1, 7, 13, 11, -4},
    {31, 44, 34, 27, 30, 40, 42, 33},
    {31, 55, 37, 32, 34, 44, 36, 34},
    {42, 56, 47, 41, 37, 46, 42, 32},
    {34, 59, 44, 37, 42, 53, 45, 43},
    {32, 57, 50, 31, 54, 55, 37, 45},
    {28, 43, 35, 26, 33, 40, 32, 35},
    {19, 32, 38, 26, 31, 43, 37, 30},
    {48, 37, 39, 39, 42, 51, 40, 50},
    {67, 34, 30, 41, 37, 45, 38, 39},
    {68, 44, 40, 50, 39, 55, 50, 45},
    {62, 39, 36, 44, 46, 52, 42, 52},
    {62, 43, 34, 41, 45, 49, 42, 46},
    {56, 32, 26, 40, 26, 43, 30, 37},
    {63, 37, 31, 36, 28, 44, 30, 36},
    {39, 29, 32, 39, 35, 38, 36, 42},
    {60, 43, 41, 45, 36, 49, 42, 44},
    {53, 42, 27, 40, 35, 43, 39, 42},
    {42, 40, 34, 47, 33, 44, 38, 44},
    {37, 36, 32, 40, 51, 51, 36, 42},
    {43, 41, 33, 48, 49, 56, 40, 49},
    {46, 46, 44, 54, 50, 57, 44, 54},
    {46, 41, 39, 52, 43, 53, 46, 60},
    {33, 37, 33, 57, 31, 45, 43, 38},
    {39, 39, 34, 54, 39, 46, 40, 36},
    {39, 41, 40, 45, 44, 47, 44, 38},
    {29, 39, 39, 51, 20, 47, 42, 33},
    {38, 42, 42, 50, 26, 50, 44, 39},
    {31, 60, 53, 59, 40, 56, 48, 45},
    {30, 23, 28, 36, 25, 32, 33, 31},
    {38, 36, 32, 28, 37, 40, 33, 46},
    {-12, -15, -26, -13, -30, -26, -15, -34},
    {-19, -16, -28, -22, -34, -24, -20, -34},
    {10, 15, 23, 17, 15, 21, 20, 19},
    {30, 45, 33, 30, 43, 46, 38, 41},
    {12, 34, 17, 10, 16, 20, 17, 15},
    {33, 46, 34, 27, 44, 40, 33, 38},
    {24, 34, 20, 19, 30, 30, 22, 24},
    {28, 37, 34, 30, 32, 42, 49, 32},
    {4, 30, 30, 26, 21, 35, 35, 27},
    {26, 32, 35, 35, 32, 33, 54, 25},
    {14, 37, 26, 19, 14, 25, 46, 14},
    {35, 46, 34, 41, 35, 40, 63, 38},
    {32, 36, 31, 37, 30, 38, 51, 28},
    {37, 43, 34, 42, 33, 49, 54, 38},
    {37, 41, 40, 39, 32, 55, 49, 41},
    {29, 33, 23, 31, 11, 25, 46, 22},
    {31, 37, 27, 31, 28, 36, 43, 29},
    {28, 33, 25, 30, 28, 33, 47, 26},
    {21, 25, 11, 9, 8, 15, 17, 6},
    {12, 25, 21, 17, 10, 19, 32, 7},
    {12, 44, 38, 20, 24, 38, 34, 20},
    {0, 27, 21, 3, 8, 19, 19, 6}
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

    static int Asw[130] = {
             15,   10,   13,   12,   15,    9,   17,   12,   10,   11,
             15,   11,    9,    8,    4,    6,    4,    4,    5,    6,
              6,    4,    7,    7,    6,    9,   10,    7,   11,   11,
              9,   10,    9,    5,    9,    6,    4,    8,    8,   10,
             10,    6,   11,   13,   11,   12,   11,   13,   12,    7,
              6,   13,   10,    8,    9,   11,   11,    9,    8,    8,
              8,    8,    7,    8,    8,   10,    5,    5,   11,    8,
              7,   15,    7,    6,    7,    8,    5,    8,    7,    7,
              7,   10,    9,    7,    6,    6,    5,    7,    8,    8,
              4,    4,    5,    5,    7,    7,   11,    8,    9,    7,
             14,   16,   15,    7,    8,    9,   11,    7,    9,    6,
              8,    4,    3,    5,    3,   10,    4,   14,    9,   10,
             11,    5,    5,    4,    6,    7,    2,    7,    8,    7};

    static int Ntw[130] = {
             -1,    0,    2,   -6,    3,   -2,    2,   -4,    0,   -2,
             -1,   -7,   -7,   -2,   13,   16,   16,   15,   15,   17,
             19,   12,   -4,   -8,   -5,   -9,   -4,   -4,    1,   -5,
            -12,   -6,   20,   22,   21,   13,   16,    5,    5,   -5,
              6,   -5,   -4,   -2,    1,   -1,   -4,    0,    4,    4,
             -3,    4,    4,   -3,   -1,    5,   -5,   -5,   -6,   -7,
             -3,   -5,   -8,   -8,   -4,   -7,   -5,   -4,   -6,   -4,
             -6,    1,   -2,   -4,   -1,   -2,    0,   10,   -3,   -3,
             -1,   -4,   -7,   -3,   -3,   -7,   -8,   -8,   -6,   -6,
             -7,   -9,   -6,   -9,   -5,   -6,    0,   -5,   -6,  -12,
              3,    5,    5,   -2,   -4,   -1,    4,   -6,   19,   19,
              3,   -9,   -2,   -8,   -4,    0,   -3,    6,    6,    1,
              4,   -7,   -8,   -2,   -2,   -1,   -1,    7,    4,    5};


	for (i = 0; i < 130; i++)
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

        for (i = 0; i < 130; i++)
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

	for (fieldno = 0; fieldno < 178; fieldno++)
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
					Row.Dyscalculia = atoi(valstr);
					break;

				case 11:
					Row.Dyslexia = atoi(valstr);
					break;

				case 12:
					Row.Dyspraxia = atoi(valstr);
					break;

				case 13:
					Row.Hyperlexia = atoi(valstr);
					break;

				case 14:
					Row.OCD = atoi(valstr);
					break;

				case 15:
					Row.TS = atoi(valstr);
					break;

				case 16:
					Row.Allergy = atoi(valstr);
					break;

				case 17:
					Row.Chemical = atoi(valstr);
					break;

				case 18:
					Row.Diet = atoi(valstr);
					break;

				case 19:
					Row.Eating = atoi(valstr);
					break;

				case 20:
					Row.Bipolar = atoi(valstr);
					break;

				case 21:
					Row.Depression = atoi(valstr);
					break;

				case 22:
					Row.Anxiety = atoi(valstr);
					break;

				case 23:
					Row.Social = atoi(valstr);
					break;

				case 24:
					Row.Phobia = atoi(valstr);
					break;

				case 25:
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

				case 26:
					Row.AsResult = atoi(valstr);
					break;

				case 27:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 28;
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
	TFile infile("quizr1.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 130; i++)
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
