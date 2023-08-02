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
# QuizQ2.cpp
# Quiz class for Q2
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizQ2.h"

#define CI      1

#define MAX_IN_ROW              4096

/*##########################################################################
#
#   Name       : TQuizQ2::TQuizQ2
#
#   Purpose....: Constructor for TQuizQ2
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ2::TQuizQ2()
  : TQuiz(170)
{
    SetupTexts();
}

/*##########################################################################
#
#   Name       : TQuizQ2::~TQuizQ2
#
#   Purpose....: Destructor for TQuizQ2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ2::~TQuizQ2()
{
}

/*##################  TQuizQ2::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ2::GetCatCount(int Question)
{
    return 3;
}

/*##################  TQuizQ2::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ2::GetQuizN()
{
    return 170;
}

/*##########################################################################
#
#   Name       : TQuizQ2::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ2::WriteName(TFile &File)
{
    File.Write("Q2");
}

/*##########################################################################
#
#   Name       : TQuizQ2::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ2::WriteLongName(TFile &File)
{
    File.Write("Q2");
}

/*##########################################################################
#
#   Name       : TQuizQ2::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ2::SetupTexts()
{
  ItemArr[0]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[1]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[2]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[4]->MyGroup = GROUP_ASPIE_TALENT;
  ItemArr[5]->MyGroup = GROUP_NT_TALENT;
  ItemArr[6]->MyGroup = GROUP_NT_TALENT;
  ItemArr[7]->MyGroup = GROUP_NT_TALENT;
  ItemArr[8]->MyGroup = GROUP_NT_TALENT;
  ItemArr[9]->MyGroup = GROUP_NT_TALENT;
  ItemArr[11]->MyGroup = GROUP_NT_TALENT;
  ItemArr[12]->MyGroup = GROUP_NT_TALENT;
  ItemArr[13]->MyGroup = GROUP_NT_TALENT;
  ItemArr[15]->MyGroup = GROUP_NT_TALENT;
  ItemArr[16]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[17]->MyGroup = GROUP_NT_TALENT;
  ItemArr[18]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[19]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[20]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[21]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[22]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[23]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[24]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[25]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[26]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[27]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[28]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[29]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[30]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[31]->MyGroup = GROUP_ASPIE_SENSORY;
  ItemArr[33]->MyGroup = GROUP_NT_NVC;
  ItemArr[34]->MyGroup = GROUP_NT_NVC;
  ItemArr[35]->MyGroup = GROUP_NT_NVC;
  ItemArr[36]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[37]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[38]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[39]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[41]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[42]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[43]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[44]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[46]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[48]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[49]->MyGroup = GROUP_ASPIE_NVC;  
  ItemArr[50]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[51]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[52]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[53]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[54]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[55]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[56]->MyGroup = GROUP_NT_NVC;
  ItemArr[57]->MyGroup = GROUP_NT_NVC;
  ItemArr[58]->MyGroup = GROUP_NT_NVC;
  ItemArr[60]->MyGroup = GROUP_NT_NVC;
  ItemArr[61]->MyGroup = GROUP_NT_NVC;
  ItemArr[63]->MyGroup = GROUP_NT_NVC;
  ItemArr[64]->MyGroup = GROUP_NT_NVC;
  ItemArr[65]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[66]->MyGroup = GROUP_NT_NVC;
  ItemArr[67]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[68]->MyGroup = GROUP_NT_NVC;
  ItemArr[69]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[70]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[71]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[72]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[74]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[75]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[76]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[77]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[83]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[85]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[86]->MyGroup = GROUP_NT_RELATION;
  ItemArr[87]->MyGroup = GROUP_NT_RELATION;
  ItemArr[88]->MyGroup = GROUP_NT_RELATION;
  ItemArr[89]->MyGroup = GROUP_NT_RELATION;
  ItemArr[90]->MyGroup = GROUP_NT_RELATION;
  ItemArr[91]->MyGroup = GROUP_NT_RELATION;
  ItemArr[92]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[94]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[95]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[97]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[98]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[99]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[100]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[101]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[103]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[104]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[106]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[108]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[110]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[112]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[113]->MyGroup = GROUP_NT_RELATION;
  ItemArr[115]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[116]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[122]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[123]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[124]->MyGroup = GROUP_NT_TALENT;
  ItemArr[127]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[128]->MyGroup = GROUP_NT_TALENT;
  ItemArr[137]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[138]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[139]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[141]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[150]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[155]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[158]->MyGroup = GROUP_NT_TALENT;
  ItemArr[159]->MyGroup = GROUP_NT_TALENT;
  ItemArr[164]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[165]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[166]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[167]->MyGroup = GROUP_ASPIE_RELATION;

  ItemArr[0]->Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  ItemArr[1]->Text = "Do you have an avid perseverance in gathering and/or cataloguing information on a topic of interest?";
  ItemArr[2]->Text = "Is it important for you to find a unique niche where you can acquire unique competence?";
  ItemArr[3]->Text = "Do you notice patterns in things all the time?";
  ItemArr[4]->Text = "Do you have one special talent which you have emphasised and worked on?";
  ItemArr[5]->Text = "Do you get confused by several verbal instructions at the same time?";
  ItemArr[6]->Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  ItemArr[7]->Text = "Do you find it very hard to learn things that you are not interested in?";
  ItemArr[8]->Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  ItemArr[9]->Text = "Do you have problems filling out forms?";
  ItemArr[10]->Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  ItemArr[11]->Text = "Do you find it difficult to take notes in lectures?";
  ItemArr[12]->Text = "Do you need to do things yourself in order to remember them?";
  ItemArr[13]->Text = "Are you easily distracted?";
  ItemArr[14]->Text = "If there is an interruption, can you  Quickly return to what you were doing before?";
  ItemArr[15]->Text = "Do you need a lot of motivation to do things?";
  ItemArr[16]->Text = "Do you have problems finding your way to new places?";
  ItemArr[17]->Text = "Do you work slowly on jobs you dislike?";
  ItemArr[18]->Text = "Do you have trouble reading clocks?";
  ItemArr[19]->Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  ItemArr[20]->Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  ItemArr[21]->Text = "Do you dislike when people walk behind you?";
  ItemArr[22]->Text = "Do you have certain routines which you need to follow?";
  ItemArr[23]->Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  ItemArr[24]->Text = "Are you bothered by clothes tags or light touch?";
  ItemArr[25]->Text = "Are you sensitive to changes in humidity and air pressure?";
  ItemArr[26]->Text = "Are you sometimes afraid in safe situations?";
  ItemArr[27]->Text = "Do you have extra sensitive hearing?";
  ItemArr[28]->Text = "Are your eyes extra sensitive to strong light and glare?";
  ItemArr[29]->Text = "Do you dislike it when people stamp their foot in the floor?";
  ItemArr[30]->Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  ItemArr[31]->Text = "Do you need lists and schedules in order to get things done?";
  ItemArr[32]->Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  ItemArr[33]->Text = "Do you have problems with timing in conversations?";
  ItemArr[34]->Text = "Do you have problems recognizing faces (prosopagnosia)?";
  ItemArr[35]->Text = "Are you good at interpreting facial expressions?";
  ItemArr[36]->Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  ItemArr[37]->Text = "Do you find it hard to tell the age of people?";
  ItemArr[38]->Text = "Do you have difficulties judging distances, height, depth or speed?";
  ItemArr[39]->Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  ItemArr[40]->Text = "In conversations, do you use small sounds that others don't seem to use?";
  ItemArr[41]->Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  ItemArr[42]->Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  ItemArr[43]->Text = "Do you fiddle with things?";
  ItemArr[44]->Text = "Do you mistake noises for voices?";
  ItemArr[45]->Text = "Have you been accused of staring?";
  ItemArr[46]->Text = "Do recently heard tunes or rhythms tend to stick and replay themselves repeatedly in your head?";
  ItemArr[47]->Text = "Have your thoughts ever been so vivid that you were worried other people would hear them?";
  ItemArr[48]->Text = "Do you have a fascination for slowly flowing water?";
  ItemArr[49]->Text = "Do you enjoy spinning in circles?";
  ItemArr[50]->Text = "Do you have an urge to jump over things?";
  ItemArr[51]->Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  ItemArr[52]->Text = "Do you pace (e.g. when thinking or anxious)?";
  ItemArr[53]->Text = "Do you get a pleasurable tingling sensation in the head, scalp or back of the body in response to certain sounds?";
  ItemArr[54]->Text = "Do you talk to yourself?";
  ItemArr[55]->Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  ItemArr[56]->Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  ItemArr[57]->Text = "Do you tend to express your feelings in ways that may baffle others?";
  ItemArr[58]->Text = "Do others often misunderstand you?";
  ItemArr[59]->Text = "Is your sense of humor different from mainstream or considered odd?";
  ItemArr[60]->Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  ItemArr[61]->Text = "Do people sometimes think you are smiling at the wrong occasion?";
  ItemArr[62]->Text = "Do you forget you are in a social situation when something gets your attention?";
  ItemArr[63]->Text = "Is it hard for you to see why some things upset people so much?";
  ItemArr[64]->Text = "Do you tend to interpret things literally?";
  ItemArr[65]->Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  ItemArr[66]->Text = "Have others told you that you have an odd posture or gait?";
  ItemArr[67]->Text = "Do you realize hours later that somebody that you have a romantic interest for actually showed interest for you, and then feel bad about the missed opportunity to connect?";
  ItemArr[68]->Text = "Do you have a monotonous voice?";
  ItemArr[69]->Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  ItemArr[70]->Text = "Have you experienced stronger than normal attachments to certain people?";
  ItemArr[71]->Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  ItemArr[72]->Text = "Do you have an urge to learn the routines of people you know?";
  ItemArr[73]->Text = "Do you like to follow (walk behind) people you are attached to?";
  ItemArr[74]->Text = "Do you have an urge to observe the habits of humans and/or animals?";
  ItemArr[75]->Text = "Have people you formed strong attachments to taken advantage of you?";
  ItemArr[76]->Text = "Do you have unusual sexual preferences?";
  ItemArr[77]->Text = "Do you like to protect people you are attached to even when they didn't ask for it?";
  ItemArr[78]->Text = "Do you feel that you are a very special or unusual person?";
  ItemArr[79]->Text = "Do you examine the hair of people you like a lot?";
  ItemArr[80]->Text = "Do you have, or used to have, imaginary relationships?";
  ItemArr[81]->Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  ItemArr[82]->Text = "Do you have odd hair (for example multiple whorls, standing up when short or other peculiarities)?";
  ItemArr[83]->Text = "Do you prefer to construct your own set of spiritual beliefs rather than following existing religions / belief-systems?";
  ItemArr[84]->Text = "Are you more sexually attracted to strangers than to people you know well?";
  ItemArr[85]->Text = "Do you tend to get romantic feelings for people that persistently shows interest for you?";
  ItemArr[86]->Text = "Do you enjoy traditional dating?";
  ItemArr[87]->Text = "Do you find yourself at ease in romantic situations?";
  ItemArr[88]->Text = "Are you asexual?";
  ItemArr[89]->Text = "Do you like tongue-kissing?";
  ItemArr[90]->Text = "Do you enjoy travel?";
  ItemArr[91]->Text = "Do you take pride in your appearance?";
  ItemArr[92]->Text = "Do you see your own activities as more important than other people's?";
  ItemArr[93]->Text = "Would you  Quickly become impatient and irritated if you would not find a solution to a problem?";
  ItemArr[94]->Text = "Do you usually find faults with opinions that you don't share?";
  ItemArr[95]->Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  ItemArr[96]->Text = "Do you feel as if you are being persecuted in some way?";
  ItemArr[97]->Text = "Do you have difficulty accepting criticism, correction, and direction?";
  ItemArr[98]->Text = "Will you abandon your friends if your activities or ideals clash?";
  ItemArr[99]->Text = "Do you obstruct others' plans?";
  ItemArr[100]->Text = "Do you feel irritated when one person disagrees with what everyone else in a group believes?";
  ItemArr[101]->Text = "Do you prefer to keep to yourself?";
  ItemArr[102]->Text = "Do you find it hard to be emotionally close to other people?";
  ItemArr[103]->Text = "Do you have a tendency to become stuck when asked  Questions in social situation?";
  ItemArr[104]->Text = "Has it been harder for you than for others to keep friends?";
  ItemArr[105]->Text = "Are you good at team-work?";
  ItemArr[106]->Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  ItemArr[107]->Text = "Do you enjoy big events even if they are crowded?";
  ItemArr[108]->Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  ItemArr[109]->Text = "Do you stay away from situations where people might express affection for you?";
  ItemArr[110]->Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  ItemArr[111]->Text = "Do you find it easy to describe your feelings?";
  ItemArr[112]->Text = "Do you dislike it when people drop by to visit you uninvited?";
  ItemArr[113]->Text = "Is it hard for you to approach somebody you are attracted to?";
  ItemArr[114]->Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  ItemArr[115]->Text = "Are you shy?";
  ItemArr[116]->Text = "Do you prefer to hug only a romantic partner?";
  ItemArr[117]->Text = "Is your sense of humor fairly conventional?";
  ItemArr[118]->Text = "Can you easily remember verbal instructions?";
  ItemArr[119]->Text = "Do you accept criticism, correction and direction?";
  ItemArr[120]->Text = "Do you find it easy to estimate the age of people?";

  ItemArr[121]->Text = "Can you sometimes be very distressed by a topic that others think of as trivial?";
  ItemArr[122]->Text = "Do you find social situations chaotic?";
  ItemArr[123]->Text = "Do you find engaging in stimming (e.g.,fidgeting, rocking) to be relaxing?";
  ItemArr[124]->Text = "Do you find it difficult to engage in a task of no interest to you even if it is important?";
  ItemArr[125]->Text = "Do you find sudden unexpected disruptions to your attention startling?";
  ItemArr[126]->Text = "Do you find yourself getting stuck in loops of thought?";
  ItemArr[127]->Text = "Do you avoid talking because you cannot reliably predict how others will react, especially strangers?";
  ItemArr[128]->Text = "Can making a decision be so hard you get physically stuck?";
  ItemArr[129]->Text = "Do you need a quiet and predictable environment for you to switch from one task to another easily?";
  ItemArr[130]->Text = "Do you find simultaneously holding eye contact and making a verbal conversation with another person uncomfortable?";
  ItemArr[131]->Text = "Do you tend to feel quite self-conscious unless you're deeply absorbed in a task?";
  ItemArr[132]->Text = "Do you find it easy to keep up with group discussions where everyone is speaking?";
  ItemArr[133]->Text = "Are you still fascinated by many of the things you were interested in when you were much younger?";
  ItemArr[134]->Text = "Do you find a problem you can't solve distressing and/or hard to put down?";
  ItemArr[135]->Text = "Do you find it difficult to switch topics after engaging in an activity for a longtime?";
  ItemArr[136]->Text = "Do you get overwhelmed by things your body senses?";
  ItemArr[137]->Text = "Do you a hard time getting other people's attention when you're in a group?";
  ItemArr[138]->Text = "Do you practice what you want to say in conversations?";
  ItemArr[139]->Text = "Have you recently experienced trembling (eg, in the hands)?";
  ItemArr[140]->Text = "Have you recently felt that you were rather touchy?";
  ItemArr[141]->Text = "Do you feel that you have no interest to be with other people?";
  ItemArr[142]->Text = "Do you cry about nothing?";
  ItemArr[143]->Text = "Have you sensed that somebody was around you even when you couldn't see anybody?";
  ItemArr[144]->Text = "When you listen to music can you get so caught up in it that you don't notice anything else?";
  ItemArr[145]->Text = "Can you wander off into your thoughts so completely while doing a routine task that you actually forget what you are doing and a few minutes later find that you have finished it?";
  ItemArr[146]->Text = "Can things that might seem meaningless to others make sense to you?";
  ItemArr[147]->Text = "Are you often delighted by small things (like the colors in soap bubbles and the five pointed star shape that appears when you cut an apple across the core)?";
  ItemArr[148]->Text = "Can the sound of a voice be so fascinating to you that you can just go on listening to it?";
  ItemArr[149]->Text = "Have you had the experience of someone calling you or speaking your name and not being sure whether it was really happening or you were imagining it?";
  ItemArr[150]->Text = "Do you have a clear and distinct sense of time?";
  ItemArr[151]->Text = "Do you spend more than half the day (daytime) fantasizing or daydreaming?";
  ItemArr[152]->Text = "Did you feel lonely as a child?";
  ItemArr[153]->Text = "If you think about something cold, do you actually get cold?";
  ItemArr[154]->Text = "Do you feel that other people are watching you?";
  ItemArr[155]->Text = "Do you get nervous when you have to make polite conversation?";
  ItemArr[156]->Text = "Do you suddenly feel distracted by distant sounds that you are not normally aware of?";
  ItemArr[157]->Text = "Are your thoughts sometimes so strong that you can almost hear them?";
  ItemArr[158]->Text = "Do you forget what you are trying to say?";
  ItemArr[159]->Text = "Do you tend to wander off the topic when having a conversation?";
  ItemArr[160]->Text = "Are you good at expressing your true feelings by the way you talk and look?";
  ItemArr[161]->Text = "Do you feel you have to be on your guard even with friends?";
  ItemArr[162]->Text = "Do you have to keep an eye out to stop people from taking advantage of you?";
  ItemArr[163]->Text = "Are you sensitive to electromagnetic fields?";
  ItemArr[164]->Text = "I stare into the distance while I think of my loved one";
  ItemArr[165]->Text = "Are you so restless that it is hard to sit still?";
  ItemArr[166]->Text = "Do you obsess over people?";
  ItemArr[167]->Text = "Do you prefer to learn the character of a potential romantic partner through observation rather than conversation?";
  ItemArr[168]->Text = "Do you worry your friend doesn't really like you?";
  ItemArr[169]->Text = "Do you dislike being hugged when you haven’t asked for it?";

}

/*##################  TQuizQ2::ProcessRow ##########################
*   Purpose....: Process row                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizQ2::ProcessRow(char *str)
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
#   Name       : TQuizQ2::Load
#
#   Purpose....: Load data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ2::Load()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile file("raw\\aspie-quiz-q2.csv");
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
