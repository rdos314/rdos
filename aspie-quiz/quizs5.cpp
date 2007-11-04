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
# quizs5.cpp
# Quiz stable release 5 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs5.h"
#include "file.h"
#include "quizdbs5.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

class TRace
{
public:
	TRace();
	void Add(TQuizRow *Row);
	void WriteUsRow(TFile &file, int index, const char *text);
	void WriteNonUsRow(TFile &file, int index, const char *text);
	void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);

	int UsCount[10];
	int UsAsCount[10];
	int NonUsCount[10];
	int NonUsAsCount[10];
};

/*##########################################################################
#
#   Name       : TQuizS5::TQuizS5
#
#   Purpose....: Constructor for TQuizS5
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS5::TQuizS5(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4)
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS5::~TQuizS5
#
#   Purpose....: Destructor for TQuizS5
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS5::~TQuizS5()
{
}

/*##################  TQuizS5::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS5::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS5::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS5::GetCatCount(int Question)
{
    if (Question <= 177)
        return 3;
    else
        return 5;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS5::GetQuizN()
{
	return 171;
}

/*##########################################################################
#
#   Name       : TQuizS5::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS5::WriteName(TFile &File)
{
	 File.Write("S5");
}

/*##################  TQuizS5::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS5::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS5::SetupTexts()
{
  Quiz[31].Reverse = TRUE;
  Quiz[50].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[62].Reverse = TRUE;
  Quiz[91].Reverse = TRUE;
  Quiz[92].Reverse = TRUE;
  Quiz[93].Reverse = TRUE;
  Quiz[95].Reverse = TRUE;
  Quiz[96].Reverse = TRUE;
  Quiz[97].Reverse = TRUE;
  Quiz[98].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;
  Quiz[140].Reverse = TRUE;
  Quiz[141].Reverse = TRUE;
  Quiz[142].Reverse = TRUE;
  Quiz[178].Reverse = TRUE;
  Quiz[179].Reverse = TRUE;
  Quiz[180].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_NT_HUNTING;
  Quiz[1].MyGroup = GROUP_NT_HUNTING;
  Quiz[2].MyGroup = GROUP_NT_HUNTING;
  Quiz[3].MyGroup = GROUP_NT_HUNTING;
  Quiz[4].MyGroup = GROUP_NT_HUNTING;
  Quiz[5].MyGroup = GROUP_NT_HUNTING;
  Quiz[6].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[7].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[8].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[9].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[10].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[11].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[12].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[13].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[14].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[15].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[16].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[17].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[18].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[19].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[20].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[21].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[24].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[25].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[26].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[27].MyGroup = GROUP_NT_TALENT;
  Quiz[28].MyGroup = GROUP_NT_TALENT;
  Quiz[29].MyGroup = GROUP_NT_TALENT;
  Quiz[30].MyGroup = GROUP_NT_TALENT;
  Quiz[31].MyGroup = GROUP_NT_TALENT;
  Quiz[32].MyGroup = GROUP_NT_TALENT;
  Quiz[33].MyGroup = GROUP_NT_TALENT;
  Quiz[34].MyGroup = GROUP_NT_TALENT;
  Quiz[35].MyGroup = GROUP_NT_TALENT;
  Quiz[36].MyGroup = GROUP_NT_TALENT;
  Quiz[37].MyGroup = GROUP_NT_TALENT;
  Quiz[38].MyGroup = GROUP_NT_SOCIAL;
  Quiz[39].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[40].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[42].MyGroup = GROUP_MIXED;
  Quiz[43].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[44].MyGroup = GROUP_NT_SOCIAL;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_NT_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[48].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[54].MyGroup = GROUP_NT_OBSESSION;
  Quiz[55].MyGroup = GROUP_NT_SOCIAL;
  Quiz[56].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[62].MyGroup = GROUP_NT_SOCIAL;
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
  Quiz[82].MyGroup = GROUP_ASPIE_NVC;
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
  Quiz[93].MyGroup = GROUP_NT_SOCIAL;
  Quiz[94].MyGroup = GROUP_NT_NVC;
  Quiz[95].MyGroup = GROUP_NT_NVC;
  Quiz[96].MyGroup = GROUP_NT_SOCIAL;
  Quiz[97].MyGroup = GROUP_NT_NVC;
  Quiz[98].MyGroup = GROUP_NT_NVC;
  Quiz[99].MyGroup = GROUP_NT_NVC;
  Quiz[100].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[101].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[102].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[103].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[104].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[105].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[106].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[107].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[108].MyGroup = GROUP_ENVIRONMENT;
  Quiz[109].MyGroup = GROUP_ENVIRONMENT;
  Quiz[110].MyGroup = GROUP_ENVIRONMENT;
  Quiz[111].MyGroup = GROUP_ENVIRONMENT;
  Quiz[112].MyGroup = GROUP_ENVIRONMENT;
  Quiz[113].MyGroup = GROUP_ENVIRONMENT;
  Quiz[114].MyGroup = GROUP_ENVIRONMENT;
  Quiz[115].MyGroup = GROUP_ENVIRONMENT;
  Quiz[116].MyGroup = GROUP_MIXED;
  Quiz[117].MyGroup = GROUP_MIXED;
  Quiz[118].MyGroup = GROUP_MIXED;
  Quiz[119].MyGroup = GROUP_MIXED;
  Quiz[120].MyGroup = GROUP_MIXED;
  Quiz[121].MyGroup = GROUP_MIXED;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[124].MyGroup = GROUP_PARANOID;
  Quiz[125].MyGroup = GROUP_MIXED;
  Quiz[126].MyGroup = GROUP_MIXED;
  Quiz[127].MyGroup = GROUP_PARANOID;
  Quiz[128].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[129].MyGroup = GROUP_MIXED;
  Quiz[130].MyGroup = GROUP_PARANOID;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[133].MyGroup = GROUP_MIXED;
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_MIXED;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_PARANOID;
  Quiz[138].MyGroup = GROUP_NT_TALENT;
  Quiz[139].MyGroup = GROUP_ENVIRONMENT;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_NT_SOCIAL;
  Quiz[142].MyGroup = GROUP_NT_SOCIAL;
  Quiz[143].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[144].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[145].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[146].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[147].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[148].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[149].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[150].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[151].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[152].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[153].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[154].MyGroup = GROUP_MIXED;
  Quiz[155].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[156].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[157].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[158].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[159].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[160].MyGroup = GROUP_MIXED;
  Quiz[161].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[162].MyGroup = GROUP_ASPIE_HUNTING;

  Quiz[163].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[164].MyGroup = GROUP_MIXED;
  Quiz[165].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[166].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[167].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[168].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[169].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[170].MyGroup = GROUP_ASPIE_HUNTING;

  Quiz[171].MyGroup = GROUP_NT_TALENT;
  Quiz[172].MyGroup = GROUP_NT_TALENT;
  Quiz[173].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[174].MyGroup = GROUP_MIXED;
  Quiz[175].MyGroup = GROUP_MIXED;
  Quiz[176].MyGroup = GROUP_ASPIE_SOCIAL;

  Quiz[177].MyGroup = GROUP_MIXED;
  Quiz[178].MyGroup = GROUP_MIXED;
  Quiz[179].MyGroup = GROUP_MIXED;
  Quiz[180].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Do you drop things when your attention is on other things?";
  Quiz[1].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[2].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[3].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[4].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[5].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[6].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[7].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[8].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[9].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[10].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[11].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[12].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[13].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[14].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[15].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[16].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[17].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[18].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[19].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[20].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[21].Text = "Do people see you as eccentric?";
  Quiz[22].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[23].Text = "Do you have a hyperactive mind?";
  Quiz[24].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[25].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[26].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[27].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[28].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[29].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[30].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[31].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[32].Text = "Do you have poor concept of time?";
  Quiz[33].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[34].Text = "Are you easily distracted?";
  Quiz[35].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[36].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[37].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[38].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[39].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[40].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[41].Text = "Have you felt different from others for most of your life?";
  Quiz[42].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[43].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[44].Text = "Do you prefer to avoid eye-contact?";
  Quiz[45].Text = "Do people think you are aloof and distant?";
  Quiz[46].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[47].Text = "Do you dislike shaking hands?";
  Quiz[48].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[49].Text = "Do you prefer to keep to yourself?";
  Quiz[50].Text = "Do you instinctively know how to behave when somebody shows interest in you as a potential partner?";
  Quiz[51].Text = "Do you feel uncomfortable with strangers?";
  Quiz[52].Text = "Are you good at social chitchat?";
  Quiz[53].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[54].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[55].Text = "Are your views typical of your peer group?";
  Quiz[56].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[57].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[58].Text = "Do you find it easy to describe your feelings?";
  Quiz[59].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[60].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[61].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[62].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[63].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[64].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[65].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[66].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[67].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[68].Text = "Do you often don't know where to put your arms?";
  Quiz[69].Text = "Have you been accused of staring?";
  Quiz[70].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[71].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[72].Text = "Do you fiddle with things?";
  Quiz[73].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[74].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[75].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[76].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[77].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[78].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[79].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[80].Text = "Do you talk to yourself?";
  Quiz[81].Text = "Do you stutter when stressed?";
  Quiz[82].Text = "Do you clench your fists when angry?";
  Quiz[83].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[84].Text = "Do others often misunderstand you?";
  Quiz[85].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[86].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[87].Text = "Are you often surprised what people's motives are ?";
  Quiz[88].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[89].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[90].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[91].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[92].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[93].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[94].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[95].Text = "Do you know when you are expected to offer an apology?";
  Quiz[96].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[97].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[98].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[99].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[100].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[101].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[102].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[103].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[104].Text = "Do you have certain routines which you need to follow?";
  Quiz[105].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[106].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[107].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[108].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[109].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[110].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[111].Text = "Are you sometimes afraid in safe situations?";
  Quiz[112].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[113].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[114].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[115].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[116].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[117].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[118].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[119].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[120].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[121].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[122].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[123].Text = "Do you notice patterns in things all the time?";
  Quiz[124].Text = "Do you feel that people are watching you?";
  Quiz[125].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[126].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[127].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[128].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[129].Text = "Do you find it hard to tell the age of people?";
  Quiz[130].Text = "Do you mistake noises for voices?";
  Quiz[131].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[132].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[133].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[134].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[135].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[136].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[137].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[138].Text = "Can you easily remember verbal instructions?";
  Quiz[139].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[140].Text = "Do you find it easy to estimate the age of people?";
  Quiz[141].Text = "Do people understand you?";
  Quiz[142].Text = "Are you good at teamwork?";
  Quiz[143].Text = "Do you enjoy walking on your toes?";
  Quiz[144].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[145].Text = "Do you enjoy digging?";
  Quiz[146].Text = "Do you like to relax and do absolutely nothing while pondering on things of interest?";
  Quiz[147].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[148].Text = "Do you sometimes have an urge to climb?";
  Quiz[149].Text = "Do you feel good in mist or fog?";
  Quiz[150].Text = "Do you like sniffing people or things?";
  Quiz[151].Text = "Do you have a fascination for caves?";
  Quiz[152].Text = "Do you enjoy lying on the ground looking at the sky?";
  Quiz[153].Text = "Do you enjoy biting people - if they let you?";
  Quiz[154].Text = "Do you more often get things because you need them than because others have them?";
  Quiz[155].Text = "Do you wobble your hand slightly to indicate so-so?";
  Quiz[156].Text = "Do you feel excited in unfamiliar situations?";
  Quiz[157].Text = "Do you like animals a lot?";
  Quiz[158].Text = "Are you good at sneaking up on people or animals?";
  Quiz[159].Text = "Are you good at jumping high?";
  Quiz[160].Text = "Do you instinctively point to things of interest?";
  Quiz[161].Text = "Do you have a strong grip?";
  Quiz[162].Text = "Do you have above average physical endurance?";
  Quiz[163].Text = "Do you avoid going to a party?";
  Quiz[164].Text = "Do you dislike working while being observed?";
  Quiz[165].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[166].Text = "Do you enjoy wandering through the woods all by yourself?";
  Quiz[167].Text = "Have you been fascinated about making traps?";
  Quiz[168].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[169].Text = "Do you enjoy sneaking through the woods?";
  Quiz[170].Text = "Do you enjoy watching rodeo-riders?";

  Quiz[171].Text = "Dyslexia";
  Quiz[172].Text = "Dyscalculia";
  Quiz[173].Text = "OCD";
  Quiz[174].Text = "ODD";
  Quiz[175].Text = "Bipolar";
  Quiz[176].Text = "Social phobia";

  Quiz[177].Text = "Adopted";
  Quiz[178].Text = "Satisfied with childhood";
  Quiz[179].Text = "Biological parent income";
  Quiz[180].Text = "My income";

#endif

#ifdef SWEDISH
  Quiz[0].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[1].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[2].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[3].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[4].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[5].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[6].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[7].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[8].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[9].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[10].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[11].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[12].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[13].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[14].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[15].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[16].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[17].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[18].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[19].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[20].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[21].Text = "Tycker folk att du är excentrisk?";
  Quiz[22].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[23].Text = "Är du mentalt hyperaktiv?";
  Quiz[24].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[25].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[26].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[27].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[28].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[29].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[30].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[31].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[32].Text = "Har du dålig tidsuppfattning?";
  Quiz[33].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[34].Text = "Blir du lätt distraherad?";
  Quiz[35].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[36].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[37].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[38].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[39].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[40].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[41].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[42].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[43].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[44].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[45].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[46].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[47].Text = "Ogillar du att behöva ta i hand?";
  Quiz[48].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[49].Text = "Föredrar du att vara för dig själv?";
  Quiz[50].Text = "Vet du instinktivt hur du ska uppföra dig om någon visar intresse för dig som möjlig partner?";
  Quiz[51].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[52].Text = "Är du bra på kallprat?";
  Quiz[53].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[54].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[55].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[56].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[57].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[58].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[59].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[60].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[61].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[62].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[63].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[64].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[65].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[66].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[67].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[68].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[69].Text = "Har du blivit anklagad för att stirra?";
  Quiz[70].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[71].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[72].Text = "Brukar du fingra på saker?";
  Quiz[73].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[74].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[75].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[76].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[77].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[78].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[79].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[80].Text = "Brukar du prata med dig själv?";
  Quiz[81].Text = "Stammar du när du blir stressad?";
  Quiz[82].Text = "Knyter du nävarna när du är arg?";
  Quiz[83].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[84].Text = "Blir du ofta missförstådd av andra?";
  Quiz[85].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[86].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[87].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[88].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[89].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[90].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[91].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[92].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[93].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[94].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[95].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[96].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[97].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[98].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[99].Text = "Har du svårt att känna igen ansikten?";
  Quiz[100].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[101].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[102].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[103].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[104].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[105].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[106].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[107].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[108].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[109].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[110].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[111].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[112].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[113].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[114].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[115].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[116].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[117].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[118].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[119].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[120].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[121].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[122].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[123].Text = "Ser du mönster i saker hela tiden?";
  Quiz[124].Text = "Tycker du att folk bevakar dig?";
  Quiz[125].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[126].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[127].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[128].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[129].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[130].Text = "Misstar du ljud för röster?";
  Quiz[131].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[132].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[133].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[134].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[135].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[136].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[137].Text = "Har du haft långvariga hämndbegär?";
  Quiz[138].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[139].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[140].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[141].Text = "Förstår sig folk på dig?";
  Quiz[142].Text = "Är du bra på att arbeta i grupp?";
  Quiz[143].Text = "Gillar du att gå på tå?";
  Quiz[144].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[145].Text = "Gillar du att gräva?";
  Quiz[146].Text = "Brukar du gilla att bara slappa och göra ingenting medan du tänker på intressanta saker?";
  Quiz[147].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[148].Text = "Brukar du ibland ha ett behov av att klättra?";
  Quiz[149].Text = "Brukar du må bra när det är dis eller dimma?";
  Quiz[150].Text = "Gillar du att på nära håll lukta på andra människor eller saker?";
  Quiz[151].Text = "Är du fascinerad av grottor?";
  Quiz[152].Text = "Gillar du att ligga på marken och studera himlen?";
  Quiz[153].Text = "Gillar du att bita folk - om du får?";
  Quiz[154].Text = "Skaffar du dig oftare prylar för att du behöver dem än för att andra har dem?";
  Quiz[155].Text = "Brukar du vippa handen lite för att indikera \"sådär\"?";
  Quiz[156].Text = "Blir du upprymd av okända situationer?";
  Quiz[157].Text = "Tycker du mycket om djur?";
  Quiz[158].Text = "Är du bra att smyga på människor eller djur?";
  Quiz[159].Text = "Är du bra på att hoppa högt?";
  Quiz[160].Text = "Pekar du insktinktivt på saker du finner intressanta?";
  Quiz[161].Text = "Har du starka nypor?";
  Quiz[162].Text = "Är du mer fysiskt uthållig än normalt?";
  Quiz[163].Text = "Undviker du att gå på fester?";
  Quiz[164].Text = "Ogillar du att andra tittar på när du arbetar?";
  Quiz[165].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[166].Text = "Gillar du att vandra omkring i skogen för dig själv?";
  Quiz[167].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[168].Text = "Gillar du att härma djurläten?";
  Quiz[169].Text = "Gillar du att smyga omkring i skogen?";
  Quiz[170].Text = "Gillar du att titta på rodeo?";

  Quiz[171].Text = "Dyslexi";
  Quiz[172].Text = "Dyskaluli";
  Quiz[173].Text = "OCD";
  Quiz[174].Text = "ODD";
  Quiz[175].Text = "Bipolär";
  Quiz[176].Text = "Social fobi";

  Quiz[177].Text = "Adopterad";
  Quiz[178].Text = "Nöjd med min barndom";
  Quiz[179].Text = "Biologiska föräldrars inkomst";
  Quiz[180].Text = "Egen inkomst";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS5::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS5::InitReferers()
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

/*##################  TQuizS5::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::LoadReferers()
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

		if (Row.Ancestry == 3)
			UpdateReferer(&AmerindianRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Ancestry == 5)
			UpdateReferer(&AfroAmericanRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Ancestry == 6)
			UpdateReferer(&HispanicRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Ancestry >= 1000 && Row.Ancestry < 2000)
			UpdateReferer(&AfricanRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if ((Row.Ancestry >= 2000 && Row.Ancestry < 3000) || Row.Ancestry == 3205)
			UpdateReferer(&WhiteRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Ancestry >= 3000 && Row.Ancestry < 4000 && Row.Ancestry != 3205)
			UpdateReferer(&ArabRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Ancestry >= 4000)
			UpdateReferer(&AsianRef, Row.AsResult, Row.NtResult, Row.GroupResult);

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
#   Name       : TQuizS5::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS5::LoadPopulations()
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

		Row.Quiz[171] = Row.Dyslexia + 1;
		Row.Quiz[172] = Row.Dyscalculia + 1;
		Row.Quiz[173] = Row.OCD + 1;
		Row.Quiz[174] = Row.ODD + 1;
		Row.Quiz[175] = Row.Bipolar + 1;
		Row.Quiz[176] = Row.Social + 1;

		Row.Quiz[177] = Row.Adopt;
		Row.Quiz[178] = Row.Grow;
		Row.Quiz[179] = Row.Parent;
		Row.Quiz[180] = Row.Income;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
			    if (i < 171)
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
#   Name       : TQuizS5::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS5::SetupControlGroups()
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
#   Name       : TQuizS5::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS5::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4)
{
	DefineCross(QuizS4, 0, 64);
	DefineCross(QuizS4, 1, 0);
    DefineCross(QuizS4, 2, 1);
    DefineCross(QuizS4, 3, 2);
    DefineCross(QuizS4, 4, 3);
    DefineCross(QuizS4, 5, 4);
    DefineCross(QuizS4, 6, 5);
    DefineCross(QuizS4, 7, 138);
    DefineCross(QuizS4, 8, 118);
    DefineCross(QuizS4, 9, 6);
    DefineCross(QuizS4, 10, 8);
    DefineCross(QuizS4, 11, 9);
    DefineCross(QuizS4, 12, 79);
    DefineCross(QuizS4, 13, 147);
    DefineCross(QuizS4, 14, 52);
    DefineCross(QuizS4, 15, 10);
    DefineCross(QuizS4, 16, 54);
    DefineCross(QuizS4, 17, 11);
    DefineCross(QuizS4, 18, 12);
    DefineCross(QuizS4, 19, 13);
    DefineCross(QuizS4, 20, 114);
    DefineCross(QuizS4, 21, 137);
    DefineCross(QuizS4, 22, 14);
    DefineCross(QuizS4, 23, 15);
    DefineCross(QuizS4, 24, 17);
    DefineCross(QuizS4, 25, 18);
    DefineCross(QuizS4, 26, 19);
    DefineCross(QuizS4, 27, 20);
	DefineCross(QuizS4, 28, 55);
    DefineCross(QuizS4, 29, 61);
    DefineCross(QuizS4, 30, 119);
    DefineCross(QuizS4, 31, 21);
    DefineCross(QuizS4, 32, 22);
    DefineCross(QuizS4, 33, 23);
    DefineCross(QuizS4, 34, 24);
    DefineCross(QuizS4, 35, 25);
    DefineCross(QuizS4, 36, 28);
    DefineCross(QuizS4, 37, 27);
    DefineCross(QuizS4, 38, 30);
    DefineCross(QuizS4, 39, 31);
    DefineCross(QuizS4, 40, 32);
    DefineCross(QuizS4, 41, 33);
    DefineCross(QuizS4, 42, 35);
    DefineCross(QuizS4, 43, 36);
    DefineCross(QuizS4, 44, 37);
    DefineCross(QuizS4, 45, 134);
    DefineCross(QuizS4, 46, 135);
    DefineCross(QuizS4, 47, 38);
    DefineCross(QuizS4, 48, 39);
    DefineCross(QuizS4, 49, 136);
    DefineCross(QuizS4, 50, 40);
    DefineCross(QuizS4, 51, 41);
    DefineCross(QuizS4, 52, 42);
    DefineCross(QuizS4, 53, 43);
    DefineCross(QuizS4, 54, 44);
    DefineCross(QuizS4, 55, 45);
    DefineCross(QuizS4, 56, 46);
    DefineCross(QuizS4, 57, 47);
    DefineCross(QuizS4, 58, 49);
    DefineCross(QuizS4, 59, 48);
    DefineCross(QuizS4, 60, 124);
    DefineCross(QuizS4, 61, 50);
    DefineCross(QuizS4, 62, 51);
	DefineCross(QuizS4, 63, 86);
    DefineCross(QuizS4, 64, 87);
    DefineCross(QuizS4, 65, 133);
    DefineCross(QuizS4, 66, 88);
    DefineCross(QuizS4, 67, 89);
    DefineCross(QuizS4, 68, 90);
    DefineCross(QuizS4, 69, 91);
    DefineCross(QuizS4, 70, 92);
    DefineCross(QuizS4, 71, 94);
    DefineCross(QuizS4, 72, 95);
    DefineCross(QuizS4, 73, 97);
    DefineCross(QuizS4, 74, 98);
    DefineCross(QuizS4, 75, 99);
    DefineCross(QuizS4, 76, 100);
    DefineCross(QuizS4, 77, 101);
    DefineCross(QuizS4, 78, 102);
    DefineCross(QuizS4, 79, 103);
    DefineCross(QuizS4, 80, 104);
    DefineCross(QuizS4, 81, 105);
    DefineCross(QuizS4, 82, 106);
    DefineCross(QuizS4, 83, 29);
    DefineCross(QuizS4, 84, 107);
    DefineCross(QuizS4, 85, 108);
    DefineCross(QuizS4, 86, 110);
    DefineCross(QuizS4, 87, 112);
    DefineCross(QuizS4, 88, 111);
    DefineCross(QuizS4, 89, 60);
    DefineCross(QuizS4, 90, 113);
    DefineCross(QuizS4, 91, 115);
    DefineCross(QuizS4, 92, 116);
    DefineCross(QuizS4, 93, 132);
    DefineCross(QuizS4, 94, 117);
    DefineCross(QuizS4, 95, 120);
    DefineCross(QuizS4, 96, 121);
    DefineCross(QuizS4, 97, 123);
	DefineCross(QuizS4, 98, 126);
    DefineCross(QuizS4, 99, 125);
    DefineCross(QuizS4, 100, 56);
    DefineCross(QuizS4, 101, 58);
    DefineCross(QuizS4, 102, 59);
    DefineCross(QuizS4, 103, 62);
    DefineCross(QuizS4, 104, 63);
    DefineCross(QuizS4, 105, 65);
    DefineCross(QuizS4, 106, 69);
    DefineCross(QuizS4, 107, 75);
    DefineCross(QuizS4, 108, 53);
    DefineCross(QuizS4, 109, 34);
    DefineCross(QuizS4, 110, 66);
    DefineCross(QuizS4, 111, 70);
    DefineCross(QuizS4, 112, 73);
    DefineCross(QuizS4, 113, 74);
    DefineCross(QuizS4, 114, 77);
    DefineCross(QuizS4, 115, 82);
    DefineCross(QuizS4, 116, 85);
    DefineCross(QuizS4, 117, 109);
    DefineCross(QuizS4, 118, 57);
    DefineCross(QuizS4, 119, 67);
    DefineCross(QuizS4, 120, 68);
    DefineCross(QuizS4, 121, 71);
    DefineCross(QuizS4, 122, 93);
    DefineCross(QuizS4, 123, 16);
    DefineCross(QuizS4, 124, 142);
    DefineCross(QuizS4, 125, 7);
    DefineCross(QuizS4, 126, 72);
    DefineCross(QuizS4, 127, 141);
    DefineCross(QuizS4, 128, 96);
    DefineCross(QuizS4, 129, 122);
    DefineCross(QuizS4, 130, 140);
    DefineCross(QuizS4, 131, 26);
    DefineCross(QuizS4, 132, 76);
	DefineCross(QuizS4, 133, 78);
    DefineCross(QuizS4, 134, 80);
    DefineCross(QuizS4, 135, 81);
    DefineCross(QuizS4, 136, 83);
    DefineCross(QuizS4, 137, 84);
    DefineCross(QuizS4, 138, 127);
    DefineCross(QuizS4, 139, 130);
    DefineCross(QuizS4, 140, 131);
    DefineCross(QuizS4, 141, 129);
    DefineCross(QuizS4, 142, 128);
    DefineCross(QuizR3, 143, 89);
    DefineCross(QuizR6, 144, 95);
    DefineCross(QuizR6, 145, 96);
    DefineCross(QuizR6, 146, 97);
    DefineCross(QuizR4, 147, 149);
    DefineCross(QuizR4, 148, 148);
    DefineCross(QuizR4, 149, 144);
    DefineCross(QuizR3, 150, 93);
    DefineCross(QuizR4, 151, 150);
    DefineCross(QuizR1, 152, 128);
    DefineCross(QuizR3, 153, 94);
    DefineCross(QuizR2, 154, 164);
    DefineCross(QuizR1, 155, 127);
    DefineCross(QuizR5, 156, 40);
    DefineCross(QuizIII, 157, 99);
    DefineCross(QuizR1, 158, 129);
    DefineCross(Quiz8, 159, 15);
    DefineCross(QuizR5, 160, 140);
    DefineCross(Quiz9, 161, 6);
    DefineCross(Quiz8, 162, 18);

	DefineGlobalId(163, 920);
	DefineGlobalId(164, 921);
	DefineGlobalId(165, 922);
	DefineGlobalId(166, 923);
	DefineGlobalId(167, 924);
	DefineGlobalId(168, 925);
	DefineGlobalId(169, 926);
	DefineGlobalId(170, 927);

	DefineCross(QuizS4, 171, 197);
	DefineCross(QuizS4, 172, 198);
	DefineCross(QuizS4, 173, 199);
	DefineCross(QuizS4, 174, 200);
	DefineCross(QuizS4, 175, 201);
	DefineCross(QuizS4, 176, 202);

	DefineGlobalId(177, 928);
	DefineGlobalId(178, 929);
	DefineGlobalId(179, 930);
	DefineGlobalId(180, 931);
}

/*##########################################################################
#
#   Name       : TQuizS5::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS5::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizS5::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS5::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::ExportExcelAspie(const char *filename)
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

/*##################  TQuizS5::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS5::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::ImportMvsp(const char *filename, int PcaType)
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
//					if (PcaType == PCA_TYPE_ALL)
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

/*##################  TRace::TRace ##########################
*   Purpose....: Initialize TRace                 			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TRace::TRace()
{
	int i;

	for (i = 0; i < 10; i++)
	{
		UsCount[i] = 0;
		UsAsCount[i] = 0;
		NonUsCount[i] = 0;
		NonUsAsCount[i] = 0;
	}
}

/*##################  TRace::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::Add(TQuizRow *Row)
{
	int index = -1;
	int diff = Row->AsResult - Row->NtResult;

	if (Row->Country == 7302)
	{
		if (Row->Ancestry == 3)
			index = 0;      // american indian

		if (Row->Ancestry == 5)
			index = 1;

		if (Row->Ancestry == 6)
			index = 2;      // hispanic

		if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
			index = 1;

		if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
			index = 3;      // white

		if (Row->Ancestry >= 3000 && Row->Ancestry < 4000 && Row->Ancestry != 3205)
			index = 4;      // arab

		if (Row->Ancestry >= 4000)
			index = 5;      // asian

		if (index >= 0)
		{
			UsCount[index]++;

			if (diff > 0)
				UsAsCount[index]++;
		}
	}
	else
	{
		if (Row->Ancestry == 3) // && Row->Hair >= 6 && Row->Eye >= 5)
			index = 0;      // american indian

		if (Row->Ancestry == 5)
			index = 1;      // african american

		if (Row->Ancestry == 6)
			index = 2;      // hispanic

		if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
			index = 3;      // black african

		if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
			index = 4;      // white

		if (Row->Ancestry >= 3000 && Row->Ancestry < 4000 && Row->Ancestry != 3205)
			index = 5;      // arab

		if (Row->Ancestry >= 4000)
			index = 6;      // asian

		if (index >= 0)
		{
			NonUsCount[index]++;

			if (diff > 0)
				NonUsAsCount[index]++;
		}
	}
}

/*##################  TRace::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Race");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Count");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Interest");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS proportion");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TRace::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteEntry(TFile &file, int val, int count)
{
    char str[80];
    long double dev;
	long double sd;
    long double mean;
    long double r;
    long double rsum;
	int ival;

    WriteCenteredFieldHeader(file, 12);

#ifdef CI

    mean = (long double)val / (long double)count;

    r = 1.0 - mean;
    rsum = (long double)val * r * r;

    r = -mean;
    rsum += (long double)(count - val) * r * r;

    if (count > 1 && val)
    {
		sd = sqrtl(rsum / ((long double)count - 1));

		dev = 1.96 * sd / sqrtl(count);

		r = mean - dev;
		if (r < 0.0)
			r = 0.0;

		ival = round(1000.0 * r);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		r = mean + dev;
		if (r > 1.0)
			r = 1.0;

		ival = round(1000.0 * r);

		sprintf(str, "-%d.%01d%", ival / 10, ival % 10);
	    file.Write(str);
	}
	else
		file.Write("---");
	
#else
    ival = val * 1000 / count;
    sprintf(str, "%d.%01d%", ival / 10, ival % 10);
    file.Write(str);
#endif

	WriteFieldFooter(file);
}

/*##################  TRace::WriteUsRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteUsRow(TFile &file, int index, const char *text)
{
    char str[80];
    int sum;
    int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
    file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsCount[index]);
    file.Write(str);
	WriteFieldFooter(file);

    sum = 0;
	for (i = 0; i < 10; i++)
        sum += UsCount[i];            

    if (sum)
    {
        WriteEntry(file, UsCount[index], sum);

		if (UsCount[index])
            WriteEntry(file, UsAsCount[index], UsCount[index]);
    }
	else
	    file.Write("---");

    file.Write("</tr>");
}

/*##################  TRace::WriteNonUsRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteNonUsRow(TFile &file, int index, const char *text)
{
    char str[80];
    int sum;
    int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
    file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", NonUsCount[index]);
	file.Write(str);
	WriteFieldFooter(file);

	sum = 0;
	for (i = 0; i < 10; i++)
		sum += NonUsCount[i];

	if (sum)
	{
		WriteEntry(file, NonUsCount[index], sum);

		if (NonUsCount[index])
			WriteEntry(file, NonUsAsCount[index], NonUsCount[index]);
	}
	else
		file.Write("---");

	file.Write("</tr>");
}


/*##################  TQuizS5::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::WriteRace(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TRace race;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		race.Add(&Row);

	file.Write("<h2>US population</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TRace::WriteHeader(file);

	race.WriteUsRow(file, 0, "Native American");
	race.WriteUsRow(file, 1, "Black African");
	race.WriteUsRow(file, 2, "Hispanic");
	race.WriteUsRow(file, 3, "Caucasian");
	race.WriteUsRow(file, 4, "Arab");
	race.WriteUsRow(file, 5, "Asian");

	file.Write("</table>");

	file.Write("<br><br>");

	file.Write("<h2>Non-US population</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TRace::WriteHeader(file);

	race.WriteNonUsRow(file, 0, "Native American");
	race.WriteNonUsRow(file, 1, "African American");
	race.WriteNonUsRow(file, 2, "Hispanic");
	race.WriteNonUsRow(file, 3, "African");
	race.WriteNonUsRow(file, 4, "Caucasian");
	race.WriteNonUsRow(file, 5, "Arab");
	race.WriteNonUsRow(file, 6, "Asian");

	file.Write("</table>");
}

/*##################  TQuizS5::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS5::WriteRetest(const char *filename)
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
	long double QMean[171];
	long double AsSd;
	long double NtSd;
	long double QSd[171];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[171];
	int QCount[171];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[171][20];
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

    for (q = 0; q < 171; q++)
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

                    for (q = 0; q < 171; q++)
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

                	        for (q = 0; q < 171; q++)
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
    
	    			for (q = 0; q < 171; q++)
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

	    			for (q = 0; q < 171; q++)
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

	for (q = 0; q < 171; q++)
	{
	    sprintf(str, "%d. ", q + 1);
	    file.Write(str);
	    
		file.Write(Quiz[q].Text);
	    
	    sd = QTot[q] / QCount[q];

        sprintf(str, " <b>%3.2Lf</b><br>", sd);
    	file.Write(str);
    }
}
