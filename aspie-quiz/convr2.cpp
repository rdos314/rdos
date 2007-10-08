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
# convr2.cpp
# Convert exported quiz-r2 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr2.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r2 VALUES(";

TFile quizfile("quizr2.bin", 0);

static int Gw[165][8] = 
{
    {23, 25, 20, 21, 23, 30, 30, 23},
    {16, 22, 21, 13, 20, 20, 22, 20},
    {19, 32, 21, 18, 21, 28, 30, 23},
    {62, 38, 31, 43, 41, 43, 40, 48},
    {52, 38, 31, 45, 38, 47, 40, 47},
    {58, 36, 35, 42, 43, 46, 44, 48},
    {63, 42, 38, 48, 35, 44, 52, 48},
    {53, 42, 27, 40, 35, 43, 40, 42},
    {56, 37, 31, 33, 36, 38, 39, 43},
    {34, 58, 44, 37, 42, 55, 46, 43},
    {36, 59, 39, 36, 37, 51, 41, 38},
    {33, 54, 47, 34, 38, 51, 50, 41},
    {38, 60, 45, 42, 49, 56, 46, 44},
    {31, 48, 44, 34, 43, 55, 49, 43},
    {37, 46, 35, 38, 33, 46, 44, 44},
    {24, 47, 43, 33, 38, 53, 45, 37},
    {28, 43, 35, 27, 35, 42, 34, 36},
    {28, 55, 40, 26, 28, 42, 37, 32},
    {36, 44, 30, 36, 30, 44, 41, 36},
    {31, 43, 34, 28, 31, 41, 43, 33},
    {28, 56, 38, 26, 29, 44, 41, 31},
    {29, 40, 33, 30, 29, 42, 41, 32},
    {27, 42, 31, 34, 27, 37, 46, 31},
    {27, 47, 31, 21, 25, 36, 38, 30},
    {19, 30, 29, 23, 29, 36, 27, 25},
    {21, 27, 33, 22, 27, 31, 27, 23},
    {16, 31, 27, 31, 25, 36, 27, 19},
    {36, 52, 58, 43, 51, 60, 49, 55},
    {31, 43, 59, 34, 49, 55, 42, 49},
    {29, 50, 64, 32, 43, 51, 44, 45},
    {26, 48, 61, 25, 39, 51, 42, 39},
    {32, 44, 58, 33, 38, 47, 44, 42},
    {29, 42, 52, 35, 36, 47, 37, 45},
    {25, 43, 52, 31, 36, 46, 34, 37},
    {17, 37, 57, 13, 28, 38, 31, 28},
    {16, 29, 38, 7, 25, 35, 28, 24},
    {36, 40, 37, 56, 45, 47, 41, 40},
    {27, 32, 26, 48, 35, 41, 36, 39},
    {35, 38, 33, 58, 42, 49, 45, 41},
    {-24, -19, -11, -41, -32, -26, -23, -30},
    {24, 34, 34, 32, 30, 39, 38, 39},
    {32, 28, 21, 42, 22, 36, 36, 29},
    {39, 40, 43, 41, 67, 56, 43, 61},
    {47, 48, 47, 57, 70, 69, 55, 68},
    {38, 50, 47, 39, 62, 58, 41, 50},
    {35, 47, 58, 44, 58, 60, 53, 55},
    {35, 39, 39, 42, 60, 52, 46, 55},
    {36, 43, 41, 43, 66, 58, 44, 55},
    {34, 51, 48, 40, 59, 57, 50, 44},
    {32, 40, 43, 34, 64, 52, 37, 53},
    {35, 37, 37, 37, 55, 52, 39, 46},
    {33, 55, 49, 39, 59, 59, 45, 49},
    {27, 42, 51, 38, 59, 59, 45, 49},
    {-29, -30, -35, -30, -57, -43, -33, -46},
    {27, 40, 46, 29, 53, 51, 37, 42},
    {-32, -30, -27, -30, -63, -37, -31, -49},
    {34, 42, 40, 39, 67, 59, 41, 46},
    {31, 42, 38, 34, 49, 52, 44, 47},
    {23, 31, 40, 36, 53, 41, 38, 46},
    {27, 38, 32, 34, 48, 48, 31, 38},
    {-34, -27, -23, -32, -55, -37, -27, -45},
    {-28, -38, -28, -22, -58, -47, -27, -44},
    {29, 35, 38, 35, 45, 53, 38, 47},
    {37, 45, 45, 41, 48, 54, 43, 44},
    {-28, -31, -39, -25, -49, -39, -34, -44},
    {-25, -29, -28, -23, -59, -42, -31, -41},
    {-25, -30, -32, -28, -55, -36, -30, -35},
    {-22, -28, -31, -22, -52, -37, -22, -41},
    {-25, -31, -35, -25, -47, -41, -33, -43},
    {-33, -35, -19, -29, -46, -42, -31, -37},
    {28, 38, 31, 32, 49, 50, 30, 36},
    {35, 44, 40, 40, 39, 52, 41, 40},
    {24, 34, 39, 18, 42, 46, 40, 37},
    {16, 24, 23, 19, 34, 33, 26, 26},
    {-19, -26, -23, -18, -56, -31, -20, -32},
    {-11, -18, -25, -14, -41, -21, -17, -30},
    {-13, -10, -13, -8, -42, -14, -11, -31},
    {35, 45, 42, 41, 40, 56, 54, 50},
    {31, 43, 43, 37, 37, 54, 60, 44},
    {38, 46, 38, 44, 44, 54, 60, 47},
    {28, 37, 38, 35, 35, 43, 56, 38},
    {28, 42, 35, 27, 30, 40, 50, 33},
    {29, 37, 34, 32, 33, 46, 49, 34},
    {29, 33, 27, 32, 32, 41, 46, 34},
    {35, 47, 38, 40, 40, 48, 61, 42},
    {29, 31, 30, 31, 25, 41, 52, 30},
    {27, 34, 26, 26, 25, 32, 38, 26},
    {28, 34, 37, 41, 35, 37, 54, 36},
    {6, 32, 31, 27, 22, 35, 37, 29},
    {47, 46, 46, 47, 58, 59, 52, 69},
    {47, 45, 49, 51, 61, 60, 55, 72},
    {39, 46, 45, 43, 46, 58, 54, 60},
    {33, 48, 55, 43, 48, 59, 52, 62},
    {38, 46, 42, 40, 46, 57, 44, 61},
    {43, 42, 40, 44, 50, 55, 53, 54},
    {36, 38, 29, 48, 44, 47, 43, 54},
    {39, 36, 36, 38, 45, 48, 46, 55},
    {45, 41, 37, 46, 42, 50, 46, 60},
    {47, 39, 39, 40, 44, 53, 51, 52},
    {39, 47, 39, 40, 43, 47, 42, 51},
    {-23, -29, -33, -35, -53, -44, -35, -53},
    {38, 36, 33, 29, 37, 42, 36, 45},
    {-29, -21, -21, -28, -49, -35, -30, -58},
    {35, 40, 37, 42, 40, 52, 56, 47},
    {28, 37, 38, 43, 34, 50, 51, 45},
    {41, 53, 43, 51, 51, 62, 50, 51},
    {34, 47, 47, 37, 37, 54, 48, 51},
    {38, 49, 40, 40, 56, 52, 45, 52},
    {31, 43, 46, 40, 52, 56, 44, 50},
    {39, 44, 40, 36, 38, 50, 41, 44},
    {32, 41, 33, 49, 42, 52, 40, 44},
    {37, 41, 38, 50, 34, 53, 49, 43},
    {35, 40, 34, 44, 40, 54, 43, 44},
    {27, 35, 34, 35, 33, 46, 37, 37},
    {27, 35, 30, 32, 28, 52, 37, 41},
    {28, 33, 24, 30, 25, 37, 38, 30},
    {20, 28, 27, 32, 35, 49, 37, 30},
    {18, 38, 25, 29, 31, 46, 42, 27},
    {18, 29, 33, 28, 26, 51, 43, 27},
    {20, 30, 20, 22, 20, 39, 36, 23},
    {34, 47, 58, 44, 58, 65, 49, 54},
    {35, 45, 45, 52, 45, 60, 47, 50},
    {39, 49, 48, 47, 51, 65, 47, 53},
    {36, 48, 44, 38, 50, 62, 47, 47},
    {38, 50, 47, 41, 50, 65, 49, 52},
    {34, 43, 47, 40, 53, 60, 45, 53},
    {33, 48, 50, 35, 45, 61, 47, 49},
    {34, 49, 48, 41, 40, 62, 51, 45},
    {29, 43, 50, 21, 36, 50, 38, 39},
    {21, 44, 52, 26, 39, 51, 39, 37},
    {37, 46, 34, 32, 29, 49, 44, 34},
    {32, 40, 27, 31, 30, 44, 43, 31},
    {-18, -21, -13, -12, -21, -16, -15, -23},
    {12, 30, 35, 10, 25, 32, 20, 22},
    {17, 25, 21, 21, 22, 31, 25, 24},
    {42, 51, 52, 48, 59, 66, 56, 65},
    {40, 50, 53, 45, 51, 64, 56, 61},
    {46, 48, 40, 57, 49, 61, 50, 59},
    {38, 50, 52, 50, 56, 63, 56, 61},
    {45, 45, 45, 55, 52, 61, 50, 58},
    {41, 41, 46, 51, 53, 58, 43, 55},
    {44, 46, 46, 52, 45, 54, 55, 56},
    {33, 48, 40, 46, 40, 54, 45, 45},
    {32, 45, 48, 36, 43, 55, 46, 43},
    {43, 40, 33, 49, 50, 58, 43, 53},
    {-33, -31, -28, -34, -49, -38, -31, -52},
    {30, 42, 46, 37, 50, 56, 51, 41},
    {43, 40, 33, 48, 35, 46, 40, 45},
    {40, 42, 42, 49, 50, 56, 51, 43},
    {38, 35, 31, 43, 54, 52, 40, 44},
    {30, 38, 34, 40, 56, 49, 44, 48},
    {30, 38, 41, 37, 66, 54, 37, 43},
    {33, 39, 29, 35, 35, 43, 46, 39},
    {38, 29, 31, 40, 35, 42, 37, 43},
    {24, 37, 35, 44, 41, 52, 47, 40},
    {24, 38, 30, 28, 28, 37, 29, 32},
    {32, 33, 22, 36, 29, 37, 42, 37},
    {31, 26, 27, 34, 30, 40, 34, 37},
    {23, 29, 27, 24, 26, 37, 33, 32},
    {29, 23, 22, 43, 27, 33, 31, 31},
    {14, 30, 31, 14, 13, 25, 23, 18},
    {20, 25, 15, 22, 14, 31, 28, 22},
    {10, 20, 29, 26, 24, 34, 30, 29},
    {15, 31, 29, 11, 27, 35, 30, 24},
    {17, 19, 29, 16, 27, 25, 22, 23}
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

        for (i = 0; i < 165; i++)
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

				case 11:
					Row.AsResult = atoi(valstr);
					break;

				case 12:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 13;
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
	TFile infile("quizr2.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 165; i++)
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
