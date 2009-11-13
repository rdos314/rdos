/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2009, Leif Ekblad
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
# quizg2.cpp
# Quiz final version 2, release 2 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizg2.h"
#include "file.h"
#include "quizdbg2.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

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
#   Name       : TQuizG2::TQuizG2
#
#   Purpose....: Constructor for TQuizG2
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizG2::TQuizG2(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5, TQuiz *QuizF6, TQuiz *QuizF7, TQuiz *QuizF8, TQuiz *QuizF9, TQuiz *QuizF10, TQuiz *QuizF11, TQuiz *QuizF12, TQuiz *QuizF13, TQuiz *QuizF14, TQuiz *QuizF15, TQuiz *QuizGe, TQuiz *QuizGe2, TQuiz *QuizGe3, TQuiz *QuizG1)
  : TQuizFinal2(162, QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1, QuizN2, QuizN3, QuizN4, QuizFI, QuizF1, QuizF2, QuizF3, QuizF4, QuizF5, QuizF6, QuizF7, QuizF8, QuizF9, QuizF10, QuizF11, QuizF12, QuizF13, QuizF14, QuizF15, QuizGe, QuizGe2, QuizGe3),
	FDataFile(FileName)
{
	DefineCross(51, QuizG1);

	SetupTexts();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1, QuizN2, QuizN3, QuizN4, QuizFI, QuizF1, QuizF2, QuizF3, QuizF4, QuizF5, QuizF6, QuizF7, QuizF8, QuizF9, QuizF10, QuizF11, QuizF12, QuizF13, QuizF14, QuizF15, QuizGe, QuizGe2, QuizGe3, QuizG1);

	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizG2::~TQuizG2
#
#   Purpose....: Destructor for TQuizG2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizG2::~TQuizG2()
{
}

