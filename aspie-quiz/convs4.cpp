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
# convs4.cpp
# Convert exported quiz-s4 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbs4.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-s4 VALUES(";

TFile quizfile("quizs4.bin", 0);

static int Gw[132][9] = 
{
    {61, 43, 41, 49, 41, 52, 55, 50, 19},
    {55, 34, 35, 45, 45, 47, 43, 49, 15},
    {57, 41, 40, 46, 39, 51, 53, 49, 0},
    {54, 39, 28, 42, 35, 44, 42, 41, 15},
    {55, 33, 32, 34, 37, 41, 39, 42, 17},
    {38, 59, 53, 43, 49, 58, 51, 48, 20},
    {35, 55, 45, 40, 43, 56, 49, 43, 16},
    {39, 48, 43, 40, 38, 55, 51, 44, 23},
    {35, 55, 43, 39, 38, 49, 45, 37, 0},
    {33, 44, 36, 36, 35, 45, 40, 34, 0},
    {38, 49, 59, 47, 53, 64, 54, 56, 21},
    {38, 38, 58, 41, 53, 56, 49, 51, 0},
    {32, 47, 57, 39, 48, 57, 46, 48, 24},
    {33, 42, 60, 36, 48, 57, 47, 49, 15},
    {31, 48, 64, 37, 42, 55, 50, 46, 22},
    {34, 49, 56, 48, 38, 57, 52, 42, 0},
    {31, 42, 62, 36, 39, 55, 51, 45, 0},
    {28, 46, 62, 30, 39, 54, 48, 40, 17},
    {33, 37, 51, 36, 37, 51, 45, 39, 0},
    {27, 40, 54, 32, 38, 49, 40, 39, 0},
    {47, 47, 43, 59, 52, 62, 54, 60, 19},
    {-40, -34, -43, -54, -52, -52, -46, -54, 0},
    {44, 39, 36, 49, 35, 49, 46, 46, 18},
    {33, 39, 36, 50, 42, 53, 43, 44, 15},
    {35, 36, 38, 57, 36, 52, 46, 42, 0},
    {29, 31, 31, 48, 36, 43, 41, 41, 13},
    {33, 39, 37, 42, 35, 46, 40, 38, 0},
    {30, 39, 37, 44, 26, 47, 42, 32, 16},
    {31, 32, 26, 47, 31, 43, 36, 36, 15},
    {48, 41, 51, 55, 67, 67, 59, 69, 20},
    {46, 33, 50, 50, 63, 61, 49, 61, 0},
    {50, 45, 50, 46, 63, 58, 47, 55, 17},
    {38, 48, 48, 41, 61, 59, 45, 50, 18},
    {38, 45, 55, 41, 58, 62, 49, 50, 24},
    {45, 40, 42, 50, 61, 61, 52, 50, 0},
    {41, 37, 48, 47, 58, 58, 54, 57, 0},
    {39, 44, 47, 42, 57, 57, 47, 49, 19},
    {39, 36, 43, 43, 59, 55, 51, 53, 0},
    {42, 45, 42, 43, 55, 54, 48, 51, 19},
    {30, 36, 50, 37, 54, 54, 43, 43, 18},
    {-36, -17, -45, -39, -59, -51, -42, -60, 0},
    {35, 33, 33, 38, 58, 51, 41, 46, 13},
    {-32, -22, -37, -36, -64, -46, -38, -54, 0},
    {-32, -33, -35, -31, -58, -48, -32, -47, -15},
    {28, 29, 43, 36, 49, 44, 39, 45, 14},
    {-30, -31, -45, -31, -50, -45, -40, -47, -15},
    {30, 36, 34, 34, 49, 49, 34, 36, 13},
    {-32, -24, -35, -35, -55, -42, -36, -50, 0},
    {34, 25, 31, 41, 51, 47, 43, 42, 15},
    {-28, -25, -34, -37, -52, -43, -41, -50, -16},
    {-23, -26, -33, -24, -52, -39, -26, -41, -10},
    {-25, -19, -28, -24, -51, -36, -27, -43, 0},
    {38, 48, 59, 48, 59, 66, 55, 55, 21},
    {44, 51, 46, 54, 52, 64, 54, 51, 23},
    {38, 45, 59, 47, 55, 63, 58, 57, 24},
    {44, 44, 51, 57, 52, 63, 55, 58, 25},
    {38, 46, 47, 41, 52, 62, 52, 50, 15},
    {32, 40, 51, 39, 55, 57, 54, 55, 20},
    {35, 42, 48, 42, 54, 60, 49, 53, 16},
    {35, 45, 51, 47, 50, 64, 51, 49, 18},
    {39, 41, 52, 49, 45, 60, 56, 59, 0},
    {39, 44, 46, 53, 47, 58, 52, 48, 16},
    {37, 49, 51, 44, 43, 63, 56, 46, 19},
    {35, 46, 50, 39, 46, 60, 50, 48, 15},
    {49, 46, 47, 52, 44, 57, 58, 52, 21},
    {41, 51, 47, 49, 48, 61, 56, 48, 0},
    {41, 38, 37, 49, 50, 55, 44, 48, 16},
    {37, 40, 47, 49, 49, 58, 54, 44, 20},
    {34, 41, 45, 41, 50, 55, 49, 46, 23},
    {38, 40, 51, 45, 48, 54, 48, 48, 0},
    {42, 43, 41, 45, 50, 57, 50, 46, 0},
    {34, 42, 48, 39, 37, 53, 48, 49, 20},
    {35, 44, 46, 40, 41, 55, 50, 44, 18},
    {37, 38, 37, 46, 43, 53, 43, 42, 12},
    {37, 40, 40, 37, 38, 50, 41, 41, 20},
    {34, 42, 42, 38, 43, 49, 40, 38, 0},
    {28, 46, 45, 35, 36, 51, 49, 40, 25},
    {29, 31, 36, 35, 34, 48, 37, 37, 11},
    {30, 36, 34, 38, 33, 49, 44, 39, 15},
    {37, 43, 34, 37, 35, 46, 43, 38, 18},
    {30, 33, 41, 39, 36, 48, 41, 38, 0},
    {26, 34, 32, 31, 29, 39, 31, 33, 14},
    {26, 35, 38, 33, 25, 49, 41, 32, 24},
    {28, 31, 36, 35, 32, 43, 41, 32, 0},
    {26, 28, 34, 22, 29, 44, 32, 24, 0},
    {50, 46, 65, 56, 53, 71, 68, 65, 0},
    {41, 43, 49, 46, 47, 59, 60, 59, 17},
    {39, 35, 54, 53, 53, 62, 60, 59, 0},
    {42, 38, 44, 45, 46, 54, 53, 52, 0},
    {40, 43, 48, 43, 41, 56, 62, 49, 0},
    {42, 39, 47, 45, 50, 57, 57, 50, 0},
    {38, 45, 44, 44, 41, 56, 56, 50, 22},
    {47, 36, 42, 41, 45, 54, 57, 50, 18},
    {34, 49, 48, 38, 38, 53, 53, 41, 17},
    {37, 40, 44, 42, 39, 53, 63, 43, 0},
    {38, 37, 49, 47, 43, 53, 64, 47, 0},
    {36, 41, 47, 41, 38, 53, 58, 44, 0},
    {38, 44, 41, 41, 38, 52, 59, 41, 0},
    {34, 42, 43, 39, 37, 53, 59, 43, 24},
    {38, 40, 41, 43, 37, 52, 58, 45, 15},
    {35, 45, 43, 41, 36, 51, 58, 41, 0},
    {33, 34, 43, 39, 38, 49, 54, 41, 0},
    {32, 34, 40, 41, 38, 51, 52, 44, 12},
    {33, 40, 38, 39, 33, 48, 53, 36, 0},
    {30, 36, 37, 33, 33, 47, 49, 35, 19},
    {33, 36, 30, 36, 36, 44, 50, 39, 16},
    {26, 31, 31, 34, 26, 42, 49, 31, 0},
    {45, 50, 55, 51, 60, 68, 62, 64, 19},
    {48, 44, 48, 50, 59, 61, 57, 68, 17},
    {43, 49, 56, 49, 52, 66, 62, 61, 22},
    {39, 46, 52, 45, 50, 60, 55, 63, 17},
    {40, 38, 44, 38, 48, 54, 49, 62, 16},
    {40, 44, 46, 43, 48, 59, 49, 61, 17},
    {44, 40, 44, 42, 45, 56, 54, 64, 16},
    {42, 41, 57, 49, 43, 61, 59, 58, 0},
    {-41, -30, -39, -36, -62, -50, -42, -67, -13},
    {-44, -34, -45, -45, -58, -51, -51, -64, 0},
    {33, 41, 55, 41, 44, 55, 49, 55, 14},
    {40, 48, 41, 44, 44, 51, 47, 50, 18},
    {39, 35, 32, 50, 46, 50, 48, 52, 10},
    {-34, -31, -37, -37, -53, -47, -41, -62, -15},
    {-35, -32, -33, -38, -53, -44, -41, -55, -15},
    {42, 31, 37, 39, 39, 44, 42, 49, 15},
    {-38, -25, -37, -43, -51, -44, -39, -61, 0},
    {-32, -29, -39, -34, -48, -44, -41, -45, 0},
    {38, 32, 31, 31, 36, 40, 37, 45, 15},
    {-33, -22, -30, -44, -50, -39, -32, -49, 0},
    {-39, -31, -34, -53, -49, -47, -40, -52, 0},
    {-40, -32, -39, -44, -61, -51, -42, -53, 0},
    {-37, -31, -48, -44, -59, -55, -47, -58, 0},
    {-29, -30, -24, -32, -37, -41, -31, -40, -7},
    {-35, -19, -30, -35, -40, -36, -32, -48, 0}
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

        for (i = 0; i < 127; i++)
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

	for (fieldno = 0; fieldno < 221; fieldno++)
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
					Row.Quiz[197] = Row.Dyslexia;
					break;

				case 14:
					Row.Dyscalculia = atoi(valstr);
					Row.Quiz[198] = Row.Dyscalculia;
					break;

				case 15:
					Row.OCD = atoi(valstr);
					Row.Quiz[199] = Row.OCD;
					break;

				case 16:
					Row.ODD = atoi(valstr);
					Row.Quiz[200] = Row.ODD;
					break;

				case 17:
					Row.Bipolar = atoi(valstr);
					Row.Quiz[201] = Row.Bipolar;
					break;

				case 18:
					Row.Schizophrenia = atoi(valstr);
					break;

				case 19:
					Row.Social = atoi(valstr);
					Row.Quiz[202] = Row.Social;
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
					Row.LsasResult = atoi(valstr);
					break;

				default:
					i = fieldno - 24;
					Row.Quiz[i] = atoi(valstr);

					if (Row.LsasResult && i >= 149 && i <= 196)
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
	TFile infile("quizs4.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 127; i++)
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
