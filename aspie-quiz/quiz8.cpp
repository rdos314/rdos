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

#define MAX_IN_ROW		1024

#define FALSE 0
#define TRUE !FALSE

class THair
{
public:
	THair();
	void Add(TQuizRow *Row);
	void WriteRow(TFile &file, int index, const char *text);
    void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);
	int AsCount[7];
	int NtCount[7];
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
  : TQuiz(125),
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
	 DefineID(1, 53);
	 DefineID(2, 390);
	 DefineID(3, 58);
	 DefineID(4, 178);
	 DefineID(5, 55);
	 DefineID(6, 230);
	 DefineID(7, 330);
	 DefineID(8, 61);
	 DefineID(9, 60);
	 DefineID(10, 234);
	 DefineID(11, 203);
	 DefineID(12, 389);
	 DefineID(13, 232);
	 DefineID(14, 160);
	 DefineID(15, 56);

#ifdef ENGLISH
	 DefineText(16, "Are you good at climbing?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef SWEDISH
	 DefineText(16, "Är du bra på att sjunga?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef ENGLISH
	 DefineText(17, "Are you good at jumping high?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef SWEDISH
	 DefineText(17, "Är du bra på att hoppa högt?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef ENGLISH
	 DefineText(18, "Do you have a firm handshake?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef SWEDISH
	 DefineText(18, "Har du ett starkt handslag?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef ENGLISH
	 DefineText(19, "Do you have a good sense for how much pressure your hands should apply?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef SWEDISH
	 DefineText(19, "Har du en bra känsla för hur mycket du ska ta i med händerna?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef ENGLISH
	 DefineText(20, "Do you have above average physical endurance?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef SWEDISH
	 DefineText(20, "Är du mer fysiskt uthållig än normalt?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef ENGLISH
	 DefineText(21, "Do you drop things when your attention is on other things?", GROUP_ASPIE_BIOLOGY);
#endif

#ifdef SWEDISH
	 DefineText(21, "Tappar du saker när din uppmärksamhet är på annat håll?", GROUP_ASPIE_BIOLOGY);
#endif

	 DefineID(22, 207);
	 DefineID(23, 214);
	 DefineID(24, 205);
	 DefineID(25, 46);
	 DefineID(26, 213);
	 DefineID(27, 204);
	 DefineID(28, 416);
	 DefineID(29, 23);
	 DefineID(30, 20);
	 DefineID(31, 238);
	 DefineID(32, 140);
	 DefineID(33, 5);
	 DefineID(34, 19);
	 DefineID(35, 319);
	 DefineID(36, 118);
	 DefineID(37, 310);
	 DefineID(38, 294);
	 DefineID(39, 393);
	 DefineID(40, 318);
	 DefineID(41, 281);
	 DefineID(42, 255);
	 DefineID(43, 269);
	 DefineID(44, 70);
	 DefineID(45, 91);
	 DefineID(46, 370);
	 DefineID(47, 291);
	 DefineID(48, 66);
	 DefineID(49, 81);
	 DefineID(50, 134);
	 DefineID(51, 201);
	 DefineID(52, 68);
	 DefineID(53, 421);
	 DefineID(54, 268);
	 DefineID(55, 97);
	 DefineID(56, 365);
	 DefineID(57, 363);
	 DefineID(58, 78);
	 DefineID(59, 151);
	 DefineID(60, 283);
	 DefineID(61, 98);
	 DefineID(62, 256);
	 DefineID(63, 258);
	 DefineID(64, 126);
	 DefineID(65, 263);
	 DefineID(66, 366);
	 DefineID(67, 368);
	 DefineID(68, 398);
	 DefineID(69, 367);
	 DefineID(70, 184);
	 DefineID(71, 166);
	 DefineID(72, 146);
	 DefineID(73, 153);
	 DefineID(74, 135);
	 DefineID(75, 244);
	 DefineID(76, 150);
	 DefineID(77, 181);
	 DefineID(78, 401);
	 DefineID(79, 403);
	 DefineID(80, 404);
	 DefineID(81, 422);
	 DefineID(82, 402);
	 DefineID(83, 406);
	 DefineID(84, 231);

#ifdef ENGLISH
	 DefineText(85, "Do you sing for yourself?", GROUP_ASPIE_COMM);
#endif

#ifdef SWEDISH
	 DefineText(85, "Sjunger du för dig själv?", GROUP_ASPIE_COMM);
#endif

	DefineID(86, 83);
   	DefineID(87, 226);
    DefineID(88, 262);
    DefineID(89, 86);
    DefineID(90, 224);
    DefineID(91, 285);
    DefineID(92, 54);
    DefineID(93, 215);
    DefineID(94, 286);
    DefineID(95, 18);
    DefineID(96, 43);
    DefineID(97, 360);
    DefineID(98, 361);
    DefineID(99, 37);
    DefineID(100, 25);
    DefineID(101, 38);
    DefineID(102, 39);
    DefineID(103, 36);

#ifdef ENGLISH
	 DefineText(104, "Do you have a need for symmetry, order and/or precision?", GROUP_REPETITION);
#endif

#ifdef SWEDISH
	 DefineText(104, "Har du ett behov av symmerti, ordning och/eller precision?", GROUP_REPETITION);
#endif

    DefineID(105, 137);
    DefineID(106, 381);
    DefineID(107, 136);

#ifdef ENGLISH
	 DefineText(108, "Do you have compulsive sexual behavior, e.g. spend too much time on sex or switch sexual partner frequently?", GROUP_SEX);
#endif

#ifdef SWEDISH
	 DefineText(108, "Har du tvångsmässigt sexuellt beteende, t.ex. använder för mycket tid för sex eller byter sex-partner ofta?", GROUP_SEX);
#endif

    DefineID(109, 303);
    DefineID(110, 130);
    DefineID(111, 227);
    DefineID(112, 3);
    DefineID(113, 4);
    DefineID(114, 251);
    DefineID(115, 77);
    DefineID(116, 139);

#ifdef ENGLISH
	 DefineText(117, "Do you have an urge to climb?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(117, "Har du ett behov av att klättra?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(118, "Do you have an urge to jump over objects?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(118, "Har du ett behov av att hoppa över saker?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(119, "Are you superstitious?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(119, "Är du vidskeplig?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(120, "Do you care if you are right in a discussion?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(120, "Bryr du dig om ifall du får rätt i en diskussion?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(121, "Have you had paranormal experiences?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(121, "Har du haft övernaturliga upplevelser?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(122, "Do you tend to shut down or have a meltdown when stressed or overwhelmed?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(122, "Stänger du av eller bryter ihop när du blir stressad eller överväldigad?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(123, "Do your hands shake?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(123, "Skakar dina händer?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(124, "Do you apologize constantly?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(124, "Ber du om ursäkt i ett kör?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	 DefineText(125, "Do you have a small mouth?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	 DefineText(125, "Har du en liten mun?", GROUP_MIXED);
#endif
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
  Quiz[41].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[46].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[59].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[62].Reverse = TRUE;
  Quiz[64].Reverse = TRUE;
  Quiz[66].Reverse = TRUE;
  Quiz[68].Reverse = TRUE;
  Quiz[69].Reverse = TRUE;
  Quiz[70].Reverse = TRUE;
  Quiz[71].Reverse = TRUE;
  Quiz[72].Reverse = TRUE;
  Quiz[73].Reverse = TRUE;
  Quiz[74].Reverse = TRUE;
  Quiz[75].Reverse = TRUE;
  Quiz[76].Reverse = TRUE;
  Quiz[87].Reverse = TRUE;
  Quiz[89].Reverse = TRUE;
  Quiz[90].Reverse = TRUE;
  Quiz[92].Reverse = TRUE;
  Quiz[93].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[1].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[2].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[3].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[4].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[5].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[6].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[7].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[8].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[9].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[10].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[11].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[12].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[13].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[14].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[15].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[16].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[17].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[18].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[19].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[20].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[21].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[22].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[23].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[24].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[25].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[26].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[27].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[28].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[29].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[30].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[31].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[32].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[33].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[34].MyGroup = GROUP_NT_TALENT;
  Quiz[35].MyGroup = GROUP_NT_TALENT;
  Quiz[36].MyGroup = GROUP_NT_TALENT;
  Quiz[37].MyGroup = GROUP_NT_TALENT;
  Quiz[38].MyGroup = GROUP_NT_TALENT;
  Quiz[39].MyGroup = GROUP_NT_TALENT;
  Quiz[40].MyGroup = GROUP_ASPIE_SOCIAL;
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
  Quiz[68].MyGroup = GROUP_NT_SOCIAL;
  Quiz[69].MyGroup = GROUP_NT_SOCIAL;
  Quiz[70].MyGroup = GROUP_NT_SOCIAL;
  Quiz[71].MyGroup = GROUP_NT_SOCIAL;
  Quiz[72].MyGroup = GROUP_NT_SOCIAL;
  Quiz[73].MyGroup = GROUP_NT_SOCIAL;
  Quiz[74].MyGroup = GROUP_NT_SOCIAL;
  Quiz[75].MyGroup = GROUP_NT_SOCIAL;
  Quiz[76].MyGroup = GROUP_NT_SOCIAL;
  Quiz[77].MyGroup = GROUP_ASPIE_COMM;
  Quiz[78].MyGroup = GROUP_ASPIE_COMM;
  Quiz[79].MyGroup = GROUP_ASPIE_COMM;
  Quiz[80].MyGroup = GROUP_ASPIE_COMM;
  Quiz[81].MyGroup = GROUP_ASPIE_COMM;
  Quiz[82].MyGroup = GROUP_ASPIE_COMM;
  Quiz[83].MyGroup = GROUP_ASPIE_COMM;
  Quiz[84].MyGroup = GROUP_ASPIE_COMM;
  Quiz[85].MyGroup = GROUP_NONVERBAL;
  Quiz[86].MyGroup = GROUP_NONVERBAL;
  Quiz[87].MyGroup = GROUP_NONVERBAL;
  Quiz[88].MyGroup = GROUP_NONVERBAL;
  Quiz[89].MyGroup = GROUP_NONVERBAL;
  Quiz[90].MyGroup = GROUP_NONVERBAL;
  Quiz[91].MyGroup = GROUP_NONVERBAL;
  Quiz[92].MyGroup = GROUP_NONVERBAL;
  Quiz[93].MyGroup = GROUP_NONVERBAL;
  Quiz[94].MyGroup = GROUP_NONVERBAL;
  Quiz[95].MyGroup = GROUP_NONVERBAL;
  Quiz[96].MyGroup = GROUP_REPETITION;
  Quiz[97].MyGroup = GROUP_REPETITION;
  Quiz[98].MyGroup = GROUP_REPETITION;
  Quiz[99].MyGroup = GROUP_REPETITION;
  Quiz[100].MyGroup = GROUP_REPETITION;
  Quiz[101].MyGroup = GROUP_REPETITION;
  Quiz[102].MyGroup = GROUP_REPETITION;
  Quiz[103].MyGroup = GROUP_REPETITION;
  Quiz[104].MyGroup = GROUP_SEX;
  Quiz[105].MyGroup = GROUP_SEX;
  Quiz[106].MyGroup = GROUP_SEX;
  Quiz[107].MyGroup = GROUP_SEX;
  Quiz[108].MyGroup = GROUP_MIXED;
  Quiz[109].MyGroup = GROUP_MIXED;
  Quiz[110].MyGroup = GROUP_MIXED;
  Quiz[111].MyGroup = GROUP_MIXED;
  Quiz[112].MyGroup = GROUP_MIXED;
  Quiz[113].MyGroup = GROUP_MIXED;
  Quiz[114].MyGroup = GROUP_MIXED;
  Quiz[115].MyGroup = GROUP_MIXED;
  Quiz[116].MyGroup = GROUP_MIXED;
  Quiz[117].MyGroup = GROUP_MIXED;
  Quiz[118].MyGroup = GROUP_MIXED;
  Quiz[119].MyGroup = GROUP_MIXED;
  Quiz[120].MyGroup = GROUP_MIXED;
  Quiz[121].MyGroup = GROUP_MIXED;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_MIXED;
  Quiz[124].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
  Quiz[1].Text = "Do you have a very acute sense of taste?";
  Quiz[2].Text = "Do you feel strongly attracted to, or appalled by, certain tastes, smells, sounds, colours, shapes, textures or materials?";
  Quiz[3].Text = "Do you squint now or have done in the past?";
  Quiz[4].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[5].Text = "Do you blink or roll your eyes?";
  Quiz[6].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[7].Text = "Do you feel tortured by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' material?";
  Quiz[8].Text = "Are you sensitive to heat, cold, wind and/or changes in air-pressure, humidity etc?";
  Quiz[9].Text = "Do you stammer when stressed?";
  Quiz[10].Text = "Do you see yourself as sensitive?";
  Quiz[11].Text = "Do you have a very acute sense of smell?";
  Quiz[12].Text = "Do you sniff involuntary?";
  Quiz[13].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
  Quiz[14].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[15].Text = "Are you good at climbing?";
  Quiz[16].Text = "Are you good at jumping high?";
  Quiz[17].Text = "Do you have a firm handshake?";
  Quiz[18].Text = "Do you have a good sense for how much pressure your hands should apply?";
  Quiz[19].Text = "Do you have above average physical endurance?";
  Quiz[20].Text = "Do you drop things when your attention is on other things?";
  Quiz[21].Text = "Do you have difficulty with throwing and catching a ball?";
  Quiz[22].Text = "Are you the last one to finish manual tasks?";
  Quiz[23].Text = "Do you have a tendency to drop things?";
  Quiz[24].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[25].Text = "Are you often injured in the kitchen?";
  Quiz[26].Text = "Do you have difficulty hopping, skipping or riding a bike?";
  Quiz[27].Text = "Do you have difficulty writing by hand?";
  Quiz[28].Text = "Do you have unconventional, often unique ways of solving problems?";
  Quiz[29].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[30].Text = "Do you have one special talent which you have emphasised and worked on?";
  Quiz[31].Text = "Is you imagination unusual, with unique ideas that others don't have?";
  Quiz[32].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[33].Text = "Are you very gifted in one or more areas?";
  Quiz[34].Text = "Do you find it difficult to taking notes in lectures?";
  Quiz[35].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
  Quiz[36].Text = "Do you have trouble reading clocks?";
  Quiz[37].Text = "Do you often forget were you put things?";
  Quiz[38].Text = "Do you have trouble with math?";
  Quiz[39].Text = "Do you often make spelling errors?";
  Quiz[40].Text = "Do you find preferable/easier to understand & communicate with computers, animals or unusual people?";
  Quiz[41].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[42].Text = "Have you felt different from others for most of your life?";
  Quiz[43].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[44].Text = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";
  Quiz[45].Text = "Are you the life of a party?";
  Quiz[46].Text = "Are you good at party games?";
  Quiz[47].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
  Quiz[48].Text = "Do you tend to feel get nervous, shy, confused and/or like you don't fit in, in various social situations?";
  Quiz[49].Text = "Do you find the usual courting behavior natural?";
  Quiz[50].Text = "Do you dislike touch?";
  Quiz[51].Text = "Are you fairly self-absorbed, more interested in yourself than in others and/or an objective observer of yourself?";
  Quiz[52].Text = "Do you dislike it when people turn up at your home uninvited?";
  Quiz[53].Text = "Does an unplanned hug make you jump out of your skin?";
  Quiz[54].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
  Quiz[55].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[56].Text = "Do you prefer animals to people?";
  Quiz[57].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[58].Text = "Is your sense of humor different from mainstream and / or considered odd?";
  Quiz[59].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[60].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[61].Text = "Are you energised by being in the company of others?";
  Quiz[62].Text = "Are you comfortable in social situations and with new people?";
  Quiz[63].Text = "Have you had the feeling of playing a game to pretend to be like people around you?";
  Quiz[64].Text = "Do you see yourself as putting people first, before ideals and objects?";
  Quiz[65].Text = "Do you feel uncomfortable with strangers?";
  Quiz[66].Text = "Do you find it easy to maintain your social network?";
  Quiz[67].Text = "Do you dislike eye-contact?";
  Quiz[68].Text = "Is a large social network important for you?";
  Quiz[69].Text = "Is creating a social identity important for you?";
  Quiz[70].Text = "Do you appreciate to be in charge of other people?";
  Quiz[71].Text = "Do you have an interest for fashions?";
  Quiz[72].Text = "Do you enjoy gossip?";
  Quiz[73].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
  Quiz[74].Text = "Do you find a little danger in your life energising?";
  Quiz[75].Text = "Is your style and image very important to you?";
  Quiz[76].Text = "Is other people's image of you important to you?";
  Quiz[77].Text = "Do you talk to yourself?";
  Quiz[78].Text = "Do you sing for yourself?";
  Quiz[79].Text = "Do you bounce your leg?";
  Quiz[80].Text = "Do you click or rub a pen for the fun of it?";
  Quiz[81].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[82].Text = "Do you rock your body?";
  Quiz[83].Text = "Do you thrust your tounge at the wrong occassion?";
  Quiz[84].Text = "Do you sing for yourself?";
  Quiz[85].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[86].Text = "Are you often surprised what people's motives are ?";
  Quiz[87].Text = "Do you have an intuitive sense of when to do the right thing socially?";
  Quiz[88].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[89].Text = "Do you read people well?";
  Quiz[90].Text = "Can you read between the lines?";
  Quiz[91].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
  Quiz[92].Text = "Is it easy for you to interpret body language?";
  Quiz[93].Text = "Can you spot hidden agendas with ease?";
  Quiz[94].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[95].Text = "Do you have an odd posture, gait and/or difficulties sitting/standing erect?";
  Quiz[96].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed?";
  Quiz[97].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[98].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[99].Text = "Does it feel vitally important to be left undisturbed to persue your special interests?";
  Quiz[100].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[101].Text = "Do you have very strong attachments to certain objects, e.g. a favourite cup or a favourite towel and really need to have that precise one?";
  Quiz[102].Text = "Do you have certain simple & logical routines which you need to follow?";
  Quiz[103].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[104].Text = "Do you feel like you were born with the wrong gender?";
  Quiz[105].Text = "Do you have unusual sexual preferences?";
  Quiz[106].Text = "Are you homosexual or bisexual?";
  Quiz[107].Text = "Do you have compulsive sexual behavior, e.g. spend too much time on sex or switch sexual partner frequently?";
  Quiz[108].Text = "Are you easily distracted or overwhelmed?";
  Quiz[109].Text = "Do others often misunderstand you?";
  Quiz[110].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[111].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[112].Text = "Do you need to see, touch or do things yourself in order to remember them?";
  Quiz[113].Text = "Do you see the value in owning one of a kind?";
  Quiz[114].Text = "Do you more easily get very upset over 'minor' things (e.g. losing your favourite pen) than over which others get upset about (e.g. a relative passing away)?";
  Quiz[115].Text = "Are you asexual?";
  Quiz[116].Text = "Do you have an urge to climb?";
  Quiz[117].Text = "Do you have an urge to jump over objects?";
  Quiz[118].Text = "Are you superstitious?";
  Quiz[119].Text = "Do you care if you are right in a discussion?";
  Quiz[120].Text = "Have you had paranormal experiences?";
  Quiz[121].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[122].Text = "Do your hands shake?";
  Quiz[123].Text = "Do you apologize constantly?";
  Quiz[124].Text = "Do you have a small mouth?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
  Quiz[1].Text = "Har du extra känsligt smaksinne?";
  Quiz[2].Text = "Brukar du känna stark lust eller häftigt obehag av vissa färger, former, dofter, smaker, material eller konsistenser?";
  Quiz[3].Text = "Skelar du eller har gjort det?";
  Quiz[4].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
  Quiz[5].Text = "Blinkar eller rullar du med ögona?";
  Quiz[6].Text = "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
  Quiz[7].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda i \"fel\" material?";
  Quiz[8].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
  Quiz[9].Text = "Stammar du när du blir stressad?";
  Quiz[10].Text = "Anser du att du är känslig?";
  Quiz[11].Text = "Har du extra känsligt luktsinne?";
  Quiz[12].Text = "Sniffar du ofrivilligt?";
  Quiz[13].Text = "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
  Quiz[14].Text = "Är du känslig för lyrsrörsljus?";
  Quiz[15].Text = "Är du bra på att sjunga?";
  Quiz[16].Text = "Är du bra på att hoppa högt?";
  Quiz[17].Text = "Har du ett starkt handslag?";
  Quiz[18].Text = "Har du en bra känsla för hur mycket du ska ta i med händerna?";
  Quiz[19].Text = "Är du mer fysiskt uthållig än normalt?";
  Quiz[20].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[21].Text = "Har du svårt för att kasta eller fånga en boll?";
  Quiz[22].Text = "Är du sist med att avsluta manuella uppgifter?";
  Quiz[23].Text = "Har du en tendens att tappa saker?";
  Quiz[24].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
  Quiz[25].Text = "Skadar du dig ofta i köket?";
  Quiz[26].Text = "Har du svårt för att hoppa eller cykla?";
  Quiz[27].Text = "Har du svårt att skriva för hand?";
  Quiz[28].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
  Quiz[29].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[30].Text = "Har du en speciell talang som du har jobbat med?";
  Quiz[31].Text = "Är din fantasi ovanlig med unika idéer som andra inte har?";
  Quiz[32].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[33].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[34].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[35].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
  Quiz[36].Text = "Har du svårigheter att läsa av klockor?";
  Quiz[37].Text = "Glömmer du ofta var du lagt saker?";
  Quiz[38].Text = "Har du problem med matematik?";
  Quiz[39].Text = "Gör du ofta stavfel?";
  Quiz[40].Text = "Tycker du det är att föredra/lättare att förstå och kommunicera med datorer, djur eller udda människor?";
  Quiz[41].Text = "Trivs du med romantiska situationer?";
  Quiz[42].Text = "Har du känt dig annorlunda största delen av ditt liv?";
  Quiz[43].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[44].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
  Quiz[45].Text = "Är du aktiv på fester?";
  Quiz[46].Text = "Är du bra på sällskapsspel?";
  Quiz[47].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
  Quiz[48].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
  Quiz[49].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
  Quiz[50].Text = "Ogillar du beröring?";
  Quiz[51].Text = "Är du rätt självupptagen, mer intresserad av dig själv än av andra och/eller en objektiv självobservatör?";
  Quiz[52].Text = "Ogillar du att folk dyker upp vid ditt hem utan att du bjudit in dem?";
  Quiz[53].Text = "Gör en oplanerad kram att du vill hoppa ur ditt skinn?";
  Quiz[54].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara aktuellt/modernt/inne?";
  Quiz[55].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[56].Text = "Umgås du hellre med djur än med människor?";
  Quiz[57].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[58].Text = "Är ditt sinne för humor annorlunda än andras och / eller ansett som udda?";
  Quiz[59].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[60].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[61].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[62].Text = "Känner du dig hemma i sociala situationer med nya människor?";
  Quiz[63].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[64].Text = "Sätter du människor före saker och idéer?";
  Quiz[65].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[66].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
  Quiz[67].Text = "Ogillar du ögonkontakt?";
  Quiz[68].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[69].Text = "Är det viktigt för dig att skapa en social identitet?";
  Quiz[70].Text = "Uppskattar du att leda andra människor?";
  Quiz[71].Text = "Är du intressad av mode?";
  Quiz[72].Text = "Tycker du om skvaller?";
  Quiz[73].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
  Quiz[74].Text = "Tycker du det är utmanande med faror?";
  Quiz[75].Text = "Är din stil och image mycket viktig för dig?";
  Quiz[76].Text = "Är andra människors syn på dig viktigt för dig?";
  Quiz[77].Text = "Pratar du med dig själv?";
  Quiz[78].Text = "Sjunger du för dig själv?";
  Quiz[79].Text = "Brukar du vippa med benet?";
  Quiz[80].Text = "Klickar eller gnider du på en penna för skojs skull?";
  Quiz[81].Text = "Använder du små ljud som andra inte verkar använda i samtal?";
  Quiz[82].Text = "Brukar du gunga med kroppen?";
  Quiz[83].Text = "Räcker du ut tungan vid fel tillfällen?";
  Quiz[84].Text = "Sjunger du för dig själv?";
  Quiz[85].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[86].Text = "Blir du ofta överraskad av vad folks motiv är?";
  Quiz[87].Text = "Känner du intuitivt av vad som är rätt socialt?";
  Quiz[88].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[89].Text = "Läser du av folk bra?";
  Quiz[90].Text = "Kan du läsa mellan raderna?";
  Quiz[91].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
  Quiz[92].Text = "Har du lätt för att tolka kroppsspråk?";
  Quiz[93].Text = "Kan du lätt avslöja dolda motiv?";
  Quiz[94].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[95].Text = "Har du ovanlig kroppshållning, gångstil och/eller svårt att sitta/stå upprätt?";
  Quiz[96].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
  Quiz[97].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[98].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[99].Text = "Känns det livsviktigt att få vara ifred och ägna dig åt dina specialintressen i lugn och ro?";
  Quiz[100].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[101].Text = "Är du exceptionellt fäst vid vissa saker, t ex en favoritkopp, en favorittröja, en favorithandduk, och verkligen MÅSTE ha just den?";
  Quiz[102].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
  Quiz[103].Text = "Har du ett behov av symmerti, ordning och/eller precision?";
  Quiz[104].Text = "Känns det som du föddes med fel kön?";
  Quiz[105].Text = "Har du ovanliga sexuella preferenser?";
  Quiz[106].Text = "Är du homosexuell eller bisexuell?";
  Quiz[107].Text = "Har du tvångsmässigt sexuellt beteende, t.ex. använder för mycket tid för sex eller byter sex-partner ofta?";
  Quiz[108].Text = "Är du lätt att distrahera eller överväldiga?";
  Quiz[109].Text = "Blir du ofta missförstådd av andra?";
  Quiz[110].Text = "Tar du ibland initiativ som inte visar sig önskade?";
  Quiz[111].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[112].Text = "Har du behov av att SE, ta i, eller själv bearbeta saker för att riktigt minnas dem?";
  Quiz[113].Text = "Tycker du det finns ett värde i att äga en sak av varje sort?";
  Quiz[114].Text = "Brukar du bli mer upprörd över smärre saker (t ex att du tappat din favoritpenna eller någon satt sig på din favoritplats) än över sånt som andra blir upprörda av (t ex en släktings bortgång)?";
  Quiz[115].Text = "Är du asexuell?";
  Quiz[116].Text = "Har du ett behov av att klättra?";
  Quiz[117].Text = "Har du ett behov av att hoppa över saker?";
  Quiz[118].Text = "Är du vidskeplig?";
  Quiz[119].Text = "Bryr du dig om ifall du får rätt i en diskussion?";
  Quiz[120].Text = "Har du haft övernaturliga upplevelser?";
  Quiz[121].Text = "Stänger du av eller bryter ihop när du blir stressad eller överväldigad?";
  Quiz[122].Text = "Skakar dina händer?";
  Quiz[123].Text = "Ber du om ursäkt i ett kör?";
  Quiz[124].Text = "Har du en liten mun?";
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
	AddReferer("wikipedia.org/wiki/As", "en.wikipedia.org/wiki/Aspergers");
	AddReferer("whoa.nu", "whoa.nu");
	AddReferer("airliners.net", "airliners.net/discussions/non_aviation/read.main/1295619");
	AddReferer("supermama.lt", "supermama.lt/forumas/index.php?showtopic=99238");
    AddReferer("dickflash.com", "dickflash.com");
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
		else
		{
			ref = FindReferer(Row.Referer);

			if (ref)
			{
				if (ref->NT && Row.Autism == 0 && Row.Aspie == 0)
				{
					Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
					if (Row.Gender == 1)
						NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
					else
						NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
				}

//                if (!aspie)
					aspie = ref->Aspie;
			}
		}


		if (aspie)
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
    DefineCross(Quiz5, 2, 1);
    DefineCross(Quiz7, 3, 1);
    DefineCross(Quiz7, 4, 2);
    DefineCross(Quiz6, 5, 5);
    DefineCross(Quiz7, 6, 6);
    DefineCross(Quiz7, 7, 7);
    DefineCross(Quiz7, 8, 3);
    DefineCross(Quiz6, 9, 7);
    DefineCross(Quiz5, 10, 10);
    DefineCross(Quiz7, 11, 4);
    DefineCross(Quiz6, 12, 11);
    DefineCross(Quiz7, 13, 9);
    DefineCross(Quiz7, 14, 8);
    DefineGlobalId( 15, 428);
    DefineGlobalId( 16, 429);
    DefineGlobalId( 17, 430);
    DefineGlobalId( 18, 431);
    DefineGlobalId( 19, 432);
    DefineGlobalId( 20, 433);
    DefineCross(Quiz6, 21, 12);
    DefineCross(Quiz7, 22, 14);
    DefineCross(Quiz7, 23, 13);
    DefineCross(Quiz7, 24, 15);
    DefineCross(Quiz7, 25, 16);
    DefineCross(Quiz7, 26, 17);
    DefineCross(Quiz7, 27, 140);
    DefineCross(Quiz7, 28, 18);
    DefineCross(Quiz7, 29, 19);
    DefineCross(Quiz7, 30, 22);
    DefineCross(Quiz7, 31, 20);
    DefineCross(Quiz7, 32, 21);
    DefineCross(Quiz7, 33, 23);
    DefineCross(Quiz7, 34, 28);
    DefineCross(Quiz7, 35, 27);
    DefineCross(Quiz7, 36, 29);
    DefineCross(Quiz7, 37, 31);
    DefineCross(Quiz7, 38, 30);
    DefineCross(Quiz7, 39, 32);
    DefineCross(Quiz5, 40, 60);
    DefineCross(Quiz7, 41, 38);
    DefineCross(Quiz7, 42, 42);
    DefineCross(QuizIII, 43, 44);
    DefineCross(Quiz7, 44, 39);
    DefineCross(Quiz6, 45, 110);
    DefineCross(Quiz7, 46, 41);
    DefineCross(Quiz7, 47, 44);
    DefineCross(Quiz7, 48, 46);
    DefineCross(Quiz7, 49, 43);
    DefineCross(Quiz5, 50, 99);
    DefineCross(QuizIII, 51, 52);
    DefineCross(Quiz7, 52, 147);
    DefineCross(Quiz7, 53, 45);
    DefineCross(QuizI, 54, 96);
    DefineCross(Quiz7, 55, 54);
    DefineCross(Quiz7, 56, 56);
    DefineCross(Quiz7, 57, 50);
    DefineCross(QuizII, 58, 78);
    DefineCross(Quiz7, 59, 48);
    DefineCross(Quiz7, 60, 49);
    DefineCross(Quiz7, 61, 47);
	DefineCross(QuizNd, 62, 95);
	DefineCross(QuizII, 63, 45);
	DefineCross(QuizNd, 64, 105);
    DefineCross(Quiz7, 65, 57);
    DefineCross(Quiz7, 66, 55);
    DefineCross(Quiz7, 67, 107);
    DefineCross(Quiz7, 68, 58);
    DefineCross(Quiz7, 69, 59);
    DefineCross(QuizII, 70, 93);
    DefineCross(Quiz7, 71, 61);
    DefineCross(Quiz7, 72, 63);
	DefineCross(Quiz6, 73, 140);
	DefineCross(QuizNd, 74, 75);
	DefineCross(Quiz7, 75, 62);
	DefineCross(Quiz7, 76, 65);
	DefineCross(Quiz7, 77, 112);
	DefineGlobalId( 78, 434);
	DefineCross(Quiz7, 79, 127);
	DefineCross(Quiz7, 80, 148);
	DefineCross(Quiz7, 81, 113);
	DefineCross(Quiz7, 82, 129);
	DefineCross(Quiz7, 83, 110);
	DefineGlobalId( 84, 435);
	DefineCross(Quiz7, 85, 69);
	DefineCross(Quiz7, 86, 74);
	DefineCross(Quiz7, 87, 72);
    DefineCross(Quiz7, 88, 70);
    DefineCross(Quiz7, 89, 77);
    DefineCross(Quiz7, 90, 71);
    DefineCross(Quiz7, 91, 76);
    DefineCross(Quiz7, 92, 80);
    DefineCross(Quiz7, 93, 79);
    DefineCross(Quiz7, 94, 81);
    DefineCross(QuizII, 95, 26);
    DefineCross(Quiz7, 96, 88);
	DefineCross(Quiz7, 97, 87);
	DefineCross(Quiz7, 98, 85);
	DefineCross(Quiz7, 99, 118);
	DefineCross(Quiz7, 100, 86);
	DefineCross(Quiz7, 101, 92);
	DefineCross(Quiz7, 102, 89);
	DefineGlobalId( 103, 436);
	DefineCross(Quiz7, 104, 94);
	DefineCross(Quiz7, 105, 95);
	DefineCross(Quiz7, 106, 96);
	DefineGlobalId( 107, 437);
	DefineCross(Quiz7, 108, 104);
	DefineCross(Quiz7, 109, 73);
	DefineCross(Quiz7, 110, 115);
	DefineCross(Quiz7, 111, 103);
    DefineCross(Quiz6, 112, 127);
    DefineCross(Quiz5, 113, 53);
    DefineCross(QuizII, 114, 35);
    DefineCross(QuizII, 115, 59);
    DefineGlobalId( 116, 438);
    DefineGlobalId( 117, 439);
    DefineGlobalId( 118, 440);
    DefineGlobalId( 119, 441);
    DefineGlobalId( 120, 442);
    DefineGlobalId( 121, 443);
    DefineGlobalId( 122, 444);
    DefineGlobalId( 123, 445);
    DefineGlobalId( 124, 446);
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

		strncpy(str, Group[i].Name, 35);
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

    for (i = 0; i < 7; i++)
    {
        AsCount[i] = 0;
        NtCount[i] = 0;
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

	if (diff > 0)
		AsCount[index]++;
	else
		NtCount[index]++;
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
void THair::WriteRow(TFile &file, int index, const char *text)
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
		sum += AsCount[i];

	if (sum)
		WriteEntry(file, AsCount[index], sum);
	else
		file.Write("---");

	sum = 0;
	for (i = 0; i < 7; i++)
		sum += NtCount[i];

	if (sum)
		WriteEntry(file, NtCount[index], sum);
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
void TQuiz8::WriteHair(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	THair hair[7];

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Hair != 7)
			hair[0].Add(&Row);
	}

	for (i = 0; i < 1; i++)
	{
		file.Write("<h3>");

		switch (i)
		{
			case 0:
				file.Write("Hair-color excluding black");
				break;

		}

		file.Write("</h3><br>");

		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		THair::WriteHeader(file);

		hair[i].WriteRow(file, 0, "Red/Strawberry blond/auburn");
		hair[i].WriteRow(file, 1, "Blond");
		hair[i].WriteRow(file, 2, "Brown");

		file.Write("</table>");

		file.Write("<br><br>");

	}

}
