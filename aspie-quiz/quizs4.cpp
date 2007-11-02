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
# quizs4.cpp
# Quiz stable release 4 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs4.h"
#include "file.h"
#include "quizdbs4.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS4::TQuizS4
#
#   Purpose....: Constructor for TQuizS4
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS4::TQuizS4(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3)
  : TQuiz(203),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS4::~TQuizS4
#
#   Purpose....: Destructor for TQuizS4
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS4::~TQuizS4()
{
}

/*##################  TQuizS4::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS4::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS4::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS4::GetCatCount(int Question)
{
    if (Question >= 149 && Question <= 196)
        return 4;
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
int TQuizS4::GetQuizN()
{
	return 149;
}

/*##########################################################################
#
#   Name       : TQuizS4::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS4::WriteName(TFile &File)
{
	 File.Write("S4");
}

/*##################  TQuizS4::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizS4::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS4::SetupTexts()
{
  Quiz[21].Reverse = TRUE;
  Quiz[40].Reverse = TRUE;
  Quiz[42].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[47].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[50].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[115].Reverse = TRUE;
  Quiz[116].Reverse = TRUE;
  Quiz[120].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[123].Reverse = TRUE;
  Quiz[124].Reverse = TRUE;
  Quiz[126].Reverse = TRUE;
  Quiz[127].Reverse = TRUE;
  Quiz[128].Reverse = TRUE;
  Quiz[129].Reverse = TRUE;
  Quiz[130].Reverse = TRUE;
  Quiz[131].Reverse = TRUE;
  Quiz[132].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[1].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[2].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[3].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[4].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[5].MyGroup = GROUP_SENSORY;
  Quiz[6].MyGroup = GROUP_SENSORY;
  Quiz[7].MyGroup = GROUP_MIXED;
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
  Quiz[26].MyGroup = GROUP_MIXED;
  Quiz[27].MyGroup = GROUP_NT_TALENT;
  Quiz[28].MyGroup = GROUP_NT_TALENT;
  Quiz[29].MyGroup = GROUP_NONVERBAL;
  Quiz[30].MyGroup = GROUP_NT_SOCIAL;
  Quiz[31].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[32].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[34].MyGroup = GROUP_ENVIRONMENT;
  Quiz[35].MyGroup = GROUP_MIXED;
  Quiz[36].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[37].MyGroup = GROUP_NT_SOCIAL;
  Quiz[38].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[39].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[40].MyGroup = GROUP_NT_SOCIAL;
  Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[42].MyGroup = GROUP_NT_SOCIAL;
  Quiz[43].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[44].MyGroup = GROUP_CONFORM;
  Quiz[45].MyGroup = GROUP_NT_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_SOCIAL;
  Quiz[48].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[53].MyGroup = GROUP_ENVIRONMENT;
  Quiz[54].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[55].MyGroup = GROUP_NT_TALENT;
  Quiz[56].MyGroup = GROUP_OCD;
  Quiz[57].MyGroup = GROUP_MIXED;
  Quiz[58].MyGroup = GROUP_OCD;
  Quiz[59].MyGroup = GROUP_OCD;
  Quiz[60].MyGroup = GROUP_NONVERBAL;
  Quiz[61].MyGroup = GROUP_NT_TALENT;
  Quiz[62].MyGroup = GROUP_OCD;
  Quiz[63].MyGroup = GROUP_OCD;
  Quiz[64].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[65].MyGroup = GROUP_OCD;
  Quiz[66].MyGroup = GROUP_ENVIRONMENT;
  Quiz[67].MyGroup = GROUP_MIXED;
  Quiz[68].MyGroup = GROUP_MIXED;
  Quiz[69].MyGroup = GROUP_OCD;
  Quiz[70].MyGroup = GROUP_ENVIRONMENT;
  Quiz[71].MyGroup = GROUP_MIXED;
  Quiz[72].MyGroup = GROUP_MIXED;
  Quiz[73].MyGroup = GROUP_ENVIRONMENT;
  Quiz[74].MyGroup = GROUP_ENVIRONMENT;
  Quiz[75].MyGroup = GROUP_OCD;
  Quiz[76].MyGroup = GROUP_INSTINCT;
  Quiz[77].MyGroup = GROUP_ENVIRONMENT;
  Quiz[78].MyGroup = GROUP_MIXED;
  Quiz[79].MyGroup = GROUP_SENSORY;
  Quiz[80].MyGroup = GROUP_MIXED;
  Quiz[81].MyGroup = GROUP_MIXED;
  Quiz[82].MyGroup = GROUP_ENVIRONMENT;
  Quiz[83].MyGroup = GROUP_MIXED;
  Quiz[84].MyGroup = GROUP_PARANOID;
  Quiz[85].MyGroup = GROUP_MIXED;
  Quiz[86].MyGroup = GROUP_ASPIE_NVC;
  Quiz[87].MyGroup = GROUP_ASPIE_NVC;
  Quiz[88].MyGroup = GROUP_ASPIE_NVC;
  Quiz[89].MyGroup = GROUP_ASPIE_NVC;
  Quiz[90].MyGroup = GROUP_ASPIE_NVC;
  Quiz[91].MyGroup = GROUP_ASPIE_NVC;
  Quiz[92].MyGroup = GROUP_ASPIE_NVC;
  Quiz[93].MyGroup = GROUP_MIXED;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_NVC;
  Quiz[96].MyGroup = GROUP_INSTINCT;
  Quiz[97].MyGroup = GROUP_ASPIE_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_NVC;
  Quiz[100].MyGroup = GROUP_ASPIE_NVC;
  Quiz[101].MyGroup = GROUP_ASPIE_NVC;
  Quiz[102].MyGroup = GROUP_ASPIE_NVC;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_ASPIE_NVC;
  Quiz[107].MyGroup = GROUP_NONVERBAL;
  Quiz[108].MyGroup = GROUP_NONVERBAL;
  Quiz[109].MyGroup = GROUP_MIXED;
  Quiz[110].MyGroup = GROUP_NONVERBAL;
  Quiz[111].MyGroup = GROUP_NONVERBAL;
  Quiz[112].MyGroup = GROUP_NONVERBAL;
  Quiz[113].MyGroup = GROUP_NONVERBAL;
  Quiz[114].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[115].MyGroup = GROUP_NONVERBAL;
  Quiz[116].MyGroup = GROUP_NONVERBAL;
  Quiz[117].MyGroup = GROUP_NONVERBAL;
  Quiz[118].MyGroup = GROUP_SENSORY;
  Quiz[119].MyGroup = GROUP_NT_TALENT;
  Quiz[120].MyGroup = GROUP_NONVERBAL;
  Quiz[121].MyGroup = GROUP_NT_SOCIAL;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_NONVERBAL;
  Quiz[124].MyGroup = GROUP_NT_SOCIAL;
  Quiz[125].MyGroup = GROUP_NONVERBAL;
  Quiz[126].MyGroup = GROUP_NONVERBAL;
  Quiz[127].MyGroup = GROUP_NT_TALENT;
  Quiz[128].MyGroup = GROUP_NT_SOCIAL;
  Quiz[129].MyGroup = GROUP_NT_SOCIAL;
  Quiz[130].MyGroup = GROUP_ENVIRONMENT;
  Quiz[131].MyGroup = GROUP_MIXED;

  Quiz[132].MyGroup = GROUP_NT_SOCIAL;
  Quiz[133].MyGroup = GROUP_ASPIE_NVC;
  Quiz[134].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[135].MyGroup = GROUP_NT_SOCIAL;
  Quiz[136].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[137].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[138].MyGroup = GROUP_SENSORY;
  Quiz[139].MyGroup = GROUP_PARANOID;
  Quiz[140].MyGroup = GROUP_PARANOID;
  Quiz[141].MyGroup = GROUP_PARANOID;
  Quiz[142].MyGroup = GROUP_PARANOID;
  Quiz[143].MyGroup = GROUP_PARANOID;
  Quiz[144].MyGroup = GROUP_MIXED;
  Quiz[145].MyGroup = GROUP_PARANOID;
  Quiz[146].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[147].MyGroup = GROUP_SENSORY;
  Quiz[148].MyGroup = GROUP_INSTINCT;

  Quiz[149].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[150].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[151].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[152].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[153].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[154].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[155].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[156].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[157].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[158].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[159].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[160].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[161].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[162].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[163].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[164].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[165].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[166].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[167].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[168].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[169].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[170].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[171].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[172].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[173].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[174].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[175].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[176].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[177].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[178].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[179].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[180].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[181].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[182].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[183].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[184].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[185].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[186].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[187].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[188].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[189].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[190].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[191].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[192].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[193].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[194].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[195].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[196].MyGroup = GROUP_ASPIE_SOCIAL;

  Quiz[197].MyGroup = GROUP_NT_TALENT;
  Quiz[198].MyGroup = GROUP_NT_TALENT;
  Quiz[199].MyGroup = GROUP_SENSORY;
  Quiz[200].MyGroup = GROUP_MIXED;
  Quiz[201].MyGroup = GROUP_MIXED;
  Quiz[202].MyGroup = GROUP_ASPIE_SOCIAL;

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
  Quiz[14].Text = "Do you or others think that you have unconventional ways of solving problems?";
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
  Quiz[30].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[31].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[32].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[33].Text = "Have you felt different from others for most of your life?";
  Quiz[34].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[35].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[36].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[37].Text = "Do you prefer to avoid eye-contact?";
  Quiz[38].Text = "Do you dislike shaking hands?";
  Quiz[39].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[40].Text = "Do you instinctively know how to behave when somebody shows interest in you as a potential partner?";
  Quiz[41].Text = "Do you feel uncomfortable with strangers?";
  Quiz[42].Text = "Are you good at social chitchat?";
  Quiz[43].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[44].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[45].Text = "Are your views typical of your peer group?";
  Quiz[46].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[47].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[48].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[49].Text = "Do you find it easy to describe your feelings?";
  Quiz[50].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[51].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[52].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[53].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[54].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[55].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[56].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[57].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[58].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[59].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[60].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[61].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[62].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[63].Text = "Do you have certain routines which you need to follow?";
  Quiz[64].Text = "Do you drop things when your attention is on other things?";
  Quiz[65].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[66].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[67].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[68].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[69].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[70].Text = "Are you sometimes afraid in safe situations?";
  Quiz[71].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[72].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[73].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[74].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[75].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[76].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[77].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[78].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[79].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[80].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[81].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[82].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[83].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[84].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[85].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[86].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[87].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[88].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[89].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[90].Text = "Do you often don't know where to put your arms?";
  Quiz[91].Text = "Have you been accused of staring?";
  Quiz[92].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[93].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[94].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[95].Text = "Do you fiddle with things?";
  Quiz[96].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[97].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[98].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[99].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[100].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[101].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[102].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[103].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[104].Text = "Do you talk to yourself?";
  Quiz[105].Text = "Do you stutter when stressed?";
  Quiz[106].Text = "Do you clench your fists when angry?";
  Quiz[107].Text = "Do others often misunderstand you?";
  Quiz[108].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[109].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[110].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[111].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[112].Text = "Are you often surprised what people's motives are ?";
  Quiz[113].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[114].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[115].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[116].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[117].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[118].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[119].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[120].Text = "Do you know when you are expected to offer an apology?";
  Quiz[121].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[122].Text = "Do you find it hard to tell the age of people?";
  Quiz[123].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[124].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[125].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[126].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[127].Text = "Can you easily remember verbal instructions?";
  Quiz[128].Text = "Are you good at teamwork?";
  Quiz[129].Text = "Do people understand you?";
  Quiz[130].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[131].Text = "Do you find it easy to estimate the age of people?";

  Quiz[132].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[133].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[134].Text = "Do people think you are aloof and distant?";
  Quiz[135].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[136].Text = "Do you prefer to keep to yourself?";
  Quiz[137].Text = "Do people see you as eccentric?";
  Quiz[138].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[139].Text = "Do you mistake objects or shadows for people?";
  Quiz[140].Text = "Do you mistake noises for voices?";
  Quiz[141].Text = "Are your thoughts so strong that you can (almost) hear them?";
  Quiz[142].Text = "Do you feel that people are watching you?";
  Quiz[143].Text = "Do you wonder if people are talking about you behind your back?";
  Quiz[144].Text = "Do you see a special meaning in the way things are arranged around you?";
  Quiz[145].Text = "Do you hear a voice speaking your thoughts out loud?";
  Quiz[146].Text = "Do you see things that other people don't see?";
  Quiz[147].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[148].Text = "When you read numbers or single letters, do particular colors or sounds come to mind?";

  Quiz[149].Text = "LSAS - Fear - Using a telephone in public";
  Quiz[150].Text = "LSAS - Avoid - Using a telephone in public";
  Quiz[151].Text = "LSAS - Fear - Participating in a small group activity";
  Quiz[152].Text = "LSAS - Avoid - Participating in a small group activity";
  Quiz[153].Text = "LSAS - Fear - Eating in public";
  Quiz[154].Text = "LSAS - Avoid - Eating in public";
  Quiz[155].Text = "LSAS - Fear - Drinking with others";
  Quiz[156].Text = "LSAS - Avoid - Drinking with others";
  Quiz[157].Text = "LSAS - Fear - Talking to someone in authority";
  Quiz[158].Text = "LSAS - Avoid - Talking to someone in authority";
  Quiz[159].Text = "LSAS - Fear - Acting, performing, or speaking in front of an audience";
  Quiz[160].Text = "LSAS - Avoid - Acting, performing, or speaking in front of an audience";
  Quiz[161].Text = "LSAS - Fear - Going to a party";
  Quiz[162].Text = "LSAS - Avoid - Going to a party";
  Quiz[163].Text = "LSAS - Fear - Working while being observed";
  Quiz[164].Text = "LSAS - Avoid - Working while being observed";
  Quiz[165].Text = "LSAS - Fear - Writing while being observed";
  Quiz[166].Text = "LSAS - Avoid - Writing while being observed";
  Quiz[167].Text = "LSAS - Fear - Calling someone you don't know very well";
  Quiz[168].Text = "LSAS - Avoid - Calling someone you don't know very well";
  Quiz[169].Text = "LSAS - Fear - Talking face to face with someone you don't know very well";
  Quiz[170].Text = "LSAS - Avoid - Talking face to face with someone you don't know very well";
  Quiz[171].Text = "LSAS - Fear - Meeting strangers";
  Quiz[172].Text = "LSAS - Avoid - Meeting strangers";
  Quiz[173].Text = "LSAS - Fear - Urinating in a public bathroom";
  Quiz[174].Text = "LSAS - Avoid - Urinating in a public bathroom";
  Quiz[175].Text = "LSAS - Fear - Entering a room when others are already seated";
  Quiz[176].Text = "LSAS - Avoid - Entering a room when others are already seated";
  Quiz[177].Text = "LSAS - Fear - Being the center of attention";
  Quiz[178].Text = "LSAS - Avoid - Being the center of attention";
  Quiz[179].Text = "LSAS - Fear - Speaking up at a meeting";
  Quiz[180].Text = "LSAS - Avoid - Speaking up at a meeting";
  Quiz[181].Text = "LSAS - Fear - Taking a test of your ability, skill, or knowledge";
  Quiz[182].Text = "LSAS - Avoid - Taking a test of your ability, skill, or knowledge";
  Quiz[183].Text = "LSAS - Fear - Expressing disagreement or disapproval to someone you don't know very well";
  Quiz[184].Text = "LSAS - Avoid - Expressing disagreement or disapproval to someone you don't know very well";
  Quiz[185].Text = "LSAS - Fear - Looking someone who you don't know very well straight in the eyes";
  Quiz[186].Text = "LSAS - Avoid - Looking someone who you don't know very well straight in the eyes";
  Quiz[187].Text = "LSAS - Fear - Giving a prepared oral talk to a group";
  Quiz[188].Text = "LSAS - Avoid - Giving a prepared oral talk to a group";
  Quiz[189].Text = "LSAS - Fear - Trying to make someone's acquaintance for the purpose of a romantic/sexual relationship";
  Quiz[190].Text = "LSAS - Avoid - Trying to make someone's acquaintance for the purpose of a romantic/sexual relationship";
  Quiz[191].Text = "LSAS - Fear - Returning goods to a store for a refund";
  Quiz[192].Text = "LSAS - Avoid - Returning goods to a store for a refund";
  Quiz[193].Text = "LSAS - Fear - Giving a party";
  Quiz[194].Text = "LSAS - Avoid - Giving a party";
  Quiz[195].Text = "LSAS - Fear - Resisting a high pressure sales person";
  Quiz[196].Text = "LSAS - Avoid - Resisting a high pressure sales person";

  Quiz[197].Text = "Dyslexia";
  Quiz[198].Text = "Dyscalculia";
  Quiz[199].Text = "OCD";
  Quiz[200].Text = "ODD";
  Quiz[201].Text = "Bipolar";
  Quiz[202].Text = "Social phobia";

#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[1].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
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
  Quiz[14].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
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
  Quiz[30].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[31].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[32].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[33].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[34].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[35].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[36].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[37].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[38].Text = "Ogillar du att behöva ta i hand?";
  Quiz[39].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[40].Text = "Vet du instinktivt hur du ska uppföra dig om någon visar intresse för dig som möjlig partner?";
  Quiz[41].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[42].Text = "Är du bra på kallprat?";
  Quiz[43].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[44].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[45].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[46].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[47].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[48].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[49].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[50].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[51].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[52].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[53].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[54].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[55].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[56].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[57].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[58].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[59].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[60].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[61].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[62].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[63].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[64].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[65].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[66].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[67].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[68].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[69].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[70].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[71].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[72].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[73].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[74].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[75].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[76].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[77].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[78].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[79].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[80].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[81].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[82].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[83].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[84].Text = "Har du haft långvariga hämndbegär?";
  Quiz[85].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[86].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[87].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[88].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[89].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[90].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[91].Text = "Har du blivit anklagad för att stirra?";
  Quiz[92].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[93].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[94].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[95].Text = "Brukar du fingra på saker?";
  Quiz[96].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[97].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[98].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[99].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[100].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[101].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[102].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[103].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[104].Text = "Brukar du prata med dig själv?";
  Quiz[105].Text = "Stammar du när du blir stressad?";
  Quiz[106].Text = "Knyter du nävarna när du är arg?";
  Quiz[107].Text = "Blir du ofta missförstådd av andra?";
  Quiz[108].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[109].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[110].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[111].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[112].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[113].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[114].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[115].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[116].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[117].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[118].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[119].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[120].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[121].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[122].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[123].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[124].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[125].Text = "Har du svårt att känna igen ansikten?";
  Quiz[126].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[127].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[128].Text = "Är du bra på att arbeta i grupp?";
  Quiz[129].Text = "Förstår sig folk på dig?";
  Quiz[130].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[131].Text = "Har du lätt för att bedömma människors ålder?";

  Quiz[132].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[133].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[134].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[135].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[136].Text = "Föredrar du att vara för dig själv?";
  Quiz[137].Text = "Tycker folk att du är excentrisk?";
  Quiz[138].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[139].Text = "Misstar du saker eller skuggor för människor?";
  Quiz[140].Text = "Misstar du ljud för röster?";
  Quiz[141].Text = "Är dina tankar så starka att du (nästan) kan höra dem?";
  Quiz[142].Text = "Tycker du att folk bevakar dig?";
  Quiz[143].Text = "Undrar du om folk pratar om dig bakom din rygg?";
  Quiz[144].Text = "Ser du en speciell mening i hur saker är arrangerade omkring dig?";
  Quiz[145].Text = "Hör du en röst som högt talar ut dina tankar?";
  Quiz[146].Text = "Ser du saker som andra inte ser?";
  Quiz[147].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[148].Text = "När du läser siffror eller enstaka bokstäver får du då associationer med speciella färger eller ljud?";

  Quiz[149].Text = "LSAS - Fear - Using a telephone in public";
  Quiz[150].Text = "LSAS - Avoid - Using a telephone in public";
  Quiz[151].Text = "LSAS - Fear - Participating in a small group activity";
  Quiz[152].Text = "LSAS - Avoid - Participating in a small group activity";
  Quiz[153].Text = "LSAS - Fear - Eating in public";
  Quiz[154].Text = "LSAS - Avoid - Eating in public";
  Quiz[155].Text = "LSAS - Fear - Drinking with others";
  Quiz[156].Text = "LSAS - Avoid - Drinking with others";
  Quiz[157].Text = "LSAS - Fear - Talking to someone in authority";
  Quiz[158].Text = "LSAS - Avoid - Talking to someone in authority";
  Quiz[159].Text = "LSAS - Fear - Acting, performing, or speaking in front of an audience";
  Quiz[160].Text = "LSAS - Avoid - Acting, performing, or speaking in front of an audience";
  Quiz[161].Text = "LSAS - Fear - Going to a party";
  Quiz[162].Text = "LSAS - Avoid - Going to a party";
  Quiz[163].Text = "LSAS - Fear - Working while being observed";
  Quiz[164].Text = "LSAS - Avoid - Working while being observed";
  Quiz[165].Text = "LSAS - Fear - Writing while being observed";
  Quiz[166].Text = "LSAS - Avoid - Writing while being observed";
  Quiz[167].Text = "LSAS - Fear - Calling someone you don't know very well";
  Quiz[168].Text = "LSAS - Avoid - Calling someone you don't know very well";
  Quiz[169].Text = "LSAS - Fear - Talking face to face with someone you don't know very well";
  Quiz[170].Text = "LSAS - Avoid - Talking face to face with someone you don't know very well";
  Quiz[171].Text = "LSAS - Fear - Meeting strangers";
  Quiz[172].Text = "LSAS - Avoid - Meeting strangers";
  Quiz[173].Text = "LSAS - Fear - Urinating in a public bathroom";
  Quiz[174].Text = "LSAS - Avoid - Urinating in a public bathroom";
  Quiz[175].Text = "LSAS - Fear - Entering a room when others are already seated";
  Quiz[176].Text = "LSAS - Avoid - Entering a room when others are already seated";
  Quiz[177].Text = "LSAS - Fear - Being the center of attention";
  Quiz[178].Text = "LSAS - Avoid - Being the center of attention";
  Quiz[179].Text = "LSAS - Fear - Speaking up at a meeting";
  Quiz[180].Text = "LSAS - Avoid - Speaking up at a meeting";
  Quiz[181].Text = "LSAS - Fear - Taking a test of your ability, skill, or knowledge";
  Quiz[182].Text = "LSAS - Avoid - Taking a test of your ability, skill, or knowledge";
  Quiz[183].Text = "LSAS - Fear - Expressing disagreement or disapproval to someone you don't know very well";
  Quiz[184].Text = "LSAS - Avoid - Expressing disagreement or disapproval to someone you don't know very well";
  Quiz[185].Text = "LSAS - Fear - Looking someone who you don't know very well straight in the eyes";
  Quiz[186].Text = "LSAS - Avoid - Looking someone who you don't know very well straight in the eyes";
  Quiz[187].Text = "LSAS - Fear - Giving a prepared oral talk to a group";
  Quiz[188].Text = "LSAS - Avoid - Giving a prepared oral talk to a group";
  Quiz[189].Text = "LSAS - Fear - Trying to make someone's acquaintance for the purpose of a romantic/sexual relationship";
  Quiz[190].Text = "LSAS - Avoid - Trying to make someone's acquaintance for the purpose of a romantic/sexual relationship";
  Quiz[191].Text = "LSAS - Fear - Returning goods to a store for a refund";
  Quiz[192].Text = "LSAS - Avoid - Returning goods to a store for a refund";
  Quiz[193].Text = "LSAS - Fear - Giving a party";
  Quiz[194].Text = "LSAS - Avoid - Giving a party";
  Quiz[195].Text = "LSAS - Fear - Resisting a high pressure sales person";
  Quiz[196].Text = "LSAS - Avoid - Resisting a high pressure sales person";

  Quiz[197].Text = "Dyslexi";
  Quiz[198].Text = "Dyskaluli";
  Quiz[199].Text = "OCD";
  Quiz[200].Text = "ODD";
  Quiz[201].Text = "Bipolär";
  Quiz[202].Text = "Social fobi";

#endif

}

/*##########################################################################
#
#   Name       : TQuizS4::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS4::InitReferers()
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

/*##################  TQuizS4::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::LoadReferers()
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
#   Name       : TQuizS4::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS4::LoadPopulations()
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

		Row.Quiz[197] = Row.Dyslexia + 1;
		Row.Quiz[198] = Row.Dyscalculia + 1;
		Row.Quiz[199] = Row.OCD + 1;
		Row.Quiz[200] = Row.ODD + 1;
		Row.Quiz[201] = Row.Bipolar + 1;
		Row.Quiz[202] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
			    if (i < 197)
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
#   Name       : TQuizS4::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS4::SetupControlGroups()
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
#   Name       : TQuizS4::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS4::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3)
{
    DefineCross(QuizS3, 0, 0);
    DefineCross(QuizS3, 1, 1);
    DefineCross(QuizS3, 2, 2);
    DefineCross(QuizS3, 3, 3);
    DefineCross(QuizS3, 4, 4);
    DefineCross(QuizS3, 5, 5);
    DefineCross(QuizS3, 6, 6);
    DefineCross(QuizS3, 7, 7);
    DefineCross(QuizS3, 8, 8);
    DefineCross(QuizS3, 9, 9);
    DefineCross(QuizS3, 10, 10);
    DefineCross(QuizS3, 11, 11);
    DefineCross(QuizS3, 12, 12);
    DefineCross(QuizS3, 13, 13);
    DefineCross(QuizS3, 14, 14);
    DefineCross(QuizS3, 15, 15);
    DefineCross(QuizS3, 16, 16);
    DefineCross(QuizS3, 17, 17);
    DefineCross(QuizS3, 18, 18);
    DefineCross(QuizS3, 19, 19);
    DefineCross(QuizS3, 20, 20);
    DefineCross(QuizS3, 21, 21);
    DefineCross(QuizS3, 22, 22);
    DefineCross(QuizS3, 23, 23);
    DefineCross(QuizS3, 24, 24);
    DefineCross(QuizS3, 25, 25);
    DefineCross(QuizS3, 26, 26);
    DefineCross(QuizS3, 27, 27);
    DefineCross(QuizS3, 28, 28);
    DefineCross(QuizS3, 29, 29);
    DefineCross(QuizS3, 30, 30);
    DefineCross(QuizS3, 31, 31);
    DefineCross(QuizS3, 32, 32);
	DefineCross(QuizS3, 33, 33);
    DefineCross(QuizS3, 34, 34);
    DefineCross(QuizS3, 35, 35);
    DefineCross(QuizS3, 36, 36);
    DefineCross(QuizS3, 37, 37);
    DefineCross(QuizS3, 38, 38);
    DefineCross(QuizS3, 39, 39);
    DefineCross(QuizS3, 40, 41);
    DefineCross(QuizS3, 41, 42);
    DefineCross(QuizS3, 42, 43);
    DefineCross(QuizS3, 43, 45);
    DefineCross(QuizS3, 44, 44);
    DefineCross(QuizS3, 45, 48);
    DefineCross(QuizS3, 46, 47);
    DefineCross(QuizS3, 47, 49);
    DefineCross(QuizS3, 48, 46);
    DefineCross(QuizS3, 49, 50);
    DefineCross(QuizS3, 50, 51);
    DefineCross(QuizS3, 51, 52);
    DefineCross(QuizS3, 52, 53);
    DefineCross(QuizS3, 53, 54);
    DefineCross(QuizS3, 54, 55);
    DefineCross(QuizS3, 55, 56);
    DefineCross(QuizS3, 56, 57);
    DefineCross(QuizS3, 57, 58);
    DefineCross(QuizS3, 58, 59);
    DefineCross(QuizS3, 59, 60);
    DefineCross(QuizS3, 60, 61);
    DefineCross(QuizS3, 61, 62);
    DefineCross(QuizS3, 62, 63);
    DefineCross(QuizS3, 63, 64);
    DefineCross(QuizS3, 64, 66);
    DefineCross(QuizS3, 65, 67);
    DefineCross(QuizS3, 66, 68);
    DefineCross(QuizS3, 67, 69);
	DefineCross(QuizS3, 68, 70);
    DefineCross(QuizS3, 69, 71);
    DefineCross(QuizS3, 70, 72);
    DefineCross(QuizS3, 71, 73);
    DefineCross(QuizS3, 72, 74);
    DefineCross(QuizS3, 73, 75);
    DefineCross(QuizS3, 74, 76);
    DefineCross(QuizS3, 75, 77);
    DefineCross(QuizS3, 76, 78);
    DefineCross(QuizS3, 77, 79);
    DefineCross(QuizS3, 78, 80);
    DefineCross(QuizS3, 79, 81);
    DefineCross(QuizS3, 80, 106);
    DefineCross(QuizS3, 81, 82);
    DefineCross(QuizS3, 82, 83);
    DefineCross(QuizS3, 83, 84);
    DefineCross(QuizS3, 84, 135);
    DefineCross(QuizS3, 85, 85);
    DefineCross(QuizS3, 86, 87);
    DefineCross(QuizS3, 87, 86);
    DefineCross(QuizS3, 88, 88);
    DefineCross(QuizS3, 89, 90);
    DefineCross(QuizS3, 90, 89);
    DefineCross(QuizS3, 91, 91);
    DefineCross(QuizS3, 92, 92);
    DefineCross(QuizS3, 93, 93);
    DefineCross(QuizS3, 94, 94);
    DefineCross(QuizS3, 95, 95);
    DefineCross(QuizS3, 96, 96);
    DefineCross(QuizS3, 97, 98);
    DefineCross(QuizS3, 98, 97);
    DefineCross(QuizS3, 99, 99);
    DefineCross(QuizS3, 100, 101);
    DefineCross(QuizS3, 101, 102);
    DefineCross(QuizS3, 102, 100);
	DefineCross(QuizS3, 103, 103);
    DefineCross(QuizS3, 104, 104);
    DefineCross(QuizS3, 105, 105);
    DefineCross(QuizS3, 106, 107);
    DefineCross(QuizS3, 107, 108);
    DefineCross(QuizS3, 108, 109);
    DefineCross(QuizS3, 109, 110);
    DefineCross(QuizS3, 110, 111);
    DefineCross(QuizS3, 111, 112);
    DefineCross(QuizS3, 112, 113);
    DefineCross(QuizS3, 113, 115);
    DefineCross(QuizS3, 114, 114);
    DefineCross(QuizS3, 115, 116);
    DefineCross(QuizS3, 116, 117);
    DefineCross(QuizS3, 117, 118);
    DefineCross(QuizS3, 118, 120);
    DefineCross(QuizS3, 119, 119);
    DefineCross(QuizS3, 120, 121);
    DefineCross(QuizS3, 121, 123);
    DefineCross(QuizS3, 122, 122);
    DefineCross(QuizS3, 123, 124);
    DefineCross(QuizS3, 124, 125);
    DefineCross(QuizS3, 125, 126);
    DefineCross(QuizS3, 126, 127);
    DefineCross(QuizS3, 127, 133);
    DefineCross(QuizS3, 128, 40);
    DefineCross(QuizS3, 129, 132);
    DefineCross(QuizS3, 130, 130);
    DefineCross(QuizS3, 131, 131);

	DefineGlobalId(132, 855);
	DefineGlobalId(133, 856);
	DefineGlobalId(134, 857);
	DefineGlobalId(135, 858);
	DefineGlobalId(136, 859);
	DefineGlobalId(137, 860);
	DefineGlobalId(138, 861);
	DefineGlobalId(139, 862);
	DefineGlobalId(140, 863);
	DefineGlobalId(141, 864);
	DefineGlobalId(142, 865);
	DefineGlobalId(143, 866);
	DefineGlobalId(144, 867);
	DefineGlobalId(145, 868);
	DefineGlobalId(146, 869);
	DefineGlobalId(147, 870);
	DefineGlobalId(148, 871);

	DefineGlobalId(149, 872);
	DefineGlobalId(150, 873);
	DefineGlobalId(151, 874);
	DefineGlobalId(152, 875);
	DefineGlobalId(153, 876);
	DefineGlobalId(154, 877);
	DefineGlobalId(155, 878);
	DefineGlobalId(156, 879);
	DefineGlobalId(157, 880);
	DefineGlobalId(158, 881);
	DefineGlobalId(159, 882);
	DefineGlobalId(160, 883);
	DefineGlobalId(161, 884);
	DefineGlobalId(162, 885);
	DefineGlobalId(163, 886);
	DefineGlobalId(164, 887);
	DefineGlobalId(165, 888);
	DefineGlobalId(166, 889);
	DefineGlobalId(167, 890);
	DefineGlobalId(168, 891);
	DefineGlobalId(169, 892);
	DefineGlobalId(170, 893);
	DefineGlobalId(171, 894);
	DefineGlobalId(172, 895);
	DefineGlobalId(173, 896);
	DefineGlobalId(174, 897);
	DefineGlobalId(175, 898);
	DefineGlobalId(176, 899);
	DefineGlobalId(177, 900);
	DefineGlobalId(178, 901);
	DefineGlobalId(179, 902);
	DefineGlobalId(180, 903);
	DefineGlobalId(181, 904);
	DefineGlobalId(182, 905);
	DefineGlobalId(183, 906);
	DefineGlobalId(184, 907);
	DefineGlobalId(185, 908);
	DefineGlobalId(186, 909);
	DefineGlobalId(187, 910);
	DefineGlobalId(188, 911);
	DefineGlobalId(189, 912);
	DefineGlobalId(190, 913);
	DefineGlobalId(191, 914);
	DefineGlobalId(192, 915);
	DefineGlobalId(193, 916);
	DefineGlobalId(194, 917);
	DefineGlobalId(195, 918);
	DefineGlobalId(196, 919);

	DefineCross(QuizS3, 197, 210);
	DefineCross(QuizS3, 198, 211);
	DefineCross(QuizS3, 199, 212);
	DefineCross(QuizS3, 200, 213);
	DefineCross(QuizS3, 201, 214);
	DefineCross(QuizS3, 202, 215);
}

/*##########################################################################
#
#   Name       : TQuizS4::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS4::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizS4::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS4::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::ExportExcelAspie(const char *filename)
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
	    if (Row.LsasResult)
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

/*##################  TQuizS4::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS4::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::ImportMvsp(const char *filename, int PcaType)
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

/*##################  TQuizS4::WriteLSAS ##########################
*   Purpose....: Write LSAS test report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::WriteLSAS(const char *filename)
{
	int Count;
	long double AsSum;
	long double NtSum;
	long double DiffSum;
	long double LsasSum;
	long double AsMean;
	long double NtMean;
	long double DiffMean;
	long double LsasMean;
	long double AsSd;
	long double NtSd;
	long double DiffSd;
	long double LsasSd;
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
	LsasSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.LsasResult)
        {
			Count++;
			AsSum += Row.AsResult;
			NtSum += Row.NtResult;
			DiffSum += Row.AsResult - Row.NtResult;
			LsasSum += Row.LsasResult;
	    }
	}

	AsMean = AsSum / Count;
	NtMean = NtSum / Count;
	DiffMean = DiffSum / Count;
	LsasMean = LsasSum / Count;

	AsSum = 0;
	NtSum = 0;
	LsasSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.LsasResult)
        {
            val = (long double)Row.AsResult - AsMean;
   			AsSum += val * val;
   			
            val = (long double)Row.NtResult - NtMean;
			NtSum += val * val;
			
            val = (long double)(Row.AsResult - Row.NtResult) - DiffMean;
			DiffSum += val * val;

            val = (long double)Row.LsasResult - LsasMean;
			LsasSum += val * val;
	    }
	}

	AsSd = sqrtl(AsSum / (Count - 1));
	NtSd = sqrtl(NtSum / (Count - 1));
	DiffSd = sqrtl(DiffSum / (Count - 1));
	LsasSd = sqrtl(LsasSum / (Count - 1));

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.LsasResult)
        {
            zx = ((long double)Row.LsasResult - LsasMean) / LsasSd;

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
	printf("Mean LSAS score: %5.1Lf, SD: %5.1Lf\r\n", LsasMean, LsasSd);

	printf("LSAS - Aspie score correlation: %5.2Lf\r\n", AsCorr);
	printf("LSAS - NT score correlation: %5.2Lf\r\n", NtCorr);
	printf("LSAS - score diff correlation: %5.2Lf\r\n", DiffCorr);
}

/*##################  TQuizS4::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS4::WriteRetest(const char *filename)
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
