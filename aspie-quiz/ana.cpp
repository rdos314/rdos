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
// #include "spq.h"
#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1

#define FALSE 0
#define TRUE !FALSE

TQuiz *Quiz[25];

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
	 Quiz[20]->CheckCross();

	Quiz[0]->ExportExcelCase("all1.dat", PCA_TYPE_ALL);
	Quiz[0]->ExportExcelCase("male1.dat", PCA_TYPE_MALE);
	Quiz[0]->ExportExcelCase("female1.dat", PCA_TYPE_FEMALE);

	Quiz[1]->ExportExcelCase("all2.dat", PCA_TYPE_ALL);
	Quiz[1]->ExportExcelCase("male2.dat", PCA_TYPE_MALE);
	Quiz[1]->ExportExcelCase("female2.dat", PCA_TYPE_FEMALE);

	 Quiz[2]->ExportExcelCase("all3.dat", PCA_TYPE_ALL);
	 Quiz[2]->ExportExcelCase("male3.dat", PCA_TYPE_MALE);
	 Quiz[2]->ExportExcelCase("female3.dat", PCA_TYPE_FEMALE);

	 Quiz[3]->ExportExcelCase("all4.dat", PCA_TYPE_ALL);
	 Quiz[3]->ExportExcelCase("male4.dat", PCA_TYPE_MALE);
	 Quiz[3]->ExportExcelCase("female4.dat", PCA_TYPE_FEMALE);

	 Quiz[4]->ExportExcelCase("all5.dat", PCA_TYPE_ALL);
	 Quiz[4]->ExportExcelCase("male5.dat", PCA_TYPE_MALE);
	 Quiz[4]->ExportExcelCase("female5.dat", PCA_TYPE_FEMALE);

	 Quiz[5]->ExportExcelCase("all6.dat", PCA_TYPE_ALL);
	 Quiz[5]->ExportExcelCase("male6.dat", PCA_TYPE_MALE);
	 Quiz[5]->ExportExcelCase("female6.dat", PCA_TYPE_FEMALE);

	 Quiz[6]->ExportExcelCase("all7.dat", PCA_TYPE_ALL);
	 Quiz[6]->ExportExcelCase("male7.dat", PCA_TYPE_MALE);
	 Quiz[6]->ExportExcelCase("female7.dat", PCA_TYPE_FEMALE);

	 Quiz[7]->ExportExcelCase("all8.dat", PCA_TYPE_ALL);
	 Quiz[7]->ExportExcelCase("male8.dat", PCA_TYPE_MALE);
	 Quiz[7]->ExportExcelCase("female8.dat", PCA_TYPE_FEMALE);

	 Quiz[8]->ExportExcelCase("all9.dat", PCA_TYPE_ALL);
	 Quiz[8]->ExportExcelCase("male9.dat", PCA_TYPE_MALE);
	 Quiz[8]->ExportExcelCase("female9.dat", PCA_TYPE_FEMALE);

	 Quiz[9]->ExportExcelCase("allr1.dat", PCA_TYPE_ALL);
	 Quiz[9]->ExportExcelCase("maler1.dat", PCA_TYPE_MALE);
	 Quiz[9]->ExportExcelCase("femaler1.dat", PCA_TYPE_FEMALE);

	 Quiz[10]->ExportExcelCase("allr2.dat", PCA_TYPE_ALL);
	 Quiz[10]->ExportExcelCase("maler2.dat", PCA_TYPE_MALE);
	 Quiz[10]->ExportExcelCase("femaler2.dat", PCA_TYPE_FEMALE);

	 Quiz[11]->ExportExcelCase("allr3.dat", PCA_TYPE_ALL);
	 Quiz[11]->ExportExcelCase("maler3.dat", PCA_TYPE_MALE);
	 Quiz[11]->ExportExcelCase("femaler3.dat", PCA_TYPE_FEMALE);

	 Quiz[12]->ExportExcelCase("allr4.dat", PCA_TYPE_ALL);
	 Quiz[12]->ExportExcelCase("maler4.dat", PCA_TYPE_MALE);
	 Quiz[12]->ExportExcelCase("femaler4.dat", PCA_TYPE_FEMALE);

	 Quiz[13]->ExportExcelCase("allr5.dat", PCA_TYPE_ALL);
	 Quiz[13]->ExportExcelCase("maler5.dat", PCA_TYPE_MALE);
	 Quiz[13]->ExportExcelCase("femaler5.dat", PCA_TYPE_FEMALE);

	 Quiz[14]->ExportExcelCase("allr6.dat", PCA_TYPE_ALL);
	 Quiz[14]->ExportExcelCase("maler6.dat", PCA_TYPE_MALE);
	 Quiz[14]->ExportExcelCase("femaler6.dat", PCA_TYPE_FEMALE);

	 Quiz[15]->ExportExcelCase("allr7.dat", PCA_TYPE_ALL);
	 Quiz[15]->ExportExcelCase("maler7.dat", PCA_TYPE_MALE);
	 Quiz[15]->ExportExcelCase("femaler7.dat", PCA_TYPE_FEMALE);

	 Quiz[16]->ExportExcelCase("alls1.dat", PCA_TYPE_ALL);
	 Quiz[16]->ExportExcelCase("males1.dat", PCA_TYPE_MALE);
	 Quiz[16]->ExportExcelCase("females1.dat", PCA_TYPE_FEMALE);

	 Quiz[17]->ExportExcelCase("alls2.dat", PCA_TYPE_ALL);
	 Quiz[17]->ExportExcelCase("males2.dat", PCA_TYPE_MALE);
	 Quiz[17]->ExportExcelCase("females2.dat", PCA_TYPE_FEMALE);

	 Quiz[18]->ExportExcelCase("alls3.dat", PCA_TYPE_ALL);
	 Quiz[18]->ExportExcelCase("males3.dat", PCA_TYPE_MALE);
	 Quiz[18]->ExportExcelCase("females3.dat", PCA_TYPE_FEMALE);

	 Quiz[19]->ExportExcelCase("alls4.dat", PCA_TYPE_ALL);
	 Quiz[19]->ExportExcelCase("males4.dat", PCA_TYPE_MALE);
	 Quiz[19]->ExportExcelCase("females4.dat", PCA_TYPE_FEMALE);

	 Quiz[20]->ExportExcelCase("alls5.dat", PCA_TYPE_ALL);
	 Quiz[20]->ExportExcelCase("males5.dat", PCA_TYPE_MALE);
	 Quiz[20]->ExportExcelCase("females5.dat", PCA_TYPE_FEMALE);

	 Quiz[0]->ExportExcelAspie("aspie1.dat");
	 Quiz[1]->ExportExcelAspie("aspie2.dat");
	 Quiz[2]->ExportExcelAspie("aspie3.dat");
	 Quiz[3]->ExportExcelAspie("aspie4.dat");
	 Quiz[4]->ExportExcelAspie("aspie5.dat");
	 Quiz[5]->ExportExcelAspie("aspie6.dat");
	 Quiz[6]->ExportExcelAspie("aspie7.dat");
	 Quiz[7]->ExportExcelAspie("aspie8.dat");
	 Quiz[8]->ExportExcelAspie("aspie9.dat");
	 Quiz[9]->ExportExcelAspie("aspier1.dat");
	 Quiz[10]->ExportExcelAspie("aspier2.dat");
	 Quiz[11]->ExportExcelAspie("aspier3.dat");
	 Quiz[12]->ExportExcelAspie("aspier4.dat");
	 Quiz[13]->ExportExcelAspie("aspier5.dat");
	 Quiz[14]->ExportExcelAspie("aspier6.dat");
	 Quiz[15]->ExportExcelAspie("aspier7.dat");
	 Quiz[16]->ExportExcelAspie("aspies1.dat");
	 Quiz[17]->ExportExcelAspie("aspies2.dat");
	 Quiz[18]->ExportExcelAspie("aspies3.dat");
	 Quiz[19]->ExportExcelAspie("aspies4.dat");
	 Quiz[20]->ExportExcelAspie("aspies5.dat");

	 Quiz[0]->ImportMvsp("all1.txt", PCA_TYPE_ALL);

	 Quiz[1]->ImportMvsp("all2.txt", PCA_TYPE_ALL);
	 Quiz[1]->ImportMvsp("male2.txt", PCA_TYPE_MALE);
	 Quiz[1]->ImportMvsp("female2.txt", PCA_TYPE_FEMALE);

	 Quiz[2]->ImportMvsp("all3.txt", PCA_TYPE_ALL);
	 Quiz[2]->ImportMvsp("male3.txt", PCA_TYPE_MALE);
	 Quiz[2]->ImportMvsp("female3.txt", PCA_TYPE_FEMALE);

	 Quiz[3]->ImportMvsp("all4.txt", PCA_TYPE_ALL);
	 Quiz[3]->ImportMvsp("male4.txt", PCA_TYPE_MALE);
	 Quiz[3]->ImportMvsp("female4.txt", PCA_TYPE_FEMALE);

	 Quiz[4]->ImportMvsp("all5.txt", PCA_TYPE_ALL);
	 Quiz[4]->ImportMvsp("male5.txt", PCA_TYPE_MALE);
	 Quiz[4]->ImportMvsp("female5.txt", PCA_TYPE_FEMALE);

	 Quiz[5]->ImportMvsp("all6.txt", PCA_TYPE_ALL);
	 Quiz[5]->ImportMvsp("male6.txt", PCA_TYPE_MALE);
	 Quiz[5]->ImportMvsp("female6.txt", PCA_TYPE_FEMALE);

	 Quiz[6]->ImportMvsp("all7.txt", PCA_TYPE_ALL);
	 Quiz[6]->ImportMvsp("male7.txt", PCA_TYPE_MALE);
	 Quiz[6]->ImportMvsp("female7.txt", PCA_TYPE_FEMALE);

	 Quiz[7]->ImportMvsp("all8.txt", PCA_TYPE_ALL);
	 Quiz[7]->ImportMvsp("male8.txt", PCA_TYPE_MALE);
	 Quiz[7]->ImportMvsp("female8.txt", PCA_TYPE_FEMALE);

	 Quiz[8]->ImportMvsp("all9.txt", PCA_TYPE_ALL);
	 Quiz[8]->ImportMvsp("male9.txt", PCA_TYPE_MALE);
	 Quiz[8]->ImportMvsp("female9.txt", PCA_TYPE_FEMALE);

	 Quiz[9]->ImportMvsp("allr1.txt", PCA_TYPE_ALL);
	 Quiz[9]->ImportMvsp("maler1.txt", PCA_TYPE_MALE);
	 Quiz[9]->ImportMvsp("femaler1.txt", PCA_TYPE_FEMALE);

	 Quiz[10]->ImportMvsp("allr2.txt", PCA_TYPE_ALL);
	 Quiz[10]->ImportMvsp("maler2.txt", PCA_TYPE_MALE);
	 Quiz[10]->ImportMvsp("femaler2.txt", PCA_TYPE_FEMALE);

	 Quiz[11]->ImportMvsp("allr3.txt", PCA_TYPE_ALL);
	 Quiz[11]->ImportMvsp("maler3.txt", PCA_TYPE_MALE);
	 Quiz[11]->ImportMvsp("femaler3.txt", PCA_TYPE_FEMALE);

	 Quiz[12]->ImportMvsp("allr4.txt", PCA_TYPE_ALL);
	 Quiz[12]->ImportMvsp("maler4.txt", PCA_TYPE_MALE);
	 Quiz[12]->ImportMvsp("femaler4.txt", PCA_TYPE_FEMALE);

	 Quiz[13]->ImportMvsp("allr5.txt", PCA_TYPE_ALL);
	 Quiz[13]->ImportMvsp("maler5.txt", PCA_TYPE_MALE);
	 Quiz[13]->ImportMvsp("femaler5.txt", PCA_TYPE_FEMALE);

	 Quiz[14]->ImportMvsp("allr6.txt", PCA_TYPE_ALL);
	 Quiz[14]->ImportMvsp("maler6.txt", PCA_TYPE_MALE);
	 Quiz[14]->ImportMvsp("femaler6.txt", PCA_TYPE_FEMALE);

	 Quiz[15]->ImportMvsp("allr7.txt", PCA_TYPE_ALL);
	 Quiz[15]->ImportMvsp("maler7.txt", PCA_TYPE_MALE);
	 Quiz[15]->ImportMvsp("femaler7.txt", PCA_TYPE_FEMALE);

	 Quiz[16]->ImportMvsp("alls1.txt", PCA_TYPE_ALL);
	 Quiz[16]->ImportMvsp("males1.txt", PCA_TYPE_MALE);
	 Quiz[16]->ImportMvsp("females1.txt", PCA_TYPE_FEMALE);

	 Quiz[17]->ImportMvsp("alls2.txt", PCA_TYPE_ALL);
	 Quiz[17]->ImportMvsp("males2.txt", PCA_TYPE_MALE);
	 Quiz[17]->ImportMvsp("females2.txt", PCA_TYPE_FEMALE);

	 Quiz[18]->ImportMvsp("alls3.txt", PCA_TYPE_ALL);
	 Quiz[18]->ImportMvsp("males3.txt", PCA_TYPE_MALE);
	 Quiz[18]->ImportMvsp("females3.txt", PCA_TYPE_FEMALE);

	 Quiz[19]->ImportMvsp("alls4.txt", PCA_TYPE_ALL);
	 Quiz[19]->ImportMvsp("males4.txt", PCA_TYPE_MALE);
	 Quiz[19]->ImportMvsp("females4.txt", PCA_TYPE_FEMALE);

	 Quiz[20]->ImportMvsp("alls5.txt", PCA_TYPE_ALL);
	 Quiz[20]->ImportMvsp("males5.txt", PCA_TYPE_MALE);
	 Quiz[20]->ImportMvsp("females5.txt", PCA_TYPE_FEMALE);

	 Quiz[0]->ImportMvspAspie("aspie1.txt");
	 Quiz[1]->ImportMvspAspie("aspie2.txt");
	 Quiz[2]->ImportMvspAspie("aspie3.txt");
	 Quiz[3]->ImportMvspAspie("aspie4.txt");
	 Quiz[4]->ImportMvspAspie("aspie5.txt");
	 Quiz[5]->ImportMvspAspie("aspie6.txt");
	 Quiz[6]->ImportMvspAspie("aspie7.txt");
	 Quiz[7]->ImportMvspAspie("aspie8.txt");
	 Quiz[8]->ImportMvspAspie("aspie9.txt");
	 Quiz[9]->ImportMvspAspie("aspier1.txt");
	 Quiz[10]->ImportMvspAspie("aspier2.txt");
	 Quiz[11]->ImportMvspAspie("aspier3.txt");
	 Quiz[12]->ImportMvspAspie("aspier4.txt");
	 Quiz[13]->ImportMvspAspie("aspier5.txt");
	 Quiz[14]->ImportMvspAspie("aspier6.txt");
	 Quiz[15]->ImportMvspAspie("aspier7.txt");
	 Quiz[16]->ImportMvspAspie("aspies1.txt");
	 Quiz[17]->ImportMvspAspie("aspies2.txt");
	 Quiz[18]->ImportMvspAspie("aspies3.txt");
	 Quiz[19]->ImportMvspAspie("aspies4.txt");
	 Quiz[20]->ImportMvspAspie("aspies5.txt");

	 Quiz[20]->CalcGlobal();

