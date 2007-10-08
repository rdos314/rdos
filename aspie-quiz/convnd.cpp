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

const char InsertString[] = "INSERT INTO aspie-quiz-nd VALUES(";

TFile quizfile("quiznd.bin", 0);

static int Gw[210][8] = 
{
    {6, 37, 25, 9, 17, 26, 22, 17},
    {39, 48, 37, 35, 44, 44, 38, 52},
    {36, 55, 48, 31, 41, 55, 45, 45},
    {26, 56, 39, 23, 26, 42, 35, 34},
    {36, 60, 39, 30, 37, 50, 38, 39},
    {31, 42, 33, 22, 31, 41, 39, 34},
    {10, 38, 34, 12, 22, 33, 30, 25},
    {33, 61, 44, 32, 43, 53, 43, 45},
    {31, 56, 37, 28, 34, 44, 34, 35},
    {29, 56, 39, 25, 30, 44, 35, 34},
    {46, 62, 46, 43, 54, 62, 47, 55},
    {33, 51, 38, 27, 51, 45, 36, 50},
    {27, 43, 36, 26, 35, 41, 32, 36},
    {35, 47, 40, 34, 38, 48, 41, 42},
    {27, 45, 42, 29, 36, 45, 36, 39},
    {10, 29, 13, 10, 13, 23, 12, 19},
    {31, 48, 29, 27, 30, 49, 29, 30},
    {51, 35, 24, 27, 28, 32, 26, 39},
    {56, 51, 37, 33, 39, 51, 47, 49},
    {-45, -15, -6, -24, -30, -21, -19, -32},
    {55, 38, 30, 28, 37, 36, 30, 44},
    {-40, -17, -10, -19, -31, -18, -8, -25},
    {-46, -18, -15, -19, -41, -23, -15, -34},
    {-29, -12, -2, -20, -26, -14, -11, -24},
    {-27, 1, 10, -20, -9, -7, -6, -9},
    {-6, 13, 17, -7, -8, 7, 6, -2},
    {40, 41, 34, 25, 27, 39, 34, 32},
    {48, 38, 31, 42, 38, 42, 33, 45},
    {47, 49, 48, 43, 61, 58, 51, 72},
    {-39, -30, -28, -27, -56, -38, -30, -68},
    {39, 50, 49, 40, 53, 57, 49, 68},
    {40, 44, 45, 35, 52, 52, 48, 67},
    {43, 53, 52, 44, 58, 62, 51, 66},
    {40, 41, 38, 36, 48, 50, 49, 58},
    {-18, -12, -6, -17, -10, -24, -17, -19},
    {22, 26, 19, 24, 9, 37, 28, 25},
    {-29, -22, -24, -21, -60, -28, -18, -53},
    {28, 39, 33, 28, 43, 44, 33, 41},
    {35, 38, 29, 45, 42, 44, 41, 53},
    {-36, -26, -28, -22, -49, -35, -26, -63},
    {40, 42, 41, 34, 44, 50, 47, 64},
    {-34, -32, -21, -30, -40, -34, -28, -49},
    {28, 42, 41, 24, 34, 45, 33, 47},
    {37, 37, 31, 25, 36, 38, 24, 55},
    {37, 40, 35, 27, 42, 43, 35, 49},
    {-24, -15, -8, -15, -27, -12, -6, -25},
    {29, 38, 30, 32, 28, 41, 46, 40},
    {-40, -21, -15, -25, -53, -30, -23, -66},
    {-32, -20, -15, -24, -50, -27, -23, -59},
    {40, 51, 42, 31, 46, 52, 38, 60},
    {33, 50, 49, 29, 37, 53, 39, 50},
    {14, 13, 16, 11, 24, 21, 16, 22},
    {32, 35, 21, 36, 32, 34, 40, 36},
    {29, 39, 35, 22, 31, 40, 46, 32},
    {24, 34, 27, 21, 18, 32, 40, 24},
    {24, 39, 30, 24, 26, 39, 41, 31},
    {9, 16, 19, 16, 12, 31, 29, 13},
    {35, 43, 31, 32, 36, 47, 47, 40},
    {29, 50, 63, 27, 44, 49, 42, 47},
    {28, 43, 57, 27, 51, 50, 40, 49},
    {-24, -20, -22, -22, -45, -28, -18, -39},
    {34, 51, 58, 38, 51, 57, 45, 55},
    {-27, -27, -28, -20, -56, -30, -20, -40},
    {-20, -10, 4, -22, -38, -13, -9, -28},
    {24, 45, 58, 22, 37, 47, 37, 38},
    {23, 47, 58, 17, 38, 48, 39, 39},
    {29, 46, 50, 14, 37, 49, 36, 41},
    {15, 34, 56, 6, 27, 35, 28, 28},
    {19, 32, 48, 11, 30, 35, 25, 30},
    {-10, -7, 3, -21, -26, -9, -5, -21},
    {30, 40, 31, 37, 35, 44, 31, 39},
    {21, 37, 45, 5, 31, 40, 34, 37},
    {20, 26, 12, 20, 12, 28, 23, 22},
    {-31, -32, -15, -20, -50, -31, -18, -43},
    {-29, -38, -22, -19, -57, -37, -21, -44},
    {-19, -10, 2, -4, -30, -6, 0, -20},
    {-15, -5, -5, -8, -44, -8, -6, -32},
    {32, 48, 44, 25, 44, 56, 44, 48},
    {37, 50, 35, 27, 31, 51, 40, 35},
    {-10, -8, 2, 4, -22, 4, 0, -17},
    {-22, -23, -18, -13, -28, -26, -20, -29},
    {-22, -17, -10, -17, -44, -19, -12, -32},
    {38, 52, 45, 36, 50, 61, 45, 51},
    {35, 52, 43, 31, 49, 53, 36, 44},
    {37, 51, 45, 34, 34, 58, 43, 46},
    {-34, -36, -24, -26, -40, -41, -22, -43},
    {25, 42, 47, 17, 32, 46, 34, 39},
    {16, 33, 37, 12, 17, 35, 26, 19},
    {21, 43, 31, 10, 29, 39, 22, 30},
    {22, 34, 16, 19, 19, 32, 21, 20},
    {33, 41, 24, 30, 28, 45, 36, 26},
    {-41, -39, -31, -32, -64, -39, -30, -57},
    {-36, -35, -28, -20, -71, -29, -23, -52},
    {38, 52, 47, 34, 59, 56, 41, 52},
    {-9, -7, -5, -3, -37, -3, -3, -21},
    {-35, -32, -23, -28, -68, -35, -24, -55},
    {24, 36, 36, 22, 38, 37, 30, 34},
    {36, 43, 45, 32, 65, 51, 38, 57},
    {40, 46, 42, 31, 43, 52, 40, 47},
    {24, 38, 45, 20, 49, 46, 33, 40},
    {-8, -2, 1, -21, -17, -3, -5, -13},
    {40, 54, 44, 38, 47, 62, 44, 48},
    {10, 19, 21, 7, 36, 20, 12, 24},
    {-47, -32, -34, -31, -65, -43, -31, -73},
    {-35, -31, -33, -31, -55, -37, -34, -60},
    {-28, -25, -31, -18, -51, -33, -28, -48},
    {29, 44, 38, 28, 34, 51, 36, 42},
    {-3, 6, 16, 0, -4, 1, 7, -6},
    {30, 43, 48, 29, 54, 52, 45, 52},
    {-24, -29, -33, -20, -41, -29, -19, -40},
    {-23, -14, -5, -18, -37, -22, -13, -38},
    {-23, -5, -3, -12, -34, -11, -10, -33},
    {35, 47, 42, 29, 53, 49, 40, 52},
    {40, 50, 52, 31, 54, 58, 37, 51},
    {10, 11, 7, 22, -8, 20, 11, 4},
    {0, -3, -17, 3, -21, 2, -5, -16},
    {-21, -10, -7, -15, -40, -16, -12, -33},
    {8, 14, 32, 5, 10, 17, 11, 7},
    {-4, -2, -9, 1, -18, 1, 0, -9},
    {12, 23, 28, 12, 32, 20, 15, 26},
    {-26, -30, -30, -19, -58, -30, -22, -42},
    {26, 37, 35, 25, 45, 41, 26, 42},
    {-25, -21, -20, -15, -49, -26, -13, -42},
    {41, 50, 55, 36, 54, 57, 45, 61},
    {-42, -35, -34, -35, -60, -44, -34, -59},
    {-23, -18, -10, -26, -55, -19, -16, -38},
    {42, 53, 55, 36, 65, 59, 42, 60},
    {43, 43, 44, 40, 65, 54, 44, 62},
    {-28, -29, -38, -21, -46, -31, -24, -41},
    {-42, -41, -31, -25, -57, -39, -22, -46},
    {14, 29, 27, 6, 20, 28, 24, 21},
    {-42, -39, -27, -35, -53, -42, -31, -71},
    {-38, -32, -20, -29, -49, -36, -24, -65},
    {-30, -16, -15, -24, -36, -20, -14, -44},
    {-29, -34, -40, -27, -53, -38, -30, -48},
    {-30, -30, -22, -22, -43, -33, -23, -47},
    {-7, -7, 5, 4, -20, -5, 2, -17},
    {-35, -24, -18, -32, -49, -30, -23, -43},
    {-6, -2, 13, 0, 1, 4, 4, -1},
    {8, 23, 28, -8, 7, 22, 13, 10},
    {24, 18, 18, 36, 13, 28, 23, 21},
    {18, 16, 19, 35, 11, 25, 20, 21},
    {-3, 8, 4, -25, -13, 0, -2, -11},
    {19, 12, 14, 37, 9, 21, 22, 16},
    {-24, -7, 2, -36, -22, -9, -11, -23},
    {-15, 6, 16, -39, -16, -2, -4, -13},
    {16, 29, 37, 1, 24, 37, 21, 24},
    {17, 30, 41, 3, 26, 30, 19, 29},
    {15, 8, 2, 27, 23, 15, 11, 21},
    {45, 47, 33, 49, 44, 57, 42, 50},
    {23, 33, 30, 35, 14, 42, 33, 21},
    {-34, -35, -15, -25, -39, -38, -24, -36},
    {8, 20, 27, 14, 10, 29, 17, 12},
    {15, 31, 19, 20, 18, 35, 22, 18},
    {21, 38, 39, 22, 25, 45, 34, 23},
    {14, 24, 30, 24, 19, 44, 27, 22},
    {28, 29, 16, 42, 21, 31, 31, 22},
    {-17, -10, 0, -33, -12, -14, -12, -13},
    {-14, -7, 16, -33, 4, -6, -2, 1},
    {31, 26, 14, 45, 14, 31, 30, 22},
    {30, 27, 9, 46, 13, 29, 21, 16},
    {27, 20, 6, 44, 12, 23, 18, 18},
    {25, 29, 13, 44, 23, 31, 24, 26},
    {9, 12, 4, 29, 10, 16, 13, 11},
    {13, 18, 10, 31, 11, 18, 25, 13},
    {29, 32, 23, 46, 32, 35, 31, 35},
    {-12, -2, 4, -22, -9, -5, -12, -7},
    {2, 6, 12, -24, -3, -5, -4, -1},
    {7, 13, 5, 31, 8, 20, 15, 10},
    {7, 8, 8, 20, 2, 15, 9, 9},
    {15, 29, 27, -1, 14, 23, 15, 16},
    {23, 27, 17, 36, 8, 28, 26, 19},
    {19, 29, 32, 10, 34, 30, 22, 31},
    {25, 33, 24, 44, 27, 41, 34, 35},
    {-2, -4, -5, -7, -12, -1, 0, -6},
    {32, 46, 36, 39, 33, 48, 37, 39},
    {41, 42, 36, 48, 37, 46, 41, 48},
    {50, 43, 28, 37, 34, 44, 37, 43},
    {-19, -2, 5, -29, -17, -5, -8, -21},
    {30, 38, 32, 26, 28, 41, 35, 31},
    {46, 51, 40, 54, 48, 57, 47, 58},
    {11, 21, 18, 4, 10, 17, 14, 12},
    {24, 39, 31, 22, 23, 35, 25, 29},
    {3, 13, 9, 3, 0, 12, 6, 1},
    {25, 47, 26, 18, 20, 36, 27, 25},
    {21, 33, 19, 10, 8, 24, 20, 13},
    {16, 20, 13, 10, 12, 20, 13, 16},
    {13, 17, 11, 17, 8, 18, 16, 12},
    {13, 32, 35, 11, 20, 30, 20, 21},
    {13, 28, 41, 15, 24, 30, 23, 18},
    {-12, -18, -17, -11, -24, -10, -11, -13},
    {14, 28, 17, 20, 4, 32, 19, 12},
    {19, 15, -4, 26, 3, 23, 15, 13},
    {-15, -5, 12, -32, -13, -8, -7, -17},
    {-18, -9, 8, -35, -17, -10, -12, -21},
    {39, 41, 37, 31, 59, 44, 34, 56},
    {-23, -25, -21, -15, -49, -25, -17, -34},
    {-17, -6, -8, -7, -43, -5, -8, -34},
    {3, 12, 14, 3, 11, 15, 12, 12},
    {-13, -6, -4, -6, -34, -6, -4, -25},
    {25, 30, 24, 16, 20, 23, 20, 28},
    {32, 29, 14, 20, 15, 21, 17, 24},
    {11, 21, 9, 18, 8, 15, 15, 6},
    {21, 17, 11, 32, 11, 15, 12, 16},
    {21, 31, 21, 17, 17, 28, 27, 18},
    {11, 15, 12, 11, 7, 17, 22, 11},
    {13, 21, 20, 12, 15, 16, 15, 15},
    {21, 27, 21, 16, 21, 20, 12, 28},
    {19, 17, 15, 17, 13, 16, 14, 18},
    {20, 30, 17, 20, 18, 30, 21, 17}
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

    static int Asw[210] = {
             11,    9,   14,    9,   11,    7,    8,   11,    8,    3,
             12,    6,    8,    8,    9,    6,   10,    3,    6,    6,
              6,    7,    5,    4,    7,    7,    3,    6,   11,    7,
              9,    9,   12,    8,    9,    6,    3,   10,    9,    7,
              6,   10,    9,    7,    8,    4,    3,    7,    5,    7,
              8,    8,    4,    5,    2,    3,    6,    5,   12,   12,
              6,   11,    5,    5,   13,   13,   10,   12,    8,    7,
             12,    7,    8,    5,    5,    6,    4,    9,    5,    7,
              5,    8,    8,    9,   10,    5,    9,    7,    8,    4,
              7,    5,    6,   13,    3,    4,    5,   12,   10,   15,
              6,   12,   11,    5,    9,    6,   11,    4,   12,    4,
             10,    5,    7,   12,    3,    8,    7,    7,    2,    9,
              7,    7,    3,    7,    6,    3,   11,   13,    3,    3,
              4,    8,    6,    7,    3,    6,    5,    6,    8,    7,
              9,    5,    4,    7,    6,    6,   10,    8,   10,   10,
              8,    4,    9,    8,    8,    8,    3,   13,    7,    4,
              4,    5,    7,    3,    4,    6,    7,   12,    3,    3,
              5,    4,    5,    9,    8,    9,    8,    8,    6,    8,
             11,    4,    9,    0,    5,    6,    3,    1,   11,   10,
              6,    6,    6,    9,    8,    9,    4,    5,    7,    3,
              1,    1,    1,    1,    2,    0,    1,    1,    0,    1};

    static int Ntw[210] = {
              1,   -7,    3,   -1,    0,   -2,    1,   -3,   -2,   -2,
             -7,   -7,   -3,   -5,   -3,    0,   -2,   -5,   -7,   10,
             -6,    9,   10,    7,    6,    3,   -4,   -6,  -11,   15,
            -10,  -11,   -7,  -10,    7,   -1,   10,   -3,   -7,   14,
            -10,   14,   -3,   -5,   -7,    7,   -4,   15,   12,   -7,
             -4,   -1,   -4,   -3,   -1,   -3,    0,   -5,    0,   -3,
             11,   -5,   10,    8,    0,    1,   -3,    5,   -2,    8,
             -2,   -4,    0,   12,   12,    7,    8,   -6,   -6,    6,
              8,   10,   -9,   -6,   -4,   11,   -3,    0,   -2,   -2,
             -3,   14,   14,   -4,    6,   12,   -5,   -7,   -4,    4,
              6,   -3,    0,   16,   22,   13,   -1,    3,   -4,   10,
             11,    8,   -8,   -4,    0,    6,    9,    2,    2,    0,
             19,   -4,    9,   -8,   14,    9,   -8,   -7,    9,   11,
             -1,   16,   14,   11,    9,   12,    6,   12,    5,    1,
              0,   -1,    4,    0,    8,    6,    0,   -1,    0,   -6,
              0,   10,    1,   -1,   -1,   -1,   -3,    8,    4,   -2,
             -2,   -1,   -2,   -1,   -1,   -5,    6,    6,    0,    0,
              0,   -1,   -3,   -3,    5,   -4,   -7,   -5,    7,   -2,
             -9,    0,   -3,    0,   -3,    0,    0,    0,    1,    0,
              6,    0,    0,    8,    8,   -7,    8,    9,    1,    5,
             -1,    0,    0,    0,   -1,    0,    0,   -1,    0,   -1};


	for (i = 0; i < 200; i++)
	{
		if (row->Quiz[i] < 0 || row->Quiz[i] > 3)
        	exit;

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

	if (row->AsResult < 0 || row->AsResult >= 200)
		exit;

	if (row->NtResult < 0 || row->NtResult >= 200)
		exit;

    for (grp = 0; grp < 8; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 200; i++)
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
					Row.Quiz[200] = Row.Hyperlexia;
					break;

				case 9:
					Row.Dyspraxia = atoi(valstr);
					Row.Quiz[201] = Row.Dyspraxia;
					break;

				case 10:
					Row.Dyslexia = atoi(valstr);
					Row.Quiz[202] = Row.Dyslexia;
					break;

				case 11:
					Row.Dyscalculia = atoi(valstr);
					Row.Quiz[203] = Row.Dyscalculia;
					break;

				case 12:
					Row.OCD = atoi(valstr);
					Row.Quiz[204] = Row.OCD;
					break;

				case 13:
					Row.ODD = atoi(valstr);
					Row.Quiz[205] = Row.ODD;
					break;

				case 14:
					Row.Synaesthesia = atoi(valstr);
					Row.Quiz[206] = Row.Synaesthesia;
					break;

				case 15:
					Row.PA = atoi(valstr);
					Row.Quiz[207] = Row.PA;
					break;

				case 16:
					Row.Dysgraphia = atoi(valstr);
					Row.Quiz[208] = Row.Dysgraphia;
					break;

				case 17:
					Row.Bipolar = atoi(valstr);
					Row.Quiz[209] = Row.Bipolar;
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
	int i;
	int grp;
	int max;
	long double w;

	for (i = 0; i < 200; i++)
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

