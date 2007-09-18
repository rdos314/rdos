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
# spg.cpp
# Quiz SPQ-A class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "spq.h"
#include "file.h"
#include "quizdbs3.h"

#define CI	1

#define MAX_IN_ROW		4096
#define MAX_USERS       500

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSpq::TSpq
#
#   Purpose....: Constructor for TSpq
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSpq::TSpq(const char *FileName)
  : TSubQuiz(74),
	FDataFile(FileName)
{
    int i;

    for (i = 0; i < N; i++)
        Quiz[i].Pca[0] = 1;

	SetupTexts();
	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	LoadPopulations();
}

/*##########################################################################
#
#   Name       : TSpq::~TSpq
#
#   Purpose....: Destructor for TSpq
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSpq::~TSpq()
{
}

/*##################  TSpq::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSpq::GetCatCount(int Question)
{
    return 2;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSpq::GetQuizN()
{
	return 74;
}

/*##########################################################################
#
#   Name       : TSpq::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSpq::WriteName(TFile &File)
{
	 File.Write("SPQ-A");
}

/*##########################################################################
#
#   Name       : TSpq::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSpq::SetupTexts()
{
  Quiz[0].Text = "Do you sometimes feel that things you see on the TV or read in the newspaper have a special meaning for you?";          
  Quiz[1].Text = "I sometimes avoid going to places where there will be many people because I will get anxious.";
  Quiz[2].Text = "Have you had experiences with the supernatural?";
  Quiz[3].Text = "Have you often mistaken objects or shadows for people, or noises for voices?";
  Quiz[4].Text = "Other people see me as slightly eccentric (odd).";
  Quiz[5].Text = "I have little interest in getting to know other people.";
  Quiz[6].Text = "People sometimes find it hard to understand what I am saying.";
  Quiz[7].Text = "People sometimes find me aloof and distant.";
  Quiz[8].Text = "I am sure I am being talked about behind my back.";
  Quiz[9].Text = "I am aware that people notice me when I go out for a meal or to see a film.";
  Quiz[10].Text = "I get very nervous when I have to make polite conversation.";
  Quiz[11].Text = "Do you believe in telepathy (mind-reading)?";
  Quiz[12].Text = "Have you ever had the sense that some person or force is around you, even though you cannot see anyone?";
  Quiz[13].Text = "People sometimes comment on my unusual mannerisms and habits.";
  Quiz[14].Text = "I prefer to keep to myself.";
  Quiz[15].Text = "I sometimes jump quickly from one topic to another when speaking.";
  Quiz[16].Text = "I am poor at expressing my true feelings by the way I talk and look.";
  Quiz[17].Text = "Do you often feel that other people have got it in for you?";
  Quiz[18].Text = "Do some people drop hints about you or say things with a double meaning?";
  Quiz[19].Text = "Do you ever get nervous when someone is walking behind you?";
  Quiz[20].Text = "Are you sometimes sure that other people can tell what you are thinking?";
  Quiz[21].Text = "When you look at a person, or yourself in a mirror, have you ever seen the face change right before your eyes?";
  Quiz[22].Text = "Sometimes other people think that I am a little strange.";
  Quiz[23].Text = "I am mostly quiet when with other people.";
  Quiz[24].Text = "I sometimes forget what I am trying to say.";
  Quiz[25].Text = "I rarely laugh and smile.";
  Quiz[26].Text = "Do you sometimes get concerned that friends or co-workers are not really loyal or trustworthy?";
  Quiz[27].Text = "Have you ever noticed a common event or object that seemed to be a special sign for you?";
  Quiz[28].Text = "I get anxious when meeting people for the first time.";
  Quiz[29].Text = "Do you believe in clairvoyancy (psychic forces, fortune telling)?";
  Quiz[30].Text = "I often hear a voice speaking my thoughts aloud.";
  Quiz[31].Text = "Some people think that I am a very bizarre person.";
  Quiz[32].Text = "I find it hard to be emotionally close to other people.";
  Quiz[33].Text = "I often ramble on too much when speaking.";
  Quiz[34].Text = "My \"non-verbal\" communication (smiling and nodding during a Y N conversation) is poor.";
  Quiz[35].Text = "I feel I have to be on my guard even with friends.";
  Quiz[36].Text = "Do you sometimes see special meanings in advertisements, shop windows, or in the way things are arranged around you?";
  Quiz[37].Text = "Do you often feel nervous when you are in a group of unfamiliar people?";
  Quiz[38].Text = "Can other people feel your feelings when they are not there?";
  Quiz[39].Text = "Have you ever seen things invisible to other people?";
  Quiz[40].Text = "Do you feel that there is no-one you are really close to outside of your immediate family, or people you can confide in or talk to about personal problems?";
  Quiz[41].Text = "Some people find me a bit vague and elusive during a conversation.";
  Quiz[42].Text = "I am poor at returning social courtesies and gestures.";
  Quiz[43].Text = "Do you often pick up hidden threats or put-downs from what people say or do?";
  Quiz[44].Text = "When shopping do you get the feeling that other people are taking notice of you?";
  Quiz[45].Text = "I feel very uncomfortable in social situations involving unfamiliar people.";
  Quiz[46].Text = "Have you had experiences with astrology, seeing the future, UFOs, ESP or a sixth sense?";
  Quiz[47].Text = "Do everyday things seem unusually large or small?";
  Quiz[48].Text = "Writing letters to friends is more trouble than it is worth.";
  Quiz[49].Text = "I sometimes use words in unusual ways.";
  Quiz[50].Text = "I tend to avoid eye contact when conversing with others.";
  Quiz[51].Text = "Have you found that it is best not to let other people know too much about you?";
  Quiz[52].Text = "When you see people talking to each other, do you often wonder if they are talking about you?";
  Quiz[53].Text = "I would feel very anxious if I had to give a speech in front of a large group of people.";
  Quiz[54].Text = "Have you ever felt that you are communicating with another person telepathically (by mind-reading)?";
  Quiz[55].Text = "Does your sense of smell sometimes become unusually strong?";
  Quiz[56].Text = "I tend to keep in the background on social occasions.";
  Quiz[57].Text = "Do you tend to wander off the topic when having a conversation.";
  Quiz[58].Text = "I often feel that others have it in for me.";
  Quiz[59].Text = "Do you sometimes feel that other people are watching you?";
  Quiz[60].Text = "Do you ever suddenly feel distracted by distant sounds that you are not normally aware of?";
  Quiz[61].Text = "I attach little importance to having close friends.";
  Quiz[62].Text = "Do you sometimes feel that people are talking about you?";
  Quiz[63].Text = "Are your thoughts sometimes so strong that you can almost hear them?";
  Quiz[64].Text = "Do you often have to keep an eye out to stop people from taking advantage of you?";
  Quiz[65].Text = "Do you feel that you are unable to get \"close\" to people?";
  Quiz[66].Text = "I am an odd, unusual person.";
  Quiz[67].Text = "I do not have an expressive and lively way of speaking.";
  Quiz[68].Text = "I find it hard to communicate clearly what I want to say to people.";
  Quiz[69].Text = "I have some eccentric (odd) habits.";
  Quiz[70].Text = "I feel very uneasy talking to people I do not know well.";
  Quiz[71].Text = "People occasionally comment that my conversation is confusing.";
  Quiz[72].Text = "I tend to keep my feelings to myself.";
  Quiz[73].Text = "People sometimes stare at me because of my odd appearance.";
}

/*##########################################################################
#
#   Name       : TSpq::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSpq::InitReferers()
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
	AddReferer("tbg.nu", "tbg.nu/news_show/109118/40");
	AddReferer("vof.se", "vof.se/forum/viewtopic.php?t=3080");
	AddReferer("autismspeaks.org", "autismspeaks.org/community/forums");
	AddReferer("nordisk.nu", "nordisk.nu/showthread.php?t=3117");
	AddReferer("swedvdr.org", "swedvdr.org/forums.php?action=viewtopic");
	AddReferer("filmtipset.se", "filmtipset.se/forum.cgi?id=1339244");
	AddReferer("tvsushi.com", "forum.tvsushi.com/index.php?showtopic=52752");
}

/*##################  TSpq::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSpq::LoadReferers()
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
			UpdateReferer(ref, Row.SpqResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.SpqResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.SpqResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.SpqResult);

		if (Row.ADHD >= 1)
			UpdateReferer(&DxAddRef, Row.SpqResult);

		if (Row.TS >= 1)
			UpdateReferer(&DxTsRef, Row.SpqResult);

		if (Row.Dyslexia >= 1)
			UpdateReferer(&DyslexiaRef, Row.SpqResult);

		if (Row.Dyscalculia >= 1)
			UpdateReferer(&DyscalculiaRef, Row.SpqResult);

		if (Row.OCD >= 1)
			UpdateReferer(&OCDRef, Row.SpqResult);

		if (Row.ODD >= 1)
			UpdateReferer(&ODDRef, Row.SpqResult);

		if (Row.Bipolar >= 1)
			UpdateReferer(&BipolarRef, Row.SpqResult);

		if (Row.Schizophrenia >= 1)
			UpdateReferer(&SchizophreniaRef, Row.SpqResult);

		if (Row.Social >= 1)
			UpdateReferer(&SocialPhobiaRef, Row.SpqResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.SpqResult);
			else
				UpdateReferer(&FemaleAsRef, Row.SpqResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TSpq::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSpq::LoadPopulations()
{
	TQuizRow Row;
	TQuizRow Spq;
	int i;
	int id;
	TReferer *ref;
	int aspie;
	char score;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
        for (i = 0; i < N; i++)
            Spq.Quiz[i] = Row.Quiz[136 + i];
	
		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.SpqResult, Spq.Quiz);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.SpqResult, Spq.Quiz);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.SpqResult, Spq.Quiz);

				AsMale.Add(Row.SpqResult, Spq.Quiz);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.SpqResult, Spq.Quiz);

				AsFemale.Add(Row.SpqResult, Spq.Quiz);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.SpqResult, Spq.Quiz);

			if (Row.Aspie == 2)
				As.Add(Row.SpqResult, Spq.Quiz);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.SpqResult, Spq.Quiz);
		}

		if (Row.ADHD >= 1)
		{
			Add.Add(Row.SpqResult, Spq.Quiz);
			if (Row.Gender == 1)
				AddMale.Add(Row.SpqResult, Spq.Quiz);
			else
				AddFemale.Add(Row.SpqResult, Spq.Quiz);
		}

		if (Row.TS >= 1)
			Ts.Add(Row.SpqResult, Spq.Quiz);

		if (Row.Dyslexia >= 1)
			Dyslexia.Add(Row.SpqResult, Spq.Quiz);

		if (Row.Dyscalculia >= 1)
			Dyscalculia.Add(Row.SpqResult, Spq.Quiz);

		if (Row.OCD >= 1)
			OCD.Add(Row.SpqResult, Spq.Quiz);

		if (Row.ODD >= 1)
			ODD.Add(Row.SpqResult, Spq.Quiz);

		if (Row.Bipolar >= 1)
			Bipolar.Add(Row.SpqResult, Spq.Quiz);

		if (Row.Schizophrenia >= 1)
			Schizophrenia.Add(Row.SpqResult, Spq.Quiz);

		if (Row.Social >= 1)
			SocialPhobia.Add(Row.SpqResult, Spq.Quiz);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.SpqResult, Spq.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(Row.SpqResult, Spq.Quiz);
			else
				MixFemale.Add(Row.SpqResult, Spq.Quiz);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.SpqResult, Spq.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TSpq::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSpq::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");
	DefineNt("tbg.nu");
	DefineNt("vof.se");
	DefineNt("nordisk.nu");
	DefineNt("swedvdr.org");
	DefineNt("filmtipset.se");
	DefineNt("tvsushi.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TSpq::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSpq::GetReferer(const char *referer, TPopulation *pop)
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

/*##################  TSpq::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSpq::ExportExcelCase(const char *filename, int PcaType)
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

/*##################  TSpq::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSpq::ExportExcelGroups(const char *filename)
{
}

/*##################  TSpq::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSpq::ImportMvsp(const char *filename, int PcaType)
{
}
