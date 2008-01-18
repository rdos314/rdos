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

#include "pop.h"
#include "file.h"
#include "quizdb.h"
#include "conv.h"

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz VALUES(";

TFile quizfile("quiz1.bin", 0);


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

	for (grp = 0; grp < 14; grp++)
	{
	    printf("%d", Row->GroupResult[grp]);
	    if (grp != 13)
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

	for (grp = 0; grp < 14; grp++)
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

			sum += val * w;
			totsum += 2 * w;
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

