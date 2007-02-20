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
#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1

#define FALSE 0
#define TRUE !FALSE

TQuiz *Quiz[15];

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

//	Quiz[9]->WritePhpQuestions("q.php");
//	Quiz[9]->WriteSetupTexts("q.cpp");
//	Quiz[9]->WriteSetupCross("c.cpp");

//  Quiz[0]->CheckCross();
//	Quiz[1]->CheckCross();
//	Quiz[2]->CheckCross();
//	Quiz[3]->CheckCross();
//	Quiz[4]->CheckCross();
//	Quiz[5]->CheckCross();
//	Quiz[6]->CheckCross();
//  Quiz[7]->CheckCross();
//	Quiz[8]->CheckCross();
	Quiz[9]->CheckCross();

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

	 Quiz[9]->WriteGroupTable("group.htm", TRUE);
	 Quiz[9]->WriteGroupCorrTable("groupcorr.htm");
	 Quiz[9]->WritePcaLoadTable("pcaload.htm");

	 Quiz[9]->WriteAverageGroupCorrTable("avgcorr.htm");
	 Quiz[9]->WriteAveragePcaTable("avgpca.htm");
	 Quiz[9]->WriteAveragePcaCorrTable("avg.htm");

	 Quiz[9]->WritePcaCorrTable("pcacorr.htm");

	 Quiz[9]->WriteLinkReport("index.htm");

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

	 Quiz[6]->WriteRefererNtCorrelation("exhnt.htm", "Exhibitionism", "dickflash.com");

	 Quiz[7]->ExportHistogram("all8.csv", POP_TYPE_ALL, 2, TRUE);
	 Quiz[8]->ExportHistogram("all9.csv", POP_TYPE_ALL, 2, TRUE);

	 Quiz[8]->WriteWeighting("weights.cpp");
	 Quiz[8]->WritePhpWeighting("weights.php");
	 Quiz[8]->WritePhpGroupWeighting("group.php");

//	 Quiz[9]->MoveWiki("iwiki.txt", "wiki.txt", 0.2);

//     Quiz[9]->WriteGlobalCorrelation("maxcorr.htm", 25);
     Quiz[9]->WriteWikiCorrelation("wiki.txt", "maxcorr.htm", 25);
     Quiz[9]->WriteWikiNoncorrelated("wiki.txt", "mincorr.htm", 25);

//	 Quiz[7]->WritePhpGlobalQuestions("global.php");
}

