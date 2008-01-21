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
# quizr4.cpp
# Quiz R4 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr4.h"
#include "file.h"
#include "quizdbr4.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuiz4::TQuizR4
#
#   Purpose....: Constructor for TQuizR4
#
#   In params..: Filename to load quiz R4  from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR4::TQuizR4(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3)
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR4::~TQuizR4
#
#   Purpose....: Destructor for TQuizR4
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR4::~TQuizR4()
{
}

/*##################  TQuizR4::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR4::GetPcaCount()
{
	return 4;
}

/*##################  TQuizR4::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR4::GetCatCount(int Question)
{
    if (Question < 153)
        return 3;
    else
    	return 4;
}

/*##################  TQuizR4::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR4::GetQuizN()
{
	return 152;
}

/*##########################################################################
#
#   Name       : TQuizR4::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::WriteName(TFile &File)
{
	 File.Write("R4");
}

/*##########################################################################
#
#   Name       : TQuizR4::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::WriteLongName(TFile &File)
{
	 File.Write("experimental version 4");
}

/*##################  TQuizR4::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR4::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR4::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::SetupTexts()
{
  Quiz[16].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[19].Reverse = TRUE;
  Quiz[38].Reverse = TRUE;
  Quiz[39].Reverse = TRUE;
  Quiz[153].Reverse = TRUE;
  Quiz[160].Reverse = TRUE;
  Quiz[162].Reverse = TRUE;
  Quiz[163].Reverse = TRUE;
  Quiz[166].Reverse = TRUE;
  Quiz[167].Reverse = TRUE;
  Quiz[169].Reverse = TRUE;
  Quiz[176].Reverse = TRUE;
  Quiz[177].Reverse = TRUE;
  Quiz[179].Reverse = TRUE;
  Quiz[180].Reverse = TRUE;
  Quiz[181].Reverse = TRUE;
  Quiz[183].Reverse = TRUE;
  Quiz[184].Reverse = TRUE;
  Quiz[186].Reverse = TRUE;
  Quiz[188].Reverse = TRUE;
  Quiz[189].Reverse = TRUE;
  Quiz[190].Reverse = TRUE;
  Quiz[192].Reverse = TRUE;
  Quiz[196].Reverse = TRUE;
  Quiz[199].Reverse = TRUE;
  Quiz[200].Reverse = TRUE;
  Quiz[201].Reverse = TRUE;
  Quiz[202].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_SOCIAL;
  Quiz[2].MyGroup = GROUP_NT_NVC;
  Quiz[3].MyGroup = GROUP_SOCIAL;
  Quiz[4].MyGroup = GROUP_SOCIAL;
  Quiz[5].MyGroup = GROUP_NT_NVC;
  Quiz[6].MyGroup = GROUP_MIXED;
  Quiz[7].MyGroup = GROUP_MIXED;
  Quiz[8].MyGroup = GROUP_SEX;
  Quiz[9].MyGroup = GROUP_MIXED;
  Quiz[10].MyGroup = GROUP_SOCIAL;
  Quiz[11].MyGroup = GROUP_MIXED;
  Quiz[12].MyGroup = GROUP_SOCIAL;
  Quiz[13].MyGroup = GROUP_SOCIAL;
  Quiz[14].MyGroup = GROUP_ENVIRONMENT;
  Quiz[15].MyGroup = GROUP_ENVIRONMENT;
  Quiz[16].MyGroup = GROUP_NT_OBSESSION;
  Quiz[17].MyGroup = GROUP_NT_NVC;
  Quiz[18].MyGroup = GROUP_NT_NVC;
  Quiz[19].MyGroup = GROUP_SOCIAL;
  Quiz[20].MyGroup = GROUP_SOCIAL;
  Quiz[21].MyGroup = GROUP_NT_NVC;
  Quiz[22].MyGroup = GROUP_ASPIE_NVC;
  Quiz[23].MyGroup = GROUP_NT_NVC;
  Quiz[24].MyGroup = GROUP_MIXED;
  Quiz[25].MyGroup = GROUP_ASPIE_NVC;
  Quiz[26].MyGroup = GROUP_SOCIAL;
  Quiz[27].MyGroup = GROUP_SOCIAL;
  Quiz[28].MyGroup = GROUP_NT_NVC;
  Quiz[29].MyGroup = GROUP_NT_NVC;
  Quiz[30].MyGroup = GROUP_ASPIE_NVC;
  Quiz[31].MyGroup = GROUP_MIXED;
  Quiz[32].MyGroup = GROUP_NT_NVC;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_NT_NVC;
  Quiz[35].MyGroup = GROUP_SOCIAL;
  Quiz[36].MyGroup = GROUP_SOCIAL;
  Quiz[37].MyGroup = GROUP_ASPIE_NVC;
  Quiz[38].MyGroup = GROUP_SOCIAL;
  Quiz[39].MyGroup = GROUP_NT_NVC;
  Quiz[40].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[41].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[42].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[43].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[44].MyGroup = GROUP_NT_TALENT;
  Quiz[45].MyGroup = GROUP_ASPIE_NVC;
  Quiz[46].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[47].MyGroup = GROUP_ASPIE_NVC;
  Quiz[48].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[49].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[50].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[51].MyGroup = GROUP_MIXED;
  Quiz[52].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[53].MyGroup = GROUP_SOCIAL;
  Quiz[54].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[55].MyGroup = GROUP_SEX;
  Quiz[56].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[57].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[58].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[59].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[60].MyGroup = GROUP_ASPIE_NVC;
  Quiz[61].MyGroup = GROUP_ASPIE_NVC;
  Quiz[62].MyGroup = GROUP_ASPIE_NVC;
  Quiz[63].MyGroup = GROUP_ASPIE_NVC;
  Quiz[64].MyGroup = GROUP_ASPIE_NVC;
  Quiz[65].MyGroup = GROUP_ASPIE_NVC;
  Quiz[66].MyGroup = GROUP_ASPIE_NVC;
  Quiz[67].MyGroup = GROUP_ASPIE_NVC;
  Quiz[68].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[69].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[70].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[71].MyGroup = GROUP_ASPIE_NVC;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ASPIE_NVC;
  Quiz[74].MyGroup = GROUP_ASPIE_NVC;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ENVIRONMENT;
  Quiz[77].MyGroup = GROUP_ASPIE_NVC;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[81].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[82].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[83].MyGroup = GROUP_NT_TALENT;
  Quiz[84].MyGroup = GROUP_NT_TALENT;
  Quiz[85].MyGroup = GROUP_SOCIAL;
  Quiz[86].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[87].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[88].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[89].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[90].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[91].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[92].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[93].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[94].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[95].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[96].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[99].MyGroup = GROUP_ENVIRONMENT;
  Quiz[100].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[101].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[102].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[103].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[104].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[105].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[106].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[107].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[108].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[109].MyGroup = GROUP_ACTIVITY;
  Quiz[110].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[111].MyGroup = GROUP_MIXED;
  Quiz[112].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[113].MyGroup = GROUP_ACTIVITY;
  Quiz[114].MyGroup = GROUP_MIXED;
  Quiz[115].MyGroup = GROUP_NT_OBSESSION;
  Quiz[116].MyGroup = GROUP_SEX;
  Quiz[117].MyGroup = GROUP_ENVIRONMENT;
  Quiz[118].MyGroup = GROUP_ENVIRONMENT;
  Quiz[119].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[120].MyGroup = GROUP_ENVIRONMENT;
  Quiz[121].MyGroup = GROUP_SOCIAL;
  Quiz[122].MyGroup = GROUP_NT_NVC;
  Quiz[123].MyGroup = GROUP_NT_TALENT;
  Quiz[124].MyGroup = GROUP_NT_SENSORY;
  Quiz[125].MyGroup = GROUP_NT_HUNTING;
  Quiz[126].MyGroup = GROUP_ACTIVITY;
  Quiz[127].MyGroup = GROUP_ACTIVITY;
  Quiz[128].MyGroup = GROUP_NT_TALENT;
  Quiz[129].MyGroup = GROUP_ACTIVITY;
  Quiz[130].MyGroup = GROUP_ACTIVITY;
  Quiz[131].MyGroup = GROUP_NT_SENSORY;
  Quiz[132].MyGroup = GROUP_NT_SENSORY;
  Quiz[133].MyGroup = GROUP_NT_SENSORY;
  Quiz[134].MyGroup = GROUP_NT_SENSORY;
  Quiz[135].MyGroup = GROUP_NT_SENSORY;
  Quiz[136].MyGroup = GROUP_NT_SENSORY;
  Quiz[137].MyGroup = GROUP_NT_SENSORY;
  Quiz[138].MyGroup = GROUP_ASPIE_NVC;
  Quiz[139].MyGroup = GROUP_ASPIE_NVC;
  Quiz[140].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[141].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[142].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[143].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[144].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[145].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[146].MyGroup = GROUP_ASPIE_NVC;
  Quiz[147].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[148].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[149].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[150].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[151].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[152].MyGroup = GROUP_ASPIE_HUNTING;

  Quiz[153].MyGroup = GROUP_SOCIAL;
  Quiz[154].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[155].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[156].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[157].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[158].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[159].MyGroup = GROUP_NT_NVC;
  Quiz[160].MyGroup = GROUP_NT_NVC;
  Quiz[161].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[162].MyGroup = GROUP_NT_TALENT;
  Quiz[163].MyGroup = GROUP_SOCIAL;
  Quiz[164].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[165].MyGroup = GROUP_SOCIAL;
  Quiz[166].MyGroup = GROUP_MIXED;
  Quiz[167].MyGroup = GROUP_SOCIAL;
  Quiz[168].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[169].MyGroup = GROUP_SOCIAL;
  Quiz[170].MyGroup = GROUP_MIXED;
  Quiz[171].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[172].MyGroup = GROUP_NT_NVC;
  Quiz[173].MyGroup = GROUP_NT_NVC;
  Quiz[174].MyGroup = GROUP_SOCIAL;
  Quiz[175].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[176].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[177].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[178].MyGroup = GROUP_SOCIAL;
  Quiz[179].MyGroup = GROUP_NT_NVC;
  Quiz[180].MyGroup = GROUP_NT_TALENT;
  Quiz[181].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[182].MyGroup = GROUP_NT_NVC;
  Quiz[183].MyGroup = GROUP_NT_NVC;
  Quiz[184].MyGroup = GROUP_NT_TALENT;
  Quiz[185].MyGroup = GROUP_NT_NVC;
  Quiz[186].MyGroup = GROUP_SOCIAL;
  Quiz[187].MyGroup = GROUP_NT_NVC;
  Quiz[188].MyGroup = GROUP_NT_NVC;
  Quiz[189].MyGroup = GROUP_NT_TALENT;
  Quiz[190].MyGroup = GROUP_SOCIAL;
  Quiz[191].MyGroup = GROUP_MIXED;
  Quiz[192].MyGroup = GROUP_NT_NVC;
  Quiz[193].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[194].MyGroup = GROUP_NT_NVC;
  Quiz[195].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[196].MyGroup = GROUP_SOCIAL;
  Quiz[197].MyGroup = GROUP_NT_NVC;
  Quiz[198].MyGroup = GROUP_SOCIAL;
  Quiz[199].MyGroup = GROUP_SOCIAL;
  Quiz[200].MyGroup = GROUP_NT_NVC;
  Quiz[201].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[202].MyGroup = GROUP_NT_NVC;

#ifdef ENGLISH
  Quiz[0].Text = "Have you felt different from others for most of your life?";
  Quiz[1].Text = "Have you had more difficulties than others making friends?";
  Quiz[2].Text = "Is it or has it been harder for you than for others to find a partner?";
  Quiz[3].Text = "Do you tend to feel nervous, shy, confused or left out in social situations?";
  Quiz[4].Text = "Are you more of an observer than one who participates in life?";
  Quiz[5].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[6].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[7].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[8].Text = "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?";
  Quiz[9].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[10].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[11].Text = "Have you had a tendency to prefer the company of those who are older or younger than yourself?";
  Quiz[12].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[13].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[14].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[15].Text = "Have you had thoughts of committing suicide?";
  Quiz[16].Text = "Is a large social network important to you?";
  Quiz[17].Text = "Are you intuitive about what people need from you?";
  Quiz[18].Text = "Do you find the usual courting behavior natural?";
  Quiz[19].Text = "Are you good at teamwork?";
  Quiz[20].Text = "Is it difficult or tiresome for you to talk?";
  Quiz[21].Text = "Do you have a monotonous voice?";
  Quiz[22].Text = "Do you tend to talk either too softly or too loundly?";
  Quiz[23].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[24].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[25].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[26].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[27].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[28].Text = "Do you have difficulties understanding figures of speech, idioms, allegories and a tendency to interpret things literally?";
  Quiz[29].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
  Quiz[30].Text = "Do people sometimes think you are smiling when you shouldn't?";
  Quiz[31].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[32].Text = "Do others often misunderstand you?";
  Quiz[33].Text = "Do you tend to be more blunt and straightforward than others?";
  Quiz[34].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[35].Text = "Do you dislike shaking hands?";
  Quiz[36].Text = "Do you prefer to avoid eye-contact?";
  Quiz[37].Text = "Have you been accused of staring?";
  Quiz[38].Text = "Do you find it easy to describe your feelings?";
  Quiz[39].Text = "Is it easy for you to adopt a polite or socially 'appropriate' facial expression, even if it does not match what you feel inside?";
  Quiz[40].Text = "Do you have extra sensitive hearing?";
  Quiz[41].Text = "Are you easily disturbed by sounds/noises that others make?";
  Quiz[42].Text = "Do you find the sound from a motor-bike, helicopter or tractor painful?";
  Quiz[43].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[44].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[45].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[46].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[47].Text = "Do you usually close one eye in strong sun-light?";
  Quiz[48].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[49].Text = "Do you have a very acute sense of smell?";
  Quiz[50].Text = "Do you have a very acute sense of taste?";
  Quiz[51].Text = "Are you a picky eater?";
  Quiz[52].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[53].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[54].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
  Quiz[55].Text = "Are you fairly non-sensitive to physical pain?";
  Quiz[56].Text = "Are you sensitive to heat?";
  Quiz[57].Text = "Are you sensitive to cold?";
  Quiz[58].Text = "Are you sensitive to wind?";
  Quiz[59].Text = "Are you sensitive to weather changes?";
  Quiz[60].Text = "Do you tap your fingers or fiddle with something (e.g. when bored, restless or concentrating)?";
  Quiz[61].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[62].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[63].Text = "Do you grind teeth (e.g. when stressed)?";
  Quiz[64].Text = "Do you talk to yourself?";
  Quiz[65].Text = "Do you pick your nose?";
  Quiz[66].Text = "Do you crack joints?";
  Quiz[67].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[68].Text = "Do you enjoy watching things that shimmer or glitter?";
  Quiz[69].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[70].Text = "Do you enjoy spinning in circles and/or walking on your toes?";
  Quiz[71].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[72].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[73].Text = "Do you flap your hands (e.g. when excited or upset)?";
  Quiz[74].Text = "Do you bite yourself (e.g. when frustrated or upset)?";
  Quiz[75].Text = "Do you repeatedly bang your head (e.g. when frustrated or upset)?";
  Quiz[76].Text = "Do you self-harm, or have you done so in the past?";
  Quiz[77].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[78].Text = "Do you have a habit of sniffing, snorting, coughing or clearing your throat, without it being due to allergy, cold or bronchitis?";
  Quiz[79].Text = "Do you repeatedly blink or have twitches in eyes or face?";
  Quiz[80].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[81].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[82].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[83].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[84].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[85].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[86].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[87].Text = "Do you love to make lists, diagrams etc for the fun of it?";
  Quiz[88].Text = "Do you love to collect things?";
  Quiz[89].Text = "Do you have certain routines which you need to follow?";
  Quiz[90].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[91].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[92].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[93].Text = "Do you prefer to wear the same clothes every day for many days in a row?";
  Quiz[94].Text = "Do you prefer to eat the same food every day for long periods at a time?";
  Quiz[95].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[96].Text = "Do you have a fascination for water?";
  Quiz[97].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[98].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[99].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[100].Text = "Are you very gifted in one or more areas?";
  Quiz[101].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[102].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[103].Text = "Do you have unconventional ways of solving problems?";
  Quiz[104].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[105].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[106].Text = "Are you a computer geek?";
  Quiz[107].Text = "Do you have strong sense of ethics and a tendency to stand up for your ideals & beliefs?";
  Quiz[108].Text = "Do you have a hyperactive mind?";
  Quiz[109].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[110].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[111].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[112].Text = "Do you have odd teeth; e.g. that are crooked, bigger than usual; that have gaps, overlaps, underbite or that show extra much gum?";
  Quiz[113].Text = "Do you have atypical or irregular sleeping patterns that deviate from the 24-h cycle?";
  Quiz[114].Text = "Do you find the norms of hygiene too strict?";
  Quiz[115].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[116].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[117].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[118].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[119].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[120].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[121].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[122].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[123].Text = "Is it difficult for you to multitask?";
  Quiz[124].Text = "Do you have poor concept of time?";
  Quiz[125].Text = "Do you often forget where you put things?";
  Quiz[126].Text = "Are you easily distracted?";
  Quiz[127].Text = "Do you find it hard to focus on or learn things you are not interested in?";
  Quiz[128].Text = "Do you have difficulty describing & summarising for example events, conversations or something you've read?";
  Quiz[129].Text = "Have you or have you had a tendency to be hyperactive and/or restless?";
  Quiz[130].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[131].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[132].Text = "Do you have poor balance, e.g. difficulty riding a bicycle, skating, standing on one leg?";
  Quiz[133].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[134].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[135].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
  Quiz[136].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[137].Text = "Do you have difficulty writing by hand?";
  Quiz[138].Text = "Do you have difficulties with pronunciation?";
  Quiz[139].Text = "Do you stutter when stressed?";
  Quiz[140].Text = "Does it come more natural to you to think in pictures than in words?";
  Quiz[141].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[142].Text = "Are you affected negatively by high air humidity combined with cold weather?";
  Quiz[143].Text = "Are you sensitive to dry air?";
  Quiz[144].Text = "Do you feel good in mist or fog?";
  Quiz[145].Text = "Can you sense differences in air-pressure (when the weather changes from low-pressure to high-pressure and vice versa)?";
  Quiz[146].Text = "Do you sometimes say \"we\" instead of \"I\"?";
  Quiz[147].Text = "Do you enjoy digging?";
  Quiz[148].Text = "Do you sometimes have an urge to climb?";
  Quiz[149].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[150].Text = "Do you have a fascination for caves?";
  Quiz[151].Text = "Do you like to relax and do absolutely nothing while pondering on things of interest?";
  Quiz[152].Text = "Do you like Science Fiction?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[1].Text = "Har du haft svårare än andra att få vänner?";
  Quiz[2].Text = "Är det eller har det varit svårare för dig än för andra att hitta en partner?";
  Quiz[3].Text = "Brukar du känna dig nervös, blyg, förvirrad eller utanför i olika sociala situationer?";
  Quiz[4].Text = "Känner du dig mer som en observatör än som en deltagare i livet?";
  Quiz[5].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[6].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[7].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[8].Text = "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?";
  Quiz[9].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[10].Text = "Föredrar du att bara umgås med folk du känner väl, på tu man hand eller i en mindre grupp?";
  Quiz[11].Text = "Har du haft en tendens att helst umgås med människor som är antingen äldre eller yngre än du själv?";
  Quiz[12].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[13].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[14].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[15].Text = "Har du haft självmordstankar?";
  Quiz[16].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[17].Text = "Känner du intuitivt vad folk behöver från dig?";
  Quiz[18].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[19].Text = "Är du bra på att arbeta i grupp?";
  Quiz[20].Text = "Finner du det svårt eller tröttsamt att tala?";
  Quiz[21].Text = "Har du en monoton röst?";
  Quiz[22].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[23].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[24].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[25].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[26].Text = "Tycker du att vanligt kallprat är svårt, tröttsamt eller slöseri med tid?";
  Quiz[27].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[28].Text = "Har du eller har du haft svårt att förstå talesätt, idiom, allegorier och en tendens att tolka saker bokstavligt?";
  Quiz[29].Text = "Brukar du ha svårt att tolka kroppsspråk och/eller ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
  Quiz[30].Text = "Tycker andra ibland att du ler när du inte borde?";
  Quiz[31].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[32].Text = "Blir du ofta missförstådd av andra?";
  Quiz[33].Text = "Brukar du vara mer rak och rättfram i din kommunikation än andra?";
  Quiz[34].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[35].Text = "Ogillar du att behöva ta i hand?";
  Quiz[36].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[37].Text = "Har du blivit anklagad för att stirra?";
  Quiz[38].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[39].Text = "Är det lätt för dig att använda ett artigt eller 'passande' ansiktsuttryck, även om det inte motsvarar vad du egentligen känner?";
  Quiz[40].Text = "Har du extra känslig hörsel?";
  Quiz[41].Text = "Blir du lätt störd av ljud från andra?";
  Quiz[42].Text = "Upplever du att ljudet från en motorcykel, helikopter eller traktor gör ont?";
  Quiz[43].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[44].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[45].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[46].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[47].Text = "Blundar du gärna med ena ögat i starkt solljus?";
  Quiz[48].Text = "Tycker du att lysrörsljus känns obehagligt?";
  Quiz[49].Text = "Har du extra känsligt luktsinne?";
  Quiz[50].Text = "Har du extra känsligt smaksinne?";
  Quiz[51].Text = "Är du petig med vad du äter?";
  Quiz[52].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[53].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[54].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
  Quiz[55].Text = "Är du ganska okänslig för fysisk smärta?";
  Quiz[56].Text = "Är du känslig för värme?";
  Quiz[57].Text = "Är du känsig för kyla?";
  Quiz[58].Text = "Är du känslig för när det blåser?";
  Quiz[59].Text = "Är du känslig för väderomslag?";
  Quiz[60].Text = "Brukar du trumma med fingrarna eller fingra på något (t ex när du är uttråkad, rastlös eller koncenterar dig)?";
  Quiz[61].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[62].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[63].Text = "Brukar du gnissla tänder (t ex när du är stressad)?";
  Quiz[64].Text = "Brukar du prata med dig själv?";
  Quiz[65].Text = "Brukar du peta näsan?";
  Quiz[66].Text = "Brukar du dra i/knäcka leder?";
  Quiz[67].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[68].Text = "Gillar du att titta på något som skimrar eller glittrar?";
  Quiz[69].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[70].Text = "Gillar du att snurra runt runt och/eller att gå på tå?";
  Quiz[71].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[72].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[73].Text = "Brukar du vifta med händerna (t ex när du är upprymd eller upprörd)?";
  Quiz[74].Text = "Brukar du bita dig själv? (t ex när du är upprörd)?";
  Quiz[75].Text = "Brukar du upprepade gånger banka huvudet i nånting (t ex när du blir frustrerad eller upprörd)?";
  Quiz[76].Text = "Brukar du eller har du brukat ägna dig åt självskadande beteende?";
  Quiz[77].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[78].Text = "Brukar du göra snusningar, harklingar eller hostningar utan att det beror på allergi, förkylning eller bronkit?";
  Quiz[79].Text = "Brukar du ha upprepade blinkningar eller ryckningar i ögon eller ansikte?";
  Quiz[80].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[81].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[82].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[83].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[84].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[85].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[86].Text = "Har du behov av symmetri, ordning och/eller precision?";
  Quiz[87].Text = "Gillar du att göra listor, diagram o dyl för att det är kul?";
  Quiz[88].Text = "Gillar du att samla?";
  Quiz[89].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[90].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[91].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[92].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[93].Text = "Föredrar du att ha samma kläder varje dag, många dar i rad?";
  Quiz[94].Text = "Föredrar du att äta samma mat varje dag, långa perioder i taget?";
  Quiz[95].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[96].Text = "Är du fascinerad av vatten?";
  Quiz[97].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[98].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[99].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[100].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[101].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[102].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[103].Text = "Brukar du lösa problem på okonventionella sätt?";
  Quiz[104].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[105].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[106].Text = "Är du en datornörd?";
  Quiz[107].Text = "Har du hög moral och en tendens att hålla fast vid/stå upp för dina ideal?";
  Quiz[108].Text = "Är du mentalt hyperaktiv?";
  Quiz[109].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[110].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[111].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[112].Text = "Har du udda tänder; t ex tänder som sitter snett, klättrar på varandra; är större än vanligt; mellanrum mellan tänderna; underbett, som visar extra mycket tandkött?";
  Quiz[113].Text = "Har du otypisk eller oregelbunden sömnrytm (d v s som avviker från 24-timmarscykeln)?";
  Quiz[114].Text = "Tycker du att normerna för hygien är för strikta?";
  Quiz[115].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[116].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet?";
  Quiz[117].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[118].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[119].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[120].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[121].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[122].Text = "Har du svårt att känna igen ansikten?";
  Quiz[123].Text = "Har du svårt att göra flera saker samtidigt?";
  Quiz[124].Text = "Har du dålig tidsuppfattning?";
  Quiz[125].Text = "Glömmer du ofta var du lagt saker?";
  Quiz[126].Text = "Blir du lätt distraherad?";
  Quiz[127].Text = "Har du svårt att koncenterera dig på eller lära dig saker du inte är intresserad av?";
  Quiz[128].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[129].Text = "Har du eller har du haft en tendens att vara hyperaktiv och/eller rastlös?";
  Quiz[130].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[131].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[132].Text = "Har du dåligt balanssinne, t ex svårt att cykla, åka skridskor, stå på ett ben?";
  Quiz[133].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[134].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[135].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[136].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[137].Text = "Har du svårt att skriva för hand?";
  Quiz[138].Text = "Har du svårigheter med uttal?";
  Quiz[139].Text = "Stammar du när du blir stressad?";
  Quiz[140].Text = "Är det mer naturligt för dig att tänka i bilder än i ord?";
  Quiz[141].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[142].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med kallt väder?";
  Quiz[143].Text = "Är du känslig för torr luft?";
  Quiz[144].Text = "Brukar du må bra när det är dis eller dimma?";
  Quiz[145].Text = "Brukar du känna av skillnader i lufttryck (när det växlar från högtryck till lågtryck och vice versa)?";
  Quiz[146].Text = "Säger du ibland \"vi\" istället för \"jag\"?";
  Quiz[147].Text = "Gillar du att gräva?";
  Quiz[148].Text = "Brukar du ibland ha ett behov av att klättra?";
  Quiz[149].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[150].Text = "Är du fascinerad av grottor?";
  Quiz[151].Text = "Brukar du gilla att bara slappa och göra ingenting medan du tänker på intressanta saker?";
  Quiz[152].Text = "Gillar du Science Fiction?";
#endif

 Quiz[153].Text = "AQ - I prefer to do things with others rather than on my own.";          
 Quiz[154].Text = "AQ - I prefer to do things the same way over and over again.";          
 Quiz[155].Text = "AQ - If I try to imagine something, I find it very easy to create a picture in my mind.";          
 Quiz[156].Text = "AQ - I frequently get so strongly absorbed in one thing that I lose sight of other things.";          
 Quiz[157].Text = "AQ - I often notice small sounds when others do not.";          
 Quiz[158].Text = "AQ - I usually notice car number plates or similar strings of information.";          
 Quiz[159].Text = "AQ - Other people frequently tell me that what I've said is impolite, even though I think it is polite.";          
 Quiz[160].Text = "AQ - When I'm reading a story, I can easily imagine what the characters might look like.";          
 Quiz[161].Text = "AQ - I am fascinated by dates.";          
 Quiz[162].Text = "AQ - In a social group, I can easily keep track of several different people's conversations.";          
 Quiz[163].Text = "AQ - I find social situations easy.";          
 Quiz[164].Text = "AQ - I tend to notice details that others do not.";          
 Quiz[165].Text = "AQ - I would rather go to a library than to a party.";          
 Quiz[166].Text = "AQ - I find making up stories easy.";          
 Quiz[167].Text = "AQ - I find myself drawn more strongly to people than to things.";          
 Quiz[168].Text = "AQ - I tend to have very strong interests, which I get upset about if I can't pursue.";          
 Quiz[169].Text = "AQ - I enjoy social chitchat.";          
 Quiz[170].Text = "AQ - When I talk, it isn't always easy for others to get a word in edgewise.";          
 Quiz[171].Text = "AQ - I am fascinated by numbers.";          
 Quiz[172].Text = "AQ - When I'm reading a story, I find it difficult to work out the characters' intentions.";          
 Quiz[173].Text = "AQ - I don't particularly enjoy reading fiction.";          
 Quiz[174].Text = "AQ - I find it hard to make new friends.";          
 Quiz[175].Text = "AQ - I notice patterns in things all the time.";          
 Quiz[176].Text = "AQ - I would rather go to the theater than to a museum.";          
 Quiz[177].Text = "AQ - It does not upset me if my daily routine is disturbed.";          
 Quiz[178].Text = "AQ - I frequently find that I don't know how to keep a conversation going.";          
 Quiz[179].Text = "AQ - I find it easy to 'read between the lines' when someone is talking to me.";          
 Quiz[180].Text = "AQ - I usually concentrate more on the whole picture, rather than on the small details.";          
 Quiz[181].Text = "AQ - I am not very good at remembering phone numbers.";          
 Quiz[182].Text = "AQ - I don't usually notice small changes in a situation or a person's appearance.";
 Quiz[183].Text = "AQ - I know how to tell if someone listening to me is getting bored.";          
 Quiz[184].Text = "AQ - I find it easy to do more than one thing at once.";          
 Quiz[185].Text = "AQ - When I talk on the phone, I'm not sure when it's my turn to speak.";          
 Quiz[186].Text = "AQ - I enjoy doing things spontaneously.";          
 Quiz[187].Text = "AQ - I am often the last to understand the point of a joke.";          
 Quiz[188].Text = "AQ - I find it easy to work out what someone is thinking or feeling just by looking at their face.";          
 Quiz[189].Text = "AQ - If there is an interruption, I can switch back to what I was doing very quickly.";          
 Quiz[190].Text = "AQ - I am good at social chitchat.";          
 Quiz[191].Text = "AQ - People often tell me that I keep going on and on about the same thing.";          
 Quiz[192].Text = "AQ - When I was young, I used to enjoy playing games involving pretending with other children.";          
 Quiz[193].Text = "AQ - I like to collect information about categories of things (e.g., types of cars, birds, trains, plants).";          
 Quiz[194].Text = "AQ - I find it difficult to imagine what it would be like to be someone else.";          
 Quiz[195].Text = "AQ - I like to carefully plan any activities I participate in.";          
 Quiz[196].Text = "AQ - I enjoy social occasions.";          
 Quiz[197].Text = "AQ - I find it difficult to work out people's intentions.";          
 Quiz[198].Text = "AQ - New situations make me anxious.";          
 Quiz[199].Text = "AQ - I enjoy meeting new people.";          
 Quiz[200].Text = "AQ - I am a good diplomat.";
 Quiz[201].Text = "AQ - I am not very good at remembering people's date of birth.";
 Quiz[202].Text = "AQ - I find it very easy to play games with children that involve pretending.";

}

/*##########################################################################
#
#   Name       : TQuizR4::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::InitReferers()
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

/*##################  TQuizR4::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR4::LoadReferers()
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

		if (Row.Autism == 1 || Row.Aspie == 1 || Row.PDD == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2 || Row.Autism == 2 || Row.PDD == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism || Row.Aspie || Row.PDD)
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
#   Name       : TQuizR4::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::LoadPopulations()
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
		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				score = Row.Quiz[i] - 1;
				id = IdArr[i];

				DsmAutism.Add(Row.Autism, id, score);
				DsmAdd.Add(Row.ADHD, id, score);
				DsmTs.Add(Row.TS, id, score);
				DsmDyslexia.Add(Row.Dyslexia, id, score);
				DsmDyscalculia.Add(Row.Dyscalculia, id, score);
				DsmOCD.Add(Row.OCD, id, score);
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

		All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);

				AsMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR4::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::SetupControlGroups()
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
#   Name       : TQuizR4::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3)
{
    DefineCross(QuizR3, 0, 0);
    DefineCross(QuizR3, 1, 1);
    DefineCross(QuizR3, 2, 2);
    DefineCross(QuizR3, 3, 14);
    DefineCross(QuizR3, 4, 3);
    DefineCross(QuizR3, 5, 12);
    DefineCross(QuizR3, 6, 16);
    DefineCross(QuizR3, 7, 13);
    DefineCross(QuizR3, 8, 5);
    DefineCross(QuizR3, 9, 15);
    DefineCross(QuizR3, 10, 7);
    DefineCross(QuizR3, 11, 6);
    DefineCross(QuizR3, 12, 9);
    DefineCross(QuizR3, 13, 8);
    DefineCross(QuizR3, 14, 10);
    DefineCross(QuizR3, 15, 11);
    DefineCross(QuizR3, 16, 19);
    DefineCross(QuizR3, 17, 21);
    DefineCross(QuizR3, 18, 22);
    DefineCross(QuizR3, 19, 23);
    DefineCross(QuizR3, 20, 24);
    DefineCross(QuizR3, 21, 25);
    DefineCross(QuizR3, 22, 26);
    DefineCross(QuizR3, 23, 32);
    DefineCross(QuizR3, 24, 33);
    DefineCross(QuizR3, 25, 34);
    DefineCross(QuizR3, 26, 35);
    DefineCross(QuizR3, 27, 36);
    DefineCross(QuizR3, 28, 37);
    DefineCross(QuizR3, 29, 38);
    DefineCross(QuizR3, 30, 46);
    DefineCross(QuizR3, 31, 39);
    DefineCross(QuizR3, 32, 47);
    DefineCross(QuizR3, 33, 40);
    DefineCross(QuizR3, 34, 41);
    DefineCross(QuizR3, 35, 42);
    DefineCross(QuizR3, 36, 43);
    DefineCross(QuizR3, 37, 45);
    DefineCross(QuizR3, 38, 48);
    DefineCross(QuizR3, 39, 50);
    DefineCross(QuizR3, 40, 53);
    DefineCross(QuizR3, 41, 54);
    DefineCross(QuizR3, 42, 55);
    DefineCross(QuizR3, 43, 56);
    DefineCross(QuizR3, 44, 154);
    DefineCross(QuizR3, 45, 57);
    DefineCross(QuizR1, 46, 75);
    DefineCross(Quiz7, 47, 10);
    DefineCross(QuizR3, 48, 58);
    DefineCross(QuizR3, 49, 59);
    DefineCross(QuizR3, 50, 60);
    DefineCross(QuizR3, 51, 61);
    DefineCross(QuizR3, 52, 64);
    DefineCross(QuizR3, 53, 65);
    DefineCross(QuizR3, 54, 66);
    DefineCross(QuizR3, 55, 63);
    DefineCross(QuizR3, 56, 67);
    DefineCross(QuizR3, 57, 68);
    DefineCross(QuizR3, 58, 69);
    DefineCross(QuizR1, 59, 80);
    DefineGlobalId( 60, 623);
    DefineCross(QuizR3, 61, 82);
    DefineCross(QuizR3, 62, 83);
    DefineCross(QuizR2, 63, 86);
    DefineCross(QuizR3, 64, 81);
    DefineCross(QuizR3, 65, 87);
    DefineCross(QuizR3, 66, 78);
    DefineCross(QuizR3, 67, 79);
    DefineCross(QuizR3, 68, 91);
    DefineCross(QuizR3, 69, 90);
    DefineGlobalId( 70, 624);
    DefineCross(QuizR3, 71, 97);
    DefineCross(QuizR3, 72, 98);
    DefineCross(QuizR3, 73, 96);
    DefineCross(QuizR3, 74, 95);
    DefineGlobalId( 75, 625);
    DefineCross(QuizR3, 76, 120);
    DefineCross(QuizR3, 77, 29);
    DefineGlobalId( 78, 626);
    DefineGlobalId( 79, 627);
    DefineCross(QuizR3, 80, 100);
    DefineCross(QuizR3, 81, 99);
    DefineCross(QuizR3, 82, 101);
    DefineCross(QuizR3, 83, 150);
    DefineCross(QuizR3, 84, 102);
    DefineCross(QuizR3, 85, 4);
    DefineCross(QuizR3, 86, 103);
    DefineCross(QuizR3, 87, 106);
    DefineCross(QuizR3, 88, 104);
    DefineCross(QuizR3, 89, 107);
    DefineCross(QuizR3, 90, 159);
    DefineCross(QuizR3, 91, 108);
    DefineCross(QuizR3, 92, 109);
    DefineCross(QuizR3, 93, 110);
    DefineCross(QuizR3, 94, 111);
    DefineCross(QuizR3, 95, 117);
    DefineGlobalId( 96, 628);
    DefineCross(QuizR3, 97, 113);
    DefineCross(QuizR3, 98, 112);
    DefineCross(QuizR3, 99, 114);
    DefineCross(QuizR3, 100, 121);
    DefineCross(QuizR3, 101, 122);
    DefineCross(QuizR3, 102, 123);
    DefineCross(QuizR3, 103, 124);
    DefineCross(QuizR3, 104, 132);
    DefineCross(QuizR3, 105, 125);
    DefineCross(QuizR3, 106, 129);
    DefineCross(QuizR3, 107, 130);
    DefineCross(QuizR3, 108, 126);
    DefineCross(QuizR3, 109, 145);
    DefineCross(QuizR3, 110, 135);
    DefineCross(QuizR3, 111, 136);
    DefineCross(QuizR3, 112, 137);
    DefineCross(QuizR3, 113, 139);
    DefineCross(QuizR3, 114, 141);
    DefineCross(QuizR3, 115, 142);
    DefineCross(QuizR3, 116, 143);
    DefineCross(QuizR3, 117, 116);
    DefineCross(QuizR3, 118, 151);
    DefineCross(QuizR3, 119, 144);
    DefineCross(QuizR3, 120, 147);
    DefineCross(QuizR3, 121, 146);
    DefineCross(QuizR3, 122, 155);
    DefineCross(QuizR3, 123, 153);
    DefineCross(QuizR3, 124, 148);
    DefineCross(QuizR3, 125, 149);
    DefineCross(QuizR3, 126, 162);
    DefineCross(QuizR3, 127, 157);
    DefineCross(QuizR3, 128, 152);
    DefineGlobalId( 129, 629);
    DefineCross(QuizR3, 130, 156);
    DefineCross(QuizR3, 131, 167);
    DefineCross(QuizR3, 132, 168);
    DefineCross(QuizR3, 133, 169);
    DefineCross(QuizR3, 134, 170);
    DefineCross(QuizR3, 135, 171);
    DefineCross(QuizR3, 136, 172);
    DefineCross(QuizR3, 137, 173);
    DefineCross(QuizR3, 138, 28);
    DefineCross(QuizR3, 139, 27);
    DefineGlobalId( 140, 630);
    DefineGlobalId( 141, 631);
    DefineGlobalId( 142, 632);
    DefineGlobalId( 143, 633);
    DefineGlobalId( 144, 634);
    DefineGlobalId( 145, 635);
    DefineCross(QuizR3, 146, 30);
    DefineGlobalId( 147, 636);
    DefineCross(QuizR2, 148, 88);
    DefineCross(Quiz9, 149, 97);
    DefineCross(Quiz6, 150, 145);
    DefineGlobalId( 151, 637);
    DefineGlobalId( 152, 638);

    DefineGlobalId( 153, 639);
    DefineGlobalId( 154, 640);
    DefineGlobalId( 155, 641);
    DefineGlobalId( 156, 642);
    DefineGlobalId( 157, 643);
    DefineGlobalId( 158, 644);
    DefineGlobalId( 159, 645);
    DefineGlobalId( 160, 646);
    DefineGlobalId( 161, 647);
    DefineGlobalId( 162, 648);
    DefineGlobalId( 163, 649);
    DefineGlobalId( 164, 650);
    DefineGlobalId( 165, 651);
    DefineGlobalId( 166, 652);
    DefineGlobalId( 167, 653);
    DefineGlobalId( 168, 654);
    DefineGlobalId( 169, 655);
    DefineGlobalId( 170, 656);
    DefineGlobalId( 171, 657);
    DefineGlobalId( 172, 658);
    DefineGlobalId( 173, 659);
    DefineGlobalId( 174, 660);
    DefineGlobalId( 175, 661);
    DefineGlobalId( 176, 662);
    DefineGlobalId( 177, 663);
    DefineGlobalId( 178, 664);
    DefineGlobalId( 179, 665);
    DefineGlobalId( 180, 666);
    DefineGlobalId( 181, 667);
    DefineGlobalId( 182, 668);
    DefineGlobalId( 183, 669);
    DefineGlobalId( 184, 670);
    DefineGlobalId( 185, 671);
    DefineGlobalId( 186, 672);
    DefineGlobalId( 187, 673);
    DefineGlobalId( 188, 674);
    DefineGlobalId( 189, 675);
    DefineGlobalId( 190, 676);
    DefineGlobalId( 191, 677);
    DefineGlobalId( 192, 678);
    DefineGlobalId( 193, 679);
    DefineGlobalId( 194, 680);
    DefineGlobalId( 195, 681);
    DefineGlobalId( 196, 682);
    DefineGlobalId( 197, 683);
    DefineGlobalId( 198, 684);
    DefineGlobalId( 199, 685);
    DefineGlobalId( 200, 686);
    DefineGlobalId( 201, 687);
    DefineGlobalId( 202, 688);
}

/*##########################################################################
#
#   Name       : TQuizR4::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR4::GetReferer(const char *referer, TPopulation *pop)
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
			pop->Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult);
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

/*##################  TQuizR4::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR4::ExportExcelCase(const char *filename, int PcaType)
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
    
					if (i < 153 && ival > 2)
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

/*##################  TQuizR4::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR4::ExportExcelAspie(const char *filename)
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
	    if (Row.AqResult)
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

/*##################  TQuizR4::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR4::ExportExcelGroups(const char *filename)
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
					ival = Quiz[i].Cats - ival;
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

/*##################  TQuizR4::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR4::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_ALL)
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

/*##################  TQuizR4::WriteAQ ##########################
*   Purpose....: Write AQ test report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR4::WriteAQ(const char *filename)
{
	int Count;
	long double AsSum;
	long double NtSum;
	long double DiffSum;
	long double AqSum;
	long double AsMean;
	long double NtMean;
	long double DiffMean;
	long double AqMean;
	long double AsSd;
	long double NtSd;
	long double DiffSd;
	long double AqSd;
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
	TFile file(filename, 0);

	Count = 0;
	AsSum = 0;
	NtSum = 0;
	AqSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.AqResult)
        {
			Count++;
			AsSum += Row.AsResult;
			NtSum += Row.NtResult;
			DiffSum += Row.AsResult - Row.NtResult;
			AqSum += Row.AqResult;
	    }
	}

	AsMean = AsSum / Count;
	NtMean = NtSum / Count;
	DiffMean = DiffSum / Count;
	AqMean = AqSum / Count;

	AsSum = 0;
	NtSum = 0;
	AqSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.AqResult)
        {
            val = (long double)Row.AsResult - AsMean;
   			AsSum += val * val;
   			
            val = (long double)Row.NtResult - NtMean;
			NtSum += val * val;
			
            val = (long double)(Row.AsResult - Row.NtResult) - DiffMean;
			DiffSum += val * val;

            val = (long double)Row.AqResult - AqMean;
			AqSum += val * val;
	    }
	}

	AsSd = sqrtl(AsSum / (Count - 1));
	NtSd = sqrtl(NtSum / (Count - 1));
	DiffSd = sqrtl(DiffSum / (Count - 1));
	AqSd = sqrtl(AqSum / (Count - 1));

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.AqResult)
        {
            zx = ((long double)Row.AqResult - AqMean) / AqSd;

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
	printf("Mean AQ score: %5.1Lf, SD: %5.1Lf\r\n", AqMean, AqSd);

	printf("AQ - Aspie score correlation: %5.2Lf\r\n", AsCorr);
	printf("AQ - NT score correlation: %5.2Lf\r\n", NtCorr);
	printf("AQ - score diff correlation: %5.2Lf\r\n", DiffCorr);
}

