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
# quizf2.cpp
# Quiz final version 2 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizf2.h"
#include "file.h"
#include "quizdbf2.h"

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
#   Name       : TQuizF2::TQuizF2
#
#   Purpose....: Constructor for TQuizF2
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizF2::TQuizF2(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1)
  : TQuizFinal(270, QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1, QuizN2, QuizN3, QuizN4),
	FDataFile(FileName)
{
	DefineCross(32, QuizFI);
	DefineCross(33, QuizF1);

	SetupTexts();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1, QuizN2, QuizN3, QuizN4, QuizFI, QuizF1);

	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizF2::~TQuizF2
#
#   Purpose....: Destructor for TQuizF2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizF2::~TQuizF2()
{
}

/*##################  TQuizF2::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizF2::GetCatCount(int Question)
{
    if (Question < 150)
        return 3;
    else
    	return 5;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizF2::GetQuizN()
{
	return 150;
}

/*##########################################################################
#
#   Name       : TQuizF2::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF2::WriteName(TFile &File)
{
	 File.Write("F2");
}

/*##########################################################################
#
#   Name       : TQuizF2::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF2::WriteLongName(TFile &File)
{
	 File.Write("final version 2");
}

/*##########################################################################
#
#   Name       : TQuizF2::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF2::SetupTexts()
{
 Quiz[151].Reverse = TRUE;
 Quiz[153].Reverse = TRUE;
 Quiz[154].Reverse = TRUE;
 Quiz[156].Reverse = TRUE;
 Quiz[161].Reverse = TRUE;
 Quiz[163].Reverse = TRUE;
 Quiz[164].Reverse = TRUE;
 Quiz[166].Reverse = TRUE;
 Quiz[167].Reverse = TRUE;
 Quiz[168].Reverse = TRUE;
 Quiz[169].Reverse = TRUE;
 Quiz[171].Reverse = TRUE;
 Quiz[172].Reverse = TRUE;
 Quiz[174].Reverse = TRUE;
 Quiz[176].Reverse = TRUE;
 Quiz[177].Reverse = TRUE;
 Quiz[178].Reverse = TRUE;
 Quiz[181].Reverse = TRUE;
 Quiz[183].Reverse = TRUE;
 Quiz[184].Reverse = TRUE;
 Quiz[186].Reverse = TRUE;
 Quiz[191].Reverse = TRUE;
 Quiz[192].Reverse = TRUE;
 Quiz[193].Reverse = TRUE;
 Quiz[194].Reverse = TRUE;
 Quiz[196].Reverse = TRUE;
 Quiz[199].Reverse = TRUE;
 Quiz[200].Reverse = TRUE;
 Quiz[201].Reverse = TRUE;
 Quiz[203].Reverse = TRUE;
 Quiz[204].Reverse = TRUE;
 Quiz[206].Reverse = TRUE;
 Quiz[207].Reverse = TRUE;
 Quiz[208].Reverse = TRUE;
 Quiz[213].Reverse = TRUE;
 Quiz[214].Reverse = TRUE;
 Quiz[221].Reverse = TRUE;
 Quiz[226].Reverse = TRUE;
 Quiz[230].Reverse = TRUE;
 Quiz[231].Reverse = TRUE;
 Quiz[233].Reverse = TRUE;
 Quiz[236].Reverse = TRUE;
 Quiz[237].Reverse = TRUE;
 Quiz[244].Reverse = TRUE;
 Quiz[245].Reverse = TRUE;
 Quiz[250].Reverse = TRUE;
 Quiz[255].Reverse = TRUE;
 Quiz[256].Reverse = TRUE;
 Quiz[260].Reverse = TRUE;
 Quiz[261].Reverse = TRUE;
 Quiz[265].Reverse = TRUE;
 Quiz[266].Reverse = TRUE;

 Quiz[150].MyGroup = GROUP_ENVIRONMENT;
 Quiz[151].MyGroup = GROUP_NT_SOCIAL;
 Quiz[152].MyGroup = GROUP_ASPIE_TALENT;
 Quiz[153].MyGroup = GROUP_ENVIRONMENT;
 Quiz[154].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[155].MyGroup = GROUP_ENVIRONMENT;
 Quiz[156].MyGroup = GROUP_NT_OBSESSION;
 Quiz[157].MyGroup = GROUP_MIXED;
 Quiz[158].MyGroup = GROUP_NT_NVC;
 Quiz[159].MyGroup = GROUP_ASPIE_OBSESSION;
 Quiz[160].MyGroup = GROUP_ENVIRONMENT;
 Quiz[161].MyGroup = GROUP_NT_SOCIAL;
 Quiz[162].MyGroup = GROUP_ENVIRONMENT;
 Quiz[163].MyGroup = GROUP_NT_NVC;
 Quiz[164].MyGroup = GROUP_MIXED;
 Quiz[165].MyGroup = GROUP_NT_SOCIAL;
 Quiz[166].MyGroup = GROUP_NT_HUNTING;
 Quiz[167].MyGroup = GROUP_ASPIE_OBSESSION;
 Quiz[168].MyGroup = GROUP_NT_OBSESSION;
 Quiz[169].MyGroup = GROUP_MIXED;
 Quiz[170].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[171].MyGroup = GROUP_NT_OBSESSION;
 Quiz[172].MyGroup = GROUP_NT_TALENT;
 Quiz[173].MyGroup = GROUP_NT_NVC;
 Quiz[174].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[175].MyGroup = GROUP_ENVIRONMENT;
 Quiz[176].MyGroup = GROUP_NT_OBSESSION;
 Quiz[177].MyGroup = GROUP_MIXED;
 Quiz[178].MyGroup = GROUP_NT_NVC;
 Quiz[179].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[180].MyGroup = GROUP_ENVIRONMENT;
 Quiz[181].MyGroup = GROUP_NT_SOCIAL;
 Quiz[182].MyGroup = GROUP_MIXED;
 Quiz[183].MyGroup = GROUP_ENVIRONMENT;
 Quiz[184].MyGroup = GROUP_MIXED;
 Quiz[185].MyGroup = GROUP_ENVIRONMENT;
 Quiz[186].MyGroup = GROUP_NT_OBSESSION;
 Quiz[187].MyGroup = GROUP_ASPIE_TALENT;
 Quiz[188].MyGroup = GROUP_MIXED;
 Quiz[189].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[190].MyGroup = GROUP_ENVIRONMENT;
 Quiz[191].MyGroup = GROUP_NT_SOCIAL;
 Quiz[192].MyGroup = GROUP_NT_NVC;
 Quiz[193].MyGroup = GROUP_NT_NVC;
 Quiz[194].MyGroup = GROUP_MIXED;
 Quiz[195].MyGroup = GROUP_NT_SOCIAL;
 Quiz[196].MyGroup = GROUP_MIXED;
 Quiz[197].MyGroup = GROUP_ASPIE_OBSESSION;
 Quiz[198].MyGroup = GROUP_ENVIRONMENT;
 Quiz[199].MyGroup = GROUP_ASPIE_TALENT;
 Quiz[200].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[201].MyGroup = GROUP_NT_OBSESSION;
 Quiz[202].MyGroup = GROUP_MIXED;
 Quiz[203].MyGroup = GROUP_ENVIRONMENT;
 Quiz[204].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[205].MyGroup = GROUP_MIXED;
 Quiz[206].MyGroup = GROUP_NT_OBSESSION;
 Quiz[207].MyGroup = GROUP_MIXED;
 Quiz[208].MyGroup = GROUP_NT_NVC;
 Quiz[209].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[210].MyGroup = GROUP_ENVIRONMENT;
 Quiz[211].MyGroup = GROUP_NT_SOCIAL;
 Quiz[212].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[213].MyGroup = GROUP_ENVIRONMENT;
 Quiz[214].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[215].MyGroup = GROUP_ENVIRONMENT;
 Quiz[216].MyGroup = GROUP_NT_SOCIAL;
 Quiz[217].MyGroup = GROUP_MIXED;
 Quiz[218].MyGroup = GROUP_MIXED;
 Quiz[219].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[220].MyGroup = GROUP_ENVIRONMENT;
 Quiz[221].MyGroup = GROUP_NT_SOCIAL;
 Quiz[222].MyGroup = GROUP_NT_NVC;
 Quiz[223].MyGroup = GROUP_NT_NVC;
 Quiz[224].MyGroup = GROUP_MIXED;
 Quiz[225].MyGroup = GROUP_NT_SOCIAL;
 Quiz[226].MyGroup = GROUP_NT_HUNTING;
 Quiz[227].MyGroup = GROUP_ASPIE_OBSESSION;
 Quiz[228].MyGroup = GROUP_NT_NVC;
 Quiz[229].MyGroup = GROUP_MIXED;
 Quiz[230].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[231].MyGroup = GROUP_NT_OBSESSION;
 Quiz[232].MyGroup = GROUP_NT_TALENT;
 Quiz[233].MyGroup = GROUP_ENVIRONMENT;
 Quiz[234].MyGroup = GROUP_MIXED;
 Quiz[235].MyGroup = GROUP_ENVIRONMENT;
 Quiz[236].MyGroup = GROUP_ENVIRONMENT;
 Quiz[237].MyGroup = GROUP_MIXED;
 Quiz[238].MyGroup = GROUP_NT_NVC;
 Quiz[239].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[240].MyGroup = GROUP_ENVIRONMENT;
 Quiz[241].MyGroup = GROUP_NT_SOCIAL;
 Quiz[242].MyGroup = GROUP_ASPIE_TALENT;
 Quiz[243].MyGroup = GROUP_ENVIRONMENT;
 Quiz[244].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[245].MyGroup = GROUP_ENVIRONMENT;
 Quiz[246].MyGroup = GROUP_NT_OBSESSION;
 Quiz[247].MyGroup = GROUP_NT_NVC;
 Quiz[248].MyGroup = GROUP_NT_NVC;
 Quiz[249].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[250].MyGroup = GROUP_ENVIRONMENT;
 Quiz[251].MyGroup = GROUP_NT_SOCIAL;
 Quiz[252].MyGroup = GROUP_NT_NVC;
 Quiz[253].MyGroup = GROUP_NT_NVC;
 Quiz[254].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[255].MyGroup = GROUP_NT_SOCIAL;
 Quiz[256].MyGroup = GROUP_MIXED;
 Quiz[257].MyGroup = GROUP_ASPIE_OBSESSION;
 Quiz[258].MyGroup = GROUP_NT_NVC;
 Quiz[259].MyGroup = GROUP_MIXED;
 Quiz[260].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[261].MyGroup = GROUP_MIXED;
 Quiz[262].MyGroup = GROUP_MIXED;
 Quiz[263].MyGroup = GROUP_NT_NVC;
 Quiz[264].MyGroup = GROUP_ASPIE_SOCIAL;
 Quiz[265].MyGroup = GROUP_ENVIRONMENT;
 Quiz[266].MyGroup = GROUP_ENVIRONMENT;
 Quiz[267].MyGroup = GROUP_MIXED;
 Quiz[268].MyGroup = GROUP_NT_NVC;
 Quiz[269].MyGroup = GROUP_ASPIE_SOCIAL;

 Quiz[150].Text = "NEO - Worry about things";
 Quiz[151].Text = "NEO - Make friends easily";
 Quiz[152].Text = "NEO - Have a vivid imagination";
 Quiz[153].Text = "NEO - Trust others";
 Quiz[154].Text = "NEO - Complete tasks successfully";
 Quiz[155].Text = "NEO - Get angry easily";
 Quiz[156].Text = "NEO - Love large parties";
 Quiz[157].Text = "NEO - Believe in the importance of art";
 Quiz[158].Text = "NEO - Use others for my own ends";
 Quiz[159].Text = "NEO - Like to tidy up";
 Quiz[160].Text = "NEO - Often feel blue";
 Quiz[161].Text = "NEO - Take charge";
 Quiz[162].Text = "NEO - Experience my emotions intensely";
 Quiz[163].Text = "NEO - Love to help others";
 Quiz[164].Text = "NEO - Keep my promises";
 Quiz[165].Text = "NEO - Find it difficult to approach others";
 Quiz[166].Text = "NEO - Am always busy";
 Quiz[167].Text = "NEO - Prefer variety to routine";
 Quiz[168].Text = "NEO - Love a good fight";
 Quiz[169].Text = "NEO - Work hard";
 Quiz[170].Text = "NEO - Go on binges";
 Quiz[171].Text = "NEO - Love excitement";
 Quiz[172].Text = "NEO - Love to read challenging material";
 Quiz[173].Text = "NEO - Believe that I am better than others";
 Quiz[174].Text = "NEO - Am always prepared";
 Quiz[175].Text = "NEO - Panic easily";
 Quiz[176].Text = "NEO - Radiate joy";
 Quiz[177].Text = "NEO - Tend to vote for liberal political candidates";
 Quiz[178].Text = "NEO - Sympathize with the homeless";
 Quiz[179].Text = "NEO - Jump into things without thinking";
 Quiz[180].Text = "NEO - Fear for the worst";
 Quiz[181].Text = "NEO - Feel comfortable around people";
 Quiz[182].Text = "NEO - Enjoy wild flights of fantasy";
 Quiz[183].Text = "NEO - Believe that others have good intentions";
 Quiz[184].Text = "NEO - Excel in what I do";
 Quiz[185].Text = "NEO - Get irritated easily";
 Quiz[186].Text = "NEO - Talk to a lot of different people at parties";
 Quiz[187].Text = "NEO - See beauty in things that others might not notice";
 Quiz[188].Text = "NEO - Cheat to get ahead";
 Quiz[189].Text = "NEO - Often forget to put things back in their proper place";
 Quiz[190].Text = "NEO - Dislike myself";
 Quiz[191].Text = "NEO - Try to lead others";
 Quiz[192].Text = "NEO - Feel others' emotions";
 Quiz[193].Text = "NEO - Am concerned about others";
 Quiz[194].Text = "NEO - Tell the truth";
 Quiz[195].Text = "NEO - Am afraid to draw attention to myself";
 Quiz[196].Text = "NEO - Am always on the go";
 Quiz[197].Text = "NEO - Prefer to stick with things that I know";
 Quiz[198].Text = "NEO - Yell at people";
 Quiz[199].Text = "NEO - Do more than what's expected of me";
 Quiz[200].Text = "NEO - Rarely overindulge";
 Quiz[201].Text = "NEO - Seek adventure";
 Quiz[202].Text = "NEO - Avoid philosophical discussions";
 Quiz[203].Text = "NEO - Think highly of myself";
 Quiz[204].Text = "NEO - Carry out my plans";
 Quiz[205].Text = "NEO - Become overwhelmed by events";
 Quiz[206].Text = "NEO - Have a lot of fun";
 Quiz[207].Text = "NEO - Believe that there is no absolute right or wrong";
 Quiz[208].Text = "NEO - Feel sympathy for those who are worse off than myself";
 Quiz[209].Text = "NEO - Make rash decisions";
 Quiz[210].Text = "NEO - Am afraid of many things";
 Quiz[211].Text = "NEO - Avoid contacts with others";
 Quiz[212].Text = "NEO - Love to daydream";
 Quiz[213].Text = "NEO - Trust what people say";
 Quiz[214].Text = "NEO - Handle tasks smoothly";
 Quiz[215].Text = "NEO - Lose my temper";
 Quiz[216].Text = "NEO - Prefer to be alone";
 Quiz[217].Text = "NEO - Do not like poetry";
 Quiz[218].Text = "NEO - Take advantage of others";
 Quiz[219].Text = "NEO - Leave a mess in my room";
 Quiz[220].Text = "NEO - Am often down in the dumps";
 Quiz[221].Text = "NEO - Take control of things";
 Quiz[222].Text = "NEO - Rarely notice my emotional reactions";
 Quiz[223].Text = "NEO - Am indifferent to the feelings of others";
 Quiz[224].Text = "NEO - Break rules";
 Quiz[225].Text = "NEO - Only feel comfortable with friends";
 Quiz[226].Text = "NEO - Do a lot in my spare time";
 Quiz[227].Text = "NEO - Dislike changes";
 Quiz[228].Text = "NEO - Insult people";
 Quiz[229].Text = "NEO - Do just enough work to get by";
 Quiz[230].Text = "NEO - Easily resist temptations";
 Quiz[231].Text = "NEO - Enjoy being reckless";
 Quiz[232].Text = "NEO - Have difficulty understanding abstract ideas";
 Quiz[233].Text = "NEO - Have a high opinion of myself";
 Quiz[234].Text = "NEO - Waste my time";
 Quiz[235].Text = "NEO - Feel that I'm unable to deal with things";
 Quiz[236].Text = "NEO - Love life";
 Quiz[237].Text = "NEO - Tend to vote for conservative political candidates";
 Quiz[238].Text = "NEO - Am not interested in other people's problems";
 Quiz[239].Text = "NEO - Rush into things";
 Quiz[240].Text = "NEO - Get stressed out easily";
 Quiz[241].Text = "NEO - Keep others at a distance";
 Quiz[242].Text = "NEO - Like to get lost in thought";
 Quiz[243].Text = "NEO - Distrust people";
 Quiz[244].Text = "NEO - Know how to get things done";
 Quiz[245].Text = "NEO - Am not easily annoyed";
 Quiz[246].Text = "NEO - Avoid crowds";
 Quiz[247].Text = "NEO - Do not enjoy going to art museums";
 Quiz[248].Text = "NEO - Obstruct others' plans";
 Quiz[249].Text = "NEO - Leave my belongings around";
 Quiz[250].Text = "NEO - Feel comfortable with myself";
 Quiz[251].Text = "NEO - Wait for others to lead the way";
 Quiz[252].Text = "NEO - Don't understand people who get emotional";
 Quiz[253].Text = "NEO - Take no time for others";
 Quiz[254].Text = "NEO - Break my promises";
 Quiz[255].Text = "NEO - Am not bothered by difficult social situations";
 Quiz[256].Text = "NEO - Like to take it easy";
 Quiz[257].Text = "NEO - Am attached to conventional ways";
 Quiz[258].Text = "NEO - Get back at others";
 Quiz[259].Text = "NEO - Put little time and effort into my work";
 Quiz[260].Text = "NEO - Am able to control my cravings";
 Quiz[261].Text = "NEO - Act wild and crazy";
 Quiz[262].Text = "NEO - Am not interested in theoretical discussions";
 Quiz[263].Text = "NEO - Boast about my virtues";
 Quiz[264].Text = "NEO - Have difficulty starting tasks";
 Quiz[265].Text = "NEO - Remain calm under pressure";
 Quiz[266].Text = "NEO - Look at the bright side of life";
 Quiz[267].Text = "NEO - Believe that we should be tough on crime";
 Quiz[268].Text = "NEO - Try not to think about the needy";
 Quiz[269].Text = "NEO - Act without thinking";

}

/*##################  TQuizF2::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::LoadReferers()
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
#   Name       : TQuizF2::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF2::LoadPopulations()
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
				if (i < 150)
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
#   Name       : TQuizF2::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF2::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1)
{
  int i;
    
  for (i = 0; i < 150; i++)
	DefineCross(QuizF1, i, i);

  DefineGlobalId(150, 1209);
  DefineGlobalId(151, 1210);
  DefineGlobalId(152, 1211);
  DefineGlobalId(153, 1212);
  DefineGlobalId(154, 1213);
  DefineGlobalId(155, 1214);
  DefineGlobalId(156, 1215);
  DefineGlobalId(157, 1216);
  DefineGlobalId(158, 1217);
  DefineGlobalId(159, 1218);
  DefineGlobalId(160, 1219);
  DefineGlobalId(161, 1220);
  DefineGlobalId(162, 1221);
  DefineGlobalId(163, 1222);
  DefineGlobalId(164, 1223);
  DefineGlobalId(165, 1224);
  DefineGlobalId(166, 1225);
  DefineGlobalId(167, 1226);
  DefineGlobalId(168, 1227);
  DefineGlobalId(169, 1228);
  DefineGlobalId(170, 1229);
  DefineGlobalId(171, 1230);
  DefineGlobalId(172, 1231);
  DefineGlobalId(173, 1232);
  DefineGlobalId(174, 1233);
  DefineGlobalId(175, 1234);
  DefineGlobalId(176, 1235);
  DefineGlobalId(177, 1236);
  DefineGlobalId(178, 1237);
  DefineGlobalId(179, 1238);
  DefineGlobalId(180, 1239);
  DefineGlobalId(181, 1240);
  DefineGlobalId(182, 1241);
  DefineGlobalId(183, 1242);
  DefineGlobalId(184, 1243);
  DefineGlobalId(185, 1244);
  DefineGlobalId(186, 1245);
  DefineGlobalId(187, 1246);
  DefineGlobalId(188, 1247);
  DefineGlobalId(189, 1248);
  DefineGlobalId(190, 1249);
  DefineGlobalId(191, 1250);
  DefineGlobalId(192, 1251);
  DefineGlobalId(193, 1252);
  DefineGlobalId(194, 1253);
  DefineGlobalId(195, 1254);
  DefineGlobalId(196, 1255);
  DefineGlobalId(197, 1256);
  DefineGlobalId(198, 1257);
  DefineGlobalId(199, 1258);
  DefineGlobalId(200, 1259);
  DefineGlobalId(201, 1260);
  DefineGlobalId(202, 1261);
  DefineGlobalId(203, 1262);
  DefineGlobalId(204, 1263);
  DefineGlobalId(205, 1264);
  DefineGlobalId(206, 1265);
  DefineGlobalId(207, 1266);
  DefineGlobalId(208, 1267);
  DefineGlobalId(209, 1268);
  DefineGlobalId(210, 1269);
  DefineGlobalId(211, 1270);
  DefineGlobalId(212, 1271);
  DefineGlobalId(213, 1272);
  DefineGlobalId(214, 1273);
  DefineGlobalId(215, 1274);
  DefineGlobalId(216, 1275);
  DefineGlobalId(217, 1276);
  DefineGlobalId(218, 1277);
  DefineGlobalId(219, 1278);
  DefineGlobalId(220, 1279);
  DefineGlobalId(221, 1280);
  DefineGlobalId(222, 1281);
  DefineGlobalId(223, 1282);
  DefineGlobalId(224, 1283);
  DefineGlobalId(225, 1284);
  DefineGlobalId(226, 1285);
  DefineGlobalId(227, 1286);
  DefineGlobalId(228, 1287);
  DefineGlobalId(229, 1288);
  DefineGlobalId(230, 1289);
  DefineGlobalId(231, 1290);
  DefineGlobalId(232, 1291);
  DefineGlobalId(233, 1292);
  DefineGlobalId(234, 1293);
  DefineGlobalId(235, 1294);
  DefineGlobalId(236, 1295);
  DefineGlobalId(237, 1296);
  DefineGlobalId(238, 1297);
  DefineGlobalId(239, 1298);
  DefineGlobalId(240, 1299);
  DefineGlobalId(241, 1300);
  DefineGlobalId(242, 1301);
  DefineGlobalId(243, 1302);
  DefineGlobalId(244, 1303);
  DefineGlobalId(245, 1304);
  DefineGlobalId(246, 1305);
  DefineGlobalId(247, 1306);
  DefineGlobalId(248, 1307);
  DefineGlobalId(249, 1308);
  DefineGlobalId(250, 1309);
  DefineGlobalId(251, 1310);
  DefineGlobalId(252, 1311);
  DefineGlobalId(253, 1312);
  DefineGlobalId(254, 1313);
  DefineGlobalId(255, 1314);
  DefineGlobalId(256, 1315);
  DefineGlobalId(257, 1316);
  DefineGlobalId(258, 1317);
  DefineGlobalId(259, 1318);
  DefineGlobalId(260, 1319);
  DefineGlobalId(261, 1320);
  DefineGlobalId(262, 1321);
  DefineGlobalId(263, 1322);
  DefineGlobalId(264, 1323);
  DefineGlobalId(265, 1324);
  DefineGlobalId(266, 1325);
  DefineGlobalId(267, 1326);
  DefineGlobalId(268, 1327);
  DefineGlobalId(269, 1328);
}

/*##########################################################################
#
#   Name       : TQuizF2::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF2::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizF2::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::ExportExcelCase(const char *filename, int PcaType)
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
		if (IsPca(&Row, PcaType) && (Row.Un || Row.Ue || Row.Uo || Row.Ua || Row.Uc || Row.Sn))
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

					sprintf(str, "%d", ival);
					file.Write(str);
					if (i != GetQuizN() - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizF2::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::ExportExcelAspie(const char *filename)
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
		if (Row.Un)
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

				sprintf(str, "%d", ival);
				file.Write(str);
				if (i != N - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizF2::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::ExportExcelGroups(const char *filename)
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

/*##################  TQuizF2::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_ALL)
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
		sd = sqrt(rsum / ((long double)count - 1));

		dev = 1.96 * sd / sqrt(count);

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


/*##################  TQuizF2::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::WriteRace(const char *filename)
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

/*##################  TQuizF2::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::WriteRetest(const char *filename)
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

					 AsSd = sqrt(AsSum / index);
					NtSd = sqrt(NtSum / index);

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
							 QSd[q] = sqrt(sum / count);

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


/*##################  TQuizF2::ExportIPIP ##########################
*   Purpose....: Export IPIP cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::ExportIPIP(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < 270; i++)
	{
    	file.Write("\"");

//  	strncpy(str, Quiz[i].Text, 35);
//      str[35] = 0;
		sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != 270 - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
	    if (Row.Quiz[269])
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < 270; i++)
			{
    			ival = Row.Quiz[i];
	    		if (ival)
					ival--;
                    
				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != 270 - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizF2::ImportIPIP ##########################
*   Purpose....: Import MVSP loadings for IPIP  	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::ImportIPIP(const char *filename)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3, d4, d5, d6, d7, d8, d9, d10;
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

			if (sscanf(rowstr, "%d %Lf %Lf %Lf %Lf %Lf %Lf %Lf %Lf %Lf %Lf", &q, &d1, &d2, &d3, &d4, &d5, &d6, &d7, &d8, &d9, &d10) == 11)
			{
				q--;
				IpipLoadArr[q][0] = d1;
				IpipLoadArr[q][1] = d2;
				IpipLoadArr[q][2] = d3;
				IpipLoadArr[q][3] = d4;
				IpipLoadArr[q][4] = d5;
				IpipLoadArr[q][5] = d6;
				IpipLoadArr[q][6] = d7;
				IpipLoadArr[q][7] = d8;
				IpipLoadArr[q][8] = d9;
				IpipLoadArr[q][9] = d10;
			}
		}
	}
}

/*##################  TQuizF2::CalcIpipCongruence ##########################
*   Purpose....: Calculate congruence using IPIP loadings  	      	   	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::CalcIpipCongruence()
{
	 long double IpipArr[120][5] =
	 {
		{-0.13,  0.58,  0.12,  0.08, -0.02},
		{ 0.62, -0.10,  0.12,  0.21, -0.05},
		 { 0.15,  0.04, -0.08,  0.02,  0.46},
		{ 0.25, -0.18, -0.04,  0.41, -0.10},
		{ 0.04, -0.16,  0.55,  0.02,  0.07},
		{ 0.12,  0.56,  0.10, -0.32, -0.05},
		{ 0.64,  0.00, -0.10,  0.02, -0.09},
		{ 0.01,  0.04, -0.03,  0.19,  0.55},
		{-0.23, -0.12,  0.13,  0.45,  0.01},
		{-0.01,  0.10,  0.48,  0.12, -0.17},
		{-0.27,  0.57, -0.14, -0.09,  0.14},
		{ 0.43, -0.07,  0.41, -0.20,  0.15},
		{ 0.13,  0.49,  0.07,  0.16,  0.27},
		{ 0.23,  0.09,  0.13,  0.53,  0.12},
		{-0.03, -0.13,  0.32,  0.19,  0.09},
		{-0.54,  0.25, -0.18, -0.02, -0.03},
		{ 0.21,  0.03,  0.40,  0.06,  0.01},
		{ 0.27, -0.13, -0.19,  0.04,  0.27},
		{-0.29, -0.07,  0.07,  0.41, -0.09},
		{ 0.06, -0.03,  0.55,  0.12,  0.03},
    	{ 0.13,  0.31, -0.20, -0.14,  0.10},
    	{ 0.55,  0.02, -0.09, -0.01,  0.08},
    	{-0.04, -0.07,  0.11, -0.01,  0.54},
    	{-0.08,  0.08, -0.03,  0.49, -0.20},
    	{-0.03, -0.12,  0.54,  0.02, -0.01},
    	{-0.10,  0.64, -0.03,  0.08, -0.13},
    	{ 0.51, -0.11,  0.08,  0.36, -0.04},
   	    { 0.00,  0.03, -0.13,  0.11,  0.29},
    	{ 0.03,  0.16, -0.06,  0.43,  0.19},
    	{-0.33, -0.35,  0.40,  0.10,  0.05},
    	{-0.22,  0.58, -0.02, -0.08, -0.05},
    	{ 0.64, -0.24,  0.15,  0.21, -0.04},
    	{ 0.27,  0.12, -0.28, -0.01,  0.35},
    	{ 0.22, -0.14, -0.02,  0.49, -0.03},
    	{ 0.18, -0.18,  0.43, -0.05,  0.23},
    	{ 0.02,  0.57,  0.05, -0.34, -0.01},
	    { 0.67, -0.04,  0.03,  0.06,  0.00},
    	{ 0.11,  0.07, -0.01,  0.25,  0.46},
    	{-0.16, -0.06,  0.29,  0.41,  0.10},
    	{-0.08, -0.06,  0.48,  0.09, -0.11},
    	{-0.30,  0.53, -0.22, -0.06, -0.03},
    	{ 0.43, -0.07,  0.33, -0.21,  0.15},
    	{ 0.16,  0.19,  0.04,  0.44,  0.24},
    	{ 0.17,  0.14,  0.09,  0.57,  0.18},
    	{-0.12, -0.14,  0.35,  0.28,  0.06},
    	{-0.56,  0.21, -0.07,  0.15, -0.12},
    	{ 0.39,  0.02,  0.30,  0.02,  0.00},
    	{ 0.25, -0.31, -0.05,  0.00,  0.35},
    	{-0.20, -0.42,  0.04,  0.40,  0.09},
		{ 0.08, -0.04,  0.54,  0.08,  0.17},
    	{ 0.13,  0.25, -0.21, -0.07,  0.10},
    	{ 0.49, -0.05, -0.11, -0.07,  0.20},
    	{ 0.02, -0.09, -0.02, -0.01,  0.57},
    	{-0.27,  0.37, -0.22,  0.21, -0.18},
    	{ 0.16, -0.20,  0.58, -0.01,  0.07},
    	{-0.13,  0.55, -0.10,  0.11, -0.11},
    	{ 0.59, -0.19,  0.01,  0.17,  0.00},
    	{ 0.06, -0.06, -0.19, -0.01,  0.22},
    	{ 0.05,  0.17,  0.01,  0.49,  0.17},
    	{-0.27, -0.33,  0.35,  0.26,  0.04},
    	{-0.20,  0.59, -0.12,  0.08, -0.12},
    	{ 0.59, -0.19,  0.13,  0.25, -0.02},
    	{ 0.13,  0.21, -0.30,  0.07,  0.35},
    	{ 0.20, -0.13, -0.07,  0.45, -0.09},
    	{ 0.14, -0.29,  0.49,  0.05,  0.12},
    	{ 0.14,  0.60,  0.03, -0.33, -0.03},
    	{ 0.52, -0.09,  0.02,  0.21, -0.19},
    	{ 0.07,  0.10, -0.03,  0.25,  0.44},
    	{-0.14, -0.08,  0.20,  0.54,  0.04},
    	{-0.08, -0.06,  0.49,  0.07, -0.16},
    	{-0.29,  0.63, -0.18, -0.12,  0.10},
    	{ 0.39, -0.10,  0.47, -0.24,  0.17},
    	{ 0.07,  0.23,  0.11,  0.25,  0.27},
    	{ 0.06,  0.11,  0.08,  0.55,  0.23},
    	{-0.26, -0.01,  0.39,  0.42, -0.17},
    	{-0.46,  0.25, -0.11, -0.10,  0.00},
    	{ 0.25, -0.14,  0.36,  0.07,  0.12},
    	{ 0.30, -0.29, -0.05,  0.05,  0.28},
    	{-0.16, -0.21,  0.17,  0.55,  0.03},
		{ 0.00, -0.12,  0.58,  0.17,  0.10},
    	{ 0.15,  0.27, -0.32, -0.08,  0.00},
    	{ 0.41,  0.06, -0.36, -0.28,  0.14},
    	{ 0.00, -0.21,  0.04, -0.02,  0.58},
    	{-0.28,  0.37, -0.22,  0.22, -0.18},
    	{ 0.09, -0.22,  0.57,  0.13, -0.03},
    	{-0.22,  0.57, -0.27,  0.00, -0.09},
    	{ 0.40, -0.33,  0.18,  0.27,  0.09},
    	{ 0.00,  0.03, -0.20,  0.06,  0.25},
    	{ 0.14,  0.11,  0.02,  0.48,  0.17},
    	{-0.36, -0.32,  0.34,  0.18,  0.03},
    	{-0.10,  0.73, -0.02, -0.02, -0.06},
    	{ 0.52, -0.18,  0.06,  0.36, -0.16},
    	{ 0.00,  0.18, -0.26,  0.04,  0.45},
    	{ 0.23, -0.26, -0.03,  0.49, -0.07},
    	{ 0.21, -0.24,  0.51, -0.06,  0.16},
    	{ 0.00,  0.55,  0.05, -0.30, -0.01},
    	{ 0.63, -0.13, -0.04,  0.10, -0.08},
    	{ 0.00,  0.01,  0.03,  0.22,  0.49},
    	{-0.12, -0.13,  0.20,  0.41,  0.14},
    	{-0.10, -0.07,  0.46,  0.07, -0.14},
    	{-0.31,  0.52, -0.23, -0.04, -0.09},
    	{ 0.39, -0.26,  0.35, -0.15,  0.24},
    	{ 0.14,  0.29,  0.03,  0.43,  0.17},
    	{ 0.21,  0.01,  0.11,  0.47,  0.13},
    	{-0.05, -0.18,  0.34,  0.23,  0.09},
    	{-0.44,  0.32, -0.06,  0.06, -0.04},
    	{ 0.01,  0.03,  0.35, -0.06,  0.01},
    	{ 0.19, -0.17, -0.19, -0.04,  0.39},
    	{-0.14, -0.16,  0.08,  0.41,  0.09},
		{ 0.00, -0.11,  0.52,  0.15,  0.14},
    	{ 0.04,  0.33, -0.23, -0.03, -0.02},
    	{ 0.60,  0.09, -0.28, -0.12,  0.07},
    	{-0.01, -0.10, -0.01,  0.01,  0.59},
    	{-0.27, -0.05,  0.02,  0.30,  0.06},
    	{ 0.10, -0.21,  0.59,  0.05,  0.00},
    	{-0.11,  0.53, -0.13,  0.05, -0.21},
    	{ 0.37, -0.45,  0.12,  0.32,  0.04},
    	{-0.03, -0.05, -0.29,  0.05,  0.22},
    	{ 0.07,  0.03,  0.08,  0.39,  0.18},
    	{-0.34, -0.34,  0.41,  0.18,  0.09}
    };

    int factor;
	int axis;
	int q;
	long double rsum;
	long double asum[2];
	long double x;
	long double y;
    long double xsum;
    long double ysum;	
    long double sqsum;
    int val;
    int count;

	for (factor = 0; factor < 5; factor++)
    {
    	for (axis = 0; axis < 10; axis++)
        {
        	xsum = 0;
        	ysum = 0;

			rsum = 0;
        
			for (q = 0; q < 120; q++)
			{
				x = IpipLoadArr[150 + q][axis];
				y = IpipArr[q][factor];

				rsum += x * y;
				xsum += x * x;
				ysum += y * y;
			}

			if (rsum < 0)
			    rsum = -rsum;

			sqsum = xsum * ysum;

			if (sqsum > 0.0)
				  sqsum = sqrt(xsum * ysum);

		    if (sqsum > 0.0)
				IpipCon[factor][axis] = rsum / sqsum;
			else
				 IpipCon[factor][axis] = 0.0;

		}
	 }


	count = GetQuizN();

	xsum = 0;
	ysum = 0;

	for (axis = 0; axis < 2; axis++)
    {
        asum[axis] = 0;
        
    	for (q = 0; q < count; q++)
	    {
	        x = Quiz[q].Pca[axis];
	        y = IpipLoadArr[q][axis];

            asum[axis] += x * y;
            xsum += x * x;
            ysum += y * y;
        }

        if (asum[axis] < 0)
            asum[axis] = -asum[axis];
	}

    sqsum = xsum * ysum;

    if (sqsum > 0.0)
    	sqsum = sqrt(xsum * ysum);
		
    if (sqsum > 0.0)
        IpipPcaCon = (asum[0] + asum[1]) / sqsum;
    else
		IpipPcaCon = 0;
}

/*##################  TQuizF2::WriteIPIP ##########################
*   Purpose....: Write IPIP NEO personality test report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF2::WriteIPIP(const char *filename)
{
	int Count;
	long double AsSum;
	long double NtSum;
	long double DiffSum;
	long double GrpSum[ACTIVE_GROUP_COUNT];
	long double NSum;
	long double ESum;
	long double OSum;
	long double ASum;
	long double CSum;
	long double AsMean;
	long double NtMean;
	long double DiffMean;
	long double GrpMean[ACTIVE_GROUP_COUNT];
	long double NMean;
	long double EMean;
	long double OMean;
	long double AMean;
	long double CMean;
	long double AsSd;
	long double NtSd;
	long double DiffSd;
	long double GrpSd[ACTIVE_GROUP_COUNT];
	long double NSd;
	long double ESd;
	long double OSd;
	long double ASd;
	long double CSd;
	long double AsCorr;
	long double NtCorr;
	long double DiffCorr;
	long double val;
	long double zx;
	long double zy;
	int grp;
	long double NGrpCorr[ACTIVE_GROUP_COUNT];
	long double EGrpCorr[ACTIVE_GROUP_COUNT];
	long double OGrpCorr[ACTIVE_GROUP_COUNT];
	long double AGrpCorr[ACTIVE_GROUP_COUNT];
	long double CGrpCorr[ACTIVE_GROUP_COUNT];
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	int factor;
	int axis;
	TFile file(filename, 0);

	ExportIPIP("pca\\ipip.dat");
	ImportIPIP("pca\\ipip.txt");
	CalcIpipCongruence();

	Count = 0;
	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

    for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
        GrpSum[grp] = 0;
	
	NSum = 0;
	ESum = 0;
	OSum = 0;
	ASum = 0;
	CSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
        {
			Count++;
			AsSum += Row.AsResult;
			NtSum += Row.NtResult;
			DiffSum += Row.AsResult - Row.NtResult;

            for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
                GrpSum[grp] += Row.GroupResult[grp];
			
			NSum += Row.Un;
			ESum += Row.Ue;
			OSum += Row.Uo;
			ASum += Row.Ua;
			CSum += Row.Uc;
	    }
	}

	AsMean = AsSum / Count;
	NtMean = NtSum / Count;
	DiffMean = DiffSum / Count;

    for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
        GrpMean[grp] = GrpSum[grp] / Count;
    
	NMean = NSum / Count;
	EMean = ESum / Count;
	OMean = OSum / Count;
	AMean = ASum / Count;
	CMean = CSum / Count;

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

    for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
        GrpSum[grp] = 0;
	
	NSum = 0;
	ESum = 0;
	OSum = 0;
	ASum = 0;
	CSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
        {
            val = (long double)Row.AsResult - AsMean;
   			AsSum += val * val;
   			
            val = (long double)Row.NtResult - NtMean;
			NtSum += val * val;
			
            val = (long double)(Row.AsResult - Row.NtResult) - DiffMean;
			DiffSum += val * val;

            for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
            {
                val = (long double)Row.GroupResult[grp] - GrpMean[grp];
                GrpSum[grp] += val * val;
            }			

            val = (long double)Row.Un - NMean;
			NSum += val * val;

            val = (long double)Row.Ue - EMean;
			ESum += val * val;

            val = (long double)Row.Uo - OMean;
			OSum += val * val;

            val = (long double)Row.Ua - AMean;
			ASum += val * val;

            val = (long double)Row.Uc - CMean;
			CSum += val * val;
	    }
	}

	AsSd = sqrt(AsSum / (Count - 1));
	NtSd = sqrt(NtSum / (Count - 1));
	DiffSd = sqrt(DiffSum / (Count - 1));

    for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
        GrpSd[grp] = sqrt(GrpSum[grp] / (Count - 1));

	NSd = sqrt(NSum / (Count - 1));
	ESd = sqrt(ESum / (Count - 1));
	OSd = sqrt(OSum / (Count - 1));
	ASd = sqrt(ASum / (Count - 1));
	CSd = sqrt(CSum / (Count - 1));

	file.Write("<h2>Big-five correlations with Aspie-quiz scores</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Factor");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	file.Write("Aspie score");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	file.Write("NT score");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	file.Write("Score difference");
	WriteFieldFooter(file);

	file.Write("</tr>");

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
        {
            zx = ((long double)Row.Un - NMean) / NSd;

            zy = ((long double)Row.AsResult - AsMean) / AsSd;
            AsSum += zx * zy;
        
            zy = ((long double)Row.NtResult - NtMean) / NtSd;
            NtSum += zx * zy;

            zy = ((long double)(Row.AsResult - Row.NtResult) - DiffMean) / DiffSd;
            DiffSum += zx * zy;
	    }
	}

    AsCorr = AsSum / (Count - 1);
    NtCorr = NtSum / (Count - 1);
    DiffCorr = DiffSum / (Count - 1);

	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Neuroticisn");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", AsCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", NtCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", DiffCorr);
	file.Write(str);
	WriteFieldFooter(file);

	file.Write("</tr>");

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
        {
            zx = ((long double)Row.Ue - EMean) / ESd;

            zy = ((long double)Row.AsResult - AsMean) / AsSd;
            AsSum += zx * zy;
        
            zy = ((long double)Row.NtResult - NtMean) / NtSd;
            NtSum += zx * zy;

            zy = ((long double)(Row.AsResult - Row.NtResult) - DiffMean) / DiffSd;
            DiffSum += zx * zy;
	    }
	}

    AsCorr = AsSum / (Count - 1);
    NtCorr = NtSum / (Count - 1);
    DiffCorr = DiffSum / (Count - 1);
	
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Extroversion");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", AsCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", NtCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", DiffCorr);
	file.Write(str);
	WriteFieldFooter(file);

	file.Write("</tr>");

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
        {
            zx = ((long double)Row.Uo - OMean) / OSd;

            zy = ((long double)Row.AsResult - AsMean) / AsSd;
            AsSum += zx * zy;
        
            zy = ((long double)Row.NtResult - NtMean) / NtSd;
            NtSum += zx * zy;

            zy = ((long double)(Row.AsResult - Row.NtResult) - DiffMean) / DiffSd;
            DiffSum += zx * zy;
	    }
	}

    AsCorr = AsSum / (Count - 1);
    NtCorr = NtSum / (Count - 1);
    DiffCorr = DiffSum / (Count - 1);
	
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Openness");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", AsCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", NtCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", DiffCorr);
	file.Write(str);
	WriteFieldFooter(file);

	file.Write("</tr>");

	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
        {
            zx = ((long double)Row.Ua - AMean) / ASd;

            zy = ((long double)Row.AsResult - AsMean) / AsSd;
            AsSum += zx * zy;
        
            zy = ((long double)Row.NtResult - NtMean) / NtSd;
            NtSum += zx * zy;

            zy = ((long double)(Row.AsResult - Row.NtResult) - DiffMean) / DiffSd;
            DiffSum += zx * zy;
	    }
	}

    AsCorr = AsSum / (Count - 1);
    NtCorr = NtSum / (Count - 1);
    DiffCorr = DiffSum / (Count - 1);
	
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Agreeableness");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", AsCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", NtCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", DiffCorr);
	file.Write(str);
	WriteFieldFooter(file);

	file.Write("</tr>");
	
	AsSum = 0;
	NtSum = 0;
	DiffSum = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
        {
            zx = ((long double)Row.Uc - CMean) / CSd;

            zy = ((long double)Row.AsResult - AsMean) / AsSd;
            AsSum += zx * zy;
        
            zy = ((long double)Row.NtResult - NtMean) / NtSd;
            NtSum += zx * zy;

            zy = ((long double)(Row.AsResult - Row.NtResult) - DiffMean) / DiffSd;
            DiffSum += zx * zy;
	    }
	}

    AsCorr = AsSum / (Count - 1);
    NtCorr = NtSum / (Count - 1);
    DiffCorr = DiffSum / (Count - 1);
	
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Conscientousness");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", AsCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", NtCorr);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 25);
	sprintf(str, "%5.2Lf\r\n", DiffCorr);
	file.Write(str);
	WriteFieldFooter(file);

	file.Write("</tr>");
	file.Write("</table>");


	file.Write("<h2>Big-five correlations with Aspie-quiz groups</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 20);
	file.Write("Group");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 16);
	file.Write("Neuroticism");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 16);
	file.Write("Extroversion");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 16);
	file.Write("Openness");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 16);
	file.Write("Agreeableness");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 16);
	file.Write("Conscientousness");
	WriteFieldFooter(file);

	file.Write("</tr>");

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		GrpSum[grp] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
		{
			zx = ((long double)Row.Un - NMean) / NSd;

			for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
			{
				if (GrpMean[grp] > 0 && GrpSd[grp] > 0)
				{
					zy = ((long double)Row.GroupResult[grp] - GrpMean[grp]) / GrpSd[grp];
					GrpSum[grp] += zx * zy;
				}
			}
		}
	}

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		NGrpCorr[grp] = GrpSum[grp] / (Count - 1);

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		GrpSum[grp] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
		{
			zx = ((long double)Row.Ue - EMean) / ESd;

			for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
			{
				if (GrpMean[grp] > 0 && GrpSd[grp] > 0)
				{
					zy = ((long double)Row.GroupResult[grp] - GrpMean[grp]) / GrpSd[grp];
					GrpSum[grp] += zx * zy;
				}
			}
		}
	}

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		EGrpCorr[grp] = GrpSum[grp] / (Count - 1);

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		GrpSum[grp] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
		{
			zx = ((long double)Row.Uo - OMean) / OSd;

			for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
			{
				if (GrpMean[grp] > 0 && GrpSd[grp] > 0)
				{
					zy = ((long double)Row.GroupResult[grp] - GrpMean[grp]) / GrpSd[grp];
					GrpSum[grp] += zx * zy;
				}
			}
		}
	}

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		OGrpCorr[grp] = GrpSum[grp] / (Count - 1);

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		GrpSum[grp] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
		{
			zx = ((long double)Row.Ua - AMean) / ASd;

			for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
			{
				if (GrpMean[grp] > 0 && GrpSd[grp] > 0)
				{
					zy = ((long double)Row.GroupResult[grp] - GrpMean[grp]) / GrpSd[grp];
					GrpSum[grp] += zx * zy;
				}
			}
		}
	}

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		AGrpCorr[grp] = GrpSum[grp] / (Count - 1);

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
		GrpSum[grp] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Ua)
		{
			zx = ((long double)Row.Uc - CMean) / CSd;

			for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
			{
				if (GrpMean[grp] > 0 && GrpSd[grp] > 0)
				{
					zy = ((long double)Row.GroupResult[grp] - GrpMean[grp]) / GrpSd[grp];
					GrpSum[grp] += zx * zy;
				}
            }
	    }
	}

	for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
        CGrpCorr[grp] = GrpSum[grp] / (Count - 1);

    for (grp = 0; grp < ACTIVE_GROUP_COUNT; grp++)
    {
        if (GrpMean[grp] > 0 && GrpSd[grp] > 0)
        {

        	file.Write("<tr style='height:24.75pt'>");

        	WriteCenteredFieldHeader(file, 20);
	        file.Write(Group[grp].PosName);
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 16);
        	sprintf(str, "%5.2Lf\r\n", NGrpCorr[grp]);
        	file.Write(str);
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 16);
        	sprintf(str, "%5.2Lf\r\n", EGrpCorr[grp]);
        	file.Write(str);
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 16);
        	sprintf(str, "%5.2Lf\r\n", OGrpCorr[grp]);
        	file.Write(str);
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 16);
        	sprintf(str, "%5.2Lf\r\n", AGrpCorr[grp]);
        	file.Write(str);
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 16);
        	sprintf(str, "%5.2Lf\r\n", CGrpCorr[grp]);
        	file.Write(str);
        	WriteFieldFooter(file);

        	file.Write("</tr>");
        }
    }

    file.Write("</table>");



	file.Write("<h2>IPIP congruence</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 15);
	file.Write("Axis");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 15);
	file.Write("Extrovert");
	WriteFieldFooter(file);
	
	WriteCenteredFieldHeader(file, 15);
	file.Write("Neuroticism");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 15);
	file.Write("Conscientousness");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 15);
	file.Write("Agreeableness");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 15);
	file.Write("Openness");
	WriteFieldFooter(file);

	file.Write("</tr>");

    for (axis = 0; axis < 10; axis++)
    {

	    file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 15);

        switch (axis)
        {
            case 0:
                file.Write("Neurodiversity");
                break;

            case 1:
                file.Write("Neutotypical");
                break;

            case 2:
                file.Write("G");
                break;

            default:
                sprintf(str, "%d\r\n", axis + 1);
                file.Write(str);
        }

        WriteFieldFooter(file);	        

	    for (factor = 0; factor < 5; factor++)
	    {
	        val = IpipCon[factor][axis];
        	WriteCenteredFieldHeader(file, 15);
        	sprintf(str, "%5.2Lf\r\n", val);
        	file.Write(str);
        	WriteFieldFooter(file);	        
	    }

    	file.Write("</tr>");
    }

    file.Write("</table>");

    file.Write("Aspie-quiz factor congruence: ");
	val = IpipPcaCon;
    sprintf(str, "%5.2Lf\r\n", val);
    file.Write(str);
    
}

