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
# conv9.cpp
# Convert exported quiz-9 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdb9.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-9 VALUES (";

TFile quizfile("quiz9.bin", 0);

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
   int j;
	TQuizRow Row;
	int quote;

	for (fieldno = 0; fieldno < 209; fieldno++)
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
					Row.BirthMonth = atoi(valstr);
					break;

				case 4:
					Row.Gender = atoi(valstr);
					break;

				case 5:
					Row.Hair = atoi(valstr);
                	switch (Row.Hair)
            	    {
            		    case 1:
    		            case 2:
            	    	case 5:
            		    	Row.Quiz[151] = 3;
    		            	break;

                   		case 3:
	    	            	Row.Quiz[151] = 1;
            		    	break;

		                case 4:
                		case 6:
	    	            	Row.Quiz[151] = 2;
                			break;

	    	            case 7:
            		    	Row.Quiz[151] = 0;
    		            	break;
            	    }
					break;

				case 6:
					Row.Eye = atoi(valstr);
                	switch (Row.Eye)
            	    {
            		    case 1:
                		case 2:
							Row.Quiz[152] = 1;
							break;

						case 3:
							Row.Quiz[152] = 2;
							break;

						case 4:
						case 5:
							Row.Quiz[152] = 3;
							break;
					}
					break;

				case 7:
					Row.Lang = atoi(valstr);
					break;

				case 8:
					Row.Autism = atoi(valstr);
					break;

				case 9:
					Row.Aspie = atoi(valstr);
					break;

				case 10:
					Row.ADHD = atoi(valstr);
					break;

				case 11:
					Row.ABO = atoi(valstr);
					break;

				case 12:
					Row.Parkinson = atoi(valstr);
					break;

				case 13:
					Row.Alzheimer = atoi(valstr);
					break;

				case 14:
					Row.CFTR = atoi(valstr);
					break;

				case 15:
					Row.HFE = atoi(valstr);
					break;

				case 16:
					Row.Leiden = atoi(valstr);
					break;

				case 17:
					Row.RA = atoi(valstr);
					break;

				case 18:
					Row.Fibromyalgia = atoi(valstr);
					break;

			    case 19:
			    case 20:
			    case 21:
			    case 22:
			    case 23:
			        break;

				case 24:
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

				case 25:
					Row.AsResult = atoi(valstr);
					break;

				case 26:
					Row.NtResult = atoi(valstr);
					break;

			    case 177:
			        break;

				default:
					i = fieldno - 27;
					if (i < 150)
    					Row.Quiz[i] = atoi(valstr);
    				else
    				{
    				    i = i - 151;

    				    if (i < 31)
    				        Row.Stim[i] = atoi(valstr);
    				}
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
	TFile infile("quiz9.sql");

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
