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
#include "quizdb3.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-III VALUES(";

TFile quizfile("quiz3.bin", 0);

static int Gw[100][8] = 
{
    {41, 64, 51, 44, 50, 54, 46, 50},
    {42, 66, 50, 45, 43, 59, 49, 48},
    {31, 58, 41, 31, 30, 41, 36, 35},
    {37, 59, 39, 38, 36, 50, 39, 38},
    {34, 55, 37, 36, 36, 45, 35, 37},
    {36, 60, 43, 43, 44, 55, 46, 46},
    {32, 45, 36, 37, 37, 44, 38, 40},
    {36, 55, 49, 42, 43, 55, 50, 44},
    {19, 43, 40, 27, 27, 40, 35, 34},
    {30, 55, 41, 31, 29, 44, 35, 35},
    {21, 31, 14, 17, 9, 19, 14, 13},
    {61, 40, 31, 41, 37, 44, 43, 47},
    {63, 46, 35, 45, 42, 50, 48, 51},
    {54, 43, 29, 41, 35, 43, 39, 44},
    {46, 46, 39, 44, 41, 49, 46, 50},
    {30, 40, 33, 31, 27, 41, 34, 34},
    {40, 37, 24, 34, 25, 34, 33, 31},
    {35, 46, 41, 38, 36, 47, 44, 44},
    {30, 45, 42, 38, 38, 46, 41, 39},
    {29, 46, 42, 39, 32, 51, 40, 41},
    {17, 28, 26, 19, 26, 30, 23, 22},
    {10, 18, 13, 12, 7, 16, 12, 13},
    {14, 18, 18, 18, 19, 23, 20, 19},
    {30, 41, 35, 32, 25, 39, 35, 34},
    {2, 9, 13, 10, 6, 12, 13, 15},
    {44, 45, 48, 49, 59, 55, 54, 73},
    {49, 50, 49, 53, 61, 60, 56, 73},
    {41, 41, 38, 40, 45, 46, 40, 55},
    {44, 46, 49, 48, 57, 56, 54, 70},
    {41, 52, 52, 54, 54, 59, 56, 70},
    {33, 48, 52, 44, 49, 54, 49, 62},
    {42, 45, 44, 50, 47, 54, 54, 69},
    {39, 42, 35, 51, 39, 50, 47, 60},
    {41, 38, 37, 39, 42, 45, 41, 52},
    {37, 46, 47, 43, 44, 57, 47, 60},
    {46, 50, 42, 54, 51, 57, 51, 63},
    {42, 40, 41, 44, 48, 51, 51, 59},
    {43, 51, 53, 55, 53, 61, 55, 67},
    {21, 32, 41, 30, 45, 39, 35, 47},
    {35, 37, 33, 46, 40, 44, 45, 55},
    {33, 39, 36, 41, 34, 46, 51, 46},
    {33, 36, 31, 40, 27, 40, 47, 41},
    {26, 34, 29, 43, 29, 41, 38, 42},
    {31, 37, 39, 43, 33, 47, 49, 46},
    {47, 51, 49, 45, 60, 56, 45, 57},
    {43, 54, 57, 51, 65, 63, 56, 70},
    {41, 54, 50, 47, 61, 59, 47, 56},
    {34, 54, 58, 42, 54, 56, 45, 53},
    {39, 43, 48, 46, 63, 54, 47, 62},
    {-24, -26, -31, -31, -49, -34, -27, -40},
    {32, 47, 50, 44, 57, 55, 52, 56},
    {32, 47, 53, 43, 63, 57, 44, 51},
    {32, 41, 51, 43, 58, 55, 45, 55},
    {39, 48, 46, 44, 62, 58, 47, 55},
    {-10, -9, -7, -5, -36, -4, -3, -15},
    {-9, -13, -20, -12, -48, -18, -14, -24},
    {-4, -11, -23, -7, -32, -11, -10, -19},
    {-7, -16, -24, -12, -43, -14, -15, -29},
    {-11, -12, -13, -2, -31, -6, -4, -13},
    {-9, -15, -13, -5, -37, -9, -5, -14},
    {2, 6, 4, -2, -6, -2, 0, -2},
    {-3, -5, 1, -7, -25, -6, 0, -7},
    {-12, -18, -14, -14, -48, -19, -11, -21},
    {21, 25, 22, 19, 19, 29, 21, 25},
    {9, 12, 10, 6, 6, 10, 9, 7},
    {17, 19, 13, 10, 8, 16, 13, 11},
    {12, 20, 18, 13, 11, 23, 16, 12},
    {9, 21, 20, 11, 6, 16, 15, 13},
    {5, 17, 16, 7, 0, 14, 12, 8},
    {32, 53, 64, 40, 45, 51, 45, 49},
    {34, 52, 59, 50, 52, 59, 50, 54},
    {30, 46, 54, 36, 40, 52, 41, 43},
    {31, 46, 61, 43, 48, 54, 46, 51},
    {29, 51, 61, 38, 42, 52, 41, 45},
    {23, 36, 47, 31, 32, 41, 38, 40},
    {27, 49, 58, 37, 39, 49, 43, 43},
    {18, 40, 59, 28, 42, 45, 36, 44},
    {19, 39, 58, 26, 33, 38, 33, 34},
    {9, 29, 49, 16, 30, 30, 26, 29},
    {42, 56, 50, 52, 53, 65, 52, 59},
    {36, 45, 48, 42, 52, 58, 48, 54},
    {39, 51, 47, 47, 47, 65, 51, 52},
    {37, 54, 46, 45, 41, 62, 50, 49},
    {35, 49, 50, 46, 44, 63, 52, 53},
    {38, 50, 46, 46, 41, 59, 54, 48},
    {36, 50, 43, 39, 34, 59, 45, 46},
    {28, 43, 44, 30, 32, 48, 37, 40},
    {34, 39, 34, 44, 34, 48, 36, 42},
    {21, 26, 20, 21, 17, 26, 22, 24},
    {15, 16, 13, 14, 9, 21, 12, 14},
    {11, 15, 8, 7, 2, 11, 9, 6},
    {14, 23, 24, 16, 20, 21, 20, 22},
    {6, 10, 9, 6, 5, 8, 9, 8},
    {17, 33, 21, 17, 14, 23, 19, 18},
    {4, 7, 12, 7, 3, 9, 9, 11},
    {14, 13, 11, 10, 7, 15, 11, 12},
    {10, 15, 6, 9, 3, 9, 10, 8},
    {8, 19, 18, 14, 9, 19, 18, 16},
    {14, 22, 11, 14, 11, 14, 12, 15},
    {11, 26, 13, 15, 7, 17, 12, 10}
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
					Row.AsResult = atoi(valstr);
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
	TFile infile("quiz3.sql");
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

