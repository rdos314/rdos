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
# final.cpp
# Analyze final aspie-quiz (release 1)
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

// #define EXPORT	1
// #define ALL		1
// #define CONV		1

#include "file.h"
#include "quizfin.h"


#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1


#define FALSE 0
#define TRUE !FALSE

TQuiz *Quiz[50];

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
	char str[80];
	int g;

	Quiz[0] = new TQuizFinal("final.bin");

	Quiz[0]->WriteNoAnswerStats("final\\noans.txt");

#ifdef EXPORT
	printf("all\r\n");
	Quiz[0]->ExportExcelCase("pca\\allfin.dat", PCA_TYPE_ALL);
	Quiz[0]->ExportExcelCase("pca\\malefin.dat", PCA_TYPE_MALE);
	Quiz[0]->ExportExcelCase("pca\\femfin.dat", PCA_TYPE_FEMALE);
	Quiz[0]->ExportExcelCase("pca\\youngfin.dat", PCA_TYPE_YOUNG);
	Quiz[0]->ExportExcelCase("pca\\oldfin.dat", PCA_TYPE_OLD);

	printf("aspie\r\n");

	 Quiz[0]->ExportExcelAspie("pca\\aspiefin.dat");
#endif

	printf("import\r\n");
	 Quiz[0]->ImportMvsp("pca\\allfin.txt", PCA_TYPE_ALL);
	 Quiz[0]->ImportMvsp("pca\\malefin.txt", PCA_TYPE_MALE);
	 Quiz[0]->ImportMvsp("pca\\femfin.txt", PCA_TYPE_FEMALE);
	 Quiz[0]->ImportMvsp("pca\\oldfin.txt", PCA_TYPE_OLD);
	 Quiz[0]->ImportMvsp("pca\\youngfin.txt", PCA_TYPE_YOUNG);


	printf("import aspie\r\n");

	 Quiz[0]->ImportMvspAspie("pca\\aspiefin.txt");

	printf("congruence\r\n");

	 Quiz[0]->ExportGenderCongruence("final\\gender.txt");
	 Quiz[0]->ExportAgeCongruence("final\\age.txt");

	printf("referers\r\n");

	 Quiz[0]->WriteReferers("eval\\reffin.htm");

	printf("details\r\n");

	 Quiz[0]->WriteSumaryTable("eval\\quizfin.htm", FALSE);

	printf("rel\r\n");

	 Quiz[0]->WriteIntercorr("eval\\relfin.htm");

	 printf("race\r\n");

	 Quiz[0]->WriteRace("final\\race.htm");

	printf("type histograms\r\n");
	 Quiz[0]->ExportDiffHistogram("final\\all.csv", POP_TYPE_ALL, TRUE);
	 Quiz[0]->ExportDiffHistogram("final\\as.csv", POP_TYPE_AS, TRUE);
	 Quiz[0]->ExportDiffHistogram("final\\nt.csv", POP_TYPE_NT_CONTROL, TRUE);
	 Quiz[0]->ExportDiffHistogram("final\\soc.csv", POP_TYPE_SOCIAL_PHOBIA, TRUE);
	 Quiz[0]->ExportDiffHistogram("final\\add.csv", POP_TYPE_ADD, TRUE);
	 Quiz[0]->ExportDiffHistogram("final\\ocd.csv", POP_TYPE_OCD, TRUE);

	 TQuiz::ExportBirthMonthHistogram("final\\birth.csv");

}


