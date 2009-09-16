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
# quizr7.cpp
# Quiz R7 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr7.h"
#include "file.h"
#include "quizdbr7.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizR7::TQuizR7
#
#   Purpose....: Constructor for TQuizR7
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR7::TQuizR7(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6)
  : TQuiz(150),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR7::~TQuizR7
#
#   Purpose....: Destructor for TQuizR7
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR7::~TQuizR7()
{
}

/*##################  TQuizR7::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR7::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR7::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::WriteName(TFile &File)
{
	 File.Write("R7");
}

/*##########################################################################
#
#   Name       : TQuizR7::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::WriteLongName(TFile &File)
{
	 File.Write("experimental version 7");
}

/*##################  TQuizR7::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR7::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR7::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::SetupTexts()
{
  Quiz[6].Reverse = TRUE;
  Quiz[38].Reverse = TRUE;
  Quiz[41].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[44].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[59].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[63].Reverse = TRUE;
  Quiz[83].Reverse = TRUE;
  Quiz[119].Reverse = TRUE;
  Quiz[123].Reverse = TRUE;
  Quiz[126].Reverse = TRUE;
  Quiz[128].Reverse = TRUE;
  Quiz[136].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;
  Quiz[141].Reverse = TRUE;
  Quiz[143].Reverse = TRUE;
  Quiz[144].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_MIXED;
  Quiz[1].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[2].MyGroup = GROUP_NT_SENSORY;
  Quiz[3].MyGroup = GROUP_NT_SENSORY;
  Quiz[4].MyGroup = GROUP_NT_SENSORY;
  Quiz[5].MyGroup = GROUP_NT_SENSORY;
  Quiz[6].MyGroup = GROUP_NT_SENSORY;
  Quiz[7].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[8].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[9].MyGroup = GROUP_ASPIE_NVC;
  Quiz[10].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[11].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[12].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[13].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[14].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[15].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[16].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[17].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[18].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[19].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[23].MyGroup = GROUP_NT_TALENT;
  Quiz[24].MyGroup = GROUP_NT_HUNTING;
  Quiz[25].MyGroup = GROUP_NT_NVC;
  Quiz[26].MyGroup = GROUP_NT_SOCIAL;
  Quiz[27].MyGroup = GROUP_NT_SOCIAL;
  Quiz[28].MyGroup = GROUP_NT_NVC;
  Quiz[29].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[30].MyGroup = GROUP_NT_SOCIAL;
  Quiz[31].MyGroup = GROUP_NT_SOCIAL;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_NT_NVC;
  Quiz[34].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[35].MyGroup = GROUP_ENVIRONMENT;
  Quiz[36].MyGroup = GROUP_NT_SOCIAL;
  Quiz[37].MyGroup = GROUP_NT_SOCIAL;
  Quiz[38].MyGroup = GROUP_NT_SOCIAL;
  Quiz[39].MyGroup = GROUP_NT_SOCIAL;
  Quiz[40].MyGroup = GROUP_MIXED;
  Quiz[41].MyGroup = GROUP_NT_SOCIAL;
  Quiz[42].MyGroup = GROUP_ENVIRONMENT;
  Quiz[43].MyGroup = GROUP_NT_NVC;
  Quiz[44].MyGroup = GROUP_NT_NVC;
  Quiz[45].MyGroup = GROUP_NT_SOCIAL;
  Quiz[46].MyGroup = GROUP_NT_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_OBSESSION;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_NVC;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_NT_SOCIAL;
  Quiz[54].MyGroup = GROUP_NT_OBSESSION;
  Quiz[55].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[56].MyGroup = GROUP_NT_OBSESSION;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_NT_OBSESSION;
  Quiz[60].MyGroup = GROUP_NT_OBSESSION;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
  Quiz[62].MyGroup = GROUP_ASPIE_NVC;
  Quiz[63].MyGroup = GROUP_NT_OBSESSION;
  Quiz[64].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[65].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[66].MyGroup = GROUP_ENVIRONMENT;
  Quiz[67].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[68].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[69].MyGroup = GROUP_NT_TALENT;
  Quiz[70].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[71].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[72].MyGroup = GROUP_NT_NVC;
  Quiz[73].MyGroup = GROUP_NT_HUNTING;
  Quiz[74].MyGroup = GROUP_MIXED;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[77].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[81].MyGroup = GROUP_ENVIRONMENT;
  Quiz[82].MyGroup = GROUP_NT_TALENT;
  Quiz[83].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[84].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[85].MyGroup = GROUP_ASPIE_NVC;
  Quiz[86].MyGroup = GROUP_NT_TALENT;
  Quiz[87].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[88].MyGroup = GROUP_ENVIRONMENT;
  Quiz[89].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[90].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[91].MyGroup = GROUP_ASPIE_NVC;
  Quiz[92].MyGroup = GROUP_ASPIE_NVC;
  Quiz[93].MyGroup = GROUP_ENVIRONMENT;
  Quiz[94].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[95].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[96].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[97].MyGroup = GROUP_ASPIE_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_NVC;
  Quiz[100].MyGroup = GROUP_ASPIE_NVC;
  Quiz[101].MyGroup = GROUP_ASPIE_NVC;
  Quiz[102].MyGroup = GROUP_ASPIE_NVC;
  Quiz[103].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_ASPIE_NVC;
  Quiz[107].MyGroup = GROUP_ASPIE_NVC;
  Quiz[108].MyGroup = GROUP_ASPIE_NVC;
  Quiz[109].MyGroup = GROUP_ASPIE_NVC;
  Quiz[110].MyGroup = GROUP_NT_NVC;
  Quiz[111].MyGroup = GROUP_NT_NVC;
  Quiz[112].MyGroup = GROUP_NT_TALENT;
  Quiz[113].MyGroup = GROUP_NT_NVC;
  Quiz[114].MyGroup = GROUP_NT_NVC;
  Quiz[115].MyGroup = GROUP_NT_TALENT;
  Quiz[116].MyGroup = GROUP_ASPIE_NVC;
  Quiz[117].MyGroup = GROUP_NT_NVC;
  Quiz[118].MyGroup = GROUP_NT_NVC;
  Quiz[119].MyGroup = GROUP_NT_NVC;
  Quiz[120].MyGroup = GROUP_NT_NVC;
  Quiz[121].MyGroup = GROUP_NT_NVC;
  Quiz[122].MyGroup = GROUP_ASPIE_NVC;
  Quiz[123].MyGroup = GROUP_NT_NVC;
  Quiz[124].MyGroup = GROUP_NT_NVC;
  Quiz[125].MyGroup = GROUP_NT_NVC;
  Quiz[126].MyGroup = GROUP_NT_NVC;
  Quiz[127].MyGroup = GROUP_NT_TALENT;
  Quiz[128].MyGroup = GROUP_NT_NVC;
  Quiz[129].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[130].MyGroup = GROUP_NT_NVC;
  Quiz[131].MyGroup = GROUP_ASPIE_NVC;
  Quiz[132].MyGroup = GROUP_NT_SENSORY;
  Quiz[133].MyGroup = GROUP_NT_SENSORY;
  Quiz[134].MyGroup = GROUP_ENVIRONMENT;
  Quiz[135].MyGroup = GROUP_ENVIRONMENT;
  Quiz[136].MyGroup = GROUP_NT_OBSESSION;
  Quiz[137].MyGroup = GROUP_NT_SENSORY;
  Quiz[138].MyGroup = GROUP_NT_TALENT;
  Quiz[139].MyGroup = GROUP_NT_NVC;
  Quiz[140].MyGroup = GROUP_NT_NVC;
  Quiz[141].MyGroup = GROUP_NT_NVC;
  Quiz[142].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[143].MyGroup = GROUP_NT_TALENT;
  Quiz[144].MyGroup = GROUP_ENVIRONMENT;
  Quiz[145].MyGroup = GROUP_NT_SENSORY;
  Quiz[146].MyGroup = GROUP_NT_NVC;
  Quiz[147].MyGroup = GROUP_NT_NVC;
  Quiz[148].MyGroup = GROUP_NT_TALENT;
  Quiz[149].MyGroup = GROUP_NT_OBSESSION;

#ifdef ENGLISH
  Quiz[0].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[1].Text = "Do you have odd teeth; e.g. that are crooked, bigger than usual; that have gaps, overlaps, underbite or that show extra much gum?";
  Quiz[2].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[3].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[4].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[5].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[6].Text = "Can you easily judge distance, height, depth and speed?";
  Quiz[7].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
  Quiz[8].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[9].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[10].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[11].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[12].Text = "Do you have a very acute sense of smell and/or taste?";
  Quiz[13].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[14].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[15].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[16].Text = "Do you have unconventional ways of solving problems?";
  Quiz[17].Text = "Do you notice patterns in things all the time?";
  Quiz[18].Text = "Do you have a hyperactive mind?";
  Quiz[19].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[20].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[21].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[22].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[23].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[24].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[25].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[26].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[27].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[28].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[29].Text = "Have you felt different from others for most of your life?";
  Quiz[30].Text = "Have you had more difficulties than others making friends?";
  Quiz[31].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[32].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[33].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[34].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[35].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[36].Text = "Do you dislike shaking hands?";
  Quiz[37].Text = "Do you prefer to avoid eye-contact?";
  Quiz[38].Text = "Are you good at social chitchat?";
  Quiz[39].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[40].Text = "Have you had a tendency to prefer the company of those who are older or younger than yourself?";
  Quiz[41].Text = "Are you good at teamwork?";
  Quiz[42].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[43].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[44].Text = "Do you find the usual courting behavior natural?";
  Quiz[45].Text = "Do you find it easy to maintain your social network?";
  Quiz[46].Text = "Do you feel uncomfortable with strangers?";
  Quiz[47].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[48].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[49].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[50].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[51].Text = "Do you find it easy to describe your feelings?";
  Quiz[52].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[53].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[54].Text = "Are you energised by being in the company of others?";
  Quiz[55].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[56].Text = "Are your views typical of your peer group?";
  Quiz[57].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[58].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[59].Text = "Do you enjoy being in a big crowd, such as a football game?";
  Quiz[60].Text = "Is a large social network important to you?";
  Quiz[61].Text = "Does it feel natural for you to say 'thank you' and 'sorry'?";
  Quiz[62].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[63].Text = "Do you enjoy meeting new people?";
  Quiz[64].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[65].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[66].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[67].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[68].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[69].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[70].Text = "Do you have certain routines which you need to follow?";
  Quiz[71].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[72].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[73].Text = "Do you drop things when your attention is on other things?";
  Quiz[74].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[75].Text = "Do you rehearse inside your head?";
  Quiz[76].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[77].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[78].Text = "Have you been accused of staring?";
  Quiz[79].Text = "Do you often don't know where to put your arms?";
  Quiz[80].Text = "Do you have unusual eating habits?";
  Quiz[81].Text = "Are you sometimes afraid in safe situations?";
  Quiz[82].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[83].Text = "Is your sense of humor fairly conventional?";
  Quiz[84].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[85].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[86].Text = "Are you easily distracted?";
  Quiz[87].Text = "Do you love to collect things?";
  Quiz[88].Text = "Are you prone to getting depressions?";
  Quiz[89].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[90].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[91].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[92].Text = "Do you stutter when stressed?";
  Quiz[93].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[94].Text = "Does it come more natural to you to think in pictures than in words?";
  Quiz[95].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[96].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[97].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[98].Text = "Do you make unusual facial expressions?";
  Quiz[99].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[100].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[101].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[102].Text = "Do you fiddle with things?";
  Quiz[103].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[104].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[105].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[106].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[107].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[108].Text = "Do you talk to yourself?";
  Quiz[109].Text = "Do you blink or roll your eyes?";
  Quiz[110].Text = "Do others often misunderstand you?";
  Quiz[111].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[112].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[113].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[114].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[115].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[116].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[117].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[118].Text = "Are you often surprised what people's motives are ?";
  Quiz[119].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[120].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[121].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
  Quiz[122].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[123].Text = "Do people understand you?";
  Quiz[124].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[125].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[126].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[127].Text = "Do you have difficulty describing & summarising for example events, conversations or something you've read?";
  Quiz[128].Text = "Do you know when you are expected to offer an apology?";
  Quiz[129].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[130].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[131].Text = "Do you have an odd posture or gait?";
  Quiz[132].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[133].Text = "Do you have poor concept of time?";
  Quiz[134].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[135].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[136].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[137].Text = "Do you find it hard to tell the age of people?";
  Quiz[138].Text = "Can you easily remember verbal instructions?";
  Quiz[139].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[140].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[141].Text = "Can you spot hidden agendas with ease?";
  Quiz[142].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[143].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[144].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[145].Text = "Do you find it easy to estimate the age of people?";
  Quiz[146].Text = "Do you find it easy to 'read between the lines' when someone is talking to you?";
  Quiz[147].Text = "Do you find it easy to understand what someone is thinking or feeling just by looking at their face?";
  Quiz[148].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[149].Text = "Do you like to drive a car or to watch motor-sports?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[1].Text = "Har du udda tänder; t ex tänder som sitter snett, klättrar på varandra; är större än vanligt; mellanrum mellan tänderna; underbett, som visar extra mycket tandkött?";
  Quiz[2].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[3].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[4].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[5].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[6].Text = "Har du lätt för att bedöma avstånd, höjd, djup eller fart?";
  Quiz[7].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
  Quiz[8].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[9].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[10].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[11].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[12].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
  Quiz[13].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[14].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[15].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[16].Text = "Brukar du lösa problem på okonventionella sätt?";
  Quiz[17].Text = "Ser du mönster i saker hela tiden?";
  Quiz[18].Text = "Är du mentalt hyperaktiv?";
  Quiz[19].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[20].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[21].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[22].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[23].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[24].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[25].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[26].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[27].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[28].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[29].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[30].Text = "Har du haft svårare än andra att få vänner?";
  Quiz[31].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[32].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[33].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[34].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[35].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[36].Text = "Ogillar du att behöva ta i hand?";
  Quiz[37].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[38].Text = "Är du bra på kallprat?";
  Quiz[39].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[40].Text = "Har du haft en tendens att helst umgås med människor som är antingen äldre eller yngre än du själv?";
  Quiz[41].Text = "Är du bra på att arbeta i grupp?";
  Quiz[42].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[43].Text = "Trivs du i romantiska situationer?";
  Quiz[44].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[45].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
  Quiz[46].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[47].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[48].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[49].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[50].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[51].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[52].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[53].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[54].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[55].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[56].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[57].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[58].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[59].Text = "Tycker du om att vara bland mycket folk som t.ex. på en fotbollsmatch?";
  Quiz[60].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[61].Text = "Känns det naturligt för dig att säga 'tack' och 'förlåt'?";
  Quiz[62].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[63].Text = "Trivs du med att möta nya människor?";
  Quiz[64].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[65].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[66].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[67].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[68].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[69].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[70].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[71].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[72].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[73].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[74].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[75].Text = "Tränar du scenarier inuti ditt huvud?";
  Quiz[76].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[77].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[78].Text = "Har du blivit anklagad för att stirra?";
  Quiz[79].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[80].Text = "Har du ovanliga matvanor?";
  Quiz[81].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[82].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[83].Text = "Är ditt sinne för humor ganska konventionellt?";
  Quiz[84].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[85].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[86].Text = "Blir du lätt distraherad?";
  Quiz[87].Text = "Gillar du att samla?";
  Quiz[88].Text = "Brukar du få depressioner?";
  Quiz[89].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[90].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[91].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[92].Text = "Stammar du när du blir stressad?";
  Quiz[93].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[94].Text = "Är det mer naturligt för dig att tänka i bilder än i ord?";
  Quiz[95].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[96].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[97].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[98].Text = "Har du ovanliga ansiktsuttryck?";
  Quiz[99].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[100].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[101].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[102].Text = "Brukar du fingra på saker?";
  Quiz[103].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[104].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[105].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[106].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[107].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[108].Text = "Brukar du prata med dig själv?";
  Quiz[109].Text = "Blinkar eller rullar du med ögona?";
  Quiz[110].Text = "Blir du ofta missförstådd av andra?";
  Quiz[111].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[112].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[113].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[114].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[115].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[116].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[117].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[118].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[119].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[120].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[121].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
  Quiz[122].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[123].Text = "Förstår sig folk på dig?";
  Quiz[124].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[125].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[126].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[127].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[128].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[129].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[130].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[131].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[132].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[133].Text = "Har du dålig tidsuppfattning?";
  Quiz[134].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[135].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[136].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[137].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[138].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[139].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[140].Text = "Har du svårt att känna igen ansikten?";
  Quiz[141].Text = "Kan du lätt avslöja dolda motiv?";
  Quiz[142].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[143].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[144].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
  Quiz[145].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[146].Text = "Tycker du det är lätt att 'läsa mellan raderna' när någon talar med dig?";
  Quiz[147].Text = "Tycker du det är lätt att förstå vad någon tänker eller känner genom att bara titta på deras ansikte?";
  Quiz[148].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[149].Text = "Gillar du att köra bil eller att titta på motorsport?";
#endif

}

/*##########################################################################
#
#   Name       : TQuizR7::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::InitReferers()
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
 }

/*##################  TQuizR7::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR7::LoadReferers()
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
#   Name       : TQuizR7::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	char DxArr[DX_COUNT];
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

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				score = Row.Quiz[i] - 1;
				id = IdArr[i];

				DsmAutism.Add(Row.Autism, id, score);
				DsmAs.Add(Row.Aspie, id, score);
				DsmAdd.Add(Row.ADHD, id, score);
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

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

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
#   Name       : TQuizR7::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizR7::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6)
{
    DefineCross(QuizR6, 0, 0);
    DefineCross(QuizR6, 1, 1);
    DefineCross(QuizR6, 2, 2);
    DefineCross(QuizR6, 3, 3);
    DefineCross(QuizR6, 4, 4);
    DefineCross(QuizR6, 5, 5);
    DefineCross(QuizR5, 6, 4);
    DefineCross(QuizR6, 7, 6);
    DefineCross(QuizR6, 8, 7);
    DefineCross(QuizR6, 9, 8);
    DefineCross(QuizR6, 10, 9);
    DefineCross(QuizR6, 11, 10);
    DefineCross(QuizR6, 12, 11);
    DefineCross(QuizR6, 13, 14);
    DefineCross(QuizR6, 14, 15);
    DefineCross(QuizR6, 15, 16);
    DefineCross(QuizR6, 16, 18);
    DefineCross(QuizR6, 17, 20);
    DefineCross(QuizR6, 18, 17);
    DefineCross(QuizR6, 19, 21);
    DefineCross(QuizR6, 20, 19);
    DefineCross(QuizR6, 21, 23);
    DefineCross(QuizR6, 22, 22);
    DefineCross(QuizR6, 23, 25);
    DefineCross(QuizR6, 24, 27);
    DefineCross(QuizR6, 25, 28);
    DefineCross(QuizR6, 26, 29);
    DefineCross(QuizR6, 27, 30);
    DefineCross(QuizR6, 28, 33);
    DefineCross(QuizR6, 29, 32);
    DefineCross(QuizR4, 30, 1);
    DefineCross(QuizR4, 31, 53);
    DefineCross(QuizR6, 32, 31);
    DefineCross(QuizR6, 33, 34);
    DefineCross(QuizR2, 34, 125);
    DefineCross(QuizR6, 35, 35);
    DefineCross(QuizR4, 36, 35);
    DefineCross(QuizR6, 37, 39);
    DefineCross(QuizR6, 38, 44);
    DefineCross(QuizR6, 39, 40);
    DefineCross(QuizR6, 40, 37);
    DefineCross(QuizR6, 41, 41);
    DefineCross(QuizR6, 42, 43);
    DefineCross(QuizR6, 43, 42);
    DefineCross(QuizR4, 44, 18);
    DefineCross(QuizR6, 45, 48);
    DefineCross(QuizR6, 46, 46);
    DefineCross(QuizR4, 47, 115);
    DefineCross(QuizR4, 48, 121);
    DefineCross(QuizR6, 49, 146);
    DefineCross(QuizR4, 50, 12);
    DefineCross(QuizR6, 51, 53);
    DefineCross(QuizR2, 52, 61);
    DefineCross(QuizR1, 53, 17);
    DefineCross(QuizR6, 54, 51);
    DefineCross(QuizR6, 55, 49);
    DefineCross(QuizR6, 56, 55);
    DefineCross(QuizR6, 57, 52);
    DefineCross(QuizR2, 58, 67);
    DefineCross(QuizR2, 59, 66);
    DefineCross(QuizR4, 60, 16);
    DefineGlobalId( 61, 737);
    DefineGlobalId( 62, 738);
    DefineGlobalId( 63, 739);
    DefineCross(QuizR6, 64, 63);
    DefineCross(QuizR4, 65, 110);
    DefineCross(QuizR6, 66, 64);
    DefineCross(QuizR2, 67, 123);
    DefineCross(QuizR6, 68, 66);
    DefineCross(QuizR6, 69, 65);
    DefineCross(QuizR6, 70, 69);
    DefineCross(QuizR6, 71, 68);
    DefineCross(QuizR6, 72, 71);
    DefineCross(QuizR6, 73, 73);
    DefineCross(QuizR6, 74, 72);
    DefineCross(QuizR2, 75, 146);
    DefineCross(QuizR6, 76, 74);
    DefineCross(QuizR6, 77, 76);
    DefineCross(QuizR6, 78, 75);
    DefineCross(QuizR6, 79, 78);
    DefineCross(QuizR3, 80, 140);
    DefineCross(QuizR6, 81, 80);
    DefineCross(QuizR6, 82, 79);
    DefineCross(QuizR6, 83, 77);
    DefineCross(Quiz6, 84, 10);
    DefineCross(QuizR6, 85, 81);
    DefineCross(QuizR5, 86, 73);
    DefineCross(QuizR6, 87, 83);
    DefineCross(QuizR6, 88, 82);
    DefineCross(QuizR6, 89, 93);
    DefineCross(QuizR6, 90, 86);
    DefineCross(QuizR6, 91, 92);
    DefineCross(QuizR6, 92, 87);
    DefineCross(QuizR6, 93, 85);
    DefineCross(QuizR4, 94, 140);
    DefineCross(QuizR6, 95, 88);
    DefineCross(QuizR6, 96, 90);
    DefineCross(QuizR6, 97, 89);
    DefineCross(QuizR6, 98, 98);
    DefineCross(QuizR6, 99, 100);
    DefineCross(QuizR2, 100, 103);
    DefineCross(QuizR6, 101, 101);
    DefineCross(QuizR3, 102, 77);
    DefineCross(QuizR6, 103, 102);
    DefineCross(QuizR6, 104, 104);
    DefineCross(QuizR6, 105, 99);
    DefineCross(QuizR6, 106, 105);
    DefineCross(QuizR6, 107, 103);
    DefineCross(QuizR6, 108, 107);
    DefineCross(QuizR2, 109, 81);
    DefineCross(QuizR4, 110, 32);
    DefineCross(QuizR6, 111, 113);
    DefineCross(QuizR4, 112, 44);
    DefineCross(QuizR6, 113, 114);
    DefineCross(QuizR6, 114, 115);
    DefineCross(QuizR6, 115, 116);
    DefineCross(QuizR6, 116, 117);
    DefineCross(QuizR6, 117, 118);
    DefineCross(QuizR6, 118, 119);
    DefineCross(QuizR6, 119, 120);
    DefineCross(QuizI, 120, 84);
    DefineCross(Quiz6, 121, 34);
    DefineCross(QuizR6, 122, 123);
    DefineCross(QuizR6, 123, 121);
    DefineCross(QuizR6, 124, 122);
    DefineCross(QuizR2, 125, 96);
    DefineCross(QuizR6, 126, 126);
    DefineCross(QuizR6, 127, 124);
    DefineCross(QuizR6, 128, 127);
    DefineCross(QuizR6, 129, 128);
    DefineCross(QuizR6, 130, 130);
    DefineCross(QuizR6, 131, 129);
    DefineCross(QuizR6, 132, 133);
    DefineCross(QuizR4, 133, 124);
    DefineCross(QuizR6, 134, 134);
    DefineCross(QuizR6, 135, 137);
    DefineCross(QuizR6, 136, 141);
    DefineCross(QuizR6, 137, 136);
    DefineCross(QuizR6, 138, 131);
    DefineCross(QuizR2, 139, 145);
    DefineCross(QuizR4, 140, 122);
    DefineCross(Quiz9, 141, 108);
    DefineCross(QuizR6, 142, 142);
    DefineCross(QuizR5, 143, 136);
    DefineCross(Quiz7, 144, 125);
    DefineCross(QuizR6, 145, 144);
    DefineGlobalId( 146, 740);
    DefineGlobalId( 147, 741);
    DefineGlobalId( 148, 742);
    DefineGlobalId( 149, 743);
}

/*##########################################################################
#
#   Name       : TQuizR7::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR7::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizR7::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR7::ExportExcelCase(const char *filename, int PcaType)
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
    
					if (ival > 2)
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

/*##################  TQuizR7::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR7::ExportExcelAspie(const char *filename)
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

/*##################  TQuizR7::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR7::ExportExcelGroups(const char *filename)
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

/*##################  TQuizR7::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR7::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_MALE)
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
