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
# h10.cpp
# Analyze H10
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"
#include "quizh10.h"

#include "h10-1.h"
#include "h10-2.h"
#include "h10-3.h"
#include "h10-4.h"

#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1

#define FALSE 0
#define TRUE !FALSE

TQuizH10 *Quiz[50];

/*##################  WriteUnion ##########################
*   Purpose....: Write union                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteUnion()
{
    int i;
    int j;
    int k;
    int count;
    int arr1[85];
    int arr2[85];
    char str[16];
    TFile outfile("res\\unh10.txt", 0);

    for (i = 0; i < 28; i++)
    {
        for (j = 0; j < 85; j++)
        {
            arr1[j] = FALSE;
            arr2[j] = FALSE;
        }

        for (j = 0; j < 16; j++)
        {
            k = Freq3[i][j];
            arr1[k] = TRUE;

            k = Freq4[i][j];
            arr2[k] = TRUE;
        }

        count = 0;
        for (j = 0; j < 85; j++)
            if (arr1[j] && arr2[j])
                count++;

        sprintf(str, "%d\r\n", count);
        outfile.Write(str);        
    }    
}

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

        WriteUnion();
        
        printf("read data\r\n");
        Quiz[0] = new TQuizH10("bin\\quizh10.bin");

        printf("write no answer\r\n");
        Quiz[0]->WriteNoAnswerStats("res\\noans.txt");

        printf("eye results\r\n");
        Quiz[0]->WriteEyeResults("res\\eye.csv");

        printf("import\r\n");
        Quiz[0]->ImportMvsp("pca-done\\allH10.txt", PCA_TYPE_ALL);
        Quiz[0]->ImportMvsp("pca-done\\maleH10.txt", PCA_TYPE_MALE);
        Quiz[0]->ImportMvsp("pca-done\\femH10.txt", PCA_TYPE_FEMALE);

        printf("details\r\n");

         Quiz[0]->WriteSumaryTable("res\\quizh10.htm", FALSE);

        printf("rel\r\n");

         Quiz[0]->WriteIntercorr("res\\relh10.htm");

     printf("calc global\r\n");
        Quiz[0]->CalcGlobal();

                  printf("group\r\n");
                        Quiz[0]->WriteGroupTable("res\\group.htm", TRUE);
                  printf("groupcorr\r\n");
                        Quiz[0]->WriteGroupCorrTable("res\\groupcorr.htm");

                  printf("main\r\n");
                        Quiz[0]->WriteLinkReport("res\\index.htm");
}


