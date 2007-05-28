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
# quiz.cpp
# Basic quiz class
#                                        
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <math.h>

#include "quiz.h"
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

#define CALC_QUESTION_CORR       // turn on to calculate question correlations

#define MAX_GLOBAL_QUESTIONS       1024

static int GlobalArr[MAX_GLOBAL_QUESTIONS];

static int GlobalCorrInited = FALSE;
static int GlobalCorrCount[MAX_GLOBAL_QUESTIONS][MAX_GLOBAL_QUESTIONS];
static long double GlobalCorrArr[MAX_GLOBAL_QUESTIONS][MAX_GLOBAL_QUESTIONS];

static int GlobalInited = FALSE;
static TQuiz *GlobalTopQuiz[MAX_GLOBAL_QUESTIONS];
static int GlobalTopQuestion[MAX_GLOBAL_QUESTIONS];
static int GlobalAsNtCorrCount[MAX_GLOBAL_QUESTIONS];
static long double GlobalAsNtCorrSum[MAX_GLOBAL_QUESTIONS];
static long double GlobalChi2[MAX_GLOBAL_QUESTIONS];
static int GlobalCatCount[MAX_GLOBAL_QUESTIONS];

static long double GlobalGroupCorrSum[MAX_GLOBAL_QUESTIONS][MAX_GROUP_COUNT];
static int GlobalGroupCorrCount[MAX_GLOBAL_QUESTIONS][MAX_GROUP_COUNT];

static long double GlobalPcaSum[MAX_GLOBAL_QUESTIONS][4];
static int GlobalPcaCount[MAX_GLOBAL_QUESTIONS][4];

