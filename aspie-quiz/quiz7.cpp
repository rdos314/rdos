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
# quiz7.cpp
# Quiz 7 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quiz7.h"
#include "file.h"
#include "quizdb7.h"

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

class TRace
{
public:
	TRace();
	void Add(TQuizRow *Row);
	void WriteUsRow(TFile &file, int index, const char *text);
	void WriteNonUsRow(TFile &file, int index, const char *text);
    void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);

	int UsCount[10];
	int UsAsCount[10];
	int NonUsCount[10];
	int NonUsAsCount[10];
};

/*##########################################################################
#
#   Name       : TQuiz7::TQuiz7
#
#   Purpose....: Constructor for TQuiz7
#
#   In params..: Filename to load quiz 7 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz7::TQuiz7(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6)
  : TQuiz(161),
	FDataFile(FileName)
{             
    DefineCross(0, QuizI);
	DefineCross(1, QuizII);
    DefineCross(2, QuizIII);
    DefineCross(3, QuizNd);
    DefineCross(4, Quiz5);
    DefineCross(5, Quiz6);

	SetupTexts();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
    SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6);
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuiz7::~TQuiz7
#
#   Purpose....: Destructor for TQuiz7
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz7::~TQuiz7()
{
}

/*##################  TQuiz7::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz7::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuiz7::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::WriteName(TFile &File)
{
    File.Write("7");
}

/*##########################################################################
#
#   Name       : TQuiz7::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::SetupTexts()
{
	Quiz[36].Reverse = TRUE;
	Quiz[38].Reverse = TRUE;
	Quiz[41].Reverse = TRUE;
	Quiz[43].Reverse = TRUE;
	Quiz[47].Reverse = TRUE;
	Quiz[48].Reverse = TRUE;
	Quiz[52].Reverse = TRUE;
	Quiz[55].Reverse = TRUE;
	Quiz[58].Reverse = TRUE;
	Quiz[59].Reverse = TRUE;
	Quiz[60].Reverse = TRUE;
	Quiz[61].Reverse = TRUE;
	Quiz[62].Reverse = TRUE;
	Quiz[63].Reverse = TRUE;
	Quiz[64].Reverse = TRUE;
	Quiz[65].Reverse = TRUE;
	Quiz[66].Reverse = TRUE;
	Quiz[67].Reverse = TRUE;
	Quiz[68].Reverse = TRUE;
	Quiz[71].Reverse = TRUE;
	Quiz[72].Reverse = TRUE;
	Quiz[77].Reverse = TRUE;
	Quiz[79].Reverse = TRUE;
	Quiz[80].Reverse = TRUE;
	Quiz[82].Reverse = TRUE;
	Quiz[97].Reverse = TRUE;
	Quiz[98].Reverse = TRUE;
	Quiz[99].Reverse = TRUE;
	Quiz[101].Reverse = TRUE;
	Quiz[102].Reverse = TRUE;
	Quiz[116].Reverse = TRUE;
	Quiz[123].Reverse = TRUE;
	Quiz[124].Reverse = TRUE;
	Quiz[125].Reverse = TRUE;
	Quiz[133].Reverse = TRUE;
	Quiz[134].Reverse = TRUE;
	Quiz[135].Reverse = TRUE;
	Quiz[146].Reverse = TRUE;

	Quiz[0].MyGroup = GROUP_SENSORY;
	Quiz[1].MyGroup = GROUP_SENSORY;
	Quiz[2].MyGroup = GROUP_SENSORY;
	Quiz[3].MyGroup = GROUP_SENSORY;
	Quiz[4].MyGroup = GROUP_SENSORY;
	Quiz[5].MyGroup = GROUP_SENSORY;
	Quiz[6].MyGroup = GROUP_MIXED;
	Quiz[7].MyGroup = GROUP_SENSORY;
	Quiz[8].MyGroup = GROUP_SENSORY;
	Quiz[9].MyGroup = GROUP_ASPIE_COMM;
	Quiz[10].MyGroup = GROUP_ASPIE_COMM;
	Quiz[11].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[12].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[13].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[14].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[15].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[16].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[17].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[18].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[19].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[20].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[21].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[24].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[25].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[26].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[27].MyGroup = GROUP_NT_TALENT;
	Quiz[28].MyGroup = GROUP_NT_TALENT;
	Quiz[29].MyGroup = GROUP_NT_TALENT;
	Quiz[30].MyGroup = GROUP_NT_TALENT;
	Quiz[31].MyGroup = GROUP_ASPIE_COMM;
	Quiz[32].MyGroup = GROUP_NT_TALENT;
	Quiz[33].MyGroup = GROUP_NT_TALENT;
	Quiz[34].MyGroup = GROUP_NT_TALENT;
	Quiz[35].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[36].MyGroup = GROUP_NT_TALENT;
	Quiz[37].MyGroup = GROUP_NT_TALENT;
	Quiz[38].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[39].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[40].MyGroup = GROUP_MIXED;
	Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
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
	Quiz[53].MyGroup = GROUP_ASPIE_COMM;
	Quiz[54].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[55].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[56].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[57].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[58].MyGroup = GROUP_NT_SOCIAL;
	Quiz[59].MyGroup = GROUP_NT_SOCIAL;
	Quiz[60].MyGroup = GROUP_NT_SOCIAL;
	Quiz[61].MyGroup = GROUP_NT_SOCIAL;
	Quiz[62].MyGroup = GROUP_NT_SOCIAL;
	Quiz[63].MyGroup = GROUP_NT_SOCIAL;
	Quiz[64].MyGroup = GROUP_NT_SOCIAL;
	Quiz[65].MyGroup = GROUP_NT_SOCIAL;
	Quiz[66].MyGroup = GROUP_NT_SOCIAL;
	Quiz[67].MyGroup = GROUP_NT_SOCIAL;
	Quiz[68].MyGroup = GROUP_NT_SOCIAL;
	Quiz[69].MyGroup = GROUP_NONVERBAL;
	Quiz[70].MyGroup = GROUP_NONVERBAL;
	Quiz[71].MyGroup = GROUP_NONVERBAL;
	Quiz[72].MyGroup = GROUP_NONVERBAL;
	Quiz[73].MyGroup = GROUP_NONVERBAL;
	Quiz[74].MyGroup = GROUP_NONVERBAL;
	Quiz[75].MyGroup = GROUP_NONVERBAL;
	Quiz[76].MyGroup = GROUP_NONVERBAL;
	Quiz[77].MyGroup = GROUP_NONVERBAL;
	Quiz[78].MyGroup = GROUP_NONVERBAL;
	Quiz[79].MyGroup = GROUP_NONVERBAL;
	Quiz[80].MyGroup = GROUP_NONVERBAL;
	Quiz[81].MyGroup = GROUP_NONVERBAL;
	Quiz[82].MyGroup = GROUP_NONVERBAL;
	Quiz[83].MyGroup = GROUP_MIXED;
	Quiz[84].MyGroup = GROUP_REPETITION;
	Quiz[85].MyGroup = GROUP_REPETITION;
	Quiz[86].MyGroup = GROUP_REPETITION;
	Quiz[87].MyGroup = GROUP_REPETITION;
	Quiz[88].MyGroup = GROUP_REPETITION;
	Quiz[89].MyGroup = GROUP_REPETITION;
	Quiz[90].MyGroup = GROUP_REPETITION;
	Quiz[91].MyGroup = GROUP_REPETITION;
	Quiz[92].MyGroup = GROUP_REPETITION;
	Quiz[93].MyGroup = GROUP_REPETITION;
	Quiz[94].MyGroup = GROUP_SEX;
	Quiz[95].MyGroup = GROUP_SEX;
	Quiz[96].MyGroup = GROUP_SEX;
	Quiz[97].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[98].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[99].MyGroup = GROUP_NT_SOCIAL;
	Quiz[100].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[101].MyGroup = GROUP_NT_SOCIAL;
	Quiz[102].MyGroup = GROUP_NT_TALENT;
	Quiz[103].MyGroup = GROUP_MIXED;
	Quiz[104].MyGroup = GROUP_EMOTION;
	Quiz[105].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[106].MyGroup = GROUP_REPETITION;
	Quiz[107].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[108].MyGroup = GROUP_ASPIE_COMM;
	Quiz[109].MyGroup = GROUP_ASPIE_COMM;
	Quiz[110].MyGroup = GROUP_ASPIE_COMM;
	Quiz[111].MyGroup = GROUP_ASPIE_COMM;
	Quiz[112].MyGroup = GROUP_ASPIE_COMM;
	Quiz[113].MyGroup = GROUP_ASPIE_COMM;
	Quiz[114].MyGroup = GROUP_ASPIE_COMM;
	Quiz[115].MyGroup = GROUP_MIXED;
	Quiz[116].MyGroup = GROUP_NONVERBAL;
	Quiz[117].MyGroup = GROUP_MIXED;
	Quiz[118].MyGroup = GROUP_REPETITION;
	Quiz[119].MyGroup = GROUP_EMOTION;
	Quiz[120].MyGroup = GROUP_EMOTION;
	Quiz[121].MyGroup = GROUP_EMOTION;
	Quiz[122].MyGroup = GROUP_MIXED;
	Quiz[123].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[124].MyGroup = GROUP_NONVERBAL;
	Quiz[125].MyGroup = GROUP_NONVERBAL;
	Quiz[126].MyGroup = GROUP_ASPIE_COMM;
	Quiz[127].MyGroup = GROUP_ASPIE_COMM;
	Quiz[128].MyGroup = GROUP_ASPIE_COMM;
	Quiz[129].MyGroup = GROUP_ASPIE_COMM;
	Quiz[130].MyGroup = GROUP_ASPIE_COMM;
	Quiz[131].MyGroup = GROUP_MIXED;
	Quiz[132].MyGroup = GROUP_ASPIE_COMM;
	Quiz[133].MyGroup = GROUP_MIXED;
	Quiz[134].MyGroup = GROUP_NT_SOCIAL;
	Quiz[135].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[136].MyGroup = GROUP_ASPIE_COMM;
	Quiz[137].MyGroup = GROUP_SENSORY;
	Quiz[138].MyGroup = GROUP_ASPIE_COMM;
	Quiz[139].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[140].MyGroup = GROUP_MIXED;
	Quiz[141].MyGroup = GROUP_MIXED;
	Quiz[142].MyGroup = GROUP_ASPIE_COMM;
	Quiz[143].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[144].MyGroup = GROUP_EMOTION;
	Quiz[145].MyGroup = GROUP_MIXED;
	Quiz[146].MyGroup = GROUP_NT_SOCIAL;
	Quiz[147].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[148].MyGroup = GROUP_ASPIE_COMM;
	Quiz[149].MyGroup = GROUP_ASPIE_COMM;

	Quiz[150].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[151].MyGroup = GROUP_MIXED;
	Quiz[152].MyGroup = GROUP_SENSORY;
	Quiz[153].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[154].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[155].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[156].MyGroup = GROUP_MIXED;
	Quiz[157].MyGroup = GROUP_MIXED;
	Quiz[158].MyGroup = GROUP_MIXED;
	Quiz[159].MyGroup = GROUP_MIXED;
	Quiz[160].MyGroup = GROUP_MIXED;

#ifdef ENGLISH

	Quiz[0].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
	Quiz[1].Text = "Do you squint, or have you done so in the past?";
	Quiz[2].Text = "Do certain phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
	Quiz[3].Text = "Are you hyper- or hypo-sensitive to heat, cold, wind, humidity etc?";
	Quiz[4].Text = "Do you have a very acute sense of smell?";
	Quiz[5].Text = "Do you have a very acute sense of taste?";
	Quiz[6].Text = "Do you look, feel or act younger than your biological age?";
	Quiz[7].Text = "Are you irritated by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' textures/material?";
	Quiz[8].Text = "Are you bothered by fluorescent light?";
	Quiz[9].Text = "Do you feel an urge to peel skin-flakes off yourself and /or others?";
	Quiz[10].Text= "Do you tend to shut one of your eyes in strong sun-light?";
	Quiz[11].Text = "Are you flat-footed?";
	Quiz[12].Text = "Do you have difficulty catching a ball?";
	Quiz[13].Text = "Do you have a tendency to drop things?";
	Quiz[14].Text = "Are you slow to finish manual tasks?";
	Quiz[15].Text = "Do you have difficulties judging distances, height, depth or speed?";
	Quiz[16].Text = "Are you accident prone?";
	Quiz[17].Text = "Do you have difficulty hopping, skipping or riding a bike?";
	Quiz[18].Text = "Do you have unconventional, often unique ways of solving problems?";
	Quiz[19].Text = "Do you focus on one interest at a time and become an expert on that subject?";
	Quiz[20].Text = "Do you have unusual imagination and unique ideas that others don't seem to have?";
	Quiz[21].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
	Quiz[22].Text = "Do you have one special talent which you have emphasised and worked on?";
	Quiz[23].Text = "Are you very gifted in one or more areas?";
	Quiz[24].Text = "Do you consider yourself a very logical person?";
	Quiz[25].Text = "Do you like to figure out how things work?";
	Quiz[26].Text = "Do you have excellent vocabulary and/or a fascination with words?";
	Quiz[27].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
	Quiz[28].Text = "Do you find it difficult to take notes in lectures?";
	Quiz[29].Text = "Do you have trouble reading clocks?";
	Quiz[30].Text = "Do you have trouble with math?";
	Quiz[31].Text = "Do you forget where you put things?";
	Quiz[32].Text = "Do you often make spelling errors?";
	Quiz[33].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
	Quiz[34].Text = "Do you have difficulty remembering scores during games?";
	Quiz[35].Text = "Are you a fast reader?";
	Quiz[36].Text = "Do find it easy to remember math formulas?";
	Quiz[37].Text = "Do you find it difficult to calculate change received from a purchase?";
	Quiz[38].Text = "Do you find yourself at ease in romantic situations?";
	Quiz[39].Text = "Do you have difficulty compared to others your age in developing relationships and friendships?";
	Quiz[40].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
	Quiz[41].Text = "Are you good at party games?";
	Quiz[42].Text = "Have you felt different from others for most of your life?";
	Quiz[43].Text = "Do you find the usual courting behavior natural?";
	Quiz[44].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
	Quiz[45].Text = "Do you dislike being hugged when you haven't asked for it?";
	Quiz[46].Text = "Do you tend to feel nervous, shy, confused and/or like you don't fit in, in various social situations?";
	Quiz[47].Text = "Are you energised by being in the company of others?";
	Quiz[48].Text = "Do you enjoy team sport and group endeavours?";
	Quiz[49].Text = "Do you find social chitchat difficult, tiresome or a waste of time?";
	Quiz[50].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
	Quiz[51].Text = "Do you prefer to do things on your own?";
	Quiz[52].Text = "Do your friends mean more to you than hobbies and interests?";
	Quiz[53].Text = "Do you have an alternative view of what is attractive in the opposite sex compared to most others?";
	Quiz[54].Text = "Do you find it easier to communicate online than in real life?";
	Quiz[55].Text = "Do you find it easy to maintain your social network?";
	Quiz[56].Text = "Do you prefer animals to people?";
	Quiz[57].Text = "Do you feel uncomfortable with strangers?";
	Quiz[58].Text = "Is a large social network important for you?";
	Quiz[59].Text = "Is creating a social identity important for you?";
	Quiz[60].Text = "Do you prefer romance/drama films to science fiction/documentary films?";
	Quiz[61].Text = "Do you have an interest in fashion?";
	Quiz[62].Text = "Is your style and image important to you?";
	Quiz[63].Text = "Do you enjoy listening to gossip?";
	Quiz[64].Text = "Do you enjoy the status of a new car/new stereo/new TV?";
	Quiz[65].Text = "Is other people's image of you important to you?";
	Quiz[66].Text = "Do you talk to put others at ease even when you really have nothing to say?";
	Quiz[67].Text = "Do you enjoy make-up?";
	Quiz[68].Text = "Do you enjoy wearing jewelry?";
	Quiz[69].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
	Quiz[70].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
	Quiz[71].Text = "Can you read between the lines?";
	Quiz[72].Text = "Do you have an intuitive sense for what is the right thing to do socially?";
	Quiz[73].Text = "Do others often misunderstand you?";
	Quiz[74].Text = "Are you often surprised when you find out what people's true motives are?";
	Quiz[75].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
	Quiz[76].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
	Quiz[77].Text = "Do you read people well?";
	Quiz[78].Text = "Do you forget you are in a social situation when something else gets your attention?";
	Quiz[79].Text = "Can you spot hidden agendas with ease?";
	Quiz[80].Text = "Is it easy for you to interpret body language?";
	Quiz[81].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
	Quiz[82].Text = "Do you know when you are expected to offer an apology?";
	Quiz[83].Text = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
	Quiz[84].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
	Quiz[85].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
	Quiz[86].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
	Quiz[87].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
	Quiz[88].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed?";
	Quiz[89].Text = "Do you have certain simple & logical routines which you need to follow?";
	Quiz[90].Text = "Do you have a need for comfort items like blankets, stuffed animals etc?";
	Quiz[91].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
	Quiz[92].Text = "Do you have very strong attachments to certain objects?";
	Quiz[93].Text= "Do you have obsessions or compulsions (repeated irresistible impulses to do certain things)?";
	Quiz[94].Text= "Do you feel like you were born with the wrong gender?";
	Quiz[95].Text= "Do you have unusual sexual preferences?";
	Quiz[96].Text= "Are you homosexual or bisexual?";
	Quiz[97].Text= "Are you a leader?";
	Quiz[98].Text= "Do you like to speak in public?";
	Quiz[99].Text= "Are you willing to do almost anything to get attention?";
	Quiz[100].Text= "Are you a better listener than talker?";
	Quiz[101].Text= "Do you get bored by silence and stillness?";
	Quiz[102].Text= "Do you think before you act?";
	Quiz[103].Text= "Do you find verbal instructions confusing - - especially several at the same time?";
	Quiz[104].Text= "Are you easily distracted or overwhelmed?";
	Quiz[105].Text = "Do you tend to get so absorbed in your projects that you forget everything else?";
	Quiz[106].Text = "Do you need to do things yourself in order to remember them?";
	Quiz[107].Text = "Do you dislike eye-contact?";
	Quiz[108].Text = "Do you roll your eyes involuntary?";
	Quiz[109].Text = "Do you sniff?";
	Quiz[110].Text = "Do you stick your tounge out in inappropriate situations?";
	Quiz[111].Text = "Do you swear a lot?";
	Quiz[112].Text = "Do you talk to yourself?";
	Quiz[113].Text = "In conversations, do you use small sounds that others don't seem to use?";
	Quiz[114].Text = "Have you been accused of staring?";
	Quiz[115].Text = "Have you taken initiative only to find out it was not wanted?";
	Quiz[116].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
	Quiz[117].Text = "Are you fascinated by dates and/or numbers?";
	Quiz[118].Text = "Does it feel vitally important to be left undisturbed to persue your special interests?";
	Quiz[119].Text = "Have you been bullied, abused or taken advantage of in various situations?";
	Quiz[120].Text = "Do you find it very hard to learn things you are not interested in?";
	Quiz[121].Text = "Do you get surprised and disappointed when people are unfriendly and don't seem to understand or accept you as you are?";
	Quiz[122].Text = "Do you have a poor concept of time?";
	Quiz[123].Text = "Do you enjoy having a variety of choices to make each day?";
	Quiz[124].Text = "Do you get the big picture before noticing details?";
	Quiz[125].Text = "Are you gracious about criticism, correction and direction?";
	Quiz[126].Text = "Do you mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
	Quiz[127].Text = "Do you bounce your leg?";
	Quiz[128].Text = "Do you tap your fingers?";
	Quiz[129].Text = "Do you rock your body?";
	Quiz[130].Text = "Do you bite your nails?";
	Quiz[131].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
	Quiz[132].Text = "Do you roll your eyes as part of your communication?";
	Quiz[133].Text = "Do you wear a wrist-watch?";
	Quiz[134].Text = "Do you have tatoos?";
	Quiz[135].Text = "Can you whistle?";
	Quiz[136].Text = "Do you self-injure?";
	Quiz[137].Text = "Can you sense the feelings of animals?";
	Quiz[138].Text = "Do you chew on things?";
	Quiz[139].Text = "Do you have more body-hair than others of your gender?";
	Quiz[140].Text = "Do you have difficulty writing by hand?";
	Quiz[141].Text = "Are you pained by the sound of a motor-bike?";
	Quiz[142].Text = "Have you been hyperactive most of your life?";
	Quiz[143].Text = "Did you learn to read before you started school?";
	Quiz[144].Text = "Do you feel shame when you do something wrong?";
	Quiz[145].Text = "Are you sometimes afraid in safe situations, yet fearless in situations which may actually be dangerous?";
	Quiz[146].Text = "Do you find it natural to keep track of whom owes whom favours?";
	Quiz[147].Text = "Do you dislike it when people turn up at your home uninvited?";
	Quiz[148].Text = "Do you click or rub a pen for the fun of it?";
	Quiz[149].Text = "Do you sing for yourself or for your family?";

	Quiz[150].Text = "Social phobia";
	Quiz[151].Text = "Prefer flute";
	Quiz[152].Text = "Environmentalist";
	Quiz[153].Text = "Prefers cold";
    Quiz[154].Text = "Red hair-color";
	Quiz[155].Text = "Do you have brown eyes?";
	Quiz[156].Text = "Induced birth";
	Quiz[157].Text = "Premature birth";
	Quiz[158].Text = "Private religion";
	Quiz[159].Text = "Short-sighted";
	Quiz[160].Text = "Visual learner";

#endif

#ifdef SWEDISH
	Quiz[0].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
	Quiz[1].Text = "Skelar du eller har gjort det?";
	Quiz[2].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
	Quiz[3].Text = "Är du över- eller underkänslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
	Quiz[4].Text = "Har du extra känsligt luktsinne?";
	Quiz[5].Text = "Har du extra känsligt smaksinne?";
	Quiz[6].Text = "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
	Quiz[7].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda av 'fel' material?";
	Quiz[8].Text = "Är du känslig för vissa typer av ljus, t.ex lysrörsljus?";
	Quiz[9].Text = "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
	Quiz[10].Text= "Blundar du gärna med ena ögat i starkt solljus?";
	Quiz[11].Text = "Är du plattfot?";
	Quiz[12].Text = "Har du svårt för att fånga en boll?";
	Quiz[13].Text = "Har du en tendens att tappa saker?";
	Quiz[14].Text = "Är du långsam med att avsluta manuella uppgifter?";
	Quiz[15].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller hastighet?";
	Quiz[16].Text = "Skadar du dig lätt?";
	Quiz[17].Text = "Har du svårt för att hoppa eller cykla?";
	Quiz[18].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
	Quiz[19].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert på det?";
	Quiz[20].Text = "Har du ovanlig fantasi och unika idéer som andra inte verka ha?";
	Quiz[21].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
	Quiz[22].Text = "Har du en speciell talang som du har jobbat på?";
	Quiz[23].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
	Quiz[24].Text = "Anser du dig själv vara en väldigt logisk person?";
	Quiz[25].Text = "Tycker du om att lista ut hur saker fungerar?";
	Quiz[26].Text = "Har du utmärkt vokabulär och intresse för språk?";
	Quiz[27].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
	Quiz[28].Text = "Har du svårt att göra anteckningar under lektioner?";
	Quiz[29].Text = "Har du svårigheter att läsa av klockor?";
	Quiz[30].Text = "Har du problem med matematik?";
	Quiz[31].Text = "Glömmer du var du lagt saker?";
	Quiz[32].Text = "Gör du ofta stavfel?";
	Quiz[33].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
	Quiz[34].Text = "Har du svårt för att komma ihåg poängställningar under spel?";
	Quiz[35].Text = "Läser du snabbt?";
	Quiz[36].Text = "Tycker du det är enkelt att komma ihåg matematiska formler?";
	Quiz[37].Text = "Tycker du det är svårt att beräkna växel på ett köp?";
	Quiz[38].Text = "Trivs du med romantiska situationer?";
	Quiz[39].Text = "Har du svårare än dina jämnåriga att få vänner och partners?";
	Quiz[40].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
	Quiz[41].Text = "Är du bra på sällskapsspel?";
	Quiz[42].Text = "Har du känt dig annorlunda största delen av ditt liv?";
	Quiz[43].Text = "Tycker du det normala sättet att uppvakta varandra är naturligt?";
	Quiz[44].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
	Quiz[45].Text = "Tycker du illa om att bli kramad när du inte bett om det?";
	Quiz[46].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
	Quiz[47].Text = "Får du energi av att vara i sällskap med andra?";
	Quiz[48].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
	Quiz[49].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
	Quiz[50].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
	Quiz[51].Text = "Föredrar du att göra saker på egen hand?";
	Quiz[52].Text = "Betyder vänner mer för dig än hobbies och intressen?";
	Quiz[53].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet än vad många andra anser?";
	Quiz[54].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
	Quiz[55].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
	Quiz[56].Text = "Umgås du hellre med djur än med människor?";
	Quiz[57].Text = "Känner du dig obekväm bland främmande människor?";
	Quiz[58].Text = "Är ett stort socialt nätverk viktigt för dig?";
	Quiz[59].Text = "Är det viktigt för dig att skapa en social identitet?";
	Quiz[60].Text = "Föredrar du filmer om romantik / drama före filmer om vetenskap/dokumentärer?";
	Quiz[61].Text = "Är du intressad av mode?";
	Quiz[62].Text = "Är din stil och image viktig för dig?";
	Quiz[63].Text = "Tycker du om att lyssna på skvaller?";
	Quiz[64].Text = "Njuter du av den status som en ny bil/stereo/TV ger?";
	Quiz[65].Text = "Är andra människors syn på dig viktigt för dig?";
	Quiz[66].Text = "Pratar du för att andra ska känna sig väl till mods även om du inte har något att säga?";
	Quiz[67].Text = "Gillar du att sminka dig?";
	Quiz[68].Text = "Gillar du att bära smycken?";
	Quiz[69].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
	Quiz[70].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
	Quiz[71].Text = "Kan du läsa mellan raderna?";
	Quiz[72].Text = "Känner du intuitivt av vad som är rätt socialt?";
	Quiz[73].Text = "Missförstår andra ofta dig?";
	Quiz[74].Text = "Blir du ofta överraskad när du får reda på vad folks verkliga motiv är?";
	Quiz[75].Text = "Är du oftast omedveten om outtalade sociala regler?";
	Quiz[76].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
	Quiz[77].Text = "Är du bra på att läsa av folk?";
	Quiz[78].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
	Quiz[79].Text = "Kan du lätt avslöja dolda motiv?";
	Quiz[80].Text = "Har du lätt för att tolka kroppsspråk?";
	Quiz[81].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
	Quiz[82].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
	Quiz[83].Text = "Har du en tendens att lätt bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?";
	Quiz[84].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
	Quiz[85].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
	Quiz[86].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
	Quiz[87].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
	Quiz[88].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
	Quiz[89].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
	Quiz[90].Text = "Har du behov av gosefilt, kramdjur eller liknande?";
	Quiz[91].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
	Quiz[92].Text = "Är du exceptionellt fäst vid vissa saker?";
	Quiz[93].Text= "Har du tvångssyndrom (= tvångstankar eller oemotståndliga, upprepade, irrationella impulser att göra vissa saker)?";
	Quiz[94].Text= "Känns det som du föddes med fel kön?";
	Quiz[95].Text= "Har du ovanliga sexuella preferenser?";
	Quiz[96].Text= "Är du homosexuell eller bisexuell?";
	Quiz[97].Text= "Är du en ledare?";
	Quiz[98].Text= "Tycker du om att tala offentligt?";
	Quiz[99].Text= "Gör du lite allt möligt för uppmärksamhet?";
	Quiz[100].Text= "Är du en bättre lyssnare än talare?";
	Quiz[101].Text= "Blir du uttråkad när det är lugnt och tyst?";
	Quiz[102].Text= "Tänker du innan du agerar?";
	Quiz[103].Text= "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
	Quiz[104].Text= "Blir du lätt distraherad eller överväldigad?";
	Quiz[105].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat?";
	Quiz[106].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
	Quiz[107].Text = "Ogillar du ögonkontakt?";
	Quiz[108].Text = "Rullar du med ögonen ofrivilligt?";
	Quiz[109].Text = "Sniffar du?";
	Quiz[110].Text = "Räcker du ut tungan vid fel tillfällen?";
	Quiz[111].Text = "Svär du mycket?";
	Quiz[112].Text = "Pratar du med dig själv?";
	Quiz[113].Text = "Använder du små ljud som andra inte verkar använda i samtal?";
	Quiz[114].Text = "Har du blivit anklagad för att glo?";
	Quiz[115].Text = "Tar du ibland initiativ som inte visar sig önskade?";
	Quiz[116].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
	Quiz[117].Text = "Är du fascinerad av datum och/eller siffror?";
	Quiz[118].Text = "Känns det livsviktigt att få vara ifred och ägna dig åt dina specialintressen i lugn och ro?";
	Quiz[119].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
	Quiz[120].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
	Quiz[121].Text = "Blir du förvånad och besviken när folk är ovänliga och inte tycks förstå eller acceptera dig som du är?";
	Quiz[122].Text = "Har du dålig tidsuppfattning?";
	Quiz[123].Text = "Gillar du att ha många olika saker du kan göra varje dag?";
	Quiz[124].Text = "Tar du först in helheten innan du upptäcker detaljer?";
	Quiz[125].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
	Quiz[126].Text = "Blandar du ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
	Quiz[127].Text = "Brukar du vippa med benet?";
	Quiz[128].Text = "Brukar du trumma med fingrarna?";
	Quiz[129].Text = "Brukar du gunga med kroppen?";
	Quiz[130].Text = "Brukar du bita på naglarna?";
	Quiz[131].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
	Quiz[132].Text = "Rullar du med ögonen som en del av din kommunikation?";
	Quiz[133].Text = "Bär du en armbandsklocka?";
	Quiz[134].Text = "Har du tatueringar?";
	Quiz[135].Text = "Kan du vissla?";
	Quiz[136].Text = "Skadar du dig själv?";
	Quiz[137].Text = "Känner du av djurs känslor?";
	Quiz[138].Text = "Tuggar du på saker?";
	Quiz[139].Text = "Har du mer kroppshår än andra av ditt kön?";
	Quiz[140].Text = "Har du svårt att skriva för hand?";
	Quiz[141].Text = "Gör ljudet från en motorcykel ont?";
	Quiz[142].Text = "Har du varit hyperaktiv största delen av ditt liv?";
	Quiz[143].Text = "Lärde du dig att läsa innan du började skolan?";
	Quiz[144].Text = "Skäms du när du gör något fel?";
	Quiz[145].Text = "Händer det att du är rädd i ofarliga situationer men orädd i situationer som faktiskt kan vara farliga?";
	Quiz[146].Text = "Känns det naturligt för dig att hålla reda på tjänster och gentjänster?";
	Quiz[147].Text = "Ogillar du att folk dyker upp vid ditt hem utan att du bjudit in dem?";
	Quiz[148].Text = "Klickar eller gnider du på en penna för skojs skull?";
	Quiz[149].Text = "Sjunger du för dig själv eller din familj?";

	Quiz[150].Text = "Social fobi";
	Quiz[151].Text = "Föredrar flöjt";
	Quiz[152].Text = "Miljöpartist";
	Quiz[153].Text = "Föredrar kyla över värme";
    Quiz[154].Text = "Röd hårfärg";
	Quiz[155].Text = "Har du bruna ögon?";
	Quiz[156].Text = "Igöngsatt födelse?";
	Quiz[157].Text = "För tidigt född?";
	Quiz[158].Text = "Privat religion";
	Quiz[159].Text = "Närsynt";
	Quiz[160].Text = "Visuell inlärning";

#endif
}

/*##########################################################################
#
#   Name       : TQuiz7::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
	AddReferer("wikipedia.org/wiki/As", "en.wikipedia.org/wiki/Aspergers");
	AddReferer("whoa.nu", "whoa.nu");
	AddReferer("airliners.net", "airliners.net/discussions/non_aviation/read.main/1295619");
	AddReferer("supermama.lt", "supermama.lt/forumas/index.php?showtopic=99238");
    AddReferer("dickflash.com", "dickflash.com");
 }

/*##########################################################################
#
#   Name       : TQuiz7::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
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

/*##################  TQuiz7::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz7::LoadReferers()
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

		if (Row.Ancestry == 3)
			if (Row.Hair >= 6 && Row.Eye >= 5)
				UpdateReferer(&AmerindianRef, Row.AsResult, Row.NtResult);

		if (Row.Ancestry == 5)
		{
			if (Row.Hair >= 6 && Row.Eye >= 5)
				UpdateReferer(&AfroAmericanRef, Row.AsResult, Row.NtResult);
			else
				UpdateReferer(&MixedAfroAmericanRef, Row.AsResult, Row.NtResult);
		}

		if (Row.Ancestry == 6)
			UpdateReferer(&HispanicRef, Row.AsResult, Row.NtResult);

		if (Row.Ancestry >= 1000 && Row.Ancestry < 2000)
		{
			if (Row.Hair >= 6 && Row.Eye >= 5)
				UpdateReferer(&AfricanRef, Row.AsResult, Row.NtResult);
			else
    			UpdateReferer(&MixedAfricanRef, Row.AsResult, Row.NtResult);
		}

		if ((Row.Ancestry >= 2000 && Row.Ancestry < 3000) || Row.Ancestry == 3205)
			UpdateReferer(&WhiteRef, Row.AsResult, Row.NtResult);

		if (Row.Ancestry >= 3000 && Row.Ancestry < 4000 && Row.Ancestry != 3205)
			UpdateReferer(&ArabRef, Row.AsResult, Row.NtResult);

		if (Row.Ancestry >= 4000)
			UpdateReferer(&AsianRef, Row.AsResult, Row.NtResult);

		if (Row.Social)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult);

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
#   Name       : TQuiz7::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::LoadPopulations()
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
		Row.Quiz[150] = Row.Social + 1;
		switch (Row.Music)
		{
		    case 1:
        		Row.Quiz[151] = 1;
        		break;

        	case 2:
        	    Row.Quiz[151] = 1;
        		break;

            case 3:
        	    Row.Quiz[151] = 3;
        	    break;
        }

		if (Row.Politics == 6)
	        Row.Quiz[152] = 3;
		else
		    Row.Quiz[152] = 1;

		switch (Row.Temp)
		{
	        case 1:
		    case 2:
		    case 3:
		    case 4:
		    case 5:
		        Row.Quiz[153] = 3;
		        break;

		    case 6:
		        Row.Quiz[153] = 2;
		        break;

		    case 7:
		    case 8:
		        Row.Quiz[153] = 1;
		        break;
		}

		switch (Row.Hair)
		{
		    case 1:
    		case 2:
	    	case 5:
		    	Row.Quiz[154] = 3;
    			break;

    		case 3:
	    		Row.Quiz[154] = 1;
		    	break;

		    case 4:
    		case 6:
	    		Row.Quiz[154] = 2;
    			break;

	    	case 7:
		    	Row.Quiz[154] = 0;
    			break;
	    }

		switch (Row.Eye)
		{
			case 1:
			case 2:
				Row.Quiz[155] = 1;
				break;

			case 3:
				Row.Quiz[155] = 2;
				break;

			case 4:
			case 5:
				Row.Quiz[155] = 3;
				break;
		}

		switch (Row.Premature)
		{
			case 1:
				Row.Quiz[156] = 0;
				Row.Quiz[157] = 0;
                break;
					        
			case 2:
        		Row.Quiz[156] = 3;
				Row.Quiz[157] = 1;
        		break;

            case 3:
        	    Row.Quiz[156] = 1;
				Row.Quiz[157] = 1;
			    break;

			case 4:
		    case 5:
        		Row.Quiz[156] = 1;
			    Row.Quiz[157] = 2;
			    break;
                                    					
			case 6:
			case 7:
        		Row.Quiz[156] = 1;
			    Row.Quiz[157] = 3;
			    break;
                            
        }

		switch (Row.Religion)
		{
            case 1:
			case 6:
		    case 11:
		        Row.Quiz[158] = 1;
			    break;

			case 26:
				Row.Quiz[158] = 3;
				break;


            default:
				Row.Quiz[158] = 2;
				break;
        }					        
		
		switch (Row.Vision)
		{
			case 3:
			case 4:
			    Row.Quiz[159] = 2;
				break;
					        
			case 5:
			case 6:
				Row.Quiz[159] = 3;
				break;

            default:
                Row.Quiz[159] = 1;
                break;
        }

        switch (Row.Learn)
		{
            case 1:
		        Row.Quiz[160] = 1;
			    break;

	        case 2:
			    Row.Quiz[160] = 2;
			    break;

			case 3:
			    Row.Quiz[160] = 3;
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

		if (Row.Social)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

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
#   Name       : TQuiz7::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("whoa.nu");
	DefineNt("airliners.net");
	DefineNt("supermama.lt");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("xmission.com/~winter");
	DefineAspie("delphiforums.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuiz7::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6)
{
	DefineCross(Quiz6, 0, 0);
	DefineCross(Quiz6, 1, 1);
	DefineCross(Quiz6, 2, 2);
	DefineCross(Quiz6, 3, 4);
	DefineGlobalId(    4, 388);
	DefineGlobalId(    5, 389);
	DefineCross(Quiz6, 6, 128);
	DefineCross(Quiz6, 7, 6);
	DefineCross(Quiz6, 8, 8);
	DefineCross(Quiz6, 9, 133);
	DefineGlobalId(    10, 390);
	DefineCross(Quiz6, 11, 124);
	DefineGlobalId(    12, 391);
	DefineCross(Quiz6, 13, 13);
	DefineCross(Quiz6, 14, 14);
	DefineCross(Quiz6, 15, 15);
	DefineCross(Quiz6, 16, 17);
	DefineCross(Quiz6, 17, 16);
	DefineCross(Quiz6, 18, 41);
	DefineCross(Quiz6, 19, 42);
	DefineCross(Quiz6, 20, 45);
	DefineCross(Quiz6, 21, 46);
	DefineCross(Quiz6, 22, 48);
	DefineCross(Quiz6, 23, 47);
	DefineCross(Quiz6, 24, 50);
	DefineCross(Quiz6, 25, 51);
	DefineCross(Quiz6, 26, 52);
	DefineCross(Quiz6, 27, 99);
	DefineCross(Quiz6, 28, 100);
	DefineCross(Quiz6, 29, 101);
	DefineGlobalId(    30, 392);
	DefineCross(Quiz6, 31, 102);
	DefineCross(Quiz6, 32, 104);
	DefineCross(Quiz6, 33, 105);
	DefineCross(Quiz6, 34, 106);
	DefineGlobalId(    35, 393);
	DefineCross(Quiz5, 36, 95);
	DefineCross(Quiz6, 37, 108);
	DefineCross(Quiz6, 38, 64);
	DefineCross(Quiz6, 39, 69);
	DefineCross(Quiz6, 40, 70);
	DefineCross(Quiz6, 41, 71);
	DefineCross(Quiz6, 42, 74);
	DefineCross(Quiz6, 43, 72);
	DefineCross(Quiz6, 44, 73);
	DefineCross(Quiz6, 45, 76);
	DefineCross(Quiz6, 46, 78);
	DefineCross(Quiz6, 47, 77);
	DefineCross(Quiz6, 48, 79);
	DefineCross(Quiz6, 49, 80);
	DefineCross(Quiz6, 50, 86);
	DefineCross(Quiz6, 51, 82);
	DefineCross(Quiz6, 52, 83);
	DefineCross(Quiz6, 53, 85);
	DefineCross(Quiz6, 54, 67);
	DefineCross(Quiz6, 55, 97);
	DefineCross(Quiz6, 56, 65);
	DefineCross(Quiz6, 57, 87);
	DefineCross(Quiz6, 58, 96);
	DefineCross(Quiz6, 59, 90);
	DefineCross(Quiz6, 60, 137);
	DefineCross(Quiz6, 61, 88);
	DefineCross(Quiz6, 62, 89);
	DefineCross(Quiz6, 63, 91);
	DefineCross(Quiz6, 64, 93);
	DefineCross(Quiz6, 65, 94);
	DefineCross(Quiz6, 66, 92);
	DefineGlobalId(    67, 394);
	DefineGlobalId(    68, 395);
	DefineCross(Quiz6, 69, 18);
	DefineCross(Quiz6, 70, 19);
	DefineCross(Quiz6, 71, 21);
	DefineCross(Quiz6, 72, 20);
	DefineCross(Quiz6, 73, 23);
	DefineCross(Quiz6, 74, 26);
	DefineCross(Quiz6, 75, 24);
	DefineCross(Quiz6, 76, 25);
	DefineCross(Quiz6, 77, 27);
	DefineCross(Quiz6, 78, 28);
	DefineCross(Quiz6, 79, 29);
	DefineCross(Quiz6, 80, 30);
	DefineCross(Quiz6, 81, 22);
	DefineCross(Quiz6, 82, 129);
	DefineCross(Quiz6, 83, 55);
	DefineCross(Quiz6, 84, 44);
	DefineCross(Quiz6, 85, 56);
	DefineCross(Quiz6, 86, 57);
	DefineCross(Quiz6, 87, 54);
	DefineCross(Quiz6, 88, 53);
	DefineCross(Quiz6, 89, 58);
	DefineCross(Quiz6, 90, 59);
	DefineCross(Quiz6, 91, 60);
	DefineCross(Quiz6, 92, 62);
	DefineCross(Quiz6, 93, 61);
	DefineCross(Quiz6, 94, 121);
	DefineCross(Quiz6, 95, 122);
	DefineCross(QuizII, 96, 56);
	DefineCross(Quiz6, 97, 112);
	DefineCross(Quiz6, 98, 120);
	DefineCross(Quiz6, 99, 119);
	DefineCross(Quiz6, 100, 109);
	DefineCross(Quiz6, 101, 117);
	DefineCross(Quiz6, 102, 113);
	DefineCross(Quiz6, 103, 125);
	DefineCross(Quiz6, 104, 126);
	DefineCross(Quiz6, 105, 40);
	DefineGlobalId(    106, 396);
	DefineGlobalId(    107, 397);
	DefineGlobalId(    108, 398);
	DefineGlobalId(    109, 399);
	DefineCross(QuizNd, 110, 54);
	DefineCross(QuizNd, 111, 56);
	DefineGlobalId(    112, 400);
	DefineGlobalId(    113, 401);
	DefineGlobalId(    114, 402);
	DefineCross(Quiz6, 115, 32);
	DefineCross(Quiz6, 116, 75);
	DefineCross(Quiz6, 117, 43);
	DefineCross(Quiz6, 118, 49);
	DefineCross(Quiz6, 119, 81);
	DefineCross(Quiz6, 120, 130);
	DefineCross(Quiz6, 121, 131);
	DefineCross(Quiz6, 122, 98);
	DefineCross(Quiz6, 123, 138);
	DefineCross(Quiz6, 124, 132);
	DefineCross(Quiz6, 125, 135);
	DefineCross(Quiz6, 126, 136);
	DefineGlobalId(    127, 403);
	DefineGlobalId(    128, 404);
	DefineGlobalId(    129, 405);
	DefineGlobalId(    130, 406);
	DefineCross(Quiz6, 131, 146);
	DefineGlobalId(    132, 407);
	DefineGlobalId(    133, 408);
	DefineGlobalId(    134, 409);
	DefineGlobalId(    135, 410);
	DefineGlobalId(    136, 411);
	DefineGlobalId(    137, 412);
	DefineGlobalId(    138, 413);
	DefineGlobalId(    139, 414);
	DefineGlobalId(    140, 415);
	DefineGlobalId(    141, 416);
	DefineGlobalId(    142, 417);
	DefineGlobalId(    143, 418);
	DefineGlobalId(    144, 419);
	DefineCross(QuizI, 145, 79);
	DefineCross(QuizII, 146, 46);
	DefineGlobalId(    147, 420);
	DefineGlobalId(    148, 421);
	DefineGlobalId(    149, 422);

	DefineGlobalId(    150, 423);
	DefineGlobalId(    151, 424);
	DefineGlobalId(    152, 425);
	DefineGlobalId(    153, 426);
	DefineCross(Quiz6, 154, 150);
	DefineCross(Quiz6, 155, 151);
	DefineGlobalId(    156, 480);
	DefineGlobalId(    157, 481);
	DefineGlobalId(    158, 482);
	DefineGlobalId(    159, 483);
	DefineGlobalId(    160, 484);
}

/*##########################################################################
#
#   Name       : TQuiz7::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz7::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuiz7::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz7::ExportExcelCase(const char *filename, int PcaType)
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
						else
							ival = 1;

						if (ival > 2)
							ival = 1;
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

/*##################  TQuiz7::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz7::ExportExcelGroups(const char *filename)
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

/*##################  TQuiz7::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz7::ImportMvsp(const char *filename, int PcaType)
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

    if (Row->Country == 7302 && Row->Ancestry >= 2000 && Row->Ancestry < 3000)
    {
	    if (diff > 0)
		    AsCount[1][index]++;
    	else
	    	NtCount[1][index]++;
	 }

    if (Row->Lang == 0 && Row->Ancestry >= 2000 && Row->Ancestry < 3000)
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


    if (Row->Country == 7302 && Row->Ancestry >= 2000 && Row->Ancestry < 3000)
    {
	    if (diff > 0)
		    AsCount[1][index]++;
    	else
	    	NtCount[1][index]++;
	 }

    if (Row->Lang == 0 && Row->Ancestry >= 2000 && Row->Ancestry < 3000)
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

/*##################  TRace::TRace ##########################
*   Purpose....: Initialize TRace                 			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TRace::TRace()
{
	int i;

    for (i = 0; i < 10; i++)
    {
		UsCount[i] = 0;
		UsAsCount[i] = 0;
		NonUsCount[i] = 0;
		NonUsAsCount[i] = 0;
    }
}

/*##################  TRace::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::Add(TQuizRow *Row)
{
	int index = -1;
	int diff = Row->AsResult - Row->NtResult;

    if (Row->Country == 7302)
    {
    	if (Row->Ancestry == 3 && Row->Hair >= 6 && Row->Eye >= 5)
	    	index = 0;      // american indian

    	if (Row->Ancestry == 5)
	        index = 1;

	    if (Row->Ancestry == 6)
		    index = 2;      // hispanic

    	if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
    	    index = 1;

	    if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
		    index = 3;      // white

    	if (Row->Ancestry >= 3000 && Row->Ancestry < 4000 && Row->Ancestry != 3205)
	    	index = 4;      // arab

    	if (Row->Ancestry >= 4000)
	    	index = 5;      // asian

    	if (index >= 0)
	    {
		    UsCount[index]++;

    		if (diff > 0)
	    		UsAsCount[index]++;
        }
    }
    else
    {
    	if (Row->Ancestry == 3) // && Row->Hair >= 6 && Row->Eye >= 5)
	    	index = 0;      // american indian

    	if (Row->Ancestry == 5)
	    {
		    if (Row->Hair >= 6 && Row->Eye >= 5)
			    index = 1;      // african american
    		else
	    		index = 2;      // mixed american
    	}

	    if (Row->Ancestry == 6)
		    index = 3;      // hispanic

    	if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
	    {
    		if (Row->Hair >= 6 && Row->Eye >= 5)
	    		index = 4;      // black african
		    else
			    index = 5;      // mixed african
    	}

	    if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
		    index = 6;      // white

    	if (Row->Ancestry >= 3000 && Row->Ancestry < 4000 && Row->Ancestry != 3205)
	    	index = 7;      // arab

    	if (Row->Ancestry >= 4000)
	    	index = 8;      // asian

    	if (index >= 0)
	    {
		    NonUsCount[index]++;

    		if (diff > 0)
	    		NonUsAsCount[index]++;
	    }
	}
}

/*##################  TRace::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Race");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Count");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Interest");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS proportion");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TRace::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteEntry(TFile &file, int val, int count)
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
	}
	else
	    file.Write("---");
	
#else
    ival = val * 1000 / count;
    sprintf(str, "%d.%01d%", ival / 10, ival % 10);
    file.Write(str);
#endif

	WriteFieldFooter(file);
}

/*##################  TRace::WriteUsRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteUsRow(TFile &file, int index, const char *text)
{
    char str[80];
    int sum;
    int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
    file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsCount[index]);
    file.Write(str);
	WriteFieldFooter(file);

    sum = 0;
    for (i = 0; i < 10; i++)
        sum += UsCount[i];            

    if (sum)
    {
        WriteEntry(file, UsCount[index], sum);

		if (UsCount[index])
            WriteEntry(file, UsAsCount[index], UsCount[index]);
    }
	else
	    file.Write("---");

    file.Write("</tr>");
}

/*##################  TRace::WriteNonUsRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteNonUsRow(TFile &file, int index, const char *text)
{
    char str[80];
    int sum;
    int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
    file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", NonUsCount[index]);
    file.Write(str);
	WriteFieldFooter(file);

    sum = 0;
    for (i = 0; i < 10; i++)
        sum += NonUsCount[i];            

    if (sum)
    {
        WriteEntry(file, NonUsCount[index], sum);

		if (NonUsCount[index])
            WriteEntry(file, NonUsAsCount[index], NonUsCount[index]);
    }
	else
	    file.Write("---");

    file.Write("</tr>");
}

/*##################  TQuiz5::WriteHair ##########################
*   Purpose....: Write hair report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz7::WriteHair(const char *filename)
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
				file.Write("Hair-color, US Caucasians");
				break;

			case 2:
				file.Write("Hair-color, English-speaking Caucasians");
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

/*##################  TQuiz5::WriteEye ##########################
*   Purpose....: Write eye color report                   			     	        #
 *   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz7::WriteEye(const char *filename)
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
				file.Write("Eye color, US Caucasians");
				break;

			case 2:
				file.Write("Eye color, English-speaking Caucasians");
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

/*##################  TQuiz7::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz7::WriteRace(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
    char str[80];
	TFile file(filename, 0);

    TRace race;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	    race.Add(&Row);

	file.Write("<h2>US population</h2>");
        
    file.Write("<table border=3 cellspacing=0 cellpadding=0>");

    TRace::WriteHeader(file);

    race.WriteUsRow(file, 0, "Native American");
    race.WriteUsRow(file, 1, "Black African");
    race.WriteUsRow(file, 2, "Hispanic");
    race.WriteUsRow(file, 3, "Caucasian");
    race.WriteUsRow(file, 4, "Arab");
    race.WriteUsRow(file, 5, "Asian");

    file.Write("</table>");

    file.Write("<br><br>");

	file.Write("<h2>Non-US population</h2>");
        
    file.Write("<table border=3 cellspacing=0 cellpadding=0>");

    TRace::WriteHeader(file);

    race.WriteNonUsRow(file, 0, "Native American");
    race.WriteNonUsRow(file, 1, "African American");
	race.WriteNonUsRow(file, 2, "Mixed American");
    race.WriteNonUsRow(file, 3, "Hispanic");
    race.WriteNonUsRow(file, 4, "Black African");
    race.WriteNonUsRow(file, 5, "Mixed African");
    race.WriteNonUsRow(file, 6, "Caucasian");
    race.WriteNonUsRow(file, 7, "Arab");
    race.WriteNonUsRow(file, 8, "Asian");

    file.Write("</table>");
}