//	 Quiz[20]->WritePhpQuestions("q.php");
//	 Quiz[20]->WriteSetupTexts("q.cpp");
//	 Quiz[20]->WriteSetupCross("c.cpp");

	 Quiz[0]->WriteReferers("ref1.htm");
	 Quiz[1]->WriteReferers("ref2.htm");
	 Quiz[2]->WriteReferers("ref3.htm");
	 Quiz[3]->WriteReferers("refnd.htm");
	 Quiz[4]->WriteReferers("ref5.htm");
	 Quiz[5]->WriteReferers("ref6.htm");
	 Quiz[6]->WriteReferers("ref7.htm");
	 Quiz[7]->WriteReferers("ref8.htm");
	 Quiz[8]->WriteReferers("ref9.htm");
	 Quiz[9]->WriteReferers("refr1.htm");
	 Quiz[10]->WriteReferers("refr2.htm");
	 Quiz[11]->WriteReferers("refr3.htm");
	 Quiz[12]->WriteReferers("refr4.htm");
	 Quiz[13]->WriteReferers("refr5.htm");
	 Quiz[14]->WriteReferers("refr6.htm");
	 Quiz[15]->WriteReferers("refr7.htm");
	 Quiz[16]->WriteReferers("refs1.htm");
	 Quiz[17]->WriteReferers("refs2.htm");
	 Quiz[18]->WriteReferers("refs3.htm");
	 Quiz[19]->WriteReferers("refs4.htm");
	 Quiz[20]->WriteReferers("refs5.htm");

	 Quiz[0]->WriteSumaryTable("quiz1.htm", FALSE);
	 Quiz[1]->WriteSumaryTable("quiz2.htm", FALSE);
	 Quiz[2]->WriteSumaryTable("quiz3.htm", FALSE);
	 Quiz[3]->WriteSumaryTable("quiznd.htm", FALSE);
	 Quiz[4]->WriteSumaryTable("quiz5.htm", FALSE);
	 Quiz[5]->WriteSumaryTable("quiz6.htm", FALSE);
	 Quiz[6]->WriteSumaryTable("quiz7.htm", FALSE);
	 Quiz[7]->WriteSumaryTable("quiz8.htm", FALSE);
	 Quiz[8]->WriteSumaryTable("quiz9.htm", FALSE);
	 Quiz[9]->WriteSumaryTable("quizr1.htm", FALSE);
	 Quiz[10]->WriteSumaryTable("quizr2.htm", FALSE);
	 Quiz[11]->WriteSumaryTable("quizr3.htm", FALSE);
	 Quiz[12]->WriteSumaryTable("quizr4.htm", FALSE);
	 Quiz[13]->WriteSumaryTable("quizr5.htm", FALSE);
	 Quiz[14]->WriteSumaryTable("quizr6.htm", FALSE);
	 Quiz[15]->WriteSumaryTable("quizr7.htm", FALSE);
	 Quiz[16]->WriteSumaryTable("quizs1.htm", FALSE);
	 Quiz[17]->WriteSumaryTable("quizs2.htm", FALSE);
	 Quiz[18]->WriteSumaryTable("quizs3.htm", FALSE);
	 Quiz[19]->WriteSumaryTable("quizs4.htm", FALSE);
	 Quiz[20]->WriteSumaryTable("quizs5.htm", FALSE);

	 Quiz[0]->WriteIntercorr("rel1.htm");
	 Quiz[1]->WriteIntercorr("rel2.htm");
	 Quiz[2]->WriteIntercorr("rel3.htm");
	 Quiz[3]->WriteIntercorr("relnd.htm");
	 Quiz[4]->WriteIntercorr("rel5.htm");
	 Quiz[5]->WriteIntercorr("rel6.htm");
	 Quiz[6]->WriteIntercorr("rel7.htm");
	 Quiz[7]->WriteIntercorr("rel8.htm");
	 Quiz[8]->WriteIntercorr("rel9.htm");
	 Quiz[9]->WriteIntercorr("relr1.htm");
	 Quiz[10]->WriteIntercorr("relr2.htm");
	 Quiz[11]->WriteIntercorr("relr3.htm");
	 Quiz[12]->WriteIntercorr("relr4.htm");
	 Quiz[13]->WriteIntercorr("relr5.htm");
	 Quiz[14]->WriteIntercorr("relr6.htm");
	 Quiz[15]->WriteIntercorr("relr7.htm");
	 Quiz[16]->WriteIntercorr("rels1.htm");
	 Quiz[17]->WriteIntercorr("rels2.htm");
	 Quiz[18]->WriteIntercorr("rels3.htm");
	 Quiz[19]->WriteIntercorr("rels4.htm");
	 Quiz[20]->WriteIntercorr("rels5.htm");

	 Quiz[20]->WriteGroupTable("group.htm", TRUE);
	 Quiz[20]->WriteGroupCorrTable("groupcorr.htm");
	 Quiz[20]->WritePcaLoadTable("pcaload.htm");

	 Quiz[20]->WriteAverageGroupCorrTable("avgcorr.htm");
	 Quiz[20]->WriteAveragePcaTable("avgpca.htm");
	 Quiz[20]->WriteAveragePcaCorrTable("avg.htm");

	 Quiz[20]->WritePcaCorrTable("pcacorr.htm");

	 Quiz[20]->WriteAxisLoadTable("axisload.htm");
	 Quiz[20]->WriteAverageAxisTable("avgaxis.htm");

	 Quiz[20]->WriteLinkReport("index.htm");

	 Quiz[5]->WriteHair("hair6.htm");
	 Quiz[5]->WriteEye("eye6.htm");
	 Quiz[5]->WriteRace("race6.htm");

	 Quiz[6]->WriteHair("hair7.htm");
	 Quiz[6]->WriteEye("eye7.htm");
	 Quiz[6]->WriteRace("race7.htm");

	 Quiz[7]->WriteHair("hair8.htm");
	 Quiz[7]->WriteEye("eye8.htm");
	 Quiz[7]->WriteStim("stim8.htm");

	 Quiz[8]->WriteHair("hair9.htm");
	 Quiz[8]->WriteEye("eye9.htm");
	 Quiz[8]->WriteABO("abo9.htm");
	 Quiz[8]->WriteParkinson("park9.htm");
	 Quiz[8]->WriteAlzheimer("alz9.htm");
	 Quiz[8]->WriteCFTR("cftr9.htm");
	 Quiz[8]->WriteHFE("hfe9.htm");
	 Quiz[8]->WriteLeiden("leiden9.htm");

	 Quiz[17]->WriteRetest("retests2.htm");
	 Quiz[18]->WriteRetest("retests3.htm");
	 Quiz[19]->WriteRetest("retests4.htm");
	 Quiz[19]->WriteVersionRetest("vervar.htm");

	 Quiz[16]->WritePictureRating("imgrate1.htm");
	 Quiz[17]->WritePictureRating("imgrate2.htm");

	 Quiz[0]->WritePcaGroupCorr("pca1.htm");
	 Quiz[1]->WritePcaGroupCorr("pca2.htm");
	 Quiz[2]->WritePcaGroupCorr("pca3.htm");
	 Quiz[3]->WritePcaGroupCorr("pca4.htm");
	 Quiz[4]->WritePcaGroupCorr("pca5.htm");
	 Quiz[5]->WritePcaGroupCorr("pca6.htm");
	 Quiz[6]->WritePcaGroupCorr("pca7.htm");
	 Quiz[7]->WritePcaGroupCorr("pca8.htm");
	 Quiz[8]->WritePcaGroupCorr("pca9.htm");
	 Quiz[9]->WritePcaGroupCorr("pcar1.htm");
	 Quiz[10]->WritePcaGroupCorr("pcar2.htm");
	 Quiz[11]->WritePcaGroupCorr("pcar3.htm");
	 Quiz[12]->WritePcaGroupCorr("pcar4.htm");
	 Quiz[13]->WritePcaGroupCorr("pcar5.htm");
	 Quiz[14]->WritePcaGroupCorr("pcar6.htm");
	 Quiz[15]->WritePcaGroupCorr("pcar7.htm");
	 Quiz[16]->WritePcaGroupCorr("pcas1.htm");
	 Quiz[17]->WritePcaGroupCorr("pcas2.htm");
	 Quiz[18]->WritePcaGroupCorr("pcas3.htm");
	 Quiz[19]->WritePcaGroupCorr("pcas4.htm");
	 Quiz[20]->WritePcaGroupCorr("pcas5.htm");

