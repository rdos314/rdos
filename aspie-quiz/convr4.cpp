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
# convr4.cpp
# Convert exported quiz-r4 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr4.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r4 VALUES(";

TFile quizfile("quizr4.bin", 0);

static int Gw[203][8] = 
{
    {37, 47, 52, 39, 56, 59, 45, 48},
    {40, 30, 43, 42, 65, 49, 43, 48},
    {35, 24, 36, 40, 54, 49, 38, 47},
    {37, 42, 40, 43, 66, 56, 47, 53},
    {34, 36, 39, 39, 65, 53, 42, 44},
    {47, 43, 47, 55, 68, 65, 58, 64},
    {36, 46, 48, 39, 38, 55, 50, 50},
    {34, 45, 44, 42, 53, 57, 48, 47},
    {37, 44, 41, 38, 40, 51, 45, 36},
    {41, 51, 54, 47, 51, 65, 59, 60},
    {30, 35, 40, 35, 61, 48, 39, 38},
    {38, 47, 49, 39, 44, 56, 50, 38},
    {29, 39, 32, 33, 50, 48, 35, 34},
    {38, 49, 46, 39, 61, 57, 43, 48},
    {39, 42, 40, 37, 38, 50, 42, 41},
    {23, 32, 25, 32, 37, 46, 38, 27},
    {-21, -26, -28, -19, -55, -33, -24, -33},
    {-28, -22, -24, -30, -49, -37, -30, -57},
    {-30, -30, -36, -32, -56, -43, -34, -46},
    {-39, -35, -35, -44, -55, -48, -43, -43},
    {33, 38, 33, 40, 58, 50, 47, 49},
    {31, 26, 32, 34, 43, 43, 42, 46},
    {39, 38, 41, 46, 45, 53, 48, 50},
    {47, 45, 46, 48, 58, 60, 54, 68},
    {43, 40, 45, 48, 61, 55, 50, 55},
    {33, 37, 39, 45, 41, 52, 51, 47},
    {32, 40, 43, 35, 65, 52, 38, 52},
    {35, 37, 40, 38, 55, 52, 43, 46},
    {46, 41, 43, 52, 48, 57, 52, 60},
    {49, 43, 50, 53, 60, 60, 57, 72},
    {38, 40, 45, 46, 43, 56, 54, 51},
    {30, 36, 30, 36, 31, 48, 42, 37},
    {43, 51, 52, 50, 58, 66, 59, 63},
    {26, 40, 48, 33, 33, 48, 37, 40},
    {38, 46, 49, 51, 43, 63, 54, 54},
    {41, 49, 40, 41, 55, 54, 46, 48},
    {39, 42, 43, 47, 63, 55, 49, 54},
    {36, 47, 43, 43, 41, 55, 56, 50},
    {-24, -27, -33, -36, -52, -42, -34, -49},
    {-22, -17, -22, -26, -33, -29, -21, -40},
    {36, 60, 46, 37, 43, 51, 45, 36},
    {38, 57, 44, 47, 45, 52, 52, 38},
    {37, 59, 36, 37, 35, 45, 44, 35},
    {40, 48, 39, 41, 43, 47, 45, 49},
    {46, 48, 41, 57, 50, 60, 52, 58},
    {34, 52, 47, 36, 39, 52, 54, 41},
    {37, 60, 40, 32, 34, 42, 45, 28},
    {28, 45, 34, 31, 29, 42, 44, 27},
    {31, 56, 37, 32, 34, 45, 40, 32},
    {22, 59, 33, 27, 25, 39, 36, 23},
    {27, 61, 42, 32, 29, 47, 42, 29},
    {31, 39, 32, 33, 32, 42, 36, 30},
    {35, 58, 44, 39, 43, 55, 48, 42},
    {37, 49, 47, 40, 57, 57, 46, 46},
    {30, 43, 35, 29, 35, 43, 36, 36},
    {16, 24, 29, 22, 20, 29, 29, 23},
    {33, 47, 34, 35, 28, 41, 38, 25},
    {23, 41, 19, 25, 17, 25, 25, 11},
    {31, 50, 29, 34, 26, 37, 39, 19},
    {37, 59, 40, 34, 30, 39, 44, 21},
    {29, 32, 37, 39, 33, 46, 53, 33},
    {36, 41, 40, 43, 40, 50, 60, 33},
    {38, 43, 44, 44, 40, 54, 64, 41},
    {26, 32, 24, 27, 22, 33, 38, 22},
    {30, 36, 36, 32, 33, 46, 50, 33},
    {15, 22, 28, 25, 25, 34, 30, 24},
    {11, 19, 23, 21, 18, 29, 32, 16},
    {34, 38, 42, 39, 34, 47, 57, 38},
    {29, 46, 38, 38, 30, 47, 53, 29},
    {35, 41, 45, 41, 37, 51, 59, 40},
    {32, 34, 33, 35, 26, 48, 51, 27},
    {36, 49, 45, 43, 37, 54, 58, 38},
    {38, 45, 41, 40, 36, 51, 59, 37},
    {29, 36, 26, 35, 25, 42, 44, 27},
    {34, 39, 35, 36, 30, 50, 52, 33},
    {27, 37, 33, 29, 16, 36, 44, 24},
    {24, 38, 26, 29, 30, 46, 42, 27},
    {33, 42, 43, 39, 37, 54, 58, 42},
    {30, 32, 29, 35, 29, 40, 47, 31},
    {33, 26, 24, 25, 21, 30, 48, 26},
    {36, 49, 57, 46, 58, 65, 54, 52},
    {37, 51, 58, 44, 52, 63, 52, 54},
    {40, 40, 52, 46, 48, 54, 49, 45},
    {46, 45, 48, 58, 54, 62, 55, 58},
    {40, 45, 43, 52, 45, 56, 52, 46},
    {29, 37, 49, 36, 55, 54, 45, 43},
    {24, 43, 53, 31, 40, 53, 44, 37},
    {32, 31, 44, 30, 30, 43, 40, 30},
    {34, 38, 50, 40, 36, 54, 47, 33},
    {34, 46, 49, 37, 45, 60, 49, 48},
    {34, 39, 36, 43, 33, 42, 45, 33},
    {36, 43, 41, 34, 41, 48, 41, 32},
    {43, 53, 45, 47, 46, 62, 54, 43},
    {38, 41, 45, 41, 52, 57, 48, 45},
    {41, 42, 47, 43, 48, 62, 47, 46},
    {36, 50, 49, 43, 41, 63, 55, 44},
    {28, 49, 41, 30, 29, 51, 44, 17},
    {29, 34, 39, 40, 35, 45, 46, 32},
    {33, 38, 48, 36, 37, 51, 45, 35},
    {45, 39, 36, 46, 58, 54, 50, 43},
    {18, 36, 56, 15, 28, 39, 34, 27},
    {32, 43, 59, 35, 49, 57, 45, 49},
    {27, 48, 62, 28, 40, 54, 47, 39},
    {30, 50, 64, 34, 43, 54, 48, 45},
    {32, 46, 56, 34, 43, 53, 44, 36},
    {40, 41, 59, 43, 54, 57, 48, 49},
    {19, 19, 40, 20, 32, 35, 28, 26},
    {24, 35, 45, 25, 27, 38, 30, 24},
    {34, 53, 55, 52, 42, 58, 55, 41},
    {39, 43, 43, 51, 50, 58, 56, 41},
    {37, 46, 58, 46, 57, 63, 56, 54},
    {26, 36, 32, 30, 30, 40, 34, 34},
    {33, 29, 31, 30, 27, 39, 35, 29},
    {30, 41, 41, 40, 34, 53, 45, 31},
    {32, 29, 31, 37, 35, 44, 38, 37},
    {26, 30, 41, 37, 51, 44, 38, 44},
    {35, 45, 48, 38, 44, 57, 49, 42},
    {43, 52, 44, 53, 51, 62, 53, 49},
    {37, 39, 35, 46, 42, 51, 45, 40},
    {17, 36, 37, 35, 28, 44, 38, 33},
    {44, 40, 33, 50, 50, 56, 44, 49},
    {36, 29, 29, 43, 53, 48, 42, 43},
    {38, 34, 31, 31, 38, 41, 37, 46},
    {46, 36, 34, 60, 50, 54, 47, 57},
    {44, 40, 35, 49, 36, 49, 45, 46},
    {33, 29, 23, 43, 23, 38, 40, 31},
    {38, 42, 38, 62, 39, 54, 50, 43},
    {36, 36, 37, 54, 43, 48, 44, 38},
    {37, 36, 29, 50, 45, 48, 46, 53},
    {32, 42, 41, 51, 32, 49, 49, 37},
    {36, 42, 38, 51, 32, 50, 49, 38},
    {53, 40, 26, 41, 34, 43, 42, 41},
    {67, 34, 29, 41, 36, 44, 44, 41},
    {59, 35, 32, 44, 43, 44, 41, 48},
    {57, 35, 30, 34, 35, 39, 40, 41},
    {62, 34, 28, 40, 31, 42, 39, 42},
    {61, 42, 39, 46, 36, 50, 54, 47},
    {41, 34, 32, 40, 35, 43, 39, 42},
    {34, 33, 25, 36, 32, 38, 44, 38},
    {33, 36, 28, 35, 35, 41, 46, 38},
    {21, 45, 39, 41, 29, 45, 45, 30},
    {36, 45, 28, 36, 32, 41, 42, 28},
    {24, 50, 30, 30, 21, 32, 36, 16},
    {29, 42, 24, 28, 23, 35, 39, 14},
    {18, 25, 24, 21, 21, 36, 32, 15},
    {20, 58, 41, 26, 18, 41, 41, 12},
    {27, 36, 33, 28, 26, 38, 41, 30},
    {25, 35, 35, 34, 22, 43, 45, 22},
    {8, 34, 31, 29, 22, 39, 40, 27},
    {8, 34, 33, 33, 22, 44, 47, 29},
    {20, 41, 37, 27, 23, 42, 36, 23},
    {24, 32, 28, 33, 37, 44, 38, 25},
    {17, 26, 28, 18, 17, 34, 29, 8},
    {-14, -17, -28, -14, -38, -25, -23, -25},
    {22, 30, 42, 36, 48, 52, 39, 43},
    {-4, 22, 10, 3, 0, 10, 12, -14},
    {33, 51, 62, 62, 60, 74, 57, 56},
    {25, 62, 52, 41, 41, 58, 45, 35},
    {23, 42, 58, 36, 42, 52, 41, 41},
    {39, 46, 57, 56, 47, 67, 53, 57},
    {-10, 17, -4, -6, -18, -6, 3, -30},
    {26, 40, 55, 33, 28, 46, 45, 30},
    {-27, -15, -18, -45, -46, -32, -26, -49},
    {-30, -34, -38, -49, -81, -51, -38, -58},
    {13, 46, 53, 28, 31, 52, 33, 23},
    {25, 38, 46, 29, 60, 42, 29, 35},
    {-3, 11, 1, -4, -23, 0, 1, -33},
    {-22, -32, -44, -33, -65, -50, -31, -51},
    {32, 48, 59, 52, 51, 70, 51, 52},
    {-27, -34, -46, -35, -74, -49, -32, -52},
    {20, 26, 33, 28, 14, 37, 28, 24},
    {20, 29, 62, 32, 39, 49, 45, 36},
    {31, 23, 40, 45, 46, 50, 41, 63},
    {5, 19, 16, 20, 16, 23, 22, 28},
    {32, 33, 42, 41, 72, 54, 38, 54},
    {31, 50, 66, 41, 50, 63, 49, 43},
    {-13, -28, -34, -14, -29, -26, -23, -24},
    {-29, -41, -47, -48, -52, -61, -49, -49},
    {35, 28, 41, 47, 70, 49, 45, 60},
    {-40, -30, -40, -55, -57, -51, -41, -70},
    {-27, -26, -39, -38, -39, -46, -32, -44},
    {2, -5, -24, 6, -1, -4, -2, 0},
    {15, -7, -2, 12, 15, 5, 5, 27},
    {-35, -35, -39, -43, -47, -51, -42, -63},
    {-33, -27, -30, -53, -48, -51, -40, -59},
    {41, 47, 51, 52, 62, 67, 54, 61},
    {-23, -21, -30, -22, -52, -32, -20, -42},
    {39, 31, 32, 47, 42, 48, 46, 56},
    {-39, -30, -44, -50, -56, -53, -42, -72},
    {-34, -42, -39, -57, -47, -54, -42, -52},
    {-31, -32, -42, -41, -80, -49, -38, -57},
    {32, 37, 48, 46, 40, 61, 47, 49},
    {-23, -16, -24, -29, -43, -29, -15, -44},
    {33, 40, 61, 45, 37, 64, 56, 47},
    {24, 31, 36, 40, 45, 44, 30, 51},
    {21, 22, 35, 25, 39, 35, 29, 32},
    {-29, -43, -48, -40, -80, -57, -37, -55},
    {38, 35, 43, 53, 60, 52, 39, 71},
    {22, 36, 30, 36, 55, 41, 33, 39},
    {-29, -39, -38, -37, -73, -50, -34, -52},
    {-26, -13, -25, -29, -43, -33, -19, -52},
    {-3, 1, -20, 3, -3, -2, -12, -2},
    {-25, -10, -18, -23, -40, -21, -16, -46}
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

        for (i = 0; i < 203; i++)
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

	for (fieldno = 0; fieldno < 222; fieldno++)
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
					Row.Gender = atoi(valstr);
					break;

				case 5:
					Row.Lang = atoi(valstr);
					break;

				case 6:
					Row.Autism = atoi(valstr);
					break;

				case 7:
					Row.Aspie = atoi(valstr);
					break;

				case 8:
					Row.PDD = atoi(valstr);
					break;

				case 9:
					Row.ADHD = atoi(valstr);
					break;

				case 10:
					Row.Dyslexia = atoi(valstr);
					break;

				case 11:
					Row.Dyscalculia = atoi(valstr);
					break;

				case 12:
					Row.NLD = atoi(valstr);
					break;

				case 13:
					Row.OCD = atoi(valstr);
					break;

				case 14:
					Row.TS = atoi(valstr);
					break;

				case 15:
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

				case 16:
					Row.AsResult = atoi(valstr);
					break;

				case 17:
					Row.NtResult = atoi(valstr);
					break;

				case 18:
					Row.AqResult = atoi(valstr);
					break;

				default:
					i = fieldno - 19;
					Row.Quiz[i] = atoi(valstr);

					if (i >= 203)
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
	TFile infile("quizr4.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 203; i++)
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
