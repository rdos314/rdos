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
# quiz8.cpp
# Quiz 8 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quiz8.h"
#include "file.h"
#include "quizdb8.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

class THair
{
public:
	THair();
	void Add(TQuizRow *Row);
	void WriteRow(TFile &file, int report, int index, const char *text);
    void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);
	int AsCount[4][7];
	int NtCount[4][7];
};

class TEye
{
public:
	TEye();
	void Add(TQuizRow *Row);
	void WriteRow(TFile &file, int report, int index, const char *text);
    void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);

	int AsCount[4][5];
	int NtCount[4][5];
};

class TStim
{
public:
	TStim();
	void Add(TQuizRow *Row);
	void WriteStimRow(TFile &file, int index);
	void WriteChoiceRow(TFile &file, int index);

    const char *StimText[50];
    const char *ReasonText[40];
    int StimChoice[50][40];
    int StimCount[50];
    int ChoiceCount[40];
    int Ignore[40];
    
};

/*##########################################################################
#
#   Name       : TQuiz8::TQuiz8
#
#   Purpose....: Constructor for TQuiz8
#
#   In params..: Filename to load quiz 7 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz8::TQuiz8(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7)
  : TQuiz(154),
	FDataFile(FileName)
{
	 DefineCross(0, QuizI);
	DefineCross(1, QuizII);
    DefineCross(2, QuizIII);
    DefineCross(3, QuizNd);
    DefineCross(4, Quiz5);
    DefineCross(5, Quiz6);
    DefineCross(6, Quiz7);

	SetupTexts();
    DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
    SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7);
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuiz8::~TQuiz8
#
#   Purpose....: Destructor for TQuiz8
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz8::~TQuiz8()
{
}

/*##################  TQuiz8::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz8::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuiz8::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::WriteName(TFile &File)
{
	 File.Write("8");
}

/*##################  TQuiz8::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuiz8::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::SetupTexts()
{
  Quiz[14].Reverse = TRUE;
  Quiz[15].Reverse = TRUE;
  Quiz[16].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[46].Reverse = TRUE;
  Quiz[47].Reverse = TRUE;
  Quiz[50].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[62].Reverse = TRUE;
  Quiz[63].Reverse = TRUE;
  Quiz[65].Reverse = TRUE;
  Quiz[67].Reverse = TRUE;
  Quiz[70].Reverse = TRUE;
  Quiz[71].Reverse = TRUE;
  Quiz[72].Reverse = TRUE;
  Quiz[73].Reverse = TRUE;
  Quiz[74].Reverse = TRUE;
  Quiz[75].Reverse = TRUE;
  Quiz[76].Reverse = TRUE;
  Quiz[77].Reverse = TRUE;
  Quiz[78].Reverse = TRUE;
  Quiz[79].Reverse = TRUE;
  Quiz[80].Reverse = TRUE;
  Quiz[81].Reverse = TRUE;
  Quiz[82].Reverse = TRUE;
  Quiz[93].Reverse = TRUE;
  Quiz[95].Reverse = TRUE;
  Quiz[96].Reverse = TRUE;
  Quiz[98].Reverse = TRUE;
  Quiz[99].Reverse = TRUE;
  Quiz[102].Reverse = TRUE;
  Quiz[128].Reverse = TRUE;
  Quiz[141].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_SENSORY;
  Quiz[1].MyGroup = GROUP_SENSORY;
  Quiz[2].MyGroup = GROUP_SENSORY;
  Quiz[3].MyGroup = GROUP_SENSORY;
  Quiz[4].MyGroup = GROUP_ASPIE_COMM;
  Quiz[5].MyGroup = GROUP_MIXED;
  Quiz[6].MyGroup = GROUP_SENSORY;
  Quiz[7].MyGroup = GROUP_SENSORY;
  Quiz[8].MyGroup = GROUP_ASPIE_COMM;
  Quiz[9].MyGroup = GROUP_SENSORY;
  Quiz[10].MyGroup = GROUP_SENSORY;
  Quiz[11].MyGroup = GROUP_ASPIE_COMM;
  Quiz[12].MyGroup = GROUP_ASPIE_COMM;
  Quiz[13].MyGroup = GROUP_SENSORY;
  Quiz[14].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[15].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[16].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[17].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[18].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[19].MyGroup = GROUP_ASPIE_COMM;
  Quiz[20].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[21].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[22].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[23].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[24].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[25].MyGroup = GROUP_MIXED;
  Quiz[26].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[27].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[28].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[29].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[30].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[31].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_NT_TALENT;
  Quiz[35].MyGroup = GROUP_NT_TALENT;
  Quiz[36].MyGroup = GROUP_NT_TALENT;
  Quiz[37].MyGroup = GROUP_ASPIE_COMM;
  Quiz[38].MyGroup = GROUP_NT_TALENT;
  Quiz[39].MyGroup = GROUP_NT_TALENT;
  Quiz[40].MyGroup = GROUP_NT_TALENT;
  Quiz[41].MyGroup = GROUP_NT_TALENT;
  Quiz[42].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[43].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[44].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[48].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[51].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[52].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[54].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[55].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[56].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[57].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[58].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[59].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[60].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[61].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[62].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[63].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[64].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[65].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[66].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[67].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[68].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[69].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[70].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[71].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[72].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[73].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[74].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[75].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[76].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[77].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[78].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[79].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[81].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[82].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[83].MyGroup = GROUP_ASPIE_COMM;
  Quiz[84].MyGroup = GROUP_ASPIE_COMM;
  Quiz[85].MyGroup = GROUP_ASPIE_COMM;
  Quiz[86].MyGroup = GROUP_ASPIE_COMM;
  Quiz[87].MyGroup = GROUP_ASPIE_COMM;
  Quiz[88].MyGroup = GROUP_ASPIE_COMM;
  Quiz[89].MyGroup = GROUP_ASPIE_COMM;
  Quiz[90].MyGroup = GROUP_ASPIE_COMM;
  Quiz[91].MyGroup = GROUP_NONVERBAL;
  Quiz[92].MyGroup = GROUP_NONVERBAL;
  Quiz[93].MyGroup = GROUP_NONVERBAL;
  Quiz[94].MyGroup = GROUP_NONVERBAL;
  Quiz[95].MyGroup = GROUP_NONVERBAL;
  Quiz[96].MyGroup = GROUP_NONVERBAL;
  Quiz[97].MyGroup = GROUP_NONVERBAL;
  Quiz[98].MyGroup = GROUP_NONVERBAL;
  Quiz[99].MyGroup = GROUP_NONVERBAL;
  Quiz[100].MyGroup = GROUP_NONVERBAL;
  Quiz[101].MyGroup = GROUP_NONVERBAL;
  Quiz[102].MyGroup = GROUP_NONVERBAL;
  Quiz[103].MyGroup = GROUP_REPETITION;
  Quiz[104].MyGroup = GROUP_REPETITION;
  Quiz[105].MyGroup = GROUP_REPETITION;
  Quiz[106].MyGroup = GROUP_REPETITION;
  Quiz[107].MyGroup = GROUP_REPETITION;
  Quiz[108].MyGroup = GROUP_REPETITION;
  Quiz[109].MyGroup = GROUP_REPETITION;
  Quiz[110].MyGroup = GROUP_REPETITION;
  Quiz[111].MyGroup = GROUP_REPETITION;
  Quiz[112].MyGroup = GROUP_SEX;
  Quiz[113].MyGroup = GROUP_SEX;
  Quiz[114].MyGroup = GROUP_SEX;
  Quiz[115].MyGroup = GROUP_SEX;
  Quiz[116].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[117].MyGroup = GROUP_EMOTION;
  Quiz[118].MyGroup = GROUP_NONVERBAL;
  Quiz[119].MyGroup = GROUP_MIXED;
  Quiz[120].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[121].MyGroup = GROUP_MIXED;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_MIXED;
  Quiz[124].MyGroup = GROUP_NONVERBAL;
  Quiz[125].MyGroup = GROUP_MIXED;
  Quiz[126].MyGroup = GROUP_MIXED;
  Quiz[127].MyGroup = GROUP_SENSORY;
  Quiz[128].MyGroup = GROUP_NONVERBAL;
  Quiz[129].MyGroup = GROUP_ASPIE_COMM;
  Quiz[130].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[131].MyGroup = GROUP_EMOTION;
  Quiz[132].MyGroup = GROUP_ASPIE_COMM;
  Quiz[133].MyGroup = GROUP_ASPIE_COMM;
  Quiz[134].MyGroup = GROUP_ASPIE_COMM;
  Quiz[135].MyGroup = GROUP_EMOTION;
  Quiz[136].MyGroup = GROUP_SENSORY;
  Quiz[137].MyGroup = GROUP_EMOTION;
  Quiz[138].MyGroup = GROUP_ASPIE_COMM;
  Quiz[139].MyGroup = GROUP_ASPIE_COMM;
  Quiz[140].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[141].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[142].MyGroup = GROUP_ASPIE_COMM;
  Quiz[143].MyGroup = GROUP_ASPIE_COMM;
  Quiz[144].MyGroup = GROUP_SENSORY;
  Quiz[145].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[146].MyGroup = GROUP_ASPIE_COMM;
  Quiz[147].MyGroup = GROUP_SEX;
  Quiz[148].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[149].MyGroup = GROUP_EMOTION;

  Quiz[150].MyGroup = GROUP_MIXED;
  Quiz[151].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[152].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[153].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
  Quiz[1].Text = "Do you have a very acute sense of taste?";
  Quiz[2].Text = "Do you squint now or have done in the past?";
  Quiz[3].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[4].Text = "Do you blink or roll your eyes?";
  Quiz[5].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[6].Text = "Do you feel tortured by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' material?";
  Quiz[7].Text = "Are you sensitive to heat, cold, wind and/or changes in air-pressure, humidity etc?";
  Quiz[8].Text = "Do you stammer when stressed?";
  Quiz[9].Text = "Do you see yourself as sensitive?";
  Quiz[10].Text = "Do you have a very acute sense of smell?";
  Quiz[11].Text = "Do you sniff involuntary?";
  Quiz[12].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  Quiz[13].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[14].Text = "Are you good at climbing?";
  Quiz[15].Text = "Are you good at jumping high?";
  Quiz[16].Text = "Do you have strong hands?";
  Quiz[17].Text = "Do you have a good sense for how much pressure to apply when you do someting with your hands?";
  Quiz[18].Text = "Do you have above average physical endurance?";
  Quiz[19].Text = "Do you drop things when your attention is on other things?";
  Quiz[20].Text = "Do you have difficulty with throwing and catching a ball?";
  Quiz[21].Text = "Are you the last one to finish manual tasks?";
  Quiz[22].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[23].Text = "Are you often injured in the kitchen?";
  Quiz[24].Text = "Do you have difficulty hopping, skipping or riding a bike?";
  Quiz[25].Text = "Do you have difficulty writing by hand?";
  Quiz[26].Text = "Do you have unconventional, often unique ways of solving problems?";
  Quiz[27].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[28].Text = "Do you have one special talent which you have emphasised and worked on?";
  Quiz[29].Text = "Is you imagination unusual, with unique ideas that others don't have?";
  Quiz[30].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[31].Text = "Are you very gifted in one or more areas?";
  Quiz[32].Text = "Do you like to work out how things work?";
  Quiz[33].Text = "Do you have excellent vocabulary and/or a fascination with words?";
  Quiz[34].Text = "Do you find it difficult to taking notes in lectures?";
  Quiz[35].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
  Quiz[36].Text = "Do you have trouble reading clocks?";
  Quiz[37].Text = "Do you often forget were you put things?";
  Quiz[38].Text = "Do you have trouble with math?";
  Quiz[39].Text = "Do you often make spelling errors?";
  Quiz[40].Text = "Do you have difficulty remembering scores during games?";
  Quiz[41].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[42].Text = "Do you find preferable/easier to understand & communicate with computers, animals or unusual people?";
  Quiz[43].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[44].Text = "Have you felt different from others for most of your life?";
  Quiz[45].Text = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";
  Quiz[46].Text = "Are you the life of a party?";
  Quiz[47].Text = "Are you good at party games?";
  Quiz[48].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
  Quiz[49].Text = "Do you tend to feel get nervous, shy, confused and/or like you don't fit in, in various social situations?";
  Quiz[50].Text = "Do you find the usual courting behavior natural?";
  Quiz[51].Text = "Do you dislike touch?";
  Quiz[52].Text = "Are you fairly self-absorbed, more interested in yourself than in others and/or an objective observer of yourself?";
  Quiz[53].Text = "Do you dislike it when people turn up at your home uninvited?";
  Quiz[54].Text = "Does an unplanned hug make you jump out of your skin?";
  Quiz[55].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[56].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[57].Text = "Do you prefer animals to people?";
  Quiz[58].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[59].Text = "Is your sense of humor different from mainstream and / or considered odd?";
  Quiz[60].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[61].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[62].Text = "Are you energised by being in the company of others?";
  Quiz[63].Text = "Are you comfortable in social situations and with new people?";
  Quiz[64].Text = "Have you had the feeling of playing a game to pretend to be like people around you?";
  Quiz[65].Text = "Do you see yourself as putting people first, before ideals and objects?";
  Quiz[66].Text = "Do you feel uncomfortable with strangers?";
  Quiz[67].Text = "Do you find it easy to maintain your social network?";
  Quiz[68].Text = "Do you dislike eye-contact?";
  Quiz[69].Text = "Do you mostly prefer to play/work/do things on your own - in your own way and at your own pace?";
  Quiz[70].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[71].Text = "Is a large social network important for you?";
  Quiz[72].Text = "Is creating a social identity important for you?";
  Quiz[73].Text = "Do you appreciate to be in charge of other people?";
  Quiz[74].Text = "Do you have an interest for the current fashions?";
  Quiz[75].Text = "Do you enjoy gossip?";
  Quiz[76].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
  Quiz[77].Text = "Is your style and image very important to you?";
  Quiz[78].Text = "Is other people's image of you important to you?";
  Quiz[79].Text = "Do you enjoy the status of a new car/new stereo/new TV?";
  Quiz[80].Text = "Do you enjoy wearing jewelry?";
  Quiz[81].Text = "Do you enjoy make-up?";
  Quiz[82].Text = "Is climing the social hierarchy important to you?";
  Quiz[83].Text = "Do you talk to yourself?";
  Quiz[84].Text = "Have you been accused of staring?";
  Quiz[85].Text = "Do you bounce your leg?";
  Quiz[86].Text = "Do you click or rub a pen for the fun of it?";
  Quiz[87].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[88].Text = "Do you rock your body?";
  Quiz[89].Text = "Do you thrust your tounge at the wrong occassion?";
  Quiz[90].Text = "Do you sing for yourself?";
  Quiz[91].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[92].Text = "Are you often surprised what people's motives are ?";
  Quiz[93].Text = "Do you have an intuitive sense of when to do the right thing socially?";
  Quiz[94].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[95].Text = "Do you read people well?";
  Quiz[96].Text = "Can you read between the lines?";
  Quiz[97].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
  Quiz[98].Text = "Is it easy for you to interpret body language?";
  Quiz[99].Text = "Can you spot hidden agendas with ease?";
  Quiz[100].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[101].Text = "Do you have an odd posture, gait and/or difficulties sitting/standing erect?";
  Quiz[102].Text = "Do you know when you are expected to offer an apology?";
  Quiz[103].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed?";
  Quiz[104].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[105].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[106].Text = "Does it feel vitally important to be left undisturbed to persue your special interests?";
  Quiz[107].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[108].Text = "Do you have very strong attachments to certain objects, e.g. a favourite cup or a favourite towel and really need to have that precise one?";
  Quiz[109].Text = "Do you have certain simple & logical routines which you need to follow?";
  Quiz[110].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
  Quiz[111].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[112].Text = "Do you feel like you were born with the wrong gender?";
  Quiz[113].Text = "Are you homosexual or bisexual?";
  Quiz[114].Text = "Do you have unusual sexual preferences?";
  Quiz[115].Text = "Do you have compulsive sexual behavior, e.g. spend too much time on sex or switch sexual partner frequently?";
  Quiz[116].Text = "Do you find it easier to understand & communicate with computers, animals and/or Aspies than with 'ordinary' people?";
  Quiz[117].Text = "Are you easily distracted or overwhelmed?";
  Quiz[118].Text = "Do others often misunderstand you?";
  Quiz[119].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[120].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
  Quiz[121].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[122].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[123].Text = "Do you need to see, touch or do things yourself in order to remember them?";
  Quiz[124].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[125].Text = "Do you see the value in owning one of a kind?";
  Quiz[126].Text = "Do you more easily get very upset over 'minor' things (e.g. losing your favourite pen) than over which others get upset about (e.g. a relative passing away)?";
  Quiz[127].Text = "Do you have an unusual sensitivity to pain?";
  Quiz[128].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
  Quiz[129].Text = "Do you have an alternative view of what is attractive in the opposite sex compared to most others?";
  Quiz[130].Text = "Are you asexual?";
  Quiz[131].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[132].Text = "Do you have an urge to climb?";
  Quiz[133].Text = "Do you have an urge to jump over objects?";
  Quiz[134].Text = "Are you superstitious?";
  Quiz[135].Text = "Do you care if you are right in a discussion?";
  Quiz[136].Text = "Have you had paranormal experiences?";
  Quiz[137].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[138].Text = "Do your hands shake?";
  Quiz[139].Text = "Do you apologize constantly?";
  Quiz[140].Text = "Do you have a small mouth?";
  Quiz[141].Text = "Do you find it easy to talk about feelings?";
  Quiz[142].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[143].Text = "Are you instinctively afraid of floods and/or fast running streams?";
  Quiz[144].Text = "Do you feel sickened by seeing and/or hearing of torture or other cruelty against strangers?";
  Quiz[145].Text = "Is your second toe longer than your big toe?";
  Quiz[146].Text = "Do you examine the hair of people you like a lot?";
  Quiz[147].Text = "Do you lick people you like a lot?";
  Quiz[148].Text = "Do you prefer to do things on your own even if you could use others work or expertice?";
  Quiz[149].Text = "Do you have a bad temper?";

  Quiz[150].Text = "Likes Neanderthal faces";
  Quiz[151].Text = "Red hair-color";
  Quiz[152].Text = "Do you have brown eyes?";
  Quiz[153].Text = "Correct Neanderthal gender";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
  Quiz[1].Text = "Har du extra känsligt smaksinne?";
  Quiz[2].Text = "Skelar du eller har gjort det?";
  Quiz[3].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
  Quiz[4].Text = "Blinkar eller rullar du med ögona?";
  Quiz[5].Text = "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
  Quiz[6].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda i \"fel\" material?";
  Quiz[7].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
  Quiz[8].Text = "Stammar du när du blir stressad?";
  Quiz[9].Text = "Anser du att du är känslig?";
  Quiz[10].Text = "Har du extra känsligt luktsinne?";
  Quiz[11].Text = "Sniffar du ofrivilligt?";
  Quiz[12].Text = "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
  Quiz[13].Text = "Är du känslig för lyrsrörsljus?";
  Quiz[14].Text = "Är du bra på att klättra?";
  Quiz[15].Text = "Är du bra på att hoppa högt?";
  Quiz[16].Text = "Har du starka händer?";
  Quiz[17].Text = "Har du en bra känsla för hur mycket du ska ta i när du gör något med händerna?";
  Quiz[18].Text = "Är du mer fysiskt uthållig än normalt?";
  Quiz[19].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[20].Text = "Har du svårt för att kasta eller fånga en boll?";
  Quiz[21].Text = "Är du sist med att avsluta manuella uppgifter?";
  Quiz[22].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
  Quiz[23].Text = "Skadar du dig ofta i köket?";
  Quiz[24].Text = "Har du svårt för att hoppa eller cykla?";
  Quiz[25].Text = "Har du svårt att skriva för hand?";
  Quiz[26].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
  Quiz[27].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[28].Text = "Har du en speciell talang som du har jobbat med?";
  Quiz[29].Text = "Är din fantasi ovanlig med unika idéer som andra inte har?";
  Quiz[30].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[31].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[32].Text = "Tycker du om att reda ut hur saker fungerar? ";
  Quiz[33].Text = "Har du utmärkt vokabulär och intresse för språk?";
  Quiz[34].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[35].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
  Quiz[36].Text = "Har du svårigheter att läsa av klockor?";
  Quiz[37].Text = "Glömmer du ofta var du lagt saker?";
  Quiz[38].Text = "Har du problem med matematik?";
  Quiz[39].Text = "Gör du ofta stavfel?";
  Quiz[40].Text = "Har du svårt för att komma ihåg poängställningar under spel?";
  Quiz[41].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[42].Text = "Tycker du det är att föredra/lättare att förstå och kommunicera med datorer, djur eller udda människor?";
  Quiz[43].Text = "Trivs du med romantiska situationer?";
  Quiz[44].Text = "Har du känt dig annorlunda största delen av ditt liv?";
  Quiz[45].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
  Quiz[46].Text = "Är du aktiv på fester?";
  Quiz[47].Text = "Är du bra på sällskapsspel?";
  Quiz[48].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
  Quiz[49].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
  Quiz[50].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[51].Text = "Ogillar du beröring?";
  Quiz[52].Text = "Är du rätt självupptagen, mer intresserad av dig själv än av andra och/eller en objektiv självobservatör?";
  Quiz[53].Text = "Ogillar du att folk dyker upp vid ditt hem utan att du bjudit in dem?";
  Quiz[54].Text = "Gör en oplanerad kram att du vill hoppa ur ditt skinn?";
  Quiz[55].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara aktuellt/modernt/inne?";
  Quiz[56].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[57].Text = "Umgås du hellre med djur än med människor?";
  Quiz[58].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[59].Text = "Är ditt sinne för humor annorlunda än andras och / eller ansett som udda?";
  Quiz[60].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[61].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[62].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[63].Text = "Känner du dig hemma i sociala situationer med nya människor?";
  Quiz[64].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[65].Text = "Sätter du människor före saker och idéer?";
  Quiz[66].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[67].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
  Quiz[68].Text = "Ogillar du ögonkontakt?";
  Quiz[69].Text = "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?";
  Quiz[70].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[71].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[72].Text = "Är det viktigt för dig att skapa en social identitet?";
  Quiz[73].Text = "Uppskattar du att leda andra människor?";
  Quiz[74].Text = "Är du intressad av nuvarande mode?";
  Quiz[75].Text = "Tycker du om skvaller?";
  Quiz[76].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
  Quiz[77].Text = "Är din stil och image mycket viktig för dig?";
  Quiz[78].Text = "Är andra människors syn på dig viktigt för dig?";
  Quiz[79].Text = "Njuter du av den status som en ny bil/stereo/TV ger?";
  Quiz[80].Text = "Gillar du att bära smycken?";
  Quiz[81].Text = "Gillar du att sminka dig?";
  Quiz[82].Text = "Är det viktigt för dig att klättra i den sociala hierarkin?";
  Quiz[83].Text = "Pratar du med dig själv?";
  Quiz[84].Text = "Har du blivit anklagad för att glo?";
  Quiz[85].Text = "Brukar du vippa med benet?";
  Quiz[86].Text = "Klickar eller gnider du på en penna för skojs skull?";
  Quiz[87].Text = "Använder du små ljud som andra inte verkar använda i samtal?";
  Quiz[88].Text = "Brukar du gunga med kroppen?";
  Quiz[89].Text = "Räcker du ut tungan vid fel tillfällen?";
  Quiz[90].Text = "Sjunger du för dig själv?";
  Quiz[91].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[92].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[93].Text = "Känner du intuitivt av vad som är rätt socialt?";
  Quiz[94].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[95].Text = "Läser du av folk bra?";
  Quiz[96].Text = "Kan du läsa mellan raderna?";
  Quiz[97].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
  Quiz[98].Text = "Har du lätt för att tolka kroppsspråk?";
  Quiz[99].Text = "Kan du lätt avslöja dolda motiv?";
  Quiz[100].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[101].Text = "Har du ovanlig kroppshållning, gångstil och/eller svårt att sitta/stå upprätt?";
  Quiz[102].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[103].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
  Quiz[104].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[105].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[106].Text = "Känns det livsviktigt att få vara ifred och ägna dig åt dina specialintressen i lugn och ro?";
  Quiz[107].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[108].Text = "Är du exceptionellt fäst vid vissa saker, t ex en favoritkopp, en favorittröja, en favorithandduk, och verkligen MÅSTE ha just den?";
  Quiz[109].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
  Quiz[110].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
  Quiz[111].Text = "Har du ett behov av symmerti, ordning och/eller precision?";
  Quiz[112].Text = "Känns det som du föddes med fel kön?";
  Quiz[113].Text = "Är du homosexuell eller bisexuell?";
  Quiz[114].Text = "Har du ovanliga sexuella preferenser?";
  Quiz[115].Text = "Har du tvångsmässigt sexuellt beteende, t.ex. använder för mycket tid för sex eller byter sex-partner ofta?";
  Quiz[116].Text = "Har du lättare att förstå dig på datorer, djur och/eller Aspergare än att umgås och kommunicera framgångsrikt med \"vanliga\" människor?";
  Quiz[117].Text = "Är du lätt att distrahera eller överväldiga?";
  Quiz[118].Text = "Blir du ofta missförstådd av andra?";
  Quiz[119].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[120].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat (äta, duscha, sova, andra människor etc.)?";
  Quiz[121].Text = "Tar du ibland initiativ som inte visar sig önskade?";
  Quiz[122].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[123].Text = "Har du behov av att SE, ta i, eller själv bearbeta saker för att riktigt minnas dem?";
  Quiz[124].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[125].Text = "Tycker du det finns ett värde i att äga en sak av varje sort?";
  Quiz[126].Text = "Brukar du bli mer upprörd över smärre saker (t ex att du tappat din favoritpenna eller någon satt sig på din favoritplats) än över sånt som andra blir upprörda av (t ex en släktings bortgång)?";
  Quiz[127].Text = "Har du ovanlig känslighet för smärta? ";
  Quiz[128].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
  Quiz[129].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet än vad många andra anser?";
  Quiz[130].Text = "Är du asexuell?";
  Quiz[131].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[132].Text = "Har du ett behov av att klättra?";
  Quiz[133].Text = "Har du ett behov av att hoppa över saker?";
  Quiz[134].Text = "Är du vidskeplig?";
  Quiz[135].Text = "Bryr du dig om ifall du får rätt i en diskussion?";
  Quiz[136].Text = "Har du haft övernaturliga upplevelser?";
  Quiz[137].Text = "Stänger du av eller bryter ihop när du blir stressad eller överväldigad?";
  Quiz[138].Text = "Skakar dina händer?";
  Quiz[139].Text = "Ber du om ursäkt i ett kör?";
  Quiz[140].Text = "Har du en liten mun?";
  Quiz[141].Text = "Tycker du det är lätt att prata om känslor?";
  Quiz[142].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[143].Text = "Är du instinktivt rädd för översvämningar och/eller snabbt rinnande forsar?";
  Quiz[144].Text = "Mår du illa av att höra eller se tortyr eller andra grymheter mot främlingar?";
  Quiz[145].Text = "Är din andratå längre än din stortå?";
  Quiz[146].Text = "Undersöker du håret på de som du gillar mycket?";
  Quiz[147].Text = "Slickar du på de som du gillar mycket?";
  Quiz[148].Text = "Föredrar du att göra saker på egen hand även om du skulle kunna använda andras arbete och expertis?";
  Quiz[149].Text = "Har du häftigt humör?";

  Quiz[150].Text = "Gillar neandertalsansikten";
  Quiz[151].Text = "Röd hårfärg";
  Quiz[152].Text = "Har du bruna ögon?";
  Quiz[153].Text = "Rätt kön på neandertalaren";
#endif

}

/*##########################################################################
#
#   Name       : TQuiz8::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::InitReferers()
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

/*##########################################################################
#
#   Name       : TQuiz8::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
{
	int diff;

	ref->Count++;
	ref->AsResult += AsResult;
	ref->NtResult += NtResult;

	diff = AsResult - NtResult;

	if (diff >= 35)
		ref->ResultAs++;
	else
	{
		if (diff <= -35)
			ref->ResultNt++;
		else
			ref->ResultMixed++;
	}
}

/*##################  TQuiz8::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::LoadReferers()
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
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuiz8::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;

	for (i = 0; i < N; i++)
		Quiz[i].NoAnswer = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		switch (Row.HnSimilar)
		{
			case 1:
			case 4:
        	    Row.Quiz[150] = 1;
        		break;
        					
			case 2:
			case 3:
        		Row.Quiz[150] = 2;
        		break;

			default:
				Row.Quiz[150] = 3;
        		break;
        					
        }

		switch (Row.Hair)
		{
		    case 1:
    		case 2:
	    	case 5:
		    	Row.Quiz[151] = 3;
    			break;

    		case 3:
	    		Row.Quiz[151] = 1;
		    	break;

		    case 4:
    		case 6:
	    		Row.Quiz[151] = 2;
    			break;

	    	case 7:
		    	Row.Quiz[151] = 0;
    			break;
	    }

		switch (Row.Eye)
		{
			case 1:
			case 2:
				Row.Quiz[152] = 1;
				break;

			case 3:
				Row.Quiz[152] = 2;
				break;

			case 4:
			case 5:
				Row.Quiz[152] = 3;
				break;
		}

		switch (Row.HnGender)
		{
			case 1:
        	    Row.Quiz[153] = 1;
        		break;
        					
			case 2:
        		Row.Quiz[153] = 3;
        		break;

        }

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;

		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Gender == 1)
				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Autism == 2 || Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuiz8::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::SetupControlGroups()
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
#   Name       : TQuiz8::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7)
{
    DefineCross(Quiz7, 0, 0);
    DefineCross(Quiz7, 1, 5);
    DefineCross(Quiz7, 2, 1);
    DefineCross(Quiz7, 3, 2);
    DefineCross(Quiz6, 4, 5);
    DefineCross(Quiz7, 5, 6);
    DefineCross(Quiz7, 6, 7);
    DefineCross(Quiz7, 7, 3);
	 DefineCross(Quiz6, 8, 7);
    DefineCross(Quiz5, 9, 10);
    DefineCross(Quiz7, 10, 4);
    DefineCross(Quiz6, 11, 11);
    DefineCross(Quiz7, 12, 9);
    DefineCross(Quiz7, 13, 8);
	DefineGlobalId( 14, 427);
	DefineGlobalId( 15, 428);
	DefineGlobalId( 16, 429);
	DefineGlobalId( 17, 430);
	DefineGlobalId( 18, 431);
	DefineGlobalId( 19, 432);
    DefineCross(Quiz6, 20, 12);
    DefineCross(Quiz7, 21, 14);
    DefineCross(Quiz7, 22, 15);
    DefineCross(Quiz7, 23, 16);
    DefineCross(Quiz7, 24, 17);
    DefineCross(Quiz7, 25, 140);
    DefineCross(Quiz7, 26, 18);
    DefineCross(Quiz7, 27, 19);
    DefineCross(Quiz7, 28, 22);
    DefineCross(Quiz7, 29, 20);
    DefineCross(Quiz7, 30, 21);
    DefineCross(Quiz7, 31, 23);
    DefineCross(Quiz7, 32, 25);
    DefineCross(Quiz7, 33, 26);
    DefineCross(Quiz7, 34, 28);
    DefineCross(Quiz7, 35, 27);
    DefineCross(Quiz7, 36, 29);
    DefineCross(Quiz7, 37, 31);
    DefineCross(Quiz7, 38, 30);
    DefineCross(Quiz7, 39, 32);
    DefineCross(Quiz7, 40, 34);
    DefineCross(Quiz7, 41, 33);
    DefineCross(Quiz5, 42, 60);
	 DefineCross(Quiz7, 43, 38);
    DefineCross(Quiz7, 44, 42);
    DefineCross(Quiz7, 45, 39);
    DefineCross(Quiz6, 46, 110);
    DefineCross(Quiz7, 47, 41);
    DefineCross(Quiz7, 48, 44);
    DefineCross(Quiz7, 49, 46);
    DefineCross(Quiz7, 50, 43);
    DefineCross(Quiz5, 51, 99);
    DefineCross(QuizIII, 52, 52);
    DefineCross(Quiz7, 53, 147);
    DefineCross(Quiz7, 54, 45);
    DefineCross(QuizI, 55, 96);
    DefineCross(Quiz7, 56, 54);
    DefineCross(Quiz7, 57, 56);
    DefineCross(Quiz7, 58, 50);
    DefineCross(QuizII, 59, 78);
    DefineCross(Quiz7, 60, 48);
    DefineCross(Quiz7, 61, 49);
    DefineCross(Quiz7, 62, 47);
	 DefineCross(QuizNd, 63, 95);
	 DefineCross(QuizII, 64, 45);
    DefineCross(QuizNd, 65, 105);
    DefineCross(Quiz7, 66, 57);
    DefineCross(Quiz7, 67, 55);
    DefineCross(Quiz7, 68, 107);
    DefineCross(Quiz7, 69, 51);
    DefineCross(Quiz7, 70, 52);
    DefineCross(Quiz7, 71, 58);
    DefineCross(Quiz7, 72, 59);
    DefineCross(QuizII, 73, 93);
    DefineCross(QuizIII, 74, 55);
    DefineCross(Quiz7, 75, 63);
    DefineCross(Quiz6, 76, 140);
    DefineCross(Quiz7, 77, 62);
	 DefineCross(Quiz7, 78, 65);
    DefineCross(Quiz7, 79, 64);
    DefineCross(Quiz7, 80, 68);
    DefineCross(Quiz7, 81, 67);
	DefineGlobalId( 82, 433);
    DefineCross(Quiz7, 83, 112);
    DefineCross(Quiz7, 84, 114);
    DefineCross(Quiz7, 85, 127);
    DefineCross(Quiz7, 86, 148);
    DefineCross(Quiz7, 87, 113);
    DefineCross(Quiz7, 88, 129);
    DefineCross(Quiz7, 89, 110);
	DefineGlobalId( 90, 434);
    DefineCross(Quiz7, 91, 69);
    DefineCross(Quiz7, 92, 74);
    DefineCross(Quiz7, 93, 72);
    DefineCross(Quiz7, 94, 70);
    DefineCross(Quiz7, 95, 77);
    DefineCross(Quiz7, 96, 71);
    DefineCross(Quiz7, 97, 76);
    DefineCross(Quiz7, 98, 80);
    DefineCross(Quiz7, 99, 79);
    DefineCross(Quiz7, 100, 81);
    DefineCross(QuizII, 101, 26);
    DefineCross(Quiz7, 102, 82);
    DefineCross(Quiz7, 103, 88);
    DefineCross(Quiz7, 104, 87);
    DefineCross(Quiz7, 105, 85);
    DefineCross(Quiz7, 106, 118);
    DefineCross(Quiz7, 107, 86);
    DefineCross(Quiz7, 108, 92);
    DefineCross(Quiz7, 109, 89);
    DefineCross(Quiz7, 110, 84);
	DefineGlobalId( 111, 435);
    DefineCross(Quiz7, 112, 94);
	 DefineCross(Quiz7, 113, 96);
    DefineCross(Quiz7, 114, 95);
	DefineGlobalId( 115, 436);
    DefineCross(QuizIII, 116, 45);
    DefineCross(Quiz7, 117, 104);
    DefineCross(Quiz7, 118, 73);
    DefineCross(Quiz7, 119, 40);
    DefineCross(Quiz7, 120, 105);
    DefineCross(Quiz7, 121, 115);
    DefineCross(Quiz7, 122, 103);
    DefineCross(Quiz6, 123, 127);
    DefineCross(Quiz7, 124, 78);
    DefineCross(Quiz5, 125, 53);
    DefineCross(QuizII, 126, 35);
    DefineCross(QuizII, 127, 9);
    DefineCross(Quiz7, 128, 116);
    DefineCross(Quiz7, 129, 53);
    DefineCross(QuizII, 130, 59);
    DefineCross(Quiz7, 131, 120);
	DefineGlobalId( 132, 437);
	DefineGlobalId( 133, 438);
	DefineGlobalId( 134, 439);
	DefineGlobalId( 135, 440);
	DefineGlobalId( 136, 441);
	DefineGlobalId( 137, 442);
	DefineGlobalId( 138, 443);
	DefineGlobalId( 139, 444);
	DefineGlobalId( 140, 445);
	DefineGlobalId( 141, 446);
	DefineGlobalId( 142, 447);
	DefineGlobalId( 143, 448);
	DefineGlobalId( 144, 449);
	DefineGlobalId( 145, 450);
	DefineGlobalId( 146, 451);
	DefineGlobalId( 147, 452);
	DefineGlobalId( 148, 453);
	DefineGlobalId( 149, 454);
	DefineGlobalId( 150, 455);
    DefineCross(Quiz7, 151, 154);
    DefineCross(Quiz7, 152, 155);
	DefineGlobalId( 153, 458);
}

/*##########################################################################
#
#   Name       : TQuiz8::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz8::GetReferer(const char *referer, TPopulation *pop)
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
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz);
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

/*##################  TQuiz8::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::ExportExcelCase(const char *filename, int PcaType)
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
					if (i >= 150)
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

/*##################  TQuiz8::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::ExportExcelGroups(const char *filename)
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

/*##################  TQuiz8::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::ImportMvsp(const char *filename, int PcaType)
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
//					if (PcaType == PCA_TYPE_FEMALE)
//						d2 = -d2;

//					if (PcaType == PCA_TYPE_ALL)
//						d3 = -d3;

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

/*##################  THair::THair ##########################
*   Purpose....: Initialize THair                  			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
THair::THair()
{
    int i;
    int j;

    for (i = 0; i < 7; i++)
    {
        for (j = 0; j < 3; j++)
        {
			AsCount[j][i] = 0;
            NtCount[j][i] = 0;
        }
    }
}

/*##################  THair::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THair::Add(TQuizRow *Row)
{
	int index;
	int diff = Row->AsResult - Row->NtResult;

	switch (Row->Hair)
	{
		case 1:
		case 2:
		case 5:
			index = 0;
			break;

		case 3:
			index = 1;
			break;

		case 4:
		case 6:
			index = 2;
			break;

		case 7:
			index = 3;
			break;
	}

    if (Row->Lang == 0)
    {
	    if (diff > 0)
		    AsCount[1][index]++;
    	else
	    	NtCount[1][index]++;
	}

    if (Row->Lang == 1)
    {
	    if (diff > 0)
		    AsCount[2][index]++;
    	else
	    	NtCount[2][index]++;
	}

	if (diff > 0)
		AsCount[0][index]++;
	else
		NtCount[0][index]++;
}

/*##################  THair::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THair::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Color");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("NT");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  THair::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THair::WriteEntry(TFile &file, int val, int count)
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
		sd = sqrtl(rsum / ((long double)count - 1));

		dev = 1.96 * sd / sqrtl(count);

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

		ival = round(1000.0 * mean);
		sprintf(str, " (%d.%01d%)", ival / 10, ival % 10);
		file.Write(str);
	}
	else
	    file.Write("---");
	
#else
    ival = val * 100 / count;
	sprintf(str, "%d%", ival);
    file.Write(str);
#endif

	WriteFieldFooter(file);
}

/*##################  THair::Write ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void THair::WriteRow(TFile &file, int report, int index, const char *text)
{
    char str[80];
	int sum;
    int i;

    file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	file.Write(text);
	WriteFieldFooter(file);


    sum = 0;
	for (i = 0; i < 7; i++)
		sum += AsCount[report][i];

	if (sum)
		WriteEntry(file, AsCount[report][index], sum);
	else
		file.Write("---");

	sum = 0;
	for (i = 0; i < 7; i++)
		sum += NtCount[report][i];

	if (sum)
		WriteEntry(file, NtCount[report][index], sum);
	else
		file.Write("---");

    file.Write("</tr>");
}

/*##################  TEye::TEye ##########################
*   Purpose....: Initialize TEye                  			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TEye::TEye()
{
	int i;
	int j;

    for (i = 0; i < 5; i++)
    {
        for (j = 0; j < 3; j++)
        {
            AsCount[j][i] = 0;
            NtCount[j][i] = 0;
        }
    }
}

/*##################  TEye::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TEye::Add(TQuizRow *Row)
{
    int index;
	int diff = Row->AsResult - Row->NtResult;

	switch (Row->Eye)
	{
		case 1:
		case 2:
			index = 0;
			break;

		case 3:
			index = 1;
			break;

		case 4:
		case 5:
			index = 2;
			break;
	}

    if (Row->Lang == 0)
    {
	    if (diff > 0)
		    AsCount[1][index]++;
    	else
	    	NtCount[1][index]++;
	 }

    if (Row->Lang == 1)
    {
	    if (diff > 0)
		    AsCount[2][index]++;
    	else
	    	NtCount[2][index]++;
	 }

	if (diff > 0)
		AsCount[0][index]++;
    else
	    NtCount[0][index]++;

}

/*##################  TEye::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TEye::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Color");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("NT");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TEye::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TEye::WriteEntry(TFile &file, int val, int count)
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
		sd = sqrtl(rsum / ((long double)count - 1));

		dev = 1.96 * sd / sqrtl(count);

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

		ival = round(1000.0 * mean);
		sprintf(str, " (%d.%01d%)", ival / 10, ival % 10);
		file.Write(str);
	}
	else
	    file.Write("---");
#else
	ival = val * 100 / count;
	sprintf(str, "%d%", ival);
	file.Write(str);
#endif

	WriteFieldFooter(file);
}

/*##################  TEye::Write ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TEye::WriteRow(TFile &file, int report, int index, const char *text)
{
	char str[80];
	int sum;
	int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	file.Write(text);
	WriteFieldFooter(file);

	sum = 0;
	for (i = 0; i < 3; i++)
		sum += AsCount[report][i];

	if (sum)
        WriteEntry(file, AsCount[report][index], sum);
	else
	    file.Write("---");


    sum = 0;
    for (i = 0; i < 3; i++)
        sum += NtCount[report][i];            

    if (sum)
        WriteEntry(file, NtCount[report][index], sum);
	else
	    file.Write("---");

    file.Write("</tr>");
}

/*##################  TStim::TStim ##########################
*   Purpose....: Initialize TStim                  			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TStim::TStim()
{
	int i;
	int j;

    for (i = 0; i < 46; i++)
    {
        for (j = 0; j < 34; j++)
            StimChoice[i][j] = 0;

        StimCount[i] = 0;
	}

    for (i = 0; i < 34; i++)
    {
        ChoiceCount[i] = 0;
        Ignore[i] = FALSE;
    }

//    Ignore[3] = TRUE;
//    Ignore[4] = TRUE;
//    Ignore[13] = TRUE;
//    Ignore[15] = TRUE;
//    Ignore[27] = TRUE;
//    Ignore[28] = TRUE;
//    Ignore[30] = TRUE;
//    Ignore[32] = TRUE;



#ifdef ENGLISH

	StimText[0] = "Talking to yourself";
	StimText[1] = "Singing to yourself";
	StimText[2] = "Humming";
	StimText[3] = "Whistling";
	StimText[4] = "Tapping ears";
	StimText[5] = "Pressing eyes";
	StimText[6] = "Rolling eyes";
	StimText[7] = "Watching a spinning, blinking or glittering object";
	StimText[8] = "Picking nose";
	StimText[9] = "Grinding teeth";
	StimText[10] = "Clicking teeth";
	StimText[11] = "Sticking tounge out";
	StimText[12] = "Sucking thumb";
	StimText[13] = "Sucking lip";
	StimText[14] = "Biting lip, cheek or tongue";
	StimText[15] = "Biting nails";
	StimText[16] = "Biting, peeling or picking cuticle or fingertip";
	StimText[17] = "Chewing or sucking on strands of hair or beard";
	StimText[18] = "Chewing or sucking on pencil, toothpick or other object";
	StimText[19] = "Clicking a pen";
	StimText[20] = "Twirling hair";
	StimText[21] = "Tapping fingers";
	StimText[22] = "Tapping pen or other object";
	StimText[23] = "Digging fingernails under each other, into skin or other things";
	StimText[24] = "Flapping hands";
	StimText[25] = "Clapping hands";
	StimText[26] = "Rubbing hands together";
	StimText[27] = "Rubbing arms or thighs";
	StimText[28] = "Picking skin and scabs";
	StimText[29] = "Peeling skin flakes, including from lips";
	StimText[30] = "Pulling hairs from head, face or body";
	StimText[31] = "Doodling";
	StimText[32] = "Cracking joints";
	StimText[33] = "Clenching and unclenching fists";
	StimText[34] = "Twisting hands/fingers";
	StimText[35] = "Fiddling with things";
	StimText[36] = "Spinning an object";
	StimText[37] = "Wiggling toes or feet";
	StimText[38] = "Bouncing leg/foot";
	StimText[39] = "Rocking back-&-forth";
	StimText[40] = "Rocking side-to-side";
	StimText[41] = "Rocking up and down";
	StimText[42] = "Spinning in circles";
	StimText[43] = "Pacing";
	StimText[44] = "Walking on toes";

#endif

#ifdef SWEDISH

	StimText[0] = "Prata med sig själv";
	StimText[1] = "Sjunga för sig själv";
	StimText[2] = "Nynna";
	StimText[3] = "Vissla";
	StimText[4] = "Trumma på öronen";
	StimText[5] = "Trycka på ögonen";
	StimText[6] = "Rulla med ögonen";
	StimText[7] = "Studera ett roterande, blinkande eller glittrande föremål";
	StimText[8] = "Peta näsan";
	StimText[9] = "Gnissla med tänderna";
	StimText[10] = "Klappra med tänderna";
	StimText[11] = "Räcka ut tungan";
	StimText[12] = "Suga på tummen";
	StimText[13] = "Suga på läppen";
	StimText[14] = "Bita sig i läppen, kinden eller tungan";
	StimText[15] = "Bita på naglarna";
	StimText[16] = "Bita eller pilla på nagelband eller fingertoppar";
	StimText[17] = "Tugga eller suga på hårslingor";
	StimText[18] = "Tugga eller suga på penna, tandpetare eller annat föremål";
	StimText[19] = "Klicka med en penna";
	StimText[20] = "Snurra en hårslinga";
	StimText[21] = "Trumma med fingrarna";
	StimText[22] = "Trumma med penna eller annat föremål";
	StimText[23] = "Trycka in naglarna under varandra, in i huden eller in i andra saker";
	StimText[24] = "Flaxa med händerna";
	StimText[25] = "Klappa händerna";
	StimText[26] = "Gnugga händerna";
	StimText[27] = "Gnugga sina armar eller lår";
	StimText[28] = "Pilla på hud och sårskorpor";
	StimText[29] = "Dra bort hudflagor, inkl från läpparna";
	StimText[30] = "Dra ut hårstrån";
	StimText[31] = "Kludda/rita figurer";
	StimText[32] = "Knäcka leder";
	StimText[33] = "Upprepat knyta nävarna";
	StimText[34] = "Vrida händerna/fingrarna";
	StimText[35] = "Pilla på något föremål";
	StimText[36] = "Snurra på föremål";
	StimText[37] = "Vicka på tårna eller fötterna";
	StimText[38] = "Vippa med benet eller foten";
	StimText[39] = "Sittandes vagga kroppen framåtillbaka";
	StimText[40] = "Vagga i sidled";
	StimText[41] = "Vagga upp och ned";
	StimText[42] = "Snurra hela kroppen runt, runt";
	StimText[43] = "Vanka av och an";
	StimText[44] = "Gå på tå";

#endif

#ifdef ENGLISH

	ReasonText[1] = "When happy";
	ReasonText[2] = "When excited";
	ReasonText[3] = "When relaxed";
	ReasonText[4] = "When thinking";
	ReasonText[5] = "When bored";
	ReasonText[6] = "When sad";
	ReasonText[7] = "When disappointed";
	ReasonText[8] = "When depressed";
	ReasonText[9] = "When distressed";
	ReasonText[10] = "When worried";
	ReasonText[11] = "When anxious";
	ReasonText[12] = "When nervous";
	ReasonText[13] = "When restless";
	ReasonText[14] = "When stressed";
	ReasonText[15] = "When overstimulated";
	ReasonText[16] = "When overwhelmed";
	ReasonText[17] = "When in physical or emotional pain";
	ReasonText[18] = "When confused";
	ReasonText[19] = "When indecisive";
	ReasonText[20] = "When upset";
	ReasonText[21] = "When frustrated";
	ReasonText[22] = "When angry";
	ReasonText[23] = "When concentrated";
	ReasonText[24] = "When you like somebody";
	ReasonText[25] = "When you dislike somebody";
	ReasonText[26] = "For comfort";
	ReasonText[27] = "To calm myself";
	ReasonText[28] = "To concentrate";
	ReasonText[29] = "To release excess energy";
	ReasonText[30] = "For fun";
	ReasonText[31] = "It's pleasurable";
	ReasonText[32] = "Other";

#endif

#ifdef SWEDISH

	ReasonText[1] = "När jag är lycklig";
	ReasonText[2] = "När jag är upprymd";
	ReasonText[3] = "När jag är avslappnad";
	ReasonText[4] = "När jag tänker";
	ReasonText[5] = "När jag är uttråkad";
	ReasonText[6] = "När jag är ledsen";
	ReasonText[7] = "När jag är besviken";
	ReasonText[8] = "När jag är deprimerad";
	ReasonText[9] = "När jag är olycklig";
	ReasonText[10] = "När jag är orolig";
	ReasonText[11] = "När jag är rädd eller har ångest";
	ReasonText[12] = "När jag är nervös";
	ReasonText[13] = "När jag är rastlös";
	ReasonText[14] = "När jag är stressad";
	ReasonText[15] = "När jag är överstimulerad";
	ReasonText[16] = "När jag är överväldigad";
	ReasonText[17] = "Av fysisk eller emotionell smärta";
	ReasonText[18] = "När jag är förvirrad";
	ReasonText[19] = "När jag inte kan bestämma mig";
	ReasonText[20] = "När jag är upprörd";
	ReasonText[21] = "När jag är frustrerad";
	ReasonText[22] = "När jag är arg";
	ReasonText[23] = "När jag är koncentrerad";
	ReasonText[24] = "När jag gillar någon";
	ReasonText[25] = "När jag ogillar någon";
	ReasonText[26] = "Som tröst";
	ReasonText[27] = "För att lugna ner mig";
	ReasonText[28] = "För att koncentrera mig";
	ReasonText[29] = "För att göra av med överskottsenergi";
	ReasonText[30] = "För att det är roligt";
	ReasonText[31] = "För att det är njutbart";
	ReasonText[32] = "Annan orsak";

#endif
}

/*##################  TStim::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TStim::Add(TQuizRow *Row)
{
	int i;
	int j;
	int index;

	for (i = 0; i < 45; i++)
	{
		  for (j = 0; j < 3; j++)
		  {
				if (Row->Stim[i][j])
				{
					 index = Row->Stim[i][j];
					 if (index < 33 && index >= 0)
					 {
//					      StimChoice[i][index]++;
						  StimChoice[i][index] += 3 - j;
						  StimCount[i]++;
						  ChoiceCount[index]++;
					 }
				}
		  }
	}
}

/*##################  TStim::WriteStimRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TStim::WriteStimRow(TFile &file, int index)
{
	char str[20];
	int i;
	int j;
	int max;
	int min;
	int val;
	int currind;
	int used[33];


	max = 0;
	for (i = 1; i <= 32; i++)
	{
		used[i] = FALSE;

		val = StimChoice[index][i];
		if (val > max && !Ignore[i])
		{
			max = val;
			currind = i;
		}
	}

	min = max * 6 / 10;

	if (max)
	{
		file.Write("<b>");
		file.Write(StimText[index]);
		file.Write("</b>");
		sprintf(str, " (%d)", StimCount[index]);
		file.Write(str);
		file.Write(":  ");
		file.Write(ReasonText[currind]);
		used[currind] = TRUE;

		while (max)
		{
			sprintf(str, " (%d)", max);
			file.Write(str);

			max = 0;

			for (i = 1; i <= 32; i++)
			{
				if (!used[i] && !Ignore[i])
				{
					val = StimChoice[index][i];
					if (val >= min && val > max)
					{
						max = val;
						currind = i;
					}
				}
			}

			if (max)
			{
				file.Write(", ");
				file.Write(ReasonText[currind]);
				used[currind] = TRUE;
			}
		}

		file.Write("<br>\n");
	}
}

/*##################  TStim::WriteChoiceRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TStim::WriteChoiceRow(TFile &file, int index)
{
    char str[20];
	int i;
    int j;
	int max;
	int min;
	int val;
	int currind;
	int used[45];
	

    max = 0;
    for (i = 1; i < 45; i++)
    {
        used[i] = FALSE;
        
        val = StimChoice[i][index];
        if (val > max)
        {
            max = val;
			currind = i;
        }
    }

    min = max * 6 / 10;

    if (max)
    {
        file.Write("<b>");
    	file.Write(ReasonText[index]);
    	file.Write("</b>");
		sprintf(str, " (%d)", ChoiceCount[index]);
		file.Write(str);
    	file.Write(":  ");
    	file.Write(StimText[currind]);
    	used[currind] = TRUE;

        while (max)
        {
            sprintf(str, " (%d)", max);
            file.Write(str);
            
            max = 0;
        
            for (i = 0; i < 45; i++)
			{
                if (!used[i])
                {
                    val = StimChoice[i][index];
                    if (val >= min && val > max)
                    {
                        max = val;                    
                        currind = i;
                    }
                }
            }

            if (max)
            {
                file.Write(", ");
                file.Write(StimText[currind]);
                used[currind] = TRUE;
            }
        }

        file.Write("<br>\n");
	}
}

/*##################  TQuiz5::WriteHair ##########################
*   Purpose....: Write hair report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::WriteHair(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	THair hair;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		hair.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Hair-color, whole population");
				break;

			case 1:
				file.Write("Hair-color, English speaking");
				break;

			case 2:
				file.Write("Hair-color, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		THair::WriteHeader(file);

		hair.WriteRow(file, i, 0, "Red/Strawberry blond/auburn");
		hair.WriteRow(file, i, 1, "Blond");
		hair.WriteRow(file, i, 2, "Brown");
		hair.WriteRow(file, i, 3, "Black");

		file.Write("</table>");

		file.Write("<br><br>");

	}

}

/*##################  TQuiz8::WriteEye ##########################
*   Purpose....: Write eye color report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::WriteEye(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TEye eye;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		eye.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Eye color, whole population");
				break;

			case 1:
				file.Write("Eye color, English speaking");
				break;

			case 2:
				file.Write("Eye color, Swedish speaking");
				break;

		}

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TEye::WriteHeader(file);

		eye.WriteRow(file, i, 0, "Grey-blue/Blue");
		eye.WriteRow(file, i, 1, "Green");
		eye.WriteRow(file, i, 2, "Hazel/Brown");

		file.Write("</table>");

		file.Write("<br><br>");

	}
}

/*##################  TQuiz8::WriteStim ##########################
*   Purpose....: Write stim report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz8::WriteStim(const char *filename)
{
	TQuizRow Row;
	int i;
	int j;
	int index;
	int ival;
	char str[80];
	TFile file(filename, 0);
	int Used[45];
	int max;

    TStim stim;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		stim.Add(&Row);

	file.Write("<h3>");

#ifdef ENGLISH	
	file.Write("Stim results");
#endif

#ifdef SWEDISH	
	file.Write("Stim resultat");
#endif
	
	file.Write("</h3><br>");


    for (j = 0; j < 45; j++)
        Used[j] = FALSE;
        
    for (i = 0; i < 45; i++)
    {
        max = 0;

        for (j = 0; j < 45; j++)
				if (!Used[j] && stim.StimCount[j] > max)
				{
					 index = j;
					 max = stim.StimCount[j];
            }
    
        stim.WriteStimRow(file, index);
        Used[index] = TRUE;
    }

	file.Write("<br><br>");

    for (j = 1; j < 33; j++)
        Used[j] = FALSE;
        
    for (i = 1; i < 33; i++)
    {
        max = 0;

        for (j = 1; j < 33; j++)
				if (!Used[j] && stim.ChoiceCount[j] > max)
				{
					 index = j;
					 max = stim.ChoiceCount[j];
				}
    
        stim.WriteChoiceRow(file, index);
        Used[index] = TRUE;
    }

	file.Write("<br><br>");
}
