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
# convr7.cpp
# Convert exported quiz-r7 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr7.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r7 VALUES (";

TFile quizfile("quizr7.bin", 0);

static int Gw[150][8] = 
{
    {26, 36, 32, 31, 30, 39, 31, 34},
    {30, 29, 30, 29, 27, 37, 33, 30},
    {59, 43, 40, 46, 39, 52, 53, 49},
    {63, 45, 40, 49, 40, 51, 53, 51},
    {54, 40, 27, 41, 35, 44, 42, 42},
    {55, 34, 31, 34, 36, 41, 38, 41},
    {-49, -22, -19, -36, -35, -32, -29, -38},
    {37, 62, 51, 40, 48, 56, 47, 48},
    {35, 58, 45, 39, 44, 56, 48, 43},
    {34, 51, 48, 37, 39, 53, 53, 41},
    {33, 60, 41, 36, 37, 47, 43, 35},
    {31, 48, 33, 36, 36, 45, 41, 32},
    {28, 55, 41, 27, 28, 44, 39, 32},
    {37, 51, 59, 45, 52, 63, 52, 55},
    {30, 49, 57, 39, 49, 56, 44, 49},
    {32, 43, 59, 36, 48, 56, 45, 49},
    {30, 49, 64, 35, 42, 54, 49, 45},
    {28, 45, 63, 38, 41, 55, 51, 44},
    {32, 51, 56, 49, 39, 57, 53, 41},
    {27, 48, 62, 30, 40, 54, 48, 40},
    {36, 40, 50, 42, 47, 51, 47, 46},
    {32, 39, 49, 36, 37, 50, 44, 38},
    {26, 43, 54, 32, 39, 49, 40, 38},
    {28, 31, 30, 48, 36, 43, 38, 40},
    {30, 33, 24, 48, 29, 43, 35, 35},
    {47, 43, 49, 53, 69, 66, 57, 67},
    {48, 48, 49, 44, 64, 57, 44, 56},
    {38, 49, 47, 40, 61, 58, 44, 50},
    {40, 39, 46, 46, 60, 58, 52, 58},
    {37, 47, 54, 41, 58, 60, 46, 49},
    {41, 32, 45, 44, 66, 53, 44, 53},
    {39, 50, 47, 41, 57, 57, 47, 48},
    {38, 41, 58, 42, 56, 57, 49, 51},
    {30, 42, 50, 38, 55, 56, 51, 54},
    {34, 44, 48, 41, 54, 61, 47, 54},
    {45, 42, 40, 49, 62, 60, 51, 49},
    {42, 49, 41, 42, 56, 55, 48, 51},
    {38, 39, 42, 44, 61, 55, 50, 53},
    {-31, -25, -34, -36, -68, -46, -35, -55},
    {29, 37, 50, 37, 55, 54, 44, 43},
    {38, 47, 50, 42, 47, 58, 50, 43},
    {-38, -33, -37, -43, -61, -49, -40, -50},
    {41, 39, 35, 48, 49, 55, 42, 47},
    {-35, -32, -33, -32, -62, -44, -36, -53},
    {-32, -31, -37, -33, -56, -45, -36, -48},
    {-30, -30, -31, -35, -61, -45, -32, -50},
    {35, 35, 31, 37, 57, 49, 39, 46},
    {27, 31, 42, 37, 51, 44, 39, 45},
    {36, 29, 30, 43, 52, 49, 43, 43},
    {-32, -30, -35, -33, -57, -43, -37, -48},
    {30, 39, 32, 34, 50, 48, 36, 35},
    {-27, -28, -34, -38, -54, -44, -37, -50},
    {-31, -39, -31, -26, -59, -48, -31, -48},
    {-39, -36, -31, -29, -54, -39, -27, -41},
    {-30, -29, -28, -23, -65, -35, -27, -46},
    {33, 44, 41, 36, 41, 47, 39, 35},
    {-29, -32, -43, -29, -53, -43, -37, -46},
    {-25, -22, -27, -21, -53, -36, -28, -43},
    {-22, -28, -31, -23, -52, -38, -24, -41},
    {-32, -35, -36, -31, -57, -39, -31, -39},
    {-21, -26, -28, -20, -56, -34, -25, -34},
    {-28, -25, -30, -32, -46, -34, -30, -45},
    {34, 37, 44, 44, 39, 54, 48, 40},
    {-40, -38, -38, -39, -71, -49, -39, -56},
    {37, 49, 59, 47, 59, 66, 55, 53},
    {38, 47, 58, 47, 58, 63, 56, 56},
    {43, 52, 46, 53, 52, 64, 53, 51},
    {38, 50, 46, 40, 52, 63, 50, 49},
    {34, 46, 49, 44, 48, 63, 49, 48},
    {39, 45, 45, 52, 47, 58, 53, 46},
    {34, 47, 49, 38, 45, 60, 50, 48},
    {36, 50, 50, 44, 42, 64, 55, 46},
    {38, 44, 51, 49, 46, 60, 55, 57},
    {46, 49, 47, 52, 46, 59, 57, 53},
    {33, 43, 45, 42, 51, 56, 49, 46},
    {32, 43, 49, 40, 50, 57, 53, 44},
    {37, 43, 46, 50, 50, 59, 54, 44},
    {40, 53, 46, 47, 46, 62, 55, 46},
    {36, 46, 44, 43, 41, 56, 56, 49},
    {40, 43, 45, 41, 51, 59, 57, 48},
    {34, 47, 45, 39, 44, 57, 49, 45},
    {40, 44, 39, 43, 51, 54, 48, 48},
    {32, 41, 35, 50, 42, 53, 41, 44},
    {-28, -27, -38, -30, -45, -41, -37, -44},
    {37, 50, 41, 37, 37, 52, 47, 43},
    {32, 36, 40, 43, 39, 52, 52, 45},
    {35, 38, 37, 58, 36, 52, 46, 41},
    {29, 38, 49, 37, 35, 51, 46, 35},
    {29, 41, 32, 44, 45, 53, 41, 35},
    {25, 36, 38, 34, 25, 51, 43, 33},
    {26, 48, 45, 35, 38, 52, 49, 39},
    {29, 36, 34, 37, 33, 49, 43, 39},
    {33, 36, 29, 35, 36, 44, 48, 38},
    {31, 40, 37, 47, 28, 47, 44, 34},
    {23, 45, 39, 40, 30, 45, 43, 32},
    {28, 32, 35, 36, 36, 49, 37, 39},
    {36, 44, 32, 36, 35, 46, 43, 38},
    {28, 34, 36, 37, 35, 44, 42, 33},
    {35, 45, 46, 41, 41, 56, 64, 47},
    {36, 43, 43, 42, 40, 54, 64, 42},
    {38, 41, 39, 44, 41, 53, 59, 50},
    {33, 42, 42, 38, 37, 53, 59, 43},
    {40, 42, 51, 49, 44, 56, 67, 49},
    {34, 43, 46, 41, 39, 54, 60, 44},
    {35, 44, 40, 39, 39, 52, 59, 41},
    {32, 42, 39, 41, 35, 48, 56, 36},
    {32, 37, 42, 39, 38, 49, 56, 40},
    {32, 48, 43, 40, 36, 52, 59, 39},
    {30, 36, 37, 32, 34, 46, 50, 34},
    {29, 42, 36, 29, 31, 43, 53, 35},
    {44, 52, 53, 51, 59, 67, 60, 64},
    {47, 45, 47, 49, 58, 61, 55, 68},
    {47, 48, 42, 58, 50, 61, 53, 59},
    {42, 51, 55, 48, 52, 65, 60, 61},
    {37, 48, 50, 44, 49, 59, 50, 64},
    {44, 44, 50, 57, 54, 62, 55, 59},
    {39, 45, 48, 44, 46, 58, 57, 59},
    {38, 40, 43, 36, 48, 53, 47, 61},
    {39, 46, 44, 41, 47, 59, 48, 61},
    {-40, -30, -37, -34, -61, -47, -37, -67},
    {42, 49, 56, 53, 52, 65, 60, 63},
    {42, 42, 42, 39, 44, 54, 51, 65},
    {40, 39, 43, 44, 47, 53, 51, 51},
    {-34, -31, -45, -43, -61, -52, -44, -55},
    {32, 44, 54, 42, 45, 56, 49, 55},
    {39, 37, 37, 38, 46, 49, 47, 56},
    {-44, -35, -44, -43, -59, -50, -47, -64},
    {38, 37, 31, 50, 47, 50, 48, 53},
    {-33, -32, -36, -36, -53, -45, -39, -62},
    {40, 49, 40, 42, 43, 49, 47, 49},
    {34, 45, 47, 39, 37, 54, 49, 49},
    {45, 38, 40, 39, 45, 54, 54, 51},
    {55, 35, 34, 44, 45, 46, 40, 49},
    {44, 41, 35, 50, 36, 50, 45, 46},
    {37, 39, 36, 46, 44, 52, 43, 43},
    {36, 41, 40, 37, 39, 50, 42, 41},
    {-32, -29, -40, -33, -53, -45, -41, -48},
    {41, 35, 35, 38, 40, 42, 40, 50},
    {-38, -31, -34, -52, -49, -47, -39, -52},
    {-34, -31, -29, -35, -50, -40, -33, -53},
    {38, 34, 31, 31, 38, 41, 36, 46},
    {-32, -22, -19, -29, -43, -34, -25, -58},
    {30, 39, 35, 41, 34, 44, 41, 36},
    {-34, -21, -28, -41, -48, -36, -27, -49},
    {-29, -31, -21, -30, -36, -39, -26, -41},
    {-36, -21, -30, -38, -42, -36, -32, -49},
    {-39, -38, -42, -48, -52, -47, -41, -64},
    {-33, -25, -34, -33, -50, -36, -35, -56},
    {-44, -38, -46, -55, -56, -48, -46, -57},
    {-16, -3, -2, -12, -18, -6, -3, -12}
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

	for (fieldno = 0; fieldno < 163; fieldno++)
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
	TFile infile("quizr7.sql");
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
