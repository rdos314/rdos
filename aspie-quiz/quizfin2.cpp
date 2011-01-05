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
# quizfin2.cpp
# Quiz class for final version 2
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizfin2.h"
#include "quizdbg.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

class TRace
{
public:
	TRace();
	void Add(TQuiz2Row *Row);
	void WriteUsRow(TFile &file, int index, const char *text);
	void WriteAllRow(TFile &file, int index, const char *text);
	void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);

	int UsCount[10];
	int UsAsCount[10];
	int AllCount[10];
	int AllAsCount[10];
};

/*##########################################################################
#
#   Name       : TQuizFinal2::TQuizFinal2
#
#   Purpose....: Constructor for TQuizFinal2
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizFinal2::TQuizFinal2(const char *FileName)
  : TQuiz(150),
	FDataFile(FileName)
{
	SetupTexts();
	SetupCross();

	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizFinal2::~TQuizFinal2
#
#   Purpose....: Destructor for TQuizFinal2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizFinal2::~TQuizFinal2()
{
}

/*##################  TQuizFinal2::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizFinal2::GetPcaCount()
{
	return 4;
}

/*##################  TQuizFinal2::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizFinal2::GetCatCount(int Question)
{
	return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizFinal2::GetQuizN()
{
	return 150;
}

/*##########################################################################
#
#   Name       : TQuizFinal2::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::WriteName(TFile &File)
{
	 File.Write("G");
}

/*##########################################################################
#
#   Name       : TQuizFinal2::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::WriteLongName(TFile &File)
{
	 File.Write("final version 2");
}

/*##########################################################################
#
#   Name       : TQuizFinal2::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::SetupTexts()
{
  Quiz[0].Aspie = TRUE;
  Quiz[1].Aspie = TRUE;
  Quiz[2].Aspie = TRUE;
  Quiz[3].Aspie = TRUE;
  Quiz[4].Aspie = TRUE;
  Quiz[5].Aspie = TRUE;
  Quiz[6].Aspie = TRUE;
  Quiz[7].Aspie = TRUE;
  Quiz[8].Aspie = TRUE;
  Quiz[9].Nt = TRUE;
  Quiz[10].Nt = TRUE;
  Quiz[11].Nt = TRUE;
  Quiz[12].Nt = TRUE;
  Quiz[13].Nt = TRUE;
  Quiz[14].Nt = TRUE;
  Quiz[15].Nt = TRUE;
  Quiz[16].Nt = TRUE;
  Quiz[17].Aspie = TRUE;
  Quiz[18].Aspie = TRUE;
  Quiz[19].Aspie = TRUE;
  Quiz[20].Aspie = TRUE;
  Quiz[21].Aspie = TRUE;
  Quiz[22].Aspie = TRUE;
  Quiz[23].Aspie = TRUE;
  Quiz[24].Aspie = TRUE;
  Quiz[25].Aspie = TRUE;
  Quiz[26].Nt = TRUE;
  Quiz[27].Nt = TRUE;
  Quiz[28].Nt = TRUE;
  Quiz[29].Nt = TRUE;
  Quiz[30].Nt = TRUE;
  Quiz[31].Nt = TRUE;
  Quiz[32].Aspie = TRUE;
  Quiz[33].Aspie = TRUE;
  Quiz[34].Aspie = TRUE;
  Quiz[35].Aspie = TRUE;
  Quiz[36].Aspie = TRUE;
  Quiz[37].Aspie = TRUE;
  Quiz[38].Aspie = TRUE;
  Quiz[39].Aspie = TRUE;
  Quiz[40].Aspie = TRUE;
  Quiz[41].Aspie = TRUE;
  Quiz[42].Aspie = TRUE;
  Quiz[43].Aspie = TRUE;
  Quiz[44].Aspie = TRUE;
  Quiz[45].Aspie = TRUE;
  Quiz[46].Aspie = TRUE;
  Quiz[47].Aspie = TRUE;
  Quiz[48].Nt = TRUE;
  Quiz[49].Nt = TRUE;
  Quiz[50].Nt = TRUE;
  Quiz[51].Nt = TRUE;
  Quiz[52].Nt = TRUE;
  Quiz[53].Nt = TRUE;
  Quiz[54].Nt = TRUE;
  Quiz[55].Nt = TRUE;
  Quiz[56].Nt = TRUE;
  Quiz[57].Nt = TRUE;
  Quiz[58].Nt = TRUE;
  Quiz[59].Nt = TRUE;
  Quiz[60].Nt = TRUE;
  Quiz[61].Nt = TRUE;
  Quiz[62].Aspie = TRUE;
  Quiz[63].Aspie = TRUE;
  Quiz[64].Aspie = TRUE;
  Quiz[65].Aspie = TRUE;
  Quiz[66].Aspie = TRUE;
  Quiz[67].Aspie = TRUE;
  Quiz[68].Aspie = TRUE;
  Quiz[69].Aspie = TRUE;
  Quiz[70].Aspie = TRUE;
  Quiz[71].Aspie = TRUE;
  Quiz[72].Aspie = TRUE;
  Quiz[73].Aspie = TRUE;
  Quiz[74].Aspie = TRUE;
  Quiz[75].Aspie = TRUE;
  Quiz[76].Aspie = TRUE;
  Quiz[77].Aspie = TRUE;
  Quiz[78].Aspie = TRUE;
  Quiz[79].Aspie = TRUE;
  Quiz[80].Aspie = TRUE;
  Quiz[81].Aspie = TRUE;
  Quiz[82].Aspie = TRUE;
  Quiz[83].Aspie = TRUE;
  Quiz[84].Nt = TRUE;
  Quiz[85].Nt = TRUE;
  Quiz[86].Nt = TRUE;
  Quiz[87].Nt = TRUE;
  Quiz[88].Nt = TRUE;
  Quiz[89].Nt = TRUE;
  Quiz[90].Nt = TRUE;
  Quiz[91].Nt = TRUE;
  Quiz[92].Nt = TRUE;
  Quiz[93].Nt = TRUE;
  Quiz[94].Nt = TRUE;
  Quiz[95].Nt = TRUE;
  Quiz[96].Nt = TRUE;
  Quiz[97].Nt = TRUE;
  Quiz[98].Nt = TRUE;
  Quiz[99].Nt = TRUE;
  Quiz[100].Nt = TRUE;
  Quiz[101].Nt = TRUE;
  Quiz[102].Nt = TRUE;
  Quiz[103].Nt = TRUE;
  Quiz[104].Aspie = TRUE;
  Quiz[105].Aspie = TRUE;
  Quiz[106].Aspie = TRUE;
  Quiz[107].Aspie = TRUE;
  Quiz[108].Aspie = TRUE;
  Quiz[109].Aspie = TRUE;
  Quiz[110].Aspie = TRUE;
  Quiz[111].Aspie = TRUE;
  Quiz[112].Nt = TRUE;
  Quiz[113].Nt = TRUE;
  Quiz[114].Nt = TRUE;
  Quiz[115].Nt = TRUE;
  Quiz[116].Nt = TRUE;
  Quiz[117].Nt = TRUE;
  Quiz[118].Aspie = TRUE;
  Quiz[119].Aspie = TRUE;
  Quiz[120].Aspie = TRUE;
  Quiz[121].Aspie = TRUE;
  Quiz[122].Aspie = TRUE;
  Quiz[123].Aspie = TRUE;
  Quiz[124].Aspie = TRUE;
  Quiz[125].Aspie = TRUE;
  Quiz[126].Aspie = TRUE;
  Quiz[127].Aspie = TRUE;
  Quiz[128].Nt = TRUE;
  Quiz[129].Nt = TRUE;
  Quiz[130].Nt = TRUE;
  Quiz[131].Nt = TRUE;
  Quiz[132].Nt = TRUE;
  Quiz[133].Nt = TRUE;
  Quiz[134].Nt = TRUE;
  Quiz[135].Nt = TRUE;
  Quiz[136].Nt = TRUE;

  Quiz[145].Nt = TRUE;
  Quiz[146].Aspie = TRUE;
  Quiz[147].Nt = TRUE;
  Quiz[148].Nt = TRUE;

  Quiz[12].Reverse = TRUE;
  Quiz[16].Reverse = TRUE;
  Quiz[27].Reverse = TRUE;
  Quiz[28].Reverse = TRUE;
  Quiz[29].Reverse = TRUE;
  Quiz[30].Reverse = TRUE;
  Quiz[31].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[96].Reverse = TRUE;
  Quiz[97].Reverse = TRUE;
  Quiz[98].Reverse = TRUE;
  Quiz[101].Reverse = TRUE;
  Quiz[136].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
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
  Quiz[17].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[18].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[19].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_NT_OBSESSION;
  Quiz[27].MyGroup = GROUP_NT_OBSESSION;
  Quiz[28].MyGroup = GROUP_NT_OBSESSION;
  Quiz[29].MyGroup = GROUP_NT_OBSESSION;
  Quiz[30].MyGroup = GROUP_NT_OBSESSION;
  Quiz[31].MyGroup = GROUP_NT_OBSESSION;
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
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_NT_SOCIAL;
  Quiz[54].MyGroup = GROUP_NT_SOCIAL;
  Quiz[55].MyGroup = GROUP_NT_SOCIAL;
  Quiz[56].MyGroup = GROUP_NT_SOCIAL;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_NT_SOCIAL;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
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
  Quiz[82].MyGroup = GROUP_ASPIE_NVC;
  Quiz[83].MyGroup = GROUP_ASPIE_NVC;
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
  Quiz[95].MyGroup = GROUP_NT_NVC;
  Quiz[96].MyGroup = GROUP_NT_NVC;
  Quiz[97].MyGroup = GROUP_NT_NVC;
  Quiz[98].MyGroup = GROUP_NT_NVC;
  Quiz[99].MyGroup = GROUP_NT_NVC;
  Quiz[100].MyGroup = GROUP_NT_NVC;
  Quiz[101].MyGroup = GROUP_NT_NVC;
  Quiz[102].MyGroup = GROUP_NT_NVC;
  Quiz[103].MyGroup = GROUP_NT_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[105].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[106].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[107].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[108].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[109].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[110].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[111].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[112].MyGroup = GROUP_NT_HUNTING;
  Quiz[113].MyGroup = GROUP_NT_HUNTING;
  Quiz[114].MyGroup = GROUP_NT_HUNTING;
  Quiz[115].MyGroup = GROUP_NT_HUNTING;
  Quiz[116].MyGroup = GROUP_NT_HUNTING;
  Quiz[117].MyGroup = GROUP_NT_HUNTING;
  Quiz[118].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[119].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[120].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[121].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[122].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[123].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[124].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[125].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[126].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[127].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[128].MyGroup = GROUP_NT_SENSORY;
  Quiz[129].MyGroup = GROUP_NT_SENSORY;
  Quiz[130].MyGroup = GROUP_NT_SENSORY;
  Quiz[131].MyGroup = GROUP_NT_SENSORY;
  Quiz[132].MyGroup = GROUP_NT_SENSORY;
  Quiz[133].MyGroup = GROUP_NT_SENSORY;
  Quiz[134].MyGroup = GROUP_NT_SENSORY;
  Quiz[135].MyGroup = GROUP_NT_SENSORY;
  Quiz[136].MyGroup = GROUP_NT_SENSORY;
  Quiz[137].MyGroup = GROUP_ENVIRONMENT;
  Quiz[138].MyGroup = GROUP_ENVIRONMENT;
  Quiz[139].MyGroup = GROUP_ENVIRONMENT;
  Quiz[140].MyGroup = GROUP_ENVIRONMENT;
  Quiz[141].MyGroup = GROUP_ENVIRONMENT;
  Quiz[142].MyGroup = GROUP_ENVIRONMENT;
  Quiz[143].MyGroup = GROUP_ENVIRONMENT;
  Quiz[144].MyGroup = GROUP_ENVIRONMENT;

  Quiz[145].MyGroup = GROUP_NT_TALENT;
  Quiz[146].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[147].MyGroup = GROUP_NT_NVC;
  Quiz[148].MyGroup = GROUP_NT_SENSORY;
  Quiz[149].MyGroup = GROUP_ENVIRONMENT;

  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[2].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[3].Text = "Do you have an avid perseverance in gathering and cataloguing information on a topic of interest?";
  Quiz[4].Text = "Do you need periods of contemplation?";
  Quiz[5].Text = "Do you notice patterns in things all the time?";
  Quiz[6].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[7].Text = "Do you have one special talent which you have emphasised and worked on?";
  Quiz[8].Text = "Do you tend to notice details that others do not?";
  Quiz[9].Text = "Do you get confused by several verbal instructions at the same time?";
  Quiz[10].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[11].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[12].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[13].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[14].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[15].Text = "Are you easily distracted?";
  Quiz[16].Text = "Do you find it easy to do more than one thing at once?";
  Quiz[17].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[18].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[19].Text = "Do you prefer to wear the same clothes or eat the same food many days in a row?";
  Quiz[20].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[21].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[22].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[23].Text = "Do you have certain routines which you need to follow?";
  Quiz[24].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[25].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[26].Text = "Do you often feel out-of-sync with others?";
  Quiz[27].Text = "Do you enjoy team sports?";
  Quiz[28].Text = "Are your views typical of your peer group?";
  Quiz[29].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[30].Text = "Do you have an interest for the current fashions?";
  Quiz[31].Text = "Do you enjoy gossip?";
  Quiz[32].Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  Quiz[33].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  Quiz[34].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[35].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[36].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[37].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[38].Text = "Do you tend to become obsessed with a potential partner and cannot let go of him/her?";
  Quiz[39].Text = "Do you see your own activities as more important than other people's?";
  Quiz[40].Text = "Do your feelings cycle regulary between hopelessness and extremely high confidence?";
  Quiz[41].Text = "Do you have problems starting and / or finishing projects?";
  Quiz[42].Text = "Do you have trouble with authority?";
  Quiz[43].Text = "Do you have atypical or irregular sleeping patterns that deviate from the 24-h cycle?";
  Quiz[44].Text = "Do you find the norms of hygiene too strict?";
  Quiz[45].Text = "Do you sometimes lie awake at night because of too many thoughts?";
  Quiz[46].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[47].Text = "Do you have unusual sexual preferences?";
  Quiz[48].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[49].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[50].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[51].Text = "Do people think you are aloof and distant?";
  Quiz[52].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[53].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[54].Text = "Do you dislike shaking hands with strangers?";
  Quiz[55].Text = "Are you naturally good at returning social courtesies and gestures?";
  Quiz[56].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[57].Text = "Do you enjoy meeting new people?";
  Quiz[58].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[59].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[60].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[61].Text = "Do you dislike working while being observed?";
  Quiz[62].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[63].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[64].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[65].Text = "Do you often don't know where to put your arms?";
  Quiz[66].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[67].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[68].Text = "Have you been accused of staring?";
  Quiz[69].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[70].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[71].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[72].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[73].Text = "Do recently heard tunes or rhythms tend to stick and replay themselves repeatedly in your head?";
  Quiz[74].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[75].Text = "Do you repeat vocalizations made by others?";
  Quiz[76].Text = "Do you fiddle with things?";
  Quiz[77].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[78].Text = "Do you stutter when stressed?";
  Quiz[79].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[80].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[81].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  Quiz[82].Text = "Do you talk to yourself?";
  Quiz[83].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[84].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[85].Text = "Do you have problems with timing in conversations?";
  Quiz[86].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[87].Text = "Do others often misunderstand you?";
  Quiz[88].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[89].Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  Quiz[90].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[91].Text = "Do you tend to interpret things literally?";
  Quiz[92].Text = "Do people often tell you that you keep going on and on about the same thing?";
  Quiz[93].Text = "Are you often surprised what people's motives are ?";
  Quiz[94].Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  Quiz[95].Text = "Is it hard for you to see why some things upset people so much?";
  Quiz[96].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[97].Text = "Do you know when you are expected to offer an apology?";
  Quiz[98].Text = "Are you good at interpreting facial expressions?";
  Quiz[99].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[100].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[101].Text = "Do you find it easy to describe your feelings?";
  Quiz[102].Text = "Do you have a monotonous voice?";
  Quiz[103].Text = "Are you naturally so honest and sincere yourself that you assume everyone should be?";
  Quiz[104].Text = "Do you mistake noises for voices?";
  Quiz[105].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[106].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[107].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[108].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[109].Text = "Are you or have you been hyperactive?";
  Quiz[110].Text = "Do you enjoy walking on your toes?";
  Quiz[111].Text = "Have you been fascinated about making traps?";
  Quiz[112].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[113].Text = "Do you drop things when your attention is on other things?";
  Quiz[114].Text = "Do you have problems filling out forms?";
  Quiz[115].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[116].Text = "Do you mix up digits in numbers like 95 and 59?";
  Quiz[117].Text = "Do you have trouble reading clocks?";
  Quiz[118].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[119].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[120].Text = "Do you dislike when people walk behind you?";
  Quiz[121].Text = "Are you bothered by clothes tags or light touch?";
  Quiz[122].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[123].Text = "Do you have extra sensitive hearing?";
  Quiz[124].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[125].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[126].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[127].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[128].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[129].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[130].Text = "Do you misjudge how much time has passed when involved in interesting activities?";
  Quiz[131].Text = "Do you find it hard to tell the age of people?";
  Quiz[132].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[133].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
  Quiz[134].Text = "Do you have problems finding your way to new places?";
  Quiz[135].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[136].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  Quiz[137].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[138].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[139].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[140].Text = "Are you sometimes afraid in safe situations?";
  Quiz[141].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[142].Text = "Are you prone to getting depressions?";
  Quiz[143].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[144].Text = "Are you impatient and have low frustration tolerance?";
  Quiz[145].Text = "Can you easily remember verbal instructions?";
  Quiz[146].Text = "Is your sense of humor fairly conventional?";
  Quiz[147].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[148].Text = "Do you find it easy to estimate the age of people?";
  Quiz[149].Text = "Are you gracious about criticism, correction and direction?";
}

/*##########################################################################
#
#   Name       : TQuizFinal2::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::InitReferers()
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
	AddReferer("weebls-stuff.com", "weebls-stuff.com");
	AddReferer("keithandthegirl.com", "keithandthegirl.com/forums/showthread.php?t=9785");
}

/*##########################################################################
#
#   Name       : TQuizFinal2::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::SetupControlGroups()
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
	DefineNt("weebls-stuff.com");
	DefineNt("keithandthegirl.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##################  TQuizFinal2::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::LoadReferers()
{
	TQuiz2Row Row;
	TReferer *ref;
	int g;
	char GroupResult[ACTIVE_GROUP_COUNT];

    for (g = 0; g < ACTIVE_GROUP_COUNT; g++)
        GroupResult[g] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Gender == 1)
			UpdateReferer(&MaleRef, Row.AsResult, Row.NtResult, GroupResult);
        else			
			UpdateReferer(&FemaleRef, Row.AsResult, Row.NtResult, GroupResult);
	
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Aspie == 2)
			UpdateReferer(&AsRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&AddRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.OCD == 2)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Social == 2)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult, GroupResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult, GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizFinal2::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::LoadPopulations()
{
	TQuiz2Row Row;
	int i;
	int id;
	TReferer *ref;
	char DxArr[DX_COUNT];
	char score;
	int IdArr[MAX_QUESTIONS];
	int g;
	char GroupResult[ACTIVE_GROUP_COUNT];
	char DxResult[DX_COUNT];

	for (g = 0; g < ACTIVE_GROUP_COUNT; g++)
		GroupResult[g] = 0;

	for (g = 0; g < DX_COUNT; g++)
		DxResult[g] = 0;

	for (i = 0; i < N; i++)
	{
		Quiz[i].NoAnswer = 0;
		IdArr[i] = GetGlobalId(i);
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		BirthMonth.Add(Row.AsResult, Row.NtResult, Row.BirthMonth);
		BirthYear.Add(Row.AsResult, Row.NtResult, Row.BirthYear, Row.Gender);

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 150)
				{
					score = Row.Quiz[i] - 1;
					id = IdArr[i];

					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
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

		if (Row.Social == 2)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_YES;

		if (Row.Social == 1)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_SELF;

		if (Row.Social == 0)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_NO;

		All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

		if (Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

				AsMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			}

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

			if (Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.ADHD >= 2)
		{
			Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.Social >= 2)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

		if (Row.OCD >= 2)
			OCD.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

	}
}

/*##########################################################################
#
#   Name       : TQuizFinal2::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::SetupCross()
{
    int i;

    for (i = 0; i < 150; i++)
	    DefineGlobalId(i, i);
}

/*##########################################################################
#
#   Name       : TQuizFinal2::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal2::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuiz2Row Row;
	char DxArr[DX_COUNT];
	int g;
	char GroupResult[ACTIVE_GROUP_COUNT];
	char DxResult[DX_COUNT];

	for (g = 0; g < ACTIVE_GROUP_COUNT; g++)
		GroupResult[g] = 0;

	for (g = 0; g < DX_COUNT; g++)
		DxResult[g] = 0;

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
			pop->Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
}

/*##################  IsPca ##########################
*   Purpose....: Check quiz row against pca-type                 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int IsPca(TQuiz2Row *row, int PcaType)
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
				if (row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizFinal2::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::ExportExcelCase(const char *filename, int PcaType)
{
	TQuiz2Row Row;
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
                    
					sprintf(str, "%d", ival);
					file.Write(str);
					if (i != GetQuizN() - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizFinal2::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::ExportExcelAspie(const char *filename)
{
	TQuiz2Row Row;
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

				sprintf(str, "%d", ival);
				file.Write(str);
				if (i != N - 1)
					file.Write(", ");
			}
			file.Write("\n");
	}
}

/*##################  TQuizFinal2::ExportExcelAspieItems ##########################
*   Purpose....: Export aspie items only cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::ExportExcelAspieItems(const char *filename)
{
	TQuiz2Row Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		if (Quiz[i].Aspie)
		{
    		file.Write("\"");

    		sprintf(str, "#%d", i + 1);
	    	file.Write(str);

		    file.Write("\", ");
		 }
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
//	    if (Row.AsResult - Row.NtResult >= 35)
		 {
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				 if (Quiz[i].Aspie)
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
					file.Write(", ");
				 }
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizFinal2::ExportExcelNtItems ##########################
*   Purpose....: Export nt items only cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::ExportExcelNtItems(const char *filename)
{
	TQuiz2Row Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		if (Quiz[i].Nt)
		{
			file.Write("\"");

			sprintf(str, "#%d", i + 1);
			file.Write(str);

			 file.Write("\", ");
		 }
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
//		 if (Row.NtResult - Row.AsResult >= 35)
		 {
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				 if (Quiz[i].Nt)
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
					file.Write(", ");
			    }
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizFinal2::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::ExportExcelGroups(const char *filename)
{
	TQuiz2Row Row;
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

/*##################  TQuizFinal2::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_MALE)
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

					case PCA_TYPE_ASIA:
						Quiz[q - 1].AsiaPca[0] = d1;
						Quiz[q - 1].AsiaPca[1] = d2;
						Quiz[q - 1].AsiaPca[2] = d3;
						Quiz[q - 1].AsiaPca[3] = d4;
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
		AllCount[i] = 0;
		AllAsCount[i] = 0;
	}
}

/*##################  TRace::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::Add(TQuiz2Row *Row)
{
	int index;
	int diff = Row->AsResult - Row->NtResult;

	index = 3;
	    
	if (Row->Ancestry == 5)
		index = 0;      // african american

	if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
		index = 0;      // black african

	if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
		index = 1;      // white

	if (Row->Ancestry >= 4000)
		index = 2;      // asian

	AllCount[index]++;

	if (diff >= 35)
		AllAsCount[index]++;

	if (Row->Country == 7302)
	{
	    index = 5;
	    
		if (Row->Ancestry == 3)
			index = 0;      // american indian

		if (Row->Ancestry == 5)
			index = 1;

		if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
			index = 1;

		if (Row->Ancestry == 6)
			index = 2;      // hispanic

		if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
			index = 3;      // white

		if (Row->Ancestry >= 4000)
			index = 4;      // asian

		UsCount[index]++;

		if (diff >= 35)
			UsAsCount[index]++;
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
	file.Write("All");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Aspie");
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
		sd = sqrt(rsum / ((long double)count - 1));

		dev = 1.96 * sd / sqrt(count);

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

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsAsCount[index]);
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

/*##################  TRace::WriteAllRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteAllRow(TFile &file, int index, const char *text)
{
	 char str[80];
	 int sum;
	 int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	 file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", AllCount[index]);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", AllAsCount[index]);
	file.Write(str);
	WriteFieldFooter(file);

	sum = 0;
	for (i = 0; i < 10; i++)
		sum += AllCount[i];

	if (sum)
	{
		WriteEntry(file, AllCount[index], sum);

		if (AllCount[index])
			WriteEntry(file, AllAsCount[index], AllCount[index]);
	}
	else
		file.Write("---");

	file.Write("</tr>");
}


/*##################  TQuizFinal2::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal2::WriteRace(const char *filename)
{
	TQuiz2Row Row;
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
	race.WriteUsRow(file, 4, "Asian");
	race.WriteUsRow(file, 5, "Other");

	file.Write("</table>");

	file.Write("<br><br>");

	file.Write("<h2>Total population</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TRace::WriteHeader(file);

	race.WriteAllRow(file, 0, "African");
	race.WriteAllRow(file, 1, "Caucasian");
	race.WriteAllRow(file, 2, "Asian");
	race.WriteAllRow(file, 3, "Other");

	file.Write("</table>");
}
