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
# quizs11.cpp
# Quiz stable version 11 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs11.h"
#include "file.h"
#include "quizds11.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS11::TQuizS11
#
#   Purpose....: Constructor for TQuizS11
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS11::TQuizS11(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10)
  : TQuiz(181),
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
	DefineCross(24, QuizS9);
	DefineCross(25, QuizS10);

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS11::~TQuizS11
#
#   Purpose....: Destructor for TQuizS11
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS11::~TQuizS11()
{
}

/*##################  TQuizS11::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS11::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS11::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS11::GetCatCount(int Question)
{
	if (Question >= 149 && Question <= 175)
		return 2;
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
int TQuizS11::GetQuizN()
{
	return 149;
}

/*##########################################################################
#
#   Name       : TQuizS11::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::WriteName(TFile &File)
{
	 File.Write("S11");
}

/*##########################################################################
#
#   Name       : TQuizS11::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::WriteLongName(TFile &File)
{
	 File.Write("stable version 11");
}

/*##########################################################################
#
#   Name       : TQuizS11::GetDxData
#
#   Purpose....: Get diagnostic data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::GetDxData()
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

		if (Row.Autism == 1)
			DxArr[POP_TYPE_AUTISM] = DX_STATE_SELF;

		if (Row.Autism == 0)
			DxArr[POP_TYPE_AUTISM] = DX_STATE_NO;

		if (Row.Aspie == 2)
			DxArr[POP_TYPE_AS] = DX_STATE_YES;

		if (Row.Aspie == 1)
			DxArr[POP_TYPE_AS] = DX_STATE_SELF;

		if (Row.Aspie == 0)
			DxArr[POP_TYPE_AS] = DX_STATE_NO;

		if (Row.ADHD == 2)
			DxArr[POP_TYPE_ADD] = DX_STATE_YES;

		if (Row.ADHD == 1)
			DxArr[POP_TYPE_ADD] = DX_STATE_SELF;

		if (Row.ADHD == 0)
			DxArr[POP_TYPE_ADD] = DX_STATE_NO;

		if (Row.TS == 2)
			DxArr[POP_TYPE_TS] = DX_STATE_YES;

		if (Row.TS == 1)
			DxArr[POP_TYPE_TS] = DX_STATE_SELF;

		if (Row.TS == 0)
			DxArr[POP_TYPE_TS] = DX_STATE_NO;

		if (Row.Dyspraxia == 2)
			DxArr[POP_TYPE_DYSPRAXIA] = DX_STATE_YES;

		if (Row.Dyspraxia == 1)
			DxArr[POP_TYPE_DYSPRAXIA] = DX_STATE_SELF;

		if (Row.Dyspraxia == 0)
			DxArr[POP_TYPE_DYSPRAXIA] = DX_STATE_NO;

		if (Row.Dyslexia == 2)
			DxArr[POP_TYPE_DYSLEXIA] = DX_STATE_YES;

		if (Row.Dyslexia == 1)
			DxArr[POP_TYPE_DYSLEXIA] = DX_STATE_SELF;

		if (Row.Dyslexia == 0)
			DxArr[POP_TYPE_DYSLEXIA] = DX_STATE_NO;

		if (Row.Dyscalculia == 2)
			DxArr[POP_TYPE_DYSCALCULIA] = DX_STATE_YES;

		if (Row.Dyscalculia == 1)
			DxArr[POP_TYPE_DYSCALCULIA] = DX_STATE_SELF;

		if (Row.Dyscalculia == 0)
			DxArr[POP_TYPE_DYSCALCULIA] = DX_STATE_NO;

		if (Row.Bipolar == 2)
			DxArr[POP_TYPE_BIPOLAR] = DX_STATE_YES;

		if (Row.Bipolar == 1)
			DxArr[POP_TYPE_BIPOLAR] = DX_STATE_SELF;

		if (Row.Bipolar == 0)
			DxArr[POP_TYPE_BIPOLAR] = DX_STATE_NO;

		if (Row.Schizophrenia == 2)
			DxArr[POP_TYPE_SCHIZOPHRENIA] = DX_STATE_YES;

		if (Row.Schizophrenia == 1)
			DxArr[POP_TYPE_SCHIZOPHRENIA] = DX_STATE_SELF;

		if (Row.Schizophrenia == 0)
			DxArr[POP_TYPE_SCHIZOPHRENIA] = DX_STATE_NO;

		if (Row.Social == 2)
			DxArr[POP_TYPE_SOCIAL_PHOBIA] = DX_STATE_YES;

		if (Row.Social == 1)
			DxArr[POP_TYPE_SOCIAL_PHOBIA] = DX_STATE_SELF;

		if (Row.Social == 0)
			DxArr[POP_TYPE_SOCIAL_PHOBIA] = DX_STATE_NO;

		ProcessDxEntry(Row.GroupResult, DxArr);

	}
}

/*##################  TQuizS11::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS11::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::SetupTexts()
{
  Quiz[13].Reverse = TRUE;
  Quiz[16].Reverse = TRUE;
  Quiz[27].Reverse = TRUE;
  Quiz[28].Reverse = TRUE;
  Quiz[30].Reverse = TRUE;
  Quiz[31].Reverse = TRUE;
  Quiz[32].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[50].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[82].Reverse = TRUE;
  Quiz[83].Reverse = TRUE;
  Quiz[84].Reverse = TRUE;
  Quiz[85].Reverse = TRUE;
  Quiz[86].Reverse = TRUE;
  Quiz[87].Reverse = TRUE;
  Quiz[135].Reverse = TRUE;
  Quiz[136].Reverse = TRUE;
  Quiz[137].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[6].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[8].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[9].MyGroup = GROUP_NT_TALENT;
  Quiz[10].MyGroup = GROUP_NT_TALENT;
  Quiz[11].MyGroup = GROUP_NT_TALENT;
  Quiz[12].MyGroup = GROUP_NT_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[18].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[19].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_NT_OBSESSION;
  Quiz[28].MyGroup = GROUP_NT_OBSESSION;
  Quiz[29].MyGroup = GROUP_NT_OBSESSION;
  Quiz[30].MyGroup = GROUP_NT_OBSESSION;
  Quiz[31].MyGroup = GROUP_NT_OBSESSION;
  Quiz[32].MyGroup = GROUP_NT_OBSESSION;
  Quiz[33].MyGroup = GROUP_ACTIVITY;
  Quiz[34].MyGroup = GROUP_ACTIVITY;
  Quiz[35].MyGroup = GROUP_ACTIVITY;
  Quiz[36].MyGroup = GROUP_ACTIVITY;
  Quiz[37].MyGroup = GROUP_ACTIVITY;
  Quiz[38].MyGroup = GROUP_SOCIAL;
  Quiz[39].MyGroup = GROUP_SOCIAL;
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
  Quiz[53].MyGroup = GROUP_SOCIAL;
  Quiz[54].MyGroup = GROUP_ASPIE_NVC;
  Quiz[55].MyGroup = GROUP_ASPIE_NVC;
  Quiz[56].MyGroup = GROUP_ASPIE_NVC;
  Quiz[57].MyGroup = GROUP_ASPIE_NVC;
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
  Quiz[74].MyGroup = GROUP_NT_NVC;
  Quiz[75].MyGroup = GROUP_NT_NVC;
  Quiz[76].MyGroup = GROUP_NT_NVC;
  Quiz[77].MyGroup = GROUP_NT_NVC;
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
  Quiz[88].MyGroup = GROUP_ASPIE_NVC;
  Quiz[89].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[90].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[91].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[92].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[93].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[94].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[95].MyGroup = GROUP_NT_HUNTING;
  Quiz[96].MyGroup = GROUP_NT_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[98].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[99].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[100].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[101].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[102].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[103].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[104].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[105].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[106].MyGroup = GROUP_NT_SENSORY;
  Quiz[107].MyGroup = GROUP_NT_SENSORY;
  Quiz[108].MyGroup = GROUP_NT_SENSORY;
  Quiz[109].MyGroup = GROUP_NT_SENSORY;
  Quiz[110].MyGroup = GROUP_NT_SENSORY;
  Quiz[111].MyGroup = GROUP_NT_SENSORY;
  Quiz[112].MyGroup = GROUP_NT_SENSORY;
  Quiz[113].MyGroup = GROUP_NT_NVC;
  Quiz[114].MyGroup = GROUP_PARANOID;
  Quiz[115].MyGroup = GROUP_PARANOID;
  Quiz[116].MyGroup = GROUP_PARANOID;
  Quiz[117].MyGroup = GROUP_ENVIRONMENT;
  Quiz[118].MyGroup = GROUP_ENVIRONMENT;
  Quiz[119].MyGroup = GROUP_ENVIRONMENT;
  Quiz[120].MyGroup = GROUP_ENVIRONMENT;
  Quiz[121].MyGroup = GROUP_ENVIRONMENT;
  Quiz[122].MyGroup = GROUP_ENVIRONMENT;
  Quiz[123].MyGroup = GROUP_ENVIRONMENT;
  Quiz[124].MyGroup = GROUP_MIXED;
  Quiz[125].MyGroup = GROUP_ENVIRONMENT;
  Quiz[126].MyGroup = GROUP_MIXED;
  Quiz[127].MyGroup = GROUP_MIXED;
  Quiz[128].MyGroup = GROUP_MIXED;
  Quiz[129].MyGroup = GROUP_NT_HUNTING;
  Quiz[130].MyGroup = GROUP_MIXED;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_MIXED;
  Quiz[133].MyGroup = GROUP_MIXED;
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_MIXED;
  Quiz[136].MyGroup = GROUP_ENVIRONMENT;
  Quiz[137].MyGroup = GROUP_NT_SENSORY;
  Quiz[138].MyGroup = GROUP_SOCIAL;
  Quiz[139].MyGroup = GROUP_NT_NVC;

  Quiz[140].MyGroup = GROUP_NT_HUNTING;
  Quiz[141].MyGroup = GROUP_SOCIAL;
  Quiz[142].MyGroup = GROUP_NT_SENSORY;
  Quiz[143].MyGroup = GROUP_NT_HUNTING;
  Quiz[144].MyGroup = GROUP_NT_HUNTING;
  Quiz[145].MyGroup = GROUP_ASPIE_NVC;
  Quiz[146].MyGroup = GROUP_NT_HUNTING;
  Quiz[147].MyGroup = GROUP_MIXED;
  Quiz[148].MyGroup = GROUP_MIXED;

  Quiz[149].MyGroup = GROUP_MIXED;
  Quiz[150].MyGroup = GROUP_ASPIE_NVC;
  Quiz[151].MyGroup = GROUP_ASPIE_NVC;
  Quiz[152].MyGroup = GROUP_ASPIE_NVC;
  Quiz[153].MyGroup = GROUP_MIXED;
  Quiz[154].MyGroup = GROUP_ASPIE_NVC;
  Quiz[155].MyGroup = GROUP_MIXED;
  Quiz[156].MyGroup = GROUP_MIXED;
  Quiz[157].MyGroup = GROUP_MIXED;
  Quiz[158].MyGroup = GROUP_MIXED;
  Quiz[159].MyGroup = GROUP_MIXED;
  Quiz[160].MyGroup = GROUP_MIXED;
  Quiz[161].MyGroup = GROUP_MIXED;
  Quiz[162].MyGroup = GROUP_MIXED;
  Quiz[163].MyGroup = GROUP_MIXED;
  Quiz[164].MyGroup = GROUP_MIXED;
  Quiz[165].MyGroup = GROUP_MIXED;
  Quiz[166].MyGroup = GROUP_MIXED;
  Quiz[167].MyGroup = GROUP_MIXED;
  Quiz[168].MyGroup = GROUP_MIXED;
  Quiz[169].MyGroup = GROUP_MIXED;
  Quiz[170].MyGroup = GROUP_MIXED;
  Quiz[171].MyGroup = GROUP_MIXED;
  Quiz[172].MyGroup = GROUP_MIXED;
  Quiz[173].MyGroup = GROUP_MIXED;
  Quiz[174].MyGroup = GROUP_MIXED;
  Quiz[175].MyGroup = GROUP_MIXED;

  Quiz[176].MyGroup = GROUP_NT_HUNTING;
  Quiz[177].MyGroup = GROUP_NT_HUNTING;
  Quiz[178].MyGroup = GROUP_NT_SENSORY;
  Quiz[179].MyGroup = GROUP_ACTIVITY;
  Quiz[180].MyGroup = GROUP_SOCIAL;

#ifdef ENGLISH

  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[2].Text = "Have you felt different from others for most of your life?";
  Quiz[3].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[4].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[5].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[6].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[7].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[8].Text = "Do you notice patterns in things all the time?";
  Quiz[9].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[10].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[11].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[12].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[13].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[14].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[15].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[16].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[17].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[18].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[19].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[20].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[21].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[22].Text = "Do you have certain routines which you need to follow?";
  Quiz[23].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[24].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[25].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[26].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[27].Text = "Do you enjoy meeting new people?";
  Quiz[28].Text = "Are your views typical of your peer group?";
  Quiz[29].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[30].Text = "Is a large social network important to you?";
  Quiz[31].Text = "Do you take pride in your appearance?";
  Quiz[32].Text = "Do you enjoy gossip?";
  Quiz[33].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[34].Text = "Are you easily distracted?";
  Quiz[35].Text = "Do you have problems starting and / or finishing projects?";
  Quiz[36].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[37].Text = "Are you or have you been hyperactive?";
  Quiz[38].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[39].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[40].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[41].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[42].Text = "Do you prefer to avoid eye-contact?";
  Quiz[43].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[44].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[45].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[46].Text = "Do you dislike shaking hands?";
  Quiz[47].Text = "Do people think you are aloof and distant?";
  Quiz[48].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[49].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[50].Text = "Do you find it easy to describe your feelings?";
  Quiz[51].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[52].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[53].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[54].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[55].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[56].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[57].Text = "Do you often don't know where to put your arms?";
  Quiz[58].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[59].Text = "Have you been accused of staring?";
  Quiz[60].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[61].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[62].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[63].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[64].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[65].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[66].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[67].Text = "Do you fiddle with things?";
  Quiz[68].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[69].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[70].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[71].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[72].Text = "Do you stutter when stressed?";
  Quiz[73].Text = "Do you talk to yourself?";
  Quiz[74].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[75].Text = "Do others often misunderstand you?";
  Quiz[76].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[77].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[78].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[79].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[80].Text = "Are you often surprised what people's motives are ?";
  Quiz[81].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[82].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[83].Text = "Do you know when you are expected to offer an apology?";
  Quiz[84].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[85].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[86].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[87].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[88].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[89].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[90].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[91].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[92].Text = "Do you enjoy walking on your toes?";
  Quiz[93].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[94].Text = "Have you been fascinated about making traps?";
  Quiz[95].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[96].Text = "Do you confuse left and right?";
  Quiz[97].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[98].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[99].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[100].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[101].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[102].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[103].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[104].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[105].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[106].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[107].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[108].Text = "Do you have poor concept of time?";
  Quiz[109].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[110].Text = "Do you find it hard to tell the age of people?";
  Quiz[111].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[112].Text = "Did you perceive practical classes like handi-work or gymnasics as hard in school?";
  Quiz[113].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[114].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[115].Text = "Do you feel that people are watching you?";
  Quiz[116].Text = "Do you mistake noises for voices?";
  Quiz[117].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[118].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[119].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[120].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[121].Text = "Are you sometimes afraid in safe situations?";
  Quiz[122].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[123].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[124].Text = "Do you have immature interests?";
  Quiz[125].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[126].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[127].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[128].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[129].Text = "Do you drop things when your attention is on other things?";
  Quiz[130].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[131].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[132].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[133].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[134].Text = "Do you have trouble with authority?";
  Quiz[135].Text = "Can you easily remember verbal instructions?";
  Quiz[136].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[137].Text = "Do you find it easy to estimate the age of people?";
  Quiz[138].Text = "Are you good at teamwork?";
  Quiz[139].Text = "Do you have a good sense for what is the right thing to do socially?";

  Quiz[140].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[141].Text = "Do you dislike reading aloud?";
  Quiz[142].Text = "Do you have problems finding your way to new places?";
  Quiz[143].Text = "Do you have problems filling out forms?";
  Quiz[144].Text = "Do you mix up digits in numbers like 95 and 59?";
  Quiz[145].Text = "Have you thought of one word but written another?";
  Quiz[146].Text = "Do you mix up dates and times and miss appointments?";
  Quiz[147].Text = "Are you good at games that require that you remember where several cards or other objects are located?";
  Quiz[148].Text = "Do like it when people you are fond of looks a lot at you and continue to do so for several hours without anything else happening?";

  Quiz[149].Text = "TS - Do you involuntarily swear or utter obscene words or socially inappropriate and derogatory remarks (coprolalia)?";
  Quiz[150].Text = "TS - Do you involuntarily repeat or imitate observed movements of others (echopraxia)?";
  Quiz[151].Text = "TS - Do you repeat vocalizations made by others (echolalia)?";
  Quiz[152].Text = "TS - Do you repeat or echo your own spoken words (stuttering, palilalia)?";
  Quiz[153].Text = "TS - Do you have complex motor tics (eg facial grimaces, pulling cloth, touching people or objects, obscene gesturing or gyrating movements)?";
  Quiz[154].Text = "TS - Do you have complex vocal tics (eg talking to yourself, using socially meaningless sentences)?";
  Quiz[155].Text = "TS - Did you have tics before the age of twelve?";
  Quiz[156].Text = "TS - If you have tics, do the wax and wane?";
  Quiz[157].Text = "TS - If you have tics, did they begin above shoulders";
  Quiz[158].Text = "TS - Do you have five or more motor tic types in the list above?";
  Quiz[159].Text = "TS - Do you have three or more vocal tic types in the list above?";
  Quiz[160].Text = "TS - If you have motor tics, do they affect multiple body locations?";
  Quiz[161].Text = "TS - If you have tics, have they varied with some tics disappearing and new tics appearing over time?";
  Quiz[162].Text = "TS - If you have tics, do you have them even if you are not in a stressful situation?";
  Quiz[163].Text = "TS - If you have tics, are they voluntarily suppressible?";
  Quiz[164].Text = "TS - If you have tics, do you attempt to suppress them?";
  Quiz[165].Text = "TS - If you have tics and you try to suppress them, do they become worse (rebound effect)?";
  Quiz[166].Text = "TS - If you have tics, can you sense their coming beforehand (premonitory sensation)?";
  Quiz[167].Text = "TS - If you have tics, do you sense relief after you had them?";
  Quiz[168].Text = "TS - If you have tics, do a mention or sight of a specific tic induce it (suggestible)?";
  Quiz[169].Text = "TS - Do you have frequent tics (more than one per minute at times)?";
  Quiz[170].Text = "TS - Do you have orchestrated sequences of tics?";
  Quiz[171].Text = "TS - If you have tics, do they cause distress?";
  Quiz[172].Text = "TS - If you have tics, have you sought treatment or diagnosis?";
  Quiz[173].Text = "TS - Have you had tics for a duration of two or more years";
  Quiz[174].Text = "TS - Have your tics been confirmed by one or more reliable observers?";
  Quiz[175].Text = "TS - Do you have an absence of other medical problems that might cause tics (eg prior stimulant therapy, history of encephalitis)?";

  Quiz[176].Text = "Dyslexia";
  Quiz[177].Text = "Dyscalculia";
  Quiz[178].Text = "Dyspraxia";
  Quiz[179].Text = "Bipolar";
  Quiz[180].Text = "Social phobia";

#endif

#ifdef SWEDISH

  Quiz[0].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[1].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[2].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[3].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[4].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[5].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[6].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[7].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[8].Text = "Ser du mönster i saker hela tiden?";
  Quiz[9].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[10].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[11].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[12].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[13].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[14].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[15].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[16].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[17].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[18].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[19].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[20].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[21].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[22].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[23].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[24].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[25].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[26].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[27].Text = "Trivs du med att möta nya människor?";
  Quiz[28].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[29].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[30].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[31].Text = "Är du stolt över ditt utseende?";
  Quiz[32].Text = "Tycker du om skvaller?";
  Quiz[33].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[34].Text = "Blir du lätt distraherad?";
  Quiz[35].Text = "Har du problem att starta och / eller slutföra projekt?";
  Quiz[36].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[37].Text = "Är du eller har du varit hyperaktiv";
  Quiz[38].Text = "Låser det sig för dig när du får frågor i sociala situationer?";
  Quiz[39].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[40].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[41].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[42].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[43].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[44].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[45].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[46].Text = "Ogillar du att behöva ta i hand?";
  Quiz[47].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[48].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[49].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[50].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[51].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[52].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[53].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[54].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[55].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[56].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[57].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[58].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[59].Text = "Har du blivit anklagad för att stirra?";
  Quiz[60].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[61].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[62].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[63].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[64].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[65].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[66].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[67].Text = "Brukar du fingra på saker?";
  Quiz[68].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[69].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[70].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[71].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[72].Text = "Stammar du när du blir stressad?";
  Quiz[73].Text = "Brukar du prata med dig själv?";
  Quiz[74].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[75].Text = "Blir du ofta missförstådd av andra?";
  Quiz[76].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[77].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[78].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[79].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[80].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[81].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[82].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[83].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[84].Text = "Trivs du i romantiska situationer?";
  Quiz[85].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[86].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[87].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[88].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[89].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[90].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[91].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[92].Text = "Gillar du att gå på tå?";
  Quiz[93].Text = "Gillar du att härma djurläten?";
  Quiz[94].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[95].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[96].Text = "Brukar du blanda ihop höger och vänster?";
  Quiz[97].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[98].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[99].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[100].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[101].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[102].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[103].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[104].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[105].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[106].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[107].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[108].Text = "Har du dålig tidsuppfattning?";
  Quiz[109].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[110].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[111].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[112].Text = "Tyckte du praktiska ämnen som slöjd och gymnastik var svårt i skolan?";
  Quiz[113].Text = "Har du svårt att känna igen ansikten?";
  Quiz[114].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[115].Text = "Tycker du att folk bevakar dig?";
  Quiz[116].Text = "Misstar du ljud för röster?";
  Quiz[117].Text = "Har du haft långvariga hämndbegär?";
  Quiz[118].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[119].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[120].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[121].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[122].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[123].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[124].Text = "Har du omogna intressen?";
  Quiz[125].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[126].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[127].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[128].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[129].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[130].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[131].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[132].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[133].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[134].Text = "Har du problem med auktoriteter?";
  Quiz[135].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[136].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[137].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[138].Text = "Är du bra på att arbeta i grupp?";
  Quiz[139].Text = "Har du en bra känla för vad som är rätt socialt?";

  Quiz[140].Text = "Tycker du det är svårt att ta meddelenden på telefon och skicka dem vidare rätt?'";
  Quiz[141].Text = "Ogillar du högläsning?";
  Quiz[142].Text = "Har du svårt att hitta till nya platser?";
  Quiz[143].Text = "Har du svårt att fylla i formulär?";
  Quiz[144].Text = "Blandar du ihop siffor i tal som t.ex. 95 och 59?";
  Quiz[145].Text = "Har du tänkt på ett ord men skrivit ett annat?";
  Quiz[146].Text = "Blandar du ihop tider och datum och missar möten?";
  Quiz[147].Text = "Är du bra på spel som kräver att du kommer ihåg var flera olika kort eller andra saker finns?";
  Quiz[148].Text = "Gillar du när människor du är förtjust i tittar mycket på dig och fortsätter att göra det under flera timmar utan att något annat händer?";

  Quiz[149].Text = "TS - Do you involuntarily swear or utter obscene words or socially inappropriate and derogatory remarks (coprolalia)?";
  Quiz[150].Text = "TS - Do you involuntarily repeat or imitate observed movements of others (echopraxia)?";
  Quiz[151].Text = "TS - Do you repeat vocalizations made by others (echolalia)?";
  Quiz[152].Text = "TS - Do you repeat or echo your own spoken words (stuttering, palilalia)?";
  Quiz[153].Text = "TS - Do you have complex motor tics (eg facial grimaces, pulling cloth, touching people or objects, obscene gesturing or gyrating movements)?";
  Quiz[154].Text = "TS - Do you have complex vocal tics (eg talking to yourself, using socially meaningless sentences)?";
  Quiz[155].Text = "TS - Did you have tics before the age of twelve?";
  Quiz[156].Text = "TS - If you have tics, do the wax and wane?";
  Quiz[157].Text = "TS - If you have tics, did they begin above shoulders";
  Quiz[158].Text = "TS - Do you have five or more motor tic types in the list above?";
  Quiz[159].Text = "TS - Do you have three or more vocal tic types in the list above?";
  Quiz[160].Text = "TS - If you have motor tics, do they affect multiple body locations?";
  Quiz[161].Text = "TS - If you have tics, have they varied with some tics disappearing and new tics appearing over time?";
  Quiz[162].Text = "TS - If you have tics, do you have them even if you are not in a stressful situation?";
  Quiz[163].Text = "TS - If you have tics, are they voluntarily suppressible?";
  Quiz[164].Text = "TS - If you have tics, do you attempt to suppress them?";
  Quiz[165].Text = "TS - If you have tics and you try to suppress them, do they become worse (rebound effect)?";
  Quiz[166].Text = "TS - If you have tics, can you sense their coming beforehand (premonitory sensation)?";
  Quiz[167].Text = "TS - If you have tics, do you sense relief after you had them?";
  Quiz[168].Text = "TS - If you have tics, do a mention or sight of a specific tic induce it (suggestible)?";
  Quiz[169].Text = "TS - Do you have frequent tics (more than one per minute at times)?";
  Quiz[170].Text = "TS - Do you have orchestrated sequences of tics?";
  Quiz[171].Text = "TS - If you have tics, do they cause distress?";
  Quiz[172].Text = "TS - If you have tics, have you sought treatment or diagnosis?";
  Quiz[173].Text = "TS - Have you had tics for a duration of two or more years";
  Quiz[174].Text = "TS - Have your tics been confirmed by one or more reliable observers?";
  Quiz[175].Text = "TS - Do you have an absence of other medical problems that might cause tics (eg prior stimulant therapy, history of encephalitis)?";

  Quiz[176].Text = "Dyslexi";
  Quiz[177].Text = "Dyskaluli";
  Quiz[178].Text = "Dyspraxi";
  Quiz[179].Text = "Bipolär";
  Quiz[180].Text = "Social fobi";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS11::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::InitReferers()
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

/*##################  TQuizS11::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::LoadReferers()
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

		if (Row.Dyspraxia >= 1)
			UpdateReferer(&DyspraxiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyslexia >= 1)
			UpdateReferer(&DyslexiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyscalculia >= 1)
			UpdateReferer(&DyscalculiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

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
#   Name       : TQuizS11::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::LoadPopulations()
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

		Row.Quiz[176] = Row.Dyslexia + 1;
		Row.Quiz[177] = Row.Dyscalculia + 1;
		Row.Quiz[178] = Row.Dyspraxia + 1;
		Row.Quiz[179] = Row.Bipolar + 1;
		Row.Quiz[180] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 176)
				{
					score = Row.Quiz[i] - 1;
					id = IdArr[i];

					DsmAutism.Add(Row.Autism, id, score);
					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
					DsmTs.Add(Row.TS, id, score);
					DsmDyspraxia.Add(Row.Dyspraxia, id, score);
					DsmDyslexia.Add(Row.Dyslexia, id, score);
					DsmDyscalculia.Add(Row.Dyscalculia, id, score);
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

		if (Row.Dyspraxia >= 1)
			Dyspraxia.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Dyslexia >= 1)
			Dyslexia.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Dyscalculia >= 1)
			Dyscalculia.Add(Row.AsResult, Row.NtResult, aspie, Row.Gender, Row.Quiz, Row.GroupResult);

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
#   Name       : TQuizS11::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::SetupControlGroups()
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
#   Name       : TQuizS11::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10)
{
    DefineCross(QuizS10, 0, 0);
	 DefineCross(QuizS10, 1, 1);
    DefineCross(QuizS10, 2, 2);
    DefineCross(QuizS10, 3, 3);
    DefineCross(QuizS10, 4, 5);
	 DefineCross(QuizS10, 5, 4);
    DefineCross(QuizS10, 6, 6);
	 DefineCross(QuizS10, 7, 10);
    DefineCross(QuizS10, 8, 11);
    DefineCross(QuizS10, 9, 14);
    DefineCross(QuizS10, 10, 15);
    DefineCross(QuizS10, 11, 16);
	 DefineCross(QuizS10, 12, 17);
    DefineCross(QuizS10, 13, 18);
    DefineCross(QuizS10, 14, 19);
    DefineCross(QuizS10, 15, 20);
    DefineCross(QuizS10, 16, 93);
	 DefineCross(QuizS10, 17, 22);
    DefineCross(QuizS10, 18, 23);
	 DefineCross(QuizS10, 19, 24);
	 DefineCross(QuizS10, 20, 25);
    DefineCross(QuizS10, 21, 26);
    DefineCross(QuizS10, 22, 27);
    DefineCross(QuizS10, 23, 28);
    DefineCross(QuizS10, 24, 29);
    DefineCross(QuizS10, 25, 30);
	 DefineCross(QuizS10, 26, 145);
	 DefineCross(QuizS10, 27, 31);
    DefineCross(QuizS10, 28, 32);
	 DefineCross(QuizS10, 29, 33);
    DefineCross(QuizS10, 30, 34);
	 DefineCross(QuizS10, 31, 35);
    DefineCross(QuizS10, 32, 36);
    DefineCross(QuizS10, 33, 37);
    DefineCross(QuizS10, 34, 38);
	 DefineCross(QuizS10, 35, 165);
    DefineCross(QuizS10, 36, 41);
	 DefineCross(QuizR3, 37, 160);
    DefineCross(QuizS10, 38, 156);
    DefineCross(QuizS10, 39, 101);
    DefineCross(QuizS10, 40, 42);
    DefineCross(QuizS10, 41, 43);
	 DefineCross(QuizS10, 42, 44);
    DefineCross(QuizS10, 43, 45);
    DefineCross(QuizS10, 44, 46);
    DefineCross(QuizS10, 45, 47);
    DefineCross(QuizS10, 46, 48);
	 DefineCross(QuizS10, 47, 49);
    DefineCross(QuizS10, 48, 50);
	 DefineCross(QuizS10, 49, 51);
	 DefineCross(QuizS10, 50, 53);
    DefineCross(QuizS10, 51, 54);
    DefineCross(QuizS10, 52, 55);
    DefineCross(QuizS10, 53, 56);
    DefineCross(QuizS10, 54, 58);
    DefineCross(QuizS10, 55, 59);
	 DefineCross(QuizS10, 56, 60);
	 DefineCross(QuizS10, 57, 61);
    DefineCross(QuizS10, 58, 62);
	 DefineCross(QuizS10, 59, 63);
    DefineCross(QuizS10, 60, 64);
	 DefineCross(QuizS10, 61, 65);
    DefineCross(QuizS10, 62, 66);
    DefineCross(QuizS10, 63, 142);
    DefineCross(QuizS10, 64, 67);
	 DefineCross(QuizS10, 65, 68);
    DefineCross(QuizS10, 66, 69);
	 DefineCross(QuizS10, 67, 70);
    DefineCross(QuizS10, 68, 71);
    DefineCross(QuizS10, 69, 72);
    DefineCross(QuizS10, 70, 144);
    DefineCross(QuizS10, 71, 73);
	 DefineCross(QuizS10, 72, 74);
    DefineCross(QuizS10, 73, 75);
    DefineCross(QuizS10, 74, 78);
    DefineCross(QuizS10, 75, 79);
    DefineCross(QuizS10, 76, 80);
	 DefineCross(QuizS10, 77, 135);
    DefineCross(QuizS10, 78, 81);
	 DefineCross(QuizS10, 79, 82);
	 DefineCross(QuizS10, 80, 84);
    DefineCross(QuizS10, 81, 85);
    DefineCross(QuizS10, 82, 86);
    DefineCross(QuizS10, 83, 87);
    DefineCross(QuizS10, 84, 89);
    DefineCross(QuizS10, 85, 90);
	 DefineCross(QuizS10, 86, 91);
	 DefineCross(QuizS10, 87, 92);
    DefineCross(QuizS10, 88, 94);
	 DefineCross(QuizS10, 89, 95);
    DefineCross(QuizS10, 90, 96);
	 DefineCross(QuizS10, 91, 97);
    DefineCross(QuizS10, 92, 98);
    DefineCross(QuizS10, 93, 99);
    DefineCross(QuizS10, 94, 100);
	 DefineCross(QuizS10, 95, 21);
    DefineCross(QuizS10, 96, 122);
	 DefineCross(QuizS10, 97, 108);
    DefineCross(QuizS10, 98, 109);
    DefineCross(QuizS10, 99, 110);
    DefineCross(QuizS10, 100, 111);
    DefineCross(QuizS10, 101, 112);
	 DefineCross(QuizS10, 102, 113);
    DefineCross(QuizS10, 103, 114);
    DefineCross(QuizS10, 104, 116);
    DefineCross(QuizS10, 105, 115);
    DefineCross(QuizS10, 106, 103);
	 DefineCross(QuizS10, 107, 104);
    DefineCross(QuizS10, 108, 117);
	 DefineCross(QuizS10, 109, 105);
	 DefineCross(QuizS10, 110, 118);
    DefineCross(QuizS10, 111, 119);
    DefineCross(QuizS10, 112, 107);
    DefineCross(QuizS10, 113, 120);
    DefineCross(QuizS10, 114, 125);
    DefineCross(QuizS10, 115, 123);
	 DefineCross(QuizS10, 116, 124);
	 DefineCross(QuizS10, 117, 126);
    DefineCross(QuizS10, 118, 127);
	 DefineCross(QuizS10, 119, 128);
    DefineCross(QuizS10, 120, 129);
	 DefineCross(QuizS10, 121, 130);
    DefineCross(QuizS10, 122, 131);
    DefineCross(QuizS10, 123, 132);
    DefineCross(QuizS10, 124, 158);
	 DefineCross(QuizS10, 125, 134);
	 DefineCross(QuizS10, 126, 136);
	 DefineCross(QuizS10, 127, 137);
	 DefineCross(QuizS10, 128, 138);
	 DefineCross(QuizS10, 129, 102);
	 DefineCross(QuizS10, 130, 139);
	 DefineCross(QuizS10, 131, 140);
	 DefineCross(QuizS10, 132, 141);
	 DefineCross(QuizS10, 133, 143);
	 DefineCross(QuizS10, 134, 159);
	 DefineCross(QuizS10, 135, 146);
	 DefineCross(QuizS10, 136, 152);
	 DefineCross(QuizS10, 137, 150);
	 DefineCross(QuizS10, 138, 148);
	 DefineCross(QuizS10, 139, 149);

	 DefineGlobalId(140, 1075);
	 DefineGlobalId(141, 1076);
	 DefineGlobalId(142, 1077);
	 DefineGlobalId(143, 1078);
	 DefineGlobalId(144, 1079);
	 DefineGlobalId(145, 1080);
	 DefineGlobalId(146, 1081);
	 DefineGlobalId(147, 1082);
	 DefineGlobalId(148, 1083);

	 DefineGlobalId(149, 1084);
	 DefineGlobalId(150, 1085);
	 DefineGlobalId(151, 1086);
	 DefineGlobalId(152, 1087);
	 DefineGlobalId(153, 1088);
	 DefineGlobalId(154, 1089);
	 DefineGlobalId(155, 1090);
	 DefineGlobalId(156, 1091);
	 DefineGlobalId(157, 1092);
	 DefineGlobalId(158, 1093);
	 DefineGlobalId(159, 1094);
	 DefineGlobalId(160, 1095);
	 DefineGlobalId(161, 1096);
	 DefineGlobalId(162, 1097);
	 DefineGlobalId(163, 1098);
	 DefineGlobalId(164, 1099);
	 DefineGlobalId(165, 1100);
	 DefineGlobalId(166, 1101);
	 DefineGlobalId(167, 1102);
	 DefineGlobalId(168, 1103);
	 DefineGlobalId(169, 1104);
	 DefineGlobalId(170, 1105);
	 DefineGlobalId(171, 1106);
	 DefineGlobalId(172, 1107);
	 DefineGlobalId(173, 1108);
	 DefineGlobalId(174, 1109);
	 DefineGlobalId(175, 1110);

	 DefineCross(QuizS10, 176, 188);
	 DefineCross(QuizS10, 177, 189);
	 DefineCross(QuizNd, 178, 201);
	 DefineCross(QuizS10, 179, 192);
	 DefineCross(QuizS10, 180, 193);
}

/*##########################################################################
#
#   Name       : TQuizS11::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS11::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizS11::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS11::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::ExportExcelAspie(const char *filename)
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
		if (Row.TsResult)
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

/*##################  TQuizS11::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS11::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::ImportMvsp(const char *filename, int PcaType)
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
//					if (PcaType == PCA_TYPE_FEMALE)
//						d2 = -d2;

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

/*##################  TQuizS11::WriteTS ##########################
*   Purpose....: Write TS test report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::WriteTS(const char *filename)
{
	int Count;
	long double AsSum;
	long double NtSum;
	long double DiffSum;
	long double TsSum;
	long double AsMean;
	long double NtMean;
	long double DiffMean;
	long double TsMean;
	long double AsSd;
	long double NtSd;
	long double DiffSd;
	long double TsSd;
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
	TsSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.TsResult)
        {
			Count++;
			AsSum += Row.AsResult;
			NtSum += Row.NtResult;
			DiffSum += Row.AsResult - Row.NtResult;
			TsSum += Row.TsResult;
	    }
	}

	AsMean = AsSum / Count;
	NtMean = NtSum / Count;
	DiffMean = DiffSum / Count;
	TsMean = TsSum / Count;

	AsSum = 0;
	NtSum = 0;
	TsSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.TsResult)
        {
            val = (long double)Row.AsResult - AsMean;
   			AsSum += val * val;
   			
            val = (long double)Row.NtResult - NtMean;
			NtSum += val * val;
			
            val = (long double)(Row.AsResult - Row.NtResult) - DiffMean;
			DiffSum += val * val;

            val = (long double)Row.TsResult - TsMean;
			TsSum += val * val;
	    }
	}

	AsSd = sqrtl(AsSum / (Count - 1));
	NtSd = sqrtl(NtSum / (Count - 1));
	DiffSd = sqrtl(DiffSum / (Count - 1));
	TsSd = sqrtl(TsSum / (Count - 1));

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.TsResult)
		  {
            zx = ((long double)Row.TsResult - TsMean) / TsSd;

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
	printf("Mean TS score: %5.1Lf, SD: %5.1Lf\r\n", TsMean, TsSd);

	printf("TS - Aspie score correlation: %5.2Lf\r\n", AsCorr);
	printf("TS - NT score correlation: %5.2Lf\r\n", NtCorr);
	printf("TS - score diff correlation: %5.2Lf\r\n", DiffCorr);
}


/*##################  TQuizS11::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS11::WriteRetest(const char *filename)
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
	long double QMean[149];
	long double AsSd;
	long double NtSd;
	long double QSd[149];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[149];
	int QCount[149];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[149][20];
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

	 for (q = 0; q < 149; q++)
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

						  for (q = 0; q < 149; q++)
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

								  for (q = 0; q < 149; q++)
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

					for (q = 0; q < 149; q++)
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

					for (q = 0; q < 149; q++)
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

	for (q = 0; q < 149; q++)
	{
		 sprintf(str, "%d. ", q + 1);
		 file.Write(str);

		file.Write(Quiz[q].Text);

		 sd = QTot[q] / QCount[q];

		  sprintf(str, " <b>%3.2Lf</b><br>", sd);
		file.Write(str);
	 }
}