/*##################  TQuizG2::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizG2::GetCatCount(int Question)
{
    if (Question < 150)
    	return 3;
    else
		return 2;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizG2::GetQuizN()
{
	return 150;
}

/*##########################################################################
#
#   Name       : TQuizG2::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizG2::WriteName(TFile &File)
{
	 File.Write("G2");
}

/*##########################################################################
#
#   Name       : TQuizG2::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizG2::WriteLongName(TFile &File)
{
	 File.Write("final version 2:2");
}

/*##########################################################################
#
#   Name       : TQuizG2::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizG2::SetupTexts()
{
  Quiz[150].MyGroup = GROUP_MIXED;
  Quiz[151].MyGroup = GROUP_MIXED;
  Quiz[152].MyGroup = GROUP_MIXED;
  Quiz[153].MyGroup = GROUP_MIXED;
  Quiz[154].MyGroup = GROUP_MIXED;
  Quiz[155].MyGroup = GROUP_MIXED;
  Quiz[156].MyGroup = GROUP_MIXED;
  Quiz[157].MyGroup = GROUP_MIXED;
  Quiz[158].MyGroup = GROUP_MIXED;
  Quiz[159].MyGroup = GROUP_MIXED;
  Quiz[160].MyGroup = GROUP_MIXED;
  Quiz[161].MyGroup = GROUP_MIXED;
  Quiz[162].MyGroup = GROUP_MIXED;
  Quiz[163].MyGroup = GROUP_MIXED;
  Quiz[164].MyGroup = GROUP_MIXED;
  Quiz[165].MyGroup = GROUP_MIXED;
  Quiz[166].MyGroup = GROUP_MIXED;
  Quiz[167].MyGroup = GROUP_MIXED;
  Quiz[168].MyGroup = GROUP_MIXED;
  Quiz[169].MyGroup = GROUP_MIXED;
  Quiz[170].MyGroup = GROUP_MIXED;
  Quiz[171].MyGroup = GROUP_MIXED;
  Quiz[172].MyGroup = GROUP_MIXED;
  Quiz[173].MyGroup = GROUP_MIXED;
  Quiz[174].MyGroup = GROUP_MIXED;
  Quiz[175].MyGroup = GROUP_MIXED;
  Quiz[176].MyGroup = GROUP_MIXED;
  Quiz[177].MyGroup = GROUP_MIXED;
  Quiz[178].MyGroup = GROUP_MIXED;
  Quiz[179].MyGroup = GROUP_MIXED;
  Quiz[180].MyGroup = GROUP_MIXED;
  Quiz[181].MyGroup = GROUP_MIXED;
  Quiz[182].MyGroup = GROUP_MIXED;
  Quiz[183].MyGroup = GROUP_MIXED;
  Quiz[184].MyGroup = GROUP_MIXED;
  Quiz[185].MyGroup = GROUP_MIXED;
  Quiz[186].MyGroup = GROUP_MIXED;
  Quiz[187].MyGroup = GROUP_MIXED;
  Quiz[188].MyGroup = GROUP_MIXED;
  Quiz[189].MyGroup = GROUP_MIXED;
  Quiz[190].MyGroup = GROUP_MIXED;
  Quiz[191].MyGroup = GROUP_MIXED;
  Quiz[192].MyGroup = GROUP_MIXED;
  Quiz[193].MyGroup = GROUP_MIXED;
  Quiz[194].MyGroup = GROUP_MIXED;
  Quiz[195].MyGroup = GROUP_MIXED;
  Quiz[196].MyGroup = GROUP_MIXED;
  Quiz[197].MyGroup = GROUP_MIXED;
  Quiz[198].MyGroup = GROUP_MIXED;
  Quiz[199].MyGroup = GROUP_MIXED;
  Quiz[200].MyGroup = GROUP_MIXED;
  Quiz[201].MyGroup = GROUP_MIXED;
  Quiz[202].MyGroup = GROUP_MIXED;
  Quiz[203].MyGroup = GROUP_MIXED;
  Quiz[204].MyGroup = GROUP_MIXED;
  Quiz[205].MyGroup = GROUP_MIXED;
  Quiz[206].MyGroup = GROUP_MIXED;
  Quiz[207].MyGroup = GROUP_MIXED;
  Quiz[208].MyGroup = GROUP_MIXED;
  Quiz[209].MyGroup = GROUP_MIXED;
  Quiz[210].MyGroup = GROUP_MIXED;
  Quiz[211].MyGroup = GROUP_MIXED;
  Quiz[212].MyGroup = GROUP_MIXED;
  Quiz[213].MyGroup = GROUP_MIXED;
  Quiz[214].MyGroup = GROUP_MIXED;
  Quiz[215].MyGroup = GROUP_MIXED;
  Quiz[216].MyGroup = GROUP_MIXED;
  Quiz[217].MyGroup = GROUP_MIXED;
  Quiz[218].MyGroup = GROUP_MIXED;
  Quiz[219].MyGroup = GROUP_MIXED;
  Quiz[220].MyGroup = GROUP_MIXED;
  Quiz[221].MyGroup = GROUP_MIXED;
  Quiz[222].MyGroup = GROUP_MIXED;
  Quiz[223].MyGroup = GROUP_MIXED;
  Quiz[224].MyGroup = GROUP_MIXED;
  Quiz[225].MyGroup = GROUP_MIXED;
  Quiz[226].MyGroup = GROUP_MIXED;
  Quiz[227].MyGroup = GROUP_MIXED;
  Quiz[228].MyGroup = GROUP_MIXED;
  Quiz[229].MyGroup = GROUP_MIXED;
  Quiz[230].MyGroup = GROUP_MIXED;
  Quiz[231].MyGroup = GROUP_MIXED;
  Quiz[232].MyGroup = GROUP_MIXED;
  Quiz[233].MyGroup = GROUP_MIXED;
  Quiz[234].MyGroup = GROUP_MIXED;
  Quiz[235].MyGroup = GROUP_MIXED;
  Quiz[236].MyGroup = GROUP_MIXED;
  Quiz[237].MyGroup = GROUP_MIXED;
  Quiz[238].MyGroup = GROUP_MIXED;
  Quiz[239].MyGroup = GROUP_MIXED;
  Quiz[240].MyGroup = GROUP_MIXED;
  Quiz[241].MyGroup = GROUP_MIXED;
  Quiz[242].MyGroup = GROUP_MIXED;
  Quiz[243].MyGroup = GROUP_MIXED;
  Quiz[244].MyGroup = GROUP_MIXED;
  Quiz[245].MyGroup = GROUP_MIXED;
  Quiz[246].MyGroup = GROUP_MIXED;
  Quiz[247].MyGroup = GROUP_MIXED;
  Quiz[248].MyGroup = GROUP_MIXED;
  Quiz[249].MyGroup = GROUP_MIXED;
  Quiz[250].MyGroup = GROUP_MIXED;
  Quiz[251].MyGroup = GROUP_MIXED;
  Quiz[252].MyGroup = GROUP_MIXED;
  Quiz[253].MyGroup = GROUP_MIXED;
  Quiz[254].MyGroup = GROUP_MIXED;
  Quiz[255].MyGroup = GROUP_MIXED;
  Quiz[256].MyGroup = GROUP_MIXED;
  Quiz[257].MyGroup = GROUP_MIXED;
  Quiz[258].MyGroup = GROUP_MIXED;
  Quiz[259].MyGroup = GROUP_MIXED;
  Quiz[260].MyGroup = GROUP_MIXED;
  Quiz[261].MyGroup = GROUP_MIXED;
  Quiz[262].MyGroup = GROUP_MIXED;
  Quiz[263].MyGroup = GROUP_MIXED;
  Quiz[264].MyGroup = GROUP_MIXED;
  Quiz[265].MyGroup = GROUP_MIXED;
  Quiz[266].MyGroup = GROUP_MIXED;
  Quiz[267].MyGroup = GROUP_MIXED;
  Quiz[268].MyGroup = GROUP_MIXED;
  Quiz[269].MyGroup = GROUP_MIXED;
  Quiz[270].MyGroup = GROUP_MIXED;
  Quiz[271].MyGroup = GROUP_MIXED;
  Quiz[272].MyGroup = GROUP_MIXED;
  Quiz[273].MyGroup = GROUP_MIXED;
  Quiz[274].MyGroup = GROUP_MIXED;
  Quiz[275].MyGroup = GROUP_MIXED;
  Quiz[276].MyGroup = GROUP_MIXED;
  Quiz[277].MyGroup = GROUP_MIXED;
  Quiz[278].MyGroup = GROUP_MIXED;
  Quiz[279].MyGroup = GROUP_MIXED;
  Quiz[280].MyGroup = GROUP_MIXED;
  Quiz[281].MyGroup = GROUP_MIXED;
  Quiz[282].MyGroup = GROUP_MIXED;
  Quiz[283].MyGroup = GROUP_MIXED;
  Quiz[284].MyGroup = GROUP_MIXED;
  Quiz[285].MyGroup = GROUP_MIXED;
  Quiz[286].MyGroup = GROUP_MIXED;
  Quiz[287].MyGroup = GROUP_MIXED;
  Quiz[288].MyGroup = GROUP_MIXED;
  Quiz[289].MyGroup = GROUP_MIXED;
  Quiz[290].MyGroup = GROUP_MIXED;
  Quiz[291].MyGroup = GROUP_MIXED;
  Quiz[292].MyGroup = GROUP_MIXED;
  Quiz[293].MyGroup = GROUP_MIXED;
  Quiz[294].MyGroup = GROUP_MIXED;
  Quiz[295].MyGroup = GROUP_MIXED;
  Quiz[296].MyGroup = GROUP_MIXED;
  Quiz[297].MyGroup = GROUP_MIXED;
  Quiz[298].MyGroup = GROUP_MIXED;
  Quiz[299].MyGroup = GROUP_MIXED;
  Quiz[300].MyGroup = GROUP_MIXED;
  Quiz[301].MyGroup = GROUP_MIXED;
  Quiz[302].MyGroup = GROUP_MIXED;
  Quiz[303].MyGroup = GROUP_MIXED;
  Quiz[304].MyGroup = GROUP_MIXED;
  Quiz[305].MyGroup = GROUP_MIXED;
  Quiz[306].MyGroup = GROUP_MIXED;
  Quiz[307].MyGroup = GROUP_MIXED;
  Quiz[308].MyGroup = GROUP_MIXED;
  Quiz[309].MyGroup = GROUP_MIXED;
  Quiz[310].MyGroup = GROUP_MIXED;
  Quiz[311].MyGroup = GROUP_MIXED;
  Quiz[312].MyGroup = GROUP_MIXED;
  Quiz[313].MyGroup = GROUP_MIXED;
  Quiz[314].MyGroup = GROUP_MIXED;
  Quiz[315].MyGroup = GROUP_MIXED;
  Quiz[316].MyGroup = GROUP_MIXED;
  Quiz[317].MyGroup = GROUP_MIXED;
  Quiz[318].MyGroup = GROUP_MIXED;
  Quiz[319].MyGroup = GROUP_MIXED;
  Quiz[320].MyGroup = GROUP_MIXED;
  Quiz[321].MyGroup = GROUP_MIXED;
  Quiz[322].MyGroup = GROUP_MIXED;
  Quiz[323].MyGroup = GROUP_MIXED;
  Quiz[324].MyGroup = GROUP_MIXED;
  Quiz[325].MyGroup = GROUP_MIXED;
  Quiz[326].MyGroup = GROUP_MIXED;
  Quiz[327].MyGroup = GROUP_MIXED;
  Quiz[328].MyGroup = GROUP_MIXED;
  Quiz[329].MyGroup = GROUP_MIXED;
  Quiz[330].MyGroup = GROUP_MIXED;
  Quiz[331].MyGroup = GROUP_MIXED;
  Quiz[332].MyGroup = GROUP_MIXED;
  Quiz[333].MyGroup = GROUP_MIXED;
  Quiz[334].MyGroup = GROUP_MIXED;
  Quiz[335].MyGroup = GROUP_MIXED;
  Quiz[336].MyGroup = GROUP_MIXED;
  Quiz[337].MyGroup = GROUP_MIXED;
  Quiz[338].MyGroup = GROUP_MIXED;
  Quiz[339].MyGroup = GROUP_MIXED;
  Quiz[340].MyGroup = GROUP_MIXED;
  Quiz[341].MyGroup = GROUP_MIXED;
  Quiz[342].MyGroup = GROUP_MIXED;
  Quiz[343].MyGroup = GROUP_MIXED;
  Quiz[344].MyGroup = GROUP_MIXED;
  Quiz[345].MyGroup = GROUP_MIXED;
  Quiz[346].MyGroup = GROUP_MIXED;
  Quiz[347].MyGroup = GROUP_MIXED;
  Quiz[348].MyGroup = GROUP_MIXED;
  Quiz[349].MyGroup = GROUP_MIXED;
  Quiz[350].MyGroup = GROUP_MIXED;
  Quiz[351].MyGroup = GROUP_MIXED;
  Quiz[352].MyGroup = GROUP_MIXED;
  Quiz[353].MyGroup = GROUP_MIXED;
  Quiz[354].MyGroup = GROUP_MIXED;
  Quiz[355].MyGroup = GROUP_MIXED;
  Quiz[356].MyGroup = GROUP_MIXED;
  Quiz[357].MyGroup = GROUP_MIXED;
  Quiz[358].MyGroup = GROUP_MIXED;
  Quiz[359].MyGroup = GROUP_MIXED;
  Quiz[360].MyGroup = GROUP_MIXED;
  Quiz[361].MyGroup = GROUP_MIXED;
  Quiz[362].MyGroup = GROUP_MIXED;
  Quiz[363].MyGroup = GROUP_MIXED;
  Quiz[364].MyGroup = GROUP_MIXED;
  Quiz[365].MyGroup = GROUP_MIXED;
  Quiz[366].MyGroup = GROUP_MIXED;
  Quiz[367].MyGroup = GROUP_MIXED;
  Quiz[368].MyGroup = GROUP_MIXED;
  Quiz[369].MyGroup = GROUP_MIXED;
  Quiz[370].MyGroup = GROUP_MIXED;
  Quiz[371].MyGroup = GROUP_MIXED;
  Quiz[372].MyGroup = GROUP_MIXED;
  Quiz[373].MyGroup = GROUP_MIXED;
  Quiz[374].MyGroup = GROUP_MIXED;
  Quiz[375].MyGroup = GROUP_MIXED;
  Quiz[376].MyGroup = GROUP_MIXED;
  Quiz[377].MyGroup = GROUP_MIXED;
  Quiz[378].MyGroup = GROUP_MIXED;
  Quiz[379].MyGroup = GROUP_MIXED;

  Quiz[150].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - confused";
  Quiz[151].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - unsure";
  Quiz[152].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - worried";
  Quiz[153].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - puzzled";
  Quiz[154].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - skeptical";
  Quiz[155].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - bemused";
  Quiz[156].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - disgruntled";
  Quiz[157].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - frustrated";
  Quiz[158].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - awkward";
  Quiz[159].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - indifferent";
  Quiz[160].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - irritated";
  Quiz[161].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon1.gif\"> - smirking";
  
  Quiz[162].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - evil";
  Quiz[163].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - happy";
  Quiz[164].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - mischievous";
  Quiz[165].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - grin";
  Quiz[166].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - devious";
  Quiz[167].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - angry";
  Quiz[168].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - mean";
  Quiz[169].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - muahahaha";
  Quiz[170].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - naughty";
  Quiz[171].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - vengeful";
  Quiz[172].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - sadistic";
  Quiz[173].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon2.gif\"> - sarcastic";

  Quiz[174].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - angry";
  Quiz[175].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - evil";
  Quiz[176].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - sad";
  Quiz[177].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - unhappy";
  Quiz[178].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - upset";
  Quiz[179].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - pissed off";
  Quiz[180].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - vengeful";
  Quiz[181].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - grumpy";
  Quiz[182].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - hate";
  Quiz[183].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - mean";
  Quiz[184].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - cross";
  Quiz[185].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon3.gif\"> - displeased";

  Quiz[186].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - sarcastic";
  Quiz[187].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - exasperated";
  Quiz[188].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - bored";
  Quiz[189].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - annoyed";
  Quiz[190].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - unsure";
  Quiz[191].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - amused";
  Quiz[192].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - apologetic";
  Quiz[193].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - embarrased";
  Quiz[194].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - something stupid was said";
  Quiz[195].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - confused";
  Quiz[196].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - thinking";
  Quiz[197].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon4.gif\"> - innocent";

  Quiz[198].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - surprised";
  Quiz[199].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - happy";
  Quiz[200].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - shocked";
  Quiz[201].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - excited";
  Quiz[202].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - smiling";
  Quiz[203].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - talkative";
  Quiz[204].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - shouting";
  Quiz[205].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - cheerful";
  Quiz[206].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - oh my";
  Quiz[207].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - grin";
  Quiz[208].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - wow";
  Quiz[209].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon5.gif\"> - scared";

  Quiz[210].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - happy";
  Quiz[211].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - sticking tounge out";
  Quiz[212].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - playful";
  Quiz[213].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - laughing";
  Quiz[214].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - joking";
  Quiz[215].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - smiling";
  Quiz[216].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - excited";
  Quiz[217].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - silly";
  Quiz[218].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - raspberry";
  Quiz[219].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - fake";
  Quiz[220].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - friendly";
  Quiz[221].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon6.gif\"> - rude";

  Quiz[222].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - confused";
  Quiz[223].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - unsure";
  Quiz[224].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - skeptical";
  Quiz[225].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - tired";
  Quiz[226].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - happy";
  Quiz[227].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - pain";
  Quiz[228].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - sad";
  Quiz[229].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - self content";
  Quiz[230].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - embarrassed";
  Quiz[231].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - ill";
  Quiz[232].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - uncomfortable";
  Quiz[233].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon7.gif\"> - worried";

  Quiz[234].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - angry";
  Quiz[235].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - annoyed";
  Quiz[236].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - humph";
  Quiz[237].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - stubborn";
  Quiz[238].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - disgusted";
  Quiz[239].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - pouty";
  Quiz[240].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - offended";
  Quiz[241].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - no way";
  Quiz[242].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - disdainful";
  Quiz[243].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - go away";
  Quiz[244].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - displeased";
  Quiz[245].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon8.gif\"> - huffy";

  Quiz[246].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - dreamy";
  Quiz[247].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - hopeful";
  Quiz[248].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - thinking";
  Quiz[249].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - bashful";
  Quiz[250].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - exasperated";
  Quiz[251].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - happy";
  Quiz[252].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - in love";
  Quiz[253].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - relieved";
  Quiz[254].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - wistful";
  Quiz[255].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - bored";
  Quiz[256].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - satisfied";
  Quiz[257].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon9.gif\"> - confused";

  Quiz[258].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - winking";
  Quiz[259].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - suspicous";
  Quiz[260].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - confused";
  Quiz[261].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - mean";
  Quiz[262].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - nosy";
  Quiz[263].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - playful";
  Quiz[264].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - sad";
  Quiz[265].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - skeptical";
  Quiz[266].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - sneaky";
  Quiz[267].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - cynical";
  Quiz[268].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - frustrated";
  Quiz[269].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon10.gif\"> - displeased";

  Quiz[270].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - happy";
  Quiz[271].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - laughing";
  Quiz[272].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - stupid";
  Quiz[273].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - funny";
  Quiz[274].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - amused";
  Quiz[275].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - grin";
  Quiz[276].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - goofy";
  Quiz[277].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - hillbilly";
  Quiz[278].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - cute";
  Quiz[279].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - dorky";
  Quiz[280].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - cool";
  Quiz[281].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon11.gif\"> - joking";

  Quiz[282].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - evil";
  Quiz[283].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - staring";
  Quiz[284].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - mean";
  Quiz[285].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - plotting";
  Quiz[286].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - determined";
  Quiz[287].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - mischevious";
  Quiz[288].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - sneaky";
  Quiz[289].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - angry";
  Quiz[290].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - leer";
  Quiz[291].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - shy";
  Quiz[292].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - hunting";
  Quiz[293].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon12.gif\"> - creepy";

  Quiz[294].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - happy";
  Quiz[295].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - dancing";
  Quiz[296].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - cheery";
  Quiz[297].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - celebrating";
  Quiz[298].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - excited";
  Quiz[299].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - joyful";
  Quiz[300].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - proud";
  Quiz[301].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - told you so";
  Quiz[302].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - triumphant";
  Quiz[303].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - well done";
  Quiz[304].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - yeah";
  Quiz[305].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon13.gif\"> - fanatical";

  Quiz[306].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - stop";
  Quiz[307].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - no thanks";
  Quiz[308].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - hello";
  Quiz[309].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - back off";
  Quiz[310].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - dismissive";
  Quiz[311].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - don't talk to me";
  Quiz[312].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - don't want to know";
  Quiz[313].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - wait";
  Quiz[314].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - bye";
  Quiz[315].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - busy";
  Quiz[316].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - cautious";
  Quiz[317].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon14.gif\"> - overwhelmed";

  Quiz[318].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - be quiet";
  Quiz[319].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - secretive";
  Quiz[320].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - hush";
  Quiz[321].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - you";
  Quiz[322].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - thinking";
  Quiz[323].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - gossip";
  Quiz[324].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - shut up";
  Quiz[325].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - wisper";
  Quiz[326].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - cautious";
  Quiz[327].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - accusing";
  Quiz[328].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - requesting";
  Quiz[329].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon15.gif\"> - puzzled";

  Quiz[330].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - happy";
  Quiz[331].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - smiling";
  Quiz[332].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - laughing";
  Quiz[333].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - pleased";
  Quiz[334].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - sarcastic";
  Quiz[335].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - confident";
  Quiz[336].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - friendly";
  Quiz[337].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - funny";
  Quiz[338].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - elated";
  Quiz[339].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - mocking";
  Quiz[340].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - hiding";
  Quiz[341].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon16.gif\"> - awesome";

  Quiz[342].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - sad";
  Quiz[343].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - crying";
  Quiz[344].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - depressed";
  Quiz[345].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - unhappy";
  Quiz[346].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - upset";
  Quiz[347].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - crushed";
  Quiz[348].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - disappointed";
  Quiz[349].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - despondent";
  Quiz[350].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - hurt";
  Quiz[351].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - miserable";
  Quiz[352].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - overwhelmed";
  Quiz[353].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon17.gif\"> - let down";

  Quiz[354].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - embarrassed";
  Quiz[355].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - blushing";
  Quiz[356].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - ashamed";
  Quiz[357].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - oops";
  Quiz[358].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - bashful";
  Quiz[359].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - sad";
  Quiz[360].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - sick";
  Quiz[361].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - angry";
  Quiz[362].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - uncomfortable";
  Quiz[363].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - tense";
  Quiz[364].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - sour";
  Quiz[365].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon18.gif\"> - sexual";

  Quiz[366].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - sad";
  Quiz[367].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - unhappy";
  Quiz[368].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - disappointed";
  Quiz[369].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - worried";
  Quiz[370].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - afraid";
  Quiz[371].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - upset";
  Quiz[372].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - angry";
  Quiz[373].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - anxious";
  Quiz[374].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - doleful";
  Quiz[375].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - frustrated";
  Quiz[376].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - downcast";
  Quiz[377].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon19.gif\"> - exhausted";

  Quiz[378].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - happy";
  Quiz[379].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - smiling";
  Quiz[380].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - content";
  Quiz[381].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - excited";
  Quiz[382].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - satisfied";
  Quiz[383].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - evil";
  Quiz[384].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - friendly";
  Quiz[385].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - funny";
  Quiz[386].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - laughing";
  Quiz[387].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - cheeky";
  Quiz[388].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - creepy";
  Quiz[389].Text = "<img border=\"0\" src=\"http://www.rdos.net/smileys/icon20.gif\"> - smirk";
}

/*##################  TQuizG2::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizG2::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Gender == 1)
			UpdateReferer(&MaleRef, Row.AsResult, Row.NtResult, Row.GroupResult);
        else			
			UpdateReferer(&FemaleRef, Row.AsResult, Row.NtResult, Row.GroupResult);
	
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2)
			UpdateReferer(&AsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&AddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.OCD == 2)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Social == 2)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie)
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
#   Name       : TQuizG2::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizG2::LoadPopulations()
{
	TQuizRow Row;
	int i;
	int id;
	TReferer *ref;
	char DxArr[DX_COUNT];
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
				if (i < 161)
				{
					score = Row.Quiz[i] - 1;
					id = IdArr[i];

					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
					DsmSocialPhobia.Add(Row.Social, id, score);
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

		All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Aspie)
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

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

			if (Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.ADHD >= 1)
		{
			Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.Social >= 1)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

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
#   Name       : TQuizG2::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizG2::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5, TQuiz *QuizF6, TQuiz *QuizF7, TQuiz *QuizF8, TQuiz *QuizF9, TQuiz *QuizF10, TQuiz *QuizF11, TQuiz *QuizF12, TQuiz *QuizF13, TQuiz *QuizF14, TQuiz *QuizF15, TQuiz *QuizGE, TQuiz *QuizGE2, TQuiz *QuizGE3, TQuiz *QuizG1)
{
    int i;

    for (i = 0; i < 150; i++)
	    DefineCross(QuizG1, i, i);

	DefineGlobalId(150, 1448);
	DefineGlobalId(151, 1449);
	DefineGlobalId(152, 1450);
	DefineGlobalId(153, 1451);
	DefineGlobalId(154, 1452);
	DefineGlobalId(155, 1453);
	DefineGlobalId(156, 1454);
	DefineGlobalId(157, 1455);
	DefineGlobalId(158, 1456);
	DefineGlobalId(159, 1457);
	DefineGlobalId(160, 1458);
	DefineGlobalId(161, 1459);
	DefineGlobalId(162, 1460);
	DefineGlobalId(163, 1461);
	DefineGlobalId(164, 1462);
	DefineGlobalId(165, 1463);
	DefineGlobalId(166, 1464);
	DefineGlobalId(167, 1465);
	DefineGlobalId(168, 1466);
	DefineGlobalId(169, 1467);
	DefineGlobalId(170, 1468);
	DefineGlobalId(171, 1469);
	DefineGlobalId(172, 1470);
	DefineGlobalId(173, 1471);
	DefineGlobalId(174, 1472);
	DefineGlobalId(175, 1473);
	DefineGlobalId(176, 1474);
	DefineGlobalId(177, 1475);
	DefineGlobalId(178, 1476);
	DefineGlobalId(179, 1477);
	DefineGlobalId(180, 1478);
	DefineGlobalId(181, 1479);
	DefineGlobalId(182, 1480);
	DefineGlobalId(183, 1481);
	DefineGlobalId(184, 1482);
	DefineGlobalId(185, 1483);
	DefineGlobalId(186, 1484);
	DefineGlobalId(187, 1485);
	DefineGlobalId(188, 1486);
	DefineGlobalId(189, 1487);
	DefineGlobalId(190, 1488);
	DefineGlobalId(191, 1489);
	DefineGlobalId(192, 1490);
	DefineGlobalId(193, 1491);
	DefineGlobalId(194, 1492);
	DefineGlobalId(195, 1493);
	DefineGlobalId(196, 1494);
	DefineGlobalId(197, 1495);
	DefineGlobalId(198, 1496);
	DefineGlobalId(199, 1497);
	DefineGlobalId(200, 1498);
	DefineGlobalId(201, 1499);
	DefineGlobalId(202, 1500);
	DefineGlobalId(203, 1501);
	DefineGlobalId(204, 1502);
	DefineGlobalId(205, 1503);
	DefineGlobalId(206, 1504);
	DefineGlobalId(207, 1505);
	DefineGlobalId(208, 1506);
	DefineGlobalId(209, 1507);
	DefineGlobalId(210, 1508);
	DefineGlobalId(211, 1509);
	DefineGlobalId(212, 1510);
	DefineGlobalId(213, 1511);
	DefineGlobalId(214, 1512);
	DefineGlobalId(215, 1513);
	DefineGlobalId(216, 1514);
	DefineGlobalId(217, 1515);
	DefineGlobalId(218, 1516);
	DefineGlobalId(219, 1517);
	DefineGlobalId(220, 1518);
	DefineGlobalId(221, 1519);
	DefineGlobalId(222, 1520);
	DefineGlobalId(223, 1521);
	DefineGlobalId(224, 1522);
	DefineGlobalId(225, 1523);
	DefineGlobalId(226, 1524);
	DefineGlobalId(227, 1525);
	DefineGlobalId(228, 1526);
	DefineGlobalId(229, 1527);
	DefineGlobalId(230, 1528);
	DefineGlobalId(231, 1529);
	DefineGlobalId(232, 1530);
	DefineGlobalId(233, 1531);
	DefineGlobalId(234, 1532);
	DefineGlobalId(235, 1533);
	DefineGlobalId(236, 1534);
	DefineGlobalId(237, 1535);
	DefineGlobalId(238, 1536);
	DefineGlobalId(239, 1537);
	DefineGlobalId(240, 1538);
	DefineGlobalId(241, 1539);
	DefineGlobalId(242, 1540);
	DefineGlobalId(243, 1541);
	DefineGlobalId(244, 1542);
	DefineGlobalId(245, 1543);
	DefineGlobalId(246, 1544);
	DefineGlobalId(247, 1545);
	DefineGlobalId(248, 1546);
	DefineGlobalId(249, 1547);
	DefineGlobalId(250, 1548);
	DefineGlobalId(251, 1549);
	DefineGlobalId(252, 1550);
	DefineGlobalId(253, 1551);
	DefineGlobalId(254, 1552);
	DefineGlobalId(255, 1553);
	DefineGlobalId(256, 1554);
	DefineGlobalId(257, 1555);
	DefineGlobalId(258, 1556);
	DefineGlobalId(259, 1557);
	DefineGlobalId(260, 1558);
	DefineGlobalId(261, 1559);
	DefineGlobalId(262, 1560);
	DefineGlobalId(263, 1561);
	DefineGlobalId(264, 1562);
	DefineGlobalId(265, 1563);
	DefineGlobalId(266, 1564);
	DefineGlobalId(267, 1565);
	DefineGlobalId(268, 1566);
	DefineGlobalId(269, 1567);
	DefineGlobalId(270, 1568);
	DefineGlobalId(271, 1569);
	DefineGlobalId(272, 1570);
	DefineGlobalId(273, 1571);
	DefineGlobalId(274, 1572);
	DefineGlobalId(275, 1573);
	DefineGlobalId(276, 1574);
	DefineGlobalId(277, 1575);
	DefineGlobalId(278, 1576);
	DefineGlobalId(279, 1577);
	DefineGlobalId(280, 1578);
	DefineGlobalId(281, 1579);
	DefineGlobalId(282, 1580);
	DefineGlobalId(283, 1581);
	DefineGlobalId(284, 1582);
	DefineGlobalId(285, 1583);
	DefineGlobalId(286, 1584);
	DefineGlobalId(287, 1585);
	DefineGlobalId(288, 1586);
	DefineGlobalId(289, 1587);
	DefineGlobalId(290, 1588);
	DefineGlobalId(291, 1589);
	DefineGlobalId(292, 1590);
	DefineGlobalId(293, 1591);
	DefineGlobalId(294, 1592);
	DefineGlobalId(295, 1593);
	DefineGlobalId(296, 1594);
	DefineGlobalId(297, 1595);
	DefineGlobalId(298, 1596);
	DefineGlobalId(299, 1597);
	DefineGlobalId(300, 1598);
	DefineGlobalId(301, 1599);
	DefineGlobalId(302, 1600);
	DefineGlobalId(303, 1601);
	DefineGlobalId(304, 1602);
	DefineGlobalId(305, 1603);
	DefineGlobalId(306, 1604);
	DefineGlobalId(307, 1605);
	DefineGlobalId(308, 1606);
	DefineGlobalId(309, 1607);
	DefineGlobalId(310, 1608);
	DefineGlobalId(311, 1609);
	DefineGlobalId(312, 1610);
	DefineGlobalId(313, 1611);
	DefineGlobalId(314, 1612);
	DefineGlobalId(315, 1613);
	DefineGlobalId(316, 1614);
	DefineGlobalId(317, 1615);
	DefineGlobalId(318, 1616);
	DefineGlobalId(319, 1617);
	DefineGlobalId(320, 1618);
	DefineGlobalId(321, 1619);
	DefineGlobalId(322, 1620);
	DefineGlobalId(323, 1621);
	DefineGlobalId(324, 1622);
	DefineGlobalId(325, 1623);
	DefineGlobalId(326, 1624);
	DefineGlobalId(327, 1625);
	DefineGlobalId(328, 1626);
	DefineGlobalId(329, 1627);
	DefineGlobalId(330, 1628);
	DefineGlobalId(331, 1629);
	DefineGlobalId(332, 1630);
	DefineGlobalId(333, 1631);
	DefineGlobalId(334, 1632);
	DefineGlobalId(335, 1633);
	DefineGlobalId(336, 1634);
	DefineGlobalId(337, 1635);
	DefineGlobalId(338, 1636);
	DefineGlobalId(339, 1637);
	DefineGlobalId(340, 1638);
	DefineGlobalId(341, 1639);
	DefineGlobalId(342, 1640);
	DefineGlobalId(343, 1641);
	DefineGlobalId(344, 1642);
	DefineGlobalId(345, 1643);
	DefineGlobalId(346, 1644);
	DefineGlobalId(347, 1645);
	DefineGlobalId(348, 1646);
	DefineGlobalId(349, 1647);
	DefineGlobalId(350, 1648);
	DefineGlobalId(351, 1649);
	DefineGlobalId(352, 1650);
	DefineGlobalId(353, 1651);
	DefineGlobalId(354, 1652);
	DefineGlobalId(355, 1653);
	DefineGlobalId(356, 1654);
	DefineGlobalId(357, 1655);
	DefineGlobalId(358, 1656);
	DefineGlobalId(359, 1657);
	DefineGlobalId(360, 1658);
	DefineGlobalId(361, 1659);
	DefineGlobalId(362, 1660);
	DefineGlobalId(363, 1661);
	DefineGlobalId(364, 1662);
	DefineGlobalId(365, 1663);
	DefineGlobalId(366, 1664);
	DefineGlobalId(367, 1665);
	DefineGlobalId(368, 1666);
	DefineGlobalId(369, 1667);
	DefineGlobalId(370, 1668);
	DefineGlobalId(371, 1669);
	DefineGlobalId(372, 1670);
	DefineGlobalId(373, 1671);
	DefineGlobalId(374, 1672);
	DefineGlobalId(375, 1673);
	DefineGlobalId(376, 1674);
	DefineGlobalId(377, 1675);
	DefineGlobalId(378, 1676);
	DefineGlobalId(379, 1677);
	DefineGlobalId(380, 1678);
	DefineGlobalId(381, 1679);
	DefineGlobalId(382, 1680);
	DefineGlobalId(383, 1681);
	DefineGlobalId(384, 1682);
	DefineGlobalId(385, 1683);
	DefineGlobalId(386, 1684);
	DefineGlobalId(387, 1685);
	DefineGlobalId(388, 1686);
	DefineGlobalId(389, 1687);

}

/*##########################################################################
#
#   Name       : TQuizG2::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizG2::GetReferer(const char *referer, TPopulation *pop)
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
			if (row->BirthYear >= 1975)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear < 1975)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_AS:
				if (row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizG2::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizG2::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GetQuizN(); i++)
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

			for (i = 0; i < GetQuizN(); i++)
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
					if (i != GetQuizN() - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizG2::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizG2::ExportExcelAspie(const char *filename)
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
		if (1)
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
						ival = GetCatCount(i) - ival;
					else
						ival--;
				}


				if (ival >= GetCatCount(i))
					ival = 0;

				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != N - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizG2::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizG2::ExportExcelGroups(const char *filename)
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

		for (i = 0; i < GetQuizN(); i++)
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

/*##################  TQuizG2::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizG2::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_MALE)
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
		if (Row->Ancestry == 3)
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

			if (diff >= 35)
				UsAsCount[index]++;
		}
	}
	else
	{
		if (Row->Ancestry == 3) // && Row->Hair >= 6 && Row->Eye >= 5)
			index = 0;      // american indian

		if (Row->Ancestry == 5)
			index = 1;      // african american

		if (Row->Ancestry == 6)
			index = 2;      // hispanic

		if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
			index = 3;      // black african

		if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
			index = 4;      // white

		if (Row->Ancestry >= 3000 && Row->Ancestry < 4000 && Row->Ancestry != 3205)
			index = 5;      // arab

		if (Row->Ancestry >= 4000)
			index = 6;      // asian

		if (index >= 0)
		{
			NonUsCount[index]++;

			if (diff >= 35)
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
	file.Write("All");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Aspie");
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

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsAsCount[index]);
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

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", NonUsAsCount[index]);
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


/*##################  TQuizG2::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizG2::WriteRace(const char *filename)
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
	race.WriteNonUsRow(file, 2, "Hispanic");
	race.WriteNonUsRow(file, 3, "African");
	race.WriteNonUsRow(file, 4, "Caucasian");
	race.WriteNonUsRow(file, 5, "Arab");
	race.WriteNonUsRow(file, 6, "Asian");

	file.Write("</table>");
}

/*##################  TQuizG2::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizG2::WriteRetest(const char *filename)
{
	TQuizRow Row;
	int userid;
	int i;
	int index;
	int birthyear;
	int birthmonth;
	int gender;
	long double val;
	long double AsSum;
	long double NtSum;
	long double AsMean;
	long double NtMean;
	long double QMean[147];
	long double AsSd;
	long double NtSd;
	long double QSd[147];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[147];
	int QCount[147];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[14][20];
	int ok;
	char str[80];
	TFile file(filename, 0);

	for (userid = 0; userid < MAX_USERS; userid++)
		 UserInfo[userid] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		 userid = Row.userid;

		 if (userid)
		 {
			  if (UserInfo[userid] == 0)
			  {
					UserInfo[userid] = new TUserInfo;
					UserInfo[userid]->Count = 1;
					  UserInfo[userid]->BirthYear = Row.BirthYear;
					  UserInfo[userid]->BirthMonth = Row.BirthMonth;
					UserInfo[userid]->AsSum = Row.AsResult;
					UserInfo[userid]->NtSum = Row.NtResult;
			  }
			  else
					UserInfo[userid]->Count++;
		 }
	}

	 AsCount = 0;
	 NtCount = 0;
	 AsTot = 0;
	 NtTot = 0;

	 for (q = 0; q < 147; q++)
	 {
		  QTot[q] = 0;
		  QCount[q] = 0;
	 }

	for (userid = 1; userid < MAX_USERS; userid++)
	{
		  if (UserInfo[userid])
		  {
				if (UserInfo[userid]->Count > 1)
				 {
					 for (i = 0; i < 20; i++)
					 {
						  AsArr[i] = 0;
						  NtArr[i] = 0;

						  for (q = 0; q < 14; q++)
								QArr[q][i] = 0;
					 }

					 index = 0;

					FDataFile.SetPos(0);
				 while (FDataFile.Read(&Row, sizeof(Row)))
					{
						 if (Row.userid == userid)
						 {
								ok = FALSE;

							if (index == 0)
							{
									birthyear = Row.BirthYear;
									birthmonth = Row.BirthMonth;
									gender = Row.Gender;
								 ok = TRUE;

									  UserInfo[userid]->Count = 1;
									 UserInfo[userid]->BirthYear = Row.BirthYear;
									 UserInfo[userid]->BirthMonth = Row.BirthMonth;
									UserInfo[userid]->AsSum = Row.AsResult;
									UserInfo[userid]->NtSum = Row.NtResult;
							}
							else
							  {
									if (    birthyear == Row.BirthYear &&
											  birthmonth == Row.BirthMonth &&
											gender == Row.Gender)
								 {
									  ok = TRUE;

									  UserInfo[userid]->Count++;
									  UserInfo[userid]->AsSum += Row.AsResult;
									  UserInfo[userid]->NtSum += Row.NtResult;
								 }
							}

							  if (ok)
							  {
								  AsArr[index] = Row.AsResult;
								  NtArr[index] = Row.NtResult;

								  for (q = 0; q < 14; q++)
										QArr[q][index] = Row.Quiz[q];

								 index++;
							}
					  }
				 }

				if (index > 1)
				{
					AsSum = 0;
					NtSum = 0;

					for (i = 0; i < index; i++)
					{
						AsSum += AsArr[i];
						NtSum += NtArr[i];
					 }

					AsMean = AsSum / index;
					NtMean = NtSum / index;

					for (q = 0; q < 147; q++)
					{
						 count = 0;
						  sum = 0;

						 for (i = 0; i < index; i++)
						 {
							  if (QArr[q][i])
							  {
									 sum += QArr[q][i] - 1;
									 count++;
								}
						 }

						 if (count)
							  QMean[q] = sum / count;
						 else
								QMean[q] = 0;
					}

					AsSum = 0;
					NtSum = 0;

					for (i = 0; i < index; i++)
					 {
						val = AsArr[i] - AsMean;
						AsSum += val * val;

						val = NtArr[i] - NtMean;
						NtSum += val * val;
					}

					 AsSd = sqrtl(AsSum / index);
					NtSd = sqrtl(NtSum / index);

					for (q = 0; q < 147; q++)
					{
						 count = 0;
						  sum = 0;

						 for (i = 0; i < index; i++)
						 {
							  if (QArr[q][i])
								{
									 val = QArr[q][i] - 1 - QMean[q];
									 sum += val * val;
									 count++;
							  }
						 }

								if (count)
								{
							 QSd[q] = sqrtl(sum / count);

							 QTot[q] += QSd[q];
							 QCount[q]++;
						}
						else
							  QSd[q] = 0;
					}

						  AsTot += AsSd;
						  AsCount++;

					NtTot += NtSd;
					 NtCount++;

//  				sprintf(str, "Userid: %d, AS: %5.1Lf (%5.1Lf), NT: %5.1Lf (%5.1Lf)<br>", userid, AsMean, AsSd, NtMean, NtSd);
//	    			file.Write(str);
//
//		    		for (q = 0; q < 135; q++)
//			    	{
//				        if (QSd[q] > 0.1)
//  				    {
//        				    sprintf(str, "#%d, Sd = %5.1Lf<br>", q, QSd[q]);
//    	    			    file.Write(str);
//    		    		}
//    		        }
				}
			 }
		}
	}

	AsSd = AsTot / AsCount;
	NtSd = NtTot / NtCount;

#ifdef ENGLISH
	file.Write("<h2>Retest result</h2>\n");
#endif

#ifdef SWEDISH
	file.Write("<h2>Omtestnings resultat</h2>\n");
#endif

#ifdef ENGLISH
	sprintf(str, "Population size: %d", AsCount);
#endif

#ifdef SWEDISH
	sprintf(str, "Populationsstorlek: %d", AsCount);
#endif

	file.Write(str);
	file.Write("<br><br>");

#ifdef ENGLISH
	sprintf(str, "AS score standard deviation: %2.1Lf", AsSd);
#endif

#ifdef SWEDISH
	sprintf(str, "AS poäng standardavvikelse: %2.1Lf", AsSd);
#endif

	file.Write(str);
	file.Write("<br>");

#ifdef ENGLISH
	sprintf(str, "NT score standard deviation: %2.1Lf", NtSd);
#endif

#ifdef SWEDISH
	sprintf(str, "NT poäng standardavvikelse: %2.1Lf", NtSd);
#endif

	file.Write(str);
	file.Write("<br><br>");
}
