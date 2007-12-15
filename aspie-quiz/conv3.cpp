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
#include "conv3.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-III VALUES(";

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

    static int Asw[100] = {
             13,   13,   10,   12,    9,   12,    9,   16,    9,    4,
              1,    7,    9,    9,    9,    9,    7,    9,   13,   11,
             10,    2,    7,    8,    6,   11,   12,    9,   10,   11,
             11,    8,    5,   10,    9,   12,    9,   13,   13,   10,
              7,    4,    9,   11,   14,   13,   15,   13,   15,    6,
             13,   17,   14,   17,    7,    4,    4,    6,    6,    9,
             13,    9,    7,    2,    2,    3,    4,    7,    5,   13,
             14,   12,   14,   14,    8,   15,   14,   14,   15,   12,
             10,    9,    9,   10,   10,   11,   10,   13,    7,    4,
              6,    6,    7,    3,    3,    4,    5,    6,    3,   14};

    static int Ntw[100] = {
             -4,   -2,    0,    4,   -1,   -1,   -2,    9,    2,   -2,
              0,   -7,   -5,   -5,   -8,   -1,    0,   -5,    2,   -1,
              1,    1,    4,   -1,    4,  -14,  -12,   -8,  -13,  -11,
             -9,  -13,  -10,   -6,   -8,   -9,  -11,   -7,   -2,   -7,
             -6,   -5,   -3,    1,   -7,  -13,   -4,   -3,   -6,   25,
             -2,    8,   -1,    6,   20,   20,   15,   22,   17,   28,
             25,   26,   30,   -2,    1,    2,    2,    8,    7,    0,
             -2,   -1,   -1,    2,   -4,    4,    4,    9,    8,   -7,
            -10,  -10,   -9,   -7,   -4,   -3,   -2,    1,    1,    1,
              8,    2,    9,    0,    3,    3,    6,    5,    1,   18};

	for (i = 0; i < 100; i++)
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

        for (i = 0; i < 100; i++)
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

