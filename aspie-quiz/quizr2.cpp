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
# quizr2.cpp
# Quiz R2 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr2.h"
#include "file.h"
#include "quizdbr2.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizR2::TQuizR2
#
#   Purpose....: Constructor for TQuizR2
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR2::TQuizR2(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1)
  : TQuiz(165),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR2::~TQuizR2
#
#   Purpose....: Destructor for TQuizR2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR2::~TQuizR2()
{
}

/*##################  TQuizR2::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR2::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR2::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR2::WriteName(TFile &File)
{
	 File.Write("R2");
}

/*##################  TQuizR2::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR2::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR2::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR2::SetupTexts()
{
  Quiz[39].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[64].Reverse = TRUE;
  Quiz[65].Reverse = TRUE;
  Quiz[66].Reverse = TRUE;
  Quiz[67].Reverse = TRUE;
  Quiz[68].Reverse = TRUE;
  Quiz[69].Reverse = TRUE;
  Quiz[74].Reverse = TRUE;
  Quiz[75].Reverse = TRUE;
  Quiz[76].Reverse = TRUE;
  Quiz[100].Reverse = TRUE;
  Quiz[102].Reverse = TRUE;
  Quiz[132].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[1].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[2].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[3].MyGroup = GROUP_NT_HUNTING;
  Quiz[4].MyGroup = GROUP_NT_HUNTING;
  Quiz[5].MyGroup = GROUP_NT_HUNTING;
  Quiz[6].MyGroup = GROUP_NT_HUNTING;
  Quiz[7].MyGroup = GROUP_NT_SENSORY;
  Quiz[8].MyGroup = GROUP_NT_HUNTING;
  Quiz[9].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[10].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[11].MyGroup = GROUP_MIXED;
  Quiz[12].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[13].MyGroup = GROUP_MIXED;
  Quiz[14].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[15].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[16].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[17].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[18].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[19].MyGroup = GROUP_MIXED;
  Quiz[20].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[21].MyGroup = GROUP_ASPIE_NVC;
  Quiz[22].MyGroup = GROUP_MIXED;
  Quiz[23].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[24].MyGroup = GROUP_MIXED;
  Quiz[25].MyGroup = GROUP_MIXED;
  Quiz[26].MyGroup = GROUP_MIXED;
  Quiz[27].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[28].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[29].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[30].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[31].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[35].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[36].MyGroup = GROUP_NT_TALENT;
  Quiz[37].MyGroup = GROUP_NT_TALENT;
  Quiz[38].MyGroup = GROUP_NT_TALENT;
  Quiz[39].MyGroup = GROUP_NT_TALENT;
  Quiz[40].MyGroup = GROUP_MIXED;
  Quiz[41].MyGroup = GROUP_NT_TALENT;
  Quiz[42].MyGroup = GROUP_NT_SOCIAL;
  Quiz[43].MyGroup = GROUP_NT_NVC;
  Quiz[44].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[45].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[48].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[49].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_NT_OBSESSION;
  Quiz[54].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[55].MyGroup = GROUP_NT_SOCIAL;
  Quiz[56].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[57].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_OBSESSION;
  Quiz[59].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
  Quiz[62].MyGroup = GROUP_MIXED;
  Quiz[63].MyGroup = GROUP_MIXED;
  Quiz[64].MyGroup = GROUP_NT_OBSESSION;
  Quiz[65].MyGroup = GROUP_NT_SOCIAL;
  Quiz[66].MyGroup = GROUP_NT_SOCIAL;
  Quiz[67].MyGroup = GROUP_NT_SOCIAL;
  Quiz[68].MyGroup = GROUP_NT_SOCIAL;
  Quiz[69].MyGroup = GROUP_NT_SOCIAL;
  Quiz[70].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[71].MyGroup = GROUP_SEX;
  Quiz[72].MyGroup = GROUP_MIXED;
  Quiz[73].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[74].MyGroup = GROUP_NT_SOCIAL;
  Quiz[75].MyGroup = GROUP_NT_OBSESSION;
  Quiz[76].MyGroup = GROUP_NT_SOCIAL;
  Quiz[77].MyGroup = GROUP_ASPIE_NVC;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_NVC;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
  Quiz[82].MyGroup = GROUP_ASPIE_NVC;
  Quiz[83].MyGroup = GROUP_ASPIE_NVC;
  Quiz[84].MyGroup = GROUP_ASPIE_NVC;
  Quiz[85].MyGroup = GROUP_ASPIE_NVC;
  Quiz[86].MyGroup = GROUP_ASPIE_NVC;
  Quiz[87].MyGroup = GROUP_ASPIE_NVC;
  Quiz[88].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[89].MyGroup = GROUP_NT_NVC;
  Quiz[90].MyGroup = GROUP_NT_NVC;
  Quiz[91].MyGroup = GROUP_ASPIE_NVC;
  Quiz[92].MyGroup = GROUP_NT_NVC;
  Quiz[93].MyGroup = GROUP_NT_NVC;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_NT_TALENT;
  Quiz[96].MyGroup = GROUP_NT_NVC;
  Quiz[97].MyGroup = GROUP_NT_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[100].MyGroup = GROUP_NT_SOCIAL;
  Quiz[101].MyGroup = GROUP_NT_SENSORY;
  Quiz[102].MyGroup = GROUP_NT_NVC;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_NVC;
  Quiz[105].MyGroup = GROUP_ENVIRONMENT;
  Quiz[106].MyGroup = GROUP_MIXED;
  Quiz[107].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[108].MyGroup = GROUP_MIXED;
  Quiz[109].MyGroup = GROUP_ENVIRONMENT;
  Quiz[110].MyGroup = GROUP_NT_TALENT;
  Quiz[111].MyGroup = GROUP_NT_TALENT;
  Quiz[112].MyGroup = GROUP_ENVIRONMENT;
  Quiz[113].MyGroup = GROUP_ENVIRONMENT;
  Quiz[114].MyGroup = GROUP_MIXED;
  Quiz[115].MyGroup = GROUP_ASPIE_NVC;
  Quiz[116].MyGroup = GROUP_ENVIRONMENT;
  Quiz[117].MyGroup = GROUP_ENVIRONMENT;
  Quiz[118].MyGroup = GROUP_MIXED;
  Quiz[119].MyGroup = GROUP_ENVIRONMENT;
  Quiz[120].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[121].MyGroup = GROUP_NT_TALENT;
  Quiz[122].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[123].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[124].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[125].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[126].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[127].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[128].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[129].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[130].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_MIXED;
  Quiz[133].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[134].MyGroup = GROUP_SEX;
  Quiz[135].MyGroup = GROUP_NT_NVC;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_NT_TALENT;
  Quiz[138].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[139].MyGroup = GROUP_NT_TALENT;
  Quiz[140].MyGroup = GROUP_NT_TALENT;
  Quiz[141].MyGroup = GROUP_NT_HUNTING;
  Quiz[142].MyGroup = GROUP_NT_TALENT;
  Quiz[143].MyGroup = GROUP_SEX;
  Quiz[144].MyGroup = GROUP_ENVIRONMENT;
  Quiz[145].MyGroup = GROUP_NT_SOCIAL;
  Quiz[146].MyGroup = GROUP_MIXED;
  Quiz[147].MyGroup = GROUP_NT_SENSORY;
  Quiz[148].MyGroup = GROUP_MIXED;
  Quiz[149].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[150].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[151].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[152].MyGroup = GROUP_ASPIE_NVC;
  Quiz[153].MyGroup = GROUP_NT_HUNTING;
  Quiz[154].MyGroup = GROUP_MIXED;
  Quiz[155].MyGroup = GROUP_MIXED;
  Quiz[156].MyGroup = GROUP_ASPIE_NVC;
  Quiz[157].MyGroup = GROUP_MIXED;
  Quiz[158].MyGroup = GROUP_ASPIE_NVC;
  Quiz[159].MyGroup = GROUP_NT_TALENT;
  Quiz[160].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[161].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[162].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[163].MyGroup = GROUP_MIXED;
  Quiz[164].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Do you have odd teeth; e.g. teeth that are crooked or bigger than usual; gaps; overlaps; underbite etc.?";
  Quiz[1].Text = "Do you have a larger head (or hat size) than normal?";
  Quiz[2].Text = "Do you have loose joints that have dislocated?";
  Quiz[3].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[4].Text = "Are you the last one to finish manual tasks?";
  Quiz[5].Text = "Did you perceive practical classes like handi-work or gymnasics as hard in school?";
  Quiz[6].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[7].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[8].Text = "Do you have difficulty with throwing and catching a ball?";
  Quiz[9].Text = "Do you feel tortured by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' material?";
  Quiz[10].Text = "Are you sensitive to heat, cold, wind and/or changes in air-pressure, humidity etc?";
  Quiz[11].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[12].Text = "Do you have extra sensitive hearing?";
  Quiz[13].Text = "Do you have unusual eating patterns?";
  Quiz[14].Text = "Do you have an unusual sensitivity to pain?";
  Quiz[15].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[16].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
  Quiz[17].Text = "Do you have a very acute sense of smell and/or taste?";
  Quiz[18].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[19].Text = "Do you squint now or have done in the past?";
  Quiz[20].Text = "Are you sensitive to electromagnetic fields?";
  Quiz[21].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  Quiz[22].Text = "Do you tend to shut one or both of your eyes in strong sun-light?";
  Quiz[23].Text = "Do you have food intolerances?";
  Quiz[24].Text = "Do you prefer cold weather over warm weather?";
  Quiz[25].Text = "Do you have an intense dislike for the military?";
  Quiz[26].Text = "Are you naturally nocturnal, i.e. do you tend to be most alert at night?";
  Quiz[27].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
  Quiz[28].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[29].Text = "Do you have unconventional, often unique ways of solving problems?";
  Quiz[30].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[31].Text = "Have you been called a 'know-it-all' because you feel compelled to correct people with accurate facts?";
  Quiz[32].Text = "Do you tend to be more blunt and straightforward than others?";
  Quiz[33].Text = "Do you have high morals and a tendency to stand up for your ideals and beliefs even if they are contrary to general consensus, or if it means social or economical disadvantages?";
  Quiz[34].Text = "Are you very gifted in one or more areas?";
  Quiz[35].Text = "Do you take on too much because it is easier than having to explain to others how to do it?";
  Quiz[36].Text = "Do you find it hard to focus on or learn things you are not interested in?";
  Quiz[37].Text = "Do you find it difficult to taking notes in lectures?";
  Quiz[38].Text = "Are you easily distracted and/or bored?";
  Quiz[39].Text = "Do you find it easy to organize your daily life?";
  Quiz[40].Text = "Do you sometimes flip letters?";
  Quiz[41].Text = "Do you often forget were you put things?";
  Quiz[42].Text = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";
  Quiz[43].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[44].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
  Quiz[45].Text = "Is your sense of humor different from mainstream and / or considered odd?";
  Quiz[46].Text = "Do you dislike eye-contact?";
  Quiz[47].Text = "Do you tend to feel get nervous, shy, confused and/or like you don't fit in, in various social situations?";
  Quiz[48].Text = "Before doing something or going somewhere, do you need to visualize the place you're going to or rehearse possible scenarios in your mind so as to prepare yourself?";
  Quiz[49].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[50].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[51].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[52].Text = "Do you prefer to do things on your own even if you could use others work or expertice?";
  Quiz[53].Text = "Do you find the usual courting behavior natural?";
  Quiz[54].Text = "Do you mostly prefer to play/work/do things on your own - in your own way and at your own pace?";
  Quiz[55].Text = "Are you comfortable in social situations and with new people?";
  Quiz[56].Text = "Are you more of an observer than one who participates in life - being a detached observer ?";
  Quiz[57].Text = "Do you lose interest in what others have to say?";
  Quiz[58].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[59].Text = "Do you dislike it when people turn up at your home uninvited?";
  Quiz[60].Text = "Are you good at party games?";
  Quiz[61].Text = "Do you welcome a surprise, even if it means being taken off task?";
  Quiz[62].Text = "If asked to describe yourself, would you do so in a detached way, as if you were describing someone else?";
  Quiz[63].Text = "Do you prefer the company of those older than yourself to that of your peers?";
  Quiz[64].Text = "Are your views typical of your peer group?";
  Quiz[65].Text = "Do you like having other involved in your pursuits?";
  Quiz[66].Text = "Do you enjoy being in a big crowd, such as a football game?";
  Quiz[67].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[68].Text = "Do you judge a potential mate as most anybody else would?";
  Quiz[69].Text = "Are you relaxed most anywhere, anytime?";
  Quiz[70].Text = "Do you get annoyed when people drop by to visit you?";
  Quiz[71].Text = "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?";
  Quiz[72].Text = "Do you remember rules of a game but not enjoy playing?";
  Quiz[73].Text = "Are you asexual?";
  Quiz[74].Text = "Is a large social network important for you?";
  Quiz[75].Text = "Do you enjoy gossip?";
  Quiz[76].Text = "Do you talk to put others at ease even when you really have nothing to say?";
  Quiz[77].Text = "Have you been accused of staring?";
  Quiz[78].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[79].Text = "Do you do any of the following in order to calm yourself when excited, overwhelmed or overstimulated: rocking; flapping hands; tapping ears; pressing eyes?";
  Quiz[80].Text = "Do you tap your fingers?";
  Quiz[81].Text = "Do you blink or roll your eyes?";
  Quiz[82].Text = "Do you talk to yourself?";
  Quiz[83].Text = "Do your hands shake?";
  Quiz[84].Text = "Do you do any of the following when anxious: twisting hands or fingers; rubbing hands, arms or thighs; biting lip, cheek or tongue?";
  Quiz[85].Text = "Do you chew on things?";
  Quiz[86].Text = "Do you grind your teeth when stressed or anxious?";
  Quiz[87].Text = "Do you do any of the following when you're thinking, restless or bored: pacing; bouncing leg or foot; tapping fingers, pen or other object; doodling; fiddling with object e.g clicking pen; chewing on something?";
  Quiz[88].Text = "Do you have an urge to climb?";
  Quiz[89].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[90].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
  Quiz[91].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[92].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[93].Text = "Are you often surprised what people's motives are ?";
  Quiz[94].Text = "Do you have an odd posture, gait and/or difficulties sitting/standing erect?";
  Quiz[95].Text = "Do you have difficulty summarizing and reporting conversations or describing events?";
  Quiz[96].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[97].Text = "Do you have difficulties understanding figures of speech, parodies, allegories, irony etc?";
  Quiz[98].Text = "Do you have an odd posture or gait?";
  Quiz[99].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
  Quiz[100].Text = "Do you find it easy to describe your feelings?";
  Quiz[101].Text = "Do you have problems recognizing faces out of their usual context (e.g. your doctor at the supermarket without his white robe)?";
  Quiz[102].Text = "Are you intuitive about what people need from you?";
  Quiz[103].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[104].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[105].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[106].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[107].Text = "Do you dislike shaking hands?";
  Quiz[108].Text = "Have you had the feeling of playing a game to pretend to be like people around you?";
  Quiz[109].Text = "Have you been bullied, abused or taken advantage of in various situations?";
  Quiz[110].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[111].Text = "Do you tend to be impatient and impulsive, e.g. having trouble waiting for your turn?";
  Quiz[112].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[113].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[114].Text = "Do you expect other people to know your thoughts, experiences and opinions?";
  Quiz[115].Text = "Do you apologize constantly?";
  Quiz[116].Text = "Do you often have thoughts of committing suicide?";
  Quiz[117].Text = "Do you self-harm, or have you done so in the past?";
  Quiz[118].Text = "Do your feelings cycle regulary between hopelessness and extremely high confidence?";
  Quiz[119].Text = "Do you self-injure?";
  Quiz[120].Text = "Does it feel vitally important to be left undisturbed to persue your special interests?";
  Quiz[121].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[122].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed?";
  Quiz[123].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[124].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[125].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[126].Text = "Do you have certain simple & logical routines which you need to follow?";
  Quiz[127].Text = "Do you have very strong attachments to certain objects, e.g. a favourite cup or a favourite towel and really need to have that precise one?";
  Quiz[128].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
  Quiz[129].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[130].Text = "Do you have a need for comfort items like blankets, stuffed animals etc?";
  Quiz[131].Text = "Do you have phobias?";
  Quiz[132].Text = "Are you relaxed about whether or not you might have forgotten to do something which normally you would do (locking the door, unplugging an appliance)?";
  Quiz[133].Text = "Are you punctual, conscientious and perfectionist?";
  Quiz[134].Text = "Do you feel like you were born with the wrong gender?";
  Quiz[135].Text = "Do others often misunderstand you?";
  Quiz[136].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[137].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[138].Text = "Do you more easily get very upset over 'minor' things (e.g. losing your favourite pen) than over which others get upset about (e.g. a relative passing away)?";
  Quiz[139].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[140].Text = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";
  Quiz[141].Text = "Do you drop things when your attention is on other things?";
  Quiz[142].Text = "Do you need to see, touch or do things yourself in order to remember them?";
  Quiz[143].Text = "Do you have an alternative view of what is attractive in the opposite sex compared to most others?";
  Quiz[144].Text = "Is it harder for you to make it on your own, than it seems to be for most others of your age?";
  Quiz[145].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[146].Text = "Do you rehearse inside your head?";
  Quiz[147].Text = "Do you have poor concept of time?";
  Quiz[148].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[149].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[150].Text = "Is it difficult or tiresome for you to talk?";
  Quiz[151].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[152].Text = "Do you stammer when stressed?";
  Quiz[153].Text = "Do you have difficulty writing by hand?";
  Quiz[154].Text = "Do you have irregular eating habits that are adapted to what you are doing right now?";
  Quiz[155].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[156].Text = "Do you have difficulties with pronunciation?";
  Quiz[157].Text = "Do you find the norms of hygiene too strict?";
  Quiz[158].Text = "Do you sometimes say \"we\" instead of \"I\"?";
  Quiz[159].Text = "Do have difficulties keeping things tidy ?";
  Quiz[160].Text = "Do you see the value in owning one of a kind?";
  Quiz[161].Text = "Do you prefer being told the bottom line rather than having to find your own way there?";
  Quiz[162].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[163].Text = "Are you trying to slow down at work because you run out of things to do?";
  Quiz[164].Text = "Do you more often get things because you need them than because others have them?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du udda tänder; t ex tänder som sitter snett, är större än vanligt; mellanrum mellan tänderna; tänder som klättrar på varandra; underbett etc.?";
  Quiz[1].Text = "Har du större huvud (eller hattstorlek) än normalt?";
  Quiz[2].Text = "Har du lösa leder som har hoppat ur led?";
  Quiz[3].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[4].Text = "Är du sist med att avsluta manuella uppgifter?";
  Quiz[5].Text = "Tyckte du praktiska ämnen som slöjd och gymnastik var svårt i skolan?";
  Quiz[6].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[7].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
  Quiz[8].Text = "Har du svårt för att kasta eller fånga en boll?";
  Quiz[9].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda i \"fel\" material?";
  Quiz[10].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
  Quiz[11].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
  Quiz[12].Text = "Har du extra känslig hörsel?";
  Quiz[13].Text = "Har du ovanliga ätvanor?";
  Quiz[14].Text = "Har du ovanlig känslighet för smärta? ";
  Quiz[15].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[16].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
  Quiz[17].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
  Quiz[18].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[19].Text = "Skelar du eller har gjort det?";
  Quiz[20].Text = "Är du känslig för elektromagnetiska fält?";
  Quiz[21].Text = "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
  Quiz[22].Text = "Blundar du gärna med ena eller bägge ögana i starkt solljus?";
  Quiz[23].Text = "Är du intolerant mot någon slags mat?";
  Quiz[24].Text = "Trivs du bättre i kallt väder än i varmt?";
  Quiz[25].Text = "Ogillar du intensivt militären?";
  Quiz[26].Text = "Är du en nattmänniska, d.v.s. brukar du vara som piggast på kvällen/natten?";
  Quiz[27].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat (äta, duscha, sova, andra människor etc.)?";
  Quiz[28].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[29].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
  Quiz[30].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[31].Text = "Har du blivit kallad 'besserwisser' för att du känner dig manad att korrigera andra med korrekta fakta?";
  Quiz[32].Text = "Brukar du vara mer rak och rättfram i din kommunikation än andra?";
  Quiz[33].Text = "Har du hög moral och en tendens att hålla fast vid dina ideal, övertygelser och principer även om de går emot det rådande synsättet och kan vara till din nackdel, t ex socialt eller ekonomiskt?";
  Quiz[34].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[35].Text = "Tar du på dig för mycket för att det är enklare att göra saker själv än att förklara för andra?";
  Quiz[36].Text = "Har du svårt att koncenterera dig på eller lära dig saker du inte är intresserad av?";
  Quiz[37].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[38].Text = "Blir du lätt distraherad och/eller uttråkad?";
  Quiz[39].Text = "Tycker du det är enkelt att organisera ditt dagliga liv?";
  Quiz[40].Text = "Vänder du ibland på bokstäver?";
  Quiz[41].Text = "Glömmer du ofta var du lagt saker?";
  Quiz[42].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
  Quiz[43].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[44].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
  Quiz[45].Text = "Är ditt sinne för humor annorlunda än andras och / eller ansett som udda?";
  Quiz[46].Text = "Ogillar du ögonkontakt?";
  Quiz[47].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
  Quiz[48].Text = "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?";
  Quiz[49].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[50].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[51].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller bett om det?";
  Quiz[52].Text = "Föredrar du att göra saker på egen hand även om du skulle kunna använda andras arbete och expertis?";
  Quiz[53].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[54].Text = "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?";
  Quiz[55].Text = "Känner du dig hemma i sociala situationer med nya människor?";
  Quiz[56].Text = "Känner du dig mer som en observatör än som en deltagare i livet?";
  Quiz[57].Text = "Tappar du intresse för vad andra säger?";
  Quiz[58].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara aktuellt/modernt/inne?";
  Quiz[59].Text = "Ogillar du att folk dyker upp vid ditt hem utan att du bjudit in dem?";
  Quiz[60].Text = "Är du bra på sällskapsspel?";
  Quiz[61].Text = "Välkomnar du överraskningar även om de gör att du måste avbryta en aktivitet?";
  Quiz[62].Text = "Om du blev ombedd att beskriva dig själv, skulle du då göra det på objektivt sätt, som om du beskrev någon annan?";
  Quiz[63].Text = "Umgås du hellre med människor som är äldre/mer erfarna, än med dina jämnåriga?";
  Quiz[64].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[65].Text = "Tycker du om att ha med andra i dina aktiviteter?";
  Quiz[66].Text = "Tycker du om att vara bland mycket folk som t.ex. på en fotbollsmatch?";
  Quiz[67].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[68].Text = "Bedömmer du en potentiell partner på samma sätt som de flesta andra människor?";
  Quiz[69].Text = "Är du avspänd nästan alltid och överallt?";
  Quiz[70].Text = "Blir du irriterad när folk kommer på besök oanmälda?";
  Quiz[71].Text = "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?";
  Quiz[72].Text = "Kommer du ihåg regler men tycker inte om att spela?";
  Quiz[73].Text = "Är du asexuell?";
  Quiz[74].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[75].Text = "Tycker du om skvaller?";
  Quiz[76].Text = "Pratar du för att andra ska känna sig väl till mods även om du inte har något att säga?";
  Quiz[77].Text = "Har du blivit anklagad för att glo?";
  Quiz[78].Text = "Använder du små ljud som andra inte verkar använda i samtal?";
  Quiz[79].Text = "Brukar du göra något av följande för att lugna ner dig när du blivit upphetsad, stressad eller överstimulerad: gunga med överkroppen, flaxa med händerna, slå på öronen, pressa händerna mot ögonen?";
  Quiz[80].Text = "Brukar du trumma med fingrarna?";
  Quiz[81].Text = "Blinkar eller rullar du med ögona?";
  Quiz[82].Text = "Pratar du med dig själv?";
  Quiz[83].Text = "Skakar dina händer?";
  Quiz[84].Text = "Brukar du göra något av följande när du är orolig: vrida dina händer eller fingar; gnugga händer, överarmar eller lår; bita dig i läppen, kinden eller tungan?";
  Quiz[85].Text = "Tuggar du på saker?";
  Quiz[86].Text = "Gnisslar du med tänderna när du är stressad eller har ångest?";
  Quiz[87].Text = "Brukar du göra något av följande när du tänker, är rastlös eller uttråkad: vanka; vippa foten eller benet; trumma med fingrarna, en penna eller annat objekt; kludda; klicka penna, pilla eller tugga på något?";
  Quiz[88].Text = "Har du ett behov av att klättra?";
  Quiz[89].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[90].Text = "Brukar du ha svårt att tolka kroppsspråk och ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
  Quiz[91].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[92].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[93].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[94].Text = "Har du ovanlig kroppshållning, gångstil och/eller svårt att sitta/stå upprätt?";
  Quiz[95].Text = "Har du problem med att redogöra för konversationer eller händelser och att sammanfatta?";
  Quiz[96].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[97].Text = "Har du svårt att förstå talesätt, allegorier, parodier, ironi och liknande?";
  Quiz[98].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[99].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
  Quiz[100].Text = "Är det lätt för dig att beskriva dina känslor?";
  Quiz[101].Text = "Har du svårt att känna igen ansikten i oväntade sammanhang (t ex din läkare i snabbköpet utan sin vita rock?";
  Quiz[102].Text = "Känner du intuitivt av vad folk behöver från dig?";
  Quiz[103].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[104].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[105].Text = "Stänger du av eller bryter ihop när du blir stressad eller överväldigad?";
  Quiz[106].Text = "Tar du ibland initiativ som inte visar sig önskade?";
  Quiz[107].Text = "Ogillar du att behöva ta i hand?";
  Quiz[108].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[109].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
  Quiz[110].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[111].Text = "Brukar du vara otålig och impulsiv och t ex ha svårt att vänta på din tur?";
  Quiz[112].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[113].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[114].Text = "Förväntar du dig att andra vet om dina tankar, upplevelser och åsikter?";
  Quiz[115].Text = "Ber du om ursäkt i ett kör?";
  Quiz[116].Text = "Har du ofta självmordstankar?";
  Quiz[117].Text = "Brukar du ägna dig åt självskadande beteende, eller har du gjort det tidigare?";
  Quiz[118].Text = "Växlar dina känslor mellan hopplöshet och extremt bra självförtroende?";
  Quiz[119].Text = "Skadar du dig själv?";
  Quiz[120].Text = "Känns det livsviktigt att få vara ifred och ägna dig åt dina specialintressen i lugn och ro?";
  Quiz[121].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[122].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
  Quiz[123].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[124].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[125].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[126].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
  Quiz[127].Text = "Är du exceptionellt fäst vid vissa saker, t ex en favoritkopp, en favorittröja, en favorithandduk, och verkligen MÅSTE ha just den?";
  Quiz[128].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
  Quiz[129].Text = "Har du ett behov av symmerti, ordning och/eller precision?";
  Quiz[130].Text = "Har du ibland behov av gosefilt, kramdjur eller liknande?";
  Quiz[131].Text = "Har du fobier?";
  Quiz[132].Text = "Är du lugn för att du inte glömt något du brukar göra (låsa dörren, stänga av spisen)?";
  Quiz[133].Text = "Är du punktlig, noggrann och/eller perfektionistisk?";
  Quiz[134].Text = "Känns det som du föddes med fel kön?";
  Quiz[135].Text = "Blir du ofta missförstådd av andra?";
  Quiz[136].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[137].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[138].Text = "Brukar du bli mer upprörd över smärre saker (t ex att du tappat din favoritpenna eller någon satt sig på din favoritplats) än över sånt som andra blir upprörda av (t ex en släktings bortgång)?";
  Quiz[139].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[140].Text = "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför behov av att få göra klart det du håller på med innan du kan ta itu med något annat?";
  Quiz[141].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[142].Text = "Har du behov av att SE, ta i, eller själv bearbeta saker för att riktigt minnas dem?";
  Quiz[143].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet än vad många andra anser?";
  Quiz[144].Text = "Har du svårare att klara dig själv - känslomässigt och/eller praktiskt - än andra i samma ålder?";
  Quiz[145].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[146].Text = "Tränar du scenarier inuti ditt huvud?";
  Quiz[147].Text = "Har du dålig tidsuppfattning?";
  Quiz[148].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[149].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[150].Text = "Finner du det svårt eller tröttsamt att tala?";
  Quiz[151].Text = "Föredrar du att umgås med folk du känner väl, och helst på tu man hand eller i en mindre grupp?";
  Quiz[152].Text = "Stammar du när du blir stressad?";
  Quiz[153].Text = "Har du svårt att skriva för hand?";
  Quiz[154].Text = "Har du oregelbunda mattider som anpassas efter det du för stunden håller på med?";
  Quiz[155].Text = "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
  Quiz[156].Text = "Har du svårigheter med uttal?";
  Quiz[157].Text = "Tycker du att normerna för hygien är för strikta?";
  Quiz[158].Text = "Säger du ibland \"vi\" istället för \"jag\"?";
  Quiz[159].Text = "Har du svårt att hålla ordning omkring dig?";
  Quiz[160].Text = "Tycker du det finns ett värde i att äga en sak av varje sort?";
  Quiz[161].Text = "Föredrar du att få veta av andra hur saker fungerar snarare än att ta reda på det på ditt eget sätt?";
  Quiz[162].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[163].Text = "Försöker du sakta ned på jobbet för att du riskerar att bli sysslolös?";
  Quiz[164].Text = "Skaffar du dig oftare prylar för att du behöver dem än för att andra har dem?";
#endif

}

/*##########################################################################
#
#   Name       : TQuizR2::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR2::InitReferers()
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

/*##################  TQuizR2::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR2::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

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
#   Name       : TQuizR2::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR2::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;
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

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR2::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR2::SetupControlGroups()
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
#   Name       : TQuizR2::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR2::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1)
{
    DefineCross(Quiz9, 0, 1);
    DefineCross(QuizIII, 1, 91);
    DefineCross(Quiz9, 2, 3);
    DefineCross(QuizR1, 3, 88);
    DefineCross(Quiz8, 4, 21);
    DefineCross(QuizII, 5, 19);
    DefineCross(QuizR1, 6, 87);
    DefineCross(QuizR1, 7, 94);
    DefineCross(Quiz9, 8, 9);
    DefineCross(QuizR1, 9, 81);
    DefineCross(Quiz9, 10, 22);
    DefineCross(QuizR1, 11, 71);
    DefineCross(QuizR1, 12, 69);
    DefineCross(QuizNd, 13, 14);
    DefineCross(Quiz8, 14, 127);
    DefineCross(Quiz9, 15, 134);
    DefineCross(QuizR1, 16, 83);
    DefineCross(Quiz6, 17, 3);
    DefineCross(Quiz7, 18, 131);
    DefineCross(QuizR1, 19, 78);
    DefineCross(Quiz9, 20, 25);
    DefineCross(Quiz9, 21, 131);
    DefineCross(Quiz6, 22, 144);
    DefineCross(QuizNd, 23, 184);
    DefineCross(QuizIII, 24, 20);
    DefineCross(QuizII, 25, 86);
    DefineCross(QuizR1, 26, 40);
    DefineCross(QuizR1, 27, 56);
    DefineCross(QuizR1, 28, 46);
    DefineCross(QuizR1, 29, 45);
    DefineCross(QuizR1, 30, 47);
    DefineCross(QuizR1, 31, 54);
    DefineCross(QuizR1, 32, 28);
    DefineCross(QuizR1, 33, 55);
    DefineCross(QuizR1, 34, 44);
    DefineCross(QuizNd, 35, 146);
    DefineCross(QuizR1, 36, 101);
    DefineCross(Quiz9, 37, 39);
    DefineCross(QuizR1, 38, 100);
    DefineCross(QuizII, 39, 92);
    DefineCross(QuizII, 40, 34);
    DefineCross(Quiz9, 41, 42);
    DefineCross(QuizR1, 42, 3);
    DefineCross(QuizR1, 43, 11);
    DefineCross(QuizR1, 44, 7);
    DefineCross(QuizR1, 45, 42);
    DefineCross(Quiz9, 46, 63);
    DefineCross(QuizR1, 47, 10);
    DefineCross(QuizR1, 48, 64);
    DefineCross(QuizR1, 49, 29);
    DefineCross(QuizR1, 50, 26);
    DefineCross(QuizR1, 51, 82);
    DefineCross(Quiz9, 52, 60);
    DefineCross(Quiz9, 53, 56);
    DefineCross(QuizR1, 54, 6);
    DefineCross(QuizR1, 55, 16);
    DefineCross(QuizR1, 56, 2);
    DefineCross(QuizNd, 57, 37);
    DefineCross(Quiz9, 58, 67);
    DefineCross(Quiz8, 59, 53);
    DefineCross(Quiz9, 60, 53);
    DefineCross(QuizNd, 61, 74);
    DefineCross(QuizR1, 62, 27);
    DefineCross(QuizR1, 63, 5);
    DefineCross(QuizNd, 64, 128);
    DefineCross(QuizNd, 65, 62);
    DefineCross(QuizII, 66, 44);
    DefineCross(QuizR1, 67, 15);
    DefineCross(QuizNd, 68, 109);
    DefineCross(QuizNd, 69, 151);
    DefineCross(QuizR1, 70, 8);
    DefineCross(QuizR1, 71, 13);
    DefineCross(QuizNd, 72, 172);
    DefineCross(Quiz8, 73, 130);
    DefineCross(QuizR1, 74, 14);
    DefineCross(Quiz9, 75, 78);
    DefineCross(QuizR1, 76, 35);
    DefineCross(Quiz9, 77, 87);
    DefineCross(Quiz9, 78, 90);
    DefineCross(QuizR1, 79, 121);
    DefineCross(Quiz7, 80, 128);
    DefineCross(Quiz8, 81, 4);
    DefineCross(QuizR1, 82, 115);
    DefineCross(Quiz9, 83, 91);
    DefineCross(QuizR1, 84, 119);
    DefineCross(Quiz7, 85, 138);
    DefineCross(QuizR1, 86, 124);
    DefineCross(QuizR1, 87, 117);
    DefineCross(QuizR1, 88, 116);
    DefineCross(QuizR1, 89, 25);
    DefineCross(QuizR1, 90, 30);
    DefineCross(Quiz6, 91, 37);
    DefineCross(QuizIII, 92, 30);
    DefineCross(Quiz9, 93, 99);
    DefineCross(Quiz9, 94, 107);
    DefineCross(Quiz6, 95, 33);
    DefineCross(QuizR1, 96, 23);
    DefineCross(QuizR1, 97, 99);
    DefineCross(QuizR1, 98, 85);
    DefineCross(QuizR1, 99, 70);
    DefineCross(QuizR1, 100, 33);
    DefineCross(QuizR1, 101, 107);
    DefineCross(QuizR1, 102, 19);
    DefineCross(QuizIII, 103, 40);
    DefineCross(QuizIII, 104, 43);
    DefineCross(Quiz9, 105, 123);
    DefineCross(Quiz8, 106, 121);
    DefineCross(QuizII, 107, 71);
    DefineCross(Quiz8, 108, 64);
    DefineCross(QuizR1, 109, 9);
    DefineCross(Quiz9, 110, 130);
    DefineCross(QuizR1, 111, 104);
    DefineCross(QuizIII, 112, 87);
    DefineCross(Quiz9, 113, 142);
    DefineCross(QuizII, 114, 39);
    DefineCross(Quiz8, 115, 139);
    DefineCross(QuizII, 116, 14);
    DefineCross(QuizR1, 117, 67);
    DefineCross(QuizNd, 118, 155);
    DefineCross(Quiz7, 119, 136);
    DefineCross(Quiz9, 120, 113);
    DefineCross(Quiz7, 121, 106);
    DefineCross(QuizR1, 122, 59);
    DefineCross(Quiz7, 123, 91);
    DefineCross(QuizR1, 124, 62);
    DefineCross(QuizR1, 125, 63);
    DefineCross(QuizR1, 126, 58);
    DefineCross(QuizR1, 127, 61);
    DefineCross(QuizR1, 128, 53);
    DefineCross(QuizR1, 129, 60);
    DefineCross(QuizR1, 130, 66);
    DefineCross(QuizNd, 131, 90);
    DefineCross(QuizNd, 132, 80);
    DefineCross(QuizR1, 133, 52);
    DefineCross(Quiz9, 134, 119);
    DefineCross(Quiz9, 135, 125);
    DefineCross(Quiz8, 136, 124);
    DefineCross(Quiz9, 137, 127);
    DefineCross(Quiz8, 138, 126);
    DefineCross(QuizR1, 139, 98);
    DefineCross(QuizR1, 140, 57);
    DefineCross(Quiz8, 141, 19);
    DefineCross(Quiz8, 142, 123);
    DefineCross(Quiz9, 143, 129);
    DefineCross(QuizR1, 144, 97);
    DefineCross(Quiz8, 145, 128);
    DefineCross(Quiz9, 146, 135);
    DefineCross(QuizR1, 147, 95);
    DefineCross(QuizR1, 148, 102);
    DefineCross(QuizR1, 149, 96);
    DefineCross(QuizR1, 150, 22);
    DefineCross(QuizR1, 151, 4);
    DefineCross(QuizR1, 152, 24);
    DefineCross(QuizR1, 153, 92);
    DefineCross(QuizII, 154, 66);
    DefineCross(Quiz9, 155, 128);
    DefineCross(QuizNd, 156, 52);
    DefineCross(QuizR1, 157, 41);
    DefineCross(QuizII, 158, 31);
    DefineCross(QuizR1, 159, 106);
    DefineCross(Quiz8, 160, 125);
    DefineCross(Quiz5, 161, 109);
    DefineCross(QuizR1, 162, 110);
    DefineCross(QuizNd, 163, 130);
    DefineCross(QuizII, 164, 75);
}

/*##########################################################################
#
#   Name       : TQuizR2::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR2::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz, Row.GroupResult);
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

/*##################  TQuizR2::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR2::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizR2::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR2::ExportExcelAspie(const char *filename)
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

/*##################  TQuizR2::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR2::ExportExcelGroups(const char *filename)
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

/*##################  TQuizR2::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR2::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_FEMALE)
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
