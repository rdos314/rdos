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
# quizs8.cpp
# Quiz stable version 8 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs8.h"
#include "file.h"
#include "quizdbs8.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS8::TQuizS8
#
#   Purpose....: Constructor for TQuizS8
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS8::TQuizS8(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7)
  : TQuiz(178),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS8::~TQuizS8
#
#   Purpose....: Destructor for TQuizS8
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS8::~TQuizS8()
{
}

/*##################  TQuizS8::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS8::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS8::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS8::GetCatCount(int Question)
{
	if (Question >= 157 && Question <= 171)
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
int TQuizS8::GetQuizN()
{
	return 157;
}

/*##########################################################################
#
#   Name       : TQuizS8::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS8::WriteName(TFile &File)
{
	 File.Write("S8");
}

/*##################  TQuizS8::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS8::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS8::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS8::SetupTexts()
{
  Quiz[18].Reverse = TRUE;
  Quiz[33].Reverse = TRUE;
  Quiz[34].Reverse = TRUE;
  Quiz[35].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[37].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[59].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[90].Reverse = TRUE;
  Quiz[91].Reverse = TRUE;
  Quiz[93].Reverse = TRUE;
  Quiz[94].Reverse = TRUE;
  Quiz[120].Reverse = TRUE;
  Quiz[150].Reverse = TRUE;
  Quiz[151].Reverse = TRUE;
  Quiz[152].Reverse = TRUE;
  Quiz[153].Reverse = TRUE;
  Quiz[154].Reverse = TRUE;
  Quiz[155].Reverse = TRUE;
  Quiz[156].Reverse = TRUE;
  Quiz[159].Reverse = TRUE;
  Quiz[160].Reverse = TRUE;
  Quiz[165].Reverse = TRUE;
  Quiz[166].Reverse = TRUE;
  Quiz[167].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_OBSESSION;
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
  Quiz[20].MyGroup = GROUP_NT_TALENT;
  Quiz[21].MyGroup = GROUP_NT_TALENT;
  Quiz[22].MyGroup = GROUP_NT_TALENT;
  Quiz[23].MyGroup = GROUP_NT_TALENT;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[28].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[29].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[30].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[31].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[32].MyGroup = GROUP_NT_OBSESSION;
  Quiz[33].MyGroup = GROUP_NT_SOCIAL;
  Quiz[34].MyGroup = GROUP_NT_OBSESSION;
  Quiz[35].MyGroup = GROUP_NT_OBSESSION;
  Quiz[36].MyGroup = GROUP_NT_OBSESSION;
  Quiz[37].MyGroup = GROUP_NT_OBSESSION;
  Quiz[38].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[39].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[40].MyGroup = GROUP_NT_SOCIAL;
  Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[42].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[43].MyGroup = GROUP_NT_SOCIAL;
  Quiz[44].MyGroup = GROUP_NT_SOCIAL;
  Quiz[45].MyGroup = GROUP_NT_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_NT_SOCIAL;
  Quiz[54].MyGroup = GROUP_NT_SOCIAL;
  Quiz[55].MyGroup = GROUP_NT_SOCIAL;
  Quiz[56].MyGroup = GROUP_NT_SOCIAL;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_NT_SOCIAL;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
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
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_NVC;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
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
  Quiz[93].MyGroup = GROUP_NT_NVC;
  Quiz[94].MyGroup = GROUP_NT_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[96].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[98].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[99].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[100].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[101].MyGroup = GROUP_NT_HUNTING;
  Quiz[102].MyGroup = GROUP_NT_HUNTING;
  Quiz[103].MyGroup = GROUP_NT_HUNTING;
  Quiz[104].MyGroup = GROUP_NT_HUNTING;
  Quiz[105].MyGroup = GROUP_NT_HUNTING;
  Quiz[106].MyGroup = GROUP_NT_HUNTING;
  Quiz[107].MyGroup = GROUP_NT_HUNTING;
  Quiz[108].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[109].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[110].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[111].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[112].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[113].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[114].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[115].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[116].MyGroup = GROUP_NT_SENSORY;
  Quiz[117].MyGroup = GROUP_NT_SENSORY;
  Quiz[118].MyGroup = GROUP_NT_SENSORY;
  Quiz[119].MyGroup = GROUP_NT_SENSORY;
  Quiz[120].MyGroup = GROUP_NT_SENSORY;
  Quiz[121].MyGroup = GROUP_NT_SENSORY;
  Quiz[122].MyGroup = GROUP_PARANOID;
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
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_MIXED;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_MIXED;
  Quiz[138].MyGroup = GROUP_MIXED;
  Quiz[139].MyGroup = GROUP_MIXED;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[142].MyGroup = GROUP_MIXED;
  Quiz[143].MyGroup = GROUP_MIXED;
  Quiz[144].MyGroup = GROUP_MIXED;
  Quiz[145].MyGroup = GROUP_MIXED;
  Quiz[146].MyGroup = GROUP_MIXED;
  Quiz[147].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[148].MyGroup = GROUP_MIXED;
  Quiz[149].MyGroup = GROUP_ASPIE_NVC;
  Quiz[150].MyGroup = GROUP_NT_TALENT;
  Quiz[151].MyGroup = GROUP_NT_SOCIAL;
  Quiz[152].MyGroup = GROUP_NT_SOCIAL;
  Quiz[153].MyGroup = GROUP_NT_NVC;
  Quiz[154].MyGroup = GROUP_NT_SENSORY;
  Quiz[155].MyGroup = GROUP_NT_SENSORY;
  Quiz[156].MyGroup = GROUP_ENVIRONMENT;

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

  Quiz[172].MyGroup = GROUP_NT_TALENT;
  Quiz[173].MyGroup = GROUP_NT_TALENT;
  Quiz[174].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[175].MyGroup = GROUP_MIXED;
  Quiz[176].MyGroup = GROUP_MIXED;
  Quiz[177].MyGroup = GROUP_ASPIE_SOCIAL;

#ifdef ENGLISH

  Quiz[0].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[1].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[2].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[3].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[4].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[5].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[6].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
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
  Quiz[24].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[25].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[26].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[27].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[28].Text = "Do you have certain routines which you need to follow?";
  Quiz[29].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[30].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[31].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[32].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[33].Text = "Is a large social network important to you?";
  Quiz[34].Text = "Do you enjoy gossip?";
  Quiz[35].Text = "Do you take pride in your appearance?";
  Quiz[36].Text = "Do you like to be in charge of other people?";
  Quiz[37].Text = "Do you enjoy wearing jewelry?";
  Quiz[38].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[39].Text = "Have you felt different from others for most of your life?";
  Quiz[40].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[41].Text = "Do you dislike shaking hands?";
  Quiz[42].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[43].Text = "Do people think you are aloof and distant?";
  Quiz[44].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[45].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[46].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[47].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[48].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[49].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[50].Text = "Do you prefer to avoid eye-contact?";
  Quiz[51].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[52].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[53].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[54].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[55].Text = "Do you enjoy meeting new people?";
  Quiz[56].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[57].Text = "Are your views typical of your peer group?";
  Quiz[58].Text = "Do you find it easy to describe your feelings?";
  Quiz[59].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[60].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[61].Text = "Do you find it easier to communicate in real life than online?";
  Quiz[62].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[63].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[64].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[65].Text = "Do you often don't know where to put your arms?";
  Quiz[66].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[67].Text = "Have you been accused of staring?";
  Quiz[68].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[69].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[70].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[71].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[72].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[73].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[74].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[75].Text = "Do you fiddle with things?";
  Quiz[76].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[77].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[78].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[79].Text = "Do you stutter when stressed?";
  Quiz[80].Text = "Do you talk to yourself?";
  Quiz[81].Text = "Do you clench your fists when angry?";
  Quiz[82].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[83].Text = "Do others often misunderstand you?";
  Quiz[84].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[85].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[86].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[87].Text = "Are you often surprised what people's motives are ?";
  Quiz[88].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[89].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[90].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[91].Text = "Do you know when you are expected to offer an apology?";
  Quiz[92].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[93].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[94].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[95].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[96].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[97].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[98].Text = "Do you enjoy walking on your toes?";
  Quiz[99].Text = "Have you been fascinated about making traps?";
  Quiz[100].Text = "Do you enjoy mimicking animal sounds?";
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
  Quiz[112].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[113].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[114].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[115].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[116].Text = "Do you have poor concept of time?";
  Quiz[117].Text = "Do you find it hard to tell the age of people?";
  Quiz[118].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[119].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[120].Text = "Are you good at keeping track of where people are (for instance in team-sports)?";
  Quiz[121].Text = "Do you confuse left and right?";
  Quiz[122].Text = "Do you feel that people are watching you?";
  Quiz[123].Text = "Do you mistake noises for voices?";
  Quiz[124].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[125].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[126].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[127].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[128].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[129].Text = "Are you sometimes afraid in safe situations?";
  Quiz[130].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[131].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[132].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[133].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[134].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[135].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[136].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[137].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[138].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[139].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[140].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[141].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[142].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[143].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[144].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[145].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[146].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[147].Text = "Do you dislike working while being observed?";
  Quiz[148].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[149].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[150].Text = "Can you easily remember verbal instructions?";
  Quiz[151].Text = "Do people understand you?";
  Quiz[152].Text = "Are you good at teamwork?";
  Quiz[153].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[154].Text = "Do you find it easy to estimate the age of people?";
  Quiz[155].Text = "Do you have a good sense of what time it is?";
  Quiz[156].Text = "Are you gracious about criticism, correction and direction?";

  Quiz[157].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you felt so good or so hyper that other people thought you were not your normal self or you were so hyper that you got into trouble?";
  Quiz[158].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were so irritable that you shouted at people or started fights or arguments?";
  Quiz[159].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you felt much more self-confident than usual?";
  Quiz[160].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you got much less sleep than usual and found you didn't really miss it?";
  Quiz[161].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more talkative or spoke faster than usual?";
  Quiz[162].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) thoughts raced through your head or you couldn't slow you mind down?";
  Quiz[163].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were so easily distracted by things around you that you had trouble concentrating or staying on track?";
  Quiz[164].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you had much more energy than usual?";
  Quiz[165].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more active or did many more things than usual?";
  Quiz[166].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more social or outgoing than usual; for example, you telephoned friends in the middle of the night?";
  Quiz[167].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more interested in sex than usual?";
  Quiz[168].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you did things that were unusual for you or that other people might have thought were excessive, foolish, or risky?";
  Quiz[169].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) spending money got you or your family into trouble?";
  Quiz[170].Text = "MDQ - If you checked YES to more than one of the above, have several of these ever happened during the same period of time?";
  Quiz[171].Text = "MDQ - How much of a problem did any of these cause you -- like being unable to work/; having family, money, or legal troubles; getting into arguments or fights?";

  Quiz[172].Text = "Dyslexia";
  Quiz[173].Text = "Dyscalculia";
  Quiz[174].Text = "OCD";
  Quiz[175].Text = "ODD";
  Quiz[176].Text = "Bipolar";
  Quiz[177].Text = "Social phobia";

#endif

#ifdef SWEDISH

  Quiz[0].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[1].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[2].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[3].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[4].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[5].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[6].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
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
  Quiz[24].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[25].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[26].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[27].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[28].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[29].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[30].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[31].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[32].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[33].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[34].Text = "Tycker du om skvaller?";
  Quiz[35].Text = "Är du stolt över ditt utseende?";
  Quiz[36].Text = "Gillar du att leda andra människor?";
  Quiz[37].Text = "Gillar du att bära smycken?";
  Quiz[38].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[39].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[40].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[41].Text = "Ogillar du att behöva ta i hand?";
  Quiz[42].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[43].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[44].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[45].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[46].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[47].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[48].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[49].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[50].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[51].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[52].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[53].Text = "Trivs du i romantiska situationer?";
  Quiz[54].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[55].Text = "Trivs du med att möta nya människor?";
  Quiz[56].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[57].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[58].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[59].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[60].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[61].Text = "Tycker du att det är lättare att kommunicera i verkliga livet än via dator?";
  Quiz[62].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[63].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[64].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[65].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[66].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[67].Text = "Har du blivit anklagad för att stirra?";
  Quiz[68].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[69].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[70].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[71].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[72].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[73].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[74].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[75].Text = "Brukar du fingra på saker?";
  Quiz[76].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[77].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[78].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[79].Text = "Stammar du när du blir stressad?";
  Quiz[80].Text = "Brukar du prata med dig själv?";
  Quiz[81].Text = "Knyter du nävarna när du är arg?";
  Quiz[82].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[83].Text = "Blir du ofta missförstådd av andra?";
  Quiz[84].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[85].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[86].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[87].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[88].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[89].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[90].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[91].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[92].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[93].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[94].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[95].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[96].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[97].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[98].Text = "Gillar du att gå på tå?";
  Quiz[99].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[100].Text = "Gillar du att härma djurläten?";
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
  Quiz[112].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[113].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[114].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[115].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[116].Text = "Har du dålig tidsuppfattning?";
  Quiz[117].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[118].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[119].Text = "Har du svårt att känna igen ansikten?";
  Quiz[120].Text = "Är du bra på att hålla reda på var folk är (t.ex. i bollsporter)?";
  Quiz[121].Text = "Brukar du blanda ihop höger och vänster?";
  Quiz[122].Text = "Tycker du att folk bevakar dig?";
  Quiz[123].Text = "Misstar du ljud för röster?";
  Quiz[124].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[125].Text = "Har du haft långvariga hämndbegär?";
  Quiz[126].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[127].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[128].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[129].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[130].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[131].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[132].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[133].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[134].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[135].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[136].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[137].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[138].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[139].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[140].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[141].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[142].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[143].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[144].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[145].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[146].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[147].Text = "Ogillar du att andra tittar på när du arbetar?";
  Quiz[148].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[149].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[150].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[151].Text = "Förstår sig folk på dig?";
  Quiz[152].Text = "Är du bra på att arbeta i grupp?";
  Quiz[153].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[154].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[155].Text = "Har du ett bra sinne för hur mycket klockan är?";
  Quiz[156].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";

  Quiz[157].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you felt so good or so hyper that other people thought you were not your normal self or you were so hyper that you got into trouble?";
  Quiz[158].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were so irritable that you shouted at people or started fights or arguments?";
  Quiz[159].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you felt much more self-confident than usual?";
  Quiz[160].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you got much less sleep than usual and found you didn't really miss it?";
  Quiz[161].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more talkative or spoke faster than usual?";
  Quiz[162].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) thoughts raced through your head or you couldn't slow you mind down?";
  Quiz[163].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were so easily distracted by things around you that you had trouble concentrating or staying on track?";
  Quiz[164].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you had much more energy than usual?";
  Quiz[165].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more active or did many more things than usual?";
  Quiz[166].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more social or outgoing than usual; for example, you telephoned friends in the middle of the night?";
  Quiz[167].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you were much more interested in sex than usual?";
  Quiz[168].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) you did things that were unusual for you or that other people might have thought were excessive, foolish, or risky?";
  Quiz[169].Text = "MDQ - Has there ever been a period of time when you were not your usual self and (while not on drugs or alcohol) spending money got you or your family into trouble?";
  Quiz[170].Text = "MDQ - If you checked YES to more than one of the above, have several of these ever happened during the same period of time?";
  Quiz[171].Text = "MDQ - How much of a problem did any of these cause you -- like being unable to work/; having family, money, or legal troubles; getting into arguments or fights?";

  Quiz[172].Text = "Dyslexi";
  Quiz[173].Text = "Dyskaluli";
  Quiz[174].Text = "OCD";
  Quiz[175].Text = "ODD";
  Quiz[176].Text = "Bipolär";
  Quiz[177].Text = "Social fobi";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS8::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS8::InitReferers()
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

/*##################  TQuizS8::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS8::LoadReferers()
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
#   Name       : TQuizS8::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS8::LoadPopulations()
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

		Row.Quiz[172] = Row.Dyslexia + 1;
		Row.Quiz[173] = Row.Dyscalculia + 1;
		Row.Quiz[174] = Row.OCD + 1;
		Row.Quiz[175] = Row.ODD + 1;
		Row.Quiz[176] = Row.Bipolar + 1;
		Row.Quiz[177] = Row.Social + 1;

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

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.ADHD >= 1)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.TS >= 1)
			Ts.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Dyslexia >= 1)
			Dyslexia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Dyscalculia >= 1)
			Dyscalculia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.OCD >= 1)
			OCD.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.ODD >= 1)
			ODD.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Bipolar >= 1)
			Bipolar.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Schizophrenia >= 1)
			Schizophrenia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Social >= 1)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

	}
}

/*##########################################################################
#
#   Name       : TQuizS8::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS8::SetupControlGroups()
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
#   Name       : TQuizS8::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS8::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7)
{
    DefineCross(QuizS7, 0, 20);
    DefineCross(QuizS7, 1, 21);
    DefineCross(QuizS7, 2, 22);
    DefineCross(QuizS7, 3, 23);
    DefineCross(QuizS7, 4, 24);
    DefineCross(QuizS7, 5, 25);
    DefineCross(QuizS7, 6, 26);
    DefineCross(QuizS7, 7, 27);
    DefineCross(QuizS7, 8, 28);
    DefineCross(QuizS7, 9, 29);
    DefineCross(QuizS7, 10, 30);
    DefineCross(QuizS7, 11, 31);
    DefineCross(QuizS7, 12, 32);
    DefineCross(QuizS7, 13, 33);
    DefineCross(QuizS7, 14, 34);
    DefineCross(QuizS7, 15, 35);
    DefineCross(QuizS7, 16, 36);
    DefineCross(QuizS7, 17, 37);
    DefineCross(QuizS7, 18, 38);
    DefineCross(QuizS7, 19, 40);
    DefineCross(QuizS7, 20, 41);
    DefineCross(QuizS7, 21, 42);
    DefineCross(QuizS7, 22, 43);
    DefineCross(QuizS7, 23, 44);
    DefineCross(QuizS7, 24, 104);
    DefineCross(QuizS7, 25, 105);
    DefineCross(QuizS7, 26, 106);
    DefineCross(QuizS7, 27, 107);
    DefineCross(QuizS7, 28, 108);
    DefineCross(QuizS7, 29, 109);
    DefineCross(QuizS7, 30, 110);
    DefineCross(QuizS7, 31, 111);
    DefineCross(QuizS7, 32, 112);
    DefineCross(QuizS7, 33, 113);
    DefineCross(QuizS7, 34, 115);
    DefineCross(QuizS7, 35, 116);
    DefineCross(QuizS7, 36, 117);
    DefineCross(QuizS7, 37, 118);
    DefineCross(QuizS7, 38, 46);
    DefineCross(QuizS7, 39, 47);
    DefineCross(QuizS7, 40, 48);
    DefineCross(QuizS7, 41, 49);
    DefineCross(QuizS7, 42, 50);
    DefineCross(QuizS7, 43, 51);
    DefineCross(QuizS7, 44, 52);
    DefineCross(QuizS7, 45, 54);
    DefineCross(QuizS7, 46, 55);
    DefineCross(QuizS7, 47, 56);
    DefineCross(QuizS7, 48, 57);
    DefineCross(QuizS7, 49, 58);
    DefineCross(QuizS7, 50, 155);
    DefineCross(QuizS7, 51, 59);
    DefineCross(QuizS7, 52, 60);
    DefineCross(QuizS7, 53, 156);
    DefineCross(QuizS7, 54, 61);
    DefineCross(QuizS7, 55, 159);
    DefineCross(QuizS7, 56, 162);
    DefineCross(QuizS7, 57, 63);
    DefineCross(QuizS7, 58, 64);
    DefineCross(QuizS7, 59, 65);
    DefineCross(QuizS7, 60, 67);
    DefineCross(QuizS7, 61, 163);
    DefineCross(QuizS7, 62, 69);
    DefineCross(QuizS7, 63, 70);
    DefineCross(QuizS7, 64, 71);
    DefineCross(QuizS7, 65, 73);
    DefineCross(QuizS7, 66, 72);
    DefineCross(QuizS7, 67, 74);
    DefineCross(QuizS7, 68, 75);
    DefineCross(QuizS7, 69, 76);
    DefineCross(QuizS7, 70, 77);
    DefineCross(QuizS7, 71, 78);
    DefineCross(QuizS7, 72, 79);
    DefineCross(QuizS7, 73, 80);
    DefineCross(QuizS7, 74, 81);
    DefineCross(QuizS7, 75, 82);
    DefineCross(QuizS7, 76, 83);
    DefineCross(QuizS7, 77, 84);
    DefineCross(QuizS7, 78, 85);
    DefineCross(QuizS7, 79, 86);
    DefineCross(QuizS7, 80, 87);
    DefineCross(QuizS7, 81, 88);
    DefineCross(QuizS7, 82, 89);
    DefineCross(QuizS7, 83, 90);
    DefineCross(QuizS7, 84, 91);
    DefineCross(QuizS7, 85, 92);
    DefineCross(QuizS7, 86, 93);
    DefineCross(QuizS7, 87, 94);
    DefineCross(QuizS7, 88, 96);
    DefineCross(QuizS7, 89, 97);
    DefineCross(QuizS7, 90, 98);
    DefineCross(QuizS7, 91, 99);
    DefineCross(QuizS7, 92, 100);
    DefineCross(QuizS7, 93, 101);
    DefineCross(QuizS7, 94, 103);
    DefineCross(QuizS7, 95, 0);
    DefineCross(QuizS7, 96, 1);
    DefineCross(QuizS7, 97, 2);
    DefineCross(QuizS7, 98, 3);
    DefineCross(QuizS7, 99, 5);
    DefineCross(QuizS7, 100, 4);
    DefineCross(QuizS7, 101, 45);
    DefineCross(QuizS7, 102, 6);
    DefineCross(QuizS7, 103, 7);
    DefineCross(QuizS7, 104, 8);
    DefineCross(QuizS7, 105, 9);
    DefineCross(QuizS7, 106, 173);
    DefineCross(QuizS7, 107, 170);
    DefineCross(QuizS7, 108, 12);
    DefineCross(QuizS7, 109, 13);
    DefineCross(QuizS7, 110, 14);
    DefineCross(QuizS7, 111, 15);
    DefineCross(QuizS7, 112, 16);
    DefineCross(QuizS7, 113, 17);
    DefineCross(QuizS7, 114, 18);
    DefineCross(QuizS7, 115, 19);
    DefineCross(QuizS7, 116, 39);
    DefineCross(QuizS7, 117, 141);
    DefineCross(QuizS7, 118, 10);
    DefineCross(QuizS7, 119, 102);
    DefineCross(QuizS7, 120, 181);
    DefineCross(QuizS7, 121, 174);
    DefineCross(QuizS7, 122, 119);
    DefineCross(QuizS7, 123, 120);
    DefineCross(QuizS7, 124, 121);
    DefineCross(QuizS7, 125, 122);
    DefineCross(QuizS7, 126, 123);
    DefineCross(QuizS7, 127, 124);
    DefineCross(QuizS7, 128, 125);
    DefineCross(QuizS7, 129, 126);
    DefineCross(QuizS7, 130, 127);
    DefineCross(QuizS7, 131, 128);
    DefineCross(QuizS7, 132, 129);
    DefineCross(QuizS7, 133, 130);
    DefineCross(QuizS7, 134, 131);
    DefineCross(QuizS7, 135, 132);
    DefineCross(QuizS7, 136, 134);
    DefineCross(QuizS7, 137, 133);
    DefineCross(QuizS7, 138, 135);
    DefineCross(QuizS7, 139, 136);
    DefineCross(QuizS7, 140, 137);
    DefineCross(QuizS7, 141, 139);
    DefineCross(QuizS7, 142, 140);
    DefineCross(QuizS7, 143, 138);
    DefineCross(QuizS7, 144, 144);
    DefineCross(QuizS7, 145, 142);
    DefineCross(QuizS7, 146, 143);
    DefineCross(QuizS7, 147, 145);
    DefineCross(QuizS7, 148, 146);
    DefineCross(QuizS7, 149, 147);
    DefineCross(QuizS7, 150, 150);
    DefineCross(QuizS7, 151, 152);
    DefineCross(QuizS7, 152, 153);
    DefineCross(QuizS7, 153, 95);
    DefineCross(QuizS7, 154, 154);
    DefineCross(QuizS7, 155, 177);
    DefineCross(QuizS7, 156, 151);

	DefineGlobalId(157, 941);
	DefineGlobalId(158, 942);
	DefineGlobalId(159, 943);
	DefineGlobalId(160, 944);
	DefineGlobalId(161, 945);
	DefineGlobalId(162, 946);
	DefineGlobalId(163, 947);
	DefineGlobalId(164, 948);
	DefineGlobalId(165, 949);
	DefineGlobalId(166, 950);
	DefineGlobalId(167, 951);
	DefineGlobalId(168, 952);
	DefineGlobalId(169, 953);
	DefineGlobalId(170, 954);
	DefineGlobalId(171, 955);

	DefineCross(QuizS7, 172, 183);
	DefineCross(QuizS7, 173, 184);
	DefineCross(QuizS7, 174, 185);
	DefineCross(QuizS7, 175, 186);
	DefineCross(QuizS7, 176, 187);
	DefineCross(QuizS7, 177, 188);

}

/*##########################################################################
#
#   Name       : TQuizS8::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS8::GetReferer(const char *referer, TPopulation *pop)
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
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz, Row.GroupResult);
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

/*##################  TQuizS8::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS8::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS8::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS8::ExportExcelAspie(const char *filename)
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
	    if (Row.MdqResult)
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

/*##################  TQuizS8::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS8::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS8::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS8::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_FEMALE)
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
