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
# quizr5.cpp
# Quiz R5 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr5.h"
#include "file.h"
#include "quizdbr5.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

#if !defined(SWEDISH) && !defined(ENGLISH)
#define ENGLISH
#endif

/*##########################################################################
#
#   Name       : TQuizR5::TQuizR5
#
#   Purpose....: Constructor for TQuizR5
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR5::TQuizR5(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4)
  : TQuiz(144),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR5::~TQuizR5
#
#   Purpose....: Destructor for TQuizR5
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR5::~TQuizR5()
{
}

/*##################  TQuizR5::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR5::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR5::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::WriteName(TFile &File)
{
	 File.Write("R5");
}

/*##########################################################################
#
#   Name       : TQuizR5::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::WriteLongName(TFile &File)
{
	 File.Write("experimental version 5");
}

/*##################  TQuizR5::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR5::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::SetupTexts()
{
  Quiz[1].Reverse = TRUE;
  Quiz[2].Reverse = TRUE;
  Quiz[3].Reverse = TRUE;
  Quiz[4].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[41].Reverse = TRUE;
  Quiz[42].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[44].Reverse = TRUE;
  Quiz[46].Reverse = TRUE;
  Quiz[47].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[74].Reverse = TRUE;
  Quiz[88].Reverse = TRUE;
  Quiz[89].Reverse = TRUE;
  Quiz[110].Reverse = TRUE;
  Quiz[111].Reverse = TRUE;
  Quiz[114].Reverse = TRUE;
  Quiz[116].Reverse = TRUE;
  Quiz[119].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[123].Reverse = TRUE;
  Quiz[124].Reverse = TRUE;
  Quiz[127].Reverse = TRUE;
  Quiz[129].Reverse = TRUE;
  Quiz[130].Reverse = TRUE;
  Quiz[131].Reverse = TRUE;
  Quiz[134].Reverse = TRUE;
  Quiz[136].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_MIXED;
  Quiz[1].MyGroup = GROUP_NT_SENSORY;
  Quiz[2].MyGroup = GROUP_NT_SENSORY;
  Quiz[3].MyGroup = GROUP_MIXED;
  Quiz[4].MyGroup = GROUP_NT_SENSORY;
  Quiz[5].MyGroup = GROUP_NT_SENSORY;
  Quiz[6].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[7].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[8].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[9].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[10].MyGroup = GROUP_ASPIE_NVC;
  Quiz[11].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[12].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[13].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[14].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[15].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[16].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[17].MyGroup = GROUP_NT_SOCIAL;
  Quiz[18].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[19].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[20].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[21].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[24].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[25].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[26].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[27].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[28].MyGroup = GROUP_NT_TALENT;
  Quiz[29].MyGroup = GROUP_NT_TALENT;
  Quiz[30].MyGroup = GROUP_NT_HUNTING;
  Quiz[31].MyGroup = GROUP_NT_NVC;
  Quiz[32].MyGroup = GROUP_NT_OBSESSION;
  Quiz[33].MyGroup = GROUP_ASPIE_NVC;
  Quiz[34].MyGroup = GROUP_NT_SOCIAL;
  Quiz[35].MyGroup = GROUP_NT_SOCIAL;
  Quiz[36].MyGroup = GROUP_NT_SOCIAL;
  Quiz[37].MyGroup = GROUP_NT_SOCIAL;
  Quiz[38].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[39].MyGroup = GROUP_NT_NVC;
  Quiz[40].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[41].MyGroup = GROUP_NT_OBSESSION;
  Quiz[42].MyGroup = GROUP_NT_OBSESSION;
  Quiz[43].MyGroup = GROUP_NT_OBSESSION;
  Quiz[44].MyGroup = GROUP_NT_SOCIAL;
  Quiz[45].MyGroup = GROUP_ENVIRONMENT;
  Quiz[46].MyGroup = GROUP_NT_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_SOCIAL;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_NT_SOCIAL;
  Quiz[54].MyGroup = GROUP_NT_OBSESSION;
  Quiz[55].MyGroup = GROUP_NT_SOCIAL;
  Quiz[56].MyGroup = GROUP_NT_OBSESSION;
  Quiz[57].MyGroup = GROUP_NT_OBSESSION;
  Quiz[58].MyGroup = GROUP_NT_OBSESSION;
  Quiz[59].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[60].MyGroup = GROUP_ENVIRONMENT;
  Quiz[61].MyGroup = GROUP_NT_NVC;
  Quiz[62].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[63].MyGroup = GROUP_NT_TALENT;
  Quiz[64].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[65].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[66].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[67].MyGroup = GROUP_NT_NVC;
  Quiz[68].MyGroup = GROUP_MIXED;
  Quiz[69].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[70].MyGroup = GROUP_NT_HUNTING;
  Quiz[71].MyGroup = GROUP_ASPIE_NVC;
  Quiz[72].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[73].MyGroup = GROUP_NT_TALENT;
  Quiz[74].MyGroup = GROUP_NT_OBSESSION;
  Quiz[75].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[76].MyGroup = GROUP_NT_TALENT;
  Quiz[77].MyGroup = GROUP_ENVIRONMENT;
  Quiz[78].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ENVIRONMENT;
  Quiz[81].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[82].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[83].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[84].MyGroup = GROUP_ASPIE_NVC;
  Quiz[85].MyGroup = GROUP_NT_NVC;
  Quiz[86].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[87].MyGroup = GROUP_ASPIE_NVC;
  Quiz[88].MyGroup = GROUP_MIXED;
  Quiz[89].MyGroup = GROUP_NT_SOCIAL;
  Quiz[90].MyGroup = GROUP_ASPIE_NVC;
  Quiz[91].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[92].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[93].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_NVC;
  Quiz[96].MyGroup = GROUP_ASPIE_NVC;
  Quiz[97].MyGroup = GROUP_ASPIE_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[100].MyGroup = GROUP_ASPIE_NVC;
  Quiz[101].MyGroup = GROUP_ASPIE_NVC;
  Quiz[102].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_ASPIE_NVC;
  Quiz[107].MyGroup = GROUP_ASPIE_NVC;
  Quiz[108].MyGroup = GROUP_ASPIE_NVC;
  Quiz[109].MyGroup = GROUP_ASPIE_NVC;
  Quiz[110].MyGroup = GROUP_NT_NVC;
  Quiz[111].MyGroup = GROUP_NT_NVC;
  Quiz[112].MyGroup = GROUP_NT_NVC;
  Quiz[113].MyGroup = GROUP_NT_NVC;
  Quiz[114].MyGroup = GROUP_NT_TALENT;
  Quiz[115].MyGroup = GROUP_NT_TALENT;
  Quiz[116].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[117].MyGroup = GROUP_NT_NVC;
  Quiz[118].MyGroup = GROUP_NT_NVC;
  Quiz[119].MyGroup = GROUP_NT_NVC;
  Quiz[120].MyGroup = GROUP_ASPIE_NVC;
  Quiz[121].MyGroup = GROUP_NT_NVC;
  Quiz[122].MyGroup = GROUP_ENVIRONMENT;
  Quiz[123].MyGroup = GROUP_NT_TALENT;
  Quiz[124].MyGroup = GROUP_NT_NVC;
  Quiz[125].MyGroup = GROUP_NT_NVC;
  Quiz[126].MyGroup = GROUP_ASPIE_NVC;
  Quiz[127].MyGroup = GROUP_NT_TALENT;
  Quiz[128].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[129].MyGroup = GROUP_NT_HUNTING;
  Quiz[130].MyGroup = GROUP_NT_SENSORY;
  Quiz[131].MyGroup = GROUP_NT_SENSORY;
  Quiz[132].MyGroup = GROUP_ENVIRONMENT;
  Quiz[133].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[134].MyGroup = GROUP_NT_SENSORY;
  Quiz[135].MyGroup = GROUP_ASPIE_NVC;
  Quiz[136].MyGroup = GROUP_NT_TALENT;
  Quiz[137].MyGroup = GROUP_MIXED;
  Quiz[138].MyGroup = GROUP_NT_NVC;
  Quiz[139].MyGroup = GROUP_NT_SOCIAL;
  Quiz[140].MyGroup = GROUP_ASPIE_NVC;
  Quiz[141].MyGroup = GROUP_ASPIE_NVC;
  Quiz[142].MyGroup = GROUP_MIXED;
  Quiz[143].MyGroup = GROUP_ASPIE_NVC;

#ifdef ENGLISH
  Quiz[0].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[1].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  Quiz[2].Text = "Do you find it easy to imitate & time the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[3].Text = "Do you seldom fall, stumble or bump into things?";
  Quiz[4].Text = "Can you easily judge distance, height, depth and speed?";
  Quiz[5].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[6].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
  Quiz[7].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[8].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[9].Text = "Do you have extra sensitive hearing?";
  Quiz[10].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[11].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[12].Text = "Are you sensitive to weather changes?";
  Quiz[13].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[14].Text = "Do you have a very acute sense of smell and/or taste?";
  Quiz[15].Text = "Are you sensitive to dry air?";
  Quiz[16].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[17].Text = "As a child, was your play more directed towards social games with other kids, than for example, sorting, building, investigating or taking things apart?";
  Quiz[18].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[19].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[20].Text = "Do you notice patterns in things all the time?";
  Quiz[21].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[22].Text = "Do you have a hyperactive mind?";
  Quiz[23].Text = "Do you have unconventional ways of solving problems?";
  Quiz[24].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[25].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[26].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[27].Text = "Do you often find reasons to question authorities?";
  Quiz[28].Text = "Are you easily distracted and/or bored?";
  Quiz[29].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[30].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[31].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[32].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[33].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[34].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[35].Text = "Do you prefer to avoid eye-contact?";
  Quiz[36].Text = "Is it easy for you to make friends?";
  Quiz[37].Text = "Don't you usually mind unexpected touch or an unexpected hug?";
  Quiz[38].Text = "Have you felt different from others for most of your life?";
  Quiz[39].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[40].Text = "Do you feel excited in unfamiliar situations?";
  Quiz[41].Text = "Do you prefer to eat different food every day?";
  Quiz[42].Text = "Do you prefer to change cloth every day?";
  Quiz[43].Text = "Do you prefer the company of those that are the same age as yourself?";
  Quiz[44].Text = "Are you good at social chitchat?";
  Quiz[45].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[46].Text = "Do you prefer to use others' help or expertise instead of doing things on your own?";
  Quiz[47].Text = "Do you find it easier to communicate in real life than online?";
  Quiz[48].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[49].Text = "Are you good at teamwork?";
  Quiz[50].Text = "Do you prefer animals to people?";
  Quiz[51].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[52].Text = "Do you feel uncomfortable with strangers?";
  Quiz[53].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[54].Text = "Are you usually aware of/interested in what is currently in vogue?";
  Quiz[55].Text = "Do you enjoy when people drop by to visit you univited?";
  Quiz[56].Text = "Are you energised by being in the company of others?";
  Quiz[57].Text = "Are your views typical of your peer group?";
  Quiz[58].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[59].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[60].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[61].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[62].Text = "Before doing something or going somewhere, do you need to visualize the place you're going to or rehearse possible scenarios in your mind so as to prepare yourself?";
  Quiz[63].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[64].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[65].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[66].Text = "Do you have certain routines which you need to follow?";
  Quiz[67].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[68].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[69].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[70].Text = "Do you drop things when your attention is on other things?";
  Quiz[71].Text = "Have you been accused of staring?";
  Quiz[72].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[73].Text = "Are you easily distracted?";
  Quiz[74].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[75].Text = "Do you have unusual eating and/or sleeping patterns?";
  Quiz[76].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[77].Text = "Are you prone to getting depressions?";
  Quiz[78].Text = "Do you love to collect things?";
  Quiz[79].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[80].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[81].Text = "Do you have an unusual sensitivity to pain?";
  Quiz[82].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[83].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[84].Text = "Do you stutter when stressed?";
  Quiz[85].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[86].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[87].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[88].Text = "Does it come more natural to you to think in words than in pictures?";
  Quiz[89].Text = "Do you eat almost anything?";
  Quiz[90].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[91].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[92].Text = "Do you like to relax and do absolutely nothing while pondering on things of interest?";
  Quiz[93].Text = "Do you enjoy digging?";
  Quiz[94].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[95].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[96].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[97].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[98].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[99].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[100].Text = "Do you tap your fingers or fiddle with something (e.g. when bored, restless or concentrating)?";
  Quiz[101].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[102].Text = "Do you grind teeth?";
  Quiz[103].Text = "Do you talk to yourself?";
  Quiz[104].Text = "Do you make unusual facial expressions?";
  Quiz[105].Text = "Do you repeatedly blink or have twitches in eyes or face?";
  Quiz[106].Text = "Do you roll your eyes involuntary?";
  Quiz[107].Text = "Do you bite yourself (e.g. when frustrated or upset)?";
  Quiz[108].Text = "Do you clench your fists when angry?";
  Quiz[109].Text = "Do you flap your hands (e.g. when excited or upset)?";
  Quiz[110].Text = "Do people understand you?";
  Quiz[111].Text = "Are you good at interpreting facial expressions?";
  Quiz[112].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[113].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[114].Text = "Can you easily remember verbal instructions?";
  Quiz[115].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[116].Text = "Is your sense of humor fairly conventional?";
  Quiz[117].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[118].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[119].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[120].Text = "Do you tend to talk either too softly or too loundly?";
  Quiz[121].Text = "Do you intuitively sense boundraries and personal space of others?";
  Quiz[122].Text = "Are you sometimes afraid in safe situations?";
  Quiz[123].Text = "Do you find it easy to do more than one thing at the time?";
  Quiz[124].Text = "Do you find it easy to 'read between the lines' in a conversation?";
  Quiz[125].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[126].Text = "Do you have an odd posture or gait?";
  Quiz[127].Text = "Do you find it easy to describe & summarize for example events, conversations or something you've read?";
  Quiz[128].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[129].Text = "Do you easily accept criticism, correction, and direction?";
  Quiz[130].Text = "Do you have a good sense of what time it is?";
  Quiz[131].Text = "Do you find it easy estimate the age of people?";
  Quiz[132].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[133].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[134].Text = "Do you easily recognize faces?";
  Quiz[135].Text = "Do you have difficulties with pronunciation?";
  Quiz[136].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[137].Text = "Do you flip letters when you write?";
  Quiz[138].Text = "Are you always aware of other things going on around you even when reading or otherwise occupied?";
  Quiz[139].Text = "Do you find it natural to wave when you meet people?";
  Quiz[140].Text = "Do you instinctively point to things of interest?";
  Quiz[141].Text = "Do you instinctively cross your arms when you are in a closed state of mind?";
  Quiz[142].Text = "Do you interpret a pat on somebody's head as patronizing?";
  Quiz[143].Text = "Do you often don't know where to put your arms?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[1].Text = "Har du ett bra sinne för hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[2].Text = "Har du lätt för att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[3].Text = "Är det sällan du ramlar, snubblar eller springer in i saker?";
  Quiz[4].Text = "Har du lätt för att bedöma avstånd, höjd, djup eller fart?";
  Quiz[5].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[6].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
  Quiz[7].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[8].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[9].Text = "Har du extra känslig hörsel?";
  Quiz[10].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[11].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[12].Text = "Är du känslig för väderomslag?";
  Quiz[13].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[14].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
  Quiz[15].Text = "Är du känslig för torr luft?";
  Quiz[16].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[17].Text = "Brukade dina lekar mer bestå i sociala lekar med andra barn än att t ex sortera, bygga, undersöka eller ta isär saker?";
  Quiz[18].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[19].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[20].Text = "Ser du mönster i saker hela tiden?";
  Quiz[21].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[22].Text = "Är du mentalt hyperaktiv?";
  Quiz[23].Text = "Brukar du lösa problem på okonventionella sätt?";
  Quiz[24].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[25].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[26].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[27].Text = "Tycker du att det ofta finns skäl att ifrågasätta auktoriteter?";
  Quiz[28].Text = "Blir du lätt distraherad och/eller uttråkad?";
  Quiz[29].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[30].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[31].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[32].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[33].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[34].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[35].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[36].Text = "Har du lätt för att få vänner?";
  Quiz[37].Text = "Har du oftast inget emot oväntad beröring eller en oväntad kram?";
  Quiz[38].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[39].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[40].Text = "Blir du upprymd av okända situationer?";
  Quiz[41].Text = "Föredrar du att äta olika maträtter varje dag?";
  Quiz[42].Text = "Föredrar du att byta kläder varje dag?";
  Quiz[43].Text = "Föredrar du att umgås med jämnåriga?";
  Quiz[44].Text = "Är du bra på kallprat?";
  Quiz[45].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[46].Text = "Föredrar du att använda andras hjälp och expertis istället för att göra saker på egen hand?";
  Quiz[47].Text = "Tycker du att det är lättare att kommunicera i verkliga livet än via dator?";
  Quiz[48].Text = "Trivs du i romantiska situationer?";
  Quiz[49].Text = "Är du bra på att arbeta i grupp?";
  Quiz[50].Text = "Umgås du hellre med djur än med människor?";
  Quiz[51].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[52].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[53].Text = "Föredrar du att bara umgås med folk du känner väl, på tu man hand eller i en mindre grupp?";
  Quiz[54].Text = "Är du ofta medveten om/intresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[55].Text = "Gillar du när folk kommer på besök oanmälda?";
  Quiz[56].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[57].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[58].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[59].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[60].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[61].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[62].Text = "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?";
  Quiz[63].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[64].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[65].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[66].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[67].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[68].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[69].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet?";
  Quiz[70].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[71].Text = "Har du blivit anklagad för att stirra?";
  Quiz[72].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[73].Text = "Blir du lätt distraherad?";
  Quiz[74].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[75].Text = "Har du ovanliga ät- och/eller sovvanor?";
  Quiz[76].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[77].Text = "Brukar du få depressioner?";
  Quiz[78].Text = "Gillar du att samla?";
  Quiz[79].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[80].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[81].Text = "Har du ovanlig känslighet för smärta? ";
  Quiz[82].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[83].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[84].Text = "Stammar du när du blir stressad?";
  Quiz[85].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[86].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[87].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[88].Text = "Är det mer naturligt för dig att tänka i ord än i bilder?";
  Quiz[89].Text = "Äter du nästan allt?";
  Quiz[90].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
  Quiz[91].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[92].Text = "Brukar du gilla att bara slappa och göra ingenting medan du tänker på intressanta saker?";
  Quiz[93].Text = "Gillar du att gräva?";
  Quiz[94].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[95].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[96].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[97].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[98].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[99].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[100].Text = "Brukar du trumma med fingrarna eller fingra på något (t ex när du är uttråkad, rastlös eller koncenterar dig)?";
  Quiz[101].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[102].Text = "Brukar du gnissla tänder?";
  Quiz[103].Text = "Brukar du prata med dig själv?";
  Quiz[104].Text = "Har du ovanliga ansiktsuttryck?";
  Quiz[105].Text = "Brukar du ha upprepade blinkningar eller ryckningar i ögon eller ansikte?";
  Quiz[106].Text = "Rullar du med ögonen ofrivilligt?";
  Quiz[107].Text = "Brukar du bita dig själv? (t ex när du är upprörd)?";
  Quiz[108].Text = "Knyter du nävarna när du är arg?";
  Quiz[109].Text = "Brukar du vifta med händerna (t ex när du är upprymd eller upprörd)?";
  Quiz[110].Text = "Förstår sig folk på dig?";
  Quiz[111].Text = "Är du bra på att tolka ansiktsuttryck?";
  Quiz[112].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[113].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[114].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[115].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[116].Text = "Är ditt sinne för humor ganska konventionellt?";
  Quiz[117].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[118].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[119].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[120].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[121].Text = "Känner du intuitivt av andras gränser och privata sfär?";
  Quiz[122].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[123].Text = "Tycker du det är lätt att göra mer än en sak i taget?";
  Quiz[124].Text = "Tycker du det är lätt att 'läsa mellan raderna' i en konversation?";
  Quiz[125].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[126].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[127].Text = "Har du lätt för att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[128].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[129].Text = "Har du lätt för att acceptera kritik, korrektion och direktiv?";
  Quiz[130].Text = "Har du ett bra sinne för hur mycket klockan är?";
  Quiz[131].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[132].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[133].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[134].Text = "Har du lätt för att känna igen ansikten?";
  Quiz[135].Text = "Har du svårigheter med uttal?";
  Quiz[136].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[137].Text = "Brukar du kasta om bokstäver när du skriver?";
  Quiz[138].Text = "Är du alltid medveten om det som försigår runt omkring dig även om du läser eller sysslar med något annat?";
  Quiz[139].Text = "Är det naturligt för dig att vinka när du möter folk?";
  Quiz[140].Text = "Pekar du insktinktivt på saker du finner intressanta?";
  Quiz[141].Text = "Korsar du instinktivt dina armar när du är reserverad?";
  Quiz[142].Text = "Uppfattar du en klapp på huvudet som nedlåtande?";
  Quiz[143].Text = "Vet du ofta inte var du ska göra av dina armar?";
#endif

}

/*##########################################################################
#
#   Name       : TQuizR5::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::InitReferers()
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

/*##################  TQuizR5::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::LoadReferers()
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
#   Name       : TQuizR5::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::LoadPopulations()
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
			DxArr[POP_TYPE_AUTISM] = DX_STATE_YES;

		if (Row.Autism == 1)
			DxArr[POP_TYPE_AUTISM] = DX_STATE_SELF;

		if (Row.Autism == 0)
			DxArr[POP_TYPE_AUTISM] = DX_STATE_NO;

		if (Row.Aspie == 2)
			DxArr[POP_TYPE_AS] = DX_STATE_YES;

		if (Row.Aspie == 1)
			DxArr[POP_TYPE_AS] = DX_STATE_SELF;

		if (Row.Aspie == 0)
			DxArr[POP_TYPE_AS] = DX_STATE_NO;

		if (Row.ADHD == 2)
			DxArr[POP_TYPE_ADD] = DX_STATE_YES;

		if (Row.ADHD == 1)
			DxArr[POP_TYPE_ADD] = DX_STATE_SELF;

		if (Row.ADHD == 0)
			DxArr[POP_TYPE_ADD] = DX_STATE_NO;

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
#   Name       : TQuizR5::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::SetupControlGroups()
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
#   Name       : TQuizR5::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4)
{
    DefineCross(QuizR4, 0, 111);
    DefineGlobalId( 1, 689);
    DefineGlobalId( 2, 690);
    DefineGlobalId( 3, 691);
    DefineGlobalId( 4, 692);
    DefineCross(QuizR4, 5, 134);
    DefineCross(Quiz9, 6, 19);
    DefineCross(QuizR4, 7, 52);
    DefineCross(QuizR4, 8, 46);
    DefineCross(QuizR4, 9, 40);
    DefineCross(QuizR4, 10, 45);
    DefineCross(QuizR4, 11, 141);
    DefineCross(QuizR4, 12, 59);
    DefineCross(QuizR2, 13, 18);
    DefineCross(QuizR2, 14, 17);
    DefineCross(QuizR4, 15, 143);
    DefineCross(QuizR4, 16, 81);
    DefineGlobalId( 17, 693);
    DefineCross(Quiz9, 18, 126);
    DefineCross(QuizR4, 19, 82);
    DefineGlobalId( 20, 694);
    DefineCross(QuizR4, 21, 101);
    DefineCross(QuizR4, 22, 108);
    DefineCross(QuizR4, 23, 103);
    DefineCross(QuizR4, 24, 104);
    DefineCross(QuizR4, 25, 102);
    DefineCross(QuizR4, 26, 98);
    DefineCross(QuizII, 27, 91);
    DefineCross(QuizR2, 28, 38);
    DefineCross(QuizR3, 29, 165);
    DefineCross(Quiz8, 30, 41);
    DefineCross(QuizR4, 31, 5);
    DefineCross(QuizIII, 32, 44);
    DefineCross(QuizR4, 33, 24);
    DefineCross(QuizR4, 34, 13);
    DefineCross(QuizR4, 35, 36);
    DefineGlobalId( 36, 695);
    DefineGlobalId( 37, 696);
    DefineCross(QuizR4, 38, 0);
    DefineCross(Quiz9, 39, 62);
    DefineGlobalId( 40, 697);
    DefineGlobalId( 41, 698);
    DefineGlobalId( 42, 699);
    DefineGlobalId( 43, 700);
    DefineGlobalId( 44, 701);
    DefineCross(QuizR4, 45, 120);
    DefineGlobalId( 46, 702);
    DefineGlobalId( 47, 703);
    DefineCross(Quiz9, 48, 49);
    DefineCross(QuizR4, 49, 19);
    DefineCross(Quiz8, 50, 57);
    DefineCross(QuizR4, 51, 91);
    DefineCross(Quiz9, 52, 71);
    DefineCross(QuizR4, 53, 10);
    DefineGlobalId( 54, 704);
    DefineGlobalId( 55, 705);
    DefineCross(Quiz9, 56, 66);
    DefineCross(QuizR2, 57, 64);
    DefineCross(QuizNd, 58, 122);
    DefineCross(QuizR4, 59, 80);
    DefineCross(QuizR4, 60, 117);
    DefineGlobalId( 61, 706);
    DefineCross(QuizR2, 62, 48);
    DefineCross(QuizR4, 63, 84);
    DefineCross(QuizR4, 64, 92);
    DefineCross(QuizR4, 65, 95);
    DefineCross(QuizR4, 66, 89);
    DefineCross(QuizR4, 67, 34);
    DefineCross(QuizR4, 68, 7);
    DefineCross(QuizR4, 69, 116);
    DefineCross(QuizR2, 70, 141);
    DefineCross(QuizR4, 71, 37);
    DefineCross(QuizR4, 72, 109);
    DefineCross(QuizR4, 73, 126);
    DefineGlobalId( 74, 707);
    DefineGlobalId( 75, 708);
    DefineCross(QuizR2, 76, 110);
    DefineCross(QuizR3, 77, 179);
    DefineCross(QuizR4, 78, 88);
    DefineCross(QuizR4, 79, 25);
    DefineCross(QuizR4, 80, 130);
    DefineCross(QuizR2, 81, 14);
    DefineCross(QuizR2, 82, 15);
    DefineCross(QuizR2, 83, 113);
    DefineCross(QuizR4, 84, 139);
    DefineCross(QuizR4, 85, 31);
    DefineCross(Quiz9, 86, 133);
    DefineCross(QuizR4, 87, 97);
    DefineGlobalId( 88, 709);
    DefineGlobalId( 89, 710);
    DefineCross(Quiz9, 90, 132);
    DefineCross(QuizR4, 91, 119);
    DefineCross(QuizR4, 92, 151);
    DefineCross(QuizR4, 93, 147);
    DefineCross(QuizR4, 94, 61);
    DefineCross(QuizR4, 95, 62);
    DefineCross(QuizR4, 96, 71);
    DefineCross(QuizR4, 97, 72);
    DefineCross(QuizR4, 98, 77);
    DefineCross(QuizR4, 99, 69);
    DefineCross(QuizR4, 100, 60);
    DefineCross(QuizR4, 101, 67);
    DefineCross(QuizR3, 102, 80);
    DefineCross(QuizR4, 103, 64);
    DefineGlobalId( 104, 711);
    DefineCross(QuizR4, 105, 79);
    DefineCross(Quiz7, 106, 108);
    DefineCross(QuizR4, 107, 74);
    DefineCross(QuizR1, 108, 125);
    DefineCross(QuizR4, 109, 73);
    DefineGlobalId( 110, 712);
    DefineGlobalId( 111, 713);
    DefineCross(QuizR4, 112, 23);
    DefineCross(QuizR4, 113, 9);
    DefineGlobalId( 114, 714);
    DefineCross(QuizR4, 115, 83);
    DefineGlobalId( 116, 715);
    DefineCross(QuizR2, 117, 91);
    DefineCross(QuizR2, 118, 92);
    DefineCross(QuizR1, 119, 20);
    DefineCross(QuizR4, 120, 22);
    DefineGlobalId( 121, 716);
    DefineGlobalId( 122, 717);
    DefineGlobalId( 123, 718);
    DefineGlobalId( 124, 719);
    DefineCross(QuizR4, 125, 6);
    DefineCross(QuizR2, 126, 98);
    DefineGlobalId( 127, 720);
    DefineCross(QuizR4, 128, 43);
    DefineGlobalId( 129, 721);
    DefineGlobalId( 130, 722);
    DefineGlobalId( 131, 723);
    DefineCross(QuizR4, 132, 14);
    DefineCross(QuizR4, 133, 90);
    DefineGlobalId( 134, 724);
    DefineCross(QuizR4, 135, 138);
    DefineGlobalId( 136, 725);
    DefineCross(QuizR3, 137, 164);
    DefineCross(QuizNd, 138, 133);
    DefineGlobalId( 139, 726);
    DefineGlobalId( 140, 727);
    DefineGlobalId( 141, 728);
    DefineGlobalId( 142, 729);
    DefineGlobalId( 143, 730);
}

/*##########################################################################
#
#   Name       : TQuizR5::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizR5::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::ExportExcelCase(const char *filename, int PcaType)
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
                    
					sprintf(str, "%d", ival);
					file.Write(str);
					if (i != N - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizR5::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::ExportExcelAspie(const char *filename)
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

			sprintf(str, "%d", ival);
			file.Write(str);
			if (i != N - 1)
				file.Write(", ");
		}
		file.Write("\n");
	}
}

/*##################  TQuizR5::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::ExportExcelGroups(const char *filename)
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

/*##################  TQuizR5::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_FEMALE)
						d2 = -d2;

//					if (PcaType == PCA_TYPE_ALL)
//						d3 = -d3;

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