/*##########################################################################
#
#   Name       : TQuiz::TQuiz
#
#   Purpose....: Constructor for TQuiz
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz::TQuiz(int Questions)
  : PopCorr(Questions),
	 All(Questions),
	 LowAs(Questions),
	 As(Questions),
	 AsMale(Questions),
	 AsFemale(Questions),
	 Add(Questions),
	 AddMale(Questions),
	 AddFemale(Questions),
	 Aspie(Questions),
	 AspieMale(Questions),
	 AspieFemale(Questions),
	 YoungMale(Questions),
	 YoungFemale(Questions),
	 Mix(Questions),
	 MixMale(Questions),
	 MixFemale(Questions),
	 Nt(Questions),
	 NtMale(Questions),
	 NtFemale(Questions),
	 Ts(Questions),
	 Hyperlexia(Questions),
	 Dyspraxia(Questions),
	 Dyslexia(Questions),
	 Dyscalculia(Questions),
	 OCD(Questions),
	 ODD(Questions),
	 Synaesthesia(Questions),
	 PA(Questions),
	 Dysgraphia(Questions),
	 Bipolar(Questions),
	 Schizophrenia(Questions),
	 SocialPhobia(Questions),
	 LowIQ(Questions),
	 HighIQ(Questions),
	 NoRef("", "No referrer"),
     NTRef("", "NT control group"),
     AspieRef("", "Aspie control group"),
     DxAsRef("", "Diagnosed AS/HFA/PDD"),
     DxTsRef("", "Diagnosed Tourette"),
     DxAddRef("", "Diagnosed ADD/ADHD"),
     SelfAsRef("", "Self-diagnosed AS/HFA/PDD"),
     SelfTsRef("", "Self-diagnosed Tourette"),
     SelfAddRef("", "Self-diagnosed ADD/ADHD"),
     MaleAsRef("", "Male AS/HFA/PDD"),
     FemaleAsRef("", "Female AS/HFA/PDD"),
     MaleNonAsRef("", "Male non-AS/HFA/PDD"),
	 FemaleNonAsRef("", "Female non-AS/HFA/PDD"),
	 HyperlexiaRef("", "Hyperlexia"),
	 DyspraxiaRef("", "Dyspraxia"),
	 DyslexiaRef("", "Dyslexia"),
	 DyscalculiaRef("", "Dyscalculia"),
	 OCDRef("", "OCD"),
	 ODDRef("", "ODD"),
	 SynaesthesiaRef("", "Synaesthesia"),
	 PARef("", "Prosapagnosia"),
	 DysgraphiaRef("", "Dysgraphia"),
	 BipolarRef("", "Bipolar"),
	 SchizophreniaRef("", "Schizophrenia"),
	 SocialPhobiaRef("", "Social phobia"),
	 AmerindianRef("", "Native American"),
	 AfroAmericanRef("", "Afroamerican"),
	 MixedAfroAmericanRef("", "Mixed American"),
	 AfricanRef("", "African"),
	 MixedAfricanRef("", "Mixed African"),
	 HispanicRef("", "Hispanic"),
	 WhiteRef("", "European"),
	 ArabRef("", "Middle East & North African"),
	 AsianRef("", "Asian")
{
    int i;
    int g;
    int g1, g2;

    N = Questions;

    RefCount = 0;
    UseNtResult = TRUE;

    for (i = 0; i < MAX_REFERERS; i++)
        RefArr[i] = 0;

    for (i = 0; i < MAX_CROSS; i++)
        CrossQuiz[i] = 0;

    for (i = 0; i < N; i++)
    {
        Quiz[i].Text = "NO TEXT";
        Quiz[i].AsCount = 0;
        Quiz[i].AsMean = 0;
        Quiz[i].AsSd = 0;
        Quiz[i].NtCount = 0;
        Quiz[i].NtMean = 0;
        Quiz[i].NtSd = 0;
        Quiz[i].Chi2 = 0;
        Quiz[i].Corr = 0;
        Quiz[i].Used = FALSE;
        Quiz[i].MyGroup = 0;
        Quiz[i].Reverse = FALSE;
        Quiz[i].CrossQuiz = 0;
        Quiz[i].CrossInd = 0;
        Quiz[i].GlobalId = -1;
        Quiz[i].Changed = FALSE;

        for (g = 0; g < MAX_GROUP_COUNT; g++)
        {
            Quiz[i].Group[g].Corr = 0;
            Quiz[i].Group[g].Count = 0;
        }

        for (g = 0; g < MAX_PCA_AXIS; g++)
        {
            Quiz[i].Pca[g] = 0;
            Quiz[i].MalePca[g] = 0;
            Quiz[i].FemalePca[g] = 0;
            Quiz[i].YoungPca[g] = 0;
            Quiz[i].OldPca[g] = 0;
			Quiz[i].AsPca[g] = 0;
			Quiz[i].MixedPca[g] = 0;
		}
	}

	for (g1 = 0; g1 < MAX_GROUP_COUNT; g1++)
	{
		for (g2 = 0; g2 < MAX_GROUP_COUNT; g2++)
		{
			GroupCorr[g1][g2].Corr = 0;
			GroupCorr[g1][g2].Count = 0;
		}
	}

	for (g = 0; g < MAX_GROUP_COUNT; g++)
	{
		Group[g].Mean = 0;
		Group[g].Sd = 0;
	}

	GroupValArr = 0;
	GroupValCount = 0;

    Init();
}

/*##########################################################################
#
#   Name       : TQuiz::~TQuiz
#
#   Purpose....: Destructor for TQuiz
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz::~TQuiz()
{
    int i;
        
    for (i = 0; i < MAX_REFERERS; i++)
        if (RefArr[i])
            delete RefArr[i];

    if (GroupValArr)
        delete GroupValArr;
}

/*##########################################################################
#
#   Name       : TQuiz::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz::Init()
{
	int i;
	int g;

    for (i = 0; i < N; i++)
    {
        Quiz[i].Text = "NO TEXT";
        Quiz[i].Reverse = FALSE;
        Quiz[i].GlobalId = -1;
    }

    for (g = 0; g < MAX_GROUP_COUNT; g++)
    {
		Group[g].PosName = "NO NAME";
		Group[g].NegName = "NO NAME";
	}

#ifdef ENGLISH

	Group[GROUP_ASPIE_BIOLOGY].PosName = "Aspie biology";
	Group[GROUP_ASPIE_BIOLOGY].NegName = "NT biology";

	Group[GROUP_NT_BIOLOGY].PosName = "Motor problem";
	Group[GROUP_NT_BIOLOGY].NegName = "Motor";

	Group[GROUP_SENSORY].PosName = "Perception";
	Group[GROUP_SENSORY].NegName = "Perception problem";

	Group[GROUP_ASPIE_TALENT].PosName = "Aspie ability";
	Group[GROUP_ASPIE_TALENT].NegName = "Aspie ability problem";

	Group[GROUP_NT_TALENT].PosName = "NT ability problem";
	Group[GROUP_NT_TALENT].NegName = "NT ability";

	Group[GROUP_ASPIE_SOCIAL].PosName = "Aspie social";
	Group[GROUP_ASPIE_SOCIAL].NegName = "NT social";

	Group[GROUP_ASPIE_COMM].PosName = "Aspie instinct";
	Group[GROUP_ASPIE_COMM].NegName = "Aspie instinct problem";

	Group[GROUP_ASPIE_NVC].PosName = "Aspie communication";
	Group[GROUP_ASPIE_NVC].NegName = "Aspie communication problem";

	Group[GROUP_NONVERBAL].PosName = "NT communication problem";
	Group[GROUP_NONVERBAL].NegName = "NT communication";

	Group[GROUP_SEX].PosName = "Sexual deviation";
	Group[GROUP_SEX].NegName = "Sexual normality";

	Group[GROUP_MIXED].PosName = "Aspie mixed";
	Group[GROUP_MIXED].NegName = "NT mixed";

#endif

#ifdef SWEDISH

	Group[GROUP_ASPIE_BIOLOGY].PosName = "Aspie biologi";
	Group[GROUP_ASPIE_BIOLOGY].NegName = "NT biologi";

	Group[GROUP_NT_BIOLOGY].PosName = "Motorik problem";
	Group[GROUP_NT_BIOLOGY].NegName = "Motorik";

	Group[GROUP_SENSORY].PosName = "Perception";
	Group[GROUP_SENSORY].NegName = "Perception problem";

	Group[GROUP_ASPIE_TALENT].PosName = "Aspie talang";
	Group[GROUP_ASPIE_TALENT].NegName = "Aspie talang problem";

	Group[GROUP_NT_TALENT].PosName = "NT talang problem";
	Group[GROUP_NT_TALENT].NegName = "NT talang";

	Group[GROUP_ASPIE_SOCIAL].PosName = "Aspie social";
	Group[GROUP_ASPIE_SOCIAL].NegName = "NT social";

	Group[GROUP_ASPIE_COMM].PosName = "Aspie instinkt";
	Group[GROUP_ASPIE_COMM].NegName = "Aspie instinkt problem";

	Group[GROUP_ASPIE_NVC].PosName = "Aspie kommunikation";
	Group[GROUP_ASPIE_NVC].NegName = "Aspie kommunikation problem";

	Group[GROUP_NONVERBAL].PosName = "NT kommunikation problem";
	Group[GROUP_NONVERBAL].NegName = "NT kommunikation";

	Group[GROUP_SEX].PosName = "Avvikande sexualitet";
	Group[GROUP_SEX].NegName = "Normal sexualitet";

	Group[GROUP_MIXED].PosName = "Aspie blandat";
	Group[GROUP_MIXED].NegName = "NT blandat";

#endif
}

/*##################  TQuiz::round ##########################
*   Purpose....: round long double to int       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::round(long double val)
{
	return (int)(val + 0.5);
}

/*##################  TQuiz::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::GetPcaCount()
{
	return 2;
}

/*##################  TQuiz::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::GetCatCount(int Question)
{
	return 3;
}

/*##################  TQuiz::DefineCross ##########################
*   Purpose....: Define cross reference quiz 					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::DefineCross(int id, TQuiz *quiz)
{
    if (id >= 0 && id < MAX_CROSS)
		CrossQuiz[id] = quiz;
}

/*##################  TQuiz::DefineID ##########################
*   Purpose....: Define global ID for question 				       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::DefineID(int Question, int GlobalId)
{
    if (Question > 0 && Question <= MAX_QUESTIONS)
        Quiz[Question - 1].GlobalId = GlobalId - 1;
}

/*##################  TQuiz::DefineText ##########################
*   Purpose....: Define text for question 				       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::DefineText(int Question, const char *Text, int Group)
{
    if (Question > 0 && Question <= MAX_QUESTIONS)
    {
        Quiz[Question - 1].Text = Text;
        Quiz[Question - 1].MyGroup = Group;
    }
}

/*##################  TQuiz::RedefineText ##########################
*   Purpose....: Redefine a previous text    				       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::RedefineText(int Question, int GlobalId, const char *Text)
{
    if (Question > 0 && Question <= MAX_QUESTIONS)
    {
        Quiz[Question - 1].GlobalId = GlobalId - 1;
        Quiz[Question - 1].Text = Text;
        Quiz[Question - 1].Changed = TRUE;
    }
}

/*##################  TQuiz::DefineGlobalId ##########################
*   Purpose....: Define global ID for question 					            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::DefineGlobalId(int id, int GlobalId)
{
    if (id >= 0 && id < N)
        if (GlobalId >= 0 && GlobalId < MAX_GLOBAL_QUESTIONS)
            if (!GlobalArr[GlobalId])
            {
        		GlobalArr[GlobalId] = TRUE;
        		Quiz[id].GlobalId = GlobalId;
            }
}

/*##################  TQuiz::CheckCross ##########################
*   Purpose....: Check cross-references 					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::CheckCross()
{
    int q;
    int qc;
    int group;
    int i;
    int curr;
    TQuiz *quiz;
    const char *text;
    int CrossArr[MAX_CROSS];
    int cross;

    for (q = 0; q < N; q++)
    {
        quiz = this;
        group = quiz->Quiz[q].MyGroup;
        text = quiz->Quiz[q].Text;
        curr = q;

        if (quiz->Quiz[q].CrossQuiz == 0 && quiz->Quiz[q].GlobalId < 0)
            printf("Missing global ID, question:%d\n", q);

        for (cross = 0; cross < MAX_CROSS; cross++)
            CrossArr[cross] = -1;

        while (quiz)
        {
            for (cross = 0; cross < MAX_CROSS; cross++)
                if (quiz == CrossQuiz[cross])
                    CrossArr[cross] = curr;
        
            if (quiz->Quiz[curr].MyGroup != group)
                printf("Group conflict, question:%d %d should be %d\n",
                         q, quiz->Quiz[curr].MyGroup, group);

            if (strcmp(quiz->Quiz[curr].Text, text))
                printf("Text conflict, question:%d <%s> should be <%s>\n",
                         q, quiz->Quiz[curr].Text, text);
                    

            i = quiz->Quiz[curr].CrossInd;
            quiz = quiz->Quiz[curr].CrossQuiz;
            curr = i;
        }

        for (cross = 0; cross < MAX_CROSS; cross++)
            if (CrossQuiz[cross])
                for (qc = 0; qc < CrossQuiz[cross]->N; qc++)
                    if (qc != CrossArr[cross])
                        if (!strcmp(CrossQuiz[cross]->Quiz[qc].Text, text))
                            printf("Text duplicate, question:%d in cross %d:%d",
                                q, cross, qc);
                    
    }
}

/*##################  TQuiz::GetGlobalQuestionText ##########################
*   Purpose....: Get global question text from ID   		     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
const char *TQuiz::GetGlobalQuestionText(int GlobalId)
{
	int cross;
	int q;
	TQuiz *quiz;
	char str[128];

    for (q = 0; q < N; q++)
        if (Quiz[q].GlobalId == GlobalId)
            return Quiz[q].Text;

    for (cross = 0; cross < MAX_CROSS; cross++)
    {
        quiz = CrossQuiz[cross];
        if (quiz)
        {
				for (q = 0; q < quiz->N; q++)
            {
                if (quiz->Quiz[q].GlobalId == GlobalId)
                    return quiz->Quiz[q].Text;
            }
        }
    }

    return "";
}

/*##################  TQuiz::WritePhpQuestions ##########################
*   Purpose....: Write questions using global IDs for php questionary		     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePhpQuestions(const char *filename)
{
	TFile file(filename, 0);
	int i;
	int cross;
	int q;
	TQuiz *quiz;
	int found;
	char str[128];

    for (i = 0; i < N; i++)
    {
        found = FALSE;
        
		if (Quiz[i].GlobalId >= 0 && !Quiz[i].Changed)
		{
            quiz = GlobalTopQuiz[Quiz[i].GlobalId];
            q = GlobalTopQuestion[Quiz[i].GlobalId];
            if (quiz)
            {
                sprintf(str, " $m[%d] = \"", i);
                file.Write(str);
                file.Write(quiz->Quiz[q].Text);
                file.Write("\";\n");                            
                found = TRUE;
            }
        } 

        if (!found)
        {
            sprintf(str, " $m[%d] = \"", i);
            file.Write(str);
            file.Write(Quiz[i].Text);
            file.Write("\";\n");                            
        }
    }
}

/*##################  TQuiz::WriteSetupTexts ##########################
*   Purpose....: Write SetupText template for quiz  		     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteSetupTexts(const char *filename)
{
	TFile file(filename, 0);
	int i;
	int cross;
	int q;
	TQuiz *quiz;
	int found;
	char str[128];
	int group;

    for (i = 0; i < N; i++)
    {
        found = FALSE;
        
        if (Quiz[i].GlobalId >= 0)
        {            
            for (cross = 0; cross < MAX_CROSS && !found; cross++)
            {
                quiz = CrossQuiz[cross];
                if (quiz)
                {
                    for (q = 0; q < quiz->N && !found; q++)
                    {
                        if (Quiz[i].GlobalId == quiz->Quiz[q].GlobalId)
                        {
                            if (quiz->Quiz[q].Reverse)
                            {
                                sprintf(str, "  Quiz[%d].Reverse = TRUE;\n", i);
                                file.Write(str);
                            }
                            found = TRUE;
                        }
                    }
                }
            }
        } 
    }

    for (i = 0; i < N; i++)
    {
        group = GROUP_MIXED;
        found = FALSE;
        
        if (Quiz[i].GlobalId >= 0)
        {            
            for (cross = 0; cross < MAX_CROSS && !found; cross++)
            {
                quiz = CrossQuiz[cross];
                if (quiz)
                {
                    for (q = 0; q < quiz->N && !found; q++)
                    {
                        if (Quiz[i].GlobalId == quiz->Quiz[q].GlobalId)
                        {    
                            group = quiz->Quiz[q].MyGroup;
                            found = TRUE;
                        }
                    }
                }
            }
        } 

        if (!found)
            group = Quiz[i].MyGroup;

        sprintf(str, "  Quiz[%d].MyGroup = ", i);
        file.Write(str);
        switch (group)
        {
            case GROUP_ASPIE_BIOLOGY:
                file.Write("GROUP_ASPIE_BIOLOGY");
                break;

            case GROUP_NT_BIOLOGY:
                file.Write("GROUP_NT_BIOLOGY");
                break;

            case GROUP_SENSORY:
                file.Write("GROUP_SENSORY");
                break;

            case GROUP_ASPIE_TALENT:
                file.Write("GROUP_ASPIE_TALENT");
                break;

            case GROUP_NT_TALENT:
                file.Write("GROUP_NT_TALENT");
                break;

            case GROUP_ASPIE_SOCIAL:
                file.Write("GROUP_ASPIE_SOCIAL");
                break;

            case GROUP_ASPIE_COMM:
                file.Write("GROUP_ASPIE_COMM");
                break;

            case GROUP_ASPIE_NVC:
                file.Write("GROUP_ASPIE_NVC");
                break;

            case GROUP_NONVERBAL:
                file.Write("GROUP_NONVERBAL");
                break;

            case GROUP_SEX:
                file.Write("GROUP_SEX");
                break;

            default:
                file.Write("GROUP_MIXED");
                break;
        }
        file.Write(";\n");                            
    }

    for (i = 0; i < N; i++)
    {
        found = FALSE;
        
        if (Quiz[i].GlobalId >= 0 && !Quiz[i].Changed)
        {            
            quiz = GlobalTopQuiz[Quiz[i].GlobalId];
            q = GlobalTopQuestion[Quiz[i].GlobalId];
            if (quiz)
            {
                sprintf(str, "  Quiz[%d].Text = \"", i);
                file.Write(str);
                file.Write(quiz->Quiz[q].Text);
                file.Write("\";\n");                            
                found = TRUE;
            }
        } 

        if (!found)
        {
            sprintf(str, "  Quiz[%d].Text = \"", i);
            file.Write(str);
            file.Write(Quiz[i].Text);
            file.Write("\";\n");                            
        }
    }
}

/*##################  TQuiz::WriteSetupCross ##########################
*   Purpose....: Write SetupCross procedure for quiz		     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteSetupCross(const char *filename)
{
	TFile file(filename, 0);
	int i;
	int cross;
	int q;
	int clink;
	int cq;
	TQuiz *quiz;
	TQuiz *cquiz;
	TQuiz *topquiz;
	int topq;
	int found;
	char str[128];
	int GlobalId;

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	{
	    if (!GlobalArr[i])
	    {
	        GlobalId = i;
	        break;
	    }
    }
    
    for (i = 0; i < N; i++)
    {
        found = FALSE;
        
        if (Quiz[i].GlobalId >= 0)
        {            
            for (cross = 0; cross < MAX_CROSS && !found; cross++)
            {
                quiz = CrossQuiz[cross];
                if (quiz)
                {
                    for (q = 0; q < quiz->N && !found; q++)
                    {
                        if (Quiz[i].GlobalId == quiz->Quiz[q].GlobalId)
                        {
                            topq = q;
                            topquiz = quiz;
                            
                            for (clink = cross + 1; clink < MAX_CROSS; clink++)
                            {
                                cquiz = CrossQuiz[clink];
                                if (cquiz)
                                {
                                    for (cq = 0; cq < cquiz->N; cq++)
                                    {
                                        if (cquiz->Quiz[cq].CrossQuiz == topquiz)
                                        {
                                            if (cquiz->Quiz[cq].CrossInd == topq)
                                            {
                                                topquiz = cquiz;
                                                topq = cq;
                                            }
                                        }
                                    }
                                }
                            }
                        
                            file.Write("    DefineCross(Quiz");
                            topquiz->WriteName(file);
                            sprintf(str, ", %d, %d);\n", i, topq);
                            file.Write(str);
                            found = TRUE;
                        }
                    }
                }
            }
        } 

        if (!found)
        {
            sprintf(str, "  DefineGlobalId( %d, %d);\n", i, GlobalId);
            file.Write(str);
            GlobalId++;
        }
    }
}

/*##################  TQuiz::CalcAsNtDiff ##########################
*   Purpose....: Calculate accumulated As & Nt diff for whole population         	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::CalcAsNtDiff(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS], int *AsDiff, int *NtDiff)
{
    int answers;
    int e;
    int i;
    int ival;
    int astot;
    int nttot;
    int assum;
    int ntsum;
    int w;
    int asresult;
    int ntresult;
    int diff;
    int ascnt = 0;
    int errorcnt = 0;

    answers = All.ValueCount;

    *AsDiff = 0;
    *NtDiff = 0;

    for (e = 0; e < answers; e++)
    {
        astot = 0;
        nttot = 0;
        assum = 0;
        ntsum = 0;
    
		for (i = 0; i < N; i++)
		{
			ival = All.ValArr[e].Quiz[i];
			if (ival)
			{
			    w = Asw[i];
				assum += w * (ival - 1);
				astot += w;

				 w = Ntw[i];
				ntsum += w * (ival - 1);
				nttot += w;
			}
		}

		if (astot)
    		asresult = assum * 100 / astot;
        else
            asresult = 0;

        if (nttot)
    		ntresult = ntsum * 100 / nttot;
        else
            ntresult = 0;
            
		diff = asresult - ntresult;

        if (All.ValArr[e].As)
        {
            ascnt++;
            *AsDiff += diff;

            if (diff < 0)
                errorcnt++;
        }
        else
            *NtDiff -= diff;
	}

	*AsDiff = *AsDiff * 100 / ascnt;
	*NtDiff = *NtDiff * 100 / (answers - ascnt);

	return errorcnt * 10000 / ascnt;
}

/*##################  TQuiz::OptimizeAsOne ##########################
*   Purpose....: Optimize As & Nt weights, one iteration          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::OptimizeAsOne(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS])
{
    int AswCnt;
    int NtwCnt;
    int AsDiff;
    int NtDiff;
    int BestQ;
    int BestIsAs;
    int BestIsInc;
    int CurrDiff;
    int q;
    int diff;
    int err;
    static int ntc = 2;

    err = CalcAsNtDiff(Asw, Ntw, &AsDiff, &NtDiff);
            
    CurrDiff = AsDiff + ntc * NtDiff - 10 * err / ntc;
    BestQ = -1;
    BestIsAs = FALSE;
    BestIsInc = FALSE;

    AswCnt = 0;
    NtwCnt = 0;
    
    for (q = 0; q < N; q++)
    {
        if (Asw[q])
            AswCnt++;

        if (Ntw[q])
            NtwCnt++;
    } 
               
	for (q = 0; q < N; q++)
	{
	    if (Asw[q] < 5 && Ntw[q] == 0)
	    {
            Asw[q]++;
	    	err = CalcAsNtDiff(Asw, Ntw, &AsDiff, &NtDiff);
		    Asw[q]--;

    		diff = AsDiff + ntc * NtDiff - 10 * err / ntc;
	    	if (diff > CurrDiff)
		    {
			    BestQ = q;
    			BestIsAs = TRUE;
	    		BestIsInc = TRUE;
		    }
		}

		if (Asw[q] && AswCnt > 15)
		{
	        Asw[q]--;
			err = CalcAsNtDiff(Asw, Ntw, &AsDiff, &NtDiff);
			Asw[q]++;

			diff = AsDiff + ntc * NtDiff - 10 * err / ntc;
			if (diff > CurrDiff)
		    {
                BestQ = q;
                BestIsAs = TRUE;
                BestIsInc = FALSE;
            }
        }

        if (Ntw[q] < 5 && Asw[q] == 0)
        {
            Ntw[q]++;
            err = CalcAsNtDiff(Asw, Ntw, &AsDiff, &NtDiff);
            Ntw[q]--;
        
            diff = AsDiff + ntc * NtDiff - 10 * err / ntc;
            if (diff > CurrDiff)
            {
                BestQ = q;
                BestIsAs = FALSE;
                BestIsInc = TRUE;
            }
        }
        
        if (Ntw[q] && NtwCnt > 15)
        {        
            Ntw[q]--;
            err = CalcAsNtDiff(Asw, Ntw, &AsDiff, &NtDiff);
            Ntw[q]++;
        
            diff = AsDiff + ntc * NtDiff - 10 * err / ntc;
            if (diff > CurrDiff)
            {
                BestQ = q;
                BestIsAs = FALSE;
                BestIsInc = FALSE;
            }
        }
    }

    if (BestQ >= 0)
    {
        if (BestIsAs)
        {
            if (BestIsInc)
                Asw[BestQ]++;
            else
                Asw[BestQ]--;
        }
        else
        {
            if (BestIsInc)
                Ntw[BestQ]++;
            else
                Ntw[BestQ]--;
        }
    }

    err = CalcAsNtDiff(Asw, Ntw, &AsDiff, &NtDiff);

	printf("Error: %d.%02d As: %d.%02d, Nt: %d.%02d ", err / 100, err % 100, AsDiff / 100, AsDiff % 100, NtDiff / 100, NtDiff % 100);
	printf("\n");

	if (BestQ >= 0)
	    return TRUE;
	else
	    return FALSE;	    
}

/*##################  TQuiz::WriteAsWeights ##########################
*   Purpose....: Write As & Nt weights                        	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAsWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS])
{
	 int i;

    printf("    static int Asw[200] = {\n");

    for (i = 0; i < 200; i++)
    {
        printf("%4d", Asw[i]);

        if (i == 199)
            printf("};\n\n");
        else
        {
            if (i % 10 == 9)
                printf(",\n           ");
            else
                printf(",");
        }
    }

    printf("    static int Ntw[200] = {\n");

    for (i = 0; i < 200; i++)
    {
        printf("%4d", Ntw[i]);

        if (i == 199)
            printf("};\n\n");
        else
        {
            if (i % 10 == 9)
                printf(",\n           ");
            else
                printf(",");
        }
    }
}

/*##################  TQuiz::WriteWikiWeights ##########################
*   Purpose....: Write As & Nt weights for wikipedia              	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteWikiWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS])
{
	int i;

    for (i = 0; i < N; i++)
    {
        printf("* ");
        printf(Quiz[i].Text);

        if (Asw[i] || Ntw[i])
            printf(" (%d %d)", Asw[i], Ntw[i]);        

        printf("\n\n");
    }
}

/*##################  TQuiz::OptimizeAsWeights ##########################
*   Purpose....: Optimize As & Nt weights                        	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::OptimizeAsWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS])
{
    int i;

    for (i = 0; i < 1000; i++)
        if (!OptimizeAsOne(Asw, Ntw))
            break;

    WriteAsWeights(Asw, Ntw);
    WriteWikiWeights(Asw, Ntw);
}

/*##################  TQuiz::FindReferer ##########################
*   Purpose....: Find referer in array    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TReferer *TQuiz::FindReferer(char *Referer)
{
    int i;
	TReferer *ref;

	if (strlen(Referer) == 0)
		return &NoRef;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(Referer))
		    return ref;
	}
	return 0;
}

/*##################  TQuiz::AddReferer ##########################
*   Purpose....: Add referer to array    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TReferer *TQuiz::AddReferer(char *Search, char *Ref)
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

/*##################  TQuiz::SortReferers ##########################
*   Purpose....: Sort referer array      					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::SortReferers()
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

/*##################  TQuiz::DefineNt ##########################
*   Purpose....: Define NT control group    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::DefineNt(char *Referer)
{
	TReferer *ref;

	ref = FindReferer(Referer);
	if (ref)
	{
		ref->NT = TRUE;
		if (UseNtResult)
		{
    		NTRef.AsResult += ref->AsResult;
    		NTRef.NtResult += ref->NtResult;
	    	NTRef.Count += ref->Count;
    		NTRef.ResultNt += ref->ResultNt;
	    	NTRef.ResultMixed += ref->ResultMixed;
		    NTRef.ResultAs += ref->ResultAs;
        }
        else
        {
    		NTRef.Result += ref->Result;
	    	NTRef.Count += ref->Count;
    		NTRef.Result0_59 += ref->Result0_59;
	    	NTRef.Result60_99 += ref->Result60_99;
		    NTRef.Result100_139 += ref->Result100_139;
		    NTRef.Result140_200 += ref->Result140_200;
		}
	}
}

/*##################  TQuiz::DefineAspie ##########################
*   Purpose....: Define Aspie control group    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::DefineAspie(char *Referer)
{
	TReferer *ref;

	ref = FindReferer(Referer);
	if (ref)
	{
		 ref->Aspie = TRUE;
		 if (UseNtResult)
		 {
    		 AspieRef.AsResult += ref->AsResult;
    		 AspieRef.NtResult += ref->NtResult;
	    	 AspieRef.Count += ref->Count;
		     AspieRef.ResultNt += ref->ResultNt;
    		 AspieRef.ResultMixed += ref->ResultMixed;
	    	 AspieRef.ResultAs += ref->ResultAs;
		 }
		 else
		 {
    		 AspieRef.Result += ref->Result;
	    	 AspieRef.Count += ref->Count;
		     AspieRef.Result0_59 += ref->Result0_59;
    		 AspieRef.Result60_99 += ref->Result60_99;
	    	 AspieRef.Result100_139 += ref->Result100_139;
		     AspieRef.Result140_200 += ref->Result140_200;
		 }
	}
}

/*##################  TQuiz::DefineCross ##########################
*   Purpose....: Define cross-reference                 	      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::DefineCross(TQuiz *quiz, int MyQuestion, int CrossQuestion)
{
    Quiz[MyQuestion].CrossQuiz = quiz;
    Quiz[MyQuestion].CrossInd = CrossQuestion;
}

/*##################  TQuiz::GetPop ##########################
*   Purpose....: Get population from type                 	      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TPopulation *TQuiz::GetPop(int PopType)
{
    switch (PopType)
    {
	    case POP_TYPE_ALL:
			return &All;

	    case POP_TYPE_AS:
			return &As;

		case POP_TYPE_ASPIE:
			return &Aspie;

		case POP_TYPE_ADD:
			return &Add;

		case POP_TYPE_NT:
			return &Nt;

		case POP_TYPE_HYPERLEXIA:
			return &Hyperlexia;

		case POP_TYPE_DYSPRAXIA:
			return &Dyspraxia;

		case POP_TYPE_DYSLEXIA:
			return &Dyslexia;

		case POP_TYPE_DYSCALCULIA:
			return &Dyscalculia;

		case POP_TYPE_OCD:
			return &OCD;

		case POP_TYPE_ODD:
			return &ODD;

		case POP_TYPE_SYNAESTHESIA:
			return &Synaesthesia;

		case POP_TYPE_PA:
			return &PA;

		case POP_TYPE_DYSGRAPHIA:
			return &Dysgraphia;

		case POP_TYPE_BIPOLAR:
			return &Bipolar;

		case POP_TYPE_TS:
			return &Ts;

		case POP_TYPE_SCHIZOPHRENIA:
			return &Schizophrenia;

		case POP_TYPE_SOCIAL_PHOBIA:
			return &SocialPhobia;

		case POP_TYPE_LOW_IQ:
			return &LowIQ;

		case POP_TYPE_HIGH_IQ:
			return &HighIQ;

		default:
			return 0;
	}
}

/*##################  TQuiz::ClearUsed ##########################
*   Purpose....: Clear used in this quiz and cross-linked quizes 	    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::ClearUsed(int Question)
{
    TQuiz *quiz;
    int i;

    quiz = this;

    while (quiz)
    {
        quiz->Quiz[Question].Used = FALSE;
        i = quiz->Quiz[Question].CrossInd;
        quiz = quiz->Quiz[Question].CrossQuiz;
        Question = i;        
    }
}

/*##################  TQuiz::ClearUsed ##########################
*   Purpose....: Clear all used in this quiz and cross-linked quizes 	    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::ClearUsed()
{
    int i;
    int cross;

    for (i = 0; i < N; i++)
        ClearUsed(i);

    for (cross = 0; cross < MAX_CROSS; cross++)
        if (CrossQuiz[cross])
            CrossQuiz[cross]->ClearUsed();
}

/*##################  TQuiz::GetTopQuizCorr ##########################
*   Purpose....: Get top node of higest correlated quiz question     	    #
*              : Does not update used field
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TQuiz *TQuiz::GetTopQuizCorr(int *Question)
{
    TQuiz *CurrQuiz;
    TQuiz *TopQuiz;
    int i;
    long double corr;
    long double maxcorr;
    int q;
    int CurrQuestion;
    int cross;
    
    maxcorr = -1;
    TopQuiz = 0;

    for (q = 0; q < N; q++)
    {
        CurrQuiz = this;
        CurrQuestion = q;

        while (CurrQuiz)
        {
            if (!CurrQuiz->Quiz[CurrQuestion].Used)
            {
//                corr =  CurrQuiz->Quiz[CurrQuestion].Pca[0] - 
//                        CurrQuiz->Quiz[CurrQuestion].Pca[1];
                corr = CurrQuiz->Quiz[CurrQuestion].Corr;
                if (corr < 0)
                    corr = -corr;

                if (corr > maxcorr)
                {
                    TopQuiz = this;
                    *Question = q;
                    maxcorr = corr;
                }
            }

            i = CurrQuiz->Quiz[CurrQuestion].CrossInd;
            CurrQuiz = CurrQuiz->Quiz[CurrQuestion].CrossQuiz;
            CurrQuestion = i;
        }
    }

    for (cross = 0; cross < MAX_CROSS; cross++)
    {
        if (CrossQuiz[cross])
        {
            for (q = 0; q < CrossQuiz[cross]->N; q++)
            {
                CurrQuiz = CrossQuiz[cross];
                CurrQuestion = q;

                while (CurrQuiz)
                {
                    if (!CurrQuiz->Quiz[CurrQuestion].Used)
                    {
//                        corr =  CurrQuiz->Quiz[CurrQuestion].Pca[0] - 
//                                CurrQuiz->Quiz[CurrQuestion].Pca[1];
                        corr = CurrQuiz->Quiz[CurrQuestion].Corr;
                        if (corr < 0)
                            corr = -corr;

						if (corr > maxcorr)
						{
							TopQuiz = CrossQuiz[cross];
							*Question = q;
							maxcorr = corr;
						}
					}

					i = CurrQuiz->Quiz[CurrQuestion].CrossInd;
					CurrQuiz = CurrQuiz->Quiz[CurrQuestion].CrossQuiz;
					CurrQuestion = i;
				}
			}
		}
    }

    return TopQuiz;
}

/*##################  TQuiz::GetTopGroupCorr ##########################
*   Purpose....: Get top node of higest correlated question in group            	    #
*              : Does not update used field
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TQuiz *TQuiz::GetTopGroupCorr(int Group, int *Question)
{
    TQuiz *CurrQuiz;
    TQuiz *TopQuiz;
    int i;
    long double corr;
    long double maxcorr;
    int q;
    int CurrQuestion;
    int cross;
    
    maxcorr = -1;
    TopQuiz = 0;

    for (q = 0; q < N; q++)
    {
        if (Quiz[q].MyGroup == Group)
        {
            CurrQuiz = this;
            CurrQuestion = q;

            while (CurrQuiz)
            {
                if (!CurrQuiz->Quiz[CurrQuestion].Used)
                {
//                    corr =  CurrQuiz->Quiz[CurrQuestion].Pca[0] - 
//                            CurrQuiz->Quiz[CurrQuestion].Pca[1];
                    corr = CurrQuiz->Quiz[CurrQuestion].Corr;
                    if (corr < 0)
                        corr = -corr;

                    if (corr > maxcorr)
                    {
                        TopQuiz = this;
                        *Question = q;
                        maxcorr = corr;
                    }
                }

                i = CurrQuiz->Quiz[CurrQuestion].CrossInd;
                CurrQuiz = CurrQuiz->Quiz[CurrQuestion].CrossQuiz;
                CurrQuestion = i;
            }
        }
    }

    for (cross = MAX_CROSS - 1; cross >= 0; cross--)
    {
        if (CrossQuiz[cross])
        {
            for (q = 0; q < CrossQuiz[cross]->N; q++)
            {
                if (CrossQuiz[cross]->Quiz[q].MyGroup == Group)
                {
                    CurrQuiz = CrossQuiz[cross];
                    CurrQuestion = q;

                    while (CurrQuiz)
                    {
                        if (!CurrQuiz->Quiz[CurrQuestion].Used)
                        {
//                            corr =  CurrQuiz->Quiz[CurrQuestion].Pca[0] - 
//                                    CurrQuiz->Quiz[CurrQuestion].Pca[1];
                            corr = CurrQuiz->Quiz[CurrQuestion].Corr;
                            if (corr < 0)
                                corr = -corr;

                            if (corr > maxcorr)
                            {
                                TopQuiz = CrossQuiz[cross];
                                *Question = q;
                                maxcorr = corr;
                            }
                        }

                        i = CurrQuiz->Quiz[CurrQuestion].CrossInd;
                        CurrQuiz = CurrQuiz->Quiz[CurrQuestion].CrossQuiz;
                        CurrQuestion = i;
                    }
				}
			}
		}
	}

	return TopQuiz;
}

/*##################  TQuiz::GetHighestCorr ##########################
*   Purpose....: Get highest correlated in question cross link        	    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TQuiz *TQuiz::GetHighestCorr(int MyQuestion, int *Question)
{
    TQuiz *CurrQuiz;
    TQuiz *MaxQuiz;
    int i;
    long double corr;
    long double maxcorr;
    
    maxcorr = 0;
    MaxQuiz = 0;

    CurrQuiz = this;

    while (CurrQuiz)
    {
        if (!CurrQuiz->Quiz[MyQuestion].Used)
        {
//			corr =  CurrQuiz->Quiz[MyQuestion].Pca[0] -
//					CurrQuiz->Quiz[MyQuestion].Pca[1];
            corr = CurrQuiz->Quiz[MyQuestion].Corr;
			if (corr < 0)
				corr = -corr;

			if (corr >= maxcorr)
			{
				*Question = MyQuestion;
				MaxQuiz = CurrQuiz;
				maxcorr = corr;
			}
		}

		i = CurrQuiz->Quiz[MyQuestion].CrossInd;
		CurrQuiz = CurrQuiz->Quiz[MyQuestion].CrossQuiz;
		MyQuestion = i;
    }

    if (MaxQuiz)
        MaxQuiz->Quiz[*Question].Used = TRUE;

    return MaxQuiz;
}

/*##################  TQuiz::Calculate ##########################
*   Purpose....: Calculate quiz                           	      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::Calculate()
{
	int i;
    int j;
	int g;
	int e;
	int ok;
	int ival;
	int count;
	int sum;
	long double mean[MAX_QUESTIONS];
	long double csd[MAX_QUESTIONS];
	int q;
	long double val;
	long double rsum;
	long double zx;
	long double zy;
	long double exp;
	int g1, g2;
	int count1;
	int sum1;
	int count2;
	int sum2;
    TQuiz *quiz;
    int cq;
	int q1, q2;
    int ival1, ival2;
    int gid1, gid2;
	long double dcount1;
	long double dcount2;
	long double val1;
	long double val2;

	PopCorr.Correlate(&Aspie, &Nt);

	for (i = 0; i < N; i++)
	{
		Quiz[i].AsCount = Aspie.Count[i];
		Quiz[i].AsMean = Aspie.GetMean(i);
		Quiz[i].AsSd = Aspie.GetSd(i);
		Quiz[i].NtCount = Nt.Count[i];
		Quiz[i].NtMean = Nt.GetMean(i);
		Quiz[i].NtSd = Nt.GetSd(i);
		Quiz[i].Corr = PopCorr.corr[i];
		Quiz[i].Cats = GetCatCount(i);

    	Quiz[i].ChiCount[0] = Aspie.Count[i];
    	Quiz[i].ChiCount[1] = Nt.Count[i];
        
	    for (j = 0; j < Quiz[i].Cats; j++)
		{

		    Quiz[i].ChiArr[0][j] = Aspie.ChiArr[i][j];
		    Quiz[i].ChiArr[1][j] = Nt.ChiArr[i][j];
        }

		rsum = 0;
		dcount1 = (long double)Quiz[i].ChiCount[0];
		dcount2 = (long double)Quiz[i].ChiCount[1];

		for (j = 0; j < Quiz[i].Cats; j++)
		{
			val1 = (long double)Quiz[i].ChiArr[0][j];
			val2 = (long double)Quiz[i].ChiArr[1][j];

			exp = (val1 + val2) * dcount1 / (dcount1 + dcount2);
			if (exp >= 5.0)
			{
				val = val1 - exp;
				rsum += val * val / exp;
			}

			exp = (val1 + val2) * dcount2 / (dcount1 + dcount2);
			if (exp >= 5.0)
			{
				val = val2 - exp;
				rsum += val * val / exp;
			}
		}

		Quiz[i].Chi2 = rsum;

	}

	for (i = 0; i < N; i++)
	{
		Quiz[i].Count = 0;
		Quiz[i].Sum = 0;
	}

	for (i = 0; i < GROUP_COUNT; i++)
	{
        Group[i].Answers = 0;
        Group[i].Count = 0;
        Group[i].Sum = 0;
		Group[i].Questions = 0;
	}

    GroupValCount = All.ValueCount;

    if (GroupValArr)
        delete GroupValArr;
        
	GroupValArr = new TGroupValArr[GroupValCount];

    for (e = 0; e < GroupValCount; e++)
    {
		for (i = 0; i < N; i++)
		{
			ival = All.ValArr[e].Quiz[i];
			if (ival)
			{
				if (Quiz[i].Reverse)
					ival = Quiz[i].Cats - ival;
				else
					ival--;

				Quiz[i].Sum += ival;
				Quiz[i].Count++;
			}
		}

		for (g = 0; g < GROUP_COUNT; g++)
		{
			ok = TRUE;
			sum = 0;
			count = 0;

			for (i = 0; i < N; i++)
			{
				if (Quiz[i].MyGroup == g)
				{
					ival = All.ValArr[e].Quiz[i];
					if (ival)
					{
						if (Quiz[i].Reverse)
							sum += Quiz[i].Cats - ival;
						else
							sum += ival - 1;

						count++;
					}
					else
					    ok = FALSE;
				}
			}

			if (ok)
			{
			    GroupValArr[e].Group[g].Sum = sum;
			    GroupValArr[e].Group[g].Count = count;
                Group[g].Answers++;
                Group[g].Sum += sum;
                Group[g].Count += count;
			}
			else
			{
			    GroupValArr[e].Group[g].Sum = 0;
			    GroupValArr[e].Group[g].Count = 0;
			}
		}
	}

	for (i = 0; i < N; i++)
	{
        g = Quiz[i].MyGroup;
        Group[g].Questions++;
	
	    if (Quiz[i].Count > 1)
	    {
    		mean[i] = (long double)Quiz[i].Sum / Quiz[i].Count;

    		rsum = 0;

	    	for (e = 0; e < GroupValCount; e++)
		    {
			    ival = All.ValArr[e].Quiz[i];
    			if (ival)
	    		{
		    		if (Quiz[i].Reverse)
			            ival = Quiz[i].Cats - ival;
			        else
    				    ival--;

    				val = (long double)ival - mean[i];
	    			rsum += val * val;
		    	}
		    }
		    csd[i] = sqrtl(rsum / ((long double)Quiz[i].Count - 1));
		}
		else
		{
		    mean[i] = 0;
		    csd[i] = 0;
		}
	}

	for (g = 0; g < GROUP_COUNT; g++)
	{
	    if (Group[g].Count > 1 && Group[g].Answers > 1)
	    {
    		Group[g].Mean = (long double)Group[g].Sum / Group[g].Count;

	    	rsum = 0;

    		for (e = 0; e < GroupValCount; e++)
	    	{
		        if (GroupValArr[e].Group[g].Count)
			    {
			        val = (long double)GroupValArr[e].Group[g].Sum / GroupValArr[e].Group[g].Count;
    				val -= Group[g].Mean;
	    			rsum += val * val;
		    	}
		    }
		    Group[g].Sd = sqrtl(rsum / ((long double)Group[g].Answers - 1));
		}
		else
		{
		    Group[g].Mean = 0;
		    Group[g].Sd = 0;
		}
	}

	for (q = 0; q < N; q++)
	{
		for (g = 0; g < GROUP_COUNT; g++)
		{
			Quiz[q].Group[g].Corr = 0;

			if (csd[q] && Group[g].Sd)
			{
    		    rsum = 0;
	    		for (e = 0; e < GroupValCount; e++)
		    	{
			    	ival = All.ValArr[e].Quiz[q];
	    			count = GroupValArr[e].Group[g].Count;
		    		sum = GroupValArr[e].Group[g].Sum;

    			    if (ival && count)
	    		    {
		    	        if (Quiz[q].Reverse)
			                ival = Quiz[q].Cats - ival;
			            else
    			            ival--;

                        if (Quiz[q].MyGroup == g)
                        {
                            count--;
				    		sum -= ival;
                        }

                        if (count)
                        {
            			    Quiz[q].Group[g].Count++;

    	    				zx = ((long double)ival - mean[q]) / csd[q];
	    	    			zy = ((long double)sum / count - Group[g].Mean) / Group[g].Sd;
		    	    		rsum += zx * zy;
		     	        }
				    }
			    }

    			if (Quiz[q].Group[g].Count)
	    			Quiz[q].Group[g].Corr = rsum / ((long double)Quiz[q].Group[g].Count - 1);
	    	}
		}
	}

	for (g1 = 0; g1 < GROUP_COUNT; g1++)
		GroupCorr[g1][g1].Corr = 1.0;

	for (g1 = 0; g1 < GROUP_COUNT; g1++)
	{
		for (g2 = 0; g2 < g1; g2++)
		{
		    GroupCorr[g1][g2].Corr = 0;
			GroupCorr[g1][g2].Count = 0;

			rsum = 0;
			for (e = 0; e < GroupValCount; e++)
			{
			    count1 = GroupValArr[e].Group[g1].Count;
				sum1 = GroupValArr[e].Group[g1].Sum;

			    count2 = GroupValArr[e].Group[g2].Count;
			    sum2 = GroupValArr[e].Group[g2].Sum;

			    if (count1 && count2 && Group[g1].Sd && Group[g2].Sd)
			    {
					GroupCorr[g1][g2].Count++;

					zx = ((long double)sum1 / count1 - Group[g1].Mean) / Group[g1].Sd;
					zy = ((long double)sum2 / count2 - Group[g2].Mean) / Group[g2].Sd;
					rsum += zx * zy;
				}
            }
            
			if (GroupCorr[g1][g2].Count)
			{
				GroupCorr[g1][g2].Corr = rsum / ((long double)GroupCorr[g1][g2].Count - 1);
				GroupCorr[g2][g1].Corr = rsum / ((long double)GroupCorr[g1][g2].Count - 1);
				GroupCorr[g2][g1].Count = GroupCorr[g1][g2].Count;
			}
			else
			{
				GroupCorr[g1][g2].Corr = 0;
		        GroupCorr[g2][g1].Corr = 0;
				GroupCorr[g2][g1].Count = 0;
			}
		}
	}

    if (!GlobalCorrInited)
    {
        GlobalCorrInited = TRUE;

		for (gid1 = 0; gid1 < MAX_GLOBAL_QUESTIONS; gid1++)
        {
            for (gid2 = 0; gid2 < MAX_GLOBAL_QUESTIONS; gid2++)
            {
                GlobalCorrCount[gid1][gid2] = 0;
                GlobalCorrArr[gid1][gid2] = 0.0;
            }
        }
    }


#ifdef CALC_QUESTION_CORR
                
    for (q = 0; q < N; q++)
    {
        quiz = Quiz[q].CrossQuiz;
        if (quiz)
        {
			cq = Quiz[q].CrossInd;
			Quiz[q].GlobalId = quiz->Quiz[cq].GlobalId;
		}
	}

	for (q1 = 0; q1 < N; q1++)
	{
	    for (q2 = 0; q2 < q1; q2++)
		{
		    count = 0;
			rsum = 0;
			for (e = 0; e < All.ValueCount; e++)
			{
    			ival1 = All.ValArr[e].Quiz[q1];
    			if (ival1)
    			{
    				if (Quiz[q1].Reverse)
	    				ival1 = Quiz[q1].Cats - ival1;
	    			else
    					ival1--;

        			ival2 = All.ValArr[e].Quiz[q2];
        			if (ival2)
        			{
        				if (Quiz[q2].Reverse)
	        				ival2 = Quiz[q2].Cats - ival2;
	        			else
    		    			ival2--;

    		    		if (csd[q1] != 0.0 && csd[q2] != 0.0)
    		    		{
    		    			count++;
    
            			    zx = ((long double)ival1 - mean[q1]) / csd[q1];
		    		        zy = ((long double)ival2 - mean[q2]) / csd[q2];
			    	        rsum += zx * zy;
			    	    }
		    	    }
		    	}
		    }

		    if (count > 1)
			{
		        gid1 = Quiz[q1].GlobalId;
				gid2 = Quiz[q2].GlobalId;

				GlobalCorrCount[gid1][gid2] += count;
				GlobalCorrArr[gid1][gid2] += rsum;

				GlobalCorrCount[gid2][gid1] += count;
				GlobalCorrArr[gid2][gid1] += rsum;
	    	}
		}
	}

#endif
	
}

/*##################  TQuiz::CalcGlobal ##########################
*   Purpose....: Calculate global data  	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::CalcGlobal()
{
    int GlobalId;
    int i;
	int j;
	int k;
    TQuiz *quiz;
  	TQuiz *TopQuiz;
	int TopQuestion;
	int q;
	int count;
	int w;
	long double val;
	long double rsum;
	long double exp;
	int ChiArr[2][8];
	int ChiCount[2];
	int Cats;
	long double dcount1;
	long double dcount2;
	long double val1;
	long double val2;

	if (GlobalInited)
	    return;

	GlobalInited = TRUE;

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	{
		GlobalAsNtCorrSum[i] = 0.0;
		GlobalAsNtCorrCount[i] = 0;
		GlobalChi2[i] = 0.0;

		for (j = 0; j < MAX_GROUP_COUNT; j++)
		{
    		GlobalGroupCorrSum[i][j] = 0.0;
	    	GlobalGroupCorrCount[i][j] = 0;
	   	}

        for (j = 0; j < 4; j++)
        {
            GlobalPcaSum[i][j] = 0.0;
            GlobalPcaCount[i][j] = 0;
        }

	}

	ClearUsed();

    TopQuiz = GetTopQuizCorr(&TopQuestion);

	while (TopQuiz)
	{
        quiz = TopQuiz;
        q = TopQuestion;

		for (;;)
        {
            quiz->Quiz[q].Used = TRUE;
        
            if (quiz->Quiz[q].CrossQuiz)
            {
                j = quiz->Quiz[q].CrossInd;
                quiz = quiz->Quiz[q].CrossQuiz;
                q = j;
		    }
            else
            {
			    GlobalId = quiz->Quiz[q].GlobalId;
				break;
			}
		}

        if (GlobalId >= 0 && GlobalId < MAX_GLOBAL_QUESTIONS)
        {
            Cats = TopQuiz->GetCatCount(TopQuestion);

            GlobalCatCount[GlobalId] = Cats;

            for (j = 0; j < 2; j++)
            {
                ChiCount[j] = 0;

                for (k = 0; k < Cats; k++)
                    ChiArr[j][k] = 0;
            }
        
			GlobalTopQuiz[GlobalId] = TopQuiz;
            GlobalTopQuestion[GlobalId] = TopQuestion;

            quiz = TopQuiz;
		    q = TopQuestion;

    		for (;;)
            {    
                for (j = 0; j < 2; j++)
                {
                    ChiCount[j] += quiz->Quiz[q].ChiCount[j];
    
                    for (k = 0; k < Cats; k++)
                        ChiArr[j][k] += quiz->Quiz[q].ChiArr[j][k];
                }

			    GlobalAsNtCorrSum[GlobalId] += quiz->Quiz[q].Corr * quiz->Quiz[q].Count;
                GlobalAsNtCorrCount[GlobalId] += quiz->Quiz[q].Count;

            	for (j = 0; j < GROUP_COUNT - 1; j++)
			    {
        		    val = quiz->Quiz[q].Group[j].Corr;
				    count = quiz->Quiz[q].Group[j].Count;
					w = quiz->Group[j].Questions;
					w = w * quiz->Quiz[q].Count;
						
        			if (count > 3)
		        	{
				        GlobalGroupCorrSum[GlobalId][j] += val * w;
						GlobalGroupCorrCount[GlobalId][j] += w;
        		    }
			    }

                w = quiz->All.ValueCount;

                for (j = 0; j < 4; j++)
                {
                    if (quiz->GetPcaCount() > j)
                    {
						GlobalPcaSum[GlobalId][j] += quiz->Quiz[q].Pca[j] * w;
						 GlobalPcaCount[GlobalId][j] += w;
                    }
                }

                if (quiz->Quiz[q].CrossQuiz)
                {
                    j = quiz->Quiz[q].CrossInd;
                    quiz = quiz->Quiz[q].CrossQuiz;
                    q = j;
				}
                else
    				break;
		    }

    		rsum = 0;
	    	dcount1 = (long double)ChiCount[0];
		    dcount2 = (long double)ChiCount[1];

    		for (j = 0; j < Cats; j++)
	    	{
		    	val1 = (long double)ChiArr[0][j];
			    val2 = (long double)ChiArr[1][j];
			    
    			exp = (val1 + val2) * dcount1 / (dcount1 + dcount2);
	    		if (exp >= 5.0)
		    	{
			    	val = val1 - exp;
    				rsum += val * val / exp;
	    		}

		    	exp = (val1 + val2) * dcount2 / (dcount1 + dcount2);
			    if (exp >= 5.0)
    			{
	    			val = val2 - exp;
		    		rsum += val * val / exp;
			    }
    		}

		
	        GlobalChi2[GlobalId] = rsum;
		    
	    }

        TopQuiz = GetTopQuizCorr(&TopQuestion);
	}
}

/*##################  TQuiz::WriteIQ ##########################
*   Purpose....: Write IQ report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteIQ(const char *FileName)
{
}

/*##################  TQuiz::WriteHair ##########################
*   Purpose....: Write hair report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteHair(const char *FileName)
{
}

/*##################  TQuiz::WriteEye ##########################
*   Purpose....: Write eye report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteEye(const char *FileName)
{
}

/*##################  TQuiz::WriteRace ##########################
*   Purpose....: Write race report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteRace(const char *FileName)
{
}

/*##################  TQuiz::WriteStim ##########################
*   Purpose....: Write stim report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteStim(const char *FileName)
{
}

/*##################  TQuiz::WriteABO ##########################
*   Purpose....: Write ABO report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteABO(const char *FileName)
{
}

/*##################  TQuiz::WriteBirthMonth ##########################
*   Purpose....: Write birth month report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteBirthMonth(const char *FileName)
{
}

/*##################  TQuiz::ExportBirthMonthHistogram ##########################
*   Purpose....: Write birth month histogram (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::ExportBirthMonthHistogram(const char *FileName)
{
}

/*##################  TQuiz::WriteParkinson ##########################
*   Purpose....: Write Parkinson report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteParkinson(const char *FileName)
{
}

/*##################  TQuiz::WriteAlzheimer ##########################
*   Purpose....: Write Alzheimer report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAlzheimer(const char *FileName)
{
}

/*##################  TQuiz::WriteCFTR ##########################
*   Purpose....: Write CFTR report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCFTR(const char *FileName)
{
}

/*##################  TQuiz::WriteHFE ##########################
*   Purpose....: Write HFE report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteHFE(const char *FileName)
{
}

/*##################  TQuiz::WriteLeiden ##########################
*   Purpose....: Write Factor V Leiden report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteLeiden(const char *FileName)
{
}

/*##################  TQuiz::WriteAQ ##########################
*   Purpose....: Write AQ test report (dummy)           			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAQ(const char *FileName)
{
}

/*##################  TQuiz::WriteFieldHeader ##########################
*   Purpose....: Write field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

	File.Write("<p>\n");
	File.Write("<b>\n");
}

/*##################  TQuiz::WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

	File.Write("<p align=\"center\">\n");
	File.Write("<b>\n");
}

/*##################  TQuiz::WriteRightFieldHeader ##########################
*   Purpose....: Write right-aligned field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteRightFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

	File.Write("<p align=\"right\">\n");
	File.Write("<b>\n");
}

/*##################  TQuiz::WriteFieldFooter ##########################
*   Purpose....: Write field footer for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteFieldFooter(TFile &File)
{
    File.Write("\n</b>\n");
	File.Write("</p>\n");

    File.Write("</td>\n");
}

/*##################  TQuiz::WriteReferer ##########################
*   Purpose....: Write referer    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteReferer(TFile &file, TReferer *ref)
{
    char str[80];

    if (ref->Count)
    {
	    file.Write("<tr style='height:24.75pt'>");

	    WriteCenteredFieldHeader(file, 4);
	    sprintf(str, "%d", ref->Count);
	    file.Write(str);
	    WriteFieldFooter(file);

	    if (UseNtResult)
	    {
    	    WriteRightFieldHeader(file, 4);
			sprintf(str, "%d", ref->AsResult / ref->Count);
			file.Write(str);
			WriteFieldFooter(file);

			WriteRightFieldHeader(file, 4);
			sprintf(str, "%d", ref->NtResult / ref->Count);
			file.Write(str);
			WriteFieldFooter(file);

			WriteRightFieldHeader(file, 4);
			sprintf(str, "%d%", round(100.0 * ref->ResultNt / ref->Count));
    	    file.Write(str);
	        WriteFieldFooter(file);
    
	        WriteRightFieldHeader(file, 4);
    	    sprintf(str, "%d%", round(100.0 * ref->ResultMixed / ref->Count));
	        file.Write(str);
	        WriteFieldFooter(file);

    	    WriteRightFieldHeader(file, 4);
	        sprintf(str, "%d%", round(100.0 * ref->ResultAs / ref->Count));
	        file.Write(str);
	        WriteFieldFooter(file);
	    }
	    else
	    {
    	    WriteRightFieldHeader(file, 4);
	        sprintf(str, "%d", ref->Result / ref->Count);
	        file.Write(str);
	        WriteFieldFooter(file);

    	    WriteRightFieldHeader(file, 4);
	        sprintf(str, "%d%", round(100.0 * ref->Result0_59 / ref->Count));
    	    file.Write(str);
	        WriteFieldFooter(file);
    
	        WriteRightFieldHeader(file, 4);
    	    sprintf(str, "%d%", round(100.0 * ref->Result60_99 / ref->Count));
	        file.Write(str);
	        WriteFieldFooter(file);

    	    WriteRightFieldHeader(file, 4);
	        sprintf(str, "%d%", round(100.0 * ref->Result100_139 / ref->Count));
	        file.Write(str);
	        WriteFieldFooter(file);
	      
    	    WriteRightFieldHeader(file, 4);
            sprintf(str, "%d%", round(100.0 * ref->Result140_200 / ref->Count));
            file.Write(str);
	        WriteFieldFooter(file);
	    }
    
	    WriteFieldHeader(file, 72);

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

	    WriteFieldFooter(file);

        file.Write("</tr>");
    }
}

/*##################  TQuiz::WriteReferers ##########################
*   Purpose....: Print referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteReferers(const char *filename)
{
    TFile file(filename, 0);
	int i;

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 4);
	file.Write("Answers");
	WriteFieldFooter(file);

	if (UseNtResult)
	{
    	WriteCenteredFieldHeader(file, 4);
        file.Write("AS Score");
    	WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 4);
        file.Write("NT Score");
    	WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 4);
        file.Write("NT");
	    WriteFieldFooter(file);
	      
    	WriteCenteredFieldHeader(file, 4);
        file.Write("Mixed");
    	WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 4);
        file.Write("AS");
	    WriteFieldFooter(file);
	}
	else
	{
    	WriteCenteredFieldHeader(file, 4);
        file.Write("Score");
    	WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 4);
        file.Write("0-59");
	    WriteFieldFooter(file);
	      
    	WriteCenteredFieldHeader(file, 4);
        file.Write("60-99");
    	WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 4);
        file.Write("100-139");
	    WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 4);
        file.Write("140-200");
	    WriteFieldFooter(file);
	}

	WriteFieldHeader(file, 72);
	file.Write("Web site / description");
	WriteFieldFooter(file);

	file.Write("</tr>");

	WriteReferer(file, &DxAsRef);
	WriteReferer(file, &DxTsRef);
	WriteReferer(file, &DxAddRef);
	WriteReferer(file, &SelfAsRef);
	WriteReferer(file, &SelfTsRef);
	WriteReferer(file, &SelfAddRef);
	WriteReferer(file, &MaleAsRef);
	WriteReferer(file, &FemaleAsRef);
	WriteReferer(file, &MaleNonAsRef);
	WriteReferer(file, &FemaleNonAsRef);
	WriteReferer(file, &AspieRef);
	WriteReferer(file, &HyperlexiaRef);
	WriteReferer(file, &DyspraxiaRef);
	WriteReferer(file, &DyslexiaRef);
	WriteReferer(file, &DyscalculiaRef);
	WriteReferer(file, &OCDRef);
	WriteReferer(file, &ODDRef);
	WriteReferer(file, &SynaesthesiaRef);
	WriteReferer(file, &PARef);
	WriteReferer(file, &DysgraphiaRef);
	WriteReferer(file, &BipolarRef);
	WriteReferer(file, &SchizophreniaRef);
	WriteReferer(file, &SocialPhobiaRef);
	WriteReferer(file, &WhiteRef);
	WriteReferer(file, &AsianRef);
	WriteReferer(file, &AmerindianRef);
	WriteReferer(file, &MixedAfroAmericanRef);
	WriteReferer(file, &AfroAmericanRef);
	WriteReferer(file, &HispanicRef);
	WriteReferer(file, &MixedAfricanRef);
	WriteReferer(file, &AfricanRef);
	WriteReferer(file, &ArabRef);
	WriteReferer(file, &NTRef);
	WriteReferer(file, &NoRef);

	for (i = 0; i < RefCount; i++)
		if (RefArr[i]->Count >= 10) // change later!
    		WriteReferer(file, RefArr[i]);

	file.Write("</table>");
}

/*##################  TQuiz::WriteStaple ##########################
*   Purpose....: Write staple      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteStaple(TFile &File, TPopulation *pop, int Question)
{
    int count;
    long double mean;
	char str[80];
	int ival;
    
	File.Write("<img border=\"0\" src=\"http://www.rdos.net/stdpic/");
	count = pop->Count[Question];
	if (count)
	{
		mean = pop->GetMean(Question);
		ival = round(10 * mean);
	}
	else
		ival = 0;

	sprintf(str, "%d", ival);
	File.Write(str);
	File.Write(".jpg\" width=\"4\" height=\"21\">");
}

/*##################  TQuiz::WriteCI95 ##########################
*   Purpose....: Write 95% confidence interval      	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCI95(TFile &File, TPopulation *pop, int Question)
{
    int count;
    long double mean;
    long double sd;
    long double dev;
    long double val;
    long double maxval;
    int ival;
	char str[80];
    
    count = pop->Count[Question];
    maxval = (long double)(Quiz[Question].Cats - 1);

    if (count > 1)
	{
        mean = pop->GetMean(Question);
	    sd = pop->GetSd(Question);

		dev = 1.96 * sd / sqrtl(count);

		val = mean - dev;
		if (val < 0.0)
			val = 0.0;

		ival = round(100.0 * val);

		sprintf(str, "%d.%02d", ival / 100, ival % 100);
		File.Write(str);

		val = mean + dev;
		if (val > maxval && mean < maxval)
			val = maxval;

		ival = round(100.0 * val);

		sprintf(str, "-%d.%02d", ival / 100, ival % 100);
		File.Write(str);
	}
    else
		File.Write("-----");
}

/*##################  TQuiz::WriteCorr95 ##########################
*   Purpose....: Write 95% correlation interval      	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCorr95(TFile &File, long double corr, int count)
{
    long double zij;
    long double za;
    long double rlow;
    long double rhigh;
    int ival;
	char str[80];

    if (corr < 0.0)
        corr = -corr;

    File.Write("\n");

    if (corr > 0.7)
		File.Write("<span style='color:#BB0000'>");
    else
	{
        if (corr > 0.5)
	    	File.Write("<span style='color:#995500'>");
		else
		{
			if (corr > 0.3)
        		File.Write("<span style='color:#228844'>");
            else
            {
			    if (corr > 0.1)
            		File.Write("<span style='color:#002277'>");
            	else
                    File.Write("<span>");
    	    }
        }
    }

    File.Write("\n");

    if (count > 3)
    {
        if (corr < 1.0)
        {    
    		zij = 0.5 * logl((1 + corr) / (1 - corr));
	    	za = 1.96 / sqrtl(count - 3);
            rlow = tanhl(zij - za);
            rhigh = tanhl(zij + za);   

            if (rlow <= 0.0 && rhigh >= 0.0)
                File.Write("-----");
            else
            {
#ifdef USE_PERCENT
                ival = round(100.0 * rlow * rlow);
		        sprintf(str, "%d", ival);
		        File.Write(str);

        		ival = round(100.0 * rhigh * rhigh);
	        	sprintf(str, "-%d", ival);
		        File.Write(str);
			
    			File.Write("%");
#else
                if (rlow <= 0.0)
                {
                    File.Write("-");
                    rlow = -rlow;
                    rhigh = -rhigh;
                }
                
                ival = round(100 * rlow);
		        sprintf(str, ".%02d", ival);
		        File.Write(str);

        		ival = round(100.0 * rhigh);
	        	sprintf(str, "-.%02d", ival);
		        File.Write(str);
#endif
	    	}
	    }
	    else
#ifdef USE_PERCENT
            File.Write("100%");
#else
            File.Write("1.00");
#endif
    }
    else
	    File.Write(" ");

    File.Write("</span>\n");
        
}

/*##################  TQuiz::WriteCorrVal ##########################
*   Purpose....: Write correlation value      	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCorrVal(TFile &File, long double corr, int count)
{
    int ival;
	char str[80];

    if (corr < 0.0)
        corr = -corr;

    File.Write("\n");

    if (corr > 0.7)
		File.Write("<span style='color:#BB0000'>");
    else
	{
        if (corr > 0.5)
	    	File.Write("<span style='color:#995500'>");
		else
		{
			if (corr > 0.3)
        		File.Write("<span style='color:#228844'>");
            else
            {
			    if (corr > 0.1)
            		File.Write("<span style='color:#002277'>");
            	else
                    File.Write("<span>");
    	    }
        }
    }

    File.Write("\n");

    if (count > 3)
    {
#ifdef USE_PERCENT
        ival = round(100.0 * corr * corr);
		sprintf(str, "%d%", ival);
		File.Write(str);
#else
        if (corr <= 0.0)
        {
            File.Write("-");
            corr = -corr;
        }
                
        ival = round(100 * corr);
		sprintf(str, ".%02d", ival);
		File.Write(str);
#endif
    }
    else
	    File.Write(" ");

    File.Write("</span>\n");
        
}

/*##################  TQuiz::WriteChi2 ##########################
*   Purpose....: Write chi-2                           	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteChi2(TFile &File, long double chi2)
{
    char str[40];
    int ival;

    ival = round(chi2);

    sprintf(str, "%d", ival);
            
	File.Write(str);
}

/*##################  TQuiz::WriteP ##########################
*   Purpose....: Write chi-2 based p                   	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteP(TFile &File, long double chi2)
{
    char str[40];

    if (chi2 >= 18.5)
        strcpy(str, "0.0001");
    else
    {
        if (chi2 >= 17.8)
            strcpy(str, "0.0002");
        else
        {
            if (chi2 >= 15.5)
                strcpy(str, "0.0005");
            else
            {
                if (chi2 >= 14.0)
                    strcpy(str, "0.001");
                else
                {
                    if (chi2 >= 12.5)
                        strcpy(str, "0.002");
                    else
                    {
                        if (chi2 >= 10.62)
                            strcpy(str, "0.005");
                        else
                        {
                            if (chi2 >= 9.23)
                                strcpy(str, "0.01");
                            else
                            {
                                if (chi2 >= 7.83)
                                    strcpy(str, "0.02");
                                else
                                {
                                    if (chi2 >= 6.00)
                                        strcpy(str, "0.05");
                                    else
                                    {
                                        if (chi2 >= 4.61)
														  strcpy(str, "0.1");
													 else
													 {
														  if (chi2 >= 3.22)
																strcpy(str, "0.2");
														  else
																strcpy(str, "---");
													 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
            
	File.Write(str);
}


/*##################  TQuiz::WritePca ##########################
*   Purpose....: Write PCA loading                    	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePca(TFile &File, long double pca)
{
    int ival;
    char str[40];

    if (pca < 0.0)
    {
	    pca = -pca;
	    File.Write("-");
    }
    
	ival = round(100.0 * pca);
			        
    sprintf(str, ".%02d", ival);
	File.Write(str);
}

/*##################  TQuiz::WritePcaPopCorr ##########################
*   Purpose....: Write PCA-population correlation      	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePcaPopCorr(TFile &File, TQuiz *quiz, int PopType, int PcaNr)
{
    TPopulation *pop;
    long double val;
    long double aw;
    long double nw;
    int question;
    long double mean[MAX_QUESTIONS];
    long double pca[MAX_QUESTIONS];
    long double PopMean;
    long double PcaMean;
    long double PopSd;
    long double PcaSd;
    long double sum;
    long double zx;
    long double zy;
    long double count;
    int ival;
	char str[80];

    pop = quiz->GetPop(PopType);

	count = (long double)quiz->N;

    for (question = 0; question < quiz->N; question++)
    {
        val = quiz->All.GetMean(question);
        mean[question] = pop->GetMean(question) - val;

        switch (PcaNr)
        {
            case -1:
                aw = quiz->Quiz[question].Pca[0];
                nw = quiz->Quiz[question].Pca[1];
                val = aw - nw;
                break;
                
            case 0:
                aw = quiz->Quiz[question].Pca[0];
                nw = quiz->Quiz[question].Pca[1];

                if (aw > 0.0 && nw > 0.0)
                {
                    if (aw > nw)
                        val = aw - nw;
                    else
                        val = 0.0;
                }
                else
                    val = aw;
                break;
                
            case 1:
                aw = quiz->Quiz[question].Pca[0];
                nw = quiz->Quiz[question].Pca[1];

                if (aw > 0.0 && nw > 0.0)
                {
                    if (aw > nw)
                        val = 0.0;
                    else
                        val = nw - aw;
                }
                else
                    val = nw;
                break;

            default:                
                val = quiz->Quiz[question].Pca[PcaNr];
                break;
        }
        pca[question] = val;
    }

    sum = 0.0;
    for (question = 0; question < quiz->N; question++)
        sum += mean[question];

    PopMean = sum / count;

    sum = 0.0;
    for (question = 0; question < quiz->N; question++)
        sum += pca[question];

    PcaMean = sum / count;

    sum = 0.0;
    for (question = 0; question < quiz->N; question++)
    {
        val = mean[question] - PopMean;
        sum += val * val;
    }
    PopSd = sqrtl(sum / (count - 1.0));

    sum = 0.0;
    for (question = 0; question < quiz->N; question++)
    {
        val = pca[question] - PcaMean;
        sum += val * val;
    }
    PcaSd = sqrtl(sum / (count - 1.0));

    sum = 0.0;
    for (question = 0; question < quiz->N; question++)
    {
        zx = (mean[question] - PopMean) / PopSd;
        zy = (pca[question] - PcaMean) / PcaSd;
        sum += zx * zy;
    }

    val = sum / (count - 1.0);       

#ifdef USE_PERCENT
    ival = quiz->round(100.0 * val * val);
    sprintf(str, "%d%", ival);
    File.Write(str);
#else
    if (val <= 0.0)
    {
        File.Write("-");
        val = -val;
    }
                
	ival = quiz->round(100 * val);
    sprintf(str, ".%02d", ival);
    File.Write(str);
#endif
}

/*##################  TQuiz::WriteSumaryTable ##########################
*   Purpose....: Write sumary table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteSumaryTable(const char *filename, int OnlyMixed)
{
	int i;
	int j;
	char str[80];
	int ival;
	TFile file(filename, 0);
	int UseGender;

	if (AspieMale.ValueCount && NtMale.ValueCount && AspieFemale.ValueCount && NtFemale.ValueCount)
		UseGender = TRUE;
	else
	    UseGender = FALSE;

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

    j = 0;
    
	for (i = 0; i < N; i++)
	{
		if (!OnlyMixed || Quiz[i].MyGroup == GROUP_MIXED)
        {
    		if (j % 10 == 0)
	    	{
		    	file.Write("<tr style='height:24.75pt'>");

            	WriteCenteredFieldHeader(file, 5);
	    		file.Write("#");
            	WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 40);
	    		file.Write(" ");
            	WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 5);
	    		file.Write("?");
            	WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 5);
	    		file.Write("Trend");
            	WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
	    		file.Write("Aspie loading");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
        	    WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
	    		file.Write("NT loading");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
        	    WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 6);
	    		file.Write("Aspie");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
        	    WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
	    		file.Write("AS");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
			    WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
	    		file.Write("Young Aspie");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
			    WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
		    	file.Write("Mixed");
	    		if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
        	    WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
	    		file.Write("NT");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
        	    WriteFieldFooter(file);

    			file.Write("</tr>");
    		}

            j++;
            
    		file.Write("<tr style='height:24.75pt'>");

	    	WriteCenteredFieldHeader(file, 5);
		    sprintf(str, "%d", i + 1);
    		file.Write(str);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 40);
	    	file.Write(Quiz[i].Text);
            WriteFieldFooter(file);

			WriteCenteredFieldHeader(file, 5);
	    	if (All.Count[i])
            {
    		    ival = round(100.0 * Quiz[i].NoAnswer / All.ValueCount);
    	    	sprintf(str, "%d%", ival);
	    	    file.Write(str);
		    }
    		else
	    	    file.Write("-----");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
	    	if (UseGender && !OnlyMixed)
		    {
    		    WriteStaple(file, &AspieMale, i);
	    	    WriteStaple(file, &AsMale, i);
		    	WriteStaple(file, &YoungMale, i);
		        WriteStaple(file, &MixMale, i);
		        WriteStaple(file, &NtMale, i);

    		    file.Write("<br>");

	    		WriteStaple(file, &AspieFemale, i);
				WriteStaple(file, &AsFemale, i);
		        WriteStaple(file, &YoungFemale, i);
		        WriteStaple(file, &MixFemale, i);
		        WriteStaple(file, &NtFemale, i);
    	    }
	        else
	        {
		        WriteStaple(file, &Aspie, i);
			    WriteStaple(file, &As, i);
			    WriteStaple(file, &Add, i);
			    WriteStaple(file, &Mix, i);
			    WriteStaple(file, &Nt, i);
		    }
			WriteFieldFooter(file);

    		if (UseGender && !OnlyMixed)
	    	{
		    	WriteCenteredFieldHeader(file, 6);
			    WritePca(file, Quiz[i].MalePca[0]);
		    	file.Write("<br>");
			    WritePca(file, Quiz[i].FemalePca[0]);
		    	WriteFieldFooter(file);

       			WriteCenteredFieldHeader(file, 6);
	    	    WritePca(file, Quiz[i].MalePca[1]);
    			file.Write("<br>");
	    		WritePca(file, Quiz[i].FemalePca[1]);
    			WriteFieldFooter(file);

    			WriteCenteredFieldHeader(file, 6);
	    		WriteCI95(file, &AspieMale, i);
		    	file.Write("<br>");
			    WriteCI95(file, &AspieFemale, i);
    			WriteFieldFooter(file);

	    		WriteCenteredFieldHeader(file, 6);
		    	WriteCI95(file, &AsMale, i);
			    file.Write("<br>");
    			WriteCI95(file, &AsFemale, i);
	    		WriteFieldFooter(file);
    
	       		WriteCenteredFieldHeader(file, 6);
       			WriteCI95(file, &YoungMale, i);
	    		file.Write("<br>");
		    	WriteCI95(file, &YoungFemale, i);
    			WriteFieldFooter(file);

	    		WriteCenteredFieldHeader(file, 6);
				WriteCI95(file, &MixMale, i);
			    file.Write("<br>");
    			WriteCI95(file, &MixFemale, i);
	    		WriteFieldFooter(file);

		    	WriteCenteredFieldHeader(file, 6);
			    WriteCI95(file, &NtMale, i);
    			file.Write("<br>");
	    		WriteCI95(file, &NtFemale, i);
		    	WriteFieldFooter(file);

        		file.Write("</tr>");
	    	}
		    else
		    {
    			WriteCenteredFieldHeader(file, 6);
	    		if (OnlyMixed)
				    WritePca(file, Quiz[i].MixedPca[0]);
	    		else
		    		WritePca(file, Quiz[i].Pca[0]);
				WriteFieldFooter(file);
    
        	    if (GetPcaCount() > 1)
        	    {
    	    		WriteCenteredFieldHeader(file, 6);
	    	    	if (OnlyMixed)
	        			WritePca(file, Quiz[i].MixedPca[1]);
			        else
    			    	WritePca(file, Quiz[i].Pca[1]);
		    	    WriteFieldFooter(file);
		    	}

        	    if (GetPcaCount() > 2)
        	    {
    	    		WriteCenteredFieldHeader(file, 6);
	    	    	if (OnlyMixed)
	        			WritePca(file, Quiz[i].MixedPca[2]);
			        else
    			    	WritePca(file, Quiz[i].Pca[2]);
		    	    WriteFieldFooter(file);
		    	}

				WriteCenteredFieldHeader(file, 6);
	    		WriteCI95(file, &Aspie, i);
		    	WriteFieldFooter(file);
    
	    		WriteCenteredFieldHeader(file, 6);
		        WriteCI95(file, &As, i);
                WriteFieldFooter(file);

                WriteCenteredFieldHeader(file, 6);
	    	    WriteCI95(file, &Add, i);
                WriteFieldFooter(file);
    
    			WriteCenteredFieldHeader(file, 6);
	    	    WriteCI95(file, &Mix, i);
                WriteFieldFooter(file);
    
                WriteCenteredFieldHeader(file, 6);
		        WriteCI95(file, &Nt, i);
                WriteFieldFooter(file);

           		file.Write("</tr>");
    	    }
	    }
	}

	file.Write("</table>");
}

/*##################  TQuiz::WriteCorrTable ##########################
*   Purpose....: Write population correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCorrTable(const char *filename, const char *name1, const char *name2, TPopulation *pop1, TPopulation *pop2, long double mincorr)
{
	int i;
	int ok;
	int j;
	int ind;
	char str[80];
	int ival;
	TFile file(filename, 0);

    PopCorr.Correlate(pop1, pop2);
    PopCorr.Sort();

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	j = 0;

	for (i = 0; i < N; i++)
	{
		ind = PopCorr.IndArr[i];

		ok = (PopCorr.chi2[ind] >= mincorr);

		if (ok && j % 10 == 0)
		{
			file.Write("<tr style='height:24.75pt'>");

            WriteFieldHeader(file, 4);
			file.Write("#");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 60);
			file.Write(" ");
            WriteFieldFooter(file);

            WriteFieldHeader(file, 10);
			file.Write(name1);
            WriteFieldFooter(file);

            WriteFieldHeader(file, 10);
			file.Write(name2);
            WriteFieldFooter(file);

            WriteFieldHeader(file, 6);
			file.Write("Chi2");
            WriteFieldFooter(file);

            WriteFieldHeader(file, 10);
			file.Write("Corr");
            WriteFieldFooter(file);

			file.Write("</tr>");
		}

		if (ok)
		{
			j++;

			file.Write("<tr style='height:24.75pt'>");

            WriteFieldHeader(file, 4);
			sprintf(str, "%d", ind + 1);
			file.Write(str);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 60);
			file.Write(Quiz[ind].Text);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 10);
            WriteCI95(file, pop1, ind);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 10);
            WriteCI95(file, pop2, ind);
            WriteFieldFooter(file);

            WriteRightFieldHeader(file, 6);
			ival = round(PopCorr.chi2[ind]);
			sprintf(str, "%d", ival);
			file.Write(str);
            WriteFieldFooter(file);

            WriteRightFieldHeader(file, 10);
			WriteCorr95(file, PopCorr.corr[ind], pop1->Count[ind] + pop2->Count[ind]);
            WriteFieldFooter(file);
		}
	}

	file.Write("</table>");
}

/*##################  TQuiz::WriteAsNtCorrelation ##########################
*   Purpose....: Write AS vs NT correlation	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAsNtCorrelation(const char *filename)
{
    if (As.ValueCount >= 5 && Nt.ValueCount >= 5)
    	WriteCorrTable(filename, "AS/HFA/PDD", "NT control", &As, &Nt, 6.0);
}

/*##################  TQuiz::WriteAsAspieCorrelation ##########################
*   Purpose....: Write Aspie vs AS correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAspieAsCorrelation(const char *filename)
{
    if (Aspie.ValueCount >= 5 && As.ValueCount >= 5)
    	WriteCorrTable(filename, "Aspie control", "AS/HFA/PDD", &Aspie, &As, 6.0);
}

/*##################  TQuiz::WriteAddNtCorrelation ##########################
*   Purpose....: Write ADD/ADHD vs NT correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAddNtCorrelation(const char *filename)
{
    if (Add.ValueCount >= 5 && Nt.ValueCount >= 5)
    	WriteCorrTable(filename, "ADD/ADHD", "NT control", &Add, &Nt, 6.0);
}

/*##################  TQuiz::WriteAddAsCorrelation ##########################
*   Purpose....: Write ADD/ADHD vs AS correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAddAsCorrelation(const char *filename)
{
    if (Add.ValueCount >= 5 && As.ValueCount >= 5)
    	WriteCorrTable(filename, "ADD/ADHD", "AS/HFA/PDD", &Add, &As, 6.0);
}

/*##################  TQuiz::WriteGenderAsCorrelation ##########################
*   Purpose....: Write male vs female AS correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteGenderAsCorrelation(const char *filename)
{
	if (AsMale.ValueCount >= 5 && AsFemale.ValueCount >= 5)
		WriteCorrTable(filename, "Male AS", "Female AS", &AsMale, &AsFemale, 6.0);
}

/*##################  TQuiz::WriteLowAsNtCorrelation ##########################
*   Purpose....: Write low-score AS vs NT correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteLowAsNtCorrelation(const char *filename)
{
	if (LowAs.ValueCount >= 5 && Nt.ValueCount >= 5)
		WriteCorrTable(filename, "Low AS", "NT control", &LowAs, &Nt, 6.0);
}

/*##################  TQuiz::WriteLowAsAsCorrelation ##########################
*   Purpose....: Write low-score AS vs AS correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteLowAsAsCorrelation(const char *filename)
{
	if (LowAs.ValueCount >= 5 && As.ValueCount >= 5)
		WriteCorrTable(filename, "Low AS", "AS/HFA/PDD", &LowAs, &As, 6.0);
}

/*##################  TQuiz::WriteRefererNtCorrelation ##########################
*   Purpose....: Write referer vs NT correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteRefererNtCorrelation(const char *filename, const char *header, const char *referer)
{
	TPopulation pop(N);

	GetReferer(referer, &pop);

	if (pop.ValueCount >= 5 && Nt.ValueCount >= 5)
		WriteCorrTable(filename, header, "NT control", &pop, &Nt, 6.0);
}

/*##################  TQuiz::WriteRefererAsCorrelation ##########################
*   Purpose....: Write referer vs AS correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteRefererAsCorrelation(const char *filename, const char *header, const char *referer)
{
    TPopulation pop(N);

    GetReferer(referer, &pop);

    if (pop.ValueCount >= 5 && Aspie.ValueCount >= 5)
		WriteCorrTable(filename, header, "Aspie control", &pop, &As, 6.0);
}

/*##################  TQuiz::WriteAsCI95 ##########################
*   Purpose....: Write AS mean with 95% confidence interval                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAsCI95(TFile &File, int Question)
{
    long double mean;
    long double sd;
    long double dev;
    long double val;
    long double maxval;
    int ival;
	int count;
    char str[80];
            
	mean = Quiz[Question].AsMean;
	sd = Quiz[Question].AsSd;
	count = Quiz[Question].AsCount;
	maxval = (long double)(Quiz[Question].Cats - 1);

	if (count > 1)
	{
		dev = 1.96 * sd / sqrtl(count);

		val = mean - dev;
		if (val < 0.0)
			val = 0.0;

		ival = 100 * val;

		sprintf(str, "%d.%02d", ival / 100, ival % 100);
		File.Write(str);

		val = mean + dev;
		if (val > maxval)
			val = maxval;

		ival = 100 * val;

		sprintf(str, "-%d.%02d", ival / 100, ival % 100);
		File.Write(str);
	}
	else
		File.Write("-----");
}

/*##################  TQuiz::WriteNtCI95 ##########################
*   Purpose....: Write NT mean with 95% confidence interval                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteNtCI95(TFile &File, int Question)
{
    long double mean;
    long double sd;
    long double dev;
    long double val;
    long double maxval;
    int ival;
	int count;
    char str[80];
            
	mean = Quiz[Question].NtMean;
	sd = Quiz[Question].NtSd;
	count = Quiz[Question].NtCount;
	maxval = (long double)(Quiz[Question].Cats - 1);

	if (count > 1)
	{
		dev = 1.96 * sd / sqrtl(count);

		val = mean - dev;
		if (val < 0.0)
			val = 0.0;

		ival = 100 * val;

		sprintf(str, "%d.%02d", ival / 100, ival % 100);
		File.Write(str);

		val = mean + dev;
		if (val > maxval)
			val = maxval;

		ival = 100 * val;

		sprintf(str, "-%d.%02d", ival / 100, ival % 100);
		File.Write(str);
	}
	else
	    File.Write("-----");
}

/*##################  TQuiz::WriteAsNtChi2 ##########################
*   Purpose....: Write AS vs NT chi-2                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAsNtChi2(TFile &File, int Question)
{
    int ival;
    char str[80];
    
    ival = round(Quiz[Question].Chi2);

    sprintf(str, "%d", ival);
	File.Write(str);
}

/*##################  TQuiz::WriteAsNtCorr95 ##########################
*   Purpose....: Write AS vs NT 95% correlation interval      	          	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAsNtCorr95(TFile &File, int Question)
{
    int count;
    long double corr;
    
	count = Quiz[Question].AsCount + Quiz[Question].NtCount;

	if (count > 3)
	{
    	corr = Quiz[Question].Corr;
    	WriteCorr95(File, corr, count);
    }
    else
        File.Write("-----");
}

/*##################  TQuiz::WriteAsNtAll ##########################
*   Purpose....: Write AS vs NT correlation, all quizes                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAsNtAll(const char *filename)
{
	int j;
	char str[80];
	TFile file(filename, 0);
	TQuiz *quiz;
	TQuiz *TopQuiz;
	int TopQuestion;
	int q;

	ClearUsed();

	j = 0;
	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TopQuiz = GetTopQuizCorr(&TopQuestion);

	while (TopQuiz)
	{
		if (j % 10 == 0)
		{
			file.Write("<tr style='height:24.75pt'>");

            WriteFieldHeader(file, 6);
			file.Write("#");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 60);
			file.Write(" ");
            WriteFieldFooter(file);

            WriteFieldHeader(file, 6);
			file.Write("Aspie");
            WriteFieldFooter(file);

            WriteFieldHeader(file, 6);
			file.Write("NT");
            WriteFieldFooter(file);

            WriteFieldHeader(file, 6);
			file.Write("Chi2");
            WriteFieldFooter(file);

            WriteFieldHeader(file, 6);
			file.Write("Corr");
            WriteFieldFooter(file);

			file.Write("</tr>");
		}

		j++;

		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 6);
		quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
		while (quiz)
		{
			quiz->WriteName(file);
			sprintf(str, ":%d", q + 1);
			file.Write(str);
			quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            if (quiz)
    			file.Write("<br>");
		}
		WriteFieldFooter(file);
	    
        WriteCenteredFieldHeader(file, 60);
		file.Write(TopQuiz->Quiz[TopQuestion].Text);
        WriteFieldFooter(file);

        TopQuiz->ClearUsed(TopQuestion);
        WriteCenteredFieldHeader(file, 6);
        quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
        while (quiz)
        {
            quiz->WriteAsCI95(file, q);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            if (quiz)
    			file.Write("<br>");
        }
        WriteFieldFooter(file);

        TopQuiz->ClearUsed(TopQuestion);
        WriteCenteredFieldHeader(file, 6);
        quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
        while (quiz)
        {
            quiz->WriteNtCI95(file, q);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            if (quiz)
    			file.Write("<br>");
        }
        WriteFieldFooter(file);

        TopQuiz->ClearUsed(TopQuestion);
        WriteRightFieldHeader(file, 6);
        quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
        while (quiz)
        {
            quiz->WriteAsNtChi2(file, q);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            if (quiz)
    			file.Write("<br>");
        }
        WriteFieldFooter(file);

        TopQuiz->ClearUsed(TopQuestion);
        WriteRightFieldHeader(file, 6);
        quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
        while (quiz)
        {
            quiz->WriteAsNtCorr95(file, q);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            if (quiz)
    			file.Write("<br>");
        }
		WriteFieldFooter(file);

		TopQuiz = GetTopQuizCorr(&TopQuestion);
	}

	file.Write("</table>");
}

/*##################  TQuiz::WriteGroupCorrTable ##########################
*   Purpose....: Write group correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteGroupCorrTable(const char *filename)
{
	int j;
	int g;
	int grp;
    TQuiz *quiz;
    TQuiz *TopQuiz;
    int TopQuestion;
    int q;
	char str[80];
	long double NormCorr[MAX_CROSS];
	int cross;
	int ival;
	int count;
	long double val;
	long double corrval;
	TFile file(filename, 0);

	ClearUsed();

#ifdef ENGLISH
    file.Write("<h2>Grouped results</h2>\n");
    file.Write("<span style='color:#990099'>");
    file.Write("Reversed score questions are showed in red color");
    file.Write("</span><br>");

	file.Write("<span style='color:#009999'>");
    file.Write("High correlation is light blue");
    file.Write("</span><br>");

	file.Write("<span style='color:#990099'>");
    file.Write("Negative correlation is red color");
    file.Write("</span><br>");

	 file.Write("Correlations are calculated against other questions in the group, not including the current question<br>");
	 file.Write("Each group is sorted so the highest AS-NT correlation comes first<br><br>");
#endif

#ifdef SWEDISH
	 file.Write("<h2>Grupperade resultat</h2>\n");
	 file.Write("<span style='color:#990099'>");
	 file.Write("Reverserade frågor visas med röd färg");
	 file.Write("</span><br>");

	file.Write("<span style='color:#009999'>");
	 file.Write("Hög korrelation visas i ljusblått");
	 file.Write("</span><br>");

	file.Write("<span style='color:#990099'>");
	 file.Write("Negativ korrelation visas i rött");
	 file.Write("</span><br>");

	 file.Write("Korrelationer är beräknade genemot andra frågor i gruppen ");
	 file.Write("förutom den nuvarande frågan.<br> Varje grupp är sorterad med ");
	 file.Write("högsta AS-NT korrelation först<br><br>");
#endif

    for (g = 0; g < GROUP_COUNT; g++)
    {
    	file.Write("<table border=3 cellspacing=0 cellpadding=0>");
        
		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 3);
		sprintf(str, "G:%d", g + 1);
		file.Write(str);
        WriteFieldFooter(file);

		  WriteCenteredFieldHeader(file, 24);
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
		  WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("p <");
		  WriteFieldFooter(file);

		for (grp = 0; grp < GROUP_COUNT - 1; grp++)
        {
            WriteFieldHeader(file, 4);
			sprintf(str, "G:%d", grp + 1);
			file.Write(str);
            WriteFieldFooter(file);
		}

		file.Write("</tr>");

    	TopQuiz = GetTopGroupCorr(g, &TopQuestion);

	    while (TopQuiz)
    	{
			file.Write("<tr style='height:24.75pt'>");

    		WriteCenteredFieldHeader(file, 3);
	    	quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
		    while (quiz)
    		{
                if (quiz->Quiz[q].Chi2 <= 6.0)
    				file.Write("<span style='color:#EE0000'>");
    			else
    			{
                    if (quiz->Quiz[q].Chi2 <= 9.3)
        				file.Write("<span style='color:#990099'>");
        		}
                
   		    	quiz->WriteName(file);
    			sprintf(str, ":%d", q + 1);
	    		file.Write(str);

                if (quiz->Quiz[q].Chi2 <= 9.3)
    				file.Write("</span>");

                quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
		    	if (quiz)
    	    		file.Write("<br>");
		    }
		    WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 24);
			if (TopQuiz->Quiz[TopQuestion].Reverse)
				file.Write("<span style='color:#990099'>");
			file.Write(TopQuiz->Quiz[TopQuestion].Text);
			if (TopQuiz->Quiz[TopQuestion].Reverse)
				file.Write("</span>");
		    WriteFieldFooter(file);
					
            cross = 0;
            TopQuiz->ClearUsed(TopQuestion);
            WriteCenteredFieldHeader(file, 4);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            while (quiz)
            {
                NormCorr[cross] = 0.0;
				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					val = quiz->Quiz[q].Group[j].Corr;
					if (val >= NormCorr[cross])
						NormCorr[cross] = val;
				}       
				NormCorr[cross] = 0.9 * NormCorr[cross]; 

#ifdef USE_PERCENT  
				ival = round(100.0 * quiz->Quiz[q].Corr * quiz->Quiz[q].Corr);
				sprintf(str, "%d%", ival);
				file.Write(str);
#else
				ival = round(100.0 * quiz->Quiz[q].Corr);
				if (ival < 0)
				{
				    file.Write("-");
				    ival = -ival;
				}
				
				sprintf(str, ".%02d", ival);
				file.Write(str);
#endif
				
                quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
                if (quiz)
                {   cross++;
    			    file.Write("<br>");
				}
			}
			WriteFieldFooter(file);
					
            cross = 0;
            TopQuiz->ClearUsed(TopQuestion);
            WriteCenteredFieldHeader(file, 4);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            while (quiz)
            {
                NormCorr[cross] = 0.0;
				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					val = quiz->Quiz[q].Group[j].Corr;
					if (val >= NormCorr[cross])
						NormCorr[cross] = val;
				}       
				NormCorr[cross] = 0.9 * NormCorr[cross]; 

				WriteP(file, quiz->Quiz[q].Chi2);
				
                quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
                if (quiz)
                {   cross++;
    			    file.Write("<br>");
				}
			}
			WriteFieldFooter(file);

			for (j = 0; j < GROUP_COUNT - 1; j++)
			{
				cross = 0;
				TopQuiz->ClearUsed(TopQuestion);
				WriteCenteredFieldHeader(file, 4);
				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				while (quiz)
				{
					val = quiz->Quiz[q].Group[j].Corr;
					corrval = val;
					count = quiz->Quiz[q].Group[j].Count;

                    if (count > 3)
                    {

    					if (val > NormCorr[cross])
	    					file.Write("<span style='color:#009999'>");
    
	    				if (val < 0.0)
		    				file.Write("<span style='color:#990099'>");

#ifdef USE_PERCENT
			    		ival = round(100.0 * val * val);
				    	sprintf(str, "%d%", ival);
					    file.Write(str);
#else
    					ival = round(100.0 * val);
	    				if (ival < 0)
		    			{
			    			file.Write("-");
				    		ival = -ival;
					    }

    					sprintf(str, ".%02d", ival);
	    				file.Write(str);
#endif

		    			if (val > NormCorr[cross] || val < 0.0)
							file.Write("</span>");
			    	}
			    	else
			    		file.Write("---");
			    	    

					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					if (quiz)
					{
						cross++;
						file.Write("<br>");
					}
				}
				WriteFieldFooter(file);
			}
			file.Write("</tr>");    
        	TopQuiz = GetTopGroupCorr(g, &TopQuestion);
		}
    	file.Write("</table>");
    	file.Write("<br><br>");
	}
}

/*##################  TQuiz::WritePcaLoadTable ##########################
*   Purpose....: Write Pca loading table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePcaLoadTable(const char *filename)
{
	int j;
	int g;
	int grp;
	 TQuiz *quiz;
    TQuiz *TopQuiz;
    int TopQuestion;
    int q;
	char str[80];
	long double NormCorr[MAX_CROSS];
	int cross;
	int ival;
	int count;
	long double val;
	TFile file(filename, 0);

	ClearUsed();

#ifdef ENGLISH
    file.Write("<h2>Principal components analysis (PCA) results</h2>\n");
    file.Write("<span style='color:#990099'>");
    file.Write("Reversed score questions are showed in red color");
    file.Write("</span><br>");
#endif

#ifdef SWEDISH
	 file.Write("<h2>Principal components analys (PCA) resultat</h2>\n");
	 file.Write("<span style='color:#990099'>");
	 file.Write("Reverserade frågor visas med röd färg");
	 file.Write("</span><br>");

	file.Write("<span style='color:#009999'>");
	 file.Write("Hög korrelation visas i ljusblått");
	 file.Write("</span><br>");
#endif

    for (g = 0; g < GROUP_COUNT; g++)
    {
    	file.Write("<table border=3 cellspacing=0 cellpadding=0>");
        
		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 3);
		sprintf(str, "G:%d", g + 1);
		file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 26);
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
		  WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("Aspie loading");
        WriteFieldFooter(file);

        if (GetPcaCount() > 1)
        {
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("NT loading");
            WriteFieldFooter(file);
		}

        if (GetPcaCount() > 2)
        {
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("g loading");
            WriteFieldFooter(file);
        }

        if (GetPcaCount() > 3)
        {
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("introvert loading");
            WriteFieldFooter(file);
        }

		file.Write("</tr>");

    	TopQuiz = GetTopGroupCorr(g, &TopQuestion);

	    while (TopQuiz)
    	{
			file.Write("<tr style='height:24.75pt'>");

    		WriteCenteredFieldHeader(file, 3);
	    	quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
		    while (quiz)
    		{
		    	quiz->WriteName(file);
    			sprintf(str, ":%d", q + 1);
	    		file.Write(str);
		    	quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
		    	if (quiz)
    	    		file.Write("<br>");
		    }
		    WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 26);
			if (TopQuiz->Quiz[TopQuestion].Reverse)
				file.Write("<span style='color:#990099'>");
			file.Write(TopQuiz->Quiz[TopQuestion].Text);
			if (TopQuiz->Quiz[TopQuestion].Reverse)
				file.Write("</span>");
		    WriteFieldFooter(file);
					
            cross = 0;
			TopQuiz->ClearUsed(TopQuestion);
            WriteCenteredFieldHeader(file, 6);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            while (quiz)
            {
                NormCorr[cross] = 0.0;
				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					val = quiz->Quiz[q].Group[j].Corr;
					if (val >= NormCorr[cross])
						NormCorr[cross] = val;
				}       
				NormCorr[cross] = 0.9 * NormCorr[cross]; 

#ifdef USE_PERCENT  
				ival = round(100.0 * quiz->Quiz[q].Corr * quiz->Quiz[q].Corr);
				sprintf(str, "%d%", ival);
				file.Write(str);
#else
				ival = round(100.0 * quiz->Quiz[q].Corr);
				if (ival < 0)
				{
				    file.Write("-");
					ival = -ival;
				}
				
				sprintf(str, ".%02d", ival);
				file.Write(str);
#endif
				
                quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
                if (quiz)
                {   cross++;
    			    file.Write("<br>");
				}
			}
			WriteFieldFooter(file);
					
            cross = 0;
            TopQuiz->ClearUsed(TopQuestion);
            WriteCenteredFieldHeader(file, 6);
            quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
            while (quiz)
			{
				WritePca(file, quiz->Quiz[q].Pca[0]);

				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				if (quiz)
				{   cross++;
					file.Write("<br>");
				}
			}
			WriteFieldFooter(file);

			cross = 0;
			TopQuiz->ClearUsed(TopQuestion);
			WriteCenteredFieldHeader(file, 6);
			quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
			while (quiz)
			{
                if (GetPcaCount() > 1)
    				WritePca(file, quiz->Quiz[q].Pca[1]);

				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				if (quiz)
				{   cross++;
					file.Write("<br>");
				}
			}
			WriteFieldFooter(file);

			cross = 0;
			TopQuiz->ClearUsed(TopQuestion);
			WriteCenteredFieldHeader(file, 6);
			quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
			while (quiz)
			{
			    if (quiz->GetPcaCount() > 2)
    				WritePca(file, quiz->Quiz[q].Pca[2]);

				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				if (quiz)
				{   cross++;
					file.Write("<br>");
				}
			}
			WriteFieldFooter(file);

			cross = 0;
			TopQuiz->ClearUsed(TopQuestion);
			WriteCenteredFieldHeader(file, 6);
			quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
			while (quiz)
			{
			    if (quiz->GetPcaCount() > 3)
    				WritePca(file, quiz->Quiz[q].Pca[3]);

				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				if (quiz)
				{   cross++;
					file.Write("<br>");
				}
			}
			WriteFieldFooter(file);

			file.Write("</tr>");    
        	TopQuiz = GetTopGroupCorr(g, &TopQuestion);
		}
    	file.Write("</table>");
    	file.Write("<br><br>");
	}
}

/*##################  TQuiz::WriteAverageGroupCorrTable ##########################
*   Purpose....: Write averaged group correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAverageGroupCorrTable(const char *filename)
{
    int Used[MAX_GLOBAL_QUESTIONS];
    int GlobalId;
    int i;
	int j;
	int g;
	int grp;
    TQuiz *quiz;
	 int q;
	char str[80];
	long double NormCorr;
	int ival;
	long double val;
	long double corrval;
    long double LowestCorr;
	TFile file(filename, 0);

    CalcGlobal();
    
#ifdef ENGLISH
	file.Write("<h2>Averaged, grouped results</h2>\n");
	file.Write("<span style='color:#990099'>");
	file.Write("Reversed score questions are showed in red color");
	file.Write("</span><br>");

	file.Write("<span style='color:#009999'>");
	file.Write("High correlation is light blue");
	file.Write("</span><br>");

	file.Write("<span style='color:#990099'>");
	file.Write("Negative correlation is red color");
	file.Write("</span><br>");

	 file.Write("Correlations are calculated against other questions in the group, not including the current question<br>");
	 file.Write("Each group is sorted so the highest AS-NT correlation comes first<br><br>");
#endif

#ifdef SWEDISH
	 file.Write("<h2>Sammanslagna, grupperade resultat</h2>\n");
	 file.Write("<span style='color:#990099'>");
	 file.Write("Reverserade frågor visas med röd färg");
	 file.Write("</span><br>");

	file.Write("<span style='color:#009999'>");
	 file.Write("Hög korrelation visas i ljusblått");
	 file.Write("</span><br>");

	file.Write("<span style='color:#990099'>");
	 file.Write("Negativ korrelation visas i rött");
	 file.Write("</span><br>");

	 file.Write("Korrelationer är beräknade genemot andra frågor i gruppen ");
	 file.Write("förutom den nuvarande frågan.<br> Varje grupp är sorterad med ");
	 file.Write("högsta AS-NT korrelation först<br><br>");
#endif

    for (q = 0; q < MAX_GLOBAL_QUESTIONS; q++)
        Used[q] = FALSE;

	for (g = 0; g < GROUP_COUNT; g++)
	{
		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		file.Write("<tr style='height:24.75pt'>");

		WriteCenteredFieldHeader(file, 3);
		sprintf(str, "G:%d", g + 1);
		file.Write(str);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 24);
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("p <");
		WriteFieldFooter(file);

		for (grp = 0; grp < GROUP_COUNT - 1; grp++)
		{
			WriteFieldHeader(file, 4);
			sprintf(str, "G:%d", grp + 1);
			file.Write(str);
				WriteFieldFooter(file);
		}

		file.Write("</tr>");

		for (;;)
		{
			LowestCorr = -0.1;
			GlobalId = -1;

			for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
			{
				 quiz = GlobalTopQuiz[i];
				 q = GlobalTopQuestion[i];
				 if (!Used[i] && quiz && quiz->Quiz[q].MyGroup == g && GlobalAsNtCorrCount[i])
				 {
                    corrval = GlobalAsNtCorrSum[i] / GlobalAsNtCorrCount[i];
                    corrval = corrval * corrval;
                    if (corrval > LowestCorr)
                    {
                        GlobalId = i;
						LowestCorr = corrval;
                    }
                }
			}

			if (GlobalId >= 0)
			{
				quiz = GlobalTopQuiz[GlobalId];
				q = GlobalTopQuestion[GlobalId];

				file.Write("<tr style='height:24.75pt'>");

				WriteCenteredFieldHeader(file, 3);

                if (GlobalChi2[GlobalId] <= 6.0)
    				file.Write("<span style='color:#EE0000'>");
    			else
    			{
                    if (GlobalChi2[GlobalId] <= 9.3)
        				file.Write("<span style='color:#990099'>");
        		}

				sprintf(str, "%d", GlobalId + 1);
				file.Write(str);
                
                if (GlobalChi2[GlobalId] <= 9.3)
    				file.Write("</span>");

				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 24);
				if (quiz->Quiz[q].Reverse)
					file.Write("<span style='color:#990099'>");
				file.Write(quiz->Quiz[q].Text);
				if (quiz->Quiz[q].Reverse)
					file.Write("</span>");
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 4);

				val = GlobalAsNtCorrSum[GlobalId] / GlobalAsNtCorrCount[GlobalId];

				Used[GlobalId] = TRUE;

#ifdef USE_PERCENT
				ival = round(100.0 * val * val);
				sprintf(str, "%d%", ival);
				file.Write(str);
#else
				ival = round(100.0 * val);
				if (ival < 0)
				{
					file.Write("-");
					ival = -ival;
				}

				sprintf(str, ".%02d", ival);
				file.Write(str);
#endif
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 4);
				WriteP(file, GlobalChi2[GlobalId]);
				WriteFieldFooter(file);

				NormCorr = 0.0;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GlobalGroupCorrCount[GlobalId][j])
					{
						val = GlobalGroupCorrSum[GlobalId][j] / GlobalGroupCorrCount[GlobalId][j];
						if (val >= NormCorr)
							NormCorr = val;
					}
				}
				NormCorr = 0.9 * NormCorr;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					WriteCenteredFieldHeader(file, 4);

					if (GlobalGroupCorrCount[GlobalId][j])
					{
						val = GlobalGroupCorrSum[GlobalId][j] / GlobalGroupCorrCount[GlobalId][j];

						if (val > NormCorr)
							file.Write("<span style='color:#009999'>");

						if (val < 0.0)
							file.Write("<span style='color:#990099'>");

#ifdef USE_PERCENT
						ival = round(100.0 * val * val);
						sprintf(str, "%d%", ival);
						file.Write(str);
#else
						ival = round(100.0 * val);
						if (ival < 0)
						{
							file.Write("-");
							ival = -ival;
						}

						sprintf(str, ".%02d", ival);
						file.Write(str);
#endif

						if (val > NormCorr || val < 0.0)
							file.Write("</span>");
					}
					else
						file.Write("    ");

					WriteFieldFooter(file);

				}
				file.Write("</tr>");
			}
			else
			    break;
	    }
    	file.Write("</table>");
    	file.Write("<br><br>");
	}
}

/*##################  TQuiz::WriteAveragePcaTable ##########################
*   Purpose....: Write averaged PCA table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAveragePcaTable(const char *filename)
{
	 int Used[MAX_GLOBAL_QUESTIONS];
	int GlobalId;
	int i;
	int j;
	int g;
	TQuiz *quiz;
	int q;
	char str[80];
	int ival;
	long double val;
	long double corrval;
	long double LowestCorr;
	TFile file(filename, 0);

	 CalcGlobal();

	ClearUsed();

#ifdef ENGLISH
	file.Write("<h2>Averaged principal components analysis (PCA) results</h2>\n");
	file.Write("<span style='color:#990099'>");
	file.Write("Reversed score questions are showed in red color");
	file.Write("</span><br>");
#endif

#ifdef SWEDISH
	 file.Write("<h2>Sammanslagna principal components analys (PCA) resultat</h2>\n");
	 file.Write("<span style='color:#990099'>");
	 file.Write("Reverserade frågor visas med röd färg");
	 file.Write("</span><br>");
#endif

    for (q = 0; q < MAX_GLOBAL_QUESTIONS; q++)
        Used[q] = FALSE;

	for (g = 0; g < GROUP_COUNT; g++)
	{
		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 3);
		sprintf(str, "G:%d", g + 1);
		file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 26);
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("p < ");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("Aspie loading");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("NT loading");
		WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
	    file.Write("g loading");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
	    file.Write("introvert loading");
        WriteFieldFooter(file);

		file.Write("</tr>");

        for (;;)
		{
			LowestCorr = -0.1;
            GlobalId = -1;

            for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
			{
		        quiz = GlobalTopQuiz[i];
				q = GlobalTopQuestion[i];
				if (!Used[i] && quiz && quiz->Quiz[q].MyGroup == g && GlobalAsNtCorrCount[i])
				{
                    corrval = GlobalAsNtCorrSum[i] / GlobalAsNtCorrCount[i];
                    corrval = corrval * corrval;
                    if (corrval > LowestCorr)
                    {
                        GlobalId = i;
						LowestCorr = corrval;
                    }
                }
            }

            if (GlobalId >= 0)
            {
				quiz = GlobalTopQuiz[GlobalId];
				q = GlobalTopQuestion[GlobalId];

				file.Write("<tr style='height:24.75pt'>");

				WriteCenteredFieldHeader(file, 3);

                if (GlobalChi2[GlobalId] <= 6.0)
    				file.Write("<span style='color:#EE0000'>");
    			else
    			{
                    if (GlobalChi2[GlobalId] <= 9.3)
        				file.Write("<span style='color:#990099'>");
        		}

				sprintf(str, "%d", GlobalId + 1);
				file.Write(str);
                
                if (GlobalChi2[GlobalId] <= 9.3)
    				file.Write("</span>");

				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 26);
				if (quiz->Quiz[q].Reverse)
					file.Write("<span style='color:#990099'>");
				file.Write(quiz->Quiz[q].Text);
				if (quiz->Quiz[q].Reverse)
					file.Write("</span>");
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 6);

				val = GlobalAsNtCorrSum[GlobalId] / GlobalAsNtCorrCount[GlobalId];

				Used[GlobalId] = TRUE;

#ifdef USE_PERCENT  
			    ival = round(100.0 * val * val);
				sprintf(str, "%d%", ival);
				file.Write(str);
#else
	    		ival = round(100.0 * val);
		    	if (ival < 0)
			    {
					file.Write("-");
				    ival = -ival;
				}

				sprintf(str, ".%02d", ival);
				file.Write(str);
#endif
				WriteCenteredFieldHeader(file, 3);
				WriteP(file, GlobalChi2[GlobalId]);
				WriteFieldFooter(file);

				for (j = 0; j < 4; j++)
				{
    				WriteCenteredFieldHeader(file, 6);

                    if (GlobalPcaCount[GlobalId][j])
						WritePca(file, GlobalPcaSum[GlobalId][j] / GlobalPcaCount[GlobalId][j]);

    				WriteFieldFooter(file);
    		    }

				file.Write("</tr>");
			}
			else
			    break;
		}
		file.Write("</table>");
		file.Write("<br><br>");
	}
}

/*##################  TQuiz::WriteAveragePcaCorrTable ##########################
*   Purpose....: Write averaged PCA+correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteAveragePcaCorrTable(const char *filename)
{
    int Used[MAX_GLOBAL_QUESTIONS];
	int AsLoad;
	int NtLoad;
	int GlobalId;
	int i;
	int j;
	int g;
	int grp;
	TQuiz *quiz;
	int q;
	char str[80];
	long double NormCorr;
	long double CorrArr[MAX_GROUP_COUNT];
	int ival;
	long double val;
	long double corrval;
	long double LowestCorr;
	int ok;
	int first;
	int neg;
	TFile file(filename, 0);

	ClearUsed();

#ifdef ENGLISH
	file.Write("<h2>Averaged results</h2>\n");
	file.Write("<span style='color:#990099'>");
	file.Write("Reversed score questions are showed in red color");
	file.Write("</span><br>");
	file.Write("Correlated groups are shown with most significant groups first up to 90% of maximunm correlation");
#endif

#ifdef SWEDISH
	 file.Write("<h2>Sammanslagna resultat</h2>\n");
	 file.Write("<span style='color:#990099'>");
	 file.Write("Reverserade frågor visas med röd färg");
	 file.Write("</span><br>");
	 file.Write("Korrelerade grupper visas med mest signifikant grupp först t.o.m. 90% av maximal korrelation");
#endif

    for (q = 0; q < MAX_GLOBAL_QUESTIONS; q++)
        Used[q] = FALSE;

	for (g = 0; g < GROUP_COUNT; g++)
	{
		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		file.Write("<tr style='height:24.75pt'>");

		WriteCenteredFieldHeader(file, 3);
		sprintf(str, "#", g + 1);
		file.Write(str);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 45);
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("p <");
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("Aspie score NO/YES");
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("NT score NO/YES");
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 40);
		file.Write("Correlated groups");
		WriteFieldFooter(file);

		file.Write("</tr>");

        for (;;)
		{
			LowestCorr = -0.1;
            GlobalId = -1;

            for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
			{
		        quiz = GlobalTopQuiz[i];
				q = GlobalTopQuestion[i];
				if (!Used[i] && quiz && quiz->Quiz[q].MyGroup == g && GlobalAsNtCorrCount[i] && GlobalChi2[i] >= 6.0)
				{
                    corrval = GlobalAsNtCorrSum[i] / GlobalAsNtCorrCount[i];
                    corrval = corrval * corrval;
                    if (corrval > LowestCorr)
                    {
                        GlobalId = i;
						LowestCorr = corrval;
                    }
                }
            }

            if (GlobalId >= 0)
            {
				quiz = GlobalTopQuiz[GlobalId];
				q = GlobalTopQuestion[GlobalId];

				file.Write("<tr style='height:24.75pt'>");

				WriteCenteredFieldHeader(file, 3);

                if (GlobalChi2[GlobalId] <= 6.0)
    				file.Write("<span style='color:#EE0000'>");
    			else
    			{
                    if (GlobalChi2[GlobalId] <= 9.3)
        				file.Write("<span style='color:#990099'>");
        		}

				sprintf(str, "%d", GlobalId + 1);
				file.Write(str);
                
                if (GlobalChi2[GlobalId] <= 9.3)
    				file.Write("</span>");

				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 45);
				if (quiz->Quiz[q].Reverse)
					file.Write("<span style='color:#990099'>");
				file.Write(quiz->Quiz[q].Text);
				if (quiz->Quiz[q].Reverse)
					file.Write("</span>");
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 3);

				val = GlobalAsNtCorrSum[GlobalId] / GlobalAsNtCorrCount[GlobalId];

				Used[GlobalId] = TRUE;

#ifdef USE_PERCENT
				ival = round(100.0 * val * val);
				sprintf(str, "%d%", ival);
				file.Write(str);
#else
				ival = round(100.0 * val);
				if (ival < 0)
				{
					file.Write("-");
					ival = -ival;
				}

				sprintf(str, ".%02d", ival);
				file.Write(str);
#endif
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 3);
				WriteP(file, GlobalChi2[GlobalId]);
				WriteFieldFooter(file);

                if (GlobalPcaCount[GlobalId][0])
					AsLoad = round(100 * GlobalPcaSum[GlobalId][0] / GlobalPcaCount[GlobalId][0]);
			    else
					AsLoad = 0;

			    if (GlobalPcaCount[GlobalId][1])
				    NtLoad = round(100 * GlobalPcaSum[GlobalId][1] / GlobalPcaCount[GlobalId][1]);
			    else
                    NtLoad = 0;                    

				if (AsLoad > 0 && NtLoad > 0)
				{
					if (AsLoad > NtLoad)
					{
						AsLoad = AsLoad - NtLoad;
						NtLoad = 0;
					}
					else
					{
						NtLoad = NtLoad - AsLoad;
						AsLoad = 0;
					}
				}

				WriteCenteredFieldHeader(file, 3);
				sprintf(str, "0/%d", AsLoad);
				file.Write(str);
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 3);

			    if (GlobalPcaCount[GlobalId][1])
				{
					if (NtLoad >= 0)
						sprintf(str, "0/%d", NtLoad);
					else
						sprintf(str, "%d/0", -NtLoad);
					file.Write(str);
				}

				WriteFieldFooter(file);

				NormCorr = 0.0;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GlobalGroupCorrCount[GlobalId][j])
					{
						val = GlobalGroupCorrSum[GlobalId][j] / GlobalGroupCorrCount[GlobalId][j];
						val = val * val;
						if (val >= NormCorr)
							NormCorr = val;
					}
				}
				NormCorr = 0.81 * NormCorr;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GlobalGroupCorrCount[GlobalId][j])
					{
						val = GlobalGroupCorrSum[GlobalId][j] / GlobalGroupCorrCount[GlobalId][j];
						CorrArr[j] = val * val;
				    }
				    else
				        CorrArr[j] = 0.0;
				}

				WriteFieldHeader(file, 40);

				first = TRUE;
				ok = TRUE;
				while (ok)
				{
					ok = FALSE;
					corrval = 0.0;

					for (j = 0; j < GROUP_COUNT - 1; j++)
					{
					    if (CorrArr[j] >= NormCorr)
					    {
					        if (CorrArr[j] > corrval)
					        {
					            grp = j;
					            corrval = CorrArr[j];
					            ok = TRUE;
					        }
					    }
					}
					
					if (ok)
					{
                        CorrArr[grp] = 0.0;
					
						if (!first)
							file.Write(", ");

						val = GlobalGroupCorrSum[GlobalId][grp] / GlobalGroupCorrCount[GlobalId][grp];

        				neg = quiz->Quiz[q].Reverse;

        				if (val < 0.0)
        				    neg = !neg;

                        if (neg)
    						file.Write(Group[grp].NegName);
    					else
    						file.Write(Group[grp].PosName);

						first = FALSE;
					}
				}
				WriteFieldFooter(file);
				file.Write("</tr>");
			}
			else
			    break;
		}
		file.Write("</table>");
		file.Write("<br><br>");
	}
}

/*##################  TQuiz::WriteLinkQuestion ##########################
*   Purpose....: Write link report question	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteLinkQuestion(TFile *file, int Question, int GlobalId)
{
	char str[80];
	
    sprintf(str, "<a href=\"#%d\">", GlobalId + 1);
	file->Write(str);
	sprintf(str, "%d. ", GlobalId + 1);
	file->Write(str);
	file->Write(Quiz[Question].Text);
    file->Write("</a><br>");
}

/*##################  TQuiz::WriteLinkGroup ##########################
*   Purpose....: Write link report group	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteLinkGroup(TFile *file, int Group)
{
	switch (Group)
	{
	    case GROUP_ASPIE_BIOLOGY:
	        file->Write("ASPIE_BIOLOGY");
	        break;
	            
	    case GROUP_NT_BIOLOGY:
	        file->Write("NT_BIOLOGY");
	        break;
	            
	    case GROUP_ASPIE_TALENT:
	        file->Write("ASPIE_ABILITY");
	        break;
	            
	    case GROUP_NT_TALENT:
	        file->Write("ASPIE_DISABILITY");
	        break;
	            
	    case GROUP_ASPIE_SOCIAL:
	        file->Write("ASPIE_SOCIAL");
	        break;
	            
	    case GROUP_ASPIE_COMM:
	        file->Write("STIMS");
	        break;
	            
	    case GROUP_ASPIE_NVC:
	        file->Write("ASPIE_NVC");
	        break;
	            
	    case GROUP_NONVERBAL:
	        file->Write("NT_COMMUNICATION");
	        break;
	            
	    case GROUP_SEX:
	        file->Write("SEX");
	        break;
	            
	    case GROUP_MIXED:
	        file->Write("MIXED");
	        break;
	}
}

/*##################  TQuiz::WriteLinkReport ##########################
*   Purpose....: Write link report	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteLinkReport(const char *filename)
{
    int Used[MAX_GLOBAL_QUESTIONS];
	int AsLoad;
	int NtLoad;
	int GlobalId;
	int i;
	int j;
	int g;
	int grp;
	TQuiz *quiz;
	int q;
	TQuiz *TopQuiz;
	int TopQuestion;
	char str[80];
	long double NormCorr;
	long double CorrArr[MAX_GROUP_COUNT];
	int ival;
	int count;
	int reverse;
	long double val;
	long double corrval;
	long double LowestCorr;
	int ok;
	int first;
	TFile file(filename, 0);

#ifdef ENGLISH
	file.Write("<h2>Aspie-quiz evaluation</h2>\n");
#endif

#ifdef SWEDISH
	file.Write("<h2>Aspie-quiz utvärdering</h2>\n");
#endif

#ifdef ENGLISH
	file.Write("<h3>Sumaries</h3>\n");
	
    file.Write("<a href=\"avg.htm\">Grouped overview</a><br>\n");
    file.Write("<a href=\"avgcorr.htm\">Averaged group correlations</a><br>\n");
    file.Write("<a href=\"avgpca.htm\">Averaged PCA-loadings</a><br>\n");
    file.Write("<a href=\"groupcorr.htm\">Grouping of Aspie-quiz I-III + ND + 5-9</a><br>\n");
    file.Write("<a href=\"pcaload.htm\">PCA loadings of Aspie-quiz I-III + ND + 5-9 + R1</a><br>\n");
    file.Write("<a href=\"pcacorr.htm\">Correlation between PCA loadings and psychiatric diagnosis</a><br>\n");
    file.Write("<a href=\"group.htm\">Correlation between groups</a><br>\n");

	file.Write("<h3>Quiz versions</h3>\n");
#endif

#ifdef SWEDISH
	file.Write("<h3>Summeringar</h3>\n");

    file.Write("<a href=\"avg.htm\">Översiktlig, grupperad rapport</a><br>\n");
    file.Write("<a href=\"avgcorr.htm\">Sammanvägda gruppkorrelationer</a><br>\n");
    file.Write("<a href=\"avgpca.htm\">Sammanvägda PCA-vikter</a><br>\n");
    file.Write("<a href=\"groupcorr.htm\">Gruppering av Aspie-quiz I-III + ND + 5-9 + R1</a><br>\n");
    file.Write("<a href=\"pcaload.htm\">PCA koefficienter för Aspie-quiz I-III + ND + 5-9 + R1</a><br>\n");
    file.Write("<a href=\"pcacorr.htm\">Korrelation mellan PCA och psykiatriska diagnoser</a><br>\n");
    file.Write("<a href=\"group.htm\">Korrelation mellan grupper</a><br>\n");

	file.Write("<h3>Quiz versioner</h3>\n");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[0]->WriteName(file);
	file.Write("\">");
	file.Write("Version ");
    CrossQuiz[0]->WriteName(file);
    file.Write("</a>");

#ifdef ENGLISH
    file.Write(" <a href=\"quiz1.htm\">summary</a><br>\n");
#endif
    
#ifdef SWEDISH
    file.Write(" <a href=\"quiz1.htm\">summering</a><br>\n");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[1]->WriteName(file);
	file.Write("\">");
	file.Write("Version ");
    CrossQuiz[1]->WriteName(file);
    file.Write("</a>");

#ifdef ENGLISH
    file.Write(" <a href=\"quiz2.htm\">summary</a> <a href=\"ref2.htm\">referer sites</a><br>\n");
#endif
    
#ifdef SWEDISH
    file.Write(" <a href=\"quiz2.htm\">summering</a> <a href=\"ref2.htm\">referenssajter</a><br>\n");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[2]->WriteName(file);
	file.Write("\">");
	file.Write("Version ");
    CrossQuiz[2]->WriteName(file);
    file.Write("</a>");

#ifdef ENGLISH
    file.Write(" <a href=\"quiz3.htm\">summary</a> <a href=\"ref3.htm\">referer sites</a><br>\n");
#endif
    
#ifdef SWEDISH
    file.Write(" <a href=\"quiz3.htm\">summering</a> <a href=\"ref3.htm\">referenssajter</a><br>\n");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[3]->WriteName(file);
	file.Write("\">");
	file.Write("Neurodiversity version ");
    file.Write("</a>");

#ifdef ENGLISH
    file.Write(" <a href=\"quiznd.htm\">summary</a> <a href=\"refnd.htm\">referer sites</a><br>\n");
#endif
    
#ifdef SWEDISH
    file.Write(" <a href=\"quiznd.htm\">summering</a> <a href=\"refnd.htm\">referenssajter</a><br>\n");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[4]->WriteName(file);
	file.Write("\">");
	file.Write("Version ");
    CrossQuiz[4]->WriteName(file);
    file.Write("</a>");

#ifdef ENGLISH
    file.Write(" <a href=\"quiz5.htm\">summary</a> <a href=\"ref5.htm\">referer sites</a>");
    file.Write(" <a href=\"iq.htm\">IQ test</a>");
    file.Write("<br>\n");
#endif
    
#ifdef SWEDISH
    file.Write(" <a href=\"quiz5.htm\">summering</a> <a href=\"ref5.htm\">referenssajter</a>");
    file.Write(" <a href=\"iq.htm\">IQ test</a>");
    file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[5]->WriteName(file);
	file.Write("\">");
	file.Write("Version ");
    CrossQuiz[5]->WriteName(file);
    file.Write("</a>");

#ifdef ENGLISH
    file.Write(" <a href=\"quiz6.htm\">summary</a> <a href=\"ref6.htm\">referer sites</a>");
    file.Write(" <a href=\"race6.htm\">ancestry</a>");
    file.Write(" <a href=\"hair6.htm\">hair-color</a>");
    file.Write(" <a href=\"eye6.htm\">eye-color</a>");
    file.Write("<br>");
#endif
    
#ifdef SWEDISH
    file.Write(" <a href=\"quiz6.htm\">summering</a> <a href=\"ref6.htm\">referenssajter</a>");
    file.Write(" <a href=\"race6.htm\">ursprung</a>");
    file.Write(" <a href=\"hair6.htm\">hårfärg</a>");
    file.Write(" <a href=\"eye6.htm\">ögonfärg</a>");
    file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[6]->WriteName(file);
	file.Write("\">");
	file.Write("Version ");
    CrossQuiz[6]->WriteName(file);
    file.Write("</a>");

#ifdef ENGLISH
    file.Write(" <a href=\"quiz7.htm\">summary</a> <a href=\"ref7.htm\">referer sites</a>");
    file.Write(" <a href=\"race7.htm\">ancestry</a>");
    file.Write(" <a href=\"hair7.htm\">hair-color</a>");
    file.Write(" <a href=\"eye7.htm\">eye-color</a>");
    file.Write("<br>");
#endif
    
#ifdef SWEDISH
    file.Write(" <a href=\"quiz7.htm\">summering</a> <a href=\"ref7.htm\">referenssajter</a>");
    file.Write(" <a href=\"race7.htm\">ursprung</a>");
    file.Write(" <a href=\"hair7.htm\">hårfärg</a>");
    file.Write(" <a href=\"eye7.htm\">ögonfärg</a>");
    file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	CrossQuiz[7]->WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[7]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quiz8.htm\">summary</a> <a href=\"ref8.htm\">referer sites</a>");
	file.Write(" <a href=\"hair8.htm\">hair-color</a>");
	file.Write(" <a href=\"eye8.htm\">eye-color</a>");
	file.Write(" <a href=\"stim8.htm\">stims</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	file.Write(" <a href=\"quiz8.htm\">summering</a> <a href=\"ref8.htm\">referenssajter</a>");
	file.Write(" <a href=\"hair8.htm\">hårfärg</a>");
	file.Write(" <a href=\"eye8.htm\">ögonfärg</a>");
	file.Write(" <a href=\"stim8.htm\">stimming</a>");
	file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[8]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quiz9.htm\">summary</a> <a href=\"ref9.htm\">referer sites</a>");
	 file.Write(" <a href=\"hair9.htm\">hair-color</a>");
	 file.Write(" <a href=\"eye9.htm\">eye-color</a>");
	 file.Write(" <a href=\"abo9.htm\">ABO</a>");
	 file.Write(" <a href=\"park9.htm\">Parkinson</a>");
	 file.Write(" <a href=\"alz9.htm\">Alzheimer</a>");
	 file.Write(" <a href=\"cftr9.htm\">Cystic fibrosis</a>");
	 file.Write(" <a href=\"hfe9.htm\">Hemochromatosis</a>");
	 file.Write(" <a href=\"leiden9.htm\">Factor V Leiden</a>");
	 file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quiz9.htm\">summering</a> <a href=\"ref9.htm\">referenssajter</a>");
	 file.Write(" <a href=\"hair9.htm\">hårfärg</a>");
	 file.Write(" <a href=\"eye9.htm\">ögonfärg</a>");
	 file.Write(" <a href=\"abo9.htm\">ABO</a>");
	 file.Write(" <a href=\"park9.htm\">Parkinson</a>");
	 file.Write(" <a href=\"alz9.htm\">Alzheimer</a>");
	 file.Write(" <a href=\"cftr9.htm\">Cystisk fibros</a>");
	 file.Write(" <a href=\"hfe9.htm\">Hemokromatos</a>");
	 file.Write(" <a href=\"leiden9.htm\">Factor V Leiden</a>");
	 file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[9]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quizr1.htm\">summary</a> <a href=\"refr1.htm\">referer sites</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quizr1.htm\">summering</a> <a href=\"refr1.htm\">referenssajter</a>");
	 file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[10]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quizr2.htm\">summary</a> <a href=\"refr2.htm\">referer sites</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quizr2.htm\">summering</a> <a href=\"refr2.htm\">referenssajter</a>");
	 file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[11]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quizr3.htm\">summary</a> <a href=\"refr3.htm\">referer sites</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quizr3.htm\">summering</a> <a href=\"refr3.htm\">referenssajter</a>");
	 file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[12]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quizr4.htm\">summary</a> <a href=\"refr4.htm\">referer sites</a> <a href=\"aq.htm\">AQ test</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quizr4.htm\">summering</a> <a href=\"refr4.htm\">referenssajter</a>");
	 file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[13]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quizr5.htm\">summary</a> <a href=\"refr5.htm\">referer sites</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quizr5.htm\">summering</a> <a href=\"refr5.htm\">referenssajter</a>");
	 file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	CrossQuiz[14]->WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quizr6.htm\">summary</a> <a href=\"refr6.htm\">referer sites</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quizr6.htm\">summering</a> <a href=\"refr6.htm\">referenssajter</a>");
	 file.Write("<br>");
#endif

	file.Write("<a name=\"QUIZ");
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
	WriteName(file);
	file.Write("</a>");

#ifdef ENGLISH
	file.Write(" <a href=\"quizr7.htm\">summary</a> <a href=\"refr7.htm\">referer sites</a>");
	file.Write("<br>");
#endif

#ifdef SWEDISH
	 file.Write(" <a href=\"quizr7.htm\">summering</a> <a href=\"refr7.htm\">referenssajter</a>");
	 file.Write("<br>");
#endif

	file.Write("<h3>Histograms</h3>\n");

	file.Write("<p><img src=\"all.jpg\" ALIGN=BOTTOM WIDTH=560 HEIGHT=480 BORDER=0></p>");
	file.Write("<p><img src=\"dx.jpg\" ALIGN=BOTTOM WIDTH=560 HEIGHT=600 BORDER=0></p>");
	file.Write("<p><img src=\"birth9.jpg\" ALIGN=BOTTOM WIDTH=360 HEIGHT=480 BORDER=0></p>");

#ifdef ENGLISH
	file.Write("<h3>Groups</h3>\n");
#endif

#ifdef SWEDISH
	file.Write("<h3>Grupper</h3>\n");
#endif

	for (g = 0; g < GROUP_COUNT; g++)
	{
        file.Write("<a href=\"#");
        WriteLinkGroup(&file, g);
        file.Write("\">");
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
		  file.Write("</a><br>");
    }

#ifdef ENGLISH
	file.Write("<h3>Questions</h3>\n");
#endif

#ifdef SWEDISH
	 file.Write("<h3>Frågor</h3>\n");
#endif

    for (GlobalId = 0; GlobalId < MAX_GLOBAL_QUESTIONS; GlobalId++)
    {
        quiz = GlobalTopQuiz[GlobalId];
        q = GlobalTopQuestion[GlobalId];

        if (quiz && GlobalChi2[GlobalId] >= 6.0)
            quiz->WriteLinkQuestion(&file, q, GlobalId);
    }

	ClearUsed();

    for (q = 0; q < MAX_GLOBAL_QUESTIONS; q++)
        Used[q] = FALSE;

	for (g = 0; g < GROUP_COUNT; g++)
	{
	    file.Write("<h3>");
	    file.Write("<a name=\"");
        WriteLinkGroup(&file, g);
        file.Write("\">");
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
        file.Write("</a>");
        file.Write("</h3>");
        
        for (;;)
		{
			LowestCorr = -0.1;
            GlobalId = -1;

            for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
			{
		        quiz = GlobalTopQuiz[i];
				q = GlobalTopQuestion[i];
				if (!Used[i] && quiz && quiz->Quiz[q].MyGroup == g && GlobalAsNtCorrCount[i] && GlobalChi2[i] >= 6.0)
				{
                    corrval = GlobalAsNtCorrSum[i] / GlobalAsNtCorrCount[i];
                    corrval = corrval * corrval;
                    if (corrval > LowestCorr)
                    {
                        GlobalId = i;
						LowestCorr = corrval;
                    }
                }
            }

            if (GlobalId >= 0)
            {
				TopQuiz = GlobalTopQuiz[GlobalId];
				TopQuestion = GlobalTopQuestion[GlobalId];

        	    file.Write("<h4>");
	            file.Write("<a name=\"");
	            sprintf(str, "%d", GlobalId + 1);
	            file.Write(str);
                file.Write("\">");
                file.Write(str);
                file.Write(". ");
				file.Write(TopQuiz->Quiz[TopQuestion].Text);
                file.Write("</a>");
                file.Write("</h4>");


#ifdef ENGLISH
            	file.Write("Quiz versions: ");
#endif

#ifdef SWEDISH
            	file.Write("Quiz versioner: ");
#endif

                count = 0;

				TopQuiz->ClearUsed(TopQuestion);
    	    	quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
    		    while (quiz)
        		{
                    count += quiz->All.Count[q];
        		
                    file.Write("<a href=\"#QUIZ");
		        	quiz->WriteName(file);
                    file.Write("\">");
		        	quiz->WriteName(file);
                    file.Write("</a>");

    		    	sprintf(str, ":%d", q + 1);
	    		    file.Write(str);
		    	    quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
		    	    if (quiz)
    	    		    file.Write(", ");
    		    }


#ifdef ENGLISH
    		    sprintf(str, ", %d answers<br>\n", count);
#endif

#ifdef SWEDISH
    		    sprintf(str, ", %d svar<br>\n", count);
#endif

    		    file.Write(str);


				val = GlobalAsNtCorrSum[GlobalId] / GlobalAsNtCorrCount[GlobalId];

				Used[GlobalId] = TRUE;

#ifdef ENGLISH
            	file.Write("Pearson's r: ");
#endif

#ifdef SWEDISH
            	file.Write("Pearson r: ");
#endif
				

#ifdef USE_PERCENT
				ival = round(100.0 * val * val);
				sprintf(str, "%d%", ival);
				file.Write(str);
#else
				ival = round(100.0 * val);
				if (ival < 0)
				{
					file.Write("-");
					ival = -ival;
				}

				sprintf(str, ".%02d", ival);
				file.Write(str);
#endif
                file.Write("<br>");


#ifdef ENGLISH
            	file.Write("Chi-square: ");
#endif

#ifdef SWEDISH
            	file.Write("Chi-2: ");
#endif

				WriteChi2(file, GlobalChi2[GlobalId]);

                file.Write("<br>");


#ifdef ENGLISH
            	file.Write("p < ");
#endif

#ifdef SWEDISH
            	file.Write("p <  ");
#endif

				WriteP(file, GlobalChi2[GlobalId]);

                file.Write("<br>");

#ifdef ENGLISH
            	file.Write("Cramer's phi: ");
#endif

#ifdef SWEDISH
            	file.Write("Cramers phi: ");
#endif

				val = GlobalChi2[GlobalId] / (long double)count;
				val = sqrtl(val);

				ival = round(100.0 * val);

				sprintf(str, ".%02d", ival);
				file.Write(str);

                file.Write("<br>");

                if (GlobalPcaCount[GlobalId][0])
					AsLoad = round(100 * GlobalPcaSum[GlobalId][0] / GlobalPcaCount[GlobalId][0]);
			    else
					AsLoad = 0;

			    if (GlobalPcaCount[GlobalId][1])
				    NtLoad = round(100 * GlobalPcaSum[GlobalId][1] / GlobalPcaCount[GlobalId][1]);
			    else
                    NtLoad = 0;                    

				if (AsLoad > 0 && NtLoad > 0)
				{
					if (AsLoad > NtLoad)
					{
						AsLoad = AsLoad - NtLoad;
						NtLoad = 0;
					}
					else
					{
						NtLoad = NtLoad - AsLoad;
						AsLoad = 0;
					}
				}

#ifdef ENGLISH
    			sprintf(str, "Aspie score: NO 0, YES %d", AsLoad);
#endif

#ifdef SWEDISH
	    		sprintf(str, "Aspie poäng: NEJ 0, JA %d", AsLoad);
#endif
		    	file.Write(str);
			    file.Write("<br>");


                if (GlobalPcaCount[GlobalId][1])
                {

			        if (NtLoad >= 0)
#ifdef ENGLISH
				    	sprintf(str, "Neurotypical score: NO 0, YES %d", NtLoad);
#endif

#ifdef SWEDISH
					    sprintf(str, "Neurotypisk poäng: NEJ 0, JA %d", NtLoad);
#endif
    				else
#ifdef ENGLISH
	    				sprintf(str, "Neurotypical score: NO %d, YES 0", -NtLoad);
#endif

#ifdef SWEDISH
		    			sprintf(str, "Neurotypisk poäng: NEJ %d, JA 0", -NtLoad);
#endif

			    	file.Write(str);
				    file.Write("<br>");
				}

                if (GlobalPcaCount[GlobalId][0])
                {
       				file.Write("PCA: Aspie: ");
	    			WritePca(file, GlobalPcaSum[GlobalId][0] / GlobalPcaCount[GlobalId][0]);
                }	    			

                if (GlobalPcaCount[GlobalId][1])
                {
        			file.Write(", NT: ");
	    			WritePca(file, GlobalPcaSum[GlobalId][1] / GlobalPcaCount[GlobalId][1]);
                }	    			

                if (GlobalPcaCount[GlobalId][2])
                {
       				file.Write(", g: ");
	    			WritePca(file, GlobalPcaSum[GlobalId][2] / GlobalPcaCount[GlobalId][2]);
                }	    			

                if (GlobalPcaCount[GlobalId][3])
                {
        			file.Write(", introvert: ");
	    			WritePca(file, GlobalPcaSum[GlobalId][3] / GlobalPcaCount[GlobalId][3]);
                }	    			

                file.Write("<br>");


#ifdef ENGLISH
                file.Write("Correlates with: ");
#endif

#ifdef SWEDISH
                file.Write("Korrelaterar med: ");
#endif

				NormCorr = 0.0;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GlobalGroupCorrCount[GlobalId][j])
					{
						val = GlobalGroupCorrSum[GlobalId][j] / GlobalGroupCorrCount[GlobalId][j];
						val = val * val;
						if (val >= NormCorr)
							NormCorr = val;
					}
				}
				NormCorr = 0.81 * NormCorr;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GlobalGroupCorrCount[GlobalId][j])
					{
						val = GlobalGroupCorrSum[GlobalId][j] / GlobalGroupCorrCount[GlobalId][j];
						CorrArr[j] = val * val;
				    }
				    else
				        CorrArr[j] = 0.0;
				}

				first = TRUE;
				ok = TRUE;
				while (ok)
				{
					ok = FALSE;
					corrval = 0.0;

					for (j = 0; j < GROUP_COUNT - 1; j++)
					{
					    if (CorrArr[j] >= NormCorr)
					    {
					        if (CorrArr[j] > corrval)
					        {
					            grp = j;
					            corrval = CorrArr[j];
					            ok = TRUE;
					        }
					    }
					}
					
					if (ok)
					{
                        CorrArr[grp] = 0.0;
					
						if (!first)
							file.Write(", ");

						val = GlobalGroupCorrSum[GlobalId][grp] / GlobalGroupCorrCount[GlobalId][grp];

						if (val < 0.0)
						{
						    reverse = TRUE;
						    val = -val;
						}
						else
						    reverse = FALSE;

        				ival = round(100.0 * val);

        				if (TopQuiz->Quiz[TopQuestion].Reverse)
        				    reverse = !reverse;

                        file.Write("<a href=\"#");
                        WriteLinkGroup(&file, grp);
                        file.Write("\">");

                        if (reverse)
                    		file.Write(Group[grp].NegName);
                    	else
                    		file.Write(Group[grp].PosName);

                		file.Write("</a>");

    					sprintf(str, " (.%02d)", ival);
	    				file.Write(str);
                        
						first = FALSE;
					}

				}
				file.Write("<br>");
			}
			else
			    break;
		}
		file.Write("<br>");
	}

}

/*##################  TQuiz::WritePcaCorrRow ##########################
*   Purpose....: Write Pca correlation row	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePcaCorrRow(TFile &File, const char *comment, int PopType)
{
	int pca;
	int q;
    int count;
    TQuiz *quiz;
    TQuiz *QuizArr[MAX_CROSS + 1];
    int rows;
    int ok;

	File.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(File, 25);
	File.Write(comment);
	WriteFieldFooter(File);

    rows = 0;
    for (q = 1; q < MAX_CROSS; q++)
    {
        quiz = CrossQuiz[q];

        if (quiz)
        {
            switch (PopType)
            {
                case POP_TYPE_AS:
                    ok = quiz->As.ValueCount > 5;
                    break;

                case POP_TYPE_ASPIE:
                    ok = quiz->Aspie.ValueCount > 5;
                    break;

                case POP_TYPE_ADD:
                    ok = quiz->Add.ValueCount > 5;
                    break;

                case POP_TYPE_NT:
                    ok = quiz->Nt.ValueCount > 5;
                    break;

                case POP_TYPE_HYPERLEXIA:
                    ok = quiz->Hyperlexia.ValueCount > 5;
                    break;

                case POP_TYPE_DYSPRAXIA:
                    ok = quiz->Dyspraxia.ValueCount > 5;
                    break;

                case POP_TYPE_DYSLEXIA:
                    ok = quiz->Dyslexia.ValueCount > 5;
                    break;

                case POP_TYPE_DYSCALCULIA:
                    ok = quiz->Dyscalculia.ValueCount > 5;
                    break;

                case POP_TYPE_OCD:
                    ok = quiz->OCD.ValueCount > 5;
                    break;

                case POP_TYPE_ODD:
                    ok = quiz->ODD.ValueCount > 5;
                    break;

                case POP_TYPE_SYNAESTHESIA:
                    ok = quiz->Synaesthesia.ValueCount > 5;
                    break;

                case POP_TYPE_PA:
                    ok = quiz->PA.ValueCount > 5;
                    break;

                case POP_TYPE_DYSGRAPHIA:
                    ok = quiz->Dysgraphia.ValueCount > 5;
                    break;

                case POP_TYPE_BIPOLAR:
                    ok = quiz->Bipolar.ValueCount > 5;
                    break;

                case POP_TYPE_TS:
                    ok = quiz->Ts.ValueCount > 5;
                    break;

                case POP_TYPE_SCHIZOPHRENIA:
                    ok = quiz->Schizophrenia.ValueCount > 5;
                    break;

                case POP_TYPE_SOCIAL_PHOBIA:
                    ok = quiz->SocialPhobia.ValueCount > 5;
                    break;

                case POP_TYPE_LOW_IQ:
                    ok = quiz->LowIQ.ValueCount > 5;
                    break;

                case POP_TYPE_HIGH_IQ:
                    ok = quiz->HighIQ.ValueCount > 5;
                    break;

                default:
                    ok = FALSE;
                    break;
            }

            if (ok)
            {
                QuizArr[rows] = quiz;
                rows++;
            }
        }
    }

    switch (PopType)
    {
        case POP_TYPE_AS:
            ok = As.ValueCount > 5;
            break;

        case POP_TYPE_ASPIE:
            ok = Aspie.ValueCount > 5;
            break;

        case POP_TYPE_ADD:
            ok = Add.ValueCount > 5;
            break;

        case POP_TYPE_NT:
            ok = Nt.ValueCount > 5;
            break;

        case POP_TYPE_HYPERLEXIA:
            ok = Hyperlexia.ValueCount > 5;
            break;

        case POP_TYPE_DYSPRAXIA:
            ok = Dyspraxia.ValueCount > 5;
            break;

        case POP_TYPE_DYSLEXIA:
            ok = Dyslexia.ValueCount > 5;
            break;

        case POP_TYPE_DYSCALCULIA:
            ok = Dyscalculia.ValueCount > 5;
            break;

        case POP_TYPE_OCD:
            ok = OCD.ValueCount > 5;
            break;

        case POP_TYPE_ODD:
            ok = ODD.ValueCount > 5;
            break;

        case POP_TYPE_SYNAESTHESIA:
            ok = Synaesthesia.ValueCount > 5;
            break;

        case POP_TYPE_PA:
            ok = PA.ValueCount > 5;
            break;

        case POP_TYPE_DYSGRAPHIA:
            ok = Dysgraphia.ValueCount > 5;
            break;

        case POP_TYPE_BIPOLAR:
            ok = Bipolar.ValueCount > 5;
            break;

        case POP_TYPE_TS:
            ok = Ts.ValueCount > 5;
            break;

        case POP_TYPE_SCHIZOPHRENIA:
            ok = Schizophrenia.ValueCount > 5;
            break;

        case POP_TYPE_SOCIAL_PHOBIA:
            ok = SocialPhobia.ValueCount > 5;
            break;

        case POP_TYPE_LOW_IQ:
            ok = LowIQ.ValueCount > 5;
            break;

        case POP_TYPE_HIGH_IQ:
            ok = HighIQ.ValueCount > 5;
            break;

        default:
            ok = FALSE;
    }

    if (ok)
    {
        QuizArr[rows] = this;
        rows++;
    }

	WriteCenteredFieldHeader(File, 10);

	for (q = 0; q < rows; q++)
	{
        if (q)
			File.Write("<br>");
            		
		QuizArr[q]->WriteName(File);
    }
	WriteFieldFooter(File);
                        
	for (pca = -1; pca < 4; pca++)
	{
		count = 0;

		WriteCenteredFieldHeader(File, 3);

		for (q = 0; q < rows; q++)
		{
            if (q)
				File.Write("<br>");
            		
			quiz = QuizArr[q];

			if (quiz->GetPcaCount() > pca)
				WritePcaPopCorr(File, quiz, PopType, pca);
		}

		WriteFieldFooter(File);

	}

	File.Write("</tr>");
}

/*##################  TQuiz::WritePcaCorrTable ##########################
*   Purpose....: Write Pca correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePcaCorrTable(const char *filename)
{
    int i;
	int q;
    int count;
    TQuiz *quiz;
	TFile file(filename, 0);

#ifdef ENGLISH
    file.Write("<h2>Principal components analysis (PCA) correlates with psychiatric diagnosis</h2>\n");
#endif

#ifdef SWEDISH
	file.Write("<h2>Principal components analys (PCA) korrelationer med psykiatriska diagnoser</h2>\n");
#endif

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");
        
	file.Write("<tr style='height:24.75pt'>");

    WriteCenteredFieldHeader(file, 25);
	file.Write("Condition");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 10);
	file.Write("Quiz");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("Quiz scoring (PCA Aspie - PCA NT)");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("Aspie loading");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("NT loading");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("g loading");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("Introvert loading");
    WriteFieldFooter(file);

	file.Write("</tr>");

	WritePcaCorrRow(file, "Diagnosed AS", POP_TYPE_AS);
	WritePcaCorrRow(file, "Aspie", POP_TYPE_ASPIE);
	WritePcaCorrRow(file, "ADD/ADHD", POP_TYPE_ADD);
	WritePcaCorrRow(file, "Tourette", POP_TYPE_TS);
	WritePcaCorrRow(file, "Hyperlexia", POP_TYPE_HYPERLEXIA);
	WritePcaCorrRow(file, "Dyspraxia", POP_TYPE_DYSPRAXIA);
	WritePcaCorrRow(file, "Dyslexia", POP_TYPE_DYSLEXIA);
	WritePcaCorrRow(file, "Dyscalculia", POP_TYPE_DYSCALCULIA);
	WritePcaCorrRow(file, "OCD", POP_TYPE_OCD);
	WritePcaCorrRow(file, "ODD", POP_TYPE_ODD);
	WritePcaCorrRow(file, "Synaesthesia", POP_TYPE_SYNAESTHESIA);
	WritePcaCorrRow(file, "Prosapagnosia", POP_TYPE_PA);
	WritePcaCorrRow(file, "Dysgraphia", POP_TYPE_DYSGRAPHIA);
	WritePcaCorrRow(file, "Bipolar", POP_TYPE_BIPOLAR);
	WritePcaCorrRow(file, "Schizophrenia", POP_TYPE_SCHIZOPHRENIA);
	WritePcaCorrRow(file, "Social phobia", POP_TYPE_SOCIAL_PHOBIA);
	WritePcaCorrRow(file, "NT control", POP_TYPE_NT);
	WritePcaCorrRow(file, "Low IQ", POP_TYPE_LOW_IQ);
	WritePcaCorrRow(file, "High IQ", POP_TYPE_HIGH_IQ);

	file.Write("</table>");
}

/*##################  TQuiz::WriteGroupTable ##########################
*   Purpose....: Write group - group correlation table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteGroupTable(const char *filename, int Cross)
{
    int g1;
	int g2;
    long double corrval;
    int count;
	char str[80];
	int insertcr;
	int cross;
	TFile file(filename, 0);

    file.Write("<table border=3 cellspacing=0 cellpadding=0>");
        
	file.Write("<tr style='height:24.75pt'>");

    WriteCenteredFieldHeader(file, 3);
	file.Write("#");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 25);
	file.Write("Group");
    WriteFieldFooter(file);

	for (g2 = 0; g2 < GROUP_COUNT - 1; g2++)
    {
        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "G:%d", g2 + 1);
    	file.Write(str);
        WriteFieldFooter(file);
    }

	file.Write("</tr>");

    for (g1 = 0; g1 < GROUP_COUNT - 1; g1++)
    {
		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 3);
        sprintf(str, "G:%d", g1 + 1);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 25);
		file.Write(Group[g1].PosName);
        WriteFieldFooter(file);

        for (g2 = 0; g2 < GROUP_COUNT - 1; g2++)
        {
            WriteCenteredFieldHeader(file, 5);

            insertcr = FALSE;
            
            for (cross = 0; cross < MAX_CROSS && Cross; cross++)
            {
                if (CrossQuiz[cross])
                {
                    if (insertcr)
                        file.Write("<br>");
                    insertcr = TRUE;
					corrval = CrossQuiz[cross]->GroupCorr[g1][g2].Corr;
					count = CrossQuiz[cross]->GroupCorr[g1][g2].Count;
					WriteCorrVal(file, corrval, count);
				}
			}

			if (insertcr)
				file.Write("<br>");

			corrval = GroupCorr[g1][g2].Corr;
			count = GroupCorr[g1][g2].Count;
			WriteCorrVal(file, corrval, count);

            WriteFieldFooter(file);
	    }
	}
}

/*##################  TQuiz::WritePca ##########################
*   Purpose....: Write PCA loadings      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePca(const char *filename)
{
	int i;
	char str[80];
	int ival;
	int p;
	TFile file(filename, 0);

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	for (i = 0; i < N; i++)
	{
		if (i % 10 == 0)
		{
			file.Write("<tr style='height:24.75pt'>");

        	WriteCenteredFieldHeader(file, 5);
			file.Write("#");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 55);
			file.Write(" ");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 5);
			file.Write("AS-NT corr");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 5);
			file.Write("Total PCA #1/#2");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 5);
			file.Write("Young PCA #1/#2");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 5);
			file.Write("Old PCA #1/#2");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 5);
			file.Write("AS PCA #1/#2");
        	WriteFieldFooter(file);

			file.Write("</tr>");
		}

		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 5);
		sprintf(str, "%d", i + 1);
		file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 65);
		file.Write(Quiz[i].Text);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        WriteAsCI95(file, i);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        ival = round(100.0 * Quiz[i].Pca[0]);
		sprintf(str, "%d%", ival);
		file.Write(str);
		file.Write("<br>");
		
        ival = round(100.0 * Quiz[i].Pca[1]);
		sprintf(str, "%d%", ival);
		file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        ival = round(100.0 * Quiz[i].YoungPca[0]);
		sprintf(str, "%d%", ival);
		file.Write(str);
		file.Write("<br>");

		ival = round(100.0 * Quiz[i].YoungPca[1]);
		sprintf(str, "%d%", ival);
		file.Write(str);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 5);
		ival = round(100.0 * Quiz[i].OldPca[0]);
		sprintf(str, "%d%", ival);
		file.Write(str);
		file.Write("<br>");

		ival = round(100.0 * Quiz[i].OldPca[1]);
		sprintf(str, "%d%", ival);
		file.Write(str);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 5);
		if (Quiz[i].MyGroup == GROUP_MIXED)
			ival = round(100.0 * Quiz[i].MixedPca[0]);
		else
			ival = round(100.0 * Quiz[i].AsPca[0]);
		sprintf(str, "%d%", ival);
		file.Write(str);
		file.Write("<br>");

		if (Quiz[i].MyGroup == GROUP_MIXED)
			ival = round(100.0 * Quiz[i].MixedPca[1]);
		else
			ival = round(100.0 * Quiz[i].AsPca[1]);
		sprintf(str, "%d%", ival);
		file.Write(str);
		WriteFieldFooter(file);

		file.Write("</tr>");
	}

	file.Write("</table>");
}

/*##################  TQuiz::WriteWeighting ##########################
*   Purpose....: Write weighting        	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteWeighting(const char *filename)
{
	int i;
	int j;
	int k;
	char str[80];
	int ival;
	long double val;
	long double Asw[MAX_QUESTIONS];
	long double Ntw[MAX_QUESTIONS];
	long double Asg[MAX_QUESTIONS];
	long double Ntg[MAX_QUESTIONS];
    int count;
    long double assum;
    long double ntsum;
    long double mas0, mas1, fas0, fas1;
    long double oas0, oas1, yas0, yas1;
    TQuiz *CurrQuiz;
	TFile file(filename, 0);

    for (i = 0; i < N; i++)
	{
	    if (All.Count[i] > 100)
	    {
    		assum = Quiz[i].Pca[0];
	    	ntsum = Quiz[i].Pca[1];
		    count = 1;
		}
		else
		{
		    assum = 0;
		    ntsum = 0;
		    count = 0;
		}

        j = Quiz[i].CrossInd;
        CurrQuiz = Quiz[i].CrossQuiz;

        while (CurrQuiz)
        {
            if (CurrQuiz->GetPcaCount() > 1)
            {
    			assum += CurrQuiz->Quiz[j].Pca[0];
	    		ntsum += CurrQuiz->Quiz[j].Pca[1];
		    	count++;
		    }

			k = CurrQuiz->Quiz[j].CrossInd;
			CurrQuiz = CurrQuiz->Quiz[j].CrossQuiz;
            j = k;
        }

        if (count)
        {
            Asw[i] = assum / (long double)count;
            Ntw[i] = ntsum / (long double)count;        
        }
        else
        {
            Asw[i] = 0;
            Ntw[i] = 0;
        }
    }

    sprintf(str, "    static int Asw[%d] = {", N);
    file.Write(str);
    
	for (i = 0; i < N; i++)
	{
        if ((i % 10) == 0)
    	    file.Write("\r\n          ");
    	        
		ival = round(100.0 * Asw[i]);
		sprintf(str, "%5d", ival);
		file.Write(str);

	    if (i != N - 1)
    	    file.Write(",");		
	}
	file.Write("};\r\n\r\n");

    sprintf(str, "    static int Ntw[%d] = {", N);
    file.Write(str);
    
	for (i = 0; i < N; i++)
	{
        if ((i % 10) == 0)
    	    file.Write("\r\n          ");
    	        
		ival = round(100.0 * Ntw[i]);
		sprintf(str, "%5d", ival);
		file.Write(str);

	    if (i != N - 1)
    	    file.Write(",");		
	}
	file.Write("};\r\n\r\n");

}

/*##################  TQuiz::WritePhpWeighting ##########################
*   Purpose....: Write weighting  for PHP       	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePhpWeighting(const char *filename)
{
	int i;
	int j;
	int k;
	char str[80];
	int ival;
	long double val;
	long double Asw[MAX_QUESTIONS];
	long double Ntw[MAX_QUESTIONS];
	long double Asg[MAX_QUESTIONS];
	long double Ntg[MAX_QUESTIONS];
    int count;
    long double assum;
    long double ntsum;
    long double mas0, mas1, fas0, fas1;
    long double oas0, oas1, yas0, yas1;
    TQuiz *CurrQuiz;
	TFile file(filename, 0);

    for (i = 0; i < N; i++)
	{
	    if (All.Count[i] > 100)
	    {
    		assum = Quiz[i].Pca[0];
	    	ntsum = Quiz[i].Pca[1];
		    count = 1;
		}
		else
		{
		    assum = 0;
		    ntsum = 0;
		    count = 0;
		}

        j = Quiz[i].CrossInd;
        CurrQuiz = Quiz[i].CrossQuiz;

        while (CurrQuiz)
        {
            if (CurrQuiz->GetPcaCount() > 1)
            {
    			assum += CurrQuiz->Quiz[j].Pca[0];
	    		ntsum += CurrQuiz->Quiz[j].Pca[1];
		    	count++;
		    }

			k = CurrQuiz->Quiz[j].CrossInd;
			CurrQuiz = CurrQuiz->Quiz[j].CrossQuiz;
            j = k;
        }

        if (count)
        {
            Asw[i] = assum / (long double)count;
            Ntw[i] = ntsum / (long double)count;        
        }
        else
        {
            Asw[i] = 0;
            Ntw[i] = 0;
        }
    }

    file.Write("function GetAsWeights()\r\n");
    file.Write("{\r\n");

	for (i = 0; i < N; i++)
	{
		ival = round(100.0 * Asw[i]);
		sprintf(str, "  $aw[%d] = %d;\r\n", i, ival);
		file.Write(str);
	}
	file.Write("\r\n");
	file.Write("  return $aw;\r\n");
	file.Write("\r\n");

    file.Write("function GetNtWeights()\r\n");
    file.Write("{\r\n");
    
	for (i = 0; i < N; i++)
	{
		ival = round(100.0 * Ntw[i]);
		sprintf(str, "  $nw[%d] = %d;\r\n", i, ival);
		file.Write(str);
	}
	file.Write("\r\n");
	file.Write("  return $nw;\r\n");
	file.Write("\r\n");
}

/*##################  TQuiz::ExportHistogram ##########################
*   Purpose....: Export histogram for score distribution for population       	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::ExportHistogram(const char *filename, int PopType, int width, int All)
{
    char str[80];
    int val;
    int i;
    int j;
    int e;
    int cross;
    TQuiz *quiz;
    int count;
	int HistAsCount[200];
	int HistNtCount[200];
    int HistScore[200];
	TFile file(filename, 0);
	TPopulation *pop;

    pop = GetPop(PopType);
    if (pop == 0)
        return;

    count = pop->ValueCount;
        
    for (i = 0; i < 200; i++)
    {
        HistAsCount[i] = 0;
        HistNtCount[i] = 0;
        HistScore[i] = i * width;
    }

    for (e = 0; e < pop->ValueCount; e++)
    {
        i = pop->ValArr[e].AsScore / width;
        HistAsCount[i]++;

        i = pop->ValArr[e].NtScore / width;
        HistNtCount[i]++;        
	}

	if (All)
	{
	    for (cross = 0; cross < MAX_CROSS; cross++)
	    {
	        quiz = CrossQuiz[cross];
	        if (quiz)
	        {
                pop = quiz->GetPop(PopType);
                if (pop)
                {
    	            count += pop->ValueCount;
	            
                    for (e = 0; e < pop->ValueCount; e++)
                    {
                        i = pop->ValArr[e].AsScore / width;
                        HistAsCount[i]++;

                        i = pop->ValArr[e].NtScore / width;
                        HistNtCount[i]++;        
                	}
                }
	        }
	    }
	}

	for (i = 0; i < 200; i++)
	{
	    j = HistScore[i];
	    if (j < 200)
	    {
	        sprintf(str, "%d\t", j);
	        file.Write(str);

            val = HistAsCount[i] * 10000;
            val = val / width / count;
	        sprintf(str, "%d\t", val);
	        file.Write(str);

            val = HistNtCount[i] * 10000;
            val = val / width / count;
	        sprintf(str, "%d\n", val);
	        file.Write(str);	        
	    }
	}
}

/*##################  TQuiz::WritePhpGlobalQuestions ##########################
*   Purpose....: Write global question vector 					            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePhpGlobalQuestions(const char *filename)
{
	TFile file(filename, 0);
	int i;
	int cross;
	int q;
	TQuiz *quiz;
	int found;
	char str[128];
    int id;

    for (id = 0; id < MAX_GLOBAL_QUESTIONS; id++)
    {	
		  if (GlobalArr[id])
        {
            found = FALSE;

            for (cross = 0; cross < MAX_CROSS && !found; cross++)
            {
                quiz = CrossQuiz[cross];
                if (quiz)
                {
                    for (q = 0; q < quiz->N && !found; q++)
                    {
                        if (quiz->Quiz[q].GlobalId == id)
                        {
                            sprintf(str, " $m[%d] = \"", id);
                            file.Write(str);
                            file.Write(quiz->Quiz[q].Text);
                            file.Write("\";\n");                            
                            found = TRUE;
                        }
                    }
                }
            }

            if (!found)
            {            
                for (i = 0; i < N && !found; i++)
                {
                    if (Quiz[i].GlobalId == id)
                    {
                        sprintf(str, " $m[%d] = \"", id);
                        file.Write(str);
                        file.Write(Quiz[i].Text);
                        file.Write("\";\n");                            
                        found = TRUE;
                    }
                }
            }
        } 
    }
}

/*##################  TQuiz::WritePhpGroupWeighting ##########################
*   Purpose....: Write average group correlation in PHP-format for current quiz	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WritePhpGroupWeighting(const char *filename)
{
    long double gsum;
    int gcount;
    long double val;
    int count;
    int questions;
	int curr;
	int grp;
    TQuiz *quiz;
	 int q;
    int j;
	 int ival;
	 char str[80];
	TFile file(filename, 0);

    file.Write("function GetGroupWeights()\r\n");
    file.Write("{\r\n");

	for (q = 0; q < N; q++)
	{
    	sprintf(str, "  $gw[%d] = array(0 => ", q);
		file.Write(str);

		for (grp = 1; grp < GROUP_COUNT - 2; grp++)
		{
			gsum = 0.0;
			gcount = 0;

			quiz = this;
			curr = q;
			while (quiz)
			{
				val = quiz->Quiz[curr].Group[grp].Corr;
				count = quiz->Quiz[curr].Group[grp].Count;
				questions = quiz->Group[grp].Questions;

				if (count > 3)
				{
					gsum += val * questions;
					gcount += questions;
				}

                if (quiz->Quiz[curr].CrossQuiz)
                {
                    j = quiz->Quiz[curr].CrossInd;
                    quiz = quiz->Quiz[curr].CrossQuiz;
                    curr = j;
    			}
    			else
    			    quiz = 0;
			}

            if (gcount)
           		ival = round(100.0 * gsum / gcount);
            else
                ival = 0;

            if (Quiz[q].Reverse)
                ival = -ival;

			sprintf(str, "%d", ival);
	    	file.Write(str);

            if (grp != GROUP_COUNT - 3)
                file.Write(", ");            
			
		}
		file.Write(");\r\n");
	}
}

/*##################  TQuiz::WriteWiki ##########################
*   Purpose....: Write Wiki report      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteWiki(const char *filename, long double threshold, long double intercorr)
{
	long double CorrSum[MAX_GLOBAL_QUESTIONS];
	long double NoAnswerSum[MAX_GLOBAL_QUESTIONS];
	int CorrCount[MAX_GLOBAL_QUESTIONS];
	int CorrGroup[MAX_GLOBAL_QUESTIONS];
	TQuiz *CorrQuiz[MAX_GLOBAL_QUESTIONS];
	int CorrQuestion[MAX_GLOBAL_QUESTIONS];
	int Mark[MAX_GLOBAL_QUESTIONS];
	int Used[MAX_GLOBAL_QUESTIONS];
	int GlobalId;
	int i;
	int j;
	int g;
   int k;
	TQuiz *quiz;
	TQuiz *TopQuiz;
	int TopQuestion;
	int q;
	char str[80];
	int cnt;
   int count;
	int ival;
	int mark;
	long double sum;
	long double MaxCorr;
   long double CurrCorr;
    long double val;
	long double corrval;
	long double LowestCorr;
	TFile file(filename, 0);

	ClearUsed();

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	{
		CorrSum[i] = 0.0;
		NoAnswerSum[i] = 0.0;
		CorrCount[i] = 0;
	}    

	for (g = 0; g < GROUP_COUNT; g++)
	{
		TopQuiz = GetTopGroupCorr(g, &TopQuestion);

		while (TopQuiz)
		{
			quiz = TopQuiz;
			q = TopQuestion;

			for (;;)
			{
				quiz->Quiz[q].Used = TRUE;

				if (quiz->Quiz[q].CrossQuiz)
				{
					j = quiz->Quiz[q].CrossInd;
					quiz = quiz->Quiz[q].CrossQuiz;
					q = j;
				}
				else
				{
					GlobalId = quiz->Quiz[q].GlobalId;
					break;
				}
			}

			if (GlobalId > 0 && GlobalId < MAX_GLOBAL_QUESTIONS)
			{
				CorrQuiz[GlobalId] = TopQuiz;
				CorrQuestion[GlobalId] = TopQuestion;
				CorrGroup[GlobalId] = g;

            	mark = FALSE;

                for (i = 0; i < 153 && !mark; i++)
                {
                    quiz = this;
                    q = i;
                    while (quiz && !mark)
                    {
                        if (quiz->Quiz[q].CrossQuiz)
                        {
                            j = quiz->Quiz[q].CrossInd;
		        	        quiz = quiz->Quiz[q].CrossQuiz;
            	        	q = j;
                    	}
                        else
                        {
                            if (quiz->Quiz[q].GlobalId == GlobalId)
                                mark = TRUE;

                            quiz = 0;
                        }
                    }
                }

                Mark[GlobalId] = mark;                                

				quiz = TopQuiz;
				q = TopQuestion;

				while (quiz)
				{
					CorrSum[GlobalId] += quiz->Quiz[q].Corr;
                    NoAnswerSum[GlobalId] += (long double)quiz->Quiz[i].NoAnswer / (long double)quiz->All.ValueCount;
					CorrCount[GlobalId]++;

					j = quiz->Quiz[q].CrossInd;
					quiz = quiz->Quiz[q].CrossQuiz;
					q = j;
				}
			}

			TopQuiz = GetTopGroupCorr(g, &TopQuestion);
		}
	}


	for (g = 0; g < GROUP_COUNT; g++)
	{
    	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
            Used[i] = FALSE;
	    
	    file.Write("== ");
		file.Write(Group[g].PosName);
		file.Write(" / ");
		file.Write(Group[g].NegName);
		file.Write(" ==\r\n\r\n");
        
		GlobalId = 0;

		while (GlobalId >= 0)
		{
			LowestCorr = -0.1;
			GlobalId = -1;

			for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
			{
				if (CorrCount[i] && CorrGroup[i] == g && !Used[i])
				{
					corrval = CorrSum[i] / CorrCount[i];
					corrval = corrval * corrval;
					if (corrval > LowestCorr)
					{
						GlobalId = i;
						LowestCorr = corrval;
					}
				}
			}

			if (GlobalId >= 0)
			{
				val = CorrSum[GlobalId] / CorrCount[GlobalId];
                if (val * val > threshold * threshold)
                {

    				TopQuiz = CorrQuiz[GlobalId];
	    			TopQuestion = CorrQuestion[GlobalId];

    				file.Write("* ");

	    			if (Mark[GlobalId])
		    		    file.Write("'''");

    				sprintf(str, "%d. ", GlobalId + 1);
	    			file.Write(str);
		    		file.Write(TopQuiz->Quiz[TopQuestion].Text);
			    	file.Write(" (");

    				val = CorrSum[GlobalId] / CorrCount[GlobalId];
                    Used[GlobalId] = TRUE;
    			
		    		ival = round(100.0 * val);
			    	if (ival < 0)
				    {
    					file.Write("-");
	    				ival = -ival;
		    		}

    				sprintf(str, ".%02d, ", ival);
	    			file.Write(str);

                    ival = round(100.0 * NoAnswerSum[GlobalId] / CorrCount[GlobalId]);
                	sprintf(str, "%d%)", ival);
            	    file.Write(str);

   	    			if (Mark[GlobalId])
		    		    file.Write("'''");

            		file.Write("\r\n");

                	MaxCorr = 1.0;

                	for (j = 0; j < 10; j++)
                	{
                    	CurrCorr = intercorr * intercorr;

                    	q = -1;
    	
                	    for (k = 0; k < MAX_GLOBAL_QUESTIONS; k++)
                	    {
                        	cnt = GlobalCorrCount[GlobalId][k];

                        	if (cnt > 1)
            	                corrval = GlobalCorrArr[GlobalId][k] / ((long double)cnt - 1);
                            else
                                corrval = 0.0;

                    	    corrval = corrval * corrval;
            	    
                        	if (corrval > CurrCorr && corrval < MaxCorr)
                        	{
                        	    CurrCorr = corrval;
                        	    q = k;
                        	}
                    	}

                        MaxCorr = CurrCorr;
            
        	            if (q >= 0)
                    	{
						    TopQuiz = CorrQuiz[q];
					        TopQuestion = CorrQuestion[q];
                
						    file.Write(":");

        	    			if (Mark[q])
		            		    file.Write("'''");

        					sprintf(str, "%d. ", q + 1);
		        			file.Write(str);
				        	file.Write(TopQuiz->Quiz[TopQuestion].Text);
                    	    file.Write(" (");

        					val = CorrSum[q] / CorrCount[q];
            		        ival = round(100.0 * val);
        	                if (ival < 0)
            	            {
                        		file.Write("-");
            	            	ival = -ival;
        		            }

                        	sprintf(str, ".%02d, ", ival);
	                        file.Write(str);
            
                            ival = round(100.0 * NoAnswerSum[q] / CorrCount[q]);
                   	        sprintf(str, "%d%), intercorr: ", ival);
                     	    file.Write(str);

                        	cnt = GlobalCorrCount[GlobalId][q];

                        	if (cnt > 1)
            	                val = GlobalCorrArr[GlobalId][q] / ((long double)cnt - 1);
                            else
                                val = 0.0;

                    		ival = round(100.0 * val);

    	                    sprintf(str, ".%02d", ival);
                    	    file.Write(str);

        	    			if (Mark[q])
		            		    file.Write("'''");

        	                file.Write("\r\n");
                    	}
                	}

    				file.Write("\r\n\r\n");
    			}
    			else
    			    GlobalId = -1;
            }				
		}
	}

}

/*##################  TQuiz::WriteQuizWiki ##########################
*   Purpose....: Write Wiki report for current quiz      	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteQuizWiki(const char *filename)
{
	long double sum;
	int count;
	int GlobalId;
	int i;
	int j;
	int k;
	int g;
	TQuiz *quiz;
	TQuiz *TopQuiz;
	int TopQuestion;
	int q;
	int gid1;
	int gid2;
	int cnt;
	char str[80];
	int ival;
	int mark;
    long double val;
    long double corrlev;
	long double corrval;
	long double CurrCorr;
	long double MaxCorr;
	long double CorrArr[MAX_QUESTIONS];
	int GlobalIdArr[MAX_QUESTIONS];
	TFile file(filename, 0);

	for (i = 0; i < N; i++)
	{
        quiz = this;
        q = i;
        while (quiz)
        {
		    GlobalIdArr[i] = quiz->Quiz[q].GlobalId;

            j = quiz->Quiz[q].CrossInd;
			quiz = quiz->Quiz[q].CrossQuiz;
            q = j;
		}
	}

	for (i = 0; i < N; i++)
	{
	    sum = 0;
	    count = 0;
	    
        quiz = this;
        q = i;
        while (quiz)
        {
	        sum += quiz->Quiz[q].Corr;
		    count++;

            j = quiz->Quiz[q].CrossInd;
			quiz = quiz->Quiz[q].CrossQuiz;
            q = j;
		}

        file.Write("* ");
		file.Write("'''");

    	sprintf(str, "%d. ", GlobalIdArr[i] + 1);
	    file.Write(str);
		file.Write(Quiz[i].Text);
	    file.Write(" (");

    	val = sum / count;
		ival = round(100.0 * val);
	    if (ival < 0)
	    {
    		file.Write("-");
	    	ival = -ival;
		}

	    corrlev = 0.9 * val;

    	sprintf(str, ".%02d, ", ival);
	    file.Write(str);

        ival = round(100.0 * Quiz[i].NoAnswer / All.ValueCount);
    	sprintf(str, "%d%)", ival);
	    file.Write(str);


		file.Write("'''");

		file.Write("\r\n");

		gid1 = GlobalIdArr[i];

		for (k = 0; k < N; k++)
		{
		    gid2 = GlobalIdArr[k];
		    
        	cnt = GlobalCorrCount[gid1][gid2];

        	if (cnt > 1)
            	CorrArr[k] = GlobalCorrArr[gid1][gid2] / ((long double)cnt - 1);
            else
                CorrArr[k] = 0.0;

		}

    	MaxCorr = 1.0;

    	for (j = 0; j < 10; j++)
    	{
        	CurrCorr = corrlev * corrlev;

        	q = -1;
    	
    	    for (k = 0; k < N; k++)
    	    {
        	    corrval = CorrArr[k];
        	    corrval = corrval * corrval;
            	    
            	if (corrval > CurrCorr && corrval < MaxCorr)
            	{
            	    CurrCorr = corrval;
            	    q = k;
            	}
        	}

            MaxCorr = CurrCorr;
            
        	if (q >= 0)
        	{
        	    k = q;

        	    sum = 0;
	            count = 0;
	            
                quiz = this;
                while (quiz)
                {
        	        sum += quiz->Quiz[q].Corr;
		            count++;

                    j = quiz->Quiz[q].CrossInd;
		        	quiz = quiz->Quiz[q].CrossQuiz;
                    q = j;
                }

                q = k;
                
        	    file.Write(":");
            	sprintf(str, "%d. ", GlobalIdArr[q] + 1);
	            file.Write(str);
        		file.Write(Quiz[q].Text);
        	    file.Write(" (");

            	val = sum / count;
		        ival = round(100.0 * val);
        	    if (ival < 0)
	            {
            		file.Write("-");
	            	ival = -ival;
        		}

            	sprintf(str, ".%02d), intercorr: ", ival);
	            file.Write(str);

                val = CorrArr[q];
        		ival = round(100.0 * val);

    	        sprintf(str, ".%02d", ival);
        	    file.Write(str);
        	    file.Write("\r\n");
        	}
    	}
    
    	file.Write("\r\n\r\n");
	}
}

/*##################  TQuiz::WriteGlobalCorrelation ##########################
*   Purpose....: Write N largest inter-question correlations     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteGlobalCorrelation(const char *filename, int count)
{
    int i;
    int gid1, gid2;
    int maxgid1, maxgid2;
    int cnt;
    int ival;
    long double corr;
    long double MaxCorr;
    long double CorrLev;
    char str[120];
	TFile file(filename, 0);

	CorrLev = 1.0;

	for (i = 0; i < count; i++)
	{
    	MaxCorr = 0.0;

    	for (gid1 = 0; gid1 < MAX_GLOBAL_QUESTIONS; gid1++)
    	{
        	for (gid2 = 0; gid2 < gid1; gid2++)
        	{
        	    cnt = GlobalCorrCount[gid1][gid2];

        	    if (cnt > 1)
        	    {
            	    corr = GlobalCorrArr[gid1][gid2] / ((long double)cnt - 1);
            	    corr = corr * corr;
            	    
            	    if (corr > MaxCorr && corr < CorrLev)
            	    {
            	        MaxCorr = corr;
            	        maxgid1 = gid1;
            	        maxgid2 = gid2;
            	    }
            	}
        	}
        }

        CorrLev = MaxCorr;

        sprintf(str, "Question %d \"", maxgid1 + 1);
        file.Write(str);
        file.Write(GetGlobalQuestionText(maxgid1));
        file.Write("\", ");

        sprintf(str, "Question %d \"", maxgid2 + 1);
        file.Write(str);
        file.Write(GetGlobalQuestionText(maxgid2));

        file.Write(" (");
        cnt = GlobalCorrCount[maxgid1][maxgid2];
        corr = GlobalCorrArr[maxgid1][maxgid2] / ((long double)cnt - 1);

		ival = round(100.0 * corr);
	    if (ival < 0)
	    {
    		file.Write("-");
	    	ival = -ival;
		}

    	sprintf(str, ".%02d)", ival);
	    file.Write(str);
        file.Write("<br>");
    }
}

/*##################  TQuiz::PrintGlobalCorrelation ##########################
*   Purpose....: Print global correlation between two questions   	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::PrintGlobalCorrelation(int q1, int q2)
{
    int cnt;
    long double corr;
    int ival;
    
    cnt = GlobalCorrCount[q1-1][q2-1];
    corr = GlobalCorrArr[q1-1][q2-1] / ((long double)cnt - 1);

	ival = round(100.0 * corr);
	if (ival < 0)
		 ival = -ival;
	 printf("Question %d and Question %d, correlation: .%02d\r\n", q1, q2, ival);
}

/*##################  TQuiz::WriteWikiCorrelation ##########################
*   Purpose....: Write N largest inter-question correlations from wiki-set  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteWikiCorrelation(const char *wiki, const char *filename, int count)
{
    int i;
    int gid1, gid2;
    int maxgid1, maxgid2;
    int cnt;
    int ival;
    long double corr;
    long double MaxCorr;
    long double CorrLev;
    long double val;
    long double val1;
    long double val2;
    char str[120];
	TFile file(filename, 0);
	int found;
	int q;
	int cross;
	long double sum;
	int j;
   int k;
   TQuiz *quiz;
	int Arr[MAX_GLOBAL_QUESTIONS];
	long double CorrArr[MAX_GLOBAL_QUESTIONS];
	char buf[4096];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	TFile infile(wiki);

    for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
    {
        found = FALSE;        
        quiz = 0;
        
        for (q = 0; q < N && !found; q++)
        {
            if (Quiz[q].GlobalId == i)
            {
                quiz = this;
                found = TRUE;
            }
        }

        for (cross = MAX_CROSS - 1; cross >= 0 && !found; cross--)
        {
            quiz = CrossQuiz[cross];
            if (quiz)
            {
			    for (q = 0; q < quiz->N && !found; q++)
                {
                    if (quiz->Quiz[q].GlobalId == i)
                    {
                        found = TRUE;
                        break;
                    }
                }
            }
        }

        if (quiz)
        {
    	    sum = 0;
	        cnt = 0;
	    
            j = q;
            while (quiz)
            {
	            sum += quiz->Quiz[j].Corr;
    		    cnt++;

                k = quiz->Quiz[j].CrossInd;
			    quiz = quiz->Quiz[j].CrossQuiz;
                j = k;
    		}

            corr = sum / cnt;
            corr = corr * corr;

            CorrArr[i] = corr;
        }
        else
            CorrArr[i] = 0.0;
    }

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	    Arr[i] = FALSE;

	while (size = infile.Read(buf, 4096))
	{
		buf[size] = 0;
		rowstr = strchr(buf, '*');
		if (rowstr)
		{
            ptr = strchr(rowstr, 0xd);
            if (ptr)
                *ptr = 0;

            ptr = strstr(rowstr, "'''");
            if (ptr)
            {
                ptr += 3;
                i = atoi(ptr);
                if (i)
                    Arr[i - 1] = TRUE;
                   
            }           
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);
	}

	CorrLev = 1000.0;

	for (i = 0; i < count; i++)
	{
    	MaxCorr = 0.0;

    	for (gid1 = 0; gid1 < MAX_GLOBAL_QUESTIONS; gid1++)
    	{
    	    if (Arr[gid1])
    	    {
            	for (gid2 = 0; gid2 < gid1; gid2++)
            	{
            	    if (Arr[gid2])
            	    {
                	    cnt = GlobalCorrCount[gid1][gid2];

                	    if (cnt > 1)
        	            {
                            val1 = CorrArr[gid1] * CorrArr[gid1];
                            val2 = CorrArr[gid2] * CorrArr[gid2];

//                            val = sqrtl(val1 + val2);
        	            
            	            corr = GlobalCorrArr[gid1][gid2] / ((long double)cnt - 1);
                    	    corr = corr * corr;

                    	    val = 1.0;
                    	    
                    	    if (corr > val1 || corr > val2)
                    	    {
                    	        
                    	        if (val1 > val2)
                    	            corr = corr - val2;
                    	        else
                    	            corr = corr - val1;
                    	    }
                    	    else
                    	        corr = 0.0;

                    	    if (val)
                        	    corr = corr / val;
                        	else
                        	    corr = 0.0;
            	    
                        	if (corr > MaxCorr && corr < CorrLev)
                	        {
                        	    MaxCorr = corr;
                        	    maxgid1 = gid1;
            	                maxgid2 = gid2;
                        	}
                    	}
                	}
                }
            }
        }

        CorrLev = MaxCorr;

        sprintf(str, "Question %d \"", maxgid1 + 1);
        file.Write(str);
        file.Write(GetGlobalQuestionText(maxgid1));
        file.Write("\" (");

		val = GlobalAsNtCorrSum[maxgid1] / GlobalAsNtCorrCount[maxgid1];
		ival = round(100.0 * val);
		if (ival < 0)
		{
			file.Write("-");
			ival = -ival;
		}

		sprintf(str, ".%02d), ", ival);
		file.Write(str);

        sprintf(str, "Question %d \"", maxgid2 + 1);
        file.Write(str);
        file.Write(GetGlobalQuestionText(maxgid2));
        file.Write("\" (");

		val = GlobalAsNtCorrSum[maxgid2] / GlobalAsNtCorrCount[maxgid2];
		ival = round(100.0 * val);
		if (ival < 0)
		{
			file.Write("-");
			ival = -ival;
		}

		sprintf(str, ".%02d), Corr: ", ival);
		file.Write(str);

        cnt = GlobalCorrCount[maxgid1][maxgid2];
        corr = GlobalCorrArr[maxgid1][maxgid2] / ((long double)cnt - 1);

//        val = CorrArr[maxgid1] + CorrArr[maxgid2];
        	            
//        corr = corr * corr;
//        corr = corr / val;

		ival = round(100.0 * corr);

    	if (ival < 0)
    	{
    	    ival = -ival;
    	    file.Write("-");
    	}
    	
    	sprintf(str, "%d", ival);
	    file.Write(str);
        file.Write("<br>");
    }
}

/*##################  TQuiz::WriteWikiNoncorrelated ##########################
*   Purpose....: Write N lowest inter-question correlations from wiki-set  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteWikiNoncorrelated(const char *wiki, const char *filename, int count)
{
	int i;
	int j;
    int k;
	int cnt;
	long double corr;
	long double MaxCorr;
	long double CorrLev;
	int MaxInd;
    int ival;
    long double sum;
    char str[120];
	TFile file(filename, 0);
	int Selected[MAX_GLOBAL_QUESTIONS];
	int Present[MAX_GLOBAL_QUESTIONS];
	long double CorrArr[MAX_GLOBAL_QUESTIONS];
	char buf[4096];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	TFile infile(wiki);
	int cross;
	int q;
	TQuiz *quiz;
	int found;

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	{
	    if (GlobalAsNtCorrCount[i])
            corr = GlobalAsNtCorrSum[i] / GlobalAsNtCorrCount[i];
        else
            corr = 0.0;
            
        corr = corr * corr;

        if (corr > 0.16)
            Present[i] = TRUE;
        else
            Present[i] = FALSE;

	    Selected[i] = FALSE;
    }

	while (size = infile.Read(buf, 4096))
	{
		buf[size] = 0;
		rowstr = strchr(buf, '*');
		if (rowstr)
		{
            ptr = strchr(rowstr, 0xd);
            if (ptr)
				*ptr = 0;

            ptr = strstr(rowstr, "'''");
            if (ptr)
            {
                ptr += 3;
                i = atoi(ptr);
                if (i)
                {
                    Present[i - 1] = FALSE;
                    Selected[i - 1] = TRUE;
                }
                   
            }
            else
            {
                rowstr++;
                i = atoi(rowstr);
                if (i)
                    Present[i - 1] = TRUE;
            }
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);
	}

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	{
		if (Selected[i])
			CorrArr[i] = 1.0;

		if (Present[i])
		{
			MaxCorr = 0.0;

			for (j = 0; j < MAX_GLOBAL_QUESTIONS; j++)
			{
				if (Selected[j])
				{
					cnt = GlobalCorrCount[i][j];

					if (cnt > 1)
					{
						corr = GlobalCorrArr[i][j] / ((long double)cnt - 1);
						corr = corr * corr;

						if (corr > MaxCorr)
							MaxCorr = corr;
					}
				}
			}

			CorrArr[i] = MaxCorr;
		}
	}

    for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
    {
        if (Present[i])
        {
            found = FALSE;        
            quiz = 0;
        
            for (q = 0; q < N && !found; q++)
            {
                if (Quiz[q].GlobalId == i)
                {
                    quiz = this;
                    found = TRUE;
                }
            }

            for (cross = MAX_CROSS - 1; cross >= 0 && !found; cross--)
            {
                quiz = CrossQuiz[cross];
                if (quiz)
                {
			        for (q = 0; q < quiz->N && !found; q++)
                    {
                        if (quiz->Quiz[q].GlobalId == i)
                        {
                            found = TRUE;
                            break;
                        }
                    }
                }
            }

            if (quiz)
            {
    	        sum = 0;
	            cnt = 0;
	    
                j = q;
                while (quiz)
                {
    	            sum += quiz->Quiz[j].Corr;
        		    cnt++;
    
                    k = quiz->Quiz[j].CrossInd;
		    	    quiz = quiz->Quiz[j].CrossQuiz;
                    j = k;
        		}

                corr = sum / cnt;
                corr = corr * corr;

                CorrArr[i] = corr / CorrArr[i];
            }
            else
                CorrArr[i] = 0.0;
        }
        else
            CorrArr[i] = 0.0;
    }

	CorrLev = 1000000.0;

	for (i = 0; i < count; i++)
	{
		MaxCorr = 0.0;

		for (j = 0; j < MAX_GLOBAL_QUESTIONS; j++)
		{
			if (Present[j])
			{
				corr = CorrArr[j];

				if (corr > MaxCorr && corr < CorrLev)
				{
					MaxCorr = CorrArr[j];
					MaxInd = j;
				}
			}
		}

		CorrLev = MaxCorr;

		sprintf(str, "Question %d \"", MaxInd + 1);
		file.Write(str);
        file.Write(GetGlobalQuestionText(MaxInd));
        file.Write("\", ");

        file.Write(" (");
        corr = GlobalAsNtCorrSum[MaxInd] / GlobalAsNtCorrCount[MaxInd];

		ival = round(100.0 * corr);

		if (ival < 0)
		{
		    file.Write("-");
			ival = -ival;
		}

    	sprintf(str, ".%02d)", ival);
	    file.Write(str);
        file.Write("<br>");
    }
}

/*##################  TQuiz::MoveWiki ##########################
*   Purpose....: Move used-questions only to a full wiki                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::MoveWiki(const char *fromwiki, const char *towiki, long double threshold)
{
    int i;
    char str[120];
	int Use[MAX_GLOBAL_QUESTIONS];
	char buf[4096];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	TFile fromfile(fromwiki);
	long double CorrSum[MAX_GLOBAL_QUESTIONS];
	int CorrCount[MAX_GLOBAL_QUESTIONS];
	TQuiz *CorrQuiz[MAX_GLOBAL_QUESTIONS];
	int CorrQuestion[MAX_GLOBAL_QUESTIONS];
	int GlobalId;
	int j;
	int g;
	TQuiz *quiz;
	TQuiz *TopQuiz;
	int TopQuestion;
	int q;
	int ival;
    long double val;
	long double corrval;
	long double LowestCorr;
	TFile tofile(towiki, 0);

	for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
	    Use[i] = FALSE;

	while (size = fromfile.Read(buf, 4096))
	{
		buf[size] = 0;
		rowstr = strchr(buf, '*');
		if (rowstr)
		{
            ptr = strchr(rowstr, 0xd);
            if (ptr)
                *ptr = 0;

            ptr = strstr(rowstr, "'''");
            if (ptr)
            {
                ptr += 3;
                i = atoi(ptr);
                if (i)
                    Use[i - 1] = TRUE;
                   
            }           
		}

		pos += strlen(buf) + 1;
		fromfile.SetPos(pos);
	}

	ClearUsed();

	for (g = 0; g < GROUP_COUNT; g++)
	{
		 tofile.Write("== ");
		tofile.Write(Group[g].PosName);
		tofile.Write(" / ");
		tofile.Write(Group[g].NegName);
		  tofile.Write(" ==\r\n\r\n");

		for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
		{
			CorrSum[i] = 0.0;
			CorrCount[i] = 0;
		}

		TopQuiz = GetTopGroupCorr(g, &TopQuestion);

		while (TopQuiz)
		{
			quiz = TopQuiz;
			q = TopQuestion;

			for (;;)
			{
				quiz->Quiz[q].Used = TRUE;

				if (quiz->Quiz[q].CrossQuiz)
				{
					j = quiz->Quiz[q].CrossInd;
					quiz = quiz->Quiz[q].CrossQuiz;
					q = j;
				}
				else
				{
					GlobalId = quiz->Quiz[q].GlobalId;
					break;
				}
			}

			if (GlobalId > 0 && GlobalId < MAX_GLOBAL_QUESTIONS)
			{
				CorrQuiz[GlobalId] = TopQuiz;
				CorrQuestion[GlobalId] = TopQuestion;

				quiz = TopQuiz;
				q = TopQuestion;

				while (quiz)
				{
					CorrSum[GlobalId] += quiz->Quiz[q].Corr;
					CorrCount[GlobalId]++;

					j = quiz->Quiz[q].CrossInd;
					quiz = quiz->Quiz[q].CrossQuiz;
					q = j;
				}
			}

			TopQuiz = GetTopGroupCorr(g, &TopQuestion);
		}

		GlobalId = -1;

		while (GlobalId)
		{
			LowestCorr = -0.1;
			GlobalId = 0;

			for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
			{
				if (CorrCount[i])
				{
					corrval = CorrSum[i] / CorrCount[i];
					corrval = corrval * corrval;
					if (corrval > LowestCorr)
					{
						GlobalId = i;
						LowestCorr = corrval;
					}
				}
			}

			if (GlobalId)
			{
				val = CorrSum[GlobalId] / CorrCount[GlobalId];
					 if (val * val > threshold * threshold)
					 {

					TopQuiz = CorrQuiz[GlobalId];
					TopQuestion = CorrQuestion[GlobalId];

					tofile.Write("* ");

					if (Use[GlobalId])
						 tofile.Write("'''");

					sprintf(str, "%d. ", GlobalId + 1);
					tofile.Write(str);
					tofile.Write(TopQuiz->Quiz[TopQuestion].Text);
					tofile.Write(" (");

					val = CorrSum[GlobalId] / CorrCount[GlobalId];
					CorrCount[GlobalId] = 0;
					ival = round(100.0 * val);
					if (ival < 0)
					 {
						tofile.Write("-");
						ival = -ival;
					}

					sprintf(str, ".%02d)", ival);
					tofile.Write(str);

					if (Use[GlobalId])
						 tofile.Write("'''");

					tofile.Write("\r\n\r\n");
				}
				else
					CorrCount[GlobalId] = 0;
				}
		}
	}

}

/*##################  TQuiz::WikiToQuiz ##########################
*   Purpose....: Convert Wiki to quiz                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WikiToQuiz(const char *wikifile, const char *quizfile)
{
    int i;
    char str[120];
	int Use[MAX_GLOBAL_QUESTIONS];
	char buf[4096];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int id;
	TFile fromfile(wikifile);
	TFile tofile(quizfile, 0);

    id = 1;
    
	while (size = fromfile.Read(buf, 4096))
	{
		buf[size] = 0;
		rowstr = strchr(buf, '*');
		if (rowstr)
		{
            ptr = strchr(rowstr, 0xd);
            if (ptr)
                *ptr = 0;

            ptr = strstr(rowstr, "'''");
            if (ptr)
            {
                ptr += 3;
                i = atoi(ptr);
                if (i)
                {
                    sprintf(str, "  DefineID(%d, %d);\r\n", id, i);
                    tofile.Write(str);
                    id++;
                }
            }           
		}

		pos += strlen(buf) + 1;
		fromfile.SetPos(pos);
	}
}
