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
# ana.cpp
# Analyze aspie-quiz
#
########################################################################*/
#include <stdio.h>                          
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"

#include "quiz1.h"
#include "quiz2.h"
#include "quiz3.h"
#include "quiznd.h"
#include "quiz5.h"
#include "quiz6.h"
#include "quiz7.h"
#include "quiz8.h"
#include "quiz9.h"
#include "quizr1.h"
#include "quizr2.h"
#include "quizr3.h"
#include "quizr4.h"
#include "quizr5.h"
#include "quizr6.h"
#include "quizr7.h"
#include "quizs1.h"
#include "quizs2.h"
#include "quizs3.h"
#include "quizs4.h"
#include "quizs5.h"
#include "quizs6.h"
#include "quizs7.h"
#include "quizs8.h"
#include "quizs9.h"
#include "quizs10.h"
#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1

#define FALSE 0
#define TRUE !FALSE

TQuiz *Quiz[30];

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
	Quiz[0] = new TQuizI("quiz1.bin");
	Quiz[1] = new TQuizII("quiz2.bin", Quiz[0]);
	Quiz[2] = new TQuizIII("quiz3.bin", Quiz[0], Quiz[1]);
	Quiz[3] = new TQuizNd("quiznd.bin", Quiz[0], Quiz[1], Quiz[2]);
	Quiz[4] = new TQuiz5("quiz5.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3]);
	Quiz[5] = new TQuiz6("quiz6.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4]);
	Quiz[6] = new TQuiz7("quiz7.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5]);
	Quiz[7] = new TQuiz8("quiz8.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6]);
	Quiz[8] = new TQuiz9("quiz9.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7]);
	Quiz[9] = new TQuizR1("quizr1.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8]);
	Quiz[10] = new TQuizR2("quizr2.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9]);
	Quiz[11] = new TQuizR3("quizr3.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10]);
	Quiz[12] = new TQuizR4("quizr4.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11]);
	Quiz[13] = new TQuizR5("quizr5.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12]);
	Quiz[14] = new TQuizR6("quizr6.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13]);
	Quiz[15] = new TQuizR7("quizr7.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14]);
	Quiz[16] = new TQuizS1("quizs1.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15]);
	Quiz[17] = new TQuizS2("quizs2.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16]);
	Quiz[18] = new TQuizS3("quizs3.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17]);
	Quiz[19] = new TQuizS4("quizs4.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18]);
	Quiz[20] = new TQuizS5("quizs5.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19]);
	Quiz[21] = new TQuizS6("quizs6.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20]);
	Quiz[22] = new TQuizS7("quizs7.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21]);
	Quiz[23] = new TQuizS8("quizs8.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22]);
	Quiz[24] = new TQuizS9("quizs9.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23]);
	Quiz[25] = new TQuizS10("quizs10.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24]);

//  Quiz[0]->CheckCross();
//	Quiz[1]->CheckCross();
//	Quiz[2]->CheckCross();
//	Quiz[3]->CheckCross();
//	Quiz[4]->CheckCross();
//	Quiz[5]->CheckCross();
//	Quiz[6]->CheckCross();
//	Quiz[7]->CheckCross();
//	Quiz[8]->CheckCross();
//	Quiz[9]->CheckCross();
//	 Quiz[10]->CheckCross();
//	 Quiz[11]->CheckCross();
//	 Quiz[12]->CheckCross();
//	 Quiz[13]->CheckCross();
//	 Quiz[14]->CheckCross();
//	 Quiz[15]->CheckCross();
//	 Quiz[16]->CheckCross();
//	 Quiz[17]->CheckCross();
//	 Quiz[18]->CheckCross();
//	 Quiz[19]->CheckCross();
//	 Quiz[20]->CheckCross();
//	 Quiz[21]->CheckCross();
//	 Quiz[22]->CheckCross();
//	 Quiz[23]->CheckCross();
//	 Quiz[24]->CheckCross();
	 Quiz[25]->CheckCross();

	Quiz[0]->ExportExcelCase("pca\\all1.dat", PCA_TYPE_ALL);
	Quiz[0]->ExportExcelCase("pca\\male1.dat", PCA_TYPE_MALE);
	Quiz[0]->ExportExcelCase("pca\\female1.dat", PCA_TYPE_FEMALE);

	Quiz[1]->ExportExcelCase("pca\\all2.dat", PCA_TYPE_ALL);
	Quiz[1]->ExportExcelCase("pca\\male2.dat", PCA_TYPE_MALE);
	Quiz[1]->ExportExcelCase("pca\\female2.dat", PCA_TYPE_FEMALE);

	 Quiz[2]->ExportExcelCase("pca\\all3.dat", PCA_TYPE_ALL);
	 Quiz[2]->ExportExcelCase("pca\\male3.dat", PCA_TYPE_MALE);
	 Quiz[2]->ExportExcelCase("pca\\female3.dat", PCA_TYPE_FEMALE);

	 Quiz[3]->ExportExcelCase("pca\\all4.dat", PCA_TYPE_ALL);
	 Quiz[3]->ExportExcelCase("pca\\male4.dat", PCA_TYPE_MALE);
	 Quiz[3]->ExportExcelCase("pca\\female4.dat", PCA_TYPE_FEMALE);

	 Quiz[4]->ExportExcelCase("pca\\all5.dat", PCA_TYPE_ALL);
	 Quiz[4]->ExportExcelCase("pca\\male5.dat", PCA_TYPE_MALE);
	 Quiz[4]->ExportExcelCase("pca\\female5.dat", PCA_TYPE_FEMALE);

	 Quiz[5]->ExportExcelCase("pca\\all6.dat", PCA_TYPE_ALL);
	 Quiz[5]->ExportExcelCase("pca\\male6.dat", PCA_TYPE_MALE);
	 Quiz[5]->ExportExcelCase("pca\\female6.dat", PCA_TYPE_FEMALE);

	 Quiz[6]->ExportExcelCase("pca\\all7.dat", PCA_TYPE_ALL);
	 Quiz[6]->ExportExcelCase("pca\\male7.dat", PCA_TYPE_MALE);
	 Quiz[6]->ExportExcelCase("pca\\female7.dat", PCA_TYPE_FEMALE);

	 Quiz[7]->ExportExcelCase("pca\\all8.dat", PCA_TYPE_ALL);
	 Quiz[7]->ExportExcelCase("pca\\male8.dat", PCA_TYPE_MALE);
	 Quiz[7]->ExportExcelCase("pca\\female8.dat", PCA_TYPE_FEMALE);

	 Quiz[8]->ExportExcelCase("pca\\all9.dat", PCA_TYPE_ALL);
	 Quiz[8]->ExportExcelCase("pca\\male9.dat", PCA_TYPE_MALE);
	 Quiz[8]->ExportExcelCase("pca\\female9.dat", PCA_TYPE_FEMALE);

	 Quiz[9]->ExportExcelCase("pca\\allr1.dat", PCA_TYPE_ALL);
	 Quiz[9]->ExportExcelCase("pca\\maler1.dat", PCA_TYPE_MALE);
	 Quiz[9]->ExportExcelCase("pca\\femaler1.dat", PCA_TYPE_FEMALE);

	 Quiz[10]->ExportExcelCase("pca\\allr2.dat", PCA_TYPE_ALL);
	 Quiz[10]->ExportExcelCase("pca\\maler2.dat", PCA_TYPE_MALE);
	 Quiz[10]->ExportExcelCase("pca\\femaler2.dat", PCA_TYPE_FEMALE);

	 Quiz[11]->ExportExcelCase("pca\\allr3.dat", PCA_TYPE_ALL);
	 Quiz[11]->ExportExcelCase("pca\\maler3.dat", PCA_TYPE_MALE);
	 Quiz[11]->ExportExcelCase("pca\\femaler3.dat", PCA_TYPE_FEMALE);

	 Quiz[12]->ExportExcelCase("pca\\allr4.dat", PCA_TYPE_ALL);
	 Quiz[12]->ExportExcelCase("pca\\maler4.dat", PCA_TYPE_MALE);
	 Quiz[12]->ExportExcelCase("pca\\femaler4.dat", PCA_TYPE_FEMALE);

	 Quiz[13]->ExportExcelCase("pca\\allr5.dat", PCA_TYPE_ALL);
	 Quiz[13]->ExportExcelCase("pca\\maler5.dat", PCA_TYPE_MALE);
	 Quiz[13]->ExportExcelCase("pca\\femaler5.dat", PCA_TYPE_FEMALE);

	 Quiz[14]->ExportExcelCase("pca\\allr6.dat", PCA_TYPE_ALL);
	 Quiz[14]->ExportExcelCase("pca\\maler6.dat", PCA_TYPE_MALE);
	 Quiz[14]->ExportExcelCase("pca\\femaler6.dat", PCA_TYPE_FEMALE);

	 Quiz[15]->ExportExcelCase("pca\\allr7.dat", PCA_TYPE_ALL);
	 Quiz[15]->ExportExcelCase("pca\\maler7.dat", PCA_TYPE_MALE);
	 Quiz[15]->ExportExcelCase("pca\\femaler7.dat", PCA_TYPE_FEMALE);

	 Quiz[16]->ExportExcelCase("pca\\alls1.dat", PCA_TYPE_ALL);
	 Quiz[16]->ExportExcelCase("pca\\males1.dat", PCA_TYPE_MALE);
	 Quiz[16]->ExportExcelCase("pca\\females1.dat", PCA_TYPE_FEMALE);

	 Quiz[17]->ExportExcelCase("pca\\alls2.dat", PCA_TYPE_ALL);
	 Quiz[17]->ExportExcelCase("pca\\males2.dat", PCA_TYPE_MALE);
	 Quiz[17]->ExportExcelCase("pca\\females2.dat", PCA_TYPE_FEMALE);

	 Quiz[18]->ExportExcelCase("pca\\alls3.dat", PCA_TYPE_ALL);
	 Quiz[18]->ExportExcelCase("pca\\males3.dat", PCA_TYPE_MALE);
	 Quiz[18]->ExportExcelCase("pca\\females3.dat", PCA_TYPE_FEMALE);

	 Quiz[19]->ExportExcelCase("pca\\alls4.dat", PCA_TYPE_ALL);
	 Quiz[19]->ExportExcelCase("pca\\males4.dat", PCA_TYPE_MALE);
	 Quiz[19]->ExportExcelCase("pca\\females4.dat", PCA_TYPE_FEMALE);

	 Quiz[20]->ExportExcelCase("pca\\alls5.dat", PCA_TYPE_ALL);
	 Quiz[20]->ExportExcelCase("pca\\males5.dat", PCA_TYPE_MALE);
	 Quiz[20]->ExportExcelCase("pca\\females5.dat", PCA_TYPE_FEMALE);

	 Quiz[21]->ExportExcelCase("pca\\alls6.dat", PCA_TYPE_ALL);
	 Quiz[21]->ExportExcelCase("pca\\males6.dat", PCA_TYPE_MALE);
	 Quiz[21]->ExportExcelCase("pca\\females6.dat", PCA_TYPE_FEMALE);

	 Quiz[22]->ExportExcelCase("pca\\alls7.dat", PCA_TYPE_ALL);
	 Quiz[22]->ExportExcelCase("pca\\males7.dat", PCA_TYPE_MALE);
	 Quiz[22]->ExportExcelCase("pca\\females7.dat", PCA_TYPE_FEMALE);

	 Quiz[23]->ExportExcelCase("pca\\alls8.dat", PCA_TYPE_ALL);
	 Quiz[23]->ExportExcelCase("pca\\males8.dat", PCA_TYPE_MALE);
	 Quiz[23]->ExportExcelCase("pca\\females8.dat", PCA_TYPE_FEMALE);

	 Quiz[24]->ExportExcelCase("pca\\alls9.dat", PCA_TYPE_ALL);
	 Quiz[24]->ExportExcelCase("pca\\males9.dat", PCA_TYPE_MALE);
	 Quiz[24]->ExportExcelCase("pca\\females9.dat", PCA_TYPE_FEMALE);

	 Quiz[25]->ExportExcelCase("pca\\alls10.dat", PCA_TYPE_ALL);
	 Quiz[25]->ExportExcelCase("pca\\males10.dat", PCA_TYPE_MALE);
	 Quiz[25]->ExportExcelCase("pca\\fems10.dat", PCA_TYPE_FEMALE);

	 Quiz[0]->ExportExcelAspie("pca\\aspie1.dat");
	 Quiz[1]->ExportExcelAspie("pca\\aspie2.dat");
	 Quiz[2]->ExportExcelAspie("pca\\aspie3.dat");
	 Quiz[3]->ExportExcelAspie("pca\\aspie4.dat");
	 Quiz[4]->ExportExcelAspie("pca\\aspie5.dat");
	 Quiz[5]->ExportExcelAspie("pca\\aspie6.dat");
	 Quiz[6]->ExportExcelAspie("pca\\aspie7.dat");
	 Quiz[7]->ExportExcelAspie("pca\\aspie8.dat");
	 Quiz[8]->ExportExcelAspie("pca\\aspie9.dat");
	 Quiz[9]->ExportExcelAspie("pca\\aspier1.dat");
	 Quiz[10]->ExportExcelAspie("pca\\aspier2.dat");
	 Quiz[11]->ExportExcelAspie("pca\\aspier3.dat");
	 Quiz[12]->ExportExcelAspie("pca\\aspier4.dat");
	 Quiz[13]->ExportExcelAspie("pca\\aspier5.dat");
	 Quiz[14]->ExportExcelAspie("pca\\aspier6.dat");
	 Quiz[15]->ExportExcelAspie("pca\\aspier7.dat");
	 Quiz[16]->ExportExcelAspie("pca\\aspies1.dat");
	 Quiz[17]->ExportExcelAspie("pca\\aspies2.dat");
	 Quiz[18]->ExportExcelAspie("pca\\aspies3.dat");
	 Quiz[19]->ExportExcelAspie("pca\\aspies4.dat");
	 Quiz[20]->ExportExcelAspie("pca\\aspies5.dat");
	 Quiz[21]->ExportExcelAspie("pca\\aspies6.dat");
	 Quiz[22]->ExportExcelAspie("pca\\aspies7.dat");
	 Quiz[23]->ExportExcelAspie("pca\\aspies8.dat");
	 Quiz[24]->ExportExcelAspie("pca\\aspies9.dat");
	 Quiz[25]->ExportExcelAspie("pca\\aspies10.dat");

	 Quiz[0]->ImportMvsp("pca\\all1.txt", PCA_TYPE_ALL);

	 Quiz[1]->ImportMvsp("pca\\all2.txt", PCA_TYPE_ALL);
	 Quiz[1]->ImportMvsp("pca\\male2.txt", PCA_TYPE_MALE);
	 Quiz[1]->ImportMvsp("pca\\female2.txt", PCA_TYPE_FEMALE);

	 Quiz[2]->ImportMvsp("pca\\all3.txt", PCA_TYPE_ALL);
	 Quiz[2]->ImportMvsp("pca\\male3.txt", PCA_TYPE_MALE);
	 Quiz[2]->ImportMvsp("pca\\female3.txt", PCA_TYPE_FEMALE);

	 Quiz[3]->ImportMvsp("pca\\all4.txt", PCA_TYPE_ALL);
	 Quiz[3]->ImportMvsp("pca\\male4.txt", PCA_TYPE_MALE);
	 Quiz[3]->ImportMvsp("pca\\female4.txt", PCA_TYPE_FEMALE);

	 Quiz[4]->ImportMvsp("pca\\all5.txt", PCA_TYPE_ALL);
	 Quiz[4]->ImportMvsp("pca\\male5.txt", PCA_TYPE_MALE);
	 Quiz[4]->ImportMvsp("pca\\female5.txt", PCA_TYPE_FEMALE);

	 Quiz[5]->ImportMvsp("pca\\all6.txt", PCA_TYPE_ALL);
	 Quiz[5]->ImportMvsp("pca\\male6.txt", PCA_TYPE_MALE);
	 Quiz[5]->ImportMvsp("pca\\female6.txt", PCA_TYPE_FEMALE);

	 Quiz[6]->ImportMvsp("pca\\all7.txt", PCA_TYPE_ALL);
	 Quiz[6]->ImportMvsp("pca\\male7.txt", PCA_TYPE_MALE);
	 Quiz[6]->ImportMvsp("pca\\female7.txt", PCA_TYPE_FEMALE);

	 Quiz[7]->ImportMvsp("pca\\all8.txt", PCA_TYPE_ALL);
	 Quiz[7]->ImportMvsp("pca\\male8.txt", PCA_TYPE_MALE);
	 Quiz[7]->ImportMvsp("pca\\female8.txt", PCA_TYPE_FEMALE);

	 Quiz[8]->ImportMvsp("pca\\all9.txt", PCA_TYPE_ALL);
	 Quiz[8]->ImportMvsp("pca\\male9.txt", PCA_TYPE_MALE);
	 Quiz[8]->ImportMvsp("pca\\female9.txt", PCA_TYPE_FEMALE);

	 Quiz[9]->ImportMvsp("pca\\allr1.txt", PCA_TYPE_ALL);
	 Quiz[9]->ImportMvsp("pca\\maler1.txt", PCA_TYPE_MALE);
	 Quiz[9]->ImportMvsp("pca\\femaler1.txt", PCA_TYPE_FEMALE);

	 Quiz[10]->ImportMvsp("pca\\allr2.txt", PCA_TYPE_ALL);
	 Quiz[10]->ImportMvsp("pca\\maler2.txt", PCA_TYPE_MALE);
	 Quiz[10]->ImportMvsp("pca\\femaler2.txt", PCA_TYPE_FEMALE);

	 Quiz[11]->ImportMvsp("pca\\allr3.txt", PCA_TYPE_ALL);
	 Quiz[11]->ImportMvsp("pca\\maler3.txt", PCA_TYPE_MALE);
	 Quiz[11]->ImportMvsp("pca\\femaler3.txt", PCA_TYPE_FEMALE);

	 Quiz[12]->ImportMvsp("pca\\allr4.txt", PCA_TYPE_ALL);
	 Quiz[12]->ImportMvsp("pca\\maler4.txt", PCA_TYPE_MALE);
	 Quiz[12]->ImportMvsp("pca\\femaler4.txt", PCA_TYPE_FEMALE);

	 Quiz[13]->ImportMvsp("pca\\allr5.txt", PCA_TYPE_ALL);
	 Quiz[13]->ImportMvsp("pca\\maler5.txt", PCA_TYPE_MALE);
	 Quiz[13]->ImportMvsp("pca\\femaler5.txt", PCA_TYPE_FEMALE);

	 Quiz[14]->ImportMvsp("pca\\allr6.txt", PCA_TYPE_ALL);
	 Quiz[14]->ImportMvsp("pca\\maler6.txt", PCA_TYPE_MALE);
	 Quiz[14]->ImportMvsp("pca\\femaler6.txt", PCA_TYPE_FEMALE);

	 Quiz[15]->ImportMvsp("pca\\allr7.txt", PCA_TYPE_ALL);
	 Quiz[15]->ImportMvsp("pca\\maler7.txt", PCA_TYPE_MALE);
	 Quiz[15]->ImportMvsp("pca\\femaler7.txt", PCA_TYPE_FEMALE);

	 Quiz[16]->ImportMvsp("pca\\alls1.txt", PCA_TYPE_ALL);
	 Quiz[16]->ImportMvsp("pca\\males1.txt", PCA_TYPE_MALE);
	 Quiz[16]->ImportMvsp("pca\\females1.txt", PCA_TYPE_FEMALE);

	 Quiz[17]->ImportMvsp("pca\\alls2.txt", PCA_TYPE_ALL);
	 Quiz[17]->ImportMvsp("pca\\males2.txt", PCA_TYPE_MALE);
	 Quiz[17]->ImportMvsp("pca\\females2.txt", PCA_TYPE_FEMALE);

	 Quiz[18]->ImportMvsp("pca\\alls3.txt", PCA_TYPE_ALL);
	 Quiz[18]->ImportMvsp("pca\\males3.txt", PCA_TYPE_MALE);
	 Quiz[18]->ImportMvsp("pca\\females3.txt", PCA_TYPE_FEMALE);

	 Quiz[19]->ImportMvsp("pca\\alls4.txt", PCA_TYPE_ALL);
	 Quiz[19]->ImportMvsp("pca\\males4.txt", PCA_TYPE_MALE);
	 Quiz[19]->ImportMvsp("pca\\females4.txt", PCA_TYPE_FEMALE);

	 Quiz[20]->ImportMvsp("pca\\alls5.txt", PCA_TYPE_ALL);
	 Quiz[20]->ImportMvsp("pca\\males5.txt", PCA_TYPE_MALE);
	 Quiz[20]->ImportMvsp("pca\\females5.txt", PCA_TYPE_FEMALE);

	 Quiz[21]->ImportMvsp("pca\\alls6.txt", PCA_TYPE_ALL);
	 Quiz[21]->ImportMvsp("pca\\males6.txt", PCA_TYPE_MALE);
	 Quiz[21]->ImportMvsp("pca\\females6.txt", PCA_TYPE_FEMALE);

	 Quiz[22]->ImportMvsp("pca\\alls7.txt", PCA_TYPE_ALL);
	 Quiz[22]->ImportMvsp("pca\\males7.txt", PCA_TYPE_MALE);
	 Quiz[22]->ImportMvsp("pca\\females7.txt", PCA_TYPE_FEMALE);

	 Quiz[23]->ImportMvsp("pca\\alls8.txt", PCA_TYPE_ALL);
	 Quiz[23]->ImportMvsp("pca\\males8.txt", PCA_TYPE_MALE);
	 Quiz[23]->ImportMvsp("pca\\females8.txt", PCA_TYPE_FEMALE);

	 Quiz[24]->ImportMvsp("pca\\alls9.txt", PCA_TYPE_ALL);
	 Quiz[24]->ImportMvsp("pca\\males9.txt", PCA_TYPE_MALE);
	 Quiz[24]->ImportMvsp("pca\\females9.txt", PCA_TYPE_FEMALE);

	 Quiz[25]->ImportMvsp("pca\\alls10.txt", PCA_TYPE_ALL);
	 Quiz[25]->ImportMvsp("pca\\males10.txt", PCA_TYPE_MALE);
	 Quiz[25]->ImportMvsp("pca\\fems10.txt", PCA_TYPE_FEMALE);

	 Quiz[0]->ImportMvspAspie("pca\\aspie1.txt");
	 Quiz[1]->ImportMvspAspie("pca\\aspie2.txt");
	 Quiz[2]->ImportMvspAspie("pca\\aspie3.txt");
	 Quiz[3]->ImportMvspAspie("pca\\aspie4.txt");
	 Quiz[4]->ImportMvspAspie("pca\\aspie5.txt");
	 Quiz[5]->ImportMvspAspie("pca\\aspie6.txt");
	 Quiz[6]->ImportMvspAspie("pca\\aspie7.txt");
	 Quiz[7]->ImportMvspAspie("pca\\aspie8.txt");
	 Quiz[8]->ImportMvspAspie("pca\\aspie9.txt");
	 Quiz[9]->ImportMvspAspie("pca\\aspier1.txt");
	 Quiz[10]->ImportMvspAspie("pca\\aspier2.txt");
	 Quiz[11]->ImportMvspAspie("pca\\aspier3.txt");
	 Quiz[12]->ImportMvspAspie("pca\\aspier4.txt");
	 Quiz[13]->ImportMvspAspie("pca\\aspier5.txt");
	 Quiz[14]->ImportMvspAspie("pca\\aspier6.txt");
	 Quiz[15]->ImportMvspAspie("pca\\aspier7.txt");
	 Quiz[16]->ImportMvspAspie("pca\\aspies1.txt");
	 Quiz[17]->ImportMvspAspie("pca\\aspies2.txt");
	 Quiz[18]->ImportMvspAspie("pca\\aspies3.txt");
	 Quiz[19]->ImportMvspAspie("pca\\aspies4.txt");
	 Quiz[20]->ImportMvspAspie("pca\\aspies5.txt");
	 Quiz[21]->ImportMvspAspie("pca\\aspies6.txt");
	 Quiz[22]->ImportMvspAspie("pca\\aspies7.txt");
	 Quiz[23]->ImportMvspAspie("pca\\aspies8.txt");
	 Quiz[24]->ImportMvspAspie("pca\\aspies9.txt");
	 Quiz[25]->ImportMvspAspie("pca\\aspies10.txt");

	 Quiz[25]->CalcGlobal();

//	 Quiz[25]->WritePhpQuestions("q.php");
//	 Quiz[25]->WriteSetupTexts("q.cpp");
//	 Quiz[25]->WriteSetupCross("c.cpp");

	 Quiz[0]->WriteReferers("eval\\ref1.htm");
	 Quiz[1]->WriteReferers("eval\\ref2.htm");
	 Quiz[2]->WriteReferers("eval\\ref3.htm");
	 Quiz[3]->WriteReferers("eval\\refnd.htm");
	 Quiz[4]->WriteReferers("eval\\ref5.htm");
	 Quiz[5]->WriteReferers("eval\\ref6.htm");
	 Quiz[6]->WriteReferers("eval\\ref7.htm");
	 Quiz[7]->WriteReferers("eval\\ref8.htm");
	 Quiz[8]->WriteReferers("eval\\ref9.htm");
	 Quiz[9]->WriteReferers("eval\\refr1.htm");
	 Quiz[10]->WriteReferers("eval\\refr2.htm");
	 Quiz[11]->WriteReferers("eval\\refr3.htm");
	 Quiz[12]->WriteReferers("eval\\refr4.htm");
	 Quiz[13]->WriteReferers("eval\\refr5.htm");
	 Quiz[14]->WriteReferers("eval\\refr6.htm");
	 Quiz[15]->WriteReferers("eval\\refr7.htm");
	 Quiz[16]->WriteReferers("eval\\refs1.htm");
	 Quiz[17]->WriteReferers("eval\\refs2.htm");
	 Quiz[18]->WriteReferers("eval\\refs3.htm");
	 Quiz[19]->WriteReferers("eval\\refs4.htm");
	 Quiz[20]->WriteReferers("eval\\refs5.htm");
	 Quiz[21]->WriteReferers("eval\\refs6.htm");
	 Quiz[22]->WriteReferers("eval\\refs7.htm");
	 Quiz[23]->WriteReferers("eval\\refs8.htm");
	 Quiz[24]->WriteReferers("eval\\refs9.htm");
	 Quiz[25]->WriteReferers("eval\\refs10.htm");

	 Quiz[0]->WriteSumaryTable("eval\\quiz1.htm", FALSE);
	 Quiz[1]->WriteSumaryTable("eval\\quiz2.htm", FALSE);
	 Quiz[2]->WriteSumaryTable("eval\\quiz3.htm", FALSE);
	 Quiz[3]->WriteSumaryTable("eval\\quiznd.htm", FALSE);
	 Quiz[4]->WriteSumaryTable("eval\\quiz5.htm", FALSE);
	 Quiz[5]->WriteSumaryTable("eval\\quiz6.htm", FALSE);
	 Quiz[6]->WriteSumaryTable("eval\\quiz7.htm", FALSE);
	 Quiz[7]->WriteSumaryTable("eval\\quiz8.htm", FALSE);
	 Quiz[8]->WriteSumaryTable("eval\\quiz9.htm", FALSE);
	 Quiz[9]->WriteSumaryTable("eval\\quizr1.htm", FALSE);
	 Quiz[10]->WriteSumaryTable("eval\\quizr2.htm", FALSE);
	 Quiz[11]->WriteSumaryTable("eval\\quizr3.htm", FALSE);
	 Quiz[12]->WriteSumaryTable("eval\\quizr4.htm", FALSE);
	 Quiz[13]->WriteSumaryTable("eval\\quizr5.htm", FALSE);
	 Quiz[14]->WriteSumaryTable("eval\\quizr6.htm", FALSE);
	 Quiz[15]->WriteSumaryTable("eval\\quizr7.htm", FALSE);
	 Quiz[16]->WriteSumaryTable("eval\\quizs1.htm", FALSE);
	 Quiz[17]->WriteSumaryTable("eval\\quizs2.htm", FALSE);
	 Quiz[18]->WriteSumaryTable("eval\\quizs3.htm", FALSE);
	 Quiz[19]->WriteSumaryTable("eval\\quizs4.htm", FALSE);
	 Quiz[20]->WriteSumaryTable("eval\\quizs5.htm", FALSE);
	 Quiz[21]->WriteSumaryTable("eval\\quizs6.htm", FALSE);
	 Quiz[22]->WriteSumaryTable("eval\\quizs7.htm", FALSE);
	 Quiz[23]->WriteSumaryTable("eval\\quizs8.htm", FALSE);
	 Quiz[24]->WriteSumaryTable("eval\\quizs9.htm", FALSE);
	 Quiz[25]->WriteSumaryTable("eval\\quizs10.htm", FALSE);

	 Quiz[0]->WriteIntercorr("eval\\rel1.htm");
	 Quiz[1]->WriteIntercorr("eval\\rel2.htm");
	 Quiz[2]->WriteIntercorr("eval\\rel3.htm");
	 Quiz[3]->WriteIntercorr("eval\\relnd.htm");
	 Quiz[4]->WriteIntercorr("eval\\rel5.htm");
	 Quiz[5]->WriteIntercorr("eval\\rel6.htm");
	 Quiz[6]->WriteIntercorr("eval\\rel7.htm");
	 Quiz[7]->WriteIntercorr("eval\\rel8.htm");
	 Quiz[8]->WriteIntercorr("eval\\rel9.htm");
	 Quiz[9]->WriteIntercorr("eval\\relr1.htm");
	 Quiz[10]->WriteIntercorr("eval\\relr2.htm");
	 Quiz[11]->WriteIntercorr("eval\\relr3.htm");
	 Quiz[12]->WriteIntercorr("eval\\relr4.htm");
	 Quiz[13]->WriteIntercorr("eval\\relr5.htm");
	 Quiz[14]->WriteIntercorr("eval\\relr6.htm");
	 Quiz[15]->WriteIntercorr("eval\\relr7.htm");
	 Quiz[16]->WriteIntercorr("eval\\rels1.htm");
	 Quiz[17]->WriteIntercorr("eval\\rels2.htm");
	 Quiz[18]->WriteIntercorr("eval\\rels3.htm");
	 Quiz[19]->WriteIntercorr("eval\\rels4.htm");
	 Quiz[20]->WriteIntercorr("eval\\rels5.htm");
	 Quiz[21]->WriteIntercorr("eval\\rels6.htm");
	 Quiz[22]->WriteIntercorr("eval\\rels7.htm");
	 Quiz[23]->WriteIntercorr("eval\\rels8.htm");
	 Quiz[24]->WriteIntercorr("eval\\rels9.htm");
	 Quiz[25]->WriteIntercorr("eval\\rels10.htm");

	 Quiz[25]->WriteGroupTable("eval\\group.htm", TRUE);
	 Quiz[25]->WriteGroupCorrTable("eval\\groupcorr.htm");
	 Quiz[25]->WritePcaLoadTable("eval\\pcaload.htm");

	 Quiz[25]->WriteAverageGroupCorrTable("eval\\avgcorr.htm");
	 Quiz[25]->WriteAveragePcaTable("eval\\avgpca.htm");
	 Quiz[25]->WriteAveragePcaCorrTable("eval\\avg.htm");

	 Quiz[25]->WritePcaCorrTable("eval\\pcacorr.htm");

	 Quiz[25]->WriteAxisLoadTable("eval\\axisload.htm");
	 Quiz[25]->WriteAverageAxisTable("eval\\avgaxis.htm");

	 Quiz[25]->WriteLinkReport("eval\\index.htm");

	 Quiz[5]->WriteHair("eval\\hair6.htm");
	 Quiz[5]->WriteEye("eval\\eye6.htm");
	 Quiz[5]->WriteRace("eval\\race6.htm");
	 Quiz[20]->WriteRace("eval\\races5.htm");

	 Quiz[6]->WriteHair("eval\\hair7.htm");
	 Quiz[6]->WriteEye("eval\\eye7.htm");
	 Quiz[6]->WriteRace("eval\\race7.htm");

	 Quiz[7]->WriteHair("eval\\hair8.htm");
	 Quiz[7]->WriteEye("eval\\eye8.htm");
	 Quiz[7]->WriteStim("eval\\stim8.htm");

	 Quiz[8]->WriteHair("eval\\hair9.htm");
	 Quiz[8]->WriteEye("eval\\eye9.htm");
	 Quiz[8]->WriteABO("eval\\abo9.htm");
	 Quiz[8]->WriteParkinson("eval\\park9.htm");
	 Quiz[8]->WriteAlzheimer("eval\\alz9.htm");
	 Quiz[8]->WriteCFTR("eval\\cftr9.htm");
	 Quiz[8]->WriteHFE("eval\\hfe9.htm");
	 Quiz[8]->WriteLeiden("eval\\leiden9.htm");

	 Quiz[17]->WriteRetest("eval\\retests2.htm");
	 Quiz[18]->WriteRetest("eval\\retests3.htm");
	 Quiz[19]->WriteRetest("eval\\retests4.htm");
	 Quiz[20]->WriteRetest("eval\\retests5.htm");
	 Quiz[21]->WriteRetest("eval\\retests6.htm");
	 Quiz[22]->WriteRetest("eval\\retests7.htm");
	 Quiz[23]->WriteRetest("eval\\retests8.htm");
	 Quiz[24]->WriteRetest("eval\\retests9.htm");
	 Quiz[24]->WriteVersionRetest("eval\\vervar.htm");

	 Quiz[16]->WritePictureRating("eval\\imgrate1.htm");
	 Quiz[17]->WritePictureRating("eval\\imgrate2.htm");

	 Quiz[0]->WritePcaGroupCorr("eval\\pca1.htm");
	 Quiz[1]->WritePcaGroupCorr("eval\\pca2.htm");
	 Quiz[2]->WritePcaGroupCorr("eval\\pca3.htm");
	 Quiz[3]->WritePcaGroupCorr("eval\\pca4.htm");
	 Quiz[4]->WritePcaGroupCorr("eval\\pca5.htm");
	 Quiz[5]->WritePcaGroupCorr("eval\\pca6.htm");
	 Quiz[6]->WritePcaGroupCorr("eval\\pca7.htm");
	 Quiz[7]->WritePcaGroupCorr("eval\\pca8.htm");
	 Quiz[8]->WritePcaGroupCorr("eval\\pca9.htm");
	 Quiz[9]->WritePcaGroupCorr("eval\\pcar1.htm");
	 Quiz[10]->WritePcaGroupCorr("eval\\pcar2.htm");
	 Quiz[11]->WritePcaGroupCorr("eval\\pcar3.htm");
	 Quiz[12]->WritePcaGroupCorr("eval\\pcar4.htm");
	 Quiz[13]->WritePcaGroupCorr("eval\\pcar5.htm");
	 Quiz[14]->WritePcaGroupCorr("eval\\pcar6.htm");
	 Quiz[15]->WritePcaGroupCorr("eval\\pcar7.htm");
	 Quiz[16]->WritePcaGroupCorr("eval\\pcas1.htm");
	 Quiz[17]->WritePcaGroupCorr("eval\\pcas2.htm");
	 Quiz[18]->WritePcaGroupCorr("eval\\pcas3.htm");
	 Quiz[19]->WritePcaGroupCorr("eval\\pcas4.htm");
	 Quiz[20]->WritePcaGroupCorr("eval\\pcas5.htm");
	 Quiz[21]->WritePcaGroupCorr("eval\\pcas6.htm");
	 Quiz[22]->WritePcaGroupCorr("eval\\pcas7.htm");
	 Quiz[23]->WritePcaGroupCorr("eval\\pcas8.htm");
	 Quiz[24]->WritePcaGroupCorr("eval\\pcas9.htm");
	 Quiz[25]->WritePcaGroupCorr("eval\\pcas10.htm");

//	 Quiz[19]->WriteLSAS("");
//	 Quiz[23]->WriteMDQ("");
	 Quiz[24]->WriteADD("");
	 Quiz[25]->WriteDyslexia("");

	 Quiz[6]->WriteRefererNtCorrelation("eval\\exhnt.htm", "Exhibitionism", "dickflash.com");

	 Quiz[1]->ExportHistogram("csv\\all2.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[2]->ExportHistogram("csv\\all3.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[3]->ExportHistogram("csv\\all4.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[4]->ExportHistogram("csv\\all5.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[5]->ExportHistogram("csv\\all6.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[6]->ExportHistogram("csv\\all7.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[7]->ExportHistogram("csv\\all8.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[8]->ExportHistogram("csv\\all9.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[9]->ExportHistogram("csv\\allr1.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[10]->ExportHistogram("csv\\allr2.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[11]->ExportHistogram("csv\\allr3.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[12]->ExportHistogram("csv\\allr4.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[13]->ExportHistogram("csv\\allr5.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[14]->ExportHistogram("csv\\allr6.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[15]->ExportHistogram("csv\\allr7.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[16]->ExportHistogram("csv\\alls1.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[17]->ExportHistogram("csv\\alls2.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[18]->ExportHistogram("csv\\alls3.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[19]->ExportHistogram("csv\\alls4.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[20]->ExportHistogram("csv\\alls5.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[21]->ExportHistogram("csv\\alls6.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[22]->ExportHistogram("csv\\alls7.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[23]->ExportHistogram("csv\\alls8.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[24]->ExportHistogram("csv\\alls9.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[25]->ExportHistogram("csv\\alls10.csv", POP_TYPE_ALL, 2, FALSE);

	 Quiz[0]->WriteGroupWeighting("conv.h");
	 Quiz[1]->WriteGroupWeighting("conv2.h");
	 Quiz[2]->WriteGroupWeighting("conv3.h");
	 Quiz[3]->WriteGroupWeighting("convnd.h");
	 Quiz[4]->WriteGroupWeighting("conv5.h");
	 Quiz[5]->WriteGroupWeighting("conv6.h");
	 Quiz[6]->WriteGroupWeighting("conv7.h");
	 Quiz[7]->WriteGroupWeighting("conv8.h");
	 Quiz[8]->WriteGroupWeighting("conv9.h");
	 Quiz[9]->WriteGroupWeighting("convr1.h");
	 Quiz[10]->WriteGroupWeighting("convr2.h");
	 Quiz[11]->WriteGroupWeighting("convr3.h");
	 Quiz[12]->WriteGroupWeighting("convr4.h");
	 Quiz[13]->WriteGroupWeighting("convr5.h");
	 Quiz[14]->WriteGroupWeighting("convr6.h");
	 Quiz[15]->WriteGroupWeighting("convr7.h");
	 Quiz[16]->WriteGroupWeighting("convs1.h");
	 Quiz[17]->WriteGroupWeighting("convs2.h");
	 Quiz[18]->WriteGroupWeighting("convs3.h");
	 Quiz[19]->WriteGroupWeighting("convs4.h");
	 Quiz[20]->WriteGroupWeighting("convs5.h");
	 Quiz[21]->WriteGroupWeighting("convs6.h");
	 Quiz[22]->WriteGroupWeighting("convs7.h");
	 Quiz[23]->WriteGroupWeighting("convs8.h");
	 Quiz[24]->WriteGroupWeighting("convs9.h");
	 Quiz[25]->WriteGroupWeighting("convs10.h");

	 Quiz[25]->ExportDiffHistogram("csv\\all.csv", POP_TYPE_ALL);

	 Quiz[25]->ExportDiffHistogram("csv\\autism.csv", POP_TYPE_AUTISM);
	 Quiz[25]->ExportDiffHistogram("csv\\as.csv", POP_TYPE_AS);
	 Quiz[25]->ExportDiffHistogram("csv\\nt.csv", POP_TYPE_NT_CONTROL);
	 Quiz[25]->ExportDiffHistogram("csv\\soc.csv", POP_TYPE_SOCIAL_PHOBIA);
	 Quiz[25]->ExportDiffHistogram("csv\\add.csv", POP_TYPE_ADD);
	 Quiz[25]->ExportDiffHistogram("csv\\ts.csv", POP_TYPE_TS);
	 Quiz[25]->ExportDiffHistogram("csv\\pa.csv", POP_TYPE_PA);
	 Quiz[25]->ExportDiffHistogram("csv\\bip.csv", POP_TYPE_BIPOLAR);
	 Quiz[25]->ExportDiffHistogram("csv\\schizo.csv", POP_TYPE_SCHIZOPHRENIA);
	 Quiz[25]->ExportDiffHistogram("csv\\syn.csv", POP_TYPE_SYNAESTHESIA);
	 Quiz[25]->ExportDiffHistogram("csv\\dysl.csv", POP_TYPE_DYSLEXIA);
	 Quiz[25]->ExportDiffHistogram("csv\\dysc.csv", POP_TYPE_DYSCALCULIA);
	 Quiz[25]->ExportDiffHistogram("csv\\dysg.csv", POP_TYPE_DYSGRAPHIA);
	 Quiz[25]->ExportDiffHistogram("csv\\ocd.csv", POP_TYPE_OCD);
	 Quiz[25]->ExportDiffHistogram("csv\\odd.csv", POP_TYPE_ODD);
	 Quiz[25]->ExportDiffHistogram("csv\\dysp.csv", POP_TYPE_DYSPRAXIA);

	 TQuiz::ExportBirthMonthHistogram("csv\\birth.csv");

	 TQuiz::WriteDsmReport("eval\\autism.htm", POP_TYPE_AUTISM);
	 TQuiz::WriteDsmReport("eval\\as.htm", POP_TYPE_AS);
	 TQuiz::WriteDsmReport("eval\\add.htm", POP_TYPE_ADD);
	 TQuiz::WriteDsmReport("eval\\ts.htm", POP_TYPE_TS);
	 TQuiz::WriteDsmReport("eval\\dysp.htm", POP_TYPE_DYSPRAXIA);
	 TQuiz::WriteDsmReport("eval\\dysl.htm", POP_TYPE_DYSLEXIA);
	 TQuiz::WriteDsmReport("eval\\dysc.htm", POP_TYPE_DYSCALCULIA);
	 TQuiz::WriteDsmReport("eval\\ocd.htm", POP_TYPE_OCD);
	 TQuiz::WriteDsmReport("eval\\odd.htm", POP_TYPE_ODD);
	 TQuiz::WriteDsmReport("eval\\pa.htm", POP_TYPE_PA);
	 TQuiz::WriteDsmReport("eval\\dysg.htm", POP_TYPE_DYSGRAPHIA);
	 TQuiz::WriteDsmReport("eval\\bip.htm", POP_TYPE_BIPOLAR);
	 TQuiz::WriteDsmReport("eval\\schizo.htm", POP_TYPE_SCHIZOPHRENIA);
	 TQuiz::WriteDsmReport("eval\\social.htm", POP_TYPE_SOCIAL_PHOBIA);

//	 Quiz[18]->WriteWeighting("weights.cpp");
//	 Quiz[25]->WritePhpWeighting("weights.php");
//	 Quiz[25]->WritePhpGroupWeighting("group.php");

//	 Quiz[9]->MoveWiki("iwiki.txt", "wiki.txt", 0.2);

//	  Quiz[16]->WriteWiki("wiki.txt", 0.2, 0.2);
//	  Quiz[14]->WriteWikiCorrelation("wiki.txt", "maxcorr.htm", 150);
//	  Quiz[14]->WriteWikiNoncorrelated("wiki.txt", "mincorr.htm", 150);

//	  Quiz[24]->WriteQuizWiki("s10.txt");

//	  TQuiz::PrintGlobalCorrelation(258, 81);
//	  TQuiz::PrintGlobalCorrelation(556, 493);


//	 TQuiz::WikiToQuiz("wiki.txt", "s10.txt");

//	 Quiz[7]->WritePhpGlobalQuestions("global.php");

	Quiz[25]->ExportGlobalSql("db\\global.sql");
	Quiz[25]->ExportQuizVerSql("db\\quizver.sql");
	Quiz[25]->ExportGroupSql("db\\group.sql");
	Quiz[25]->ExportPopTypeSql("db\\poptype.sql");
	Quiz[25]->ExportGlobalCorrSql("db\\gcorr.sql");
	Quiz[25]->ExportGlobalAxisSql("db\\gaxis.sql");
	Quiz[25]->ExportQuizCatPopSql("db\\qcatpop.sql");
	Quiz[25]->ExportQuizGlobalSql("db\\qglobal.sql");
}

