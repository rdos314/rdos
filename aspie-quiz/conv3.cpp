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
# conv2.cpp
# Convert exported quiz-II to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdb3.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-III VALUES (";

TFile quizfile("quiz3.bin", 0);

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
	printf("%d AS: %d, NT: %d, Ref: %s\n", Row->ID, Row->AsResult, Row->NtResult, Row->Referer);
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

    static int Asw[100] = {
             12,   10,    9,    9,   10,   11,    8,    6,    7,    5,
              1,    4,    5,    8,    8,   10,    7,    8,    6,   11,
              7,    1,    4,    8,    2,   11,   10,    5,    9,    7,
             10,    8,    7,   10,    7,   10,   10,    7,    9,    9,
              8,    4,   11,    9,    7,   12,    7,    7,   13,    7,
             11,    4,   12,    9,    0,    0,    2,    1,    2,    0,
              0,    0,    0,    7,    0,    0,    5,    0,    0,    6,
              9,   11,   10,    6,    8,   10,   11,    7,    9,   10,
              5,    9,    9,    9,   10,    6,    9,    9,    8,    2,
              0,    5,    0,    3,    1,    2,    0,    2,    3,    0};

    static int Ntw[100] = {
             -4,   -5,   -3,    0,   -3,   -1,   -5,    0,   -4,   -4,
              0,    1,    2,   -3,   -8,   -2,    0,   -9,    2,   -2,
              0,    0,    0,   -1,    0,  -13,  -11,   -4,  -11,   -5,
             -8,   -6,   -5,   -5,   -6,  -10,   -7,    2,    0,   -5,
             -7,   -2,   -3,   -6,    5,   -9,    0,    9,   -4,    6,
             -4,    0,   -3,   -4,   18,   16,    5,    7,    7,   19,
             11,   18,   23,    0,    1,    0,    0,    1,    3,    1,
             -1,   -3,   -6,    6,   -1,   -5,    0,   -1,   -1,   -2,
              0,  -12,  -11,  -11,   -5,   -1,   -1,   -1,    0,    5,
              3,    0,    1,    0,    0,    0,    1,    0,    0,    4};

    static int Asg[100] = {
              0,    0,    0,    3,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,   -1,    1,    0,    0,    1,    0,
              0,    1,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    1,    0,    0,    0,    0,    0,    0,    0,
              1,    0,    1,    1,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    1,    0,   -1,   -1,    0,    1,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    1,
              0,    2,    0,    0,    1,   -1,    0,   -1,    0,    0};

    static int Ntg[100] = {
             -2,   -1,    0,   -1,   -1,   -1,    0,    0,    0,    0,
              0,   -1,   -2,   -1,   -1,   -1,   -1,    0,    1,    0,
              0,    0,    0,   -1,    1,    1,    1,    0,    1,    0,
              1,    0,    0,    0,    0,    0,    1,    0,    1,    1,
              0,    0,    1,    1,    0,    2,    1,    1,    2,    0,
              1,    0,    2,    0,    0,   -1,   -2,    0,    2,    1,
              0,    2,    0,    1,    1,    0,    0,    0,    0,    0,
              2,    0,    2,    0,    0,    0,    0,    0,    1,    0,
              0,    0,    0,    0,    0,    0,    1,    0,    1,   -1,
             -1,    0,    0,    0,    0,    0,    0,    1,    0,    0};

    static int Asa[100] = {
              0,    1,    0,   -3,    0,    0,    1,   -1,    0,    0,
              0,    0,    0,    0,    0,    0,   -1,    0,    0,    0,
             -1,    0,   -1,    0,    1,    0,    0,    1,    0,    1,
              1,    0,    1,    0,    0,    0,    0,    0,    1,    0,
              0,    0,    0,    0,    0,    0,    1,    0,    0,    0,
              0,   -1,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,   -1,    0,    1,    1,    1,    0,    1,
              0,    0,    0,    1,    0,    2,    1,    3,    1,   -1,
              0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
              0,    1,    2,    0,    0,   -1,    0,    1,    0,    0};

    static int Nta[100] = {
              2,    0,    2,    0,    1,    1,    2,    0,    1,    1,
              1,    3,    1,    2,    1,    1,    2,    0,    0,   -1,
              0,    1,    0,    0,    0,   -1,    0,    1,   -1,    0,
              0,    0,    0,    0,    0,    0,    0,    1,    0,    0,
              0,    0,   -1,   -1,    0,    1,    0,    0,    0,    1,
              0,    0,    1,    0,    0,    1,    1,    1,    0,    2,
              0,   -2,   -1,    0,    0,    0,    0,    0,    0,    0,
              0,    1,   -1,    0,    0,    0,    0,    0,    0,    0,
              0,    0,    0,    0,    0,    0,    1,    0,    0,    1,
              3,    0,    0,    1,    0,    1,    0,    0,    0,    3};


	for (i = 0; i < 100; i++)
	{
		if (row->Quiz[i])
		{
			val = row->Quiz[i];
			w = Asw[i];
			if (row->Gender == 1)
				w += Asg[i];
			else
				w -= Asg[i];

			if (2005 - row->BirthYear <= 25)
				w -= Asa[i];

		    if (2005 - row->BirthYear >= 40)
		        w += Asa[i];
		        
			assum += w * (val - 1);
			astotsum += w;

			w = Ntw[i];
			if (row->Gender == 1)
				w += Ntg[i];
			else
				w -= Ntg[i];

		    if (2005 - row->BirthYear <= 25)
		        w -= Nta[i];

		    if (2005 - row->BirthYear >= 40)
		        w += Nta[i];

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

	row->AsResult = assum * 100 / astotsum;
	row->NtResult = ntsum * 100 / nttotsum;
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

	for (fieldno = 0; fieldno < 107; fieldno++)
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
					Row.Diagnos = atoi(valstr);
                    break;

                case 3:
                    Row.BirthYear = atoi(valstr);
                    break;

				case 4:
                    Row.Gender = atoi(valstr);
                    break;

                case 5:
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

                case 6:
					Row.AsResult = atoi(valstr);
                    break;

                default:
                    i = fieldno - 7;
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
	TFile infile("quiz3.sql");

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

