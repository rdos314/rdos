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
# Convert exported quiz-7 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdb7.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-7 VALUES (";

TFile quizfile("quiz7.bin", 0);

static int Gw[161][8] = 
{
    {40, 63, 49, 39, 46, 55, 43, 47},
    {33, 43, 34, 26, 30, 41, 42, 33},
    {35, 53, 47, 32, 37, 52, 46, 41},
    {39, 59, 39, 35, 36, 52, 40, 39},
    {27, 52, 31, 28, 17, 35, 30, 21},
    {32, 54, 41, 33, 22, 43, 37, 29},
    {25, 38, 30, 26, 25, 36, 24, 31},
    {34, 60, 43, 35, 41, 53, 43, 43},
    {32, 56, 36, 31, 33, 43, 36, 34},
    {30, 39, 32, 29, 27, 41, 37, 31},
    {31, 41, 35, 34, 29, 44, 44, 35},
    {18, 16, 14, 17, 9, 19, 18, 14},
    {56, 35, 30, 37, 35, 40, 31, 42},
    {60, 49, 35, 40, 35, 49, 48, 46},
    {54, 39, 31, 44, 38, 46, 39, 47},
    {53, 41, 27, 39, 33, 43, 37, 42},
    {49, 44, 33, 34, 27, 43, 44, 36},
    {53, 34, 25, 29, 27, 34, 30, 36},
    {31, 50, 63, 29, 40, 49, 42, 45},
    {31, 42, 57, 30, 46, 52, 39, 49},
    {27, 46, 60, 26, 35, 46, 40, 37},
    {26, 48, 60, 22, 36, 48, 40, 38},
    {23, 37, 53, 20, 29, 41, 33, 33},
    {17, 35, 57, 9, 24, 34, 29, 26},
    {4, 23, 41, 1, 23, 22, 19, 24},
    {6, 26, 48, 10, 25, 27, 26, 26},
    {16, 26, 41, 2, 15, 23, 20, 12},
    {23, 31, 21, 47, 25, 41, 32, 34},
    {28, 32, 24, 47, 32, 38, 34, 38},
    {32, 32, 20, 43, 20, 33, 34, 25},
    {25, 27, 6, 45, 10, 23, 19, 15},
    {33, 26, 22, 40, 17, 33, 32, 27},
    {17, 18, 9, 33, 11, 20, 23, 17},
    {28, 31, 19, 49, 25, 39, 30, 32},
    {29, 24, 14, 47, 19, 30, 24, 25},
    {9, 8, 19, -7, 2, 3, 9, -3},
    {-7, -2, 19, -26, 5, 0, 5, 3},
    {27, 24, 9, 45, 14, 28, 22, 18},
    {-36, -34, -32, -29, -61, -41, -29, -55},
    {40, 41, 43, 39, 64, 54, 41, 62},
    {33, 52, 54, 37, 49, 56, 42, 50},
    {-33, -27, -20, -31, -52, -33, -22, -45},
    {38, 49, 53, 36, 53, 57, 39, 48},
    {-27, -29, -34, -28, -53, -39, -29, -44},
    {38, 50, 46, 36, 59, 55, 39, 51},
    {34, 45, 38, 31, 50, 46, 33, 46},
    {38, 45, 42, 41, 63, 58, 42, 55},
    {-29, -30, -26, -19, -65, -30, -20, -46},
    {-37, -36, -28, -25, -53, -36, -22, -39},
    {32, 39, 41, 32, 62, 50, 33, 53},
    {30, 42, 47, 33, 52, 52, 44, 51},
    {26, 38, 45, 25, 52, 47, 34, 40},
    {-23, -28, -30, -21, -52, -33, -21, -42},
    {32, 45, 46, 34, 38, 49, 41, 40},
    {35, 37, 36, 34, 50, 51, 38, 46},
    {-28, -29, -26, -31, -59, -41, -27, -49},
    {31, 45, 33, 34, 44, 46, 35, 39},
    {34, 35, 28, 34, 53, 48, 32, 45},
    {-15, -22, -21, -13, -56, -24, -14, -31},
    {-12, -18, -16, -9, -49, -16, -11, -27},
    {-6, -11, -24, -3, -31, -12, -10, -20},
    {-11, -9, -17, -6, -42, -13, -10, -26},
    {-13, -10, -12, -6, -41, -9, -8, -23},
    {-9, -17, -22, -11, -40, -16, -11, -28},
    {-11, -13, -12, 0, -27, -6, -3, -12},
    {-9, -15, -16, -4, -32, -8, -9, -19},
    {-12, -6, -9, -6, -42, -9, -6, -31},
    {-2, 1, -16, 0, -31, -7, -2, -20},
    {-1, 3, -11, 0, -30, -6, -1, -18},
    {47, 48, 47, 45, 57, 59, 50, 71},
    {40, 49, 49, 42, 49, 58, 49, 66},
    {-37, -31, -26, -33, -48, -40, -28, -68},
    {-41, -31, -34, -31, -61, -44, -32, -69},
    {43, 51, 51, 46, 55, 62, 51, 65},
    {40, 47, 41, 37, 43, 55, 40, 60},
    {38, 40, 42, 35, 47, 50, 44, 61},
    {39, 46, 37, 37, 41, 45, 37, 51},
    {-36, -21, -22, -28, -52, -36, -25, -67},
    {41, 49, 52, 41, 47, 58, 50, 59},
    {-32, -24, -19, -29, -44, -35, -21, -61},
    {-36, -28, -29, -29, -54, -40, -30, -67},
    {39, 39, 36, 37, 45, 49, 44, 56},
    {-33, -32, -32, -34, -52, -42, -36, -62},
    {47, 51, 39, 52, 51, 64, 45, 57},
    {30, 45, 49, 19, 35, 49, 36, 40},
    {34, 44, 47, 37, 50, 57, 43, 53},
    {38, 51, 45, 39, 47, 62, 46, 52},
    {36, 47, 47, 42, 43, 63, 46, 49},
    {40, 48, 41, 45, 45, 65, 45, 52},
    {34, 48, 46, 33, 42, 60, 45, 49},
    {37, 47, 34, 31, 28, 49, 41, 35},
    {36, 48, 44, 37, 47, 59, 43, 46},
    {35, 50, 46, 40, 33, 60, 48, 43},
    {36, 46, 43, 41, 34, 57, 51, 44},
    {19, 24, 20, 20, 18, 27, 22, 23},
    {16, 23, 24, 18, 16, 27, 25, 18},
    {16, 21, 17, 15, 13, 24, 21, 16},
    {-19, -9, 1, -17, -41, -20, -11, -33},
    {-10, -14, 0, -17, -41, -21, -11, -28},
    {1, 0, 3, 9, -27, 6, 7, -4},
    {3, 6, 7, 5, 28, 14, 9, 11},
    {2, 1, -2, 14, -19, 4, 11, -1},
    {-13, -6, 5, -20, 7, -6, -12, -13},
    {46, 48, 37, 56, 44, 58, 45, 57},
    {47, 50, 37, 54, 41, 61, 46, 55},
    {36, 51, 59, 39, 48, 57, 46, 54},
    {37, 47, 46, 52, 41, 60, 45, 48},
    {38, 40, 38, 39, 53, 53, 39, 55},
    {32, 36, 31, 29, 26, 43, 49, 35},
    {29, 40, 31, 31, 26, 39, 48, 34},
    {25, 33, 27, 22, 18, 33, 43, 25},
    {10, 19, 17, 19, 9, 27, 34, 12},
    {29, 35, 33, 31, 29, 42, 50, 31},
    {33, 40, 41, 34, 29, 49, 56, 38},
    {40, 42, 37, 40, 33, 50, 52, 47},
    {36, 48, 47, 36, 35, 53, 47, 51},
    {-35, -33, -30, -35, -51, -43, -33, -55},
    {23, 37, 46, 9, 31, 41, 37, 37},
    {35, 48, 58, 43, 53, 62, 47, 53},
    {40, 46, 40, 36, 40, 52, 40, 45},
    {32, 40, 31, 46, 37, 49, 35, 42},
    {30, 41, 34, 35, 28, 50, 37, 41},
    {41, 41, 35, 48, 33, 45, 41, 45},
    {-28, -28, -18, -24, -49, -37, -23, -44},
    {-24, -23, -17, -17, -34, -27, -19, -38},
    {-28, -31, -18, -28, -34, -35, -21, -39},
    {30, 37, 28, 35, 26, 40, 43, 38},
    {27, 31, 33, 32, 27, 39, 52, 32},
    {28, 33, 38, 31, 28, 41, 57, 32},
    {33, 41, 36, 34, 28, 48, 57, 38},
    {16, 15, 17, 18, 12, 24, 34, 16},
    {37, 43, 27, 37, 27, 45, 36, 34},
    {29, 36, 27, 27, 15, 38, 49, 26},
    {0, -4, 1, -9, -2, -1, -6, -3},
    {0, 7, -1, 6, -6, 2, 3, -7},
    {-23, -6, -4, -9, -17, -10, -4, -18},
    {21, 29, 17, 23, 17, 35, 35, 22},
    {9, 26, 19, 15, 8, 24, 19, 3},
    {27, 30, 27, 28, 17, 38, 49, 27},
    {18, 17, 17, 17, 12, 20, 22, 13},
    {36, 31, 32, 37, 34, 37, 36, 38},
    {38, 46, 34, 36, 36, 49, 33, 40},
    {22, 30, 27, 34, 4, 31, 38, 22},
    {9, 16, 25, -1, 12, 17, 17, 7},
    {14, 10, 8, 12, 5, 20, 13, 7},
    {35, 51, 49, 40, 41, 58, 48, 50},
    {2, 2, 8, 3, -4, 14, 12, 2},
    {30, 39, 30, 33, 44, 48, 31, 37},
    {30, 39, 38, 32, 30, 46, 53, 34},
    {11, 20, 15, 9, -11, 14, 25, 0},
    {29, 33, 25, 30, 43, 42, 25, 35},
    {4, 6, 0, 0, 2, 1, 0, 2},
    {4, 7, 2, 3, 2, 6, 1, 1},
    {8, 7, 9, 5, 16, 12, 12, 11},
    {3, 4, 6, 1, 4, 5, 4, 3},
    {6, 7, 8, 2, 3, 5, 6, 3},
    {5, 10, 5, 6, 4, 6, 6, 4},
    {14, 6, 1, 7, 7, 7, 6, 6},
    {5, 12, 15, 6, 10, 10, 8, 6},
    {10, 11, 10, 3, 11, 8, 6, 6},
    {3, 13, 10, 16, 12, 14, 9, 14}
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

    static int Asw[150] = {
             11,    7,   14,   10,    7,    7,   10,   11,    7,    8,
             10,    4,    7,    7,    6,    8,    5,    3,   12,   11,
             13,   13,    9,   12,   13,   14,   13,    8,    7,    3,
              6,   10,    4,    8,    6,   12,    7,    5,    5,   13,
             12,    5,   14,    5,   13,    9,   14,    6,    4,   12,
             12,   14,    7,    9,   11,    4,    7,   11,    4,    6,
              4,    5,    7,    6,    5,    8,    6,    3,    4,   10,
              9,    9,    7,   12,    8,    8,    8,    8,    8,    6,
              7,    7,    9,   10,    9,    9,    7,   12,    9,    9,
              5,   10,    9,    8,    2,    5,    3,    6,    4,    3,
             11,    5,   11,   10,   10,   12,   11,    9,    4,    5,
              2,    7,    9,    4,    6,    9,    7,    6,   10,   11,
             13,   11,    7,    6,    7,    7,    3,    9,    9,    5,
              7,    4,    5,    7,    2,   11,    3,    8,    7,    4,
              6,    4,    3,   10,   12,    9,    7,   11,   10,    8};

    static int Ntw[150] = {
             -4,   -2,    2,   -3,   -2,   -2,   -1,   -3,   -3,   -2,
             -1,    0,   -6,   -5,   -6,   -5,   -4,   -4,    0,   -3,
              0,    1,   -2,    3,    5,    6,    7,   -3,   -4,   -3,
              0,    0,   -1,   -2,   -1,    9,    5,   -1,   17,   -7,
             -3,   14,   -1,   20,   -4,   -6,    0,   15,   13,   -5,
             -4,    2,   17,   -3,   -4,   14,   -6,   -4,   11,   17,
             11,   12,   16,   16,   12,   16,   11,    4,    7,  -11,
             -9,   19,   20,   -7,   -7,   -9,   -7,   19,   -7,   16,
             19,   -9,   21,   -7,   -3,   -8,   -8,   -2,   -7,   -6,
             -5,   -6,   -6,   -5,   -1,    0,    0,   12,   10,    4,
              4,    4,   10,   -8,   -6,   -4,   -3,   -9,   -4,   -4,
             -2,    1,   -1,   -5,   -6,   -4,   17,   -4,   -7,   -3,
             -1,   -1,   -6,   15,   13,   13,   -4,   -2,   -3,   -4,
              0,   -5,   -3,    8,    4,   14,   -2,    5,   -2,    0,
             -6,   -6,   -2,    5,    7,   -4,    8,   -3,   -1,    5};

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

	for (fieldno = 0; fieldno < 174; fieldno++)
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
            		    	Row.Quiz[154] = 3;
                			break;

                		case 3:
	    	            	Row.Quiz[154] = 1;
            		    	break;

		                case 4:
                		case 6:
            	    		Row.Quiz[154] = 2;
    		            	break;

            	    	case 7:
		                	Row.Quiz[154] = 0;
                			break;
            	    }   
					break;

				case 5:
					Row.Eye = atoi(valstr);
                	switch (Row.Eye)
            	    {
            		    case 1:
                		case 2:
							Row.Quiz[155] = 1;
							break;

						case 3:
							Row.Quiz[155] = 2;
							break;

						case 4:
						case 5:
							Row.Quiz[155] = 3;
							break;
					}
					break;

				case 6:
					Row.Lang = atoi(valstr);
					break;

				case 7:
					Row.Country = atoi(valstr);
					break;

				case 8:
					Row.Ancestry = atoi(valstr);
					break;

				case 9:
					Row.Autism = atoi(valstr);
					break;

				case 10:
					Row.Aspie = atoi(valstr);
					break;

				case 11:
					Row.ADHD = atoi(valstr);
					break;

				case 12:
					Row.Social = atoi(valstr);
					Row.Quiz[150] = Row.Social;
					break;

				case 13:
					Row.Premature = atoi(valstr);
					switch (Row.Premature)
					{
					    case 1:
					        Row.Quiz[156] = 0;
					        Row.Quiz[157] = 0;
                            break;
					        
					    case 2:
        					Row.Quiz[156] = 3;
					        Row.Quiz[157] = 1;
        					break;

                        case 3:
        			        Row.Quiz[156] = 1;
					        Row.Quiz[157] = 1;
					        break;

					    case 4:
					    case 5:
        			        Row.Quiz[156] = 1;
					        Row.Quiz[157] = 2;
					        break;
                                    					
					    case 6:
					    case 7:
        			        Row.Quiz[156] = 1;
					        Row.Quiz[157] = 3;
					        break;
                            
        			}
					break;

				case 14:
					Row.Job = atoi(valstr);
					break;

				case 15:
					Row.Music = atoi(valstr);
					switch (Row.Music)
					{
					    case 1:
        					Row.Quiz[151] = 0;
        					break;

        			    case 2:
        			        Row.Quiz[151] = 0;
        			        break;

        			    case 3:
        			        Row.Quiz[151] = 2;
        			        break;
        			}
					break;

				case 16:
					Row.Politics = atoi(valstr);
					if (Row.Politics == 6)
					    Row.Quiz[152] = 2;
					else
					    Row.Quiz[152] = 0;
					break;

				case 17:
					Row.Religion = atoi(valstr);
					switch (Row.Religion)
					{
					    case 1:
					    case 6:
					    case 11:
					        Row.Quiz[158] = 1;
					        break;

					    case 26:
					        Row.Quiz[158] = 3;
					        break;


					    default:
					        Row.Quiz[158] = 2;
					        break;
                    }					        
					break;

				case 18:
					Row.Temp = atoi(valstr);
					switch (Row.Temp)
					{
					    case 1:
					    case 2:
					    case 3:
					    case 4:
					    case 5:
					        Row.Quiz[153] = 2;
					        break;

					    case 6:
					        Row.Quiz[153] = 1;
					        break;

					    case 7:
					    case 8:
					        Row.Quiz[153] = 0;
					        break;
					}
					break;

				case 19:
					Row.Vision = atoi(valstr);
					switch (Row.Vision)
					{
					    case 3:
					    case 4:
					        Row.Quiz[159] = 2;
					        break;
					        
					    case 5:
					    case 6:
					        Row.Quiz[159] = 3;
					        break;

                        default:
                            Row.Quiz[159] = 1;
                            break;
                    }
					break;

				case 20:
					Row.Learn = atoi(valstr);
					switch (Row.Learn)
					{
					    case 1:
					        Row.Quiz[160] = 1;
					        break;

					    case 2:
					        Row.Quiz[160] = 2;
					        break;

					    case 3:
					        Row.Quiz[160] = 3;
					        break;
				    }
					break;

				case 21:
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

				case 22:
					Row.AsResult = atoi(valstr);
					break;

				case 23:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 24;
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
	TFile infile("quiz7.sql");
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
