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
# QuizM1.cpp
# Quiz class for M1
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizm1.h"
#include "quizdm.h"

#define CI      1

#define MAX_IN_ROW              4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizM1::TQuizM1
#
#   Purpose....: Constructor for TQuizM1
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizM1::TQuizM1(const char *FileName)
  : TQuiz(134),
        FDataFile(FileName)
{
        SetupTexts();
        SetupCross();

        LoadPopulations();
        Calculate();
}

/*##########################################################################
#
#   Name       : TQuizM1::~TQuizM1
#
#   Purpose....: Destructor for TQuizM1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizM1::~TQuizM1()
{
}

/*##################  TQuizM1::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizM1::GetPcaCount()
{
    return 4;
}

/*##################  TQuizM1::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizM1::GetCatCount(int Question)
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
int TQuizM1::GetQuizN()
{
    return 134;
}

/*##########################################################################
#
#   Name       : TQuizM1::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizM1::WriteName(TFile &File)
{
    File.Write("M1");
}

/*##########################################################################
#
#   Name       : TQuizM1::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizM1::WriteLongName(TFile &File)
{
    File.Write("M1");
}

/*##########################################################################
#
#   Name       : TQuizM1::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizM1::SetupTexts()
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
  Quiz[9].Aspie = TRUE;
  Quiz[10].Aspie = TRUE;
  Quiz[11].Aspie = TRUE;
  Quiz[12].Aspie = TRUE;
  Quiz[13].Nt = TRUE;
  Quiz[14].Nt = TRUE;
  Quiz[15].Nt = TRUE;
  Quiz[16].Nt = TRUE;
  Quiz[17].Nt = TRUE;
  Quiz[18].Nt = TRUE;
  Quiz[19].Nt = TRUE;
  Quiz[20].Nt = TRUE;
  Quiz[21].Nt = TRUE;
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
  Quiz[33].Nt = TRUE;
  Quiz[34].Nt = TRUE;
  Quiz[35].Nt = TRUE;
  Quiz[36].Nt = TRUE;
  Quiz[37].Nt = TRUE;
  Quiz[38].Nt = TRUE;
  Quiz[39].Aspie = TRUE;
  Quiz[40].Aspie = TRUE;
  Quiz[41].Aspie = TRUE;
  Quiz[42].Aspie = TRUE;
  Quiz[43].Aspie = TRUE;
  Quiz[44].Aspie = TRUE;
  Quiz[45].Aspie = TRUE;
  Quiz[46].Aspie = TRUE;
  Quiz[47].Aspie = TRUE;
  Quiz[48].Aspie = TRUE;
  Quiz[49].Aspie = TRUE;
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
  Quiz[61].Aspie = TRUE;
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
  Quiz[73].Nt = TRUE;
  Quiz[74].Nt = TRUE;
  Quiz[75].Nt = TRUE;
  Quiz[76].Nt = TRUE;
  Quiz[77].Nt = TRUE;
  Quiz[78].Nt = TRUE;
  Quiz[79].Aspie = TRUE;
  Quiz[80].Aspie = TRUE;
  Quiz[81].Aspie = TRUE;
  Quiz[82].Aspie = TRUE;
  Quiz[83].Aspie = TRUE;
  Quiz[84].Aspie = TRUE;
  Quiz[85].Aspie = TRUE;
  Quiz[86].Aspie = TRUE;
  Quiz[87].Aspie = TRUE;
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

  Quiz[16].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[73].Reverse = TRUE;
  Quiz[74].Reverse = TRUE;
  Quiz[75].Reverse = TRUE;
  Quiz[76].Reverse = TRUE;
  Quiz[78].Reverse = TRUE;
  Quiz[91].Reverse = TRUE;
  Quiz[92].Reverse = TRUE;
  Quiz[93].Reverse = TRUE;
  Quiz[94].Reverse = TRUE;
  Quiz[97].Reverse = TRUE;
  Quiz[100].Reverse = TRUE;
  Quiz[104].Reverse = TRUE;
  Quiz[105].Reverse = TRUE;
  Quiz[106].Reverse = TRUE;
  Quiz[107].Reverse = TRUE;
  Quiz[127].Reverse = TRUE;
  Quiz[129].Reverse = TRUE;
  Quiz[130].Reverse = TRUE;
 
  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[6].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[8].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[9].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[10].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[11].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[12].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_NT_TALENT;
  Quiz[19].MyGroup = GROUP_NT_TALENT;
  Quiz[20].MyGroup = GROUP_NT_TALENT;
  Quiz[21].MyGroup = GROUP_NT_TALENT;
  Quiz[22].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[23].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[24].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[25].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[26].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[27].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[28].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[29].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[30].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[31].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[32].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[33].MyGroup = GROUP_NT_SENSORY;
  Quiz[34].MyGroup = GROUP_NT_SENSORY;
  Quiz[35].MyGroup = GROUP_NT_SENSORY;
  Quiz[36].MyGroup = GROUP_NT_SENSORY;
  Quiz[37].MyGroup = GROUP_NT_SENSORY;
  Quiz[38].MyGroup = GROUP_NT_SENSORY;
  Quiz[39].MyGroup = GROUP_ASPIE_NVC;
  Quiz[40].MyGroup = GROUP_ASPIE_NVC;
  Quiz[41].MyGroup = GROUP_ASPIE_NVC;
  Quiz[42].MyGroup = GROUP_ASPIE_NVC;
  Quiz[43].MyGroup = GROUP_ASPIE_NVC;
  Quiz[44].MyGroup = GROUP_ASPIE_NVC;
  Quiz[45].MyGroup = GROUP_ASPIE_NVC;
  Quiz[46].MyGroup = GROUP_ASPIE_NVC;
  Quiz[47].MyGroup = GROUP_ASPIE_NVC;
  Quiz[48].MyGroup = GROUP_ASPIE_NVC;
  Quiz[49].MyGroup = GROUP_ASPIE_NVC;  
  Quiz[50].MyGroup = GROUP_NT_NVC;
  Quiz[51].MyGroup = GROUP_NT_NVC;
  Quiz[52].MyGroup = GROUP_NT_NVC;
  Quiz[53].MyGroup = GROUP_NT_NVC;
  Quiz[54].MyGroup = GROUP_NT_NVC;
  Quiz[55].MyGroup = GROUP_NT_NVC;
  Quiz[56].MyGroup = GROUP_NT_NVC;
  Quiz[57].MyGroup = GROUP_NT_NVC;
  Quiz[58].MyGroup = GROUP_NT_NVC;
  Quiz[59].MyGroup = GROUP_NT_NVC;
  Quiz[60].MyGroup = GROUP_NT_NVC;
  Quiz[61].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[62].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[63].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[64].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[65].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[66].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[67].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[68].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[69].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[70].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[71].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[72].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[73].MyGroup = GROUP_NT_RELATION;
  Quiz[74].MyGroup = GROUP_NT_RELATION;
  Quiz[75].MyGroup = GROUP_NT_RELATION;
  Quiz[76].MyGroup = GROUP_NT_RELATION;
  Quiz[77].MyGroup = GROUP_NT_RELATION;
  Quiz[78].MyGroup = GROUP_NT_RELATION;
  Quiz[79].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[81].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[82].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[83].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[84].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[85].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[86].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[87].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[88].MyGroup = GROUP_NT_SOCIAL;
  Quiz[89].MyGroup = GROUP_NT_SOCIAL;
  Quiz[90].MyGroup = GROUP_NT_SOCIAL;
  Quiz[91].MyGroup = GROUP_NT_SOCIAL;
  Quiz[92].MyGroup = GROUP_NT_SOCIAL;
  Quiz[93].MyGroup = GROUP_NT_SOCIAL;
  Quiz[94].MyGroup = GROUP_NT_SOCIAL;
  Quiz[95].MyGroup = GROUP_NT_SOCIAL;
  Quiz[96].MyGroup = GROUP_NT_SOCIAL;
  Quiz[97].MyGroup = GROUP_NT_SOCIAL;
  Quiz[98].MyGroup = GROUP_NT_SOCIAL;
  Quiz[99].MyGroup = GROUP_NT_SOCIAL;
  Quiz[100].MyGroup = GROUP_NT_SOCIAL;
  Quiz[101].MyGroup = GROUP_NT_SOCIAL;
  Quiz[102].MyGroup = GROUP_NT_SOCIAL;
  Quiz[103].MyGroup = GROUP_NT_SOCIAL;
  Quiz[104].MyGroup = GROUP_MIXED;
  Quiz[105].MyGroup = GROUP_MIXED;
  Quiz[106].MyGroup = GROUP_MIXED;
  Quiz[107].MyGroup = GROUP_MIXED;
  Quiz[108].MyGroup = GROUP_MIXED;
  Quiz[109].MyGroup = GROUP_MIXED;
  Quiz[110].MyGroup = GROUP_MIXED;
  Quiz[111].MyGroup = GROUP_MIXED;
  Quiz[112].MyGroup = GROUP_MIXED;
  Quiz[113].MyGroup = GROUP_MIXED;
  Quiz[114].MyGroup = GROUP_MIXED;
  Quiz[115].MyGroup = GROUP_MIXED;
  Quiz[116].MyGroup = GROUP_MIXED;
  Quiz[117].MyGroup = GROUP_MIXED;
  Quiz[118].MyGroup = GROUP_MIXED;
  Quiz[119].MyGroup = GROUP_MIXED;
  Quiz[120].MyGroup = GROUP_MIXED;
  Quiz[121].MyGroup = GROUP_MIXED;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_MIXED;
  Quiz[124].MyGroup = GROUP_MIXED;
  Quiz[125].MyGroup = GROUP_MIXED;
  Quiz[126].MyGroup = GROUP_MIXED;
  Quiz[127].MyGroup = GROUP_MIXED;
  Quiz[128].MyGroup = GROUP_MIXED;
  Quiz[129].MyGroup = GROUP_MIXED;
  Quiz[130].MyGroup = GROUP_MIXED;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_MIXED;
  Quiz[133].MyGroup = GROUP_MIXED;

  Quiz[0].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[1].Text = "Do you have an urge to observe the habits of animals?";
  Quiz[2].Text = "Do you notice patterns in nature?";
  Quiz[3].Text = "Do you love to collect things?";
  Quiz[4].Text = "Do you scan your environment for good hiding places?";  
  Quiz[5].Text = "Do you enjoy walking on your toes?";
  Quiz[6].Text = "Do you have an urge to jump over things?";
  Quiz[7].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[8].Text = "Do you like to sniff things?";
  Quiz[9].Text = "Do you enjoy spinning in circles?";
  Quiz[10].Text = "Do you naturally communicate feelings with animals?";
  Quiz[11].Text = "Do you enjoy sneaking through the woods?";
  Quiz[12].Text = "Do you use small sounds that others don't seem to use?";
  Quiz[13].Text = "Do you get confused by several verbal instructions at the same time?";
  Quiz[14].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[15].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[16].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[17].Text = "Do you have problems filling out forms?";
  Quiz[18].Text = "Do you need a lot of motivation to do things?";
  Quiz[19].Text = "Are you easily distracted?";
  Quiz[20].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[21].Text = "Do you work slowly on jobs you dislike?";
  Quiz[22].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[23].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[24].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[25].Text = "Are you bothered by clothes tags or light touch?";
  Quiz[26].Text = "Do you dislike when people walk behind you?";
  Quiz[27].Text = "Are your eyes extra sensitive to strong light and glare?";
  Quiz[28].Text = "Do you have certain routines which you need to follow?";
  Quiz[29].Text = "Do you have extra sensitive hearing?";
  Quiz[30].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[31].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[32].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[33].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[34].Text = "Do you find it hard to tell the age of people?";
  Quiz[35].Text = "Do you have problems finding your way to new places?";
  Quiz[36].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  Quiz[37].Text = "Do you have trouble reading clocks?"; 
  Quiz[38].Text = "Do you have a poor concept of time?";
  Quiz[39].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[40].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[41].Text = "Do you fiddle with things?";
  Quiz[42].Text = "Have you been accused of staring?";
  Quiz[43].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[44].Text = "Do you mistake noises for voices?";
  Quiz[45].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[46].Text = "Have your thoughts ever been so vivid that you were worried other people would hear them?";
  Quiz[47].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[48].Text = "Do you have, or used to have, imaginary relationships?";
  Quiz[49].Text = "Do you talk to yourself?";
  Quiz[50].Text = "Do others often misunderstand you?";
  Quiz[51].Text = "Do you have problems with timing in conversations?";
  Quiz[52].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[53].Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  Quiz[54].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[55].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[56].Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  Quiz[57].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[58].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[59].Text = "Is it hard for you to see why some things upset people so much?";
  Quiz[60].Text = "Do you tend to interpret things literally?";
  Quiz[61].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  Quiz[62].Text = "Is it important for you to find a unique niche where you can acquire unique competence?";
  Quiz[63].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[64].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[65].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[66].Text = "Have people you formed strong attachments to taken advantage of you?";
  Quiz[67].Text = "Do you feel that you are a very special or unusual person?";
  Quiz[68].Text = "Do you realize hours later that somebody that you have a romantic interest for actually showed interest for you, and then feel bad about the missed opportunity to connect?";
  Quiz[69].Text = "Do you have unusual sexual preferences?";
  Quiz[70].Text = "Do you like to protect people you are attached to even when they didn't ask for it?";  
  Quiz[71].Text = "Do you tend to develop romantic feelings for people that persistently shows interest for you?";
  Quiz[72].Text = "Do you tend to study people you are interested in?";
  Quiz[73].Text = "Do you enjoy traditional dating?";
  Quiz[74].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[75].Text = "Do you like tongue-kissing?";
  Quiz[76].Text = "Do you enjoy travel?";
  Quiz[77].Text = "Are you asexual?";
  Quiz[78].Text = "Do you take pride in your appearance?";
  Quiz[79].Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  Quiz[80].Text = "Do you have difficulty accepting criticism, correction, and direction?";  
  Quiz[81].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[82].Text = "Do you usually find faults with others' opinions that you don't share?";
  Quiz[83].Text = "Will you abandon your friends if your activities or ideals clash?";
  Quiz[84].Text = "Do you obstruct others' plans?";
  Quiz[85].Text = "Do you see your own activities as more important than other people's?";
  Quiz[86].Text = "Do you feel irritated when one person disagrees with what everyone else in a group believes?";
  Quiz[87].Text = "Are you more sexually attracted to strangers than to people you know well?";
  Quiz[88].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[89].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[90].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[91].Text = "Are you good at team-work?";
  Quiz[92].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[93].Text = "Do you stay away from situations where people might express affection for you?";
  Quiz[94].Text = "Do you find it easy to describe your feelings?";
  Quiz[95].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[96].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[97].Text = "Do you enjoy big events even if they are crowded?";
  Quiz[98].Text = "Do you prefer to keep to yourself?";
  Quiz[99].Text = "Is it hard for you to approach somebody you are attracted to?";
  Quiz[100].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[101].Text = "Are you shy?";
  Quiz[102].Text = "Do you prefer to hug only a romantic partner?";
  Quiz[103].Text = "Do you have a monotonous voice?";
  Quiz[104].Text = "Is your sense of humor fairly conventional?";
  Quiz[105].Text = "Can you easily remember verbal instructions?";
  Quiz[106].Text = "Do you accept criticism, correction and direction?";
  Quiz[107].Text = "Do you find it easy to estimate the age of people?";
  Quiz[108].Text = "Do you like to examine hair?";
  Quiz[109].Text = "Do you enjoy horseback riding?";
  Quiz[110].Text = "Have you been fascinated about making traps?";
  Quiz[111].Text = "Do you have a fascination for caves?";
  Quiz[112].Text = "Do you have a fascination with fire?";
  Quiz[113].Text = "Do you feel good in mist or fog?";
  Quiz[114].Text = "Do you enjoy lying on the ground looking at the sky?";
  Quiz[115].Text = "Are you concerned about animal welfare?";
  Quiz[116].Text = "Can you ignore pain?";
  Quiz[117].Text = "Do you have a strong grip?";
  Quiz[118].Text = "Do you enjoy hanging upside down?";
  Quiz[119].Text = "Do you enjoy chasing animals?";
  Quiz[120].Text = "Do you get an urge to climb?";
  Quiz[121].Text = "Do you enjoy to throw small things like stones?";
  Quiz[122].Text = "Do you like to dig holes in the ground?";
  Quiz[123].Text = "Do you enjoy biting people - if they let you?";
  Quiz[124].Text = "Do you have irregular sleeping patterns?";
  Quiz[125].Text = "Do you like spicey food?";
  Quiz[126].Text = "Do you like to eat vegetables?";
  Quiz[127].Text = "Can you throw things with precision?";
  Quiz[128].Text = "Would you eat food that is nutrious even if it is not so tasty?";
  Quiz[129].Text = "Do you enjoy sharing food with others?";
  Quiz[130].Text = "Do you enjoy team sports?";
  Quiz[131].Text = "Do you confuse left and right?";
  Quiz[132].Text = "Do you mix up dates and times and miss appointments?";
  Quiz[133].Text = "Are you poor at organizing your work and / or life?";
}

/*##########################################################################
#
#   Name       : TQuizM1::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizM1::LoadPopulations()
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
                                if (i < 134)
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
#   Name       : TQuizM1::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizM1::SetupCross()
{
    int i;

    for (i = 0; i < 134; i++)
            DefineGlobalId(i, i);
}

/*##########################################################################
#
#   Name       : TQuizM1::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizM1::GetReferer(const char *referer, TPopulation *pop)
{
}

/*##################  TQuizM1::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizM1::ImportMvsp(const char *filename, int PcaType)
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
