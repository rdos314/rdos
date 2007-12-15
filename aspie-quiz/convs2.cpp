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
#include "convs2.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-s2 VALUES(";

TFile quizfile("quizs2.bin", 0);


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
    int grp;
    int i;
    int val;
    int w;
    int sum;
    int totsum;

    for (grp = 0; grp < 14; grp++)
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
