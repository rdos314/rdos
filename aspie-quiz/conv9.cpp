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

#include "pop.h"
#include "file.h"
#include "quizdb9.h"
#include "conv9.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-9 VALUES(";

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
	int i;
	int assum = 0;
	int astotsum = 0;
	int ntsum = 0;
	int nttotsum = 0;
	int val;
	int aw;
	int nw;
	int grp;
	int dx;
	int w;
    int sum;
    int totsum;

    static int Asw[153] = {
              5,    7,    4,    4,    4,    4,    8,    2,    3,    6,
              7,    7,    7,    5,    4,    5,   10,    9,    7,   10,
              7,    7,    9,   10,    7,    4,    7,    7,    8,    6,
             12,   11,   12,    8,   13,   11,   12,   14,   15,    7,
              8,    4,   10,    6,    5,    6,    5,   10,   11,    5,
             11,   15,    4,    5,   15,   12,    5,   10,    8,   10,
             11,   11,   11,    8,   11,    4,    6,   10,    4,    4,
              8,   10,    4,    6,    4,    3,    6,    6,    6,    4,
              7,    6,    8,    5,    6,    4,    7,    7,    9,    5,
              5,    5,    5,    4,    9,    5,    8,    4,    9,    8,
              6,    8,    9,    7,    7,    7,    7,    7,    6,    9,
              8,   13,    8,   10,    7,    8,    8,    8,    8,    3,
              4,    4,    4,    9,   10,   11,   11,    9,    9,    8,
             13,    7,    4,    8,    6,   13,    8,    4,    3,    8,
             11,   13,    7,    7,    6,   11,    4,    7,    9,    5};

    static int Ntw[153] = {
              0,   -1,    0,   -1,    1,   -1,    6,   -2,   -1,   -5,
             -6,   -5,   -7,   10,   -4,   -5,   15,   11,    8,   -5,
             -3,   -2,   -3,    0,   -1,   -3,   -4,   -3,    0,   -3,
             -2,   -4,    0,   -2,    0,    1,    4,    4,    2,   -4,
             -3,   -4,    0,    5,   -1,   -2,    6,    8,   -8,   16,
             -7,   -3,   13,   15,   -2,   -5,   19,   -4,   -6,   -5,
             -3,   -5,   -5,   -7,   -6,   14,   16,   -3,   15,   15,
             -8,   -4,   12,   11,   13,   10,   15,   12,   15,   16,
             15,   12,   14,   11,    6,    9,    1,   -6,   -1,   -4,
             -6,   -4,   -5,   -3,   -2,   -2,   -2,   -2,   -9,   -7,
             18,   -8,   19,   18,   18,   -8,   -6,   -7,   15,   20,
             -7,   -2,   -8,   -6,   -8,   -3,   -6,   -6,   -3,   -3,
             -1,   -1,    1,   -6,   -6,   -7,   -4,   -7,   -1,   -4,
             -1,   -2,   -5,   -1,   -4,   -1,    0,   -4,    2,    9,
			 14,   15,   -1,    0,    0,    9,    0,   13,   11,   -1};


	for (i = 0; i < 150; i++)
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

		for (i = 0; i < 150; i++)
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

	for (fieldno = 0; fieldno < 209; fieldno++)
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
					break;

				case 2:
					Row.BirthYear = atoi(valstr);
					break;

				case 3:
					Row.BirthMonth = atoi(valstr);
                	switch (Row.BirthMonth)
            	    {
                        case 2:
                        case 3:
                        case 4:
                        case 5:
						    Row.Quiz[152] = 1;
						    break;

                        case 8:
						case 9:
						case 10:
						case 11:
					        Row.Quiz[152] = 3;
						    break;

						default:
							Row.Quiz[152] = 2;
                            break;
            	    }
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
            		    	Row.Quiz[150] = 3;
    		            	break;

                   		case 3:
	    	            	Row.Quiz[150] = 1;
            		    	break;

		                case 4:
                		case 6:
	    	            	Row.Quiz[150] = 2;
                			break;

	    	            case 7:
							Row.Quiz[150] = 0;
    		            	break;
            	    }
					break;

				case 6:
					Row.Eye = atoi(valstr);
                	switch (Row.Eye)
            	    {
            		    case 1:
                		case 2:
							Row.Quiz[151] = 1;
							break;

						case 3:
							Row.Quiz[151] = 2;
							break;

						case 4:
						case 5:
							Row.Quiz[151] = 3;
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
	TFile infile("quiz9.sql");
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
