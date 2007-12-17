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
# quizs2.cpp
# Quiz stable release 2 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs2.h"
#include "file.h"
#include "quizdbs2.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS2::TQuizS2
#
#   Purpose....: Constructor for TQuizS2
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS2::TQuizS2(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1)
  : TQuiz(170),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS2::~TQuizS2
#
#   Purpose....: Destructor for TQuizS2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS2::~TQuizS2()
{
}

/*##################  TQuizS2::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS2::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS2::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS2::GetCatCount(int Question)
{
	if (Question < 160)
		return 3;
	else
		return 11;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS2::GetQuizN()
{
	return 140;
}

/*##########################################################################
#
#   Name       : TQuizS2::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::WriteName(TFile &File)
{
	 File.Write("S2");
}

/*##########################################################################
#
#   Name       : TQuizS2::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::WriteLongName(TFile &File)
{
	 File.Write("stable version 2");
}

/*##########################################################################
#
#   Name       : TQuizS2::GetRegressData
#
#   Purpose....: Get regression data for dsm & group
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::GetRegressData(int PopType, int Group, int Arr[101][2])
{
	TQuizRow Row;
	int res;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{

		res = Row.GroupResult[Group];
		if (res >= 0 && res <= 100)
		{

			switch (PopType)
			{
				case POP_TYPE_AUTISM:
					 if (Row.Autism == 2)
						  Arr[res][1]++;

					 if (Row.Autism == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_AS:
					 if (Row.Aspie == 2)
						  Arr[res][1]++;

					 if (Row.Aspie == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_ADD:
					 if (Row.ADHD == 2)
						  Arr[res][1]++;

					 if (Row.ADHD == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_TS:
					 if (Row.TS == 2)
						  Arr[res][1]++;

					 if (Row.TS == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_DYSLEXIA:
					 if (Row.Dyslexia == 2)
						  Arr[res][1]++;

					 if (Row.Dyslexia == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_DYSCALCULIA:
					 if (Row.Dyscalculia == 2)
						  Arr[res][1]++;

					 if (Row.Dyscalculia == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_OCD:
					 if (Row.OCD == 2)
						  Arr[res][1]++;

					 if (Row.OCD == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_ODD:
					 if (Row.ODD == 2)
						  Arr[res][1]++;

					 if (Row.ODD == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_BIPOLAR:
					 if (Row.Bipolar == 2)
						  Arr[res][1]++;

					 if (Row.Bipolar == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_SCHIZOPHRENIA:
					 if (Row.Schizophrenia == 2)
						  Arr[res][1]++;

					 if (Row.Schizophrenia == 0)
						  Arr[res][0]++;
					 break;

				case POP_TYPE_SOCIAL_PHOBIA:
					 if (Row.Social == 2)
						  Arr[res][1]++;

					 if (Row.Social == 0)
						  Arr[res][0]++;
					 break;

			}
		 }
	 }
}

/*##################  TQuizS2::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS2::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::SetupTexts()
{
  Quiz[21].Reverse = TRUE;
  Quiz[40].Reverse = TRUE;
  Quiz[41].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[44].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[46].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[122].Reverse = TRUE;
  Quiz[126].Reverse = TRUE;
  Quiz[128].Reverse = TRUE;
  Quiz[129].Reverse = TRUE;
  Quiz[130].Reverse = TRUE;
  Quiz[132].Reverse = TRUE;
  Quiz[133].Reverse = TRUE;
  Quiz[134].Reverse = TRUE;
  Quiz[135].Reverse = TRUE;
  Quiz[136].Reverse = TRUE;
  Quiz[137].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;
  Quiz[156].Reverse = TRUE;
  Quiz[157].Reverse = TRUE;
  Quiz[160].Reverse = TRUE;
  Quiz[161].Reverse = TRUE;
  Quiz[162].Reverse = TRUE;
  Quiz[164].Reverse = TRUE;
  Quiz[168].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_NT_SENSORY;
  Quiz[1].MyGroup = GROUP_NT_SENSORY;
  Quiz[2].MyGroup = GROUP_MIXED;
  Quiz[3].MyGroup = GROUP_NT_SENSORY;
  Quiz[4].MyGroup = GROUP_NT_SENSORY;
  Quiz[5].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[6].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[7].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[8].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[9].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[10].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[11].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[12].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[13].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[14].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[15].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[16].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[17].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[18].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[19].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[20].MyGroup = GROUP_NT_TALENT;
  Quiz[21].MyGroup = GROUP_NT_TALENT;
  Quiz[22].MyGroup = GROUP_NT_SENSORY;
  Quiz[23].MyGroup = GROUP_NT_TALENT;
  Quiz[24].MyGroup = GROUP_ACTIVITY;
  Quiz[25].MyGroup = GROUP_NT_TALENT;
  Quiz[26].MyGroup = GROUP_MIXED;
  Quiz[27].MyGroup = GROUP_ACTIVITY;
  Quiz[28].MyGroup = GROUP_NT_HUNTING;
  Quiz[29].MyGroup = GROUP_NT_NVC;
  Quiz[30].MyGroup = GROUP_MIXED;
  Quiz[31].MyGroup = GROUP_SOCIAL;
  Quiz[32].MyGroup = GROUP_SOCIAL;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_ENVIRONMENT;
  Quiz[35].MyGroup = GROUP_MIXED;
  Quiz[36].MyGroup = GROUP_SOCIAL;
  Quiz[37].MyGroup = GROUP_SOCIAL;
  Quiz[38].MyGroup = GROUP_SOCIAL;
  Quiz[39].MyGroup = GROUP_SOCIAL;
  Quiz[40].MyGroup = GROUP_SOCIAL;
  Quiz[41].MyGroup = GROUP_NT_NVC;
  Quiz[42].MyGroup = GROUP_SOCIAL;
  Quiz[43].MyGroup = GROUP_NT_NVC;
  Quiz[44].MyGroup = GROUP_SOCIAL;
  Quiz[45].MyGroup = GROUP_NT_OBSESSION;
  Quiz[46].MyGroup = GROUP_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_OBSESSION;
  Quiz[48].MyGroup = GROUP_SOCIAL;
  Quiz[49].MyGroup = GROUP_SOCIAL;
  Quiz[50].MyGroup = GROUP_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_OBSESSION;
  Quiz[52].MyGroup = GROUP_SOCIAL;
  Quiz[53].MyGroup = GROUP_SOCIAL;
  Quiz[54].MyGroup = GROUP_SOCIAL;
  Quiz[55].MyGroup = GROUP_SOCIAL;
  Quiz[56].MyGroup = GROUP_NT_OBSESSION;
  Quiz[57].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[58].MyGroup = GROUP_ENVIRONMENT;
  Quiz[59].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[60].MyGroup = GROUP_NT_TALENT;
  Quiz[61].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[62].MyGroup = GROUP_MIXED;
  Quiz[63].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[64].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[65].MyGroup = GROUP_NT_TALENT;
  Quiz[66].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[67].MyGroup = GROUP_NT_NVC;
  Quiz[68].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[69].MyGroup = GROUP_MIXED;
  Quiz[70].MyGroup = GROUP_MIXED;
  Quiz[71].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ENVIRONMENT;
  Quiz[74].MyGroup = GROUP_ACTIVITY;
  Quiz[75].MyGroup = GROUP_MIXED;
  Quiz[76].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[77].MyGroup = GROUP_ENVIRONMENT;
  Quiz[78].MyGroup = GROUP_MIXED;
  Quiz[79].MyGroup = GROUP_MIXED;
  Quiz[80].MyGroup = GROUP_ENVIRONMENT;
  Quiz[81].MyGroup = GROUP_ENVIRONMENT;
  Quiz[82].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[83].MyGroup = GROUP_ENVIRONMENT;
  Quiz[84].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[85].MyGroup = GROUP_ENVIRONMENT;
  Quiz[86].MyGroup = GROUP_MIXED;
  Quiz[87].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[88].MyGroup = GROUP_ENVIRONMENT;
  Quiz[89].MyGroup = GROUP_MIXED;
  Quiz[90].MyGroup = GROUP_ASPIE_NVC;
  Quiz[91].MyGroup = GROUP_MIXED;
  Quiz[92].MyGroup = GROUP_ASPIE_NVC;
  Quiz[93].MyGroup = GROUP_ASPIE_NVC;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_NVC;
  Quiz[96].MyGroup = GROUP_ASPIE_NVC;
  Quiz[97].MyGroup = GROUP_MIXED;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_NVC;
  Quiz[100].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[101].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[102].MyGroup = GROUP_ASPIE_NVC;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_ASPIE_NVC;
  Quiz[107].MyGroup = GROUP_ASPIE_NVC;
  Quiz[108].MyGroup = GROUP_ASPIE_NVC;
  Quiz[109].MyGroup = GROUP_ASPIE_NVC;
  Quiz[110].MyGroup = GROUP_MIXED;
  Quiz[111].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[112].MyGroup = GROUP_ASPIE_NVC;
  Quiz[113].MyGroup = GROUP_NT_NVC;
  Quiz[114].MyGroup = GROUP_NT_NVC;
  Quiz[115].MyGroup = GROUP_MIXED;
  Quiz[116].MyGroup = GROUP_NT_NVC;
  Quiz[117].MyGroup = GROUP_NT_NVC;
  Quiz[118].MyGroup = GROUP_NT_NVC;
  Quiz[119].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[120].MyGroup = GROUP_NT_NVC;
  Quiz[121].MyGroup = GROUP_NT_NVC;
  Quiz[122].MyGroup = GROUP_NT_NVC;
  Quiz[123].MyGroup = GROUP_NT_NVC;
  Quiz[124].MyGroup = GROUP_NT_TALENT;
  Quiz[125].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[126].MyGroup = GROUP_NT_NVC;
  Quiz[127].MyGroup = GROUP_NT_SENSORY;
  Quiz[128].MyGroup = GROUP_SOCIAL;
  Quiz[129].MyGroup = GROUP_NT_NVC;
  Quiz[130].MyGroup = GROUP_NT_NVC;
  Quiz[131].MyGroup = GROUP_NT_SENSORY;
  Quiz[132].MyGroup = GROUP_NT_NVC;
  Quiz[133].MyGroup = GROUP_NT_TALENT;
  Quiz[134].MyGroup = GROUP_SOCIAL;
  Quiz[135].MyGroup = GROUP_SOCIAL;
  Quiz[136].MyGroup = GROUP_NT_TALENT;
  Quiz[137].MyGroup = GROUP_SOCIAL;
  Quiz[138].MyGroup = GROUP_ENVIRONMENT;
  Quiz[139].MyGroup = GROUP_NT_SENSORY;

  Quiz[140].MyGroup = GROUP_NT_HUNTING;
  Quiz[141].MyGroup = GROUP_NT_HUNTING;
  Quiz[142].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[143].MyGroup = GROUP_MIXED;
  Quiz[144].MyGroup = GROUP_ACTIVITY;
  Quiz[145].MyGroup = GROUP_SOCIAL;

  Quiz[146].MyGroup = GROUP_RELIGION;
  Quiz[147].MyGroup = GROUP_RELIGION;
  Quiz[148].MyGroup = GROUP_RELIGION;

  Quiz[149].MyGroup = GROUP_RELIGION;
  Quiz[150].MyGroup = GROUP_RELIGION;
  Quiz[151].MyGroup = GROUP_RELIGION;
  Quiz[152].MyGroup = GROUP_RELIGION;

  Quiz[153].MyGroup = GROUP_ASPIE_NVC;
  Quiz[154].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[155].MyGroup = GROUP_SOCIAL;
  Quiz[156].MyGroup = GROUP_NT_NVC;
  Quiz[157].MyGroup = GROUP_NT_NVC;
  Quiz[158].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[159].MyGroup = GROUP_RELIGION;

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

#ifdef ENGLISH
  Quiz[0].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[1].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[2].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[3].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[4].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[5].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[6].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[7].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[8].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[9].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[10].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[11].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[12].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[13].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[14].Text = "Do you have unconventional ways of solving problems?";
  Quiz[15].Text = "Do you have a hyperactive mind?";
  Quiz[16].Text = "Do you notice patterns in things all the time?";
  Quiz[17].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[18].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[19].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[20].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[21].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[22].Text = "Do you have poor concept of time?";
  Quiz[23].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[24].Text = "Are you easily distracted?";
  Quiz[25].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[26].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[27].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[28].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[29].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[30].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[31].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[32].Text = "Have you had more difficulties than others making friends?";
  Quiz[33].Text = "Have you felt different from others for most of your life?";
  Quiz[34].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[35].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[36].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[37].Text = "Do you dislike shaking hands?";
  Quiz[38].Text = "Do you prefer to avoid eye-contact?";
  Quiz[39].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[40].Text = "Are you good at teamwork?";
  Quiz[41].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[42].Text = "Do you feel uncomfortable with strangers?";
  Quiz[43].Text = "Do you find the usual courting behavior natural?";
  Quiz[44].Text = "Do you find it easy to maintain your social network?";
  Quiz[45].Text = "Do you enjoy meeting new people?";
  Quiz[46].Text = "Are you good at social chitchat?";
  Quiz[47].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[48].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[49].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[50].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[51].Text = "Are your views typical of your peer group?";
  Quiz[52].Text = "Do you find it easy to describe your feelings?";
  Quiz[53].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[54].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[55].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[56].Text = "Is a large social network important to you?";
  Quiz[57].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[58].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[59].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[60].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[61].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[62].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[63].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[64].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[65].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[66].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[67].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[68].Text = "Do you have certain routines which you need to follow?";
  Quiz[69].Text = "Have you had a tendency to prefer the company of those who are older or younger than yourself?";
  Quiz[70].Text = "Do you drop things when your attention is on other things?";
  Quiz[71].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[72].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[73].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[74].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[75].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[76].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[77].Text = "Are you sometimes afraid in safe situations?";
  Quiz[78].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[79].Text = "Do you have unusual eating habits?";
  Quiz[80].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[81].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[82].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[83].Text = "Are you prone to getting depressions?";
  Quiz[84].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[85].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[86].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[87].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[88].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[89].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[90].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[91].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[92].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[93].Text = "Do you often don't know where to put your arms?";
  Quiz[94].Text = "Have you been accused of staring?";
  Quiz[95].Text = "Do you make unusual facial expressions?";
  Quiz[96].Text = "Do you have an odd posture or gait?";
  Quiz[97].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[98].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[99].Text = "Do you fiddle with things?";
  Quiz[100].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[101].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[102].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[103].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[104].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[105].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[106].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[107].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[108].Text = "Do you talk to yourself?";
  Quiz[109].Text = "Do you stutter when stressed?";
  Quiz[110].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[111].Text = "Do you easily blush?";
  Quiz[112].Text = "Do you clench your fists when angry?";
  Quiz[113].Text = "Do others often misunderstand you?";
  Quiz[114].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[115].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[116].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[117].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[118].Text = "Are you often surprised what people's motives are ?";
  Quiz[119].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[120].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[121].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[122].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[123].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[124].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[125].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[126].Text = "Do you know when you are expected to offer an apology?";
  Quiz[127].Text = "Do you find it hard to tell the age of people?";
  Quiz[128].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[129].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[130].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[131].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[132].Text = "Do you find it easy to understand what someone is thinking or feeling just by looking at their face?";
  Quiz[133].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[134].Text = "Does it feel natural for you to say 'thank you' and 'sorry'?";
  Quiz[135].Text = "Do people understand you?";
  Quiz[136].Text = "Can you easily remember verbal instructions?";
  Quiz[137].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[138].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[139].Text = "Do you find it easy to estimate the age of people?";

  Quiz[140].Text = "Dyslexia";
  Quiz[141].Text = "Dyscalculia";
  Quiz[142].Text = "OCD";
  Quiz[143].Text = "ODD";
  Quiz[144].Text = "Bipolar";
  Quiz[145].Text = "Social phobia";

  Quiz[146].Text = "Do you believe in God?";
  Quiz[147].Text = "Do you go to church or religious services?";
  Quiz[148].Text = "Do you pray to God?";
  Quiz[149].Text = "Do you have psychic abilities?";
  Quiz[150].Text = "Do you believe in ghosts and / or supernatural phenomens?";
  Quiz[151].Text = "Are you superstitious?";
  Quiz[152].Text = "Have you had paranormal experiences?";

  Quiz[153].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[154].Text = "Are you irritated by inefficiency and do you find it easy to see how things can be done in better ways?";
  Quiz[155].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[156].Text = "Do you find it easy to understand when somebody is interested in you as a potential partner?";
  Quiz[157].Text = "Do you instinctively know how to behave when somebody shows interest in you as a potential partner?";
  Quiz[158].Text = "Do you pull hair?";
  Quiz[159].Text = "Do you believe in a higher power from whom you expect favors, especially if you pray and follow the will of the higher power, as revealed in sacred narratives?";

  Quiz[160].Text = "Rating for Aspie male #1";
  Quiz[161].Text = "Rating for NT female #3";
  Quiz[162].Text = "Rating for Aspie female #3";
  Quiz[163].Text = "Rating for Aspie female #1";
  Quiz[164].Text = "Rating for body-builder";
  Quiz[165].Text = "Rating for horse";
  Quiz[166].Text = "Rating for goat";
  Quiz[167].Text = "Rating for tropical scene #3";
  Quiz[168].Text = "Rating for socker game";
  Quiz[169].Text = "Rating for scandinavian scene #3";

#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[1].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[2].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[3].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[4].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[5].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[6].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[7].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[8].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[9].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[10].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[11].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[12].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[13].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[14].Text = "Brukar du lösa problem på okonventionella sätt?";
  Quiz[15].Text = "Är du mentalt hyperaktiv?";
  Quiz[16].Text = "Ser du mönster i saker hela tiden?";
  Quiz[17].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[18].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[19].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[20].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[21].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[22].Text = "Har du dålig tidsuppfattning?";
  Quiz[23].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[24].Text = "Blir du lätt distraherad?";
  Quiz[25].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[26].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[27].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[28].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[29].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[30].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[31].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[32].Text = "Har du haft svårare än andra att få vänner?";
  Quiz[33].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[34].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[35].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[36].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[37].Text = "Ogillar du att behöva ta i hand?";
  Quiz[38].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[39].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[40].Text = "Är du bra på att arbeta i grupp?";
  Quiz[41].Text = "Trivs du i romantiska situationer?";
  Quiz[42].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[43].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[44].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
  Quiz[45].Text = "Trivs du med att möta nya människor?";
  Quiz[46].Text = "Är du bra på kallprat?";
  Quiz[47].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[48].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[49].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[50].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[51].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[52].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[53].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[54].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[55].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[56].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[57].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[58].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[59].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[60].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[61].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[62].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[63].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[64].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[65].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[66].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[67].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[68].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[69].Text = "Har du haft en tendens att helst umgås med människor som är antingen äldre eller yngre än du själv?";
  Quiz[70].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[71].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[72].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[73].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[74].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[75].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[76].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[77].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[78].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[79].Text = "Har du ovanliga matvanor?";
  Quiz[80].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[81].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[82].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[83].Text = "Brukar du få depressioner?";
  Quiz[84].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[85].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[86].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[87].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[88].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[89].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[90].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[91].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[92].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[93].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[94].Text = "Har du blivit anklagad för att stirra?";
  Quiz[95].Text = "Har du ovanliga ansiktsuttryck?";
  Quiz[96].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[97].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[98].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[99].Text = "Brukar du fingra på saker?";
  Quiz[100].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[101].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[102].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[103].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[104].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[105].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[106].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[107].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[108].Text = "Brukar du prata med dig själv?";
  Quiz[109].Text = "Stammar du när du blir stressad?";
  Quiz[110].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[111].Text = "Rodnar du lätt?";
  Quiz[112].Text = "Knyter du nävarna när du är arg?";
  Quiz[113].Text = "Blir du ofta missförstådd av andra?";
  Quiz[114].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[115].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[116].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[117].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[118].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[119].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[120].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[121].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[122].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[123].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[124].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[125].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[126].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[127].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[128].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[129].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[130].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[131].Text = "Har du svårt att känna igen ansikten?";
  Quiz[132].Text = "Tycker du det är lätt att förstå vad någon tänker eller känner genom att bara titta på deras ansikte?";
  Quiz[133].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[134].Text = "Känns det naturligt för dig att säga 'tack' och 'förlåt'?";
  Quiz[135].Text = "Förstår sig folk på dig?";
  Quiz[136].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[137].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[138].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[139].Text = "Har du lätt för att bedömma människors ålder?";

  Quiz[140].Text = "Dyslexi";
  Quiz[141].Text = "Dyskaluli";
  Quiz[142].Text = "OCD";
  Quiz[143].Text = "ODD";
  Quiz[144].Text = "Bipolär";
  Quiz[145].Text = "Social fobi";

  Quiz[146].Text = "Tror du på Gud?";
  Quiz[147].Text = "Går du till kyrkan eller religösa arrangemang?";
  Quiz[148].Text = "Ber du till Gud?";
  Quiz[149].Text = "Har du övernaturliga förmågor?";
  Quiz[150].Text = "Tror du på spöken och / eller övernaturliga fenomen?";
  Quiz[151].Text = "Är du vidskeplig?";
  Quiz[152].Text = "Har du haft övernaturliga upplevelser?";

  Quiz[153].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[154].Text = "Blir du irriterad på ineffektivitet och har du lätt för att se hur saker kan göras på smidigare sätt?";
  Quiz[155].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[156].Text = "Tycker du det är lätt att förstå om någon är intresserad av dig som möjlig partner?";
  Quiz[157].Text = "Vet du instinktivt hur du ska uppföra dig om någon visar intresse för dig som möjlig partner?";
  Quiz[158].Text = "Brukar du dra ut hårstrån?";
  Quiz[159].Text = "Tror du på en högre makt från vilken du förväntar dig tjänster, speciellt om du ber och följer denna högre makts vilja, så som det står beskriviet i heliga skrifter?";

  Quiz[160].Text = "Bedömning för Aspie kille #1";
  Quiz[161].Text = "Bedömning för NT tjej #3";
  Quiz[162].Text = "Bedömning för Aspie tjej #3";
  Quiz[163].Text = "Bedömning för Aspie tjej #1";
  Quiz[164].Text = "Bedömning för kroppsbyggare";
  Quiz[165].Text = "Bedömning för häst";
  Quiz[166].Text = "Bedömning för get";
  Quiz[167].Text = "Bedömning för tropisk scen #3";
  Quiz[168].Text = "Bedömning för fotbollsmatch";
  Quiz[169].Text = "Bedömning för skandinavisk scen #3";

#endif
}

/*##########################################################################
#
#   Name       : TQuizS2::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::InitReferers()
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

}

/*##################  TQuizS2::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::LoadReferers()
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
#   Name       : TQuizS2::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;
	int id;
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

		Row.Quiz[140] = Row.Dyslexia + 1;
		Row.Quiz[141] = Row.Dyscalculia + 1;
		Row.Quiz[142] = Row.OCD + 1;
		Row.Quiz[143] = Row.ODD + 1;
		Row.Quiz[144] = Row.Bipolar + 1;
		Row.Quiz[145] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
		    else
			{
				if (i < 140 || (i >= 146 && i < 160))
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
#   Name       : TQuizS2::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::SetupControlGroups()
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

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizS2::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1)
{
	DefineCross(QuizS1, 0, 1);
    DefineCross(QuizS1, 1, 0);
    DefineCross(QuizS1, 2, 2);
    DefineCross(QuizS1, 3, 3);
    DefineCross(QuizS1, 4, 4);
    DefineCross(QuizS1, 5, 5);
    DefineCross(QuizS1, 6, 6);
    DefineCross(QuizS1, 7, 7);
    DefineCross(QuizS1, 8, 8);
	DefineCross(QuizS1, 9, 9);
    DefineCross(QuizS1, 10, 10);
    DefineCross(QuizS1, 11, 11);
	DefineCross(QuizS1, 12, 12);
	DefineCross(QuizS1, 13, 13);
    DefineCross(QuizS1, 14, 14);
    DefineCross(QuizS1, 15, 16);
    DefineCross(QuizS1, 16, 15);
	DefineCross(QuizS1, 17, 17);
	DefineCross(QuizS1, 18, 18);
    DefineCross(QuizS1, 19, 19);
    DefineCross(QuizS1, 20, 20);
    DefineCross(QuizS1, 21, 23);
    DefineCross(QuizS1, 22, 21);
    DefineCross(QuizS1, 23, 22);
	DefineCross(QuizS1, 24, 24);
	DefineCross(QuizS1, 25, 26);
    DefineCross(QuizS1, 26, 27);
    DefineCross(QuizS1, 27, 28);
	DefineCross(QuizS1, 28, 29);
    DefineCross(QuizS1, 29, 30);
    DefineCross(QuizS1, 30, 31);
    DefineCross(QuizS1, 31, 32);
    DefineCross(QuizS1, 32, 33);
    DefineCross(QuizS1, 33, 35);
	DefineCross(QuizS1, 34, 34);
	DefineCross(QuizS1, 35, 37);
    DefineCross(QuizS1, 36, 36);
    DefineCross(QuizS1, 37, 38);
    DefineCross(QuizS1, 38, 39);
    DefineCross(QuizS1, 39, 40);
    DefineCross(QuizS1, 40, 43);
    DefineCross(QuizS1, 41, 42);
    DefineCross(QuizS1, 42, 45);
    DefineCross(QuizS1, 43, 44);
	DefineCross(QuizS1, 44, 46);
    DefineCross(QuizS1, 45, 47);
    DefineCross(QuizS1, 46, 48);
	DefineCross(QuizS1, 47, 51);
	DefineCross(QuizS1, 48, 49);
    DefineCross(QuizS1, 49, 50);
    DefineCross(QuizS1, 50, 54);
    DefineCross(QuizS1, 51, 52);
	DefineCross(QuizS1, 52, 53);
	DefineCross(QuizS1, 53, 56);
    DefineCross(QuizS1, 54, 57);
    DefineCross(QuizS1, 55, 58);
    DefineCross(QuizS1, 56, 59);
    DefineCross(QuizS1, 57, 60);
    DefineCross(QuizS1, 58, 61);
	DefineCross(QuizS1, 59, 119);
	DefineCross(QuizS1, 60, 62);
    DefineCross(QuizS1, 61, 63);
    DefineCross(QuizS1, 62, 64);
	DefineCross(QuizS1, 63, 65);
    DefineCross(QuizS1, 64, 66);
    DefineCross(QuizS1, 65, 69);
    DefineCross(QuizS1, 66, 67);
    DefineCross(QuizS1, 67, 68);
    DefineCross(QuizS1, 68, 71);
	DefineCross(QuizS1, 69, 70);
	DefineCross(QuizS1, 70, 72);
    DefineCross(QuizS1, 71, 74);
    DefineCross(QuizS1, 72, 75);
    DefineCross(QuizS1, 73, 73);
    DefineCross(QuizS1, 74, 78);
    DefineCross(QuizS1, 75, 80);
    DefineCross(QuizS1, 76, 83);
    DefineCross(QuizS1, 77, 77);
    DefineCross(QuizS1, 78, 82);
	DefineCross(QuizS1, 79, 84);
    DefineCross(QuizS1, 80, 86);
    DefineCross(QuizS1, 81, 87);
	DefineCross(QuizS1, 82, 88);
	DefineCross(QuizS1, 83, 91);
    DefineCross(QuizS1, 84, 90);
    DefineCross(QuizS1, 85, 92);
    DefineCross(QuizS1, 86, 94);
	DefineCross(QuizS1, 87, 95);
	DefineCross(QuizS1, 88, 93);
    DefineCross(QuizS1, 89, 97);
    DefineCross(QuizS1, 90, 98);
    DefineCross(QuizS1, 91, 100);
    DefineCross(QuizS1, 92, 121);
    DefineCross(QuizS1, 93, 76);
	DefineCross(QuizS1, 94, 79);
	DefineCross(QuizS1, 95, 101);
    DefineCross(QuizS1, 96, 81);
    DefineCross(QuizS1, 97, 85);
	DefineCross(QuizS1, 98, 104);
    DefineCross(QuizS1, 99, 102);
    DefineCross(QuizS1, 100, 103);
    DefineCross(QuizS1, 101, 105);
    DefineCross(QuizS1, 102, 106);
    DefineCross(QuizS1, 103, 108);
	DefineCross(QuizS1, 104, 89);
	DefineCross(QuizS1, 105, 111);
    DefineCross(QuizS1, 106, 107);
    DefineCross(QuizS1, 107, 109);
    DefineCross(QuizS1, 108, 112);
    DefineCross(QuizS1, 109, 96);
    DefineCross(QuizS1, 110, 110);
    DefineCross(QuizS1, 111, 140);
    DefineCross(QuizS1, 112, 114);
    DefineCross(QuizS1, 113, 115);
	DefineCross(QuizS1, 114, 116);
    DefineCross(QuizS1, 115, 117);
    DefineCross(QuizS1, 116, 118);
	DefineCross(QuizS1, 117, 122);
	DefineCross(QuizS1, 118, 123);
    DefineCross(QuizS1, 119, 120);
    DefineCross(QuizS1, 120, 124);
    DefineCross(QuizS1, 121, 125);
	DefineCross(QuizS1, 122, 126);
	DefineCross(QuizS1, 123, 127);
    DefineCross(QuizS1, 124, 128);
    DefineCross(QuizS1, 125, 129);
    DefineCross(QuizS1, 126, 130);
    DefineCross(QuizS1, 127, 131);
    DefineCross(QuizS1, 128, 133);
	DefineCross(QuizS1, 129, 134);
	DefineCross(QuizS1, 130, 132);
    DefineCross(QuizS1, 131, 135);
    DefineCross(QuizS1, 132, 136);
	DefineCross(QuizS1, 133, 137);
	DefineCross(QuizS1, 134, 139);
	DefineCross(QuizS1, 135, 41);
	DefineCross(QuizS1, 136, 25);
	DefineCross(QuizS1, 137, 55);
	DefineCross(QuizS1, 138, 99);
	DefineCross(QuizS1, 139, 138);

	DefineCross(QuizS1, 140, 141);
	DefineCross(QuizS1, 141, 142);
	DefineCross(QuizS1, 142, 143);
	DefineCross(QuizS1, 143, 144);
	DefineCross(QuizS1, 144, 145);
	DefineCross(QuizS1, 145, 146);

	DefineGlobalId(146, 761);
	DefineGlobalId(147, 762);
	DefineGlobalId(148, 763);
	DefineCross(Quiz9, 149, 146);
	DefineCross(QuizII, 150, 12);
	DefineCross(Quiz8, 151, 134);
	DefineCross(Quiz8, 152, 136);

	DefineGlobalId(153, 764);
	DefineGlobalId(154, 765);
	DefineGlobalId(155, 766);
	DefineGlobalId(156, 767);
	DefineGlobalId(157, 768);
	DefineGlobalId(158, 769);
	DefineGlobalId(159, 770);

	DefineCross(QuizS1, 160, 147);
	DefineGlobalId(161, 771);
	DefineGlobalId(162, 772);
	DefineCross(QuizS1, 163, 148);
	DefineGlobalId(164, 773);
	DefineGlobalId(165, 774);
	DefineGlobalId(166, 775);
	DefineGlobalId(167, 776);
	DefineCross(QuizS1, 168, 153);
	DefineGlobalId(169, 777);
}

/*##########################################################################
#
#   Name       : TQuizS2::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS2::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizS2::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS2::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::ExportExcelAspie(const char *filename)
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
					ival = 3 - ival;
				else
					ival--;
			}


			if (ival > 2)
				ival = 0;

			sprintf(str, "\"%d\"", ival);
			file.Write(str);
			if (i != N - 1)
				file.Write(", ");
		}
		file.Write("\n");
	}
}

/*##################  TQuizS2::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS2::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_FEMALE)
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

/*##################  round ##########################
*   Purpose....: round long double to int       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int round(long double val)
{
	return (int)(val + 0.5);
}

/*##################  WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
	char str[80];

	sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
	File.Write(str);

	File.Write("<p align=\"center\">\n");
	File.Write("<b>\n");
}

/*##################  WriteFieldFooter ##########################
*   Purpose....: Write field footer for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteFieldFooter(TFile &File)
{
	File.Write("\n</b>\n");
	File.Write("</p>\n");

	File.Write("</td>\n");
}

/*##################  TQuizS2::WritePictureRating ##########################
*   Purpose....: Write picture rating report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::WritePictureRating(const char *filename)
{
	int NtRateCount[10];
	long double NtRateSum[10];
	long double NtRateMean[10];
	long double NtRateSd[10];
	int NtViewCount[10];
	long double NtViewSum[10];
	long double NtViewMean[10];
	long double NtViewSd[10];
	int AsRateCount[10];
	long double AsRateSum[10];
	long double AsRateMean[10];
	long double AsRateSd[10];
	int AsViewCount[10];
	long double AsViewSum[10];
	long double AsViewMean[10];
	long double AsViewSd[10];
	int UseMale[10];
	int UseFemale[10];
	int use;
	int i;
	int ival;
	long double val;
	long double dev;
	char str[80];
	int diff;
	TQuizRow Row;
	TFile file(filename, 0);

	for (i = 0; i < 10; i++)
	{
		AsRateCount[i] = 0;
		AsRateSum[i] = 0;
		AsViewCount[i] = 0;
		AsViewSum[i] = 0;

		NtRateCount[i] = 0;
		NtRateSum[i] = 0;
		NtViewCount[i] = 0;
		NtViewSum[i] = 0;

		UseMale[i] = TRUE;
		UseFemale[i] = TRUE;
	}

	UseMale[0] = FALSE;
	UseFemale[1] = FALSE;
	UseFemale[2] = FALSE;
	UseFemale[3] = FALSE;
	UseMale[4] = FALSE;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < 10; i++)
		{
		    if (Row.Gender == 2)
		        use = UseFemale[i];
		    else
		        use = UseMale[i];

            if (use)
            {		    
    			diff = Row.AsResult - Row.NtResult;
	    		if (Row.Rating[i])
		    	{
			    	if (diff > 0)
				    {
    					AsRateCount[i]++;
	    				AsRateSum[i] += Row.Rating[i] - 1;
		    		}
			    	else
				    {
    					NtRateCount[i]++;
	    				NtRateSum[i] += Row.Rating[i] - 1;
		    		}
    			}

	    		if (Row.ViewTime[i])
		    	{
			    	if (Row.ViewTime[i] < 30000)
				    {
    					if (diff > 0)
	    				{
		    				AsViewCount[i]++;
			    			AsViewSum[i] += Row.ViewTime[i];
				    	}
    					else
	    				{
		    				NtViewCount[i]++;
			    			NtViewSum[i] += Row.ViewTime[i];
				    	}
    				}
	    		}
	        }
		}
	}

	for (i = 0; i < 10; i++)
	{
		AsRateMean[i] = AsRateSum[i] / AsRateCount[i];
		AsViewMean[i] = AsViewSum[i] / AsViewCount[i];

		NtRateMean[i] = NtRateSum[i] / NtRateCount[i];
		NtViewMean[i] = NtViewSum[i] / NtViewCount[i];
	}

	for (i = 0; i < 10; i++)
	{
		AsRateCount[i] = 0;
		AsRateSum[i] = 0;
		AsViewCount[i] = 0;
		AsViewSum[i] = 0;

		NtRateCount[i] = 0;
		NtRateSum[i] = 0;
		NtViewCount[i] = 0;
		NtViewSum[i] = 0;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < 10; i++)
		{
		    if (Row.Gender == 2)
		        use = UseFemale[i];
		    else
		        use = UseMale[i];

            if (use)
            {		    
    			diff = Row.AsResult - Row.NtResult;
	    		if (Row.Rating[i])
		    	{
			    	if (diff > 0)
    				{
	    				AsRateCount[i]++;
		    			val = (long double)(Row.Rating[i] - 1) - AsRateMean[i];
			    		AsRateSum[i] += val * val;
    				}
	    			else
		    		{
			    		NtRateCount[i]++;
    					val = (long double)(Row.Rating[i] - 1) - NtRateMean[i];
	    				NtRateSum[i] += val * val;
		    		}
			    }

    			if (Row.ViewTime[i])
	    		{
		    		if (Row.ViewTime[i] < 30000)
			    	{
    					if (diff > 0)
	    				{
		    				AsViewCount[i]++;
			    			val = (long double)Row.Rating[i] - AsViewMean[i];
				    		AsViewSum[i] += val * val;
    					}
	    				else
		    			{
			    			NtViewCount[i]++;
				    		val = (long double)Row.Rating[i] - NtViewMean[i];
					    	NtViewSum[i] += val * val;
    					}
	    			}
	    		}
			}
		}
	}

	for (i = 0; i < 10; i++)
	{
		AsRateSd[i] = sqrtl(AsRateSum[i] / ((long double)AsRateCount[i] - 1));
		AsViewSd[i] = sqrtl(AsViewSum[i] / ((long double)AsViewCount[i] - 1));

		NtRateSd[i] = sqrtl(NtRateSum[i] / ((long double)NtRateCount[i] - 1));
		NtViewSd[i] = sqrtl(NtViewSum[i] / ((long double)NtViewCount[i] - 1));
	}

	file.Write("<h3>Image rating</h3>");

	sprintf(str, "AS rate count: %d<br>", AsRateCount[0]);
	file.Write(str);

	sprintf(str, "NT rate count: %d<br>", NtRateCount[0]);
	file.Write(str);

	sprintf(str, "AS view time count: %d<br>", AsViewCount[0]);
	file.Write(str);

	sprintf(str, "NT view time count: %d<br>", NtViewCount[0]);
	file.Write(str);

	file.Write("<br>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Image");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Rating (AS/NT)");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("View-time (AS/NT)");
	WriteFieldFooter(file);

	file.Write("</tr>");


    for (i = 0; i < 10; i++)
    {
    	file.Write("<tr style='height:24.75pt'>");

	    WriteCenteredFieldHeader(file, 25);
	    switch (i)
	    {
	        case 0:
            	file.Write("Aspie male #1");
            	break;
            	
			case 1:
            	file.Write("NT female #3");
            	break;
            	
	        case 2:
            	file.Write("Aspie female #3");
            	break;
            	
	        case 3:
            	file.Write("Aspie female #1");
            	break;
            	
	        case 4:
            	file.Write("Body-builder");
            	break;
            	
	        case 5:
            	file.Write("Horse");
            	break;
            	
	        case 6:
            	file.Write("Goat");
            	break;
            	
	        case 7:
            	file.Write("Tropical scene #3");
            	break;
            	
	        case 8:
            	file.Write("Socker game");
            	break;

	        case 9:
            	file.Write("Scandinavian scene #3");
            	break;
		}
            	            	
   	    WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 12);

#ifdef CI

		dev = 1.96 * AsRateSd[i] / sqrtl(AsRateCount[i]);

		val = AsRateMean[i] - dev;
		if (val < 0.0)
			val = 0.0;

		ival = round(10 * val);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		val = AsRateMean[i] + dev;
		if (val > 10.0)
			val = 10.0;

		ival = round(10 * val);

		sprintf(str, "-%d.%01d / ", ival / 10, ival % 10);
		file.Write(str);

#else
		val = AsRateMean[i];
		if (val < 0.0)
			val = 0.0;

		ival = round(10 * val);

		sprintf(str, "%d.%01d / ", ival / 10, ival % 10);
		file.Write(str);

#endif


#ifdef CI

		dev = 1.96 * NtRateSd[i] / sqrtl(NtRateCount[i]);

		val = NtRateMean[i] - dev;
		if (val < 0.0)
			val = 0.0;

		ival = round(10 * val);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		val = NtRateMean[i] + dev;
		if (val > 10.0)
			val = 10.0;

		ival = round(10 * val);

		sprintf(str, "-%d.%01d", ival / 10, ival % 10);
		file.Write(str);

#else

		val = NtRateMean[i];
		if (val < 0.0)
			val = 0.0;

		ival = round(10 * val);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

#endif

		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 12);

#ifdef CI

		dev = 1.96 * AsViewSd[i] / sqrtl(AsViewCount[i]);

		val = AsViewMean[i] - dev;
		if (val < 0.0)
			val = 0.0;

		ival = round(val / 100);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		val = AsViewMean[i] + dev;

		ival = round(val / 100);

		sprintf(str, "-%d.%01d s / ", ival / 10, ival % 10);
		file.Write(str);

#else

		val = AsViewMean[i];
		if (val < 0.0)
			val = 0.0;

		ival = round(val / 100);

		sprintf(str, "%d.%01d s / ", ival / 10, ival % 10);
		file.Write(str);
#endif


#ifdef  CI

		dev = 1.96 * NtViewSd[i] / sqrtl(NtViewCount[i]);

		val = NtViewMean[i] - dev;
		if (val < 0.0)
			val = 0.0;

		ival = round(val / 100);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		val = NtViewMean[i] + dev;

		ival = round(val / 100);

		sprintf(str, "-%d.%01d s", ival / 10, ival % 10);
		file.Write(str);

#else

		val = NtViewMean[i];
		if (val < 0.0)
			val = 0.0;

		ival = round(val / 100);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

#endif

    	WriteFieldFooter(file);

    	file.Write("</tr>");
    }
	file.Write("</table>");
   	
}

/*##################  TQuizS2::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS2::WriteRetest(const char *filename)
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
	long double QMean[140];
	long double AsSd;
	long double NtSd;
	long double QSd[140];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[140];
	int QCount[140];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[140][20];
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

    for (q = 0; q < 140; q++)
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

                    for (q = 0; q < 140; q++)
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

                	        for (q = 0; q < 140; q++)
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
    
	    			for (q = 0; q < 140; q++)
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

	    			for (q = 0; q < 140; q++)
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
//		    		for (q = 0; q < 140; q++)
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

	for (q = 0; q < 140; q++)
	{
	    sprintf(str, "%d. ", q + 1);
	    file.Write(str);
	    
		file.Write(Quiz[q].Text);
	    
	    sd = QTot[q] / QCount[q];

        sprintf(str, " <b>%3.2Lf</b><br>", sd);
    	file.Write(str);
    }
}
