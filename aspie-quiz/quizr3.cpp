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
# quizr3.cpp
# Quiz R3 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr3.h"
#include "file.h"
#include "quizdbr3.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizR3::TQuizR3
#
#   Purpose....: Constructor for TQuizR3
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR3::TQuizR3(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2)
  : TQuiz(180),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR3::~TQuizR3
#
#   Purpose....: Destructor for TQuizR3
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR3::~TQuizR3()
{
}

/*##################  TQuizR3::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR3::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR3::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::WriteName(TFile &File)
{
	 File.Write("R3");
}

/*##########################################################################
#
#   Name       : TQuizR3::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::WriteLongName(TFile &File)
{
	 File.Write("experimental version 3");
}

/*##################  TQuizR3::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR3::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR3::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::SetupTexts()
{
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[19].Reverse = TRUE;
  Quiz[20].Reverse = TRUE;
  Quiz[21].Reverse = TRUE;
  Quiz[22].Reverse = TRUE;
  Quiz[23].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[50].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_SOCIAL;
  Quiz[2].MyGroup = GROUP_NT_NVC;
  Quiz[3].MyGroup = GROUP_SOCIAL;
  Quiz[4].MyGroup = GROUP_SOCIAL;
  Quiz[5].MyGroup = GROUP_SEX;
  Quiz[6].MyGroup = GROUP_MIXED;
  Quiz[7].MyGroup = GROUP_SOCIAL;
  Quiz[8].MyGroup = GROUP_SOCIAL;
  Quiz[9].MyGroup = GROUP_SOCIAL;
  Quiz[10].MyGroup = GROUP_ENVIRONMENT;
  Quiz[11].MyGroup = GROUP_ENVIRONMENT;
  Quiz[12].MyGroup = GROUP_NT_NVC;
  Quiz[13].MyGroup = GROUP_MIXED;
  Quiz[14].MyGroup = GROUP_SOCIAL;
  Quiz[15].MyGroup = GROUP_MIXED;
  Quiz[16].MyGroup = GROUP_MIXED;
  Quiz[17].MyGroup = GROUP_SOCIAL;
  Quiz[18].MyGroup = GROUP_NT_OBSESSION;
  Quiz[19].MyGroup = GROUP_NT_OBSESSION;
  Quiz[20].MyGroup = GROUP_NT_OBSESSION;
  Quiz[21].MyGroup = GROUP_NT_NVC;
  Quiz[22].MyGroup = GROUP_NT_NVC;
  Quiz[23].MyGroup = GROUP_SOCIAL;
  Quiz[24].MyGroup = GROUP_SOCIAL;
  Quiz[25].MyGroup = GROUP_NT_NVC;
  Quiz[26].MyGroup = GROUP_ASPIE_NVC;
  Quiz[27].MyGroup = GROUP_ASPIE_NVC;
  Quiz[28].MyGroup = GROUP_ASPIE_NVC;
  Quiz[29].MyGroup = GROUP_ASPIE_NVC;
  Quiz[30].MyGroup = GROUP_ASPIE_NVC;
  Quiz[31].MyGroup = GROUP_ASPIE_NVC;
  Quiz[32].MyGroup = GROUP_NT_NVC;
  Quiz[33].MyGroup = GROUP_MIXED;
  Quiz[34].MyGroup = GROUP_ASPIE_NVC;
  Quiz[35].MyGroup = GROUP_SOCIAL;
  Quiz[36].MyGroup = GROUP_SOCIAL;
  Quiz[37].MyGroup = GROUP_NT_NVC;
  Quiz[38].MyGroup = GROUP_NT_NVC;
  Quiz[39].MyGroup = GROUP_MIXED;
  Quiz[40].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[41].MyGroup = GROUP_NT_NVC;
  Quiz[42].MyGroup = GROUP_SOCIAL;
  Quiz[43].MyGroup = GROUP_SOCIAL;
  Quiz[44].MyGroup = GROUP_SOCIAL;
  Quiz[45].MyGroup = GROUP_ASPIE_NVC;
  Quiz[46].MyGroup = GROUP_ASPIE_NVC;
  Quiz[47].MyGroup = GROUP_NT_NVC;
  Quiz[48].MyGroup = GROUP_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_NVC;
  Quiz[50].MyGroup = GROUP_NT_NVC;
  Quiz[51].MyGroup = GROUP_NT_NVC;
  Quiz[52].MyGroup = GROUP_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[54].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[55].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[56].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[57].MyGroup = GROUP_ASPIE_NVC;
  Quiz[58].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[59].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[60].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[61].MyGroup = GROUP_MIXED;
  Quiz[62].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[63].MyGroup = GROUP_SEX;
  Quiz[64].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[65].MyGroup = GROUP_SOCIAL;
  Quiz[66].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[67].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[68].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[69].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[70].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[71].MyGroup = GROUP_MIXED;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ASPIE_NVC;
  Quiz[74].MyGroup = GROUP_ASPIE_NVC;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ASPIE_NVC;
  Quiz[77].MyGroup = GROUP_ASPIE_NVC;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
  Quiz[82].MyGroup = GROUP_ASPIE_NVC;
  Quiz[83].MyGroup = GROUP_ASPIE_NVC;
  Quiz[84].MyGroup = GROUP_ASPIE_NVC;
  Quiz[85].MyGroup = GROUP_ASPIE_NVC;
  Quiz[86].MyGroup = GROUP_ASPIE_NVC;
  Quiz[87].MyGroup = GROUP_ASPIE_NVC;
  Quiz[88].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[89].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[90].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[91].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[92].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[93].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[94].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[95].MyGroup = GROUP_ASPIE_NVC;
  Quiz[96].MyGroup = GROUP_ASPIE_NVC;
  Quiz[97].MyGroup = GROUP_ASPIE_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[100].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[101].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[102].MyGroup = GROUP_NT_TALENT;
  Quiz[103].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[104].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[105].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[106].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[107].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[108].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[109].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[110].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[111].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[112].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[113].MyGroup = GROUP_ASPIE_NVC;
  Quiz[114].MyGroup = GROUP_ENVIRONMENT;
  Quiz[115].MyGroup = GROUP_ENVIRONMENT;
  Quiz[116].MyGroup = GROUP_ENVIRONMENT;
  Quiz[117].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[118].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[119].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[120].MyGroup = GROUP_ENVIRONMENT;
  Quiz[121].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[122].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[123].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[124].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[125].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[126].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[127].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[128].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[129].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[130].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[131].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[132].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[133].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[138].MyGroup = GROUP_ACTIVITY;
  Quiz[139].MyGroup = GROUP_ACTIVITY;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_NT_OBSESSION;
  Quiz[143].MyGroup = GROUP_SEX;
  Quiz[144].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[145].MyGroup = GROUP_ACTIVITY;
  Quiz[146].MyGroup = GROUP_SOCIAL;
  Quiz[147].MyGroup = GROUP_ENVIRONMENT;
  Quiz[148].MyGroup = GROUP_NT_SENSORY;
  Quiz[149].MyGroup = GROUP_NT_HUNTING;
  Quiz[150].MyGroup = GROUP_NT_TALENT;
  Quiz[151].MyGroup = GROUP_ENVIRONMENT;
  Quiz[152].MyGroup = GROUP_NT_TALENT;
  Quiz[153].MyGroup = GROUP_NT_TALENT;
  Quiz[154].MyGroup = GROUP_NT_TALENT;
  Quiz[155].MyGroup = GROUP_NT_NVC;
  Quiz[156].MyGroup = GROUP_ACTIVITY;
  Quiz[157].MyGroup = GROUP_ACTIVITY;
  Quiz[158].MyGroup = GROUP_ACTIVITY;
  Quiz[159].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[160].MyGroup = GROUP_ACTIVITY;
  Quiz[161].MyGroup = GROUP_ACTIVITY;
  Quiz[162].MyGroup = GROUP_ACTIVITY;
  Quiz[163].MyGroup = GROUP_ACTIVITY;
  Quiz[164].MyGroup = GROUP_MIXED;
  Quiz[165].MyGroup = GROUP_NT_TALENT;
  Quiz[166].MyGroup = GROUP_NT_HUNTING;
  Quiz[167].MyGroup = GROUP_NT_SENSORY;
  Quiz[168].MyGroup = GROUP_NT_SENSORY;
  Quiz[169].MyGroup = GROUP_NT_SENSORY;
  Quiz[170].MyGroup = GROUP_NT_SENSORY;
  Quiz[171].MyGroup = GROUP_NT_SENSORY;
  Quiz[172].MyGroup = GROUP_NT_SENSORY;
  Quiz[173].MyGroup = GROUP_NT_SENSORY;
  Quiz[174].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[175].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[176].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[177].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[178].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[179].MyGroup = GROUP_ENVIRONMENT;

#ifdef ENGLISH
  Quiz[0].Text = "Have you felt different from others for most of your life?";
  Quiz[1].Text = "Have you had more difficulties than others making friends?";
  Quiz[2].Text = "Is it or has it been harder for you than for others to find a partner?";
  Quiz[3].Text = "Are you more of an observer than one who participates in life?";
  Quiz[4].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[5].Text = "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?";
  Quiz[6].Text = "Have you had a tendency to prefer the company of those who are older or younger than yourself?";
  Quiz[7].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[8].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[9].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[10].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[11].Text = "Have you had thoughts of committing suicide?";
  Quiz[12].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[13].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[14].Text = "Do you tend to feel nervous, shy, confused or left out in social situations?";
  Quiz[15].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[16].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[17].Text = "Are you comfortable in most social situations and with new people?";
  Quiz[18].Text = "Do you like having others involved in your activities?";
  Quiz[19].Text = "Is a large social network important to you?";
  Quiz[20].Text = "Is your image and social identity a important to you?";
  Quiz[21].Text = "Are you intuitive about what people need from you?";
  Quiz[22].Text = "Do you find the usual courting behavior natural?";
  Quiz[23].Text = "Are you good at teamwork?";
  Quiz[24].Text = "Is it difficult or tiresome for you to talk?";
  Quiz[25].Text = "Do you have a monotonous voice?";
  Quiz[26].Text = "Do you tend to talk either too softly or too loundly?";
  Quiz[27].Text = "Do you stutter when stressed?";
  Quiz[28].Text = "Do you have difficulties with pronunciation?";
  Quiz[29].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[30].Text = "Do you sometimes say \"we\" instead of \"I\"?";
  Quiz[31].Text = "Do you have a habit of repeating others' last words (echolalia)?";
  Quiz[32].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[33].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[34].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[35].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[36].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[37].Text = "Do you have difficulties understanding figures of speech, idioms, allegories and a tendency to interpret things literally?";
  Quiz[38].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
  Quiz[39].Text = "Do you expect other people to know your thoughts, experiences and opinions?";
  Quiz[40].Text = "Do you tend to be more blunt and straightforward than others?";
  Quiz[41].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[42].Text = "Do you dislike shaking hands?";
  Quiz[43].Text = "Do you prefer to avoid eye-contact?";
  Quiz[44].Text = "Do you look this way and that while talking to people?";
  Quiz[45].Text = "Have you been accused of staring?";
  Quiz[46].Text = "Do people sometimes think you are smiling when you shouldn't?";
  Quiz[47].Text = "Do others often misunderstand you?";
  Quiz[48].Text = "Do you find it easy to describe your feelings?";
  Quiz[49].Text = "Can you read between the lines?";
  Quiz[50].Text = "Is it easy for you to adopt a polite or socially 'appropriate' facial expression, even if it does not match what you feel inside?";
  Quiz[51].Text = "Would you rather tell a polite white lie than a potentially painful but informative truth?";
  Quiz[52].Text = "Are you good at small talk?";
  Quiz[53].Text = "Do you have extra sensitive hearing?";
  Quiz[54].Text = "Are you easily disturbed by sounds/noises that others make?";
  Quiz[55].Text = "Do you find the sound from a motor-bike, helicopter or tractor painful?";
  Quiz[56].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[57].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[58].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[59].Text = "Do you have a very acute sense of smell?";
  Quiz[60].Text = "Do you have a very acute sense of taste?";
  Quiz[61].Text = "Are you a picky eater?";
  Quiz[62].Text = "Are you extra sensitive to physical pain?";
  Quiz[63].Text = "Are you fairly non-sensitive to physical pain?";
  Quiz[64].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[65].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[66].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
  Quiz[67].Text = "Are you sensitive to heat?";
  Quiz[68].Text = "Are you sensitive to cold?";
  Quiz[69].Text = "Are you sensitive to wind?";
  Quiz[70].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[71].Text = "Do you prefer cold weather over warm weather?";
  Quiz[72].Text = "Do you tap your fingers (e.g. when bored, restless or concentrating)?";
  Quiz[73].Text = "Do you click or tap a pen?";
  Quiz[74].Text = "Do you bounce your leg or foot?";
  Quiz[75].Text = "Do you chew or suck on pencil, toothpick or similar object?";
  Quiz[76].Text = "Do you doodle (e.g. at lectures or when on the phone)?";
  Quiz[77].Text = "Do you fiddle with things?";
  Quiz[78].Text = "Do you crack joints?";
  Quiz[79].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[80].Text = "Do you grind teeth?";
  Quiz[81].Text = "Do you talk to yourself?";
  Quiz[82].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[83].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[84].Text = "Do you twirl your hair?";
  Quiz[85].Text = "Do you bite your nails, cuticles or fingertips (e.g. when bored, anxious or nervous)?";
  Quiz[86].Text = "Do you dig your fingerlails under the nails on the other hand?";
  Quiz[87].Text = "Do you pick your nose?";
  Quiz[88].Text = "Do you enjoy spinning in circles?";
  Quiz[89].Text = "Do you enjoy walking on your toes?";
  Quiz[90].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[91].Text = "Do you enjoy watching things that shimmer or glitter?";
  Quiz[92].Text = "Do you enjoy watching or playing with water?";
  Quiz[93].Text = "Do you like sniffing people or things?";
  Quiz[94].Text = "Do you enjoy biting people - if they let you?";
  Quiz[95].Text = "Do you bite yourself (e.g. when upset)?";
  Quiz[96].Text = "Do you flap your hands (e.g. when excited or upset)?";
  Quiz[97].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[98].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[99].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[100].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[101].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[102].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[103].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[104].Text = "Do you love to collect things?";
  Quiz[105].Text = "Are you good at sorting, organizing and creating order?";
  Quiz[106].Text = "Do you love to make lists, diagrams etc for the fun of it?";
  Quiz[107].Text = "Do you have certain routines which you need to follow?";
  Quiz[108].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[109].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[110].Text = "Do you prefer to wear the same clothes every day for many days in a row?";
  Quiz[111].Text = "Do you prefer to eat the same food every day for long periods at a time?";
  Quiz[112].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[113].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[114].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[115].Text = "Do you find it stressful to go to a new place alone for the first time?";
  Quiz[116].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[117].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[118].Text = "Do you have a need for comfort items like a blanket, stuffed animals etc?";
  Quiz[119].Text = "Do you more easily get very upset over 'minor' things (e.g. losing your favourite pen) than over things which others get upset about?";
  Quiz[120].Text = "Do you self-harm, or have you done so in the past?";
  Quiz[121].Text = "Are you very gifted in one or more areas?";
  Quiz[122].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[123].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[124].Text = "Do you have unconventional ways of solving problems?";
  Quiz[125].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[126].Text = "Do you have a hyperactive mind?";
  Quiz[127].Text = "Do you have a good memory for dates and/or numbers?";
  Quiz[128].Text = "Are you good at math?";
  Quiz[129].Text = "Are you a computer geek?";
  Quiz[130].Text = "Do you have strong sense of ethics and a tendency to stand up for your ideals & beliefs?";
  Quiz[131].Text = "Do you take on too much because it is easier to do it yourself than having to explain to others how to do it?";
  Quiz[132].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[133].Text = "Do you try to always be punctual?";
  Quiz[134].Text = "Do you always give back books, things or money you have borrowed and expect others to do the same?";
  Quiz[135].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[136].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[137].Text = "Do you have odd teeth; e.g. that are crooked, bigger than usual; that have gaps, overlaps, underbite or that show extra much gum?";
  Quiz[138].Text = "Are you naturally nocturnal, most alert after midnight?";
  Quiz[139].Text = "Do you have atypical or irregular sleeping patterns that deviate from the 24-h cycle?";
  Quiz[140].Text = "Do you have unusual eating habits?";
  Quiz[141].Text = "Do you find the norms of hygiene too strict?";
  Quiz[142].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[143].Text = "Do you have an alternative view of what is attractive in the opposite sex compared to most others?";
  Quiz[144].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[145].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[146].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[147].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[148].Text = "Do you have poor concept of time?";
  Quiz[149].Text = "Do you often forget were you put things?";
  Quiz[150].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[151].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[152].Text = "Do you have difficulty describing & summarising for example events, conversations or something you've read?";
  Quiz[153].Text = "Is it difficult for you to multitask?";
  Quiz[154].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[155].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[156].Text = "Do you tend to be impatient and impulsive?";
  Quiz[157].Text = "Do you find it hard to focus on or learn things you are not interested in?";
  Quiz[158].Text = "Do you tend to procrastinate?";
  Quiz[159].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[160].Text = "Are you or have you been hyperactive?";
  Quiz[161].Text = "Do you tend to be restless?";
  Quiz[162].Text = "Are you easily distracted?";
  Quiz[163].Text = "Are you easily bored?";
  Quiz[164].Text = "Do you flip letters when you write?";
  Quiz[165].Text = "Do you find it difficult to taking notes in lectures?";
  Quiz[166].Text = "Do you have trouble with math?";
  Quiz[167].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[168].Text = "Do you have poor balance, e.g. difficulty riding a bicycle, skating, standing on one leg?";
  Quiz[169].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[170].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[171].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
  Quiz[172].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands and a tendency to drop, spill or break things by mistake?";
  Quiz[173].Text = "Do you have difficulty writing by hand?";
  Quiz[174].Text = "Do you have tics?";
  Quiz[175].Text = "Do you have difficulties swallowing (dysphagia)?";
  Quiz[176].Text = "Do you have chronic bronchitis?";
  Quiz[177].Text = "Do you cough even when you don't have a cold?";
  Quiz[178].Text = "Do you constantly clear your throat?";
  Quiz[179].Text = "Are you prone to getting depressions?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[1].Text = "Har du haft svårare än andra att få vänner?";
  Quiz[2].Text = "Är det eller har det varit svårare för dig än för andra att hitta en partner?";
  Quiz[3].Text = "Känner du dig mer som en observatör än som en deltagare i livet?";
  Quiz[4].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[5].Text = "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?";
  Quiz[6].Text = "Har du haft en tendens att helst umgås med människor som är antingen äldre eller yngre än du själv?";
  Quiz[7].Text = "Föredrar du att bara umgås med folk du känner väl, på tu man hand eller i en mindre grupp?";
  Quiz[8].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[9].Text = "Blir du irriterad när folk kommer på besök oanmälda?";
  Quiz[10].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[11].Text = "Har du haft självmordstankar?";
  Quiz[12].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[13].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[14].Text = "Brukar du bli nervös, blyg, förvirrad eller känna dig utanför i olika sociala situationer?";
  Quiz[15].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[16].Text = "Tar du ibland initiativ som inte visar sig önskade?";
  Quiz[17].Text = "Känner du dig hemma i de flesta sociala situationer och med nya människor?";
  Quiz[18].Text = "Tycker du om att ha med andra i dina aktiviteter?";
  Quiz[19].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[20].Text = "Är din image och sociala identitet viktig för dig?";
  Quiz[21].Text = "Känner du intuitivt vad folk behöver från dig?";
  Quiz[22].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[23].Text = "Är du bra på att arbeta i grupp?";
  Quiz[24].Text = "Finner du det svårt eller tröttsamt att tala?";
  Quiz[25].Text = "Har du en monoton röst?";
  Quiz[26].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[27].Text = "Stammar du när du blir stressad?";
  Quiz[28].Text = "Har du svårigheter med uttal?";
  Quiz[29].Text = "Använder du små ljud som andra inte verkar använda i samtal?";
  Quiz[30].Text = "Säger du ibland \"vi\" istället för \"jag\"?";
  Quiz[31].Text = "Brukar du upprepa de sista orden som någon annan just sagt (ekolali)?";
  Quiz[32].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[33].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[34].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[35].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[36].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[37].Text = "Har du svårt att förstå talesätt, idiom, allegorier och en tendens att tolka saker bokstavligt?";
  Quiz[38].Text = "Brukar du ha svårt att tolka kroppsspråk och/eller ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
  Quiz[39].Text = "Förväntar du dig att andra vet om dina tankar, upplevelser och åsikter?";
  Quiz[40].Text = "Brukar du vara mer rak och rättfram i din kommunikation än andra?";
  Quiz[41].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[42].Text = "Ogillar du att behöva ta i hand?";
  Quiz[43].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[44].Text = "Brukar du flacka med blicken när du talar med folk?";
  Quiz[45].Text = "Har du blivit anklagad för att stirra?";
  Quiz[46].Text = "Tycker andra ibland att du ler när du inte borde?";
  Quiz[47].Text = "Blir du ofta missförstådd av andra?";
  Quiz[48].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[49].Text = "Kan du läsa mellan raderna?";
  Quiz[50].Text = "Är det lätt för dig att använda ett artigt eller 'passande' ansiktsuttryck, även om det inte motsvarar vad du egentligen känner?";
  Quiz[51].Text = "Skulle du hellre använda en artig vit lögn än en potentiellt smärtsam men informativ sanning?";
  Quiz[52].Text = "Är du bra på kallprat?";
  Quiz[53].Text = "Har du extra känslig hörsel?";
  Quiz[54].Text = "Blir du lätt störd av ljud från andra?";
  Quiz[55].Text = "Upplever du att ljudet från en motorcykel, helikopter eller traktor gör ont?";
  Quiz[56].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[57].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
  Quiz[58].Text = "Tycker du att lysrörsljus känns obehagligt?";
  Quiz[59].Text = "Har du extra känsligt luktsinne?";
  Quiz[60].Text = "Har du extra känsligt smaksinne?";
  Quiz[61].Text = "Är du petig med vad du äter?";
  Quiz[62].Text = "Är du extra känslig för fysisk smärta?";
  Quiz[63].Text = "Är du ganska okänslig för fysisk smärta?";
  Quiz[64].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[65].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[66].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
  Quiz[67].Text = "Är du känslig för värme?";
  Quiz[68].Text = "Är du känsig för kyla?";
  Quiz[69].Text = "Är du känslig för när det blåser?";
  Quiz[70].Text = "Är du känslig för omslag i luftryck och luftfuktighet?";
  Quiz[71].Text = "Trivs du bättre i kallt väder än i varmt?";
  Quiz[72].Text = "Brukar du trumma med fingrarna (t. ex när du är uttråkad, rastlös eller när du koncentrerar dig)?";
  Quiz[73].Text = "Brukar du klicka på eller vippa med en penna?";
  Quiz[74].Text = "Brukar du vippa på benet eller foten?";
  Quiz[75].Text = "Brukar du tugga eller suga på en penna, tandpetare el dyl?";
  Quiz[76].Text = "Brukar du klottra i ditt anteckningsblock (t ex under ett föredrag eller medan du pratar i telefon)?";
  Quiz[77].Text = "Brukar du fingra på saker?";
  Quiz[78].Text = "Brukar du dra i/knäcka leder?";
  Quiz[79].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[80].Text = "Brukar du gnissla tänder?";
  Quiz[81].Text = "Brukar du prata med dig själv?";
  Quiz[82].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[83].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[84].Text = "Brukar du snurra på en hårslinga?";
  Quiz[85].Text = "Brukar du bita på naglarna, nagelbanden eller fingertopparna (t ex när du är uttråkad, orolig eller nervös)?";
  Quiz[86].Text = "Brukar du sticka in naglarna under andra handens naglar?";
  Quiz[87].Text = "Brukar du peta näsan?";
  Quiz[88].Text = "Gillar du att snurra runt, runt?";
  Quiz[89].Text = "Gillar du att gå på tå?";
  Quiz[90].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[91].Text = "Gillar du att titta på något som skimrar eller glittrar?";
  Quiz[92].Text = "Gillar du att titta på eller leka med vatten?";
  Quiz[93].Text = "Gillar du att på nära håll lukta på andra människor eller saker?";
  Quiz[94].Text = "Gillar du att bita folk - om du får?";
  Quiz[95].Text = "Brukar du bita dig själv? (t ex när du är upprörd)?";
  Quiz[96].Text = "Brukar du vifta med händerna (t ex när du är upprymd eller upprörd)?";
  Quiz[97].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[98].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[99].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[100].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[101].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[102].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[103].Text = "Har du behov av symmetri, ordning och/eller precision?";
  Quiz[104].Text = "Gillar du att samla?";
  Quiz[105].Text = "Är du bra på att sortera, organisera och skapa ordning?";
  Quiz[106].Text = "Gillar du att göra listor, diagram o dyl för att det är kul?";
  Quiz[107].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[108].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[109].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[110].Text = "Föredrar du att ha samma kläder varje dag, många dar i rad?";
  Quiz[111].Text = "Föredrar du att äta samma mat varje dag, långa perioder i taget?";
  Quiz[112].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[113].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[114].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[115].Text = "Blir du stressad av att gå till ett nytt ställe för första gången?";
  Quiz[116].Text = "Stänger du av eller bryter ihop när du blir stressad eller överväldigad?";
  Quiz[117].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[118].Text = "Har du behov av gosefilt, kramdjur eller liknande?";
  Quiz[119].Text = "Brukar du bli mer upprörd över smärre saker (t ex att du tappat din favoritpenna) än över sånt som andra brukar bli upprörda av?";
  Quiz[120].Text = "Brukar du eller har du brukat ägna dig åt självskadande beteende?";
  Quiz[121].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[122].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[123].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[124].Text = "Har du okonventionella sätt att lösa problem på?";
  Quiz[125].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[126].Text = "Är du mentalt hyperaktiv?";
  Quiz[127].Text = "Har du bra minne för datum och/eller siffror?";
  Quiz[128].Text = "Är du bra på matte?";
  Quiz[129].Text = "Är du en datornörd?";
  Quiz[130].Text = "Har du hög moral och en tendens att hålla fast vid/stå upp för dina ideal?";
  Quiz[131].Text = "Tar du på dig för mycket för att det är enklare att göra saker själv än att förklara för andra hur man gör?";
  Quiz[132].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[133].Text = "Försöker du alltid vara punktlig?";
  Quiz[134].Text = "Lämnar du alltid tillbaka böcker, saker och pengar du lånat och förväntar dig att andra gör detsamma?";
  Quiz[135].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[136].Text = "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
  Quiz[137].Text = "Har du udda tänder; t ex tänder som sitter snett, klättrar på varandra; är större än vanligt; mellanrum mellan tänderna; underbett, som visar extra mycket tandkött?";
  Quiz[138].Text = "Är du en nattmänniska, som piggast efter midnatt?";
  Quiz[139].Text = "Har du otypisk eller oregelbunden sömnrytm (d v s som avviker från 24-timmarscykeln)?";
  Quiz[140].Text = "Har du ovanliga matvanor?";
  Quiz[141].Text = "Tycker du att normerna för hygien är för strikta?";
  Quiz[142].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[143].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet än vad många andra anser?";
  Quiz[144].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[145].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[146].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[147].Text = "Har du svårare att klara dig själv än andra i samma ålder?";
  Quiz[148].Text = "Har du dålig tidsuppfattning?";
  Quiz[149].Text = "Glömmer du ofta var du lagt saker?";
  Quiz[150].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[151].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[152].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[153].Text = "Har du svårt att göra flera saker samtidigt?";
  Quiz[154].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[155].Text = "Har du svårt att känna igen ansikten?";
  Quiz[156].Text = "Brukar du vara otålig och impulsiv och t ex ha svårt att vänta på din tur?";
  Quiz[157].Text = "Har du svårt att koncenterera dig på eller lära dig saker du inte är intresserad av?";
  Quiz[158].Text = "Brukar du skjuta upp saker in i det längsta?";
  Quiz[159].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[160].Text = "Är du eller har du varit hyperaktiv";
  Quiz[161].Text = "Brukar du vara rastlös?";
  Quiz[162].Text = "Blir du lätt distraherad?";
  Quiz[163].Text = "Blir du lätt uttråkad?";
  Quiz[164].Text = "Brukar du kasta om bokstäver när du skriver?";
  Quiz[165].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[166].Text = "Har du problem med matematik?";
  Quiz[167].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[168].Text = "Har du dåligt balanssinne, t ex svårt att cykla, åka skridskor, stå på ett ben?";
  Quiz[169].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[170].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[171].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[172].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna och en tendens att tappa, spilla eller ha sönder saker av misstag?";
  Quiz[173].Text = "Har du svårt att skriva för hand?";
  Quiz[174].Text = "Har du tics?";
  Quiz[175].Text = "Har du sväljsvårigheter?";
  Quiz[176].Text = "Har du problem med luftrören?";
  Quiz[177].Text = "Brukar du hosta fast du inte är förkyld?";
  Quiz[178].Text = "Brukar du ständigt harkla dig?";
  Quiz[179].Text = "Brukar du få depressioner?";
#endif

}

/*##########################################################################
#
#   Name       : TQuizR3::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::InitReferers()
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

/*##################  TQuizR3::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR3::LoadReferers()
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

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

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
#   Name       : TQuizR3::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::LoadPopulations()
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
#   Name       : TQuizR3::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::SetupControlGroups()
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
#   Name       : TQuizR3::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2)
{
    DefineCross(QuizR1, 0, 0);
    DefineGlobalId( 1, 541);
    DefineGlobalId( 2, 542);
	 DefineCross(QuizR2, 3, 56);
    DefineCross(QuizR2, 4, 52);
    DefineCross(QuizR2, 5, 71);
    DefineGlobalId( 6, 543);
    DefineCross(QuizR2, 7, 151);
    DefineCross(QuizR2, 8, 44);
    DefineCross(QuizR2, 9, 70);
    DefineCross(QuizR2, 10, 109);
    DefineCross(QuizR2, 11, 116);
    DefineCross(QuizR2, 12, 43);
    DefineCross(QuizR2, 13, 108);
    DefineCross(QuizR2, 14, 47);
    DefineCross(QuizR2, 15, 136);
    DefineCross(QuizR2, 16, 106);
    DefineCross(QuizR2, 17, 55);
    DefineCross(QuizR2, 18, 65);
    DefineCross(QuizR2, 19, 74);
    DefineCross(QuizR1, 20, 18);
    DefineCross(QuizR2, 21, 102);
    DefineCross(QuizR2, 22, 53);
    DefineGlobalId( 23, 544);
    DefineCross(QuizR2, 24, 150);
    DefineGlobalId( 25, 545);
    DefineGlobalId( 26, 546);
    DefineCross(QuizR2, 27, 152);
    DefineCross(QuizR2, 28, 156);
    DefineCross(QuizR2, 29, 78);
    DefineCross(QuizR2, 30, 158);
    DefineGlobalId( 31, 547);
    DefineCross(QuizR2, 32, 89);
    DefineGlobalId( 33, 548);
    DefineCross(QuizR2, 34, 104);
    DefineCross(QuizR2, 35, 49);
    DefineCross(QuizR2, 36, 50);
    DefineGlobalId( 37, 549);
	 DefineCross(QuizR2, 38, 90);
    DefineCross(QuizR2, 39, 114);
    DefineCross(QuizR2, 40, 32);
    DefineGlobalId( 41, 550);
    DefineCross(QuizR2, 42, 107);
    DefineGlobalId( 43, 551);
    DefineGlobalId( 44, 552);
    DefineCross(QuizR2, 45, 77);
    DefineGlobalId( 46, 553);
    DefineCross(QuizR2, 47, 135);
	 DefineCross(QuizR2, 48, 100);
	 DefineCross(QuizR1, 49, 32);
	 DefineGlobalId( 50, 554);
	 DefineGlobalId( 51, 555);
	 DefineCross(QuizR1, 52, 36);
	 DefineCross(QuizR2, 53, 12);
	 DefineGlobalId( 54, 556);
	 DefineGlobalId( 55, 557);
	 DefineCross(QuizR2, 56, 99);
	 DefineCross(QuizR2, 57, 11);
	 DefineCross(QuizR1, 58, 79);
	 DefineCross(QuizR1, 59, 74);
	 DefineCross(QuizR1, 60, 72);
	 DefineGlobalId( 61, 558);
	 DefineGlobalId( 62, 559);
	 DefineGlobalId( 63, 560);
	 DefineCross(QuizR2, 64, 9);
	 DefineCross(QuizR2, 65, 51);
	 DefineCross(QuizR2, 66, 16);
	 DefineGlobalId( 67, 561);
	 DefineGlobalId( 68, 562);
	 DefineGlobalId( 69, 563);
	 DefineGlobalId( 70, 564);
	 DefineCross(QuizR2, 71, 24);
	 DefineCross(QuizR2, 72, 80);
	 DefineGlobalId( 73, 565);
	 DefineGlobalId( 74, 566);
	 DefineGlobalId( 75, 567);
	 DefineGlobalId( 76, 568);
	 DefineGlobalId( 77, 569);
	 DefineGlobalId( 78, 570);
	 DefineGlobalId( 79, 571);
	 DefineGlobalId( 80, 572);
	 DefineCross(QuizR2, 81, 82);
	 DefineGlobalId( 82, 573);
	 DefineGlobalId( 83, 574);
	 DefineGlobalId( 84, 575);
	 DefineGlobalId( 85, 576);
	 DefineGlobalId( 86, 577);
	 DefineGlobalId( 87, 578);
	 DefineGlobalId( 88, 579);
	 DefineGlobalId( 89, 580);
	 DefineGlobalId( 90, 581);
	 DefineGlobalId( 91, 582);
	 DefineGlobalId( 92, 583);
	 DefineGlobalId( 93, 584);
	 DefineGlobalId( 94, 585);
	 DefineGlobalId( 95, 586);
	 DefineGlobalId( 96, 587);
	 DefineGlobalId( 97, 588);
	 DefineGlobalId( 98, 589);
	 DefineCross(QuizR2, 99, 27);
	 DefineCross(QuizR2, 100, 120);
	 DefineGlobalId( 101, 590);
	 DefineCross(QuizR2, 102, 121);
	 DefineCross(QuizR2, 103, 129);
	 DefineGlobalId( 104, 591);
	 DefineGlobalId( 105, 592);
	 DefineGlobalId( 106, 593);
	 DefineCross(QuizR2, 107, 126);
	 DefineGlobalId( 108, 594);
	 DefineGlobalId( 109, 595);
	 DefineGlobalId( 110, 596);
	 DefineGlobalId( 111, 597);
	 DefineGlobalId( 112, 598);
	 DefineGlobalId( 113, 599);
	 DefineGlobalId( 114, 600);
	 DefineGlobalId( 115, 601);
	 DefineCross(QuizR2, 116, 105);
	 DefineCross(QuizR2, 117, 127);
	 DefineCross(QuizR2, 118, 130);
	 DefineCross(QuizR2, 119, 138);
	 DefineCross(QuizR2, 120, 117);
	 DefineCross(QuizR2, 121, 34);
	 DefineCross(QuizR2, 122, 28);
	 DefineCross(QuizR2, 123, 30);
	 DefineCross(QuizR2, 124, 29);
	 DefineCross(QuizR1, 125, 39);
	 DefineCross(QuizR1, 126, 105);
	 DefineGlobalId( 127, 602);
	 DefineGlobalId( 128, 603);
	 DefineGlobalId( 129, 604);
	 DefineCross(QuizR2, 130, 33);
	 DefineCross(QuizR2, 131, 35);
	 DefineGlobalId( 132, 605);
	 DefineGlobalId( 133, 606);
	 DefineGlobalId( 134, 607);
	 DefineCross(QuizR2, 135, 45);
	 DefineCross(QuizR2, 136, 155);
	 DefineGlobalId( 137, 608);
	 DefineCross(QuizR2, 138, 26);
	 DefineGlobalId( 139, 609);
	 DefineCross(QuizR2, 140, 13);
	 DefineCross(QuizR2, 141, 157);
	 DefineCross(QuizR2, 142, 58);
	 DefineCross(QuizR2, 143, 143);
	 DefineCross(QuizR2, 144, 162);
	 DefineCross(QuizR2, 145, 148);
	 DefineCross(QuizR2, 146, 149);
	 DefineCross(QuizR2, 147, 144);
	 DefineCross(QuizR2, 148, 147);
	 DefineCross(QuizR2, 149, 41);
	 DefineCross(QuizR2, 150, 139);
	 DefineCross(QuizR2, 151, 112);
	 DefineCross(QuizR2, 152, 95);
	 DefineGlobalId( 153, 610);
	 DefineCross(QuizR2, 154, 137);
	 DefineCross(QuizR2, 155, 101);
	 DefineCross(QuizR2, 156, 111);
	 DefineCross(QuizR2, 157, 36);
	 DefineGlobalId( 158, 611);
	 DefineGlobalId( 159, 612);
	 DefineGlobalId( 160, 613);
	 DefineGlobalId( 161, 614);
	 DefineGlobalId( 162, 615);
	 DefineGlobalId( 163, 616);
	 DefineCross(QuizR2, 164, 40);
	 DefineCross(QuizR2, 165, 37);
	 DefineCross(Quiz8, 166, 38);
	 DefineCross(QuizR2, 167, 7);
	 DefineCross(QuizR1, 168, 86);
	 DefineCross(QuizR2, 169, 3);
	 DefineCross(QuizR2, 170, 8);
	 DefineCross(QuizR1, 171, 91);
	 DefineCross(QuizR1, 172, 93);
	 DefineCross(QuizR2, 173, 153);
	 DefineGlobalId( 174, 617);
	 DefineGlobalId( 175, 618);
	 DefineGlobalId( 176, 619);
	 DefineGlobalId( 177, 620);
	 DefineGlobalId( 178, 621);
	 DefineGlobalId( 179, 622);
}

/*##########################################################################
#
#   Name       : TQuizR3::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR3::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizR3::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR3::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizR3::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR3::ExportExcelAspie(const char *filename)
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

/*##################  TQuizR3::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR3::ExportExcelGroups(const char *filename)
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

/*##################  TQuizR3::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR3::ImportMvsp(const char *filename, int PcaType)
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
