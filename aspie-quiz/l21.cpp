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
# l21.cpp
# Analyze L21
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"
#include "quizl21.h"

#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1

#define FALSE 0
#define TRUE !FALSE

TQuizL21 *Quiz[50];

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    char str[80];
    int g;
        
    printf("read data\r\n");
    Quiz[0] = new TQuizL21("bin\\quizl21.bin");

    printf("write no answer\r\n");
    Quiz[0]->WriteNoAnswerStats("res\\noans.txt");

    printf("factors\r\n");
    Quiz[0]->WriteFactors("res\\factors.csv");

    printf("import\r\n");
    Quiz[0]->ImportMvsp("pca-done\\allL21.txt", PCA_TYPE_ALL);
    Quiz[0]->ImportMvsp("pca-done\\maleL21.txt", PCA_TYPE_MALE);
    Quiz[0]->ImportMvsp("pca-done\\femL21.txt", PCA_TYPE_FEMALE);
    Quiz[0]->ImportMvspAspie("pca-done\\grpL21.txt");

    printf("details\r\n");

    Quiz[0]->WriteSumaryTable("res\\quizl21.htm", FALSE);

    printf("rel\r\n");

    Quiz[0]->WriteIntercorr("res\\rell21.htm");

    printf("calc global\r\n");
    Quiz[0]->CalcGlobal();

    printf("group weights\r\n");
    Quiz[0]->WritePhpGroupWeighting("res\\grp.php");

    printf("group\r\n");
    Quiz[0]->WriteGroupTable("res\\group.htm", TRUE);
    printf("groupcorr\r\n");
    Quiz[0]->WriteGroupCorrTable("res\\groupl21.htm");

}


