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
# quizje1.cpp
# Quiz class for JE1
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizje1.h"
#include "quizdje1.h"

#define CI      1

#define MAX_IN_ROW              4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizJE1::TQuizJE1
#
#   Purpose....: Constructor for TQuizJE1
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizJE1::TQuizJE1(const char *FileName)
  : TQuiz(210),
        FDataFile(FileName)
{
        SetupTexts();
        SetupCross();

        LoadPopulations();
        Calculate();
}

/*##########################################################################
#
#   Name       : TQuizJE1::~TQuizJE1
#
#   Purpose....: Destructor for TQuizJE1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizJE1::~TQuizJE1()
{
}

/*##################  TQuizJE1::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizJE1::GetPcaCount()
{
        return 4;
}

/*##################  TQuizJE1::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizJE1::GetCatCount(int Question)
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
int TQuizJE1::GetQuizN()
{
    return 210;
}

/*##########################################################################
#
#   Name       : TQuizJE1::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizJE1::WriteName(TFile &File)
{
    File.Write("JE1");
}

/*##########################################################################
#
#   Name       : TQuizJE1::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizJE1::WriteLongName(TFile &File)
{
    File.Write("JE1");
}

/*##########################################################################
#
#   Name       : TQuizJE1::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizJE1::SetupTexts()
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
  Quiz[21].Nt = TRUE;
  Quiz[22].Aspie = TRUE;
  Quiz[23].Aspie = TRUE;
  Quiz[24].Aspie = TRUE;
  Quiz[25].Aspie = TRUE;
  Quiz[26].Aspie = TRUE;
  Quiz[27].Nt = TRUE;
  Quiz[28].Nt = TRUE;
  Quiz[29].Nt = TRUE;
  Quiz[30].Nt = TRUE;
  Quiz[31].Nt = TRUE;
  Quiz[32].Nt = TRUE;
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
  Quiz[48].Aspie = TRUE;
  Quiz[49].Aspie = TRUE;
  Quiz[50].Aspie = TRUE;
  Quiz[51].Aspie = TRUE;
  Quiz[52].Aspie = TRUE;
  Quiz[53].Aspie = TRUE;
  Quiz[54].Aspie = TRUE;
  Quiz[55].Aspie = TRUE;
  Quiz[56].Aspie = TRUE;
  Quiz[57].Nt = TRUE;
  Quiz[58].Nt = TRUE;
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
  Quiz[71].Nt = TRUE;
  Quiz[72].Nt = TRUE;
  Quiz[73].Nt = TRUE;
  Quiz[74].Nt = TRUE;
  Quiz[75].Aspie = TRUE;
  Quiz[76].Aspie = TRUE;
  Quiz[77].Aspie = TRUE;
  Quiz[78].Aspie = TRUE;
  Quiz[79].Aspie = TRUE;
  Quiz[80].Aspie = TRUE;
  Quiz[81].Aspie = TRUE;
  Quiz[82].Aspie = TRUE;
  Quiz[83].Aspie = TRUE;
  Quiz[84].Aspie = TRUE;
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
  Quiz[99].Aspie = TRUE;
  Quiz[100].Aspie = TRUE;
  Quiz[101].Aspie = TRUE;
  Quiz[102].Aspie = TRUE;
  Quiz[103].Aspie = TRUE;
  Quiz[104].Aspie = TRUE;
  Quiz[105].Aspie = TRUE;
  Quiz[106].Nt = TRUE;
  Quiz[107].Nt = TRUE;
  Quiz[108].Nt = TRUE;
  Quiz[109].Nt = TRUE;
  Quiz[110].Aspie = TRUE;
  Quiz[111].Aspie = TRUE;
  Quiz[112].Aspie = TRUE;
  Quiz[113].Aspie = TRUE;
  Quiz[114].Aspie = TRUE;
  Quiz[115].Aspie = TRUE;
  Quiz[116].Aspie = TRUE;
  Quiz[117].Aspie = TRUE;
  Quiz[118].Aspie = TRUE;
  Quiz[119].Aspie = TRUE;
  Quiz[120].Aspie = TRUE;
  Quiz[121].Aspie = TRUE;
  Quiz[122].Aspie = TRUE;
  Quiz[123].Nt = TRUE;
  Quiz[124].Nt = TRUE;
  Quiz[125].Nt = TRUE;
  Quiz[126].Nt = TRUE;

  Quiz[13].Reverse = TRUE;
  Quiz[21].Reverse = TRUE;
  Quiz[30].Reverse = TRUE;
  Quiz[64].Reverse = TRUE;
  Quiz[69].Reverse = TRUE;
  Quiz[70].Reverse = TRUE;
  Quiz[71].Reverse = TRUE;
  Quiz[78].Reverse = TRUE;
  Quiz[79].Reverse = TRUE;
  Quiz[84].Reverse = TRUE;
  Quiz[90].Reverse = TRUE;
  Quiz[94].Reverse = TRUE;
  Quiz[95].Reverse = TRUE;
  Quiz[96].Reverse = TRUE;
  Quiz[98].Reverse = TRUE;
  Quiz[106].Reverse = TRUE;
  Quiz[107].Reverse = TRUE;
  Quiz[108].Reverse = TRUE;
  Quiz[109].Reverse = TRUE;
  Quiz[123].Reverse = TRUE;
  Quiz[126].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;
  Quiz[150].Reverse = TRUE;
  Quiz[157].Reverse = TRUE;
  Quiz[158].Reverse = TRUE;
  Quiz[159].Reverse = TRUE;
  Quiz[160].Reverse = TRUE;
  Quiz[161].Reverse = TRUE;
  Quiz[162].Reverse = TRUE;
  Quiz[163].Reverse = TRUE;
  Quiz[164].Reverse = TRUE;
  Quiz[165].Reverse = TRUE;
  Quiz[166].Reverse = TRUE;
  Quiz[167].Reverse = TRUE;
  Quiz[168].Reverse = TRUE;
  Quiz[169].Reverse = TRUE;
  Quiz[170].Reverse = TRUE;
  Quiz[174].Reverse = TRUE;
  Quiz[175].Reverse = TRUE;
  Quiz[178].Reverse = TRUE;
  Quiz[179].Reverse = TRUE;
  Quiz[180].Reverse = TRUE;
  Quiz[181].Reverse = TRUE;
  Quiz[182].Reverse = TRUE;
  Quiz[199].Reverse = TRUE;
  Quiz[200].Reverse = TRUE;
  Quiz[209].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[6].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[8].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[9].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[10].MyGroup = GROUP_NT_TALENT;
  Quiz[11].MyGroup = GROUP_NT_TALENT;
  Quiz[12].MyGroup = GROUP_NT_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_ASPIE_TALENT;
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
  Quiz[27].MyGroup = GROUP_NT_SENSORY;
  Quiz[28].MyGroup = GROUP_NT_SENSORY;
  Quiz[29].MyGroup = GROUP_NT_SENSORY;
  Quiz[30].MyGroup = GROUP_NT_SENSORY;
  Quiz[31].MyGroup = GROUP_NT_SENSORY;
  Quiz[32].MyGroup = GROUP_NT_SENSORY;
  Quiz[33].MyGroup = GROUP_ASPIE_NVC;
  Quiz[34].MyGroup = GROUP_ASPIE_NVC;
  Quiz[35].MyGroup = GROUP_ASPIE_NVC;
  Quiz[36].MyGroup = GROUP_ASPIE_NVC;
  Quiz[37].MyGroup = GROUP_ASPIE_NVC;
  Quiz[38].MyGroup = GROUP_ASPIE_NVC;
  Quiz[39].MyGroup = GROUP_ASPIE_NVC;
  Quiz[40].MyGroup = GROUP_ASPIE_NVC;
  Quiz[41].MyGroup = GROUP_ASPIE_NVC;
  Quiz[42].MyGroup = GROUP_ASPIE_NVC;
  Quiz[43].MyGroup = GROUP_ASPIE_NVC;
  Quiz[44].MyGroup = GROUP_MIXED;
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
  Quiz[57].MyGroup = GROUP_NT_NVC;
  Quiz[58].MyGroup = GROUP_NT_NVC;
  Quiz[59].MyGroup = GROUP_NT_SOCIAL;
  Quiz[60].MyGroup = GROUP_NT_NVC;
  Quiz[61].MyGroup = GROUP_NT_NVC;
  Quiz[62].MyGroup = GROUP_NT_NVC;
  Quiz[63].MyGroup = GROUP_NT_NVC;
  Quiz[64].MyGroup = GROUP_NT_NVC;
  Quiz[65].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[66].MyGroup = GROUP_NT_NVC;
  Quiz[67].MyGroup = GROUP_NT_NVC;
  Quiz[68].MyGroup = GROUP_NT_NVC;
  Quiz[69].MyGroup = GROUP_NT_NVC;
  Quiz[70].MyGroup = GROUP_MIXED;
  Quiz[71].MyGroup = GROUP_NT_NVC;
  Quiz[72].MyGroup = GROUP_NT_NVC;
  Quiz[73].MyGroup = GROUP_NT_NVC;
  Quiz[74].MyGroup = GROUP_NT_NVC;
  Quiz[75].MyGroup = GROUP_MIXED;
  Quiz[76].MyGroup = GROUP_MIXED;
  Quiz[77].MyGroup = GROUP_MIXED;
  Quiz[78].MyGroup = GROUP_MIXED;
  Quiz[79].MyGroup = GROUP_MIXED;
  Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[81].MyGroup = GROUP_ASPIE_CONTACT;
  Quiz[82].MyGroup = GROUP_MIXED;
  Quiz[83].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[84].MyGroup = GROUP_MIXED;
  Quiz[85].MyGroup = GROUP_MIXED;
  Quiz[86].MyGroup = GROUP_MIXED;
  Quiz[87].MyGroup = GROUP_MIXED;
  Quiz[88].MyGroup = GROUP_NT_SOCIAL;
  Quiz[89].MyGroup = GROUP_NT_SOCIAL;
  Quiz[90].MyGroup = GROUP_NT_CONTACT;
  Quiz[91].MyGroup = GROUP_NT_SOCIAL;
  Quiz[92].MyGroup = GROUP_NT_SOCIAL;
  Quiz[93].MyGroup = GROUP_MIXED;
  Quiz[94].MyGroup = GROUP_MIXED;
  Quiz[95].MyGroup = GROUP_NT_SOCIAL;
  Quiz[96].MyGroup = GROUP_NT_CONTACT;
  Quiz[97].MyGroup = GROUP_NT_SOCIAL;
  Quiz[98].MyGroup = GROUP_NT_SOCIAL;
  Quiz[99].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[100].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[101].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[102].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[103].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[104].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[105].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[106].MyGroup = GROUP_NT_CONTACT;
  Quiz[107].MyGroup = GROUP_NT_ATTACH;
  Quiz[108].MyGroup = GROUP_NT_CONTACT;
  Quiz[109].MyGroup = GROUP_NT_ATTACH;
  Quiz[110].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[111].MyGroup = GROUP_MIXED;
  Quiz[112].MyGroup = GROUP_MIXED;
  Quiz[113].MyGroup = GROUP_MIXED;
  Quiz[114].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[115].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[116].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[117].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[118].MyGroup = GROUP_MIXED;
  Quiz[119].MyGroup = GROUP_MIXED;
  Quiz[120].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[121].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[122].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[123].MyGroup = GROUP_NT_ATTACH;
  Quiz[124].MyGroup = GROUP_NT_ATTACH;
  Quiz[125].MyGroup = GROUP_NT_ATTACH;
  Quiz[126].MyGroup = GROUP_NT_ATTACH;
  
  Quiz[127].MyGroup = GROUP_NDNT;
  Quiz[128].MyGroup = GROUP_NDNT;
  Quiz[129].MyGroup = GROUP_NDNT;
  Quiz[130].MyGroup = GROUP_NDNT;
  Quiz[131].MyGroup = GROUP_NDNT;
  Quiz[132].MyGroup = GROUP_NDNT;
  Quiz[133].MyGroup = GROUP_NDNT;
  Quiz[134].MyGroup = GROUP_NDNT;
  Quiz[135].MyGroup = GROUP_NDNT;
  Quiz[136].MyGroup = GROUP_NDNT;
  Quiz[137].MyGroup = GROUP_NT_SOCIAL;
  Quiz[138].MyGroup = GROUP_NDNT;
  Quiz[139].MyGroup = GROUP_NDNT;
  Quiz[140].MyGroup = GROUP_NDNT;
  Quiz[141].MyGroup = GROUP_NDNT;
  Quiz[142].MyGroup = GROUP_NDNT;
  Quiz[143].MyGroup = GROUP_NDNT;
  Quiz[144].MyGroup = GROUP_ASPIE_SOCIAL;

  Quiz[145].MyGroup = GROUP_MIXED;
  Quiz[146].MyGroup = GROUP_MIXED;
  Quiz[147].MyGroup = GROUP_MIXED;
  Quiz[148].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[149].MyGroup = GROUP_MIXED;

  Quiz[150].MyGroup = GROUP_MIXED;
  Quiz[151].MyGroup = GROUP_NT_SOCIAL;
  Quiz[152].MyGroup = GROUP_MIXED;
  Quiz[153].MyGroup = GROUP_MIXED;
  Quiz[154].MyGroup = GROUP_MIXED;
  Quiz[155].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[156].MyGroup = GROUP_NT_SOCIAL;
  Quiz[157].MyGroup = GROUP_NT_CONTACT;
  Quiz[158].MyGroup = GROUP_NT_CONTACT;
  Quiz[159].MyGroup = GROUP_NT_CONTACT;
  Quiz[160].MyGroup = GROUP_NT_CONTACT;
  Quiz[161].MyGroup = GROUP_NT_SOCIAL;
  Quiz[162].MyGroup = GROUP_NT_CONTACT;
  Quiz[163].MyGroup = GROUP_NT_CONTACT;
  Quiz[164].MyGroup = GROUP_NT_CONTACT;
  Quiz[165].MyGroup = GROUP_NT_CONTACT;
  Quiz[166].MyGroup = GROUP_NT_CONTACT;
  Quiz[167].MyGroup = GROUP_NT_CONTACT;
  Quiz[168].MyGroup = GROUP_NT_CONTACT;
  Quiz[169].MyGroup = GROUP_MIXED;
  Quiz[170].MyGroup = GROUP_NT_SOCIAL;
  Quiz[171].MyGroup = GROUP_NT_SOCIAL;
  Quiz[172].MyGroup = GROUP_NT_SOCIAL;
  Quiz[173].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[174].MyGroup = GROUP_MIXED;
  Quiz[175].MyGroup = GROUP_NT_SOCIAL;
  Quiz[176].MyGroup = GROUP_NT_SOCIAL;
  Quiz[177].MyGroup = GROUP_NT_SOCIAL;
  Quiz[178].MyGroup = GROUP_MIXED;
  Quiz[179].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[180].MyGroup = GROUP_NT_CONTACT;
  Quiz[181].MyGroup = GROUP_NT_CONTACT;
  Quiz[182].MyGroup = GROUP_NT_ATTACH;
  Quiz[183].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[184].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[185].MyGroup = GROUP_MIXED;
  Quiz[186].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[187].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[188].MyGroup = GROUP_MIXED;
  Quiz[189].MyGroup = GROUP_MIXED;
  Quiz[190].MyGroup = GROUP_MIXED;
  Quiz[191].MyGroup = GROUP_NT_SOCIAL;
  Quiz[192].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[193].MyGroup = GROUP_NT_SOCIAL;
  Quiz[194].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[195].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[196].MyGroup = GROUP_MIXED;
  Quiz[197].MyGroup = GROUP_NT_SOCIAL;
  Quiz[198].MyGroup = GROUP_MIXED;
  Quiz[199].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[200].MyGroup = GROUP_ASPIE_CONTACT;
  Quiz[201].MyGroup = GROUP_ASPIE_ATTACH;
  Quiz[202].MyGroup = GROUP_MIXED;
  Quiz[203].MyGroup = GROUP_NT_SOCIAL;
  Quiz[204].MyGroup = GROUP_ASPIE_NVC;
  Quiz[205].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[206].MyGroup = GROUP_ASPIE_CONTACT;
  Quiz[207].MyGroup = GROUP_ASPIE_CONTACT;
  Quiz[208].MyGroup = GROUP_MIXED;
  Quiz[209].MyGroup = GROUP_NT_ATTACH;


 Quiz[0].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
 Quiz[1].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
 Quiz[2].Text = "Do you have strong attachments to certain favorite objects?";
 Quiz[3].Text = "Do you have certain routines which you need to follow?";
 Quiz[4].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
 Quiz[5].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
 Quiz[6].Text = "Do you need lists and schedules in order to get things done?";
 Quiz[7].Text = "Do you notice patterns in things all the time?";
 Quiz[8].Text = "Do you have an avid perseverance in gathering and cataloguing information on a topic of interest?";
 Quiz[9].Text = "Do you have one special talent which you have emphasised and worked on?";
 Quiz[10].Text = "Do you get confused by several verbal instructions at the same time?";
 Quiz[11].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
 Quiz[12].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
 Quiz[13].Text = "If there is an interruption, can you quickly return to what you were doing before?";
 Quiz[14].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
 Quiz[15].Text = "Do you need to do things yourself in order to remember them?";
 Quiz[16].Text = "Do you have problems filling out forms?";
 Quiz[17].Text = "Do you find it difficult to take notes in lectures?";
 Quiz[18].Text = "Do you find it very hard to learn things that you are not interested in?";
 Quiz[19].Text = "Are you easily distracted?";
 Quiz[20].Text = "Do you have problems starting and / or finishing projects?";
 Quiz[21].Text = "Do you find it easy to do more than one thing at once?";
 Quiz[22].Text = "Are your eyes extra sensitive to stong light and glare?";
 Quiz[23].Text = "Are you sensitive to changes in humidity and air pressure?";
 Quiz[24].Text = "Do you dislike it when people stamp their foot in the floor?";
 Quiz[25].Text = "Do you have extra sensitive hearing?";
 Quiz[26].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
 Quiz[27].Text = "Do you have difficulties judging distances, height, depth or speed?";
 Quiz[28].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
 Quiz[29].Text = "Do you have problems finding your way to new places?";
 Quiz[30].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
 Quiz[31].Text = "Do you have trouble reading clocks?";
 Quiz[32].Text = "Do you mix up digits in numbers like 95 and 59?";
 Quiz[33].Text = "Do people sometimes think you are smiling at the wrong occasion?";
 Quiz[34].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
 Quiz[35].Text = "Do you often don't know where to put your arms?";
 Quiz[36].Text = "Do you tend to talk either too softly or too loudly?";
 Quiz[37].Text = "Have you been accused of staring?";
 Quiz[38].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
 Quiz[39].Text = "Have others told you that you have an odd posture or gait?";
 Quiz[40].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
 Quiz[41].Text = "Do you mistake noises for voices?";
 Quiz[42].Text = "In conversations, do you use small sounds that others don't seem to use?";
 Quiz[43].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
 Quiz[44].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
 Quiz[45].Text = "Do you jump between topics when speaking?";
 Quiz[46].Text = "Do you fiddle with things?";
 Quiz[47].Text = "Do you stutter when stressed?";
 Quiz[48].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
 Quiz[49].Text = "Do you have a fascination for slowly flowing water?";
 Quiz[50].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
 Quiz[51].Text = "Do recently heard tunes or rhytms tend to stick and replay themselves repeatedly in your head?";
 Quiz[52].Text = "Do you talk to yourself?";
 Quiz[53].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
 Quiz[54].Text = "Do you pace (e.g. when thinking or anxious)?";
 Quiz[55].Text = "Do you enjoy mimicking animal sounds?";
 Quiz[56].Text = "Do you enjoy walking on your toes?";
 Quiz[57].Text = "Do you find it difficult to figure out how to behave in various situations?";
 Quiz[58].Text = "Do you have problems with timing in conversations?";
 Quiz[59].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
 Quiz[60].Text = "Do you often feel out-of-sync with others?";
 Quiz[61].Text = "Do others often misunderstand you?";
 Quiz[62].Text = "Has it been harder for you than for others to keep friends?";
 Quiz[63].Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
 Quiz[64].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
 Quiz[65].Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
 Quiz[66].Text = "Are you often surprised what people's motives are ?";
 Quiz[67].Text = "Do you tend to interpret things literally?";
 Quiz[68].Text = "Is it hard for you to see why some things upset people so much?";
 Quiz[69].Text = "Do you know when you are expected to offer an apology?";
 Quiz[70].Text = "Are you naturally good at returning social courtesies and gestures?";
 Quiz[71].Text = "Are you good at interpreting facial expressions?";
 Quiz[72].Text = "Do you find it hard to tell the age of people?";
 Quiz[73].Text = "Do you have problems recognizing faces (prosopagnosia)?";
 Quiz[74].Text = "Do you have a monotonous voice?";
 Quiz[75].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
 Quiz[76].Text = "Is your sense of humor different from mainstream or considered odd?";
 Quiz[77].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
 Quiz[78].Text = "Are your views typical of your peer group?";
 Quiz[79].Text = "Do you naturally fit into the expected gender stereotypes?";
 Quiz[80].Text = "Do you have trouble with authority?";
 Quiz[81].Text = "Do you have unusual sexual preferences?";
 Quiz[82].Text = "Do you prefer to construct your own set of spiritual beliefs rather than following existing religions / belief-systems?";
 Quiz[83].Text = "Are you more sexually attracted to strangers than to people you know well?";
 Quiz[84].Text = "Do you find it natural to go through established channels?";
 Quiz[85].Text = "Do you dislike shaking hands with strangers?";
 Quiz[86].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
 Quiz[87].Text = "Do you dislike when people walk behind you?";
 Quiz[88].Text = "Do you find it hard to be emotionally close to other people?";
 Quiz[89].Text = "Do you get very tired after socializing, and need to regenerate alone?";
 Quiz[90].Text = "Do you enjoy meeting new people?";
 Quiz[91].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
 Quiz[92].Text = "Do you dislike it when people drop by to visit you uninvited?";
 Quiz[93].Text = "Do you dislike working while being observed?";
 Quiz[94].Text = "Do you find it easy to describe your feelings?";
 Quiz[95].Text = "Do you find yourself at ease in romantic situations?";
 Quiz[96].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
 Quiz[97].Text = "Do you try to avoid to talk about your warm feeling for other people?";
 Quiz[98].Text = "Do you enjoy team sports?";
 Quiz[99].Text = "Do you have difficulty accepting criticism, correction, and direction?";
 Quiz[100].Text = "Are you impatient and have low frustration tolerance?";
 Quiz[101].Text = "Do you see your own activities as more important than other people's?";
 Quiz[102].Text = "Do you usually find faults with opinions that you don't share?";
 Quiz[103].Text = "Do you think others should have the same friends and enemies as yourself?";
 Quiz[104].Text = "Have you have had long-lasting urges to take revenge?";
 Quiz[105].Text = "Are you strong-willed and stubborn?";
 Quiz[106].Text = "Do you have an interest for the current fashions?";
 Quiz[107].Text = "Do you want to share your life with someone?";
 Quiz[108].Text = "Do you enjoy gossip?";
 Quiz[109].Text = "Are intimate relationships very important in your life?";
 Quiz[110].Text = "Do you only feel safe when you are with people you are close to?";
 Quiz[111].Text = "Are you prone to getting depressions?";
 Quiz[112].Text = "Do your feelings cycle regulary between hopelessness and extremely high confidence?";
 Quiz[113].Text = "Do you sometimes lie awake at night because of too many thoughts?";
 Quiz[114].Text = "Do you tend to become obsessed with a potential partner and cannot let go of him/her?";
 Quiz[115].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
 Quiz[116].Text = "Do you like to follow (walk behind) people you are attached to?";
 Quiz[117].Text = "Do you worry about being abondoned by the person you love?";
 Quiz[118].Text = "Do you examine the hair of people you like a lot?";
 Quiz[119].Text = "Would you like to sleep all winter?";
 Quiz[120].Text = "Have you experienced stronger than normal attachments to certain people?";
 Quiz[121].Text = "Do you prefer to have friends of the opposite gender?";
 Quiz[122].Text = "Do you tend to lean towards your partner when you are at a restaurant or party?";
 Quiz[123].Text = "Do you get great pleasure from making love?";
 Quiz[124].Text = "Are you asexual?";
 Quiz[125].Text = "Do you dislike sexual intercourse other than as procreation?";
 Quiz[126].Text = "Do you find casual sex rewarding?";

 Quiz[127].Text = "Do you tend to express your feelings in ways that may baffle others?";
 Quiz[128].Text = "Do you forget you are in a social situation when something gets your attention?";
 Quiz[129].Text = "Do you suddenly feel distracted by distant sounds?";
 Quiz[130].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
 Quiz[131].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
 Quiz[132].Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
 Quiz[133].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
 Quiz[134].Text = "Do people often tell you that you keep going on and on about the same thing?";
 Quiz[135].Text = "Do you have difficulties filtering out background noise when talking to someone?";
 Quiz[136].Text = "Are you sometimes afraid in safe situations?";
 Quiz[137].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
 Quiz[138].Text = "Are you bothered by clothes tags or light touch?";
 Quiz[139].Text = "Do you prefer to wear the same clothes or eat the same food many days in a row?";
 Quiz[140].Text = "Do you drop things when your attention is on other things?";
 Quiz[141].Text = "Do you or others think that you have unconventional ways of solving problems?";
 Quiz[142].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
 Quiz[143].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
 Quiz[144].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";

 Quiz[145].Text = "Do you have a good sense for what is the right thing to do socially?";
 Quiz[146].Text = "Can you easily remember verbal instructions?";
 Quiz[147].Text = "Is your sense of humor fairly conventional?";
 Quiz[148].Text = "Are you gracious about criticism, correction and direction?";
 Quiz[149].Text = "Do you find it easy to estimate the age of people?";

 Quiz[150].Text = "Do you have a clear sense of your identity?";
 Quiz[151].Text = "Are you shy?";
 Quiz[152].Text = "Do you work slowly on jobs you dislike?";
 Quiz[153].Text = "Do you drift through life?";
 Quiz[154].Text = "Do you need a lot of motivation to do things?";
 Quiz[155].Text = "Do you argue a lot?";
 Quiz[156].Text = "Do you stay away from situations where people might express affection for you?";
 Quiz[157].Text = "Do you like to do things spontaneously?";
 Quiz[158].Text = "Are you the life of a party?";
 Quiz[159].Text = "Do you enjoy big events even if they are crowded?";
 Quiz[160].Text = "Are you energized by being in the company of others?";
 Quiz[161].Text = "Have you felt kinship and belonging to others for all your life?";
 Quiz[162].Text = "Is a large social network important for you?";
 Quiz[163].Text = "Do you prefer the company of those of the same age as yourself?";
 Quiz[164].Text = "Do you take pride in your appearance?";
 Quiz[165].Text = "Is creating a social identity important for you?";
 Quiz[166].Text = "Do you cheer loudy at a sporting event or concert?";
 Quiz[167].Text = "Do you talk to put others at ease even when you have nothing to say?";
 Quiz[168].Text = "Is your style or image important to you?";
 Quiz[169].Text = "Are you good at team-work?";
 Quiz[170].Text = "Are you good at social chit-chat?";
 Quiz[171].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
 Quiz[172].Text = "Do you prefer to keep to yourself?";
 Quiz[173].Text = "Will you abandon your friends if your activities or ideals clash?";
 Quiz[174].Text = "Does it feel natural for you to say 'thank you' and 'sorry'?";
 Quiz[175].Text = "Do you talk a lot in a relationship?";
 Quiz[176].Text = "Do you become shy or passive when you see somebody of the opposite sex that you are interested in?";
 Quiz[177].Text = "Do you avoid being the centre of attention?";
 Quiz[178].Text = "Do you prefer to know a little about many things rather than becoming a specialist in one or a few areas?";
 Quiz[179].Text = "Do you feel gratitude?";
 Quiz[180].Text = "Do you enjoy hosting or arranging events?";
 Quiz[181].Text = "Do you enjoy travel?";
 Quiz[182].Text = "Do you like tongue-kissing?";
 Quiz[183].Text = "Do you have a very acute sense of smell and/or taste?";
 Quiz[184].Text = "Are you sensitive to heat?";
 Quiz[185].Text = "Do you often use peripheral vision?";
 Quiz[186].Text = "Are you instinctively afraid of floods and/or fast running streams?";
 Quiz[187].Text = "Are you afraid of closed places?";
 Quiz[188].Text = "Do you believe in ghosts and / or supernatural phenomena?";
 Quiz[189].Text = "Do you think that living beings are connected in a mysterious way?";
 Quiz[190].Text = "Do you almost always feel hurried to reach a decision, even when there is no reason to do so?";
 Quiz[191].Text = "Do you prefer to socialize with familiar friends because you know what to expect from them?";
 Quiz[192].Text = "Do you have favorite places nearby that you need to visit from time to time?";
 Quiz[193].Text = "Would you like to live a life all by yourself?";
 Quiz[194].Text = "Is it important for you to find a unique niche where you can acquire unique competence?";
 Quiz[195].Text = "Do you admire people with unique knowledge / competence?";
 Quiz[196].Text = "Do you have an urge to observe the habits of humans and/or animals?";
 Quiz[197].Text = "Do you like to visit people one at a time?";
 Quiz[198].Text = "Do you have an urge to learn the routines of people you know?";
 Quiz[199].Text = "Is it more important to be a team player than to express oneself?";
 Quiz[200].Text = "Do you find chastity an important and valuable virtue?";
 Quiz[201].Text = "Do you have a need to confess?";
 Quiz[202].Text = "Do you pull hair?";
 Quiz[203].Text = "Is it hard for you to approach somebody you are attracted to?";
 Quiz[204].Text = "Do you enjoy hanging upside down?";
 Quiz[205].Text = "Do you obstruct others' plans?";
 Quiz[206].Text = "Are you homosexual or bisexual?";
 Quiz[207].Text = "Do you have an interest in or have practised BD/SM?";
 Quiz[208].Text = "Do you like sniffing people or things?";
 Quiz[209].Text = "Is sex important for you to keep a relationship alive?";

}

/*##########################################################################
#
#   Name       : TQuizJE1::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizJE1::LoadPopulations()
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
#   Name       : TQuizJE1::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizJE1::SetupCross()
{
    int i;

    for (i = 0; i < 210; i++)
            DefineGlobalId(i, i);
}

/*##########################################################################
#
#   Name       : TQuizJE1::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizJE1::GetReferer(const char *referer, TPopulation *pop)
{
}

/*##################  TQuizJE1::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizJE1::ImportMvsp(const char *filename, int PcaType)
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
