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
# QuizQ8.cpp
# Quiz class for Q8
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizQ8.h"

#define CI      1

#define MAX_IN_ROW              4096

/*##########################################################################
#
#   Name       : TQuizQ8::TQuizQ8
#
#   Purpose....: Constructor for TQuizQ8
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ8::TQuizQ8()
  : TQuiz(163)
{
    SetupTexts();
}

/*##########################################################################
#
#   Name       : TQuizQ8::~TQuizQ8
#
#   Purpose....: Destructor for TQuizQ8
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizQ8::~TQuizQ8()
{
}

/*##################  TQuizQ8::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ8::GetCatCount(int Question)
{
    return 3;
}

/*##################  TQuizQ8::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizQ8::GetQuizN()
{
    return 119;
}

/*##########################################################################
#
#   Name       : TQuizQ8::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ8::WriteName(TFile &File)
{
    File.Write("Q8");
}

/*##########################################################################
#
#   Name       : TQuizQ8::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ8::WriteLongName(TFile &File)
{
    File.Write("Q8");
}

/*##########################################################################
#
#   Name       : TQuizQ8::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ8::SetupTexts()
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
  ItemArr[20]->MyGroup = GROUP_NT_TALENT;
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
  ItemArr[31]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[32]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[33]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[34]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[35]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[36]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[37]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[38]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[39]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[40]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[41]->MyGroup = GROUP_NT_SENSORY;
  ItemArr[42]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[43]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[44]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[45]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[46]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[47]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[48]->MyGroup = GROUP_ASPIE_NVC;  
  ItemArr[49]->MyGroup = GROUP_ASPIE_NVC;  
  ItemArr[50]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[51]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[52]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[53]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[54]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[55]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[56]->MyGroup = GROUP_ASPIE_NVC;
  ItemArr[57]->MyGroup = GROUP_NT_NVC;
  ItemArr[58]->MyGroup = GROUP_NT_NVC;
  ItemArr[59]->MyGroup = GROUP_NT_NVC;
  ItemArr[60]->MyGroup = GROUP_NT_NVC;
  ItemArr[61]->MyGroup = GROUP_NT_NVC;
  ItemArr[62]->MyGroup = GROUP_NT_NVC;
  ItemArr[63]->MyGroup = GROUP_NT_NVC;
  ItemArr[64]->MyGroup = GROUP_NT_NVC;
  ItemArr[65]->MyGroup = GROUP_NT_NVC;
  ItemArr[66]->MyGroup = GROUP_NT_NVC;
  ItemArr[67]->MyGroup = GROUP_NT_NVC;
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
  ItemArr[78]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[79]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[80]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[81]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[82]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[83]->MyGroup = GROUP_ASPIE_RELATION;
  ItemArr[84]->MyGroup = GROUP_NT_RELATION;
  ItemArr[85]->MyGroup = GROUP_NT_RELATION;
  ItemArr[86]->MyGroup = GROUP_NT_RELATION;
  ItemArr[87]->MyGroup = GROUP_NT_RELATION;
  ItemArr[88]->MyGroup = GROUP_NT_RELATION;
  ItemArr[89]->MyGroup = GROUP_NT_RELATION;
  ItemArr[90]->MyGroup = GROUP_NT_RELATION;
  ItemArr[91]->MyGroup = GROUP_NT_RELATION;
  ItemArr[92]->MyGroup = GROUP_NT_RELATION;
  ItemArr[93]->MyGroup = GROUP_NT_RELATION;
  ItemArr[94]->MyGroup = GROUP_NT_RELATION;
  ItemArr[95]->MyGroup = GROUP_NT_RELATION;
  ItemArr[96]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[97]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[98]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[99]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[100]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[101]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[102]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[103]->MyGroup = GROUP_ASPIE_SOCIAL;
  ItemArr[104]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[105]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[106]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[107]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[108]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[109]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[110]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[111]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[112]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[113]->MyGroup = GROUP_NT_SOCIAL;
  ItemArr[114]->MyGroup = GROUP_NT_SOCIAL;

  ItemArr[0]->Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  ItemArr[1]->Text = "Do you have an avid perseverance in gathering and/or cataloguing information on a topic of interest?";
  ItemArr[2]->Text = "Is it important for you to find a unique niche where you can acquire unique competence?";
  ItemArr[3]->Text = "Do you have an urge to observe the habits of humans and/or animals?";
  ItemArr[4]->Text = "Do you notice patterns in things all the time?";
  ItemArr[5]->Text = "Do you have one special talent which you have emphasised and worked on?";
  ItemArr[6]->Text = "Do you like to create routines for things you've figured out so you don't have to figure it out again?";
  ItemArr[7]->Text = "Do you feel that you are a very special or unusual person?";
  ItemArr[8]->Text = "Can things that might seem meaningless to others make sense to you?";
  ItemArr[9]->Text = "Are you still fascinated by many of the things you were interested in when you were much younger?";
  ItemArr[10]->Text = "Do you prefer to construct your own set of spiritual beliefs rather than following existing religions / belief-systems?";
  ItemArr[11]->Text = "Is is difficult to pass on messages correctly?";
  ItemArr[12]->Text = "Do you get confused by several verbal instructions at the same time?";
  ItemArr[13]->Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  ItemArr[14]->Text = "Do you tend to wander off the topic when having a conversation?";
  ItemArr[15]->Text = "Do you have problems filling out forms?";
  ItemArr[16]->Text = "Do you find it difficult to take notes in lectures?";
  ItemArr[17]->Text = "If there is an interruption, can you  quickly return to what you were doing before?";
  ItemArr[18]->Text = "Do you need to do things yourself in order to remember them?";
  ItemArr[19]->Text = "Do you find it difficult to engage in a task of no interest to you even if it is important?";
  ItemArr[20]->Text = "Do you need a lot of motivation to do things?";
  ItemArr[21]->Text = "Are you bothered by clothes tags or light touch?";
  ItemArr[22]->Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  ItemArr[23]->Text = "Are your eyes extra sensitive to strong light and glare?";
  ItemArr[24]->Text = "Do you dislike when people walk behind you?";
  ItemArr[25]->Text = "Do you have extra sensitive hearing?";
  ItemArr[26]->Text = "Are you sensitive to changes in humidity and air pressure?";
  ItemArr[27]->Text = "Do you dislike being hugged when you haven't asked for it?";
  ItemArr[28]->Text = "Do you dislike it when people stamp their foot in the floor?";
  ItemArr[29]->Text = "Do you notice odors that other people don't seem to notice?";
  ItemArr[30]->Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  ItemArr[31]->Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  ItemArr[32]->Text = "Do you have problems with timing in conversations?";
  ItemArr[33]->Text = "Do you have difficulties judging distances, height, depth or speed?";
  ItemArr[34]->Text = "Do you have problems finding your way to new places?";
  ItemArr[35]->Text = "Do you find it hard to tell the age of people?";
  ItemArr[36]->Text = "Are you good at interpreting facial expressions?";
  ItemArr[37]->Text = "Do you have a good sense of time?";
  ItemArr[38]->Text = "Do you find it easy to describe your feelings?";
  ItemArr[39]->Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  ItemArr[40]->Text = "Do you have trouble reading clocks?";
  ItemArr[41]->Text = "Do you recognize a lot of people?";
  ItemArr[42]->Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  ItemArr[43]->Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  ItemArr[44]->Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  ItemArr[45]->Text = "Do you have obsessive attachments to animate objects?";
  ItemArr[46]->Text = "Are you often delighted by small things (like the colors in soap bubbles and the five pointed star shape that appears when you cut an apple across the core)?";
  ItemArr[47]->Text = "When you listen to music can you get so caught up in it that you don't notice anything else?";
  ItemArr[48]->Text = "Do you like to follow (walk behind) people you are attached to?";
  ItemArr[49]->Text = "Do you have a fascination for slowly flowing water?";
  ItemArr[50]->Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  ItemArr[51]->Text = "Do you pace (e.g. when thinking or anxious)?";
  ItemArr[52]->Text = "Do you examine the hair of people you like a lot?";
  ItemArr[53]->Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  ItemArr[54]->Text = "Do you enjoy spinning in circles?";
  ItemArr[55]->Text = "Do you tend to play the same tune many times in a row?";
  ItemArr[56]->Text = "Do you have an urge to jump over things?";
  ItemArr[57]->Text = "Do you tend to express your feelings in ways that may baffle others?";
  ItemArr[58]->Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  ItemArr[59]->Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  ItemArr[60]->Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  ItemArr[61]->Text = "Do others often misunderstand you?";
  ItemArr[62]->Text = "Do people sometimes think you are smiling at the wrong occasion?";
  ItemArr[63]->Text = "Is your sense of humor different from mainstream or considered odd?";
  ItemArr[64]->Text = "Have others told you that you have an odd posture or gait?";
  ItemArr[65]->Text = "Do you tend to interpret things literally?";
  ItemArr[66]->Text = "Is it hard for you to see why some things upset people so much?";
  ItemArr[67]->Text = "Do you fail to understand pop culture, things like 'being in style' or why people jump onto the latest trend?";
  ItemArr[68]->Text = "Have you been accused of staring?";
  ItemArr[69]->Text = "Do you have to keep an eye out to stop people from taking advantage of you?";
  ItemArr[70]->Text = "Do you feel as if you are being persecuted in some way?";
  ItemArr[71]->Text = "Have you experienced stronger than normal attachments to certain people?";
  ItemArr[72]->Text = "Have you sensed that somebody was around you even when you couldn't see anybody?";
  ItemArr[73]->Text = "Do you worry your friend doesn't really like you?";
  ItemArr[74]->Text = "Do you realize hours later that somebody that you have a romantic interest for actually showed interest for you, and then feel bad about the missed opportunity to connect?";
  ItemArr[75]->Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  ItemArr[76]->Text = "Do you have, or used to have, imaginary relationships?";
  ItemArr[77]->Text = "Do you have unusual sexual preferences?";
  ItemArr[78]->Text = "Did you feel lonely as a child?";
  ItemArr[79]->Text = "Do you prefer to learn the character of a potential romantic partner through observation rather than conversation?";
  ItemArr[80]->Text = "Do you cry about nothing?";
  ItemArr[81]->Text = "Do you like to protect people you are attached to even when they didn't ask for it?";
  ItemArr[82]->Text = "Have you been talked into having sex even if you really didn't want to?";
  ItemArr[83]->Text = "Do you tend to get romantic feelings for people that persistently shows interest for you?";
  ItemArr[84]->Text = "Are you good at team-work?";
  ItemArr[85]->Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  ItemArr[86]->Text = "Do you find it easy to keep up with group discussions where everyone is speaking?";
  ItemArr[87]->Text = "Do you enjoy traditional dating?";
  ItemArr[88]->Text = "Do you find yourself at ease in romantic situations?";
  ItemArr[89]->Text = "Do you enjoy big events even if they are crowded?";
  ItemArr[90]->Text = "Do you enjoy travel?";
  ItemArr[91]->Text = "Do you like to have small talk before getting on to the important topics in a conversation?";
  ItemArr[92]->Text = "Do you like tongue-kissing?";
  ItemArr[93]->Text = "Do you naturally approach somebody you have an romantic interest for?";
  ItemArr[94]->Text = "Do you like 'being in style'?";
  ItemArr[95]->Text = "Are you asexual?";
  ItemArr[96]->Text = "Would you quickly become impatient and irritated if you would not find a solution to a problem?";
  ItemArr[97]->Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  ItemArr[98]->Text = "Do you have difficulty accepting criticism, correction, and direction?";
  ItemArr[99]->Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  ItemArr[100]->Text = "Do you usually find faults with opinions that you don't share?";
  ItemArr[101]->Text = "Do you see your own activities as more important than other people's?";
  ItemArr[102]->Text = "Do you feel irritated when one person disagrees with what everyone else in a group believes?";
  ItemArr[103]->Text = "Will you abandon your friends if your activities or ideals clash?";
  ItemArr[104]->Text = "Do you avoid talking because you cannot reliably predict how others will react, especially strangers?";
  ItemArr[105]->Text = "Has it been harder for you than for others to keep friends?";
  ItemArr[106]->Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  ItemArr[107]->Text = "Do you need to prepare yourself mentally before going somewhere?";
  ItemArr[108]->Text = "Do you feel you have to be on your guard even with friends?";
  ItemArr[109]->Text = "Do you practice what you want to say in conversations?";
  ItemArr[110]->Text = "Do you spend hours overthinking and re-enacting negative social interaction?";
  ItemArr[111]->Text = "Do you dislike it when people drop by to visit you uninvited?";
  ItemArr[112]->Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  ItemArr[113]->Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  ItemArr[114]->Text = "Are you shy?";
  ItemArr[115]->Text = "Is your sense of humor fairly conventional?";
  ItemArr[116]->Text = "Can you easily remember verbal instructions?";
  ItemArr[117]->Text = "Do you find it easy to estimate the age of people?";
  ItemArr[118]->Text = "Do you accept criticism, correction and direction?";

  ItemArr[119]->Text = "Do worrying help you to avoid problems in the future?";
  ItemArr[120]->Text = "Is your worrying dangerous for you?";
  ItemArr[121]->Text = "Do think a lot about your own thoughts?";
  ItemArr[122]->Text = "Could you make yourself sick with worrying?";
  ItemArr[123]->Text = "Are you aware of the way your mind works when you are thinking through a problem?";
  ItemArr[124]->Text = "If you did not control a worrying thought, and then it happened, would it be your fault?";
  ItemArr[125]->Text = "Do you need to worry in order to remain organised?";
  ItemArr[126]->Text = "Do you have little confidence in your memory for words and names?";
  ItemArr[127]->Text = "Does your worrying thoughts persist, no matter how you try to stop them?";
  ItemArr[128]->Text = "Do worrying help you to get things sorted out in your mind?";
  ItemArr[129]->Text = "Are you unable to ignore your worrying thoughts?";
  ItemArr[130]->Text = "Do you monitor your thoughts?";
  ItemArr[131]->Text = "Should you be in control of your thoughts all of the time?";
  ItemArr[132]->Text = "Can your memory mislead you at times?";
  ItemArr[133]->Text = "Can your worrying make you go mad?";
  ItemArr[134]->Text = "Are you constantly aware of your thinking?";
  ItemArr[135]->Text = "Do you have a poor memory?";
  ItemArr[136]->Text = "Do you pay close attention to the way your mind works?";
  ItemArr[137]->Text = "Does worrying help you cope?";
  ItemArr[138]->Text = "Is not being able to control your thoughts a sign of weakness?";
  ItemArr[139]->Text = "When you start worrying, are you unable stop?";
  ItemArr[140]->Text = "Will you be punished for not controlling certain thoughts?";
  ItemArr[141]->Text = "Does worrying help you to solve problems?";
  ItemArr[142]->Text = "Do you have little confidence in your memory for places?";
  ItemArr[143]->Text = "Is it bad for you to think certain thoughts?";
  ItemArr[144]->Text = "Do you not trust your memory?";
  ItemArr[145]->Text = "If you could not control your thoughts, would you not be able to function?";
  ItemArr[146]->Text = "Do you need to worry in order to work well?";
  ItemArr[147]->Text = "Do you have little confidence in your memory for actions?";
  ItemArr[148]->Text = "Do you constantly examine your thoughts?";

  ItemArr[149]->Text = "Do you have a good relationship with your parents?";
  ItemArr[150]->Text = "Do you have conflicts with your parents?";
  ItemArr[151]->Text = "Were your parents aware of your needs as a child?";
  ItemArr[152]->Text = "Did your parents force you to obey their rules as a child?";
  ItemArr[153]->Text = "Did your parents set up many rules for you as a child?";
  ItemArr[154]->Text = "Did you parents explain and negotiate rules with you as a child?";
  ItemArr[155]->Text = "Do you feel you are right in conflicts with your parents?";
  ItemArr[156]->Text = "Do you feel you are wrong in conflicts with your parents?";
  ItemArr[157]->Text = "Do you feel your parents understand you better now than as a child?";

  ItemArr[158]->Text = "Do you have regular depressions?";
  ItemArr[159]->Text = "Do you tend to become anxious?";

  ItemArr[160]->Text = "Do you seek friends to form attachments with?";
  ItemArr[161]->Text = "Do you seek friends with similar interests?";
  ItemArr[162]->Text = "Do you seek friends you can trust?";

}

/*##################  TQuizQ8::ProcessRow ##########################
*   Purpose....: Process row                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizQ8::ProcessRow(char *str)
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
#   Name       : TQuizQ8::Load
#
#   Purpose....: Load data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizQ8::Load()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile file("raw\\aspie-quiz-Q8.csv");
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
