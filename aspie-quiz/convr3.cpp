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
# convr3.cpp
# Convert exported quiz-r3 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr3.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r3 VALUES(";

TFile quizfile("quizr3.bin", 0);

static int Gw[180][8] = 
{
    {37, 49, 55, 40, 57, 60, 45, 50},
    {43, 43, 52, 47, 71, 58, 44, 60},
    {37, 28, 37, 42, 59, 49, 42, 53},
    {35, 42, 42, 42, 68, 59, 43, 48},
    {28, 42, 52, 38, 58, 58, 45, 47},
    {37, 47, 44, 41, 42, 54, 45, 43},
    {42, 53, 54, 44, 55, 62, 51, 52},
    {32, 39, 43, 39, 66, 55, 41, 44},
    {38, 50, 48, 40, 62, 59, 43, 51},
    {30, 40, 34, 35, 51, 51, 36, 36},
    {39, 43, 41, 37, 39, 51, 42, 44},
    {23, 34, 27, 34, 38, 50, 39, 34},
    {47, 48, 49, 57, 71, 69, 60, 69},
    {34, 45, 46, 44, 53, 58, 49, 51},
    {37, 44, 42, 44, 67, 59, 48, 55},
    {41, 51, 54, 46, 52, 65, 60, 62},
    {35, 47, 49, 38, 38, 55, 50, 51},
    {-32, -31, -28, -32, -63, -39, -33, -49},
    {-28, -33, -32, -26, -59, -46, -35, -42},
    {-20, -27, -27, -19, -56, -33, -24, -33},
    {-17, -19, -22, -14, -36, -22, -21, -25},
    {-28, -21, -22, -29, -49, -35, -31, -57},
    {-30, -31, -36, -32, -57, -44, -33, -47},
    {-40, -40, -40, -48, -61, -54, -42, -55},
    {33, 39, 34, 41, 58, 51, 47, 49},
    {34, 30, 31, 35, 44, 42, 41, 47},
    {39, 46, 44, 50, 51, 59, 48, 61},
    {33, 39, 29, 35, 35, 44, 46, 40},
    {33, 34, 25, 36, 32, 39, 43, 38},
    {33, 43, 42, 38, 38, 54, 57, 44},
    {25, 33, 31, 28, 28, 39, 39, 34},
    {30, 38, 40, 31, 31, 40, 48, 35},
    {47, 46, 46, 48, 58, 60, 54, 69},
    {50, 47, 53, 54, 64, 63, 50, 61},
    {32, 37, 39, 46, 40, 50, 51, 46},
    {32, 41, 44, 35, 65, 53, 38, 53},
    {36, 37, 39, 38, 56, 53, 42, 47},
    {50, 52, 47, 56, 54, 59, 53, 63},
    {49, 46, 51, 53, 61, 61, 57, 72},
    {31, 36, 31, 36, 30, 50, 42, 42},
    {26, 41, 49, 33, 32, 45, 36, 43},
    {37, 44, 48, 51, 40, 58, 53, 56},
    {41, 50, 42, 42, 58, 55, 46, 52},
    {41, 43, 45, 48, 69, 57, 49, 57},
    {43, 45, 46, 52, 63, 61, 49, 59},
    {36, 46, 44, 42, 41, 56, 56, 51},
    {38, 45, 48, 48, 48, 57, 57, 53},
    {43, 52, 52, 49, 59, 67, 58, 65},
    {-24, -27, -32, -36, -54, -43, -34, -52},
    {-36, -28, -27, -36, -48, -40, -32, -66},
    {-21, -21, -24, -23, -37, -27, -21, -42},
    {-10, -11, -23, -8, -20, -15, -22, -29},
    {-30, -26, -29, -26, -60, -39, -31, -51},
    {37, 61, 48, 39, 48, 55, 46, 45},
    {38, 63, 49, 51, 54, 58, 53, 52},
    {38, 61, 37, 40, 42, 44, 45, 42},
    {39, 48, 40, 41, 44, 49, 44, 51},
    {34, 54, 48, 36, 39, 53, 53, 43},
    {31, 56, 37, 32, 35, 45, 41, 34},
    {21, 60, 35, 27, 26, 41, 36, 27},
    {27, 61, 43, 32, 30, 48, 43, 33},
    {34, 45, 35, 39, 34, 48, 37, 35},
    {36, 46, 25, 36, 28, 44, 32, 32},
    {19, 21, 29, 24, 19, 26, 29, 21},
    {34, 58, 44, 39, 43, 56, 48, 43},
    {36, 54, 48, 42, 60, 61, 47, 51},
    {29, 43, 36, 28, 35, 43, 35, 36},
    {35, 57, 42, 42, 42, 52, 42, 41},
    {27, 49, 24, 32, 26, 36, 27, 23},
    {32, 59, 34, 42, 36, 47, 42, 37},
    {47, 67, 52, 49, 43, 61, 55, 47},
    {22, 31, 33, 24, 33, 38, 33, 29},
    {28, 34, 38, 36, 36, 43, 56, 37},
    {25, 27, 35, 36, 29, 39, 55, 33},
    {21, 24, 32, 37, 26, 35, 50, 28},
    {20, 21, 31, 31, 20, 32, 43, 25},
    {17, 24, 20, 21, 17, 28, 36, 12},
    {39, 41, 49, 49, 42, 53, 67, 45},
    {13, 19, 24, 25, 26, 24, 33, 29},
    {37, 38, 50, 43, 45, 51, 59, 49},
    {34, 43, 36, 38, 34, 40, 49, 42},
    {30, 38, 36, 33, 35, 48, 50, 35},
    {40, 50, 47, 49, 48, 58, 64, 49},
    {41, 51, 49, 45, 45, 58, 65, 50},
    {18, 31, 21, 28, 20, 26, 35, 20},
    {16, 23, 24, 27, 23, 33, 36, 19},
    {24, 34, 32, 31, 20, 36, 43, 27},
    {16, 23, 31, 28, 35, 37, 30, 30},
    {38, 38, 39, 32, 32, 41, 51, 37},
    {29, 42, 38, 31, 34, 42, 54, 41},
    {35, 42, 47, 39, 39, 50, 59, 47},
    {31, 45, 41, 39, 32, 45, 53, 43},
    {32, 48, 45, 39, 38, 50, 57, 43},
    {21, 36, 26, 27, 22, 37, 42, 28},
    {19, 31, 23, 25, 17, 33, 45, 22},
    {38, 47, 40, 39, 37, 52, 54, 40},
    {30, 38, 28, 36, 26, 39, 41, 29},
    {41, 49, 47, 45, 42, 53, 58, 47},
    {39, 49, 48, 44, 46, 57, 62, 47},
    {37, 52, 59, 44, 52, 62, 52, 55},
    {35, 49, 60, 46, 60, 67, 53, 55},
    {40, 43, 62, 49, 56, 60, 50, 54},
    {39, 48, 50, 54, 49, 61, 52, 53},
    {23, 44, 54, 30, 40, 53, 43, 38},
    {36, 41, 54, 42, 45, 56, 48, 38},
    {9, 17, 31, 0, 10, 20, 16, 9},
    {33, 34, 45, 28, 34, 44, 40, 31},
    {34, 47, 50, 36, 46, 61, 49, 49},
    {35, 47, 49, 40, 48, 56, 41, 40},
    {44, 58, 46, 52, 51, 67, 55, 47},
    {40, 43, 48, 43, 58, 59, 49, 48},
    {42, 46, 48, 45, 51, 63, 45, 45},
    {33, 39, 50, 41, 42, 53, 43, 42},
    {31, 37, 44, 43, 38, 49, 48, 40},
    {47, 46, 42, 53, 68, 63, 51, 55},
    {39, 47, 43, 47, 61, 58, 51, 50},
    {43, 54, 46, 54, 53, 64, 54, 53},
    {35, 50, 50, 43, 41, 63, 54, 46},
    {38, 47, 35, 32, 29, 49, 46, 35},
    {41, 53, 55, 52, 57, 65, 58, 60},
    {23, 40, 27, 31, 32, 47, 42, 28},
    {17, 37, 58, 14, 29, 40, 34, 28},
    {32, 44, 60, 35, 49, 56, 45, 50},
    {27, 49, 62, 28, 40, 53, 46, 40},
    {30, 50, 65, 34, 43, 53, 47, 46},
    {41, 44, 64, 46, 54, 60, 47, 51},
    {34, 56, 57, 56, 45, 60, 56, 48},
    {14, 23, 37, 13, 13, 21, 24, 14},
    {-3, 7, 32, 0, 11, 11, 11, 7},
    {19, 17, 41, 22, 34, 36, 28, 28},
    {25, 40, 50, 29, 32, 42, 33, 33},
    {21, 34, 44, 14, 28, 40, 33, 27},
    {34, 47, 61, 36, 46, 59, 44, 42},
    {10, 18, 23, 3, 15, 17, 12, 12},
    {6, 9, 21, 0, 8, 9, 4, 9},
    {36, 47, 59, 46, 58, 62, 56, 56},
    {25, 38, 33, 30, 30, 39, 33, 34},
    {37, 34, 35, 33, 35, 44, 37, 37},
    {19, 31, 31, 34, 26, 41, 35, 22},
    {29, 38, 42, 39, 37, 55, 45, 36},
    {32, 47, 45, 37, 43, 57, 47, 43},
    {32, 28, 30, 37, 34, 43, 37, 38},
    {25, 33, 42, 37, 53, 43, 39, 47},
    {34, 46, 49, 39, 45, 57, 48, 44},
    {15, 27, 37, 33, 28, 40, 37, 34},
    {39, 42, 46, 53, 52, 58, 56, 46},
    {37, 34, 30, 46, 55, 51, 43, 44},
    {44, 41, 36, 51, 52, 58, 43, 53},
    {44, 41, 35, 49, 36, 49, 45, 46},
    {33, 29, 23, 42, 24, 37, 39, 30},
    {47, 46, 47, 59, 55, 63, 55, 61},
    {37, 42, 39, 48, 44, 56, 45, 45},
    {37, 38, 30, 49, 45, 48, 46, 54},
    {46, 42, 41, 59, 57, 60, 49, 59},
    {46, 48, 41, 57, 50, 61, 51, 60},
    {38, 37, 33, 31, 38, 43, 37, 46},
    {37, 43, 40, 53, 35, 54, 50, 45},
    {36, 41, 41, 59, 46, 50, 45, 43},
    {28, 28, 27, 47, 44, 45, 40, 34},
    {37, 45, 44, 50, 44, 51, 46, 42},
    {28, 34, 34, 45, 26, 42, 51, 40},
    {35, 45, 40, 56, 38, 53, 55, 42},
    {36, 47, 41, 64, 42, 58, 48, 50},
    {29, 39, 32, 52, 32, 41, 42, 35},
    {27, 32, 30, 31, 27, 37, 33, 35},
    {28, 32, 29, 48, 36, 42, 38, 40},
    {24, 25, 4, 36, 11, 24, 22, 16},
    {53, 42, 28, 41, 36, 44, 42, 42},
    {68, 38, 31, 41, 39, 49, 42, 42},
    {59, 38, 34, 45, 45, 46, 40, 48},
    {57, 38, 32, 34, 37, 41, 41, 43},
    {63, 39, 29, 39, 31, 46, 38, 40},
    {63, 48, 42, 50, 40, 57, 55, 50},
    {40, 32, 32, 40, 36, 43, 37, 42},
    {32, 33, 34, 35, 31, 40, 46, 31},
    {31, 37, 20, 30, 28, 32, 31, 30},
    {21, 29, 21, 28, 16, 30, 26, 19},
    {34, 35, 33, 32, 29, 44, 36, 36},
    {28, 31, 34, 33, 28, 39, 32, 32},
    {33, 47, 31, 48, 49, 59, 43, 44}
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

        for (i = 0; i < 180; i++)
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

	for (fieldno = 0; fieldno < 194; fieldno++)
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
					Row.Retake = atoi(valstr);
					break;

				case 11:
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

				case 12:
					Row.AsResult = atoi(valstr);
					break;

				case 13:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 14;
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
	TFile infile("quizr3.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 180; i++)
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
