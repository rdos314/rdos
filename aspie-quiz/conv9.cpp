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
# conv9.cpp
# Convert exported quiz-9 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdb9.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-9 VALUES (";

TFile quizfile("quiz9.bin", 0);

static int Gw[153][8] = 
{
    {19, 28, 16, 18, 20, 24, 21, 18},
    {23, 25, 19, 22, 21, 27, 27, 21},
    {17, 16, 14, 16, 11, 18, 17, 14},
    {18, 32, 21, 17, 17, 25, 24, 18},
    {13, 13, 10, 9, 10, 14, 11, 11},
    {16, 19, 12, 11, 12, 18, 14, 15},
    {-17, 14, 16, -2, -4, 8, 7, -1},
    {17, 25, 19, 18, 18, 24, 24, 19},
    {13, 14, 17, 14, 17, 19, 22, 16},
    {56, 37, 31, 32, 36, 39, 35, 42},
    {60, 48, 35, 40, 35, 48, 48, 45},
    {52, 41, 27, 40, 34, 43, 38, 42},
    {61, 37, 30, 39, 39, 42, 42, 47},
    {-43, -16, -16, -20, -40, -23, -17, -33},
    {45, 24, 18, 24, 25, 26, 26, 26},
    {47, 43, 33, 35, 28, 43, 43, 36},
    {-40, -20, -19, -27, -32, -29, -28, -39},
    {-28, -6, -6, -11, -18, -12, -7, -18},
    {-42, -3, 0, -9, -16, -4, -5, -12},
    {36, 63, 50, 39, 49, 55, 44, 47},
    {30, 43, 34, 27, 31, 41, 42, 33},
    {23, 57, 42, 30, 28, 44, 38, 29},
    {36, 60, 39, 35, 37, 51, 41, 38},
    {27, 47, 30, 28, 28, 43, 31, 27},
    {20, 55, 34, 25, 24, 37, 32, 23},
    {28, 56, 38, 26, 28, 43, 38, 30},
    {31, 56, 37, 32, 34, 44, 37, 34},
    {28, 43, 35, 26, 34, 41, 32, 35},
    {8, 38, 34, 13, 19, 31, 28, 22},
    {17, 35, 36, 23, 30, 42, 37, 28},
    {28, 49, 64, 30, 42, 50, 43, 45},
    {30, 42, 58, 31, 48, 53, 40, 49},
    {25, 46, 60, 28, 37, 48, 41, 37},
    {22, 37, 54, 22, 32, 43, 34, 34},
    {24, 47, 60, 24, 37, 50, 41, 38},
    {16, 36, 58, 10, 27, 36, 30, 27},
    {16, 28, 42, 4, 20, 26, 21, 15},
    {4, 25, 49, 12, 28, 29, 27, 27},
    {14, 29, 50, 14, 29, 35, 30, 27},
    {25, 31, 26, 47, 33, 38, 35, 38},
    {23, 31, 22, 47, 27, 40, 33, 34},
    {31, 32, 22, 42, 23, 34, 35, 26},
    {32, 27, 22, 41, 21, 34, 35, 28},
    {-14, 4, 10, -23, -9, 2, 0, -15},
    {15, 18, 9, 33, 11, 20, 22, 17},
    {27, 25, 15, 47, 20, 30, 25, 26},
    {-4, 7, 0, -24, -13, -2, -4, -12},
    {-10, 0, 12, -27, -9, -2, -1, -15},
    {39, 52, 58, 42, 67, 64, 49, 61},
    {-36, -33, -32, -30, -62, -41, -31, -54},
    {39, 40, 43, 40, 66, 54, 41, 62},
    {37, 49, 54, 38, 56, 59, 42, 50},
    {-27, -22, -22, -18, -57, -28, -22, -37},
    {-34, -27, -22, -32, -54, -35, -25, -45},
    {37, 43, 41, 42, 64, 57, 42, 55},
    {37, 50, 46, 37, 60, 56, 40, 51},
    {-29, -30, -36, -30, -56, -41, -32, -47},
    {28, 37, 49, 38, 53, 54, 42, 53},
    {33, 44, 39, 32, 52, 48, 36, 47},
    {34, 37, 38, 37, 55, 52, 40, 48},
    {25, 39, 47, 35, 56, 53, 41, 45},
    {31, 44, 56, 43, 55, 58, 53, 54},
    {29, 41, 48, 35, 54, 54, 46, 53},
    {35, 37, 38, 41, 57, 52, 42, 55},
    {31, 39, 42, 33, 64, 51, 35, 53},
    {-38, -35, -29, -27, -53, -37, -25, -40},
    {-29, -29, -27, -21, -65, -32, -22, -46},
    {23, 30, 41, 33, 52, 43, 35, 45},
    {-29, -29, -28, -33, -59, -42, -28, -50},
    {-34, -28, -25, -31, -64, -38, -28, -52},
    {38, 40, 40, 43, 61, 55, 49, 56},
    {34, 34, 29, 36, 54, 46, 34, 45},
    {-30, -34, -43, -29, -54, -44, -36, -49},
    {-23, -18, -25, -20, -40, -26, -19, -37},
    {-19, -24, -23, -17, -57, -27, -18, -33},
    {-15, -21, -14, -15, -42, -17, -14, -24},
    {-14, -18, -16, -11, -48, -17, -13, -27},
    {-18, -11, -6, -16, -36, -11, -9, -24},
    {-10, -17, -24, -13, -41, -19, -14, -30},
    {-14, -13, -24, -19, -50, -24, -20, -31},
    {-15, -10, -13, -7, -42, -11, -10, -24},
    {-13, -11, -20, -11, -30, -18, -17, -24},
    {-10, -14, -16, -5, -33, -11, -11, -20},
    {-13, -13, -12, -1, -27, -7, -4, -13},
    {-1, 0, 5, 1, -8, 10, 9, 0},
    {-5, 1, -15, -7, -33, -11, -6, -23},
    {14, 28, 14, 14, 8, 24, 29, 10},
    {34, 44, 41, 41, 39, 54, 54, 49},
    {26, 38, 34, 31, 33, 44, 50, 32},
    {27, 40, 31, 31, 28, 42, 50, 34},
    {29, 40, 41, 36, 35, 52, 57, 42},
    {30, 35, 29, 34, 32, 41, 46, 34},
    {30, 39, 36, 36, 34, 49, 56, 40},
    {0, 29, 32, 25, 23, 37, 34, 28},
    {26, 34, 37, 34, 33, 47, 53, 36},
    {18, 37, 33, 29, 24, 44, 42, 28},
    {23, 30, 33, 33, 30, 41, 51, 32},
    {3, 29, 31, 26, 23, 40, 40, 28},
    {45, 47, 47, 46, 58, 60, 51, 70},
    {38, 46, 42, 39, 45, 55, 42, 61},
    {-40, -30, -34, -32, -61, -44, -34, -68},
    {37, 48, 49, 42, 48, 58, 49, 65},
    {-36, -29, -26, -35, -49, -40, -30, -68},
    {-36, -21, -23, -29, -52, -36, -28, -67},
    {-36, -26, -30, -31, -55, -41, -32, -68},
    {37, 38, 37, 37, 46, 49, 45, 55},
    {37, 45, 37, 38, 41, 46, 39, 50},
    {42, 42, 41, 43, 47, 54, 49, 52},
    {-32, -22, -18, -29, -43, -33, -23, -60},
    {-32, -31, -33, -35, -53, -43, -36, -62},
    {37, 49, 44, 44, 48, 64, 46, 51},
    {31, 45, 48, 41, 45, 62, 46, 47},
    {32, 43, 47, 38, 52, 57, 43, 53},
    {33, 47, 58, 43, 56, 63, 47, 53},
    {37, 50, 46, 39, 48, 62, 47, 52},
    {29, 44, 49, 20, 36, 50, 37, 39},
    {32, 49, 48, 39, 37, 60, 48, 44},
    {32, 47, 47, 34, 43, 60, 46, 49},
    {19, 41, 48, 26, 37, 52, 39, 37},
    {17, 25, 21, 20, 21, 28, 23, 23},
    {15, 22, 25, 20, 20, 30, 27, 20},
    {15, 20, 16, 13, 13, 22, 20, 13},
    {12, 22, 18, 13, 13, 24, 18, 12},
    {41, 55, 44, 51, 51, 60, 51, 52},
    {45, 49, 38, 54, 44, 61, 48, 54},
    {41, 51, 52, 47, 57, 64, 53, 64},
    {31, 51, 55, 38, 51, 57, 45, 49},
    {45, 48, 39, 56, 48, 59, 47, 58},
    {23, 38, 30, 27, 27, 37, 27, 32},
    {31, 44, 47, 35, 42, 51, 43, 41},
    {31, 40, 32, 47, 40, 50, 37, 43},
    {29, 39, 32, 30, 29, 42, 40, 32},
    {30, 36, 29, 35, 27, 41, 43, 38},
    {26, 38, 36, 33, 23, 50, 40, 31},
    {22, 45, 43, 32, 36, 50, 44, 34},
    {28, 41, 43, 31, 43, 52, 46, 35},
    {28, 24, 13, 19, 17, 23, 21, 14},
    {18, 34, 34, 23, 26, 41, 39, 28},
    {0, 0, 5, -1, 0, 4, -1, 2},
    {-10, -3, -4, -9, -13, -4, -7, -10},
    {-22, -13, -16, -22, -40, -22, -15, -29},
    {-16, -10, -18, -17, -33, -20, -17, -36},
    {27, 32, 30, 29, 31, 46, 33, 33},
    {20, 34, 32, 24, 24, 47, 33, 27},
    {18, 30, 19, 16, 12, 29, 27, 13},
    {-21, 13, 22, -9, -7, 3, 2, -13},
    {10, 40, 24, 6, 9, 27, 20, 3},
    {-27, -17, -10, -19, -36, -16, -10, -28},
    {-12, -6, -6, -9, -29, -5, -3, -20},
    {22, 32, 21, 21, 19, 29, 31, 19},
    {4, 7, 6, 3, 5, 5, 5, 5},
    {5, 7, 7, 3, 5, 6, 7, 4},
    {3, 2, 1, -1, 5, 4, 2, 2}
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

    static int Asw[153] = {
              5,    7,    4,    4,    4,    4,    8,    2,    3,    6,
              7,    7,    7,    5,    4,    5,   10,    9,    7,   10,
              7,    7,    9,   10,    7,    4,    7,    7,    8,    6,
             12,   11,   12,    8,   13,   11,   12,   14,   15,    7,
              8,    4,   10,    6,    5,    6,    5,   10,   11,    5,
             11,   15,    4,    5,   15,   12,    5,   10,    8,   10,
             11,   11,   11,    8,   11,    4,    6,   10,    4,    4,
              8,   10,    4,    6,    4,    3,    6,    6,    6,    4,
              7,    6,    8,    5,    6,    4,    7,    7,    9,    5,
              5,    5,    5,    4,    9,    5,    8,    4,    9,    8,
              6,    8,    9,    7,    7,    7,    7,    7,    6,    9,
              8,   13,    8,   10,    7,    8,    8,    8,    8,    3,
              4,    4,    4,    9,   10,   11,   11,    9,    9,    8,
             13,    7,    4,    8,    6,   13,    8,    4,    3,    8,
             11,   13,    7,    7,    6,   11,    4,    7,    9,    5};

    static int Ntw[153] = {
              0,   -1,    0,   -1,    1,   -1,    6,   -2,   -1,   -5,
             -6,   -5,   -7,   10,   -4,   -5,   15,   11,    8,   -5,
             -3,   -2,   -3,    0,   -1,   -3,   -4,   -3,    0,   -3,
             -2,   -4,    0,   -2,    0,    1,    4,    4,    2,   -4,
             -3,   -4,    0,    5,   -1,   -2,    6,    8,   -8,   16,
             -7,   -3,   13,   15,   -2,   -5,   19,   -4,   -6,   -5,
             -3,   -5,   -5,   -7,   -6,   14,   16,   -3,   15,   15,
             -8,   -4,   12,   11,   13,   10,   15,   12,   15,   16,
             15,   12,   14,   11,    6,    9,    1,   -6,   -1,   -4,
             -6,   -4,   -5,   -3,   -2,   -2,   -2,   -2,   -9,   -7,
             18,   -8,   19,   18,   18,   -8,   -6,   -7,   15,   20,
             -7,   -2,   -8,   -6,   -8,   -3,   -6,   -6,   -3,   -3,
             -1,   -1,    1,   -6,   -6,   -7,   -4,   -7,   -1,   -4,
             -1,   -2,   -5,   -1,   -4,   -1,    0,   -4,    2,    9,
             14,   15,   -1,    0,    0,    9,    0,   13,   11,   -1};


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
char *ProcessRow(char *str)
{
	char *valstr;
	char *ptr;
	int fieldno;
	int i;
   int j;
	TQuizRow Row;
	int quote;

	for (fieldno = 0; fieldno < 209; fieldno++)
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
					break;

				case 2:
					Row.BirthYear = atoi(valstr);
					break;

				case 3:
					Row.BirthMonth = atoi(valstr);
                	switch (Row.BirthMonth)
            	    {
                        case 2:
                        case 3:
                        case 4:
                        case 5:
						    Row.Quiz[152] = 1;
						    break;

                        case 8:
						case 9:
						case 10:
						case 11:
					        Row.Quiz[152] = 3;
						    break;

						default:
							Row.Quiz[152] = 2;
                            break;
            	    }
					break;

				case 4:
					Row.Gender = atoi(valstr);
					break;

				case 5:
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

				case 6:
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

				case 7:
					Row.Lang = atoi(valstr);
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
					Row.ABO = atoi(valstr);
					break;

				case 12:
					Row.Parkinson = atoi(valstr);
					break;

				case 13:
					Row.Alzheimer = atoi(valstr);
					break;

				case 14:
					Row.CFTR = atoi(valstr);
					break;

				case 15:
					Row.HFE = atoi(valstr);
					break;

				case 16:
					Row.Leiden = atoi(valstr);
					break;

				case 17:
					Row.RA = atoi(valstr);
					break;

				case 18:
					Row.Fibromyalgia = atoi(valstr);
					break;

			    case 19:
			    case 20:
			    case 21:
			    case 22:
			    case 23:
			        break;

				case 24:
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

				case 25:
					Row.AsResult = atoi(valstr);
					break;

				case 26:
					Row.NtResult = atoi(valstr);
					break;

			    case 177:
			        break;

				default:
					i = fieldno - 27;
					if (i < 150)
    					Row.Quiz[i] = atoi(valstr);
    				else
    				{
    				    i = i - 151;

    				    if (i < 31)
    				        Row.Stim[i] = atoi(valstr);
    				}
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
	TFile infile("quiz9.sql");
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
			ptr = ProcessRow(rowstr);

			pos += ptr - buf;
	    }
	    else
    		pos += strlen(buf) + 1;
    		
		infile.SetPos(pos);
	}
}
