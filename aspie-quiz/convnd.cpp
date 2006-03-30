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
# convnd.cpp
# Convert exported quiz-ND to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbnd.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-nd VALUES (";

TFile quizfile("quiznd.bin", 0);

/*##################  HandleRow ##########################
*   Purpose....: Handle a row       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void HandleRow(TQuizRow *Row)
{
	quizfile.Write(Row, sizeof(TQuizRow));
	printf("%d AS: %d, NT: %d, Hn: %d%%, Hs: %d%%, Ref: %s\n", Row->ID, Row->AsResult, Row->NtResult, Row->Hn, Row->Hs, Row->Referer);
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
	int w;
    static int Asw[200] = {
             11,    8,    8,    9,    9,    6,    7,   10,    8,    3,
             11,    6,    8,    8,    9,    5,    9,    3,    6,    0,
              5,    0,    0,    0,    2,    6,    3,    5,   10,    0,
              9,    9,   12,    8,    3,    6,    0,    9,    9,    0,
              6,    0,   10,    7,    8,    0,    4,    0,    0,    7,
              8,    8,    4,    5,    2,    2,    6,    5,    9,   10,
              0,   11,    0,    0,   12,    7,    8,    5,    8,    1,
             11,    7,    7,    0,    0,    0,    0,    9,    6,    1,
              0,    0,    8,    9,   10,    0,    9,    7,    8,    3,
              6,    0,    0,   13,    0,    0,    5,   11,    9,    9,
              0,   10,   10,    0,    0,    0,   10,    4,   11,    0,
              0,    0,    7,   12,    3,    1,    0,    7,    0,    9,
              0,    7,    0,    7,    0,    0,   10,   13,    0,    0,
              3,    0,    0,    0,    0,    0,    2,    0,    4,    7,
              9,    5,    0,    7,    0,    1,   10,    8,   10,    9,
              8,    0,    9,    8,    9,    8,    2,    5,    3,    4,
              4,    5,    7,    3,    3,    5,    3,    8,    2,    2,
              4,    4,    5,    8,    2,    8,    7,    8,    0,    8,
             11,    4,    8,    0,    5,    6,    3,    1,   10,   10,
              0,    6,    5,    3,    2,    9,    0,    0,    5,    0};

    static int Ntw[200] = {
              0,   -7,    0,   -2,   -3,   -3,    0,   -4,   -4,   -2,
             -7,   -8,   -4,   -5,   -3,    0,   -3,   -5,   -7,    3,
             -6,    1,    5,    3,    0,    0,   -3,   -6,  -12,    7,
            -10,  -11,   -7,  -10,    0,   -1,    5,   -4,   -7,    5,
            -12,    2,   -2,   -5,   -8,    4,   -6,    7,    5,   -7,
             -5,   -1,   -3,   -5,   -2,   -2,    0,   -4,   -1,   -1,
              5,   -3,    6,    2,    0,    0,   -2,    1,   -4,    0,
             -4,   -3,    0,    5,    6,    1,    2,   -5,   -7,    0,
              1,    3,   -9,   -6,   -4,    6,   -3,   -3,   -2,   -2,
             -3,    9,    8,   -4,    2,    8,   -4,   -4,   -2,    0,
              0,   -1,    0,    9,   12,    7,    0,    0,   -4,    6,
              1,    3,   -9,   -5,    0,    0,    2,    0,    1,   -1,
             12,   -5,    5,   -9,    8,    5,  -10,   -5,    6,    8,
             -1,    7,    7,    4,    6,    4,    0,    7,    0,    0,
              0,   -1,    0,    0,    1,    0,   -1,   -3,    0,   -6,
              0,    5,    0,   -2,   -3,   -1,   -3,    0,    0,   -2,
             -2,   -2,   -1,   -1,   -1,   -5,    0,    0,    0,    0,
             -1,   -1,   -4,   -3,    0,   -2,   -8,   -7,    1,   -2,
             -7,   -1,   -5,    0,   -3,   -1,   -1,    0,    0,   -1,
              0,    0,    0,    0,    0,   -8,    4,    2,    0,    1};

    static int Asg[200] = {
              1,    0,    0,    0,    1,    0,    1,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    1,    0,    1,    1,    0,    0,    0,    0,    0,
              1,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    1,    0,    0,    1,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    1,
              0,    0,    0,    0,    0,    0,    0,    0,   -1,    1,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    1,    0,    0,    0,    0,    1,    0,    0,
              0,    0,    0,    0,    1,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    1,    0,    0,
              0,    0,    0,    0,    0,    0,    2,    0,    2,    2,
              0,    0,    0,    0,    0,    1,    1,    0,    1,    0,
              0,    0,    1,    0,    0,    0,    0,    2,    1,    0,
              0,    0,    0,    0,    0,    1,    0,    1,    1,    0,
             -1,    0,    0,    0,    1,    0,    0,   -1,    1,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    1,    0,
              0,    0,    0,    1,    1,    0,    0,    0,    0,    0};

    static int Ntg[200] = {
              0,    0,    0,   -1,   -1,   -1,    0,    0,    0,    0,
              0,    0,    0,    1,    0,    0,   -2,    1,    0,    0,
              0,    0,    0,    1,    0,    0,    0,    0,    0,    0,
              0,    1,    0,    0,    0,    0,    0,    0,    1,    0,
              0,   -1,    0,    1,    0,    1,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    2,
              0,    0,    0,    0,    0,    0,   -1,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    1,   -2,    0,    1,
              0,    0,    0,    0,    0,    0,    2,    2,    0,    0,
              0,   -1,    0,    0,    0,    0,   -1,    0,    1,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    2,    0,    0,
              0,    0,    0,   -1,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    1,    0,    0,   -1,   -1,    0,    0,
              0,    0,    0,    0,    0,    0,    1,    0,    0,    0,
              0,    0,    1,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,   -1,    0,    0,
              0,    0,    0,    0,    1,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,   -1,    0,    0};


	for (i = 0; i < 200; i++)
	{
		if (row->Quiz[i])
		{
			val = row->Quiz[i];
			w = Asw[i];
			if (row->Gender == 1)
				w += Asg[i];
			else
				w -= Asg[i];
		        
			assum += w * (val - 1);
			astotsum += w;

			w = Ntw[i];
			if (row->Gender == 1)
				w += Ntg[i];
			else
				w -= Ntg[i];

			if (w > 0)
			{
				val--;
				ntsum += w * val;
				nttotsum += w;
			}
			else
			{
				val = 3 - val;
				w = -w;
				ntsum += w * val;
				nttotsum += w;
			}
		}
	}

	row->Hn = assum * 100 / (assum + ntsum);
	row->Hs = 100 - row->Hn;
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
	TQuizRow Row;
	int quote;

	for (fieldno = 0; fieldno < 221; fieldno++)
	{
		valstr = str;

		quote = FALSE;
		ptr = str;
		while (*ptr && (quote || *ptr != ','))
		{
			if (*ptr == 0x27)
				quote = !quote;

			ptr++;
		}

		if (*ptr == ',')
		{
			*ptr = 0;
			str = ptr + 1;

			switch (fieldno)
			{
				case 0:
					Row.ID = atol(valstr);
					break;

				case 1:
					break;

				case 2:
					Row.BirthYear = atoi(valstr);
					break;

				case 3:
					Row.Gender = atoi(valstr);
					break;

				case 4:
					Row.Autism = atoi(valstr);
					break;

				case 5:
					Row.Aspie = atoi(valstr);
					break;

				case 6:
					Row.ADHD = atoi(valstr);
					break;

				case 7:
					Row.TS = atoi(valstr);
					break;

				case 8:
					Row.Hyperlexia = atoi(valstr);
					break;

				case 9:
					Row.Dyspraxia = atoi(valstr);
					break;

				case 10:
					Row.Dyslexia = atoi(valstr);
					break;

				case 11:
					Row.Dyscalculia = atoi(valstr);
					break;

				case 12:
					Row.OCD = atoi(valstr);
					break;

				case 13:
					Row.ODD = atoi(valstr);
					break;

				case 14:
					Row.Synaesthesia = atoi(valstr);
					break;

				case 15:
					Row.PA = atoi(valstr);
					break;

				case 16:
					Row.Dysgraphia = atoi(valstr);
					break;

				case 17:
					Row.Bipolar = atoi(valstr);
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
					Row.Quiz[i] = atoi(valstr);
					break;
			}
		}
	}

    UpdateScore(&Row);
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
	TFile infile("quiznd.sql");

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

