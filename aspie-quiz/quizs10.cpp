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
# quizS10.cpp
# Quiz stable version 9 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizS10.h"
#include "file.h"
#include "quizdS10.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS10::TQuizS10
#
#   Purpose....: Constructor for TQuizS10
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS10::TQuizS10(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9)
  : TQuiz(194),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS10::~TQuizS10
#
#   Purpose....: Destructor for TQuizS10
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS10::~TQuizS10()
{
}

/*##################  TQuizS10::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS10::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS10::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS10::GetCatCount(int Question)
{
	if (Question >= 168 && Question <= 187)
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
int TQuizS10::GetQuizN()
{
	return 168;
}

/*##########################################################################
#
#   Name       : TQuizS10::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::WriteName(TFile &File)
{
	 File.Write("S10");
}

/*##########################################################################
#
#   Name       : TQuizS10::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::WriteLongName(TFile &File)
{
	 File.Write("stable version 10");
}

/*##################  TQuizS10::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS10::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::SetupTexts()
{
  Quiz[18].Reverse = TRUE;
  Quiz[31].Reverse = TRUE;
  Quiz[32].Reverse = TRUE;
  Quiz[34].Reverse = TRUE;
  Quiz[35].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[47].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[86].Reverse = TRUE;
  Quiz[87].Reverse = TRUE;
  Quiz[89].Reverse = TRUE;
  Quiz[90].Reverse = TRUE;
  Quiz[91].Reverse = TRUE;
  Quiz[92].Reverse = TRUE;
  Quiz[93].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;
  Quiz[150].Reverse = TRUE;
  Quiz[151].Reverse = TRUE;
  Quiz[152].Reverse = TRUE;
  Quiz[160].Reverse = TRUE;
  Quiz[163].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_OBSESSION;
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
  Quiz[20].MyGroup = GROUP_NT_TALENT;
  Quiz[21].MyGroup = GROUP_NT_HUNTING;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[28].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[29].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[30].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[31].MyGroup = GROUP_NT_OBSESSION;
  Quiz[32].MyGroup = GROUP_NT_OBSESSION;
  Quiz[33].MyGroup = GROUP_NT_OBSESSION;
  Quiz[34].MyGroup = GROUP_NT_OBSESSION;
  Quiz[35].MyGroup = GROUP_NT_OBSESSION;
  Quiz[36].MyGroup = GROUP_NT_OBSESSION;
  Quiz[37].MyGroup = GROUP_ACTIVITY;
  Quiz[38].MyGroup = GROUP_ACTIVITY;
  Quiz[39].MyGroup = GROUP_MIXED;
  Quiz[40].MyGroup = GROUP_MIXED;
  Quiz[41].MyGroup = GROUP_ENVIRONMENT;
  Quiz[42].MyGroup = GROUP_SOCIAL;
  Quiz[43].MyGroup = GROUP_SOCIAL;
  Quiz[44].MyGroup = GROUP_SOCIAL;
  Quiz[45].MyGroup = GROUP_SOCIAL;
  Quiz[46].MyGroup = GROUP_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_NVC;
  Quiz[48].MyGroup = GROUP_SOCIAL;
  Quiz[49].MyGroup = GROUP_SOCIAL;
  Quiz[50].MyGroup = GROUP_SOCIAL;
  Quiz[51].MyGroup = GROUP_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_NVC;
  Quiz[53].MyGroup = GROUP_SOCIAL;
  Quiz[54].MyGroup = GROUP_SOCIAL;
  Quiz[55].MyGroup = GROUP_SOCIAL;
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
  Quiz[90].MyGroup = GROUP_NT_NVC;
  Quiz[91].MyGroup = GROUP_NT_NVC;
  Quiz[92].MyGroup = GROUP_NT_NVC;
  Quiz[93].MyGroup = GROUP_NT_TALENT;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[96].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[98].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[99].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[100].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[101].MyGroup = GROUP_SOCIAL;
  Quiz[102].MyGroup = GROUP_NT_HUNTING;
  Quiz[103].MyGroup = GROUP_NT_SENSORY;
  Quiz[104].MyGroup = GROUP_NT_SENSORY;
  Quiz[105].MyGroup = GROUP_NT_SENSORY;
  Quiz[106].MyGroup = GROUP_NT_SENSORY;
  Quiz[107].MyGroup = GROUP_NT_SENSORY;
  Quiz[108].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[109].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[110].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[111].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[112].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[113].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[114].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[115].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[116].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[117].MyGroup = GROUP_NT_SENSORY;
  Quiz[118].MyGroup = GROUP_NT_SENSORY;
  Quiz[119].MyGroup = GROUP_NT_SENSORY;
  Quiz[120].MyGroup = GROUP_NT_NVC;
  Quiz[121].MyGroup = GROUP_NT_SENSORY;
  Quiz[122].MyGroup = GROUP_NT_HUNTING;
  Quiz[123].MyGroup = GROUP_PARANOID;
  Quiz[124].MyGroup = GROUP_PARANOID;
  Quiz[125].MyGroup = GROUP_PARANOID;
  Quiz[126].MyGroup = GROUP_ENVIRONMENT;
  Quiz[127].MyGroup = GROUP_ENVIRONMENT;
  Quiz[128].MyGroup = GROUP_ENVIRONMENT;
  Quiz[129].MyGroup = GROUP_ENVIRONMENT;
  Quiz[130].MyGroup = GROUP_ENVIRONMENT;
  Quiz[131].MyGroup = GROUP_ENVIRONMENT;
  Quiz[132].MyGroup = GROUP_ENVIRONMENT;
  Quiz[133].MyGroup = GROUP_ENVIRONMENT;
  Quiz[134].MyGroup = GROUP_ENVIRONMENT;
  Quiz[135].MyGroup = GROUP_NT_NVC;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_MIXED;
  Quiz[138].MyGroup = GROUP_MIXED;
  Quiz[139].MyGroup = GROUP_MIXED;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_ASPIE_NVC;
  Quiz[143].MyGroup = GROUP_MIXED;
  Quiz[144].MyGroup = GROUP_ASPIE_NVC;
  Quiz[145].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[146].MyGroup = GROUP_NT_TALENT;
  Quiz[147].MyGroup = GROUP_NT_NVC;
  Quiz[148].MyGroup = GROUP_SOCIAL;
  Quiz[149].MyGroup = GROUP_NT_NVC;
  Quiz[150].MyGroup = GROUP_NT_SENSORY;
  Quiz[151].MyGroup = GROUP_NT_SENSORY;
  Quiz[152].MyGroup = GROUP_ENVIRONMENT;

  Quiz[153].MyGroup = GROUP_NT_TALENT;
  Quiz[154].MyGroup = GROUP_ASPIE_NVC;
  Quiz[155].MyGroup = GROUP_SOCIAL;
  Quiz[156].MyGroup = GROUP_SOCIAL;
  Quiz[157].MyGroup = GROUP_SOCIAL;
  Quiz[158].MyGroup = GROUP_MIXED;
  Quiz[159].MyGroup = GROUP_MIXED;
  Quiz[160].MyGroup = GROUP_ENVIRONMENT;
  Quiz[161].MyGroup = GROUP_MIXED;
  Quiz[162].MyGroup = GROUP_SOCIAL;
  Quiz[163].MyGroup = GROUP_NT_NVC;
  Quiz[164].MyGroup = GROUP_MIXED;
  Quiz[165].MyGroup = GROUP_ACTIVITY;
  Quiz[166].MyGroup = GROUP_ACTIVITY;
  Quiz[167].MyGroup = GROUP_ASPIE_OBSESSION;

  Quiz[168].MyGroup = GROUP_NT_HUNTING;
  Quiz[169].MyGroup = GROUP_NT_HUNTING;
  Quiz[170].MyGroup = GROUP_SOCIAL;
  Quiz[171].MyGroup = GROUP_NT_HUNTING;
  Quiz[172].MyGroup = GROUP_MIXED;
  Quiz[173].MyGroup = GROUP_NT_HUNTING;
  Quiz[174].MyGroup = GROUP_NT_HUNTING;
  Quiz[175].MyGroup = GROUP_MIXED;
  Quiz[176].MyGroup = GROUP_SOCIAL;
  Quiz[177].MyGroup = GROUP_NT_HUNTING;
  Quiz[178].MyGroup = GROUP_NT_HUNTING;
  Quiz[179].MyGroup = GROUP_NT_HUNTING;
  Quiz[180].MyGroup = GROUP_NT_HUNTING;
  Quiz[181].MyGroup = GROUP_NT_HUNTING;
  Quiz[182].MyGroup = GROUP_NT_HUNTING;
  Quiz[183].MyGroup = GROUP_NT_HUNTING;
  Quiz[184].MyGroup = GROUP_NT_HUNTING;
  Quiz[185].MyGroup = GROUP_NT_HUNTING;
  Quiz[186].MyGroup = GROUP_NT_HUNTING;
  Quiz[187].MyGroup = GROUP_NT_HUNTING;

  Quiz[188].MyGroup = GROUP_NT_HUNTING;
  Quiz[189].MyGroup = GROUP_NT_HUNTING;
  Quiz[190].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[191].MyGroup = GROUP_MIXED;
  Quiz[192].MyGroup = GROUP_ACTIVITY;
  Quiz[193].MyGroup = GROUP_SOCIAL;

#ifdef ENGLISH

  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[2].Text = "Have you felt different from others for most of your life?";
  Quiz[3].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[4].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[5].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[6].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[7].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
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
  Quiz[20].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[21].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[22].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[23].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[24].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[25].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[26].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[27].Text = "Do you have certain routines which you need to follow?";
  Quiz[28].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[29].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[30].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[31].Text = "Do you enjoy meeting new people?";
  Quiz[32].Text = "Are your views typical of your peer group?";
  Quiz[33].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[34].Text = "Is a large social network important to you?";
  Quiz[35].Text = "Do you take pride in your appearance?";
  Quiz[36].Text = "Do you enjoy gossip?";
  Quiz[37].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[38].Text = "Are you easily distracted?";
  Quiz[39].Text = "Has there been a period of time when you were not your usual self and you were so irritable that you shouted at people or started fights or arguments?";
  Quiz[40].Text = "Has there been a period of time when you were not your usual self and you were much more talkative than usual?";
  Quiz[41].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[42].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[43].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[44].Text = "Do you prefer to avoid eye-contact?";
  Quiz[45].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[46].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[47].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[48].Text = "Do you dislike shaking hands?";
  Quiz[49].Text = "Do people think you are aloof and distant?";
  Quiz[50].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[51].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[52].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[53].Text = "Do you find it easy to describe your feelings?";
  Quiz[54].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[55].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[56].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[57].Text = "Do you dislike working while being observed?";
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
  Quiz[83].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[84].Text = "Are you often surprised what people's motives are ?";
  Quiz[85].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[86].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[87].Text = "Do you know when you are expected to offer an apology?";
  Quiz[88].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[89].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[90].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[91].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[92].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[93].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[94].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[95].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[96].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[97].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[98].Text = "Do you enjoy walking on your toes?";
  Quiz[99].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[100].Text = "Have you been fascinated about making traps?";
  Quiz[101].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[102].Text = "Do you drop things when your attention is on other things?";
  Quiz[103].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[104].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[105].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[106].Text = "Do you have difficulties with fine motor skills and/or hand-eye co-ordination?";
  Quiz[107].Text = "Did you perceive practical classes like handi-work or gymnasics as hard in school?";
  Quiz[108].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[109].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[110].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[111].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[112].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[113].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[114].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[115].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[116].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[117].Text = "Do you have poor concept of time?";
  Quiz[118].Text = "Do you find it hard to tell the age of people?";
  Quiz[119].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[120].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[121].Text = "Are you good at keeping track of where people are (for instance in team-sports)?";
  Quiz[122].Text = "Do you confuse left and right?";
  Quiz[123].Text = "Do you feel that people are watching you?";
  Quiz[124].Text = "Do you mistake noises for voices?";
  Quiz[125].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[126].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[127].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[128].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[129].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[130].Text = "Are you sometimes afraid in safe situations?";
  Quiz[131].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[132].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[133].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[134].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[135].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[136].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[137].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[138].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[139].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[140].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[141].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[142].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[143].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[144].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[145].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[146].Text = "Can you easily remember verbal instructions?";
  Quiz[147].Text = "Do people understand you?";
  Quiz[148].Text = "Are you good at teamwork?";
  Quiz[149].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[150].Text = "Do you find it easy to estimate the age of people?";
  Quiz[151].Text = "Do you have a good sense of what time it is?";
  Quiz[152].Text = "Are you gracious about criticism, correction and direction?";

  Quiz[153].Text = "Do you frequently misplace things?";
  Quiz[154].Text = "Do you turn words around in conversations?";
  Quiz[155].Text = "Do you have a tendency to turn off when asked questions in social situation?";
  Quiz[156].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[157].Text = "Are you self-centered?";
  Quiz[158].Text = "Do you have immature interests?";
  Quiz[159].Text = "Do you have trouble with authority?";
  Quiz[160].Text = "Do you have good self-esteem?";
  Quiz[161].Text = "Do you respond quickly to slights?";
  Quiz[162].Text = "Do you find it natural to go through established channels?";
  Quiz[163].Text = "Do you follow expected procedures?";
  Quiz[164].Text = "Do you prefer to read directions only when all else have failed?";
  Quiz[165].Text = "Do you have problems starting and / or finishing projects?";
  Quiz[166].Text = "Are you poor at organizing your work and / or life?";
  Quiz[167].Text = "Do you like to organize your work and / or life?";

  Quiz[168].Text = "DYSLEXIA - Do you find difficulty in telling left from right?";
  Quiz[169].Text = "DYSLEXIA - Is map reading or finding your way to a strange place confusing?";
  Quiz[170].Text = "DYSLEXIA - Do you dislike reading aloud?";
  Quiz[171].Text = "DYSLEXIA - Do you take longer than you should to read a page of a book?";
  Quiz[172].Text = "DYSLEXIA - Do you find it difficult to remember the sense of what you have read?";
  Quiz[173].Text = "DYSLEXIA - Do you dislike reading long books?";
  Quiz[174].Text = "DYSLEXIA - Is your spelling poor?";
  Quiz[175].Text = "DYSLEXIA - Is your writing difficult to read?";
  Quiz[176].Text = "DYSLEXIA - Do you get confused if you have to speak in public?";
  Quiz[177].Text = "DYSLEXIA - Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[178].Text = "DYSLEXIA - When you have to say a long word, do you sometimes find it difficult to get all the sounds in the right order?";
  Quiz[179].Text = "DYSLEXIA - Do you find it difficult to do sums in your head without using your fingers or paper?";
  Quiz[180].Text = "DYSLEXIA - When using the telephone, do you tend to get the numbers mixed up when you dial?";
  Quiz[181].Text = "DYSLEXIA - Do you find it difficult to say the months of the year forwards in a fluent manner?";
  Quiz[182].Text = "DYSLEXIA - Do you find it difficult to say the months of the year backwards?";
  Quiz[183].Text = "DYSLEXIA - Do you mix up dates and times and miss appointments?";
  Quiz[184].Text = "DYSLEXIA - When writing cheques, do you frequently find yourself making mistakes?";
  Quiz[185].Text = "DYSLEXIA - Do you find forms difficult and confusing?";
  Quiz[186].Text = "DYSLEXIA - Do you mix up bus numbers like 95 and 59?";
  Quiz[187].Text = "DYSLEXIA - When you were at school, did you find it hard to learn your multiplication tables?";

  Quiz[188].Text = "Dyslexia";
  Quiz[189].Text = "Dyscalculia";
  Quiz[190].Text = "OCD";
  Quiz[191].Text = "ODD";
  Quiz[192].Text = "Bipolar";
  Quiz[193].Text = "Social phobia";

#endif

#ifdef SWEDISH

  Quiz[0].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[1].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[2].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[3].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[4].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[5].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[6].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[7].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
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
  Quiz[20].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[21].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[22].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[23].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[24].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[25].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[26].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[27].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[28].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[29].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[30].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[31].Text = "Trivs du med att möta nya människor?";
  Quiz[32].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[33].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[34].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[35].Text = "Är du stolt över ditt utseende?";
  Quiz[36].Text = "Tycker du om skvaller?";
  Quiz[37].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[38].Text = "Blir du lätt distraherad?";
  Quiz[39].Text = "Har det funnits en tid då du inte var dig själv och då du var så irritabel att du skrek åt folk eller startade bråk?";
  Quiz[40].Text = "Har det funnits en tid då du inte var dig själv och då du var mer pratsam än vanligt?";
  Quiz[41].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[42].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[43].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[44].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[45].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[46].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[47].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[48].Text = "Ogillar du att behöva ta i hand?";
  Quiz[49].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[50].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[51].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[52].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[53].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[54].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[55].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[56].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[57].Text = "Ogillar du att andra tittar på när du arbetar?";
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
  Quiz[83].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[84].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[85].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[86].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[87].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[88].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[89].Text = "Trivs du i romantiska situationer?";
  Quiz[90].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[91].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[92].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[93].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[94].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[95].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[96].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[97].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[98].Text = "Gillar du att gå på tå?";
  Quiz[99].Text = "Gillar du att härma djurläten?";
  Quiz[100].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[101].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[102].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[103].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[104].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[105].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[106].Text = "Har du problem med finmotorik och/eller öga-hand koordination?";
  Quiz[107].Text = "Tyckte du praktiska ämnen som slöjd och gymnastik var svårt i skolan?";
  Quiz[108].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[109].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[110].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[111].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[112].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[113].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[114].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[115].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[116].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[117].Text = "Har du dålig tidsuppfattning?";
  Quiz[118].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[119].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[120].Text = "Har du svårt att känna igen ansikten?";
  Quiz[121].Text = "Är du bra på att hålla reda på var folk är (t.ex. i bollsporter)?";
  Quiz[122].Text = "Brukar du blanda ihop höger och vänster?";
  Quiz[123].Text = "Tycker du att folk bevakar dig?";
  Quiz[124].Text = "Misstar du ljud för röster?";
  Quiz[125].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[126].Text = "Har du haft långvariga hämndbegär?";
  Quiz[127].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[128].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[129].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[130].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[131].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[132].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[133].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[134].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[135].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[136].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[137].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[138].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[139].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[140].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[141].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[142].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[143].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[144].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[145].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[146].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[147].Text = "Förstår sig folk på dig?";
  Quiz[148].Text = "Är du bra på att arbeta i grupp?";
  Quiz[149].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[150].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[151].Text = "Har du ett bra sinne för hur mycket klockan är?";
  Quiz[152].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";

  Quiz[153].Text = "Placerar du ofta saker på fel ställe?";
  Quiz[154].Text = "Vänder du på ord i konversationer?";
  Quiz[155].Text = "Har du en tendens att stänga av när du får frågor i sociala situationer?";
  Quiz[156].Text = "Låser det sig för dig när du får frågor i sociala situationer?";
  Quiz[157].Text = "Är du självcentrerad?";
  Quiz[158].Text = "Har du omogna intressen?";
  Quiz[159].Text = "Har du problem med auktoriteter?";
  Quiz[160].Text = "Har du bra självförtroende?";
  Quiz[161].Text = "Reagerar du snabbt på förolämpningar?";
  Quiz[162].Text = "Tycker du det är naturligt att gå genom etablerade kanaler?";
  Quiz[163].Text = "Följer du förväntade procedurer?";
  Quiz[164].Text = "Föredrar du att läsa instruktioner enbart när allt annat har misslyckats?";
  Quiz[165].Text = "Har du problem att starta och / eller slutföra projekt?";
  Quiz[166].Text = "Är du dålig på att organisera ditt arbete och / eller liv?";
  Quiz[167].Text = "Tycker du om att organisera ditt arbete och / eller liv?";

  Quiz[168].Text = "DYSLEXIA - Do you find difficulty in telling left from right?";
  Quiz[169].Text = "DYSLEXIA - Is map reading or finding your way to a strange place confusing?";
  Quiz[170].Text = "DYSLEXIA - Do you dislike reading aloud?";
  Quiz[171].Text = "DYSLEXIA - Do you take longer than you should to read a page of a book?";
  Quiz[172].Text = "DYSLEXIA - Do you find it difficult to remember the sense of what you have read?";
  Quiz[173].Text = "DYSLEXIA - Do you dislike reading long books?";
  Quiz[174].Text = "DYSLEXIA - Is your spelling poor?";
  Quiz[175].Text = "DYSLEXIA - Is your writing difficult to read?";
  Quiz[176].Text = "DYSLEXIA - Do you get confused if you have to speak in public?";
  Quiz[177].Text = "DYSLEXIA - Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[178].Text = "DYSLEXIA - When you have to say a long word, do you sometimes find it difficult to get all the sounds in the right order?";
  Quiz[179].Text = "DYSLEXIA - Do you find it difficult to do sums in your head without using your fingers or paper?";
  Quiz[180].Text = "DYSLEXIA - When using the telephone, do you tend to get the numbers mixed up when you dial?";
  Quiz[181].Text = "DYSLEXIA - Do you find it difficult to say the months of the year forwards in a fluent manner?";
  Quiz[182].Text = "DYSLEXIA - Do you find it difficult to say the months of the year backwards?";
  Quiz[183].Text = "DYSLEXIA - Do you mix up dates and times and miss appointments?";
  Quiz[184].Text = "DYSLEXIA - When writing cheques, do you frequently find yourself making mistakes?";
  Quiz[185].Text = "DYSLEXIA - Do you find forms difficult and confusing?";
  Quiz[186].Text = "DYSLEXIA - Do you mix up bus numbers like 95 and 59?";
  Quiz[187].Text = "DYSLEXIA - When you were at school, did you find it hard to learn your multiplication tables?";

  Quiz[188].Text = "Dyslexi";
  Quiz[189].Text = "Dyskaluli";
  Quiz[190].Text = "OCD";
  Quiz[191].Text = "ODD";
  Quiz[192].Text = "Bipolär";
  Quiz[193].Text = "Social fobi";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS10::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::InitReferers()
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

/*##################  TQuizS10::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::LoadReferers()
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
#   Name       : TQuizS10::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::LoadPopulations()
{
	TQuizRow Row;
	int i;
	int id;
	TReferer *ref;
	char DxArr[DX_COUNT];
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

		Row.Quiz[188] = Row.Dyslexia + 1;
		Row.Quiz[189] = Row.Dyscalculia + 1;
		Row.Quiz[190] = Row.OCD + 1;
		Row.Quiz[191] = Row.ODD + 1;
		Row.Quiz[192] = Row.Bipolar + 1;
		Row.Quiz[193] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 188)
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

		for (i = 0; i < DX_COUNT; i++)
			DxArr[i] = DX_STATE_UNKNOWN;

		if (Row.Autism == 2)
			DxArr[DX_AUTISM] = DX_STATE_YES;

		if (Row.Autism == 1)
			DxArr[DX_AUTISM] = DX_STATE_SELF;

		if (Row.Autism == 0)
			DxArr[DX_AUTISM] = DX_STATE_NO;

		if (Row.Aspie == 2)
			DxArr[DX_AS] = DX_STATE_YES;

		if (Row.Aspie == 1)
			DxArr[DX_AS] = DX_STATE_SELF;

		if (Row.Aspie == 0)
			DxArr[DX_AS] = DX_STATE_NO;

		if (Row.ADHD == 2)
			DxArr[DX_ADD] = DX_STATE_YES;

		if (Row.ADHD == 1)
			DxArr[DX_ADD] = DX_STATE_SELF;

		if (Row.ADHD == 0)
			DxArr[DX_ADD] = DX_STATE_NO;

		if (Row.TS == 2)
			DxArr[DX_TS] = DX_STATE_YES;

		if (Row.TS == 1)
			DxArr[DX_TS] = DX_STATE_SELF;

		if (Row.TS == 0)
			DxArr[DX_TS] = DX_STATE_NO;

		if (Row.Dyslexia == 2)
			DxArr[DX_DYSLEXIA] = DX_STATE_YES;

		if (Row.Dyslexia == 1)
			DxArr[DX_DYSLEXIA] = DX_STATE_SELF;

		if (Row.Dyslexia == 0)
			DxArr[DX_DYSLEXIA] = DX_STATE_NO;

		if (Row.Dyscalculia == 2)
			DxArr[DX_DYSCALCULIA] = DX_STATE_YES;

		if (Row.Dyscalculia == 1)
			DxArr[DX_DYSCALCULIA] = DX_STATE_SELF;

		if (Row.Dyscalculia == 0)
			DxArr[DX_DYSCALCULIA] = DX_STATE_NO;

		if (Row.OCD == 2)
			DxArr[DX_OCD] = DX_STATE_YES;

		if (Row.OCD == 1)
			DxArr[DX_OCD] = DX_STATE_SELF;

		if (Row.OCD == 0)
			DxArr[DX_OCD] = DX_STATE_NO;

		if (Row.ODD == 2)
			DxArr[DX_ODD] = DX_STATE_YES;

		if (Row.ODD == 1)
			DxArr[DX_ODD] = DX_STATE_SELF;

		if (Row.ODD == 0)
			DxArr[DX_ODD] = DX_STATE_NO;

		if (Row.Bipolar == 2)
			DxArr[DX_BIPOLAR] = DX_STATE_YES;

		if (Row.Bipolar == 1)
			DxArr[DX_BIPOLAR] = DX_STATE_SELF;

		if (Row.Bipolar == 0)
			DxArr[DX_BIPOLAR] = DX_STATE_NO;

		if (Row.Schizophrenia == 2)
			DxArr[DX_SCHIZOPHRENIA] = DX_STATE_YES;

		if (Row.Schizophrenia == 1)
			DxArr[DX_SCHIZOPHRENIA] = DX_STATE_SELF;

		if (Row.Schizophrenia == 0)
			DxArr[DX_SCHIZOPHRENIA] = DX_STATE_NO;

		if (Row.Social == 2)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_YES;

		if (Row.Social == 1)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_SELF;

		if (Row.Social == 0)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_NO;

		All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

				AsMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.ADHD >= 1)
		{
			Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.TS >= 1)
			Ts.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dyslexia >= 1)
			Dyslexia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dyscalculia >= 1)
			Dyscalculia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.OCD >= 1)
			OCD.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.ODD >= 1)
			ODD.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Bipolar >= 1)
			Bipolar.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Schizophrenia >= 1)
			Schizophrenia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Social >= 1)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

	}
}

/*##########################################################################
#
#   Name       : TQuizS10::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::SetupControlGroups()
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
#   Name       : TQuizS10::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9)
{
    DefineCross(QuizS9, 0, 0);
    DefineCross(QuizS9, 1, 1);
    DefineCross(QuizS9, 2, 2);
	 DefineCross(QuizS9, 3, 3);
    DefineCross(QuizS9, 4, 4);
    DefineCross(QuizS9, 5, 5);
    DefineCross(QuizS9, 6, 7);
    DefineCross(QuizS9, 7, 6);
    DefineCross(QuizS9, 8, 8);
	 DefineCross(QuizS9, 9, 9);
    DefineCross(QuizS9, 10, 10);
    DefineCross(QuizS9, 11, 11);
	DefineCross(QuizS9, 12, 12);
    DefineCross(QuizS9, 13, 13);
    DefineCross(QuizS9, 14, 14);
    DefineCross(QuizS9, 15, 15);
	 DefineCross(QuizS9, 16, 16);
    DefineCross(QuizS9, 17, 17);
    DefineCross(QuizS9, 18, 18);
    DefineCross(QuizS9, 19, 19);
    DefineCross(QuizS9, 20, 21);
	DefineCross(QuizS9, 21, 22);
    DefineCross(QuizS9, 22, 24);
    DefineCross(QuizS9, 23, 25);
    DefineCross(QuizS9, 24, 26);
    DefineCross(QuizS9, 25, 27);
    DefineCross(QuizS9, 26, 28);
    DefineCross(QuizS9, 27, 29);
    DefineCross(QuizS9, 28, 30);
    DefineCross(QuizS9, 29, 31);
    DefineCross(QuizS9, 30, 32);
    DefineCross(QuizS9, 31, 55);
    DefineCross(QuizS9, 32, 34);
	 DefineCross(QuizS9, 33, 35);
    DefineCross(QuizS9, 34, 37);
    DefineCross(QuizS9, 35, 39);
    DefineCross(QuizS9, 36, 38);
    DefineCross(QuizS9, 37, 137);
    DefineCross(QuizS9, 38, 20);
	DefineCross(QuizS9, 39, 153);
    DefineCross(QuizS9, 40, 154);
    DefineCross(QuizS9, 41, 23);
    DefineCross(QuizS9, 42, 46);
    DefineCross(QuizS9, 43, 40);
    DefineCross(QuizS9, 44, 41);
    DefineCross(QuizS9, 45, 47);
	 DefineCross(QuizS9, 46, 42);
    DefineCross(QuizS9, 47, 51);
	DefineCross(QuizS9, 48, 48);
    DefineCross(QuizS9, 49, 49);
    DefineCross(QuizS9, 50, 52);
    DefineCross(QuizS9, 51, 50);
    DefineCross(QuizS9, 52, 54);
    DefineCross(QuizS9, 53, 56);
    DefineCross(QuizS9, 54, 43);
    DefineCross(QuizS9, 55, 57);
    DefineCross(QuizS9, 56, 44);
    DefineCross(QuizS9, 57, 45);
    DefineCross(QuizS9, 58, 58);
    DefineCross(QuizS9, 59, 59);
    DefineCross(QuizS9, 60, 60);
    DefineCross(QuizS9, 61, 61);
    DefineCross(QuizS9, 62, 62);
	 DefineCross(QuizS9, 63, 63);
    DefineCross(QuizS9, 64, 64);
    DefineCross(QuizS9, 65, 65);
	DefineCross(QuizS9, 66, 66);
    DefineCross(QuizS9, 67, 67);
    DefineCross(QuizS9, 68, 68);
	 DefineCross(QuizS9, 69, 69);
    DefineCross(QuizS9, 70, 70);
    DefineCross(QuizS9, 71, 71);
    DefineCross(QuizS9, 72, 72);
    DefineCross(QuizS9, 73, 73);
    DefineCross(QuizS9, 74, 74);
	DefineCross(QuizS9, 75, 75);
	 DefineCross(QuizS9, 76, 76);
    DefineCross(QuizS9, 77, 77);
    DefineCross(QuizS9, 78, 78);
    DefineCross(QuizS9, 79, 79);
    DefineCross(QuizS9, 80, 80);
    DefineCross(QuizS9, 81, 81);
    DefineCross(QuizS9, 82, 82);
    DefineCross(QuizS9, 83, 85);
    DefineCross(QuizS9, 84, 83);
    DefineCross(QuizS9, 85, 84);
    DefineCross(QuizS9, 86, 86);
    DefineCross(QuizS9, 87, 87);
    DefineCross(QuizS9, 88, 88);
    DefineCross(QuizS9, 89, 53);
    DefineCross(QuizS9, 90, 33);
    DefineCross(QuizS9, 91, 89);
    DefineCross(QuizS9, 92, 36);
	DefineCross(QuizS9, 93, 90);
    DefineCross(QuizS9, 94, 91);
    DefineCross(QuizS9, 95, 92);
    DefineCross(QuizS9, 96, 93);
    DefineCross(QuizS9, 97, 94);
    DefineCross(QuizS9, 98, 95);
	 DefineCross(QuizS9, 99, 96);
    DefineCross(QuizS9, 100, 97);
    DefineCross(QuizS9, 101, 98);
	DefineCross(QuizS9, 102, 99);
    DefineCross(QuizS9, 103, 100);
    DefineCross(QuizS9, 104, 101);
    DefineCross(QuizS9, 105, 102);
	 DefineCross(QuizS9, 106, 103);
    DefineCross(QuizS9, 107, 104);
    DefineCross(QuizS9, 108, 105);
    DefineCross(QuizS9, 109, 106);
    DefineCross(QuizS9, 110, 107);
    DefineCross(QuizS9, 111, 108);
    DefineCross(QuizS9, 112, 109);
    DefineCross(QuizS9, 113, 110);
    DefineCross(QuizS9, 114, 111);
    DefineCross(QuizS9, 115, 112);
    DefineCross(QuizS9, 116, 113);
    DefineCross(QuizS9, 117, 114);
    DefineCross(QuizS9, 118, 115);
    DefineCross(QuizS9, 119, 116);
	DefineCross(QuizS9, 120, 117);
    DefineCross(QuizS9, 121, 118);
    DefineCross(QuizS9, 122, 119);
	 DefineCross(QuizS9, 123, 120);
    DefineCross(QuizS9, 124, 121);
    DefineCross(QuizS9, 125, 122);
    DefineCross(QuizS9, 126, 123);
    DefineCross(QuizS9, 127, 124);
    DefineCross(QuizS9, 128, 125);
	DefineCross(QuizS9, 129, 126);
    DefineCross(QuizS9, 130, 127);
    DefineCross(QuizS9, 131, 128);
    DefineCross(QuizS9, 132, 129);
    DefineCross(QuizS9, 133, 130);
    DefineCross(QuizS9, 134, 131);
    DefineCross(QuizS9, 135, 132);
	 DefineCross(QuizS9, 136, 133);
    DefineCross(QuizS9, 137, 134);
    DefineCross(QuizS9, 138, 135);
    DefineCross(QuizS9, 139, 136);
    DefineCross(QuizS9, 140, 138);
    DefineCross(QuizS9, 141, 139);
    DefineCross(QuizS9, 142, 140);
    DefineCross(QuizS9, 143, 141);
    DefineCross(QuizS9, 144, 143);
    DefineCross(QuizS9, 145, 142);
    DefineCross(QuizS9, 146, 145);
	DefineCross(QuizS9, 147, 146);
	DefineCross(QuizS9, 148, 147);
	DefineCross(QuizS9, 149, 148);
	DefineCross(QuizS9, 150, 149);
	DefineCross(QuizS9, 151, 150);
	DefineCross(QuizS9, 152, 151);

	DefineCross(QuizII, 153, 90);

	DefineGlobalId(154, 1041);
	DefineGlobalId(155, 1042);
	DefineGlobalId(156, 1043);
	DefineGlobalId(157, 1044);
	DefineGlobalId(158, 1045);
	DefineGlobalId(159, 1046);
	DefineGlobalId(160, 1047);
	DefineGlobalId(161, 1048);
	DefineGlobalId(162, 1049);
	DefineGlobalId(163, 1050);
	DefineGlobalId(164, 1051);
	DefineGlobalId(165, 1052);
	DefineGlobalId(166, 1053);
	DefineGlobalId(167, 1054);

	DefineGlobalId(168, 1055);
	DefineGlobalId(169, 1056);
	DefineGlobalId(170, 1057);
	DefineGlobalId(171, 1058);
	DefineGlobalId(172, 1059);
	DefineGlobalId(173, 1060);
	DefineGlobalId(174, 1061);
	DefineGlobalId(175, 1062);
	DefineGlobalId(176, 1063);
	DefineGlobalId(177, 1064);
	DefineGlobalId(178, 1065);
	DefineGlobalId(179, 1066);
	DefineGlobalId(180, 1067);
	DefineGlobalId(181, 1068);
	DefineGlobalId(182, 1069);
	DefineGlobalId(183, 1070);
	DefineGlobalId(184, 1071);
	DefineGlobalId(185, 1072);
	DefineGlobalId(186, 1073);
	DefineGlobalId(187, 1074);

	DefineCross(QuizS9, 188, 236);
	DefineCross(QuizS9, 189, 237);
	DefineCross(QuizS9, 190, 238);
	DefineCross(QuizS9, 191, 239);
	DefineCross(QuizS9, 192, 240);
	DefineCross(QuizS9, 193, 241);

}

/*##########################################################################
#
#   Name       : TQuizS10::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS10::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;
	char DxArr[DX_COUNT];

	for (i = 0; i < DX_COUNT; i++)
		DxArr[DX_COUNT] = DX_STATE_UNKNOWN;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop->Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
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

/*##################  TQuizS10::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS10::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::ExportExcelAspie(const char *filename)
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
		if (Row.DysResult)
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

/*##################  TQuizS10::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS10::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::ImportMvsp(const char *filename, int PcaType)
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

/*##################  TQuizS10::WriteDyslexia ##########################
*   Purpose....: Write dyslexia test report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::WriteDyslexia(const char *filename)
{
	int Count;
	long double AsSum;
	long double NtSum;
	long double DiffSum;
	long double DysSum;
	long double AsMean;
	long double NtMean;
	long double DiffMean;
	long double DysMean;
	long double AsSd;
	long double NtSd;
	long double DiffSd;
	long double DysSd;
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
	DysSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.DysResult)
        {
			Count++;
			AsSum += Row.AsResult;
			NtSum += Row.NtResult;
			DiffSum += Row.AsResult - Row.NtResult;
			DysSum += Row.DysResult;
	    }
	}

	AsMean = AsSum / Count;
	NtMean = NtSum / Count;
	DiffMean = DiffSum / Count;
	DysMean = DysSum / Count;

	AsSum = 0;
	NtSum = 0;
	DysSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.DysResult)
        {
            val = (long double)Row.AsResult - AsMean;
   			AsSum += val * val;
   			
            val = (long double)Row.NtResult - NtMean;
			NtSum += val * val;
			
            val = (long double)(Row.AsResult - Row.NtResult) - DiffMean;
			DiffSum += val * val;

            val = (long double)Row.DysResult - DysMean;
			DysSum += val * val;
	    }
	}

	AsSd = sqrtl(AsSum / (Count - 1));
	NtSd = sqrtl(NtSum / (Count - 1));
	DiffSd = sqrtl(DiffSum / (Count - 1));
	DysSd = sqrtl(DysSum / (Count - 1));

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.DysResult)
		  {
            zx = ((long double)Row.DysResult - DysMean) / DysSd;

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
	printf("Mean Dyslexia score: %5.1Lf, SD: %5.1Lf\r\n", DysMean, DysSd);

	printf("Dyslexia - Aspie score correlation: %5.2Lf\r\n", AsCorr);
	printf("Dyslexia - NT score correlation: %5.2Lf\r\n", NtCorr);
	printf("Dyslexia - score diff correlation: %5.2Lf\r\n", DiffCorr);
}


/*##################  TQuizS10::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS10::WriteRetest(const char *filename)
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
	long double QMean[168];
	long double AsSd;
	long double NtSd;
	long double QSd[168];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[168];
	int QCount[168];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[168][20];
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

	 for (q = 0; q < 168; q++)
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

						  for (q = 0; q < 168; q++)
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

								  for (q = 0; q < 168; q++)
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

					for (q = 0; q < 168; q++)
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

					for (q = 0; q < 168; q++)
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

	for (q = 0; q < 168; q++)
	{
		 sprintf(str, "%d. ", q + 1);
		 file.Write(str);

		file.Write(Quiz[q].Text);

		 sd = QTot[q] / QCount[q];

		  sprintf(str, " <b>%3.2Lf</b><br>", sd);
		file.Write(str);
	 }
}

