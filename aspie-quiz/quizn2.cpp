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
# quizn2.cpp
# Quiz neurodiversity version 2 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizn2.h"
#include "file.h"
#include "quizdbn2.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizN2::TQuizN2
#
#   Purpose....: Constructor for TQuizN2
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizN2::TQuizN2(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1)
  : TQuiz(171),
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
	DefineCross(28, QuizN1);

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizN2::~TQuizN2
#
#   Purpose....: Destructor for TQuizN2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizN2::~TQuizN2()
{
}

/*##################  TQuizN2::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizN2::GetPcaCount()
{
	return 4;
}

/*##################  TQuizN2::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizN2::GetCatCount(int Question)
{
	if (Question < 161)
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
int TQuizN2::GetQuizN()
{
	return 161;
}

/*##########################################################################
#
#   Name       : TQuizN2::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::WriteName(TFile &File)
{
	 File.Write("N2");
}

/*##########################################################################
#
#   Name       : TQuizN2::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::WriteLongName(TFile &File)
{
	 File.Write("neurodiversity version 2");
}

/*##################  TQuizN2::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizN2::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::SetupTexts()
{
  Quiz[14].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[30].Reverse = TRUE;
  Quiz[31].Reverse = TRUE;
  Quiz[33].Reverse = TRUE;
  Quiz[34].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[90].Reverse = TRUE;
  Quiz[91].Reverse = TRUE;
  Quiz[92].Reverse = TRUE;
  Quiz[93].Reverse = TRUE;
  Quiz[94].Reverse = TRUE;
  Quiz[95].Reverse = TRUE;
  Quiz[96].Reverse = TRUE;
  Quiz[99].Reverse = TRUE;
  Quiz[150].Reverse = TRUE;
  Quiz[151].Reverse = TRUE;
  Quiz[152].Reverse = TRUE;
  Quiz[153].Reverse = TRUE;
  Quiz[154].Reverse = TRUE;
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

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_NT_NVC;
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
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_ACTIVITY;
  Quiz[19].MyGroup = GROUP_NT_TALENT;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[28].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[29].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[30].MyGroup = GROUP_NT_OBSESSION;
  Quiz[31].MyGroup = GROUP_NT_OBSESSION;
  Quiz[32].MyGroup = GROUP_NT_OBSESSION;
  Quiz[33].MyGroup = GROUP_NT_OBSESSION;
  Quiz[34].MyGroup = GROUP_NT_OBSESSION;
  Quiz[35].MyGroup = GROUP_ACTIVITY;
  Quiz[36].MyGroup = GROUP_ACTIVITY;
  Quiz[37].MyGroup = GROUP_ACTIVITY;
  Quiz[38].MyGroup = GROUP_ENVIRONMENT;
  Quiz[39].MyGroup = GROUP_ACTIVITY;
  Quiz[40].MyGroup = GROUP_ACTIVITY;
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
  Quiz[52].MyGroup = GROUP_NT_NVC;
  Quiz[53].MyGroup = GROUP_SOCIAL;
  Quiz[54].MyGroup = GROUP_SOCIAL;
  Quiz[55].MyGroup = GROUP_SOCIAL;
  Quiz[56].MyGroup = GROUP_SOCIAL;
  Quiz[57].MyGroup = GROUP_SOCIAL;
  Quiz[58].MyGroup = GROUP_SOCIAL;
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
  Quiz[95].MyGroup = GROUP_SEX;
  Quiz[96].MyGroup = GROUP_NT_NVC;
  Quiz[97].MyGroup = GROUP_NT_NVC;
  Quiz[98].MyGroup = GROUP_NT_NVC;
  Quiz[99].MyGroup = GROUP_SEX;
  Quiz[100].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[101].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[102].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[103].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[104].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[105].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[106].MyGroup = GROUP_NT_HUNTING;
  Quiz[107].MyGroup = GROUP_NT_HUNTING;
  Quiz[108].MyGroup = GROUP_NT_HUNTING;
  Quiz[109].MyGroup = GROUP_NT_HUNTING;
  Quiz[110].MyGroup = GROUP_NT_HUNTING;
  Quiz[111].MyGroup = GROUP_NT_HUNTING;
  Quiz[112].MyGroup = GROUP_NT_HUNTING;
  Quiz[113].MyGroup = GROUP_NT_HUNTING;
  Quiz[114].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[115].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[116].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[117].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[118].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[119].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[120].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[121].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[122].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[123].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[124].MyGroup = GROUP_NT_SENSORY;
  Quiz[125].MyGroup = GROUP_NT_SENSORY;
  Quiz[126].MyGroup = GROUP_NT_SENSORY;
  Quiz[127].MyGroup = GROUP_NT_SENSORY;
  Quiz[128].MyGroup = GROUP_NT_SENSORY;
  Quiz[129].MyGroup = GROUP_NT_SENSORY;
  Quiz[130].MyGroup = GROUP_NT_SENSORY;
  Quiz[131].MyGroup = GROUP_NT_SENSORY;
  Quiz[132].MyGroup = GROUP_ENVIRONMENT;
  Quiz[133].MyGroup = GROUP_ENVIRONMENT;
  Quiz[134].MyGroup = GROUP_ENVIRONMENT;
  Quiz[135].MyGroup = GROUP_ENVIRONMENT;
  Quiz[136].MyGroup = GROUP_ENVIRONMENT;
  Quiz[137].MyGroup = GROUP_ENVIRONMENT;
  Quiz[138].MyGroup = GROUP_MIXED;
  Quiz[139].MyGroup = GROUP_NT_NVC;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_MIXED;
  Quiz[143].MyGroup = GROUP_MIXED;
  Quiz[144].MyGroup = GROUP_MIXED;
  Quiz[145].MyGroup = GROUP_MIXED;
  Quiz[146].MyGroup = GROUP_MIXED;
  Quiz[147].MyGroup = GROUP_MIXED;
  Quiz[148].MyGroup = GROUP_MIXED;
  Quiz[149].MyGroup = GROUP_MIXED;
  Quiz[150].MyGroup = GROUP_NT_TALENT;
  Quiz[151].MyGroup = GROUP_SOCIAL;
  Quiz[152].MyGroup = GROUP_NT_NVC;
  Quiz[153].MyGroup = GROUP_NT_SENSORY;
  Quiz[154].MyGroup = GROUP_ENVIRONMENT;
  Quiz[155].MyGroup = GROUP_SEX;
  Quiz[156].MyGroup = GROUP_SEX;
  Quiz[157].MyGroup = GROUP_SEX;
  Quiz[158].MyGroup = GROUP_SEX;
  Quiz[159].MyGroup = GROUP_SOCIAL;
  Quiz[160].MyGroup = GROUP_SEX;

  Quiz[161].MyGroup = GROUP_NT_NVC;
  Quiz[162].MyGroup = GROUP_NT_NVC;
  Quiz[163].MyGroup = GROUP_NT_NVC;
  Quiz[164].MyGroup = GROUP_NT_NVC;
  Quiz[165].MyGroup = GROUP_NT_NVC;
  Quiz[166].MyGroup = GROUP_NT_NVC;
  Quiz[167].MyGroup = GROUP_NT_NVC;
  Quiz[168].MyGroup = GROUP_NT_NVC;
  Quiz[169].MyGroup = GROUP_NT_NVC;
  Quiz[170].MyGroup = GROUP_NT_NVC;

#ifdef ENGLISH

  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[2].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[3].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[4].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[5].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[6].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[7].Text = "Do you notice patterns in things all the time?";
  Quiz[8].Text = "Do you need periods of contemplation?";
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
  Quiz[19].Text = "Are you a slow reader?";
  Quiz[20].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[21].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[22].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[23].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[24].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[25].Text = "Do you have certain routines which you need to follow?";
  Quiz[26].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[27].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[28].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[29].Text = "Are you punctual, conscientious and perfectionist?";
  Quiz[30].Text = "Do you enjoy meeting new people?";
  Quiz[31].Text = "Are your views typical of your peer group?";
  Quiz[32].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[33].Text = "Do you take pride in your appearance?";
  Quiz[34].Text = "Do you enjoy gossip?";
  Quiz[35].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[36].Text = "Do you have problems starting and / or finishing projects?";
  Quiz[37].Text = "Are you easily distracted?";
  Quiz[38].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[39].Text = "Are you poor at organizing your work and / or life?";
  Quiz[40].Text = "Are you or have you been hyperactive?";
  Quiz[41].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[42].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[43].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[44].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[45].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[46].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[47].Text = "Do people think you are aloof and distant?";
  Quiz[48].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[49].Text = "Do you dislike shaking hands?";
  Quiz[50].Text = "Do you feel uncomfortable with strangers?";
  Quiz[51].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[52].Text = "Do you find it easy to describe your feelings?";
  Quiz[53].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[54].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[55].Text = "Do you dislike reading aloud?";
  Quiz[56].Text = "Do you have trouble resisting a high pressure sales person?";
  Quiz[57].Text = "Are you self-centered?";
  Quiz[58].Text = "Do you like to speak in public?";
  Quiz[59].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[60].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[61].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[62].Text = "Do you often don't know where to put your arms?";
  Quiz[63].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[64].Text = "Have you been accused of staring?";
  Quiz[65].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[66].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[67].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[68].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[69].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[70].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[71].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[72].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[73].Text = "Do you fiddle with things?";
  Quiz[74].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[75].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[76].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[77].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[78].Text = "Do you stutter when stressed?";
  Quiz[79].Text = "Do you talk to yourself?";
  Quiz[80].Text = "Do you have difficulties with pronunciation?";
  Quiz[81].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[82].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[83].Text = "Do others often misunderstand you?";
  Quiz[84].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[85].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[86].Text = "Do you find it difficult to work out people's intentions?";
  Quiz[87].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[88].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[89].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[90].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[91].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[92].Text = "Do you know when you are expected to offer an apology?";
  Quiz[93].Text = "Are you good at interpreting facial expressions?";
  Quiz[94].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[95].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[96].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[97].Text = "Are you so honest and sincere yourself that you assume everyone is?";
  Quiz[98].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[99].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[100].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[101].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[102].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[103].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[104].Text = "Do you enjoy walking on your toes?";
  Quiz[105].Text = "Have you been fascinated about making traps?";
  Quiz[106].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[107].Text = "Do you drop things when your attention is on other things?";
  Quiz[108].Text = "Do you have problems filling out forms?";
  Quiz[109].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[110].Text = "Do you mix up dates and times and miss appointments?";
  Quiz[111].Text = "Do you mix up digits in numbers like 95 and 59?";
  Quiz[112].Text = "Do you have trouble reading clocks?";
  Quiz[113].Text = "Do you often make spelling errors?";
  Quiz[114].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[115].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[116].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[117].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[118].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[119].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[120].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[121].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[122].Text = "Does it come more natural to you to think in pictures than in words?";
  Quiz[123].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[124].Text = "Do you have problems with ball sports?";
  Quiz[125].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[126].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[127].Text = "Do you have poor concept of time?";
  Quiz[128].Text = "Do you find it hard to tell the age of people?";
  Quiz[129].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[130].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
  Quiz[131].Text = "Do you have problems finding your way to new places?";
  Quiz[132].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[133].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[134].Text = "Are you sometimes afraid in safe situations?";
  Quiz[135].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[136].Text = "Are you prone to getting depressions?";
  Quiz[137].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[138].Text = "Do you often feel out-of-sync with others?";
  Quiz[139].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[140].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[141].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[142].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[143].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[144].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[145].Text = "Do you have immature interests?";
  Quiz[146].Text = "Do you turn words around in conversations?";
  Quiz[147].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[148].Text = "Do you have phobias?";
  Quiz[149].Text = "Is your writing difficult to read?";
  Quiz[150].Text = "Can you easily remember verbal instructions?";
  Quiz[151].Text = "Are you good at teamwork?";
  Quiz[152].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[153].Text = "Do you find it easy to estimate the age of people?";
  Quiz[154].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[155].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[156].Text = "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?";
  Quiz[157].Text = "Are you fairly insensitive to physical pain, or even enjoy some types of pain?";
  Quiz[158].Text = "Do you have unusual sexual preferences?";
  Quiz[159].Text = "Are you asexual?";
  Quiz[160].Text = "If you were single, would you find casual sex (one-night stands) rewarding?";

  Quiz[161].Text = "Flirt rating - Jay Feierman #3";
  Quiz[162].Text = "Flirt rating - Heather Kuzmich #2";
  Quiz[163].Text = "Flirt rating - Jay Feierman #9";
  Quiz[164].Text = "Flirt rating - Flirt #1";
  Quiz[165].Text = "Flirt rating - Jay Feierman #12";
  Quiz[166].Text = "Flirt rating - Jay Feierman #24";
  Quiz[167].Text = "Flirt rating - Heather Kuzmich #1";
  Quiz[168].Text = "Flirt rating - Jay Feierman #28";
  Quiz[169].Text = "Flirt rating - Jay Feierman #31";
  Quiz[170].Text = "Flirt rating - Jay Feierman #41";
            	
#endif

#ifdef SWEDISH

  Quiz[0].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[1].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[2].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[3].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[4].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[5].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[6].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[7].Text = "Ser du mönster i saker hela tiden?";
  Quiz[8].Text = "Behöver du perioder av begrundande?";
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
  Quiz[19].Text = "Läser du sakta?";
  Quiz[20].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[21].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[22].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[23].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[24].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[25].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[26].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[27].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[28].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[29].Text = "Är du punktlig, noggrann och/eller perfektionistisk?";
  Quiz[30].Text = "Trivs du med att möta nya människor?";
  Quiz[31].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[32].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[33].Text = "Är du stolt över ditt utseende?";
  Quiz[34].Text = "Tycker du om skvaller?";
  Quiz[35].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[36].Text = "Har du problem att starta och / eller slutföra projekt?";
  Quiz[37].Text = "Blir du lätt distraherad?";
  Quiz[38].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[39].Text = "Är du dålig på att organisera ditt arbete och / eller liv?";
  Quiz[40].Text = "Är du eller har du varit hyperaktiv";
  Quiz[41].Text = "Låser det sig för dig när du får frågor i sociala situationer?";
  Quiz[42].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[43].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[44].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[45].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[46].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[47].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[48].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[49].Text = "Ogillar du att behöva ta i hand?";
  Quiz[50].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[51].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[52].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[53].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[54].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[55].Text = "Ogillar du högläsning?";
  Quiz[56].Text = "Har du problem att stå emot en påstridig försäljare?";
  Quiz[57].Text = "Är du självcentrerad?";
  Quiz[58].Text = "Tycker du om att tala offentligt?";
  Quiz[59].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[60].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[61].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[62].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[63].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[64].Text = "Har du blivit anklagad för att stirra?";
  Quiz[65].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[66].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[67].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[68].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[69].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[70].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[71].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[72].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[73].Text = "Brukar du fingra på saker?";
  Quiz[74].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[75].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[76].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[77].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[78].Text = "Stammar du när du blir stressad?";
  Quiz[79].Text = "Brukar du prata med dig själv?";
  Quiz[80].Text = "Har du svårigheter med uttal?";
  Quiz[81].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
  Quiz[82].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[83].Text = "Blir du ofta missförstådd av andra?";
  Quiz[84].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[85].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[86].Text = "Har du svårt att räkna ut folks intentioner?";
  Quiz[87].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[88].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[89].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[90].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[91].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[92].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[93].Text = "Är du bra på att tolka ansiktsuttryck?";
  Quiz[94].Text = "Trivs du i romantiska situationer?";
  Quiz[95].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[96].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[97].Text = "Är det så naturligt för dig att vara totalt ärlig att du tror alla är sådana?";
  Quiz[98].Text = "Har du svårt att känna igen ansikten?";
  Quiz[99].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[100].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[101].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[102].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[103].Text = "Gillar du att härma djurläten?";
  Quiz[104].Text = "Gillar du att gå på tå?";
  Quiz[105].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[106].Text = "Tycker du det är svårt att ta meddelenden på telefon och skicka dem vidare rätt?'";
  Quiz[107].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[108].Text = "Har du svårt att fylla i formulär?";
  Quiz[109].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[110].Text = "Blandar du ihop tider och datum och missar möten?";
  Quiz[111].Text = "Blandar du ihop siffor i tal som t.ex. 95 och 59?";
  Quiz[112].Text = "Har du svårigheter att läsa av klockor?";
  Quiz[113].Text = "Gör du ofta stavfel?";
  Quiz[114].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[115].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[116].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[117].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[118].Text = "Är du känslig för omslag i luftryck och luftfuktighet?";
  Quiz[119].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[120].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[121].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[122].Text = "Är det mer naturligt för dig att tänka i bilder än i ord?";
  Quiz[123].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[124].Text = "Har du problem med med bollsporter?";
  Quiz[125].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[126].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[127].Text = "Har du dålig tidsuppfattning?";
  Quiz[128].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[129].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[130].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[131].Text = "Har du svårt att hitta till nya platser?";
  Quiz[132].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[133].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[134].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[135].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[136].Text = "Brukar du få depressioner?";
  Quiz[137].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[138].Text = "Känner du dig ofta ur fas med andra?";
  Quiz[139].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[140].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[141].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[142].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[143].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[144].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[145].Text = "Har du omogna intressen?";
  Quiz[146].Text = "Blandar du om ord i konversationer?";
  Quiz[147].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[148].Text = "Har du fobier?";
  Quiz[149].Text = "Är det svårt att läsa vad du skrivit?";
  Quiz[150].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[151].Text = "Är du bra på att arbeta i grupp?";
  Quiz[152].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[153].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[154].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[155].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet?";
  Quiz[156].Text = "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?";
  Quiz[157].Text = "Är du okänslig för smärta eller till och med tycker om viss sorts smärta?";
  Quiz[158].Text = "Har du ovanliga sexuella preferenser?";
  Quiz[159].Text = "Är du asexuell?";
  Quiz[160].Text = "Om du var singel, skulle du tycka att tillfälliga sexuella kontakter vore givande?";

  Quiz[161].Text = "Fl”rt - Jay Feierman #3";
  Quiz[162].Text = "Fl”rt - Heather Kuzmich #2";
  Quiz[163].Text = "Fl”rt - Jay Feierman #9";
  Quiz[164].Text = "Fl”rt - Flirt #1";
  Quiz[165].Text = "Fl”rt - Jay Feierman #12";
  Quiz[166].Text = "Fl”rt - Jay Feierman #24";
  Quiz[167].Text = "Fl”rt - Heather Kuzmich #1";
  Quiz[168].Text = "Fl”rt - Jay Feierman #28";
  Quiz[169].Text = "Fl”rt - Jay Feierman #31";
  Quiz[170].Text = "Fl”rt - Jay Feierman #41";

#endif

}

/*##########################################################################
#
#   Name       : TQuizN2::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::InitReferers()
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

/*##################  TQuizN2::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::LoadReferers()
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

		if (Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD >= 1)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Dyslexia >= 1)
			UpdateReferer(&DyslexiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Bipolar >= 1)
			UpdateReferer(&BipolarRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Social >= 1)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie)
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
#   Name       : TQuizN2::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::LoadPopulations()
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

					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
					DsmDyslexia.Add(Row.Dyslexia, id, score);
					DsmBipolar.Add(Row.Bipolar, id, score);
					DsmSocialPhobia.Add(Row.Social, id, score);
				}
			}
		}

		for (i = 0; i < DX_COUNT; i++)
			DxArr[i] = DX_STATE_UNKNOWN;

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

		if (Row.Dyslexia == 2)
			DxArr[DX_DYSLEXIA] = DX_STATE_YES;

		if (Row.Dyslexia == 1)
			DxArr[DX_DYSLEXIA] = DX_STATE_SELF;

		if (Row.Dyslexia == 0)
			DxArr[DX_DYSLEXIA] = DX_STATE_NO;

		if (Row.Bipolar == 2)
			DxArr[DX_BIPOLAR] = DX_STATE_YES;

		if (Row.Bipolar == 1)
			DxArr[DX_BIPOLAR] = DX_STATE_SELF;

		if (Row.Bipolar == 0)
			DxArr[DX_BIPOLAR] = DX_STATE_NO;

		if (Row.Social == 2)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_YES;

		if (Row.Social == 1)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_SELF;

		if (Row.Social == 0)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_NO;

		All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Aspie)
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

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

			if (Row.Aspie == 1)
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

		if (Row.Dyslexia >= 1)
			Dyslexia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Bipolar >= 1)
			Bipolar.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

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
#   Name       : TQuizN2::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::SetupControlGroups()
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
#   Name       : TQuizN2::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1)
{
    DefineCross(QuizN1, 0, 0);
    DefineCross(QuizN1, 1, 1);
    DefineCross(QuizN1, 2, 3);
    DefineCross(QuizN1, 3, 4);
    DefineCross(QuizN1, 4, 6);
    DefineCross(QuizN1, 5, 5);
    DefineCross(QuizN1, 6, 7);
    DefineCross(QuizN1, 7, 8);
    DefineCross(QuizN1, 8, 179);
    DefineCross(QuizN1, 9, 9);
    DefineCross(QuizN1, 10, 10);
    DefineCross(QuizN1, 11, 11);
    DefineCross(QuizN1, 12, 12);
    DefineCross(QuizN1, 13, 13);
    DefineCross(QuizN1, 14, 14);
    DefineCross(QuizN1, 15, 15);
    DefineCross(QuizN1, 16, 16);
    DefineCross(QuizN1, 17, 17);
    DefineCross(QuizN1, 18, 18);
    DefineCross(QuizN1, 19, 20);
    DefineCross(QuizN1, 20, 21);
    DefineCross(QuizN1, 21, 23);
    DefineCross(QuizN1, 22, 24);
    DefineCross(QuizN1, 23, 25);
    DefineCross(QuizN1, 24, 26);
    DefineCross(QuizN1, 25, 27);
    DefineCross(QuizN1, 26, 28);
    DefineCross(QuizN1, 27, 30);
    DefineCross(QuizN1, 28, 31);
    DefineCross(QuizN1, 29, 32);
    DefineCross(QuizN1, 30, 33);
    DefineCross(QuizN1, 31, 34);
    DefineCross(QuizN1, 32, 35);
    DefineCross(QuizN1, 33, 37);
    DefineCross(QuizN1, 34, 38);
    DefineCross(QuizN1, 35, 39);
    DefineCross(QuizN1, 36, 41);
    DefineCross(QuizN1, 37, 40);
    DefineCross(QuizN1, 38, 43);
    DefineCross(QuizN1, 39, 45);
    DefineCross(QuizN1, 40, 46);
    DefineCross(QuizN1, 41, 48);
    DefineCross(QuizN1, 42, 49);
    DefineCross(QuizN1, 43, 50);
    DefineCross(QuizN1, 44, 51);
    DefineCross(QuizN1, 45, 54);
    DefineCross(QuizN1, 46, 55);
    DefineCross(QuizN1, 47, 56);
    DefineCross(QuizN1, 48, 57);
    DefineCross(QuizN1, 49, 59);
    DefineCross(QuizN1, 50, 60);
    DefineCross(QuizN1, 51, 61);
    DefineCross(QuizN1, 52, 62);
    DefineCross(QuizN1, 53, 63);
    DefineCross(QuizN1, 54, 64);
    DefineCross(QuizN1, 55, 66);
    DefineCross(QuizN1, 56, 183);
    DefineCross(QuizN1, 57, 67);
    DefineCross(QuizN1, 58, 68);
    DefineCross(QuizN1, 59, 69);
    DefineCross(QuizN1, 60, 70);
    DefineCross(QuizN1, 61, 71);
    DefineCross(QuizN1, 62, 72);
    DefineCross(QuizN1, 63, 73);
    DefineCross(QuizN1, 64, 74);
    DefineCross(QuizN1, 65, 75);
    DefineCross(QuizN1, 66, 76);
    DefineCross(QuizN1, 67, 77);
    DefineCross(QuizN1, 68, 78);
    DefineCross(QuizN1, 69, 79);
    DefineCross(QuizN1, 70, 81);
    DefineCross(QuizN1, 71, 80);
    DefineCross(QuizN1, 72, 82);
    DefineCross(QuizN1, 73, 83);
    DefineCross(QuizN1, 74, 84);
    DefineCross(QuizN1, 75, 85);
    DefineCross(QuizN1, 76, 86);
    DefineCross(QuizN1, 77, 87);
    DefineCross(QuizN1, 78, 88);
    DefineCross(QuizN1, 79, 89);
    DefineCross(QuizN1, 80, 90);
    DefineCross(QuizN1, 81, 91);
    DefineCross(QuizN1, 82, 93);
    DefineCross(QuizN1, 83, 94);
    DefineCross(QuizN1, 84, 95);
    DefineCross(QuizN1, 85, 96);
    DefineCross(QuizN1, 86, 186);
    DefineCross(QuizN1, 87, 97);
    DefineCross(QuizN1, 88, 98);
    DefineCross(QuizN1, 89, 100);
    DefineCross(QuizN1, 90, 58);
    DefineCross(QuizN1, 91, 101);
    DefineCross(QuizN1, 92, 102);
    DefineCross(QuizN1, 93, 104);
    DefineCross(QuizN1, 94, 103);
    DefineCross(QuizN1, 95, 107);
    DefineCross(QuizN1, 96, 108);
    DefineCross(QuizN1, 97, 105);
    DefineCross(QuizN1, 98, 110);
    DefineCross(QuizN1, 99, 109);
    DefineCross(QuizN1, 100, 112);
    DefineCross(QuizN1, 101, 113);
    DefineCross(QuizN1, 102, 114);
    DefineCross(QuizN1, 103, 116);
    DefineCross(QuizN1, 104, 115);
    DefineCross(QuizN1, 105, 117);
    DefineCross(QuizN1, 106, 118);
    DefineCross(QuizN1, 107, 119);
    DefineCross(QuizN1, 108, 120);
    DefineCross(QuizN1, 109, 121);
    DefineCross(QuizN1, 110, 122);
    DefineCross(QuizN1, 111, 123);
    DefineCross(QuizN1, 112, 124);
    DefineCross(QuizN1, 113, 126);
    DefineCross(QuizN1, 114, 129);
    DefineCross(QuizN1, 115, 130);
    DefineCross(QuizN1, 116, 132);
    DefineCross(QuizN1, 117, 133);
    DefineCross(QuizN1, 118, 131);
    DefineCross(QuizN1, 119, 134);
    DefineCross(QuizN1, 120, 135);
    DefineCross(QuizN1, 121, 136);
    DefineCross(QuizN1, 122, 137);
    DefineCross(QuizN1, 123, 138);
    DefineCross(QuizN1, 124, 141);
    DefineCross(QuizN1, 125, 142);
    DefineCross(QuizN1, 126, 143);
    DefineCross(QuizN1, 127, 144);
    DefineCross(QuizN1, 128, 146);
    DefineCross(QuizN1, 129, 145);
    DefineCross(QuizN1, 130, 148);
    DefineCross(QuizN1, 131, 149);
    DefineCross(QuizN1, 132, 153);
    DefineCross(QuizN1, 133, 155);
    DefineCross(QuizN1, 134, 156);
    DefineCross(QuizN1, 135, 157);
    DefineCross(QuizN1, 136, 158);
    DefineCross(QuizN1, 137, 159);
    DefineCross(QuizN1, 138, 178);
    DefineCross(QuizN1, 139, 162);
    DefineCross(QuizN1, 140, 163);
    DefineCross(QuizN1, 141, 164);
    DefineCross(QuizN1, 142, 165);
    DefineCross(QuizN1, 143, 168);
    DefineCross(QuizN1, 144, 166);
    DefineCross(QuizN1, 145, 167);
    DefineCross(QuizN1, 146, 187);
    DefineCross(QuizN1, 147, 169);
    DefineCross(QuizN1, 148, 170);
    DefineCross(QuizN1, 149, 184);
    DefineCross(QuizN1, 150, 176);
    DefineCross(QuizN1, 151, 172);
    DefineCross(QuizN1, 152, 173);
    DefineCross(QuizN1, 153, 174);
    DefineCross(QuizN1, 154, 175);
    DefineCross(QuizR6, 155, 70);
    DefineCross(QuizR4, 156, 8);
    DefineCross(QuizR1, 157, 84);
    DefineCross(Quiz9, 158, 120);
    DefineCross(QuizR2, 159, 73);

    DefineGlobalId(160, 1167);

    DefineGlobalId(161, 1168);
    DefineGlobalId(162, 1169);
    DefineGlobalId(163, 1170);
    DefineGlobalId(164, 1171);
    DefineGlobalId(165, 1172);
    DefineGlobalId(166, 1173);
    DefineGlobalId(167, 1174);
    DefineGlobalId(168, 1175);
    DefineGlobalId(169, 1176);
    DefineGlobalId(170, 1177);
}

/*##########################################################################
#
#   Name       : TQuizN2::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizN2::GetReferer(const char *referer, TPopulation *pop)
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
				if (row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizN2::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizN2::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::ExportExcelAspie(const char *filename)
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

/*##################  TQuizN2::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::ExportExcelGroups(const char *filename)
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

/*##################  TQuizN2::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_MALE)
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

/*##################  TQuizN2::WritePictureRating ##########################
*   Purpose....: Write picture rating report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::WritePictureRating(const char *filename)
{
	int NtRateCount[10];
	long double NtRateSum[10];
	long double NtRateMean[10];
	long double NtRateSd[10];
	int AsRateCount[10];
	long double AsRateSum[10];
	long double AsRateMean[10];
	long double AsRateSd[10];
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

		NtRateCount[i] = 0;
		NtRateSum[i] = 0;

		UseMale[i] = TRUE;
		UseFemale[i] = TRUE;
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
	    				AsRateSum[i] += Row.Rating[i] - 1;
		    		}
			    	else
				    {
    					NtRateCount[i]++;
	    				NtRateSum[i] += Row.Rating[i] - 1;
		    		}
    			}
	        }
		}
	}

	for (i = 0; i < 10; i++)
	{
		AsRateMean[i] = AsRateSum[i] / AsRateCount[i];
		NtRateMean[i] = NtRateSum[i] / NtRateCount[i];
	}

	for (i = 0; i < 10; i++)
	{
		AsRateCount[i] = 0;
		AsRateSum[i] = 0;

		NtRateCount[i] = 0;
		NtRateSum[i] = 0;
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
			}
		}
	}

	for (i = 0; i < 10; i++)
	{
		AsRateSd[i] = sqrtl(AsRateSum[i] / ((long double)AsRateCount[i] - 1));
		NtRateSd[i] = sqrtl(NtRateSum[i] / ((long double)NtRateCount[i] - 1));
	}

	file.Write("<h3>Video rating</h3>");

	sprintf(str, "AS rate count: %d<br>", AsRateCount[0]);
	file.Write(str);

	sprintf(str, "NT rate count: %d<br>", NtRateCount[0]);
	file.Write(str);

	file.Write("<br>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Video");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Rating (AS/NT)");
	WriteFieldFooter(file);

	file.Write("</tr>");

    for (i = 0; i < 10; i++)
    {
    	file.Write("<tr style='height:24.75pt'>");

	    WriteCenteredFieldHeader(file, 25);
	    switch (i)
	    {
	        case 0:
				file.Write("<a href=\"http://www.rdos.net/flv/fem3.swf\">Jay Feierman #3</a>");
				break;

			case 1:
				file.Write("<a href=\"http://www.rdos.net/flv/hk2.swf\">Heather Kuzmich #2</a>");
				break;

			case 2:
				file.Write("<a href=\"http://www.rdos.net/flv/fem9.swf\">Jay Feierman #9</a>");
				break;

			case 3:
				file.Write("<a href=\"http://www.rdos.net/flv/flirt1.swf\">Flirt #1</a>");
				break;

			case 4:
				file.Write("<a href=\"http://www.rdos.net/flv/fem12.swf\">Jay Feierman #12</a>");
				break;

			case 5:
				file.Write("<a href=\"http://www.rdos.net/flv/fem24.swf\">Jay Feierman #24</a>");
				break;

			case 6:
				file.Write("<a href=\"http://www.rdos.net/flv/hk1.swf\">Heather Kuzmich #1</a>");
				break;

			case 7:
				file.Write("<a href=\"http://www.rdos.net/flv/fem28.swf\">Jay Feierman #28</a>");
				break;

			case 8:
				file.Write("<a href=\"http://www.rdos.net/flv/fem31.swf\">Jay Feierman #31</a>");
				break;

			case 9:
				file.Write("<a href=\"http://www.rdos.net/flv/fem41.swf\">Jay Feierman #41</a>");
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


    	file.Write("</tr>");
    }
	file.Write("</table>");
   	
}

/*##################  TQuizN2::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizN2::WriteRetest(const char *filename)
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
	long double QMean[161];
	long double AsSd;
	long double NtSd;
	long double QSd[161];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[161];
	int QCount[161];
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

	 for (q = 0; q < 161; q++)
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

					for (q = 0; q < 161; q++)
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

					for (q = 0; q < 161; q++)
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

	for (q = 0; q < 161; q++)
	{
		 sprintf(str, "%d. ", q + 1);
		 file.Write(str);

		file.Write(Quiz[q].Text);

		if (QCount[q])
			sd = QTot[q] / QCount[q];
		else
			sd = 0;

		  sprintf(str, " <b>%3.2Lf</b><br>", sd);
		file.Write(str);
	 }
}

