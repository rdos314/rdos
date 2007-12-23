/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# quizs9.cpp
# Quiz stable version 9 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs9.h"
#include "file.h"
#include "quizdbs9.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS9::TQuizS9
#
#   Purpose....: Constructor for TQuizS9
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS9::TQuizS9(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8)
  : TQuiz(242),
	FDataFile(FileName)
{
	DefineCross(0, QuizI);
	DefineCross(1, QuizII);
	DefineCross(2, QuizIII);
	DefineCross(3, QuizNd);
	DefineCross(4, Quiz5);
	DefineCross(5, Quiz6);
	DefineCross(6, Quiz7);
	DefineCross(7, Quiz8);
	DefineCross(8, Quiz9);
	DefineCross(9, QuizR1);
	DefineCross(10, QuizR2);
	DefineCross(11, QuizR3);
	DefineCross(12, QuizR4);
	DefineCross(13, QuizR5);
	DefineCross(14, QuizR6);
	DefineCross(15, QuizR7);
	DefineCross(16, QuizS1);
	DefineCross(17, QuizS2);
	DefineCross(18, QuizS3);
	DefineCross(19, QuizS4);
	DefineCross(20, QuizS5);
	DefineCross(21, QuizS6);
	DefineCross(22, QuizS7);
	DefineCross(23, QuizS8);

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS9::~TQuizS9
#
#   Purpose....: Destructor for TQuizS9
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS9::~TQuizS9()
{
}

/*##################  TQuizS9::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS9::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS9::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS9::GetCatCount(int Question)
{
	if (Question >= 158 && Question <= 235)
		return 5;
	else
		return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS9::GetQuizN()
{
	return 158;
}

/*##########################################################################
#
#   Name       : TQuizS9::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::WriteName(TFile &File)
{
	 File.Write("S9");
}

/*##########################################################################
#
#   Name       : TQuizS9::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::WriteLongName(TFile &File)
{
	 File.Write("stable version 9");
}

/*##########################################################################
#
#   Name       : TQuizS9::GetDxData
#
#   Purpose....: Get diagnostic data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::GetDxData(int PopType, int GroupArr[MAX_GROUP_COUNT], int Arr[MAX_SCORE][2], int OnlyNtControl)
{
	TQuizRow Row;
	int res;
	int g;
	TReferer *ref;
	int NoDx;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
	    NoDx = FALSE;
	    
	    if (OnlyNtControl)
	    {
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
			    NoDx = TRUE;
	    }
	    else
	        NoDx = TRUE;

        res = 0;
	    for (g = 0; g < MAX_GROUP_COUNT; g++)
    	    res += Row.GroupResult[g] * GroupArr[g];

	    if (res >= 0 && res < MAX_SCORE)
	    {
			switch (PopType)
			{
				case POP_TYPE_AUTISM:
					 if (Row.Autism == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.Autism == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_AS:
					 if (Row.Aspie == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.Aspie == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_ADD:
					 if (Row.ADHD == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.ADHD == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_TS:
					 if (Row.TS == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.TS == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_DYSLEXIA:
					 if (Row.Dyslexia == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.Dyslexia == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_DYSCALCULIA:
					 if (Row.Dyscalculia == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.Dyscalculia == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_OCD:
					 if (Row.OCD == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.OCD == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_ODD:
					 if (Row.ODD == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.ODD == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_BIPOLAR:
					 if (Row.Bipolar == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.Bipolar == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_SCHIZOPHRENIA:
					 if (Row.Schizophrenia == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.Schizophrenia == 0))
						  Arr[res][0]++;
					 break;

				case POP_TYPE_SOCIAL_PHOBIA:
					 if (Row.Social == 2)
						  Arr[res][1]++;

					 if (NoDx && (Row.Social == 0))
						  Arr[res][0]++;
					 break;

			}
		}
	}
}

/*##################  TQuizS9::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS9::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::SetupTexts()
{
  Quiz[18].Reverse = TRUE;
  Quiz[33].Reverse = TRUE;
  Quiz[34].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[37].Reverse = TRUE;
  Quiz[38].Reverse = TRUE;
  Quiz[39].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[86].Reverse = TRUE;
  Quiz[87].Reverse = TRUE;
  Quiz[89].Reverse = TRUE;
  Quiz[90].Reverse = TRUE;
  Quiz[118].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;
  Quiz[150].Reverse = TRUE;
  Quiz[151].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[6].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[8].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[9].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[10].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[11].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[12].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[13].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_NT_TALENT;
  Quiz[19].MyGroup = GROUP_NT_TALENT;
  Quiz[20].MyGroup = GROUP_ACTIVITY;
  Quiz[21].MyGroup = GROUP_NT_TALENT;
  Quiz[22].MyGroup = GROUP_NT_HUNTING;
  Quiz[23].MyGroup = GROUP_ACTIVITY;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[28].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[29].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[30].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[31].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[32].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[33].MyGroup = GROUP_NT_NVC;
  Quiz[34].MyGroup = GROUP_NT_OBSESSION;
  Quiz[35].MyGroup = GROUP_NT_OBSESSION;
  Quiz[36].MyGroup = GROUP_NT_NVC;
  Quiz[37].MyGroup = GROUP_NT_OBSESSION;
  Quiz[38].MyGroup = GROUP_NT_OBSESSION;
  Quiz[39].MyGroup = GROUP_NT_OBSESSION;
  Quiz[40].MyGroup = GROUP_SOCIAL;
  Quiz[41].MyGroup = GROUP_SOCIAL;
  Quiz[42].MyGroup = GROUP_SOCIAL;
  Quiz[43].MyGroup = GROUP_SOCIAL;
  Quiz[44].MyGroup = GROUP_SOCIAL;
  Quiz[45].MyGroup = GROUP_SOCIAL;
  Quiz[46].MyGroup = GROUP_SOCIAL;
  Quiz[47].MyGroup = GROUP_SOCIAL;
  Quiz[48].MyGroup = GROUP_SOCIAL;
  Quiz[49].MyGroup = GROUP_SOCIAL;
  Quiz[50].MyGroup = GROUP_SOCIAL;
  Quiz[51].MyGroup = GROUP_SOCIAL;
  Quiz[52].MyGroup = GROUP_SOCIAL;
  Quiz[53].MyGroup = GROUP_NT_NVC;
  Quiz[54].MyGroup = GROUP_SOCIAL;
  Quiz[55].MyGroup = GROUP_NT_OBSESSION;
  Quiz[56].MyGroup = GROUP_SOCIAL;
  Quiz[57].MyGroup = GROUP_SOCIAL;
  Quiz[58].MyGroup = GROUP_ASPIE_NVC;
  Quiz[59].MyGroup = GROUP_ASPIE_NVC;
  Quiz[60].MyGroup = GROUP_ASPIE_NVC;
  Quiz[61].MyGroup = GROUP_ASPIE_NVC;
  Quiz[62].MyGroup = GROUP_ASPIE_NVC;
  Quiz[63].MyGroup = GROUP_ASPIE_NVC;
  Quiz[64].MyGroup = GROUP_ASPIE_NVC;
  Quiz[65].MyGroup = GROUP_ASPIE_NVC;
  Quiz[66].MyGroup = GROUP_ASPIE_NVC;
  Quiz[67].MyGroup = GROUP_ASPIE_NVC;
  Quiz[68].MyGroup = GROUP_ASPIE_NVC;
  Quiz[69].MyGroup = GROUP_ASPIE_NVC;
  Quiz[70].MyGroup = GROUP_ASPIE_NVC;
  Quiz[71].MyGroup = GROUP_ASPIE_NVC;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ASPIE_NVC;
  Quiz[74].MyGroup = GROUP_ASPIE_NVC;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ASPIE_NVC;
  Quiz[77].MyGroup = GROUP_ASPIE_NVC;
  Quiz[78].MyGroup = GROUP_NT_NVC;
  Quiz[79].MyGroup = GROUP_NT_NVC;
  Quiz[80].MyGroup = GROUP_NT_NVC;
  Quiz[81].MyGroup = GROUP_NT_NVC;
  Quiz[82].MyGroup = GROUP_NT_NVC;
  Quiz[83].MyGroup = GROUP_NT_NVC;
  Quiz[84].MyGroup = GROUP_NT_NVC;
  Quiz[85].MyGroup = GROUP_NT_NVC;
  Quiz[86].MyGroup = GROUP_NT_NVC;
  Quiz[87].MyGroup = GROUP_NT_NVC;
  Quiz[88].MyGroup = GROUP_NT_NVC;
  Quiz[89].MyGroup = GROUP_NT_NVC;
  Quiz[90].MyGroup = GROUP_NT_TALENT;
  Quiz[91].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[92].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[93].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[94].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[95].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[96].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[98].MyGroup = GROUP_SOCIAL;
  Quiz[99].MyGroup = GROUP_MIXED;
  Quiz[100].MyGroup = GROUP_NT_SENSORY;
  Quiz[101].MyGroup = GROUP_NT_SENSORY;
  Quiz[102].MyGroup = GROUP_NT_SENSORY;
  Quiz[103].MyGroup = GROUP_NT_SENSORY;
  Quiz[104].MyGroup = GROUP_NT_SENSORY;
  Quiz[105].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[106].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[107].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[108].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[109].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[110].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[111].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[112].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[113].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[114].MyGroup = GROUP_NT_SENSORY;
  Quiz[115].MyGroup = GROUP_NT_SENSORY;
  Quiz[116].MyGroup = GROUP_NT_SENSORY;
  Quiz[117].MyGroup = GROUP_NT_SENSORY;
  Quiz[118].MyGroup = GROUP_NT_SENSORY;
  Quiz[119].MyGroup = GROUP_NT_HUNTING;
  Quiz[120].MyGroup = GROUP_PARANOID;
  Quiz[121].MyGroup = GROUP_PARANOID;
  Quiz[122].MyGroup = GROUP_PARANOID;
  Quiz[123].MyGroup = GROUP_PARANOID;
  Quiz[124].MyGroup = GROUP_ENVIRONMENT;
  Quiz[125].MyGroup = GROUP_ENVIRONMENT;
  Quiz[126].MyGroup = GROUP_ENVIRONMENT;
  Quiz[127].MyGroup = GROUP_ENVIRONMENT;
  Quiz[128].MyGroup = GROUP_ENVIRONMENT;
  Quiz[129].MyGroup = GROUP_ENVIRONMENT;
  Quiz[130].MyGroup = GROUP_ENVIRONMENT;
  Quiz[131].MyGroup = GROUP_ENVIRONMENT;
  Quiz[132].MyGroup = GROUP_NT_NVC;
  Quiz[133].MyGroup = GROUP_MIXED;
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_MIXED;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_ACTIVITY;
  Quiz[138].MyGroup = GROUP_MIXED;
  Quiz[139].MyGroup = GROUP_MIXED;
  Quiz[140].MyGroup = GROUP_ASPIE_NVC;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[143].MyGroup = GROUP_ASPIE_NVC;
  Quiz[144].MyGroup = GROUP_MIXED;
  Quiz[145].MyGroup = GROUP_NT_TALENT;
  Quiz[146].MyGroup = GROUP_SOCIAL;
  Quiz[147].MyGroup = GROUP_SOCIAL;
  Quiz[148].MyGroup = GROUP_NT_NVC;
  Quiz[149].MyGroup = GROUP_NT_SENSORY;
  Quiz[150].MyGroup = GROUP_NT_SENSORY;
  Quiz[151].MyGroup = GROUP_ENVIRONMENT;

  Quiz[152].MyGroup = GROUP_MIXED;
  Quiz[153].MyGroup = GROUP_MIXED;
  Quiz[154].MyGroup = GROUP_MIXED;
  Quiz[155].MyGroup = GROUP_ACTIVITY;
  Quiz[156].MyGroup = GROUP_MIXED;
  Quiz[157].MyGroup = GROUP_MIXED;

  Quiz[158].MyGroup = GROUP_ACTIVITY;
  Quiz[159].MyGroup = GROUP_ACTIVITY;
  Quiz[160].MyGroup = GROUP_ACTIVITY;
  Quiz[161].MyGroup = GROUP_MIXED;
  Quiz[162].MyGroup = GROUP_ACTIVITY;
  Quiz[163].MyGroup = GROUP_ACTIVITY;
  Quiz[164].MyGroup = GROUP_ACTIVITY;
  Quiz[165].MyGroup = GROUP_ACTIVITY;
  Quiz[166].MyGroup = GROUP_ACTIVITY;
  Quiz[167].MyGroup = GROUP_ACTIVITY;
  Quiz[168].MyGroup = GROUP_ACTIVITY;
  Quiz[169].MyGroup = GROUP_ACTIVITY;
  Quiz[170].MyGroup = GROUP_ACTIVITY;
  Quiz[171].MyGroup = GROUP_ACTIVITY;
  Quiz[172].MyGroup = GROUP_ACTIVITY;
  Quiz[173].MyGroup = GROUP_ACTIVITY;
  Quiz[174].MyGroup = GROUP_ACTIVITY;
  Quiz[175].MyGroup = GROUP_ACTIVITY;
  Quiz[176].MyGroup = GROUP_ENVIRONMENT;
  Quiz[177].MyGroup = GROUP_ACTIVITY;
  Quiz[178].MyGroup = GROUP_NT_NVC;
  Quiz[179].MyGroup = GROUP_ACTIVITY;
  Quiz[180].MyGroup = GROUP_ENVIRONMENT;
  Quiz[181].MyGroup = GROUP_ACTIVITY;
  Quiz[182].MyGroup = GROUP_ACTIVITY;
  Quiz[183].MyGroup = GROUP_ACTIVITY;
  Quiz[184].MyGroup = GROUP_NT_NVC;
  Quiz[185].MyGroup = GROUP_ACTIVITY;
  Quiz[186].MyGroup = GROUP_ACTIVITY;
  Quiz[187].MyGroup = GROUP_ACTIVITY;
  Quiz[188].MyGroup = GROUP_ACTIVITY;
  Quiz[189].MyGroup = GROUP_ACTIVITY;
  Quiz[190].MyGroup = GROUP_ACTIVITY;
  Quiz[191].MyGroup = GROUP_ACTIVITY;
  Quiz[192].MyGroup = GROUP_ACTIVITY;
  Quiz[193].MyGroup = GROUP_ACTIVITY;
  Quiz[194].MyGroup = GROUP_ACTIVITY;
  Quiz[195].MyGroup = GROUP_ACTIVITY;
  Quiz[196].MyGroup = GROUP_ACTIVITY;
  Quiz[197].MyGroup = GROUP_ENVIRONMENT;
  Quiz[198].MyGroup = GROUP_ENVIRONMENT;
  Quiz[199].MyGroup = GROUP_ENVIRONMENT;
  Quiz[200].MyGroup = GROUP_ENVIRONMENT;
  Quiz[201].MyGroup = GROUP_ENVIRONMENT;
  Quiz[202].MyGroup = GROUP_ENVIRONMENT;
  Quiz[203].MyGroup = GROUP_ENVIRONMENT;
  Quiz[204].MyGroup = GROUP_NT_NVC;
  Quiz[205].MyGroup = GROUP_ENVIRONMENT;
  Quiz[206].MyGroup = GROUP_ENVIRONMENT;
  Quiz[207].MyGroup = GROUP_NT_NVC;
  Quiz[208].MyGroup = GROUP_SOCIAL;
  Quiz[209].MyGroup = GROUP_ENVIRONMENT;
  Quiz[210].MyGroup = GROUP_ENVIRONMENT;
  Quiz[211].MyGroup = GROUP_SOCIAL;
  Quiz[212].MyGroup = GROUP_MIXED;
  Quiz[213].MyGroup = GROUP_ENVIRONMENT;
  Quiz[214].MyGroup = GROUP_ENVIRONMENT;
  Quiz[215].MyGroup = GROUP_ACTIVITY;
  Quiz[216].MyGroup = GROUP_ENVIRONMENT;
  Quiz[217].MyGroup = GROUP_ENVIRONMENT;
  Quiz[218].MyGroup = GROUP_ACTIVITY;
  Quiz[219].MyGroup = GROUP_NT_HUNTING;
  Quiz[220].MyGroup = GROUP_NT_HUNTING;
  Quiz[221].MyGroup = GROUP_NT_HUNTING;
  Quiz[222].MyGroup = GROUP_NT_HUNTING;
  Quiz[223].MyGroup = GROUP_NT_SENSORY;
  Quiz[224].MyGroup = GROUP_ENVIRONMENT;
  Quiz[225].MyGroup = GROUP_ENVIRONMENT;
  Quiz[226].MyGroup = GROUP_ENVIRONMENT;
  Quiz[227].MyGroup = GROUP_ENVIRONMENT;
  Quiz[228].MyGroup = GROUP_SOCIAL;
  Quiz[229].MyGroup = GROUP_ACTIVITY;
  Quiz[230].MyGroup = GROUP_ENVIRONMENT;
  Quiz[231].MyGroup = GROUP_ACTIVITY;
  Quiz[232].MyGroup = GROUP_ACTIVITY;
  Quiz[233].MyGroup = GROUP_ENVIRONMENT;
  Quiz[234].MyGroup = GROUP_ACTIVITY;
  Quiz[235].MyGroup = GROUP_ASPIE_SENSORY;

  Quiz[236].MyGroup = GROUP_NT_HUNTING;
  Quiz[237].MyGroup = GROUP_NT_HUNTING;
  Quiz[238].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[239].MyGroup = GROUP_MIXED;
  Quiz[240].MyGroup = GROUP_ACTIVITY;
  Quiz[241].MyGroup = GROUP_SOCIAL;

#ifdef ENGLISH

  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[2].Text = "Have you felt different from others for most of your life?";
  Quiz[3].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[4].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[5].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[6].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[7].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[8].Text = "Do people see you as eccentric?";
  Quiz[9].Text = "Do you have a hyperactive mind?";
  Quiz[10].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[11].Text = "Do you notice patterns in things all the time?";
  Quiz[12].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[13].Text = "Do you tend to do everything worth doing, more perfect than really needed?";
  Quiz[14].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[15].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[16].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[17].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[18].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[19].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[20].Text = "Are you easily distracted?";
  Quiz[21].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[22].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[23].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[24].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[25].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[26].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[27].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[28].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[29].Text = "Do you have certain routines which you need to follow?";
  Quiz[30].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[31].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[32].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[33].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[34].Text = "Are your views typical of your peer group?";
  Quiz[35].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[36].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[37].Text = "Is a large social network important to you?";
  Quiz[38].Text = "Do you enjoy gossip?";
  Quiz[39].Text = "Do you take pride in your appearance?";
  Quiz[40].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[41].Text = "Do you prefer to avoid eye-contact?";
  Quiz[42].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[43].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[44].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[45].Text = "Do you dislike working while being observed?";
  Quiz[46].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[47].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[48].Text = "Do you dislike shaking hands?";
  Quiz[49].Text = "Do people think you are aloof and distant?";
  Quiz[50].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[51].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[52].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[53].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[54].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[55].Text = "Do you enjoy meeting new people?";
  Quiz[56].Text = "Do you find it easy to describe your feelings?";
  Quiz[57].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[58].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[59].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[60].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[61].Text = "Do you often don't know where to put your arms?";
  Quiz[62].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[63].Text = "Have you been accused of staring?";
  Quiz[64].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[65].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[66].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[67].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[68].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[69].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[70].Text = "Do you fiddle with things?";
  Quiz[71].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[72].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[73].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[74].Text = "Do you stutter when stressed?";
  Quiz[75].Text = "Do you talk to yourself?";
  Quiz[76].Text = "Do you clench your fists when angry?";
  Quiz[77].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[78].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[79].Text = "Do others often misunderstand you?";
  Quiz[80].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[81].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[82].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[83].Text = "Are you often surprised what people's motives are ?";
  Quiz[84].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[85].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[86].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[87].Text = "Do you know when you are expected to offer an apology?";
  Quiz[88].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[89].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[90].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[91].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[92].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[93].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[94].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[95].Text = "Do you enjoy walking on your toes?";
  Quiz[96].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[97].Text = "Have you been fascinated about making traps?";
  Quiz[98].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[99].Text = "Do you drop things when your attention is on other things?";
  Quiz[100].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[101].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[102].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[103].Text = "Do you have difficulties with fine motor skills and/or hand-eye co-ordination?";
  Quiz[104].Text = "Did you perceive practical classes like handi-work or gymnasics as hard in school?";
  Quiz[105].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[106].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[107].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[108].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[109].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[110].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[111].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[112].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[113].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[114].Text = "Do you have poor concept of time?";
  Quiz[115].Text = "Do you find it hard to tell the age of people?";
  Quiz[116].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[117].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[118].Text = "Are you good at keeping track of where people are (for instance in team-sports)?";
  Quiz[119].Text = "Do you confuse left and right?";
  Quiz[120].Text = "Do you feel that people are watching you?";
  Quiz[121].Text = "Do you mistake noises for voices?";
  Quiz[122].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[123].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[124].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[125].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[126].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[127].Text = "Are you sometimes afraid in safe situations?";
  Quiz[128].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[129].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[130].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[131].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[132].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[133].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[134].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[135].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[136].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[137].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[138].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[139].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[140].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[141].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[142].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[143].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[144].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[145].Text = "Can you easily remember verbal instructions?";
  Quiz[146].Text = "Do people understand you?";
  Quiz[147].Text = "Are you good at teamwork?";
  Quiz[148].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[149].Text = "Do you find it easy to estimate the age of people?";
  Quiz[150].Text = "Do you have a good sense of what time it is?";
  Quiz[151].Text = "Are you gracious about criticism, correction and direction?";

  Quiz[152].Text = "Has there been a period of time when you were not your usual self and you did things that were unusual for you?";
  Quiz[153].Text = "Has there been a period of time when you were not your usual self and you were so irritable that you shouted at people or started fights or arguments?";
  Quiz[154].Text = "Has there been a period of time when you were not your usual self and you were much more talkative than usual?";
  Quiz[155].Text = "Has there been a period of time when you were not your usual self and spending money got you or your family into trouble?";
  Quiz[156].Text = "Has there been a period of time when you were not your usual self and you were much more social or outgoing than usual?";
  Quiz[157].Text = "Do you have less body-hair than others of your gender?";

  Quiz[158].Text = "ADD - History of ADD symptoms in childhood, such as distractibility, short attention span, impulsivity or restlessness. ADD doesn't start at age 30.";
  Quiz[159].Text = "ADD - History of not living up to potential in school or work (report cards with comments such as 'not living up to potential')";
  Quiz[160].Text = "ADD - History of frequent behavior problems in school (mostly for males)";
  Quiz[161].Text = "ADD - History of bed wetting past age 5";
  Quiz[162].Text = "ADD - Family history of ADD, learning problems, mood disorders or substance abuse problems";
  Quiz[163].Text = "ADD - Short attention span, unless very interested in something";
  Quiz[164].Text = "ADD - Easily distracted, tendency to drift away (although at times can be hyper focused)";
  Quiz[165].Text = "ADD - Lacks attention to detail, due to distractibility";
  Quiz[166].Text = "ADD - Trouble listening carefully to directions";
  Quiz[167].Text = "ADD - Frequently misplaces things";
  Quiz[168].Text = "ADD - Skips around while reading, or goes to the end first, trouble staying on track";
  Quiz[169].Text = "ADD - Difficulty learning new games, because it is hard to stay on track during directions";
  Quiz[170].Text = "ADD - Easily distracted during sex, causing frequent breaks or turn-offs during lovemaking";
  Quiz[171].Text = "ADD - Poor listening skills";
  Quiz[172].Text = "ADD - Tendency to be easily bored (tunes out)";
  Quiz[173].Text = "ADD - Restlessness, constant motion, legs moving, fidgetiness";
  Quiz[174].Text = "ADD - Has to be moving in order to think";
  Quiz[175].Text = "ADD - Trouble sitting still, such as trouble sitting in one place for too long, sitting at a desk job for long periods, sitting through a movie";
  Quiz[176].Text = "ADD - An internal sense of anxiety or nervousness";
  Quiz[177].Text = "ADD - Impulsive, in words and/or actions (spending)";
  Quiz[178].Text = "ADD - Say just what comes to mind without considering its impact (tactless)";
  Quiz[179].Text = "ADD - Trouble going through established channels, trouble following proper procedure, an attitude of 'read the directions when all else fails'";
  Quiz[180].Text = "ADD - Impatient, low frustration tolerance";
  Quiz[181].Text = "ADD - A prisoner of the moment";
  Quiz[182].Text = "ADD - Frequent traffic violations";
  Quiz[183].Text = "ADD - Frequent, impulsive job changes";
  Quiz[184].Text = "ADD - Tendency to embarrass others";
  Quiz[185].Text = "ADD - Lying or stealing on impulse";
  Quiz[186].Text = "ADD - Poor organization and planning, trouble maintaining an organized work/living area";
  Quiz[187].Text = "ADD - Chronically late or chronically in a hurry";
  Quiz[188].Text = "ADD - Often have piles of stuff";
  Quiz[189].Text = "ADD - Easily overwhelmed by tasks of daily living";
  Quiz[190].Text = "ADD - Poor financial management (late bills, check book a mess, spending unnecessary money on late fees)";
  Quiz[191].Text = "ADD - Some adults with ADD are very successful, but often only if they are surrounded with people who organize them.";
  Quiz[192].Text = "ADD - Chronic procrastination or trouble getting started";
  Quiz[193].Text = "ADD - Starting projects but not finishing them, poor follow through";
  Quiz[194].Text = "ADD - Enthusiastic beginnings but poor endings";
  Quiz[195].Text = "ADD - Spends excessive time at work because of inefficiencies";
  Quiz[196].Text = "ADD - Inconsistent work performance";
  Quiz[197].Text = "ADD - Chronic sense of underachievement, feeling you should be much further along in your life than you are";
  Quiz[198].Text = "ADD - Chronic problems with self-esteem";
  Quiz[199].Text = "ADD - Sense of impending doom";
  Quiz[200].Text = "ADD - Mood swings";
  Quiz[201].Text = "ADD - Negativity";
  Quiz[202].Text = "ADD - Frequent feeling of demoralization or that things won't work out for you";
  Quiz[203].Text = "ADD - Trouble sustaining friendships or intimate relationships, promiscuity";
  Quiz[204].Text = "ADD - Trouble with intimacy";
  Quiz[205].Text = "ADD - Tendency to be immature";
  Quiz[206].Text = "ADD - Self-centered; immature interests";
  Quiz[207].Text = "ADD - Failure to see others' needs or activities as important";
  Quiz[208].Text = "ADD - Lack of talking in a relationship";
  Quiz[209].Text = "ADD - Verbally abusive to others";
  Quiz[210].Text = "ADD - Proneness to hysterical outburst";
  Quiz[211].Text = "ADD - Avoids group activities";
  Quiz[212].Text = "ADD - Trouble with authority";
  Quiz[213].Text = "ADD - Quick responses to slights that are real or imagined";
  Quiz[214].Text = "ADD - Rage outbursts, short fuse";
  Quiz[215].Text = "ADD - Frequent search for high stimulation (bungee jumping, gambling, race track, high stress jobs, ER doctors, doing many things at once, etc.)";
  Quiz[216].Text = "ADD - Tendency to seek conflict, be argumentative or to start disagreements for the fun of it";
  Quiz[217].Text = "ADD - Tendency to worry needlessly and endlessly";
  Quiz[218].Text = "ADD - Tendency toward addictions (food, alcohol, drugs, work)";
  Quiz[219].Text = "ADD - Switches around numbers, letters or words";
  Quiz[220].Text = "ADD - Turn words around in conversations";
  Quiz[221].Text = "ADD - Poor writing skills (hard to get information from brain to pen)";
  Quiz[222].Text = "ADD - Poor handwriting, often prints";
  Quiz[223].Text = "ADD - Coordination difficulties";
  Quiz[224].Text = "ADD - Performance becomes worse under pressure'";
  Quiz[225].Text = "ADD - Test anxiety, or during tests your mind tends to go blank";
  Quiz[226].Text = "ADD - The harder you try, the worse it gets";
  Quiz[227].Text = "ADD - Work or schoolwork deteriorates under pressure";
  Quiz[228].Text = "ADD - Tendency to turn off or become stuck when asked questions in social situation";
  Quiz[229].Text = "ADD - Falls asleep or becomes tired while reading";
  Quiz[230].Text = "ADD - Difficulties falling asleep, may be due to too many thoughts at night";
  Quiz[231].Text = "ADD - Difficulty coming awake (may need coffee or other stimulant or activity before feeling fully awake)";
  Quiz[232].Text = "ADD - Periods of low energy, especially early in the morning and in the afternoon";
  Quiz[233].Text = "ADD - Frequently feeling tired";
  Quiz[234].Text = "ADD - Startles easily";
  Quiz[235].Text = "ADD - Sensitive to touch, clothes, noise and light";

  Quiz[236].Text = "Dyslexia";
  Quiz[237].Text = "Dyscalculia";
  Quiz[238].Text = "OCD";
  Quiz[239].Text = "ODD";
  Quiz[240].Text = "Bipolar";
  Quiz[241].Text = "Social phobia";

#endif

#ifdef SWEDISH

  Quiz[0].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[1].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[2].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[3].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[4].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[5].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[6].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[7].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[8].Text = "Tycker folk att du är excentrisk?";
  Quiz[9].Text = "Är du mentalt hyperaktiv?";
  Quiz[10].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[11].Text = "Ser du mönster i saker hela tiden?";
  Quiz[12].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[13].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[14].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[15].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[16].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[17].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[18].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[19].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[20].Text = "Blir du lätt distraherad?";
  Quiz[21].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[22].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[23].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[24].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[25].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[26].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[27].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[28].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[29].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[30].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[31].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[32].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[33].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[34].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[35].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[36].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[37].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[38].Text = "Tycker du om skvaller?";
  Quiz[39].Text = "Är du stolt över ditt utseende?";
  Quiz[40].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[41].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[42].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[43].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[44].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[45].Text = "Ogillar du att andra tittar på när du arbetar?";
  Quiz[46].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[47].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[48].Text = "Ogillar du att behöva ta i hand?";
  Quiz[49].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[50].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[51].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[52].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[53].Text = "Trivs du i romantiska situationer?";
  Quiz[54].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[55].Text = "Trivs du med att möta nya människor?";
  Quiz[56].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[57].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[58].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[59].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[60].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[61].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[62].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[63].Text = "Har du blivit anklagad för att stirra?";
  Quiz[64].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[65].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[66].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[67].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[68].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[69].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[70].Text = "Brukar du fingra på saker?";
  Quiz[71].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[72].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[73].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[74].Text = "Stammar du när du blir stressad?";
  Quiz[75].Text = "Brukar du prata med dig själv?";
  Quiz[76].Text = "Knyter du nävarna när du är arg?";
  Quiz[77].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[78].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[79].Text = "Blir du ofta missförstådd av andra?";
  Quiz[80].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[81].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[82].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[83].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[84].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[85].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[86].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[87].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[88].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[89].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[90].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[91].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[92].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[93].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[94].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[95].Text = "Gillar du att gå på tå?";
  Quiz[96].Text = "Gillar du att härma djurläten?";
  Quiz[97].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[98].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[99].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[100].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[101].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[102].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[103].Text = "Har du problem med finmotorik och/eller öga-hand koordination?";
  Quiz[104].Text = "Tyckte du praktiska ämnen som slöjd och gymnastik var svårt i skolan?";
  Quiz[105].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[106].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[107].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[108].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[109].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[110].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[111].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[112].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[113].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[114].Text = "Har du dålig tidsuppfattning?";
  Quiz[115].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[116].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[117].Text = "Har du svårt att känna igen ansikten?";
  Quiz[118].Text = "Är du bra på att hålla reda på var folk är (t.ex. i bollsporter)?";
  Quiz[119].Text = "Brukar du blanda ihop höger och vänster?";
  Quiz[120].Text = "Tycker du att folk bevakar dig?";
  Quiz[121].Text = "Misstar du ljud för röster?";
  Quiz[122].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[123].Text = "Har du haft långvariga hämndbegär?";
  Quiz[124].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[125].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[126].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[127].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[128].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[129].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[130].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[131].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[132].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[133].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[134].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[135].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[136].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[137].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[138].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[139].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[140].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[141].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[142].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[143].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[144].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[145].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[146].Text = "Förstår sig folk på dig?";
  Quiz[147].Text = "Är du bra på att arbeta i grupp?";
  Quiz[148].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[149].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[150].Text = "Har du ett bra sinne för hur mycket klockan är?";
  Quiz[151].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";

  Quiz[152].Text = "Har det funnits en tid då du inte var dig själv och då du gjorde saker som var ovanliga för dig?";
  Quiz[153].Text = "Har det funnits en tid då du inte var dig själv och då du var så irritabel att du skrek åt folk eller startade bråk?";
  Quiz[154].Text = "Har det funnits en tid då du inte var dig själv och då du var mer pratsam än vanligt?";
  Quiz[155].Text = "Har det funnits en tid då du inte var dig själv och att du gjorde av med så mycket pengar att du eller din familj hamnade i knipa?";
  Quiz[156].Text = "Har det funnits en tid då du inte var dig själv och att du var mycket mer social och utåtriktad än normalt?";
  Quiz[157].Text = "Har du mindre kroppshår än andra av samma kön som dig själv?";

  Quiz[158].Text = "ADD - History of ADD symptoms in childhood, such as distractibility, short attention span, impulsivity or restlessness. ADD doesn't start at age 30.";
  Quiz[159].Text = "ADD - History of not living up to potential in school or work (report cards with comments such as 'not living up to potential')";
  Quiz[160].Text = "ADD - History of frequent behavior problems in school (mostly for males)";
  Quiz[161].Text = "ADD - History of bed wetting past age 5";
  Quiz[162].Text = "ADD - Family history of ADD, learning problems, mood disorders or substance abuse problems";
  Quiz[163].Text = "ADD - Short attention span, unless very interested in something";
  Quiz[164].Text = "ADD - Easily distracted, tendency to drift away (although at times can be hyper focused)";
  Quiz[165].Text = "ADD - Lacks attention to detail, due to distractibility";
  Quiz[166].Text = "ADD - Trouble listening carefully to directions";
  Quiz[167].Text = "ADD - Frequently misplaces things";
  Quiz[168].Text = "ADD - Skips around while reading, or goes to the end first, trouble staying on track";
  Quiz[169].Text = "ADD - Difficulty learning new games, because it is hard to stay on track during directions";
  Quiz[170].Text = "ADD - Easily distracted during sex, causing frequent breaks or turn-offs during lovemaking";
  Quiz[171].Text = "ADD - Poor listening skills";
  Quiz[172].Text = "ADD - Tendency to be easily bored (tunes out)";
  Quiz[173].Text = "ADD - Restlessness, constant motion, legs moving, fidgetiness";
  Quiz[174].Text = "ADD - Has to be moving in order to think";
  Quiz[175].Text = "ADD - Trouble sitting still, such as trouble sitting in one place for too long, sitting at a desk job for long periods, sitting through a movie";
  Quiz[176].Text = "ADD - An internal sense of anxiety or nervousness";
  Quiz[177].Text = "ADD - Impulsive, in words and/or actions (spending)";
  Quiz[178].Text = "ADD - Say just what comes to mind without considering its impact (tactless)";
  Quiz[179].Text = "ADD - Trouble going through established channels, trouble following proper procedure, an attitude of 'read the directions when all else fails'";
  Quiz[180].Text = "ADD - Impatient, low frustration tolerance";
  Quiz[181].Text = "ADD - A prisoner of the moment";
  Quiz[182].Text = "ADD - Frequent traffic violations";
  Quiz[183].Text = "ADD - Frequent, impulsive job changes";
  Quiz[184].Text = "ADD - Tendency to embarrass others";
  Quiz[185].Text = "ADD - Lying or stealing on impulse";
  Quiz[186].Text = "ADD - Poor organization and planning, trouble maintaining an organized work/living area";
  Quiz[187].Text = "ADD - Chronically late or chronically in a hurry";
  Quiz[188].Text = "ADD - Often have piles of stuff";
  Quiz[189].Text = "ADD - Easily overwhelmed by tasks of daily living";
  Quiz[190].Text = "ADD - Poor financial management (late bills, check book a mess, spending unnecessary money on late fees)";
  Quiz[191].Text = "ADD - Some adults with ADD are very successful, but often only if they are surrounded with people who organize them.";
  Quiz[192].Text = "ADD - Chronic procrastination or trouble getting started";
  Quiz[193].Text = "ADD - Starting projects but not finishing them, poor follow through";
  Quiz[194].Text = "ADD - Enthusiastic beginnings but poor endings";
  Quiz[195].Text = "ADD - Spends excessive time at work because of inefficiencies";
  Quiz[196].Text = "ADD - Inconsistent work performance";
  Quiz[197].Text = "ADD - Chronic sense of underachievement, feeling you should be much further along in your life than you are";
  Quiz[198].Text = "ADD - Chronic problems with self-esteem";
  Quiz[199].Text = "ADD - Sense of impending doom";
  Quiz[200].Text = "ADD - Mood swings";
  Quiz[201].Text = "ADD - Negativity";
  Quiz[202].Text = "ADD - Frequent feeling of demoralization or that things won't work out for you";
  Quiz[203].Text = "ADD - Trouble sustaining friendships or intimate relationships, promiscuity";
  Quiz[204].Text = "ADD - Trouble with intimacy";
  Quiz[205].Text = "ADD - Tendency to be immature";
  Quiz[206].Text = "ADD - Self-centered; immature interests";
  Quiz[207].Text = "ADD - Failure to see others' needs or activities as important";
  Quiz[208].Text = "ADD - Lack of talking in a relationship";
  Quiz[209].Text = "ADD - Verbally abusive to others";
  Quiz[210].Text = "ADD - Proneness to hysterical outburst";
  Quiz[211].Text = "ADD - Avoids group activities";
  Quiz[212].Text = "ADD - Trouble with authority";
  Quiz[213].Text = "ADD - Quick responses to slights that are real or imagined";
  Quiz[214].Text = "ADD - Rage outbursts, short fuse";
  Quiz[215].Text = "ADD - Frequent search for high stimulation (bungee jumping, gambling, race track, high stress jobs, ER doctors, doing many things at once, etc.)";
  Quiz[216].Text = "ADD - Tendency to seek conflict, be argumentative or to start disagreements for the fun of it";
  Quiz[217].Text = "ADD - Tendency to worry needlessly and endlessly";
  Quiz[218].Text = "ADD - Tendency toward addictions (food, alcohol, drugs, work)";
  Quiz[219].Text = "ADD - Switches around numbers, letters or words";
  Quiz[220].Text = "ADD - Turn words around in conversations";
  Quiz[221].Text = "ADD - Poor writing skills (hard to get information from brain to pen)";
  Quiz[222].Text = "ADD - Poor handwriting, often prints";
  Quiz[223].Text = "ADD - Coordination difficulties";
  Quiz[224].Text = "ADD - Performance becomes worse under pressure'";
  Quiz[225].Text = "ADD - Test anxiety, or during tests your mind tends to go blank";
  Quiz[226].Text = "ADD - The harder you try, the worse it gets";
  Quiz[227].Text = "ADD - Work or schoolwork deteriorates under pressure";
  Quiz[228].Text = "ADD - Tendency to turn off or become stuck when asked questions in social situation";
  Quiz[229].Text = "ADD - Falls asleep or becomes tired while reading";
  Quiz[230].Text = "ADD - Difficulties falling asleep, may be due to too many thoughts at night";
  Quiz[231].Text = "ADD - Difficulty coming awake (may need coffee or other stimulant or activity before feeling fully awake)";
  Quiz[232].Text = "ADD - Periods of low energy, especially early in the morning and in the afternoon";
  Quiz[233].Text = "ADD - Frequently feeling tired";
  Quiz[234].Text = "ADD - Startles easily";
  Quiz[235].Text = "ADD - Sensitive to touch, clothes, noise and light";

  Quiz[236].Text = "Dyslexi";
  Quiz[237].Text = "Dyskaluli";
  Quiz[238].Text = "OCD";
  Quiz[239].Text = "ODD";
  Quiz[240].Text = "Bipolär";
  Quiz[241].Text = "Social fobi";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS9::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
	AddReferer("circvsmaximvs.com", "circvsmaximvs.com/showthread.php?t=14129");
	AddReferer("panterachat.com", "panterachat.com/phpBB/viewtopic.php?t=24332");
	AddReferer("kaytastrophe.com", "kaytastrophe.com/index.php?topic=708.0");
	AddReferer("tbg.nu", "tbg.nu/news_show/109118/40");
	AddReferer("vof.se", "vof.se/forum/viewtopic.php?t=3080");
	AddReferer("autismspeaks.org", "autismspeaks.org/community/forums");
	AddReferer("nordisk.nu", "nordisk.nu/showthread.php?t=3117");
	AddReferer("swedvdr.org", "swedvdr.org/forums.php?action=viewtopic");
	AddReferer("filmtipset.se", "filmtipset.se/forum.cgi?id=1339244");
	AddReferer("tvsushi.com", "forum.tvsushi.com/index.php?showtopic=52752");
	AddReferer("smogon.com", "smogon.com/forums/showthread.php?t=29171");
	AddReferer("mommyconnection.org", "mommyconnection.org/board/index.php/topic,2840.0.html");
	AddReferer("calientemamas.com", "calientemamas.com/forum_posts.asp?TID=12136");
	AddReferer("forums.britxbox.co.uk", "forums.britxbox.co.uk/viewtopic.php?t=54722");
	AddReferer("goonfleet.com", "goonfleet.com/showthread.php?t=77152");
}

/*##################  TQuizS9::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD >= 1)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.TS >= 1)
			UpdateReferer(&DxTsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyslexia >= 1)
			UpdateReferer(&DyslexiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyscalculia >= 1)
			UpdateReferer(&DyscalculiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.OCD >= 1)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ODD >= 1)
			UpdateReferer(&ODDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Bipolar >= 1)
			UpdateReferer(&BipolarRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Schizophrenia >= 1)
			UpdateReferer(&SchizophreniaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Social >= 1)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizS9::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::LoadPopulations()
{
	TQuizRow Row;
	int i;
	int id;
	TReferer *ref;
	int aspie;
	char score;
	int IdArr[MAX_QUESTIONS];

	for (i = 0; i < N; i++)
	{
		Quiz[i].NoAnswer = 0;
		IdArr[i] = GetGlobalId(i);
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		BirthMonth.Add(Row.AsResult, Row.NtResult, Row.BirthMonth);

		Row.Quiz[236] = Row.Dyslexia + 1;
		Row.Quiz[237] = Row.Dyscalculia + 1;
		Row.Quiz[238] = Row.OCD + 1;
		Row.Quiz[239] = Row.ODD + 1;
		Row.Quiz[240] = Row.Bipolar + 1;
		Row.Quiz[241] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 236)
				{
					score = Row.Quiz[i] - 1;
					id = IdArr[i];

					DsmAutism.Add(Row.Autism, id, score);
					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
					DsmTs.Add(Row.TS, id, score);
					DsmDyslexia.Add(Row.Dyslexia, id, score);
					DsmDyscalculia.Add(Row.Dyscalculia, id, score);
					DsmOCD.Add(Row.OCD, id, score);
					DsmODD.Add(Row.ODD, id, score);
					DsmBipolar.Add(Row.Bipolar, id, score);
					DsmSchizophrenia.Add(Row.Schizophrenia, id, score);
					DsmSocialPhobia.Add(Row.Social, id, score);
				}
			}
		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (Row.ADHD >= 1)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (Row.TS >= 1)
			Ts.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Dyslexia >= 1)
			Dyslexia.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Dyscalculia >= 1)
			Dyscalculia.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.OCD >= 1)
			OCD.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.ODD >= 1)
			ODD.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Bipolar >= 1)
			Bipolar.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Schizophrenia >= 1)
			Schizophrenia.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Social >= 1)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);
		}

	}
}

/*##########################################################################
#
#   Name       : TQuizS9::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");
	DefineNt("tbg.nu");
	DefineNt("vof.se");
	DefineNt("nordisk.nu");
	DefineNt("swedvdr.org");
	DefineNt("filmtipset.se");
	DefineNt("tvsushi.com");
	DefineNt("smogon.com");
	DefineNt("mommyconnection.org");
	DefineNt("calientemamas.com");
	DefineNt("forums.britxbox.co.uk");
	DefineNt("goonfleet.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizS9::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8)
{
    DefineCross(QuizS8, 0, 1);
	DefineCross(QuizS8, 1, 2);
    DefineCross(QuizS8, 2, 39);
	DefineCross(QuizS8, 3, 3);
	DefineCross(QuizS8, 4, 5);
    DefineCross(QuizS8, 5, 6);
    DefineCross(QuizS8, 6, 4);
    DefineCross(QuizS8, 7, 7);
    DefineCross(QuizS8, 8, 8);
    DefineCross(QuizS8, 9, 9);
    DefineCross(QuizS8, 10, 10);
    DefineCross(QuizS8, 11, 11);
    DefineCross(QuizS8, 12, 12);
    DefineCross(QuizS8, 13, 13);
    DefineCross(QuizS8, 14, 14);
    DefineCross(QuizS8, 15, 15);
    DefineCross(QuizS8, 16, 16);
    DefineCross(QuizS8, 17, 17);
    DefineCross(QuizS8, 18, 18);
    DefineCross(QuizS8, 19, 19);
    DefineCross(QuizS8, 20, 20);
	DefineCross(QuizS8, 21, 21);
    DefineCross(QuizS8, 22, 22);
    DefineCross(QuizS8, 23, 23);
    DefineCross(QuizS8, 24, 0);
    DefineCross(QuizS8, 25, 24);
    DefineCross(QuizS8, 26, 25);
    DefineCross(QuizS8, 27, 26);
	DefineCross(QuizS8, 28, 27);
    DefineCross(QuizS8, 29, 28);
    DefineCross(QuizS8, 30, 29);
	DefineCross(QuizS8, 31, 30);
    DefineCross(QuizS8, 32, 31);
    DefineCross(QuizS8, 33, 56);
    DefineCross(QuizS8, 34, 57);
    DefineCross(QuizS8, 35, 32);
    DefineCross(QuizS8, 36, 60);
    DefineCross(QuizS8, 37, 33);
	DefineCross(QuizS8, 38, 34);
    DefineCross(QuizS8, 39, 35);
    DefineCross(QuizS8, 40, 38);
    DefineCross(QuizS8, 41, 50);
    DefineCross(QuizS8, 42, 42);
    DefineCross(QuizS8, 43, 46);
    DefineCross(QuizS8, 44, 47);
    DefineCross(QuizS8, 45, 147);
    DefineCross(QuizS8, 46, 49);
    DefineCross(QuizS8, 47, 40);
	DefineCross(QuizS8, 48, 41);
    DefineCross(QuizS8, 49, 43);
    DefineCross(QuizS8, 50, 44);
    DefineCross(QuizS8, 51, 51);
    DefineCross(QuizS8, 52, 52);
    DefineCross(QuizS8, 53, 53);
    DefineCross(QuizS8, 54, 54);
	DefineCross(QuizS8, 55, 55);
    DefineCross(QuizS8, 56, 58);
    DefineCross(QuizS8, 57, 59);
	DefineCross(QuizS8, 58, 63);
    DefineCross(QuizS8, 59, 62);
    DefineCross(QuizS8, 60, 64);
    DefineCross(QuizS8, 61, 65);
    DefineCross(QuizS8, 62, 66);
    DefineCross(QuizS8, 63, 67);
    DefineCross(QuizS8, 64, 68);
    DefineCross(QuizS8, 65, 69);
    DefineCross(QuizS8, 66, 70);
    DefineCross(QuizS8, 67, 71);
    DefineCross(QuizS8, 68, 73);
    DefineCross(QuizS8, 69, 74);
    DefineCross(QuizS8, 70, 75);
    DefineCross(QuizS8, 71, 76);
    DefineCross(QuizS8, 72, 77);
	DefineCross(QuizS8, 73, 78);
    DefineCross(QuizS8, 74, 79);
	DefineCross(QuizS8, 75, 80);
    DefineCross(QuizS8, 76, 81);
    DefineCross(QuizS8, 77, 149);
    DefineCross(QuizS8, 78, 82);
    DefineCross(QuizS8, 79, 83);
    DefineCross(QuizS8, 80, 84);
    DefineCross(QuizS8, 81, 85);
	DefineCross(QuizS8, 82, 86);
    DefineCross(QuizS8, 83, 87);
    DefineCross(QuizS8, 84, 88);
	DefineCross(QuizS8, 85, 89);
    DefineCross(QuizS8, 86, 90);
    DefineCross(QuizS8, 87, 91);
    DefineCross(QuizS8, 88, 92);
    DefineCross(QuizS8, 89, 93);
    DefineCross(QuizS8, 90, 94);
    DefineCross(QuizS8, 91, 72);
    DefineCross(QuizS8, 92, 95);
    DefineCross(QuizS8, 93, 96);
    DefineCross(QuizS8, 94, 97);
    DefineCross(QuizS8, 95, 98);
    DefineCross(QuizS8, 96, 100);
    DefineCross(QuizS8, 97, 99);
    DefineCross(QuizS8, 98, 101);
    DefineCross(QuizS8, 99, 102);
    DefineCross(QuizS8, 100, 103);
    DefineCross(QuizS8, 101, 104);
	DefineCross(QuizS8, 102, 105);
    DefineCross(QuizS8, 103, 106);
    DefineCross(QuizS8, 104, 107);
    DefineCross(QuizS8, 105, 108);
    DefineCross(QuizS8, 106, 109);
    DefineCross(QuizS8, 107, 110);
	DefineCross(QuizS8, 108, 111);
	DefineCross(QuizS8, 109, 141);
    DefineCross(QuizS8, 110, 112);
    DefineCross(QuizS8, 111, 113);
	DefineCross(QuizS8, 112, 114);
    DefineCross(QuizS8, 113, 115);
    DefineCross(QuizS8, 114, 116);
    DefineCross(QuizS8, 115, 117);
    DefineCross(QuizS8, 116, 118);
    DefineCross(QuizS8, 117, 119);
    DefineCross(QuizS8, 118, 120);
    DefineCross(QuizS8, 119, 121);
    DefineCross(QuizS8, 120, 122);
    DefineCross(QuizS8, 121, 123);
    DefineCross(QuizS8, 122, 124);
    DefineCross(QuizS8, 123, 125);
    DefineCross(QuizS8, 124, 126);
    DefineCross(QuizS8, 125, 127);
    DefineCross(QuizS8, 126, 128);
    DefineCross(QuizS8, 127, 129);
    DefineCross(QuizS8, 128, 130);
	DefineCross(QuizS8, 129, 131);
    DefineCross(QuizS8, 130, 132);
    DefineCross(QuizS8, 131, 133);
    DefineCross(QuizS8, 132, 134);
    DefineCross(QuizS8, 133, 135);
    DefineCross(QuizS8, 134, 136);
    DefineCross(QuizS8, 135, 137);
	DefineCross(QuizS8, 136, 138);
    DefineCross(QuizS8, 137, 139);
    DefineCross(QuizS8, 138, 142);
	DefineCross(QuizS8, 139, 140);
    DefineCross(QuizS8, 140, 143);
    DefineCross(QuizS8, 141, 144);
    DefineCross(QuizS8, 142, 145);
	DefineCross(QuizS8, 143, 146);
	DefineCross(QuizS8, 144, 148);
	DefineCross(QuizS8, 145, 150);
	DefineCross(QuizS8, 146, 151);
	DefineCross(QuizS8, 147, 152);
	DefineCross(QuizS8, 148, 153);
	DefineCross(QuizS8, 149, 154);
	DefineCross(QuizS8, 150, 155);
	DefineCross(QuizS8, 151, 156);

	DefineGlobalId(152, 956);
	DefineGlobalId(153, 957);
	DefineGlobalId(154, 958);
	DefineGlobalId(155, 959);
	DefineGlobalId(156, 960);
	DefineGlobalId(157, 961);
	DefineGlobalId(158, 962);
	DefineGlobalId(159, 963);
	DefineGlobalId(160, 964);
	DefineGlobalId(161, 965);
	DefineGlobalId(162, 966);
	DefineGlobalId(163, 967);
	DefineGlobalId(164, 968);
	DefineGlobalId(165, 969);
	DefineGlobalId(166, 970);
	DefineGlobalId(167, 971);
	DefineGlobalId(168, 972);
	DefineGlobalId(169, 973);
	DefineGlobalId(170, 974);
	DefineGlobalId(171, 975);
	DefineGlobalId(172, 976);
	DefineGlobalId(173, 977);
	DefineGlobalId(174, 978);
	DefineGlobalId(175, 979);
	DefineGlobalId(176, 980);
	DefineGlobalId(177, 981);
	DefineGlobalId(178, 982);
	DefineGlobalId(179, 983);
	DefineGlobalId(180, 984);
	DefineGlobalId(181, 985);
	DefineGlobalId(182, 986);
	DefineGlobalId(183, 987);
	DefineGlobalId(184, 988);
	DefineGlobalId(185, 989);
	DefineGlobalId(186, 990);
	DefineGlobalId(187, 991);
	DefineGlobalId(188, 992);
	DefineGlobalId(189, 993);
	DefineGlobalId(190, 994);
	DefineGlobalId(191, 995);
	DefineGlobalId(192, 996);
	DefineGlobalId(193, 997);
	DefineGlobalId(194, 998);
	DefineGlobalId(195, 999);
	DefineGlobalId(196, 1000);
	DefineGlobalId(197, 1001);
	DefineGlobalId(198, 1002);
	DefineGlobalId(199, 1003);
	DefineGlobalId(200, 1004);
	DefineGlobalId(201, 1005);
	DefineGlobalId(202, 1006);
	DefineGlobalId(203, 1007);
	DefineGlobalId(204, 1008);
	DefineGlobalId(205, 1009);
	DefineGlobalId(206, 1010);
	DefineGlobalId(207, 1011);
	DefineGlobalId(208, 1012);
	DefineGlobalId(209, 1013);
	DefineGlobalId(210, 1014);
	DefineGlobalId(211, 1015);
	DefineGlobalId(212, 1016);
	DefineGlobalId(213, 1017);
	DefineGlobalId(214, 1018);
	DefineGlobalId(215, 1019);
	DefineGlobalId(216, 1020);
	DefineGlobalId(217, 1021);
	DefineGlobalId(218, 1022);
	DefineGlobalId(219, 1023);
	DefineGlobalId(220, 1024);
	DefineGlobalId(221, 1025);
	DefineGlobalId(222, 1026);
	DefineGlobalId(223, 1027);
	DefineGlobalId(224, 1028);
	DefineGlobalId(225, 1029);
	DefineGlobalId(226, 1030);
	DefineGlobalId(227, 1031);
	DefineGlobalId(228, 1032);
	DefineGlobalId(229, 1033);
	DefineGlobalId(230, 1034);
	DefineGlobalId(231, 1035);
	DefineGlobalId(232, 1036);
	DefineGlobalId(233, 1037);
	DefineGlobalId(234, 1038);
	DefineGlobalId(235, 1039);

	DefineCross(QuizS8, 236, 172);
	DefineCross(QuizS8, 237, 173);
	DefineCross(QuizS8, 238, 174);
	DefineCross(QuizS8, 239, 175);
	DefineCross(QuizS8, 240, 176);
	DefineCross(QuizS8, 241, 177);
}

/*##########################################################################
#
#   Name       : TQuizS9::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS9::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Gender, Row.Quiz, Row.GroupResult);
}

/*##################  IsPca ##########################
*   Purpose....: Check quiz row against pca-type                 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int IsPca(TQuizRow *row, int PcaType)
{
    switch (PcaType)
	{
		case PCA_TYPE_ALL:
		case PCA_TYPE_MIXED:
            return TRUE;

		case PCA_TYPE_MALE:
			if (row->Gender == 1)
                return TRUE;
			else
                return FALSE;

        case PCA_TYPE_FEMALE:
			if (row->Gender == 2)
				return TRUE;
			else
                return FALSE;

        case PCA_TYPE_YOUNG:
			if (row->BirthYear >= 1980)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear <= 1965)
                return TRUE;
			else
				return FALSE;

		case PCA_TYPE_AS:
				if (row->Autism == 2 || row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizS9::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GetQuizN(); i++)
	{
		if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
		{
			file.Write("\"");

//  	      strncpy(str, Quiz[i].Text, 35);
//      	  str[35] = 0;
			sprintf(str, "#%d", i + 1);
			file.Write(str);

			file.Write("\"");
			if (i != N - 1)
				file.Write(", ");
		}
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (IsPca(&Row, PcaType))
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GetQuizN(); i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
    				ival = Row.Quiz[i];
	    			if (ival)
						ival--;
    
					if (ival > 2)
						ival = 0;
                    
					sprintf(str, "\"%d\"", ival);
					file.Write(str);
					if (i != GetQuizN() - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizS9::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::ExportExcelAspie(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		file.Write("\"");

		sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != N - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.AddResult)
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				ival = Row.Quiz[i];

				if (ival)
				{
					if (Quiz[i].Reverse)
						ival = GetCatCount(i) - ival;
					else
						ival--;
				}


				if (ival >= GetCatCount(i))
					ival = 0;

				sprintf(str, "\"%d\"", ival);
				file.Write(str);
    			if (i != N - 1)
	    			file.Write(", ");
	    	}
    		file.Write("\n");
        }
	}
}

/*##################  TQuizS9::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::ExportExcelGroups(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	int group;
	int ok;
	char str[80];
	TFile file(filename, 0);
	int GroupSum[GROUP_COUNT];
	int GroupCount[GROUP_COUNT];

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GROUP_COUNT; i++)
	{
		file.Write("\"");

		strncpy(str, Group[i].PosName, 35);
		str[35] = 0;
//        sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != GROUP_COUNT - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < GROUP_COUNT; i++)
		{
			GroupSum[i] = 0;
			GroupCount[i] = 0;
		}

		for (i = 0; i < GetQuizN(); i++)
		{
			ival = Row.Quiz[i];

			if (ival)
			{
				if (Quiz[i].Reverse)
					ival = 3 - ival;
				else
					ival--;
				group = Quiz[i].MyGroup;
				GroupSum[group] += ival;
				GroupCount[group]++;
			}
		}

		ok = TRUE;
		for (i = 0; i < GROUP_COUNT; i++)
			if (GroupCount[i] == 0)
				ok = FALSE;

		if (ok)
		{
			sprintf(str, "\%d\", ", Row.AsResult);
			file.Write(str);

				sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GROUP_COUNT; i++)
			{
				ival = round(100.0 * (long double)GroupSum[i] / (long double)GroupCount[i]);
				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != GROUP_COUNT - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizS9::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3, d4;
	int q;
	int count;
	TFile infile(filename);

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		rowstr = strstr(buf, "#");
		if (rowstr)
		{
			rowstr++;
			ptr = strstr(rowstr, "\r");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
		{
			for (i = 0; i < strlen(rowstr); i++)
			{
				switch (rowstr[i])
				{
					case ',':
						rowstr[i] = '.';
						break;

					case 0x9:
					case 0xd:
						rowstr[i] = ' ';
						break;
				}
			}

			if (sscanf(rowstr, "%d %Lf %Lf %Lf %Lf", &q, &d1, &d2, &d3, &d4) == 5)
			{
				if (PcaType != PCA_TYPE_MIXED)
				{
					if (PcaType == PCA_TYPE_MALE)
						d2 = -d2;

					if (PcaType == PCA_TYPE_ALL)
						d3 = -d3;

//					if (PcaType == PCA_TYPE_ALL)
//						d4 = -d4;

//					if (d1 > 0 && d2 > 0)
//					{
//						if (d1 > d2)
//						{
//							d1 = d1 - d2;
//							d2 = 0;
//						}
//						else
//						{
//							d2 = d2 - d1;
//							d1 = 0;
//						}
//					}
				}

				switch (PcaType)
				{
					case PCA_TYPE_ALL:
						Quiz[q - 1].Pca[0] = d1;
						Quiz[q - 1].Pca[1] = d2;
						Quiz[q - 1].Pca[2] = d3;
						Quiz[q - 1].Pca[3] = d4;
						break;

					case PCA_TYPE_MALE:
						Quiz[q - 1].MalePca[0] = d1;
						Quiz[q - 1].MalePca[1] = d2;
						Quiz[q - 1].MalePca[2] = d3;
						Quiz[q - 1].MalePca[3] = d4;
						break;

					case PCA_TYPE_FEMALE:
						Quiz[q - 1].FemalePca[0] = d1;
						Quiz[q - 1].FemalePca[1] = d2;
						Quiz[q - 1].FemalePca[2] = d3;
						Quiz[q - 1].FemalePca[3] = d4;
						break;

					case PCA_TYPE_YOUNG:
						Quiz[q - 1].YoungPca[0] = d1;
						Quiz[q - 1].YoungPca[1] = d2;
						Quiz[q - 1].YoungPca[2] = d3;
						Quiz[q - 1].YoungPca[3] = d4;
						break;

					case PCA_TYPE_OLD:
						Quiz[q - 1].OldPca[0] = d1;
						Quiz[q - 1].OldPca[1] = d2;
						Quiz[q - 1].OldPca[2] = d3;
						Quiz[q - 1].OldPca[3] = d4;
						break;

					case PCA_TYPE_AS:
						Quiz[q - 1].AsPca[0] = d1;
						Quiz[q - 1].AsPca[1] = d2;
						Quiz[q - 1].AsPca[2] = d3;
						Quiz[q - 1].AsPca[3] = d4;
						break;

					case PCA_TYPE_MIXED:
						Quiz[q - 1].MixedPca[0] = d1;
						Quiz[q - 1].MixedPca[1] = d2;
						Quiz[q - 1].MixedPca[2] = d3;
						Quiz[q - 1].MixedPca[3] = d4;
						break;
				}
			}
		}
	}
}

/*##################  TQuizS9::WriteADD ##########################
*   Purpose....: Write ADD test report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::WriteADD(const char *filename)
{
	int Count;
	long double AsSum;
	long double NtSum;
	long double DiffSum;
	long double AddSum;
	long double AsMean;
	long double NtMean;
	long double DiffMean;
	long double AddMean;
	long double AsSd;
	long double NtSd;
	long double DiffSd;
	long double AddSd;
	long double AsCorr;
	long double NtCorr;
	long double DiffCorr;
	long double val;
	long double zx;
	long double zy;
	TQuizRow Row;
	int i;
	int ival;
	char str[80];

	Count = 0;
	AsSum = 0;
	NtSum = 0;
	AddSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.AddResult)
        {
			Count++;
			AsSum += Row.AsResult;
			NtSum += Row.NtResult;
			DiffSum += Row.AsResult - Row.NtResult;
			AddSum += Row.AddResult;
	    }
	}

	AsMean = AsSum / Count;
	NtMean = NtSum / Count;
	DiffMean = DiffSum / Count;
	AddMean = AddSum / Count;

	AsSum = 0;
	NtSum = 0;
	AddSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.AddResult)
        {
            val = (long double)Row.AsResult - AsMean;
   			AsSum += val * val;
   			
            val = (long double)Row.NtResult - NtMean;
			NtSum += val * val;
			
            val = (long double)(Row.AsResult - Row.NtResult) - DiffMean;
			DiffSum += val * val;

            val = (long double)Row.AddResult - AddMean;
			AddSum += val * val;
	    }
	}

	AsSd = sqrtl(AsSum / (Count - 1));
	NtSd = sqrtl(NtSum / (Count - 1));
	DiffSd = sqrtl(DiffSum / (Count - 1));
	AddSd = sqrtl(AddSum / (Count - 1));

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.AddResult)
        {
            zx = ((long double)Row.AddResult - AddMean) / AddSd;

            zy = ((long double)Row.AsResult - AsMean) / AsSd;
            AsSum += zx * zy;
        
            zy = ((long double)Row.NtResult - NtMean) / NtSd;
            NtSum += zx * zy;

            zy = ((long double)(Row.AsResult - Row.NtResult) - DiffMean) / DiffSd;
            DiffSum += zx * zy;
	    }
	}

    AsCorr = AsSum / (Count - 1);
    NtCorr = NtSum / (Count - 1);
    DiffCorr = DiffSum / (Count - 1);
	
	printf("Mean Aspie score: %5.1Lf, SD: %5.1Lf\r\n", AsMean, AsSd);
	printf("Mean NT score: %5.1Lf, SD: %5.1Lf\r\n", NtMean, NtSd);
	printf("Mean score diff: %5.1Lf, SD: %5.1Lf\r\n", DiffMean, DiffSd);
	printf("Mean ADD score: %5.1Lf, SD: %5.1Lf\r\n", AddMean, AddSd);

	printf("ADD - Aspie score correlation: %5.2Lf\r\n", AsCorr);
	printf("ADD - NT score correlation: %5.2Lf\r\n", NtCorr);
	printf("ADD - score diff correlation: %5.2Lf\r\n", DiffCorr);
}

/*##################  TQuizS9::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS9::WriteRetest(const char *filename)
{
	TQuizRow Row;
	int userid;
	int i;
	int index;
	int birthyear;
	int birthmonth;
	int gender;
	long double val;
	long double AsSum;
	long double NtSum;
	long double AsMean;
	long double NtMean;
	long double QMean[158];
	long double AsSd;
	long double NtSd;
	long double QSd[158];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[158];
	int QCount[158];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[158][20];
	int ok;
	char str[80];
	TFile file(filename, 0);

	for (userid = 0; userid < MAX_USERS; userid++)
	    UserInfo[userid] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
	    userid = Row.userid;

	    if (userid)
	    {
	        if (UserInfo[userid] == 0)
	        {
	            UserInfo[userid] = new TUserInfo;
	            UserInfo[userid]->Count = 1;
       	        UserInfo[userid]->BirthYear = Row.BirthYear;
       	        UserInfo[userid]->BirthMonth = Row.BirthMonth;
            	UserInfo[userid]->AsSum = Row.AsResult;
	            UserInfo[userid]->NtSum = Row.NtResult;
	        }
	        else
	            UserInfo[userid]->Count++;
	    }
	}

    AsCount = 0;
    NtCount = 0;
    AsTot = 0;
    NtTot = 0;

    for (q = 0; q < 158; q++)
    {
        QTot[q] = 0;
        QCount[q] = 0;
    }

	for (userid = 1; userid < MAX_USERS; userid++)
	{
        if (UserInfo[userid])
        {
            if (UserInfo[userid]->Count > 1)
       	    {
                for (i = 0; i < 20; i++)
                {
                    AsArr[i] = 0;
                    NtArr[i] = 0;

                    for (q = 0; q < 158; q++)
                        QArr[q][i] = 0;
                }

                index = 0;

            	FDataFile.SetPos(0);
        	    while (FDataFile.Read(&Row, sizeof(Row)))
            	{
            	    if (Row.userid == userid)
            	    {
                        ok = FALSE;
                    
        	            if (index == 0)
        	            {
            	            birthyear = Row.BirthYear;
            	            birthmonth = Row.BirthMonth;
            	            gender = Row.Gender;
        	                ok = TRUE;
                   	    
       	                    UserInfo[userid]->Count = 1;
           	                UserInfo[userid]->BirthYear = Row.BirthYear;
           	                UserInfo[userid]->BirthMonth = Row.BirthMonth;
            	            UserInfo[userid]->AsSum = Row.AsResult;
	                        UserInfo[userid]->NtSum = Row.NtResult;
        	            }
        	            else
            	        {
            	            if (    birthyear == Row.BirthYear &&
            	                    birthmonth == Row.BirthMonth &&
        	                        gender == Row.Gender)
        	                {
        	                    ok = TRUE;        	                

                    	        UserInfo[userid]->Count++;
                    	        UserInfo[userid]->AsSum += Row.AsResult;
                    	        UserInfo[userid]->NtSum += Row.NtResult;
        	                }
        	            }

            	        if (ok)
            	        {
                	        AsArr[index] = Row.AsResult;
                	        NtArr[index] = Row.NtResult;

                	        for (q = 0; q < 158; q++)
                	            QArr[q][index] = Row.Quiz[q];
                	        
        	                index++;
        	            }
        	        }
        	    }

    			if (index > 1)
	    		{
		    		AsSum = 0;
			    	NtSum = 0;

    				for (i = 0; i < index; i++)
	    			{
		    			AsSum += AsArr[i];
			    		NtSum += NtArr[i];
				    }

    				AsMean = AsSum / index;
	    			NtMean = NtSum / index;
    
	    			for (q = 0; q < 158; q++)
		    		{
			    	    count = 0;
				        sum = 0;

    				    for (i = 0; i < index; i++)
	    			    {
		    		        if (QArr[q][i])
			    	        {
				                sum += QArr[q][i] - 1;
				                count++;
				            }
    				    }
    
	    			    if (count)
		    		        QMean[q] = sum / count;
			    	    else
				            QMean[q] = 0;
    				}
				    
	    			AsSum = 0;
		    		NtSum = 0;

			    	for (i = 0; i < index; i++)
				    {
    					val = AsArr[i] - AsMean;
	    				AsSum += val * val;
    
	    				val = NtArr[i] - NtMean;
		    			NtSum += val * val;
			    	}

				    AsSd = sqrtl(AsSum / index);
    				NtSd = sqrtl(NtSum / index);

	    			for (q = 0; q < 158; q++)
		    		{
			    	    count = 0;
				        sum = 0;
    
	    			    for (i = 0; i < index; i++)
		    		    {
			    	        if (QArr[q][i])
				            {
				                val = QArr[q][i] - 1 - QMean[q];
				                sum += val * val;
				                count++;
    				        }
	    			    }

                        if (count)
                        {
    			    	    QSd[q] = sqrtl(sum / count);
    
        				    QTot[q] += QSd[q];
    	    			    QCount[q]++;
    		    		}
    			    	else
    				        QSd[q] = 0;
    				}

                    AsTot += AsSd;
                    AsCount++;

			    	NtTot += NtSd;
				    NtCount++;

//  				sprintf(str, "Userid: %d, AS: %5.1Lf (%5.1Lf), NT: %5.1Lf (%5.1Lf)<br>", userid, AsMean, AsSd, NtMean, NtSd);
//	    			file.Write(str);
//
//		    		for (q = 0; q < 135; q++)
//			    	{
//				        if (QSd[q] > 0.1)
//  				    {
//        				    sprintf(str, "#%d, Sd = %5.1Lf<br>", q, QSd[q]);
//    	    			    file.Write(str);
//    		    		}
//    		        }
    			}
    	    }
		}
	}

	AsSd = AsTot / AsCount;
	NtSd = NtTot / NtCount;

#ifdef ENGLISH
	file.Write("<h2>Retest result</h2>\n");
#endif

#ifdef SWEDISH
	file.Write("<h2>Omtestnings resultat</h2>\n");
#endif

#ifdef ENGLISH
	sprintf(str, "Population size: %d", AsCount);
#endif

#ifdef SWEDISH
	sprintf(str, "Populationsstorlek: %d", AsCount);
#endif

	file.Write(str);
	file.Write("<br><br>");

#ifdef ENGLISH
	sprintf(str, "AS score standard deviation: %2.1Lf", AsSd);
#endif

#ifdef SWEDISH
	sprintf(str, "AS poäng standardavvikelse: %2.1Lf", AsSd);
#endif

	file.Write(str);
	file.Write("<br>");

#ifdef ENGLISH
	sprintf(str, "NT score standard deviation: %2.1Lf", NtSd);
#endif

#ifdef SWEDISH
	sprintf(str, "NT poäng standardavvikelse: %2.1Lf", NtSd);
#endif

	file.Write(str);
	file.Write("<br><br>");


#ifdef ENGLISH
	file.Write("<h3>Question standard deviations</h3>");
#endif

#ifdef SWEDISH
	file.Write("<h3>Standardavvikelser per fråga</h3>");
#endif

	for (q = 0; q < 158; q++)
	{
	    sprintf(str, "%d. ", q + 1);
	    file.Write(str);
	    
		file.Write(Quiz[q].Text);
	    
	    sd = QTot[q] / QCount[q];

        sprintf(str, " <b>%3.2Lf</b><br>", sd);
    	file.Write(str);
    }
}