//	 Quiz[19]->WriteLSAS("");

	 Quiz[6]->WriteRefererNtCorrelation("exhnt.htm", "Exhibitionism", "dickflash.com");

	 Quiz[1]->ExportHistogram("all2.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[2]->ExportHistogram("all3.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[3]->ExportHistogram("all4.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[4]->ExportHistogram("all5.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[5]->ExportHistogram("all6.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[6]->ExportHistogram("all7.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[7]->ExportHistogram("all8.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[8]->ExportHistogram("all9.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[9]->ExportHistogram("allr1.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[10]->ExportHistogram("allr2.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[11]->ExportHistogram("allr3.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[12]->ExportHistogram("allr4.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[13]->ExportHistogram("allr5.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[14]->ExportHistogram("allr6.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[15]->ExportHistogram("allr7.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[16]->ExportHistogram("alls1.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[17]->ExportHistogram("alls2.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[18]->ExportHistogram("alls3.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[19]->ExportHistogram("alls4.csv", POP_TYPE_ALL, 2, FALSE);
	 Quiz[20]->ExportHistogram("alls5.csv", POP_TYPE_ALL, 2, FALSE);

	 Quiz[20]->WriteGroupWeighting("group.cpp");

	 Quiz[20]->ExportDiffHistogram("all.csv", POP_TYPE_ALL);

	 Quiz[20]->ExportDiffHistogram("autism.csv", POP_TYPE_AUTISM);
	 Quiz[20]->ExportDiffHistogram("as.csv", POP_TYPE_AS);
	 Quiz[20]->ExportDiffHistogram("nt.csv", POP_TYPE_NT_CONTROL);
	 Quiz[20]->ExportDiffHistogram("soc.csv", POP_TYPE_SOCIAL_PHOBIA);
	 Quiz[20]->ExportDiffHistogram("add.csv", POP_TYPE_ADD);
	 Quiz[20]->ExportDiffHistogram("ts.csv", POP_TYPE_TS);
	 Quiz[20]->ExportDiffHistogram("pa.csv", POP_TYPE_PA);
	 Quiz[20]->ExportDiffHistogram("bip.csv", POP_TYPE_BIPOLAR);
	 Quiz[20]->ExportDiffHistogram("schizo.csv", POP_TYPE_SCHIZOPHRENIA);
	 Quiz[20]->ExportDiffHistogram("syn.csv", POP_TYPE_SYNAESTHESIA);
	 Quiz[20]->ExportDiffHistogram("dysl.csv", POP_TYPE_DYSLEXIA);
	 Quiz[20]->ExportDiffHistogram("dysc.csv", POP_TYPE_DYSCALCULIA);
	 Quiz[20]->ExportDiffHistogram("dysg.csv", POP_TYPE_DYSGRAPHIA);
	 Quiz[20]->ExportDiffHistogram("ocd.csv", POP_TYPE_OCD);
	 Quiz[20]->ExportDiffHistogram("odd.csv", POP_TYPE_ODD);
	 Quiz[20]->ExportDiffHistogram("dysp.csv", POP_TYPE_DYSPRAXIA);

	 TQuiz::ExportBirthMonthHistogram("birth.csv");

	 TQuiz::WriteDsmReport("autism.htm", POP_TYPE_AUTISM);
	 TQuiz::WriteDsmReport("as.htm", POP_TYPE_AS);
	 TQuiz::WriteDsmReport("add.htm", POP_TYPE_ADD);
	 TQuiz::WriteDsmReport("ts.htm", POP_TYPE_TS);
	 TQuiz::WriteDsmReport("dysp.htm", POP_TYPE_DYSPRAXIA);
	 TQuiz::WriteDsmReport("dysl.htm", POP_TYPE_DYSLEXIA);
	 TQuiz::WriteDsmReport("dysc.htm", POP_TYPE_DYSCALCULIA);
	 TQuiz::WriteDsmReport("ocd.htm", POP_TYPE_OCD);
	 TQuiz::WriteDsmReport("odd.htm", POP_TYPE_ODD);
	 TQuiz::WriteDsmReport("pa.htm", POP_TYPE_PA);
	 TQuiz::WriteDsmReport("dysg.htm", POP_TYPE_DYSGRAPHIA);
	 TQuiz::WriteDsmReport("bip.htm", POP_TYPE_BIPOLAR);
	 TQuiz::WriteDsmReport("schizo.htm", POP_TYPE_SCHIZOPHRENIA);
	 TQuiz::WriteDsmReport("social.htm", POP_TYPE_SOCIAL_PHOBIA);

//	 Quiz[18]->WriteWeighting("weights.cpp");
	 Quiz[20]->WritePhpWeighting("weights.php");
	 Quiz[20]->WritePhpGroupWeighting("group.php");

//	 Quiz[9]->MoveWiki("iwiki.txt", "wiki.txt", 0.2);

//	  Quiz[16]->WriteWiki("wiki.txt", 0.2, 0.2);
//	  Quiz[14]->WriteWikiCorrelation("wiki.txt", "maxcorr.htm", 150);
//	  Quiz[14]->WriteWikiNoncorrelated("wiki.txt", "mincorr.htm", 150);

//	  Quiz[19]->WriteQuizWiki("s4.txt");

//	  TQuiz::PrintGlobalCorrelation(258, 81);
//	  TQuiz::PrintGlobalCorrelation(556, 493);


//	 TQuiz::WikiToQuiz("wiki.txt", "s5.txt");

//	 Quiz[7]->WritePhpGlobalQuestions("global.php");

	Quiz[20]->ExportGlobalSql("global.sql");
	Quiz[20]->ExportQuizVerSql("quizver.sql");
	Quiz[20]->ExportGroupSql("group.sql");
	Quiz[20]->ExportPopTypeSql("poptype.sql");
	Quiz[20]->ExportGlobalCorrSql("gcorr.sql");
	Quiz[20]->ExportGlobalAxisSql("gaxis.sql");
}

