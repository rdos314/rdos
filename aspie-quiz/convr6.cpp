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
# convr6.cpp
# Convert exported quiz-r6 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr6.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r6 VALUES(";

TFile quizfile("quizr6.bin", 0);

static int Gw[147][8] = 
{
    {25, 36, 31, 30, 29, 37, 31, 32},
    {31, 29, 30, 29, 26, 38, 34, 27},
    {59, 43, 38, 45, 36, 50, 52, 46},
    {63, 43, 37, 46, 36, 46, 50, 46},
    {53, 40, 26, 41, 35, 43, 42, 40},
    {55, 34, 30, 33, 35, 39, 37, 40},
    {36, 62, 50, 39, 47, 55, 45, 46},
    {34, 58, 44, 39, 43, 55, 48, 42},
    {33, 52, 47, 36, 38, 52, 53, 40},
    {32, 60, 40, 33, 36, 45, 42, 31},
    {28, 48, 31, 34, 32, 43, 41, 29},
    {27, 55, 40, 26, 27, 42, 38, 30},
    {28, 56, 38, 27, 30, 44, 41, 30},
    {31, 43, 34, 27, 31, 41, 44, 33},
    {36, 51, 58, 44, 51, 62, 52, 53},
    {29, 49, 56, 38, 48, 55, 43, 47},
    {32, 43, 59, 35, 48, 56, 45, 48},
    {30, 51, 55, 48, 37, 56, 52, 38},
    {30, 49, 64, 35, 42, 54, 48, 44},
    {34, 39, 49, 39, 45, 49, 45, 42},
    {22, 44, 62, 34, 39, 56, 48, 41},
    {26, 48, 62, 29, 39, 54, 48, 39},
    {25, 43, 54, 30, 38, 49, 39, 35},
    {31, 38, 48, 35, 35, 50, 43, 35},
    {16, 33, 42, 31, 28, 40, 32, 30},
    {27, 31, 29, 48, 36, 41, 37, 39},
    {29, 34, 33, 55, 35, 46, 40, 35},
    {29, 33, 23, 48, 28, 42, 34, 33},
    {46, 42, 47, 53, 69, 65, 57, 65},
    {45, 47, 47, 41, 62, 55, 41, 53},
    {37, 49, 46, 39, 61, 57, 43, 48},
    {39, 41, 58, 42, 56, 57, 48, 50},
    {36, 47, 53, 40, 57, 59, 46, 48},
    {38, 38, 45, 45, 60, 56, 51, 55},
    {29, 42, 49, 36, 55, 55, 49, 53},
    {44, 40, 37, 46, 59, 56, 49, 44},
    {38, 41, 47, 40, 47, 59, 45, 44},
    {36, 46, 49, 39, 46, 57, 49, 40},
    {35, 40, 45, 40, 51, 56, 45, 45},
    {36, 39, 41, 43, 61, 54, 50, 51},
    {29, 37, 49, 36, 55, 55, 44, 43},
    {-37, -31, -35, -41, -59, -47, -39, -46},
    {-34, -32, -32, -31, -61, -42, -34, -52},
    {40, 38, 33, 47, 48, 54, 41, 45},
    {-29, -25, -33, -36, -70, -46, -36, -56},
    {-29, -33, -42, -29, -53, -43, -35, -47},
    {33, 34, 29, 36, 55, 46, 37, 43},
    {30, 45, 38, 36, 49, 52, 41, 42},
    {-29, -29, -29, -34, -60, -43, -31, -48},
    {31, 43, 40, 34, 38, 45, 38, 30},
    {-32, -30, -28, -32, -63, -40, -33, -48},
    {-29, -28, -27, -22, -65, -34, -26, -45},
    {-26, -22, -27, -20, -54, -36, -30, -44},
    {-26, -27, -33, -38, -53, -44, -37, -50},
    {-26, -32, -37, -27, -50, -44, -34, -47},
    {-28, -32, -42, -27, -52, -42, -36, -46},
    {-29, -29, -21, -25, -50, -41, -26, -43},
    {-27, -25, -32, -30, -55, -41, -36, -44},
    {-22, -24, -26, -24, -49, -28, -24, -30},
    {-20, -28, -31, -25, -41, -39, -27, -32},
    {21, 24, 26, 22, 44, 38, 29, 29},
    {-26, -24, -19, -25, -46, -29, -27, -27},
    {-19, -16, -6, -20, -29, -21, -13, -20},
    {36, 49, 58, 46, 57, 65, 54, 51},
    {41, 51, 44, 52, 50, 62, 52, 48},
    {37, 45, 44, 52, 45, 57, 52, 44},
    {32, 46, 48, 42, 47, 63, 47, 47},
    {33, 48, 48, 40, 56, 58, 54, 44},
    {35, 50, 49, 43, 41, 63, 55, 44},
    {33, 46, 49, 37, 45, 60, 50, 47},
    {33, 44, 48, 38, 44, 56, 49, 43},
    {36, 44, 49, 47, 44, 60, 54, 55},
    {33, 44, 45, 41, 51, 56, 48, 46},
    {45, 48, 45, 51, 45, 57, 57, 52},
    {37, 42, 45, 50, 49, 58, 54, 41},
    {36, 46, 43, 42, 41, 55, 55, 48},
    {38, 52, 44, 45, 45, 62, 55, 42},
    {-27, -25, -37, -27, -45, -42, -35, -45},
    {35, 41, 41, 37, 49, 57, 56, 44},
    {31, 41, 33, 49, 41, 53, 40, 42},
    {36, 42, 36, 38, 49, 50, 47, 44},
    {31, 37, 40, 43, 40, 52, 52, 45},
    {26, 41, 30, 43, 42, 53, 39, 32},
    {29, 38, 49, 37, 34, 52, 46, 34},
    {22, 37, 45, 40, 40, 50, 49, 39},
    {31, 41, 37, 47, 28, 48, 44, 34},
    {24, 47, 43, 33, 38, 52, 49, 37},
    {32, 36, 29, 35, 35, 43, 48, 37},
    {26, 31, 32, 33, 33, 46, 35, 36},
    {27, 34, 35, 37, 34, 42, 42, 31},
    {35, 44, 31, 34, 33, 44, 42, 35},
    {36, 44, 36, 36, 32, 47, 44, 40},
    {28, 36, 32, 36, 32, 49, 42, 37},
    {25, 37, 38, 34, 26, 53, 44, 33},
    {29, 36, 29, 35, 27, 42, 46, 38},
    {16, 34, 37, 33, 26, 43, 38, 32},
    {19, 34, 33, 29, 22, 41, 41, 25},
    {17, 29, 27, 26, 28, 39, 34, 22},
    {29, 44, 42, 37, 39, 55, 63, 42},
    {30, 40, 37, 39, 34, 47, 55, 31},
    {32, 41, 42, 40, 38, 52, 63, 38},
    {32, 42, 42, 37, 37, 53, 59, 41},
    {32, 42, 45, 39, 38, 53, 60, 42},
    {30, 47, 43, 40, 35, 53, 59, 37},
    {32, 44, 39, 37, 36, 51, 58, 37},
    {30, 36, 41, 37, 35, 47, 54, 37},
    {24, 33, 37, 37, 29, 45, 55, 33},
    {29, 35, 36, 32, 32, 46, 49, 32},
    {23, 36, 31, 30, 24, 36, 43, 26},
    {28, 37, 33, 34, 29, 46, 51, 32},
    {28, 36, 26, 33, 24, 41, 47, 27},
    {21, 30, 28, 31, 24, 40, 50, 25},
    {24, 32, 23, 25, 13, 31, 41, 19},
    {47, 45, 46, 48, 58, 60, 55, 68},
    {41, 51, 54, 47, 51, 65, 60, 60},
    {37, 47, 49, 43, 48, 58, 49, 64},
    {43, 44, 49, 56, 53, 62, 54, 58},
    {39, 44, 47, 43, 46, 58, 57, 59},
    {38, 40, 43, 36, 47, 52, 46, 62},
    {38, 45, 43, 40, 46, 58, 45, 61},
    {-40, -30, -36, -33, -60, -46, -36, -66},
    {-31, -29, -44, -41, -61, -51, -44, -55},
    {30, 43, 53, 40, 44, 55, 49, 54},
    {38, 38, 41, 42, 46, 53, 50, 49},
    {37, 36, 29, 50, 46, 48, 47, 53},
    {-36, -26, -31, -31, -55, -41, -32, -67},
    {-42, -32, -41, -40, -59, -48, -47, -62},
    {-33, -32, -35, -35, -53, -45, -39, -61},
    {39, 48, 39, 41, 42, 48, 46, 48},
    {44, 38, 39, 38, 44, 53, 54, 49},
    {33, 45, 47, 38, 37, 54, 49, 49},
    {-35, -29, -31, -52, -50, -46, -39, -48},
    {-41, -24, -35, -38, -60, -46, -42, -65},
    {56, 34, 32, 42, 43, 43, 39, 47},
    {36, 39, 35, 44, 42, 51, 43, 40},
    {-36, -22, -23, -35, -31, -35, -30, -34},
    {37, 34, 33, 36, 39, 40, 35, 49},
    {37, 41, 40, 36, 38, 50, 42, 41},
    {37, 36, 33, 26, 37, 41, 31, 53},
    {-36, -22, -30, -30, -42, -33, -30, -49},
    {-29, -28, -43, -31, -49, -45, -40, -51},
    {-26, -26, -39, -29, -50, -43, -40, -46},
    {28, 37, 33, 38, 30, 41, 40, 30},
    {32, 30, 31, 36, 35, 44, 38, 38},
    {-33, -17, -28, -36, -43, -34, -29, -48},
    {32, 31, 25, 35, 31, 38, 43, 37},
    {-30, -30, -35, -29, -61, -47, -38, -46}
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

        for (i = 0; i < 147; i++)
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

	for (fieldno = 0; fieldno < 160; fieldno++)
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
	TFile infile("quizr6.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 147; i++)
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
