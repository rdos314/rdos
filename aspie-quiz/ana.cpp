/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# ana.cpp
# Analyze aspie-quiz
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"
#include "quizdb.h"

#define MAX_REFERERS    1024
#define MAX_CATS        8
#define MAX_VALUES      4096

#define MAX_GROUP_COUNT 15
#define GROUP_COUNT     11

#define GROUP_SENSORY           0
#define GROUP_BIOLOGY           1
#define GROUP_NONVERBAL         2
#define GROUP_LANGUAGE          3
#define GROUP_SOCIAL            4
#define GROUP_NT_RELATION       5
#define GROUP_SEX               6
#define GROUP_FOCUS             7
#define GROUP_REPETITION        8
#define GROUP_PHYSICAL          9
#define GROUP_MIXED             10

#define FALSE 0
#define TRUE !FALSE

TFile quizfile("quiz1.bin");
TFile asfile("as.dat");
TFile addfile("add.dat");

class TReferer
{
public:
	TReferer(const char *Search, const char *Ref);
	~TReferer();

	int IsMatch(const char *Referer);

	int Now;
	int Before;
	int Count;
	int Result0_59;
	int Result60_99;
	int Result100_139;
	int Result140_200;

	int NT;
	int Aspie;

	char RefererSearch[100];
	char RefererRef[100];
};

class TPopulation 
{
public:
    TPopulation();
    ~TPopulation();

    void Add(TQuizRow *Row);
    long double GetMean(int QuestionNr);
	long double GetSd(int QuestionNr);

    int Count;
    int Sum[100];
	int ValArr[100][MAX_VALUES];
	int ChiArr[100][MAX_CATS];
    
};

class TCorrelation
{
public:
    TCorrelation(TPopulation *pop1, TPopulation *pop2);
    ~TCorrelation();
    
    long double mean[100];
    long double sd[100];
    long double corr[100];
    long double chi2[100];

    int IndArr[100];
};

struct TQuizGroup
{
	long double Corr;
    int Count;
};

struct TQuizQuestion
{
    const char *Text;
	int AsCount;
	long double AsMean;
    long double AsSd;
    int NtCount;
    long double NtMean;
    long double NtSd;
    long double Chi2;
	long double Corr;
    int Used;
    TQuizGroup Group[MAX_GROUP_COUNT];
};

struct TGroupCorr
{
    long double Corr;
	int Count;
};

struct TGroup
{
	long double Mean;
	long double Sd;
};

struct TQuizResult
{
	TGroup Group[MAX_GROUP_COUNT];
	TGroupCorr GroupCorr[MAX_GROUP_COUNT][MAX_GROUP_COUNT];
	TQuizQuestion Quiz[100];
};

int RefCount = 0;
TReferer *RefArr[MAX_REFERERS];
TReferer *NoRef = new TReferer("", "No referrer");
TReferer *NTRef = new TReferer("", "NT sites (at least 40% between 0-59 and at least 5 answers)");
TReferer *AspieRef = new TReferer("", "Aspie sites (at least 35% between 140-200 and at least 5 answers)");
TReferer *AsRef = new TReferer("", "Diagnosed AS/HFA/PDD");
TReferer *AddRef = new TReferer("", "Diagnosed ADD/ADHD");

int QuizGroup[100];
char *GroupName[GROUP_COUNT];

int ValArr[100][MAX_VALUES];
int GroupSum[GROUP_COUNT][MAX_VALUES];
int GroupCount[GROUP_COUNT][MAX_VALUES];
int GroupExist[GROUP_COUNT];

int rows;

char *QuizTextArr[100];
char *QuizHeadArr[100];

TQuizResult Quiz_I;

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

