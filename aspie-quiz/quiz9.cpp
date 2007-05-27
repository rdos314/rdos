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

#include "quiz9.h"
#include "file.h"
#include "quizdb9.h"

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

class TABO
{
public:
	TABO();
	void Add(TQuizRow *Row);
	void WriteRow(TFile &file, int report, int index, const char *text);
    void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);
	int AsCount[4][7];
	int NtCount[4][7];
};

class TBirthMonth
{
public:
	TBirthMonth();
	void Add(TQuizRow *Row);
	void WriteRow(TFile &file, int report, int index, const char *text);
	void WriteEntry(TFile &file, int val, int count);
	int GetFactor(int index);
	void ExportHistogram(const char *filename);

	static void WriteHeader(TFile &file);
	int AsCount[4][15];
	int NtCount[4][15];
};

class TDisease
{
public:
	TDisease();

    virtual int GetDisease(TQuizRow *Row) = 0;
	virtual void Add(TQuizRow *Row) = 0;

	void WriteRow(TFile &file, int report, int index, const char *text);
    void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file, const char *Name);
	int AsCount[4][7];
	int NtCount[4][7];
};

class TDiseaseParent : public TDisease
{
public:
	virtual void Add(TQuizRow *Row);
};

class TDiseaseAll : public TDisease
{
public:
	virtual void Add(TQuizRow *Row);
};
	

class TParkinson : public TDiseaseParent
{
public:
    virtual int GetDisease(TQuizRow *Row);
};

class TAlzheimer : public TDiseaseParent
{
public:
    virtual int GetDisease(TQuizRow *Row);
};

class TCFTR : public TDiseaseAll
{
public:
    virtual int GetDisease(TQuizRow *Row);
};

class THFE : public TDiseaseAll
{
public:
    virtual int GetDisease(TQuizRow *Row);
};

class TLeiden : public TDiseaseAll
{
public:
    virtual int GetDisease(TQuizRow *Row);
};

