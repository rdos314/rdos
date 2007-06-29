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
# quizs1.cpp
# Quiz stable release 1 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs1.h"
#include "file.h"
#include "quizdbs1.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS1::TQuizS1
#
#   Purpose....: Constructor for TQuizS1
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS1::TQuizS1(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7)
  : TQuiz(155),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7);
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS1::~TQuizS1
#
#   Purpose....: Destructor for TQuizS1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS1::~TQuizS1()
{
}

/*##################  TQuizS1::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS1::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS1::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS1::GetCatCount(int Question)
{
    if (Question < 140)
        return 3;
    else
    	return 11;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS1::GetQuizN()
{
	return 140;
}

/*##########################################################################
#
#   Name       : TQuizS1::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::WriteName(TFile &File)
{
	 File.Write("S1");
}

/*##################  TQuizS1::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS1::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS1::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::SetupTexts()
{
  Quiz[23].Reverse = TRUE;
  Quiz[25].Reverse = TRUE;
  Quiz[41].Reverse = TRUE;
  Quiz[42].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[44].Reverse = TRUE;
  Quiz[46].Reverse = TRUE;
  Quiz[47].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[59].Reverse = TRUE;
  Quiz[99].Reverse = TRUE;
  Quiz[125].Reverse = TRUE;
  Quiz[126].Reverse = TRUE;
  Quiz[130].Reverse = TRUE;
  Quiz[132].Reverse = TRUE;
  Quiz[133].Reverse = TRUE;
  Quiz[134].Reverse = TRUE;
  Quiz[136].Reverse = TRUE;
  Quiz[137].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;

  Quiz[142].Reverse = TRUE;
  Quiz[143].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[1].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[2].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[3].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[4].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[5].MyGroup = GROUP_SENSORY;
  Quiz[6].MyGroup = GROUP_SENSORY;
  Quiz[7].MyGroup = GROUP_SENSORY;
  Quiz[8].MyGroup = GROUP_SENSORY;
  Quiz[9].MyGroup = GROUP_SENSORY;
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
  Quiz[22].MyGroup = GROUP_NT_TALENT;
  Quiz[23].MyGroup = GROUP_NT_TALENT;
  Quiz[24].MyGroup = GROUP_NT_TALENT;
  Quiz[25].MyGroup = GROUP_NT_TALENT;
  Quiz[26].MyGroup = GROUP_NT_TALENT;
  Quiz[27].MyGroup = GROUP_NT_TALENT;
  Quiz[28].MyGroup = GROUP_NT_TALENT;
  Quiz[29].MyGroup = GROUP_NT_TALENT;
  Quiz[30].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[31].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[32].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[34].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[35].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[36].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[37].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[38].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[39].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[40].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[42].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[43].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[44].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[48].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[51].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[52].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[54].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[55].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[56].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[57].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[58].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[59].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[60].MyGroup = GROUP_ASPIE_COMM;
  Quiz[61].MyGroup = GROUP_ASPIE_COMM;
  Quiz[62].MyGroup = GROUP_ASPIE_COMM;
  Quiz[63].MyGroup = GROUP_ASPIE_COMM;
  Quiz[64].MyGroup = GROUP_ASPIE_COMM;
  Quiz[65].MyGroup = GROUP_ASPIE_COMM;
  Quiz[66].MyGroup = GROUP_ASPIE_COMM;
  Quiz[67].MyGroup = GROUP_ASPIE_COMM;
  Quiz[68].MyGroup = GROUP_ASPIE_COMM;
  Quiz[69].MyGroup = GROUP_ASPIE_COMM;
  Quiz[70].MyGroup = GROUP_ASPIE_COMM;
  Quiz[71].MyGroup = GROUP_ASPIE_COMM;
  Quiz[72].MyGroup = GROUP_ASPIE_COMM;
  Quiz[73].MyGroup = GROUP_ASPIE_COMM;
  Quiz[74].MyGroup = GROUP_ASPIE_COMM;
  Quiz[75].MyGroup = GROUP_ASPIE_COMM;
  Quiz[76].MyGroup = GROUP_ASPIE_NVC;
  Quiz[77].MyGroup = GROUP_ASPIE_COMM;
  Quiz[78].MyGroup = GROUP_ASPIE_COMM;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_COMM;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
  Quiz[82].MyGroup = GROUP_ASPIE_COMM;
  Quiz[83].MyGroup = GROUP_ASPIE_COMM;
  Quiz[84].MyGroup = GROUP_ASPIE_COMM;
  Quiz[85].MyGroup = GROUP_ASPIE_NVC;
  Quiz[86].MyGroup = GROUP_ASPIE_COMM;
  Quiz[87].MyGroup = GROUP_ASPIE_COMM;
  Quiz[88].MyGroup = GROUP_ASPIE_COMM;
  Quiz[89].MyGroup = GROUP_ASPIE_NVC;
  Quiz[90].MyGroup = GROUP_ASPIE_COMM;
  Quiz[91].MyGroup = GROUP_ASPIE_COMM;
  Quiz[92].MyGroup = GROUP_ASPIE_COMM;
  Quiz[93].MyGroup = GROUP_ASPIE_COMM;
  Quiz[94].MyGroup = GROUP_ASPIE_COMM;
  Quiz[95].MyGroup = GROUP_ASPIE_COMM;
  Quiz[96].MyGroup = GROUP_ASPIE_NVC;
  Quiz[97].MyGroup = GROUP_ASPIE_COMM;
  Quiz[98].MyGroup = GROUP_ASPIE_COMM;
  Quiz[99].MyGroup = GROUP_ASPIE_COMM;
  Quiz[100].MyGroup = GROUP_ASPIE_NVC;
  Quiz[101].MyGroup = GROUP_ASPIE_NVC;
  Quiz[102].MyGroup = GROUP_ASPIE_NVC;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_ASPIE_NVC;
  Quiz[107].MyGroup = GROUP_ASPIE_NVC;
  Quiz[108].MyGroup = GROUP_ASPIE_NVC;
  Quiz[109].MyGroup = GROUP_ASPIE_NVC;
  Quiz[110].MyGroup = GROUP_ASPIE_NVC;
  Quiz[111].MyGroup = GROUP_ASPIE_NVC;
  Quiz[112].MyGroup = GROUP_ASPIE_NVC;
  Quiz[113].MyGroup = GROUP_ASPIE_NVC;
  Quiz[114].MyGroup = GROUP_ASPIE_NVC;
  Quiz[115].MyGroup = GROUP_NONVERBAL;
  Quiz[116].MyGroup = GROUP_NONVERBAL;
  Quiz[117].MyGroup = GROUP_NONVERBAL;
  Quiz[118].MyGroup = GROUP_NONVERBAL;
  Quiz[119].MyGroup = GROUP_ASPIE_COMM;
  Quiz[120].MyGroup = GROUP_NONVERBAL;
  Quiz[121].MyGroup = GROUP_ASPIE_NVC;
  Quiz[122].MyGroup = GROUP_NONVERBAL;
  Quiz[123].MyGroup = GROUP_NONVERBAL;
  Quiz[124].MyGroup = GROUP_NONVERBAL;
  Quiz[125].MyGroup = GROUP_NONVERBAL;
  Quiz[126].MyGroup = GROUP_NONVERBAL;
  Quiz[127].MyGroup = GROUP_NONVERBAL;
  Quiz[128].MyGroup = GROUP_NONVERBAL;
  Quiz[129].MyGroup = GROUP_NONVERBAL;
  Quiz[130].MyGroup = GROUP_NONVERBAL;
  Quiz[131].MyGroup = GROUP_NONVERBAL;
  Quiz[132].MyGroup = GROUP_NONVERBAL;
  Quiz[133].MyGroup = GROUP_NONVERBAL;
  Quiz[134].MyGroup = GROUP_NONVERBAL;
  Quiz[135].MyGroup = GROUP_NONVERBAL;
  Quiz[136].MyGroup = GROUP_NONVERBAL;
  Quiz[137].MyGroup = GROUP_NONVERBAL;
  Quiz[138].MyGroup = GROUP_NONVERBAL;
  Quiz[139].MyGroup = GROUP_NONVERBAL;

  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_NONVERBAL;
  Quiz[143].MyGroup = GROUP_NONVERBAL;
  Quiz[144].MyGroup = GROUP_MIXED;
  Quiz[145].MyGroup = GROUP_MIXED;
  Quiz[146].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[147].MyGroup = GROUP_MIXED;
  Quiz[148].MyGroup = GROUP_MIXED;
  Quiz[149].MyGroup = GROUP_MIXED;
  Quiz[150].MyGroup = GROUP_MIXED;
  Quiz[151].MyGroup = GROUP_MIXED;
  Quiz[152].MyGroup = GROUP_MIXED;
  Quiz[153].MyGroup = GROUP_MIXED;
  Quiz[154].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[1].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
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
  Quiz[15].Text = "Do you notice patterns in things all the time?";
  Quiz[16].Text = "Do you have a hyperactive mind?";
  Quiz[17].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[18].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[19].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[20].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[21].Text = "Do you have poor concept of time?";
  Quiz[22].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[23].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[24].Text = "Are you easily distracted?";
  Quiz[25].Text = "Can you easily remember verbal instructions?";
  Quiz[26].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[27].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[28].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[29].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[30].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[31].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[32].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[33].Text = "Have you had more difficulties than others making friends?";
  Quiz[34].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[35].Text = "Have you felt different from others for most of your life?";
  Quiz[36].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[37].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[38].Text = "Do you dislike shaking hands?";
  Quiz[39].Text = "Do you prefer to avoid eye-contact?";
  Quiz[40].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[41].Text = "Do people understand you?";
  Quiz[42].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[43].Text = "Are you good at teamwork?";
  Quiz[44].Text = "Do you find the usual courting behavior natural?";
  Quiz[45].Text = "Do you feel uncomfortable with strangers?";
  Quiz[46].Text = "Do you find it easy to maintain your social network?";
  Quiz[47].Text = "Do you enjoy meeting new people?";
  Quiz[48].Text = "Are you good at social chitchat?";
  Quiz[49].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[50].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[51].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[52].Text = "Are your views typical of your peer group?";
  Quiz[53].Text = "Do you find it easy to describe your feelings?";
  Quiz[54].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[55].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[56].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[57].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[58].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[59].Text = "Is a large social network important to you?";
  Quiz[60].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[61].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[62].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[63].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[64].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[65].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[66].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[67].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[68].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[69].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[70].Text = "Have you had a tendency to prefer the company of those who are older or younger than yourself?";
  Quiz[71].Text = "Do you have certain routines which you need to follow?";
  Quiz[72].Text = "Do you drop things when your attention is on other things?";
  Quiz[73].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[74].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[75].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[76].Text = "Do you often don't know where to put your arms?";
  Quiz[77].Text = "Are you sometimes afraid in safe situations?";
  Quiz[78].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[79].Text = "Have you been accused of staring?";
  Quiz[80].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[81].Text = "Do you have an odd posture or gait?";
  Quiz[82].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[83].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[84].Text = "Do you have unusual eating habits?";
  Quiz[85].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[86].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[87].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[88].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[89].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[90].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[91].Text = "Are you prone to getting depressions?";
  Quiz[92].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[93].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[94].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[95].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[96].Text = "Do you stutter when stressed?";
  Quiz[97].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[98].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[99].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[100].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[101].Text = "Do you make unusual facial expressions?";
  Quiz[102].Text = "Do you fiddle with things?";
  Quiz[103].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[104].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[105].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[106].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[107].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[108].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[109].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[110].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[111].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[112].Text = "Do you talk to yourself?";
  Quiz[113].Text = "Do you blink or roll your eyes?";
  Quiz[114].Text = "Do you clench your fists when angry?";
  Quiz[115].Text = "Do others often misunderstand you?";
  Quiz[116].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[117].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[118].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[119].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[120].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[121].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[122].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[123].Text = "Are you often surprised what people's motives are ?";
  Quiz[124].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[125].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[126].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[127].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[128].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[129].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[130].Text = "Do you know when you are expected to offer an apology?";
  Quiz[131].Text = "Do you find it hard to tell the age of people?";
  Quiz[132].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[133].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[134].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[135].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[136].Text = "Do you find it easy to understand what someone is thinking or feeling just by looking at their face?";
  Quiz[137].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[138].Text = "Do you find it easy to estimate the age of people?";
  Quiz[139].Text = "Does it feel natural for you to say 'thank you' and 'sorry'?";

  Quiz[140].Text = "Rating for Aspie male #1";
  Quiz[141].Text = "Rating for Aspie female #1";
  Quiz[142].Text = "Rating for NT male #1";
  Quiz[143].Text = "Rating for NT female #1";
  Quiz[144].Text = "Rating for Aspie male #2";
  Quiz[145].Text = "Rating for cat";
  Quiz[146].Text = "Rating for socker game";
  Quiz[147].Text = "Rating for stream";
  Quiz[148].Text = "Rating for cave";
  Quiz[149].Text = "Rating for tropical beach";
  Quiz[150].Text = "Rating for NT male #2";
  Quiz[151].Text = "Rating for NT female #2";
  Quiz[152].Text = "Rating for Aspie female #2";
  Quiz[153].Text = "Rating for scandinavian scene";
  Quiz[154].Text = "Rating for tropical scene";

#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[1].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
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
  Quiz[15].Text = "Ser du mönster i saker hela tiden?";
  Quiz[16].Text = "Är du mentalt hyperaktiv?";
  Quiz[17].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[18].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[19].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[20].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[21].Text = "Har du dålig tidsuppfattning?";
  Quiz[22].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[23].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[24].Text = "Blir du lätt distraherad?";
  Quiz[25].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[26].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[27].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[28].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[29].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[30].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[31].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[32].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[33].Text = "Har du haft svårare än andra att få vänner?";
  Quiz[34].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[35].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[36].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[37].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[38].Text = "Ogillar du att behöva ta i hand?";
  Quiz[39].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[40].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[41].Text = "Förstår sig folk på dig?";
  Quiz[42].Text = "Trivs du i romantiska situationer?";
  Quiz[43].Text = "Är du bra på att arbeta i grupp?";
  Quiz[44].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[45].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[46].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
  Quiz[47].Text = "Trivs du med att möta nya människor?";
  Quiz[48].Text = "Är du bra på kallprat?";
  Quiz[49].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[50].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[51].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[52].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[53].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[54].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[55].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[56].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[57].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[58].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[59].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[60].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[61].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[62].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[63].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[64].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[65].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[66].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[67].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[68].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[69].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[70].Text = "Har du haft en tendens att helst umgås med människor som är antingen äldre eller yngre än du själv?";
  Quiz[71].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[72].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[73].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[74].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[75].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[76].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[77].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[78].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[79].Text = "Har du blivit anklagad för att stirra?";
  Quiz[80].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[81].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[82].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[83].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[84].Text = "Har du ovanliga matvanor?";
  Quiz[85].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[86].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[87].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[88].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[89].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[90].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[91].Text = "Brukar du få depressioner?";
  Quiz[92].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[93].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[94].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[95].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[96].Text = "Stammar du när du blir stressad?";
  Quiz[97].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[98].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[99].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[100].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[101].Text = "Har du ovanliga ansiktsuttryck?";
  Quiz[102].Text = "Brukar du fingra på saker?";
  Quiz[103].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[104].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[105].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[106].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[107].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[108].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[109].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[110].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[111].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[112].Text = "Brukar du prata med dig själv?";
  Quiz[113].Text = "Blinkar eller rullar du med ögona?";
  Quiz[114].Text = "Knyter du nävarna när du är arg?";
  Quiz[115].Text = "Blir du ofta missförstådd av andra?";
  Quiz[116].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[117].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[118].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[119].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[120].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[121].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[122].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[123].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[124].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[125].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[126].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[127].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[128].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[129].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[130].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[131].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[132].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[133].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[134].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[135].Text = "Har du svårt att känna igen ansikten?";
  Quiz[136].Text = "Tycker du det är lätt att förstå vad någon tänker eller känner genom att bara titta på deras ansikte?";
  Quiz[137].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[138].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[139].Text = "Känns det naturligt för dig att säga 'tack' och 'förlåt'?";

  Quiz[140].Text = "Bedömning för Aspie kille #1";
  Quiz[141].Text = "Bedömning för Aspie tjej #1";
  Quiz[142].Text = "Bedömning för NT kille #1";
  Quiz[143].Text = "Bedömning för NT tjej #1";
  Quiz[144].Text = "Bedömning för Aspie kille #2";
  Quiz[145].Text = "Bedömning för katt";
  Quiz[146].Text = "Bedömning för fotbollsmatch";
  Quiz[147].Text = "Bedömning för strömmande vatten";
  Quiz[148].Text = "Bedömning för grotta";
  Quiz[149].Text = "Bedömning för tropisk strand";
  Quiz[150].Text = "Bedömning för NT kille #2";
  Quiz[151].Text = "Bedömning för NT tjej #2";
  Quiz[152].Text = "Bedömning för Aspie tjej #2";
  Quiz[153].Text = "Bedömning för skandinavisk scen";
  Quiz[154].Text = "Bedömning för tropisk scen";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS1::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::InitReferers()
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
}

/*##########################################################################
#
#   Name       : TQuizS1::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
{
	int diff;

	ref->Count++;
	ref->AsResult += AsResult;
	ref->NtResult += NtResult;

	diff = AsResult - NtResult;

	if (diff >= 35)
		ref->ResultAs++;
	else
	{
		if (diff <= -35)
			ref->ResultNt++;
		else
			ref->ResultMixed++;
	}
}

/*##################  TQuizS1::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS1::LoadReferers()
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
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult);

		if (Row.TS == 2)
			UpdateReferer(&DxTsRef, Row.AsResult, Row.NtResult);

		if (Row.Dyslexia)
			UpdateReferer(&DyslexiaRef, Row.AsResult, Row.NtResult);

		if (Row.Dyscalculia)
			UpdateReferer(&DyscalculiaRef, Row.AsResult, Row.NtResult);

		if (Row.OCD)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult);

		if (Row.ODD)
			UpdateReferer(&ODDRef, Row.AsResult, Row.NtResult);

		if (Row.Bipolar)
			UpdateReferer(&BipolarRef, Row.AsResult, Row.NtResult);

		if (Row.Schizophrenia)
			UpdateReferer(&SchizophreniaRef, Row.AsResult, Row.NtResult);

		if (Row.Social)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizS1::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;

	for (i = 0; i < N; i++)
		Quiz[i].NoAnswer = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;

		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Gender == 1)
			{
			    if (Row.BirthYear > 1986)
			        YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			        
				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			}
			else
			{
			    if (Row.BirthYear > 1986)
			        YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			        
				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.TS)
			Ts.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Dyslexia)
			Dyslexia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Dyscalculia)
			Dyscalculia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.OCD)
			OCD.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.ODD)
			ODD.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Bipolar)
			Bipolar.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Schizophrenia)
			Schizophrenia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Social)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}
		else
		{
		    ref = FindReferer(Row.Referer);
		    if (ref && ref->NT)
		        NtControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizS1::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");
	DefineNt("tbg.nu");
	DefineNt("vof.se");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizS1::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7)
{
    DefineCross(QuizR7, 0, 132);
    DefineCross(QuizR7, 1, 3);
    DefineCross(QuizR7, 2, 2);
    DefineCross(QuizR7, 3, 4);
    DefineCross(QuizR7, 4, 5);
	DefineCross(QuizR7, 5, 7);
    DefineCross(QuizR7, 6, 8);
    DefineCross(QuizR7, 7, 84);
    DefineCross(QuizR7, 8, 10);
    DefineCross(QuizR7, 9, 11);
    DefineCross(QuizR7, 10, 13);
    DefineCross(QuizR7, 11, 32);
    DefineCross(QuizR7, 12, 14);
    DefineCross(QuizR7, 13, 15);
    DefineCross(QuizR7, 14, 16);
    DefineCross(QuizR7, 15, 17);
    DefineCross(QuizR7, 16, 18);
    DefineCross(QuizR7, 17, 19);
    DefineCross(QuizR7, 18, 21);
    DefineCross(QuizR7, 19, 22);
    DefineCross(QuizR7, 20, 112);
    DefineCross(QuizR7, 21, 133);
    DefineCross(QuizR7, 22, 82);
    DefineCross(QuizR7, 23, 148);
    DefineCross(QuizR7, 24, 86);
    DefineCross(QuizR7, 25, 138);
    DefineCross(QuizR7, 26, 23);
    DefineCross(QuizR7, 27, 142);
    DefineCross(QuizR7, 28, 93);
    DefineCross(QuizR7, 29, 24);
    DefineCross(QuizR7, 30, 25);
    DefineCross(QuizR7, 31, 26);
    DefineCross(QuizR7, 32, 27);
    DefineCross(QuizR7, 33, 30);
    DefineCross(QuizR7, 34, 35);
    DefineCross(QuizR7, 35, 29);
    DefineCross(QuizR7, 36, 31);
    DefineCross(QuizR7, 37, 28);
    DefineCross(QuizR7, 38, 36);
    DefineCross(QuizR7, 39, 37);
	DefineCross(QuizR7, 40, 39);
    DefineCross(QuizR7, 41, 123);
    DefineCross(QuizR7, 42, 43);
    DefineCross(QuizR7, 43, 41);
    DefineCross(QuizR7, 44, 44);
    DefineCross(QuizR7, 45, 46);
    DefineCross(QuizR7, 46, 45);
    DefineCross(QuizR7, 47, 63);
    DefineCross(QuizR7, 48, 38);
    DefineCross(QuizR7, 49, 52);
    DefineCross(QuizR7, 50, 48);
    DefineCross(QuizR7, 51, 47);
    DefineCross(QuizR7, 52, 56);
    DefineCross(QuizR7, 53, 51);
    DefineCross(QuizR7, 54, 50);
    DefineCross(QuizR7, 55, 53);
    DefineCross(QuizR7, 56, 49);
    DefineCross(QuizR7, 57, 58);
    DefineCross(QuizR7, 58, 57);
    DefineCross(QuizR7, 59, 60);
    DefineCross(QuizR7, 60, 64);
    DefineCross(QuizR7, 61, 66);
    DefineCross(QuizR7, 62, 115);
    DefineCross(QuizR7, 63, 67);
    DefineCross(QuizR7, 64, 33);
    DefineCross(QuizR7, 65, 34);
    DefineCross(QuizR7, 66, 68);
    DefineCross(QuizR7, 67, 71);
    DefineCross(QuizR7, 68, 72);
    DefineCross(QuizR7, 69, 69);
    DefineCross(QuizR7, 70, 40);
    DefineCross(QuizR7, 71, 70);
    DefineCross(QuizR7, 72, 73);
    DefineCross(QuizR7, 73, 42);
    DefineCross(QuizR7, 74, 77);
	DefineCross(QuizR7, 75, 122);
    DefineCross(QuizR7, 76, 79);
    DefineCross(QuizR7, 77, 81);
    DefineCross(QuizR7, 78, 76);
    DefineCross(QuizR7, 79, 78);
    DefineCross(QuizR7, 80, 74);
    DefineCross(QuizR7, 81, 131);
    DefineCross(QuizR7, 82, 130);
    DefineCross(QuizR7, 83, 20);
    DefineCross(QuizR7, 84, 80);
    DefineCross(QuizR7, 85, 9);
    DefineCross(QuizR7, 86, 134);
    DefineCross(QuizR7, 87, 135);
    DefineCross(QuizR7, 88, 55);
    DefineCross(QuizR7, 89, 85);
    DefineCross(QuizR7, 90, 90);
    DefineCross(QuizR7, 91, 88);
    DefineCross(QuizR7, 92, 95);
    DefineCross(QuizR7, 93, 89);
    DefineCross(QuizR7, 94, 91);
    DefineCross(QuizR7, 95, 96);
    DefineCross(QuizR7, 96, 92);
    DefineCross(QuizR7, 97, 0);
    DefineCross(QuizR7, 98, 97);
    DefineCross(QuizR7, 99, 144);
    DefineGlobalId(100, 744);
    DefineCross(QuizR7, 101, 98);
    DefineCross(QuizR7, 102, 102);
    DefineCross(QuizR7, 103, 103);
    DefineCross(QuizR7, 104, 99);
    DefineCross(QuizR7, 105, 101);
    DefineCross(QuizR7, 106, 104);
    DefineCross(QuizR7, 107, 106);
    DefineCross(QuizR7, 108, 100);
    DefineCross(QuizR7, 109, 105);
	DefineCross(QuizR7, 110, 62);
    DefineCross(QuizR7, 111, 107);
    DefineCross(QuizR7, 112, 108);
    DefineCross(QuizR7, 113, 109);
    DefineCross(QuizR6, 114, 111);
    DefineCross(QuizR7, 115, 110);
    DefineCross(QuizR7, 116, 111);
    DefineCross(QuizR7, 117, 113);
    DefineCross(QuizR7, 118, 114);
    DefineCross(QuizR7, 119, 65);
    DefineCross(QuizR7, 120, 120);
    DefineCross(QuizR7, 121, 116);
    DefineCross(QuizR7, 122, 117);
    DefineCross(QuizR7, 123, 118);
    DefineCross(QuizR7, 124, 121);
    DefineCross(QuizR7, 125, 119);
    DefineCross(QuizR7, 126, 126);
    DefineCross(QuizR7, 127, 124);
    DefineCross(QuizR7, 128, 127);
    DefineCross(QuizR7, 129, 129);
    DefineCross(QuizR7, 130, 128);
    DefineCross(QuizR7, 131, 137);
    DefineCross(QuizR7, 132, 136);
    DefineCross(QuizR7, 133, 139);
    DefineCross(QuizR7, 134, 146);
    DefineCross(QuizR7, 135, 140);
    DefineCross(QuizR7, 136, 147);
    DefineCross(QuizR7, 137, 143);
    DefineCross(QuizR7, 138, 145);
    DefineCross(QuizR7, 139, 61);

    DefineGlobalId(140, 745);
    DefineGlobalId(141, 746);
    DefineGlobalId(142, 747);
    DefineGlobalId(143, 748);
	DefineGlobalId(144, 749);
    DefineGlobalId(145, 750);
    DefineGlobalId(146, 751);
    DefineGlobalId(147, 752);
    DefineGlobalId(148, 753);
    DefineGlobalId(149, 754);
    DefineGlobalId(150, 755);
    DefineGlobalId(151, 756);
    DefineGlobalId(152, 757);
    DefineGlobalId(153, 758);
    DefineGlobalId(154, 759);
}

/*##########################################################################
#
#   Name       : TQuizS1::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS1::GetReferer(const char *referer, TPopulation *pop)
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
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz);
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

/*##################  TQuizS1::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS1::ExportExcelCase(const char *filename, int PcaType)
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

			for (i = 0; i < N; i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
    				ival = Row.Quiz[i];
	    			if (ival)
						ival--;
    
					if (ival < 140 && ival > 2)
						ival = 0;
                    
					sprintf(str, "\"%d\"", ival);
					file.Write(str);
					if (i != N - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizS1::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS1::ExportExcelGroups(const char *filename)
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

		for (i = 0; i < N; i++)
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

/*##################  TQuizS1::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS1::ImportMvsp(const char *filename, int PcaType)
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

//					if (PcaType == PCA_TYPE_ALL)
//						d3 = -d3;

					if (PcaType == PCA_TYPE_ALL)
						d4 = -d4;

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

/*##################  TQuizS1::WritePictureRating ##########################
*   Purpose....: Write picture rating report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS1::WritePictureRating(const char *filename)
{
	int NtRateCount[15];
	long double NtRateSum[15];
	long double NtRateMean[15];
	long double NtRateSd[15];
	int NtViewCount[15];
	long double NtViewSum[15];
	long double NtViewMean[15];
	long double NtViewSd[15];
	int AsRateCount[15];
	long double AsRateSum[15];
	long double AsRateMean[15];
	long double AsRateSd[15];
	int AsViewCount[15];
	long double AsViewSum[15];
	long double AsViewMean[15];
	long double AsViewSd[15];
	int UseMale[15];
	int UseFemale[15];
	int use;
	int i;
	int ival;
	long double val;
	long double dev;
	char str[80];
	int diff;
	TQuizRow Row;
	TFile file(filename, 0);

	for (i = 0; i < 15; i++)
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
	UseMale[2] = FALSE;
	UseFemale[3] = FALSE;
	UseMale[4] = FALSE;
	UseMale[10] = FALSE;
	UseFemale[11] = FALSE;
    UseFemale[12] = FALSE;            	

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < 15; i++)
		{
		    if (Row.Gender == 2)
		        use = UseFemale[i];
		    else
		        use = UseMale[i];

            if (use)
            {		    
    			diff = Row.AsResult - Row.NtResult;
	    		if (Row.Rating[i] || Row.ViewTime[i])
		    	{
			    	if (diff > 0)
				    {
    					AsRateCount[i]++;
	    				AsRateSum[i] += Row.Rating[i];
		    		}
			    	else
				    {
    					NtRateCount[i]++;
	    				NtRateSum[i] += Row.Rating[i];
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

	for (i = 0; i < 15; i++)
	{
		AsRateMean[i] = AsRateSum[i] / AsRateCount[i];
		AsViewMean[i] = AsViewSum[i] / AsViewCount[i];

		NtRateMean[i] = NtRateSum[i] / NtRateCount[i];
		NtViewMean[i] = NtViewSum[i] / NtViewCount[i];
	}

	for (i = 0; i < 15; i++)
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
		for (i = 0; i < 15; i++)
		{
		    if (Row.Gender == 2)
		        use = UseFemale[i];
		    else
		        use = UseMale[i];

            if (use)
            {		    
    			diff = Row.AsResult - Row.NtResult;
	    		if (Row.Rating[i] || Row.ViewTime[i])
		    	{
			    	if (diff > 0)
    				{
	    				AsRateCount[i]++;
		    			val = (long double)Row.Rating[i] - AsRateMean[i];
			    		AsRateSum[i] += val * val;
    				}
	    			else
		    		{
			    		NtRateCount[i]++;
    					val = (long double)Row.Rating[i] - NtRateMean[i];
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

	for (i = 0; i < 15; i++)
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


    for (i = 0; i < 15; i++)
    {
    	file.Write("<tr style='height:24.75pt'>");

	    WriteCenteredFieldHeader(file, 25);
	    switch (i)
	    {
	        case 0:
            	file.Write("Aspie male #1");
            	break;
            	
			case 1:
            	file.Write("Aspie female");
            	break;
            	
	        case 2:
            	file.Write("Celebrity male");
            	break;
            	
	        case 3:
            	file.Write("Celebrity female");
            	break;
            	
	        case 4:
            	file.Write("Aspie male #2");
            	break;
            	
	        case 5:
            	file.Write("Cat");
            	break;
            	
	        case 6:
            	file.Write("Socker game");
            	break;
            	
	        case 7:
            	file.Write("Stream");
            	break;
            	
	        case 8:
            	file.Write("Cave");
            	break;

	        case 9:
            	file.Write("Tropical beach");
            	break;

	        case 10:
            	file.Write("NT male #2");
            	break;

	        case 11:
            	file.Write("NT female #2");
            	break;

	        case 12:
            	file.Write("Aspie female #2");
            	break;
            	
	        case 13:
            	file.Write("Scandinavian scene");
            	break;

	        case 14:
            	file.Write("Tropical scene");
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
