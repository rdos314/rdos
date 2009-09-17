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
# quizf6.cpp
# Quiz final version 6 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizf6.h"
#include "file.h"
#include "quizdbf6.h"

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
#   Name       : TQuizF6::TQuizF6
#
#   Purpose....: Constructor for TQuizF6
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizF6::TQuizF6(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5)
  : TQuizFinal(224, QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1, QuizN2, QuizN3, QuizN4),
	FDataFile(FileName)
{
	DefineCross(32, QuizFI);
	DefineCross(33, QuizF1);
	DefineCross(34, QuizF2);
	DefineCross(35, QuizF3);
	DefineCross(36, QuizF4);
	DefineCross(37, QuizF5);

	SetupTexts();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1, QuizN2, QuizN3, QuizN4, QuizFI, QuizF1, QuizF2, QuizF3, QuizF4, QuizF5);

	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizF6::~TQuizF6
#
#   Purpose....: Destructor for TQuizF6
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizF6::~TQuizF6()
{
}

/*##################  TQuizF6::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizF6::GetCatCount(int Question)
{
	return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizF6::GetQuizN()
{
	return 224;
}

/*##########################################################################
#
#   Name       : TQuizF6::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF6::WriteName(TFile &File)
{
	 File.Write("F6");
}

/*##########################################################################
#
#   Name       : TQuizF6::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF6::WriteLongName(TFile &File)
{
	 File.Write("final version 6");
}

/*##########################################################################
#
#   Name       : TQuizF6::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF6::SetupTexts()
{
  Quiz[150].MyGroup = GROUP_MIXED;
  Quiz[151].MyGroup = GROUP_NT_SOCIAL;
  Quiz[152].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[153].MyGroup = GROUP_MIXED;
  Quiz[154].MyGroup = GROUP_ASPIE_NVC;
  Quiz[155].MyGroup = GROUP_NT_SOCIAL;
  Quiz[156].MyGroup = GROUP_ASPIE_NVC;
  Quiz[157].MyGroup = GROUP_NT_SOCIAL;
  Quiz[158].MyGroup = GROUP_MIXED;
  Quiz[159].MyGroup = GROUP_MIXED;
  Quiz[160].MyGroup = GROUP_NT_SOCIAL;
  Quiz[161].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[162].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[163].MyGroup = GROUP_ASPIE_NVC;
  Quiz[164].MyGroup = GROUP_NT_SOCIAL;
  Quiz[165].MyGroup = GROUP_ASPIE_NVC;
  Quiz[166].MyGroup = GROUP_NT_SOCIAL;
  Quiz[167].MyGroup = GROUP_MIXED;
  Quiz[168].MyGroup = GROUP_MIXED;
  Quiz[169].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[170].MyGroup = GROUP_MIXED;
  Quiz[171].MyGroup = GROUP_MIXED;
  Quiz[172].MyGroup = GROUP_ASPIE_NVC;
  Quiz[173].MyGroup = GROUP_NT_SOCIAL;
  Quiz[174].MyGroup = GROUP_NT_TALENT;
  Quiz[175].MyGroup = GROUP_NT_SOCIAL;
  Quiz[176].MyGroup = GROUP_MIXED;
  Quiz[177].MyGroup = GROUP_MIXED;
  Quiz[178].MyGroup = GROUP_NT_SOCIAL;
  Quiz[179].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[180].MyGroup = GROUP_MIXED;
  Quiz[181].MyGroup = GROUP_MIXED;
  Quiz[182].MyGroup = GROUP_NT_SOCIAL;
  Quiz[183].MyGroup = GROUP_ASPIE_NVC;
  Quiz[184].MyGroup = GROUP_NT_NVC;
  Quiz[185].MyGroup = GROUP_NT_SOCIAL;
  Quiz[186].MyGroup = GROUP_MIXED;
  Quiz[187].MyGroup = GROUP_NT_SOCIAL;
  Quiz[188].MyGroup = GROUP_MIXED;
  Quiz[189].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[190].MyGroup = GROUP_NT_SOCIAL;
  Quiz[191].MyGroup = GROUP_MIXED;
  Quiz[192].MyGroup = GROUP_NT_NVC;
  Quiz[193].MyGroup = GROUP_MIXED;
  Quiz[194].MyGroup = GROUP_MIXED;
  Quiz[195].MyGroup = GROUP_NT_SOCIAL;
  Quiz[196].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[197].MyGroup = GROUP_MIXED;
  Quiz[198].MyGroup = GROUP_NT_SOCIAL;
  Quiz[199].MyGroup = GROUP_ASPIE_NVC;
  Quiz[200].MyGroup = GROUP_NT_SOCIAL;
  Quiz[201].MyGroup = GROUP_NT_SOCIAL;
  Quiz[202].MyGroup = GROUP_MIXED;
  Quiz[203].MyGroup = GROUP_NT_SOCIAL;
  Quiz[204].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[205].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[206].MyGroup = GROUP_NT_SOCIAL;
  Quiz[207].MyGroup = GROUP_ASPIE_NVC;
  Quiz[208].MyGroup = GROUP_MIXED;
  Quiz[209].MyGroup = GROUP_MIXED;
  Quiz[210].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[211].MyGroup = GROUP_NT_SOCIAL;
  Quiz[212].MyGroup = GROUP_MIXED;
  Quiz[213].MyGroup = GROUP_MIXED;
  Quiz[214].MyGroup = GROUP_MIXED;
  Quiz[215].MyGroup = GROUP_NT_SOCIAL;
  Quiz[216].MyGroup = GROUP_NT_SOCIAL;
  Quiz[217].MyGroup = GROUP_NT_SOCIAL;
  Quiz[218].MyGroup = GROUP_ASPIE_NVC;
  Quiz[219].MyGroup = GROUP_ASPIE_NVC;
  Quiz[220].MyGroup = GROUP_NT_SOCIAL;
  Quiz[221].MyGroup = GROUP_ASPIE_NVC;
  Quiz[222].MyGroup = GROUP_NT_SOCIAL;
  Quiz[223].MyGroup = GROUP_MIXED;

  Quiz[150].Text = "SPQ - Do you sometimes feel that things you see on the TV or read in the newspaper have a special meaning for you?";
  Quiz[151].Text = "SPQ - I sometimes avoid going to places where there will be many people because I will get anxious.";
  Quiz[152].Text = "SPQ - Have you had experiences with the supernatural?";
  Quiz[153].Text = "SPQ - Have you often mistaken objects or shadows for people, or noises for voices?";
  Quiz[154].Text = "SPQ - Other people see me as slightly eccentric (odd).";
  Quiz[155].Text = "SPQ - I have little interest in getting to know other people.";
  Quiz[156].Text = "SPQ - People sometimes find it hard to understand what I am saying.";
  Quiz[157].Text = "SPQ - People sometimes find me aloof and distant.";
  Quiz[158].Text = "SPQ - I am sure I am being talked about behind my back.";
  Quiz[159].Text = "SPQ - I am aware that people notice me when I go out for a meal or to see a film.";
  Quiz[160].Text = "SPQ - I get very nervous when I have to make polite conversation.";
  Quiz[161].Text = "SPQ - Do you believe in telepathy (mind-reading)?";
  Quiz[162].Text = "SPQ - Have you ever had the sense that some person or force is around you, even though you cannot see anyone?";
  Quiz[163].Text = "SPQ - People sometimes comment on my unusual mannerisms and habits.";
  Quiz[164].Text = "SPQ - I prefer to keep to myself.";
  Quiz[165].Text = "SPQ - I sometimes jump quickly from one topic to another when speaking.";
  Quiz[166].Text = "SPQ - I am poor at expressing my true feelings by the way I talk and look.";
  Quiz[167].Text = "SPQ - Do you often feel that other people have got it in for you?";
  Quiz[168].Text = "SPQ - Do some people drop hints about you or say things with a double meaning?";
  Quiz[169].Text = "SPQ - Do you ever get nervous when someone is walking behind you?";
  Quiz[170].Text = "SPQ - Are you sometimes sure that other people can tell what you are thinking?";
  Quiz[171].Text = "SPQ - When you look at a person, or yourself in a mirror, have you ever seen the face change right before your eyes?";
  Quiz[172].Text = "SPQ - Sometimes other people think that I am a little strange.";
  Quiz[173].Text = "SPQ - I am mostly quiet when with other people.";
  Quiz[174].Text = "SPQ - I sometimes forget what I am trying to say.";
  Quiz[175].Text = "SPQ - I rarely laugh and smile.";
  Quiz[176].Text = "SPQ - Do you sometimes get concerned that friends or co-workers are not really loyal or trustworthy?";
  Quiz[177].Text = "SPQ - Have you ever noticed a common event or object that seemed to be a special sign for you?";
  Quiz[178].Text = "SPQ - I get anxious when meeting people for the first time.";
  Quiz[179].Text = "SPQ - Do you believe in clairvoyancy (psychic forces, fortune telling)?";
  Quiz[180].Text = "SPQ - I often hear a voice speaking my thoughts aloud.";
  Quiz[181].Text = "SPQ - Some people think that I am a very bizarre person.";
  Quiz[182].Text = "SPQ - I find it hard to be emotionally close to other people.";
  Quiz[183].Text = "SPQ - I often ramble on too much when speaking.";
  Quiz[184].Text = "SPQ - My \"non-verbal\" communication (smiling and nodding during a Y N conversation) is poor.";
  Quiz[185].Text = "SPQ - I feel I have to be on my guard even with friends.";
  Quiz[186].Text = "SPQ - Do you sometimes see special meanings in advertisements, shop windows, or in the way things are arranged around you?";
  Quiz[187].Text = "SPQ - Do you often feel nervous when you are in a group of unfamiliar people?";
  Quiz[188].Text = "SPQ - Can other people feel your feelings when they are not there?";
  Quiz[189].Text = "SPQ - Have you ever seen things invisible to other people?";
  Quiz[190].Text = "SPQ - Do you feel that there is no-one you are really close to outside of your immediate family, or people you can confide in or talk to about personal problems?";
  Quiz[191].Text = "SPQ - Some people find me a bit vague and elusive during a conversation.";
  Quiz[192].Text = "SPQ - I am poor at returning social courtesies and gestures.";
  Quiz[193].Text = "SPQ - Do you often pick up hidden threats or put-downs from what people say or do?";
  Quiz[194].Text = "SPQ - When shopping do you get the feeling that other people are taking notice of you?";
  Quiz[195].Text = "SPQ - I feel very uncomfortable in social situations involving unfamiliar people.";
  Quiz[196].Text = "SPQ - Have you had experiences with astrology, seeing the future, UFOs, ESP or a sixth sense?";
  Quiz[197].Text = "SPQ - Do everyday things seem unusually large or small?";
  Quiz[198].Text = "SPQ - Writing letters to friends is more trouble than it is worth.";
  Quiz[199].Text = "SPQ - I sometimes use words in unusual ways.";
  Quiz[200].Text = "SPQ - I tend to avoid eye contact when conversing with others.";
  Quiz[201].Text = "SPQ - Have you found that it is best not to let other people know too much about you?";
  Quiz[202].Text = "SPQ - When you see people talking to each other, do you often wonder if they are talking about you?";
  Quiz[203].Text = "SPQ - I would feel very anxious if I had to give a speech in front of a large group of people.";
  Quiz[204].Text = "SPQ - Have you ever felt that you are communicating with another person telepathically (by mind-reading)?";
  Quiz[205].Text = "SPQ - Does your sense of smell sometimes become unusually strong?";
  Quiz[206].Text = "SPQ - I tend to keep in the background on social occasions.";
  Quiz[207].Text = "SPQ - Do you tend to wander off the topic when having a conversation.";
  Quiz[208].Text = "SPQ - I often feel that others have it in for me.";
  Quiz[209].Text = "SPQ - Do you sometimes feel that other people are watching you?";
  Quiz[210].Text = "SPQ - Do you ever suddenly feel distracted by distant sounds that you are not normally aware of?";
  Quiz[211].Text = "SPQ - I attach little importance to having close friends.";
  Quiz[212].Text = "SPQ - Do you sometimes feel that people are talking about you?";
  Quiz[213].Text = "SPQ - Are your thoughts sometimes so strong that you can almost hear them?";
  Quiz[214].Text = "SPQ - Do you often have to keep an eye out to stop people from taking advantage of you?";
  Quiz[215].Text = "SPQ - Do you feel that you are unable to get \"close\" to people?";
  Quiz[216].Text = "SPQ - I am an odd, unusual person.";
  Quiz[217].Text = "SPQ - I do not have an expressive and lively way of speaking.";
  Quiz[218].Text = "SPQ - I find it hard to communicate clearly what I want to say to people.";
  Quiz[219].Text = "SPQ - I have some eccentric (odd) habits.";
  Quiz[220].Text = "SPQ - I feel very uneasy talking to people I do not know well.";
  Quiz[221].Text = "SPQ - People occasionally comment that my conversation is confusing.";
  Quiz[222].Text = "SPQ - I tend to keep my feelings to myself.";
  Quiz[223].Text = "SPQ - People sometimes stare at me because of my odd appearance.";
}

/*##################  TQuizF6::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF6::LoadReferers()
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
#   Name       : TQuizF6::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF6::LoadPopulations()
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
				if (i < 151)
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
#   Name       : TQuizF6::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF6::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5)
{
    int i;

    for (i = 0; i < 150; i++)
  	    DefineCross(QuizF5, i, i);

    for (i = 0; i < 74; i++)
        DefineCross(QuizS3, 150 + i, 136 + i);
}

/*##########################################################################
#
#   Name       : TQuizF6::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizF6::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TQuizF6::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF6::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TQuizF6::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF6::ExportExcelAspie(const char *filename)
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

/*##################  TQuizF6::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF6::ExportExcelGroups(const char *filename)
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

/*##################  TQuizF6::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF6::ImportMvsp(const char *filename, int PcaType)
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


/*##################  TQuizF6::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF6::WriteRace(const char *filename)
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

/*##################  TQuizF6::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizF6::WriteRetest(const char *filename)
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
