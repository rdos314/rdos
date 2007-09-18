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
# convs3.cpp
# Convert exported quiz-s3 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbs3.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-s3 VALUES(";

TFile quizfile("quizs3.bin", 0);

static int Gw[214][8] = 
{
    {62, 48, 41, 51, 44, 56, 58, 50},
    {55, 35, 35, 47, 47, 50, 45, 52},
    {58, 43, 40, 47, 39, 54, 54, 51},
    {54, 41, 27, 42, 35, 45, 42, 41},
    {55, 34, 32, 36, 37, 41, 39, 41},
    {39, 61, 52, 44, 48, 59, 53, 49},
    {36, 56, 45, 40, 43, 56, 49, 42},
    {41, 49, 42, 38, 40, 54, 53, 46},
    {37, 58, 44, 40, 39, 50, 49, 39},
    {33, 44, 33, 36, 35, 46, 44, 37},
    {38, 50, 59, 46, 51, 63, 55, 54},
    {36, 37, 57, 37, 50, 52, 47, 51},
    {30, 48, 58, 36, 48, 54, 46, 48},
    {33, 42, 60, 36, 49, 57, 47, 50},
    {31, 48, 64, 36, 41, 53, 51, 47},
    {32, 50, 57, 48, 38, 55, 51, 44},
    {31, 44, 64, 38, 38, 54, 55, 45},
    {27, 47, 62, 30, 39, 54, 48, 42},
    {32, 37, 52, 34, 33, 47, 45, 41},
    {28, 40, 52, 33, 37, 47, 39, 38},
    {48, 48, 42, 59, 52, 63, 56, 60},
    {-43, -38, -40, -58, -54, -54, -48, -54},
    {43, 40, 35, 49, 36, 49, 45, 45},
    {33, 39, 34, 50, 41, 52, 42, 43},
    {37, 38, 36, 58, 37, 52, 47, 40},
    {30, 32, 32, 49, 36, 44, 43, 42},
    {31, 39, 34, 42, 35, 47, 41, 34},
    {29, 38, 36, 44, 23, 44, 41, 31},
    {33, 34, 25, 47, 33, 44, 38, 38},
    {49, 42, 52, 54, 67, 67, 61, 70},
    {59, 42, 31, 55, 68, 70, 52, 62},
    {50, 46, 48, 45, 61, 57, 45, 52},
    {38, 48, 46, 40, 61, 59, 44, 49},
    {38, 46, 55, 42, 58, 60, 48, 51},
    {45, 43, 41, 51, 62, 63, 54, 48},
    {42, 40, 47, 48, 59, 59, 56, 57},
    {39, 45, 46, 39, 55, 57, 46, 49},
    {40, 38, 39, 40, 56, 54, 48, 51},
    {44, 47, 42, 44, 55, 56, 50, 51},
    {30, 35, 46, 36, 53, 51, 40, 43},
    {-41, -32, -37, -42, -61, -51, -42, -53},
    {-40, -27, -45, -37, -59, -60, -53, -68},
    {35, 36, 33, 41, 59, 53, 45, 49},
    {-33, -25, -38, -39, -65, -50, -43, -55},
    {28, 30, 43, 35, 49, 44, 42, 46},
    {-34, -35, -31, -32, -59, -49, -33, -49},
    {37, 30, 30, 40, 51, 49, 44, 42},
    {32, 38, 30, 35, 51, 51, 35, 38},
    {-30, -29, -40, -27, -52, -42, -38, -48},
    {-33, -27, -32, -33, -56, -43, -37, -52},
    {-28, -28, -35, -37, -51, -45, -42, -52},
    {-22, -26, -29, -22, -51, -37, -20, -41},
    {-24, -18, -23, -22, -49, -35, -23, -42},
    {38, 49, 59, 46, 57, 65, 55, 54},
    {45, 52, 45, 56, 52, 65, 55, 50},
    {38, 45, 59, 43, 53, 60, 57, 55},
    {45, 45, 50, 57, 53, 64, 57, 58},
    {39, 49, 47, 43, 53, 66, 56, 49},
    {31, 41, 50, 37, 54, 56, 54, 55},
    {35, 43, 47, 39, 52, 61, 50, 54},
    {34, 45, 49, 45, 46, 62, 52, 46},
    {39, 42, 52, 48, 46, 61, 60, 62},
    {40, 44, 44, 54, 47, 58, 54, 47},
    {37, 51, 50, 45, 42, 63, 57, 46},
    {35, 47, 50, 38, 45, 61, 52, 48},
    {-23, -13, -9, -16, -45, -32, -29, -35},
    {49, 48, 46, 53, 45, 60, 58, 52},
    {41, 50, 42, 46, 48, 59, 53, 45},
    {43, 40, 37, 50, 51, 57, 47, 48},
    {38, 43, 47, 50, 49, 60, 56, 44},
    {34, 41, 45, 41, 50, 55, 47, 46},
    {40, 41, 50, 45, 49, 57, 52, 50},
    {43, 44, 40, 49, 50, 59, 51, 46},
    {32, 43, 47, 37, 36, 53, 48, 49},
    {36, 46, 45, 42, 41, 56, 51, 44},
    {39, 39, 39, 48, 45, 55, 47, 43},
    {36, 39, 38, 37, 39, 49, 39, 40},
    {36, 42, 38, 35, 42, 47, 39, 39},
    {27, 45, 43, 32, 36, 50, 49, 40},
    {27, 31, 37, 36, 35, 47, 40, 40},
    {30, 36, 35, 35, 31, 48, 44, 40},
    {38, 43, 33, 39, 36, 49, 45, 36},
    {27, 36, 32, 32, 31, 41, 32, 35},
    {24, 33, 36, 28, 24, 46, 41, 34},
    {27, 32, 34, 35, 32, 41, 38, 32},
    {43, 45, 62, 46, 51, 70, 67, 65},
    {41, 43, 50, 52, 46, 67, 53, 53},
    {41, 45, 48, 46, 48, 59, 61, 59},
    {40, 39, 43, 42, 45, 56, 54, 52},
    {42, 42, 43, 43, 49, 56, 55, 49},
    {42, 45, 49, 48, 46, 61, 64, 51},
    {36, 44, 44, 41, 40, 55, 55, 50},
    {46, 38, 41, 42, 43, 53, 56, 49},
    {34, 50, 47, 38, 38, 52, 53, 41},
    {36, 40, 43, 39, 34, 53, 63, 42},
    {40, 40, 49, 50, 42, 55, 64, 48},
    {36, 41, 48, 41, 40, 52, 60, 49},
    {34, 42, 43, 39, 37, 53, 59, 45},
    {38, 43, 37, 39, 36, 50, 56, 38},
    {39, 41, 43, 42, 37, 55, 62, 48},
    {31, 35, 41, 37, 36, 51, 51, 45},
    {34, 45, 44, 41, 36, 51, 59, 42},
    {33, 35, 42, 38, 39, 50, 53, 42},
    {33, 40, 39, 40, 34, 48, 53, 36},
    {31, 36, 36, 34, 35, 47, 50, 38},
    {33, 36, 30, 36, 35, 46, 50, 39},
    {28, 35, 43, 38, 33, 45, 45, 44},
    {26, 30, 31, 35, 30, 40, 53, 36},
    {44, 51, 54, 50, 59, 69, 63, 64},
    {48, 45, 48, 50, 59, 62, 58, 69},
    {43, 51, 55, 49, 52, 67, 64, 62},
    {38, 47, 52, 45, 48, 61, 55, 61},
    {40, 39, 46, 39, 48, 55, 52, 61},
    {40, 45, 46, 42, 48, 62, 53, 62},
    {39, 40, 57, 42, 36, 59, 56, 55},
    {43, 41, 46, 41, 44, 56, 55, 65},
    {-40, -30, -39, -35, -61, -50, -42, -67},
    {-45, -35, -42, -44, -58, -53, -53, -65},
    {31, 41, 54, 36, 41, 54, 50, 55},
    {39, 37, 32, 51, 47, 50, 48, 52},
    {41, 49, 40, 44, 44, 52, 48, 49},
    {-35, -32, -37, -37, -53, -49, -44, -64},
    {41, 33, 35, 37, 39, 42, 42, 48},
    {-35, -32, -32, -36, -53, -42, -40, -53},
    {-41, -29, -36, -43, -52, -49, -48, -63},
    {-34, -28, -37, -27, -49, -43, -41, -43},
    {39, 32, 31, 33, 37, 42, 37, 47},
    {-34, -20, -22, -40, -46, -36, -29, -42},
    {-32, -21, -24, -30, -45, -36, -30, -44},
    {-39, -35, -31, -30, -54, -41, -30, -40},
    {-29, -29, -22, -32, -39, -41, -32, -39},
    {-35, -21, -27, -31, -40, -35, -32, -46},
    {-34, -32, -46, -41, -59, -55, -49, -59},
    {-39, -32, -32, -49, -50, -46, -39, -49},
    {-15, -4, -30, -28, -10, -18, -24, -17},
    {16, 49, 52, 9, 15, 57, 37, 40},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {9, 15, 14, 20, 7, 15, 14, 13},
    {19, 15, 10, 26, 9, 14, 12, 12},
    {13, 20, 18, 13, 8, 12, 18, 3},
    {11, 14, 15, 11, 9, 15, 18, 21},
    {12, 21, 11, 15, 12, 20, 15, 8},
    {27, 23, 23, 27, 38, 34, 29, 30}
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
    int grp;
    int i;
    int val;
    int w;
    int sum;
    int totsum;

    for (grp = 0; grp < 8; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 129; i++)
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
	int valid;

	for (fieldno = 0; fieldno < 234; fieldno++)
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
					Row.userid = atol(valstr);
					break;

				case 2:
				case 3:
				case 4:
					break;

				case 5:
					Row.BirthYear = atoi(valstr);
					break;

				case 6:
					Row.BirthMonth = atoi(valstr);
					break;

				case 7:
					Row.Gender = atoi(valstr);
					break;

				case 8:
					Row.Lang = atoi(valstr);
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
					Row.TS = atoi(valstr);
					break;

				case 13:
					Row.Dyslexia = atoi(valstr);
					Row.Quiz[210] = Row.Dyslexia;
					break;

				case 14:
					Row.Dyscalculia = atoi(valstr);
					Row.Quiz[211] = Row.Dyscalculia;
					break;

				case 15:
					Row.OCD = atoi(valstr);
					Row.Quiz[212] = Row.OCD;
					break;

				case 16:
					Row.ODD = atoi(valstr);
					Row.Quiz[213] = Row.ODD;
					break;

				case 17:
					Row.Bipolar = atoi(valstr);
					Row.Quiz[214] = Row.Bipolar;
					break;

				case 18:
					Row.Schizophrenia = atoi(valstr);
					break;

				case 19:
					Row.Social = atoi(valstr);
					Row.Quiz[215] = Row.Social;
					break;

				case 20:
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

				case 21:
					Row.AsResult = atoi(valstr);
					break;

				case 22:
					Row.NtResult = atoi(valstr);
					break;

				case 23:
					Row.SpqResult = atoi(valstr);
					break;

				default:
					i = fieldno - 24;
					Row.Quiz[i] = atoi(valstr);

					if (Row.SpqResult && i >= 136 && i <= 209)
					    Row.Quiz[i]++;
					
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
	TFile infile("quizs3.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 129; i++)
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
