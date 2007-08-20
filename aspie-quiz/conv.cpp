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
# conv.cpp
# Convert exported quiz to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdb.h"

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz VALUES (";

TFile quizfile("quiz1.bin", 0);

static int Gw[100][8] = 
{
    {16, 31, 47, 27, 36, 36, 30, 34},
    {-7, 8, 20, -1, 2, 4, 4, -1},
    {43, 45, 38, 56, 51, 56, 50, 53},
    {35, 44, 37, 52, 43, 49, 42, 43},
    {26, 41, 54, 38, 39, 46, 40, 39},
    {37, 45, 47, 61, 48, 56, 51, 54},
    {39, 45, 40, 56, 45, 53, 47, 52},
    {24, 33, 43, 33, 34, 39, 38, 39},
    {25, 36, 33, 46, 33, 43, 40, 37},
    {16, 30, 39, 24, 30, 34, 23, 26},
    {26, 28, 25, 43, 32, 39, 34, 36},
    {18, 28, 48, 25, 29, 32, 30, 27},
    {21, 30, 45, 16, 28, 29, 23, 22},
    {33, 38, 34, 45, 54, 47, 44, 44},
    {34, 39, 34, 42, 37, 46, 52, 44},
    {37, 37, 31, 41, 33, 42, 48, 43},
    {34, 36, 39, 44, 39, 48, 51, 44},
    {43, 42, 41, 49, 52, 54, 55, 58},
    {22, 36, 59, 28, 36, 39, 35, 36},
    {33, 44, 61, 45, 50, 54, 46, 50},
    {25, 37, 53, 38, 39, 44, 43, 41},
    {32, 44, 54, 39, 44, 51, 41, 43},
    {34, 49, 61, 42, 47, 52, 48, 49},
    {20, 30, 50, 27, 33, 35, 30, 32},
    {35, 51, 61, 51, 60, 61, 52, 54},
    {36, 50, 56, 52, 55, 59, 52, 53},
    {41, 45, 46, 54, 54, 59, 49, 55},
    {47, 54, 44, 57, 61, 66, 54, 54},
    {37, 51, 46, 49, 55, 63, 50, 49},
    {29, 37, 30, 37, 43, 48, 39, 32},
    {45, 48, 37, 51, 57, 59, 51, 52},
    {35, 35, 33, 44, 57, 50, 43, 44},
    {39, 47, 49, 41, 51, 54, 45, 47},
    {31, 43, 44, 41, 61, 54, 41, 43},
    {43, 50, 38, 42, 42, 54, 46, 43},
    {38, 50, 49, 49, 51, 64, 53, 52},
    {40, 50, 48, 48, 55, 62, 53, 54},
    {43, 55, 48, 50, 53, 66, 54, 54},
    {42, 56, 46, 47, 46, 62, 52, 49},
    {47, 61, 51, 58, 61, 72, 60, 61},
    {45, 53, 46, 48, 50, 60, 58, 52},
    {28, 35, 33, 27, 35, 36, 27, 31},
    {51, 48, 40, 46, 51, 54, 52, 53},
    {62, 42, 32, 41, 44, 48, 48, 50},
    {65, 50, 38, 47, 50, 55, 54, 56},
    {61, 48, 31, 46, 45, 51, 46, 48},
    {46, 43, 27, 35, 33, 39, 38, 35},
    {39, 46, 40, 39, 40, 47, 47, 45},
    {35, 47, 43, 40, 44, 48, 46, 43},
    {47, 48, 39, 46, 47, 52, 51, 50},
    {43, 53, 46, 48, 50, 61, 58, 51},
    {12, 30, 32, 17, 22, 26, 25, 21},
    {44, 66, 55, 47, 55, 62, 54, 55},
    {43, 53, 43, 48, 50, 53, 48, 54},
    {40, 58, 53, 45, 51, 59, 54, 49},
    {41, 60, 40, 39, 43, 50, 42, 43},
    {35, 61, 43, 37, 39, 47, 41, 41},
    {45, 69, 52, 48, 52, 62, 54, 52},
    {37, 52, 37, 37, 38, 48, 43, 41},
    {41, 62, 41, 41, 45, 54, 45, 43},
    {41, 64, 45, 45, 50, 59, 50, 50},
    {41, 60, 47, 47, 60, 61, 51, 54},
    {36, 49, 39, 39, 43, 46, 42, 43},
    {22, 40, 38, 32, 36, 41, 30, 33},
    {48, 63, 47, 54, 61, 68, 55, 58},
    {43, 60, 51, 49, 69, 65, 51, 56},
    {36, 45, 45, 44, 70, 58, 45, 50},
    {37, 46, 50, 46, 66, 59, 48, 57},
    {37, 48, 55, 47, 72, 60, 51, 56},
    {48, 54, 48, 47, 66, 61, 48, 57},
    {38, 52, 54, 46, 72, 62, 48, 53},
    {42, 45, 41, 46, 63, 56, 52, 56},
    {43, 51, 40, 45, 55, 54, 48, 53},
    {22, 30, 38, 33, 51, 40, 38, 43},
    {41, 55, 46, 51, 59, 64, 52, 53},
    {40, 52, 48, 51, 59, 63, 55, 61},
    {45, 56, 50, 53, 59, 64, 58, 62},
    {36, 48, 48, 46, 61, 58, 54, 57},
    {29, 44, 37, 27, 34, 42, 34, 30},
    {40, 57, 49, 46, 53, 60, 55, 55},
    {42, 51, 46, 45, 72, 63, 49, 55},
    {46, 50, 48, 53, 62, 61, 56, 71},
    {50, 52, 48, 55, 67, 64, 59, 73},
    {44, 48, 43, 52, 52, 57, 56, 70},
    {42, 48, 51, 49, 53, 58, 56, 64},
    {45, 54, 51, 56, 59, 62, 58, 71},
    {44, 47, 35, 54, 47, 54, 51, 64},
    {47, 49, 47, 55, 62, 61, 57, 73},
    {44, 45, 38, 43, 50, 49, 44, 56},
    {45, 56, 55, 55, 70, 66, 58, 68},
    {42, 46, 46, 47, 71, 62, 50, 60},
    {38, 49, 48, 43, 53, 55, 44, 59},
    {43, 49, 47, 41, 55, 55, 47, 54},
    {42, 53, 48, 47, 55, 60, 50, 59},
    {38, 53, 53, 47, 54, 58, 52, 65},
    {19, 28, 29, 14, 21, 26, 19, 20},
    {34, 40, 47, 38, 56, 50, 42, 52},
    {36, 48, 50, 46, 70, 57, 47, 57},
    {31, 46, 53, 33, 49, 48, 38, 46},
    {34, 53, 56, 39, 56, 55, 45, 52}
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
	printf("%d Now: %d Before: %d, [", Row->ID, Row->ResultNow, Row->ResultBefore);

	for (grp = 0; grp < 8; grp++)
	{
	    printf("%d", Row->GroupResult[grp]);
	    if (grp != 7)
	        printf(", ");
	}

	printf("], Ref: %s\n", Row->Referer);

}

/*##################  CalcScore ##########################
*   Purpose....: Calculate score    	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CalcScore(TQuizRow *Row)
{
	int nsum = 0;
	int fsum = 0;
	int i;
	int grp;
	int val;
	int w;
	int sum;
	int totsum;

	for (i = 0; i < 100; i++)
	{
		if (Row->Now[i] && Row->Before[i])
		{
			nsum += Row->Now[i];
			fsum += Row->Before[i];
		}
		else
		{
			if (Row->Now[i])
			{
				nsum += Row->Now[i];
				fsum += Row->Now[i];
			}

			if (Row->Before[i])
			{
				nsum += Row->Before[i];
				fsum += Row->Before[i];
			}
		}
	}

	if (Row->ResultNow)
	{
		 if (Row->ResultNow != nsum)
		 {
			  printf("Now: %d, expected: %d", nsum, Row->ResultNow);
			  exit(0);
		 }
	}
	else
		 Row->ResultNow = nsum;

	if (Row->ResultBefore)
	{
		 if (Row->ResultBefore != fsum)
		 {
			  printf("Before: %d, expected: %d", fsum, Row->ResultBefore);
			  exit(0);
		 }
	}
	else
		 Row->ResultBefore = fsum;

	for (grp = 0; grp < 8; grp++)
	{
		sum = 0;
		totsum = 0;

		for (i = 0; i < 100; i++)
		{
			val = Row->Now[i];
			if (Row->Before[i] > val)
            	val = Row->Before[i];

			w = Gw[i][grp];

			if (w < 0)
			{
				w = -w;
				val = 2 - val;
			}

			sum += val * w * w;
			totsum += 2 * w * w;
		}

		if (totsum)
			Row->GroupResult[grp] = 100 * sum / totsum;
		else
			Row->GroupResult[grp] = 0;
	}
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

/*##################  ProcessRow ##########################
*   Purpose....: Process row        	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ProcessRow(char *str)
{
    char *valstr;
	char *ptr;
	int fieldno;
	int i;
	int year, month, day;
	int hour, min, sec;
    TDateTime *time;
	TQuizRow Row;

	for (fieldno = 0; fieldno < 211; fieldno++)
    {
        valstr = str;
	    ptr = strstr(str, ",");
		if (ptr)
		{
			*ptr = 0;
			str = ptr + 1;

			switch (fieldno)
			{
			    case 0:
					Row.ID = atol(valstr);
					break;

				case 3:
						  valstr = GetQuoted(valstr);
						  if (valstr)
						  {
						sscanf(valstr, "%04d-%02d-%02d %02d:%02d:%02d",
											  &year, &month, &day,
												 &hour, &min, &sec);

						time = new TDateTime(year, month, day, hour, min, sec);
						Row.LsbTime = time->GetLsb();
						Row.MsbTime = time->GetMsb();
						delete time;
					 }
					 else
					 {
				        Row.LsbTime = 0;
				        Row.MsbTime = 0;
				    }
                    break;

                case 5:
                    Row.Diagnos = atoi(valstr);
					break;

                case 6:
                    Row.Age = atoi(valstr);
						  break;

                case 7:
                    Row.Gender = atoi(valstr);
                    break;

                case 8:
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

                case 9:
                    Row.ResultNow = atoi(valstr);
					break;

					 case 10:
						  Row.ResultBefore = atoi(valstr);
                    break;

                case 1:
                case 2:
                case 4:
                    break;

                default:
                    i = fieldno - 11;
                    if (i >= 100)
                        Row.Now[i - 100] = atoi(valstr);
                    else
                        Row.Before[i] = atoi(valstr);
                    break;
            }                    
        }
	}

    CalcScore(&Row);
    HandleRow(&Row);
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
	TFile infile("quiz1.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 100; i++)
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
			ptr = strstr(rowstr, ")");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
			ProcessRow(rowstr);
	}
}

