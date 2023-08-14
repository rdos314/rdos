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
# QuizQ5.cpp
# Quiz class for Q5
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizQ5.h"

#define CI      1

#define MAX_IN_ROW              4096

/*##########################################################################
#
#   Name       : TQuizQ5::TQuizQ5
#
#   Purpose....: Constructor for TQuizQ5
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ5::TQuizQ5()
  : TQuiz(155)
{
    SetupTexts();
}

/*##########################################################################
#
#   Name       : TQuizQ5::~TQuizQ5
#
#   Purpose....: Destructor for TQuizQ5
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ5::~TQuizQ5()
{
}

/*##################  TQuizQ5::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ5::GetCatCount(int Question)
{
    return 3;
}

/*##################  TQuizQ5::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ5::GetQuizN()
{
    return 155;
}

/*##########################################################################
#
#   Name       : TQuizQ5::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ5::WriteName(TFile &File)
{
    File.Write("Q5");
}

/*##########################################################################
#
#   Name       : TQuizQ5::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ5::WriteLongName(TFile &File)
{
    File.Write("Q5");
}

/*##########################################################################
#
#   Name       : TQuizQ5::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ5::SetupTexts()
{
  ItemArr[0]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[1]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[2]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[3]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[4]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[5]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[6]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[7]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[8]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[9]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[10]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[11]->MyGroup = GROUP_NT_TALENT;
  ItemArr[12]->MyGroup = GROUP_NT_TALENT;
  ItemArr[13]->MyGroup = GROUP_NT_TALENT;
  ItemArr[14]->MyGroup = GROUP_NT_TALENT;
  ItemArr[15]->MyGroup = GROUP_NT_TALENT;
  ItemArr[16]->MyGroup = GROUP_NT_TALENT;
  ItemArr[17]->MyGroup = GROUP_NT_TALENT;
  ItemArr[18]->MyGroup = GROUP_NT_TALENT;
  ItemArr[19]->MyGroup = GROUP_NT_TALENT;
  ItemArr[20]->MyGroup = GROUP_NOT_USED;
  ItemArr[21]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[22]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[23]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[24]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[25]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[26]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[27]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[28]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[29]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[30]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[31]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[32]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[33]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[34]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[35]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[36]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[37]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[38]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[39]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[40]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[41]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[42]->MyGroup = GROUP_NOT_USED;
  ItemArr[43]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[44]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[45]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[46]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[47]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[48]->MyGroup = GROUP_ASPIE_NVC;  
  ItemArr[49]->MyGroup = GROUP_NT_NVC;  
  ItemArr[50]->MyGroup = GROUP_NT_NVC;
  ItemArr[51]->MyGroup = GROUP_NT_NVC;
  ItemArr[52]->MyGroup = GROUP_NT_NVC;
  ItemArr[53]->MyGroup = GROUP_NT_NVC;
  ItemArr[54]->MyGroup = GROUP_NT_NVC;
  ItemArr[55]->MyGroup = GROUP_NT_NVC;
  ItemArr[56]->MyGroup = GROUP_NT_NVC;
  ItemArr[57]->MyGroup = GROUP_NT_NVC;
  ItemArr[58]->MyGroup = GROUP_NT_NVC;
  ItemArr[59]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[60]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[61]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[62]->MyGroup = GROUP_NOT_USED;
  ItemArr[63]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[64]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[65]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[66]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[67]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[68]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[69]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[70]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[71]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[72]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[73]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[74]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[75]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[76]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[77]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[78]->MyGroup = GROUP_NT_RELATION;
  ItemArr[79]->MyGroup = GROUP_NT_RELATION;
  ItemArr[80]->MyGroup = GROUP_NT_RELATION;
  ItemArr[81]->MyGroup = GROUP_NT_RELATION;
  ItemArr[82]->MyGroup = GROUP_NT_RELATION;
  ItemArr[83]->MyGroup = GROUP_NT_RELATION;
  ItemArr[84]->MyGroup = GROUP_NT_RELATION;
  ItemArr[85]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[86]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[87]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[88]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[89]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[90]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[91]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[92]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[93]->MyGroup = GROUP_NOT_USED;
  ItemArr[94]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[95]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[96]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[97]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[98]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[99]->MyGroup = GROUP_NOT_USED;
  ItemArr[100]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[101]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[102]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[103]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[104]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[105]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[106]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[111]->MyGroup = GROUP_NOT_USED;
  ItemArr[112]->MyGroup = GROUP_NOT_USED;
  ItemArr[113]->MyGroup = GROUP_NOT_USED;
  ItemArr[114]->MyGroup = GROUP_NOT_USED;
  ItemArr[115]->MyGroup = GROUP_NOT_USED;
  ItemArr[116]->MyGroup = GROUP_NOT_USED;
  ItemArr[117]->MyGroup = GROUP_NOT_USED;
  ItemArr[118]->MyGroup = GROUP_NOT_USED;
  ItemArr[119]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[120]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[121]->MyGroup = GROUP_NOT_USED;
  ItemArr[122]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[123]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[124]->MyGroup = GROUP_NOT_USED;
  ItemArr[125]->MyGroup = GROUP_NOT_USED;
  ItemArr[126]->MyGroup = GROUP_NOT_USED;
  ItemArr[127]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[128]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[129]->MyGroup = GROUP_NOT_USED;
  ItemArr[130]->MyGroup = GROUP_NOT_USED;
  ItemArr[131]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[132]->MyGroup = GROUP_NOT_USED;
  ItemArr[133]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[134]->MyGroup = GROUP_NOT_USED;
  ItemArr[135]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[136]->MyGroup = GROUP_NOT_USED;
  ItemArr[137]->MyGroup = GROUP_NOT_USED;
  ItemArr[138]->MyGroup = GROUP_NOT_USED;
  ItemArr[139]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[140]->MyGroup = GROUP_NOT_USED;
  ItemArr[141]->MyGroup = GROUP_NOT_USED;
  ItemArr[142]->MyGroup = GROUP_NOT_USED;
  ItemArr[143]->MyGroup = GROUP_NOT_USED;
  ItemArr[144]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[145]->MyGroup = GROUP_NOT_USED;
  ItemArr[147]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[148]->MyGroup = GROUP_NT_NVC;
  ItemArr[151]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[152]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[153]->MyGroup = GROUP_NT_TALENT;
  ItemArr[154]->MyGroup = GROUP_NT_SOCIAL;

  ItemArr[0]->Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  ItemArr[1]->Text = "When you listen to music can you get so caught up in it that you don't notice anything else?";
  ItemArr[2]->Text = "Are you often delighted by small things (like the colors in soap bubbles and the five pointed star shape that appears when you cut an apple across the core)?";
  ItemArr[3]->Text = "Is it important for you to find a unique niche where you can acquire unique competence?";
  ItemArr[4]->Text = "Do you have an avid perseverance in gathering and/or cataloguing information on a topic of interest?";
  ItemArr[5]->Text = "Do you notice patterns in things all the time?";
  ItemArr[6]->Text = "Do you like to create routines for things you've figured out so you don't have to figure it out again?";
  ItemArr[7]->Text = "Do you have one special talent which you have emphasised and worked on?";
  ItemArr[8]->Text = "Can things that might seem meaningless to others make sense to you?";
  ItemArr[9]->Text = "Are you still fascinated by many of the things you were interested in when you were much younger?";
  ItemArr[10]->Text = "Do you prefer to construct your own set of spiritual beliefs rather than following existing religions / belief-systems?";
  ItemArr[11]->Text = "Do you get confused by several verbal instructions at the same time?";
  ItemArr[12]->Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  ItemArr[13]->Text = "Do you have problems filling out forms?";
  ItemArr[14]->Text = "Do you find it difficult to take notes in lectures?";
  ItemArr[15]->Text = "If there is an interruption, can you  quickly return to what you were doing before?";
  ItemArr[16]->Text = "Do you tend to wander off the topic when having a conversation?";
  ItemArr[17]->Text = "Do you need to do things yourself in order to remember them?";
  ItemArr[18]->Text = "Do you find it difficult to engage in a task of no interest to you even if it is important?";
  ItemArr[19]->Text = "Do you need a lot of motivation to do things?";
  ItemArr[20]->Text = "Do you get overwhelmed by things your body senses?";
  ItemArr[21]->Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  ItemArr[22]->Text = "Are your eyes extra sensitive to strong light and glare?";
  ItemArr[23]->Text = "Do you have extra sensitive hearing?";
  ItemArr[24]->Text = "Are you sensitive to changes in humidity and air pressure?";
  ItemArr[25]->Text = "Do you dislike it when people stamp their foot in the floor?";
  ItemArr[26]->Text = "Do you dislike when people walk behind you?";
  ItemArr[27]->Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  ItemArr[28]->Text = "Have you been talked into having sex even if you really didn't want to?";
  ItemArr[29]->Text = "Do you have problems with timing in conversations?";
  ItemArr[30]->Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  ItemArr[31]->Text = "Do you have difficulties judging distances, height, depth or speed?";
  ItemArr[32]->Text = "Do you find it hard to tell the age of people?";
  ItemArr[33]->Text = "Do you have problems finding your way to new places?";
  ItemArr[34]->Text = "Are you good at interpreting facial expressions?";
  ItemArr[35]->Text = "Do you have a good sense of time?";
  ItemArr[36]->Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  ItemArr[37]->Text = "Do you have trouble reading clocks?";
  ItemArr[38]->Text = "Do you recognize a lot of people?";
  ItemArr[39]->Text = "In conversations, do you use small sounds that others don't seem to use?";
  ItemArr[40]->Text = "Do you get a pleasurable tingling sensation in the head, scalp or back of the body in response to certain sounds?";
  ItemArr[41]->Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  ItemArr[42]->Text = "Do you find engaging in stimming (e.g.,fidgeting, rocking) to be relaxing?";
  ItemArr[43]->Text = "Do you have a fascination for slowly flowing water?";
  ItemArr[44]->Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  ItemArr[45]->Text = "Do you pace (e.g. when thinking or anxious)?";
  ItemArr[46]->Text = "Do you enjoy spinning in circles?";
  ItemArr[47]->Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  ItemArr[48]->Text = "Do you have an urge to jump over things?";
  ItemArr[49]->Text = "Do you tend to express your feelings in ways that may baffle others?";
  ItemArr[50]->Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  ItemArr[51]->Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  ItemArr[52]->Text = "Have you been accused of staring?";
  ItemArr[53]->Text = "Do others often misunderstand you?";
  ItemArr[54]->Text = "Do people sometimes think you are smiling at the wrong occasion?";
  ItemArr[55]->Text = "Is your sense of humor different from mainstream or considered odd?";
  ItemArr[56]->Text = "Is it hard for you to see why some things upset people so much?";
  ItemArr[57]->Text = "Do you tend to interpret things literally?";
  ItemArr[58]->Text = "Have others told you that you have an odd posture or gait?";
  ItemArr[59]->Text = "Do you have to keep an eye out to stop people from taking advantage of you?";
  ItemArr[60]->Text = "Do you like to follow (walk behind) people you are attached to?";
  ItemArr[61]->Text = "Do you feel as if you are being persecuted in some way?";
  ItemArr[62]->Text = "Do you have an urge to learn the routines of people you know?";
  ItemArr[63]->Text = "Do you spend more than half the day (daytime) fantasizing or daydreaming?";
  ItemArr[64]->Text = "Do you prefer to learn the character of a potential romantic partner through observation rather than conversation?";
  ItemArr[65]->Text = "Do you worry your friend doesn't really like you?";
  ItemArr[66]->Text = "Do you examine the hair of people you like a lot?";
  ItemArr[67]->Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  ItemArr[68]->Text = "Do you realize hours later that somebody that you have a romantic interest for actually showed interest for you, and then feel bad about the missed opportunity to connect?";
  ItemArr[69]->Text = "Do you have, or used to have, imaginary relationships?";
  ItemArr[70]->Text = "Have you experienced stronger than normal attachments to certain people?";
  ItemArr[71]->Text = "Do you have unusual sexual preferences?";
  ItemArr[72]->Text = "Do you stare into the distance while you think of your loved one?";
  ItemArr[73]->Text = "Did you feel lonely as a child?";
  ItemArr[74]->Text = "Have you sensed that somebody was around you even when you couldn't see anybody?";
  ItemArr[75]->Text = "Do you cry about nothing?";
  ItemArr[76]->Text = "Do you like to protect people you are attached to even when they didn't ask for it?";
  ItemArr[77]->Text = "Do you tend to get romantic feelings for people that persistently shows interest for you?";
  ItemArr[78]->Text = "Do you enjoy traditional dating?";
  ItemArr[79]->Text = "Do you find yourself at ease in romantic situations?";
  ItemArr[80]->Text = "Do you enjoy big events even if they are crowded?";
  ItemArr[81]->Text = "Do you like tongue-kissing?";
  ItemArr[82]->Text = "Do you enjoy travel?";
  ItemArr[83]->Text = "Do you naturally approach somebody you have an romantic interest for?";
  ItemArr[84]->Text = "Are you asexual?";
  ItemArr[85]->Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  ItemArr[86]->Text = "Will you abandon your friends if your activities or ideals clash?";
  ItemArr[87]->Text = "Do you have difficulty accepting criticism, correction, and direction?";
  ItemArr[88]->Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  ItemArr[89]->Text = "Do you usually find faults with opinions that you don't share?";
  ItemArr[90]->Text = "Do you see your own activities as more important than other people's?";
  ItemArr[91]->Text = "Do you feel irritated when one person disagrees with what everyone else in a group believes?";
  ItemArr[92]->Text = "Do you avoid talking because you cannot reliably predict how others will react, especially strangers?";
  ItemArr[93]->Text = "Do you find social situations chaotic?";
  ItemArr[94]->Text = "Has it been harder for you than for others to keep friends?";
  ItemArr[95]->Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  ItemArr[96]->Text = "Do you feel you have to be on your guard even with friends?";
  ItemArr[97]->Text = "Do you practice what you want to say in conversations?";
  ItemArr[98]->Text = "Do you dislike being hugged when you haven't asked for it?";
  ItemArr[99]->Text = "Do you find it hard to be emotionally close to other people?";
  ItemArr[100]->Text = "Do you find it easy to describe your feelings?";
  ItemArr[101]->Text = "Are you good at team-work?";
  ItemArr[102]->Text = "Do you dislike it when people drop by to visit you uninvited?";
  ItemArr[103]->Text = "Do you find it easy to keep up with group discussions where everyone is speaking?";
  ItemArr[104]->Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  ItemArr[105]->Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  ItemArr[106]->Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  ItemArr[107]->Text = "Is your sense of humor fairly conventional?";
  ItemArr[108]->Text = "Can you easily remember verbal instructions?";
  ItemArr[109]->Text = "Do you find it easy to estimate the age of people?";
  ItemArr[110]->Text = "Do you accept criticism, correction and direction?";
  ItemArr[111]->Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  ItemArr[112]->Text = "Do you find it very hard to learn things that you are not interested in?";
  ItemArr[113]->Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  ItemArr[114]->Text = "Are you easily distracted?";
  ItemArr[115]->Text = "Do you work slowly on jobs you dislike?";
  ItemArr[116]->Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  ItemArr[117]->Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  ItemArr[118]->Text = "Do you have certain routines which you need to follow?";
  ItemArr[119]->Text = "Are you bothered by clothes tags or light touch?";
  ItemArr[120]->Text = "Are you sometimes afraid in safe situations?";
  ItemArr[121]->Text = "Do you need lists and schedules in order to get things done?";
  ItemArr[122]->Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  ItemArr[123]->Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  ItemArr[124]->Text = "Do you fiddle with things?";
  ItemArr[125]->Text = "Do you mistake noises for voices?";
  ItemArr[126]->Text = "Do recently heard tunes or rhythms tend to stick and replay themselves repeatedly in your head?";
  ItemArr[127]->Text = "Have your thoughts ever been so vivid that you were worried other people would hear them?";
  ItemArr[128]->Text = "Do you talk to yourself?";
  ItemArr[129]->Text = "Do you forget you are in a social situation when something gets your attention?";
  ItemArr[130]->Text = "Do you have a monotonous voice?";
  ItemArr[131]->Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  ItemArr[132]->Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  ItemArr[133]->Text = "Do you have an urge to observe the habits of humans and/or animals?";
  ItemArr[134]->Text = "Have people you formed strong attachments to taken advantage of you?";
  ItemArr[135]->Text = "Do you feel that you are a very special or unusual person?";
  ItemArr[136]->Text = "Do you have odd hair (for example multiple whorls, standing up when short or other peculiarities)?";
  ItemArr[137]->Text = "Are you more sexually attracted to strangers than to people you know well?";
  ItemArr[138]->Text = "Do you take pride in your appearance?";
  ItemArr[139]->Text = "Would you quickly become impatient and irritated if you would not find a solution to a problem?";
  ItemArr[140]->Text = "Do you obstruct others' plans?";
  ItemArr[141]->Text = "Do you prefer to keep to yourself?";
  ItemArr[142]->Text = "Do you have a tendency to become stuck when asked questions in social situation";
  ItemArr[143]->Text = "Do you stay away from situations where people might express affection for you?";
  ItemArr[144]->Text = "Are you shy?";
  ItemArr[145]->Text = "Do you prefer to hug only a romantic partner?";
  ItemArr[146]->Text = "Do you spend hours overthinking and re-enacting negative social interaction?";
  ItemArr[147]->Text = "Do you tend to play the same tune many times in a row?";
  ItemArr[148]->Text = "Do you fail to understand pop culture, things like 'being in style' or why people jump onto the latest trend?";
  ItemArr[149]->Text = "Do you like to have small talk before getting on to the important topics in a conversation?";
  ItemArr[150]->Text = "Do you enjoy to wear things out of style?";
  ItemArr[151]->Text = "Do you have obsessive attachments to animate objects?";
  ItemArr[152]->Text = "Do you notice odors that other people don't seem to notice?";
  ItemArr[153]->Text = "Is is difficult to pass on messages correctly?";
  ItemArr[154]->Text = "Do you need to prepare yourself mentally before going somewhere?";

}

/*##################  TQuizQ5::ProcessRow ##########################
*   Purpose....: Process row                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizQ5::ProcessRow(char *str)
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
#   Name       : TQuizQ5::Load
#
#   Purpose....: Load data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ5::Load()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile file("raw\\aspie-quiz-Q5.csv");
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
