/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2008, Leif Ekblad
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
# quizn1.cpp
# Quiz neurodiversity version 1 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizn1.h"
#include "file.h"
#include "quizdbn1.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

#if !defined(SWEDISH) && !defined(ENGLISH)
#define ENGLISH
#endif

/*##########################################################################
#
#   Name       : TQuizN1::TQuizN1
#
#   Purpose....: Constructor for TQuizN1
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizN1::TQuizN1(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12)
  : TQuiz(199),
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
	DefineCross(26, QuizS11);
	DefineCross(27, QuizS12);

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizN1::~TQuizN1
#
#   Purpose....: Destructor for TQuizN1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizN1::~TQuizN1()
{
}

/*##################  TQuizN1::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizN1::GetPcaCount()
{
	return 4;
}

/*##################  TQuizN1::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizN1::GetCatCount(int Question)
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
int TQuizN1::GetQuizN()
{
	return 194;
}

/*##########################################################################
#
#   Name       : TQuizN1::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::WriteName(TFile &File)
{
	 File.Write("N1");
}

/*##########################################################################
#
#   Name       : TQuizN1::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::WriteLongName(TFile &File)
{
	 File.Write("neurodiversity version 1");
}

/*##################  TQuizN1::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN1::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizN1::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::SetupTexts()
{
  Quiz[14].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[33].Reverse = TRUE;
  Quiz[34].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[37].Reverse = TRUE;
  Quiz[38].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[62].Reverse = TRUE;
  Quiz[64].Reverse = TRUE;
  Quiz[68].Reverse = TRUE;
  Quiz[101].Reverse = TRUE;
  Quiz[102].Reverse = TRUE;
  Quiz[103].Reverse = TRUE;
  Quiz[104].Reverse = TRUE;
  Quiz[106].Reverse = TRUE;
  Quiz[107].Reverse = TRUE;
  Quiz[108].Reverse = TRUE;
  Quiz[109].Reverse = TRUE;
  Quiz[111].Reverse = TRUE;
  Quiz[127].Reverse = TRUE;
  Quiz[128].Reverse = TRUE;
  Quiz[172].Reverse = TRUE;
  Quiz[173].Reverse = TRUE;
  Quiz[174].Reverse = TRUE;
  Quiz[175].Reverse = TRUE;
  Quiz[176].Reverse = TRUE;
  Quiz[180].Reverse = TRUE;
  Quiz[181].Reverse = TRUE;
  Quiz[182].Reverse = TRUE;
  Quiz[188].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_NT_NVC;
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
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[19].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[20].MyGroup = GROUP_NT_TALENT;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[28].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[29].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[30].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[31].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[32].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[33].MyGroup = GROUP_NT_SOCIAL;
  Quiz[34].MyGroup = GROUP_NT_OBSESSION;
  Quiz[35].MyGroup = GROUP_NT_OBSESSION;
  Quiz[36].MyGroup = GROUP_NT_OBSESSION;
  Quiz[37].MyGroup = GROUP_NT_OBSESSION;
  Quiz[38].MyGroup = GROUP_NT_OBSESSION;
  Quiz[39].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[40].MyGroup = GROUP_NT_TALENT;
  Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[42].MyGroup = GROUP_ENVIRONMENT;
  Quiz[43].MyGroup = GROUP_ENVIRONMENT;
  Quiz[44].MyGroup = GROUP_NT_TALENT;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[47].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_OBSESSION;
  Quiz[50].MyGroup = GROUP_ENVIRONMENT;
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
  Quiz[62].MyGroup = GROUP_NT_NVC;
  Quiz[63].MyGroup = GROUP_NT_SOCIAL;
  Quiz[64].MyGroup = GROUP_NT_SOCIAL;
  Quiz[65].MyGroup = GROUP_NT_SOCIAL;
  Quiz[66].MyGroup = GROUP_NT_SOCIAL;
  Quiz[67].MyGroup = GROUP_NT_SOCIAL;
  Quiz[68].MyGroup = GROUP_NT_SOCIAL;
  Quiz[69].MyGroup = GROUP_ASPIE_NVC;
  Quiz[70].MyGroup = GROUP_NT_NVC;
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
  Quiz[91].MyGroup = GROUP_ASPIE_NVC;
  Quiz[92].MyGroup = GROUP_ASPIE_SOCIAL;
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
  Quiz[103].MyGroup = GROUP_NT_SOCIAL;
  Quiz[104].MyGroup = GROUP_NT_NVC;
  Quiz[105].MyGroup = GROUP_NT_NVC;
  Quiz[106].MyGroup = GROUP_NT_NVC;
  Quiz[107].MyGroup = GROUP_NT_NVC;
  Quiz[108].MyGroup = GROUP_NT_NVC;
  Quiz[109].MyGroup = GROUP_NT_OBSESSION;
  Quiz[110].MyGroup = GROUP_NT_SENSORY;
  Quiz[111].MyGroup = GROUP_NT_NVC;
  Quiz[112].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[113].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[114].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[115].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[116].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[117].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[118].MyGroup = GROUP_NT_HUNTING;
  Quiz[119].MyGroup = GROUP_NT_HUNTING;
  Quiz[120].MyGroup = GROUP_NT_HUNTING;
  Quiz[121].MyGroup = GROUP_NT_HUNTING;
  Quiz[122].MyGroup = GROUP_NT_HUNTING;
  Quiz[123].MyGroup = GROUP_NT_HUNTING;
  Quiz[124].MyGroup = GROUP_NT_HUNTING;
  Quiz[125].MyGroup = GROUP_NT_HUNTING;
  Quiz[126].MyGroup = GROUP_NT_HUNTING;
  Quiz[127].MyGroup = GROUP_NT_HUNTING;
  Quiz[128].MyGroup = GROUP_NT_HUNTING;
  Quiz[129].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[130].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[131].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[132].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[133].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[134].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[135].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[136].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[137].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[138].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[139].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[140].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[141].MyGroup = GROUP_NT_SENSORY;
  Quiz[142].MyGroup = GROUP_NT_SENSORY;
  Quiz[143].MyGroup = GROUP_NT_SENSORY;
  Quiz[144].MyGroup = GROUP_NT_SENSORY;
  Quiz[145].MyGroup = GROUP_NT_SENSORY;
  Quiz[146].MyGroup = GROUP_NT_SENSORY;
  Quiz[147].MyGroup = GROUP_NT_SENSORY;
  Quiz[148].MyGroup = GROUP_NT_SENSORY;
  Quiz[149].MyGroup = GROUP_NT_SENSORY;
  Quiz[150].MyGroup = GROUP_MIXED;
  Quiz[151].MyGroup = GROUP_MIXED;
  Quiz[152].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[153].MyGroup = GROUP_ENVIRONMENT;
  Quiz[154].MyGroup = GROUP_ENVIRONMENT;
  Quiz[155].MyGroup = GROUP_ENVIRONMENT;
  Quiz[156].MyGroup = GROUP_ENVIRONMENT;
  Quiz[157].MyGroup = GROUP_ENVIRONMENT;
  Quiz[158].MyGroup = GROUP_ENVIRONMENT;
  Quiz[159].MyGroup = GROUP_ENVIRONMENT;
  Quiz[160].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[161].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[162].MyGroup = GROUP_NT_NVC;
  Quiz[163].MyGroup = GROUP_NT_NVC;
  Quiz[164].MyGroup = GROUP_ASPIE_NVC;
  Quiz[165].MyGroup = GROUP_MIXED;
  Quiz[166].MyGroup = GROUP_NT_NVC;
  Quiz[167].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[168].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[169].MyGroup = GROUP_NT_NVC;
  Quiz[170].MyGroup = GROUP_MIXED;
  Quiz[171].MyGroup = GROUP_MIXED;
  Quiz[172].MyGroup = GROUP_NT_SOCIAL;
  Quiz[173].MyGroup = GROUP_NT_NVC;
  Quiz[174].MyGroup = GROUP_NT_SENSORY;
  Quiz[175].MyGroup = GROUP_ENVIRONMENT;
  Quiz[176].MyGroup = GROUP_NT_TALENT;
  Quiz[177].MyGroup = GROUP_ASPIE_SENSORY;

  Quiz[178].MyGroup = GROUP_NT_OBSESSION;
  Quiz[179].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[180].MyGroup = GROUP_NT_TALENT;
  Quiz[181].MyGroup = GROUP_NT_TALENT;
  Quiz[182].MyGroup = GROUP_NT_SENSORY;
  Quiz[183].MyGroup = GROUP_NT_SOCIAL;
  Quiz[184].MyGroup = GROUP_MIXED;
  Quiz[185].MyGroup = GROUP_ASPIE_NVC;
  Quiz[186].MyGroup = GROUP_NT_NVC;
  Quiz[187].MyGroup = GROUP_ASPIE_NVC;
  Quiz[188].MyGroup = GROUP_NT_NVC;
  Quiz[189].MyGroup = GROUP_ENVIRONMENT;
  Quiz[190].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[191].MyGroup = GROUP_NT_SOCIAL;
  Quiz[192].MyGroup = GROUP_MIXED;
  Quiz[193].MyGroup = GROUP_ASPIE_HUNTING;

  Quiz[194].MyGroup = GROUP_NT_HUNTING;
  Quiz[195].MyGroup = GROUP_NT_HUNTING;
  Quiz[196].MyGroup = GROUP_NT_SENSORY;
  Quiz[197].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[198].MyGroup = GROUP_NT_SOCIAL;

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
  Quiz[11].Text = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";
  Quiz[12].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[13].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[14].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[15].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[16].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[17].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[18].Text = "Do you find it easy to organize your daily life?";
  Quiz[19].Text = "Do you have money management difficulties?";
  Quiz[20].Text = "Are you a slow reader?";
  Quiz[21].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[22].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[23].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[24].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[25].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[26].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[27].Text = "Do you have certain routines which you need to follow?";
  Quiz[28].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[29].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[30].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[31].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[32].Text = "Are you punctual, conscientious and perfectionist?";
  Quiz[33].Text = "Do you enjoy meeting new people?";
  Quiz[34].Text = "Are your views typical of your peer group?";
  Quiz[35].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[36].Text = "Is a large social network important to you?";
  Quiz[37].Text = "Do you take pride in your appearance?";
  Quiz[38].Text = "Do you enjoy gossip?";
  Quiz[39].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[40].Text = "Are you easily distracted?";
  Quiz[41].Text = "Do you have problems starting and / or finishing projects?";
  Quiz[42].Text = "Are you impatient and have low frustration tolerance?";
  Quiz[43].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[44].Text = "If you work on more than one project at a time do you seldom finish them?";
  Quiz[45].Text = "Are you poor at organizing your work and / or life?";
  Quiz[46].Text = "Are you or have you been hyperactive?";
  Quiz[47].Text = "Do you have regular periods of high activity interspaced with periods of lower activity?";
  Quiz[48].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[49].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[50].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[51].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[52].Text = "Do you tend to feel nervous, shy, confused or left out in social situations?";
  Quiz[53].Text = "Do you prefer to avoid eye-contact?";
  Quiz[54].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[55].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[56].Text = "Do people think you are aloof and distant?";
  Quiz[57].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[58].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[59].Text = "Do you dislike shaking hands?";
  Quiz[60].Text = "Do you feel uncomfortable with strangers?";
  Quiz[61].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[62].Text = "Do you find it easy to describe your feelings?";
  Quiz[63].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[64].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[65].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[66].Text = "Do you dislike reading aloud?";
  Quiz[67].Text = "Are you self-centered?";
  Quiz[68].Text = "Do you like to speak in public?";
  Quiz[69].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[70].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[71].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[72].Text = "Do you often don't know where to put your arms?";
  Quiz[73].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[74].Text = "Have you been accused of staring?";
  Quiz[75].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[76].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[77].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[78].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[79].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[80].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[81].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[82].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[83].Text = "Do you fiddle with things?";
  Quiz[84].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[85].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[86].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[87].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[88].Text = "Do you stutter when stressed?";
  Quiz[89].Text = "Do you talk to yourself?";
  Quiz[90].Text = "Do you have difficulties with pronunciation?";
  Quiz[91].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[92].Text = "Do you examine the hair of people you like a lot?";
  Quiz[93].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[94].Text = "Do others often misunderstand you?";
  Quiz[95].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[96].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[97].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[98].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[99].Text = "Are you often surprised what people's motives are ?";
  Quiz[100].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[101].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[102].Text = "Do you know when you are expected to offer an apology?";
  Quiz[103].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[104].Text = "Are you good at interpreting facial expressions?";
  Quiz[105].Text = "Are you so honest and sincere yourself that you assume everyone is?";
  Quiz[106].Text = "Are you intuitive about what people need from you?";
  Quiz[107].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[108].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[109].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[110].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[111].Text = "Can you easily remember people's names when you meet new people?";
  Quiz[112].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[113].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[114].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[115].Text = "Do you enjoy walking on your toes?";
  Quiz[116].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[117].Text = "Have you been fascinated about making traps?";
  Quiz[118].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[119].Text = "Do you drop things when your attention is on other things?";
  Quiz[120].Text = "Do you have problems filling out forms?";
  Quiz[121].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[122].Text = "Do you mix up dates and times and miss appointments?";
  Quiz[123].Text = "Do you mix up digits in numbers like 95 and 59?";
  Quiz[124].Text = "Do you have trouble reading clocks?";
  Quiz[125].Text = "Do you find it difficult to calculate change received from a purchase?";
  Quiz[126].Text = "Do you often make spelling errors?";
  Quiz[127].Text = "Do you find it easy to understand calendars?";
  Quiz[128].Text = "Do find it easy to remember math formulas?";
  Quiz[129].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[130].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[131].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[132].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[133].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[134].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[135].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[136].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[137].Text = "Does it come more natural to you to think in pictures than in words?";
  Quiz[138].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[139].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[140].Text = "Can you sense the feelings of animals?";
  Quiz[141].Text = "Do you have problems with ball sports?";
  Quiz[142].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[143].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[144].Text = "Do you have poor concept of time?";
  Quiz[145].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[146].Text = "Do you find it hard to tell the age of people?";
  Quiz[147].Text = "Did you perceive practical classes like handi-work or gymnasics as hard in school?";
  Quiz[148].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
  Quiz[149].Text = "Do you have problems finding your way to new places?";
  Quiz[150].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[151].Text = "Do you feel that people are watching you?";
  Quiz[152].Text = "Do you mistake noises for voices?";
  Quiz[153].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[154].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[155].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[156].Text = "Are you sometimes afraid in safe situations?";
  Quiz[157].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[158].Text = "Are you prone to getting depressions?";
  Quiz[159].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[160].Text = "Are you superstitious?";
  Quiz[161].Text = "Are you fairly non-sensitive to physical pain?";
  Quiz[162].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[163].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[164].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[165].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[166].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[167].Text = "Do you have immature interests?";
  Quiz[168].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[169].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[170].Text = "Do you have phobias?";
  Quiz[171].Text = "Has there been a period of time when you were not your usual self and you were much more social or outgoing than usual?";
  Quiz[172].Text = "Are you good at teamwork?";
  Quiz[173].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[174].Text = "Do you find it easy to estimate the age of people?";
  Quiz[175].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[176].Text = "Can you easily remember verbal instructions?";

  Quiz[177].Text = "Do you have a well-developed sense of colour?";
  Quiz[178].Text = "Do you often feel out-of-sync with others?";
  Quiz[179].Text = "Do you need periods of contemplation?";
  Quiz[180].Text = "Do you have an extensive vocabulary?";
  Quiz[181].Text = "Do you understand new ideas quickly?";
  Quiz[182].Text = "Are you a good problem solver?";
  Quiz[183].Text = "Do you have trouble resisting a high pressure sales person?";
  Quiz[184].Text = "Is your writing difficult to read?";
  Quiz[185].Text = "Do you repeat vocalizations made by others?";
  Quiz[186].Text = "Do you find it difficult to work out people's intentions?";
  Quiz[187].Text = "Do you turn words around in conversations?";
  Quiz[188].Text = "Do you have an expressive and lively way of speaking?";
  Quiz[189].Text = "Do you have mood swings?";
  Quiz[190].Text = "Has there ever been a period of time when you were much more social or outgoing than usual; for example, you telephoned friends in the middle of the night?";
  Quiz[191].Text = "Do you avoid urinating in a public bathroom?";
  Quiz[192].Text = "Can other people feel your feelings when they are not there?";
  Quiz[193].Text = "Do you enjoy throwing things like stones?";

  Quiz[194].Text = "Dyslexia";
  Quiz[195].Text = "Dyscalculia";
  Quiz[196].Text = "Dyspraxia";
  Quiz[197].Text = "Bipolar";
  Quiz[198].Text = "Social phobia";

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
  Quiz[11].Text = "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför behov av att få göra klart det du håller på med innan du kan ta itu med något annat?";
  Quiz[12].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[13].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[14].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[15].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[16].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[17].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[18].Text = "Tycker du det är enkelt att organisera ditt dagliga liv?";
  Quiz[19].Text = "Har du svårt att hantera din ekonomi?";
  Quiz[20].Text = "Läser du sakta?";
  Quiz[21].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[22].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[23].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[24].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[25].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[26].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[27].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[28].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[29].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[30].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[31].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[32].Text = "Är du punktlig, noggrann och/eller perfektionistisk?";
  Quiz[33].Text = "Trivs du med att möta nya människor?";
  Quiz[34].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[35].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[36].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[37].Text = "Är du stolt över ditt utseende?";
  Quiz[38].Text = "Tycker du om skvaller?";
  Quiz[39].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[40].Text = "Blir du lätt distraherad?";
  Quiz[41].Text = "Har du problem att starta och / eller slutföra projekt?";
  Quiz[42].Text = "Är du otålig och lättfrustrerad?";
  Quiz[43].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[44].Text = "Om du jobbar med mer än ett projekt slutför du då sällan dem? ";
  Quiz[45].Text = "Är du dålig på att organisera ditt arbete och / eller liv?";
  Quiz[46].Text = "Är du eller har du varit hyperaktiv";
  Quiz[47].Text = "Har du perioder av hög aktivitet med mellanliggande perioder med låg aktivitet?";
  Quiz[48].Text = "Låser det sig för dig när du får frågor i sociala situationer?";
  Quiz[49].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[50].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[51].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[52].Text = "Brukar du känna dig nervös, blyg, förvirrad eller utanför i olika sociala situationer?";
  Quiz[53].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[54].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[55].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[56].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[57].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[58].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[59].Text = "Ogillar du att behöva ta i hand?";
  Quiz[60].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[61].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[62].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[63].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[64].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[65].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[66].Text = "Ogillar du högläsning?";
  Quiz[67].Text = "Är du självcentrerad?";
  Quiz[68].Text = "Tycker du om att tala offentligt?";
  Quiz[69].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[70].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[71].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[72].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[73].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[74].Text = "Har du blivit anklagad för att stirra?";
  Quiz[75].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[76].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[77].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[78].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[79].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[80].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[81].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[82].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[83].Text = "Brukar du fingra på saker?";
  Quiz[84].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[85].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[86].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[87].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[88].Text = "Stammar du när du blir stressad?";
  Quiz[89].Text = "Brukar du prata med dig själv?";
  Quiz[90].Text = "Har du svårigheter med uttal?";
  Quiz[91].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
  Quiz[92].Text = "Undersöker du håret på de som du gillar mycket?";
  Quiz[93].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[94].Text = "Blir du ofta missförstådd av andra?";
  Quiz[95].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[96].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[97].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[98].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[99].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[100].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[101].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[102].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[103].Text = "Trivs du i romantiska situationer?";
  Quiz[104].Text = "Är du bra på att tolka ansiktsuttryck?";
  Quiz[105].Text = "Är det så naturligt för dig att vara totalt ärlig att du tror alla är sådana?";
  Quiz[106].Text = "Känner du intuitivt vad folk behöver från dig?";
  Quiz[107].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[108].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[109].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[110].Text = "Har du svårt att känna igen ansikten?";
  Quiz[111].Text = "Har du lätt att komma ihåg vad folk heter när du möter nya människor?";
  Quiz[112].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[113].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[114].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[115].Text = "Gillar du att gå på tå?";
  Quiz[116].Text = "Gillar du att härma djurläten?";
  Quiz[117].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[118].Text = "Tycker du det är svårt att ta meddelenden på telefon och skicka dem vidare rätt?'";
  Quiz[119].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[120].Text = "Har du svårt att fylla i formulär?";
  Quiz[121].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[122].Text = "Blandar du ihop tider och datum och missar möten?";
  Quiz[123].Text = "Blandar du ihop siffor i tal som t.ex. 95 och 59?";
  Quiz[124].Text = "Har du svårigheter att läsa av klockor?";
  Quiz[125].Text = "Tycker du det är svårt att beräkna växel på ett köp?";
  Quiz[126].Text = "Gör du ofta stavfel?";
  Quiz[127].Text = "Förstår du lätt dig på kalendrar?";
  Quiz[128].Text = "Tycker du det är enkelt att komma ihåg matematiska formler?";
  Quiz[129].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[130].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[131].Text = "Är du känslig för omslag i luftryck och luftfuktighet?";
  Quiz[132].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[133].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[134].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[135].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[136].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[137].Text = "Är det mer naturligt för dig att tänka i bilder än i ord?";
  Quiz[138].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[139].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[140].Text = "Känner du av djurs känslor?";
  Quiz[141].Text = "Har du problem med med bollsporter?";
  Quiz[142].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[143].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[144].Text = "Har du dålig tidsuppfattning?";
  Quiz[145].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[146].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[147].Text = "Tyckte du praktiska ämnen som slöjd och gymnastik var svårt i skolan?";
  Quiz[148].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[149].Text = "Har du svårt att hitta till nya platser?";
  Quiz[150].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[151].Text = "Tycker du att folk bevakar dig?";
  Quiz[152].Text = "Misstar du ljud för röster?";
  Quiz[153].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[154].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[155].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[156].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[157].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[158].Text = "Brukar du få depressioner?";
  Quiz[159].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[160].Text = "Är du vidskeplig?";
  Quiz[161].Text = "Är du ganska okänslig för fysisk smärta?";
  Quiz[162].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[163].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[164].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[165].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[166].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[167].Text = "Har du omogna intressen?";
  Quiz[168].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[169].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[170].Text = "Har du fobier?";
  Quiz[171].Text = "Har det funnits en tid då du inte var dig själv och att du var mycket mer social och utåtriktad än normalt?";
  Quiz[172].Text = "Är du bra på att arbeta i grupp?";
  Quiz[173].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[174].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[175].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[176].Text = "Kommer du lätt ihåg verbala instruktioner?";

  Quiz[177].Text = "Har du välutvecklat färgseende?";
  Quiz[178].Text = "Känner du dig ofta ur fas med andra?";
  Quiz[179].Text = "Behöver du perioder av begrundande?";
  Quiz[180].Text = "Har du ett omfattande ordföråd?";
  Quiz[181].Text = "Förstår du snabbt nya idéer?";
  Quiz[182].Text = "Är du en bra problemlösare?";
  Quiz[183].Text = "Har du problem att stå emot en påstridig försäljare?";
  Quiz[184].Text = "Är det svårt att läsa vad du skrivit?";
  Quiz[185].Text = "Upprepar du vad andra sagt?";
  Quiz[186].Text = "Har du svårt att räkna ut folks intentioner?";
  Quiz[187].Text = "Blandar du om ord i konversationer?";
  Quiz[188].Text = "Har du ett livligt och uttrycksfullt sätt att tala?";
  Quiz[189].Text = "Har du humörsvängningar?";
  Quiz[190].Text = "Har det varit en tid när du var mer social eller utåtriktad än normalt och då du t.ex. ringde till vänner mitt i natten?";
  Quiz[191].Text = "Undviker du att besöka offentliga toaletter?";
  Quiz[192].Text = "Kan andra känna av dina känslor när de inte är där?";
  Quiz[193].Text = "Gillar du att kasta saker som t.ex. stenar?";

  Quiz[194].Text = "Dyslexi";
  Quiz[195].Text = "Dyskaluli";
  Quiz[196].Text = "Dyspraxi";
  Quiz[197].Text = "Bipolär";
  Quiz[198].Text = "Social fobi";

  #endif

}

/*##########################################################################
#
#   Name       : TQuizN1::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::InitReferers()
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

/*##################  TQuizN1::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN1::LoadReferers()
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

		if (Row.OCD == 2)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyspraxia == 2)
			UpdateReferer(&DyspraxiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyslexia == 2)
			UpdateReferer(&DyslexiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyscalculia == 2)
			UpdateReferer(&DyscalculiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

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
#   Name       : TQuizN1::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::LoadPopulations()
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

//		Row.Quiz[182] = Row.Dyslexia + 1;
//		Row.Quiz[183] = Row.Dyscalculia + 1;
//		Row.Quiz[184] = Row.Dyspraxia + 1;
//		Row.Quiz[185] = Row.Bipolar + 1;
//		Row.Quiz[186] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 182)
				{
					score = Row.Quiz[i] - 1;
					id = IdArr[i];

					DsmAutism.Add(Row.Autism, id, score);
					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
					DsmDyspraxia.Add(Row.Dyspraxia, id, score);
					DsmDyslexia.Add(Row.Dyslexia, id, score);
					DsmDyscalculia.Add(Row.Dyscalculia, id, score);
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

		if (Row.OCD == 2)
			DxArr[DX_OCD] = DX_STATE_YES;

		if (Row.OCD == 1)
			DxArr[DX_OCD] = DX_STATE_SELF;

		if (Row.OCD == 0)
			DxArr[DX_OCD] = DX_STATE_NO;

		if (Row.Dyspraxia == 2)
			DxArr[DX_DYSPRAXIA] = DX_STATE_YES;

		if (Row.Dyspraxia == 1)
			DxArr[DX_DYSPRAXIA] = DX_STATE_SELF;

		if (Row.Dyspraxia == 0)
			DxArr[DX_DYSPRAXIA] = DX_STATE_NO;

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

		if (Row.Dyspraxia >= 1)
			Dyspraxia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dyslexia >= 1)
			Dyslexia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dyscalculia >= 1)
			Dyscalculia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

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
#   Name       : TQuizN1::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::SetupControlGroups()
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
#   Name       : TQuizN1::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12)
{
    DefineCross(QuizS12, 0, 0);
    DefineCross(QuizS12, 1, 1);
    DefineCross(QuizS12, 2, 2);
	DefineCross(QuizS12, 3, 3);
    DefineCross(QuizS12, 4, 4);
    DefineCross(QuizS12, 5, 5);
    DefineCross(QuizS12, 6, 6);
	DefineCross(QuizS12, 7, 7);
    DefineCross(QuizS12, 8, 8);
	DefineCross(QuizS12, 9, 9);
	DefineCross(QuizS12, 10, 10);
    DefineCross(QuizR2, 11, 140);
    DefineCross(QuizS12, 12, 11);
    DefineCross(QuizS12, 13, 12);
    DefineCross(QuizS12, 14, 13);
    DefineCross(QuizS12, 15, 14);
    DefineCross(QuizS12, 16, 15);
    DefineCross(QuizS12, 17, 16);
    DefineCross(QuizR2, 18, 39);
    DefineCross(QuizII, 19, 95);
    DefineCross(Quiz6, 20, 107);
    DefineCross(QuizS12, 21, 17);
    DefineCross(QuizR2, 22, 124);
    DefineCross(QuizS12, 23, 18);
    DefineCross(QuizS12, 24, 19);
    DefineCross(QuizS12, 25, 20);
    DefineCross(QuizS12, 26, 21);
    DefineCross(QuizS12, 27, 22);
    DefineCross(QuizS12, 28, 23);
    DefineCross(QuizS12, 29, 24);
    DefineCross(QuizS12, 30, 25);
    DefineCross(QuizS12, 31, 26);
    DefineCross(QuizR2, 32, 133);
    DefineCross(QuizS12, 33, 27);
    DefineCross(QuizS12, 34, 28);
    DefineCross(QuizS12, 35, 29);
    DefineCross(QuizS12, 36, 30);
    DefineCross(QuizS12, 37, 31);
    DefineCross(QuizS12, 38, 32);
    DefineCross(QuizS12, 39, 33);
	DefineCross(QuizS12, 40, 34);
    DefineCross(QuizS12, 41, 35);
    DefineCross(QuizII, 42, 65);
    DefineCross(QuizS12, 43, 36);
	DefineCross(QuizII, 44, 63);
    DefineCross(QuizS10, 45, 166);
	DefineCross(QuizS12, 46, 37);
	DefineCross(QuizNd, 47, 152);
    DefineCross(QuizS12, 48, 38);
    DefineCross(QuizS12, 49, 39);
    DefineCross(QuizS12, 50, 40);
    DefineCross(QuizS12, 51, 41);
    DefineCross(QuizR4, 52, 3);
    DefineCross(QuizS12, 53, 42);
    DefineCross(QuizS12, 54, 48);
    DefineCross(QuizS12, 55, 43);
    DefineCross(QuizS12, 56, 44);
    DefineCross(QuizS12, 57, 45);
    DefineCross(QuizS12, 58, 46);
    DefineCross(QuizS12, 59, 47);
    DefineCross(QuizS5, 60, 51);
    DefineCross(QuizS12, 61, 49);
    DefineCross(QuizS12, 62, 50);
    DefineCross(QuizS12, 63, 51);
    DefineCross(QuizS12, 64, 52);
    DefineCross(QuizS12, 65, 53);
    DefineCross(QuizS12, 66, 54);
    DefineCross(QuizS10, 67, 157);
    DefineCross(Quiz7, 68, 98);
    DefineCross(QuizS12, 69, 55);
    DefineCross(QuizS12, 70, 56);
    DefineCross(QuizS12, 71, 57);
    DefineCross(QuizS12, 72, 58);
    DefineCross(QuizS12, 73, 59);
    DefineCross(QuizS12, 74, 60);
    DefineCross(QuizS12, 75, 61);
    DefineCross(QuizS12, 76, 62);
	DefineCross(QuizS12, 77, 63);
    DefineCross(QuizS12, 78, 64);
    DefineCross(QuizS12, 79, 65);
    DefineCross(QuizS12, 80, 66);
	DefineCross(QuizS12, 81, 67);
    DefineCross(QuizS12, 82, 68);
	DefineCross(QuizS12, 83, 69);
	DefineCross(QuizS12, 84, 70);
    DefineCross(QuizS12, 85, 71);
    DefineCross(QuizS12, 86, 72);
    DefineCross(QuizS12, 87, 73);
    DefineCross(QuizS12, 88, 74);
    DefineCross(QuizS12, 89, 75);
    DefineCross(QuizR6, 90, 145);
    DefineCross(QuizR6, 91, 94);
    DefineCross(Quiz9, 92, 95);
    DefineCross(QuizS12, 93, 76);
    DefineCross(QuizS12, 94, 77);
    DefineCross(QuizS12, 95, 78);
    DefineCross(QuizS12, 96, 79);
    DefineCross(QuizS12, 97, 80);
    DefineCross(QuizS12, 98, 81);
    DefineCross(QuizS12, 99, 82);
    DefineCross(QuizS12, 100, 83);
    DefineCross(QuizS12, 101, 84);
    DefineCross(QuizS12, 102, 85);
    DefineCross(QuizS12, 103, 86);
    DefineCross(QuizR6, 104, 132);
    DefineCross(QuizNd, 105, 42);
    DefineCross(QuizR4, 106, 17);
    DefineCross(QuizS12, 107, 87);
    DefineCross(QuizS12, 108, 88);
    DefineCross(QuizS12, 109, 89);
    DefineCross(QuizS12, 110, 90);
    DefineCross(QuizR1, 111, 21);
    DefineCross(QuizS12, 112, 91);
    DefineCross(QuizS12, 113, 92);
	DefineCross(QuizS12, 114, 93);
    DefineCross(QuizS12, 115, 94);
    DefineCross(QuizS12, 116, 95);
    DefineCross(QuizS12, 117, 96);
	DefineCross(QuizS12, 118, 97);
    DefineCross(QuizS12, 119, 98);
	DefineCross(QuizS12, 120, 99);
	DefineCross(QuizS12, 121, 100);
    DefineCross(QuizS12, 122, 101);
    DefineCross(QuizS12, 123, 102);
    DefineCross(Quiz9, 124, 41);
    DefineCross(Quiz7, 125, 37);
    DefineCross(Quiz9, 126, 44);
    DefineCross(QuizNd, 127, 157);
    DefineCross(Quiz7, 128, 36);
    DefineCross(QuizS12, 129, 103);
    DefineCross(QuizS12, 130, 104);
    DefineCross(QuizR3, 131, 70);
    DefineCross(QuizS12, 132, 105);
    DefineCross(QuizS12, 133, 106);
    DefineCross(QuizS12, 134, 107);
    DefineCross(QuizS12, 135, 108);
    DefineCross(QuizS12, 136, 109);
    DefineCross(QuizR7, 137, 94);
    DefineCross(QuizS12, 138, 110);
    DefineCross(QuizS12, 139, 111);
    DefineCross(Quiz7, 140, 137);
    DefineCross(QuizR1, 141, 89);
    DefineCross(QuizS12, 142, 112);
    DefineCross(QuizS12, 143, 113);
    DefineCross(QuizS12, 144, 114);
    DefineCross(QuizS12, 145, 116);
    DefineCross(QuizS12, 146, 117);
    DefineCross(QuizS12, 147, 118);
    DefineCross(QuizR4, 148, 135);
    DefineCross(QuizS12, 149, 119);
    DefineCross(QuizS12, 150, 120);
	DefineCross(QuizS12, 151, 121);
    DefineCross(QuizS12, 152, 122);
    DefineCross(QuizS12, 153, 123);
    DefineCross(QuizS12, 154, 124);
	DefineCross(QuizS12, 155, 125);
    DefineCross(QuizS12, 156, 126);
	DefineCross(QuizS12, 157, 127);
	DefineCross(QuizS2, 158, 83);
    DefineCross(QuizS12, 159, 128);
    DefineCross(QuizS2, 160, 151);
    DefineCross(QuizR4, 161, 55);
    DefineCross(QuizS12, 162, 129);
    DefineCross(QuizS12, 163, 130);
    DefineCross(QuizS12, 164, 131);
    DefineCross(QuizS12, 165, 132);
    DefineCross(QuizS12, 166, 133);
    DefineCross(QuizS12, 167, 134);
    DefineCross(QuizS12, 168, 135);
    DefineCross(QuizS12, 169, 136);
    DefineCross(QuizR2, 170, 131);
    DefineCross(QuizS9, 171, 156);
    DefineCross(QuizS12, 172, 137);
    DefineCross(QuizS12, 173, 138);
    DefineCross(QuizS12, 174, 139);
    DefineCross(QuizS12, 175, 140);
	DefineCross(QuizS12, 176, 141);
	DefineCross(QuizR1, 177, 77);

	DefineGlobalId(178, 1151);
	DefineGlobalId(179, 1152);
	DefineGlobalId(180, 1153);
	DefineGlobalId(181, 1154);
	DefineGlobalId(182, 1155);
	DefineGlobalId(183, 1156);
	DefineGlobalId(184, 1157);
	DefineGlobalId(185, 1158);
	DefineGlobalId(186, 1159);
	DefineCross(QuizS10, 187, 154);
	DefineGlobalId(188, 1161);
	DefineGlobalId(189, 1162);
	DefineGlobalId(190, 1163);
	DefineGlobalId(191, 1164);
	DefineGlobalId(192, 1165);
	DefineGlobalId(193, 1166);

	DefineCross(QuizS12, 194, 182);
	DefineCross(QuizS12, 195, 183);
	DefineCross(QuizS12, 196, 184);
	DefineCross(QuizS12, 197, 185);
	DefineCross(QuizS12, 198, 186);
}

/*##########################################################################
#
#   Name       : TQuizN1::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN1::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizN1::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN1::ExportExcelCase(const char *filename, int PcaType)
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
                    
					sprintf(str, "%d", ival);
					file.Write(str);
					if (i != GetQuizN() - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizN1::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN1::ExportExcelAspie(const char *filename)
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

			sprintf(str, "%d", ival);
			file.Write(str);
			if (i != N - 1)
				file.Write(", ");
		}
		file.Write("\n");
	}
}

/*##################  TQuizN1::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN1::ExportExcelGroups(const char *filename)
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

/*##################  TQuizN1::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN1::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_MALE || PcaType == PCA_TYPE_FEMALE)
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


/*##################  TQuizN1::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN1::WriteRetest(const char *filename)
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
	long double QMean[194];
	long double AsSd;
	long double NtSd;
	long double QSd[194];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[194];
	int QCount[194];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[14][20];
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

	 for (q = 0; q < 194; q++)
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

						  for (q = 0; q < 14; q++)
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

								  for (q = 0; q < 14; q++)
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

					for (q = 0; q < 194; q++)
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

					 AsSd = sqrt(AsSum / index);
					NtSd = sqrt(NtSum / index);

					for (q = 0; q < 194; q++)
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
							 QSd[q] = sqrt(sum / count);

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

