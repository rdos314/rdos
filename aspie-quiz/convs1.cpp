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
# convs1.cpp
# Convert exported quiz-s1 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbs1.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-s1 VALUES (";

TFile quizfile("quizs1.bin", 0);

static int Gw[162][8] = 
{
    {55, 36, 35, 44, 45, 47, 41, 49},
    {62, 46, 41, 49, 40, 52, 54, 50},
    {57, 43, 40, 46, 38, 51, 52, 48},
    {54, 40, 27, 42, 35, 44, 43, 41},
    {55, 35, 31, 34, 36, 41, 38, 42},
    {37, 62, 52, 41, 48, 57, 49, 48},
    {35, 58, 45, 40, 43, 56, 49, 43},
    {38, 50, 42, 39, 38, 54, 50, 44},
    {34, 59, 42, 38, 38, 48, 46, 36},
    {32, 48, 34, 37, 36, 45, 43, 35},
    {38, 51, 59, 46, 53, 64, 53, 55},
    {38, 41, 58, 43, 56, 56, 51, 52},
    {31, 49, 57, 39, 49, 56, 46, 49},
    {32, 43, 60, 36, 48, 56, 46, 49},
    {31, 49, 64, 36, 42, 54, 49, 46},
    {30, 47, 63, 39, 41, 56, 53, 46},
    {33, 51, 56, 49, 40, 57, 53, 43},
    {27, 48, 62, 30, 40, 54, 49, 40},
    {33, 40, 50, 37, 37, 51, 45, 38},
    {27, 43, 54, 34, 39, 50, 41, 39},
    {47, 48, 42, 58, 51, 62, 55, 60},
    {44, 41, 36, 50, 36, 50, 45, 47},
    {32, 41, 35, 50, 42, 53, 42, 44},
    {-42, -41, -44, -55, -54, -51, -47, -56},
    {36, 38, 37, 58, 36, 52, 46, 43},
    {-38, -32, -34, -52, -50, -47, -40, -54},
    {29, 32, 31, 48, 36, 43, 40, 41},
    {31, 39, 36, 42, 34, 45, 41, 37},
    {31, 40, 38, 47, 28, 47, 44, 35},
    {30, 33, 25, 48, 29, 43, 36, 36},
    {48, 43, 49, 54, 68, 66, 58, 68},
    {48, 48, 49, 46, 63, 58, 46, 55},
    {38, 49, 47, 41, 61, 58, 45, 50},
    {43, 34, 46, 44, 67, 54, 48, 54},
    {45, 43, 41, 50, 62, 61, 51, 49},
    {37, 47, 54, 41, 58, 61, 49, 50},
    {39, 49, 47, 42, 57, 57, 48, 48},
    {40, 39, 47, 47, 59, 58, 53, 57},
    {42, 49, 42, 42, 55, 55, 49, 50},
    {39, 40, 43, 45, 61, 56, 50, 53},
    {29, 38, 50, 37, 55, 53, 44, 42},
    {-36, -33, -46, -44, -61, -53, -45, -57},
    {-36, -33, -34, -32, -62, -45, -38, -53},
    {-39, -34, -38, -44, -62, -50, -41, -51},
    {-32, -31, -38, -33, -57, -45, -38, -49},
    {35, 35, 32, 38, 58, 50, 40, 47},
    {-31, -31, -32, -36, -61, -45, -34, -49},
    {-37, -37, -37, -38, -68, -47, -39, -49},
    {-31, -26, -35, -36, -66, -45, -36, -52},
    {-31, -38, -32, -28, -58, -47, -31, -47},
    {35, 29, 31, 42, 52, 48, 43, 41},
    {28, 31, 42, 37, 50, 44, 40, 45},
    {-29, -33, -44, -30, -53, -44, -38, -47},
    {-28, -28, -34, -37, -52, -43, -38, -48},
    {31, 39, 33, 35, 50, 48, 36, 36},
    {-39, -36, -32, -29, -55, -40, -30, -42},
    {-31, -31, -34, -33, -54, -42, -34, -48},
    {-23, -28, -32, -23, -52, -38, -25, -42},
    {-25, -23, -28, -22, -52, -36, -27, -43},
    {-22, -27, -29, -21, -55, -34, -25, -35},
    {38, 50, 59, 48, 59, 66, 55, 54},
    {44, 52, 46, 54, 52, 64, 55, 52},
    {44, 45, 50, 57, 53, 63, 55, 58},
    {38, 49, 47, 41, 52, 63, 51, 49},
    {31, 42, 50, 38, 55, 57, 52, 54},
    {35, 44, 48, 41, 53, 61, 48, 53},
    {34, 47, 50, 46, 49, 64, 51, 49},
    {36, 50, 51, 44, 42, 63, 56, 46},
    {38, 44, 51, 49, 45, 60, 56, 58},
    {39, 45, 45, 53, 46, 58, 53, 47},
    {38, 47, 51, 43, 46, 58, 51, 45},
    {34, 47, 49, 38, 45, 60, 50, 47},
    {47, 49, 47, 52, 46, 58, 57, 52},
    {41, 39, 36, 48, 49, 55, 44, 47},
    {40, 53, 46, 48, 46, 62, 55, 46},
    {41, 39, 44, 45, 46, 54, 53, 52},
    {41, 43, 46, 44, 51, 58, 57, 48},
    {41, 44, 40, 45, 49, 55, 47, 45},
    {38, 43, 47, 50, 50, 59, 55, 44},
    {37, 46, 44, 43, 41, 56, 55, 50},
    {34, 43, 45, 42, 51, 56, 49, 46},
    {46, 38, 41, 40, 44, 54, 56, 50},
    {34, 45, 47, 39, 37, 54, 48, 50},
    {37, 41, 51, 43, 47, 52, 47, 45},
    {35, 47, 45, 39, 43, 56, 50, 45},
    {34, 51, 48, 38, 38, 53, 53, 41},
    {37, 39, 37, 46, 44, 52, 43, 43},
    {37, 41, 40, 37, 39, 50, 42, 42},
    {34, 45, 41, 38, 41, 48, 40, 37},
    {32, 36, 40, 42, 38, 52, 51, 46},
    {27, 48, 45, 36, 38, 52, 51, 41},
    {30, 41, 33, 44, 46, 53, 42, 35},
    {28, 33, 35, 36, 36, 48, 37, 39},
    {25, 36, 38, 34, 25, 50, 41, 33},
    {29, 36, 34, 38, 33, 49, 43, 38},
    {37, 44, 33, 37, 35, 47, 44, 38},
    {33, 36, 30, 35, 35, 44, 48, 38},
    {26, 36, 32, 31, 30, 39, 31, 34},
    {28, 34, 36, 37, 34, 44, 42, 32},
    {-29, -31, -22, -30, -37, -39, -28, -40},
    {51, 55, 65, 58, 55, 73, 65, 67},
    {38, 46, 47, 43, 41, 57, 64, 47},
    {39, 42, 50, 47, 43, 53, 66, 47},
    {35, 43, 47, 41, 39, 53, 60, 45},
    {37, 43, 44, 42, 40, 54, 63, 42},
    {33, 42, 43, 38, 37, 53, 59, 43},
    {37, 44, 41, 40, 38, 52, 60, 41},
    {33, 37, 43, 39, 38, 49, 55, 40},
    {38, 41, 40, 44, 40, 53, 60, 48},
    {33, 42, 39, 41, 34, 48, 54, 36},
    {31, 36, 41, 40, 35, 49, 41, 39},
    {34, 47, 44, 41, 36, 51, 59, 40},
    {30, 36, 37, 33, 34, 47, 50, 36},
    {30, 42, 36, 29, 31, 43, 53, 35},
    {23, 31, 29, 32, 26, 41, 51, 29},
    {44, 52, 54, 51, 60, 68, 61, 64},
    {47, 45, 48, 50, 58, 61, 56, 68},
    {42, 51, 55, 49, 51, 66, 61, 61},
    {38, 48, 51, 44, 49, 59, 52, 63},
    {38, 47, 58, 47, 57, 63, 57, 57},
    {43, 48, 56, 51, 46, 63, 59, 62},
    {40, 45, 49, 45, 47, 59, 58, 58},
    {39, 40, 44, 37, 47, 53, 47, 61},
    {40, 46, 45, 42, 47, 59, 49, 61},
    {43, 43, 43, 41, 44, 56, 53, 64},
    {-40, -31, -37, -35, -61, -48, -38, -67},
    {-44, -36, -44, -45, -58, -50, -48, -65},
    {32, 44, 55, 42, 44, 55, 49, 55},
    {39, 37, 31, 51, 47, 50, 48, 53},
    {40, 49, 40, 43, 43, 50, 47, 49},
    {-33, -33, -36, -36, -52, -45, -39, -61},
    {42, 35, 36, 39, 39, 43, 43, 49},
    {-32, -30, -39, -33, -50, -44, -42, -46},
    {-34, -32, -31, -36, -51, -41, -35, -54},
    {-39, -35, -39, -44, -50, -44, -36, -63},
    {38, 34, 31, 31, 37, 41, 36, 45},
    {-35, -26, -33, -35, -48, -36, -32, -57},
    {-33, -23, -29, -42, -48, -37, -28, -48},
    {-36, -22, -30, -37, -39, -35, -33, -46},
    {-29, -28, -32, -34, -44, -37, -32, -43},
    {26, 35, 29, 24, 36, 36, 35, 0},
    {11, 19, 10, 18, 9, 14, 8, 10},
    {20, 18, 11, 29, 10, 14, 12, 14},
    {21, 30, 21, 19, 17, 26, 26, 17},
    {12, 16, 12, 12, 7, 17, 16, 12},
    {19, 27, 17, 20, 17, 26, 21, 17},
    {26, 29, 22, 28, 37, 33, 27, 31},
    {0, -4, -2, -8, -5, -6, -4, -5},
    {0, -5, -5, -7, -4, -5, 1, -3},
    {-16, -20, -22, -16, -18, -19, 0, -23},
    {-20, -15, -16, -16, -14, -12, 0, -35},
    {-8, -1, 7, -5, -5, 7, 0, 0},
    {5, 11, 6, 4, 5, 4, 6, 7},
    {-36, -42, -40, -40, -60, -46, -40, -41},
    {4, 16, 14, 9, 5, 14, 0, 17},
    {6, 12, 16, 5, 3, 9, 13, 16},
    {-19, -13, -13, -9, -17, -13, 0, -15},
    {-10, -18, -21, -19, -19, -25, -19, 0},
    {-18, -22, -29, -20, -24, -30, -33, 0},
    {9, 12, 4, 4, 3, 3, -3, 0},
    {3, 15, 12, 9, 2, 9, 6, 0},
    {-10, -11, -12, -7, -14, -12, -22, 0}
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

	for (fieldno = 0; fieldno < 192; fieldno++)
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
					Row.TS = atoi(valstr);
					break;

				case 11:
					Row.Dyslexia = atoi(valstr);
					Row.Quiz[141] = Row.Dyslexia;
					break;

				case 12:
					Row.Dyscalculia = atoi(valstr);
					Row.Quiz[142] = Row.Dyscalculia;
					break;

				case 13:
					Row.OCD = atoi(valstr);
					Row.Quiz[143] = Row.OCD;
					break;

				case 14:
					Row.ODD = atoi(valstr);
					Row.Quiz[144] = Row.ODD;
					break;

				case 15:
					Row.Bipolar = atoi(valstr);
					Row.Quiz[145] = Row.Bipolar;
					break;

				case 16:
					Row.Schizophrenia = atoi(valstr);
					break;

				case 17:
					Row.Social = atoi(valstr);
					Row.Quiz[146] = Row.Social;
					break;

				case 18:
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

				case 19:
					Row.AsResult = atoi(valstr);
					break;

				case 20:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 21;

					if (i >= 141)
					{
					    i -= 141;
					    
					    if (i % 2 == 0)
							Row.ViewTime[i/2] = atoi(valstr);
						else
						{
							Row.Rating[i/2] = atoi(valstr);
							Row.Quiz[147 + i/2] = atoi(valstr);
					    }
					}
					else
    					Row.Quiz[i] = atoi(valstr);
					break;
			}
		}
	}

	for (i = 0; i < 15; i++)
	    if (Row.Quiz[147 + i] || Row.ViewTime[i])
	        Row.Quiz[147 + i]++;

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
	TFile infile("quizs1.sql");
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
