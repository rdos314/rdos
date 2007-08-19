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
# convs2.cpp
# Convert exported quiz-s2 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbs2.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-s2 VALUES (";

TFile quizfile("quizs2.bin", 0);

static int Gw[170][8] = 
{
    {62, 45, 41, 49, 41, 53, 55, 51},
    {54, 35, 35, 45, 45, 47, 42, 49},
    {57, 42, 40, 46, 38, 51, 52, 49},
    {54, 40, 27, 42, 36, 44, 44, 41},
    {55, 34, 31, 35, 37, 42, 39, 42},
    {38, 61, 52, 42, 48, 58, 51, 49},
    {35, 57, 45, 40, 43, 56, 49, 44},
    {38, 50, 43, 40, 38, 55, 52, 45},
    {35, 58, 42, 39, 38, 48, 47, 38},
    {33, 47, 35, 37, 36, 45, 43, 35},
    {38, 51, 59, 47, 53, 64, 54, 56},
    {39, 40, 58, 43, 56, 56, 51, 53},
    {31, 49, 57, 40, 49, 57, 47, 49},
    {33, 43, 60, 36, 48, 56, 47, 49},
    {31, 49, 64, 36, 42, 54, 50, 46},
    {34, 51, 56, 49, 40, 57, 53, 43},
    {31, 45, 63, 38, 41, 55, 54, 46},
    {28, 48, 62, 31, 40, 54, 49, 41},
    {33, 39, 50, 37, 38, 51, 46, 40},
    {27, 42, 54, 33, 38, 50, 40, 39},
    {47, 48, 43, 59, 51, 62, 55, 60},
    {-41, -37, -43, -55, -53, -52, -47, -55},
    {44, 40, 36, 50, 36, 50, 45, 47},
    {33, 41, 36, 50, 42, 53, 43, 44},
    {35, 38, 37, 57, 36, 52, 46, 42},
    {29, 31, 31, 48, 36, 43, 40, 41},
    {32, 39, 37, 43, 35, 46, 42, 38},
    {31, 40, 38, 46, 27, 48, 44, 35},
    {31, 34, 26, 47, 30, 43, 37, 37},
    {48, 43, 50, 55, 68, 67, 59, 69},
    {50, 48, 50, 47, 63, 58, 48, 56},
    {38, 49, 47, 41, 61, 59, 46, 50},
    {43, 34, 46, 45, 67, 55, 48, 55},
    {38, 47, 55, 42, 58, 62, 50, 51},
    {45, 42, 42, 50, 62, 61, 52, 50},
    {41, 39, 48, 47, 59, 58, 54, 58},
    {40, 49, 48, 43, 58, 57, 49, 50},
    {43, 48, 42, 43, 55, 55, 49, 51},
    {39, 39, 43, 45, 60, 55, 50, 53},
    {30, 38, 50, 38, 55, 53, 44, 44},
    {-40, -33, -39, -45, -62, -51, -42, -53},
    {-36, -32, -35, -33, -62, -46, -39, -53},
    {35, 35, 33, 38, 58, 50, 41, 47},
    {-33, -31, -39, -34, -57, -46, -39, -50},
    {-32, -31, -34, -37, -62, -47, -36, -51},
    {-37, -34, -38, -39, -68, -48, -40, -51},
    {-32, -25, -37, -37, -66, -46, -37, -53},
    {28, 31, 43, 37, 50, 45, 40, 46},
    {-32, -37, -34, -30, -58, -48, -33, -48},
    {35, 28, 31, 42, 51, 48, 43, 41},
    {31, 38, 33, 35, 50, 48, 36, 36},
    {-30, -33, -44, -30, -52, -45, -39, -47},
    {-28, -27, -34, -38, -52, -43, -39, -49},
    {-32, -29, -35, -33, -54, -43, -35, -49},
    {-23, -28, -32, -24, -52, -38, -26, -42},
    {-25, -22, -28, -23, -52, -37, -27, -43},
    {-22, -26, -29, -22, -55, -35, -26, -37},
    {38, 50, 60, 49, 59, 66, 56, 55},
    {44, 52, 47, 55, 53, 64, 55, 52},
    {38, 47, 59, 48, 57, 63, 58, 58},
    {45, 44, 51, 57, 54, 63, 55, 59},
    {39, 49, 47, 42, 53, 63, 52, 50},
    {31, 42, 51, 39, 56, 57, 53, 55},
    {35, 44, 48, 41, 54, 61, 49, 54},
    {35, 46, 51, 47, 49, 64, 52, 50},
    {40, 45, 46, 53, 47, 58, 53, 48},
    {37, 50, 51, 45, 42, 63, 57, 46},
    {39, 44, 52, 49, 46, 61, 56, 59},
    {34, 47, 50, 39, 45, 60, 50, 48},
    {39, 47, 51, 44, 46, 58, 52, 47},
    {48, 48, 47, 52, 45, 58, 58, 52},
    {41, 52, 47, 48, 46, 62, 55, 47},
    {42, 39, 44, 46, 47, 55, 54, 52},
    {41, 39, 36, 49, 50, 55, 44, 48},
    {38, 42, 47, 50, 50, 59, 55, 45},
    {34, 43, 45, 42, 50, 56, 49, 46},
    {37, 40, 51, 44, 48, 53, 47, 47},
    {42, 44, 41, 45, 50, 56, 49, 46},
    {34, 44, 48, 39, 37, 54, 49, 50},
    {35, 46, 45, 39, 43, 55, 49, 44},
    {37, 39, 37, 46, 44, 53, 43, 43},
    {37, 41, 40, 37, 39, 50, 42, 42},
    {34, 44, 42, 38, 42, 49, 41, 38},
    {31, 41, 34, 44, 45, 52, 42, 36},
    {27, 48, 45, 36, 37, 52, 51, 41},
    {29, 33, 35, 36, 36, 48, 38, 39},
    {30, 36, 35, 38, 34, 49, 43, 39},
    {37, 44, 34, 37, 35, 47, 44, 38},
    {25, 36, 37, 33, 25, 49, 41, 32},
    {26, 36, 33, 31, 30, 39, 32, 35},
    {28, 35, 36, 37, 34, 44, 42, 33},
    {51, 52, 66, 57, 56, 72, 66, 68},
    {41, 45, 49, 46, 47, 59, 59, 59},
    {42, 43, 47, 45, 52, 58, 57, 50},
    {37, 45, 44, 44, 41, 56, 56, 51},
    {39, 45, 48, 44, 43, 57, 64, 49},
    {46, 38, 42, 41, 45, 54, 56, 51},
    {34, 51, 48, 38, 38, 53, 54, 42},
    {38, 42, 44, 42, 41, 54, 64, 44},
    {38, 41, 50, 47, 42, 54, 65, 48},
    {35, 43, 47, 42, 39, 53, 59, 45},
    {34, 42, 43, 39, 37, 53, 59, 44},
    {38, 44, 41, 41, 39, 52, 59, 42},
    {38, 41, 40, 44, 39, 53, 59, 48},
    {32, 35, 40, 42, 38, 51, 51, 45},
    {35, 47, 44, 41, 36, 51, 59, 41},
    {33, 37, 43, 40, 38, 48, 55, 40},
    {33, 42, 39, 41, 34, 48, 55, 36},
    {30, 36, 38, 33, 34, 47, 50, 36},
    {33, 36, 30, 35, 35, 44, 49, 38},
    {30, 37, 42, 40, 35, 49, 43, 40},
    {24, 29, 25, 24, 30, 31, 32, 22},
    {25, 32, 30, 34, 26, 42, 50, 31},
    {44, 52, 55, 52, 60, 68, 62, 65},
    {48, 45, 48, 50, 59, 61, 57, 69},
    {43, 51, 56, 49, 52, 66, 62, 61},
    {38, 48, 51, 45, 49, 60, 53, 64},
    {39, 40, 44, 38, 48, 54, 49, 62},
    {40, 46, 46, 43, 47, 60, 50, 61},
    {42, 46, 57, 51, 45, 62, 58, 61},
    {44, 42, 44, 42, 45, 56, 54, 64},
    {-41, -31, -38, -36, -62, -49, -40, -67},
    {-44, -36, -45, -45, -59, -51, -49, -65},
    {33, 43, 55, 42, 44, 55, 49, 56},
    {39, 36, 32, 51, 47, 50, 48, 53},
    {40, 49, 41, 44, 44, 51, 48, 49},
    {-34, -33, -37, -37, -53, -46, -41, -62},
    {42, 36, 36, 40, 39, 44, 44, 50},
    {-35, -32, -32, -37, -52, -42, -38, -55},
    {-39, -30, -38, -44, -52, -45, -38, -63},
    {-33, -32, -40, -34, -49, -44, -42, -46},
    {38, 33, 31, 32, 37, 40, 36, 46},
    {-35, -23, -35, -35, -50, -39, -36, -58},
    {-33, -22, -29, -44, -49, -38, -30, -48},
    {-30, -28, -35, -35, -47, -40, -34, -46},
    {-37, -34, -47, -45, -61, -55, -46, -59},
    {-39, -31, -34, -54, -50, -48, -41, -54},
    {-39, -36, -32, -30, -55, -42, -32, -43},
    {-29, -31, -23, -31, -38, -40, -30, -40},
    {-36, -23, -30, -38, -40, -35, -34, -47},
    {11, 17, 10, 17, 8, 14, 11, 11},
    {19, 17, 10, 26, 10, 14, 12, 13},
    {20, 29, 21, 19, 18, 27, 26, 18},
    {11, 15, 11, 12, 7, 15, 15, 12},
    {18, 26, 16, 19, 15, 23, 20, 15},
    {25, 27, 21, 26, 36, 31, 26, 28},
    {8, 21, 6, 5, 3, 8, 9, 2},
    {4, 7, 3, 0, -2, 2, 3, -1},
    {6, 19, 3, 3, 0, 7, 7, 0},
    {12, 46, 24, 11, 9, 28, 26, 12},
    {13, 38, 14, 18, 5, 23, 20, 9},
    {14, 35, 17, 21, 8, 23, 24, 11},
    {14, 46, 27, 22, 15, 31, 29, 18},
    {41, 43, 58, 59, 59, 66, 65, 63},
    {17, 33, 42, 27, 18, 36, 34, 26},
    {51, 38, 51, 50, 72, 66, 59, 66},
    {-27, -22, -35, -35, -55, -38, -40, -49},
    {-39, -32, -46, -45, -71, -52, -50, -62},
    {31, 32, 25, 37, 37, 37, 32, 29},
    {0, 12, 5, 6, -11, 2, 5, -3},
    {-5, -11, -4, -13, -7, -12, -6, -7},
    {-27, -27, -18, -20, -22, -28, -25, -27},
    {1, 0, -4, -5, -11, -3, -6, -8},
    {2, 0, 4, 0, 3, 2, 0, 3},
    {-12, -11, -11, -12, -11, -12, -11, -16},
    {5, 16, 2, 1, -2, 2, 1, 0},
    {8, 12, 4, 2, 2, 4, 4, 5},
    {2, 11, 6, 0, 3, 6, 5, 3},
    {-38, -42, -42, -42, -61, -49, -43, -45},
    {9, 19, 13, 6, 10, 12, 11, 12}
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

        for (i = 0; i < 135; i++)
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

	for (fieldno = 0; fieldno < 197; fieldno++)
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
					Row.Quiz[140] = Row.Dyslexia;
					break;

				case 14:
					Row.Dyscalculia = atoi(valstr);
					Row.Quiz[141] = Row.Dyscalculia;
					break;

				case 15:
					Row.OCD = atoi(valstr);
					Row.Quiz[142] = Row.OCD;
					break;

				case 16:
					Row.ODD = atoi(valstr);
					Row.Quiz[143] = Row.ODD;
					break;

				case 17:
					Row.Bipolar = atoi(valstr);
					Row.Quiz[144] = Row.Bipolar;
					break;

				case 18:
					Row.Schizophrenia = atoi(valstr);
					break;

				case 19:
					Row.Social = atoi(valstr);
					Row.Quiz[145] = Row.Social;
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

				default:
					i = fieldno - 23;

					if (i >= 140)
						i += 6;

					if (i >= 160)
					{
						i -= 160;

						if (i % 2 == 0)
							Row.ViewTime[i/2] = atoi(valstr);
						else
						{
							Row.Rating[i/2] = atoi(valstr);
							Row.Quiz[160 + i/2] = atoi(valstr);
						}
					}
					else
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
	TFile infile("quizs2.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 135; i++)
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
