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
# quizK10.cpp
# Quiz class for K10
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizK10.h"
#include "quizdK10.h"

#define CI      1

#define MAX_IN_ROW              4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizK10::TQuizK10
#
#   Purpose....: Constructor for TQuizK10
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizK10::TQuizK10(const char *FileName)
  : TQuiz(146),
        FDataFile(FileName)
{
        SetupTexts();
        SetupCross();

        LoadPopulations();
        Calculate();
}

/*##########################################################################
#
#   Name       : TQuizK10::~TQuizK10
#
#   Purpose....: Destructor for TQuizK10
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizK10::~TQuizK10()
{
}

/*##################  TQuizK10::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizK10::GetPcaCount()
{
        return 4;
}

/*##################  TQuizK10::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizK10::GetCatCount(int Question)
{
   return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizK10::GetQuizN()
{
    return 146;
}

/*##########################################################################
#
#   Name       : TQuizK10::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizK10::WriteName(TFile &File)
{
    File.Write("K10");
}

/*##########################################################################
#
#   Name       : TQuizK10::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizK10::WriteLongName(TFile &File)
{
    File.Write("K10");
}

/*##########################################################################
#
#   Name       : TQuizK10::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizK10::SetupTexts()
{
  Quiz[0].Aspie = TRUE;
  Quiz[1].Aspie = TRUE;
  Quiz[2].Aspie = TRUE;
  Quiz[3].Aspie = TRUE;
  Quiz[4].Aspie = TRUE;
  Quiz[5].Aspie = TRUE;
  Quiz[6].Nt = TRUE;
  Quiz[7].Nt = TRUE;
  Quiz[8].Nt = TRUE;
  Quiz[9].Nt = TRUE;
  Quiz[10].Nt = TRUE;
  Quiz[11].Nt = TRUE;
  Quiz[12].Nt = TRUE;
  Quiz[13].Nt = TRUE;
  Quiz[14].Nt = TRUE;
  Quiz[15].Nt = TRUE;
  Quiz[16].Nt = TRUE;
  Quiz[17].Nt = TRUE;
  Quiz[18].Nt = TRUE;
  Quiz[19].Nt = TRUE;
  Quiz[20].Nt = TRUE;
  Quiz[21].Aspie = TRUE;
  Quiz[22].Aspie = TRUE;
  Quiz[23].Aspie = TRUE;
  Quiz[24].Aspie = TRUE;
  Quiz[25].Aspie = TRUE;
  Quiz[26].Aspie = TRUE;
  Quiz[27].Aspie = TRUE;
  Quiz[28].Aspie = TRUE;
  Quiz[29].Aspie = TRUE;
  Quiz[30].Aspie = TRUE;
  Quiz[31].Aspie = TRUE;
  Quiz[32].Aspie = TRUE;
  Quiz[33].Aspie = TRUE;
  Quiz[34].Nt = TRUE;
  Quiz[35].Nt = TRUE;
  Quiz[36].Nt = TRUE;
  Quiz[37].Nt = TRUE;
  Quiz[38].Nt = TRUE;
  Quiz[39].Nt = TRUE;
  Quiz[40].Nt = TRUE;
  Quiz[41].Aspie = TRUE;
  Quiz[42].Aspie = TRUE;
  Quiz[43].Aspie = TRUE;
  Quiz[44].Aspie = TRUE;
  Quiz[45].Aspie = TRUE;
  Quiz[46].Aspie = TRUE;
  Quiz[47].Aspie = TRUE;
  Quiz[48].Aspie = TRUE;
  Quiz[49].Aspie = TRUE;
  Quiz[50].Aspie = TRUE;
  Quiz[51].Aspie = TRUE;
  Quiz[52].Aspie = TRUE;
  Quiz[53].Aspie = TRUE;
  Quiz[54].Aspie = TRUE;
  Quiz[55].Aspie = TRUE;
  Quiz[56].Aspie = TRUE;
  Quiz[57].Aspie = TRUE;
  Quiz[58].Aspie = TRUE;
  Quiz[59].Nt = TRUE;
  Quiz[60].Nt = TRUE;
  Quiz[61].Nt = TRUE;
  Quiz[62].Nt = TRUE;
  Quiz[63].Nt = TRUE;
  Quiz[64].Nt = TRUE;
  Quiz[65].Nt = TRUE;
  Quiz[66].Nt = TRUE;
  Quiz[67].Nt = TRUE;
  Quiz[68].Nt = TRUE;
  Quiz[69].Nt = TRUE;
  Quiz[70].Nt = TRUE;
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
  Quiz[82].Nt = TRUE;
  Quiz[83].Nt = TRUE;
  Quiz[84].Nt = TRUE;
  Quiz[85].Nt = TRUE;
  Quiz[86].Nt = TRUE;
  Quiz[87].Nt = TRUE;
  Quiz[88].Nt = TRUE;
  Quiz[89].Aspie = TRUE;
  Quiz[90].Aspie = TRUE;
  Quiz[91].Aspie = TRUE;
  Quiz[92].Aspie = TRUE;
  Quiz[93].Aspie = TRUE;
  Quiz[94].Aspie = TRUE;
  Quiz[95].Nt = TRUE;
  Quiz[96].Nt = TRUE;  
  Quiz[97].Nt = TRUE;
  Quiz[98].Nt = TRUE;
  Quiz[99].Nt = TRUE;
  Quiz[100].Nt = TRUE;
  Quiz[101].Nt = TRUE;
  Quiz[102].Nt = TRUE;
  Quiz[103].Nt = TRUE;
  Quiz[104].Nt = TRUE;
  Quiz[105].Nt = TRUE;
  Quiz[106].Nt = TRUE;
  Quiz[107].Aspie = TRUE;
  Quiz[108].Aspie = TRUE;  
  Quiz[109].Aspie = TRUE;
  Quiz[110].Aspie = TRUE;
  Quiz[111].Aspie = TRUE;
  Quiz[112].Aspie = TRUE;
  Quiz[113].Aspie = TRUE;
  Quiz[114].Aspie = TRUE;
  Quiz[115].Aspie = TRUE;
  Quiz[116].Aspie = TRUE;
  Quiz[117].Nt = TRUE;
  Quiz[118].Nt = TRUE;
  Quiz[119].Nt = TRUE;
  Quiz[120].Nt = TRUE;
  Quiz[121].Nt = TRUE;
  Quiz[122].Nt = TRUE;
  Quiz[123].Nt = TRUE;
  Quiz[124].Nt = TRUE;

  Quiz[12].Reverse = TRUE;
  Quiz[35].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[39].Reverse = TRUE;
  Quiz[82].Reverse = TRUE;
  Quiz[83].Reverse = TRUE;
  Quiz[84].Reverse = TRUE;
  Quiz[85].Reverse = TRUE;
  Quiz[86].Reverse = TRUE;
  Quiz[87].Reverse = TRUE;
  Quiz[88].Reverse = TRUE;
  Quiz[102].Reverse = TRUE;
  Quiz[117].Reverse = TRUE;
  Quiz[118].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[122].Reverse = TRUE;
  Quiz[123].Reverse = TRUE;
  Quiz[124].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_MIXED;
  Quiz[5].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[6].MyGroup = GROUP_NT_TALENT;
  Quiz[7].MyGroup = GROUP_NT_TALENT;
  Quiz[8].MyGroup = GROUP_NT_TALENT;
  Quiz[9].MyGroup = GROUP_NT_TALENT;
  Quiz[10].MyGroup = GROUP_MIXED;
  Quiz[11].MyGroup = GROUP_NT_TALENT;
  Quiz[12].MyGroup = GROUP_NT_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_NT_TALENT;
  Quiz[19].MyGroup = GROUP_MIXED;
  Quiz[20].MyGroup = GROUP_MIXED;
  Quiz[21].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[22].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[23].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[24].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[25].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[26].MyGroup = GROUP_MIXED;
  Quiz[27].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[28].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[29].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[30].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[31].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[32].MyGroup = GROUP_MIXED;
  Quiz[33].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[34].MyGroup = GROUP_NT_SENSORY;
  Quiz[35].MyGroup = GROUP_NT_SENSORY;
  Quiz[36].MyGroup = GROUP_NT_SENSORY;  
  Quiz[37].MyGroup = GROUP_NT_SENSORY;
  Quiz[38].MyGroup = GROUP_NT_SENSORY;
  Quiz[39].MyGroup = GROUP_NT_SENSORY;
  Quiz[40].MyGroup = GROUP_NT_SENSORY;
  Quiz[41].MyGroup = GROUP_ASPIE_NVC;
  Quiz[42].MyGroup = GROUP_ASPIE_NVC;
  Quiz[43].MyGroup = GROUP_ASPIE_NVC;
  Quiz[44].MyGroup = GROUP_ASPIE_NVC;
  Quiz[45].MyGroup = GROUP_ASPIE_NVC;
  Quiz[46].MyGroup = GROUP_ASPIE_NVC;
  Quiz[47].MyGroup = GROUP_ASPIE_NVC;
  Quiz[48].MyGroup = GROUP_ASPIE_NVC;
  Quiz[49].MyGroup = GROUP_ASPIE_NVC;  
  Quiz[50].MyGroup = GROUP_ASPIE_NVC;
  Quiz[51].MyGroup = GROUP_ASPIE_NVC;
  Quiz[52].MyGroup = GROUP_ASPIE_NVC;
  Quiz[53].MyGroup = GROUP_ASPIE_NVC;
  Quiz[54].MyGroup = GROUP_ASPIE_NVC;
  Quiz[55].MyGroup = GROUP_ASPIE_NVC;
  Quiz[56].MyGroup = GROUP_ASPIE_NVC;
  Quiz[57].MyGroup = GROUP_ASPIE_NVC;
  Quiz[58].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[59].MyGroup = GROUP_NT_NVC;
  Quiz[60].MyGroup = GROUP_NT_NVC;
  Quiz[61].MyGroup = GROUP_NT_NVC;
  Quiz[62].MyGroup = GROUP_NT_NVC;
  Quiz[63].MyGroup = GROUP_NT_NVC;
  Quiz[64].MyGroup = GROUP_NT_NVC;
  Quiz[65].MyGroup = GROUP_NT_NVC;
  Quiz[66].MyGroup = GROUP_NT_NVC;
  Quiz[67].MyGroup = GROUP_NT_NVC;
  Quiz[68].MyGroup = GROUP_NT_NVC;
  Quiz[69].MyGroup = GROUP_NT_NVC;
  Quiz[70].MyGroup = GROUP_MIXED;
  Quiz[71].MyGroup = GROUP_MIXED;
  Quiz[72].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[73].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[74].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[75].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[76].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[77].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[78].MyGroup = GROUP_MIXED;
  Quiz[79].MyGroup = GROUP_MIXED;
  Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[81].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[82].MyGroup = GROUP_MIXED;
  Quiz[83].MyGroup = GROUP_MIXED;
  Quiz[84].MyGroup = GROUP_NT_FRIEND;
  Quiz[85].MyGroup = GROUP_MIXED;
  Quiz[86].MyGroup = GROUP_MIXED;
  Quiz[87].MyGroup = GROUP_MIXED;
  Quiz[88].MyGroup = GROUP_MIXED;
  Quiz[89].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[90].MyGroup = GROUP_ASPIE_RELATION;  
  Quiz[91].MyGroup = GROUP_MIXED;
  Quiz[92].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[93].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[94].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[95].MyGroup = GROUP_MIXED;
  Quiz[96].MyGroup = GROUP_NT_FRIEND;  
  Quiz[97].MyGroup = GROUP_NT_FRIEND;
  Quiz[98].MyGroup = GROUP_MIXED;
  Quiz[99].MyGroup = GROUP_NT_FRIEND;
  Quiz[100].MyGroup = GROUP_NT_FRIEND;
  Quiz[101].MyGroup = GROUP_NT_FRIEND;
  Quiz[102].MyGroup = GROUP_MIXED;
  Quiz[103].MyGroup = GROUP_NT_FRIEND;
  Quiz[104].MyGroup = GROUP_NT_FRIEND;
  Quiz[105].MyGroup = GROUP_NT_FRIEND;
  Quiz[106].MyGroup = GROUP_NT_FRIEND;
  Quiz[107].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[108].MyGroup = GROUP_ASPIE_RELATION;  
  Quiz[109].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[110].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[111].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[112].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[113].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[114].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[115].MyGroup = GROUP_MIXED;
  Quiz[116].MyGroup = GROUP_MIXED;
  Quiz[117].MyGroup = GROUP_NT_RELATION;
  Quiz[118].MyGroup = GROUP_NT_RELATION;
  Quiz[119].MyGroup = GROUP_NT_RELATION;  
  Quiz[120].MyGroup = GROUP_NT_RELATION;
  Quiz[121].MyGroup = GROUP_NT_NVC;
  Quiz[122].MyGroup = GROUP_NT_TALENT;
  Quiz[123].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[124].MyGroup = GROUP_NT_SENSORY;
  Quiz[125].MyGroup = GROUP_NT_FRIEND;
  Quiz[126].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[127].MyGroup = GROUP_MIXED;
  Quiz[128].MyGroup = GROUP_MIXED;
  Quiz[129].MyGroup = GROUP_MIXED;
  Quiz[130].MyGroup = GROUP_MIXED;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_MIXED;
  Quiz[133].MyGroup = GROUP_MIXED;
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_MIXED;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_MIXED;
  Quiz[138].MyGroup = GROUP_MIXED;
  Quiz[139].MyGroup = GROUP_MIXED;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_MIXED;
  Quiz[143].MyGroup = GROUP_MIXED;
  Quiz[144].MyGroup = GROUP_MIXED;
  Quiz[145].MyGroup = GROUP_MIXED;

  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Is it important for you to find a unique niche where you can acquire unique competence?";
  Quiz[2].Text = "Do you have an avid perseverance in gathering and cataloguing information on a topic of interest?";
  Quiz[3].Text = "Do you notice patterns in things all the time?";
  Quiz[4].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[5].Text = "Do you have one special talent which you have emphasised and worked on?";
  Quiz[6].Text = "Do you get confused by several verbal instructions at the same time?";
  Quiz[7].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[8].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[9].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[10].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[11].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[12].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[13].Text = "Do you have problems filling out forms?";
  Quiz[14].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[15].Text = "Do you need a lot of motivation to do things?";
  Quiz[16].Text = "Do you work slowly on jobs you dislike?";
  Quiz[17].Text = "Do you have problems finding your way to new places?";
  Quiz[18].Text = "Are you easily distracted?";
  Quiz[19].Text = "Do you mix up digits in numbers like 95 and 59?";
  Quiz[20].Text = "Do you have trouble reading clocks?";
  Quiz[21].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[22].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[23].Text = "Are you sometimes afraid in safe situations?";
  Quiz[24].Text = "Are you bothered by clothes tags or light touch?";
  Quiz[25].Text = "Do you have certain routines which you need to follow?";
  Quiz[26].Text = "Do you dislike when people walk behind you?";
  Quiz[27].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[28].Text = "Are your eyes extra sensitive to strong light and glare?";
  Quiz[29].Text = "Do you have extra sensitive hearing?";
  Quiz[30].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[31].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[32].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[33].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[34].Text = "Do you have problems with timing in conversations?";
  Quiz[35].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[36].Text = "Are you good at interpreting facial expressions?";
  Quiz[37].Text = "Do you find it hard to tell the age of people?";
  Quiz[38].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[39].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  Quiz[40].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[41].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[42].Text = "Have you been accused of staring?";
  Quiz[43].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[44].Text = "Do you mistake noises for voices?";
  Quiz[45].Text = "Do you fiddle with things?";
  Quiz[46].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[47].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[48].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[49].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[50].Text = "Do recently heard tunes or rhythms tend to stick and replay themselves repeatedly in your head?";
  Quiz[51].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[52].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[53].Text = "Do you get a pleasurable tingling sensation in the head, scalp or back of the body in response to certain sounds?";
  Quiz[54].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  Quiz[55].Text = "Do you talk to yourself?";
  Quiz[56].Text = "Do you have an urge to jump over things?";
  Quiz[57].Text = "Do you enjoy spinning in circles?";
  Quiz[58].Text = "Do you have, or used to have, imaginary relationships?";
  Quiz[59].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[60].Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  Quiz[61].Text = "Do others often misunderstand you?";
  Quiz[62].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[63].Text = "Is it hard for you to see why some things upset people so much?";
  Quiz[64].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[65].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[66].Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  Quiz[67].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[68].Text = "Do you tend to interpret things literally?";
  Quiz[69].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[70].Text = "Do you have a monotonous voice?";
  Quiz[71].Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  Quiz[72].Text = "Do you see your own activities as more important than other people's?";
  Quiz[73].Text = "Are you impatient and have low frustration tolerance?";
  Quiz[74].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[75].Text = "Will you abandon your friends if your activities or ideals clash?";
  Quiz[76].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[77].Text = "Do you usually find faults with opinions that you don't share?";
  Quiz[78].Text = "Do you obstruct others' plans?";
  Quiz[79].Text = "Do you have trouble with authority?";
  Quiz[80].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[81].Text = "Are you more sexually attracted to strangers than to people you know well?";
  Quiz[82].Text = "Are you good at team-work?";
  Quiz[83].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[84].Text = "Do you enjoy big events even if they are crowded?";
  Quiz[85].Text = "Does it feel natural for you to say 'thank you' and 'sorry'?";
  Quiz[86].Text = "Do you enjoy travel?";
  Quiz[87].Text = "Do you take pride in your appearance?";
  Quiz[88].Text = "Do you enjoy gossip?";
  Quiz[89].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  Quiz[90].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[91].Text = "Do you have odd hair (for example multiple whorls, standing up when short or other peculiarities)?";
  Quiz[92].Text = "Do you have unusual sexual preferences?";
  Quiz[93].Text = "Do you prefer to construct your own set of spiritual beliefs rather than following existing religions / belief-systems?";
  Quiz[94].Text = "Would you consider polyamory (being in love with more than one person) if you knew your partner would not mind?";
  Quiz[95].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[96].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[97].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[98].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[99].Text = "Do you stay away from situations where people might express affection for you?";
  Quiz[100].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[101].Text = "Do you prefer to keep to yourself?";
  Quiz[102].Text = "Do you find it easy to describe your feelings?";
  Quiz[103].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[104].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[105].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[106].Text = "Is it hard for you to approach somebody you are attracted to?";
  Quiz[107].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[108].Text = "Do you realize hours later that somebody that you have a romantic interest for actually showed interest for you, and then feel bad about the missed opportunity to connect?";
  Quiz[109].Text = "Do you have an urge to observe the habits of humans and/or animals?";
  Quiz[110].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[111].Text = "Do you like to follow (walk behind) people you are attached to?";
  Quiz[112].Text = "Do you have an urge to learn the routines of people you know?";
  Quiz[113].Text = "Have people you formed strong attachments to taken advantage of you?";
  Quiz[114].Text = "Do you examine the hair of people you like a lot?";
  Quiz[115].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[116].Text = "Do you have a need to confess?"; 
  Quiz[117].Text = "Do you like tongue-kissing?";
  Quiz[118].Text = "Do you get great pleasure from making love?";
  Quiz[119].Text = "Are you asexual?";
  Quiz[120].Text = "Do you dislike sexual intercourse other than as procreation?";
  Quiz[121].Text = "Is your sense of humor fairly conventional?";
  Quiz[122].Text = "Can you easily remember verbal instructions?";
  Quiz[123].Text = "Are you gracious about criticism, correction and direction?";
  Quiz[124].Text = "Do you find it easy to estimate the age of people?";

  Quiz[125].Text = "Do you prefer to hug only a romantic partner?";
  Quiz[126].Text = "Do you like to protect people you are attached to even when they didn't ask for it?";

  Quiz[127].Text = "12 years old";
  Quiz[128].Text = "13 years old";
  Quiz[129].Text = "14 years old";
  Quiz[130].Text = "15 years old";
  Quiz[131].Text = "16 years old";
  Quiz[132].Text = "17 years old";
  Quiz[133].Text = "18 years old";
  Quiz[134].Text = "19 years old";
  Quiz[135].Text = "20 years old";
  Quiz[136].Text = "21 years old";
  Quiz[137].Text = "22 years old";
  Quiz[138].Text = "23 years old";
  Quiz[139].Text = "24 years old";
  Quiz[140].Text = "25 years old";
  Quiz[141].Text = "26 years old";
  Quiz[142].Text = "27 years old";
  Quiz[143].Text = "28 years old";
  Quiz[144].Text = "29 years old";
  Quiz[145].Text = "30 years old";
}

/*##########################################################################
#
#   Name       : TQuizK10::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizK10::LoadPopulations()
{
        TQuizRow Row;
        int i;
        int j;
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

//                                      DsmAs.Add(Row.Aspie, id, score);
//                                      DsmAdd.Add(Row.ADHD, id, score);
//                                      DsmSocialPhobia.Add(Row.Social, id, score);
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
#   Name       : TQuizK10::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizK10::SetupCross()
{
    int i;

    for (i = 0; i < 146; i++)
            DefineGlobalId(i, i);
}

/*##########################################################################
#
#   Name       : TQuizK10::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizK10::GetReferer(const char *referer, TPopulation *pop)
{
}

/*##################  TQuizK10::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizK10::ImportMvsp(const char *filename, int PcaType)
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
            rowstr = strstr(buf, "variable loadings");
            if (rowstr)
            {
                pos += (rowstr - buf);
                break;
            }
            else
                pos += MAX_IN_ROW - 25;

            infile.SetPos(pos);
        }
        
        infile.SetPos(pos);
                                
        while (size = infile.Read(buf, MAX_IN_ROW))
        {
                buf[size] = 0;
                rowstr = strstr(buf, "C");
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

//                                      if (PcaType == PCA_TYPE_ALL)
//                                              d4 = -d4;

//                                      if (d1 > 0 && d2 > 0)
//                                      {
//                                              if (d1 > d2)
//                                              {
//                                                      d1 = d1 - d2;
//                                                      d2 = 0;
//                                              }
//                                              else
//                                              {
//                                                      d2 = d2 - d1;
//                                                      d1 = 0;
//                                              }
//                                      }
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
