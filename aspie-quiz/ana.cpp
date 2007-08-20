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
	 Quiz[17]->CheckCross();

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

	 Quiz[17]->CalcGlobal();

//	 Quiz[17]->WritePhpQuestions("q.php");
//	 Quiz[17]->WriteSetupTexts("q.cpp");
//	 Quiz[17]->WriteSetupCross("c.cpp");

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

	 Quiz[17]->WriteGroupTable("group.htm", TRUE);
	 Quiz[17]->WriteGroupCorrTable("groupcorr.htm");
	 Quiz[17]->WritePcaLoadTable("pcaload.htm");

	 Quiz[17]->WriteAverageGroupCorrTable("avgcorr.htm");
	 Quiz[17]->WriteAveragePcaTable("avgpca.htm");
	 Quiz[17]->WriteAveragePcaCorrTable("avg.htm");

	 Quiz[17]->WritePcaCorrTable("pcacorr.htm");

	 Quiz[17]->WriteLinkReport("index.htm");

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
	 Quiz[8]->WriteBirthMonth("birth9.htm");
	 Quiz[8]->ExportBirthMonthHistogram("birth9.csv");
	 Quiz[8]->WriteParkinson("park9.htm");
	 Quiz[8]->WriteAlzheimer("alz9.htm");
	 Quiz[8]->WriteCFTR("cftr9.htm");
	 Quiz[8]->WriteHFE("hfe9.htm");
	 Quiz[8]->WriteLeiden("leiden9.htm");

	 Quiz[17]->WriteRetest("retests2.htm");

	 Quiz[16]->WritePictureRating("imgrate1.htm");
	 Quiz[17]->WritePictureRating("imgrate2.htm");

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

	 Quiz[17]->WriteGroupWeighting("group.cpp");

	 Quiz[17]->ExportDiffHistogram("all.csv", POP_TYPE_ALL);

	 Quiz[17]->ExportDiffHistogram("autism.csv", POP_TYPE_AUTISM);
	 Quiz[17]->ExportDiffHistogram("as.csv", POP_TYPE_AS);
	 Quiz[17]->ExportDiffHistogram("nt.csv", POP_TYPE_NT_CONTROL);
	 Quiz[17]->ExportDiffHistogram("soc.csv", POP_TYPE_SOCIAL_PHOBIA);
	 Quiz[17]->ExportDiffHistogram("add.csv", POP_TYPE_ADD);
	 Quiz[17]->ExportDiffHistogram("ts.csv", POP_TYPE_TS);
	 Quiz[17]->ExportDiffHistogram("pa.csv", POP_TYPE_PA);
	 Quiz[17]->ExportDiffHistogram("bip.csv", POP_TYPE_BIPOLAR);
	 Quiz[17]->ExportDiffHistogram("schizo.csv", POP_TYPE_SCHIZOPHRENIA);
	 Quiz[17]->ExportDiffHistogram("syn.csv", POP_TYPE_SYNAESTHESIA);
	 Quiz[17]->ExportDiffHistogram("dysl.csv", POP_TYPE_DYSLEXIA);
	 Quiz[17]->ExportDiffHistogram("dysc.csv", POP_TYPE_DYSCALCULIA);
	 Quiz[17]->ExportDiffHistogram("dysg.csv", POP_TYPE_DYSGRAPHIA);
	 Quiz[17]->ExportDiffHistogram("ocd.csv", POP_TYPE_OCD);
	 Quiz[17]->ExportDiffHistogram("odd.csv", POP_TYPE_ODD);
	 Quiz[17]->ExportDiffHistogram("dysp.csv", POP_TYPE_DYSPRAXIA);

	 Quiz[17]->WriteWeighting("weights.cpp");
	 Quiz[17]->WritePhpWeighting("weights.php");
	 Quiz[17]->WritePhpGroupWeighting("group.php");


//	 Quiz[9]->MoveWiki("iwiki.txt", "wiki.txt", 0.2);

//	  Quiz[16]->WriteWiki("wiki.txt", 0.2, 0.2);
//	  Quiz[14]->WriteWikiCorrelation("wiki.txt", "maxcorr.htm", 150);
//	  Quiz[14]->WriteWikiNoncorrelated("wiki.txt", "mincorr.htm", 150);

//	  Quiz[16]->WriteQuizWiki("s2.txt");

//	  TQuiz::PrintGlobalCorrelation(258, 81);
//	  TQuiz::PrintGlobalCorrelation(556, 493);


	 TQuiz::WikiToQuiz("wiki.txt", "s2.txt");

//	 Quiz[7]->WritePhpGlobalQuestions("global.php");
}

