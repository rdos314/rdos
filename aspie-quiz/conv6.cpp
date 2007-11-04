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
# conv6.cpp
# Convert exported quiz-6 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"
#include "quizdb6.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000
#define MAX_REFERERS    1024

const char InsertString[] = "INSERT INTO aspie-quiz-6 VALUES(";

TFile quizfile("quiz6.bin", 0);

static int Gw[152][17] = 
{
    {3, 0, 2, 0, 0, 0, 0, 0, 5, 1, 11, 0, 2, 1, 1, 3, 1},
    {0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 5, 0, 0, 0, 0},
    {2, 0, 1, 0, 0, 0, 3, 0, 4, 0, 3, 0, 2, 1, 1, 2, 1},
    {2, 0, 2, 0, 0, 0, 0, 0, 6, 0, 14, 0, 6, 0, 0, 5, 2},
    {0, 1, 3, 0, 0, 0, 0, 0, 5, 3, 13, 0, 6, 0, 3, 5, 2},
    {0, 0, 0, 0, 0, 0, 8, 0, 3, 0, 1, 0, 5, 0, 0, 2, 0},
    {1, 1, 4, 0, 0, 0, 1, 0, 4, 1, 9, 0, 2, 0, 1, 2, 1},
    {0, 1, 0, 0, 0, 0, 5, 0, 1, 3, 0, 0, 1, 1, 0, 1, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 5, 1, 11, 0, 4, 0, 0, 4, 1},
    {0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 7, 0, 3, 0, 0, 6, 2},
    {0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 1, 0, 0, 0, 0, 1, 2},
    {0, 0, 0, 0, 0, 0, 6, 0, 2, 0, 0, 0, 2, 0, 0, 2, 0},
    {0, 2, 0, 0, 0, 0, 1, 2, 0, 16, 2, 0, 3, 0, 2, 0, 1},
    {0, 4, 0, 0, 0, 0, 5, 0, 0, 15, 3, 0, 7, 0, 2, 1, 0},
    {0, 6, 1, 0, 0, 0, 3, 2, 0, 15, 1, 0, 4, 0, 3, 0, 0},
    {0, 2, 0, 0, 0, 0, 0, 0, 0, 14, 0, 0, 2, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 0, 0, 4, 0, 0, 0, 0},
    {0, 2, 0, 0, 0, 0, 3, 0, 0, 11, 2, 0, 7, 0, 0, 2, 0},
    {3, 7, 4, 4, 6, 6, 6, 11, 0, 8, 3, 0, 2, 0, 6, 0, 1},
    {5, 4, 4, 3, 0, 1, 5, 8, 3, 3, 3, 0, 1, 0, 2, 1, 1},
    {0, 0, 0, 9, 5, 11, 0, 12, 0, 3, 0, 0, 0, 0, 1, 0, 0},
    {0, 1, 0, 6, 2, 7, 0, 13, 0, 2, 0, 0, 0, 0, 1, 0, 0},
    {0, 5, 2, 1, 3, 3, 7, 7, 0, 6, 0, 0, 0, 0, 2, 0, 0},
    {6, 6, 3, 3, 4, 5, 7, 7, 2, 4, 3, 0, 2, 2, 7, 2, 2},
    {5, 5, 4, 6, 3, 5, 6, 13, 0, 6, 2, 0, 1, 1, 4, 0, 1},
    {0, 5, 1, 0, 0, 0, 0, 2, 1, 4, 7, 0, 1, 0, 1, 1, 0},
    {2, 3, 3, 0, 0, 1, 1, 7, 0, 4, 3, 0, 2, 0, 4, 1, 0},
    {0, 0, 0, 10, 5, 10, 0, 15, 0, 3, 0, 0, 0, 0, 1, 0, 0},
    {5, 3, 3, 1, 0, 0, 5, 4, 5, 3, 2, 0, 0, 0, 1, 1, 1},
    {0, 0, 0, 5, 0, 4, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 9, 3, 9, 0, 13, 0, 2, 0, 0, 0, 0, 0, 0, 0},
    {2, 1, 0, 0, 0, 0, 7, 3, 3, 6, 0, 0, 1, 1, 0, 0, 1},
    {5, 1, 2, 0, 0, 0, 3, 3, 4, 1, 2, 0, 2, 2, 3, 1, 1},
    {0, 9, 1, 0, 2, 2, 4, 4, 0, 4, 0, 0, 0, 0, 3, 0, 0},
    {4, 6, 3, 3, 0, 2, 7, 12, 2, 7, 1, 0, 0, 1, 3, 0, 1},
    {0, 0, 0, 11, 5, 10, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 3, 0, 6, 0, 0, 1, 0, 0, 0, 0},
    {4, 3, 2, 1, 0, 1, 7, 5, 5, 3, 2, 0, 1, 3, 1, 1, 1},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0},
    {0, 2, 3, 0, 0, 0, 8, 0, 3, 2, 1, 0, 0, 0, 2, 0, 2},
    {8, 2, 3, 2, 0, 0, 1, 1, 3, 0, 1, 0, 1, 0, 0, 1, 1},
    {11, 0, 0, 1, 0, 0, 1, 0, 7, 0, 1, 0, 0, 0, 0, 3, 2},
    {10, 0, 5, 1, 1, 1, 1, 1, 2, 0, 1, 0, 0, 0, 0, 1, 0},
    {4, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0},
    {5, 0, 6, 0, 0, 0, 0, 0, 3, 0, 1, 0, 0, 0, 0, 3, 2},
    {13, 0, 0, 0, 0, 0, 1, 0, 7, 0, 4, 0, 2, 0, 0, 6, 5},
    {11, 0, 3, 0, 0, 0, 1, 0, 7, 0, 4, 0, 0, 2, 0, 3, 2},
    {13, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 4, 2},
    {10, 0, 1, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 2, 0},
    {8, 3, 8, 3, 5, 2, 1, 1, 2, 0, 4, 0, 1, 0, 3, 1, 1},
    {12, 0, 1, 4, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0},
    {9, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 1, 0},
    {6, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 1, 3},
    {4, 6, 13, 0, 5, 2, 4, 4, 0, 4, 7, 0, 3, 0, 8, 2, 1},
    {4, 3, 8, 0, 2, 0, 1, 0, 0, 0, 4, 0, 1, 0, 4, 1, 1},
    {0, 9, 9, 0, 7, 3, 5, 3, 0, 7, 5, 0, 4, 0, 12, 0, 0},
    {3, 1, 8, 4, 3, 2, 2, 2, 0, 0, 1, 0, 0, 0, 1, 0, 0},
    {3, 3, 13, 0, 3, 1, 5, 2, 0, 3, 5, 0, 1, 0, 4, 1, 1},
    {4, 2, 12, 0, 1, 0, 3, 1, 1, 1, 4, 0, 0, 0, 4, 2, 0},
    {0, 0, 6, 0, 0, 0, 4, 0, 1, 5, 5, 0, 3, 0, 3, 0, 1},
    {4, 4, 9, 0, 5, 2, 4, 1, 1, 2, 6, 0, 0, 3, 6, 1, 0},
    {3, 3, 9, 0, 0, 0, 8, 1, 1, 3, 4, 0, 2, 0, 5, 2, 3},
    {4, 1, 10, 0, 0, 0, 4, 0, 4, 1, 5, 0, 2, 1, 3, 2, 2},
    {2, 0, 1, 0, 0, 0, 2, 0, 4, 0, 1, 0, 1, 2, 7, 2, 3},
    {0, 0, 0, 7, 6, 10, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 2, 3, 1, 0, 0, 0, 0, 2, 0, 1, 0, 0, 1, 1},
    {7, 0, 0, 2, 0, 0, 2, 0, 10, 0, 6, 0, 6, 0, 2, 0, 14},
    {2, 2, 3, 4, 9, 7, 2, 3, 0, 2, 1, 0, 2, 0, 3, 0, 4},
    {2, 0, 2, 6, 9, 12, 2, 5, 0, 2, 0, 0, 2, 0, 3, 0, 1},
    {4, 4, 3, 9, 13, 10, 3, 9, 0, 4, 1, 0, 3, 0, 7, 0, 0},
    {7, 0, 0, 3, 0, 0, 0, 0, 4, 0, 1, 0, 1, 0, 0, 1, 2},
    {0, 0, 0, 7, 2, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 8, 1, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {2, 1, 3, 4, 8, 5, 0, 0, 0, 1, 5, 0, 2, 0, 4, 0, 0},
    {6, 0, 0, 4, 4, 4, 0, 0, 1, 0, 2, 0, 2, 0, 4, 1, 3},
    {0, 0, 0, 3, 1, 5, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {2, 2, 5, 5, 7, 7, 2, 2, 0, 3, 5, 0, 2, 0, 2, 2, 1},
    {0, 0, 0, 13, 8, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, 4, 2, 4, 12, 8, 1, 4, 0, 2, 1, 0, 4, 0, 8, 0, 0},
    {0, 0, 0, 8, 6, 6, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0},
    {4, 2, 3, 10, 12, 9, 0, 5, 0, 0, 2, 0, 1, 0, 3, 0, 1},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 4, 1, 1},
    {7, 0, 3, 7, 10, 6, 0, 1, 0, 0, 2, 0, 2, 0, 3, 1, 0},
    {0, 0, 0, 6, 5, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {2, 0, 0, 7, 9, 7, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 1},
    {2, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 1, 0, 0, 2, 12},
    {6, 1, 2, 5, 4, 4, 3, 4, 2, 0, 0, 0, 0, 1, 0, 0, 2},
    {0, 0, 1, 1, 7, 6, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0},
    {0, 0, 0, 24, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 23, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 18, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 15, 3, 6, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 14, 3, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 7, 7, 10, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 5, 0, 0, 0, 0, 1, 0, 2, 6, 0, 0, 1, 0, 0, 0, 1},
    {0, 11, 1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0},
    {0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 7, 0, 0, 0, 0, 1, 0, 0, 4, 0, 0, 1, 0, 0, 0, 0},
    {0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0},
    {0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 10, 5, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {5, 0, 2, 7, 15, 12, 3, 4, 1, 0, 1, 0, 0, 0, 3, 0, 4},
    {0, 0, 0, 3, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0},
    {0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0},
    {0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 4, 0, 8, 2, 0, 0, 0, 0, 3, 0, 0, 0, 2, 0, 0},
    {0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14},
    {0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 21},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0},
    {0, 10, 2, 0, 0, 0, 2, 3, 0, 5, 3, 0, 1, 0, 4, 0, 0},
    {0, 8, 1, 0, 0, 0, 2, 0, 0, 4, 2, 0, 3, 0, 6, 0, 1},
    {0, 6, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 1, 0, 1, 1, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0},
    {0, 1, 0, 7, 2, 8, 0, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0},
    {0, 8, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 3, 0, 0},
    {0, 3, 1, 0, 0, 0, 0, 2, 0, 1, 2, 0, 4, 0, 9, 0, 1},
    {0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 2, 0, 0, 1, 2},
    {0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0},
    {0, 1, 0, 0, 0, 0, 5, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0},
    {0, 0, 0, 15, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 7, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2},
    {0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 10, 7, 12, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 1},
    {0, 1, 2, 0, 0, 0, 0, 0, 1, 5, 7, 0, 0, 1, 2, 1, 0},
    {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0}
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
    int i;
    int grp;

    
	if (Row->Ancestry >= 2100 && Row->Ancestry < 2200)
	{
		for (i = 150; i < 162; i++)
			Row->Quiz[i] = 1;

		switch (Row->Hair)
		{
			case 1:
				Row->Quiz[150] = 3;
				break;

			case 2:
				Row->Quiz[151] = 3;
				break;

			case 3:
				Row->Quiz[152] = 3;
				break;

			case 4:
				Row->Quiz[153] = 3;
				break;

			case 5:
				Row->Quiz[154] = 3;
				break;

			case 6:
				Row->Quiz[155] = 3;
				break;

			case 7:
				Row->Quiz[156] = 3;
				break;
		}

		switch (Row->Eye)
		{
			case 1:
				Row->Quiz[157] = 3;
				break;

			case 2:
				Row->Quiz[158] = 3;
				break;

			case 3:
				Row->Quiz[159] = 3;
				break;

			case 4:
				Row->Quiz[160] = 3;
				break;

			case 5:
				Row->Quiz[161] = 3;
				break;
		}
	}
	else
		for (i = 150; i < 162; i++)
			Row->Quiz[i] = 0;

	quizfile.Write(Row, sizeof(TQuizRow));

	printf("%d AS: %d, NT: %d, [", Row->ID, Row->AsResult, Row->NtResult);

	for (grp = 0; grp < 12; grp++)
	{
	    printf("%d", Row->GroupResult[grp]);
	    if (grp != 11)
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

    static int Asw[162] = {
             12,    7,   14,    9,   10,    6,   11,    6,    8,    3,
              8,    3,    6,    7,    6,    8,    3,    5,   10,    9,
              7,    9,    7,   12,    8,    8,    8,    8,    8,    7,
              7,    5,    9,    9,    6,    6,    8,    8,    9,   11,
             12,   12,   11,    7,    9,   13,   13,   12,    9,   10,
             13,   14,   14,    9,   12,   10,    9,    7,    9,    5,
             10,    8,    8,    9,    5,    7,   11,   11,   10,   13,
             13,    5,    5,   13,   14,    7,    8,    6,   15,    4,
             12,   11,   15,    7,   11,   10,   12,   11,    5,    7,
              7,    6,    6,    5,    9,    9,    5,    4,    7,    8,
              7,    3,   10,    5,    4,    8,    6,    3,    5,   11,
              3,   11,    6,   11,    9,   10,    5,    4,    9,    3,
              5,    2,    5,    6,    4,   10,   10,   10,   10,    9,
             13,   11,    7,    8,    4,    7,    3,    4,    6,    5,
              7,    6,    9,   12,   12,    5,    4,    2,    5,    4,
              0,    0,    1,    1,    0,    1,    0,    1,    1,    1,
              0,    1};

    static int Ntw[162] = {
             -4,   -2,    2,   -2,   -2,   -2,   -3,   -5,   -3,   -2,
             -5,   -3,   -5,   -5,   -6,   -5,   -4,   -4,  -11,   -9,
             19,   18,   -9,   -7,   -9,   -7,   -7,   18,   -7,   16,
             19,   -6,   -4,   -7,   -9,   15,   -6,   -8,   -5,   -2,
             -5,    0,   -4,   -4,   -3,    0,    0,    3,   -2,   -7,
              4,    7,    7,   -7,   -3,   -8,   -9,   -9,   -6,   -5,
             -6,   -4,   -7,   -1,   17,   -6,   -5,   -5,   -6,   -7,
             -3,   14,   22,   -4,   -2,   16,   -7,   15,    0,   13,
             -5,   -3,    2,   17,   -1,   -4,   -4,   -4,   13,   16,
             19,   17,   11,   14,   17,   18,   13,   14,   -6,   -3,
             -5,   -2,    0,   -2,   -1,   -2,   -1,   -1,   -1,    2,
             11,   -3,   12,    9,    4,    0,   10,    3,   -4,    3,
             10,   -2,    0,   -1,    1,   -8,   -6,   -5,   -2,   21,
             -1,   -1,   12,   -2,    8,   13,   -4,   12,   14,   -4,
             14,   18,    2,   12,    0,    0,   -3,   -1,    0,   -1,
              0,    0,    2,    2,    0,    1,    0,    1,    2,    1,
              0,    1};

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

    for (grp = 0; grp < 12; grp++)
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

	for (fieldno = 0; fieldno < 165; fieldno++)
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

				case 5:
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

				case 6:
					Row.Lang = atoi(valstr);
					break;

				case 7:
					Row.Ancestry = atoi(valstr);
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
					Row.Schizophrenia = atoi(valstr);
					break;

				case 12:
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

				case 13:
					Row.AsResult = atoi(valstr);
					break;

				case 14:
					Row.NtResult = atoi(valstr);
					break;

				default:
					i = fieldno - 15;
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
	TFile infile("quiz6.sql");
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

