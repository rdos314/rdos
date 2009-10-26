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
# convge3.cpp
# Convert exported quiz-ge3 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdge3.h"
#include "convge.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-ge3 VALUES(";

TFile quizfile("quizge3.bin", 0);


/*##################  HandleRow ##########################
*   Purpose....: Handle a row       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void HandleRow(TQuizRow *Row)
{
	int dx;

	quizfile.Write(Row, sizeof(TQuizRow));

	printf("%d AS: %d, NT: %d, [", Row->ID, Row->AsResult, Row->NtResult);

	for (dx = 0; dx < DX_COUNT; dx++)
	{
		printf("%d", Row->DxResult[dx]);
		if (dx != DX_COUNT - 1)
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
	int dx;
	int i;
	int val;
	int w;
	int sum;
	int totsum;

	for (grp = 0; grp < 14; grp++)
	{
		sum = 0;
		totsum = 0;

		for (i = 0; i < 155; i++)
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

	for (dx = 0; dx < DX_COUNT; dx++)
	{
		sum = 0;
		totsum = 0;

		for (i = 0; i < 155; i++)
		{
			val = row->Quiz[i];

			if (val)
			{
				w = Dw[i][dx];

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
			row->DxResult[dx] = 100 * sum / totsum;
		else
			row->DxResult[dx] = 0;
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

//    AncestryRow.Lang = 0;
    
	for (fieldno = 0; fieldno < 172; fieldno++)
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
//					AncestryRow.BirthYear = atoi(valstr);
					break;

				case 6:
					Row.BirthMonth = atoi(valstr);
//					AncestryRow.BirthMonth = atoi(valstr);
					break;

				case 7:
					Row.Gender = atoi(valstr);
//					AncestryRow.Gender = atoi(valstr);
					break;

				case 8:
					Row.Country = atoi(valstr);
//					AncestryRow.Country = atoi(valstr);
					break;

				case 9:
					Row.Ancestry = atoi(valstr);
//					AncestryRow.Ancestry = atoi(valstr);
					break;

				case 10:
					Row.Aspie = atoi(valstr);
					break;

				case 11:
					Row.ADHD = atoi(valstr);
					break;

				case 12:
					Row.OCD = atoi(valstr);
					break;

				case 13:
					Row.Social = atoi(valstr);
					break;

				case 14:
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

				case 15:
					Row.AsResult = atoi(valstr);
//					AncestryRow.AsResult = atoi(valstr);
					break;

				case 16:
					Row.NtResult = atoi(valstr);
//					AncestryRow.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 17;
					if (i >= 0)
					{
        				Row.Quiz[i] = atoi(valstr);
    	    		}
					break;
			}
		}
	}

//	UpdateScore(&Row);
	HandleRow(&Row);

//	ancfile.Write(&AncestryRow, sizeof(TQuizAncestryRow));

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
	TFile infile("quizge3.sql");
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

