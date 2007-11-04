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
# quizs3.cpp
# Quiz stable release 3 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizs3.h"
#include "file.h"
#include "quizdbs3.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizS3::TQuizS3
#
#   Purpose....: Constructor for TQuizS3
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS3::TQuizS3(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2)
  : TQuiz(216),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizS3::~TQuizS3
#
#   Purpose....: Destructor for TQuizS3
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizS3::~TQuizS3()
{
}

/*##################  TQuizS3::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS3::GetPcaCount()
{
	return 4;
}

/*##################  TQuizS3::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizS3::GetCatCount(int Question)
{
    if (Question >= 136 && Question <= 209)
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
int TQuizS3::GetQuizN()
{
	return 134;
}

/*##########################################################################
#
#   Name       : TQuizS3::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS3::WriteName(TFile &File)
{
	 File.Write("S3");
}

/*##################  TQuizS3::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::DefineQuiz()
{
    return;
}

/*##########################################################################
#
#   Name       : TQuizS3::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS3::SetupTexts()
{
  Quiz[21].Reverse = TRUE;
  Quiz[40].Reverse = TRUE;
  Quiz[41].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[50].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[65].Reverse = TRUE;
  Quiz[116].Reverse = TRUE;
  Quiz[117].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[123].Reverse = TRUE;
  Quiz[124].Reverse = TRUE;
  Quiz[125].Reverse = TRUE;
  Quiz[127].Reverse = TRUE;
  Quiz[128].Reverse = TRUE;
  Quiz[129].Reverse = TRUE;
  Quiz[130].Reverse = TRUE;
  Quiz[131].Reverse = TRUE;
  Quiz[132].Reverse = TRUE;
  Quiz[133].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_NT_HUNTING;
  Quiz[1].MyGroup = GROUP_NT_HUNTING;
  Quiz[2].MyGroup = GROUP_NT_HUNTING;
  Quiz[3].MyGroup = GROUP_NT_HUNTING;
  Quiz[4].MyGroup = GROUP_NT_HUNTING;
  Quiz[5].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[6].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[7].MyGroup = GROUP_MIXED;
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
  Quiz[22].MyGroup = GROUP_NT_TALENT;
  Quiz[23].MyGroup = GROUP_NT_TALENT;
  Quiz[24].MyGroup = GROUP_NT_TALENT;
  Quiz[25].MyGroup = GROUP_NT_TALENT;
  Quiz[26].MyGroup = GROUP_MIXED;
  Quiz[27].MyGroup = GROUP_NT_TALENT;
  Quiz[28].MyGroup = GROUP_NT_TALENT;
  Quiz[29].MyGroup = GROUP_NT_NVC;
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
  Quiz[41].MyGroup = GROUP_NT_SOCIAL;
  Quiz[42].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[43].MyGroup = GROUP_NT_SOCIAL;
  Quiz[44].MyGroup = GROUP_NT_OBSESSION;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[54].MyGroup = GROUP_ENVIRONMENT;
  Quiz[55].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[56].MyGroup = GROUP_NT_TALENT;
  Quiz[57].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[58].MyGroup = GROUP_MIXED;
  Quiz[59].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[60].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[61].MyGroup = GROUP_NT_NVC;
  Quiz[62].MyGroup = GROUP_NT_TALENT;
  Quiz[63].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[64].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[65].MyGroup = GROUP_MIXED;
  Quiz[66].MyGroup = GROUP_NT_HUNTING;
  Quiz[67].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[68].MyGroup = GROUP_ENVIRONMENT;
  Quiz[69].MyGroup = GROUP_MIXED;
  Quiz[70].MyGroup = GROUP_MIXED;
  Quiz[71].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[72].MyGroup = GROUP_ENVIRONMENT;
  Quiz[73].MyGroup = GROUP_MIXED;
  Quiz[74].MyGroup = GROUP_MIXED;
  Quiz[75].MyGroup = GROUP_ENVIRONMENT;
  Quiz[76].MyGroup = GROUP_ENVIRONMENT;
  Quiz[77].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[78].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[79].MyGroup = GROUP_ENVIRONMENT;
  Quiz[80].MyGroup = GROUP_MIXED;
  Quiz[81].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[82].MyGroup = GROUP_MIXED;
  Quiz[83].MyGroup = GROUP_ENVIRONMENT;
  Quiz[84].MyGroup = GROUP_MIXED;
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
  Quiz[96].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_NVC;
  Quiz[100].MyGroup = GROUP_ASPIE_NVC;
  Quiz[101].MyGroup = GROUP_ASPIE_NVC;
  Quiz[102].MyGroup = GROUP_ASPIE_NVC;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_MIXED;
  Quiz[107].MyGroup = GROUP_ASPIE_NVC;
  Quiz[108].MyGroup = GROUP_NT_NVC;
  Quiz[109].MyGroup = GROUP_NT_NVC;
  Quiz[110].MyGroup = GROUP_MIXED;
  Quiz[111].MyGroup = GROUP_NT_NVC;
  Quiz[112].MyGroup = GROUP_NT_NVC;
  Quiz[113].MyGroup = GROUP_NT_NVC;
  Quiz[114].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[115].MyGroup = GROUP_NT_NVC;
  Quiz[116].MyGroup = GROUP_NT_NVC;
  Quiz[117].MyGroup = GROUP_NT_NVC;
  Quiz[118].MyGroup = GROUP_NT_NVC;
  Quiz[119].MyGroup = GROUP_NT_TALENT;
  Quiz[120].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[121].MyGroup = GROUP_NT_NVC;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_NT_SOCIAL;
  Quiz[124].MyGroup = GROUP_NT_NVC;
  Quiz[125].MyGroup = GROUP_NT_SOCIAL;
  Quiz[126].MyGroup = GROUP_NT_NVC;
  Quiz[127].MyGroup = GROUP_NT_NVC;
  Quiz[128].MyGroup = GROUP_NT_SOCIAL;
  Quiz[129].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[130].MyGroup = GROUP_ENVIRONMENT;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_NT_SOCIAL;
  Quiz[133].MyGroup = GROUP_NT_TALENT;

  Quiz[134].MyGroup = GROUP_RELIGION;
  Quiz[135].MyGroup = GROUP_PARANOID;
  Quiz[136].MyGroup = GROUP_RELIGION;
  Quiz[137].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[138].MyGroup = GROUP_RELIGION;
  Quiz[139].MyGroup = GROUP_PARANOID;
  Quiz[140].MyGroup = GROUP_ASPIE_NVC;
  Quiz[141].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[142].MyGroup = GROUP_ASPIE_NVC;
  Quiz[143].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[144].MyGroup = GROUP_PARANOID;
  Quiz[145].MyGroup = GROUP_PARANOID;
  Quiz[146].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[147].MyGroup = GROUP_RELIGION;
  Quiz[148].MyGroup = GROUP_RELIGION;
  Quiz[149].MyGroup = GROUP_ASPIE_NVC;
  Quiz[150].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[151].MyGroup = GROUP_MIXED;
  Quiz[152].MyGroup = GROUP_NT_SOCIAL;
  Quiz[153].MyGroup = GROUP_PARANOID;
  Quiz[154].MyGroup = GROUP_PARANOID;
  Quiz[155].MyGroup = GROUP_PARANOID;
  Quiz[156].MyGroup = GROUP_PARANOID;
  Quiz[157].MyGroup = GROUP_RELIGION;
  Quiz[158].MyGroup = GROUP_ASPIE_NVC;
  Quiz[159].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[160].MyGroup = GROUP_NT_TALENT;
  Quiz[161].MyGroup = GROUP_MIXED;
  Quiz[162].MyGroup = GROUP_PARANOID;
  Quiz[163].MyGroup = GROUP_RELIGION;
  Quiz[164].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[165].MyGroup = GROUP_RELIGION;
  Quiz[166].MyGroup = GROUP_PARANOID;
  Quiz[167].MyGroup = GROUP_PARANOID;
  Quiz[168].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[169].MyGroup = GROUP_MIXED;
  Quiz[170].MyGroup = GROUP_NT_NVC;
  Quiz[171].MyGroup = GROUP_PARANOID;
  Quiz[172].MyGroup = GROUP_RELIGION;
  Quiz[173].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[174].MyGroup = GROUP_RELIGION;
  Quiz[175].MyGroup = GROUP_RELIGION;
  Quiz[176].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[177].MyGroup = GROUP_PARANOID;
  Quiz[178].MyGroup = GROUP_NT_SOCIAL;
  Quiz[179].MyGroup = GROUP_PARANOID;
  Quiz[180].MyGroup = GROUP_PARANOID;
  Quiz[181].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[182].MyGroup = GROUP_RELIGION;
  Quiz[183].MyGroup = GROUP_PARANOID;
  Quiz[184].MyGroup = GROUP_PARANOID;
  Quiz[185].MyGroup = GROUP_RELIGION;
  Quiz[186].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[187].MyGroup = GROUP_PARANOID;
  Quiz[188].MyGroup = GROUP_PARANOID;
  Quiz[189].MyGroup = GROUP_MIXED;
  Quiz[190].MyGroup = GROUP_RELIGION;
  Quiz[191].MyGroup = GROUP_RELIGION;
  Quiz[192].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[193].MyGroup = GROUP_MIXED;
  Quiz[194].MyGroup = GROUP_PARANOID;
  Quiz[195].MyGroup = GROUP_PARANOID;
  Quiz[196].MyGroup = GROUP_RELIGION;
  Quiz[197].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[198].MyGroup = GROUP_PARANOID;
  Quiz[199].MyGroup = GROUP_RELIGION;
  Quiz[200].MyGroup = GROUP_PARANOID;
  Quiz[201].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[202].MyGroup = GROUP_MIXED;
  Quiz[203].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[204].MyGroup = GROUP_NT_NVC;
  Quiz[205].MyGroup = GROUP_ASPIE_NVC;
  Quiz[206].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[207].MyGroup = GROUP_PARANOID;
  Quiz[208].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[209].MyGroup = GROUP_PARANOID;

  Quiz[210].MyGroup = GROUP_NT_TALENT;
  Quiz[211].MyGroup = GROUP_NT_TALENT;
  Quiz[212].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[213].MyGroup = GROUP_MIXED;
  Quiz[214].MyGroup = GROUP_MIXED;
  Quiz[215].MyGroup = GROUP_ASPIE_SOCIAL;

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
  Quiz[40].Text = "Are you good at teamwork?";
  Quiz[41].Text = "Do you instinctively know how to behave when somebody shows interest in you as a potential partner?";
  Quiz[42].Text = "Do you feel uncomfortable with strangers?";
  Quiz[43].Text = "Are you good at social chitchat?";
  Quiz[44].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[45].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[46].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[47].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[48].Text = "Are your views typical of your peer group?";
  Quiz[49].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[50].Text = "Do you find it easy to describe your feelings?";
  Quiz[51].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[52].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[53].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[54].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[55].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[56].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[57].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[58].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[59].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[60].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[61].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[62].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[63].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[64].Text = "Do you have certain routines which you need to follow?";
  Quiz[65].Text = "Do you prefer the company of those of the same generation as yourself?";
  Quiz[66].Text = "Do you drop things when your attention is on other things?";
  Quiz[67].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[68].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[69].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[70].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[71].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[72].Text = "Are you sometimes afraid in safe situations?";
  Quiz[73].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[74].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[75].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[76].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[77].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[78].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[79].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[80].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[81].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[82].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[83].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[84].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[85].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[86].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[87].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[88].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[89].Text = "Do you often don't know where to put your arms?";
  Quiz[90].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[91].Text = "Have you been accused of staring?";
  Quiz[92].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[93].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[94].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[95].Text = "Do you fiddle with things?";
  Quiz[96].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[97].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[98].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[99].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[100].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[101].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[102].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[103].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[104].Text = "Do you talk to yourself?";
  Quiz[105].Text = "Do you stutter when stressed?";
  Quiz[106].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[107].Text = "Do you clench your fists when angry?";
  Quiz[108].Text = "Do others often misunderstand you?";
  Quiz[109].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[110].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[111].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[112].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[113].Text = "Are you often surprised what people's motives are ?";
  Quiz[114].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[115].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[116].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[117].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[118].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[119].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[120].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[121].Text = "Do you know when you are expected to offer an apology?";
  Quiz[122].Text = "Do you find it hard to tell the age of people?";
  Quiz[123].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[124].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[125].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[126].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[127].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[128].Text = "Does it feel natural for you to say 'thank you' and 'sorry'?";
  Quiz[129].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[130].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[131].Text = "Do you find it easy to estimate the age of people?";
  Quiz[132].Text = "Do people understand you?";
  Quiz[133].Text = "Can you easily remember verbal instructions?";

  Quiz[134].Text = "Have you been in love with more than one person at the same time?";
  Quiz[135].Text = "Have you have had long-lasting urges to take revenge?";

  Quiz[136].Text = "SPQ - Do you sometimes feel that things you see on the TV or read in the newspaper have a special meaning for you?";
  Quiz[137].Text = "SPQ - I sometimes avoid going to places where there will be many people because I will get anxious.";
  Quiz[138].Text = "SPQ - Have you had experiences with the supernatural?";
  Quiz[139].Text = "SPQ - Have you often mistaken objects or shadows for people, or noises for voices?";
  Quiz[140].Text = "SPQ - Other people see me as slightly eccentric (odd).";
  Quiz[141].Text = "SPQ - I have little interest in getting to know other people.";
  Quiz[142].Text = "SPQ - People sometimes find it hard to understand what I am saying.";
  Quiz[143].Text = "SPQ - People sometimes find me aloof and distant.";
  Quiz[144].Text = "SPQ - I am sure I am being talked about behind my back.";
  Quiz[145].Text = "SPQ - I am aware that people notice me when I go out for a meal or to see a film.";
  Quiz[146].Text = "SPQ - I get very nervous when I have to make polite conversation.";
  Quiz[147].Text = "SPQ - Do you believe in telepathy (mind-reading)?";
  Quiz[148].Text = "SPQ - Have you ever had the sense that some person or force is around you, even though you cannot see anyone?";
  Quiz[149].Text = "SPQ - People sometimes comment on my unusual mannerisms and habits.";
  Quiz[150].Text = "SPQ - I prefer to keep to myself.";
  Quiz[151].Text = "SPQ - I sometimes jump quickly from one topic to another when speaking.";
  Quiz[152].Text = "SPQ - I am poor at expressing my true feelings by the way I talk and look.";
  Quiz[153].Text = "SPQ - Do you often feel that other people have got it in for you?";
  Quiz[154].Text = "SPQ - Do some people drop hints about you or say things with a double meaning?";
  Quiz[155].Text = "SPQ - Do you ever get nervous when someone is walking behind you?";
  Quiz[156].Text = "SPQ - Are you sometimes sure that other people can tell what you are thinking?";
  Quiz[157].Text = "SPQ - When you look at a person, or yourself in a mirror, have you ever seen the face change right before your eyes?";
  Quiz[158].Text = "SPQ - Sometimes other people think that I am a little strange.";
  Quiz[159].Text = "SPQ - I am mostly quiet when with other people.";
  Quiz[160].Text = "SPQ - I sometimes forget what I am trying to say.";
  Quiz[161].Text = "SPQ - I rarely laugh and smile.";
  Quiz[162].Text = "SPQ - Do you sometimes get concerned that friends or co-workers are not really loyal or trustworthy?";
  Quiz[163].Text = "SPQ - Have you ever noticed a common event or object that seemed to be a special sign for you?";
  Quiz[164].Text = "SPQ - I get anxious when meeting people for the first time.";
  Quiz[165].Text = "SPQ - Do you believe in clairvoyancy (psychic forces, fortune telling)?";
  Quiz[166].Text = "SPQ - I often hear a voice speaking my thoughts aloud.";
  Quiz[167].Text = "SPQ - Some people think that I am a very bizarre person.";
  Quiz[168].Text = "SPQ - I find it hard to be emotionally close to other people.";
  Quiz[169].Text = "SPQ - I often ramble on too much when speaking.";
  Quiz[170].Text = "SPQ - My \"non-verbal\" communication (smiling and nodding during a Y N conversation) is poor.";
  Quiz[171].Text = "SPQ - I feel I have to be on my guard even with friends.";
  Quiz[172].Text = "SPQ - Do you sometimes see special meanings in advertisements, shop windows, or in the way things are arranged around you?";
  Quiz[173].Text = "SPQ - Do you often feel nervous when you are in a group of unfamiliar people?";
  Quiz[174].Text = "SPQ - Can other people feel your feelings when they are not there?";
  Quiz[175].Text = "SPQ - Have you ever seen things invisible to other people?";
  Quiz[176].Text = "SPQ - Do you feel that there is no-one you are really close to outside of your immediate family, or people you can confide in or talk to about personal problems?";
  Quiz[177].Text = "SPQ - Some people find me a bit vague and elusive during a conversation.";
  Quiz[178].Text = "SPQ - I am poor at returning social courtesies and gestures.";
  Quiz[179].Text = "SPQ - Do you often pick up hidden threats or put-downs from what people say or do?";
  Quiz[180].Text = "SPQ - When shopping do you get the feeling that other people are taking notice of you?";
  Quiz[181].Text = "SPQ - I feel very uncomfortable in social situations involving unfamiliar people.";
  Quiz[182].Text = "SPQ - Have you had experiences with astrology, seeing the future, UFOs, ESP or a sixth sense?";
  Quiz[183].Text = "SPQ - Do everyday things seem unusually large or small?";
  Quiz[184].Text = "SPQ - Writing letters to friends is more trouble than it is worth.";
  Quiz[185].Text = "SPQ - I sometimes use words in unusual ways.";
  Quiz[186].Text = "SPQ - I tend to avoid eye contact when conversing with others.";
  Quiz[187].Text = "SPQ - Have you found that it is best not to let other people know too much about you?";
  Quiz[188].Text = "SPQ - When you see people talking to each other, do you often wonder if they are talking about you?";
  Quiz[189].Text = "SPQ - I would feel very anxious if I had to give a speech in front of a large group of people.";
  Quiz[190].Text = "SPQ - Have you ever felt that you are communicating with another person telepathically (by mind-reading)?";
  Quiz[191].Text = "SPQ - Does your sense of smell sometimes become unusually strong?";
  Quiz[192].Text = "SPQ - I tend to keep in the background on social occasions.";
  Quiz[193].Text = "SPQ - Do you tend to wander off the topic when having a conversation.";
  Quiz[194].Text = "SPQ - I often feel that others have it in for me.";
  Quiz[195].Text = "SPQ - Do you sometimes feel that other people are watching you?";
  Quiz[196].Text = "SPQ - Do you ever suddenly feel distracted by distant sounds that you are not normally aware of?";
  Quiz[197].Text = "SPQ - I attach little importance to having close friends.";
  Quiz[198].Text = "SPQ - Do you sometimes feel that people are talking about you?";
  Quiz[199].Text = "SPQ - Are your thoughts sometimes so strong that you can almost hear them?";
  Quiz[200].Text = "SPQ - Do you often have to keep an eye out to stop people from taking advantage of you?";
  Quiz[201].Text = "SPQ - Do you feel that you are unable to get \"close\" to people?";
  Quiz[202].Text = "SPQ - I am an odd, unusual person.";
  Quiz[203].Text = "SPQ - I do not have an expressive and lively way of speaking.";
  Quiz[204].Text = "SPQ - I find it hard to communicate clearly what I want to say to people.";
  Quiz[205].Text = "SPQ - I have some eccentric (odd) habits.";
  Quiz[206].Text = "SPQ - I feel very uneasy talking to people I do not know well.";
  Quiz[207].Text = "SPQ - People occasionally comment that my conversation is confusing.";
  Quiz[208].Text = "SPQ - I tend to keep my feelings to myself.";
  Quiz[209].Text = "SPQ - People sometimes stare at me because of my odd appearance.";

  Quiz[210].Text = "Dyslexia";
  Quiz[211].Text = "Dyscalculia";
  Quiz[212].Text = "OCD";
  Quiz[213].Text = "ODD";
  Quiz[214].Text = "Bipolar";
  Quiz[215].Text = "Social phobia";

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
  Quiz[40].Text = "Är du bra på att arbeta i grupp?";
  Quiz[41].Text = "Vet du instinktivt hur du ska uppföra dig om någon visar intresse för dig som möjlig partner?";
  Quiz[42].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[43].Text = "Är du bra på kallprat?";
  Quiz[44].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[45].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[46].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[47].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[48].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[49].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[50].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[51].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[52].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[53].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[54].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[55].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[56].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[57].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[58].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[59].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[60].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[61].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[62].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[63].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[64].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[65].Text = "Umgås du helst med personer ur din egen generation?";
  Quiz[66].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[67].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[68].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[69].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[70].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[71].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[72].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[73].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[74].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[75].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[76].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[77].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[78].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[79].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[80].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[81].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[82].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[83].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[84].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[85].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[86].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[87].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[88].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[89].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[90].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[91].Text = "Har du blivit anklagad för att stirra?";
  Quiz[92].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[93].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[94].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[95].Text = "Brukar du fingra på saker?";
  Quiz[96].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[97].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[98].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[99].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[100].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[101].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[102].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[103].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[104].Text = "Brukar du prata med dig själv?";
  Quiz[105].Text = "Stammar du när du blir stressad?";
  Quiz[106].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[107].Text = "Knyter du nävarna när du är arg?";
  Quiz[108].Text = "Blir du ofta missförstådd av andra?";
  Quiz[109].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[110].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[111].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[112].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[113].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[114].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[115].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[116].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[117].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[118].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[119].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[120].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[121].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[122].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[123].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[124].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[125].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[126].Text = "Har du svårt att känna igen ansikten?";
  Quiz[127].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[128].Text = "Känns det naturligt för dig att säga 'tack' och 'förlåt'?";
  Quiz[129].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[130].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[131].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[132].Text = "Förstår sig folk på dig?";
  Quiz[133].Text = "Kommer du lätt ihåg verbala instruktioner?";

  Quiz[134].Text = "Har du varit kär i mer än en person åt gången?";
  Quiz[135].Text = "Har du haft långvariga hämndbegär?";

  Quiz[136].Text = "SPQ - Do you sometimes feel that things you see on the TV or read in the newspaper have a special meaning for you?";          
  Quiz[137].Text = "SPQ - I sometimes avoid going to places where there will be many people because I will get anxious.";
  Quiz[138].Text = "SPQ - Have you had experiences with the supernatural?";
  Quiz[139].Text = "SPQ - Have you often mistaken objects or shadows for people, or noises for voices?";
  Quiz[140].Text = "SPQ - Other people see me as slightly eccentric (odd).";
  Quiz[141].Text = "SPQ - I have little interest in getting to know other people.";
  Quiz[142].Text = "SPQ - People sometimes find it hard to understand what I am saying.";
  Quiz[143].Text = "SPQ - People sometimes find me aloof and distant.";
  Quiz[144].Text = "SPQ - I am sure I am being talked about behind my back.";
  Quiz[145].Text = "SPQ - I am aware that people notice me when I go out for a meal or to see a film.";
  Quiz[146].Text = "SPQ - I get very nervous when I have to make polite conversation.";
  Quiz[147].Text = "SPQ - Do you believe in telepathy (mind-reading)?";
  Quiz[148].Text = "SPQ - Have you ever had the sense that some person or force is around you, even though you cannot see anyone?";
  Quiz[149].Text = "SPQ - People sometimes comment on my unusual mannerisms and habits.";
  Quiz[150].Text = "SPQ - I prefer to keep to myself.";
  Quiz[151].Text = "SPQ - I sometimes jump quickly from one topic to another when speaking.";
  Quiz[152].Text = "SPQ - I am poor at expressing my true feelings by the way I talk and look.";
  Quiz[153].Text = "SPQ - Do you often feel that other people have got it in for you?";
  Quiz[154].Text = "SPQ - Do some people drop hints about you or say things with a double meaning?";
  Quiz[155].Text = "SPQ - Do you ever get nervous when someone is walking behind you?";
  Quiz[156].Text = "SPQ - Are you sometimes sure that other people can tell what you are thinking?";
  Quiz[157].Text = "SPQ - When you look at a person, or yourself in a mirror, have you ever seen the face change right before your eyes?";
  Quiz[158].Text = "SPQ - Sometimes other people think that I am a little strange.";
  Quiz[159].Text = "SPQ - I am mostly quiet when with other people.";
  Quiz[160].Text = "SPQ - I sometimes forget what I am trying to say.";
  Quiz[161].Text = "SPQ - I rarely laugh and smile.";
  Quiz[162].Text = "SPQ - Do you sometimes get concerned that friends or co-workers are not really loyal or trustworthy?";
  Quiz[163].Text = "SPQ - Have you ever noticed a common event or object that seemed to be a special sign for you?";
  Quiz[164].Text = "SPQ - I get anxious when meeting people for the first time.";
  Quiz[165].Text = "SPQ - Do you believe in clairvoyancy (psychic forces, fortune telling)?";
  Quiz[166].Text = "SPQ - I often hear a voice speaking my thoughts aloud.";
  Quiz[167].Text = "SPQ - Some people think that I am a very bizarre person.";
  Quiz[168].Text = "SPQ - I find it hard to be emotionally close to other people.";
  Quiz[169].Text = "SPQ - I often ramble on too much when speaking.";
  Quiz[170].Text = "SPQ - My \"non-verbal\" communication (smiling and nodding during a Y N conversation) is poor.";
  Quiz[171].Text = "SPQ - I feel I have to be on my guard even with friends.";
  Quiz[172].Text = "SPQ - Do you sometimes see special meanings in advertisements, shop windows, or in the way things are arranged around you?";
  Quiz[173].Text = "SPQ - Do you often feel nervous when you are in a group of unfamiliar people?";
  Quiz[174].Text = "SPQ - Can other people feel your feelings when they are not there?";
  Quiz[175].Text = "SPQ - Have you ever seen things invisible to other people?";
  Quiz[176].Text = "SPQ - Do you feel that there is no-one you are really close to outside of your immediate family, or people you can confide in or talk to about personal problems?";
  Quiz[177].Text = "SPQ - Some people find me a bit vague and elusive during a conversation.";
  Quiz[178].Text = "SPQ - I am poor at returning social courtesies and gestures.";
  Quiz[179].Text = "SPQ - Do you often pick up hidden threats or put-downs from what people say or do?";
  Quiz[180].Text = "SPQ - When shopping do you get the feeling that other people are taking notice of you?";
  Quiz[181].Text = "SPQ - I feel very uncomfortable in social situations involving unfamiliar people.";
  Quiz[182].Text = "SPQ - Have you had experiences with astrology, seeing the future, UFOs, ESP or a sixth sense?";
  Quiz[183].Text = "SPQ - Do everyday things seem unusually large or small?";
  Quiz[184].Text = "SPQ - Writing letters to friends is more trouble than it is worth.";
  Quiz[185].Text = "SPQ - I sometimes use words in unusual ways.";
  Quiz[186].Text = "SPQ - I tend to avoid eye contact when conversing with others.";
  Quiz[187].Text = "SPQ - Have you found that it is best not to let other people know too much about you?";
  Quiz[188].Text = "SPQ - When you see people talking to each other, do you often wonder if they are talking about you?";
  Quiz[189].Text = "SPQ - I would feel very anxious if I had to give a speech in front of a large group of people.";
  Quiz[190].Text = "SPQ - Have you ever felt that you are communicating with another person telepathically (by mind-reading)?";
  Quiz[191].Text = "SPQ - Does your sense of smell sometimes become unusually strong?";
  Quiz[192].Text = "SPQ - I tend to keep in the background on social occasions.";
  Quiz[193].Text = "SPQ - Do you tend to wander off the topic when having a conversation.";
  Quiz[194].Text = "SPQ - I often feel that others have it in for me.";
  Quiz[195].Text = "SPQ - Do you sometimes feel that other people are watching you?";
  Quiz[196].Text = "SPQ - Do you ever suddenly feel distracted by distant sounds that you are not normally aware of?";
  Quiz[197].Text = "SPQ - I attach little importance to having close friends.";
  Quiz[198].Text = "SPQ - Do you sometimes feel that people are talking about you?";
  Quiz[199].Text = "SPQ - Are your thoughts sometimes so strong that you can almost hear them?";
  Quiz[200].Text = "SPQ - Do you often have to keep an eye out to stop people from taking advantage of you?";
  Quiz[201].Text = "SPQ - Do you feel that you are unable to get \"close\" to people?";
  Quiz[202].Text = "SPQ - I am an odd, unusual person.";
  Quiz[203].Text = "SPQ - I do not have an expressive and lively way of speaking.";
  Quiz[204].Text = "SPQ - I find it hard to communicate clearly what I want to say to people.";
  Quiz[205].Text = "SPQ - I have some eccentric (odd) habits.";
  Quiz[206].Text = "SPQ - I feel very uneasy talking to people I do not know well.";
  Quiz[207].Text = "SPQ - People occasionally comment that my conversation is confusing.";
  Quiz[208].Text = "SPQ - I tend to keep my feelings to myself.";
  Quiz[209].Text = "SPQ - People sometimes stare at me because of my odd appearance.";

  Quiz[210].Text = "Dyslexi";
  Quiz[211].Text = "Dyskaluli";
  Quiz[212].Text = "OCD";
  Quiz[213].Text = "ODD";
  Quiz[214].Text = "Bipolär";
  Quiz[215].Text = "Social fobi";

#endif  

}

/*##########################################################################
#
#   Name       : TQuizS3::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS3::InitReferers()
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
}

/*##################  TQuizS3::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::LoadReferers()
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
#   Name       : TQuizS3::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS3::LoadPopulations()
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

		Row.Quiz[210] = Row.Dyslexia + 1;
		Row.Quiz[211] = Row.Dyscalculia + 1;
		Row.Quiz[212] = Row.OCD + 1;
		Row.Quiz[213] = Row.ODD + 1;
		Row.Quiz[214] = Row.Bipolar + 1;
		Row.Quiz[215] = Row.Social + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
			    if (i < 210)
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
#   Name       : TQuizS3::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS3::SetupControlGroups()
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

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizS3::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS3::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2)
{
    DefineCross(QuizS2, 0, 0);
    DefineCross(QuizS2, 1, 1);
    DefineCross(QuizS2, 2, 2);
    DefineCross(QuizS2, 3, 3);
    DefineCross(QuizS2, 4, 4);
    DefineCross(QuizS2, 5, 5);
    DefineCross(QuizS2, 6, 6);
    DefineCross(QuizS2, 7, 7);
    DefineCross(QuizS2, 8, 8);
    DefineCross(QuizS2, 9, 9);
    DefineCross(QuizS2, 10, 10);
    DefineCross(QuizS2, 11, 11);
    DefineCross(QuizS2, 12, 12);
    DefineCross(QuizS2, 13, 13);
    DefineCross(QuizS2, 14, 14);
    DefineCross(QuizS2, 15, 15);
    DefineCross(QuizS2, 16, 16);
    DefineCross(QuizS2, 17, 17);
    DefineCross(QuizS2, 18, 18);
    DefineCross(QuizS2, 19, 19);
    DefineCross(QuizS2, 20, 20);
    DefineCross(QuizS2, 21, 21);
    DefineCross(QuizS2, 22, 22);
    DefineCross(QuizS2, 23, 23);
    DefineCross(QuizS2, 24, 24);
    DefineCross(QuizS2, 25, 25);
    DefineCross(QuizS2, 26, 26);
    DefineCross(QuizS2, 27, 27);
	DefineCross(QuizS2, 28, 28);
	DefineCross(QuizS2, 29, 29);
	DefineCross(QuizS2, 30, 155);
    DefineCross(QuizS2, 31, 30);
    DefineCross(QuizS2, 32, 31);
    DefineCross(QuizS2, 33, 33);
    DefineCross(QuizS2, 34, 34);
    DefineCross(QuizS2, 35, 35);
    DefineCross(QuizS2, 36, 36);
    DefineCross(QuizS2, 37, 38);
    DefineCross(QuizS2, 38, 37);
    DefineCross(QuizS2, 39, 39);
    DefineCross(QuizS2, 40, 40);
    DefineCross(QuizS2, 41, 157);
    DefineCross(QuizS2, 42, 42);
    DefineCross(QuizS2, 43, 46);
    DefineCross(QuizS2, 44, 47);
    DefineCross(QuizS2, 45, 48);
    DefineCross(QuizS2, 46, 49);
    DefineCross(QuizS2, 47, 50);
    DefineCross(QuizS2, 48, 51);
    DefineCross(QuizS2, 49, 53);
    DefineCross(QuizS2, 50, 52);
    DefineCross(QuizS2, 51, 54);
    DefineCross(QuizS2, 52, 55);
    DefineCross(QuizS2, 53, 57);
    DefineCross(QuizS2, 54, 58);
    DefineCross(QuizS2, 55, 59);
    DefineCross(QuizS2, 56, 60);
    DefineCross(QuizS2, 57, 61);
    DefineCross(QuizS2, 58, 62);
    DefineCross(QuizS2, 59, 63);
    DefineCross(QuizS2, 60, 64);
    DefineCross(QuizS2, 61, 67);
    DefineCross(QuizS2, 62, 65);
    DefineCross(QuizS2, 63, 66);
    DefineCross(QuizS2, 64, 68);
	DefineGlobalId(65, 778);
    DefineCross(QuizS2, 66, 70);
    DefineCross(QuizS2, 67, 71);
    DefineCross(QuizS2, 68, 73);
    DefineCross(QuizS2, 69, 74);
    DefineCross(QuizS2, 70, 75);
    DefineCross(QuizS2, 71, 76);
    DefineCross(QuizS2, 72, 77);
    DefineCross(QuizS2, 73, 78);
    DefineCross(QuizS2, 74, 79);
    DefineCross(QuizS2, 75, 80);
    DefineCross(QuizS2, 76, 81);
    DefineCross(QuizS2, 77, 82);
    DefineCross(QuizS2, 78, 84);
    DefineCross(QuizS2, 79, 85);
    DefineCross(QuizS2, 80, 86);
    DefineCross(QuizS2, 81, 87);
    DefineCross(QuizS2, 82, 89);
    DefineCross(QuizS2, 83, 88);
    DefineCross(QuizS2, 84, 90);
    DefineCross(QuizS2, 85, 91);
    DefineCross(QuizS2, 86, 153);
    DefineCross(QuizS2, 87, 92);
    DefineCross(QuizS2, 88, 72);
    DefineCross(QuizS2, 89, 93);
    DefineCross(QuizS2, 90, 95);
    DefineCross(QuizS2, 91, 94);
    DefineCross(QuizS2, 92, 96);
    DefineCross(QuizS2, 93, 97);
    DefineCross(QuizS2, 94, 98);
    DefineCross(QuizS2, 95, 99);
    DefineCross(QuizS2, 96, 100);
    DefineCross(QuizS2, 97, 101);
    DefineCross(QuizS2, 98, 102);
    DefineCross(QuizS2, 99, 103);
    DefineCross(QuizS2, 100, 104);
    DefineCross(QuizS2, 101, 105);
    DefineCross(QuizS2, 102, 106);
    DefineCross(QuizS2, 103, 107);
    DefineCross(QuizS2, 104, 108);
    DefineCross(QuizS2, 105, 109);
    DefineCross(QuizS2, 106, 110);
    DefineCross(QuizS2, 107, 112);
    DefineCross(QuizS2, 108, 113);
    DefineCross(QuizS2, 109, 114);
    DefineCross(QuizS2, 110, 115);
    DefineCross(QuizS2, 111, 116);
    DefineCross(QuizS2, 112, 117);
    DefineCross(QuizS2, 113, 118);
    DefineCross(QuizS2, 114, 119);
    DefineCross(QuizS2, 115, 120);
    DefineCross(QuizS2, 116, 121);
    DefineCross(QuizS2, 117, 122);
    DefineCross(QuizS2, 118, 123);
    DefineCross(QuizS2, 119, 124);
    DefineCross(QuizS2, 120, 125);
    DefineCross(QuizS2, 121, 126);
    DefineCross(QuizS2, 122, 127);
    DefineCross(QuizS2, 123, 128);
    DefineCross(QuizS2, 124, 129);
    DefineCross(QuizS2, 125, 130);
    DefineCross(QuizS2, 126, 131);
    DefineCross(QuizS2, 127, 133);
    DefineCross(QuizS2, 128, 134);
    DefineCross(QuizS2, 129, 137);
    DefineCross(QuizS2, 130, 138);
    DefineCross(QuizS2, 131, 139);
    DefineCross(QuizS2, 132, 135);
    DefineCross(QuizS2, 133, 136);

	DefineGlobalId(134, 779);
	DefineGlobalId(135, 780);
	DefineGlobalId(136, 781);
	DefineGlobalId(137, 782);
	DefineGlobalId(138, 783);
	DefineGlobalId(139, 784);
	DefineGlobalId(140, 785);
	DefineGlobalId(141, 786);
	DefineGlobalId(142, 787);
	DefineGlobalId(143, 788);
	DefineGlobalId(144, 789);
	DefineGlobalId(145, 790);
	DefineGlobalId(146, 791);
	DefineGlobalId(147, 792);
	DefineGlobalId(148, 793);
	DefineGlobalId(149, 794);
	DefineGlobalId(150, 795);
	DefineGlobalId(151, 796);
	DefineGlobalId(152, 797);
	DefineGlobalId(153, 798);
	DefineGlobalId(154, 799);
	DefineGlobalId(155, 800);
	DefineGlobalId(156, 801);
	DefineGlobalId(157, 802);
	DefineGlobalId(158, 803);
	DefineGlobalId(159, 804);
	DefineGlobalId(160, 805);
	DefineGlobalId(161, 806);
	DefineGlobalId(162, 807);
	DefineGlobalId(163, 808);
	DefineGlobalId(164, 809);
	DefineGlobalId(165, 810);
	DefineGlobalId(166, 811);
	DefineGlobalId(167, 812);
	DefineGlobalId(168, 813);
	DefineGlobalId(169, 814);
	DefineGlobalId(170, 815);
	DefineGlobalId(171, 816);
	DefineGlobalId(172, 817);
	DefineGlobalId(173, 818);
	DefineGlobalId(174, 819);
	DefineGlobalId(175, 820);
	DefineGlobalId(176, 821);
	DefineGlobalId(177, 822);
	DefineGlobalId(178, 823);
	DefineGlobalId(179, 824);
	DefineGlobalId(180, 825);
	DefineGlobalId(181, 826);
	DefineGlobalId(182, 827);
	DefineGlobalId(183, 828);
	DefineGlobalId(184, 829);
	DefineGlobalId(185, 830);
	DefineGlobalId(186, 831);
	DefineGlobalId(187, 832);
	DefineGlobalId(188, 833);
	DefineGlobalId(189, 834);
	DefineGlobalId(190, 835);
	DefineGlobalId(191, 836);
	DefineGlobalId(192, 837);
	DefineGlobalId(193, 838);
	DefineGlobalId(194, 839);
	DefineGlobalId(195, 840);
	DefineGlobalId(196, 841);
	DefineGlobalId(197, 842);
	DefineGlobalId(198, 843);
	DefineGlobalId(199, 844);
	DefineGlobalId(200, 845);
	DefineGlobalId(201, 846);
	DefineGlobalId(202, 847);
	DefineGlobalId(203, 848);
	DefineGlobalId(204, 849);
	DefineGlobalId(205, 850);
	DefineGlobalId(206, 851);
	DefineGlobalId(207, 852);
	DefineGlobalId(208, 853);
	DefineGlobalId(209, 854);

	DefineCross(QuizS2, 210, 140);
	DefineCross(QuizS2, 211, 141);
	DefineCross(QuizS2, 212, 142);
	DefineCross(QuizS2, 213, 143);
	DefineCross(QuizS2, 214, 144);
	DefineCross(QuizS2, 215, 145);

}

/*##########################################################################
#
#   Name       : TQuizS3::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizS3::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizS3::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizS3::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::ExportExcelAspie(const char *filename)
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
	    if (Row.SpqResult)
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

/*##################  TQuizS3::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::ExportExcelGroups(const char *filename)
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

/*##################  TQuizS3::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::ImportMvsp(const char *filename, int PcaType)
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

/*##################  TQuizS3::WriteSPQ ##########################
*   Purpose....: Write SPQ test report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::WriteSPQ(const char *filename)
{
	int Count;
	long double AsSum;
	long double NtSum;
	long double DiffSum;
	long double SpqSum;
	long double AsMean;
	long double NtMean;
	long double DiffMean;
	long double SpqMean;
	long double AsSd;
	long double NtSd;
	long double DiffSd;
	long double SpqSd;
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
	SpqSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.SpqResult)
        {
			Count++;
			AsSum += Row.AsResult;
			NtSum += Row.NtResult;
			DiffSum += Row.AsResult - Row.NtResult;
			SpqSum += Row.SpqResult;
	    }
	}

	AsMean = AsSum / Count;
	NtMean = NtSum / Count;
	DiffMean = DiffSum / Count;
	SpqMean = SpqSum / Count;

	AsSum = 0;
	NtSum = 0;
	SpqSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.SpqResult)
        {
            val = (long double)Row.AsResult - AsMean;
   			AsSum += val * val;
   			
            val = (long double)Row.NtResult - NtMean;
			NtSum += val * val;
			
            val = (long double)(Row.AsResult - Row.NtResult) - DiffMean;
			DiffSum += val * val;

            val = (long double)Row.SpqResult - SpqMean;
			SpqSum += val * val;
	    }
	}

	AsSd = sqrtl(AsSum / (Count - 1));
	NtSd = sqrtl(NtSum / (Count - 1));
	DiffSd = sqrtl(DiffSum / (Count - 1));
	SpqSd = sqrtl(SpqSum / (Count - 1));

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.SpqResult)
        {
            zx = ((long double)Row.SpqResult - SpqMean) / SpqSd;

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
	printf("Mean SPQ score: %5.1Lf, SD: %5.1Lf\r\n", SpqMean, SpqSd);

	printf("SPQ - Aspie score correlation: %5.2Lf\r\n", AsCorr);
	printf("SPQ - NT score correlation: %5.2Lf\r\n", NtCorr);
	printf("SPQ - score diff correlation: %5.2Lf\r\n", DiffCorr);
}

/*##################  TQuizS3::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizS3::WriteRetest(const char *filename)
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
	long double QMean[135];
	long double AsSd;
	long double NtSd;
	long double QSd[135];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[135];
	int QCount[135];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[135][20];
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

    for (q = 0; q < 135; q++)
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

                    for (q = 0; q < 135; q++)
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

                	        for (q = 0; q < 135; q++)
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
    
	    			for (q = 0; q < 135; q++)
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

	    			for (q = 0; q < 135; q++)
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

	for (q = 0; q < 135; q++)
	{
	    sprintf(str, "%d. ", q + 1);
	    file.Write(str);
	    
		file.Write(Quiz[q].Text);
	    
	    sd = QTot[q] / QCount[q];

        sprintf(str, " <b>%3.2Lf</b><br>", sd);
    	file.Write(str);
    }
}
