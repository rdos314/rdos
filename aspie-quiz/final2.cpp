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
# final2.cpp
# Analyze final aspie-quiz (release 2)
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#define EXPORT	1
// #define ALL		1
// #define CONV		1

#include "file.h"
#include "quizfin2.h"


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

	printf("read data\r\n");
	Quiz[0] = new TQuizFinal2("final2.bin");

	printf("write no answer\r\n");
	Quiz[0]->WriteNoAnswerStats("final2\\noans.txt");

	printf("all\r\n");
	Quiz[0]->ExportExcelCase("pca\\allfin2.dat", PCA_TYPE_ALL);
	Quiz[0]->ExportExcelCase("pca\\malefin2.dat", PCA_TYPE_MALE);
	Quiz[0]->ExportExcelCase("pca\\femfin2.dat", PCA_TYPE_FEMALE);
	Quiz[0]->ExportExcelCase("pca\\yfin2.dat", PCA_TYPE_YOUNG);
	Quiz[0]->ExportExcelCase("pca\\oldfin2.dat", PCA_TYPE_OLD);

	printf("aspie\r\n");

	 Quiz[0]->ExportExcelAspie("pca\\aspfin2.dat");

	printf("aspie-nt items\r\n");

	 Quiz[0]->ExportExcelAspieItems("pca\\as2.dat");
	 Quiz[0]->ExportExcelNtItems("pca\\nt2.dat");

	printf("import\r\n");
	 Quiz[0]->ImportMvsp("pca\\allfin2.txt", PCA_TYPE_ALL);
	 Quiz[0]->ImportMvsp("pca\\malefin2.txt", PCA_TYPE_MALE);
	 Quiz[0]->ImportMvsp("pca\\femfin2.txt", PCA_TYPE_FEMALE);
	 Quiz[0]->ImportMvsp("pca\\oldfin2.txt", PCA_TYPE_OLD);
	 Quiz[0]->ImportMvsp("pca\\yfin2.txt", PCA_TYPE_YOUNG);

	printf("import aspie\r\n");

	 Quiz[0]->ImportMvspAspie("pca\\aspfin2.txt");

	printf("congruence\r\n");

	 Quiz[0]->ExportGenderCongruence("final2\\gender.txt");
	 Quiz[0]->ExportAgeCongruence("final2\\age.txt");

	printf("referers\r\n");

	 Quiz[0]->WriteReferers("eval\\reffin2.htm");

	printf("details\r\n");

	 Quiz[0]->WriteSumaryTable("eval\\quizfin2.htm", FALSE);

	printf("rel\r\n");

	 Quiz[0]->WriteIntercorr("eval\\relfin2.htm");

	 printf("race\r\n");

	 Quiz[0]->WriteRace("final2\\race.htm");

	printf("type histograms\r\n");
	 Quiz[0]->ExportDiffHistogram("final2\\all.csv", POP_TYPE_ALL, TRUE);
	 Quiz[0]->ExportDiffHistogram("final2\\as.csv", POP_TYPE_AS, TRUE);
	 Quiz[0]->ExportDiffHistogram("final2\\soc.csv", POP_TYPE_SOCIAL_PHOBIA, TRUE);
	 Quiz[0]->ExportDiffHistogram("final2\\add.csv", POP_TYPE_ADD, TRUE);
	 Quiz[0]->ExportDiffHistogram("final2\\ocd.csv", POP_TYPE_OCD, TRUE);

	 TQuiz::ExportBirthYearHistogram("final2\\birth.csv");

}