/*##########################################################################
#
#   Name       : TQuiz9::TQuiz9
#
#   Purpose....: Constructor for TQuiz9
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz9::TQuiz9(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8)
  : TQuiz(153),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8);
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuiz9::~TQuiz9
#
#   Purpose....: Destructor for TQuiz9
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz9::~TQuiz9()
{
}

/*##################  TQuiz9::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz9::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuiz9::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::WriteName(TFile &File)
{
	 File.Write("9");
}

/*##################  TQuiz9::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuiz9::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::SetupTexts()
{
  Quiz[6].Reverse = TRUE;
  Quiz[13].Reverse = TRUE;
  Quiz[16].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[46].Reverse = TRUE;
  Quiz[47].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[52].Reverse = TRUE;
  Quiz[53].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[65].Reverse = TRUE;
  Quiz[66].Reverse = TRUE;
  Quiz[68].Reverse = TRUE;
  Quiz[69].Reverse = TRUE;
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
  Quiz[83].Reverse = TRUE;
  Quiz[85].Reverse = TRUE;
  Quiz[100].Reverse = TRUE;
  Quiz[102].Reverse = TRUE;
  Quiz[103].Reverse = TRUE;
  Quiz[104].Reverse = TRUE;
  Quiz[108].Reverse = TRUE;
  Quiz[109].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;
  Quiz[140].Reverse = TRUE;
  Quiz[141].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[1].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[2].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[3].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[4].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[5].MyGroup = GROUP_SENSORY;
  Quiz[6].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[7].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[8].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[9].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[10].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[11].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[12].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[13].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[14].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[15].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[16].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[17].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[18].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[19].MyGroup = GROUP_SENSORY;
  Quiz[20].MyGroup = GROUP_SENSORY;
  Quiz[21].MyGroup = GROUP_SENSORY;
  Quiz[22].MyGroup = GROUP_SENSORY;
  Quiz[23].MyGroup = GROUP_SENSORY;
  Quiz[24].MyGroup = GROUP_SENSORY;
  Quiz[25].MyGroup = GROUP_SENSORY;
  Quiz[26].MyGroup = GROUP_SENSORY;
  Quiz[27].MyGroup = GROUP_SENSORY;
  Quiz[28].MyGroup = GROUP_SENSORY;
  Quiz[29].MyGroup = GROUP_SENSORY;
  Quiz[30].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[31].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[35].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[36].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[37].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[38].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[39].MyGroup = GROUP_NT_TALENT;
  Quiz[40].MyGroup = GROUP_NT_TALENT;
  Quiz[41].MyGroup = GROUP_NT_TALENT;
  Quiz[42].MyGroup = GROUP_NT_TALENT;
  Quiz[43].MyGroup = GROUP_NT_TALENT;
  Quiz[44].MyGroup = GROUP_NT_TALENT;
  Quiz[45].MyGroup = GROUP_NT_TALENT;
  Quiz[46].MyGroup = GROUP_NT_TALENT;
  Quiz[47].MyGroup = GROUP_NT_TALENT;
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
  Quiz[61].MyGroup = GROUP_NONVERBAL;
  Quiz[62].MyGroup = GROUP_ASPIE_COMM;
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
  Quiz[83].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[84].MyGroup = GROUP_ASPIE_COMM;
  Quiz[85].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[86].MyGroup = GROUP_ASPIE_NVC;
  Quiz[87].MyGroup = GROUP_ASPIE_COMM;
  Quiz[88].MyGroup = GROUP_ASPIE_NVC;
  Quiz[89].MyGroup = GROUP_ASPIE_NVC;
  Quiz[90].MyGroup = GROUP_ASPIE_NVC;
  Quiz[91].MyGroup = GROUP_ASPIE_NVC;
  Quiz[92].MyGroup = GROUP_ASPIE_NVC;
  Quiz[93].MyGroup = GROUP_ASPIE_COMM;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_COMM;
  Quiz[96].MyGroup = GROUP_ASPIE_NVC;
  Quiz[97].MyGroup = GROUP_ASPIE_COMM;
  Quiz[98].MyGroup = GROUP_NONVERBAL;
  Quiz[99].MyGroup = GROUP_NONVERBAL;
  Quiz[100].MyGroup = GROUP_NONVERBAL;
  Quiz[101].MyGroup = GROUP_NONVERBAL;
  Quiz[102].MyGroup = GROUP_NONVERBAL;
  Quiz[103].MyGroup = GROUP_NONVERBAL;
  Quiz[104].MyGroup = GROUP_NONVERBAL;
  Quiz[105].MyGroup = GROUP_NONVERBAL;
  Quiz[106].MyGroup = GROUP_NONVERBAL;
  Quiz[107].MyGroup = GROUP_ASPIE_COMM;
  Quiz[108].MyGroup = GROUP_NONVERBAL;
  Quiz[109].MyGroup = GROUP_NONVERBAL;
  Quiz[110].MyGroup = GROUP_ASPIE_COMM;
  Quiz[111].MyGroup = GROUP_ASPIE_COMM;
  Quiz[112].MyGroup = GROUP_ASPIE_COMM;
  Quiz[113].MyGroup = GROUP_ASPIE_COMM;
  Quiz[114].MyGroup = GROUP_ASPIE_COMM;
  Quiz[115].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[116].MyGroup = GROUP_ASPIE_COMM;
  Quiz[117].MyGroup = GROUP_ASPIE_COMM;
  Quiz[118].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[119].MyGroup = GROUP_SEX;
  Quiz[120].MyGroup = GROUP_SEX;
  Quiz[121].MyGroup = GROUP_SEX;
  Quiz[122].MyGroup = GROUP_SEX;
  Quiz[123].MyGroup = GROUP_ASPIE_COMM;
  Quiz[124].MyGroup = GROUP_NT_TALENT;
  Quiz[125].MyGroup = GROUP_NONVERBAL;
  Quiz[126].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[127].MyGroup = GROUP_NT_TALENT;
  Quiz[128].MyGroup = GROUP_ASPIE_COMM;
  Quiz[129].MyGroup = GROUP_ASPIE_COMM;
  Quiz[130].MyGroup = GROUP_NT_TALENT;
  Quiz[131].MyGroup = GROUP_ASPIE_COMM;
  Quiz[132].MyGroup = GROUP_ASPIE_COMM;
  Quiz[133].MyGroup = GROUP_ASPIE_COMM;
  Quiz[134].MyGroup = GROUP_ASPIE_COMM;
  Quiz[135].MyGroup = GROUP_ASPIE_COMM;
  Quiz[136].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[137].MyGroup = GROUP_ASPIE_COMM;
  Quiz[138].MyGroup = GROUP_MIXED;
  Quiz[139].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[140].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[141].MyGroup = GROUP_NONVERBAL;
  Quiz[142].MyGroup = GROUP_ASPIE_COMM;
  Quiz[143].MyGroup = GROUP_ASPIE_COMM;
  Quiz[144].MyGroup = GROUP_ASPIE_COMM;
  Quiz[145].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[146].MyGroup = GROUP_SENSORY;
  Quiz[147].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[148].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[149].MyGroup = GROUP_ASPIE_BIOLOGY;

  Quiz[150].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[151].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[152].MyGroup = GROUP_ASPIE_SOCIAL;

#ifdef ENGLISH
  Quiz[0].Text = "Do you have a small mouth?";
  Quiz[1].Text = "Do you have odd teeth; e.g. teeth that are crooked or bigger than usual; gaps; overlaps; underbite etc.?";
  Quiz[2].Text = "Are you flat-footed?";
  Quiz[3].Text = "Do you have loose joints that have dislocated?";
  Quiz[4].Text = "Are you shorter than what is normal for your gender?";
  Quiz[5].Text = "Do you have eczema?";
  Quiz[6].Text = "Do you have a strong grip?";
  Quiz[7].Text = "Are your ears lower set than normal?";
  Quiz[8].Text = "Do your ears stick out?";
  Quiz[9].Text = "Do you have difficulty throwing or catching a ball?";
  Quiz[10].Text = "Do you have a tendency to drop things?";
  Quiz[11].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[12].Text = "Do you have difficulties with fine motor skills and/or hand-eye co-ordination?";
  Quiz[13].Text = "Did you enjoy classes like handi-work or gymnasics in school?";
  Quiz[14].Text = "Do you have difficulty riding a bike?";
  Quiz[15].Text = "Are you accident prone?";
  Quiz[16].Text = "Do you have a good sense for how much pressure to apply when you do someting with your hands?";
  Quiz[17].Text = "Can you whistle?";
  Quiz[18].Text = "Are you good at climbing?";
  Quiz[19].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
  Quiz[20].Text = "Do you squint now or have done in the past?";
  Quiz[21].Text = "Do you have a very acute sense of taste?";
  Quiz[22].Text = "Are you sensitive to heat, cold, wind and/or changes in air-pressure, humidity etc?";
  Quiz[23].Text = "Do you see yourself as sensitive?";
  Quiz[24].Text = "Do you have a very acute sense of smell?";
  Quiz[25].Text = "Are you sensitive to electromagnetic fields?";
  Quiz[26].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[27].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
  Quiz[28].Text = "Do you often use peripheral vision?";
  Quiz[29].Text = "Are you insensitive to physical pain, or even enjoy some types of pain?";
  Quiz[30].Text = "Do you have unconventional, often unique ways of solving problems?";
  Quiz[31].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[32].Text = "Is you imagination unusual, with unique ideas that others don't have?";
  Quiz[33].Text = "Do you have one special talent which you have emphasised and worked on?";
  Quiz[34].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[35].Text = "Are you very gifted in one or more areas?";
  Quiz[36].Text = "Do you have excellent vocabulary and/or a fascination with words?";
  Quiz[37].Text = "Do you like to figure out how things work?";
  Quiz[38].Text = "Do you have excellent long-term memory in subjects that interest you?";
  Quiz[39].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[40].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
  Quiz[41].Text = "Do you have trouble reading clocks?";
  Quiz[42].Text = "Do you forget where you put things?";
  Quiz[43].Text = "Do you instinctively know what time it is when someone asks you?";
  Quiz[44].Text = "Do you often make spelling errors?";
  Quiz[45].Text = "Do you have difficulty remembering scores during games?";
  Quiz[46].Text = "Are you good at remembering birthdays?";
  Quiz[47].Text = "Can you easily remember sequences of past events?";
  Quiz[48].Text = "Do you find preferable/easier to understand & communicate with computers, animals or unusual people?";
  Quiz[49].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[50].Text = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";
  Quiz[51].Text = "Have you felt different from others for most of your life?";
  Quiz[52].Text = "Are you the life of a party?";
  Quiz[53].Text = "Are you good at party games?";
  Quiz[54].Text = "Do you tend to feel nervous, shy, confused and/or like you don't fit in, in various social situations?";
  Quiz[55].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
  Quiz[56].Text = "Do you find the usual courting behavior natural?";
  Quiz[57].Text = "Are you fairly self-absorbed, more interested in yourself than in others and/or an objective observer of yourself?";
  Quiz[58].Text = "Do you dislike being hugged when you haven't asked for it?";
  Quiz[59].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[60].Text = "Do you prefer to do things on your own even if you could use others work or expertice?";
  Quiz[61].Text = "Is your sense of humor different from mainstream and / or considered odd?";
  Quiz[62].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[63].Text = "Do you dislike eye-contact?";
  Quiz[64].Text = "Do you find social chitchat difficult, tiresome or a waste of time?";
  Quiz[65].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[66].Text = "Are you energised by being in the company of others?";
  Quiz[67].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[68].Text = "Do you find it easy to maintain your social network?";
  Quiz[69].Text = "Are you comfortable in social situations and with new people?";
  Quiz[70].Text = "Do you have problems with eye-contact?";
  Quiz[71].Text = "Do you feel uncomfortable with strangers?";
  Quiz[72].Text = "Are your dreams and fantasies much like those of others?";
  Quiz[73].Text = "Do you prefer to know a little about many things rather than becoming a specialist in one or a few areas?";
  Quiz[74].Text = "Is a large social network important for you?";
  Quiz[75].Text = "Is climing the social hierarchy important to you?";
  Quiz[76].Text = "Is creating a social identity important for you?";
  Quiz[77].Text = "Do you like to be in charge of other people?";
  Quiz[78].Text = "Do you enjoy listening to gossip?";
  Quiz[79].Text = "Do you have an interest for the current fashions?";
  Quiz[80].Text = "Is your style and image important to you?";
  Quiz[81].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
  Quiz[82].Text = "Is other people's image of you important to you?";
  Quiz[83].Text = "Do you enjoy the status of a new car/new stereo/new TV?";
  Quiz[84].Text = "Do you find it natural to keep track of whom owes whom favours?";
  Quiz[85].Text = "Do you enjoy wearing jewelry?";
  Quiz[86].Text = "Do you roll your eyes when frustrated?";
  Quiz[87].Text = "Have you been accused of staring?";
  Quiz[88].Text = "Do you talk to yourself?";
  Quiz[89].Text = "Do you sniff?";
  Quiz[90].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[91].Text = "Do your hands shake?";
  Quiz[92].Text = "Do you rock your body?";
  Quiz[93].Text = "Do you have an urge to climb?";
  Quiz[94].Text = "Do you click or rub a pen for the fun of it?";
  Quiz[95].Text = "Do you examine the hair of people you like a lot?";
  Quiz[96].Text = "Do you bounce your leg?";
  Quiz[97].Text = "Do you have an urge to jump over objects?";
  Quiz[98].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[99].Text = "Are you often surprised when you find out what people's true motives are?";
  Quiz[100].Text = "Do you have an intuitive sense for what is the right thing to do socially?";
  Quiz[101].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[102].Text = "Can you read between the lines?";
  Quiz[103].Text = "Do you read people well?";
  Quiz[104].Text = "Is it easy for you to interpret body language?";
  Quiz[105].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[106].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
  Quiz[107].Text = "Do you have an odd posture, gait and/or difficulties sitting/standing erect?";
  Quiz[108].Text = "Can you spot hidden agendas with ease?";
  Quiz[109].Text = "Do you know when you are expected to offer an apology?";
  Quiz[110].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed?";
  Quiz[111].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[112].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[113].Text = "Does it feel vitally important to be left undisturbed to persue your special interests?";
  Quiz[114].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[115].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
  Quiz[116].Text = "Do you have strong attachments to certain objects?";
  Quiz[117].Text = "Do you have certain simple & logical routines which you need to follow?";
  Quiz[118].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[119].Text = "Do you feel like you were born with the wrong gender?";
  Quiz[120].Text = "Do you have unusual sexual preferences?";
  Quiz[121].Text = "Are you homosexual or bisexual?";
  Quiz[122].Text = "Do you have an interest in or have practised BD/SM?";
  Quiz[123].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[124].Text = "Are you easily distracted or overwhelmed?";
  Quiz[125].Text = "Do others often misunderstand you?";
  Quiz[126].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[127].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[128].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[129].Text = "Do you have an alternative view of what is attractive in the opposite sex compared to most others?";
  Quiz[130].Text = "Do you find it hard to learn things you are not interested in?";
  Quiz[131].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  Quiz[132].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[133].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[134].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[135].Text = "Do you rehearse inside your head?";
  Quiz[136].Text = "Are you afraid of heights?";
  Quiz[137].Text = "Do you like to dig holes in the ground?";
  Quiz[138].Text = "Do you like to eat liver?";
  Quiz[139].Text = "Do you like to eat seafood?";
  Quiz[140].Text = "Do you enjoy travel?";
  Quiz[141].Text = "Do you feel empathy for people once you understand their feelings?";
  Quiz[142].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[143].Text = "Do you refuse to give up on a relationship or potential relationship that others would not bother with?";
  Quiz[144].Text = "Do you get tears in your eyes when excited?";
  Quiz[145].Text = "Do you have good intuition about how things work?";
  Quiz[146].Text = "Do you have psychic abilities?";
  Quiz[147].Text = "Do you like tongue-kissing?";
  Quiz[148].Text = "Do you enjoy to snuggle a long time with certain familiar people?";
  Quiz[149].Text = "Do you use to have diarrhea?";

  Quiz[150].Text = "Red hair-color";
  Quiz[151].Text = "Do you have brown eyes?";
  Quiz[152].Text = "Born in autumn";
  
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du en liten mun?";
  Quiz[1].Text = "Har du udda tänder; t ex tänder som sitter snett, är större än vanligt; mellanrum mellan tänderna; tänder som klättrar på varandra; underbett etc.?";
  Quiz[2].Text = "Är du plattfot??";
  Quiz[3].Text = "Har du lösa leder som har hoppat ur led?";
  Quiz[4].Text = "Är du kortare än vad som är normalt för ditt kön?";
  Quiz[5].Text = "Har du eksem?";
  Quiz[6].Text = "Har du starka nypor?";
  Quiz[7].Text = "Sitter dina öron lägre än normalt?";
  Quiz[8].Text = "Sticker dina öron ut?";
  Quiz[9].Text = "Har du svårt för att kasta eller fånga en boll?";
  Quiz[10].Text = "Har du en tendens att tappa saker?";
  Quiz[11].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
  Quiz[12].Text = "Har du problem med finmotorik och/eller öga-hand koordination?";
  Quiz[13].Text = "Tyckte du om praktiska ämnen som slöjd och gymnastik i skolan?";
  Quiz[14].Text = "Har du svårt för att cykla?";
  Quiz[15].Text = "Skadar du dig lätt?";
  Quiz[16].Text = "Har du en bra känsla för hur mycket du ska ta i när du gör något med händerna?";
  Quiz[17].Text = "Kan du vissla?";
  Quiz[18].Text = "Är du bra på att klättra?";
  Quiz[19].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
  Quiz[20].Text = "Skelar du eller har gjort det?";
  Quiz[21].Text = "Har du extra känsligt smaksinne?";
  Quiz[22].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
  Quiz[23].Text = "Anser du att du är känslig?";
  Quiz[24].Text = "Har du extra känsligt luktsinne?";
  Quiz[25].Text = "Är du känslig för elektromagnetiska fält?";
  Quiz[26].Text = "Är du känslig för lyrsrörsljus?";
  Quiz[27].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
  Quiz[28].Text = "Använder du ofta periferseende?";
  Quiz[29].Text = "Är du okänslig för smärta eller till och med tycker om viss sorts smärta?";
  Quiz[30].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
  Quiz[31].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[32].Text = "Är din fantasi ovanlig med unika idéer som andra inte har?";
  Quiz[33].Text = "Har du en speciell talang som du har jobbat på?";
  Quiz[34].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[35].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[36].Text = "Har du utmärkt vokabulär och intresse för språk?";
  Quiz[37].Text = "Tycker du om att lista ut hur saker fungerar?";
  Quiz[38].Text = "Har du utmärkt långtidsminne när det gäller de ämnen du är intresserad av?";
  Quiz[39].Text = "Har du svårt att göra anteckningar under lektioner?";
  Quiz[40].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
  Quiz[41].Text = "Har du svårigheter att läsa av klockor?";
  Quiz[42].Text = "Glömmer du var du lagt saker?";
  Quiz[43].Text = "Vet du instinktivt hur mycket klockan är när någon frågar dig?";
  Quiz[44].Text = "Gör du ofta stavfel?";
  Quiz[45].Text = "Har du svårt för att komma ihåg poängställningar under spel?";
  Quiz[46].Text = "Är du bra på att komma ihåg födelsedagar?";
  Quiz[47].Text = "Kan du enkelt komma ihåg sekvenser av gångna händelser?";
  Quiz[48].Text = "Tycker du det är att föredra/lättare att förstå och kommunicera med datorer, djur eller udda människor?";
  Quiz[49].Text = "Trivs du i romantiska situationer?";
  Quiz[50].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
  Quiz[51].Text = "Har du känt dig annorlunda största delen av ditt liv?";
  Quiz[52].Text = "Är du aktiv på fester?";
  Quiz[53].Text = "Är du bra på sällskapsspel?";
  Quiz[54].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
  Quiz[55].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
  Quiz[56].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[57].Text = "Är du rätt självupptagen, mer intresserad av dig själv än av andra och/eller en objektiv självobservatör?";
  Quiz[58].Text = "Tycker du illa om att bli kramad när du inte bett om det?";
  Quiz[59].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[60].Text = "Föredrar du att göra saker på egen hand även om du skulle kunna använda andras arbete och expertis?";
  Quiz[61].Text = "Är ditt sinne för humor annorlunda än andras och / eller ansett som udda?";
  Quiz[62].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[63].Text = "Ogillar du ögonkontakt?";
  Quiz[64].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[65].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[66].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[67].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara aktuellt/modernt/inne?";
  Quiz[68].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
  Quiz[69].Text = "Känner du dig hemma i sociala situationer med nya människor?";
  Quiz[70].Text = "Har du problem med ögonkontakt?";
  Quiz[71].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[72].Text = "Är dina drömmar och fantasier likadana som andras?";
  Quiz[73].Text = "Föredrar du att veta lite om mycket framför att bli specialist inom något eller några få områden?";
  Quiz[74].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[75].Text = "Är det viktigt för dig att klättra i den sociala hierarkin?";
  Quiz[76].Text = "Är det viktigt för dig att skapa en social identitet?";
  Quiz[77].Text = "Gillar du att leda andra människor?";
  Quiz[78].Text = "Tycker du om att lyssna på skvaller?";
  Quiz[79].Text = "Är du intressad av nuvarande mode?";
  Quiz[80].Text = "Är din stil och image viktig för dig?";
  Quiz[81].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
  Quiz[82].Text = "Är andra människors syn på dig viktig för dig?";
  Quiz[83].Text = "Njuter du av den status som en ny bil/stereo/TV ger?";
  Quiz[84].Text = "Känns det naturligt för dig att hålla reda på tjänster och gentjänster?";
  Quiz[85].Text = "Gillar du att bära smycken?";
  Quiz[86].Text = "Rullar du med ögonen när du blir frustrerad?";
  Quiz[87].Text = "Har du blivit anklagad för att glo?";
  Quiz[88].Text = "Pratar du med dig själv?";
  Quiz[89].Text = "Sniffar du?";
  Quiz[90].Text = "Använder du små ljud som andra inte verkar använda i samtal?";
  Quiz[91].Text = "Skakar dina händer?";
  Quiz[92].Text = "Brukar du gunga med kroppen?";
  Quiz[93].Text = "Har du ett behov av att klättra?";
  Quiz[94].Text = "Klickar eller gnider du på en penna för skojs skull?";
  Quiz[95].Text = "Undersöker du håret på de som du gillar mycket?";
  Quiz[96].Text = "Brukar du vippa med benet?";
  Quiz[97].Text = "Har du ett behov av att hoppa över saker?";
  Quiz[98].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[99].Text = "Blir du ofta överraskad när du får reda på vad folks verkliga motiv är?";
  Quiz[100].Text = "Känner du intuitivt av vad som är rätt socialt?";
  Quiz[101].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[102].Text = "Kan du läsa mellan raderna?";
  Quiz[103].Text = "Är du bra på att läsa av folk?";
  Quiz[104].Text = "Har du lätt för att tolka kroppsspråk?";
  Quiz[105].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[106].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
  Quiz[107].Text = "Har du ovanlig kroppshållning, gångstil och/eller svårt att sitta/stå upprätt?";
  Quiz[108].Text = "Kan du lätt avslöja dolda motiv?";
  Quiz[109].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[110].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
  Quiz[111].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[112].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[113].Text = "Känns det livsviktigt att få vara ifred och ägna dig åt dina specialintressen i lugn och ro?";
  Quiz[114].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[115].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
  Quiz[116].Text = "Är du exceptionellt fäst vid vissa saker?";
  Quiz[117].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
  Quiz[118].Text = "Har du ett behov av symmerti, ordning och/eller precision?";
  Quiz[119].Text = "Känns det som om du fötts med fel kön?";
  Quiz[120].Text = "Har du ovanliga sexuella preferenser?";
  Quiz[121].Text = "Är du homosexuell eller bisexuell?";
  Quiz[122].Text = "Har du intresse för eller har du medverkat i BD/SM?";
  Quiz[123].Text = "Stänger du av eller bryter ihop när du blir stressad eller överväldigad?";
  Quiz[124].Text = "Blir du lätt distraherad eller överväldigad?";
  Quiz[125].Text = "Blir du ofta missförstådd av andra?";
  Quiz[126].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[127].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[128].Text = "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
  Quiz[129].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet än vad många andra anser?";
  Quiz[130].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[131].Text = "Känner du behov av att rycka loss hudflagor från dig själv (eller andra)?";
  Quiz[132].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
  Quiz[133].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[134].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[135].Text = "Tränar du scenarier inuti ditt huvud?";
  Quiz[136].Text = "Är du höjdrädd?";
  Quiz[137].Text = "Gräver du hål i marken?";
  Quiz[138].Text = "Tycker du om lever?";
  Quiz[139].Text = "Tycker du om fisk?";
  Quiz[140].Text = "Tycker du om att resa?";
  Quiz[141].Text = "Kan du känna empati för människor när du förstår hur de känner sig?";
  Quiz[142].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[143].Text = "Vägrar du ge upp en relation eller potentiell relation som andra inte skulle bry sig om";
  Quiz[144].Text = "Blir du tårögd när du blir upprymd";
  Quiz[145].Text = "Har du bra intuition för hur saker fungerar?";
  Quiz[146].Text = "Har du övernaturliga förmågor?";
  Quiz[147].Text = "Tycker du om tungkyssar?";
  Quiz[148].Text = "Gillar du att gosa länge med vissa du känner väl?";
  Quiz[149].Text = "Brukar du ha diarre?";

  Quiz[150].Text = "Röd hårfärg";
  Quiz[151].Text = "Har du bruna ögon?";
  Quiz[152].Text = "Född på hösten";

#endif

}

/*##########################################################################
#
#   Name       : TQuiz9::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::InitReferers()
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
#   Name       : TQuiz9::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
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

/*##################  TQuiz9::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::LoadReferers()
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
#   Name       : TQuiz9::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::LoadPopulations()
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
		switch (Row.Hair)
		{
			case 1:
			case 2:
			case 5:
				Row.Quiz[150] = 3;
				break;

			case 3:
				Row.Quiz[150] = 1;
				break;

			case 4:
			case 6:
				Row.Quiz[150] = 2;
				break;

			case 7:
				Row.Quiz[150] = 0;
				break;
		}

		switch (Row.Eye)
		{
			case 1:
			case 2:
				Row.Quiz[151] = 1;
				break;

			case 3:
				Row.Quiz[151] = 2;
				break;

			case 4:
			case 5:
				Row.Quiz[151] = 3;
				break;
		}

        switch (Row.BirthMonth)
        {
				case 2:
				case 3:
				case 4:
				case 5:
					 Row.Quiz[152] = 1;
					 break;

				case 8:
				case 9:
				case 10:
				case 11:
					 Row.Quiz[152] = 3;
					 break;

				default:
					Row.Quiz[152] = 2;
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
			{
			    if (Row.BirthYear > 1986)
			        YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			        
				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			}
			else
			{
			    if (Row.BirthYear > 1986)
			        YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			        
				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			}

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
#   Name       : TQuiz9::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::SetupControlGroups()
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
#   Name       : TQuiz9::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8)
{
    DefineCross(Quiz8, 0, 140);
	DefineCross(Quiz6, 1, 123);
    DefineCross(Quiz7, 2, 11);
    DefineCross(QuizIII, 3, 93);
    DefineCross(QuizIII, 4, 95);
	DefineCross(QuizNd, 5, 186);
	DefineGlobalId( 6, 459);
	DefineGlobalId( 7, 460);
	DefineGlobalId( 8, 461);
	DefineCross(Quiz8, 9, 20);
	DefineCross(Quiz7, 10, 13);
	DefineCross(Quiz8, 11, 22);
	DefineCross(QuizIII, 12, 11);
	DefineCross(QuizNd, 13, 22);
	DefineGlobalId( 14, 462);
	DefineCross(Quiz8, 15, 23);
	DefineCross(Quiz8, 16, 17);
	DefineCross(Quiz7, 17, 135);
	DefineCross(Quiz8, 18, 14);
	DefineCross(Quiz8, 19, 0);
	DefineCross(Quiz8, 20, 2);
	DefineCross(Quiz8, 21, 1);
	DefineCross(Quiz8, 22, 7);
	DefineCross(Quiz8, 23, 9);
	DefineCross(Quiz8, 24, 10);
	DefineCross(Quiz6, 25, 9);
	DefineCross(Quiz8, 26, 13);
	DefineCross(Quiz5, 27, 13);
	DefineCross(Quiz5, 28, 15);
	DefineGlobalId( 29, 463);
	DefineCross(Quiz8, 30, 26);
	DefineCross(Quiz8, 31, 27);
	DefineCross(Quiz8, 32, 29);
	DefineCross(Quiz8, 33, 28);
	DefineCross(Quiz8, 34, 30);
	DefineCross(Quiz8, 35, 31);
	DefineCross(Quiz8, 36, 33);
	DefineCross(Quiz8, 37, 32);
	DefineCross(QuizI, 38, 11);
	DefineCross(Quiz8, 39, 34);
	DefineCross(Quiz8, 40, 35);
	DefineCross(Quiz8, 41, 36);
	DefineCross(Quiz8, 42, 37);
	DefineCross(QuizNd, 43, 178);
	DefineCross(Quiz8, 44, 39);
	DefineCross(Quiz8, 45, 40);
	DefineCross(QuizNd, 46, 142);
	DefineCross(Quiz5, 47, 90);
	DefineCross(Quiz8, 48, 42);
	DefineCross(Quiz8, 49, 43);
	DefineCross(Quiz8, 50, 45);
	DefineCross(Quiz8, 51, 44);
	DefineCross(Quiz8, 52, 46);
	DefineCross(Quiz8, 53, 47);
	DefineCross(Quiz8, 54, 49);
	DefineCross(Quiz8, 55, 48);
	DefineCross(Quiz8, 56, 50);
	DefineCross(Quiz8, 57, 52);
	DefineCross(Quiz8, 58, 54);
	DefineCross(Quiz8, 59, 56);
	DefineCross(Quiz8, 60, 148);
	DefineCross(Quiz8, 61, 59);
	DefineCross(Quiz8, 62, 58);
	DefineCross(Quiz8, 63, 68);
	DefineCross(Quiz8, 64, 61);
	DefineCross(Quiz8, 65, 60);
	DefineCross(Quiz8, 66, 62);
	DefineCross(Quiz8, 67, 55);
	DefineCross(Quiz8, 68, 67);
	DefineCross(Quiz8, 69, 63);
	DefineCross(QuizI, 70, 71);
	DefineCross(Quiz8, 71, 66);
	DefineCross(QuizNd, 72, 134);
	DefineCross(QuizNd, 73, 60);
	DefineCross(Quiz8, 74, 71);
	DefineCross(Quiz8, 75, 82);
	DefineCross(Quiz8, 76, 72);
	DefineCross(Quiz8, 77, 73);
	DefineCross(Quiz8, 78, 75);
	DefineCross(Quiz8, 79, 74);
	DefineCross(Quiz8, 80, 77);
	DefineCross(Quiz8, 81, 76);
	DefineCross(Quiz8, 82, 78);
	DefineCross(Quiz8, 83, 79);
	DefineCross(Quiz7, 84, 146);
	DefineCross(Quiz8, 85, 80);
	DefineGlobalId( 86, 464);
	DefineCross(Quiz8, 87, 84);
	DefineCross(Quiz8, 88, 83);
	DefineCross(Quiz7, 89, 109);
	DefineCross(Quiz8, 90, 87);
	DefineCross(Quiz8, 91, 138);
	DefineCross(Quiz8, 92, 88);
	DefineCross(Quiz8, 93, 132);
	DefineCross(Quiz8, 94, 86);
	DefineCross(Quiz8, 95, 146);
	DefineCross(Quiz8, 96, 85);
	DefineCross(Quiz8, 97, 133);
	DefineCross(Quiz8, 98, 91);
	DefineCross(Quiz8, 99, 92);
	DefineCross(Quiz8, 100, 93);
	DefineCross(Quiz8, 101, 94);
	DefineCross(Quiz8, 102, 96);
	DefineCross(Quiz8, 103, 95);
	DefineCross(Quiz8, 104, 98);
	DefineCross(Quiz8, 105, 100);
	DefineCross(Quiz8, 106, 97);
	DefineCross(Quiz8, 107, 101);
	DefineCross(Quiz8, 108, 99);
	DefineCross(Quiz8, 109, 102);
	DefineCross(Quiz8, 110, 103);
	DefineCross(Quiz8, 111, 104);
	DefineCross(Quiz8, 112, 105);
	DefineCross(Quiz8, 113, 106);
	DefineCross(Quiz8, 114, 107);
	DefineCross(Quiz8, 115, 110);
	DefineCross(Quiz8, 116, 108);
	DefineCross(Quiz8, 117, 109);
	DefineCross(Quiz8, 118, 111);
	DefineCross(Quiz8, 119, 112);
	DefineCross(Quiz8, 120, 114);
	DefineCross(Quiz8, 121, 113);
	DefineCross(QuizIII, 122, 66);
	DefineCross(Quiz8, 123, 137);
	DefineCross(Quiz8, 124, 117);
	DefineCross(Quiz8, 125, 118);
	DefineCross(Quiz8, 126, 119);
	DefineCross(Quiz8, 127, 122);
	DefineCross(Quiz8, 128, 5);
	DefineCross(Quiz8, 129, 129);
	DefineCross(Quiz8, 130, 131);
	DefineCross(Quiz8, 131, 12);
	DefineCross(Quiz7, 132, 126);
	DefineCross(Quiz6, 133, 63);
	DefineCross(Quiz8, 134, 142);
	DefineGlobalId( 135, 465);
	DefineGlobalId( 136, 466);
	DefineGlobalId( 137, 467);
	DefineGlobalId( 138, 468);
	DefineGlobalId( 139, 469);
	DefineGlobalId( 140, 470);
	DefineGlobalId( 141, 471);
	DefineGlobalId( 142, 472);
	DefineGlobalId( 143, 473);
	DefineGlobalId( 144, 474);
	DefineGlobalId( 145, 475);
	DefineGlobalId( 146, 476);
	DefineGlobalId( 147, 477);
	DefineGlobalId( 148, 478);
	DefineGlobalId( 149, 479);
	DefineCross(Quiz8, 150, 151);
	DefineCross(Quiz8, 151, 152);
	DefineGlobalId( 152, 539);
}

/*##########################################################################
#
#   Name       : TQuiz9::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz9::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuiz9::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::ExportExcelCase(const char *filename, int PcaType)
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
					{
					    if (i >= 154)
						{
					        switch (Row.Quiz[i])
					        {
					            case 0:
					                ival = 1;
					                break;

					            case 1:
					            case 2:
					            case 3:
					            case 4:
					                ival = 0;
					                break;

					            case 5:
								case 6:
					            case 7:
					                ival = 1;
					                break;

					            case 8:
					            case 9:
					            case 10:
					            case 11:
					                ival = 2;
					                break;
					        }
						}
					    else
    						ival = Row.Quiz[i];    				    
						
				    }
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

/*##################  TQuiz9::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::ExportExcelGroups(const char *filename)
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

/*##################  TQuiz9::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_FEMALE)
						d2 = -d2;

					if (PcaType == PCA_TYPE_ALL)
						d3 = -d3;

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

/*##################  TABO::TABO ##########################
*   Purpose....: Initialize TABO                  			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TABO::TABO()
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

/*##################  TABO::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TABO::Add(TQuizRow *Row)
{
	int index;
	int diff = Row->AsResult - Row->NtResult;

	switch (Row->ABO)
	{
		case 1:
		case 5:
			index = 0;
			break;

		case 2:
		case 6:
			index = 1;
			break;

		case 3:
		case 7:
			index = 2;
			break;

		case 4:
		case 8:
			index = 3;
			break;

		default:
			return;
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

/*##################  TABO::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TABO::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("ABO");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("NT");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TABO::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TABO::WriteEntry(TFile &file, int val, int count)
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

/*##################  TABO::Write ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TABO::WriteRow(TFile &file, int report, int index, const char *text)
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

/*##################  TBirthMonth::TBirthMonth ##########################
*   Purpose....: Initialize TBirthMonth                  			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TBirthMonth::TBirthMonth()
{
    int i;
    int j;

    for (i = 0; i < 15; i++)
    {
        for (j = 0; j < 3; j++)
        {
			AsCount[j][i] = 0;
            NtCount[j][i] = 0;
        }
    }
}

/*##################  TBirthMonth::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TBirthMonth::Add(TQuizRow *Row)
{
	int index;
	int diff = Row->AsResult - Row->NtResult;

    index = Row->BirthMonth - 1;

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

/*##################  TBirthMonth::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TBirthMonth::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Birth month");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("NT");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TBirthMonth::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TBirthMonth::WriteEntry(TFile &file, int val, int count)
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

/*##################  TBirthMonth::Write ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TBirthMonth::WriteRow(TFile &file, int report, int index, const char *text)
{
    char str[80];
	int sum;
    int i;

    file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	file.Write(text);
	WriteFieldFooter(file);


    sum = 0;
	for (i = 0; i < 15; i++)
		sum += AsCount[report][i];

	if (sum)
		WriteEntry(file, AsCount[report][index], sum);
	else
		file.Write("---");

	sum = 0;
	for (i = 0; i < 15; i++)
		sum += NtCount[report][i];

	if (sum)
		WriteEntry(file, NtCount[report][index], sum);
	else
		file.Write("---");

	file.Write("</tr>");
}

/*##################  TBirthMonth::GetFactor ##########################
*   Purpose....: Get month factor                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TBirthMonth::GetFactor(int index)
{
	switch (index)
	{
		case 0:
		case 2:
		case 4:
		case 6:
		case 7:
		case 9:
		case 11:
			return 3225;

		case 1:
			return  3539;

		case 3:
		case 5:
		case 8:
		case 10:
			return 3333;
	}
}

/*##################  TBirthMonth::ExportHistogram ##########################
*   Purpose....: Export histogram                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TBirthMonth::ExportHistogram(const char *filename)
{
	char str[80];
	int val;
	int i;
	int assum;
	int ntsum;
	TFile file(filename, 0);

	assum = 0;
	ntsum = 0;

	for (i = 0; i < 12; i++)
	{
		assum += AsCount[0][i];
		ntsum += NtCount[0][i];
	}

	for (i = 0; i < 12; i++)
	{
		sprintf(str, "%d\t", 100 * (i + 1));
		file.Write(str);

		val = AsCount[0][i] * GetFactor(i);
		val = val / assum;
		sprintf(str, "%d\t", val);
		file.Write(str);

		val = NtCount[0][i] * GetFactor(i);
		val = val / ntsum;
		sprintf(str, "%d\n", val);
		file.Write(str);
	}

	for (i = 0; i < 12; i++)
	{
		sprintf(str, "%d\t", 100 * (i + 13));
		file.Write(str);

		val = AsCount[0][i] * GetFactor(i);
		val = val / assum;
		sprintf(str, "%d\t", val);
		file.Write(str);

		val = NtCount[0][i] * GetFactor(i);
		val = val / ntsum;
	    sprintf(str, "%d\n", val);
	    file.Write(str);	        
	}

	for (i = 0; i < 12; i++)
	{
		sprintf(str, "%d\t", 100 * (i + 25));
		file.Write(str);

		val = AsCount[0][i] * GetFactor(i);
		val = val / assum;
		sprintf(str, "%d\t", val);
		file.Write(str);

		val = NtCount[0][i] * GetFactor(i);
		val = val / ntsum;
		sprintf(str, "%d\n", val);
		file.Write(str);
	}
}

/*##################  TDisease::TDisease ##########################
*   Purpose....: Initialize TDisease                  			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TDisease::TDisease()
{
    int i;
    int j;

    for (i = 0; i < 7; i++)
    {
        for (j = 0; j < 4; j++)
        {
			AsCount[j][i] = 0;
            NtCount[j][i] = 0;
        }
    }
}

/*##################  TDisease::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDisease::WriteHeader(TFile &file, const char *Name)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write(Name);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("NT");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TDisease::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDisease::WriteEntry(TFile &file, int val, int count)
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

/*##################  TDisease::WriteRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDisease::WriteRow(TFile &file, int report, int index, const char *text)
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

/*##################  TDiseaseParent::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDiseaseParent::Add(TQuizRow *Row)
{
	int index;
	int diff = Row->AsResult - Row->NtResult;

	switch (GetDisease(Row))
	{
		case 0:
			index = 0;
			break;

		case 1:
			index = 1;
			break;

		case 2:
		case 3:
			index = 2;
			break;

		case 5:
		    index = 3;
		    break;

		default:
			index = 4;
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

/*##################  TDiseaseAll::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDiseaseAll::Add(TQuizRow *Row)
{
	int index;
	int diff = Row->AsResult - Row->NtResult;

	if (GetDisease(Row))
	    index = 1;
	else
	    index = 0;

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

/*##################  TParkinson::GetDisease ##########################
*   Purpose....: Get disease entry                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TParkinson::GetDisease(TQuizRow *Row)
{
    return Row->Parkinson;
}

/*##################  TAlzheimer::GetDisease ##########################
*   Purpose....: Get disease entry                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TAlzheimer::GetDisease(TQuizRow *Row)
{
	return Row->Alzheimer;
}

/*##################  TCFTR::GetDisease ##########################
*   Purpose....: Get disease entry                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TCFTR::GetDisease(TQuizRow *Row)
{
    return Row->CFTR;
}

/*##################  THFE::GetDisease ##########################
*   Purpose....: Get disease entry                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int THFE::GetDisease(TQuizRow *Row)
{
    return Row->HFE;
}

/*##################  TLeiden::GetDisease ##########################
*   Purpose....: Get disease entry                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TLeiden::GetDisease(TQuizRow *Row)
{
    return Row->Leiden;
}

/*##################  TQuiz9::WriteHair ##########################
*   Purpose....: Write hair report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteHair(const char *filename)
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

/*##################  TQuiz9::WriteEye ##########################
*   Purpose....: Write eye color report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteEye(const char *filename)
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

/*##################  TQuiz9::WriteABO ##########################
*   Purpose....: Write ABO report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteABO(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TABO ABO;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		ABO.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("ABO blood group, whole population");
				break;

			case 1:
				file.Write("ABO blood group, English speaking");
				break;

			case 2:
				file.Write("ABO blood group, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TABO::WriteHeader(file);

		ABO.WriteRow(file, i, 0, "O");
		ABO.WriteRow(file, i, 1, "A");
		ABO.WriteRow(file, i, 2, "B");
		ABO.WriteRow(file, i, 3, "AB");

		file.Write("</table>");

		file.Write("<br><br>");

	}

}

/*##################  TQuiz9::WriteBirthMonth ##########################
*   Purpose....: Write birth month report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteBirthMonth(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TBirthMonth BirthMonth;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		BirthMonth.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Birth month, whole population");
				break;

			case 1:
				file.Write("Birth month, English speaking");
				break;

			case 2:
				file.Write("Birth month, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TBirthMonth::WriteHeader(file);

		BirthMonth.WriteRow(file, i, 0, "Jan");
		BirthMonth.WriteRow(file, i, 1, "Feb");
		BirthMonth.WriteRow(file, i, 2, "Mar");
		BirthMonth.WriteRow(file, i, 3, "Apr");
		BirthMonth.WriteRow(file, i, 4, "May");
		BirthMonth.WriteRow(file, i, 5, "Jun");
		BirthMonth.WriteRow(file, i, 6, "Jul");
		BirthMonth.WriteRow(file, i, 7, "Aug");
		BirthMonth.WriteRow(file, i, 8, "Sep");
		BirthMonth.WriteRow(file, i, 9, "Oct");
		BirthMonth.WriteRow(file, i, 10, "Nov");
		BirthMonth.WriteRow(file, i, 11, "Dec");

		file.Write("</table>");

		file.Write("<br><br>");

	}

}


/*##################  TQuiz9::ExportBirthMonthHistogram ##########################
*   Purpose....: Export birth month histogram       			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::ExportBirthMonthHistogram(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];

	TBirthMonth BirthMonth;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		BirthMonth.Add(&Row);

    BirthMonth.ExportHistogram(filename);
}

/*##################  TQuiz9::WriteParkinson ##########################
*   Purpose....: Write Parkinson report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteParkinson(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TParkinson Parkinson;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		Parkinson.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Parkinson, whole population");
				break;

			case 1:
				file.Write("Parkinson, English speaking");
				break;

			case 2:
				file.Write("Parkinson, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TDisease::WriteHeader(file, "Parkinson");

		Parkinson.WriteRow(file, i, 2, "Parent/grandparent");

		file.Write("</table>");

		file.Write("<br><br>");

	}

}

/*##################  TQuiz9::WriteAlzheimer ##########################
*   Purpose....: Write Alzheimer report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteAlzheimer(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TAlzheimer Alzheimer;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		Alzheimer.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Alzheimer, whole population");
				break;

			case 1:
				file.Write("Alzheimer, English speaking");
				break;

			case 2:
				file.Write("Alzheimer, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TDisease::WriteHeader(file, "Alzheimer");

		Alzheimer.WriteRow(file, i, 2, "Parent/grandparent");

		file.Write("</table>");

		file.Write("<br><br>");

	}

}

/*##################  TQuiz9::WriteCFTR ##########################
*   Purpose....: Write Cystic fibrosis report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteCFTR(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TCFTR CFTR;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		CFTR.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Cystic fibrosis, whole population");
				break;

			case 1:
				file.Write("Cystic fibrosis, English speaking");
				break;

			case 2:
				file.Write("Cystic fibrosis, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TDisease::WriteHeader(file, "Cystic fibrosis");

		CFTR.WriteRow(file, i, 1, "All");

		file.Write("</table>");

		file.Write("<br><br>");

	}

}

/*##################  TQuiz9::WriteHFE ##########################
*   Purpose....: Write Hemochromatosis report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteHFE(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	THFE HFE;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		HFE.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Hemochromatosis, whole population");
				break;

			case 1:
				file.Write("Hemochromatosis, English speaking");
				break;

			case 2:
				file.Write("Hemochromatosis, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TDisease::WriteHeader(file, "Hemochromatosis");

		HFE.WriteRow(file, i, 1, "All");

		file.Write("</table>");

		file.Write("<br><br>");

	}
}

/*##################  TQuiz9::WriteLeiden ##########################
*   Purpose....: Write Factor V Leiden report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz9::WriteLeiden(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TLeiden Leiden;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		Leiden.Add(&Row);

	for (i = 0; i < 3; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Factor V Leiden, whole population");
				break;

			case 1:
				file.Write("Factor V Leiden, English speaking");
				break;

			case 2:
				file.Write("Factor V Leiden, Swedish speaking");
				break;
        }

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		TDisease::WriteHeader(file, "Factor V Leiden");

		Leiden.WriteRow(file, i, 1, "All");

		file.Write("</table>");

		file.Write("<br><br>");

	}
}
