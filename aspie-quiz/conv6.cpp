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

#include "file.h"
#include "quizdb6.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-6 VALUES(";

TFile quizfile("quiz6.bin", 0);

static int Gw[152][8] = 
{
    {40, 64, 50, 38, 47, 55, 46, 48},
    {33, 44, 34, 25, 31, 40, 42, 33},
    {36, 55, 47, 32, 38, 53, 45, 42},
    {27, 55, 39, 25, 25, 41, 36, 32},
    {38, 60, 39, 34, 37, 51, 40, 39},
    {30, 41, 34, 25, 27, 38, 44, 32},
    {34, 61, 42, 34, 41, 53, 44, 43},
    {36, 43, 32, 34, 35, 45, 45, 40},
    {32, 56, 36, 30, 33, 43, 35, 33},
    {30, 56, 38, 26, 26, 42, 36, 30},
    {37, 50, 40, 36, 34, 49, 42, 41},
    {28, 41, 30, 28, 26, 39, 44, 34},
    {58, 37, 30, 31, 34, 38, 33, 42},
    {60, 49, 35, 38, 35, 49, 47, 46},
    {54, 38, 31, 43, 38, 45, 38, 46},
    {53, 42, 27, 38, 34, 44, 37, 42},
    {54, 34, 24, 29, 27, 34, 30, 36},
    {47, 43, 32, 32, 26, 41, 39, 36},
    {48, 48, 47, 44, 58, 58, 52, 72},
    {40, 50, 49, 41, 50, 57, 50, 66},
    {-40, -31, -34, -31, -60, -44, -35, -70},
    {-37, -32, -26, -34, -49, -42, -33, -68},
    {39, 41, 37, 36, 45, 49, 48, 57},
    {43, 52, 51, 45, 55, 61, 53, 65},
    {37, 40, 41, 34, 47, 49, 45, 61},
    {40, 47, 37, 37, 41, 45, 38, 51},
    {40, 47, 41, 36, 45, 54, 41, 60},
    {-36, -22, -21, -28, -52, -36, -28, -67},
    {41, 49, 53, 40, 48, 58, 49, 60},
    {-33, -27, -19, -29, -45, -36, -25, -62},
    {-36, -28, -28, -29, -54, -40, -33, -67},
    {40, 34, 35, 38, 38, 49, 46, 48},
    {36, 49, 47, 34, 36, 53, 44, 51},
    {36, 38, 29, 48, 42, 47, 43, 54},
    {40, 42, 40, 37, 42, 51, 47, 63},
    {-29, -20, -19, -27, -49, -33, -26, -60},
    {36, 37, 33, 27, 38, 41, 33, 46},
    {36, 44, 44, 42, 41, 55, 48, 58},
    {39, 36, 33, 37, 39, 43, 39, 50},
    {35, 46, 41, 40, 36, 53, 51, 44},
    {36, 51, 59, 38, 48, 56, 45, 53},
    {30, 50, 63, 28, 40, 48, 42, 45},
    {30, 42, 58, 29, 47, 52, 41, 49},
    {22, 37, 46, 9, 31, 40, 35, 37},
    {30, 45, 50, 17, 35, 48, 36, 40},
    {26, 46, 59, 25, 35, 46, 39, 36},
    {26, 48, 60, 21, 36, 48, 40, 38},
    {17, 36, 57, 8, 25, 34, 28, 27},
    {22, 37, 52, 18, 29, 40, 31, 32},
    {33, 48, 59, 43, 53, 60, 49, 51},
    {6, 27, 43, 3, 24, 24, 22, 27},
    {6, 26, 47, 10, 25, 27, 25, 26},
    {16, 25, 40, 0, 13, 22, 15, 10},
    {37, 44, 37, 45, 46, 62, 46, 52},
    {36, 45, 43, 43, 45, 62, 47, 49},
    {48, 53, 41, 53, 53, 66, 52, 58},
    {35, 44, 47, 38, 51, 57, 46, 53},
    {38, 52, 45, 38, 48, 62, 46, 52},
    {34, 48, 45, 32, 43, 59, 45, 50},
    {37, 48, 35, 31, 28, 50, 40, 35},
    {36, 49, 44, 35, 47, 57, 41, 46},
    {36, 48, 43, 43, 35, 57, 52, 45},
    {36, 51, 45, 42, 35, 60, 49, 45},
    {28, 36, 33, 34, 17, 46, 36, 30},
    {-37, -37, -33, -30, -62, -43, -34, -57},
    {29, 38, 30, 32, 44, 46, 37, 38},
    {36, 47, 48, 38, 46, 55, 45, 45},
    {32, 35, 33, 32, 49, 49, 40, 44},
    {37, 40, 38, 33, 58, 48, 38, 54},
    {41, 42, 43, 40, 65, 55, 44, 62},
    {33, 52, 55, 37, 50, 56, 45, 51},
    {-33, -27, -21, -32, -51, -34, -26, -45},
    {-26, -27, -32, -28, -51, -37, -30, -43},
    {38, 51, 46, 35, 59, 55, 41, 51},
    {39, 50, 53, 35, 53, 57, 40, 48},
    {-35, -33, -30, -34, -52, -43, -34, -55},
    {35, 46, 39, 31, 51, 47, 37, 47},
    {-30, -31, -27, -20, -66, -31, -24, -47},
    {37, 45, 42, 41, 62, 57, 45, 54},
    {-39, -37, -29, -25, -53, -37, -23, -40},
    {33, 40, 42, 32, 63, 50, 37, 53},
    {39, 45, 40, 34, 40, 51, 40, 45},
    {25, 38, 45, 24, 51, 47, 34, 40},
    {-24, -28, -30, -21, -53, -33, -24, -42},
    {11, 20, 24, 11, 43, 27, 19, 28},
    {34, 45, 46, 32, 39, 49, 41, 40},
    {29, 42, 47, 32, 52, 52, 45, 51},
    {30, 31, 24, 35, 52, 48, 34, 43},
    {-11, -9, -16, -6, -42, -13, -13, -27},
    {-13, -10, -11, -7, -40, -9, -9, -22},
    {-14, -19, -16, -11, -50, -19, -15, -28},
    {-9, -17, -21, -12, -41, -17, -15, -29},
    {-12, -6, -9, -7, -42, -9, -9, -31},
    {-10, -12, -12, 1, -27, -6, -3, -12},
    {-9, -16, -15, -5, -33, -10, -10, -19},
    {-4, -6, 1, -9, -24, -8, -2, -12},
    {-18, -25, -22, -15, -60, -29, -24, -33},
    {-25, -26, -22, -32, -58, -41, -31, -48},
    {41, 42, 35, 48, 34, 45, 40, 45},
    {24, 31, 21, 46, 26, 41, 34, 34},
    {29, 32, 24, 47, 31, 37, 34, 38},
    {31, 31, 19, 43, 20, 32, 32, 24},
    {31, 25, 21, 40, 17, 33, 31, 26},
    {32, 29, 17, 48, 18, 34, 32, 25},
    {16, 19, 11, 33, 11, 21, 26, 17},
    {27, 29, 17, 48, 25, 37, 29, 31},
    {28, 22, 12, 47, 18, 29, 23, 24},
    {10, 11, 6, 31, 11, 18, 17, 15},
    {28, 24, 8, 46, 15, 29, 22, 17},
    {5, 8, 10, 7, 34, 17, 14, 16},
    {-21, -21, -21, -12, -59, -28, -23, -34},
    {20, 28, 31, 25, 56, 41, 35, 39},
    {-20, -9, 2, -18, -41, -22, -19, -35},
    {-12, -6, 6, -18, 7, -7, -8, -11},
    {15, 18, 20, -5, 16, 10, 4, 9},
    {26, 20, 15, 27, 32, 34, 26, 31},
    {-11, -12, -14, -9, -41, -17, -11, -24},
    {3, 2, -4, 16, -15, 6, 8, 1},
    {27, 32, 24, 34, 45, 46, 29, 37},
    {6, 2, 4, 10, -23, 7, 6, -3},
    {-10, -12, 0, -19, -41, -23, -17, -29},
    {19, 24, 20, 20, 18, 27, 22, 23},
    {16, 24, 20, 17, 14, 27, 20, 16},
    {24, 21, 18, 22, 18, 26, 25, 21},
    {16, 16, 13, 16, 8, 19, 14, 13},
    {46, 48, 37, 56, 45, 57, 47, 57},
    {46, 50, 37, 53, 43, 61, 46, 54},
    {35, 48, 38, 44, 35, 51, 40, 42},
    {25, 38, 30, 26, 24, 37, 27, 31},
    {-34, -32, -32, -34, -53, -41, -36, -62},
    {31, 40, 30, 44, 36, 48, 35, 41},
    {29, 41, 35, 33, 29, 50, 36, 40},
    {-25, -23, -17, -17, -34, -26, -19, -38},
    {30, 39, 32, 29, 27, 41, 35, 31},
    {-21, -15, -11, -17, -28, -16, -10, -27},
    {-29, -32, -20, -29, -36, -37, -23, -40},
    {30, 38, 29, 35, 27, 40, 43, 39},
    {-4, -11, -23, -3, -29, -11, -11, -18},
    {-30, -31, -17, -24, -50, -37, -25, -44},
    {25, 25, 23, 30, 30, 36, 35, 35},
    {-10, -10, -18, -6, -26, -13, -13, -19},
    {-17, -14, -17, -25, -47, -26, -28, -42},
    {17, 28, 16, 26, 14, 29, 16, 17},
    {-10, 6, 16, -9, -8, -1, 0, -10},
    {23, 40, 27, 34, 26, 40, 37, 28},
    {14, 32, 30, 18, 16, 27, 28, 20},
    {33, 40, 25, 39, 26, 43, 35, 33},
    {20, 22, 9, 31, 12, 26, 19, 18},
    {19, 25, 9, 33, 14, 30, 21, 17},
    {24, 25, 10, 39, 15, 33, 24, 22},
    {5, 6, 5, 1, 3, 5, 4, 2},
    {6, 9, 8, 1, 4, 7, 6, 5}
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
    int i;
    int grp;

    
	if (Row->Ancestry >= 2100 && Row->Ancestry < 2200)
	{
		for (i = 150; i < 162; i++)
			Row->Quiz[i] = 1;

		switch (Row->Hair)
		{
			case 1:
				Row->Quiz[150] = 3;
				break;

			case 2:
				Row->Quiz[151] = 3;
				break;

			case 3:
				Row->Quiz[152] = 3;
				break;

			case 4:
				Row->Quiz[153] = 3;
				break;

			case 5:
				Row->Quiz[154] = 3;
				break;

			case 6:
				Row->Quiz[155] = 3;
				break;

			case 7:
				Row->Quiz[156] = 3;
				break;
		}

		switch (Row->Eye)
		{
			case 1:
				Row->Quiz[157] = 3;
				break;

			case 2:
				Row->Quiz[158] = 3;
				break;

			case 3:
				Row->Quiz[159] = 3;
				break;

			case 4:
				Row->Quiz[160] = 3;
				break;

			case 5:
				Row->Quiz[161] = 3;
				break;
		}
	}
	else
		for (i = 150; i < 162; i++)
			Row->Quiz[i] = 0;

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

    for (grp = 0; grp < 8; grp++)
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

	for (fieldno = 0; fieldno < 165; fieldno++)
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
					Row.Hair = atoi(valstr);
            		switch (Row.Hair)
            		{
            		    case 1:
                		case 2:
            	    	case 5:
            		    	Row.Quiz[150] = 3;
                			break;

                		case 3:
	    	            	Row.Quiz[150] = 1;
            		    	break;

		                case 4:
                		case 6:
            	    		Row.Quiz[150] = 2;
    		            	break;

            	    	case 7:
		                	Row.Quiz[150] = 0;
                			break;
            	    }   
					break;

				case 5:
					Row.Eye = atoi(valstr);
                	switch (Row.Eye)
            	    {
            		    case 1:
                		case 2:
							Row.Quiz[151] = 1;
							break;

						case 3:
							Row.Quiz[151] = 2;
							break;

						case 4:
						case 5:
							Row.Quiz[151] = 3;
							break;
					}
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

				case 13:
					Row.AsResult = atoi(valstr);
					break;

				case 14:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 15;
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
	TFile infile("quiz6.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 150; i++)
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

