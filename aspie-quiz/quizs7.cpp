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
# quizS7.cpp
# Quiz stable version 7 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizS7.h"
#include "file.h"
#include "quizdbS7.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS7::TQuizS7
#
#   Purpose....: Constructor for TQuizS7
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS7::TQuizS7(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6)
  : TQuiz(189),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS7::~TQuizS7
#
#   Purpose....: Destructor for TQuizS7
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS7::~TQuizS7()
{
}

/*##################  TQuizS7::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS7::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS7::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS7::GetCatCount(int Question)
{
	return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS7::GetQuizN()
{
	return 183;
}

/*##########################################################################
#
#   Name       : TQuizS7::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::WriteName(TFile &File)
{
	 File.Write("S7");
}

/*##########################################################################
#
#   Name       : TQuizS7::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::WriteLongName(TFile &File)
{
	 File.Write("stable version 7");
}

/*##########################################################################
#
#   Name       : TQuizS7::GetDxData
#
#   Purpose....: Get diagnostic data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::GetDxData()
{
	TQuizRow Row;
	int DxArr[POP_TYPE_COUNT];
	int i;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < POP_TYPE_COUNT; i++)
			DxArr[i] = DX_STATE_UNKNOWN;

		if (Row.Autism == 2)
			DxArr[POP_TYPE_AUTISM] = DX_STATE_YES;

		if (Row.Autism == 0)
			DxArr[POP_TYPE_AUTISM] = DX_STATE_NO;

		if (Row.Aspie == 2)
			DxArr[POP_TYPE_AS] = DX_STATE_YES;

		if (Row.Aspie == 0)
			DxArr[POP_TYPE_AS] = DX_STATE_NO;

		if (Row.ADHD == 2)
			DxArr[POP_TYPE_ADD] = DX_STATE_YES;

		if (Row.ADHD == 0)
			DxArr[POP_TYPE_ADD] = DX_STATE_NO;

		if (Row.TS == 2)
			DxArr[POP_TYPE_TS] = DX_STATE_YES;

		if (Row.TS == 0)
			DxArr[POP_TYPE_TS] = DX_STATE_NO;

		if (Row.Dyslexia == 2)
			DxArr[POP_TYPE_DYSLEXIA] = DX_STATE_YES;

		if (Row.Dyslexia == 0)
			DxArr[POP_TYPE_DYSLEXIA] = DX_STATE_NO;

		if (Row.Dyscalculia == 2)
			DxArr[POP_TYPE_DYSCALCULIA] = DX_STATE_YES;

		if (Row.Dyscalculia == 0)
			DxArr[POP_TYPE_DYSCALCULIA] = DX_STATE_NO;

		if (Row.OCD == 2)
			DxArr[POP_TYPE_OCD] = DX_STATE_YES;

		if (Row.OCD == 0)
			DxArr[POP_TYPE_OCD] = DX_STATE_NO;

		if (Row.ODD == 2)
			DxArr[POP_TYPE_ODD] = DX_STATE_YES;

		if (Row.ODD == 0)
			DxArr[POP_TYPE_ODD] = DX_STATE_NO;

		if (Row.Bipolar == 2)
			DxArr[POP_TYPE_BIPOLAR] = DX_STATE_YES;

		if (Row.Bipolar == 0)
			DxArr[POP_TYPE_BIPOLAR] = DX_STATE_NO;

		if (Row.Schizophrenia == 2)
			DxArr[POP_TYPE_SCHIZOPHRENIA] = DX_STATE_YES;

		if (Row.Schizophrenia == 0)
			DxArr[POP_TYPE_SCHIZOPHRENIA] = DX_STATE_NO;

		if (Row.Social == 2)
			DxArr[POP_TYPE_SOCIAL_PHOBIA] = DX_STATE_YES;

		if (Row.Social == 0)
			DxArr[POP_TYPE_SOCIAL_PHOBIA] = DX_STATE_NO;

		ProcessDxEntry(Row.GroupResult, DxArr);

	}
}

/*##################  TQuizS7::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS7::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS7::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::SetupTexts()
{
  Quiz[38].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[59].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[62].Reverse = TRUE;
  Quiz[63].Reverse = TRUE;
  Quiz[64].Reverse = TRUE;
  Quiz[65].Reverse = TRUE;
  Quiz[66].Reverse = TRUE;
  Quiz[67].Reverse = TRUE;
  Quiz[68].Reverse = TRUE;
  Quiz[95].Reverse = TRUE;
  Quiz[98].Reverse = TRUE;
  Quiz[99].Reverse = TRUE;
  Quiz[101].Reverse = TRUE;
  Quiz[103].Reverse = TRUE;
  Quiz[113].Reverse = TRUE;
  Quiz[114].Reverse = TRUE;
  Quiz[115].Reverse = TRUE;
  Quiz[116].Reverse = TRUE;
  Quiz[117].Reverse = TRUE;
  Quiz[118].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;
  Quiz[150].Reverse = TRUE;
  Quiz[151].Reverse = TRUE;
  Quiz[152].Reverse = TRUE;
  Quiz[153].Reverse = TRUE;
  Quiz[154].Reverse = TRUE;
  Quiz[156].Reverse = TRUE;
  Quiz[157].Reverse = TRUE;
  Quiz[158].Reverse = TRUE;
  Quiz[159].Reverse = TRUE;
  Quiz[160].Reverse = TRUE;
  Quiz[162].Reverse = TRUE;
  Quiz[163].Reverse = TRUE;
  Quiz[164].Reverse = TRUE;
  Quiz[165].Reverse = TRUE;
  Quiz[166].Reverse = TRUE;
  Quiz[167].Reverse = TRUE;
  Quiz[168].Reverse = TRUE;
  Quiz[169].Reverse = TRUE;
  Quiz[175].Reverse = TRUE;
  Quiz[177].Reverse = TRUE;
  Quiz[178].Reverse = TRUE;
  Quiz[181].Reverse = TRUE;
  Quiz[182].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[1].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[2].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[3].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[4].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[5].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[6].MyGroup = GROUP_NT_HUNTING;
  Quiz[7].MyGroup = GROUP_NT_SENSORY;
  Quiz[8].MyGroup = GROUP_NT_SENSORY;
  Quiz[9].MyGroup = GROUP_NT_SENSORY;
  Quiz[10].MyGroup = GROUP_NT_SENSORY;
  Quiz[11].MyGroup = GROUP_NT_SENSORY;
  Quiz[12].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[13].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[14].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[15].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[16].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[17].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[18].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[19].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[24].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[25].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[26].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[27].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[28].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[29].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[30].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[31].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_NT_TALENT;
  Quiz[35].MyGroup = GROUP_NT_TALENT;
  Quiz[36].MyGroup = GROUP_NT_TALENT;
  Quiz[37].MyGroup = GROUP_NT_TALENT;
  Quiz[38].MyGroup = GROUP_NT_TALENT;
  Quiz[39].MyGroup = GROUP_NT_SENSORY;
  Quiz[40].MyGroup = GROUP_NT_TALENT;
  Quiz[41].MyGroup = GROUP_ACTIVITY;
  Quiz[42].MyGroup = GROUP_NT_TALENT;
  Quiz[43].MyGroup = GROUP_NT_HUNTING;
  Quiz[44].MyGroup = GROUP_ACTIVITY;
  Quiz[45].MyGroup = GROUP_SOCIAL;
  Quiz[46].MyGroup = GROUP_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[48].MyGroup = GROUP_SOCIAL;
  Quiz[49].MyGroup = GROUP_SOCIAL;
  Quiz[50].MyGroup = GROUP_SOCIAL;
  Quiz[51].MyGroup = GROUP_SOCIAL;
  Quiz[52].MyGroup = GROUP_SOCIAL;
  Quiz[53].MyGroup = GROUP_SOCIAL;
  Quiz[54].MyGroup = GROUP_SOCIAL;
  Quiz[55].MyGroup = GROUP_SOCIAL;
  Quiz[56].MyGroup = GROUP_SOCIAL;
  Quiz[57].MyGroup = GROUP_SOCIAL;
  Quiz[58].MyGroup = GROUP_SOCIAL;
  Quiz[59].MyGroup = GROUP_SOCIAL;
  Quiz[60].MyGroup = GROUP_SOCIAL;
  Quiz[61].MyGroup = GROUP_SOCIAL;
  Quiz[62].MyGroup = GROUP_NT_NVC;
  Quiz[63].MyGroup = GROUP_NT_OBSESSION;
  Quiz[64].MyGroup = GROUP_SOCIAL;
  Quiz[65].MyGroup = GROUP_SOCIAL;
  Quiz[66].MyGroup = GROUP_NT_OBSESSION;
  Quiz[67].MyGroup = GROUP_NT_NVC;
  Quiz[68].MyGroup = GROUP_SOCIAL;
  Quiz[69].MyGroup = GROUP_ASPIE_NVC;
  Quiz[70].MyGroup = GROUP_ASPIE_NVC;
  Quiz[71].MyGroup = GROUP_ASPIE_NVC;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ASPIE_NVC;
  Quiz[74].MyGroup = GROUP_ASPIE_NVC;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ASPIE_NVC;
  Quiz[77].MyGroup = GROUP_ASPIE_NVC;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_NVC;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
  Quiz[82].MyGroup = GROUP_ASPIE_NVC;
  Quiz[83].MyGroup = GROUP_ASPIE_NVC;
  Quiz[84].MyGroup = GROUP_ASPIE_NVC;
  Quiz[85].MyGroup = GROUP_ASPIE_NVC;
  Quiz[86].MyGroup = GROUP_ASPIE_NVC;
  Quiz[87].MyGroup = GROUP_ASPIE_NVC;
  Quiz[88].MyGroup = GROUP_ASPIE_NVC;
  Quiz[89].MyGroup = GROUP_NT_NVC;
  Quiz[90].MyGroup = GROUP_NT_NVC;
  Quiz[91].MyGroup = GROUP_NT_NVC;
  Quiz[92].MyGroup = GROUP_NT_NVC;
  Quiz[93].MyGroup = GROUP_NT_NVC;
  Quiz[94].MyGroup = GROUP_NT_NVC;
  Quiz[95].MyGroup = GROUP_NT_NVC;
  Quiz[96].MyGroup = GROUP_NT_NVC;
  Quiz[97].MyGroup = GROUP_NT_NVC;
  Quiz[98].MyGroup = GROUP_NT_NVC;
  Quiz[99].MyGroup = GROUP_NT_NVC;
  Quiz[100].MyGroup = GROUP_NT_NVC;
  Quiz[101].MyGroup = GROUP_NT_NVC;
  Quiz[102].MyGroup = GROUP_NT_NVC;
  Quiz[103].MyGroup = GROUP_NT_TALENT;
  Quiz[104].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[105].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[106].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[107].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[108].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[109].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[110].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[111].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[112].MyGroup = GROUP_NT_OBSESSION;
  Quiz[113].MyGroup = GROUP_NT_OBSESSION;
  Quiz[114].MyGroup = GROUP_NT_OBSESSION;
  Quiz[115].MyGroup = GROUP_NT_OBSESSION;
  Quiz[116].MyGroup = GROUP_NT_OBSESSION;
  Quiz[117].MyGroup = GROUP_NT_OBSESSION;
  Quiz[118].MyGroup = GROUP_NT_OBSESSION;
  Quiz[119].MyGroup = GROUP_PARANOID;
  Quiz[120].MyGroup = GROUP_PARANOID;
  Quiz[121].MyGroup = GROUP_PARANOID;
  Quiz[122].MyGroup = GROUP_ENVIRONMENT;
  Quiz[123].MyGroup = GROUP_ENVIRONMENT;
  Quiz[124].MyGroup = GROUP_ENVIRONMENT;
  Quiz[125].MyGroup = GROUP_ENVIRONMENT;
  Quiz[126].MyGroup = GROUP_ENVIRONMENT;
  Quiz[127].MyGroup = GROUP_ENVIRONMENT;
  Quiz[128].MyGroup = GROUP_ENVIRONMENT;
  Quiz[129].MyGroup = GROUP_ENVIRONMENT;
  Quiz[130].MyGroup = GROUP_ENVIRONMENT;
  Quiz[131].MyGroup = GROUP_NT_NVC;
  Quiz[132].MyGroup = GROUP_MIXED;
  Quiz[133].MyGroup = GROUP_MIXED;
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_MIXED;
  Quiz[136].MyGroup = GROUP_ACTIVITY;
  Quiz[137].MyGroup = GROUP_MIXED;
  Quiz[138].MyGroup = GROUP_ASPIE_NVC;
  Quiz[139].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_NT_SENSORY;
  Quiz[142].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[143].MyGroup = GROUP_ASPIE_NVC;
  Quiz[144].MyGroup = GROUP_MIXED;
  Quiz[145].MyGroup = GROUP_SOCIAL;
  Quiz[146].MyGroup = GROUP_MIXED;
  Quiz[147].MyGroup = GROUP_ASPIE_NVC;
  Quiz[148].MyGroup = GROUP_NT_OBSESSION;
  Quiz[149].MyGroup = GROUP_NT_SENSORY;
  Quiz[150].MyGroup = GROUP_NT_TALENT;
  Quiz[151].MyGroup = GROUP_ENVIRONMENT;
  Quiz[152].MyGroup = GROUP_SOCIAL;
  Quiz[153].MyGroup = GROUP_SOCIAL;
  Quiz[154].MyGroup = GROUP_NT_SENSORY;
  Quiz[155].MyGroup = GROUP_SOCIAL;
  Quiz[156].MyGroup = GROUP_NT_NVC;
  Quiz[157].MyGroup = GROUP_SOCIAL;
  Quiz[158].MyGroup = GROUP_NT_NVC;
  Quiz[159].MyGroup = GROUP_NT_OBSESSION;
  Quiz[160].MyGroup = GROUP_SOCIAL;
  Quiz[161].MyGroup = GROUP_NT_NVC;
  Quiz[162].MyGroup = GROUP_NT_NVC;
  Quiz[163].MyGroup = GROUP_SOCIAL;
  Quiz[164].MyGroup = GROUP_SOCIAL;
  Quiz[165].MyGroup = GROUP_SOCIAL;
  Quiz[166].MyGroup = GROUP_NT_OBSESSION;
  Quiz[167].MyGroup = GROUP_SOCIAL;
  Quiz[168].MyGroup = GROUP_NT_OBSESSION;
  Quiz[169].MyGroup = GROUP_SOCIAL;
  Quiz[170].MyGroup = GROUP_NT_SENSORY;
  Quiz[171].MyGroup = GROUP_NT_SENSORY;
  Quiz[172].MyGroup = GROUP_NT_SENSORY;
  Quiz[173].MyGroup = GROUP_NT_SENSORY;
  Quiz[174].MyGroup = GROUP_NT_HUNTING;
  Quiz[175].MyGroup = GROUP_NT_SENSORY;
  Quiz[176].MyGroup = GROUP_MIXED;
  Quiz[177].MyGroup = GROUP_NT_SENSORY;
  Quiz[178].MyGroup = GROUP_MIXED;
  Quiz[179].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[180].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[181].MyGroup = GROUP_NT_SENSORY;
  Quiz[182].MyGroup = GROUP_NT_SENSORY;

  Quiz[183].MyGroup = GROUP_NT_HUNTING;
  Quiz[184].MyGroup = GROUP_NT_HUNTING;
  Quiz[185].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[186].MyGroup = GROUP_MIXED;
  Quiz[187].MyGroup = GROUP_ACTIVITY;
  Quiz[188].MyGroup = GROUP_SOCIAL;

#ifdef ENGLISH

  Quiz[0].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[1].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[2].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[3].Text = "Do you enjoy walking on your toes?";
  Quiz[4].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[5].Text = "Have you been fascinated about making traps?";
  Quiz[6].Text = "Do you drop things when your attention is on other things?";
  Quiz[7].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[8].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[9].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[10].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[11].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[12].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[13].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[14].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[15].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[16].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[17].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[18].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[19].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[20].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[21].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[22].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[23].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[24].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[25].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[26].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[27].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[28].Text = "Do people see you as eccentric?";
  Quiz[29].Text = "Do you have a hyperactive mind?";
  Quiz[30].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[31].Text = "Do you notice patterns in things all the time?";
  Quiz[32].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[33].Text = "Do you tend to do everything worth doing, more perfect than really needed?";
  Quiz[34].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[35].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[36].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[37].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[38].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[39].Text = "Do you have poor concept of time?";
  Quiz[40].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[41].Text = "Are you easily distracted?";
  Quiz[42].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[43].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[44].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[45].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[46].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[47].Text = "Have you felt different from others for most of your life?";
  Quiz[48].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[49].Text = "Do you dislike shaking hands?";
  Quiz[50].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[51].Text = "Do people think you are aloof and distant?";
  Quiz[52].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[53].Text = "Do you prefer to keep to yourself?";
  Quiz[54].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[55].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[56].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[57].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[58].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[59].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[60].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[61].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[62].Text = "Do you instinctively know how to behave when somebody shows interest in you as a potential partner?";
  Quiz[63].Text = "Are your views typical of your peer group?";
  Quiz[64].Text = "Do you find it easy to describe your feelings?";
  Quiz[65].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[66].Text = "Are you energised by being in the company of others?";
  Quiz[67].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[68].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[69].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[70].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[71].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[72].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[73].Text = "Do you often don't know where to put your arms?";
  Quiz[74].Text = "Have you been accused of staring?";
  Quiz[75].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[76].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[77].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[78].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[79].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[80].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[81].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[82].Text = "Do you fiddle with things?";
  Quiz[83].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[84].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[85].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[86].Text = "Do you stutter when stressed?";
  Quiz[87].Text = "Do you talk to yourself?";
  Quiz[88].Text = "Do you clench your fists when angry?";
  Quiz[89].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[90].Text = "Do others often misunderstand you?";
  Quiz[91].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[92].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[93].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[94].Text = "Are you often surprised what people's motives are ?";
  Quiz[95].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[96].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[97].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[98].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[99].Text = "Do you know when you are expected to offer an apology?";
  Quiz[100].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[101].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[102].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[103].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[104].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[105].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[106].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[107].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[108].Text = "Do you have certain routines which you need to follow?";
  Quiz[109].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[110].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[111].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[112].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[113].Text = "Is a large social network important to you?";
  Quiz[114].Text = "Do you have an interest for the current fashions?";
  Quiz[115].Text = "Do you enjoy gossip?";
  Quiz[116].Text = "Do you take pride in your appearance?";
  Quiz[117].Text = "Do you like to be in charge of other people?";
  Quiz[118].Text = "Do you enjoy wearing jewelry?";
  Quiz[119].Text = "Do you feel that people are watching you?";
  Quiz[120].Text = "Do you mistake noises for voices?";
  Quiz[121].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[122].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[123].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[124].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[125].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[126].Text = "Are you sometimes afraid in safe situations?";
  Quiz[127].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[128].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[129].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[130].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[131].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[132].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[133].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[134].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[135].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[136].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[137].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[138].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[139].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[140].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[141].Text = "Do you find it hard to tell the age of people?";
  Quiz[142].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[143].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[144].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[145].Text = "Do you dislike working while being observed?";
  Quiz[146].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[147].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[148].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
  Quiz[149].Text = "Are you good at predicting motion?";
  Quiz[150].Text = "Can you easily remember verbal instructions?";
  Quiz[151].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[152].Text = "Do people understand you?";
  Quiz[153].Text = "Are you good at teamwork?";
  Quiz[154].Text = "Do you find it easy to estimate the age of people?";
  Quiz[155].Text = "Do you prefer to avoid eye-contact?";
  Quiz[156].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[157].Text = "Is it easy for you to make friends?";
  Quiz[158].Text = "Do you find the usual courting behavior natural?";
  Quiz[159].Text = "Do you enjoy meeting new people?";
  Quiz[160].Text = "Are you good at social chitchat?";
  Quiz[161].Text = "Is it or has it been harder for you than for others to find a partner?";
  Quiz[162].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[163].Text = "Do you find it easier to communicate in real life than online?";
  Quiz[164].Text = "Does it feel natural for you to say 'thank you' and 'sorry'?";
  Quiz[165].Text = "Do you find it easy to describe your feelings and emotions to others?";
  Quiz[166].Text = "Do you enjoy meeting new people every day?";
  Quiz[167].Text = "Do you find it easy to talk about feelings?";
  Quiz[168].Text = "Are you the life of a party?";
  Quiz[169].Text = "Do you find it easy to understand and sympathise with those who function very differently from yourself?";
  Quiz[170].Text = "Did you perceive practical classes like handi-work or gymnasics as hard in school?";
  Quiz[171].Text = "Do you have poor gross motor skills (= clumsiness)?";
  Quiz[172].Text = "Do you have poor balance, e.g. difficulty riding a bicycle, skating, standing on one leg?";
  Quiz[173].Text = "Do you have difficulties with fine motor skills and/or hand-eye co-ordination?";
  Quiz[174].Text = "Do you confuse left and right?";
  Quiz[175].Text = "Can you whistle?";
  Quiz[176].Text = "Are you afraid of heights?";
  Quiz[177].Text = "Do you have a good sense of what time it is?";
  Quiz[178].Text = "Does it come more natural to you to think in words than in pictures?";
  Quiz[179].Text = "Do you have poor night vision?";

  Quiz[180].Text = "Do you enjoy chasing people or animals?";
  Quiz[181].Text = "Are you good at keeping track of where people are (for instance in team-sports)?";
  Quiz[182].Text = "Do you have good precision when throwing things like darts?";

  Quiz[183].Text = "Dyslexia";
  Quiz[184].Text = "Dyscalculia";
  Quiz[185].Text = "OCD";
  Quiz[186].Text = "ODD";
  Quiz[187].Text = "Bipolar";
  Quiz[188].Text = "Social phobia";

#endif

#ifdef SWEDISH

  Quiz[0].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[1].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[2].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[3].Text = "Gillar du att gå på tå?";
  Quiz[4].Text = "Gillar du att härma djurläten?";
  Quiz[5].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[6].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[7].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[8].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[9].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[10].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[11].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[12].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[13].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[14].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[15].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[16].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[17].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[18].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[19].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[20].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[21].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[22].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[23].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[24].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[25].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[26].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[27].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[28].Text = "Tycker folk att du är excentrisk?";
  Quiz[29].Text = "Är du mentalt hyperaktiv?";
  Quiz[30].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[31].Text = "Ser du mönster i saker hela tiden?";
  Quiz[32].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[33].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[34].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[35].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[36].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[37].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[38].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[39].Text = "Har du dålig tidsuppfattning?";
  Quiz[40].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[41].Text = "Blir du lätt distraherad?";
  Quiz[42].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[43].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[44].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[45].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[46].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[47].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[48].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[49].Text = "Ogillar du att behöva ta i hand?";
  Quiz[50].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[51].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[52].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[53].Text = "Föredrar du att vara för dig själv?";
  Quiz[54].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[55].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[56].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[57].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[58].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[59].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[60].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[61].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[62].Text = "Vet du instinktivt hur du ska uppföra dig om någon visar intresse för dig som möjlig partner?";
  Quiz[63].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[64].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[65].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[66].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[67].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[68].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[69].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[70].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[71].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[72].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[73].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[74].Text = "Har du blivit anklagad för att stirra?";
  Quiz[75].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[76].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[77].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[78].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[79].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[80].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[81].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[82].Text = "Brukar du fingra på saker?";
  Quiz[83].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[84].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[85].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[86].Text = "Stammar du när du blir stressad?";
  Quiz[87].Text = "Brukar du prata med dig själv?";
  Quiz[88].Text = "Knyter du nävarna när du är arg?";
  Quiz[89].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[90].Text = "Blir du ofta missförstådd av andra?";
  Quiz[91].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[92].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[93].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[94].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[95].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[96].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[97].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[98].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[99].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[100].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[101].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[102].Text = "Har du svårt att känna igen ansikten?";
  Quiz[103].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[104].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[105].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[106].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[107].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[108].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[109].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[110].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[111].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[112].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[113].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[114].Text = "Är du intressad av nuvarande mode?";
  Quiz[115].Text = "Tycker du om skvaller?";
  Quiz[116].Text = "Är du stolt över ditt utseende?";
  Quiz[117].Text = "Gillar du att leda andra människor?";
  Quiz[118].Text = "Gillar du att bära smycken?";
  Quiz[119].Text = "Tycker du att folk bevakar dig?";
  Quiz[120].Text = "Misstar du ljud för röster?";
  Quiz[121].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[122].Text = "Har du haft långvariga hämndbegär?";
  Quiz[123].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[124].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[125].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[126].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[127].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[128].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[129].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[130].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[131].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[132].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[133].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[134].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[135].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[136].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[137].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[138].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[139].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[140].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[141].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[142].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[143].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[144].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[145].Text = "Ogillar du att andra tittar på när du arbetar?";
  Quiz[146].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[147].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[148].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
  Quiz[149].Text = "Är du bra på att förutsäga rörelse?";
  Quiz[150].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[151].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[152].Text = "Förstår sig folk på dig?";
  Quiz[153].Text = "Är du bra på att arbeta i grupp?";
  Quiz[154].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[155].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[156].Text = "Trivs du i romantiska situationer?";
  Quiz[157].Text = "Har du lätt för att få vänner?";
  Quiz[158].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[159].Text = "Trivs du med att möta nya människor?";
  Quiz[160].Text = "Är du bra på kallprat?";
  Quiz[161].Text = "Är det eller har det varit svårare för dig än för andra att hitta en partner?";
  Quiz[162].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[163].Text = "Tycker du att det är lättare att kommunicera i verkliga livet än via dator?";
  Quiz[164].Text = "Känns det naturligt för dig att säga 'tack' och 'förlåt'?";
  Quiz[165].Text = "Tycker du det är lätt att beskriva dina känslor för andra?";
  Quiz[166].Text = "Tycker du om att möta nya människor varje dag?";
  Quiz[167].Text = "Tycker du det är lätt att prata om känslor?";
  Quiz[168].Text = "Är du aktiv på fester?";
  Quiz[169].Text = "Har du lätt att förstå och känna sympati även för dem som fungerar väldigt annorlunda än du själv?";
  Quiz[170].Text = "Tyckte du praktiska ämnen som slöjd och gymnastik var svårt i skolan?";
  Quiz[171].Text = "Har du problem med grovmotorik (=klumpighet)?";
  Quiz[172].Text = "Har du dåligt balanssinne, t ex svårt att cykla, åka skridskor, stå på ett ben?";
  Quiz[173].Text = "Har du problem med finmotorik och/eller öga-hand koordination?";
  Quiz[174].Text = "Brukar du blanda ihop höger och vänster?";
  Quiz[175].Text = "Kan du vissla?";
  Quiz[176].Text = "Är du höjdrädd?";
  Quiz[177].Text = "Har du ett bra sinne för hur mycket klockan är?";
  Quiz[178].Text = "Är det mer naturligt för dig att tänka i ord än i bilder?";
  Quiz[179].Text = "Har du dåligt mörkerseende?";

  Quiz[180].Text = "Gillar du att jaga människor eller djur?";
  Quiz[181].Text = "Är du bra på att hålla reda på var folk är (t.ex. i bollsporter)?";
  Quiz[182].Text = "Har du bra precision när du kastar saker som t.ex. pilar?";

  Quiz[183].Text = "Dyslexi";
  Quiz[184].Text = "Dyskaluli";
  Quiz[185].Text = "OCD";
  Quiz[186].Text = "ODD";
  Quiz[187].Text = "Bipolär";
  Quiz[188].Text = "Social fobi";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS7::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::InitReferers()
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

}

/*##################  TQuizS7::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS7::LoadReferers()
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
#   Name       : TQuizS7::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::LoadPopulations()
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

		Row.Quiz[183] = Row.Dyslexia + 1;
		Row.Quiz[184] = Row.Dyscalculia + 1;
		Row.Quiz[185] = Row.OCD + 1;
		Row.Quiz[186] = Row.ODD + 1;
		Row.Quiz[187] = Row.Bipolar + 1;
		Row.Quiz[188] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 183)
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
#   Name       : TQuizS7::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::SetupControlGroups()
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

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizS7::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6)
{
    DefineCross(QuizS6, 0, 0);
    DefineCross(QuizS6, 1, 1);
    DefineCross(QuizS6, 2, 5);
    DefineCross(QuizS6, 3, 4);
    DefineCross(QuizS6, 4, 3);
    DefineCross(QuizS6, 5, 6);
    DefineCross(QuizS6, 6, 7);
    DefineCross(QuizS6, 7, 8);
    DefineCross(QuizS6, 8, 9);
    DefineCross(QuizS6, 9, 10);
    DefineCross(QuizS6, 10, 11);
    DefineCross(QuizS6, 11, 12);
    DefineCross(QuizS6, 12, 13);
    DefineCross(QuizS6, 13, 14);
    DefineCross(QuizS6, 14, 15);
    DefineCross(QuizS6, 15, 16);
    DefineCross(QuizS6, 16, 17);
    DefineCross(QuizS6, 17, 19);
    DefineCross(QuizS6, 18, 18);
    DefineCross(QuizS6, 19, 20);
    DefineCross(QuizS6, 20, 21);
    DefineCross(QuizS6, 21, 22);
    DefineCross(QuizS6, 22, 23);
    DefineCross(QuizS6, 23, 27);
    DefineCross(QuizS6, 24, 24);
	DefineCross(QuizS6, 25, 26);
    DefineCross(QuizS6, 26, 28);
    DefineCross(QuizS6, 27, 29);
    DefineCross(QuizS6, 28, 25);
    DefineCross(QuizS6, 29, 30);
    DefineCross(QuizS6, 30, 31);
    DefineCross(QuizS6, 31, 32);
    DefineCross(QuizS6, 32, 33);
    DefineCross(QuizS6, 33, 34);
    DefineCross(QuizS6, 34, 35);
    DefineCross(QuizS6, 35, 36);
    DefineCross(QuizS6, 36, 37);
    DefineCross(QuizS6, 37, 38);
    DefineCross(QuizS6, 38, 39);
    DefineCross(QuizS6, 39, 40);
    DefineCross(QuizS6, 40, 41);
    DefineCross(QuizS6, 41, 42);
    DefineCross(QuizS6, 42, 43);
    DefineCross(QuizS6, 43, 44);
    DefineCross(QuizS6, 44, 45);
    DefineCross(QuizS6, 45, 46);
    DefineCross(QuizS6, 46, 49);
    DefineCross(QuizS6, 47, 50);
    DefineCross(QuizS6, 48, 53);
    DefineCross(QuizS6, 49, 57);
    DefineCross(QuizS6, 50, 48);
    DefineCross(QuizS6, 51, 51);
	DefineCross(QuizS6, 52, 58);
    DefineCross(QuizS6, 53, 56);
    DefineCross(QuizS6, 54, 61);
    DefineCross(QuizS6, 55, 65);
    DefineCross(QuizS6, 56, 67);
    DefineCross(QuizS6, 57, 69);
    DefineCross(QuizS6, 58, 47);
    DefineCross(QuizS6, 59, 99);
    DefineCross(QuizS6, 60, 54);
    DefineCross(QuizS6, 61, 103);
    DefineCross(QuizS6, 62, 59);
    DefineCross(QuizS6, 63, 62);
    DefineCross(QuizS6, 64, 64);
    DefineCross(QuizS6, 65, 66);
    DefineCross(QuizS6, 66, 148);
    DefineCross(QuizS6, 67, 68);
    DefineCross(QuizS6, 68, 70);
    DefineCross(QuizS6, 69, 72);
    DefineCross(QuizS6, 70, 73);
    DefineCross(QuizS6, 71, 71);
    DefineCross(QuizS6, 72, 74);
    DefineCross(QuizS6, 73, 75);
    DefineCross(QuizS6, 74, 77);
    DefineCross(QuizS6, 75, 76);
    DefineCross(QuizS6, 76, 78);
    DefineCross(QuizS6, 77, 79);
    DefineCross(QuizS6, 78, 81);
	DefineCross(QuizS6, 79, 82);
    DefineCross(QuizS6, 80, 83);
    DefineCross(QuizS6, 81, 84);
    DefineCross(QuizS6, 82, 80);
    DefineCross(QuizS6, 83, 86);
    DefineCross(QuizS6, 84, 85);
    DefineCross(QuizS6, 85, 87);
    DefineCross(QuizS6, 86, 89);
    DefineCross(QuizS6, 87, 88);
    DefineCross(QuizS6, 88, 90);
    DefineCross(QuizS6, 89, 91);
    DefineCross(QuizS6, 90, 92);
    DefineCross(QuizS6, 91, 93);
    DefineCross(QuizS6, 92, 94);
    DefineCross(QuizS6, 93, 96);
    DefineCross(QuizS6, 94, 95);
    DefineCross(QuizS6, 95, 55);
    DefineCross(QuizS6, 96, 97);
    DefineCross(QuizS6, 97, 98);
    DefineCross(QuizS6, 98, 100);
    DefineCross(QuizS6, 99, 102);
    DefineCross(QuizS6, 100, 101);
    DefineCross(QuizS6, 101, 104);
    DefineCross(QuizS6, 102, 106);
    DefineCross(QuizS6, 103, 105);
    DefineCross(QuizS6, 104, 107);
    DefineCross(QuizS6, 105, 108);
	DefineCross(QuizS6, 106, 109);
    DefineCross(QuizS6, 107, 110);
    DefineCross(QuizS6, 108, 111);
    DefineCross(QuizS6, 109, 112);
    DefineCross(QuizS6, 110, 113);
    DefineCross(QuizS6, 111, 114);
    DefineCross(QuizS6, 112, 63);
    DefineCross(QuizS6, 113, 152);
    DefineCross(QuizS6, 114, 154);
    DefineCross(QuizS6, 115, 155);
    DefineCross(QuizS6, 116, 159);
    DefineCross(QuizS6, 117, 161);
    DefineCross(QuizS6, 118, 164);
    DefineCross(QuizS6, 119, 116);
    DefineCross(QuizS6, 120, 117);
    DefineCross(QuizS6, 121, 115);
    DefineCross(QuizS6, 122, 118);
    DefineCross(QuizS6, 123, 119);
    DefineCross(QuizS6, 124, 120);
    DefineCross(QuizS6, 125, 121);
    DefineCross(QuizS6, 126, 122);
    DefineCross(QuizS6, 127, 123);
    DefineCross(QuizS6, 128, 124);
    DefineCross(QuizS6, 129, 125);
    DefineCross(QuizS6, 130, 126);
    DefineCross(QuizS6, 131, 127);
    DefineCross(QuizS6, 132, 128);
	DefineCross(QuizS6, 133, 52);
    DefineCross(QuizS6, 134, 129);
    DefineCross(QuizS6, 135, 131);
    DefineCross(QuizS6, 136, 130);
    DefineCross(QuizS6, 137, 132);
    DefineCross(QuizS6, 138, 133);
    DefineCross(QuizS6, 139, 134);
    DefineCross(QuizS6, 140, 135);
    DefineCross(QuizS6, 141, 136);
    DefineCross(QuizS6, 142, 137);
    DefineCross(QuizS6, 143, 139);
    DefineCross(QuizS6, 144, 140);
    DefineCross(QuizS6, 145, 138);
    DefineCross(QuizS6, 146, 141);
    DefineCross(QuizS6, 147, 142);
    DefineCross(QuizS6, 148, 172);
    DefineCross(QuizS6, 149, 177);
    DefineCross(QuizS6, 150, 143);
    DefineCross(QuizS6, 151, 146);
    DefineCross(QuizS6, 152, 144);
    DefineCross(QuizS6, 153, 145);
    DefineCross(QuizS6, 154, 147);
    DefineCross(QuizS5, 155, 44);
    DefineCross(QuizS2, 156, 41);
    DefineCross(QuizR5, 157, 36);
    DefineCross(QuizS2, 158, 43);
    DefineCross(QuizS2, 159, 45);
	DefineCross(QuizS6, 160, 60);
    DefineCross(QuizR4, 161, 2);
    DefineCross(QuizR6, 162, 54);
    DefineCross(QuizR6, 163, 57);
    DefineCross(QuizS3, 164, 128);
    DefineCross(Quiz6, 165, 141);
    DefineCross(QuizS6, 166, 150);
    DefineCross(Quiz8, 167, 141);
    DefineCross(QuizS6, 168, 151);
    DefineCross(QuizR1, 169, 109);
    DefineCross(QuizR2, 170, 5);
    DefineCross(QuizIII, 171, 12);
    DefineCross(QuizR4, 172, 132);
    DefineCross(Quiz9, 173, 12);
    DefineCross(QuizIII, 174, 16);
    DefineCross(Quiz9, 175, 17);
    DefineCross(Quiz9, 176, 136);
    DefineCross(QuizR5, 177, 130);
    DefineCross(QuizR5, 178, 88);
    DefineCross(QuizR1, 179, 76);

	DefineGlobalId(180, 938);
	DefineGlobalId(181, 939);
	DefineGlobalId(182, 940);

	DefineCross(QuizS6, 183, 179);
	DefineCross(QuizS6, 184, 180);
	DefineCross(QuizS6, 185, 181);
	DefineCross(QuizS6, 186, 182);
	DefineCross(QuizS6, 187, 183);
	DefineCross(QuizS6, 188, 184);
}

/*##########################################################################
#
#   Name       : TQuizS7::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS7::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizS7::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS7::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS7::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS7::ExportExcelAspie(const char *filename)
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

/*##################  TQuizS7::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS7::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS7::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS7::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_MALE || PcaType == PCA_TYPE_ALL)
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

/*##################  TQuizS7::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS7::WriteRetest(const char *filename)
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
	long double QMean[183];
	long double AsSd;
	long double NtSd;
	long double QSd[183];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[183];
	int QCount[183];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[183][20];
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

    for (q = 0; q < 183; q++)
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

                    for (q = 0; q < 183; q++)
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

                	        for (q = 0; q < 183; q++)
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
    
	    			for (q = 0; q < 183; q++)
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

	    			for (q = 0; q < 183; q++)
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

	for (q = 0; q < 183; q++)
	{
	    sprintf(str, "%d. ", q + 1);
	    file.Write(str);
	    
		file.Write(Quiz[q].Text);
	    
	    sd = QTot[q] / QCount[q];

        sprintf(str, " <b>%3.2Lf</b><br>", sd);
    	file.Write(str);
    }
}
