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
# quizs6.cpp
# Quiz stable version 6 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs6.h"
#include "file.h"
#include "quizdbs6.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS6::TQuizS6
#
#   Purpose....: Constructor for TQuizS6
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS6::TQuizS6(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5)
  : TQuiz(185),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS6::~TQuizS6
#
#   Purpose....: Destructor for TQuizS6
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS6::~TQuizS6()
{
}

/*##################  TQuizS6::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS6::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS6::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS6::GetCatCount(int Question)
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
int TQuizS6::GetQuizN()
{
	return 179;
}

/*##########################################################################
#
#   Name       : TQuizS6::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::WriteName(TFile &File)
{
	 File.Write("S6");
}

/*##########################################################################
#
#   Name       : TQuizS6::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::WriteLongName(TFile &File)
{
	 File.Write("stable version 6");
}

/*##################  TQuizS6::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS6::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS6::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::SetupTexts()
{
  Quiz[39].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[59].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[62].Reverse = TRUE;
  Quiz[64].Reverse = TRUE;
  Quiz[66].Reverse = TRUE;
  Quiz[68].Reverse = TRUE;
  Quiz[69].Reverse = TRUE;
  Quiz[70].Reverse = TRUE;
  Quiz[99].Reverse = TRUE;
  Quiz[100].Reverse = TRUE;
  Quiz[102].Reverse = TRUE;
  Quiz[103].Reverse = TRUE;
  Quiz[104].Reverse = TRUE;
  Quiz[105].Reverse = TRUE;
  Quiz[143].Reverse = TRUE;
  Quiz[144].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;
  Quiz[150].Reverse = TRUE;
  Quiz[151].Reverse = TRUE;
  Quiz[152].Reverse = TRUE;
  Quiz[153].Reverse = TRUE;
  Quiz[154].Reverse = TRUE;
  Quiz[155].Reverse = TRUE;
  Quiz[156].Reverse = TRUE;
  Quiz[157].Reverse = TRUE;
  Quiz[158].Reverse = TRUE;
  Quiz[159].Reverse = TRUE;
  Quiz[160].Reverse = TRUE;
  Quiz[161].Reverse = TRUE;
  Quiz[162].Reverse = TRUE;
  Quiz[163].Reverse = TRUE;
  Quiz[164].Reverse = TRUE;
  Quiz[165].Reverse = TRUE;
  Quiz[166].Reverse = TRUE;
  Quiz[167].Reverse = TRUE;
  Quiz[168].Reverse = TRUE;
  Quiz[169].Reverse = TRUE;
  Quiz[170].Reverse = TRUE;
  Quiz[171].Reverse = TRUE;
  Quiz[172].Reverse = TRUE;
  Quiz[173].Reverse = TRUE;
  Quiz[174].Reverse = TRUE;
  Quiz[175].Reverse = TRUE;
  Quiz[177].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[1].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[2].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[3].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[4].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[5].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[6].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[7].MyGroup = GROUP_NT_HUNTING;
  Quiz[8].MyGroup = GROUP_NT_SENSORY;
  Quiz[9].MyGroup = GROUP_NT_SENSORY;
  Quiz[10].MyGroup = GROUP_NT_SENSORY;
  Quiz[11].MyGroup = GROUP_NT_SENSORY;
  Quiz[12].MyGroup = GROUP_NT_SENSORY;
  Quiz[13].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[14].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[15].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[16].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[17].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[18].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[19].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[20].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[24].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[25].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[26].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[27].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[28].MyGroup = GROUP_NT_NVC;
  Quiz[29].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[30].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[31].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[35].MyGroup = GROUP_NT_TALENT;
  Quiz[36].MyGroup = GROUP_NT_TALENT;
  Quiz[37].MyGroup = GROUP_NT_TALENT;
  Quiz[38].MyGroup = GROUP_NT_TALENT;
  Quiz[39].MyGroup = GROUP_NT_TALENT;
  Quiz[40].MyGroup = GROUP_NT_SENSORY;
  Quiz[41].MyGroup = GROUP_NT_TALENT;
  Quiz[42].MyGroup = GROUP_ACTIVITY;
  Quiz[43].MyGroup = GROUP_NT_TALENT;
  Quiz[44].MyGroup = GROUP_NT_HUNTING;
  Quiz[45].MyGroup = GROUP_ENVIRONMENT;
  Quiz[46].MyGroup = GROUP_NT_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_SOCIAL;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_MIXED;
  Quiz[53].MyGroup = GROUP_NT_SOCIAL;
  Quiz[54].MyGroup = GROUP_NT_SOCIAL;
  Quiz[55].MyGroup = GROUP_NT_NVC;
  Quiz[56].MyGroup = GROUP_NT_SOCIAL;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_NT_NVC;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
  Quiz[62].MyGroup = GROUP_NT_OBSESSION;
  Quiz[63].MyGroup = GROUP_NT_OBSESSION;
  Quiz[64].MyGroup = GROUP_NT_NVC;
  Quiz[65].MyGroup = GROUP_NT_SOCIAL;
  Quiz[66].MyGroup = GROUP_NT_SOCIAL;
  Quiz[67].MyGroup = GROUP_NT_SOCIAL;
  Quiz[68].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[69].MyGroup = GROUP_NT_SOCIAL;
  Quiz[70].MyGroup = GROUP_NT_SOCIAL;
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
  Quiz[89].MyGroup = GROUP_ASPIE_NVC;
  Quiz[90].MyGroup = GROUP_ASPIE_NVC;
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
  Quiz[103].MyGroup = GROUP_NT_NVC;
  Quiz[104].MyGroup = GROUP_NT_NVC;
  Quiz[105].MyGroup = GROUP_NT_TALENT;
  Quiz[106].MyGroup = GROUP_NT_NVC;
  Quiz[107].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[108].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[109].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[110].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[111].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[112].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[113].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[114].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[115].MyGroup = GROUP_PARANOID;
  Quiz[116].MyGroup = GROUP_PARANOID;
  Quiz[117].MyGroup = GROUP_PARANOID;
  Quiz[118].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[119].MyGroup = GROUP_ENVIRONMENT;
  Quiz[120].MyGroup = GROUP_ENVIRONMENT;
  Quiz[121].MyGroup = GROUP_ENVIRONMENT;
  Quiz[122].MyGroup = GROUP_ENVIRONMENT;
  Quiz[123].MyGroup = GROUP_ENVIRONMENT;
  Quiz[124].MyGroup = GROUP_ENVIRONMENT;
  Quiz[125].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[126].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[127].MyGroup = GROUP_NT_NVC;
  Quiz[128].MyGroup = GROUP_NT_NVC;
  Quiz[129].MyGroup = GROUP_MIXED;
  Quiz[130].MyGroup = GROUP_ACTIVITY;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_MIXED;
  Quiz[133].MyGroup = GROUP_ASPIE_NVC;
  Quiz[134].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[135].MyGroup = GROUP_MIXED;
  Quiz[136].MyGroup = GROUP_NT_SENSORY;
  Quiz[137].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[138].MyGroup = GROUP_NT_SOCIAL;
  Quiz[139].MyGroup = GROUP_ASPIE_NVC;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_ASPIE_NVC;
  Quiz[143].MyGroup = GROUP_NT_TALENT;
  Quiz[144].MyGroup = GROUP_NT_NVC;
  Quiz[145].MyGroup = GROUP_NT_SOCIAL;
  Quiz[146].MyGroup = GROUP_ENVIRONMENT;
  Quiz[147].MyGroup = GROUP_NT_SENSORY;
  Quiz[148].MyGroup = GROUP_NT_OBSESSION;
  Quiz[149].MyGroup = GROUP_NT_SOCIAL;
  Quiz[150].MyGroup = GROUP_NT_OBSESSION;
  Quiz[151].MyGroup = GROUP_NT_OBSESSION;
  Quiz[152].MyGroup = GROUP_NT_OBSESSION;
  Quiz[153].MyGroup = GROUP_NT_OBSESSION;
  Quiz[154].MyGroup = GROUP_NT_OBSESSION;
  Quiz[155].MyGroup = GROUP_NT_OBSESSION;
  Quiz[156].MyGroup = GROUP_NT_OBSESSION;
  Quiz[157].MyGroup = GROUP_NT_SOCIAL;
  Quiz[158].MyGroup = GROUP_NT_OBSESSION;
  Quiz[159].MyGroup = GROUP_NT_OBSESSION;
  Quiz[160].MyGroup = GROUP_NT_OBSESSION;
  Quiz[161].MyGroup = GROUP_NT_OBSESSION;
  Quiz[162].MyGroup = GROUP_NT_OBSESSION;
  Quiz[163].MyGroup = GROUP_NT_OBSESSION;
  Quiz[164].MyGroup = GROUP_NT_OBSESSION;
  Quiz[165].MyGroup = GROUP_NT_OBSESSION;
  Quiz[166].MyGroup = GROUP_NT_OBSESSION;
  Quiz[167].MyGroup = GROUP_NT_OBSESSION;
  Quiz[168].MyGroup = GROUP_NT_OBSESSION;
  Quiz[169].MyGroup = GROUP_NT_OBSESSION;
  Quiz[170].MyGroup = GROUP_NT_SOCIAL;
  Quiz[171].MyGroup = GROUP_NT_OBSESSION;
  Quiz[172].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[173].MyGroup = GROUP_NT_SENSORY;
  Quiz[174].MyGroup = GROUP_NT_SENSORY;
  Quiz[175].MyGroup = GROUP_NT_SENSORY;
  Quiz[176].MyGroup = GROUP_MIXED;
  Quiz[177].MyGroup = GROUP_NT_SENSORY;
  Quiz[178].MyGroup = GROUP_ENVIRONMENT;

  Quiz[179].MyGroup = GROUP_NT_HUNTING;
  Quiz[180].MyGroup = GROUP_NT_HUNTING;
  Quiz[181].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[182].MyGroup = GROUP_MIXED;
  Quiz[183].MyGroup = GROUP_ACTIVITY;
  Quiz[184].MyGroup = GROUP_NT_SOCIAL;

#ifdef ENGLISH
  Quiz[0].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[1].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[2].Text = "Do you enjoy sneaking through the woods?";
  Quiz[3].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[4].Text = "Do you enjoy walking on your toes?";
  Quiz[5].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[6].Text = "Have you been fascinated about making traps?";
  Quiz[7].Text = "Do you drop things when your attention is on other things?";
  Quiz[8].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[9].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[10].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[11].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[12].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[13].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[14].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[15].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[16].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[17].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[18].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[19].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[20].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[21].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[22].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[23].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[24].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[25].Text = "Do people see you as eccentric?";
  Quiz[26].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[27].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[28].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[29].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[30].Text = "Do you have a hyperactive mind?";
  Quiz[31].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[32].Text = "Do you notice patterns in things all the time?";
  Quiz[33].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[34].Text = "Do you tend to do everything worth doing, more perfect than really needed?";
  Quiz[35].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[36].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[37].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[38].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[39].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[40].Text = "Do you have poor concept of time?";
  Quiz[41].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[42].Text = "Are you easily distracted?";
  Quiz[43].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[44].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[45].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[46].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[47].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[48].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[49].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[50].Text = "Have you felt different from others for most of your life?";
  Quiz[51].Text = "Do people think you are aloof and distant?";
  Quiz[52].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[53].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[54].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[55].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[56].Text = "Do you prefer to keep to yourself?";
  Quiz[57].Text = "Do you dislike shaking hands?";
  Quiz[58].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[59].Text = "Do you instinctively know how to behave when somebody shows interest in you as a potential partner?";
  Quiz[60].Text = "Are you good at social chitchat?";
  Quiz[61].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[62].Text = "Are your views typical of your peer group?";
  Quiz[63].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[64].Text = "Do you find it easy to describe your feelings?";
  Quiz[65].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[66].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[67].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[68].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[69].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[70].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[71].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[72].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[73].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[74].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[75].Text = "Do you often don't know where to put your arms?";
  Quiz[76].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[77].Text = "Have you been accused of staring?";
  Quiz[78].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[79].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[80].Text = "Do you fiddle with things?";
  Quiz[81].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[82].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[83].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[84].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[85].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[86].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[87].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[88].Text = "Do you talk to yourself?";
  Quiz[89].Text = "Do you stutter when stressed?";
  Quiz[90].Text = "Do you clench your fists when angry?";
  Quiz[91].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[92].Text = "Do others often misunderstand you?";
  Quiz[93].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[94].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[95].Text = "Are you often surprised what people's motives are ?";
  Quiz[96].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[97].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[98].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[99].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[100].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[101].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[102].Text = "Do you know when you are expected to offer an apology?";
  Quiz[103].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[104].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[105].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[106].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[107].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[108].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[109].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[110].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[111].Text = "Do you have certain routines which you need to follow?";
  Quiz[112].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[113].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[114].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[115].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[116].Text = "Do you feel that people are watching you?";
  Quiz[117].Text = "Do you mistake noises for voices?";
  Quiz[118].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[119].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[120].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[121].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[122].Text = "Are you sometimes afraid in safe situations?";
  Quiz[123].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[124].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[125].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[126].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[127].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[128].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[129].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[130].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[131].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[132].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[133].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[134].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[135].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[136].Text = "Do you find it hard to tell the age of people?";
  Quiz[137].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[138].Text = "Do you dislike working while being observed?";
  Quiz[139].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[140].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[141].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[142].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[143].Text = "Can you easily remember verbal instructions?";
  Quiz[144].Text = "Do people understand you?";
  Quiz[145].Text = "Are you good at teamwork?";
  Quiz[146].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[147].Text = "Do you find it easy to estimate the age of people?";
  Quiz[148].Text = "Are you energised by being in the company of others?";
  Quiz[149].Text = "Are you good at small talk?";
  Quiz[150].Text = "Do you enjoy meeting new people every day?";
  Quiz[151].Text = "Are you the life of a party?";
  Quiz[152].Text = "Is a large social network important to you?";
  Quiz[153].Text = "Do you enjoy hosting or arranging events?";
  Quiz[154].Text = "Do you have an interest for the current fashions?";
  Quiz[155].Text = "Do you enjoy gossip?";
  Quiz[156].Text = "Is creating a social identity important for you?";
  Quiz[157].Text = "Do you enjoy snuggling with people you like?";
  Quiz[158].Text = "Is climing the social hierarchy important to you?";
  Quiz[159].Text = "Do you take pride in your appearance?";
  Quiz[160].Text = "Do you talk to put others at ease even when you really have nothing to say?";
  Quiz[161].Text = "Do you like to be in charge of other people?";
  Quiz[162].Text = "Do you prefer romance/drama films to science fiction/documentary films?";
  Quiz[163].Text = "Do you cheerfully redecorate or try wearing a different style of clothing?";
  Quiz[164].Text = "Do you enjoy wearing jewelry?";
  Quiz[165].Text = "Is your style and image important to you?";
  Quiz[166].Text = "Is other people's image of you important to you?";
  Quiz[167].Text = "Do you enjoy the status of a new car/new stereo/new TV?";
  Quiz[168].Text = "Is making a career important to you?";
  Quiz[169].Text = "Do you enjoy make-up?";
  Quiz[170].Text = "Do you enjoy when people drop by to visit you uninvited?";
  Quiz[171].Text = "Do you spend more time getting to know others than yourself?";
  Quiz[172].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
  Quiz[173].Text = "Are you good at judging distances?";
  Quiz[174].Text = "Are you good at judging speed?";
  Quiz[175].Text = "Are you good at judging acceleration?";
  Quiz[176].Text = "Can you easily spot small differences between pictures?";
  Quiz[177].Text = "Are you good at predicting motion?";
  Quiz[178].Text = "Are you dissatisfied with how some body-part looks like in yourself?";

  Quiz[179].Text = "Dyslexia";
  Quiz[180].Text = "Dyscalculia";
  Quiz[181].Text = "OCD";
  Quiz[182].Text = "ODD";
  Quiz[183].Text = "Bipolar";
  Quiz[184].Text = "Social phobia";

#endif

#ifdef SWEDISH
  Quiz[0].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[1].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[2].Text = "Gillar du att smyga omkring i skogen?";
  Quiz[3].Text = "Gillar du att härma djurläten?";
  Quiz[4].Text = "Gillar du att gå på tå?";
  Quiz[5].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[6].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[7].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[8].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[9].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[10].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[11].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[12].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[13].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[14].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[15].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[16].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[17].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[18].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[19].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[20].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[21].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[22].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[23].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[24].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[25].Text = "Tycker folk att du är excentrisk?";
  Quiz[26].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[27].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[28].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[29].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[30].Text = "Är du mentalt hyperaktiv?";
  Quiz[31].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[32].Text = "Ser du mönster i saker hela tiden?";
  Quiz[33].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[34].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[35].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[36].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[37].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[38].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[39].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[40].Text = "Har du dålig tidsuppfattning?";
  Quiz[41].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[42].Text = "Blir du lätt distraherad?";
  Quiz[43].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[44].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[45].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[46].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[47].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[48].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[49].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[50].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[51].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[52].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[53].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[54].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[55].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[56].Text = "Föredrar du att vara för dig själv?";
  Quiz[57].Text = "Ogillar du att behöva ta i hand?";
  Quiz[58].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[59].Text = "Vet du instinktivt hur du ska uppföra dig om någon visar intresse för dig som möjlig partner?";
  Quiz[60].Text = "Är du bra på kallprat?";
  Quiz[61].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[62].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[63].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[64].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[65].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[66].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[67].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[68].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[69].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[70].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[71].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[72].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[73].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[74].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[75].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[76].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[77].Text = "Har du blivit anklagad för att stirra?";
  Quiz[78].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[79].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[80].Text = "Brukar du fingra på saker?";
  Quiz[81].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[82].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[83].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[84].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[85].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[86].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[87].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[88].Text = "Brukar du prata med dig själv?";
  Quiz[89].Text = "Stammar du när du blir stressad?";
  Quiz[90].Text = "Knyter du nävarna när du är arg?";
  Quiz[91].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[92].Text = "Blir du ofta missförstådd av andra?";
  Quiz[93].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[94].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[95].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[96].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[97].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[98].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[99].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[100].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[101].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[102].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[103].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[104].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[105].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[106].Text = "Har du svårt att känna igen ansikten?";
  Quiz[107].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[108].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[109].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[110].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[111].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[112].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[113].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[114].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[115].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[116].Text = "Tycker du att folk bevakar dig?";
  Quiz[117].Text = "Misstar du ljud för röster?";
  Quiz[118].Text = "Har du haft långvariga hämndbegär?";
  Quiz[119].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[120].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[121].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[122].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[123].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[124].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[125].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[126].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[127].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[128].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[129].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[130].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[131].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[132].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[133].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[134].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[135].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[136].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[137].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[138].Text = "Ogillar du att andra tittar på när du arbetar?";
  Quiz[139].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[140].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[141].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[142].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[143].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[144].Text = "Förstår sig folk på dig?";
  Quiz[145].Text = "Är du bra på att arbeta i grupp?";
  Quiz[146].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[147].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[148].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[149].Text = "Är du bra på kallprat?";
  Quiz[150].Text = "Tycker du om att möta nya människor varje dag?";
  Quiz[151].Text = "Är du aktiv på fester?";
  Quiz[152].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[153].Text = "Tycker du om att anordna eller vara värd för aktiviter?";
  Quiz[154].Text = "Är du intressad av nuvarande mode?";
  Quiz[155].Text = "Tycker du om skvaller?";
  Quiz[156].Text = "Är det viktigt för dig att skapa en social identitet?";
  Quiz[157].Text = "Gillar du att mysa ihop med personer du tycker om?";
  Quiz[158].Text = "Är det viktigt för dig att klättra i den sociala hierarkin?";
  Quiz[159].Text = "Är du stolt över ditt utseende?";
  Quiz[160].Text = "Pratar du för att andra ska känna sig väl till mods även om du inte har något att säga?";
  Quiz[161].Text = "Gillar du att leda andra människor?";
  Quiz[162].Text = "Föredrar du filmer om romantik / drama före filmer om vetenskap/dokumentärer?";
  Quiz[163].Text = "Möblerar du gärna om eller försöker byta stil på kläder?";
  Quiz[164].Text = "Gillar du att bära smycken?";
  Quiz[165].Text = "Är din stil och image viktig för dig?";
  Quiz[166].Text = "Är andra människors syn på dig viktig för dig?";
  Quiz[167].Text = "Njuter du av den status som en ny bil/stereo/TV ger?";
  Quiz[168].Text = "Är det viktigt för dig att göra karriär?";
  Quiz[169].Text = "Gillar du att sminka dig?";
  Quiz[170].Text = "Gillar du när folk kommer på besök oanmälda?";
  Quiz[171].Text = "Använder du mer tid för att lära känna andra än dig själv?";
  Quiz[172].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
  Quiz[173].Text = "Är du bra på att bedöma avstånd?";
  Quiz[174].Text = "Är du bra på att bedöma hastighet?";
  Quiz[175].Text = "Är du bra på att bedöma acceleration?";
  Quiz[176].Text = "Kan du lätt se små skillnader mellan bilder?";
  Quiz[177].Text = "Är du bra på att förutsäga rörelse?";
  Quiz[178].Text = "Är du missnöjd med hur någon kroppsdel ser ut hos dig?";

  Quiz[179].Text = "Dyslexi";
  Quiz[180].Text = "Dyskaluli";
  Quiz[181].Text = "OCD";
  Quiz[182].Text = "ODD";
  Quiz[183].Text = "Bipolär";
  Quiz[184].Text = "Social fobi";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS6::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::InitReferers()
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
	AddReferer("fohguild.org", "fohguild.org/forums/screenshots/31489-ass-burgers.html");

	}

/*##################  TQuizS6::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS6::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Gender == 1)
			UpdateReferer(&MaleRef, Row.AsResult, Row.NtResult, Row.GroupResult);
        else			
			UpdateReferer(&FemaleRef, Row.AsResult, Row.NtResult, Row.GroupResult);
	
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism == 2)
			UpdateReferer(&AutismRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2)
			UpdateReferer(&AsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&AddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.TS == 2)
			UpdateReferer(&TsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyslexia == 2)
			UpdateReferer(&DyslexiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyscalculia == 2)
			UpdateReferer(&DyscalculiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.OCD == 2)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ODD == 2)
			UpdateReferer(&ODDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Bipolar == 2)
			UpdateReferer(&BipolarRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Schizophrenia == 2)
			UpdateReferer(&SchizophreniaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Social == 2)
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
#   Name       : TQuizS6::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::LoadPopulations()
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

		Row.Quiz[179] = Row.Dyslexia + 1;
		Row.Quiz[180] = Row.Dyscalculia + 1;
		Row.Quiz[181] = Row.OCD + 1;
		Row.Quiz[182] = Row.ODD + 1;
		Row.Quiz[183] = Row.Bipolar + 1;
		Row.Quiz[184] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 179)
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

		if (Row.OCD == 2)
			DxArr[POP_TYPE_OCD] = DX_STATE_YES;

		if (Row.OCD == 1)
			DxArr[POP_TYPE_OCD] = DX_STATE_SELF;

		if (Row.OCD == 0)
			DxArr[POP_TYPE_OCD] = DX_STATE_NO;

		if (Row.ODD == 2)
			DxArr[POP_TYPE_ODD] = DX_STATE_YES;

		if (Row.ODD == 1)
			DxArr[POP_TYPE_ODD] = DX_STATE_SELF;

		if (Row.ODD == 0)
			DxArr[POP_TYPE_ODD] = DX_STATE_NO;

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
#   Name       : TQuizS6::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::SetupControlGroups()
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
    DefineNt("fohguild.org");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizS6::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5)
{
	DefineCross(QuizS5, 0, 128);
	DefineCross(QuizS5, 1, 132);
	DefineCross(QuizS5, 2, 169);
	DefineCross(QuizS5, 3, 168);
	DefineCross(QuizS5, 4, 143);
	DefineCross(QuizS5, 5, 147);
	DefineCross(QuizS5, 6, 167);
	DefineCross(QuizS5, 7, 0);
	DefineCross(QuizS5, 8, 1);
	DefineCross(QuizS5, 9, 2);
	DefineCross(QuizS5, 10, 3);
	DefineCross(QuizS5, 11, 4);
	DefineCross(QuizS5, 12, 5);
	DefineCross(QuizS5, 13, 7);
	DefineCross(QuizS5, 14, 6);
	DefineCross(QuizS5, 15, 8);
    DefineCross(QuizS5, 16, 9);
    DefineCross(QuizS5, 17, 10);
    DefineCross(QuizS5, 18, 11);
    DefineCross(QuizS5, 19, 12);
    DefineCross(QuizS5, 20, 13);
    DefineCross(QuizS5, 21, 14);
    DefineCross(QuizS5, 22, 15);
	DefineCross(QuizS5, 23, 16);
    DefineCross(QuizS5, 24, 17);
    DefineCross(QuizS5, 25, 21);
    DefineCross(QuizS5, 26, 18);
    DefineCross(QuizS5, 27, 19);
    DefineCross(QuizS5, 28, 20);
    DefineCross(QuizS5, 29, 22);
    DefineCross(QuizS5, 30, 23);
    DefineCross(QuizS5, 31, 24);
    DefineCross(QuizS5, 32, 123);
    DefineCross(QuizS5, 33, 25);
	DefineCross(QuizS5, 34, 26);
    DefineCross(QuizS5, 35, 27);
    DefineCross(QuizS5, 36, 28);
    DefineCross(QuizS5, 37, 29);
    DefineCross(QuizS5, 38, 30);
	DefineCross(QuizS5, 39, 31);
    DefineCross(QuizS5, 40, 32);
    DefineCross(QuizS5, 41, 33);
    DefineCross(QuizS5, 42, 34);
    DefineCross(QuizS5, 43, 35);
    DefineCross(QuizS5, 44, 36);
    DefineCross(QuizS5, 45, 37);
    DefineCross(QuizS5, 46, 39);
    DefineCross(QuizS5, 47, 38);
    DefineCross(QuizS5, 48, 165);
    DefineCross(QuizS5, 49, 40);
	DefineCross(QuizS5, 50, 41);
    DefineCross(QuizS5, 51, 45);
    DefineCross(QuizS5, 52, 42);
    DefineCross(QuizS5, 53, 43);
    DefineCross(QuizS5, 54, 46);
    DefineCross(QuizS5, 55, 91);
    DefineCross(QuizS5, 56, 49);
    DefineCross(QuizS5, 57, 47);
	DefineCross(QuizS5, 58, 48);
    DefineCross(QuizS5, 59, 50);
    DefineCross(QuizS5, 60, 52);
	DefineCross(QuizS5, 61, 53);
    DefineCross(QuizS5, 62, 55);
    DefineCross(QuizS5, 63, 54);
    DefineCross(QuizS5, 64, 58);
    DefineCross(QuizS5, 65, 56);
    DefineCross(QuizS5, 66, 57);
    DefineCross(QuizS5, 67, 59);
    DefineCross(QuizS5, 68, 60);
    DefineCross(QuizS5, 69, 61);
    DefineCross(QuizS5, 70, 62);
    DefineCross(QuizS5, 71, 64);
    DefineCross(QuizS5, 72, 63);
    DefineCross(QuizS5, 73, 65);
	DefineCross(QuizS5, 74, 66);
    DefineCross(QuizS5, 75, 68);
    DefineCross(QuizS5, 76, 67);
    DefineCross(QuizS5, 77, 69);
    DefineCross(QuizS5, 78, 70);
    DefineCross(QuizS5, 79, 71);
    DefineCross(QuizS5, 80, 72);
    DefineCross(QuizS5, 81, 73);
    DefineCross(QuizS5, 82, 74);
    DefineCross(QuizS5, 83, 75);
    DefineCross(QuizS5, 84, 76);
	DefineCross(QuizS5, 85, 77);
    DefineCross(QuizS5, 86, 78);
    DefineCross(QuizS5, 87, 79);
	DefineCross(QuizS5, 88, 80);
    DefineCross(QuizS5, 89, 81);
    DefineCross(QuizS5, 90, 82);
    DefineCross(QuizS5, 91, 83);
    DefineCross(QuizS5, 92, 84);
	DefineCross(QuizS5, 93, 85);
    DefineCross(QuizS5, 94, 86);
    DefineCross(QuizS5, 95, 87);
    DefineCross(QuizS5, 96, 88);
    DefineCross(QuizS5, 97, 89);
    DefineCross(QuizS5, 98, 90);
    DefineCross(QuizS5, 99, 93);
    DefineCross(QuizS5, 100, 92);
    DefineCross(QuizS5, 101, 94);
    DefineCross(QuizS5, 102, 95);
    DefineCross(QuizS5, 103, 96);
    DefineCross(QuizS5, 104, 97);
    DefineCross(QuizS5, 105, 98);
    DefineCross(QuizS5, 106, 99);
    DefineCross(QuizS5, 107, 100);
    DefineCross(QuizS5, 108, 101);
	DefineCross(QuizS5, 109, 102);
    DefineCross(QuizS5, 110, 103);
    DefineCross(QuizS5, 111, 104);
    DefineCross(QuizS5, 112, 105);
    DefineCross(QuizS5, 113, 106);
    DefineCross(QuizS5, 114, 107);
	DefineCross(QuizS5, 115, 127);
    DefineCross(QuizS5, 116, 124);
    DefineCross(QuizS5, 117, 130);
    DefineCross(QuizS5, 118, 137);
    DefineCross(QuizS5, 119, 108);
	DefineCross(QuizS5, 120, 109);
    DefineCross(QuizS5, 121, 110);
    DefineCross(QuizS5, 122, 111);
    DefineCross(QuizS5, 123, 112);
    DefineCross(QuizS5, 124, 113);
    DefineCross(QuizS5, 125, 114);
    DefineCross(QuizS5, 126, 115);
    DefineCross(QuizS5, 127, 116);
	DefineCross(QuizS5, 128, 117);
    DefineCross(QuizS5, 129, 118);
    DefineCross(QuizS5, 130, 119);
    DefineCross(QuizS5, 131, 120);
    DefineCross(QuizS5, 132, 121);
    DefineCross(QuizS5, 133, 122);
    DefineCross(QuizS5, 134, 125);
    DefineCross(QuizS5, 135, 126);
    DefineCross(QuizS5, 136, 129);
    DefineCross(QuizS5, 137, 131);
    DefineCross(QuizS5, 138, 164);
    DefineCross(QuizS5, 139, 134);
    DefineCross(QuizS5, 140, 133);
    DefineCross(QuizS5, 141, 135);
	DefineCross(QuizS5, 142, 136);
    DefineCross(QuizS5, 143, 138);
	DefineCross(QuizS5, 144, 141);
    DefineCross(QuizS5, 145, 142);
    DefineCross(QuizS5, 146, 139);
    DefineCross(QuizS5, 147, 140);
    DefineCross(QuizR7, 148, 54);
    DefineCross(QuizR3, 149, 52);
    DefineCross(QuizII, 150, 43);
    DefineCross(Quiz9, 151, 52);
    DefineCross(QuizS2, 152, 56);
	DefineCross(QuizNd, 153, 125);
	DefineCross(Quiz9, 154, 79);
	DefineCross(QuizR2, 155, 75);
	DefineCross(Quiz9, 156, 76);
	DefineCross(QuizR1, 157, 108);
	DefineCross(Quiz9, 158, 75);
	DefineCross(QuizNd, 159, 116);
	DefineCross(QuizR2, 160, 76);
	DefineCross(Quiz9, 161, 77);
	DefineCross(Quiz7, 162, 60);
	DefineCross(QuizNd, 163, 76);
	DefineCross(Quiz9, 164, 85);
	DefineCross(Quiz9, 165, 80);
	DefineCross(Quiz9, 166, 82);
	DefineCross(Quiz9, 167, 83);
	DefineCross(Quiz6, 168, 95);
	DefineCross(Quiz8, 169, 81);
	DefineCross(QuizR6, 170, 58);
	DefineCross(Quiz5, 171, 79);
	DefineCross(Quiz9, 172, 81);

	DefineGlobalId(173, 932);
	DefineGlobalId(174, 933);
	DefineGlobalId(175, 934);
	DefineGlobalId(176, 935);
	DefineGlobalId(177, 936);
	DefineGlobalId(178, 937);

	DefineCross(QuizS5, 179, 171);
	DefineCross(QuizS5, 180, 172);
	DefineCross(QuizS5, 181, 173);
	DefineCross(QuizS5, 182, 174);
	DefineCross(QuizS5, 183, 175);
	DefineCross(QuizS5, 184, 176);
}

/*##########################################################################
#
#   Name       : TQuizS6::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS6::GetReferer(const char *referer, TPopulation *pop)
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
			if (row->BirthYear >= 1975)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear < 1975)
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

/*##################  TQuizS6::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS6::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS6::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS6::ExportExcelAspie(const char *filename)
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

/*##################  TQuizS6::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS6::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS6::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS6::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_MALE || PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_ALL)
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

/*##################  TQuizS6::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS6::WriteRetest(const char *filename)
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
	long double QMean[179];
	long double AsSd;
	long double NtSd;
	long double QSd[179];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[179];
	int QCount[179];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[179][20];
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

    for (q = 0; q < 179; q++)
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

                    for (q = 0; q < 179; q++)
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

                	        for (q = 0; q < 179; q++)
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
    
	    			for (q = 0; q < 179; q++)
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

	    			for (q = 0; q < 179; q++)
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

}
