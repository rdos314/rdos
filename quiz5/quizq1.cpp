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
# QuizQ1.cpp
# Quiz class for Q1
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizQ1.h"

#define CI      1

#define MAX_IN_ROW              4096

/*##########################################################################
#
#   Name       : TQuizQ1::TQuizQ1
#
#   Purpose....: Constructor for TQuizQ1
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ1::TQuizQ1()
  : TQuiz(201)
{
    SetupTexts();
}

/*##########################################################################
#
#   Name       : TQuizQ1::~TQuizQ1
#
#   Purpose....: Destructor for TQuizQ1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ1::~TQuizQ1()
{
}

/*##################  TQuizQ1::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ1::GetCatCount(int Question)
{
    return 3;
}

/*##################  TQuizQ1::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ1::GetQuizN()
{
    return 201;
}

/*##########################################################################
#
#   Name       : TQuizQ1::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ1::WriteName(TFile &File)
{
    File.Write("Q1");
}

/*##########################################################################
#
#   Name       : TQuizQ1::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ1::WriteLongName(TFile &File)
{
    File.Write("Q1");
}

/*##########################################################################
#
#   Name       : TQuizQ1::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ1::SetupTexts()
{
  Quiz[14].Reverse = true;
  Quiz[32].Reverse = true;
  Quiz[35].Reverse = true;
  Quiz[36].Reverse = true;
  Quiz[86].Reverse = true;
  Quiz[87].Reverse = true;
  Quiz[89].Reverse = true;
  Quiz[90].Reverse = true;
  Quiz[91].Reverse = true;
  Quiz[105].Reverse = true;
  Quiz[107].Reverse = true;
  Quiz[111].Reverse = true;
  Quiz[114].Reverse = true;
  Quiz[117].Reverse = true;
  Quiz[118].Reverse = true;
  Quiz[119].Reverse = true;
  Quiz[120].Reverse = true;
 
  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_NT_TALENT;
  Quiz[6].MyGroup = GROUP_NT_TALENT;
  Quiz[7].MyGroup = GROUP_MIXED;
  Quiz[8].MyGroup = GROUP_NT_TALENT;
  Quiz[9].MyGroup = GROUP_NT_TALENT;
  Quiz[10].MyGroup = GROUP_NT_TALENT;
  Quiz[11].MyGroup = GROUP_NT_TALENT;
  Quiz[12].MyGroup = GROUP_NT_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_NT_TALENT;
  Quiz[19].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[20].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[21].MyGroup = GROUP_ASPIE_SENSORY;
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
  Quiz[32].MyGroup = GROUP_NT_SENSORY;
  Quiz[33].MyGroup = GROUP_NT_SENSORY;
  Quiz[34].MyGroup = GROUP_NT_SENSORY;
  Quiz[35].MyGroup = GROUP_NT_SENSORY;
  Quiz[36].MyGroup = GROUP_NT_SENSORY;
  Quiz[37].MyGroup = GROUP_NT_SENSORY;
  Quiz[38].MyGroup = GROUP_NT_SENSORY;
  Quiz[39].MyGroup = GROUP_ASPIE_NVC;
  Quiz[40].MyGroup = GROUP_ASPIE_NVC;
  Quiz[41].MyGroup = GROUP_MIXED;
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
  Quiz[56].MyGroup = GROUP_NT_NVC;
  Quiz[57].MyGroup = GROUP_NT_NVC;
  Quiz[58].MyGroup = GROUP_NT_NVC;
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
  Quiz[69].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[70].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[71].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[72].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[73].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[74].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[75].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[76].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[77].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[78].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[79].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[80].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[81].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[82].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[83].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[84].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[85].MyGroup = GROUP_ASPIE_RELATION;
  Quiz[86].MyGroup = GROUP_NT_RELATION;
  Quiz[87].MyGroup = GROUP_NT_RELATION;
  Quiz[88].MyGroup = GROUP_NT_RELATION;
  Quiz[89].MyGroup = GROUP_NT_RELATION;
  Quiz[90].MyGroup = GROUP_NT_RELATION;
  Quiz[91].MyGroup = GROUP_NT_RELATION;
  Quiz[92].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[93].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[94].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[95].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[96].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[97].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[98].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[99].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[100].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[101].MyGroup = GROUP_NT_SOCIAL;
  Quiz[102].MyGroup = GROUP_NT_SOCIAL;
  Quiz[103].MyGroup = GROUP_NT_SOCIAL;
  Quiz[104].MyGroup = GROUP_NT_SOCIAL;
  Quiz[105].MyGroup = GROUP_NT_SOCIAL;
  Quiz[106].MyGroup = GROUP_NT_SOCIAL;
  Quiz[107].MyGroup = GROUP_NT_SOCIAL;
  Quiz[108].MyGroup = GROUP_NT_SOCIAL;
  Quiz[109].MyGroup = GROUP_NT_SOCIAL;
  Quiz[110].MyGroup = GROUP_NT_SOCIAL;
  Quiz[111].MyGroup = GROUP_NT_SOCIAL;
  Quiz[112].MyGroup = GROUP_NT_SOCIAL;
  Quiz[113].MyGroup = GROUP_NT_SOCIAL;
  Quiz[114].MyGroup = GROUP_NT_SOCIAL;
  Quiz[115].MyGroup = GROUP_NT_SOCIAL;
  Quiz[116].MyGroup = GROUP_NT_SOCIAL;
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
  Quiz[146].MyGroup = GROUP_MIXED;
  Quiz[147].MyGroup = GROUP_MIXED;
  Quiz[148].MyGroup = GROUP_MIXED;
  Quiz[149].MyGroup = GROUP_MIXED;
  Quiz[150].MyGroup = GROUP_MIXED;
  Quiz[151].MyGroup = GROUP_MIXED;
  Quiz[152].MyGroup = GROUP_MIXED;
  Quiz[153].MyGroup = GROUP_MIXED;
  Quiz[154].MyGroup = GROUP_MIXED;
  Quiz[155].MyGroup = GROUP_MIXED;
  Quiz[156].MyGroup = GROUP_MIXED;
  Quiz[157].MyGroup = GROUP_MIXED;
  Quiz[158].MyGroup = GROUP_MIXED;
  Quiz[159].MyGroup = GROUP_MIXED;
  Quiz[160].MyGroup = GROUP_MIXED;
  Quiz[161].MyGroup = GROUP_MIXED;
  Quiz[162].MyGroup = GROUP_MIXED;
  Quiz[163].MyGroup = GROUP_MIXED;
  Quiz[164].MyGroup = GROUP_MIXED;
  Quiz[165].MyGroup = GROUP_MIXED;
  Quiz[166].MyGroup = GROUP_MIXED;
  Quiz[167].MyGroup = GROUP_MIXED;
  Quiz[168].MyGroup = GROUP_MIXED;
  Quiz[169].MyGroup = GROUP_MIXED;
  Quiz[170].MyGroup = GROUP_MIXED;
  Quiz[171].MyGroup = GROUP_MIXED;
  Quiz[172].MyGroup = GROUP_MIXED;
  Quiz[173].MyGroup = GROUP_MIXED;
  Quiz[174].MyGroup = GROUP_MIXED;
  Quiz[175].MyGroup = GROUP_MIXED;
  Quiz[176].MyGroup = GROUP_MIXED;
  Quiz[177].MyGroup = GROUP_MIXED;
  Quiz[178].MyGroup = GROUP_MIXED;
  Quiz[179].MyGroup = GROUP_MIXED;
  Quiz[180].MyGroup = GROUP_MIXED;
  Quiz[181].MyGroup = GROUP_MIXED;
  Quiz[182].MyGroup = GROUP_MIXED;
  Quiz[183].MyGroup = GROUP_MIXED;
  Quiz[184].MyGroup = GROUP_MIXED;
  Quiz[185].MyGroup = GROUP_MIXED;
  Quiz[186].MyGroup = GROUP_MIXED;
  Quiz[187].MyGroup = GROUP_MIXED;
  Quiz[188].MyGroup = GROUP_MIXED;
  Quiz[189].MyGroup = GROUP_MIXED;
  Quiz[190].MyGroup = GROUP_MIXED;
  Quiz[191].MyGroup = GROUP_MIXED;
  Quiz[192].MyGroup = GROUP_MIXED;
  Quiz[193].MyGroup = GROUP_MIXED;
  Quiz[194].MyGroup = GROUP_MIXED;
  Quiz[195].MyGroup = GROUP_MIXED;
  Quiz[196].MyGroup = GROUP_MIXED;
  Quiz[197].MyGroup = GROUP_MIXED;
  Quiz[198].MyGroup = GROUP_MIXED;
  Quiz[199].MyGroup = GROUP_MIXED;
  Quiz[200].MyGroup = GROUP_MIXED;

  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Do you have an avid perseverance in gathering and/or cataloguing information on a topic of interest?";
  Quiz[2].Text = "Is it important for you to find a unique niche where you can acquire unique competence?";
  Quiz[3].Text = "Do you notice patterns in things all the time?";
  Quiz[4].Text = "Do you have one special talent which you have emphasised and worked on?";
  Quiz[5].Text = "Do you get confused by several verbal instructions at the same time?";
  Quiz[6].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[7].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[8].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[9].Text = "Do you have problems filling out forms?";
  Quiz[10].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[11].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[12].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[13].Text = "Are you easily distracted?";
  Quiz[14].Text = "If there is an interruption, can you  Quickly return to what you were doing before?";
  Quiz[15].Text = "Do you need a lot of motivation to do things?";
  Quiz[16].Text = "Do you have problems finding your way to new places?";
  Quiz[17].Text = "Do you work slowly on jobs you dislike?";
  Quiz[18].Text = "Do you have trouble reading clocks?";
  Quiz[19].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[20].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[21].Text = "Do you dislike when people walk behind you?";
  Quiz[22].Text = "Do you have certain routines which you need to follow?";
  Quiz[23].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[24].Text = "Are you bothered by clothes tags or light touch?";
  Quiz[25].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[26].Text = "Are you sometimes afraid in safe situations?";
  Quiz[27].Text = "Do you have extra sensitive hearing?";
  Quiz[28].Text = "Are your eyes extra sensitive to strong light and glare?";
  Quiz[29].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[30].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[31].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[32].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[33].Text = "Do you have problems with timing in conversations?";
  Quiz[34].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[35].Text = "Are you good at interpreting facial expressions?";
  Quiz[36].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  Quiz[37].Text = "Do you find it hard to tell the age of people?";
  Quiz[38].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[39].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[40].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[41].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[42].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[43].Text = "Do you fiddle with things?";
  Quiz[44].Text = "Do you mistake noises for voices?";
  Quiz[45].Text = "Have you been accused of staring?";
  Quiz[46].Text = "Do recently heard tunes or rhythms tend to stick and replay themselves repeatedly in your head?";
  Quiz[47].Text = "Have your thoughts ever been so vivid that you were worried other people would hear them?";
  Quiz[48].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[49].Text = "Do you enjoy spinning in circles?";
  Quiz[50].Text = "Do you have an urge to jump over things?";
  Quiz[51].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[52].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[53].Text = "Do you get a pleasurable tingling sensation in the head, scalp or back of the body in response to certain sounds?";
  Quiz[54].Text = "Do you talk to yourself?";
  Quiz[55].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  Quiz[56].Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  Quiz[57].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[58].Text = "Do others often misunderstand you?";
  Quiz[59].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[60].Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  Quiz[61].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[62].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[63].Text = "Is it hard for you to see why some things upset people so much?";
  Quiz[64].Text = "Do you tend to interpret things literally?";
  Quiz[65].Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  Quiz[66].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[67].Text = "Do you realize hours later that somebody that you have a romantic interest for actually showed interest for you, and then feel bad about the missed opportunity to connect?";
  Quiz[68].Text = "Do you have a monotonous voice?";
  Quiz[69].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  Quiz[70].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[71].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[72].Text = "Do you have an urge to learn the routines of people you know?";
  Quiz[73].Text = "Do you like to follow (walk behind) people you are attached to?";
  Quiz[74].Text = "Do you have an urge to observe the habits of humans and/or animals?";
  Quiz[75].Text = "Have people you formed strong attachments to taken advantage of you?";
  Quiz[76].Text = "Do you have unusual sexual preferences?";
  Quiz[77].Text = "Do you like to protect people you are attached to even when they didn't ask for it?";
  Quiz[78].Text = "Do you feel that you are a very special or unusual person?";
  Quiz[79].Text = "Do you examine the hair of people you like a lot?";
  Quiz[80].Text = "Do you have, or used to have, imaginary relationships?";
  Quiz[81].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[82].Text = "Do you have odd hair (for example multiple whorls, standing up when short or other peculiarities)?";
  Quiz[83].Text = "Do you prefer to construct your own set of spiritual beliefs rather than following existing religions / belief-systems?";
  Quiz[84].Text = "Are you more sexually attracted to strangers than to people you know well?";
  Quiz[85].Text = "Do you tend to get romantic feelings for people that persistently shows interest for you?";
  Quiz[86].Text = "Do you enjoy traditional dating?";
  Quiz[87].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[88].Text = "Are you asexual?";
  Quiz[89].Text = "Do you like tongue-kissing?";
  Quiz[90].Text = "Do you enjoy travel?";
  Quiz[91].Text = "Do you take pride in your appearance?";
  Quiz[92].Text = "Do you see your own activities as more important than other people's?";
  Quiz[93].Text = "Would you  Quickly become impatient and irritated if you would not find a solution to a problem?";
  Quiz[94].Text = "Do you usually find faults with opinions that you don't share?";
  Quiz[95].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[96].Text = "Do you feel as if you are being persecuted in some way?";
  Quiz[97].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[98].Text = "Will you abandon your friends if your activities or ideals clash?";
  Quiz[99].Text = "Do you obstruct others' plans?";
  Quiz[100].Text = "Do you feel irritated when one person disagrees with what everyone else in a group believes?";
  Quiz[101].Text = "Do you prefer to keep to yourself?";
  Quiz[102].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[103].Text = "Do you have a tendency to become stuck when asked  Questions in social situation?";
  Quiz[104].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[105].Text = "Are you good at team-work?";
  Quiz[106].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[107].Text = "Do you enjoy big events even if they are crowded?";
  Quiz[108].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[109].Text = "Do you stay away from situations where people might express affection for you?";
  Quiz[110].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[111].Text = "Do you find it easy to describe your feelings?";
  Quiz[112].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[113].Text = "Is it hard for you to approach somebody you are attracted to?";
  Quiz[114].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[115].Text = "Are you shy?";
  Quiz[116].Text = "Do you prefer to hug only a romantic partner?";
  Quiz[117].Text = "Is your sense of humor fairly conventional?";
  Quiz[118].Text = "Can you easily remember verbal instructions?";
  Quiz[119].Text = "Do you accept criticism, correction and direction?";
  Quiz[120].Text = "Do you find it easy to estimate the age of people?";

  Quiz[121].Text = "Can you sometimes be very distressed by a topic that others think of as trivial?";
  Quiz[122].Text = "When you are focused on an activity, can you not recall all the information you might need to make good decisions?";
  Quiz[123].Text = "Do you find social situations chaotic?";
  Quiz[124].Text = "Do you find engaging in stimming (e.g.,fidgeting, rocking) to be relaxing?";
  Quiz[125].Text = "Is it distressing to be unexpectedly pulled away from something you are engaged in?";
  Quiz[126].Text = "Do you find it difficult to engage in a task of no interest to you even if it is important?";
  Quiz[127].Text = "Do you accidentally say something others find offensive/ rude when you are focused on a task?";
  Quiz[128].Text = "Do you engage in activities you are passionate about to escape from anxiety?";
  Quiz[129].Text = "Do you find sudden unexpected disruptions to your attention startling?";
  Quiz[130].Text = "Do you focus on an incident for a substantial time (days) after the event?";
  Quiz[131].Text = "Do you find yourself getting stuck in loops of thought?";
  Quiz[132].Text = "Do you avoid talking because you cannot reliably predict how others will react, especially strangers?";
  Quiz[133].Text = "Can making a decision be so hard you get physically stuck?";
  Quiz[134].Text = "Are you passionate about a few topics at any one time in your life?";
  Quiz[135].Text = "Do you need a quiet and predictable environment for you to switch from one task to another easily?";
  Quiz[136].Text = "Do you find simultaneously holding eye contact and making a verbal conversation with another person uncomfortable?";
  Quiz[137].Text = "Do you tend to feel quite self-conscious unless you're deeply absorbed in a task?";
  Quiz[138].Text = "Do you find it easy to keep up with group discussions where everyone is speaking?";
  Quiz[139].Text = "Are you still fascinated by many of the things you were interested in when you were much younger?";
  Quiz[140].Text = "Do you find a problem you can't solve distressing and/or hard to put down?";
  Quiz[141].Text = "After a period of instability, do you need a quiet and predictable environment?";
  Quiz[142].Text = "Do you have trouble filtering out sounds when you are not doing something you're focused on?";
  Quiz[143].Text = "Do people tell you that you get fixated on things?";
  Quiz[144].Text = "Do you become highly anxious by focusing on the many possible situations that might occur at a future event?";
  Quiz[145].Text = "Do you find social interactions more comfortable if communicating about atopic of interest to you?";
  Quiz[146].Text = "Do you find it difficult to switch topics after engaging in an activity for a longtime?";

  Quiz[147].Text = "Do you get overwhelmed by things your body senses?";
  Quiz[148].Text = "Do you have strong urges to make certain movements, even if you don't want to?";
  Quiz[149].Text = "Can you spend hours trying to start doing something that you want to do, but you can't get started?";
  Quiz[150].Text = "Do people get mad at you when you don't act the way they expect you to?";
  Quiz[151].Text = "When other people suffer, do you feel it strongly?";
  Quiz[152].Text = "Do people tell you your experiences aren't real?";
  Quiz[153].Text = "Do you a hard time getting other people's attention when you're in a group?";
  Quiz[154].Text = "Do you practice what you want to say in conversations?";
  Quiz[155].Text = "Have you recently tended to over-react to situations?";
  Quiz[156].Text = "Have you recently experienced trembling (eg, in the hands)?";
  Quiz[157].Text = "Have you recently found yourself getting agitated?";
  Quiz[158].Text = "Have you recently been intolerant of anything that kept you from getting on with what you were doing?";
  Quiz[159].Text = "Have you recently felt that you were rather touchy?";
  Quiz[160].Text = "Do you feel that you have no interest to be with other people?";
  Quiz[161].Text = "Do you cry about nothing?";
  Quiz[162].Text = "Do you feel that people look at you oddly because of your appearance?";
  Quiz[163].Text = "Do you feel tense?";
  Quiz[164].Text = "Have you sensed that somebody was around you even when you couldn't see anybody?";
  Quiz[165].Text = "When you listen to music can you get so caught up in it that you don't notice anything else?";
  Quiz[166].Text = "Can you wander off into your thoughts so completely while doing a routine task that you actually forget what you are doing and a few minutes later find that you have finished it?";
  Quiz[167].Text = "Can things that might seem meaningless to others make sense to you?";
  Quiz[168].Text = "Are you often delighted by small things (like the colors in soap bubbles and the five pointed star shape that appears when you cut an apple across the core)?";
  Quiz[169].Text = "Can the sound of a voice be so fascinating to you that you can just go on listening to it?";
  Quiz[170].Text = "Have you had the experience of someone calling you or speaking your name and not being sure whether it was really happening or you were imagining it?";
  Quiz[171].Text = "Do you like clear, precise border?";
  Quiz[172].Text = "Are you always at least a bit on your guard?";
  Quiz[173].Text = "Do you expect other people to keep a certain distance?";
  Quiz[174].Text = "Do you have a clear and distinct sense of time?";
  Quiz[175].Text = "Do you spend more than half the day (daytime) fantasizing or daydreaming?";
  Quiz[176].Text = "Did you feel lonely as a child?";
  Quiz[177].Text = "Do you start fantasizing when things get boring?";
  Quiz[178].Text = "If you think about something cold, do you actually get cold?";
  Quiz[179].Text = "Do you feel that other people are watching you?";
  Quiz[180].Text = "Do you avoid going to places where there will be many people because you will get anxious?";
  Quiz[181].Text = "Do you get nervous when you have to make polite conversation?";
  Quiz[182].Text = "Do you feel uneasy talking to people you do not know well?";
  Quiz[183].Text = "Do you suddenly feel distracted by distant sounds that you are not normally aware of?";
  Quiz[184].Text = "Are your thoughts sometimes so strong that you can almost hear them?";
  Quiz[185].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[186].Text = "Do you forget what you are trying to say?";
  Quiz[187].Text = "Do you tend to wander off the topic when having a conversation?";
  Quiz[188].Text = "Are you poor at expressing your true feelings by the way you talk and look?";
  Quiz[189].Text = "Do you get concerned that friends or co-workers are not really loyal or trustworthy?";
  Quiz[190].Text = "Do you feel you have to be on your guard even with friends?";
  Quiz[191].Text = "Do you have to keep an eye out to stop people from taking advantage of you?";
  Quiz[192].Text = "Do people drop hints about you or say things with a double meaning?";
  Quiz[193].Text = "Are you sensitive to electromagnetic fields?";
  Quiz[194].Text = "I stare into the distance while I think of my loved one";
  Quiz[195].Text = "Are you so restless that it is hard to sit still?";
  Quiz[196].Text = "Do you obsess over people?";
  Quiz[197].Text = "Do you prefer to learn the character of a potential romantic partner through observation rather than conversation?";
  Quiz[198].Text = "Would you discuss relationship issues with your best friends?";
  Quiz[199].Text = "Do you worry your friend doesn't really like you?";
  Quiz[200].Text = "Do you dislike being hugged when you haven’t asked for it?";

}

/*##################  TQuizQ1::ProcessRow ##########################
*   Purpose....: Process row                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizQ1::ProcessRow(char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i, j;
    int val;
    int minval, maxval;
    int range;
    int count = 0;
    int year, month, day;
    int hour, min, sec;
    TDateTime *time;
    TQuizRow Row;
    int score = 0;
    int corr_count = 0;

    str++;

    ptr = str;
    for (fieldno = 0; ptr; fieldno++)
    {
        valstr = str;
        ptr = strstr(str, ";");
        if (ptr)
            *ptr = 0;

        str = ptr + 1;

        valstr++;

        switch (fieldno)
        {
            case 0:
                Row.ID = atol(valstr);
                break;

            case 1:
                Row.UserID = atol(valstr);
                break;

            case 2:
                break;

            case 3:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.LsbTime = time->GetLsb();
                Row.MsbTime = time->GetMsb();
                delete time;
                break;

            case 4:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.FilloutTime = time->GetLsb() - Row.LsbTime;
                delete time;
                break;

            case 5:
                Row.BirthYear = atoi(valstr);
                break;

            case 6:
                Row.BirthMonth = atoi(valstr);
                break;

            case 7:
                Row.Gender = atoi(valstr);
                break;

            case 8:
                Row.Country = atoi(valstr);
                break;

            case 9:
                 Row.Ancestry = atoi(valstr);
                 break;

            case 10:
                 Row.Aspie = atoi(valstr);
                 break;

            case 11:
                 Row.ADHD = atoi(valstr);
                 break;

            case 12:
                 Row.OCD = atoi(valstr);
                 break;

            case 13:
                 Row.Social = atoi(valstr);
                 break;

            case 14:
                 break;

            case 15:
                 Row.Score = atoi(valstr);
                 break;

            default:
                 i = fieldno - 16;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }
    AddRow(&Row);
}

/*##########################################################################
#
#   Name       : TQuizQ1::Load
#
#   Purpose....: Load data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ1::Load()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile file("raw\\aspie-quiz-q1.csv");
    char *ptr;

    size = file.Read(buf, MAX_IN_ROW);
    buf[size] = 0;
    ptr = strchr(buf, 0xd);
    if (ptr)
        *ptr = 0;

    pos += strlen(buf) + 1;
    file.SetPos(pos);

    while (size = file.Read(buf, MAX_IN_ROW))
    {
        buf[size] = 0;
        ptr = strchr(buf, 0xd);
        if (ptr)
            *ptr = 0;

        pos += strlen(buf) + 1;
        file.SetPos(pos);

        if (ptr)
            ProcessRow(buf);
    }
}