/*##################  TReferer::TReferer ##########################
*   Purpose....: Referer constructor    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TReferer::TReferer(const char *Search, const char *Ref)
{
	strcpy(RefererSearch, Search);
	 strcpy(RefererRef, Ref);
	 Count = 0;
	 Now = 0;
	 Before = 0;
	 Result0_59 = 0;
	 Result60_99 = 0;
	 Result100_139 = 0;
	 Result140_200 = 0;

	 NT = FALSE;
	 Aspie = FALSE;
}

/*##################  TReferer::~TReferer ##########################
*   Purpose....: Referer destructor    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TReferer::~TReferer()
{
}

/*##################  TReferer::IsMatch ##########################
*   Purpose....: Check if referer matches   				      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TReferer::IsMatch(const char *Referer)
{
	 if (strstr(Referer, RefererSearch))
		  return TRUE;
	 else
		  return FALSE;
}

/*##################  FindReferer ##########################
*   Purpose....: Find referer in array    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TReferer *FindReferer(char *Referer)
{
	 int i;
	 TReferer *ref;

	 if (strlen(Referer) == 0)
		  return NoRef;

	 for (i = 0; i < RefCount; i++)
	 {
		  ref = RefArr[i];
		  if (ref->IsMatch(Referer))
				return ref;
	 }
	 return 0;
}

/*##################  AddReferer ##########################
*   Purpose....: Add referer to array    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TReferer *AddReferer(char *Search, char *Ref)
{
	 TReferer *ref;

	if (RefCount < MAX_REFERERS)
	{
		  ref = new TReferer(Search, Ref);
		RefArr[RefCount] = ref;
		RefCount++;

		return ref;
	}
	else
		return 0;
}

/*##################  SortReferers ##########################
*   Purpose....: Sort referer array      					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void SortReferers()
{
	 int i, j;
	 int count;
	 TReferer *ref;

	 for (i = 0; i < RefCount; i++)
	 {
		  count = RefArr[i]->Count;

		  for (j = i + 1; j < RefCount; j++)
		  {
				if (RefArr[j]->Count > count)
				{
					 ref = RefArr[j];
					 RefArr[j] = RefArr[i];
					 RefArr[i] = ref;
					 count = ref->Count;
				}
		  }
	 }
}

/*##################  ProcessReferers ##########################
*   Purpose....: Process referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ProcessReferers()
{
	TQuizRow Row;
	TReferer *ref;
	 int i;
	 int val;

	AddReferer("wikipedia.org/wiki/As", "en.wikipedia.org/wiki/Aspergers");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("google.com", "google.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("intpcentral.com", "intpcentral.com");
	AddReferer("xmission.com/~winter", "xmission.com/~winter");
	AddReferer("everyonesconnected.com", "everyonesconnected.com");
	AddReferer("tribe.net", "tribe.net");
	AddReferer("phpportalen.net", "phpportalen.net");
	AddReferer("aspforum.liebert.se", "aspforum.liebert.se");
	AddReferer("dickflash.com", "dickflash.com");
	AddReferer("99musik.com/forum", "99musik.com/forum");
	AddReferer("whoa.nu", "whoa.nu");

	quizfile.SetPos(0);
	while (quizfile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
		{
			 ref->Count++;
			 ref->Now += Row.ResultNow;
			 ref->Before += Row.ResultBefore;

			 if (Row.ResultNow >= 60)
			 {
				  if (Row.ResultNow >= 100)
				  {
						if (Row.ResultNow >= 140)
							 ref->Result140_200++;
						else
							 ref->Result100_139++;
				  }
				  else
						ref->Result60_99++;
			 }
			 else
				  ref->Result0_59++;
		}
	}

	 for (i = 0; i < RefCount; i++)
	 {
		  ref = RefArr[i];

		  if (ref->Count >= 5)
		  {
				val = ref->Result0_59 * 100 / ref->Count;
				if (val >= 40)
				{
					 ref->NT = TRUE;
					 NTRef->Now += ref->Now;
					 NTRef->Before += ref->Before;
					 NTRef->Count += ref->Count;
					 NTRef->Result0_59 += ref->Result0_59;
					 NTRef->Result60_99 += ref->Result60_99;
					 NTRef->Result100_139 += ref->Result100_139;
					 NTRef->Result140_200 += ref->Result140_200;
				}

				val = ref->Result140_200 * 100 / ref->Count;
				if (val >= 35)
				{
					 ref->Aspie = TRUE;
					 AspieRef->Now += ref->Now;
					 AspieRef->Before += ref->Before;
					 AspieRef->Count += ref->Count;
					 AspieRef->Result0_59 += ref->Result0_59;
					 AspieRef->Result60_99 += ref->Result60_99;
					 AspieRef->Result100_139 += ref->Result100_139;
					 AspieRef->Result140_200 += ref->Result140_200;
				}
		  }
	 }

	SortReferers();
}

/*##################  ProcessAs ##########################
*   Purpose....: Process AS group    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ProcessAs()
{
	TQuizRow Row;

	asfile.SetPos(0);
	while (asfile.Read(&Row, sizeof(Row)))
	{
		  AsRef->Count++;
		AsRef->Now += Row.ResultNow;
		AsRef->Before += Row.ResultBefore;

		if (Row.ResultNow >= 60)
		{
			 if (Row.ResultNow >= 100)
			 {
				  if (Row.ResultNow >= 140)
						AsRef->Result140_200++;
				  else
						AsRef->Result100_139++;
			 }
			 else
				  AsRef->Result60_99++;
		}
		else
			 AsRef->Result0_59++;
	 }
}

/*##################  ProcessAdd ##########################
*   Purpose....: Process ADD group    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ProcessAdd()
{
	TQuizRow Row;

	addfile.SetPos(0);
	while (addfile.Read(&Row, sizeof(Row)))
	{
		  AddRef->Count++;
		AddRef->Now += Row.ResultNow;
		AddRef->Before += Row.ResultBefore;

		if (Row.ResultNow >= 60)
		{
			 if (Row.ResultNow >= 100)
			 {
				  if (Row.ResultNow >= 140)
						AddRef->Result140_200++;
				  else
						AddRef->Result100_139++;
			 }
			 else
				  AddRef->Result60_99++;
		}
		else
			 AddRef->Result0_59++;
	 }
}

/*##################  WriteReferer ##########################
*   Purpose....: Write referer    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteReferer(TFile &file, TReferer *ref)
{
	 char str[80];

	 file.Write("<tr style='height:24.75pt'>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>");

	 sprintf(str, "%d", ref->Count);
	 file.Write(str);

	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>");

	 sprintf(str, "%d", ref->Now / ref->Count);
	 file.Write(str);

	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>");

	 sprintf(str, "%d", ref->Before / ref->Count);
	 file.Write(str);

	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"right\">");
	 file.Write("<b>");

	 sprintf(str, "%d", ref->Result0_59 * 100 / ref->Count);
	 file.Write(str);

	 file.Write("%</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"right\">");
	 file.Write("<b>");

	 sprintf(str, "%d", ref->Result60_99 * 100 / ref->Count);
	 file.Write(str);

	 file.Write("%</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"right\">");
	 file.Write("<b>");

	 sprintf(str, "%d", ref->Result100_139 * 100 / ref->Count);
	 file.Write(str);

	 file.Write("%</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"right\">");
	 file.Write("<b>");

	 sprintf(str, "%d", ref->Result140_200 * 100 / ref->Count);
	 file.Write(str);

	 file.Write("%</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"72%\" colspan=2 valign=middle halign=center>");

	 file.Write("<p>");
	 file.Write("<b>");

	if (strlen(ref->RefererSearch))
	 {
		  file.Write("<a href=\"http://");
		  file.Write(ref->RefererRef);
		  file.Write("\">http://");
		  file.Write(ref->RefererRef);
		  file.Write("</a>");
	 }
	 else
		  file.Write(ref->RefererRef);

	 file.Write("</b>");
	 file.Write("</p>");
	 file.Write("</td>");
	 file.Write("</tr>");
}

/*##################  PrintReferers ##########################
*   Purpose....: Print referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteReferers(const char *filename)
{
	 TFile file(filename, 0);
	 int i;

	 file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	 file.Write("<tr style='height:24.75pt'>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>Answers");
	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>Now");
	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>Before");
	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>0-59");
	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>60-99");
	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>100-139");
	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	 file.Write("<p align=\"center\">");
	 file.Write("<b>140-200");
	 file.Write("</b>");
	 file.Write("</p>");

	 file.Write("</td>");

	 file.Write("<td width=\"72%\" colspan=2 valign=middle halign=center>");

	 file.Write("<p>");
	 file.Write("<b>Web site");
	 file.Write("</b>");
	 file.Write("</p>");
	 file.Write("</td>");
	 file.Write("</tr>");

	 WriteReferer(file, AsRef);
	 WriteReferer(file, AddRef);
	 WriteReferer(file, AspieRef);
	 WriteReferer(file, NTRef);
	 WriteReferer(file, NoRef);

	 for (i = 0; i < RefCount; i++)
		  WriteReferer(file, RefArr[i]);

	 file.Write("</table>");
}


/*##################  ProcessHBT ##########################
*   Purpose....: Process HBT population 			       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ProcessHBT()
{
	 int ok;
	TQuizRow Row;
	TReferer *ref;
	 TFile hbtfile("hbt.dat", 0);

	quizfile.SetPos(0);
	while (quizfile.Read(&Row, sizeof(Row)))
	{

		 ok = FALSE;

		 if (strlen(Row.Referer))
		 {
			if (strstr(Row.Referer, "atforumz.com/showthread.php?t=274235"))
				ok = TRUE;

			if (strstr(Row.Referer, "livejournal.com/community/gay_oddities"))
					 ok = TRUE;
		  }

		  if (ok)
			 hbtfile.Write(&Row, sizeof(Row));
	}
}


/*##################  CreateReferences ##########################
*   Purpose....: Create reference populations    			       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateReferences()
{
	TQuizRow Row;
	TReferer *ref;
	 TFile ntfile("nt.dat", 0);
	 TFile aspiefile("aspie.dat", 0);

	quizfile.SetPos(0);
	while (quizfile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);

		if (ref)
		{
			 if (ref->NT)
				  ntfile.Write(&Row, sizeof(Row));

			 if (ref->Aspie)
				  aspiefile.Write(&Row, sizeof(Row));
		}
	}
}

/*##################  InitQuizText ##########################
*   Purpose....: Init quiz texts                			       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void InitQuizText()
{
	 int i;

	 for (i = 0; i < 100; i++)
		  QuizHeadArr[i] = 0;

	GroupName[GROUP_SENSORY] = "SENSORY SYSTEM";
	GroupName[GROUP_BIOLOGY] = "BIOLOGY";
	GroupName[GROUP_NONVERBAL] = "NONVERBAL COMMUNICATION";
	GroupName[GROUP_LANGUAGE] = "LANGUAGE AND SPEECH";
	GroupName[GROUP_SOCIAL] = "SOCIAL & EMOTIONS";
	GroupName[GROUP_NT_RELATION] = "NT RELATIONSHIPS";
	GroupName[GROUP_SEX] = "SEXUALITY & GENDER ISSUES";
	GroupName[GROUP_FOCUS] = "HYPERFOCUS, DETAIL & TALENTS";
	GroupName[GROUP_REPETITION] = "NEED FOR REPETITION & PREDICTABILITY";
	GroupName[GROUP_PHYSICAL] = "PHYSICAL TRAITS";
	GroupName[GROUP_MIXED] = "MIXED";

	QuizGroup[0] = GROUP_FOCUS;
	QuizGroup[1] = GROUP_FOCUS;
	QuizGroup[2] = GROUP_LANGUAGE;      // cross
	QuizGroup[3] = GROUP_MIXED;
	QuizGroup[4] = GROUP_FOCUS;
	QuizGroup[5] = GROUP_MIXED;
	QuizGroup[6] = GROUP_MIXED;
	QuizGroup[7] = GROUP_FOCUS;
	QuizGroup[8] = GROUP_MIXED;
	QuizGroup[9] = GROUP_FOCUS;       // cross
	QuizGroup[10] = GROUP_MIXED;
	QuizGroup[11] = GROUP_FOCUS;
	QuizGroup[12] = GROUP_FOCUS;
	QuizGroup[13] = GROUP_LANGUAGE;
	QuizGroup[14] = GROUP_LANGUAGE;
	QuizGroup[15] = GROUP_LANGUAGE;     // cross
	QuizGroup[16] = GROUP_LANGUAGE;
	QuizGroup[17] = GROUP_LANGUAGE;     // cross
	QuizGroup[18] = GROUP_FOCUS;
	QuizGroup[19] = GROUP_FOCUS;
	QuizGroup[20] = GROUP_FOCUS;
	QuizGroup[21] = GROUP_FOCUS;
	QuizGroup[22] = GROUP_FOCUS;      // cross
	QuizGroup[23] = GROUP_FOCUS;
	QuizGroup[24] = GROUP_FOCUS;
	QuizGroup[25] = GROUP_FOCUS;
	QuizGroup[26] = GROUP_MIXED;
	QuizGroup[27] = GROUP_MIXED;
	QuizGroup[28] = GROUP_MIXED;
	QuizGroup[29] = GROUP_MIXED;
	QuizGroup[30] = GROUP_MIXED;
	QuizGroup[31] = GROUP_MIXED;
	QuizGroup[32] = GROUP_MIXED;
	QuizGroup[33] = GROUP_SOCIAL;
	QuizGroup[34] = GROUP_MIXED;
	QuizGroup[35] = GROUP_REPETITION;
	QuizGroup[36] = GROUP_REPETITION;   // cross
	QuizGroup[37] = GROUP_REPETITION;
	QuizGroup[38] = GROUP_REPETITION;
	QuizGroup[39] = GROUP_REPETITION;   // cross
	QuizGroup[40] = GROUP_NONVERBAL;
	QuizGroup[41] = GROUP_MIXED;
	QuizGroup[42] = GROUP_BIOLOGY;      // cross
	QuizGroup[43] = GROUP_BIOLOGY;
	QuizGroup[44] = GROUP_BIOLOGY;
	QuizGroup[45] = GROUP_BIOLOGY;      // cross
	QuizGroup[46] = GROUP_BIOLOGY;
	QuizGroup[47] = GROUP_BIOLOGY;
	QuizGroup[48] = GROUP_BIOLOGY;
	QuizGroup[49] = GROUP_BIOLOGY;
	QuizGroup[50] = GROUP_REPETITION;
	QuizGroup[51] = GROUP_FOCUS;
	QuizGroup[52] = GROUP_SENSORY;      // cross
	QuizGroup[53] = GROUP_SENSORY;      // cross
	QuizGroup[54] = GROUP_SENSORY;
	QuizGroup[55] = GROUP_SENSORY;      // cross
	QuizGroup[56] = GROUP_SENSORY;      // cross
	QuizGroup[57] = GROUP_SENSORY;      // cross
	QuizGroup[58] = GROUP_MIXED;
	QuizGroup[59] = GROUP_SENSORY;
	QuizGroup[60] = GROUP_SENSORY;
	QuizGroup[61] = GROUP_SENSORY;      // cross
	QuizGroup[62] = GROUP_SENSORY;
	QuizGroup[63] = GROUP_MIXED;
	QuizGroup[64] = GROUP_SENSORY;      // cross
	QuizGroup[65] = GROUP_SOCIAL;       // cross
	QuizGroup[66] = GROUP_SOCIAL;
	QuizGroup[67] = GROUP_SOCIAL;
	QuizGroup[68] = GROUP_SOCIAL;
	QuizGroup[69] = GROUP_SOCIAL;       // cross
	QuizGroup[70] = GROUP_SOCIAL;
	QuizGroup[71] = GROUP_NONVERBAL;
	QuizGroup[72] = GROUP_MIXED;        // cross
	QuizGroup[73] = GROUP_SOCIAL;
	QuizGroup[74] = GROUP_SOCIAL;
	QuizGroup[75] = GROUP_SOCIAL;
	QuizGroup[76] = GROUP_MIXED;        // cross
	QuizGroup[77] = GROUP_SOCIAL;       // cross
	QuizGroup[78] = GROUP_SENSORY;
	QuizGroup[79] = GROUP_MIXED;
	QuizGroup[80] = GROUP_SOCIAL;
	QuizGroup[81] = GROUP_NONVERBAL;    // cross
	QuizGroup[82] = GROUP_NONVERBAL;    // cross
	QuizGroup[83] = GROUP_NONVERBAL;
	QuizGroup[84] = GROUP_NONVERBAL;
	QuizGroup[85] = GROUP_NONVERBAL;
	QuizGroup[86] = GROUP_NONVERBAL;
	QuizGroup[87] = GROUP_NONVERBAL;    // cross
	QuizGroup[88] = GROUP_NONVERBAL;    // cross
	QuizGroup[89] = GROUP_SOCIAL;       // cross
	QuizGroup[90] = GROUP_SOCIAL;       // cross
	QuizGroup[91] = GROUP_NONVERBAL;       // cross
	QuizGroup[92] = GROUP_SOCIAL;
	QuizGroup[93] = GROUP_MIXED;
	QuizGroup[94] = GROUP_NONVERBAL;
	QuizGroup[95] = GROUP_MIXED;
	QuizGroup[96] = GROUP_SOCIAL;
	QuizGroup[97] = GROUP_SOCIAL;       // cross
	QuizGroup[98] = GROUP_SOCIAL;
	QuizGroup[99] = GROUP_SOCIAL;       // cross

	QuizHeadArr[0] = "BRAIN FUNCTION & LEARNING";

	QuizTextArr[0] = "Are you very logical and get surprised or impatient when others aren't?";
	QuizTextArr[1] = "Do you find visualizing easy?";
	QuizTextArr[2] = "Do you get confused by verbal instructions - especially several at the same time?";
	QuizTextArr[3] = "Do you need to see, touch or do things yourself in order to remember them?";
	QuizTextArr[4] = "Do you take an interest in, and remember, details that others do not seem to notice?";
	QuizTextArr[5] = "Do you tend to get so stuck on details that you miss the overall picture?";
	QuizTextArr[6] = "Do you find it difficult to generalize?";
	QuizTextArr[7] = "Are you fascinated by dates and/or numbers?";
	QuizTextArr[8] = "Is it easier and more interesting for you to focus on the outer form (e.g. the font and layout of a text) than on the actual content?";
	QuizTextArr[9] = "Are you punctual, conscientious and perfectionist?";
	QuizTextArr[10]= "Do you find concrete things easier to grasp than abstract concepts?";
	QuizTextArr[11] = "Do you have excellent long-term memory in subjects that interest you?";


	QuizHeadArr[12] = "LANGUAGE & SPEECH";

	QuizTextArr[12] = "Do you have excellent vocabulary and/or a fascination with words?";
	QuizTextArr[13] = "Is it difficult or tiresome for you to talk?";
	QuizTextArr[14] = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)t?";
	QuizTextArr[15] = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
	QuizTextArr[16] = "Do you use stock phrases or phrases borrowed from other situations or people?";
	QuizTextArr[17] = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";

	QuizHeadArr[18] = "TALENTS & SPECIAL INTERESTS";

	QuizTextArr[18] = "Are you very gifted in one or more areas?";
	QuizTextArr[19] = "Do you focus on one interest at a time and become an expert on that subject?";
	QuizTextArr[20] = "Do you enjoy gathering information about categories of things (types of birds, cars etc.)?";
	QuizTextArr[21] = "Do you love to collect and organize things, make lists & diagrams etc?";
	QuizTextArr[22] = "Do you have unconventional, often unique ways of solving problems?";

	QuizHeadArr[23] = "HYPERFOCUS & PERSEVERATION";

	QuizTextArr[23] = "Do you have an ability to stick to something that interests you and not give up?";
	QuizTextArr[24] = "Does it feel vitally important to be left undisturbed to persue your special interests?";
	QuizTextArr[25] = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
	QuizTextArr[26] = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";

	QuizHeadArr[27] = "NEED FOR SAFETY, FAMILIARITY & SUPPORT";

	QuizTextArr[27] = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
	QuizTextArr[28] = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to preparei yourself mentally first?";
	QuizTextArr[29] = "Do you feel a lot safer if you have a trusted companion with you?";
	QuizTextArr[30] = "Is it harder for you to make it on your own, than it seems to be for most others of your age?";
	QuizTextArr[31] = "Do you have a tendency to be passive and not initiate things yourself?";
	QuizTextArr[32] = "Do you prefer the company of those older than yourself to that of your peers?";
	QuizTextArr[33] = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
	QuizTextArr[34] = "Do you have a need for comfort items like blankets, stuffed animals etc?";

	QuizHeadArr[35] = "NEED FOR REPETITION & PREDICABILITY";
 
	QuizTextArr[35] = "Do you have certain simple & logical routines which you need to follow?";
	QuizTextArr[36] = "Do you prefer to wear the same clothes and/or eat the same food every day?";
	QuizTextArr[37] = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
	QuizTextArr[38] = "Do you have very strong attachments to certain objects, e.g. a favourite cup or a favourite towel and really need to have that precise one?";
	QuizTextArr[39] = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed, or if an activity that is important to you gets interrupted?";
	QuizTextArr[40] = "Do you use self-stimulation i.e., rocking, tapping, humming, staring at a rotating object etc., to increase concentration & attention or to calm down and relax?";

	QuizHeadArr[41] = "BIOLOGICAL & NEUROLOGICAL DIFFERENCES";
 
	QuizTextArr[41] = "Do you look younger than your biological age??";
	QuizTextArr[42] = "Do you have an odd posture, gait and/or difficulties sitting/standing erect?";
	QuizTextArr[43] = "Do you have difficulties with fine motor skills and/or hand-eye co-ordination?";
	QuizTextArr[44] = "Do you have poor gross motor skills (= clumsiness)?";
	QuizTextArr[45] = "Do you have difficulties judging distances, height, depth or speed?";
	QuizTextArr[46] = "Do you confuse left and right?";
	QuizTextArr[47] = "Are you fairly insensitive to, or have unusual reactions to, physical pain?";
	QuizTextArr[48] = "Do you have unusual sleeping patterns?";
	QuizTextArr[49] = "Do you have poor concept of time?";
	QuizTextArr[50] = "Do you have obsessions or compulsions (repeated irresistible impulses to do certain things)?";

	QuizHeadArr[51] = "HYPERSENSITIVE SENSES";
 
	QuizTextArr[51] = "Are you musically gifted? Do you, for example, have perfect pitch and/or the ability to play one or more instruments?";
	QuizTextArr[52] = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
	QuizTextArr[53] = "Do you have problems distinguishing voices from background noise, or from other voices?";
	QuizTextArr[54] = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
	QuizTextArr[55] = "Do you feel uncomfortable in fluorescent light?";
	QuizTextArr[56] = "Do you have a very acute sense of smell and/or taste?";
	QuizTextArr[57] = "Do you feel strongly attracted to, or appalled by, certain tastes, smells, sounds, colours, shapes, textures or materials?";
	QuizTextArr[59] = "Do you love water?";
	QuizTextArr[58] = "Do you have to be particular with what you eat and/or how it is combined on the plate in order not to get sick?";
	QuizTextArr[59] = "Are you sensitive to heat, cold, wind and/or changes in air-pressure, humidity etc?";
	QuizTextArr[60] = "Do you feel tortured by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' material?";
	QuizTextArr[61] = "Do you dislike being touched - especially without prior warning, by the \"wrong\" person or at the \"wrong\" time?";
	QuizTextArr[62] = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
	QuizTextArr[63] = "Do you have a need for order and neatness?";
	QuizTextArr[64] = "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?";
	QuizTextArr[65] = "Do you get exceedingly tired after socializing, and need to regenerate alone?";

	QuizHeadArr[66] = "NATURAL INTROVERSION";

	QuizTextArr[66] = "Are you more of an observer than one who participates in life - being a detached observer ?";
	QuizTextArr[67] = "Are you fairly self-absorbed, more interested in yourself than in others and/or an objective observer of yourself?";
	QuizTextArr[68] = "Do you find yourself more attracted to things, ideas, music, computers, animals, buildings or vehicles than to people and social exchange?";
	QuizTextArr[69] = "Do you dislike or have difficulty with team sports and other group endeavours?";
	QuizTextArr[70] = "Do you mostly prefer to play/work/do things on your own - in your own way and at your own pace?";
	QuizTextArr[71] = "Do you have problems with eye-contact?";
	QuizTextArr[72] = "Do you dislike shaking hands?";

	QuizHeadArr[73] = "EMOTIONS";

	QuizTextArr[73] = "Are you fairly cool & dispassionate and usually only have feelings when provoked or excited?";
	QuizTextArr[74] = "Do you easily get frustrated and upset when you are stressed, tired, hungry, interrupted, questioned, over-stimulated, or when things don't go as you had anticipated?";
	QuizTextArr[75] = "Do you tend to express your feelings in ways that may baffle others (e.g. banging your head in the wall, or being unable to show anything at all)?";
	QuizTextArr[76] = "Do you more easily get very upset over 'minor' things (e.g. losing your favourite pen) than over which others get upset about (e.g. a relative passing away)?";
	QuizTextArr[77] = "Do you sometimes not feel anything at all, even though other people expect you to?";
	QuizTextArr[78] = "Are you sometimes so empathic that you feel other peoples' or animals' feelings as your own?";
	QuizTextArr[79] = "Are you sometimes afraid in safe situations, yet fearless in situations which may actually be dangerous?";

	QuizHeadArr[80] = "SOCIAL DIFFICULTIES";

	QuizTextArr[80] = "Do you tend to feel get nervous, shy, confused and/or like you don't fit in, in various social situations?";
	QuizTextArr[81] = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
	QuizTextArr[82] = "In conversations, do you have trouble with things like timing and reciprocity?";
	QuizTextArr[83] = "Do you have difficulties judging unseen limits and other people's personal space unless clearly instructed?";
	QuizTextArr[84] = "Do you often talk about your special interests whether others seem to be interested or not?";
	QuizTextArr[85] = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
	QuizTextArr[86] = "Do you have difficulties understanding figures of speech, parodies, allegories, irony etc?";
	QuizTextArr[87] = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
	QuizTextArr[88] = "Do you have problems recognizing faces out of their usual context (e.g. your doctor at the supermarket without his white robe)?";
	QuizTextArr[89] = "Do you find it easier to understand & communicate with computers, animals and/or Aspies than with 'ordinary' people?";
	QuizTextArr[90] = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";

	QuizHeadArr[91] = "SINCERITY, FRIENDLINESS & NAIVETÉ";
 
	QuizTextArr[91] = "Are you so honest and sincere yourself that you assume everyone is, and therefore easily miss dishonesty and hidden agendas?";
	QuizTextArr[92] = "Have you been bullied, abused or taken advantage of in various situations?";
	QuizTextArr[93] = "Do you get surprised and disappointed when people are unfriendly and don't seem to understand or accept you as you are?";
	QuizTextArr[94] = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
	QuizTextArr[95] = "Once you understand how someone feels, do you usually want to express you sympathy, help or cheer that person up if he or she is in distress?";

	QuizHeadArr[96] = "CULTURAL INDEPENDENCE";

	QuizTextArr[96] = "Are you usually unaware of/disinterested in what is currently in vogue?";
	QuizTextArr[97] = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
	QuizTextArr[98] = "Do you have high morals and a tendency to stand up for your ideals and beliefs even if they are contrary to general consensus, or if it means social or economical disadvantages?";
	QuizTextArr[99] = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
}

/*##################  TPopulation::TPopulation ##########################
*   Purpose....: Population constructor    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TPopulation::TPopulation()
{
	int i,j;

    Count = 0;

	for (i = 0; i < 100; i++)
	{
		Sum[i] = 0;
        for (j = 0; j < MAX_CATS; j++)
			ChiArr[i][j] = 0;
	}
}

/*##################  TPopulation::~TPopulation ##########################
*   Purpose....: Population destructor    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TPopulation::~TPopulation()
{
}

/*##################  TPopulation::Add ##########################
*   Purpose....: Add a quiz answer    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TPopulation::Add(TQuizRow *Row)
{
    int val;
    int i;

    for (i = 0; i < 100; i++)
    {
        val = Row->Now[i];
        ChiArr[i][val]++;
        ValArr[i][Count] = val;
        Sum[i] += val;
	}

    Count++;
}

/*##################  TPopulation::GetMean ##########################
*   Purpose....: Get mean value for a single question      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long double TPopulation::GetMean(int QuestionNr)
{
	return (long double)Sum[QuestionNr] / Count;
}

/*##################  TPopulation::GetSd ##########################
*   Purpose....: Get standard deviation for a single question      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long double TPopulation::GetSd(int QuestionNr)
{
	int e;
	long double val;
	long double rsum = 0;
	long double mean = GetMean(QuestionNr);

	for (e = 0; e < Count; e++)
	{
		val = (long double)ValArr[QuestionNr][e] - mean;
		rsum += val * val;
	}

    return sqrt(rsum / ((long double)Count - 1));
}

/*##################  TCorrelation::TCorrelation ##########################
*   Purpose....: Calculate correlation	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCorrelation::TCorrelation(TPopulation *pop1, TPopulation *pop2)
{
	int i, j;
	int e;
	int sum;
	long double val;
	long double rsum;
	long double cmean;
	long double csd;
	long double zx;
	long double zy;
	long double exp;

	for (i = 0; i < 100; i++)
	{
		sum = 0;
		for (e = 0; e < pop1->Count; e++)
			sum += pop1->ValArr[i][e];

		for (e = 0; e < pop2->Count; e++)
			sum += pop2->ValArr[i][e];

		mean[i] = (long double)sum / ((long double)pop1->Count + (long double)pop2->Count);

		rsum = 0;
		for (e = 0; e < pop1->Count; e++)
		{
			val = (long double)pop1->ValArr[i][e] - mean[i];
			rsum += val * val;
		}

		for (e = 0; e < pop2->Count; e++)
		{
			val = (long double)pop2->ValArr[i][e] - mean[i];
			rsum += val * val;
		}

		sd[i] = sqrt(rsum / ((long double)pop1->Count + (long double)pop2->Count - 1));
	}

	cmean = (long double)pop1->Count / ((long double)pop1->Count + (long double)pop2->Count);

	val = 1.0 - cmean;
	rsum = (long double)pop1->Count * val * val;

	val = cmean;
	rsum += (long double)pop2->Count * val * val;

	csd = sqrt(rsum / ((long double)pop1->Count + (long double)pop2->Count - 1));

	for (i = 0; i < 100; i++)
	{
		rsum = 0;

		zx = (1.0 - cmean) / csd;
		for (e = 0; e < pop1->Count; e++)
		{
			zy = ((long double)pop1->ValArr[i][e] - mean[i]) / sd[i];
			rsum += zx * zy;
		}

		zx = (0.0 - cmean) / csd;
		for (e = 0; e < pop2->Count; e++)
		{
			zy = ((long double)pop2->ValArr[i][e] - mean[i]) / sd[i];
			rsum += zx * zy;
		}

		corr[i] = rsum / ((long double)pop1->Count + (long double)pop2->Count - 1.0);
	}

	for (i = 0; i < 100; i++)
	{
		rsum = 0;

		for (j = 0; j < 3; j++)
		{
			exp = (long double)pop2->ChiArr[i][j] * (long double)pop1->Count / (long double)pop2->Count;
			if (exp >= 5.0)
			{
				val = (long double)pop1->ChiArr[i][j] - exp;
				rsum += val * val / exp;
			}
		}

		chi2[i] = rsum;
	}

	for (i = 0; i < 100; i++)
		IndArr[i] = i;

	for (i = 0; i < 100; i++)
	{
		val = corr[IndArr[i]];

		for (j = i + 1; j < 100; j++)
		{
			if (corr[IndArr[j]] > val)
			{
				e = IndArr[j];
				IndArr[j] = IndArr[i];
				IndArr[i] = e;
				val = corr[e];
			}
		}
	}
}

/*##################  TCorrelation::~TCorrelation ##########################
*   Purpose....: Destructor for correlation	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCorrelation::~TCorrelation()
{
}

/*##################  WriteCorrTable ##########################
*   Purpose....: Write correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCorrTable(const char *filename, const char *name1, const char *name2, TCorrelation *corr, TPopulation *pop1, TPopulation *pop2, long double mincorr)
{
	int i;
	int ok;
	int j;
	int ind;
	long double val;
	char str[80];
	int ival;
	TFile file(filename, 0);

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	j = 0;

	for (i = 0; i < 100; i++)
	{
		ind = corr->IndArr[i];

		ok = (corr->chi2[ind] >= mincorr);

		if (ok && j % 10 == 0)
		{
			file.Write("<tr style='height:24.75pt'>");

			file.Write("<td width=\"4%\" valign=middle align='center'>\n");

			file.Write("<p>");
			file.Write("<b>");
			file.Write("#");
			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"62%\" colspan=2 valign=top halign=center>");

			file.Write("<p align=\"center\">");
			file.Write("<b>");

			file.Write(" ");

			file.Write("</b>");
			file.Write("</p>");
			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			file.Write(name1);

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			file.Write(name2);

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			file.Write("Chi2");

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			file.Write("Corr");

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("</tr>");
		}

		if (ok)
		{
			j++;

			file.Write("<tr style='height:24.75pt'>");

			file.Write("<td width=\"4%\" valign=middle align='center'>\n");

			file.Write("<p>");
			file.Write("<b>");

			sprintf(str, "%d", ind + 1);
			file.Write(str);

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"62%\" colspan=2 valign=top halign=center>");

			file.Write("<p align=\"center\">");
			file.Write("<b>");

			file.Write(QuizTextArr[ind]);

			file.Write("\n");

			file.Write("</b>");
			file.Write("</p>");
			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			ival = round(100.0 * pop1->Sum[ind] / pop1->Count);
			sprintf(str, "%d.%02d", ival / 100, ival % 100);
			file.Write(str);

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			ival = round(100.0 * pop2->Sum[ind] / pop2->Count);
			sprintf(str, "%d.%02d", ival / 100, ival % 100);
			file.Write(str);

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			ival = round(corr->chi2[ind]);

			sprintf(str, "%d", ival);
			file.Write(str);

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");

			file.Write("<td width=\"6%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			ival = round(100.0 * corr->corr[ind]);
//	    	ival = 100 * sqrt(corr.chi2[ind] / (pop1->Count + pop2->Count));

			sprintf(str, "%d", ival);
			file.Write(str);
			file.Write("%");

			file.Write("</b>");
			file.Write("</p>");

			file.Write("</td>");
		}
	}

	file.Write("</table>");
}

/*##################  WriteAsNtCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteAsNtCorrelation(const char *filename)
{
	 int i;
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("as.dat");
	TFile file2("nt.dat");

	pop1 = new TPopulation;

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		 pop1->Add(&Row);

	 pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		 pop2->Add(&Row);

	 TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, "AS", "NT referrer", &corr, pop1, pop2, 6.0);

	 for (i = 0; i < 100; i++)
	 {
		  Quiz_I.Quiz[i].Text = 0;
		  Quiz_I.Quiz[i].AsCount = pop1->Count;
		  Quiz_I.Quiz[i].AsMean = pop1->GetMean(i);
		  Quiz_I.Quiz[i].AsSd = pop1->GetSd(i);
		  Quiz_I.Quiz[i].NtCount = pop2->Count;
		  Quiz_I.Quiz[i].NtMean = pop2->GetMean(i);
		  Quiz_I.Quiz[i].NtSd = pop2->GetSd(i);
		  Quiz_I.Quiz[i].Chi2 = corr.chi2[i];
		  Quiz_I.Quiz[i].Corr = corr.corr[i];
	 }

	delete pop1;
	delete pop2;
}

/*##################  WriteAsAspieCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteAsAspieCorrelation(const char *filename)
{
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("as.dat");
	TFile file2("aspie.dat");

	pop1 = new TPopulation;

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		 pop1->Add(&Row);

	 pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		 pop2->Add(&Row);

	TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, "AS", "Aspie referrer", &corr, pop1, pop2, 6.0);

	delete pop1;
	delete pop2;
}

/*##################  WriteAddNtCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteAddNtCorrelation(const char *filename)
{
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("add.dat");
	TFile file2("nt.dat");

	pop1 = new TPopulation;

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		 pop1->Add(&Row);

	pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		pop2->Add(&Row);

	TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, "ADHD", "NT referrer", &corr, pop1, pop2, 6.0);

	delete pop1;
	delete pop2;
}

/*##################  WriteAddAsCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteAddAsCorrelation(const char *filename)
{
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("add.dat");
	TFile file2("as.dat");

	pop1 = new TPopulation;

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		 pop1->Add(&Row);

	pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		pop2->Add(&Row);

	TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, "ADHD", "AS", &corr, pop1, pop2, 6.0);

	delete pop1;
	delete pop2;
}

/*##################  WriteHbtNtCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteHbtNtCorrelation(const char *filename)
{
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("hbt.dat");
	TFile file2("nt.dat");

	pop1 = new TPopulation;

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		 pop1->Add(&Row);

	pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		pop2->Add(&Row);

	TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, "HBT", "NT referrer", &corr, pop1, pop2, 5.0);

	delete pop1;
	delete pop2;
}

/*##################  WriteHbtAsCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteHbtAsCorrelation(const char *filename)
{
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("hbt.dat");
	TFile file2("as.dat");

	pop1 = new TPopulation;

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		 pop1->Add(&Row);

	pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		pop2->Add(&Row);

	TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, "HBT", "AS", &corr, pop1, pop2, 5.0);

	delete pop1;
	delete pop2;
}

/*##################  WriteRefererNtCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteRefererNtCorrelation(const char *filename, const char *header, const char *referer)
{
	int i;
	TReferer *ref;
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("quiz1.bin");
	TFile file2("nt.dat");

	pop1 = new TPopulation;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop1->Add(&Row);

	pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		pop2->Add(&Row);

	TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, header, "NT referrer", &corr, pop1, pop2, 6.0);

	delete pop1;
	delete pop2;
}

/*##################  WriteRefererAsCorrelation ##########################
*   Purpose....: Write correlation      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteRefererAsCorrelation(const char *filename, const char *header, const char *referer)
{
	int i;
	TReferer *ref;
	TQuizRow Row;
	TPopulation *pop1;
	TPopulation *pop2;
	TFile file1("quiz1.bin");
	TFile file2("as.dat");

	pop1 = new TPopulation;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	file1.SetPos(0);
	while (file1.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop1->Add(&Row);

	pop2 = new TPopulation;

	file2.SetPos(0);
	while (file2.Read(&Row, sizeof(Row)))
		pop2->Add(&Row);

	TCorrelation corr(pop1, pop2);

	WriteCorrTable(filename, header, "AS", &corr, pop1, pop2, 6.0);

	delete pop1;
	delete pop2;
}

/*##################  WriteResult ##########################
*   Purpose....: Write AS-NT result     	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteResult(const char *filename)
{
	TFile file(filename, 0);

	file.Write(&Quiz_I, sizeof(Quiz_I));
}

/*##################  CalcCorrelation ##########################
*   Purpose....: Calculate question-group correlations	   	     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CalcCorrelation()
{
	int i;
	int q;
	int g;
	int e;
	int ok;
	int ival;
	int gcount;
	int gsum;
	long double val;
	long double rsum;
	int sum[100];
	int grpcount[GROUP_COUNT];
	int grpsum[GROUP_COUNT];
	long double mean[100];
	long double csd[100];
	long double zx;
	long double zy;
	TQuizRow Row;

	for (i = 0; i < 100; i++)
	    sum[i] = 0;

    for (i = 0; i < GROUP_COUNT; i++)
	{
        grpsum[i] = 0;
        grpcount[i] = 0;
    }

    for (g = 0; g < GROUP_COUNT; g++)
    {
        GroupExist[g] = FALSE;        
        for (i = 0; i < 100; i++)
            if (QuizGroup[i] == g)
                GroupExist[g] = TRUE;
    }
    
    rows = 0;
	quizfile.SetPos(0);
	while (quizfile.Read(&Row, sizeof(Row)))
	{
        for (i = 0; i < 100; i++)
        {
            ival = Row.Now[i];
			ValArr[i][rows] = ival;
            sum[i] += ival;
        }

        for (g = 0; g < GROUP_COUNT; g++)
        {
            if (GroupExist[g])
            {
    			gsum = 0;
                gcount = 0;
    
                for (i = 0; i < 100; i++)
		    	{
                    if (QuizGroup[i] == g)
                    {
                        ival = Row.Now[i];
                        gsum += ival;                            
                        gcount++;
                    }
                }

	    		GroupSum[g][rows] = gsum;
		    	GroupCount[g][rows] = gcount;
			    grpsum[g] += gsum;
    			grpcount[g] += gcount;
    	    }
		}

		rows++;
	}

	for (i = 0; i < 100; i++)
	{
		mean[i] = (long double)sum[i] / rows;

		rsum = 0;

		for (e = 0; e < rows; e++)
		{
			ival = ValArr[i][e];
			val = (long double)ival - mean[i];
			rsum += val * val;
		}
		csd[i] = sqrt(rsum / ((long double)rows - 1));
	}

	for (g = 0; g < GROUP_COUNT; g++)
	{
	    if (GroupExist[g])
	    {
    		Quiz_I.Group[g].Mean = (long double)grpsum[g] / grpcount[g];

	    	rsum = 0;
    
	    	for (e = 0; e < rows; e++)
		    {
			    if (GroupCount[g][e])
    			{
	    			val = (long double)GroupSum[g][e] / GroupCount[g][e];
		    		val -= Quiz_I.Group[g].Mean;
			    	rsum += val * val;
    			}
	    	}
		    Quiz_I.Group[g].Sd = sqrt(rsum / ((long double)rows - 1));
		}
	}

	for (q = 0; q < 100; q++)
	{
		for (g = 0; g < GROUP_COUNT; g++)
		{
		    Quiz_I.Quiz[q].Group[g].Corr = 0;
		    if (GroupExist[g])
		    {
    		    Quiz_I.Quiz[q].Group[g].Count = 0;
	    	    rsum = 0;
		    	for (e = 0; e < rows; e++)
			    {
    			    ival = ValArr[q][e];
	    		    gcount = GroupCount[g][e];
		    	    gsum = GroupSum[g][e];
    
	    		    if (gcount)
		    	    {    			        
			            Quiz_I.Quiz[q].Group[g].Count++;

                        if (QuizGroup[q] == g)
                        {
                            gcount--;
                            gsum -= ival;
                        }

        			    zx = ((long double)ival - mean[q]) / csd[q];
						zy = ((long double)gsum / gcount - Quiz_I.Group[g].Mean) / Quiz_I.Group[g].Sd;
	        			rsum += zx * zy;
		        	}
                }
    
				if (Quiz_I.Quiz[q].Group[g].Count)
					Quiz_I.Quiz[q].Group[g].Corr = rsum / ((long double)Quiz_I.Quiz[q].Group[g].Count - 1);
			}
		}
	}
}

/*##################  WriteGroupCorrTable ##########################
*   Purpose....: Write group correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteGroupCorrTable(const char *filename)
{
    int ind;
    int i;
	int j;
	int g;
	int grp;
	int comp;
	char str[80];
	int ival;
	int count;
	long double val;
	long double maxcorr;
	long double selfcorr;
	long double zij;
    long double za;
    long double low;
    long double high;
    long double corrval;
	int group;
    int used[100];
	TFile file(filename, 0);

    for (i = 0; i < 100; i++)
        used[i] = FALSE;

    file.Write("<table border=3 cellspacing=0 cellpadding=0>");
        
    for (g = 0; g < GROUP_COUNT; g++)
    {
		file.Write("<tr style='height:24.75pt'>");

		file.Write("<td width=\"3%\" valign=middle align='center'>\n");

		file.Write("<p>");
		file.Write("<b>");

		sprintf(str, "G:%d", g + 1);
		file.Write(str);

		file.Write("</b>");
		file.Write("</p>");

		file.Write("</td>");

		file.Write("<td width=\"38%\" colspan=2 valign=top halign=center>");

		file.Write("<p align=\"center\">");
		file.Write("<b>");

		file.Write(GroupName[g]);

		file.Write("</b>");
		file.Write("</p>");
		file.Write("</td>");

		file.Write("<td width=\"3%\" colspan=2 valign=top halign=center>");

		file.Write("<p align=\"center\">");
		file.Write("<b>");

		file.Write("AS-NT Corr");

		file.Write("</b>");
		file.Write("</p>");
		file.Write("</td>");

		for (grp = 0; grp < GROUP_COUNT - 1; grp++)
        {
            if (GroupExist[grp])
            {
        		file.Write("<td width=\"4%\" colspan=2 valign=top>");

	        	file.Write("<p>");
		        file.Write("<b>");

                sprintf(str, "#%d", grp + 1);
        		file.Write(str);

        		file.Write("</b>");
	        	file.Write("</p>");
    
	    	    file.Write("</td>");
	    	}
		}

		file.Write("</tr>");

		ind = 0;

        while (ind >= 0)
        {
            maxcorr = 0.0;
            ind = -1;
        
            for (i = 0; i < 100; i++)
            {
                if (QuizGroup[i] == g && !used[i])
                {
                    val = Quiz_I.Quiz[i].Corr;
                    if (val < 0)
                        val = -val;

                    if (val > maxcorr)
                    {
                        maxcorr = val;
						ind = i;
                    }                
                }
            }

            if (ind >= 0)
			{
			    used[ind] = TRUE;
			    
				file.Write("<tr style='height:24.75pt'>");

				file.Write("<td width=\"3%\" valign=middle align='center'>\n");

				file.Write("<p>");
				file.Write("<b>");

				sprintf(str, "%d", ind + 1);
				file.Write(str);

				file.Write("</b>");
				file.Write("</p>");

				file.Write("</td>");

				file.Write("<td width=\"38%\" colspan=2 valign=top halign=center>");

				file.Write("<p align=\"center\">");
				file.Write("<b>");

				file.Write(QuizTextArr[ind]);

				file.Write("</b>");
				file.Write("</p>");
				file.Write("</td>");

				file.Write("<td width=\"3%\" colspan=2 valign=top halign=center>");

				file.Write("<p align=\"center\">");
				file.Write("<b>");

    			ival = round(100.0 * Quiz_I.Quiz[ind].Corr);
	    		sprintf(str, "%d%", ival);
		    	file.Write(str);

				file.Write("</b>");
				file.Write("</p>");
				file.Write("</td>");

				maxcorr = 0;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
				    if (GroupExist[j])
				    {
                        val = Quiz_I.Quiz[ind].Group[j].Corr;

	    				if (j == g)
		    			{
			    			selfcorr = val;
				    		comp = TRUE;
					    }
    					else
	    					comp = TRUE;

		    			if (comp && val > maxcorr)
			    		{
				    		maxcorr = val;
					    	group = j;
					    }
					}
				}

				maxcorr = maxcorr * 0.9;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
				    if (GroupExist[j])
				    {
						val = Quiz_I.Quiz[ind].Group[j].Corr;
                        corrval = val;
                        count = Quiz_I.Quiz[ind].Group[j].Count;
    
                        if (val < 0.0)
                            val = -val;

                        zij = 0.5 * logl((1 + val) / (1 - val));
                        za = 1.96 / sqrtl(count - 3); 
                        low = tanhl(zij - za);
	                    high = tanhl(zij + za);

    			    	file.Write("<td width=\"4%\" colspan=2 valign=top>");
    
    	    			file.Write("<p>");
	    	    		file.Write("<b>");
    
                        if (low <= 0.0 && high >= 0.0)
                            file.Write("-----");
                        else
				    	{
    				    	if (val > maxcorr)
	    				    	file.Write("<span style='color:#009999'>");
    
    	    				if (corrval < 0.0)
	    		    			file.Write("<span style='color:#990099'>");

    	    				ival = round(100.0 * low);
	    	    			sprintf(str, "%d", ival);
		    	    		file.Write(str);

        					ival = round(100.0 * high);
	        				sprintf(str, "-%d", ival);
		        			file.Write(str);
    
	    		    		if (val > maxcorr || corrval < 0.0)
		        	    	    file.Write("</span>");
		        	    }

		    	    	file.Write("</b>");
			    	    file.Write("</p>");

    					file.Write("</td>");
                    }
				}

				file.Write("</tr>");
			}
		}
	}
    file.Write("</table>");
}

/*##################  CalcGroupCorr ##########################
*   Purpose....: Calculate group to group correlations	   	     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CalcGroupCorr()
{
	int e;
	int g1, g2;
	long double rsum;
	long double zx;
   long double zy;
	int count1;
	int sum1;
	int count2;
	int sum2;

	for (g1 = 0; g1 < GROUP_COUNT; g1++)
	    Quiz_I.GroupCorr[g1][g1].Corr = 1.0;

	for (g1 = 0; g1 < GROUP_COUNT; g1++)
	{
		for (g2 = 0; g2 < g1; g2++)
		{
			Quiz_I.GroupCorr[g1][g2].Corr = 0;
		    Quiz_I.GroupCorr[g1][g2].Count = 0;
		    
		    rsum = 0;
			for (e = 0; e < rows; e++)
			{
			    count1 = GroupCount[g1][e];
			    sum1 = GroupSum[g1][e];

			    count2 = GroupCount[g2][e];
			    sum2 = GroupSum[g2][e];

			    if (count1 && count2)
			    {
			        Quiz_I.GroupCorr[g1][g2].Count++;

                    zx = ((long double)sum1 / count1 - Quiz_I.Group[g1].Mean) / Quiz_I.Group[g1].Sd;
					zy = ((long double)sum2 / count2 - Quiz_I.Group[g2].Mean) / Quiz_I.Group[g2].Sd;
	    			rsum += zx * zy;
		    	}
            }
            
			if (Quiz_I.GroupCorr[g1][g2].Count)
			{
				Quiz_I.GroupCorr[g1][g2].Corr = rsum / ((long double)Quiz_I.GroupCorr[g1][g2].Count - 1);
				Quiz_I.GroupCorr[g2][g1].Corr = rsum / ((long double)Quiz_I.GroupCorr[g1][g2].Count - 1);
				Quiz_I.GroupCorr[g2][g1].Count = Quiz_I.GroupCorr[g1][g2].Count;
			}
			else
			{
				Quiz_I.GroupCorr[g1][g2].Corr = 0;
				Quiz_I.GroupCorr[g2][g1].Corr = 0;
				Quiz_I.GroupCorr[g2][g1].Count = 0;
			}
		}
	}
}

/*##################  WriteGroupTable ##########################
*   Purpose....: Write group - group correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteGroupTable(const char *filename)
{
    int g1;
	 int g2;
    int ival;
    long double val;
    long double corrval;
    long double zij;
    long double za;
    long double low;
    long double high;
    int count;
	char str[80];
	TFile file(filename, 0);

    file.Write("<table border=3 cellspacing=0 cellpadding=0>");
        
	file.Write("<tr style='height:24.75pt'>");

	file.Write("<td width=\"3%\" valign=middle align='center'>\n");

	file.Write("<p>");
	file.Write("<b>");

	file.Write("#");

	file.Write("</b>");
	file.Write("</p>");

	file.Write("</td>");

	file.Write("<td width=\"38%\" colspan=2 valign=top halign=center>");

	file.Write("<p align=\"center\">");
	file.Write("<b>");

	file.Write("Group");

	file.Write("</b>");
	file.Write("</p>");
	file.Write("</td>");

	for (g2 = 0; g2 < GROUP_COUNT - 1; g2++)
    {
    	file.Write("<td width=\"4%\" colspan=2 valign=top>");

	    file.Write("<p>");
		file.Write("<b>");

        sprintf(str, "#%d", g2 + 1);
    	file.Write(str);

    	file.Write("</b>");
	    file.Write("</p>");

		file.Write("</td>");
    }

	file.Write("</tr>");

    for (g1 = 0; g1 < GROUP_COUNT - 1; g1++)
    {
        file.Write("<tr style='height:24.75pt'>");

        file.Write("<td width=\"3%\" valign=middle align='center'>\n");

        file.Write("<p>");
        file.Write("<b>");

        sprintf(str, "G:%d", g1 + 1);
        file.Write(str);

        file.Write("</b>");
        file.Write("</p>");

        file.Write("</td>");

		file.Write("<td width=\"38%\" colspan=2 valign=top halign=center>");

    	file.Write("<p align=\"center\">");
	    file.Write("<b>");

		file.Write(GroupName[g1]);

    	file.Write("</b>");
	    file.Write("</p>");
		file.Write("</td>");

        for (g2 = 0; g2 < GROUP_COUNT - 1; g2++)
        {
		    file.Write("<td width=\"4%\" colspan=2 valign=top>");

			file.Write("<p>");
			file.Write("<b>");

			val = Quiz_I.GroupCorr[g1][g2].Corr;
			corrval = val;
			count = Quiz_I.GroupCorr[g1][g2].Count;

		    if (count)
		    {
		        if (val < 0.0)
				    val = -val;

				zij = 0.5 * logl((1 + val) / (1 - val));
				za = 1.96 / sqrtl(count - 3);
				low = tanhl(zij - za);
				high = tanhl(zij + za);

				if (low <= 0.0 && high >= 0.0)
			        file.Write("-----");
				else
				{
				    if (corrval < 0.0)
					    file.Write("<span style='color:#990099'>");

					ival = round(100.0 * low);
					sprintf(str, "%d", ival);
					file.Write(str);

					ival = round(100.0 * high);
					sprintf(str, "-%d", ival);
					file.Write(str);

					if (corrval < 0.0)
					    file.Write("</span>");
				}
		    }
	    }
	}
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
	ProcessReferers();
	ProcessAs();
	ProcessAdd();
	ProcessHBT();
	WriteReferers("referrer.htm");

	CreateReferences();

	InitQuizText();
	WriteAsNtCorrelation("asnt.htm");
	WriteAsAspieCorrelation("asaspie.htm");
	WriteAddNtCorrelation("addnt.htm");
	WriteAddAsCorrelation("addas.htm");
	WriteHbtNtCorrelation("hbtnt.htm");
	WriteHbtAsCorrelation("hbtas.htm");
	WriteRefererNtCorrelation("flashnt.htm", "dickflash.com", "dickflash.com");
	WriteRefererAsCorrelation("flashas.htm", "dickflash.com", "dickflash.com");
	WriteRefererNtCorrelation("musicnt.htm", "99musik.com/forum", "99musik.com/forum");
	WriteRefererAsCorrelation("musicas.htm", "99musik.com/forum", "99musik.com/forum");
	WriteRefererNtCorrelation("opiumnt.htm", "opiumse", "66.98.216.44/~opiumse/viewtopic.php?id=20888");
	WriteRefererNtCorrelation("hiphopnt.htm", "whoa.nu", "whoa.nu");
	WriteRefererNtCorrelation("compnt.htm", "pellesoft.se", "pellesoft.se/communicate/forum/view.aspx?msgid=186984");
	WriteRefererAsCorrelation("compas.htm", "pellesoft.se", "pellesoft.se/communicate/forum/view.aspx?msgid=186984");

	CalcCorrelation();
	WriteGroupCorrTable("grpcorr1.htm");

	CalcGroupCorr();
	WriteGroupTable("group1.htm");

	WriteResult("quiz1.dat");
}

