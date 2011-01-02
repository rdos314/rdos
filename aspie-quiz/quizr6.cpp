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
# quizr6.cpp
# Quiz R6 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr6.h"
#include "file.h"
#include "quizdbr6.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizR6::TQuizR6
#
#   Purpose....: Constructor for TQuizR6
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR6::TQuizR6(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5)
  : TQuiz(147),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR6::~TQuizR6
#
#   Purpose....: Destructor for TQuizR6
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR6::~TQuizR6()
{
}

/*##################  TQuizR6::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR6::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR6::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::WriteName(TFile &File)
{
	 File.Write("R6");
}

/*##########################################################################
#
#   Name       : TQuizR6::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::WriteLongName(TFile &File)
{
	 File.Write("experimental version 6");
}

/*##################  TQuizR6::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR6::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR6::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::SetupTexts()
{
  Quiz[41].Reverse = TRUE;
  Quiz[42].Reverse = TRUE;
  Quiz[44].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[50].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[59].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[62].Reverse = TRUE;
  Quiz[77].Reverse = TRUE;
  Quiz[120].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[125].Reverse = TRUE;
  Quiz[126].Reverse = TRUE;
  Quiz[127].Reverse = TRUE;
  Quiz[131].Reverse = TRUE;
  Quiz[132].Reverse = TRUE;
  Quiz[135].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;
  Quiz[140].Reverse = TRUE;
  Quiz[141].Reverse = TRUE;
  Quiz[144].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_MIXED;
  Quiz[1].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[2].MyGroup = GROUP_NT_SENSORY;
  Quiz[3].MyGroup = GROUP_NT_SENSORY;
  Quiz[4].MyGroup = GROUP_NT_SENSORY;
  Quiz[5].MyGroup = GROUP_NT_SENSORY;
  Quiz[6].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[7].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[8].MyGroup = GROUP_ASPIE_NVC;
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
  Quiz[19].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[20].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[21].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[24].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[25].MyGroup = GROUP_NT_TALENT;
  Quiz[26].MyGroup = GROUP_NT_TALENT;
  Quiz[27].MyGroup = GROUP_NT_HUNTING;
  Quiz[28].MyGroup = GROUP_NT_NVC;
  Quiz[29].MyGroup = GROUP_NT_OBSESSION;
  Quiz[30].MyGroup = GROUP_NT_SOCIAL;
  Quiz[31].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_ASPIE_NVC;
  Quiz[34].MyGroup = GROUP_NT_NVC;
  Quiz[35].MyGroup = GROUP_ENVIRONMENT;
  Quiz[36].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[37].MyGroup = GROUP_MIXED;
  Quiz[38].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[39].MyGroup = GROUP_NT_SOCIAL;
  Quiz[40].MyGroup = GROUP_NT_SOCIAL;
  Quiz[41].MyGroup = GROUP_NT_SOCIAL;
  Quiz[42].MyGroup = GROUP_NT_SOCIAL;
  Quiz[43].MyGroup = GROUP_ENVIRONMENT;
  Quiz[44].MyGroup = GROUP_NT_SOCIAL;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_NT_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_SOCIAL;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_OBSESSION;
  Quiz[52].MyGroup = GROUP_NT_OBSESSION;
  Quiz[53].MyGroup = GROUP_NT_NVC;
  Quiz[54].MyGroup = GROUP_NT_NVC;
  Quiz[55].MyGroup = GROUP_NT_OBSESSION;
  Quiz[56].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_NT_OBSESSION;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
  Quiz[62].MyGroup = GROUP_NT_SOCIAL;
  Quiz[63].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[64].MyGroup = GROUP_ENVIRONMENT;
  Quiz[65].MyGroup = GROUP_NT_TALENT;
  Quiz[66].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[67].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[68].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[69].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[70].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[71].MyGroup = GROUP_NT_NVC;
  Quiz[72].MyGroup = GROUP_MIXED;
  Quiz[73].MyGroup = GROUP_NT_HUNTING;
  Quiz[74].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[77].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_NT_TALENT;
  Quiz[80].MyGroup = GROUP_ENVIRONMENT;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
  Quiz[82].MyGroup = GROUP_ENVIRONMENT;
  Quiz[83].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[84].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[85].MyGroup = GROUP_ENVIRONMENT;
  Quiz[86].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[87].MyGroup = GROUP_ASPIE_NVC;
  Quiz[88].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[89].MyGroup = GROUP_ASPIE_NVC;
  Quiz[90].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[91].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[92].MyGroup = GROUP_NT_NVC;
  Quiz[93].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[96].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_NVC;
  Quiz[100].MyGroup = GROUP_ASPIE_NVC;
  Quiz[101].MyGroup = GROUP_ASPIE_NVC;
  Quiz[102].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_ASPIE_NVC;
  Quiz[107].MyGroup = GROUP_ASPIE_NVC;
  Quiz[108].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[109].MyGroup = GROUP_ASPIE_NVC;
  Quiz[110].MyGroup = GROUP_ASPIE_NVC;
  Quiz[111].MyGroup = GROUP_ASPIE_NVC;
  Quiz[112].MyGroup = GROUP_ASPIE_NVC;
  Quiz[113].MyGroup = GROUP_NT_NVC;
  Quiz[114].MyGroup = GROUP_NT_NVC;
  Quiz[115].MyGroup = GROUP_NT_NVC;
  Quiz[116].MyGroup = GROUP_NT_TALENT;
  Quiz[117].MyGroup = GROUP_NT_NVC;
  Quiz[118].MyGroup = GROUP_NT_NVC;
  Quiz[119].MyGroup = GROUP_NT_NVC;
  Quiz[120].MyGroup = GROUP_NT_NVC;
  Quiz[121].MyGroup = GROUP_NT_NVC;
  Quiz[122].MyGroup = GROUP_NT_NVC;
  Quiz[123].MyGroup = GROUP_ASPIE_NVC;
  Quiz[124].MyGroup = GROUP_NT_TALENT;
  Quiz[125].MyGroup = GROUP_NT_NVC;
  Quiz[126].MyGroup = GROUP_NT_NVC;
  Quiz[127].MyGroup = GROUP_NT_NVC;
  Quiz[128].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[129].MyGroup = GROUP_ASPIE_NVC;
  Quiz[130].MyGroup = GROUP_NT_NVC;
  Quiz[131].MyGroup = GROUP_NT_TALENT;
  Quiz[132].MyGroup = GROUP_NT_NVC;
  Quiz[133].MyGroup = GROUP_NT_SENSORY;
  Quiz[134].MyGroup = GROUP_ENVIRONMENT;
  Quiz[135].MyGroup = GROUP_NT_SENSORY;
  Quiz[136].MyGroup = GROUP_NT_SENSORY;
  Quiz[137].MyGroup = GROUP_ENVIRONMENT;
  Quiz[138].MyGroup = GROUP_NT_NVC;
  Quiz[139].MyGroup = GROUP_NT_SENSORY;
  Quiz[140].MyGroup = GROUP_NT_NVC;
  Quiz[141].MyGroup = GROUP_NT_OBSESSION;
  Quiz[142].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[143].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[144].MyGroup = GROUP_NT_SENSORY;
  Quiz[145].MyGroup = GROUP_ASPIE_NVC;
  Quiz[146].MyGroup = GROUP_NT_SOCIAL;

#ifdef ENGLISH
  Quiz[0].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[1].Text = "Do you have odd teeth; e.g. that are crooked, bigger than usual; that have gaps, overlaps, underbite or that show extra much gum?";
  Quiz[2].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands?";
  Quiz[3].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[4].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[5].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[6].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
  Quiz[7].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[8].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[9].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[10].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[11].Text = "Do you have a very acute sense of smell and/or taste?";
  Quiz[12].Text = "Are you sensitive to electromagnetic fields?";
  Quiz[13].Text = "Do you squint now or have done in the past?";
  Quiz[14].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[15].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[16].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[17].Text = "Do you have a hyperactive mind?";
  Quiz[18].Text = "Do you have unconventional ways of solving problems?";
  Quiz[19].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[20].Text = "Do you notice patterns in things all the time?";
  Quiz[21].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[22].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[23].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[24].Text = "Do you often find reasons to question authorities?";
  Quiz[25].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[26].Text = "Are you easily distracted and/or bored?";
  Quiz[27].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[28].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[29].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[30].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[31].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[32].Text = "Have you felt different from others for most of your life?";
  Quiz[33].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[34].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[35].Text = "Do you feel stressed in unfamiliar situations?";
  Quiz[36].Text = "Do you prefer to eat the same food every day for long periods at a time?";
  Quiz[37].Text = "Have you had a tendency to prefer the company of those who are older or younger than yourself?";
  Quiz[38].Text = "Do you prefer to wear the same clothes every day for many days in a row?";
  Quiz[39].Text = "Do you prefer to avoid eye-contact?";
  Quiz[40].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[41].Text = "Are you good at teamwork?";
  Quiz[42].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[43].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[44].Text = "Are you good at social chitchat?";
  Quiz[45].Text = "Are your dreams and fantasies much like those of others?";
  Quiz[46].Text = "Do you feel uncomfortable with strangers?";
  Quiz[47].Text = "Do you prefer animals to people?";
  Quiz[48].Text = "Do you find it easy to maintain your social network?";
  Quiz[49].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[50].Text = "Are you comfortable in most social situations and with new people?";
  Quiz[51].Text = "Are you energised by being in the company of others?";
  Quiz[52].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[53].Text = "Do you find it easy to describe your feelings?";
  Quiz[54].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[55].Text = "Are your views typical of your peer group?";
  Quiz[56].Text = "Do you enjoy having a variety of choices to make each day?";
  Quiz[57].Text = "Do you find it easier to communicate in real life than online?";
  Quiz[58].Text = "Do you enjoy when people drop by to visit you uninvited?";
  Quiz[59].Text = "Do you prefer the company of those that are the same age as yourself?";
  Quiz[60].Text = "Do you dislike unexpected touch or hugs from strangers?";
  Quiz[61].Text = "Do you enjoy unexpected touch or hugs from friends?";
  Quiz[62].Text = "Do you enjoy when unexpected things happen in nature?";
  Quiz[63].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[64].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[65].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[66].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[67].Text = "Before doing something or going somewhere, do you need to visualize the place you're going to or rehearse possible scenarios in your mind so as to prepare yourself?";
  Quiz[68].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[69].Text = "Do you have certain routines which you need to follow?";
  Quiz[70].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[71].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[72].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[73].Text = "Do you drop things when your attention is on other things?";
  Quiz[74].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[75].Text = "Have you been accused of staring?";
  Quiz[76].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[77].Text = "Is your sense of humor fairly conventional?";
  Quiz[78].Text = "Do you often don't know where to put your arms?";
  Quiz[79].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[80].Text = "Are you sometimes afraid in safe situations?";
  Quiz[81].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[82].Text = "Are you prone to getting depressions?";
  Quiz[83].Text = "Do you love to collect things?";
  Quiz[84].Text = "Do you have unusual eating and/or sleeping patterns?";
  Quiz[85].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[86].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[87].Text = "Do you stutter when stressed?";
  Quiz[88].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[89].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[90].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[91].Text = "Do you have an unusual sensitivity to pain?";
  Quiz[92].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[93].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[94].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[95].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[96].Text = "Do you enjoy digging?";
  Quiz[97].Text = "Do you like to relax and do absolutely nothing while pondering on things of interest?";
  Quiz[98].Text = "Do you make unusual facial expressions?";
  Quiz[99].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[100].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[101].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[102].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[103].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[104].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[105].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[106].Text = "Do you tap your fingers or fiddle with something (e.g. when bored, restless or concentrating)?";
  Quiz[107].Text = "Do you talk to yourself?";
  Quiz[108].Text = "Do you grind teeth?";
  Quiz[109].Text = "Do you bite yourself (e.g. when frustrated or upset)?";
  Quiz[110].Text = "Do you flap your hands (e.g. when excited or upset)?";
  Quiz[111].Text = "Do you clench your fists when angry?";
  Quiz[112].Text = "Do you roll your eyes as part of your communication?";
  Quiz[113].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[114].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[115].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[116].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[117].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[118].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[119].Text = "Are you often surprised what people's motives are ?";
  Quiz[120].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[121].Text = "Do people understand you?";
  Quiz[122].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[123].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[124].Text = "Do you have difficulty describing & summarising for example events, conversations or something you've read?";
  Quiz[125].Text = "Is it easy for you to interpret body language?";
  Quiz[126].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[127].Text = "Do you know when you are expected to offer an apology?";
  Quiz[128].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[129].Text = "Do you have an odd posture or gait?";
  Quiz[130].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[131].Text = "Can you easily remember verbal instructions?";
  Quiz[132].Text = "Are you good at interpreting facial expressions?";
  Quiz[133].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[134].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[135].Text = "Do you have a good concept of time?";
  Quiz[136].Text = "Do you find it hard to tell the age of people?";
  Quiz[137].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[138].Text = "Do you miss dishonesty and hidden agendas?";
  Quiz[139].Text = "Do you usually recognize faces?";
  Quiz[140].Text = "Is your sense of humor fairly conventional?";
  Quiz[141].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[142].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[143].Text = "Do you find the norms of hygiene too strict?";
  Quiz[144].Text = "Do you find it easy to estimate the age of people?";
  Quiz[145].Text = "Do you have difficulties with pronunciation?";
  Quiz[146].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[1].Text = "Har du udda tänder; t ex tänder som sitter snett, klättrar på varandra; är större än vanligt; mellanrum mellan tänderna; underbett, som visar extra mycket tandkött?";
  Quiz[2].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[3].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[4].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[5].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[6].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
  Quiz[7].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[8].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[9].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[10].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[11].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
  Quiz[12].Text = "Är du känslig för elektromagnetiska fält?";
  Quiz[13].Text = "Skelar du eller har gjort det?";
  Quiz[14].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[15].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[16].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[17].Text = "Är du mentalt hyperaktiv?";
  Quiz[18].Text = "Brukar du lösa problem på okonventionella sätt?";
  Quiz[19].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[20].Text = "Ser du mönster i saker hela tiden?";
  Quiz[21].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[22].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[23].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[24].Text = "Tycker du att det ofta finns skäl att ifrågasätta auktoriteter?";
  Quiz[25].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[26].Text = "Blir du lätt distraherad och/eller uttråkad?";
  Quiz[27].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[28].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[29].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[30].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[31].Text = "Brukade dina lekar mer bestå i att t ex sortera, bygga, undersöka eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[32].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[33].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[34].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[35].Text = "Känner du dig stressad i nya okända situationer?";
  Quiz[36].Text = "Föredrar du att äta samma mat varje dag, långa perioder i taget?";
  Quiz[37].Text = "Har du haft en tendens att helst umgås med människor som är antingen äldre eller yngre än du själv?";
  Quiz[38].Text = "Föredrar du att ha samma kläder varje dag, många dar i rad?";
  Quiz[39].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[40].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[41].Text = "Är du bra på att arbeta i grupp?";
  Quiz[42].Text = "Trivs du i romantiska situationer?";
  Quiz[43].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[44].Text = "Är du bra på kallprat?";
  Quiz[45].Text = "Är dina drömmar och fantasier likadana som andras?";
  Quiz[46].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[47].Text = "Umgås du hellre med djur än med människor?";
  Quiz[48].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
  Quiz[49].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[50].Text = "Känner du dig hemma i de flesta sociala situationer och med nya människor?";
  Quiz[51].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[52].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[53].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[54].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[55].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[56].Text = "Gillar du att ha många olika saker du kan göra varje dag?";
  Quiz[57].Text = "Tycker du att det är lättare att kommunicera i verkliga livet än via dator?";
  Quiz[58].Text = "Gillar du när folk kommer på besök oanmälda?";
  Quiz[59].Text = "Föredrar du att umgås med jämnåriga?";
  Quiz[60].Text = "Ogillar du oväntad beröring eller kramar från främlingar?";
  Quiz[61].Text = "Gillar du oväntad beröring eller kramar fr†n vänner?";
  Quiz[62].Text = "Gillar du när oväntade saker händer i naturen?";
  Quiz[63].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[64].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[65].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[66].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[67].Text = "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?";
  Quiz[68].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[69].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[70].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet?";
  Quiz[71].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[72].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[73].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[74].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[75].Text = "Har du blivit anklagad för att stirra?";
  Quiz[76].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[77].Text = "Är ditt sinne för humor ganska konventionellt?";
  Quiz[78].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[79].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[80].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[81].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[82].Text = "Brukar du få depressioner?";
  Quiz[83].Text = "Gillar du att samla?";
  Quiz[84].Text = "Har du ovanliga ät- och/eller sovvanor?";
  Quiz[85].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[86].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[87].Text = "Stammar du när du blir stressad?";
  Quiz[88].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[89].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[90].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[91].Text = "Har du ovanlig känslighet för smärta? ";
  Quiz[92].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[93].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[94].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
  Quiz[95].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[96].Text = "Gillar du att gräva?";
  Quiz[97].Text = "Brukar du gilla att bara slappa och göra ingenting medan du tänker på intressanta saker?";
  Quiz[98].Text = "Har du ovanliga ansiktsuttryck?";
  Quiz[99].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[100].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[101].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[102].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[103].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[104].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[105].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[106].Text = "Brukar du trumma med fingrarna eller fingra på något (t ex när du är uttråkad, rastlös eller koncenterar dig)?";
  Quiz[107].Text = "Brukar du prata med dig själv?";
  Quiz[108].Text = "Brukar du gnissla tänder?";
  Quiz[109].Text = "Brukar du bita dig själv? (t ex när du är upprörd)?";
  Quiz[110].Text = "Brukar du vifta med händerna (t ex när du är upprymd eller upprörd)?";
  Quiz[111].Text = "Knyter du nävarna när du är arg?";
  Quiz[112].Text = "Rullar du med ögonen som en del av din kommunikation?";
  Quiz[113].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[114].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[115].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[116].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[117].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[118].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[119].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[120].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[121].Text = "Förstår sig folk på dig?";
  Quiz[122].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[123].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[124].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[125].Text = "Har du lätt för att tolka kroppsspråk?";
  Quiz[126].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[127].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[128].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[129].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[130].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[131].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[132].Text = "Är du bra på att tolka ansiktsuttryck?";
  Quiz[133].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[134].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[135].Text = "Har du en bra tidsuppfattning?";
  Quiz[136].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[137].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[138].Text = "Missar du oärlighet och dolda motiv?";
  Quiz[139].Text = "Brukar du känna igen ansikten?";
  Quiz[140].Text = "Är ditt sinne för humor ganska konventionellt?";
  Quiz[141].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[142].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[143].Text = "Tycker du att normerna för hygien är för strikta?";
  Quiz[144].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[145].Text = "Har du svårigheter med uttal?";
  Quiz[146].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
#endif

}

/*##########################################################################
#
#   Name       : TQuizR6::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::InitReferers()
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

/*##################  TQuizR6::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR6::LoadReferers()
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
#   Name       : TQuizR6::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::LoadPopulations()
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
#   Name       : TQuizR6::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::SetupControlGroups()
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
#   Name       : TQuizR6::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5)
{
    DefineCross(QuizR5, 0, 0);
    DefineCross(QuizR4, 1, 112);
    DefineCross(QuizR4, 2, 136);
    DefineCross(QuizR2, 3, 6);
    DefineCross(QuizR4, 4, 131);
    DefineCross(QuizR5, 5, 5);
    DefineCross(QuizR5, 6, 6);
    DefineCross(QuizR5, 7, 7);
    DefineCross(QuizR5, 8, 10);
    DefineCross(QuizR5, 9, 8);
    DefineCross(QuizR5, 10, 11);
    DefineCross(QuizR5, 11, 14);
    DefineCross(QuizR2, 12, 20);
    DefineCross(QuizR2, 13, 19);
    DefineCross(QuizR5, 14, 16);
    DefineCross(QuizR5, 15, 18);
    DefineCross(QuizR5, 16, 21);
    DefineCross(QuizR5, 17, 22);
    DefineCross(QuizR5, 18, 23);
    DefineCross(QuizR5, 19, 19);
    DefineCross(QuizR5, 20, 20);
    DefineCross(QuizR5, 21, 25);
    DefineCross(QuizR5, 22, 24);
    DefineCross(QuizR5, 23, 26);
    DefineCross(QuizR5, 24, 27);
    DefineCross(QuizR5, 25, 29);
    DefineCross(QuizR5, 26, 28);
    DefineCross(QuizR5, 27, 30);
    DefineCross(QuizR5, 28, 31);
    DefineCross(QuizR5, 29, 32);
    DefineCross(QuizR5, 30, 34);
    DefineCross(QuizR4, 31, 105);
    DefineCross(QuizR5, 32, 38);
    DefineCross(QuizR5, 33, 33);
    DefineCross(QuizR5, 34, 39);
    DefineCross(QuizR4, 35, 99);
    DefineCross(QuizR4, 36, 94);
    DefineCross(QuizR4, 37, 11);
    DefineCross(QuizR4, 38, 93);
    DefineCross(QuizR5, 39, 35);
    DefineCross(QuizR4, 40, 85);
    DefineCross(QuizR5, 41, 49);
    DefineCross(QuizR5, 42, 48);
    DefineCross(QuizR5, 43, 45);
    DefineCross(QuizR5, 44, 44);
    DefineCross(Quiz9, 45, 72);
    DefineCross(QuizR5, 46, 52);
    DefineCross(QuizR5, 47, 50);
    DefineCross(Quiz9, 48, 68);
    DefineCross(QuizR5, 49, 51);
    DefineCross(QuizR3, 50, 17);
    DefineCross(QuizR5, 51, 56);
    DefineCross(QuizR5, 52, 58);
    DefineCross(QuizR4, 53, 38);
    DefineCross(QuizR2, 54, 68);
    DefineCross(QuizR5, 55, 57);
    DefineCross(Quiz7, 56, 123);
    DefineCross(QuizR5, 57, 47);
    DefineCross(QuizR5, 58, 55);
    DefineCross(QuizR5, 59, 43);
    DefineGlobalId( 60, 731);
    DefineGlobalId( 61, 732);
    DefineGlobalId( 62, 733);
    DefineCross(QuizR5, 63, 59);
    DefineCross(QuizR5, 64, 60);
    DefineCross(QuizR5, 65, 63);
    DefineCross(Quiz9, 66, 111);
    DefineCross(QuizR5, 67, 62);
    DefineCross(QuizR5, 68, 65);
    DefineCross(QuizR5, 69, 66);
    DefineCross(QuizR5, 70, 69);
    DefineCross(QuizR5, 71, 67);
    DefineCross(QuizR5, 72, 68);
    DefineCross(QuizR5, 73, 70);
    DefineCross(QuizR5, 74, 72);
    DefineCross(QuizR5, 75, 71);
    DefineCross(QuizR5, 76, 64);
    DefineCross(QuizR5, 77, 116);
    DefineCross(QuizR5, 78, 143);
    DefineCross(QuizR5, 79, 76);
    DefineCross(QuizR5, 80, 122);
    DefineCross(QuizR5, 81, 79);
    DefineCross(QuizR5, 82, 77);
    DefineCross(QuizR5, 83, 78);
    DefineCross(QuizR5, 84, 75);
    DefineCross(QuizR5, 85, 80);
    DefineCross(QuizR5, 86, 82);
    DefineCross(QuizR5, 87, 84);
    DefineCross(QuizR5, 88, 83);
    DefineCross(QuizR5, 89, 87);
    DefineCross(QuizR5, 90, 13);
    DefineCross(QuizR5, 91, 81);
    DefineCross(QuizR5, 92, 85);
    DefineCross(QuizR5, 93, 86);
    DefineCross(QuizR5, 94, 90);
    DefineCross(QuizR5, 95, 91);
    DefineCross(QuizR5, 96, 93);
    DefineCross(QuizR5, 97, 92);
    DefineCross(QuizR5, 98, 104);
    DefineCross(QuizR5, 99, 94);
    DefineCross(QuizR5, 100, 95);
    DefineCross(QuizR5, 101, 98);
    DefineCross(QuizR5, 102, 99);
    DefineCross(QuizR5, 103, 96);
    DefineCross(QuizR5, 104, 97);
    DefineCross(QuizR5, 105, 101);
    DefineCross(QuizR5, 106, 100);
    DefineCross(QuizR5, 107, 103);
    DefineCross(QuizR5, 108, 102);
    DefineCross(QuizR5, 109, 107);
    DefineCross(QuizR5, 110, 109);
    DefineCross(QuizR5, 111, 108);
    DefineCross(Quiz7, 112, 132);
    DefineCross(QuizR5, 113, 112);
    DefineCross(QuizR5, 114, 113);
    DefineCross(Quiz9, 115, 101);
    DefineCross(QuizR5, 116, 115);
    DefineCross(QuizR5, 117, 117);
    DefineCross(Quiz7, 118, 75);
    DefineCross(QuizR2, 119, 93);
    DefineCross(QuizR5, 120, 119);
    DefineCross(QuizR5, 121, 110);
    DefineCross(QuizR5, 122, 118);
    DefineCross(QuizR5, 123, 120);
    DefineCross(QuizR4, 124, 128);
    DefineCross(Quiz9, 125, 104);
    DefineCross(QuizR5, 126, 61);
    DefineCross(QuizR1, 127, 34);
    DefineCross(QuizR5, 128, 128);
    DefineCross(QuizR5, 129, 126);
    DefineCross(QuizR5, 130, 125);
    DefineCross(QuizR5, 131, 114);
    DefineCross(QuizR5, 132, 111);
    DefineCross(QuizR4, 133, 133);
    DefineCross(QuizR4, 134, 118);
    DefineGlobalId( 135, 734);
    DefineCross(Quiz6, 136, 38);
    DefineCross(QuizR5, 137, 132);
    DefineCross(QuizNd, 138, 43);
    DefineGlobalId( 139, 735);
    DefineCross(QuizR5, 140, 116);
    DefineCross(QuizR5, 141, 74);
    DefineCross(QuizR5, 142, 133);
    DefineCross(QuizR4, 143, 114);
    DefineCross(QuizR5, 144, 131);
    DefineCross(QuizR5, 145, 135);
    DefineGlobalId( 146, 736);
}

/*##########################################################################
#
#   Name       : TQuizR6::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR6::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizR6::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR6::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizR6::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR6::ExportExcelAspie(const char *filename)
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

/*##################  TQuizR6::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR6::ExportExcelGroups(const char *filename)
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

/*##################  TQuizR6::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR6::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_ALL)
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
