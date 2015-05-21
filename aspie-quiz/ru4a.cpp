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
# ru4a.cpp
# Analyze RU4a
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"
#include "quizl1.h"

#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1

#define FALSE 0
#define TRUE !FALSE

TQuizL1 *Quiz[50];

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
    TPopPca cfa10_1500;
    TPopPca cfa10_9000;
    TPopPca cfa10_female;
    TPopPca cfa10_young;
    TPopPca cfa10_old;
    TPopPca cfa12_600;
    TPopPca cfa12_1500;
    TPopPca cfa12_3000;
    TPopPca cfa12_6000;
    TPopPca cfa12_18000;
    TPopPca cfa12_repl;
    TFile CongFile("res\\congr.txt", 0);
        
    printf("read data\r\n");
    Quiz[0] = new TQuizL1("bin\\quizru4a.bin");

    TQuiz::ImportPopCfa("pca\\cfa10-1500.txt", &cfa10_1500);
    TQuiz::ImportPopCfa("pca\\cfa10-9000.txt", &cfa10_9000);
    TQuiz::ImportPopCfa("pca\\cfa10-female.txt", &cfa10_female);
    TQuiz::ImportPopCfa("pca\\cfa10-young.txt", &cfa10_young);
    TQuiz::ImportPopCfa("pca\\cfa10-old.txt", &cfa10_old);
    TQuiz::ExportPopCfaCongruence("10-factor: 1500-9000", CongFile, &cfa10_1500, &cfa10_9000, 117);
    TQuiz::ExportPopCfaCongruence("10-factor: 1500-female", CongFile, &cfa10_1500, &cfa10_female, 117);
    TQuiz::ExportPopCfaCongruence("10-factor: 1500-young", CongFile, &cfa10_1500, &cfa10_young, 117);
    TQuiz::ExportPopCfaCongruence("10-factor: 1500-old", CongFile, &cfa10_1500, &cfa10_old, 117);
    TQuiz::ExportPopCfaCongruence("10-factor: young-old", CongFile, &cfa10_young, &cfa10_old, 117);

    TQuiz::ImportPopCfa("pca\\cfa12-600.txt", &cfa12_600);
    TQuiz::ImportPopCfa("pca\\cfa12-1500.txt", &cfa12_1500);
    TQuiz::ImportPopCfa("pca\\cfa12-3000.txt", &cfa12_3000);
    TQuiz::ImportPopCfa("pca\\cfa12-6000.txt", &cfa12_6000);
    TQuiz::ImportPopCfa("pca\\cfa12-18000.txt", &cfa12_18000);
    TQuiz::ImportPopCfa("pca\\cfa12-repl.txt", &cfa12_repl);
    TQuiz::ExportPopCfaCongruence("12-factor: 1500-600", CongFile, &cfa12_1500, &cfa12_600, 121);
    TQuiz::ExportPopCfaCongruence("12-factor: 1500-3000", CongFile, &cfa12_1500, &cfa12_3000, 121);
    TQuiz::ExportPopCfaCongruence("12-factor: 1500-6000", CongFile, &cfa12_1500, &cfa12_6000, 121);
    TQuiz::ExportPopCfaCongruence("12-factor: 1500-18000", CongFile, &cfa12_1500, &cfa12_18000, 121);
    TQuiz::ExportPopCfaCongruence("12-factor: 1500-repl", CongFile, &cfa12_1500, &cfa12_repl, 121);

    printf("write no answer\r\n");
    Quiz[0]->WriteNoAnswerStats("res\\noans.txt");

    printf("factors\r\n");
    Quiz[0]->WriteFactors("res\\factors.csv");

    printf("import\r\n");
    Quiz[0]->ImportMvsp("pca-done\\allL1.txt", PCA_TYPE_ALL);
    Quiz[0]->ImportMvsp("pca-done\\maleL1.txt", PCA_TYPE_MALE);
    Quiz[0]->ImportMvsp("pca-done\\femL1.txt", PCA_TYPE_FEMALE);
    Quiz[0]->ImportMvspAspie("pca-done\\grpL1.txt");

    printf("details\r\n");

    Quiz[0]->WriteSumaryTable("res\\quizru4a.htm", FALSE);

    printf("rel\r\n");

    Quiz[0]->WriteIntercorr("res\\relru4a.htm");

    printf("calc global\r\n");
    Quiz[0]->CalcGlobal();

    printf("group weights\r\n");
    Quiz[0]->WritePhpGroupWeighting("res\\grp.php");

    printf("group\r\n");
    Quiz[0]->WriteGroupTable("res\\group.htm", TRUE);
    printf("groupcorr\r\n");
    Quiz[0]->WriteGroupCorrTable("res\\groupru4a.htm");

}


