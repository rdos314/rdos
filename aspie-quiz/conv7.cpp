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
# Convert exported quiz-7 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdb7.h"
#include "conv7.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-7 VALUES(";

TFile quizfile("quiz7.bin", 0);


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

	static int Asw[150] = {
			 11,    7,   14,   10,    7,    7,   10,   11,    7,    8,
			 10,    4,    7,    7,    6,    8,    5,    3,   12,   11,
			 13,   13,    9,   12,   13,   14,   13,    8,    7,    3,
			  6,   10,    4,    8,    6,   12,    7,    5,    5,   13,
			 12,    5,   14,    5,   13,    9,   14,    6,    4,   12,
			 12,   14,    7,    9,   11,    4,    7,   11,    4,    6,
			  4,    5,    7,    6,    5,    8,    6,    3,    4,   10,
			  9,    9,    7,   12,    8,    8,    8,    8,    8,    6,
			  7,    7,    9,   10,    9,    9,    7,   12,    9,    9,
			  5,   10,    9,    8,    2,    5,    3,    6,    4,    3,
			 11,    5,   11,   10,   10,   12,   11,    9,    4,    5,
			  2,    7,    9,    4,    6,    9,    7,    6,   10,   11,
			 13,   11,    7,    6,    7,    7,    3,    9,    9,    5,
			  7,    4,    5,    7,    2,   11,    3,    8,    7,    4,
			  6,    4,    3,   10,   12,    9,    7,   11,   10,    8};

	static int Ntw[150] = {
			 -4,   -2,    2,   -3,   -2,   -2,   -1,   -3,   -3,   -2,
			 -1,    0,   -6,   -5,   -6,   -5,   -4,   -4,    0,   -3,
			  0,    1,   -2,    3,    5,    6,    7,   -3,   -4,   -3,
			  0,    0,   -1,   -2,   -1,    9,    5,   -1,   17,   -7,
             -3,   14,   -1,   20,   -4,   -6,    0,   15,   13,   -5,
             -4,    2,   17,   -3,   -4,   14,   -6,   -4,   11,   17,
             11,   12,   16,   16,   12,   16,   11,    4,    7,  -11,
             -9,   19,   20,   -7,   -7,   -9,   -7,   19,   -7,   16,
             19,   -9,   21,   -7,   -3,   -8,   -8,   -2,   -7,   -6,
             -5,   -6,   -6,   -5,   -1,    0,    0,   12,   10,    4,
              4,    4,   10,   -8,   -6,   -4,   -3,   -9,   -4,   -4,
             -2,    1,   -1,   -5,   -6,   -4,   17,   -4,   -7,   -3,
             -1,   -1,   -6,   15,   13,   13,   -4,   -2,   -3,   -4,
			  0,   -5,   -3,    8,    4,   14,   -2,    5,   -2,    0,
             -6,   -6,   -2,    5,    7,   -4,    8,   -3,   -1,    5};

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
void ProcessRow(char *str)
{
	char *valstr;
	char *ptr;
	int fieldno;
	int i;
	TQuizRow Row;
	int quote;

	for (fieldno = 0; fieldno < 174; fieldno++)
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
					Row.Hair = atoi(valstr);
            		switch (Row.Hair)
            		{
            		    case 1:
                		case 2:
            	    	case 5:
            		    	Row.Quiz[154] = 3;
                			break;

                		case 3:
	    	            	Row.Quiz[154] = 1;
            		    	break;

		                case 4:
                		case 6:
            	    		Row.Quiz[154] = 2;
    		            	break;

            	    	case 7:
		                	Row.Quiz[154] = 0;
                			break;
            	    }   
					break;

				case 5:
					Row.Eye = atoi(valstr);
                	switch (Row.Eye)
            	    {
            		    case 1:
                		case 2:
							Row.Quiz[155] = 1;
							break;

						case 3:
							Row.Quiz[155] = 2;
							break;

						case 4:
						case 5:
							Row.Quiz[155] = 3;
							break;
					}
					break;

				case 6:
					Row.Lang = atoi(valstr);
					break;

				case 7:
					Row.Country = atoi(valstr);
					break;

				case 8:
					Row.Ancestry = atoi(valstr);
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
					Row.Social = atoi(valstr);
					Row.Quiz[150] = Row.Social;
					break;

				case 13:
					Row.Premature = atoi(valstr);
					switch (Row.Premature)
					{
					    case 1:
					        Row.Quiz[156] = 0;
					        Row.Quiz[157] = 0;
                            break;
					        
					    case 2:
        					Row.Quiz[156] = 3;
					        Row.Quiz[157] = 1;
        					break;

                        case 3:
        			        Row.Quiz[156] = 1;
					        Row.Quiz[157] = 1;
					        break;

					    case 4:
					    case 5:
        			        Row.Quiz[156] = 1;
					        Row.Quiz[157] = 2;
					        break;
                                    					
					    case 6:
					    case 7:
        			        Row.Quiz[156] = 1;
					        Row.Quiz[157] = 3;
					        break;
                            
        			}
					break;

				case 14:
					Row.Job = atoi(valstr);
					break;

				case 15:
					Row.Music = atoi(valstr);
					switch (Row.Music)
					{
					    case 1:
        					Row.Quiz[151] = 0;
        					break;

        			    case 2:
        			        Row.Quiz[151] = 0;
        			        break;

        			    case 3:
        			        Row.Quiz[151] = 2;
        			        break;
        			}
					break;

				case 16:
					Row.Politics = atoi(valstr);
					if (Row.Politics == 6)
					    Row.Quiz[152] = 2;
					else
					    Row.Quiz[152] = 0;
					break;

				case 17:
					Row.Religion = atoi(valstr);
					switch (Row.Religion)
					{
					    case 1:
					    case 6:
					    case 11:
					        Row.Quiz[158] = 1;
					        break;

					    case 26:
					        Row.Quiz[158] = 3;
					        break;


					    default:
					        Row.Quiz[158] = 2;
					        break;
                    }					        
					break;

				case 18:
					Row.Temp = atoi(valstr);
					switch (Row.Temp)
					{
					    case 1:
					    case 2:
					    case 3:
					    case 4:
					    case 5:
					        Row.Quiz[153] = 2;
					        break;

					    case 6:
					        Row.Quiz[153] = 1;
					        break;

					    case 7:
					    case 8:
					        Row.Quiz[153] = 0;
					        break;
					}
					break;

				case 19:
					Row.Vision = atoi(valstr);
					switch (Row.Vision)
					{
					    case 3:
					    case 4:
					        Row.Quiz[159] = 2;
					        break;
					        
					    case 5:
					    case 6:
					        Row.Quiz[159] = 3;
					        break;

                        default:
                            Row.Quiz[159] = 1;
                            break;
                    }
					break;

				case 20:
					Row.Learn = atoi(valstr);
					switch (Row.Learn)
					{
					    case 1:
					        Row.Quiz[160] = 1;
					        break;

					    case 2:
					        Row.Quiz[160] = 2;
					        break;

					    case 3:
					        Row.Quiz[160] = 3;
					        break;
				    }
					break;

				case 21:
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

				case 22:
					Row.AsResult = atoi(valstr);
					break;

				case 23:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 24;
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
	TFile infile("quiz7.sql");
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
