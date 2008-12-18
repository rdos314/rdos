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

// #define EXPORT	1
// #define ALL		1
// #define CONV		1

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
#include "quizs11.h"
#include "quizs12.h"
#include "quizn1.h"
#include "quizn2.h"
#include "quizn3.h"
#include "quizn4.h"
#include "quizfi.h"
#include "quizf1.h"
#include "quizf2.h"
#include "quizf3.h"
#include "quizf4.h"
#include "quizdba.h"

#include "pop.h"

//#define SWEDISH     1
#define ENGLISH       1

#define ANCESTRY_CAUCASIAN      1
#define ANCESTRY_ASIAN          2
#define ANCESTRY_AMERIND        3
#define ANCESTRY_AFRICAN        4
#define ANCESTRY_ARAB           5
#define ANCESTRY_AUSTRALIAN     6
#define ANCESTRY_SWEDEN			  7
#define ANCESTRY_PORTUGAL		  8
#define ANCESTRY_NORWAY			  9
#define ANCESTRY_GERMANY		  10


#define FALSE 0
#define TRUE !FALSE

TQuiz *Quiz[40];


/*##################  ExportAncestry ##########################
*   Purpose....: Export ancestry to PCA 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ExportAncestry(const char *filename, int Ancestry)
{
	TQuizAncestryRow Row;
	int i;
	int v;
	int ival;
	char str[80];
	int use;
	TFile *infile;
	TFile outfile(filename, 0);

	outfile.Write("\"\", ");
	outfile.Write("\"\", ");

	for (i = 0; i < 145; i++)
	{
		outfile.Write("\"");

		sprintf(str, "#%d", i + 1);
		outfile.Write(str);

		outfile.Write("\"");
		if (i != 144)
			outfile.Write(", ");
	}
	outfile.Write("\n");

	 for (v = 0; v < 5; v++)
    {
        switch (v)
        {
            case 0:
                infile = new TFile("ancf1.bin");
                break;

            case 1:
                infile = new TFile("ancf2.bin");
                break;

            case 2:
                infile = new TFile("ancf3.bin");
                break;

            case 3:
                infile = new TFile("ancf4.bin");
                break;

            case 4:
                infile = new TFile("ancfi.bin");
                break;
		  }

		while (infile->Read(&Row, sizeof(Row)))
		{
			 use = FALSE;
			 switch (Ancestry)
			 {
				  case ANCESTRY_CAUCASIAN:
					 if ((Row.Ancestry >= 2000 && Row.Ancestry < 3000) || Row.Ancestry == 3205)
						 use = TRUE;
						 break;

					case ANCESTRY_ASIAN:
						if (Row.Ancestry >= 4000)
								use = TRUE;
						  break;

					case ANCESTRY_AMERIND:
						if (Row.Ancestry == 3 || Row.Ancestry == 4)
								use = TRUE;
						  break;

					case ANCESTRY_AFRICAN:
						if ((Row.Ancestry >= 1000 && Row.Ancestry < 2000) || Row.Ancestry == 5)
								use = TRUE;
						  break;

					case ANCESTRY_ARAB:
						if (Row.Ancestry >= 3000 && Row.Ancestry < 4000 && Row.Ancestry != 3205)
							use = TRUE;
							break;

					case ANCESTRY_AUSTRALIAN:
						if (Row.Ancestry == 1)
							use = TRUE;
							break;

					case ANCESTRY_SWEDEN:
						if (Row.Lang == 1)
							use = TRUE;
						break;

					case ANCESTRY_NORWAY:
						if (Row.Lang == 2)
							use = TRUE;
						break;

					case ANCESTRY_PORTUGAL:
						if (Row.Lang == 3)
							use = TRUE;
						break;

					case ANCESTRY_GERMANY:
						if (Row.Lang == 4)
							use = TRUE;
						break;
				}

				if (use)
				{
					sprintf(str, "\"%d\", ", Row.AsResult);
				outfile.Write(str);

		    	sprintf(str, "\"%d\", ", Row.NtResult);
			    outfile.Write(str);

    			for (i = 0; i < 145; i++)
	    		{
    	    		ival = Row.Quiz[i];
	    	    	if (ival)
				    	ival--;
    
    				if (ival > 2)
	    				ival = 0;
                    
		    		sprintf(str, "\"%d\"", ival);
			    	outfile.Write(str);
				    if (i != 144)
					    outfile.Write(", ");
    			}
	    		outfile.Write("\n");
	    	}
		}
		delete infile;
	}
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
	char str[80];
	int g;

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
	Quiz[26] = new TQuizS11("quizs11.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25]);
	Quiz[27] = new TQuizS12("quizs12.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26]);
	Quiz[28] = new TQuizN1("quizn1.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27]);
	Quiz[29] = new TQuizN2("quizn2.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28]);
	Quiz[30] = new TQuizN3("quizn3.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28], Quiz[29]);
	Quiz[31] = new TQuizN4("quizn4.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28], Quiz[29], Quiz[30]);
	Quiz[32] = new TQuizFI("quizfi.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28], Quiz[29], Quiz[30], Quiz[31]);
	Quiz[33] = new TQuizF1("quizf1.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28], Quiz[29], Quiz[30], Quiz[31], Quiz[32]);
	Quiz[34] = new TQuizF2("quizf2.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28], Quiz[29], Quiz[30], Quiz[31], Quiz[32], Quiz[33]);
	Quiz[35] = new TQuizF3("quizf3.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28], Quiz[29], Quiz[30], Quiz[31], Quiz[32], Quiz[33], Quiz[34]);
	Quiz[36] = new TQuizF4("quizf4.bin", Quiz[0], Quiz[1], Quiz[2], Quiz[3], Quiz[4], Quiz[5], Quiz[6], Quiz[7], Quiz[8], Quiz[9], Quiz[10], Quiz[11], Quiz[12], Quiz[13], Quiz[14], Quiz[15], Quiz[16], Quiz[17], Quiz[18], Quiz[19], Quiz[20], Quiz[21], Quiz[22], Quiz[23], Quiz[24], Quiz[25], Quiz[26], Quiz[27], Quiz[28], Quiz[29], Quiz[30], Quiz[31], Quiz[32], Quiz[33], Quiz[34], Quiz[35]);

	Quiz[36]->WriteOldQuestionCount("vercnt.txt", 145);
	Quiz[36]->WriteReverseQuestionCount("revcnt.txt");
	Quiz[36]->WriteNoAnswerStats("noans.txt");

	Quiz[36]->WritePartner("eval\\partner.htm");

	 ExportAncestry("pca\\cauc.dat", ANCESTRY_CAUCASIAN);
	 ExportAncestry("pca\\asian.dat", ANCESTRY_ASIAN);
	 ExportAncestry("pca\\amerind.dat", ANCESTRY_AMERIND);
	 ExportAncestry("pca\\african.dat", ANCESTRY_AFRICAN);
	 ExportAncestry("pca\\arab.dat", ANCESTRY_ARAB);
	 ExportAncestry("pca\\austral.dat", ANCESTRY_AUSTRALIAN);
	 ExportAncestry("pca\\sw.dat", ANCESTRY_SWEDEN);
	 ExportAncestry("pca\\no.dat", ANCESTRY_NORWAY);
	 ExportAncestry("pca\\br.dat", ANCESTRY_PORTUGAL);
	 ExportAncestry("pca\\de.dat", ANCESTRY_GERMANY);

#ifdef ALL
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
//	 Quiz[25]->CheckCross();
//	 Quiz[26]->CheckCross();
//	 Quiz[27]->CheckCross();
//	 Quiz[28]->CheckCross();
//	 Quiz[29]->CheckCross();
//	 Quiz[30]->CheckCross();
//	 Quiz[31]->CheckCross();
//	 Quiz[32]->CheckCross();
	 Quiz[33]->CheckCross();

	printf("all1\r\n");
	Quiz[0]->ExportExcelCase("pca\\all1.dat", PCA_TYPE_ALL);
	Quiz[0]->ExportExcelCase("pca\\male1.dat", PCA_TYPE_MALE);
	Quiz[0]->ExportExcelCase("pca\\female1.dat", PCA_TYPE_FEMALE);

	printf("all2\r\n");
	Quiz[1]->ExportExcelCase("pca\\all2.dat", PCA_TYPE_ALL);
	Quiz[1]->ExportExcelCase("pca\\male2.dat", PCA_TYPE_MALE);
	Quiz[1]->ExportExcelCase("pca\\female2.dat", PCA_TYPE_FEMALE);
	Quiz[1]->ExportExcelCase("pca\\young2.dat", PCA_TYPE_YOUNG);
	Quiz[1]->ExportExcelCase("pca\\old2.dat", PCA_TYPE_OLD);

	printf("all3\r\n");
	 Quiz[2]->ExportExcelCase("pca\\all3.dat", PCA_TYPE_ALL);
	 Quiz[2]->ExportExcelCase("pca\\male3.dat", PCA_TYPE_MALE);
	 Quiz[2]->ExportExcelCase("pca\\female3.dat", PCA_TYPE_FEMALE);
	Quiz[2]->ExportExcelCase("pca\\young3.dat", PCA_TYPE_YOUNG);
	Quiz[2]->ExportExcelCase("pca\\old3.dat", PCA_TYPE_OLD);

	printf("all4\r\n");
	 Quiz[3]->ExportExcelCase("pca\\all4.dat", PCA_TYPE_ALL);
	 Quiz[3]->ExportExcelCase("pca\\male4.dat", PCA_TYPE_MALE);
	 Quiz[3]->ExportExcelCase("pca\\female4.dat", PCA_TYPE_FEMALE);
	Quiz[3]->ExportExcelCase("pca\\young4.dat", PCA_TYPE_YOUNG);
	Quiz[3]->ExportExcelCase("pca\\old4.dat", PCA_TYPE_OLD);

	printf("all5\r\n");
	 Quiz[4]->ExportExcelCase("pca\\all5.dat", PCA_TYPE_ALL);
	 Quiz[4]->ExportExcelCase("pca\\male5.dat", PCA_TYPE_MALE);
	 Quiz[4]->ExportExcelCase("pca\\female5.dat", PCA_TYPE_FEMALE);
	Quiz[4]->ExportExcelCase("pca\\young5.dat", PCA_TYPE_YOUNG);
	Quiz[4]->ExportExcelCase("pca\\old5.dat", PCA_TYPE_OLD);

	printf("all6\r\n");
	 Quiz[5]->ExportExcelCase("pca\\all6.dat", PCA_TYPE_ALL);
	 Quiz[5]->ExportExcelCase("pca\\male6.dat", PCA_TYPE_MALE);
	 Quiz[5]->ExportExcelCase("pca\\female6.dat", PCA_TYPE_FEMALE);
	Quiz[5]->ExportExcelCase("pca\\young6.dat", PCA_TYPE_YOUNG);
	Quiz[5]->ExportExcelCase("pca\\old6.dat", PCA_TYPE_OLD);

	printf("all7\r\n");
	 Quiz[6]->ExportExcelCase("pca\\all7.dat", PCA_TYPE_ALL);
	 Quiz[6]->ExportExcelCase("pca\\male7.dat", PCA_TYPE_MALE);
	 Quiz[6]->ExportExcelCase("pca\\female7.dat", PCA_TYPE_FEMALE);
	Quiz[6]->ExportExcelCase("pca\\young7.dat", PCA_TYPE_YOUNG);
	Quiz[6]->ExportExcelCase("pca\\old7.dat", PCA_TYPE_OLD);

	printf("all8\r\n");
	 Quiz[7]->ExportExcelCase("pca\\all8.dat", PCA_TYPE_ALL);
	 Quiz[7]->ExportExcelCase("pca\\male8.dat", PCA_TYPE_MALE);
	 Quiz[7]->ExportExcelCase("pca\\female8.dat", PCA_TYPE_FEMALE);
	Quiz[7]->ExportExcelCase("pca\\young8.dat", PCA_TYPE_YOUNG);
	Quiz[7]->ExportExcelCase("pca\\old8.dat", PCA_TYPE_OLD);

	printf("all9\r\n");
	 Quiz[8]->ExportExcelCase("pca\\all9.dat", PCA_TYPE_ALL);
	 Quiz[8]->ExportExcelCase("pca\\male9.dat", PCA_TYPE_MALE);
	 Quiz[8]->ExportExcelCase("pca\\female9.dat", PCA_TYPE_FEMALE);
	Quiz[8]->ExportExcelCase("pca\\young9.dat", PCA_TYPE_YOUNG);
	Quiz[8]->ExportExcelCase("pca\\old9.dat", PCA_TYPE_OLD);

	printf("allr1\r\n");
	 Quiz[9]->ExportExcelCase("pca\\allr1.dat", PCA_TYPE_ALL);
	 Quiz[9]->ExportExcelCase("pca\\maler1.dat", PCA_TYPE_MALE);
	 Quiz[9]->ExportExcelCase("pca\\femaler1.dat", PCA_TYPE_FEMALE);
	Quiz[9]->ExportExcelCase("pca\\youngr1.dat", PCA_TYPE_YOUNG);
	Quiz[9]->ExportExcelCase("pca\\oldr1.dat", PCA_TYPE_OLD);

	printf("allr2\r\n");
	 Quiz[10]->ExportExcelCase("pca\\allr2.dat", PCA_TYPE_ALL);
	 Quiz[10]->ExportExcelCase("pca\\maler2.dat", PCA_TYPE_MALE);
	 Quiz[10]->ExportExcelCase("pca\\femaler2.dat", PCA_TYPE_FEMALE);
	Quiz[10]->ExportExcelCase("pca\\youngr2.dat", PCA_TYPE_YOUNG);
	Quiz[10]->ExportExcelCase("pca\\oldr2.dat", PCA_TYPE_OLD);

	printf("allr3\r\n");
	 Quiz[11]->ExportExcelCase("pca\\allr3.dat", PCA_TYPE_ALL);
	 Quiz[11]->ExportExcelCase("pca\\maler3.dat", PCA_TYPE_MALE);
	 Quiz[11]->ExportExcelCase("pca\\femaler3.dat", PCA_TYPE_FEMALE);
	Quiz[11]->ExportExcelCase("pca\\youngr3.dat", PCA_TYPE_YOUNG);
	Quiz[11]->ExportExcelCase("pca\\oldr3.dat", PCA_TYPE_OLD);

	printf("allr4\r\n");
	 Quiz[12]->ExportExcelCase("pca\\allr4.dat", PCA_TYPE_ALL);
	 Quiz[12]->ExportExcelCase("pca\\maler4.dat", PCA_TYPE_MALE);
	 Quiz[12]->ExportExcelCase("pca\\femaler4.dat", PCA_TYPE_FEMALE);
	Quiz[12]->ExportExcelCase("pca\\youngr4.dat", PCA_TYPE_YOUNG);
	Quiz[12]->ExportExcelCase("pca\\oldr4.dat", PCA_TYPE_OLD);

	printf("allr5\r\n");
	 Quiz[13]->ExportExcelCase("pca\\allr5.dat", PCA_TYPE_ALL);
	 Quiz[13]->ExportExcelCase("pca\\maler5.dat", PCA_TYPE_MALE);
	 Quiz[13]->ExportExcelCase("pca\\femaler5.dat", PCA_TYPE_FEMALE);
	Quiz[13]->ExportExcelCase("pca\\youngr5.dat", PCA_TYPE_YOUNG);
	Quiz[13]->ExportExcelCase("pca\\oldr5.dat", PCA_TYPE_OLD);

	printf("allr6\r\n");
	 Quiz[14]->ExportExcelCase("pca\\allr6.dat", PCA_TYPE_ALL);
	 Quiz[14]->ExportExcelCase("pca\\maler6.dat", PCA_TYPE_MALE);
	 Quiz[14]->ExportExcelCase("pca\\femaler6.dat", PCA_TYPE_FEMALE);
	Quiz[14]->ExportExcelCase("pca\\youngr6.dat", PCA_TYPE_YOUNG);
	Quiz[14]->ExportExcelCase("pca\\oldr6.dat", PCA_TYPE_OLD);

	printf("allr7\r\n");
	 Quiz[15]->ExportExcelCase("pca\\allr7.dat", PCA_TYPE_ALL);
	 Quiz[15]->ExportExcelCase("pca\\maler7.dat", PCA_TYPE_MALE);
	 Quiz[15]->ExportExcelCase("pca\\femaler7.dat", PCA_TYPE_FEMALE);
	Quiz[15]->ExportExcelCase("pca\\youngr7.dat", PCA_TYPE_YOUNG);
	Quiz[15]->ExportExcelCase("pca\\oldr7.dat", PCA_TYPE_OLD);

	printf("alls1\r\n");
	 Quiz[16]->ExportExcelCase("pca\\alls1.dat", PCA_TYPE_ALL);
	 Quiz[16]->ExportExcelCase("pca\\males1.dat", PCA_TYPE_MALE);
	 Quiz[16]->ExportExcelCase("pca\\females1.dat", PCA_TYPE_FEMALE);
	Quiz[16]->ExportExcelCase("pca\\youngs1.dat", PCA_TYPE_YOUNG);
	Quiz[16]->ExportExcelCase("pca\\olds1.dat", PCA_TYPE_OLD);

	printf("alls2\r\n");
	 Quiz[17]->ExportExcelCase("pca\\alls2.dat", PCA_TYPE_ALL);
	 Quiz[17]->ExportExcelCase("pca\\males2.dat", PCA_TYPE_MALE);
	 Quiz[17]->ExportExcelCase("pca\\females2.dat", PCA_TYPE_FEMALE);
	Quiz[17]->ExportExcelCase("pca\\youngs2.dat", PCA_TYPE_YOUNG);
	Quiz[17]->ExportExcelCase("pca\\olds2.dat", PCA_TYPE_OLD);

	printf("alls3\r\n");
	 Quiz[18]->ExportExcelCase("pca\\alls3.dat", PCA_TYPE_ALL);
	 Quiz[18]->ExportExcelCase("pca\\males3.dat", PCA_TYPE_MALE);
	 Quiz[18]->ExportExcelCase("pca\\females3.dat", PCA_TYPE_FEMALE);
	Quiz[18]->ExportExcelCase("pca\\youngs3.dat", PCA_TYPE_YOUNG);
	Quiz[18]->ExportExcelCase("pca\\olds3.dat", PCA_TYPE_OLD);

	printf("alls4\r\n");
	 Quiz[19]->ExportExcelCase("pca\\alls4.dat", PCA_TYPE_ALL);
	 Quiz[19]->ExportExcelCase("pca\\males4.dat", PCA_TYPE_MALE);
	 Quiz[19]->ExportExcelCase("pca\\females4.dat", PCA_TYPE_FEMALE);
	Quiz[19]->ExportExcelCase("pca\\youngs4.dat", PCA_TYPE_YOUNG);
	Quiz[19]->ExportExcelCase("pca\\olds4.dat", PCA_TYPE_OLD);

	printf("alls5\r\n");
	 Quiz[20]->ExportExcelCase("pca\\alls5.dat", PCA_TYPE_ALL);
	 Quiz[20]->ExportExcelCase("pca\\males5.dat", PCA_TYPE_MALE);
	 Quiz[20]->ExportExcelCase("pca\\females5.dat", PCA_TYPE_FEMALE);
	Quiz[20]->ExportExcelCase("pca\\youngs5.dat", PCA_TYPE_YOUNG);
	Quiz[20]->ExportExcelCase("pca\\olds5.dat", PCA_TYPE_OLD);

	printf("alls6\r\n");
	 Quiz[21]->ExportExcelCase("pca\\alls6.dat", PCA_TYPE_ALL);
	 Quiz[21]->ExportExcelCase("pca\\males6.dat", PCA_TYPE_MALE);
	 Quiz[21]->ExportExcelCase("pca\\females6.dat", PCA_TYPE_FEMALE);
	Quiz[21]->ExportExcelCase("pca\\youngs6.dat", PCA_TYPE_YOUNG);
	Quiz[21]->ExportExcelCase("pca\\olds6.dat", PCA_TYPE_OLD);

	printf("alls7\r\n");
	 Quiz[22]->ExportExcelCase("pca\\alls7.dat", PCA_TYPE_ALL);
	 Quiz[22]->ExportExcelCase("pca\\males7.dat", PCA_TYPE_MALE);
	 Quiz[22]->ExportExcelCase("pca\\females7.dat", PCA_TYPE_FEMALE);
	Quiz[22]->ExportExcelCase("pca\\youngs7.dat", PCA_TYPE_YOUNG);
	Quiz[22]->ExportExcelCase("pca\\olds7.dat", PCA_TYPE_OLD);

	printf("alls8\r\n");
	 Quiz[23]->ExportExcelCase("pca\\alls8.dat", PCA_TYPE_ALL);
	 Quiz[23]->ExportExcelCase("pca\\males8.dat", PCA_TYPE_MALE);
	 Quiz[23]->ExportExcelCase("pca\\females8.dat", PCA_TYPE_FEMALE);
	Quiz[23]->ExportExcelCase("pca\\youngs8.dat", PCA_TYPE_YOUNG);
	Quiz[23]->ExportExcelCase("pca\\olds8.dat", PCA_TYPE_OLD);

	printf("alls9\r\n");
	 Quiz[24]->ExportExcelCase("pca\\alls9.dat", PCA_TYPE_ALL);
	 Quiz[24]->ExportExcelCase("pca\\males9.dat", PCA_TYPE_MALE);
	 Quiz[24]->ExportExcelCase("pca\\females9.dat", PCA_TYPE_FEMALE);
	Quiz[24]->ExportExcelCase("pca\\youngs9.dat", PCA_TYPE_YOUNG);
	Quiz[24]->ExportExcelCase("pca\\olds9.dat", PCA_TYPE_OLD);

	printf("alls10\r\n");
	 Quiz[25]->ExportExcelCase("pca\\alls10.dat", PCA_TYPE_ALL);
	 Quiz[25]->ExportExcelCase("pca\\males10.dat", PCA_TYPE_MALE);
	 Quiz[25]->ExportExcelCase("pca\\fems10.dat", PCA_TYPE_FEMALE);
	Quiz[25]->ExportExcelCase("pca\\youngs10.dat", PCA_TYPE_YOUNG);
	Quiz[25]->ExportExcelCase("pca\\olds10.dat", PCA_TYPE_OLD);

	printf("alls11\r\n");
	 Quiz[26]->ExportExcelCase("pca\\alls11.dat", PCA_TYPE_ALL);
	 Quiz[26]->ExportExcelCase("pca\\males11.dat", PCA_TYPE_MALE);
	 Quiz[26]->ExportExcelCase("pca\\fems11.dat", PCA_TYPE_FEMALE);
	Quiz[26]->ExportExcelCase("pca\\youngs11.dat", PCA_TYPE_YOUNG);
	Quiz[26]->ExportExcelCase("pca\\olds11.dat", PCA_TYPE_OLD);

	printf("alls12\r\n");
	 Quiz[27]->ExportExcelCase("pca\\alls12.dat", PCA_TYPE_ALL);
	 Quiz[27]->ExportExcelCase("pca\\males12.dat", PCA_TYPE_MALE);
	 Quiz[27]->ExportExcelCase("pca\\fems12.dat", PCA_TYPE_FEMALE);
	Quiz[27]->ExportExcelCase("pca\\youngs12.dat", PCA_TYPE_YOUNG);
	Quiz[27]->ExportExcelCase("pca\\olds12.dat", PCA_TYPE_OLD);

	printf("alln1\r\n");
	 Quiz[28]->ExportExcelCase("pca\\alln1.dat", PCA_TYPE_ALL);
	 Quiz[28]->ExportExcelCase("pca\\malen1.dat", PCA_TYPE_MALE);
	 Quiz[28]->ExportExcelCase("pca\\femalen1.dat", PCA_TYPE_FEMALE);
	Quiz[28]->ExportExcelCase("pca\\youngn1.dat", PCA_TYPE_YOUNG);
	Quiz[28]->ExportExcelCase("pca\\oldn1.dat", PCA_TYPE_OLD);

	printf("alln2\r\n");
	 Quiz[29]->ExportExcelCase("pca\\alln2.dat", PCA_TYPE_ALL);
	 Quiz[29]->ExportExcelCase("pca\\malen2.dat", PCA_TYPE_MALE);
	 Quiz[29]->ExportExcelCase("pca\\femalen2.dat", PCA_TYPE_FEMALE);
	Quiz[29]->ExportExcelCase("pca\\youngn2.dat", PCA_TYPE_YOUNG);
	Quiz[29]->ExportExcelCase("pca\\oldn2.dat", PCA_TYPE_OLD);

	printf("alln3\r\n");
	 Quiz[30]->ExportExcelCase("pca\\alln3.dat", PCA_TYPE_ALL);
	 Quiz[30]->ExportExcelCase("pca\\malen3.dat", PCA_TYPE_MALE);
	 Quiz[30]->ExportExcelCase("pca\\femalen3.dat", PCA_TYPE_FEMALE);
	Quiz[30]->ExportExcelCase("pca\\youngn3.dat", PCA_TYPE_YOUNG);
	Quiz[30]->ExportExcelCase("pca\\oldn3.dat", PCA_TYPE_OLD);

	printf("alln4\r\n");
	 Quiz[31]->ExportExcelCase("pca\\alln4.dat", PCA_TYPE_ALL);
	 Quiz[31]->ExportExcelCase("pca\\malen4.dat", PCA_TYPE_MALE);
	 Quiz[31]->ExportExcelCase("pca\\femalen4.dat", PCA_TYPE_FEMALE);
	Quiz[31]->ExportExcelCase("pca\\youngn4.dat", PCA_TYPE_YOUNG);
	Quiz[31]->ExportExcelCase("pca\\oldn4.dat", PCA_TYPE_OLD);


#endif

	printf("allfi\r\n");
	 Quiz[32]->ExportExcelCase("pca\\allfi.dat", PCA_TYPE_ALL);
	 Quiz[32]->ExportExcelCase("pca\\malefi.dat", PCA_TYPE_MALE);
	 Quiz[32]->ExportExcelCase("pca\\femalefi.dat", PCA_TYPE_FEMALE);
	Quiz[32]->ExportExcelCase("pca\\youngfi.dat", PCA_TYPE_YOUNG);
	Quiz[32]->ExportExcelCase("pca\\oldfi.dat", PCA_TYPE_OLD);

	printf("allf1\r\n");
	 Quiz[33]->ExportExcelCase("pca\\allf1.dat", PCA_TYPE_ALL);
	 Quiz[33]->ExportExcelCase("pca\\malef1.dat", PCA_TYPE_MALE);
	 Quiz[33]->ExportExcelCase("pca\\femalef1.dat", PCA_TYPE_FEMALE);
	Quiz[33]->ExportExcelCase("pca\\youngf1.dat", PCA_TYPE_YOUNG);
	Quiz[33]->ExportExcelCase("pca\\oldf1.dat", PCA_TYPE_OLD);

	printf("allf2\r\n");
	 Quiz[34]->ExportExcelCase("pca\\allf2.dat", PCA_TYPE_ALL);
	 Quiz[34]->ExportExcelCase("pca\\malef2.dat", PCA_TYPE_MALE);
	 Quiz[34]->ExportExcelCase("pca\\femalef2.dat", PCA_TYPE_FEMALE);
	Quiz[34]->ExportExcelCase("pca\\youngf2.dat", PCA_TYPE_YOUNG);
	Quiz[34]->ExportExcelCase("pca\\oldf2.dat", PCA_TYPE_OLD);

	printf("allf3\r\n");
	 Quiz[35]->ExportExcelCase("pca\\allf3.dat", PCA_TYPE_ALL);
	 Quiz[35]->ExportExcelCase("pca\\malef3.dat", PCA_TYPE_MALE);
	 Quiz[35]->ExportExcelCase("pca\\femalef3.dat", PCA_TYPE_FEMALE);
	Quiz[35]->ExportExcelCase("pca\\youngf3.dat", PCA_TYPE_YOUNG);
	Quiz[35]->ExportExcelCase("pca\\oldf3.dat", PCA_TYPE_OLD);

	printf("allf4\r\n");
	 Quiz[36]->ExportExcelCase("pca\\allf4.dat", PCA_TYPE_ALL);
	 Quiz[36]->ExportExcelCase("pca\\malef4.dat", PCA_TYPE_MALE);
	 Quiz[36]->ExportExcelCase("pca\\femalef4.dat", PCA_TYPE_FEMALE);
	Quiz[36]->ExportExcelCase("pca\\youngf4.dat", PCA_TYPE_YOUNG);
	Quiz[36]->ExportExcelCase("pca\\oldf4.dat", PCA_TYPE_OLD);


	printf("aspie\r\n");

#ifdef EXPORT
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
	 Quiz[26]->ExportExcelAspie("pca\\aspies11.dat");
	 Quiz[27]->ExportExcelAspie("pca\\aspies12.dat");
	 Quiz[28]->ExportExcelAspie("pca\\aspien1.dat");
	 Quiz[29]->ExportExcelAspie("pca\\aspien2.dat");
	 Quiz[30]->ExportExcelAspie("pca\\aspien3.dat");
	 Quiz[31]->ExportExcelAspie("pca\\aspien4.dat");
#endif

	 Quiz[32]->ExportExcelAspie("pca\\aspiefi.dat");
	 Quiz[33]->ExportExcelAspie("pca\\aspief1.dat");
	 Quiz[34]->ExportExcelAspie("pca\\aspief2.dat");
	 Quiz[35]->ExportExcelAspie("pca\\aspief3.dat");
	 Quiz[36]->ExportExcelAspie("pca\\aspief4.dat");

	printf("import\r\n");
	 Quiz[0]->ImportMvsp("pca\\all1.txt", PCA_TYPE_ALL);

	 Quiz[1]->ImportMvsp("pca\\all2.txt", PCA_TYPE_ALL);
	 Quiz[1]->ImportMvsp("pca\\male2.txt", PCA_TYPE_MALE);
	 Quiz[1]->ImportMvsp("pca\\female2.txt", PCA_TYPE_FEMALE);
	 Quiz[1]->ImportMvsp("pca\\old2.txt", PCA_TYPE_OLD);
	 Quiz[1]->ImportMvsp("pca\\young2.txt", PCA_TYPE_YOUNG);

	 Quiz[2]->ImportMvsp("pca\\all3.txt", PCA_TYPE_ALL);
	 Quiz[2]->ImportMvsp("pca\\male3.txt", PCA_TYPE_MALE);
	 Quiz[2]->ImportMvsp("pca\\female3.txt", PCA_TYPE_FEMALE);
	 Quiz[2]->ImportMvsp("pca\\old3.txt", PCA_TYPE_OLD);
	 Quiz[2]->ImportMvsp("pca\\young3.txt", PCA_TYPE_YOUNG);

	 Quiz[3]->ImportMvsp("pca\\all4.txt", PCA_TYPE_ALL);
	 Quiz[3]->ImportMvsp("pca\\male4.txt", PCA_TYPE_MALE);
	 Quiz[3]->ImportMvsp("pca\\female4.txt", PCA_TYPE_FEMALE);
	 Quiz[3]->ImportMvsp("pca\\old4.txt", PCA_TYPE_OLD);
	 Quiz[3]->ImportMvsp("pca\\young4.txt", PCA_TYPE_YOUNG);

	 Quiz[4]->ImportMvsp("pca\\all5.txt", PCA_TYPE_ALL);
	 Quiz[4]->ImportMvsp("pca\\male5.txt", PCA_TYPE_MALE);
	 Quiz[4]->ImportMvsp("pca\\female5.txt", PCA_TYPE_FEMALE);
	 Quiz[4]->ImportMvsp("pca\\old5.txt", PCA_TYPE_OLD);
	 Quiz[4]->ImportMvsp("pca\\young5.txt", PCA_TYPE_YOUNG);

	 Quiz[5]->ImportMvsp("pca\\all6.txt", PCA_TYPE_ALL);
	 Quiz[5]->ImportMvsp("pca\\male6.txt", PCA_TYPE_MALE);
	 Quiz[5]->ImportMvsp("pca\\female6.txt", PCA_TYPE_FEMALE);
	 Quiz[5]->ImportMvsp("pca\\old6.txt", PCA_TYPE_OLD);
	 Quiz[5]->ImportMvsp("pca\\young6.txt", PCA_TYPE_YOUNG);
	 Quiz[5]->ImportMvsp("pca\\asia6.txt", PCA_TYPE_ASIA);

	 Quiz[6]->ImportMvsp("pca\\all7.txt", PCA_TYPE_ALL);
	 Quiz[6]->ImportMvsp("pca\\male7.txt", PCA_TYPE_MALE);
	 Quiz[6]->ImportMvsp("pca\\female7.txt", PCA_TYPE_FEMALE);
	 Quiz[6]->ImportMvsp("pca\\old7.txt", PCA_TYPE_OLD);
	 Quiz[6]->ImportMvsp("pca\\young7.txt", PCA_TYPE_YOUNG);
	 Quiz[6]->ImportMvsp("pca\\asia7.txt", PCA_TYPE_ASIA);

	 Quiz[7]->ImportMvsp("pca\\all8.txt", PCA_TYPE_ALL);
	 Quiz[7]->ImportMvsp("pca\\male8.txt", PCA_TYPE_MALE);
	 Quiz[7]->ImportMvsp("pca\\female8.txt", PCA_TYPE_FEMALE);
	 Quiz[7]->ImportMvsp("pca\\old8.txt", PCA_TYPE_OLD);
	 Quiz[7]->ImportMvsp("pca\\young8.txt", PCA_TYPE_YOUNG);

	 Quiz[8]->ImportMvsp("pca\\all9.txt", PCA_TYPE_ALL);
	 Quiz[8]->ImportMvsp("pca\\male9.txt", PCA_TYPE_MALE);
	 Quiz[8]->ImportMvsp("pca\\female9.txt", PCA_TYPE_FEMALE);
	 Quiz[8]->ImportMvsp("pca\\old9.txt", PCA_TYPE_OLD);
	 Quiz[8]->ImportMvsp("pca\\young9.txt", PCA_TYPE_YOUNG);

	 Quiz[9]->ImportMvsp("pca\\allr1.txt", PCA_TYPE_ALL);
	 Quiz[9]->ImportMvsp("pca\\maler1.txt", PCA_TYPE_MALE);
	 Quiz[9]->ImportMvsp("pca\\femaler1.txt", PCA_TYPE_FEMALE);
	 Quiz[9]->ImportMvsp("pca\\oldr1.txt", PCA_TYPE_OLD);
	 Quiz[9]->ImportMvsp("pca\\youngr1.txt", PCA_TYPE_YOUNG);

	 Quiz[10]->ImportMvsp("pca\\allr2.txt", PCA_TYPE_ALL);
	 Quiz[10]->ImportMvsp("pca\\maler2.txt", PCA_TYPE_MALE);
	 Quiz[10]->ImportMvsp("pca\\femaler2.txt", PCA_TYPE_FEMALE);
	 Quiz[10]->ImportMvsp("pca\\oldr2.txt", PCA_TYPE_OLD);
	 Quiz[10]->ImportMvsp("pca\\youngr2.txt", PCA_TYPE_YOUNG);

	 Quiz[11]->ImportMvsp("pca\\allr3.txt", PCA_TYPE_ALL);
	 Quiz[11]->ImportMvsp("pca\\maler3.txt", PCA_TYPE_MALE);
	 Quiz[11]->ImportMvsp("pca\\femaler3.txt", PCA_TYPE_FEMALE);
	 Quiz[11]->ImportMvsp("pca\\oldr3.txt", PCA_TYPE_OLD);
	 Quiz[11]->ImportMvsp("pca\\youngr3.txt", PCA_TYPE_YOUNG);

	 Quiz[12]->ImportMvsp("pca\\allr4.txt", PCA_TYPE_ALL);
	 Quiz[12]->ImportMvsp("pca\\maler4.txt", PCA_TYPE_MALE);
	 Quiz[12]->ImportMvsp("pca\\femaler4.txt", PCA_TYPE_FEMALE);
	 Quiz[12]->ImportMvsp("pca\\oldr4.txt", PCA_TYPE_OLD);
	 Quiz[12]->ImportMvsp("pca\\youngr4.txt", PCA_TYPE_YOUNG);

	 Quiz[13]->ImportMvsp("pca\\allr5.txt", PCA_TYPE_ALL);
	 Quiz[13]->ImportMvsp("pca\\maler5.txt", PCA_TYPE_MALE);
	 Quiz[13]->ImportMvsp("pca\\femaler5.txt", PCA_TYPE_FEMALE);
	 Quiz[13]->ImportMvsp("pca\\oldr5.txt", PCA_TYPE_OLD);
	 Quiz[13]->ImportMvsp("pca\\youngr5.txt", PCA_TYPE_YOUNG);

	 Quiz[14]->ImportMvsp("pca\\allr6.txt", PCA_TYPE_ALL);
	 Quiz[14]->ImportMvsp("pca\\maler6.txt", PCA_TYPE_MALE);
	 Quiz[14]->ImportMvsp("pca\\femaler6.txt", PCA_TYPE_FEMALE);
	 Quiz[14]->ImportMvsp("pca\\oldr6.txt", PCA_TYPE_OLD);
	 Quiz[14]->ImportMvsp("pca\\youngr6.txt", PCA_TYPE_YOUNG);

	 Quiz[15]->ImportMvsp("pca\\allr7.txt", PCA_TYPE_ALL);
	 Quiz[15]->ImportMvsp("pca\\maler7.txt", PCA_TYPE_MALE);
	 Quiz[15]->ImportMvsp("pca\\femaler7.txt", PCA_TYPE_FEMALE);
	 Quiz[15]->ImportMvsp("pca\\oldr7.txt", PCA_TYPE_OLD);
	 Quiz[15]->ImportMvsp("pca\\youngr7.txt", PCA_TYPE_YOUNG);

	 Quiz[16]->ImportMvsp("pca\\alls1.txt", PCA_TYPE_ALL);
	 Quiz[16]->ImportMvsp("pca\\males1.txt", PCA_TYPE_MALE);
	 Quiz[16]->ImportMvsp("pca\\females1.txt", PCA_TYPE_FEMALE);
	 Quiz[16]->ImportMvsp("pca\\olds1.txt", PCA_TYPE_OLD);
	 Quiz[16]->ImportMvsp("pca\\youngs1.txt", PCA_TYPE_YOUNG);

	 Quiz[17]->ImportMvsp("pca\\alls2.txt", PCA_TYPE_ALL);
	 Quiz[17]->ImportMvsp("pca\\males2.txt", PCA_TYPE_MALE);
	 Quiz[17]->ImportMvsp("pca\\females2.txt", PCA_TYPE_FEMALE);
	 Quiz[17]->ImportMvsp("pca\\olds2.txt", PCA_TYPE_OLD);
	 Quiz[17]->ImportMvsp("pca\\youngs2.txt", PCA_TYPE_YOUNG);

	 Quiz[18]->ImportMvsp("pca\\alls3.txt", PCA_TYPE_ALL);
	 Quiz[18]->ImportMvsp("pca\\males3.txt", PCA_TYPE_MALE);
	 Quiz[18]->ImportMvsp("pca\\females3.txt", PCA_TYPE_FEMALE);
	 Quiz[18]->ImportMvsp("pca\\olds3.txt", PCA_TYPE_OLD);
	 Quiz[18]->ImportMvsp("pca\\youngs3.txt", PCA_TYPE_YOUNG);

	 Quiz[19]->ImportMvsp("pca\\alls4.txt", PCA_TYPE_ALL);
	 Quiz[19]->ImportMvsp("pca\\males4.txt", PCA_TYPE_MALE);
	 Quiz[19]->ImportMvsp("pca\\females4.txt", PCA_TYPE_FEMALE);
	 Quiz[19]->ImportMvsp("pca\\olds4.txt", PCA_TYPE_OLD);
	 Quiz[19]->ImportMvsp("pca\\youngs4.txt", PCA_TYPE_YOUNG);

	 Quiz[20]->ImportMvsp("pca\\alls5.txt", PCA_TYPE_ALL);
	 Quiz[20]->ImportMvsp("pca\\males5.txt", PCA_TYPE_MALE);
	 Quiz[20]->ImportMvsp("pca\\females5.txt", PCA_TYPE_FEMALE);
	 Quiz[20]->ImportMvsp("pca\\olds5.txt", PCA_TYPE_OLD);
	 Quiz[20]->ImportMvsp("pca\\youngs5.txt", PCA_TYPE_YOUNG);
	 Quiz[20]->ImportMvsp("pca\\asias5.txt", PCA_TYPE_ASIA);

	 Quiz[21]->ImportMvsp("pca\\alls6.txt", PCA_TYPE_ALL);
	 Quiz[21]->ImportMvsp("pca\\males6.txt", PCA_TYPE_MALE);
	 Quiz[21]->ImportMvsp("pca\\females6.txt", PCA_TYPE_FEMALE);
	 Quiz[21]->ImportMvsp("pca\\olds6.txt", PCA_TYPE_OLD);
	 Quiz[21]->ImportMvsp("pca\\youngs6.txt", PCA_TYPE_YOUNG);

	 Quiz[22]->ImportMvsp("pca\\alls7.txt", PCA_TYPE_ALL);
	 Quiz[22]->ImportMvsp("pca\\males7.txt", PCA_TYPE_MALE);
	 Quiz[22]->ImportMvsp("pca\\females7.txt", PCA_TYPE_FEMALE);
	 Quiz[22]->ImportMvsp("pca\\olds7.txt", PCA_TYPE_OLD);
	 Quiz[22]->ImportMvsp("pca\\youngs7.txt", PCA_TYPE_YOUNG);

	 Quiz[23]->ImportMvsp("pca\\alls8.txt", PCA_TYPE_ALL);
	 Quiz[23]->ImportMvsp("pca\\males8.txt", PCA_TYPE_MALE);
	 Quiz[23]->ImportMvsp("pca\\females8.txt", PCA_TYPE_FEMALE);
	 Quiz[23]->ImportMvsp("pca\\olds8.txt", PCA_TYPE_OLD);
	 Quiz[23]->ImportMvsp("pca\\youngs8.txt", PCA_TYPE_YOUNG);

	 Quiz[24]->ImportMvsp("pca\\alls9.txt", PCA_TYPE_ALL);
	 Quiz[24]->ImportMvsp("pca\\males9.txt", PCA_TYPE_MALE);
	 Quiz[24]->ImportMvsp("pca\\females9.txt", PCA_TYPE_FEMALE);
	 Quiz[24]->ImportMvsp("pca\\olds9.txt", PCA_TYPE_OLD);
	 Quiz[24]->ImportMvsp("pca\\youngs9.txt", PCA_TYPE_YOUNG);

	 Quiz[25]->ImportMvsp("pca\\alls10.txt", PCA_TYPE_ALL);
	 Quiz[25]->ImportMvsp("pca\\males10.txt", PCA_TYPE_MALE);
	 Quiz[25]->ImportMvsp("pca\\fems10.txt", PCA_TYPE_FEMALE);
	 Quiz[25]->ImportMvsp("pca\\olds10.txt", PCA_TYPE_OLD);
	 Quiz[25]->ImportMvsp("pca\\youngs10.txt", PCA_TYPE_YOUNG);

	 Quiz[26]->ImportMvsp("pca\\alls11.txt", PCA_TYPE_ALL);
	 Quiz[26]->ImportMvsp("pca\\males11.txt", PCA_TYPE_MALE);
	 Quiz[26]->ImportMvsp("pca\\fems11.txt", PCA_TYPE_FEMALE);
	 Quiz[26]->ImportMvsp("pca\\olds11.txt", PCA_TYPE_OLD);
	 Quiz[26]->ImportMvsp("pca\\youngs11.txt", PCA_TYPE_YOUNG);

	 Quiz[27]->ImportMvsp("pca\\alls12.txt", PCA_TYPE_ALL);
	 Quiz[27]->ImportMvsp("pca\\males12.txt", PCA_TYPE_MALE);
	 Quiz[27]->ImportMvsp("pca\\fems12.txt", PCA_TYPE_FEMALE);
	 Quiz[27]->ImportMvsp("pca\\olds12.txt", PCA_TYPE_OLD);
	 Quiz[27]->ImportMvsp("pca\\youngs12.txt", PCA_TYPE_YOUNG);

	 Quiz[28]->ImportMvsp("pca\\alln1.txt", PCA_TYPE_ALL);
	 Quiz[28]->ImportMvsp("pca\\malen1.txt", PCA_TYPE_MALE);
	 Quiz[28]->ImportMvsp("pca\\femalen1.txt", PCA_TYPE_FEMALE);
	 Quiz[28]->ImportMvsp("pca\\oldn1.txt", PCA_TYPE_OLD);
	 Quiz[28]->ImportMvsp("pca\\youngn1.txt", PCA_TYPE_YOUNG);

	 Quiz[29]->ImportMvsp("pca\\alln2.txt", PCA_TYPE_ALL);
	 Quiz[29]->ImportMvsp("pca\\malen2.txt", PCA_TYPE_MALE);
	 Quiz[29]->ImportMvsp("pca\\femalen2.txt", PCA_TYPE_FEMALE);
	 Quiz[29]->ImportMvsp("pca\\oldn2.txt", PCA_TYPE_OLD);
	 Quiz[29]->ImportMvsp("pca\\youngn2.txt", PCA_TYPE_YOUNG);

	 Quiz[30]->ImportMvsp("pca\\alln3.txt", PCA_TYPE_ALL);
	 Quiz[30]->ImportMvsp("pca\\malen3.txt", PCA_TYPE_MALE);
	 Quiz[30]->ImportMvsp("pca\\femalen3.txt", PCA_TYPE_FEMALE);
	 Quiz[30]->ImportMvsp("pca\\oldn3.txt", PCA_TYPE_OLD);
	 Quiz[30]->ImportMvsp("pca\\youngn3.txt", PCA_TYPE_YOUNG);
	 Quiz[30]->ImportMvsp("pca\\asian3.txt", PCA_TYPE_ASIA);

	 Quiz[31]->ImportMvsp("pca\\alln4.txt", PCA_TYPE_ALL);
	 Quiz[31]->ImportMvsp("pca\\malen4.txt", PCA_TYPE_MALE);
	 Quiz[31]->ImportMvsp("pca\\femalen4.txt", PCA_TYPE_FEMALE);
	 Quiz[31]->ImportMvsp("pca\\oldn4.txt", PCA_TYPE_OLD);
	 Quiz[31]->ImportMvsp("pca\\youngn4.txt", PCA_TYPE_YOUNG);
	 Quiz[31]->ImportMvsp("pca\\asian4.txt", PCA_TYPE_ASIA);

	 Quiz[32]->ImportMvsp("pca\\allfi.txt", PCA_TYPE_ALL);
	 Quiz[32]->ImportMvsp("pca\\malefi.txt", PCA_TYPE_MALE);
	 Quiz[32]->ImportMvsp("pca\\femalefi.txt", PCA_TYPE_FEMALE);
	 Quiz[32]->ImportMvsp("pca\\oldfi.txt", PCA_TYPE_OLD);
	 Quiz[32]->ImportMvsp("pca\\youngfi.txt", PCA_TYPE_YOUNG);
	 Quiz[32]->ImportMvsp("pca\\asiafi.txt", PCA_TYPE_ASIA);

	 Quiz[33]->ImportMvsp("pca\\allf1.txt", PCA_TYPE_ALL);
	 Quiz[33]->ImportMvsp("pca\\malef1.txt", PCA_TYPE_MALE);
	 Quiz[33]->ImportMvsp("pca\\femalef1.txt", PCA_TYPE_FEMALE);
	 Quiz[33]->ImportMvsp("pca\\oldf1.txt", PCA_TYPE_OLD);
	 Quiz[33]->ImportMvsp("pca\\youngf1.txt", PCA_TYPE_YOUNG);
	 Quiz[33]->ImportMvsp("pca\\asiaf1.txt", PCA_TYPE_ASIA);

	 Quiz[34]->ImportMvsp("pca\\allf2.txt", PCA_TYPE_ALL);
	 Quiz[34]->ImportMvsp("pca\\malef2.txt", PCA_TYPE_MALE);
	 Quiz[34]->ImportMvsp("pca\\femalef2.txt", PCA_TYPE_FEMALE);
	 Quiz[34]->ImportMvsp("pca\\oldf2.txt", PCA_TYPE_OLD);
	 Quiz[34]->ImportMvsp("pca\\youngf2.txt", PCA_TYPE_YOUNG);
	 Quiz[34]->ImportMvsp("pca\\asiaf2.txt", PCA_TYPE_ASIA);

	 Quiz[35]->ImportMvsp("pca\\allf3.txt", PCA_TYPE_ALL);
	 Quiz[35]->ImportMvsp("pca\\malef3.txt", PCA_TYPE_MALE);
	 Quiz[35]->ImportMvsp("pca\\femalef3.txt", PCA_TYPE_FEMALE);
	 Quiz[35]->ImportMvsp("pca\\oldf3.txt", PCA_TYPE_OLD);
	 Quiz[35]->ImportMvsp("pca\\youngf3.txt", PCA_TYPE_YOUNG);
	 Quiz[35]->ImportMvsp("pca\\asiaf3.txt", PCA_TYPE_ASIA);

	 Quiz[36]->ImportMvsp("pca\\allf4.txt", PCA_TYPE_ALL);
	 Quiz[36]->ImportMvsp("pca\\malef4.txt", PCA_TYPE_MALE);
	 Quiz[36]->ImportMvsp("pca\\femalef4.txt", PCA_TYPE_FEMALE);
	 Quiz[36]->ImportMvsp("pca\\oldf4.txt", PCA_TYPE_OLD);
	 Quiz[36]->ImportMvsp("pca\\youngf4.txt", PCA_TYPE_YOUNG);
	 Quiz[36]->ImportMvsp("pca\\asiaf4.txt", PCA_TYPE_ASIA);

	printf("import aspie\r\n");

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
	 Quiz[26]->ImportMvspAspie("pca\\aspies11.txt");
	 Quiz[27]->ImportMvspAspie("pca\\aspies12.txt");
	 Quiz[28]->ImportMvspAspie("pca\\aspien1.txt");
	 Quiz[29]->ImportMvspAspie("pca\\aspien2.txt");
	 Quiz[30]->ImportMvspAspie("pca\\aspien3.txt");
	 Quiz[31]->ImportMvspAspie("pca\\aspien4.txt");
	 Quiz[32]->ImportMvspAspie("pca\\aspiefi.txt");
	 Quiz[33]->ImportMvspAspie("pca\\aspief1.txt");
	 Quiz[34]->ImportMvspAspie("pca\\aspief2.txt");
	 Quiz[35]->ImportMvspAspie("pca\\aspief3.txt");
	 Quiz[36]->ImportMvspAspie("pca\\aspief4.txt");

	 printf("Cutoff\r\n");
	  Quiz[36]->DsmCutoff("eval\\cutoff.htm", TRUE);

	  Quiz[0]->DsmCutoff("eval\\cut1.htm", FALSE);
	  Quiz[1]->DsmCutoff("eval\\cut2.htm", FALSE);
	  Quiz[2]->DsmCutoff("eval\\cut3.htm", FALSE);
	  Quiz[3]->DsmCutoff("eval\\cutnd.htm", FALSE);
	  Quiz[4]->DsmCutoff("eval\\cut5.htm", FALSE);
	  Quiz[5]->DsmCutoff("eval\\cut6.htm", FALSE);
	  Quiz[6]->DsmCutoff("eval\\cut7.htm", FALSE);
	  Quiz[7]->DsmCutoff("eval\\cut8.htm", FALSE);
	  Quiz[8]->DsmCutoff("eval\\cut9.htm", FALSE);
	  Quiz[9]->DsmCutoff("eval\\cutr1.htm", FALSE);
	  Quiz[10]->DsmCutoff("eval\\cutr2.htm", FALSE);
	  Quiz[11]->DsmCutoff("eval\\cutr3.htm", FALSE);
	  Quiz[12]->DsmCutoff("eval\\cutr4.htm", FALSE);
	  Quiz[13]->DsmCutoff("eval\\cutr5.htm", FALSE);
	  Quiz[14]->DsmCutoff("eval\\cutr6.htm", FALSE);
	  Quiz[15]->DsmCutoff("eval\\cutr7.htm", FALSE);
	  Quiz[16]->DsmCutoff("eval\\cuts1.htm", FALSE);
	  Quiz[17]->DsmCutoff("eval\\cuts2.htm", FALSE);
	  Quiz[18]->DsmCutoff("eval\\cuts3.htm", FALSE);
	  Quiz[19]->DsmCutoff("eval\\cuts4.htm", FALSE);
	  Quiz[20]->DsmCutoff("eval\\cuts5.htm", FALSE);
	  Quiz[21]->DsmCutoff("eval\\cuts6.htm", FALSE);
	  Quiz[22]->DsmCutoff("eval\\cuts7.htm", FALSE);
	  Quiz[23]->DsmCutoff("eval\\cuts8.htm", FALSE);
	  Quiz[24]->DsmCutoff("eval\\cuts9.htm", FALSE);
	  Quiz[25]->DsmCutoff("eval\\cuts10.htm", FALSE);
	  Quiz[26]->DsmCutoff("eval\\cuts11.htm", FALSE);
	  Quiz[27]->DsmCutoff("eval\\cuts12.htm", FALSE);
	  Quiz[28]->DsmCutoff("eval\\cutn1.htm", FALSE);
	  Quiz[29]->DsmCutoff("eval\\cutn2.htm", FALSE);
	  Quiz[30]->DsmCutoff("eval\\cutn3.htm", FALSE);
	  Quiz[31]->DsmCutoff("eval\\cutn4.htm", FALSE);
	  Quiz[32]->DsmCutoff("eval\\cutfi.htm", FALSE);
	  Quiz[33]->DsmCutoff("eval\\cutf1.htm", FALSE);
	  Quiz[34]->DsmCutoff("eval\\cutf2.htm", FALSE);
	  Quiz[35]->DsmCutoff("eval\\cutf3.htm", FALSE);
	  Quiz[36]->DsmCutoff("eval\\cutf4.htm", FALSE);

	printf("calc global\r\n");
	 Quiz[36]->CalcGlobal();

	 printf("axis corr\r\n");
	 Quiz[36]->ExportGenderCongruence("gender.txt");
	 Quiz[36]->ExportAgeCongruence("age.txt");
	 Quiz[36]->ExportAsiaCongruence("asia.txt");
	 Quiz[1]->ExportCongruence("con2.txt");
	 Quiz[2]->ExportCongruence("con3.txt");
	 Quiz[3]->ExportCongruence("con4.txt");
	 Quiz[4]->ExportCongruence("con5.txt");
	 Quiz[5]->ExportCongruence("con6.txt");
	 Quiz[6]->ExportCongruence("con7.txt");
	 Quiz[7]->ExportCongruence("con8.txt");
	 Quiz[8]->ExportCongruence("con9.txt");
	 Quiz[9]->ExportCongruence("conr1.txt");
	 Quiz[10]->ExportCongruence("conr2.txt");
	 Quiz[11]->ExportCongruence("conr3.txt");
	 Quiz[12]->ExportCongruence("conr4.txt");
	 Quiz[13]->ExportCongruence("conr5.txt");
	 Quiz[14]->ExportCongruence("conr6.txt");
	 Quiz[15]->ExportCongruence("conr7.txt");
	 Quiz[16]->ExportCongruence("cons1.txt");
	 Quiz[17]->ExportCongruence("cons2.txt");
	 Quiz[18]->ExportCongruence("cons3.txt");
	 Quiz[19]->ExportCongruence("cons4.txt");
	 Quiz[20]->ExportCongruence("cons5.txt");
	 Quiz[21]->ExportCongruence("cons6.txt");
	 Quiz[22]->ExportCongruence("cons7.txt");
	 Quiz[23]->ExportCongruence("cons8.txt");
	 Quiz[24]->ExportCongruence("cons9.txt");
	 Quiz[25]->ExportCongruence("cons10.txt");
	 Quiz[26]->ExportCongruence("cons11.txt");
	 Quiz[27]->ExportCongruence("cons12.txt");
	 Quiz[28]->ExportCongruence("conn1.txt");
	 Quiz[29]->ExportCongruence("conn2.txt");
	 Quiz[30]->ExportCongruence("conn3.txt");
	 Quiz[31]->ExportCongruence("conn4.txt");
	 Quiz[32]->ExportCongruence("confi.txt");
	 Quiz[33]->ExportCongruence("conf1.txt");
	 Quiz[34]->ExportCongruence("conf2.txt");
	 Quiz[35]->ExportCongruence("conf3.txt");
	 Quiz[36]->ExportCongruence("conf4.txt");

	 printf("export intercorr\n");
	 TQuiz::ExportHighestIntercorr("csv\\highcorr.csv");
	 TQuiz::ExportAverageIntercorr("csv\\avgcorr.csv");
	 TQuiz::ExportAveragePosIntercorr("csv\\poscorr.csv");
	 TQuiz::ExportAverageNegIntercorr("csv\\negcorr.csv");

	 for (g = 0; g < GROUP_MIXED; g++)
	 {
		sprintf(str, "csv\\corr%d.csv", g);
		TQuiz::ExportGroupIntercorr(str, g);
	 }

//	 Quiz[32]->WritePhpQuestions("q.php");
//	 Quiz[32]->WriteSetupTexts("q.cpp");
//	 Quiz[32]->WriteSetupCross("c.cpp");

	printf("referers\r\n");

//#ifdef ALL
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
	 Quiz[26]->WriteReferers("eval\\refs11.htm");
	 Quiz[27]->WriteReferers("eval\\refs12.htm");
	 Quiz[28]->WriteReferers("eval\\refn1.htm");
	 Quiz[29]->WriteReferers("eval\\refn2.htm");
	 Quiz[30]->WriteReferers("eval\\refn3.htm");
	 Quiz[31]->WriteReferers("eval\\refn4.htm");
//#endif

	 Quiz[32]->WriteReferers("eval\\reffi.htm");
	 Quiz[33]->WriteReferers("eval\\reff1.htm");
	 Quiz[34]->WriteReferers("eval\\reff2.htm");
	 Quiz[35]->WriteReferers("eval\\reff3.htm");
	 Quiz[36]->WriteReferers("eval\\reff4.htm");

	printf("details\r\n");

#ifdef ALL
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
	 Quiz[26]->WriteSumaryTable("eval\\quizs11.htm", FALSE);
	 Quiz[27]->WriteSumaryTable("eval\\quizs12.htm", FALSE);
	 Quiz[28]->WriteSumaryTable("eval\\quizn1.htm", FALSE);
	 Quiz[29]->WriteSumaryTable("eval\\quizn2.htm", FALSE);
	 Quiz[30]->WriteSumaryTable("eval\\quizn3.htm", FALSE);
	 Quiz[31]->WriteSumaryTable("eval\\quizn4.htm", FALSE);
#endif

	 Quiz[32]->WriteSumaryTable("eval\\quizfi.htm", FALSE);
	 Quiz[33]->WriteSumaryTable("eval\\quizf1.htm", FALSE);
	 Quiz[34]->WriteSumaryTable("eval\\quizf2.htm", FALSE);
	 Quiz[35]->WriteSumaryTable("eval\\quizf3.htm", FALSE);
	 Quiz[36]->WriteSumaryTable("eval\\quizf4.htm", FALSE);

	printf("rel\r\n");

#ifdef ALL
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
	 Quiz[26]->WriteIntercorr("eval\\rels11.htm");
	 Quiz[27]->WriteIntercorr("eval\\rels12.htm");
	 Quiz[28]->WriteIntercorr("eval\\reln1.htm");
	 Quiz[29]->WriteIntercorr("eval\\reln2.htm");
	 Quiz[30]->WriteIntercorr("eval\\reln3.htm");
	 Quiz[31]->WriteIntercorr("eval\\reln4.htm");
#endif

	 Quiz[32]->WriteIntercorr("eval\\relfi.htm");
	 Quiz[33]->WriteIntercorr("eval\\relf1.htm");
	 Quiz[34]->WriteIntercorr("eval\\relf2.htm");
	 Quiz[35]->WriteIntercorr("eval\\relf3.htm");
	 Quiz[36]->WriteIntercorr("eval\\relf4.htm");

	printf("group\r\n");
	 Quiz[36]->WriteGroupTable("eval\\group.htm", TRUE);
	printf("groupcorr\r\n");
	 Quiz[36]->WriteGroupCorrTable("eval\\groupcorr.htm");
	printf("pcaload\r\n");
	 Quiz[36]->WritePcaLoadTable("eval\\pcaload.htm");

	printf("avgcorr\r\n");
	 Quiz[36]->WriteAverageGroupCorrTable("eval\\avgcorr.htm");
	printf("avgpca\r\n");
	 Quiz[36]->WriteAveragePcaTable("eval\\avgpca.htm");
	printf("avg\r\n");
	 Quiz[36]->WriteAveragePcaCorrTable("eval\\avg.htm");

	printf("pcacorr\r\n");
	 Quiz[36]->WritePcaCorrTable("eval\\pcacorr.htm");

	printf("axisload\r\n");
	 Quiz[36]->WriteAxisLoadTable("eval\\axisload.htm");

	printf("avgaxis\r\n");
	 Quiz[36]->WriteAverageAxisTable("eval\\avgaxis.htm");

	printf("dxload\r\n");
	 Quiz[36]->WriteDxLoadTable("eval\\dxload.htm");

	printf("avgdx\r\n");
	 Quiz[36]->WriteAverageDxTable("eval\\avgdx.htm");

	printf("main\r\n");
	 Quiz[36]->WriteLinkReport("eval\\index.htm");

//#ifdef ALL
	printf("special reports\r\n");
	 Quiz[5]->WriteHair("eval\\hair6.htm");
	 Quiz[5]->WriteEye("eval\\eye6.htm");
	 Quiz[5]->WriteRace("eval\\race6.htm");
	 Quiz[20]->WriteRace("eval\\races5.htm");
	 Quiz[30]->WriteRace("eval\\racen3.htm");
	 Quiz[31]->WriteRace("eval\\racen4.htm");
	 Quiz[32]->WriteRace("eval\\racefi.htm");
	 Quiz[33]->WriteRace("eval\\racef1.htm");
	 Quiz[34]->WriteRace("eval\\racef2.htm");
	 Quiz[35]->WriteRace("eval\\racef3.htm");
	 Quiz[36]->WriteRace("eval\\racef4.htm");

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
//#endif

	printf("retest\r\n");

	 Quiz[17]->WriteRetest("eval\\retests2.htm");
	 Quiz[18]->WriteRetest("eval\\retests3.htm");
	 Quiz[19]->WriteRetest("eval\\retests4.htm");
	 Quiz[20]->WriteRetest("eval\\retests5.htm");
	 Quiz[21]->WriteRetest("eval\\retests6.htm");
	 Quiz[22]->WriteRetest("eval\\retests7.htm");
	 Quiz[23]->WriteRetest("eval\\retests8.htm");
	 Quiz[24]->WriteRetest("eval\\retests9.htm");
	 Quiz[25]->WriteRetest("eval\\retests10.htm");
	 Quiz[26]->WriteRetest("eval\\retests11.htm");
	 Quiz[27]->WriteRetest("eval\\retests12.htm");
	 Quiz[28]->WriteRetest("eval\\retestn1.htm");
	 Quiz[29]->WriteRetest("eval\\retestn2.htm");
	 Quiz[30]->WriteRetest("eval\\retestn3.htm");
	 Quiz[31]->WriteRetest("eval\\retestn4.htm");
	 Quiz[32]->WriteRetest("eval\\retestfi.htm");
	 Quiz[33]->WriteRetest("eval\\retestf1.htm");
	 Quiz[34]->WriteRetest("eval\\retestf2.htm");
	 Quiz[35]->WriteRetest("eval\\retestf3.htm");
	 Quiz[36]->WriteRetest("eval\\retestf4.htm");
	 Quiz[36]->WriteVersionRetest("eval\\vervar.htm");

	printf("imgrate\r\n");
#ifdef ALL
	 Quiz[16]->WritePictureRating("eval\\imgrate1.htm");
	 Quiz[17]->WritePictureRating("eval\\imgrate2.htm");
#endif

	 Quiz[29]->WritePictureRating("eval\\vidrate1.htm");

	printf("pca\r\n");

#ifdef ALL
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
	 Quiz[26]->WritePcaGroupCorr("eval\\pcas11.htm");
	 Quiz[27]->WritePcaGroupCorr("eval\\pcas12.htm");
	 Quiz[28]->WritePcaGroupCorr("eval\\pcan1.htm");
	 Quiz[29]->WritePcaGroupCorr("eval\\pcan2.htm");
	 Quiz[30]->WritePcaGroupCorr("eval\\pcan3.htm");
	 Quiz[31]->WritePcaGroupCorr("eval\\pcan4.htm");
#endif

	 Quiz[32]->WritePcaGroupCorr("eval\\pcafi.htm");
	 Quiz[33]->WritePcaGroupCorr("eval\\pcaf1.htm");
	 Quiz[34]->WritePcaGroupCorr("eval\\pcaf2.htm");
	 Quiz[35]->WritePcaGroupCorr("eval\\pcaf3.htm");
	 Quiz[36]->WritePcaGroupCorr("eval\\pcaf4.htm");

//	 Quiz[19]->WriteLSAS("");
//	 Quiz[23]->WriteMDQ("");
//	 Quiz[24]->WriteADD("");
//	 Quiz[25]->WriteDyslexia("");
//	 Quiz[26]->WriteTS("");
//	 Quiz[27]->WriteGifted("");
//	 Quiz[30]->WriteEat("");
//	 Quiz[12]->WriteAQ("");
//	 Quiz[32]->WriteAQ("");
	 Quiz[34]->WriteIPIP("eval\\ipip.htm");

	 Quiz[6]->WriteRefererNtCorrelation("eval\\exhnt.htm", "Exhibitionism", "dickflash.com");

	printf("version histogram\r\n");

#ifdef ALL
	 Quiz[1]->ExportDiffHistogram("csv\\all2.csv", POP_TYPE_ALL, FALSE);
	 Quiz[2]->ExportDiffHistogram("csv\\all3.csv", POP_TYPE_ALL, FALSE);
	 Quiz[3]->ExportDiffHistogram("csv\\all4.csv", POP_TYPE_ALL, FALSE);
	 Quiz[4]->ExportDiffHistogram("csv\\all5.csv", POP_TYPE_ALL, FALSE);
	 Quiz[5]->ExportDiffHistogram("csv\\all6.csv", POP_TYPE_ALL, FALSE);
	 Quiz[6]->ExportDiffHistogram("csv\\all7.csv", POP_TYPE_ALL, FALSE);
	 Quiz[7]->ExportDiffHistogram("csv\\all8.csv", POP_TYPE_ALL, FALSE);
	 Quiz[8]->ExportDiffHistogram("csv\\all9.csv", POP_TYPE_ALL, FALSE);
	 Quiz[9]->ExportDiffHistogram("csv\\allr1.csv", POP_TYPE_ALL, FALSE);
	 Quiz[10]->ExportDiffHistogram("csv\\allr2.csv", POP_TYPE_ALL, FALSE);
	 Quiz[11]->ExportDiffHistogram("csv\\allr3.csv", POP_TYPE_ALL, FALSE);
	 Quiz[12]->ExportDiffHistogram("csv\\allr4.csv", POP_TYPE_ALL, FALSE);
	 Quiz[13]->ExportDiffHistogram("csv\\allr5.csv", POP_TYPE_ALL, FALSE);
	 Quiz[14]->ExportDiffHistogram("csv\\allr6.csv", POP_TYPE_ALL, FALSE);
	 Quiz[15]->ExportDiffHistogram("csv\\allr7.csv", POP_TYPE_ALL, FALSE);
	 Quiz[16]->ExportDiffHistogram("csv\\alls1.csv", POP_TYPE_ALL, FALSE);
	 Quiz[17]->ExportDiffHistogram("csv\\alls2.csv", POP_TYPE_ALL, FALSE);
	 Quiz[18]->ExportDiffHistogram("csv\\alls3.csv", POP_TYPE_ALL, FALSE);
	 Quiz[19]->ExportDiffHistogram("csv\\alls4.csv", POP_TYPE_ALL, FALSE);
	 Quiz[20]->ExportDiffHistogram("csv\\alls5.csv", POP_TYPE_ALL, FALSE);
	 Quiz[21]->ExportDiffHistogram("csv\\alls6.csv", POP_TYPE_ALL, FALSE);
	 Quiz[22]->ExportDiffHistogram("csv\\alls7.csv", POP_TYPE_ALL, FALSE);
	 Quiz[23]->ExportDiffHistogram("csv\\alls8.csv", POP_TYPE_ALL, FALSE);
	 Quiz[24]->ExportDiffHistogram("csv\\alls9.csv", POP_TYPE_ALL, FALSE);
	 Quiz[25]->ExportDiffHistogram("csv\\alls10.csv", POP_TYPE_ALL, FALSE);
	 Quiz[26]->ExportDiffHistogram("csv\\alls11.csv", POP_TYPE_ALL, FALSE);
	 Quiz[27]->ExportDiffHistogram("csv\\alls12.csv", POP_TYPE_ALL, FALSE);
	 Quiz[28]->ExportDiffHistogram("csv\\alln1.csv", POP_TYPE_ALL, FALSE);
	 Quiz[29]->ExportDiffHistogram("csv\\alln2.csv", POP_TYPE_ALL, FALSE);
	 Quiz[30]->ExportDiffHistogram("csv\\alln3.csv", POP_TYPE_ALL, FALSE);
	 Quiz[31]->ExportDiffHistogram("csv\\alln4.csv", POP_TYPE_ALL, FALSE);
#endif

	 Quiz[32]->ExportDiffHistogram("csv\\allfi.csv", POP_TYPE_ALL, FALSE);
	 Quiz[33]->ExportDiffHistogram("csv\\allf1.csv", POP_TYPE_ALL, FALSE);
	 Quiz[34]->ExportDiffHistogram("csv\\allf2.csv", POP_TYPE_ALL, FALSE);
	 Quiz[35]->ExportDiffHistogram("csv\\allf3.csv", POP_TYPE_ALL, FALSE);
	 Quiz[36]->ExportDiffHistogram("csv\\allf4.csv", POP_TYPE_ALL, FALSE);

#ifdef CONV
	printf("conv headers\r\n");
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
	 Quiz[26]->WriteGroupWeighting("convs11.h");
	 Quiz[27]->WriteGroupWeighting("convs12.h");
	 Quiz[28]->WriteGroupWeighting("convn1.h");
	 Quiz[29]->WriteGroupWeighting("convn2.h");
	 Quiz[30]->WriteGroupWeighting("convn3.h");
	 Quiz[31]->WriteGroupWeighting("convn4.h");
#endif

	 Quiz[32]->WriteGroupWeighting("convf.h");

	printf("type histograms\r\n");
	 Quiz[36]->ExportDiffHistogram("csv\\all.csv", POP_TYPE_ALL, TRUE);

	 Quiz[36]->ExportDiffHistogram("csv\\autism.csv", POP_TYPE_AUTISM, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\as.csv", POP_TYPE_AS, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\nt.csv", POP_TYPE_NT_CONTROL, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\soc.csv", POP_TYPE_SOCIAL_PHOBIA, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\add.csv", POP_TYPE_ADD, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\ts.csv", POP_TYPE_TS, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\pa.csv", POP_TYPE_PA, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\bip.csv", POP_TYPE_BIPOLAR, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\schizo.csv", POP_TYPE_SCHIZOPHRENIA, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\syn.csv", POP_TYPE_SYNAESTHESIA, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\dysl.csv", POP_TYPE_DYSLEXIA, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\dysc.csv", POP_TYPE_DYSCALCULIA, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\dysg.csv", POP_TYPE_DYSGRAPHIA, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\ocd.csv", POP_TYPE_OCD, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\odd.csv", POP_TYPE_ODD, TRUE);
	 Quiz[36]->ExportDiffHistogram("csv\\dysp.csv", POP_TYPE_DYSPRAXIA, TRUE);

	 TQuiz::ExportBirthMonthHistogram("csv\\birth.csv");

	printf("DSM\r\n");
	 Quiz[36]->WriteDsmReport("eval\\autism.htm", POP_TYPE_AUTISM);
	 Quiz[36]->WriteDsmReport("eval\\as.htm", POP_TYPE_AS);
	 Quiz[36]->WriteDsmReport("eval\\add.htm", POP_TYPE_ADD);
	 Quiz[36]->WriteDsmReport("eval\\ts.htm", POP_TYPE_TS);
	 Quiz[36]->WriteDsmReport("eval\\dysp.htm", POP_TYPE_DYSPRAXIA);
	 Quiz[36]->WriteDsmReport("eval\\dysl.htm", POP_TYPE_DYSLEXIA);
	 Quiz[36]->WriteDsmReport("eval\\dysc.htm", POP_TYPE_DYSCALCULIA);
	 Quiz[36]->WriteDsmReport("eval\\ocd.htm", POP_TYPE_OCD);
	 Quiz[36]->WriteDsmReport("eval\\odd.htm", POP_TYPE_ODD);
	 Quiz[36]->WriteDsmReport("eval\\pa.htm", POP_TYPE_PA);
	 Quiz[36]->WriteDsmReport("eval\\dysg.htm", POP_TYPE_DYSGRAPHIA);
	 Quiz[36]->WriteDsmReport("eval\\bip.htm", POP_TYPE_BIPOLAR);
	 Quiz[36]->WriteDsmReport("eval\\schizo.htm", POP_TYPE_SCHIZOPHRENIA);
	 Quiz[36]->WriteDsmReport("eval\\social.htm", POP_TYPE_SOCIAL_PHOBIA);


//	 Quiz[18]->WriteWeighting("weights.cpp");
//	 Quiz[32]->WritePhpWeighting("weights.php");
//	 Quiz[32]->WritePhpGroupWeighting("group.php");

//	 Quiz[9]->MoveWiki("iwiki.txt", "wiki.txt", 0.2);

//	  Quiz[16]->WriteWiki("wiki.txt", 0.2, 0.2);
//	  Quiz[14]->WriteWikiCorrelation("wiki.txt", "maxcorr.htm", 150);
//	  Quiz[14]->WriteWikiNoncorrelated("wiki.txt", "mincorr.htm", 150);

//	  Quiz[31]->WriteQuizWiki("n5.txt");

//	  TQuiz::PrintGlobalCorrelation(258, 81);
//	  TQuiz::PrintGlobalCorrelation(556, 493);

//	 TQuiz::WikiToQuiz("wiki.txt", "final.txt");

//	 Quiz[7]->WritePhpGlobalQuestions("global.php");

	printf("SQL\r\n");
	Quiz[36]->ExportGlobalSql("db\\global.sql");
	Quiz[36]->ExportQuizVerSql("db\\quizver.sql");
	Quiz[36]->ExportGroupSql("db\\group.sql");
	Quiz[36]->ExportPopTypeSql("db\\poptype.sql");
	Quiz[36]->ExportGlobalCorrSql("db\\gcorr.sql");
	Quiz[36]->ExportGlobalAxisSql("db\\gaxis.sql");
	Quiz[36]->ExportQuizCatPopSql("db\\qcatpop.sql");
	Quiz[36]->ExportQuizGlobalSql("db\\qglobal.sql");
}

