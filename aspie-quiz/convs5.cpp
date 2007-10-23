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
# convs5.cpp
# Convert exported quiz-s5 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdbs5.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-s5 VALUES(";

TFile quizfile("quizs5.bin", 0);

static int Gw[177][12] = 
{
    {4, 10, 4, 1, 6, 0, 5, 1, 2, 0, 3, 3},
    {1, 13, 4, 0, 3, 0, 4, 0, 0, 0, 2, 1},
    {0, 11, 0, 0, 2, 0, 0, 2, 0, 0, 2, 0},
    {2, 11, 1, 0, 3, 0, 5, 3, 1, 1, 0, 1},
    {0, 13, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0},
    {0, 15, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0},
    {3, 2, 11, 3, 0, 0, 0, 0, 3, 0, 1, 3},
    {6, 4, 11, 3, 6, 0, 3, 0, 4, 5, 3, 0},
    {2, 4, 6, 0, 4, 0, 1, 2, 1, 0, 1, 1},
    {3, 1, 10, 2, 1, 0, 2, 0, 4, 0, 1, 2},
    {2, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 2},
    {2, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 2},
    {1, 4, 6, 0, 1, 0, 0, 0, 1, 0, 1, 1},
    {3, 0, 7, 1, 1, 0, 0, 0, 3, 0, 0, 0},
    {3, 0, 4, 9, 3, 4, 2, 2, 8, 0, 4, 1},
    {3, 0, 2, 9, 2, 1, 1, 1, 3, 0, 1, 1},
    {5, 1, 2, 7, 2, 1, 4, 3, 2, 1, 2, 1},
    {6, 0, 1, 8, 0, 2, 1, 3, 3, 0, 0, 0},
    {4, 0, 2, 7, 0, 0, 0, 0, 0, 0, 0, 2},
    {3, 0, 1, 12, 0, 1, 1, 2, 6, 0, 1, 1},
    {3, 4, 2, 8, 4, 0, 6, 7, 5, 0, 3, 1},
    {7, 2, 2, 10, 1, 0, 6, 4, 3, 1, 2, 0},
    {5, 0, 2, 11, 0, 0, 0, 0, 0, 0, 0, 3},
    {6, 0, 4, 6, 1, 0, 3, 0, 0, 1, 2, 2},
    {5, 0, 3, 10, 0, 0, 1, 0, 2, 0, 0, 4},
    {4, 0, 2, 6, 0, 0, 1, 0, 4, 0, 0, 0},
    {7, 0, 5, 8, 0, 0, 1, 0, 7, 0, 2, 1},
    {0, 5, 2, 0, 10, 0, 3, 3, 2, 0, 5, 0},
    {2, 2, 0, 3, 7, 0, 3, 3, 4, 0, 3, 0},
    {1, 1, 2, 1, 5, 0, 1, 0, 3, 0, 2, 1},
    {0, 3, 0, 0, 9, 1, 4, 4, 0, 0, 3, 0},
    {0, 0, 0, 0, 5, 0, 0, 2, 0, 0, 1, 0},
    {2, 6, 0, 0, 6, 0, 2, 0, 0, 0, 0, 0},
    {0, 0, 1, 0, 8, 0, 0, 0, 1, 0, 4, 0},
    {0, 3, 3, 0, 10, 0, 3, 0, 0, 0, 5, 1},
    {0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 1, 0, 4, 0, 1, 0, 0, 1, 4, 3},
    {0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 3, 0},
    {0, 7, 4, 3, 2, 8, 0, 3, 2, 0, 6, 0},
    {0, 1, 5, 3, 2, 8, 0, 1, 3, 0, 5, 0},
    {2, 1, 3, 6, 1, 5, 0, 1, 1, 0, 5, 1},
    {4, 4, 2, 3, 5, 5, 6, 6, 3, 0, 3, 0},
    {0, 0, 3, 1, 0, 4, 0, 0, 3, 0, 0, 0},
    {0, 1, 0, 0, 1, 6, 2, 3, 2, 0, 2, 0},
    {3, 2, 2, 6, 1, 4, 3, 5, 5, 3, 6, 0},
    {0, 2, 0, 4, 2, 4, 2, 7, 4, 3, 5, 0},
    {0, 2, 3, 0, 0, 4, 0, 1, 2, 0, 0, 0},
    {1, 0, 2, 5, 0, 5, 0, 1, 4, 0, 1, 0},
    {2, 0, 3, 6, 1, 4, 2, 4, 7, 2, 6, 0},
    {0, 0, 0, 1, 0, 4, 0, 4, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 7, 0, 1, 1, 0, 3, 0},
    {0, 0, 0, 0, 1, 11, 0, 7, 0, 0, 2, 0},
    {0, 0, 0, 0, 0, 6, 0, 1, 3, 0, 0, 0},
    {0, 0, 0, 3, 0, 3, 0, 2, 0, 0, 0, 0},
    {0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0},
    {0, 0, 3, 0, 0, 5, 0, 0, 4, 0, 2, 0},
    {0, 0, 0, 0, 0, 6, 0, 4, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 4, 0, 4, 0, 0, 0, 0},
    {0, 0, 0, 0, 2, 6, 1, 1, 0, 0, 4, 0},
    {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 6, 0, 1, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 4, 0, 1, 0, 0, 0, 0},
    {4, 3, 1, 3, 3, 0, 7, 5, 2, 1, 1, 1},
    {1, 0, 0, 1, 3, 0, 2, 0, 0, 2, 0, 0},
    {6, 4, 1, 7, 2, 0, 8, 5, 2, 5, 2, 0},
    {2, 5, 1, 2, 3, 0, 5, 3, 0, 1, 2, 1},
    {6, 3, 3, 2, 1, 0, 8, 1, 1, 2, 1, 2},
    {3, 2, 1, 0, 1, 0, 4, 0, 0, 2, 0, 0},
    {4, 3, 1, 1, 2, 0, 6, 1, 0, 1, 1, 2},
    {4, 7, 1, 2, 2, 0, 7, 3, 1, 1, 1, 0},
    {5, 1, 0, 0, 0, 0, 8, 0, 0, 1, 0, 0},
    {5, 1, 1, 2, 1, 0, 7, 0, 0, 1, 0, 0},
    {3, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 2},
    {6, 0, 0, 0, 0, 0, 7, 0, 0, 1, 0, 3},
    {3, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 1},
    {7, 1, 3, 0, 0, 0, 7, 0, 1, 1, 0, 1},
    {3, 0, 0, 1, 0, 0, 5, 0, 0, 0, 0, 1},
    {2, 0, 0, 0, 1, 0, 6, 0, 0, 1, 0, 1},
    {2, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 3},
    {1, 3, 1, 0, 1, 0, 6, 0, 0, 0, 0, 1},
    {0, 0, 0, 0, 0, 0, 3, 0, 0, 1, 0, 1},
    {0, 5, 0, 3, 5, 6, 4, 9, 2, 0, 6, 0},
    {3, 4, 4, 6, 6, 4, 7, 7, 3, 0, 7, 2},
    {2, 8, 3, 4, 7, 7, 7, 12, 4, 0, 6, 0},
    {3, 4, 3, 5, 5, 1, 6, 9, 5, 0, 3, 1},
    {1, 4, 3, 3, 4, 1, 2, 7, 3, 0, 5, 1},
    {2, 6, 1, 5, 5, 4, 6, 12, 4, 0, 4, 0},
    {4, 2, 1, 6, 3, 0, 4, 7, 2, 0, 2, 0},
    {2, 6, 1, 3, 6, 1, 7, 11, 3, 0, 3, 0},
    {0, 2, 0, 0, 0, 7, 0, 11, 0, 0, 1, 0},
    {0, 3, 0, 0, 1, 3, 1, 7, 0, 0, 0, 0},
    {1, 5, 2, 5, 7, 5, 3, 13, 5, 1, 6, 0},
    {4, 1, 4, 8, 3, 1, 4, 9, 4, 0, 2, 1},
    {0, 0, 0, 0, 1, 4, 0, 10, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0},
    {0, 1, 0, 0, 1, 2, 0, 8, 0, 0, 0, 0},
    {0, 2, 0, 0, 5, 4, 0, 6, 0, 0, 0, 0},
    {0, 6, 0, 0, 1, 0, 0, 3, 0, 0, 0, 0},
    {1, 1, 4, 3, 3, 2, 2, 0, 7, 0, 4, 1},
    {1, 0, 1, 3, 1, 3, 2, 2, 8, 0, 1, 0},
    {1, 1, 4, 5, 4, 1, 2, 0, 8, 0, 5, 1},
    {4, 1, 5, 4, 1, 0, 5, 0, 10, 0, 3, 2},
    {1, 0, 4, 4, 2, 0, 3, 1, 12, 0, 3, 2},
    {2, 1, 4, 0, 0, 0, 0, 0, 6, 0, 0, 1},
    {3, 2, 3, 5, 4, 1, 2, 2, 8, 0, 2, 0},
    {0, 0, 2, 0, 0, 0, 0, 0, 4, 0, 0, 1},
    {0, 3, 5, 0, 4, 0, 1, 0, 3, 0, 8, 3},
    {0, 1, 2, 0, 2, 5, 0, 0, 4, 0, 7, 0},
    {0, 5, 2, 0, 6, 3, 2, 3, 2, 0, 11, 0},
    {0, 3, 3, 0, 0, 0, 1, 0, 1, 2, 6, 1},
    {0, 2, 1, 0, 4, 0, 0, 0, 3, 0, 8, 2},
    {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 2},
    {3, 0, 1, 2, 0, 0, 2, 0, 1, 1, 7, 3},
    {5, 2, 1, 5, 2, 0, 4, 4, 1, 1, 3, 2},
    {5, 3, 3, 5, 4, 0, 5, 4, 3, 0, 1, 1},
    {3, 0, 1, 6, 2, 5, 3, 4, 2, 0, 1, 0},
    {3, 1, 0, 3, 3, 0, 3, 0, 0, 0, 4, 0},
    {3, 1, 2, 3, 1, 2, 2, 1, 2, 1, 5, 1},
    {3, 1, 2, 5, 1, 0, 4, 2, 2, 0, 3, 2},
    {2, 0, 3, 2, 0, 0, 3, 0, 0, 0, 0, 2},
    {12, 0, 5, 9, 0, 0, 4, 0, 4, 1, 0, 1},
    {1, 0, 2, 0, 1, 3, 3, 0, 1, 15, 4, 0},
    {2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2},
    {2, 0, 1, 1, 1, 0, 2, 0, 1, 1, 0, 2},
    {8, 0, 2, 2, 0, 0, 2, 0, 0, 10, 0, 0},
    {10, 0, 1, 1, 0, 0, 5, 0, 0, 0, 0, 1},
    {0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {5, 2, 1, 0, 0, 0, 2, 0, 0, 8, 0, 0},
    {0, 1, 3, 0, 4, 0, 0, 0, 4, 0, 2, 2},
    {9, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 4},
    {0, 0, 1, 0, 2, 0, 2, 0, 2, 2, 4, 1},
    {2, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0},
    {0, 0, 3, 0, 1, 0, 0, 0, 0, 0, 2, 2},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 1, 0, 0, 0, 0, 0, 8, 3, 1},
    {0, 1, 0, 0, 6, 0, 0, 1, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 1, 0, 4, 0, 5, 0, 1, 2, 0},
    {0, 0, 0, 0, 0, 6, 0, 3, 0, 0, 2, 0},
    {14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {10, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0},
    {12, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
    {20, 0, 1, 2, 1, 0, 6, 0, 0, 0, 0, 6},
    {21, 0, 1, 2, 0, 0, 4, 0, 0, 0, 0, 5},
    {6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {15, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 2},
    {12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
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

	for (grp = 0; grp < 11; grp++)
	{
	    printf("%d", Row->GroupResult[grp]);
	    if (grp != 10)
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

    for (grp = 0; grp < 11; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 138; i++)
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

	for (fieldno = 0; fieldno < 201; fieldno++)
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
					Row.Quiz[171] = Row.Dyslexia;
					break;

				case 14:
					Row.Dyscalculia = atoi(valstr);
					Row.Quiz[172] = Row.Dyscalculia;
					break;

				case 15:
					Row.OCD = atoi(valstr);
					Row.Quiz[173] = Row.OCD;
					break;

				case 16:
					Row.ODD = atoi(valstr);
					Row.Quiz[174] = Row.ODD;
					break;

				case 17:
					Row.Bipolar = atoi(valstr);
					Row.Quiz[175] = Row.Bipolar;
					break;

				case 18:
					Row.Schizophrenia = atoi(valstr);
					break;

				case 19:
					Row.Social = atoi(valstr);
					Row.Quiz[176] = Row.Social;
					break;

				case 20:
					Row.Country = atoi(valstr);
					break;

				case 21:
					Row.Ancestry = atoi(valstr);
					break;

				case 22:
					Row.Adopt = atoi(valstr);
					Row.Quiz[177] = Row.Adopt;
					break;

				case 23:
					Row.Grow = atoi(valstr);
					Row.Quiz[178] = Row.Grow;
					break;

				case 24:
					Row.Parent = atoi(valstr);
					Row.Quiz[179] = Row.Parent;
					break;

				case 25:
					Row.Income = atoi(valstr);
					Row.Quiz[180] = Row.Income;
					break;

				case 26:
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

				case 27:
					Row.AsResult = atoi(valstr);
					break;

				case 28:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 29;
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
	TFile infile("quizs5.sql");
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
