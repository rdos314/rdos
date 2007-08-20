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
#include "quizdb8.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-8 VALUES (";

TFile quizfile("quiz8.bin", 0);

static int Gw[154][8] = 
{
    {38, 63, 51, 40, 48, 56, 44, 48},
    {25, 56, 44, 34, 28, 45, 38, 31},
    {31, 43, 34, 27, 32, 41, 43, 33},
    {34, 52, 47, 33, 37, 52, 47, 41},
    {27, 41, 35, 26, 29, 38, 46, 32},
    {24, 39, 30, 27, 27, 37, 26, 32},
    {33, 59, 43, 37, 42, 53, 44, 44},
    {37, 59, 40, 36, 38, 52, 41, 39},
    {34, 43, 32, 35, 36, 46, 46, 41},
    {29, 47, 32, 29, 29, 45, 33, 28},
    {21, 54, 36, 29, 25, 39, 33, 26},
    {27, 41, 31, 29, 28, 40, 46, 35},
    {29, 39, 32, 30, 28, 41, 39, 32},
    {31, 56, 37, 32, 34, 44, 37, 34},
    {-40, 0, 6, -2, -7, 4, 1, -4},
    {-42, -6, 0, -5, -17, -1, -1, -9},
    {-34, 3, 13, -3, -4, 5, 4, -3},
    {-42, -24, -21, -32, -36, -33, -30, -44},
    {-29, 2, 11, -2, -4, 7, 1, -1},
    {39, 48, 44, 49, 43, 53, 52, 51},
    {55, 38, 31, 32, 36, 39, 35, 42},
    {51, 38, 32, 45, 38, 46, 39, 47},
    {51, 42, 27, 40, 34, 44, 38, 42},
    {46, 44, 33, 34, 28, 43, 42, 36},
    {52, 35, 26, 30, 28, 35, 31, 36},
    {34, 33, 34, 40, 36, 39, 38, 41},
    {28, 49, 64, 30, 41, 49, 43, 45},
    {30, 42, 58, 31, 47, 52, 40, 49},
    {22, 38, 53, 22, 31, 42, 34, 33},
    {25, 46, 60, 27, 35, 47, 40, 37},
    {24, 47, 60, 24, 37, 49, 41, 38},
    {16, 36, 58, 10, 26, 35, 30, 27},
    {4, 25, 49, 12, 27, 28, 26, 27},
    {15, 27, 41, 4, 18, 25, 21, 14},
    {26, 31, 25, 47, 32, 38, 34, 38},
    {23, 31, 21, 47, 26, 41, 32, 34},
    {31, 33, 21, 43, 22, 33, 35, 25},
    {31, 27, 23, 41, 19, 34, 34, 28},
    {22, 25, 6, 40, 9, 21, 18, 12},
    {16, 18, 10, 34, 11, 20, 22, 17},
    {28, 25, 15, 47, 20, 31, 26, 26},
    {28, 32, 20, 49, 26, 39, 31, 32},
    {40, 54, 58, 42, 67, 63, 48, 61},
    {-36, -34, -32, -30, -61, -41, -30, -55},
    {37, 49, 53, 37, 55, 58, 41, 49},
    {39, 41, 43, 40, 65, 55, 41, 62},
    {-28, -26, -24, -17, -58, -30, -25, -37},
    {-34, -28, -22, -31, -53, -34, -24, -45},
    {37, 50, 46, 37, 60, 56, 40, 51},
    {37, 45, 42, 42, 64, 58, 43, 55},
    {-27, -30, -35, -29, -55, -40, -31, -46},
    {34, 47, 40, 32, 54, 48, 39, 50},
    {28, 39, 50, 40, 53, 55, 43, 53},
    {27, 37, 32, 33, 45, 45, 31, 37},
    {34, 45, 40, 32, 52, 49, 36, 48},
    {24, 33, 43, 35, 52, 46, 36, 46},
    {34, 38, 37, 36, 53, 52, 39, 47},
    {30, 46, 36, 36, 49, 49, 37, 42},
    {28, 41, 48, 34, 53, 53, 45, 52},
    {27, 44, 56, 44, 53, 57, 52, 53},
    {-38, -36, -29, -27, -53, -37, -24, -40},
    {31, 38, 41, 33, 62, 50, 34, 52},
    {-28, -29, -26, -20, -64, -31, -21, -46},
    {-34, -29, -24, -29, -64, -36, -26, -53},
    {30, 41, 44, 40, 47, 52, 40, 47},
    {-24, -22, -30, -18, -49, -32, -24, -45},
    {33, 35, 29, 36, 53, 47, 33, 45},
    {-28, -30, -27, -32, -58, -41, -27, -49},
    {34, 38, 37, 40, 53, 51, 40, 54},
    {25, 38, 45, 26, 53, 48, 35, 41},
    {-22, -27, -30, -21, -52, -33, -21, -42},
    {-18, -25, -23, -16, -57, -26, -17, -32},
    {-14, -18, -16, -10, -49, -17, -12, -27},
    {-19, -15, -6, -17, -36, -11, -10, -25},
    {-13, -14, -22, -16, -47, -22, -19, -28},
    {-9, -17, -22, -12, -41, -18, -13, -29},
    {-11, -11, -18, -9, -28, -15, -15, -22},
    {-14, -10, -12, -6, -41, -10, -9, -23},
    {-9, -14, -15, -5, -33, -10, -10, -19},
    {-12, -13, -12, -1, -27, -7, -4, -13},
    {-1, 3, -11, -2, -29, -7, -3, -19},
    {3, 7, -12, 0, -26, -4, -2, -18},
    {-16, -24, -15, -17, -43, -19, -15, -28},
    {26, 38, 36, 32, 32, 45, 51, 33},
    {34, 44, 41, 42, 38, 54, 54, 50},
    {22, 30, 32, 33, 28, 40, 53, 32},
    {24, 34, 36, 34, 31, 46, 53, 35},
    {28, 39, 40, 37, 32, 49, 57, 41},
    {28, 40, 37, 37, 32, 49, 57, 40},
    {23, 33, 27, 23, 20, 34, 44, 28},
    {12, 32, 28, 22, 13, 33, 40, 19},
    {46, 48, 47, 46, 58, 59, 50, 71},
    {38, 47, 42, 39, 45, 56, 42, 61},
    {-40, -31, -35, -31, -61, -44, -33, -68},
    {38, 49, 49, 43, 48, 58, 49, 65},
    {-36, -22, -23, -28, -52, -36, -27, -67},
    {-36, -31, -26, -34, -49, -41, -29, -67},
    {37, 46, 37, 38, 41, 46, 38, 50},
    {-36, -27, -30, -30, -54, -40, -31, -67},
    {-32, -24, -19, -28, -43, -34, -22, -60},
    {37, 39, 37, 37, 45, 49, 44, 56},
    {41, 44, 41, 44, 47, 55, 49, 52},
    {-32, -32, -32, -34, -52, -43, -35, -62},
    {37, 49, 43, 46, 47, 64, 45, 52},
    {32, 46, 48, 42, 45, 63, 47, 49},
    {33, 43, 47, 38, 51, 57, 43, 53},
    {33, 47, 58, 43, 55, 62, 46, 53},
    {37, 51, 45, 39, 47, 63, 46, 52},
    {33, 50, 47, 41, 36, 60, 48, 45},
    {32, 47, 46, 34, 42, 60, 46, 49},
    {29, 44, 49, 20, 35, 49, 37, 40},
    {15, 40, 48, 27, 36, 52, 38, 37},
    {17, 25, 21, 20, 20, 28, 23, 23},
    {15, 20, 17, 14, 13, 22, 20, 14},
    {15, 21, 25, 19, 18, 28, 27, 19},
    {5, 17, 21, 20, 9, 26, 23, 17},
    {42, 54, 58, 52, 68, 65, 55, 70},
    {45, 51, 39, 54, 44, 62, 48, 55},
    {41, 52, 51, 47, 56, 63, 52, 64},
    {31, 52, 55, 38, 50, 57, 44, 50},
    {35, 51, 59, 41, 49, 59, 47, 54},
    {33, 48, 48, 36, 37, 53, 47, 51},
    {45, 49, 39, 57, 46, 59, 47, 58},
    {33, 49, 40, 46, 38, 53, 43, 44},
    {39, 50, 53, 43, 48, 60, 52, 60},
    {14, 33, 35, 15, 16, 32, 27, 19},
    {36, 50, 51, 48, 53, 62, 54, 58},
    {35, 44, 34, 38, 33, 45, 41, 44},
    {-34, -32, -30, -35, -52, -43, -33, -54},
    {29, 44, 46, 35, 39, 49, 42, 40},
    {17, 21, 21, 19, 29, 25, 21, 25},
    {32, 40, 32, 47, 39, 50, 36, 43},
    {-7, 30, 34, 26, 24, 38, 32, 29},
    {-6, 27, 29, 27, 21, 37, 37, 27},
    {15, 33, 19, 27, 9, 28, 28, 15},
    {6, 15, 24, 11, 11, 22, 17, 14},
    {12, 42, 28, 25, 18, 32, 28, 19},
    {39, 60, 48, 54, 53, 62, 52, 56},
    {27, 36, 30, 37, 33, 43, 47, 36},
    {28, 38, 31, 34, 28, 41, 41, 35},
    {22, 31, 21, 25, 25, 31, 26, 25},
    {-20, -13, -19, -22, -50, -28, -23, -41},
    {18, 45, 42, 35, 36, 49, 43, 34},
    {24, 42, 27, 32, 23, 38, 32, 27},
    {5, 15, 2, 4, -6, 0, 1, -2},
    {3, 14, 13, 9, 12, 15, 12, 12},
    {16, 38, 35, 32, 23, 42, 40, 29},
    {0, 16, 15, 14, 4, 21, 19, 9},
    {23, 39, 48, 38, 54, 55, 42, 47},
    {17, 34, 28, 32, 22, 39, 35, 28},
    {9, 10, 8, 8, 6, 12, 10, 13},
    {4, 7, 8, 3, 6, 6, 6, 5},
    {6, 8, 9, 3, 5, 6, 7, 4},
    {0, 0, 2, 0, 0, 0, 0, 0}
};

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

	for (grp = 0; grp < 8; grp++)
	{
	    printf("%d", Row->GroupResult[grp]);
	    if (grp != 7)
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

    for (grp = 0; grp < 8; grp++)
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

                sum += val * w * w;
				totsum += 2 * w * w;
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

	for (fieldno = 0; fieldno < 305; fieldno++)
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
					Row.Gender = atoi(valstr);
					break;

				case 4:
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

				case 5:
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
					Row.HnSimilar = atoi(valstr);
					switch (Row.HnSimilar)
					{
					    case 1:
					    case 4:
        					Row.Quiz[150] = 1;
        					break;
        					
					    case 2:
					    case 3:
        					Row.Quiz[150] = 2;
        					break;

					    default:
        					Row.Quiz[150] = 3;
        					break;
        					
         			}
 					break;

				case 11:
					Row.HnGender = atoi(valstr);
            		switch (Row.HnGender)
            		{
            			case 1:
                    	    Row.Quiz[153] = 1;
                    		break;
        					
            			case 2:
                    		Row.Quiz[153] = 3;
                    		break;

                    }
					break;

			    case 12:
			    case 13:
			    case 14:
			    case 15:
			        break;

				case 16:
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

				case 17:
					Row.AsResult = atoi(valstr);
					break;

				case 18:
					Row.NtResult = atoi(valstr);
					break;

			    case 169:
			        break;

				default:
					i = fieldno - 19;
					if (i < 150)
    					Row.Quiz[i] = atoi(valstr);
    				else
    				{
    				    i = i - 151;
    				    j = i % 3;
    				    i = i / 3;

    				    if (i < 45)
    				        Row.Stim[i][j] = atoi(valstr);
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
	TFile infile("quiz8.sql");
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 150; i++)
	{
	    max = 0;

        for (grp = 0; grp < 8; grp++)
        {        
            w = Gw[i][grp];
            w = w * w;
			if (w > max)
				max = w;
		}

		for (grp = 0; grp < 8; grp++)
		{
			if (max)
			{
				w = Gw[i][grp];
				w = w * w / max;

				if (w >= 0.64)
					Gw[i][grp] = (int)((long double)Gw[i][grp] * w);
				else
					Gw[i][grp] = 0;
			}
			else
				Gw[i][grp] = 0;

		}
	}

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
