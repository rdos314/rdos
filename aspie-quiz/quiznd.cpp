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
# quiz3.cpp
# Quiz III class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "quiznd.h"
#include "file.h"
#include "quizdbnd.h"

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizNd::TQuizNd
#
#   Purpose....: Constructor for TQuizNd
#
#   In params..: Filename to load quiz III from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizNd::TQuizNd(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII)
  : TQuiz(210),
    FDataFile(FileName)
{
    DefineCross(0, QuizI);
    DefineCross(1, QuizII);
    DefineCross(2, QuizIII);

    SetupTexts();
    InitReferers();
    LoadReferers();
    SetupControlGroups();
	SortReferers();
    SetupCross(QuizI, QuizII, QuizIII);
    LoadPopulations();
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuizNd::~TQuizNd
#
#   Purpose....: Destructor for TQuizNd
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizNd::~TQuizNd()
{
}

/*##################  TQuizNd::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizNd::GetPcaCount()
{
	return 4;
}

/*##################  TQuizNd::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizNd::GetQuizN()
{
	return 200;
}

/*##########################################################################
#
#   Name       : TQuizNd::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::WriteName(TFile &File)
{
    File.Write("ND");
}

/*##########################################################################
#
#   Name       : TQuizNd::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::WriteLongName(TFile &File)
{
	 File.Write("neurodiversity version");
}

/*##########################################################################
#
#   Name       : TQuizNd::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::SetupTexts()
{
	Quiz[19].Reverse = TRUE;
	Quiz[21].Reverse = TRUE;
	Quiz[22].Reverse = TRUE;
	Quiz[23].Reverse = TRUE;
	Quiz[24].Reverse = TRUE;
	Quiz[29].Reverse = TRUE;
	Quiz[34].Reverse = TRUE;
	Quiz[36].Reverse = TRUE;
	Quiz[39].Reverse = TRUE;
	Quiz[41].Reverse = TRUE;
	Quiz[45].Reverse = TRUE;
	Quiz[47].Reverse = TRUE;
	Quiz[48].Reverse = TRUE;
	Quiz[60].Reverse = TRUE;
	Quiz[62].Reverse = TRUE;
	Quiz[63].Reverse = TRUE;
	Quiz[69].Reverse = TRUE;
	Quiz[73].Reverse = TRUE;
	Quiz[74].Reverse = TRUE;
	Quiz[75].Reverse = TRUE;
	Quiz[76].Reverse = TRUE;
	Quiz[79].Reverse = TRUE;
	Quiz[80].Reverse = TRUE;
	Quiz[81].Reverse = TRUE;
	Quiz[85].Reverse = TRUE;
	Quiz[91].Reverse = TRUE;
	Quiz[92].Reverse = TRUE;
	Quiz[94].Reverse = TRUE;
	Quiz[95].Reverse = TRUE;
	Quiz[100].Reverse = TRUE;
	Quiz[103].Reverse = TRUE;
	Quiz[104].Reverse = TRUE;
	Quiz[105].Reverse = TRUE;
	Quiz[109].Reverse = TRUE;
	Quiz[110].Reverse = TRUE;
	Quiz[111].Reverse = TRUE;
	Quiz[115].Reverse = TRUE;
	Quiz[116].Reverse = TRUE;
    Quiz[118].Reverse = TRUE;
	Quiz[120].Reverse = TRUE;
	Quiz[122].Reverse = TRUE;
	Quiz[124].Reverse = TRUE;
	Quiz[125].Reverse = TRUE;
	Quiz[128].Reverse = TRUE;
	Quiz[129].Reverse = TRUE;
	Quiz[131].Reverse = TRUE;
	Quiz[132].Reverse = TRUE;
	Quiz[133].Reverse = TRUE;
	Quiz[134].Reverse = TRUE;
	Quiz[135].Reverse = TRUE;
	Quiz[136].Reverse = TRUE;
	Quiz[137].Reverse = TRUE;
	Quiz[142].Reverse = TRUE;
	Quiz[144].Reverse = TRUE;
	Quiz[145].Reverse = TRUE;
	Quiz[151].Reverse = TRUE;
	Quiz[157].Reverse = TRUE;
	Quiz[158].Reverse = TRUE;
	Quiz[166].Reverse = TRUE;
	Quiz[167].Reverse = TRUE;
	Quiz[174].Reverse = TRUE;
	Quiz[178].Reverse = TRUE;
	Quiz[190].Reverse = TRUE;
	Quiz[193].Reverse = TRUE;
	Quiz[194].Reverse = TRUE;
	Quiz[196].Reverse = TRUE;
	Quiz[197].Reverse = TRUE;
	Quiz[199].Reverse = TRUE;

	Quiz[0].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[1].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[2].MyGroup = GROUP_ASPIE_NVC;
	Quiz[3].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[4].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[5].MyGroup = GROUP_MIXED;
	Quiz[6].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[7].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[8].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[9].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[10].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[11].MyGroup = GROUP_SOCIAL;
	Quiz[12].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[13].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[14].MyGroup = GROUP_MIXED;
	Quiz[15].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[16].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[17].MyGroup = GROUP_NT_SENSORY;
	Quiz[18].MyGroup = GROUP_NT_SENSORY;
	Quiz[19].MyGroup = GROUP_NT_SENSORY;
	Quiz[20].MyGroup = GROUP_NT_SENSORY;
	Quiz[21].MyGroup = GROUP_NT_SENSORY;
	Quiz[22].MyGroup = GROUP_NT_SENSORY;
	Quiz[23].MyGroup = GROUP_MIXED;
	Quiz[24].MyGroup = GROUP_NT_SENSORY;
	Quiz[25].MyGroup = GROUP_MIXED;
	Quiz[26].MyGroup = GROUP_NT_SENSORY;
	Quiz[27].MyGroup = GROUP_NT_SENSORY;
	Quiz[28].MyGroup = GROUP_NT_NVC;
	Quiz[29].MyGroup = GROUP_NT_NVC;
	Quiz[30].MyGroup = GROUP_NT_NVC;
	Quiz[31].MyGroup = GROUP_NT_NVC;
	Quiz[32].MyGroup = GROUP_NT_NVC;
	Quiz[33].MyGroup = GROUP_NT_NVC;
	Quiz[34].MyGroup = GROUP_MIXED;
	Quiz[35].MyGroup = GROUP_ACTIVITY;
	Quiz[36].MyGroup = GROUP_SOCIAL;
	Quiz[37].MyGroup = GROUP_ACTIVITY;
	Quiz[38].MyGroup = GROUP_NT_TALENT;
	Quiz[39].MyGroup = GROUP_NT_NVC;
	Quiz[40].MyGroup = GROUP_NT_NVC;
	Quiz[41].MyGroup = GROUP_NT_NVC;
	Quiz[42].MyGroup = GROUP_NT_NVC;
	Quiz[43].MyGroup = GROUP_NT_NVC;
	Quiz[44].MyGroup = GROUP_NT_NVC;
	Quiz[45].MyGroup = GROUP_NT_NVC;
	Quiz[46].MyGroup = GROUP_ASPIE_NVC;
	Quiz[47].MyGroup = GROUP_NT_NVC;
	Quiz[48].MyGroup = GROUP_NT_NVC;
	Quiz[49].MyGroup = GROUP_NT_NVC;
	Quiz[50].MyGroup = GROUP_MIXED;
	Quiz[51].MyGroup = GROUP_SOCIAL;
	Quiz[52].MyGroup = GROUP_ASPIE_NVC;
	Quiz[53].MyGroup = GROUP_ASPIE_NVC;
	Quiz[54].MyGroup = GROUP_ASPIE_NVC;
	Quiz[55].MyGroup = GROUP_ASPIE_NVC;
	Quiz[56].MyGroup = GROUP_ASPIE_NVC;
	Quiz[57].MyGroup = GROUP_ASPIE_NVC;
	Quiz[58].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[59].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[60].MyGroup = GROUP_SOCIAL;
	Quiz[61].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[62].MyGroup = GROUP_NT_OBSESSION;
	Quiz[63].MyGroup = GROUP_NT_OBSESSION;
	Quiz[64].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[65].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[66].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[67].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[68].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[69].MyGroup = GROUP_SOCIAL;
	Quiz[70].MyGroup = GROUP_NT_TALENT;
	Quiz[71].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[72].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[73].MyGroup = GROUP_SOCIAL;
	Quiz[74].MyGroup = GROUP_SOCIAL;
	Quiz[75].MyGroup = GROUP_NT_OBSESSION;
	Quiz[76].MyGroup = GROUP_NT_OBSESSION;
	Quiz[77].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[78].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[79].MyGroup = GROUP_NT_OBSESSION;
	Quiz[80].MyGroup = GROUP_MIXED;
	Quiz[81].MyGroup = GROUP_NT_OBSESSION;
	Quiz[82].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[83].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[84].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[85].MyGroup = GROUP_ENVIRONMENT;
	Quiz[86].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[87].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[88].MyGroup = GROUP_ASPIE_OBSESSION;
	Quiz[89].MyGroup = GROUP_MIXED;
	Quiz[90].MyGroup = GROUP_MIXED;
	Quiz[91].MyGroup = GROUP_NT_NVC;
	Quiz[92].MyGroup = GROUP_NT_OBSESSION;
	Quiz[93].MyGroup = GROUP_SOCIAL;
	Quiz[94].MyGroup = GROUP_NT_OBSESSION;
	Quiz[95].MyGroup = GROUP_SOCIAL;
	Quiz[96].MyGroup = GROUP_MIXED;
	Quiz[97].MyGroup = GROUP_SOCIAL;
	Quiz[98].MyGroup = GROUP_ENVIRONMENT;
	Quiz[99].MyGroup = GROUP_SOCIAL;
	Quiz[100].MyGroup = GROUP_NT_HUNTING;
	Quiz[101].MyGroup = GROUP_MIXED;
	Quiz[102].MyGroup = GROUP_SOCIAL;
	Quiz[103].MyGroup = GROUP_NT_NVC;
	Quiz[104].MyGroup = GROUP_NT_NVC;
	Quiz[105].MyGroup = GROUP_SOCIAL;
	Quiz[106].MyGroup = GROUP_ENVIRONMENT;
	Quiz[107].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[108].MyGroup = GROUP_MIXED;
	Quiz[109].MyGroup = GROUP_NT_NVC;
	Quiz[110].MyGroup = GROUP_NT_NVC;
	Quiz[111].MyGroup = GROUP_SOCIAL;
	Quiz[112].MyGroup = GROUP_SOCIAL;
	Quiz[113].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[114].MyGroup = GROUP_NT_TALENT;
	Quiz[115].MyGroup = GROUP_NT_OBSESSION;
	Quiz[116].MyGroup = GROUP_NT_OBSESSION;
	Quiz[117].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[118].MyGroup = GROUP_NT_OBSESSION;
	Quiz[119].MyGroup = GROUP_MIXED;
	Quiz[120].MyGroup = GROUP_SOCIAL;
	Quiz[121].MyGroup = GROUP_SOCIAL;
	Quiz[122].MyGroup = GROUP_SOCIAL;
	Quiz[123].MyGroup = GROUP_MIXED;
	Quiz[124].MyGroup = GROUP_NT_NVC;
	Quiz[125].MyGroup = GROUP_NT_OBSESSION;
	Quiz[126].MyGroup = GROUP_SOCIAL;
	Quiz[127].MyGroup = GROUP_SOCIAL;
	Quiz[128].MyGroup = GROUP_NT_OBSESSION;
	Quiz[129].MyGroup = GROUP_SOCIAL;
	Quiz[130].MyGroup = GROUP_ASPIE_HUNTING;
	Quiz[131].MyGroup = GROUP_NT_NVC;
	Quiz[132].MyGroup = GROUP_NT_NVC;
	Quiz[133].MyGroup = GROUP_NT_NVC;
	Quiz[134].MyGroup = GROUP_SOCIAL;
	Quiz[135].MyGroup = GROUP_MIXED;
	Quiz[136].MyGroup = GROUP_NT_OBSESSION;
	Quiz[137].MyGroup = GROUP_NT_OBSESSION;
	Quiz[138].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[139].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[140].MyGroup = GROUP_NT_HUNTING;
	Quiz[141].MyGroup = GROUP_NT_HUNTING;
	Quiz[142].MyGroup = GROUP_NT_HUNTING;
	Quiz[143].MyGroup = GROUP_NT_HUNTING;
	Quiz[144].MyGroup = GROUP_NT_HUNTING;
	Quiz[145].MyGroup = GROUP_NT_HUNTING;
	Quiz[146].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[147].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[148].MyGroup = GROUP_NT_HUNTING;
	Quiz[149].MyGroup = GROUP_NT_TALENT;
	Quiz[150].MyGroup = GROUP_ACTIVITY;
	Quiz[151].MyGroup = GROUP_SOCIAL;
	Quiz[152].MyGroup = GROUP_ACTIVITY;
	Quiz[153].MyGroup = GROUP_ACTIVITY;
	Quiz[154].MyGroup = GROUP_ACTIVITY;
	Quiz[155].MyGroup = GROUP_ACTIVITY;
	Quiz[156].MyGroup = GROUP_NT_HUNTING;
	Quiz[157].MyGroup = GROUP_NT_HUNTING;
	Quiz[158].MyGroup = GROUP_NT_HUNTING;
	Quiz[159].MyGroup = GROUP_NT_HUNTING;
	Quiz[160].MyGroup = GROUP_NT_HUNTING;
	Quiz[161].MyGroup = GROUP_NT_HUNTING;
	Quiz[162].MyGroup = GROUP_NT_HUNTING;
	Quiz[163].MyGroup = GROUP_NT_TALENT;
	Quiz[164].MyGroup = GROUP_NT_HUNTING;
	Quiz[165].MyGroup = GROUP_NT_TALENT;
	Quiz[166].MyGroup = GROUP_NT_HUNTING;
	Quiz[167].MyGroup = GROUP_NT_TALENT;
	Quiz[168].MyGroup = GROUP_NT_TALENT;
	Quiz[169].MyGroup = GROUP_NT_TALENT;
	Quiz[170].MyGroup = GROUP_MIXED;
	Quiz[171].MyGroup = GROUP_NT_HUNTING;
	Quiz[172].MyGroup = GROUP_MIXED;
	Quiz[173].MyGroup = GROUP_NT_TALENT;
	Quiz[174].MyGroup = GROUP_MIXED;
	Quiz[175].MyGroup = GROUP_NT_TALENT;
	Quiz[176].MyGroup = GROUP_NT_SENSORY;
	Quiz[177].MyGroup = GROUP_NT_SENSORY;
	Quiz[178].MyGroup = GROUP_NT_HUNTING;
	Quiz[179].MyGroup = GROUP_ASPIE_NVC;
	Quiz[180].MyGroup = GROUP_NT_TALENT;
	Quiz[181].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[182].MyGroup = GROUP_MIXED;
	Quiz[183].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[184].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[185].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[186].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[187].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[188].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[189].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[190].MyGroup = GROUP_NT_OBSESSION;
	Quiz[191].MyGroup = GROUP_MIXED;
	Quiz[192].MyGroup = GROUP_NT_TALENT;
	Quiz[193].MyGroup = GROUP_NT_HUNTING;
	Quiz[194].MyGroup = GROUP_NT_TALENT;
	Quiz[195].MyGroup = GROUP_SOCIAL;
	Quiz[196].MyGroup = GROUP_SOCIAL;
	Quiz[197].MyGroup = GROUP_NT_OBSESSION;
	Quiz[198].MyGroup = GROUP_MIXED;
	Quiz[199].MyGroup = GROUP_NT_OBSESSION;
	Quiz[200].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[201].MyGroup = GROUP_NT_SENSORY;
	Quiz[202].MyGroup = GROUP_NT_HUNTING;
	Quiz[203].MyGroup = GROUP_NT_HUNTING;
	Quiz[204].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[205].MyGroup = GROUP_MIXED;
	Quiz[206].MyGroup = GROUP_ASPIE_SENSORY;
	Quiz[207].MyGroup = GROUP_MIXED;
	Quiz[208].MyGroup = GROUP_NT_SENSORY;
	Quiz[209].MyGroup = GROUP_ACTIVITY;

#ifdef ENGLISH
	Quiz[0].Text = "Can you easily hear small sounds?";
	Quiz[1].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
	Quiz[2].Text = "Do certain phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
 	Quiz[3].Text = "Do you have a very acute sense of smell and/or taste?";
 	Quiz[4].Text = "Are you over-or under-sensitive to heat, cold, wind, humidity etc?";
 	Quiz[5].Text = "Do you squint now or have done in the past?";
 	Quiz[6].Text = "Do you often use peripheral vision?";
 	Quiz[7].Text = "Are you irritated by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' textures/material?";
 	Quiz[8].Text = "Are you bothered by fluorescent light?";
 	Quiz[9].Text = "Are you sensitive to electromagnetic fields?";
 	Quiz[10].Text= "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?";
 	Quiz[11].Text = "Do you dislike touch?";
 	Quiz[12].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
 	Quiz[13].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
 	Quiz[14].Text = "Do you have unusual eating patterns?";
 	Quiz[15].Text = "Do you need regular eating patterns?";
 	Quiz[16].Text = "Do you see yourself as sensitive?";
 	Quiz[17].Text = "Do you have difficulty hopping, skipping or riding a bike?";
 	Quiz[18].Text = "Do you have a tendency to drop things?";
 	Quiz[19].Text = "Were you quick to learn tasks requiring fine coordination?";
 	Quiz[20].Text = "Do you have difficulty with throwing and catching a ball?";
 	Quiz[21].Text = "Can you easily handle a ball?";
	Quiz[22].Text = "Did you enjoy classes like handi-work or gymnasics in school?";
 	Quiz[23].Text = "Do you have a better than average posture?";
 	Quiz[24].Text = "Do you excel in crafts requiring much patience and skill?";
 	Quiz[25].Text = "Do you enjoy playing musical instruments?";
 	Quiz[26].Text = "Are you often injured in the kitchen?";
 	Quiz[27].Text = "Are you the last one to finish manual tasks?";
 	Quiz[28].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
 	Quiz[29].Text = "Is it easy for you to interpret body language?";
 	Quiz[30].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
 	Quiz[31].Text = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
 	Quiz[32].Text = "Do others often misunderstand you?";
 	Quiz[33].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
 	Quiz[34].Text = "Do you think before you speak?";
 	Quiz[35].Text = "Do you speak before you think?";
 	Quiz[36].Text = "Are you good at small talk?";
 	Quiz[37].Text = "Do you lose interest in what others have to say?";
 	Quiz[38].Text = "Do you have difficulty summarizing and reporting conversations or describing events?";
 	Quiz[39].Text = "Do you sense the boundaries of others without being told?";
 	Quiz[40].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly instructed?";
 	Quiz[41].Text = "Do you understand figures of speech, parodies, allegories, irony etc with ease?";
 	Quiz[42].Text = "Are you so honest and sincere yourself that you assume everyone is?";
 	Quiz[43].Text = "Do you miss dishonesty and hidden agendas?";
 	Quiz[44].Text = "Do you have problems recognizing faces out of their usual context (e.g. your doctor at the supermarket without his white robe)?";
 	Quiz[45].Text = "Do you have an exceptional ability to put faces to names?";
 	Quiz[46].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
 	Quiz[47].Text = "Do you read people well?";
 	Quiz[48].Text = "Are you intuitive about what people need from you?";
 	Quiz[49].Text = "Are you often surprised what people's motives are ?";
 	Quiz[50].Text = "Have you taken initiative only to find out it was not wanted?";
 	Quiz[51].Text = "Are your friends mostly co-workers or class-mates?";
 	Quiz[52].Text = "Do you have difficulties with pronunciation?";
 	Quiz[53].Text = "Do you blink or roll your eyes?";
 	Quiz[54].Text = "Do you thrust your tounge at the wrong occassion?";
 	Quiz[55].Text = "Do you sniff involuntary?";
 	Quiz[56].Text = "Do you swear a lot?";
 	Quiz[57].Text = "Do you stammer when stressed?";
 	Quiz[58].Text = "Do you have unconventional, often unique ways of solving problems?";
	Quiz[59].Text = "Do you focus on one interest at a time and become an expert on that subject?";
 	Quiz[60].Text = "Do you prefer to take a more general interest in many areas?";
 	Quiz[61].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
 	Quiz[62].Text = "Do you like having other involved in your pursuits?";
 	Quiz[63].Text = "Do you have lots of things going on all at once and enjoy doing them simultaneously?";
 	Quiz[64].Text = "Is you imagination unusual, with unique ideas that others don't have?";
 	Quiz[65].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
 	Quiz[66].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
 	Quiz[67].Text = "Are you very gifted in one or more areas?";
 	Quiz[68].Text = "Do you have one special talent which you have emphasised and worked on?";
 	Quiz[69].Text = "Do you enjoy learning a little of everything even if it is not something of particular interest?";
 	Quiz[70].Text = "Do you find it very hard to learn things that you are not interested in?";
 	Quiz[71].Text = "Are you fascinated by dates and/or numbers?";
 	Quiz[72].Text = "Do you prefer being told the bottom line rather than having to find your own way there?";
 	Quiz[73].Text = "Do you enjoy having a variety of choices to make each day?";
 	Quiz[74].Text = "Do you welcome a surprise, even if it means being taken off task?";
 	Quiz[75].Text = "Do you find a little danger in your life energising?";
 	Quiz[76].Text = "Do you cheerfully redecorate or try wearing a different style of clothing?";
 	Quiz[77].Text = "Do you have certain simple & logical routines which you need to follow?";
 	Quiz[78].Text = "Do you have a need for comfort items like blankets, stuffed animals etc?";
 	Quiz[79].Text = "Do you have the need for something new and exciting get motivated?";
 	Quiz[80].Text = "Are you relaxed about whether or not you might have forgotten to do something which normally you would do (locking the door, unplugging an appliance)?";
 	Quiz[81].Text = "Do you like to explore new places and take part in a new activity when somebody else takes the initiative?";
 	Quiz[82].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
 	Quiz[83].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
 	Quiz[84].Text = "Do you sometimes get very emotional about simple objects?";
 	Quiz[85].Text = "Are you gracious about criticism, correction and direction?";
 	Quiz[86].Text = "Do you like to collect items to make a set?";
 	Quiz[87].Text = "Do you see the value in owning one of a kind?";
 	Quiz[88].Text = "Do you crave order in your home and work environments?";
 	Quiz[89].Text = "Do you have contamination fears of germs, dirt, etc?";
 	Quiz[90].Text = "Do you have phobias?";
 	Quiz[91].Text = "Do you find yourself at ease in romantic situations?";
 	Quiz[92].Text = "Are you energised by being in the company of others?";
 	Quiz[93].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
 	Quiz[94].Text = "Do you spend more time getting to know others than yourself?";
 	Quiz[95].Text = "Are you comfortable in social situations and with new people?";
	Quiz[96].Text = "Do you understand why the loss of a pen can be more devastating than the loss of a relationship?";
 	Quiz[97].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
 	Quiz[98].Text = "Have you been bullied, abused or taken advantage of in various situations?";
 	Quiz[99].Text = "Do you mostly prefer to play/work/do things on your own - unsupervised?";
 	Quiz[100].Text= "Do you enjoy working to deadline?";
 	Quiz[101].Text= "Do you easily get frustrated and upset when you are stressed, tired, hungry, interrupted, questioned, over-stimulated, or when things don't go as you had anticipated?";
 	Quiz[102].Text= "Do you prefer to talk only when you have something relevant to say?";
 	Quiz[103].Text= "Do you have an intuitive sense of when to do the right thing socially?";
 	Quiz[104].Text= "Do you know when you are expected to offer an apology?";
 	Quiz[105].Text= "Do you see yourself as putting people first, before ideals and objects?";
 	Quiz[106].Text= "Do you get surprised and disappointed when people are unfriendly and don't seem to understand or accept you as you are?";
 	Quiz[107].Text= "Do you see social rejection as an opportunity to grow as a human being?";
 	Quiz[108].Text= "Do you sometimes not feel anything at all, even though other people expect you to?";
 	Quiz[109].Text= "Do you judge a potential mate as most anybody else would?";
 	Quiz[110].Text= "Do people think you have a good sense of humour?";
 	Quiz[111].Text= "Does shaking hands tell you a lot about a person?";
 	Quiz[112].Text= "Does an unplanned hug make you jump out of your skin?";
 	Quiz[113].Text= "Have you felt different from others for most of your life?";
 	Quiz[114].Text= "Do you often feel overwhelmed when having to work alone?";
 	Quiz[115].Text= "Does it matter how others view you?";
 	Quiz[116].Text= "Do you take pride in your appearance?";
 	Quiz[117].Text= "Do you enjoy standing out and not following the fashions of the day?";
 	Quiz[118].Text= "Are you loyal to certain brands because they are \"fashionable\" or \"must have\"s?";
 	Quiz[119].Text= "Do you detest gossip?";
 	Quiz[120].Text= "Do your friends mean more to you than hobbies and interests?";
 	Quiz[121].Text= "Will you abandon your friends if your activities or ideals clash?";
 	Quiz[122].Text= "Have you felt kinship and belonging to others for most of your life?";
 	Quiz[123].Text= "Do you forget you are in a social situation when something gets your attention?";
 	Quiz[124].Text= "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
 	Quiz[125].Text= "Do you enjoy hosting or arranging events?";
 	Quiz[126].Text= "Do you find preferable/easier to understand & communicate with computers, animals or unusual people?";
 	Quiz[127].Text= "Do you have difficulty compared to others your age in developing relationships and friendships?";
 	Quiz[128].Text= "Are your views typical of your peer group?";
 	Quiz[129].Text= "Do you enjoy team sport and group endeavours?";
 	Quiz[130].Text= "Are you trying to slow down at work because you run out of things to do?";
 	Quiz[131].Text= "Can you read between the lines?";
 	Quiz[132].Text= "Can you spot hidden agendas with ease?";
	Quiz[133].Text= "Are you always aware of other things going on around you even when reading or otherwise occupied?";
 	Quiz[134].Text= "Are your dreams and fantasies much like those of your friends?";
 	Quiz[135].Text= "Do you get a firm feel for the big picture, before noticing details?";
 	Quiz[136].Text= "Do you find predictability and constancy mind-numbing?";
 	Quiz[137].Text= "Are you good at party games?";
 	Quiz[138].Text= "Do you prefer troubleshooting to using a manual when technical problems arise?";
 	Quiz[139].Text= "Can you remember a discussion verbatim even days or weeks after?";
 	Quiz[140].Text= "Do you often forget were you put things?";
 	Quiz[141].Text= "Do you miss appointments often?";
 	Quiz[142].Text= "Are you the one everyone relies on to remember birthdays?";
 	Quiz[143].Text= "Do you sometimes show up without the notes you need?";
 	Quiz[144].Text= "Do you have things so well in hand that you've anticipate what will be asked for?";
 	Quiz[145].Text= "Are you the one relied on to remember what needs to be done during a project?";
 	Quiz[146].Text= "Do you take on too much because it is easier than having to explain to others how to do it?";
 	Quiz[147].Text= "Do you often work through lunch or breaks to fix mistakes and get things done on time?";
 	Quiz[148].Text= "Would you rather leave the organising of events to others?";
 	Quiz[149].Text= "Are you easily distracted or overwhelmed?";
 	Quiz[150].Text= "Are you impulsive/restless?";
 	Quiz[151].Text= "Are you relaxed most anywhere, anytime?";
 	Quiz[152].Text= "Do you have regular periods of high activity interspaced with periods of lower activity?";
 	Quiz[153].Text= "Would you like to sleep all winter?";
 	Quiz[154].Text= "Do you have regular periods of needing more sleep interspaced with periods of needing less sleep?";
 	Quiz[155].Text= "Do your feelings cycle regulary between hopelessness and extremely high confidence?";
 	Quiz[156].Text= "Do you have trouble reading clocks?";
 	Quiz[157].Text= "Do you find it easy to understand calendars?";
 	Quiz[158].Text= "Do find it easy to remember math formulas?";
 	Quiz[159].Text= "Do you fail to carry a number through to the next part of the calculation?";
 	Quiz[160].Text= "Do you find it difficult to calculate change received from a purchase?";
 	Quiz[161].Text= "Do you have difficulty remembering scores during games?";
 	Quiz[162].Text= "Do you find it hard to recognise phone numbers when said in a different way?";
 	Quiz[163].Text= "Are you a slow reader?";
 	Quiz[164].Text= "Do you often make spelling errors?";
 	Quiz[165].Text= "Do you find it difficult to taking notes in lectures?";
 	Quiz[166].Text= "Do you work rarely require editing?";
 	Quiz[167].Text= "Do you enjoy reading?";
 	Quiz[168].Text= "Is reading a chore?";
 	Quiz[169].Text= "Do you rely on recording devices rather than notes?";
	Quiz[170].Text= "Do you always carry a notepad?";
 	Quiz[171].Text= "Do you enjoy games but forget the rules?";
 	Quiz[172].Text= "Do you remember rules of a game but not enjoy playing?";
 	Quiz[173].Text= "Do you find it difficult to read written material unless it is very interesting or very easy?";
 	Quiz[174].Text= "Do you primarily read fiction for entertainment?";
 	Quiz[175].Text= "Do you need to see, touch or do things yourself in order to remember them?";
 	Quiz[176].Text= "Do you have poor concept of time?";
 	Quiz[177].Text= "Do you have difficulties judging distances, height, depth or speed?";
 	Quiz[178].Text= "Do you instinctively know what time it is when someone asks you?";
 	Quiz[179].Text= "Do you feel an urge to peel skin-flakes off yourself and /or others?";
 	Quiz[180].Text= "Do you find instructions confusing - - especially several at the same time?";
 	Quiz[181].Text= "Are you lefthanded or ambidextrious?";
 	Quiz[182].Text= "Do you look, feel or act younger than your biological age?";
 	Quiz[183].Text= "Do you have extra ribs or vertebrae?";
 	Quiz[184].Text= "Do you have food intolerances?";
 	Quiz[185].Text= "Do you have allergies?";
 	Quiz[186].Text= "Do you have eczema?";
 	Quiz[187].Text= "Do you have glue ear?";
 	Quiz[188].Text= "Are you strong-willed and stubborn?";
 	Quiz[189].Text= "Do you often question authority?";
 	Quiz[190].Text= "Do you trust authorities as long as they have the proper credentials?";
 	Quiz[191].Text= "Do you have a need to confess?";
 	Quiz[192].Text= "Do you require some instruction before solving a problem?";
 	Quiz[193].Text= "Can you easily remember sequences of past events?";
 	Quiz[194].Text= "Do you find it easy to sequence ideas in writing?";
 	Quiz[195].Text= "Do you feel awkward in romantic situations?";
 	Quiz[196].Text= "Do you enjoy working as a partner or team member, with supervision?";
 	Quiz[197].Text= "Do you talk to put others at ease even when you really have nothing to say?";
 	Quiz[198].Text= "Could you care less how others see you?";
 	Quiz[199].Text= "Do you consider yourself fashionable?";
 	Quiz[200].Text= "Hyperlexia";
 	Quiz[201].Text= "Dyspraxia";
 	Quiz[202].Text= "Dyslexia";
 	Quiz[203].Text= "Dyscalculia";
 	Quiz[204].Text= "OCD";
 	Quiz[205].Text= "ODD";
 	Quiz[206].Text= "Synaesthesia";
	Quiz[207].Text= "Prosapagnosia";
 	Quiz[208].Text= "Dysgraphia";
 	Quiz[209].Text= "Bipolar";

#endif

#ifdef SWEDISH
 	Quiz[0].Text = "Hör du lätt svaga ljud?";
 	Quiz[1].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
 	Quiz[2].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
 	Quiz[3].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
 	Quiz[4].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
 	Quiz[5].Text = "Skelar du eller har gjort det?";
 	Quiz[6].Text = "Använder du ofta periferseende?";
 	Quiz[7].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda av 'fel' material?";
 	Quiz[8].Text = "Är du känslig för vissa typer av ljus, t.ex lysrörsljus?";
 	Quiz[9].Text = "Är du känslig för elektromagnetiska fält?";
 	Quiz[10].Text= "Blir du lätt överstimulerad och stressad av för mycket ljud, mönster, flimmer, oreda, trängsel o. dyl.?";
 	Quiz[11].Text = "Ogillar du beröring?";
 	Quiz[12].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
 	Quiz[13].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
 	Quiz[14].Text = "Har du ovanliga ätvanor?";
 	Quiz[15].Text = "Behöver du regelbundna ätvanor?";
 	Quiz[16].Text = "Anser du att du är känslig?";
 	Quiz[17].Text = "Har du svårt för att hoppa eller cykla?";
 	Quiz[18].Text = "Har du en tendens att tappa saker?";
 	Quiz[19].Text = "Har du lätt för att lära dig saker som kräver bra finmotorik?";
 	Quiz[20].Text = "Har du svårt för att kasta eller fånga en boll?";
 	Quiz[21].Text = "Har du bra bollsinne?";
 	Quiz[22].Text = "Tyckte du om praktiska ämnen som slöjd och gymnastik i skolan?";
 	Quiz[23].Text = "Har du bättre kroppshållning än normalt?";
 	Quiz[24].Text = "Klarar du lätt av hantverk som kräver tålamod och skicklighet?";
 	Quiz[25].Text = "Tycker du om att spela musikinstrument?";
 	Quiz[26].Text = "Skadar du dig ofta i köket?";
 	Quiz[27].Text = "Är du sist med att avsluta manuella uppgifter?";
 	Quiz[28].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
 	Quiz[29].Text = "Har du lätt för att tolka kroppsspråk?";
	Quiz[30].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
 	Quiz[31].Text = "Är du oftast omedveten om outtalade sociala regler?";
 	Quiz[32].Text = "Missförstår andra ofta dig?";
 	Quiz[33].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
 	Quiz[34].Text = "Tänker du innan du talar?";
 	Quiz[35].Text = "Talar du innan du tänker?";
 	Quiz[36].Text = "Är du bra på kallprat?";
 	Quiz[37].Text = "Tappar du intresse för vad andra säger?";
 	Quiz[38].Text = "Har du problem med att redogöra för konversationer eller händelser och att sammanfatta?";
 	Quiz[39].Text = "Känner du av andras gränser utan att någon talar om dem?";
 	Quiz[40].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
 	Quiz[41].Text = "Har du lätt för att förstå talesätt, allegorier, parodier, ironi och liknande?";
 	Quiz[42].Text = "Är det så naturligt för dig att vara totalt ärlig att du tror alla är sådana?";
 	Quiz[43].Text = "Missar du oärlighet och dolda motiv?";
 	Quiz[44].Text = "Har du svårt att känna igen ansikten i oväntade sammanhang (t ex din läkare i snabbköpet utan sin vita rock?";
 	Quiz[45].Text = "Har du lätt för att koppla ansikten till namn?";
 	Quiz[46].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
 	Quiz[47].Text = "Läser du av folk bra?";
 	Quiz[48].Text = "Känner du intuitivt av vad folk behöver från dig?";
 	Quiz[49].Text = "Blir du ofta överraskad av vad folks motiv är?";
 	Quiz[50].Text = "Tar du ibland initiativ som inte visar sig önskade?";
 	Quiz[51].Text = "Är dina vänner mestadels arbetskamrater eller studiekamrater?";
 	Quiz[52].Text = "Har du svårigheter med uttal?";
 	Quiz[53].Text = "Blinkar eller rullar du med ögona?";
 	Quiz[54].Text = "Räcker du ut tungan vid fel tillfällen?";
 	Quiz[55].Text = "Sniffar du ofrivilligt?";
 	Quiz[56].Text = "Svär du mycket?";
 	Quiz[57].Text = "Stammar du när du blir stressad?";
 	Quiz[58].Text = "Har du okonventionella, ofta unika sätt att lösa problem på??";
 	Quiz[59].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
 	Quiz[60].Text = "Föredrar du mer generellt intresse inom många olika områden?";
 	Quiz[61].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat (äta, duscha, sova, andra människor etc.)?";
 	Quiz[62].Text = "Tycker du om att ha med andra i dina aktiviteter?";
 	Quiz[63].Text = "Har du många saker på gång och gillar att göra dem samtidigt?";
 	Quiz[64].Text = "Är din fantasi ovanlig med unika idéer som andra inte har?";
 	Quiz[65].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
 	Quiz[66].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
	Quiz[67].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
 	Quiz[68].Text = "Har du en speciell talang som du har jobbat med?";
 	Quiz[69].Text = "Tycker du om att lära lite om allt möjligt även om du inte är speciellt intresserad?";
 	Quiz[70].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
 	Quiz[71].Text = "Är du fascinerad av datum och/eller siffror?";
 	Quiz[72].Text = "Föredrar du att få veta av andra hur saker fungerar snarare än att ta reda på det på ditt eget sätt?";
 	Quiz[73].Text = "Gillar du att ha många olika saker du kan göra varje dag?";
 	Quiz[74].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
 	Quiz[75].Text = "Tycker du det är utmanande med faror?";
 	Quiz[76].Text = "Möblerar du gärna om eller försöker byta stil på kläder?";
 	Quiz[77].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
 	Quiz[78].Text = "Har du ibland behov av gosefilt, kramdjur eller liknande?";
 	Quiz[79].Text = "Behöver du nya utmaningar för att bli motiverad?";
 	Quiz[80].Text = "Är du lugn för att du inte glömt något du brukar göra (låsa dörren, stänga av spisen)?";
 	Quiz[81].Text = "Tycker du om att utforska nya platser och ta del i nya aktiviteter på andras initiativ?";
 	Quiz[82].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
 	Quiz[83].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
 	Quiz[84].Text = "Brukar du ofta fästa dig vid olika föremål?";
 	Quiz[85].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
 	Quiz[86].Text = "Tycker du om att samla på saker?";
 	Quiz[87].Text = "Tycker du det finns ett värde i att äga en sak av varje sort?";
 	Quiz[88].Text = "Behöver du ordning i ditt hem och på din arbetsplats?";
 	Quiz[89].Text = "Är du rädd för baciller, smuts e.d.?";
 	Quiz[90].Text = "Har du fobier?";
 	Quiz[91].Text = "Trivs du med romantiska situationer?";
 	Quiz[92].Text = "Får du energi av att vara i sällskap med andra?";
 	Quiz[93].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred??";
 	Quiz[94].Text = "Använder du mer tid för att lära känna andra än dig själv?";
 	Quiz[95].Text = "Känner du dig hemma i sociala situationer med nya människor?";
 	Quiz[96].Text = "Förstår du varför en förlust av en penna kan vara värre än en förlust av en partner?";
 	Quiz[97].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
 	Quiz[98].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
 	Quiz[99].Text = "Föredrar du att mestadels leka/arbeta/göra saker på egen hand - utan övervakning?";
 	Quiz[100].Text= "Tycker du om att jobba emot en sluttid?";
 	Quiz[101].Text= "Blir du lätt frustrerad och upprörd när du blir stressad, trött, hungrig, ifrågasatt, avbruten, överstimulerad, eller när saker inte går som du har tänkt dig och ställt in dig på?";
 	Quiz[102].Text= "Pratar du mestadels när du har något att tillföra en diskussion?";
 	Quiz[103].Text= "Känner du intuitivt av vad som är rätt socialt?";
	Quiz[104].Text= "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
 	Quiz[105].Text= "Sätter du människor före saker och idéer?";
 	Quiz[106].Text= "Blir du förvånad och besviken när folk är ovänliga och inte tycks förstå eller acceptera dig som du är?";
 	Quiz[107].Text= "Ser du socialt avvisande som ett sätt att växa som människa?";
 	Quiz[108].Text= "Händer det att du inte känner något alls fastän andra tycker att du borde?";
 	Quiz[109].Text= "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
 	Quiz[110].Text= "Tycker folk att du har ett bra sinne humor?";
 	Quiz[111].Text= "Talar ett handslag om mycket om en person?";
 	Quiz[112].Text= "Gör en oplanerad kram att du vill hoppa ur ditt skinn?";
 	Quiz[113].Text= "Har du känt dig annorlunda största delen av ditt liv?";
 	Quiz[114].Text= "Känner du dig ofta överväldigad av att jobba ensam?";
 	Quiz[115].Text= "Har det betydelse hur andra ser på dig?";
 	Quiz[116].Text= "Är du stolt över ditt utseende?";
 	Quiz[117].Text= "Tycker du om att sticka ut och att inte följa modet?";
 	Quiz[118].Text= "Är du lojal inför vissa märken för att de är \"inne\" och man måste ha dem?";
 	Quiz[119].Text= "Avskyr du skvaller?";
 	Quiz[120].Text= "Betyder vänner mer för dig än hobbies och intressen?";
 	Quiz[121].Text= "Överger du vänner om dina aktiviteter eller ideal kommer ikläm?";
 	Quiz[122].Text= "Har du känt att du tillhör en grupp större delen av ditt liv?";
 	Quiz[123].Text= "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
 	Quiz[124].Text= "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
 	Quiz[125].Text= "Tycker du om att anordna eller vara värd för aktiviter?";
 	Quiz[126].Text= "Tycker du det är att föredra/lättare att förstå och kommunicera med datorer, djur eller udda människor?";
 	Quiz[127].Text= "Har du svårare än dina jämnåriga att få vänner och/eller partners??";
 	Quiz[128].Text= "Är dina åsikter typiska för dina jämnåriga?";
 	Quiz[129].Text= "Tycker du om lagsporter och andra gruppaktiviteter?";
 	Quiz[130].Text= "Försöker du sakta ned på jobbet för att du riskerar att bli sysslolös?";
 	Quiz[131].Text= "Kan du läsa mellan raderna?";
 	Quiz[132].Text= "Kan du lätt avslöja dolda motiv?";
 	Quiz[133].Text= "Är du alltid medveten om det som försigår runt omkring dig även om du läser eller sysslar med något annat?";
 	Quiz[134].Text= "Är dina drömmar och fantasier likadana som dina vänners?";
 	Quiz[135].Text= "Tar du först in helheten innan du upptäcker detaljer?";
 	Quiz[136].Text= "Tycker du att förutsägbarhet och rutiner är olidigt?";
 	Quiz[137].Text= "Är du bra på sällskapsspel?";
 	Quiz[138].Text= "Föredrar du felsökning framför att läsa en manual när tekniska problem uppstår?";
 	Quiz[139].Text= "Kan du komma ihåg en diskussion ordagrant dagar eller veckor efter?";
 	Quiz[140].Text= "Glömmer du ofta var du lagt saker?";
	Quiz[141].Text= "Glömmer du ofta planerade aktiviteter?";
 	Quiz[142].Text= "Litar andra på dig när det gäller att komma ihåg födelsedagar?";
 	Quiz[143].Text= "Dyker du ibland upp utan de anteckningar du behöver?";
 	Quiz[144].Text= "Har du allting med som du kan tänkas bli ombedd att visa?";
 	Quiz[145].Text= "Är du någon som man anlitar för att komma ihåg vad som behöver göras i ett projekt?";
 	Quiz[146].Text= "Tar du på dig för mycket för att det är enklare att göra saker själv än att förklara för andra?";
 	Quiz[147].Text= "Jobbar du ofta över lunch och/eller raster för att rätta till misstag och/eller bli klar i tid?";
 	Quiz[148].Text= "Låter du hellre andra organisera aktiviteter?";
 	Quiz[149].Text= "Är du lätt att distrahera eller överväldiga?";
 	Quiz[150].Text= "Är du impulsiv/rastlös?";
 	Quiz[151].Text= "Är du avspänd nästan alltid och överallt?";
 	Quiz[152].Text= "Har du perioder av hög aktivitet med mellanliggande perioder med låg aktivitet?";
 	Quiz[153].Text= "Skulle du vilja sova hela vintern?";
 	Quiz[154].Text= "Har du perioder då du behöver mycket sömn med mellanliggande perioder då du behöver lite sömn?";
 	Quiz[155].Text= "Växlar dina känslor mellan hopplöshet och extremt bra självförtroende?";
 	Quiz[156].Text= "Har du svårigheter att läsa av klockor?";
 	Quiz[157].Text= "Förstår du lätt dig på kalendrar?";
 	Quiz[158].Text= "Tycker du det är enkelt att komma ihåg matematiska formler?";
 	Quiz[159].Text= "Glömmer du föra över ett tal till nästa del i en beräkning?";
 	Quiz[160].Text= "Tycker du det är svårt att beräkna växel på ett köp?";
 	Quiz[161].Text= "Har du svårt för att komma ihåg poängställningar under spel?";
 	Quiz[162].Text= "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
 	Quiz[163].Text= "Läser du sakta?";
 	Quiz[164].Text= "Gör du ofta stavfel?";
 	Quiz[165].Text= "Har du svårt att göra anteckningar under föreläsningar?";
 	Quiz[166].Text= "Behöver ditt arbete sällan rättas?";
 	Quiz[167].Text= "Tycker du om att läsa?";
 	Quiz[168].Text= "Är läsning en börda?";
 	Quiz[169].Text= "Litar du på inspelningsapparater snarare än anteckningar?";
 	Quiz[170].Text= "Bär du alltid med dig ett anteckningsblock?";
 	Quiz[171].Text= "Gillar du spel men glömmer regler?";
 	Quiz[172].Text= "Kommer du ihåg regler men tycker inte om att spela?";
 	Quiz[173].Text= "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
 	Quiz[174].Text= "Läser du huvudsakligen för underhållningens skull?";
 	Quiz[175].Text= "Har du behov av att SE, ta i, eller själv bearbeta saker för att riktigt minnas dem?";
 	Quiz[176].Text= "Har du dålig tidsuppfattning?";
 	Quiz[177].Text= "Har du svårigheter att bedöma avstånd, höjd, djup och hastighet?";
	Quiz[178].Text= "Vet du instinktivt hur mycket klockan är när någon frågar dig?";
 	Quiz[179].Text= "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
 	Quiz[180].Text= "Blir du förvirrad av instruktioner - särskilt flera på en gång?";
 	Quiz[181].Text= "Är du vänsterhänt eller bådahänt?";
 	Quiz[182].Text= "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
 	Quiz[183].Text= "Har du extra revben eller kotor?";
 	Quiz[184].Text= "Är du intolerant mot någon slags mat?";
 	Quiz[185].Text= "Har du allergi?";
 	Quiz[186].Text= "Har du eksem?";
 	Quiz[187].Text= "Har du vätska i mellanörat?";
 	Quiz[188].Text= "Är du envis med en stark egen vilja?";
 	Quiz[189].Text= "Ifrågasätter du ofta auktoriteter?";
 	Quiz[190].Text= "Litar du på auktoriteter så länge de har lämpliga kvalifikationer?";
 	Quiz[191].Text= "Vill du gärna bekänna?";
 	Quiz[192].Text= "Behöver du lite instruktioner innan du löser problem?";
 	Quiz[193].Text= "Kan du enkelt komma ihåg sekvenser av gångna händelser?";
 	Quiz[194].Text= "Tycker du det är lätt att skriva ned sekvenser av idéer?";
 	Quiz[195].Text= "Känner du dig obekväm i romantiska situationer?";
 	Quiz[196].Text= "Tycker du om att jobba som en partner eller projektmedlem, under övervakning?";
 	Quiz[197].Text= "Pratar du för att andra ska känna sig väl till mods även om du inte har något att säga?";
 	Quiz[198].Text= "Spelar det inte dig någon roll hur andra ser på dig?";
 	Quiz[199].Text= "Ser du dig själv som ett modelejon?";
 	Quiz[200].Text= "Hyperlexi";
 	Quiz[201].Text= "Dyspraxi";
 	Quiz[202].Text= "Dyslexi";
 	Quiz[203].Text= "Dyskaluli";
 	Quiz[204].Text= "OCD";
 	Quiz[205].Text= "ODD";
 	Quiz[206].Text= "Synaestesia";
 	Quiz[207].Text= "Prosapagnosi";
 	Quiz[208].Text= "Dysgrafi";
 	Quiz[209].Text= "Bipolär";

#endif
}

/*##########################################################################
#
#   Name       : TQuizNd::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("kolozzeum.com", "kolozzeum.com/kolozzeum/showthread.php?t=65633");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
}

/*##################  TQuizNd::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizNd::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

//
// uncomment to exclude autism/AS from no refer group
//
//		if (ref == &NoRef)
//            if (Row.Autism || Row.Aspie)
//                ref = 0;

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.TS == 1)
			UpdateReferer(&SelfTsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.TS == 2)
			UpdateReferer(&DxTsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

//
// uncomment to exclude autism/AS from ND-diagnosis
//
//		if (Row.Aspie == 0 && Row.Autism == 0)
		{
			if (Row.Hyperlexia)
				UpdateReferer(&HyperlexiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.Dyspraxia)
				UpdateReferer(&DyspraxiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.Dyslexia)
				UpdateReferer(&DyslexiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.Dyscalculia)
				UpdateReferer(&DyscalculiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.OCD)
				UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.ODD)
				UpdateReferer(&ODDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.Synaesthesia)
				UpdateReferer(&SynaesthesiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.PA)
				UpdateReferer(&PARef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.Dysgraphia)
				UpdateReferer(&DysgraphiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

			if (Row.Bipolar)
				UpdateReferer(&BipolarRef, Row.AsResult, Row.NtResult, Row.GroupResult);
		}

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
#   Name       : TQuizNd::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::LoadPopulations()
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
		Row.Quiz[200] = Row.Hyperlexia + 1;
		Row.Quiz[201] = Row.Dyspraxia + 1;
		Row.Quiz[202] = Row.Dyslexia + 1;
		Row.Quiz[203] = Row.Dyscalculia + 1;
		Row.Quiz[204] = Row.OCD + 1;
		Row.Quiz[205] = Row.ODD + 1;
		Row.Quiz[206] = Row.Synaesthesia + 1;
		Row.Quiz[207] = Row.PA + 1;
		Row.Quiz[208] = Row.Dysgraphia + 1;
		Row.Quiz[209] = Row.Bipolar + 1;

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
		    else
			{
			    if (i < 200)
			    {
    			    score = Row.Quiz[i] - 1;
					id = IdArr[i];
			    
		    	    DsmAutism.Add(Row.Autism, id, score);
    			    DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
		    	    DsmTs.Add(Row.TS, id, score);
			        DsmHyperlexia.Add(Row.Hyperlexia, id, score);
			        DsmDyspraxia.Add(Row.Dyspraxia, id, score);
    			    DsmDyslexia.Add(Row.Dyslexia, id, score);
	    		    DsmDyscalculia.Add(Row.Dyscalculia, id, score);
		    	    DsmOCD.Add(Row.OCD, id, score);
			        DsmODD.Add(Row.ODD, id, score);
    			    DsmSynaesthesia.Add(Row.Synaesthesia, id, score);
	    		    DsmPA.Add(Row.PA, id, score);
		    	    DsmBipolar.Add(Row.Bipolar, id, score);
			        DsmDysgraphia.Add(Row.Dysgraphia, id, score);
			    }
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

		if (Row.TS == 2)
			DxArr[DX_TS] = DX_STATE_YES;

		if (Row.TS == 1)
			DxArr[DX_TS] = DX_STATE_SELF;

		if (Row.TS == 0)
			DxArr[DX_TS] = DX_STATE_NO;

		if (Row.Hyperlexia == 2)
			DxArr[DX_HYPERLEXIA] = DX_STATE_YES;

		if (Row.Hyperlexia == 1)
			DxArr[DX_HYPERLEXIA] = DX_STATE_SELF;

		if (Row.Hyperlexia == 0)
			DxArr[DX_HYPERLEXIA] = DX_STATE_NO;

		if (Row.Dyspraxia == 2)
			DxArr[DX_DYSPRAXIA] = DX_STATE_YES;

		if (Row.Dyspraxia == 1)
			DxArr[DX_DYSPRAXIA] = DX_STATE_SELF;

		if (Row.Dyspraxia == 0)
			DxArr[DX_DYSPRAXIA] = DX_STATE_NO;

		if (Row.Dyslexia == 2)
			DxArr[DX_DYSLEXIA] = DX_STATE_YES;

		if (Row.Dyslexia == 1)
			DxArr[DX_DYSLEXIA] = DX_STATE_SELF;

		if (Row.Dyslexia == 0)
			DxArr[DX_DYSLEXIA] = DX_STATE_NO;

		if (Row.Dyscalculia == 2)
			DxArr[DX_DYSCALCULIA] = DX_STATE_YES;

		if (Row.Dyscalculia == 1)
			DxArr[DX_DYSCALCULIA] = DX_STATE_SELF;

		if (Row.Dyscalculia == 0)
			DxArr[DX_DYSCALCULIA] = DX_STATE_NO;

		if (Row.OCD == 2)
			DxArr[DX_OCD] = DX_STATE_YES;

		if (Row.OCD == 1)
			DxArr[DX_OCD] = DX_STATE_SELF;

		if (Row.OCD == 0)
			DxArr[DX_OCD] = DX_STATE_NO;

		if (Row.ODD == 2)
			DxArr[DX_ODD] = DX_STATE_YES;

		if (Row.ODD == 1)
			DxArr[DX_ODD] = DX_STATE_SELF;

		if (Row.ODD == 0)
			DxArr[DX_ODD] = DX_STATE_NO;

		if (Row.Synaesthesia == 2)
			DxArr[DX_SYNAESTHESIA] = DX_STATE_YES;

		if (Row.Synaesthesia == 1)
			DxArr[DX_SYNAESTHESIA] = DX_STATE_SELF;

		if (Row.Synaesthesia == 0)
			DxArr[DX_SYNAESTHESIA] = DX_STATE_NO;

		if (Row.PA == 2)
			DxArr[DX_PA] = DX_STATE_YES;

		if (Row.PA == 1)
			DxArr[DX_PA] = DX_STATE_SELF;

		if (Row.PA == 0)
			DxArr[DX_PA] = DX_STATE_NO;

		if (Row.Dysgraphia == 2)
			DxArr[DX_DYSGRAPHIA] = DX_STATE_YES;

		if (Row.Dysgraphia == 1)
			DxArr[DX_DYSGRAPHIA] = DX_STATE_SELF;

		if (Row.Dysgraphia == 0)
			DxArr[DX_DYSGRAPHIA] = DX_STATE_NO;

		if (Row.Bipolar == 2)
			DxArr[DX_BIPOLAR] = DX_STATE_YES;

		if (Row.Bipolar == 1)
			DxArr[DX_BIPOLAR] = DX_STATE_SELF;

		if (Row.Bipolar == 0)
			DxArr[DX_BIPOLAR] = DX_STATE_NO;

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

		if (Row.TS)
			Ts.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Hyperlexia)
			Hyperlexia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dyspraxia)
			Dyspraxia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dyslexia)
			Dyslexia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dyscalculia)
			Dyscalculia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.OCD)
			OCD.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.ODD)
			ODD.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Synaesthesia)
			Synaesthesia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.PA)
			PA.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Dysgraphia)
			Dysgraphia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Bipolar)
			Bipolar.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

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
#   Name       : TQuizNd::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("kolozzeum.com");
	DefineNt("rdos.net/sv");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("xmission.com/~winter");
	DefineAspie("delphiforums.com");
	DefineAspie("assupportgrouponline.co.uk");
}

/*##########################################################################
#
#   Name       : TQuizNd::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII)
{
	DefineGlobalId(      0, 199);
	DefineCross(QuizII,  1, 1);
	DefineCross(QuizIII, 2, 7);
	DefineCross(QuizIII, 3, 2);
	DefineCross(QuizIII, 4, 3);
	DefineCross(QuizIII, 5, 23);
	DefineCross(QuizIII, 6, 8);
	DefineCross(QuizIII, 7, 5);
	DefineCross(QuizIII, 8, 4);
	DefineCross(QuizIII, 9, 9);
	DefineCross(QuizII,  10, 6);
	DefineGlobalId(      11, 200);
	DefineCross(QuizIII, 12, 6);
	DefineCross(QuizIII, 13, 17);
	DefineCross(QuizIII, 14, 19);
	DefineGlobalId(      15, 201);
	DefineGlobalId(      16, 202);
	DefineGlobalId(      17, 203);
	DefineGlobalId(      18, 204);
	DefineGlobalId(      19, 205);
	DefineGlobalId(      20, 206);
	DefineGlobalId(      21, 207);
	DefineGlobalId(      22, 208);
	DefineGlobalId(      23, 209);
	DefineGlobalId(      24, 210);
	DefineGlobalId(      25, 211);
	DefineGlobalId(      26, 212);
	DefineGlobalId(      27, 213);
	DefineCross(QuizIII, 28, 26);
	DefineGlobalId(      29, 214);
	DefineCross(QuizIII, 30, 29);
	DefineCross(QuizIII, 31, 28);
	DefineCross(QuizIII, 32, 37);
	DefineCross(QuizIII, 33, 36);
	DefineGlobalId(      34, 215);
	DefineGlobalId(      35, 216);
	DefineGlobalId(      36, 217);
	DefineGlobalId(      37, 218);
	DefineCross(QuizIII, 38, 39);
	DefineGlobalId(      39, 219);
	DefineCross(QuizIII, 40, 31);
	DefineGlobalId(      41, 220);
	DefineCross(QuizII,  42, 70);
	DefineGlobalId(      43, 221);
	DefineCross(QuizIII, 44, 27);
	DefineGlobalId(      45, 222);
	DefineCross(QuizIII, 46, 41);
	DefineGlobalId(      47, 223);
	DefineGlobalId(      48, 224);
	DefineGlobalId(      49, 225);
	DefineGlobalId(      50, 226);
	DefineGlobalId(      51, 227);
	DefineGlobalId(      52, 228);
	DefineGlobalId(      53, 229);
	DefineGlobalId(      54, 230);
	DefineGlobalId(      55, 231);
	DefineGlobalId(      56, 232);
	DefineGlobalId(      57, 233);
	DefineCross(QuizIII, 58, 69);
	DefineCross(QuizIII, 59, 72);
	DefineGlobalId(      60, 234);
	DefineCross(QuizIII, 61, 70);
	DefineGlobalId(      62, 235);
	DefineGlobalId(      63, 236);
	DefineCross(QuizIII, 64, 73);
	DefineCross(QuizIII, 65, 75);
	DefineCross(QuizIII, 66, 71);
	DefineCross(QuizIII, 67, 77);
	DefineGlobalId(      68, 237);
	DefineGlobalId(      69, 238);
	DefineGlobalId(      70, 239);
	DefineCross(QuizIII, 71, 74);
	DefineGlobalId(      72, 240);
	DefineGlobalId(      73, 241);
	DefineGlobalId(      74, 242);
	DefineGlobalId(      75, 243);
	DefineGlobalId(      76, 244);
	DefineCross(QuizIII, 77, 83);
	DefineCross(QuizI,   78, 34);
	DefineGlobalId(      79, 245);
	DefineGlobalId(      80, 246);
	DefineGlobalId(      81, 247);
	DefineCross(QuizIII, 82, 81);
	DefineGlobalId(      83, 248);
	DefineCross(QuizIII, 84, 85);
	DefineGlobalId(      85, 249);
	DefineCross(QuizIII, 86, 86);
	DefineGlobalId(      87, 250);
	DefineGlobalId(      88, 251);
	DefineGlobalId(      89, 252);
	DefineGlobalId(      90, 253);
	DefineGlobalId(      91, 254);
	DefineGlobalId(      92, 255);
	DefineCross(QuizIII, 93, 46);
	DefineGlobalId(      94, 256);
	DefineGlobalId(      95, 257);
	DefineGlobalId(      96, 258);
	DefineCross(QuizII,  97, 42);
	DefineCross(QuizI,   98, 92);
	DefineCross(QuizIII, 99, 51);
	DefineGlobalId(      100, 259);
	DefineCross(QuizI,   101, 74);
	DefineGlobalId(      102, 260);
	DefineGlobalId(      103, 261);
	DefineCross(QuizII,  104, 47);
	DefineGlobalId(      105, 262);
	DefineCross(QuizI,   106, 93);
	DefineGlobalId(      107, 263);
	DefineCross(QuizIII, 108, 50);
	DefineGlobalId(      109, 264);
	DefineGlobalId(      110, 265);
	DefineGlobalId(      111, 266);
	DefineGlobalId(      112, 267);
	DefineGlobalId(      113, 268);
	DefineGlobalId(      114, 269);
	DefineGlobalId(      115, 270);
	DefineGlobalId(      116, 271);
	DefineGlobalId(      117, 272);
	DefineGlobalId(      118, 273);
	DefineGlobalId(      119, 274);
	DefineCross(QuizII,  120, 76);
	DefineGlobalId(      121, 275);
	DefineGlobalId(      122, 276);
	DefineGlobalId(      123, 277);
	DefineGlobalId(      124, 278);
	DefineGlobalId(      125, 279);
	DefineGlobalId(      126, 280);
	DefineCross(QuizIII, 127, 48);
	DefineGlobalId(      128, 281);
	DefineGlobalId(      129, 282);
	DefineGlobalId(      130, 283);
	DefineGlobalId(      131, 284);
	DefineGlobalId(      132, 285);
	DefineGlobalId(      133, 286);
	DefineGlobalId(      134, 287);
	DefineGlobalId(      135, 288);
	DefineGlobalId(      136, 289);
	DefineGlobalId(      137, 290);
	DefineGlobalId(      138, 291);
	DefineGlobalId(      139, 292);
	DefineGlobalId(      140, 293);
	DefineGlobalId(      141, 294);
	DefineGlobalId(      142, 295);
	DefineGlobalId(      143, 296);
	DefineGlobalId(      144, 297);
	DefineGlobalId(      145, 298);
	DefineGlobalId(      146, 299);
	DefineGlobalId(      147, 300);
	DefineGlobalId(      148, 301);
	DefineGlobalId(      149, 302);
	DefineGlobalId(      150, 303);
	DefineGlobalId(      151, 304);
	DefineGlobalId(      152, 305);
	DefineGlobalId(      153, 306);
	DefineGlobalId(      154, 307);
	DefineGlobalId(      155, 308);
	DefineGlobalId(      156, 309);
	DefineGlobalId(      157, 310);
	DefineGlobalId(      158, 311);
	DefineGlobalId(      159, 312);
	DefineGlobalId(      160, 313);
	DefineGlobalId(      161, 314);
	DefineGlobalId(      162, 315);
	DefineGlobalId(      163, 316);
	DefineGlobalId(      164, 317);
	DefineGlobalId(      165, 318);
	DefineGlobalId(      166, 319);
	DefineGlobalId(      167, 320);
	DefineGlobalId(      168, 321);
	DefineGlobalId(      169, 322);
	DefineGlobalId(      170, 323);
	DefineGlobalId(      171, 324);
	DefineGlobalId(      172, 325);
    DefineCross(QuizIII, 173, 42);
	DefineGlobalId(      174, 326);
	DefineCross(QuizI,   175, 3);
	DefineCross(QuizIII, 176, 14);
	DefineCross(QuizIII, 177, 13);
	DefineGlobalId(      178, 327);
	DefineCross(QuizIII, 179, 15);
	DefineCross(QuizIII, 180, 35);
	DefineGlobalId(      181, 328);
	DefineGlobalId(      182, 329);
	DefineGlobalId(      183, 330);
	DefineGlobalId(      184, 331);
	DefineGlobalId(      185, 332);
	DefineGlobalId(      186, 333);
	DefineGlobalId(      187, 334);
	DefineGlobalId(      188, 335);
	DefineGlobalId(      189, 336);
	DefineGlobalId(      190, 337);
	DefineGlobalId(      191, 338);
	DefineGlobalId(      192, 339);
	DefineGlobalId(      193, 340);
	DefineGlobalId(      194, 341);
	DefineGlobalId(      195, 342);
	DefineGlobalId(      196, 343);
	DefineGlobalId(      197, 344);
	DefineGlobalId(      198, 345);
	DefineGlobalId(      199, 346);
	DefineGlobalId(      200, 347);
	DefineGlobalId(      201, 348);
	DefineGlobalId(      202, 349);
	DefineGlobalId(      203, 350);
	DefineGlobalId(      204, 351);
	DefineGlobalId(      205, 352);
	DefineGlobalId(      206, 353);
	DefineGlobalId(      207, 354);
	DefineGlobalId(      208, 355);
	DefineGlobalId(      209, 356);
}

/*##########################################################################
#
#   Name       : TQuizNd::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizNd::GetReferer(const char *referer, TPopulation *pop)
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
            if (row->BirthYear >= 1980)
                return TRUE;
            else
                return FALSE;

        case PCA_TYPE_OLD:
				if (row->BirthYear <= 1965)
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

/*##################  TQuizNd::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizNd::ExportExcelCase(const char *filename, int PcaType)
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
					if (i >= 200)
						ival = Row.Quiz[i];
					else
						  {
						ival = Row.Quiz[i];
						if (ival)
							ival--;

						if (ival > 2)
							ival = 0;
						  }

					sprintf(str, "\"%d\"", ival);
					file.Write(str);
					if (i != N - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizNd::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizNd::ExportExcelAspie(const char *filename)
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

			sprintf(str, "\"%d\"", ival);
			file.Write(str);
			if (i != N - 1)
				file.Write(", ");
		}
		file.Write("\n");
	}
}

/*##################  TQuizNd::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizNd::ExportExcelGroups(const char *filename)
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
		    if (ival > 2)
			    ival = 0;

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

/*##################  TQuizNd::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizNd::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_MALE)
						d2 = -d2;

					if (PcaType == PCA_TYPE_ALL)
						d3 = -d3;

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
