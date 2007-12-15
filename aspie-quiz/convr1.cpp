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
# conv7.cpp
# Convert exported quiz-8 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbr1.h"
#include "convr1.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-r1 VALUES(";

TFile quizfile("quizr1.bin", 0);


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

	for (grp = 0; grp < 14; grp++)
	{
	    printf("%d", Row->GroupResult[grp]);
	    if (grp != 13)
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
	int i;
	int assum = 0;
	int astotsum = 0;
	int ntsum = 0;
	int nttotsum = 0;
	int val;
	int aw;
	int nw;
    int grp;
    int w;
    int sum;
    int totsum;

    static int Asw[130] = {
             15,   10,   13,   12,   15,    9,   17,   12,   10,   11,
             15,   11,    9,    8,    4,    6,    4,    4,    5,    6,
              6,    4,    7,    7,    6,    9,   10,    7,   11,   11,
              9,   10,    9,    5,    9,    6,    4,    8,    8,   10,
             10,    6,   11,   13,   11,   12,   11,   13,   12,    7,
              6,   13,   10,    8,    9,   11,   11,    9,    8,    8,
              8,    8,    7,    8,    8,   10,    5,    5,   11,    8,
              7,   15,    7,    6,    7,    8,    5,    8,    7,    7,
              7,   10,    9,    7,    6,    6,    5,    7,    8,    8,
              4,    4,    5,    5,    7,    7,   11,    8,    9,    7,
             14,   16,   15,    7,    8,    9,   11,    7,    9,    6,
              8,    4,    3,    5,    3,   10,    4,   14,    9,   10,
             11,    5,    5,    4,    6,    7,    2,    7,    8,    7};

    static int Ntw[130] = {
             -1,    0,    2,   -6,    3,   -2,    2,   -4,    0,   -2,
             -1,   -7,   -7,   -2,   13,   16,   16,   15,   15,   17,
             19,   12,   -4,   -8,   -5,   -9,   -4,   -4,    1,   -5,
            -12,   -6,   20,   22,   21,   13,   16,    5,    5,   -5,
              6,   -5,   -4,   -2,    1,   -1,   -4,    0,    4,    4,
             -3,    4,    4,   -3,   -1,    5,   -5,   -5,   -6,   -7,
             -3,   -5,   -8,   -8,   -4,   -7,   -5,   -4,   -6,   -4,
             -6,    1,   -2,   -4,   -1,   -2,    0,   10,   -3,   -3,
             -1,   -4,   -7,   -3,   -3,   -7,   -8,   -8,   -6,   -6,
             -7,   -9,   -6,   -9,   -5,   -6,    0,   -5,   -6,  -12,
              3,    5,    5,   -2,   -4,   -1,    4,   -6,   19,   19,
              3,   -9,   -2,   -8,   -4,    0,   -3,    6,    6,    1,
              4,   -7,   -8,   -2,   -2,   -1,   -1,    7,    4,    5};


	for (i = 0; i < 130; i++)
	{
		if (row->Quiz[i])
		{
			val = row->Quiz[i];
			aw = Asw[i];
			nw = Ntw[i];

            if (aw > 0 && nw > 0)
            {
                if (aw > nw)
                {
                    aw = aw - nw;
                    nw = 0;
                }
                else
                {
                    nw = nw - aw;
                    aw = 0;
                }
            }
		        
			assum += aw * (val - 1);
			astotsum += aw;


			if (nw > 0)
			{
				val--;
				ntsum += nw * val;
				nttotsum += nw;
			}
			else
			{
				val = 3 - val;
				nw = -nw;
				ntsum += nw * val;
				nttotsum += nw;
			}
		}
	}

	row->AsResult = assum * 100 / astotsum;
	row->NtResult = ntsum * 100 / nttotsum;

    for (grp = 0; grp < 14; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 130; i++)
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

                sum += val * w;
				totsum += 2 * w;
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
					Row.Dyscalculia = atoi(valstr);
					break;

				case 11:
					Row.Dyslexia = atoi(valstr);
					break;

				case 12:
					Row.Dyspraxia = atoi(valstr);
					break;

				case 13:
					Row.Hyperlexia = atoi(valstr);
					break;

				case 14:
					Row.OCD = atoi(valstr);
					break;

				case 15:
					Row.TS = atoi(valstr);
					break;

				case 16:
					Row.Allergy = atoi(valstr);
					break;

				case 17:
					Row.Chemical = atoi(valstr);
					break;

				case 18:
					Row.Diet = atoi(valstr);
					break;

				case 19:
					Row.Eating = atoi(valstr);
					break;

				case 20:
					Row.Bipolar = atoi(valstr);
					break;

				case 21:
					Row.Depression = atoi(valstr);
					break;

				case 22:
					Row.Anxiety = atoi(valstr);
					break;

				case 23:
					Row.Social = atoi(valstr);
					break;

				case 24:
					Row.Phobia = atoi(valstr);
					break;

				case 25:
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

				case 26:
					Row.AsResult = atoi(valstr);
					break;

				case 27:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 28;
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
	TFile infile("quizr1.sql");
	int i;
	int grp;
	int max;
	long double w;

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
