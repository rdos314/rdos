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
# conv2.cpp
# Convert exported quiz-II to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdb2.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-II VALUES(";

TFile quizfile("quiz2.bin", 0);

static int Gw[100][8] = 
{
    {43, 64, 52, 45, 52, 55, 48, 53},
    {42, 51, 42, 44, 48, 47, 44, 54},
    {37, 58, 39, 37, 38, 46, 38, 40},
    {34, 58, 41, 32, 32, 41, 38, 36},
    {44, 66, 50, 45, 46, 59, 51, 49},
    {41, 55, 45, 42, 55, 54, 46, 53},
    {48, 59, 46, 53, 58, 64, 52, 59},
    {43, 55, 49, 48, 63, 61, 48, 57},
    {54, 44, 29, 40, 37, 44, 41, 45},
    {40, 40, 29, 38, 33, 42, 36, 46},
    {31, 59, 41, 31, 32, 46, 33, 36},
    {24, 46, 38, 27, 28, 42, 34, 35},
    {16, 33, 14, 20, 4, 27, 16, 10},
    {22, 31, 21, 31, 16, 32, 20, 20},
    {23, 27, 23, 31, 27, 35, 23, 26},
    {52, 41, 35, 41, 36, 41, 39, 46},
    {-5, -3, 0, -4, -11, -5, -5, -9},
    {28, 22, 19, 22, 18, 28, 29, 36},
    {13, 11, 11, 16, 11, 17, 22, 17},
    {51, 36, 33, 38, 41, 44, 34, 49},
    {32, 39, 33, 38, 35, 37, 30, 41},
    {42, 38, 38, 37, 45, 46, 40, 55},
    {51, 51, 48, 53, 64, 62, 58, 73},
    {46, 45, 48, 49, 61, 55, 55, 73},
    {42, 41, 39, 40, 46, 47, 41, 56},
    {45, 54, 55, 51, 67, 63, 57, 70},
    {50, 45, 40, 43, 49, 55, 48, 54},
    {16, 18, 13, 19, 1, 26, 22, 13},
    {35, 47, 45, 41, 45, 59, 45, 59},
    {43, 40, 40, 44, 51, 51, 53, 59},
    {46, 48, 40, 54, 53, 58, 50, 62},
    {26, 34, 26, 27, 21, 33, 34, 38},
    {24, 31, 38, 28, 42, 38, 33, 46},
    {28, 31, 29, 44, 35, 42, 39, 45},
    {26, 35, 32, 33, 25, 38, 36, 35},
    {43, 51, 49, 50, 54, 62, 56, 59},
    {36, 47, 39, 39, 36, 58, 42, 46},
    {-13, -11, -16, -18, -36, -16, -18, -32},
    {11, 26, 33, 15, 19, 27, 23, 22},
    {29, 34, 31, 34, 27, 46, 35, 42},
    {50, 53, 48, 45, 62, 57, 46, 59},
    {45, 47, 48, 47, 59, 57, 54, 69},
    {35, 43, 50, 42, 67, 55, 45, 59},
    {-23, -23, -25, -25, -59, -33, -20, -39},
    {-24, -33, -29, -26, -55, -26, -23, -33},
    {37, 41, 47, 39, 45, 53, 35, 48},
    {-3, -1, 7, -1, -6, 11, 3, 1},
    {-28, -26, -26, -32, -47, -34, -35, -50},
    {32, 37, 30, 44, 39, 43, 43, 55},
    {44, 52, 52, 56, 55, 62, 52, 66},
    {41, 43, 46, 46, 66, 55, 49, 63},
    {17, 26, 22, 29, 17, 31, 19, 27},
    {3, 12, 12, -1, 1, 2, 2, 0},
    {40, 46, 51, 37, 49, 50, 42, 48},
    {-31, -31, -36, -34, -55, -38, -34, -48},
    {-10, -10, -20, -13, -30, -14, -16, -21},
    {18, 22, 14, 16, 15, 27, 16, 17},
    {24, 26, 25, 18, 20, 30, 22, 26},
    {15, 19, 20, 14, 14, 25, 19, 13},
    {16, 16, 21, 17, 25, 22, 17, 27},
    {33, 52, 62, 40, 47, 51, 45, 49},
    {30, 50, 57, 39, 41, 52, 37, 43},
    {8, 28, 46, 14, 30, 29, 23, 27},
    {25, 28, 31, 49, 35, 42, 28, 37},
    {29, 36, 30, 58, 28, 44, 29, 37},
    {35, 39, 29, 50, 28, 48, 30, 38},
    {21, 30, 34, 41, 29, 43, 32, 33},
    {39, 47, 48, 42, 54, 57, 49, 55},
    {45, 58, 50, 53, 57, 66, 55, 60},
    {18, 30, 33, 13, 24, 30, 22, 25},
    {36, 44, 47, 38, 44, 51, 41, 54},
    {39, 48, 40, 41, 52, 50, 44, 53},
    {37, 54, 56, 42, 54, 57, 45, 53},
    {-16, -11, -21, -9, -44, -12, -16, -27},
    {-12, -13, -17, -2, -31, -7, -8, -15},
    {19, 20, 23, 12, 23, 17, 12, 22},
    {-26, -31, -37, -27, -55, -31, -28, -42},
    {-17, -16, -15, -7, -40, -6, -11, -23},
    {35, 45, 54, 43, 50, 54, 47, 53},
    {14, 32, 29, 14, 21, 20, 12, 20},
    {-10, -16, -26, -11, -45, -13, -18, -30},
    {4, 9, 13, 16, 3, 24, 10, 4},
    {26, 25, 26, 27, 31, 36, 35, 33},
    {18, 22, 25, 25, 17, 39, 26, 31},
    {18, 30, 19, 19, 11, 23, 17, 14},
    {11, 9, 2, 14, -4, 19, 18, 9},
    {20, 27, 26, 18, 23, 32, 20, 21},
    {27, 38, 30, 30, 28, 41, 31, 33},
    {28, 43, 39, 30, 33, 47, 34, 40},
    {-3, -11, -24, -6, -31, -9, -11, -21},
    {33, 32, 20, 47, 20, 35, 27, 31},
    {21, 30, 35, 35, 35, 42, 26, 34},
    {-27, -22, -16, -46, -32, -29, -21, -34},
    {-11, -12, -5, -16, -32, -4, -5, -22},
    {35, 37, 31, 46, 35, 49, 34, 43},
    {25, 26, 19, 42, 14, 32, 24, 27},
    {15, 18, 10, 10, 13, 14, 11, 17},
    {9, 20, 8, 9, 4, 11, 7, 9},
    {15, 14, 11, 13, 7, 24, 13, 13},
    {20, 22, 17, 21, 15, 26, 24, 25}
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

    static int Asw[100] = {
             13,   10,    9,   10,   13,   14,   14,   15,    9,    6,
              4,    8,    8,    9,    7,   11,   14,    5,    5,   11,
             12,   11,   12,   10,    9,   13,    9,    9,    9,    9,
             13,    5,   12,   10,    5,   10,   11,    7,   14,    9,
             13,    9,   14,    5,    5,   11,    8,   10,   10,   14,
             14,   13,   12,   10,    7,    8,    4,    2,    4,    3,
             13,   14,   15,   13,   15,   13,   14,    9,   12,   12,
             11,    8,   12,    5,    6,   14,    8,    6,   13,    9,
              6,    8,    6,    6,    8,    6,    8,    8,   10,    5,
             12,   14,    7,    7,   13,   10,   10,    7,    4,    7};

    static int Ntw[100] = {
             -5,   -7,   -2,   -2,   -4,   -5,   -6,   -5,   -4,   -6,
             -2,    0,    6,    3,   -1,   -3,   22,   -2,    0,   -6,
             -2,   -5,  -12,  -14,   -7,  -14,   -9,    8,   -8,  -10,
            -10,   -3,   -2,   -4,   -3,   -9,   -3,   20,    8,   -2,
             -9,  -12,   -7,   21,   20,   -5,   11,   29,   -6,   -6,
             -9,    9,   15,   -5,   27,   19,    0,   -2,    0,   -2,
             -2,    0,    7,    1,    5,    2,    4,  -10,   -8,    4,
             -3,  -10,   -5,   17,   15,    7,   26,   17,   -4,    3,
             19,    7,   -4,    0,    3,    6,    0,   -2,   -2,   14,
              3,    3,   20,   16,    0,    3,    6,    6,    1,    0};

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

    for (grp = 0; grp < 8; grp++)
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

	for (fieldno = 0; fieldno < 107; fieldno++)
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
                    Row.Diagnos = atoi(valstr);
                    break;

                case 3:
                    Row.BirthYear = atoi(valstr);
                    break;

                case 4:
                    Row.Gender = atoi(valstr);
                    break;

                case 5:
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

                case 6:
                    break;

                default:
                    i = fieldno - 7;
                    Row.Quiz[i] = atoi(valstr);
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
	TFile infile("quiz2.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 100; i++)
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

