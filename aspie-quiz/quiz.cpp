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

#define MAX_GLOBAL_QUESTIONS       1024

static int GlobalArr[MAX_GLOBAL_QUESTIONS];

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
		Group[g].Name = "NO NAME";

#ifdef ENGLISH

	Group[GROUP_ASPIE_BIOLOGY].Name = "Aspie biology";
	Group[GROUP_NT_BIOLOGY].Name = "NT biology";
	Group[GROUP_ASPIE_TALENT].Name = "Aspie ability";
	Group[GROUP_NT_TALENT].Name = "Aspie disability";
	Group[GROUP_ASPIE_SOCIAL].Name = "Aspie social";
	Group[GROUP_NT_SOCIAL].Name = "NT social";
	Group[GROUP_ASPIE_COMM].Name = "Stims";
	Group[GROUP_NONVERBAL].Name = "NT communication";
	Group[GROUP_SEX].Name = "Sexuality";
	Group[GROUP_REPETITION].Name = "Compulsions";
	Group[GROUP_MIXED].Name = "Mixed";

#endif

#ifdef SWEDISH

	Group[GROUP_ASPIE_BIOLOGY].Name = "Aspie biologi";
	Group[GROUP_NT_BIOLOGY].Name = "NT biologi";
	Group[GROUP_ASPIE_TALENT].Name = "Aspie talang";
	Group[GROUP_NT_TALENT].Name = "Aspie handikapp";
	Group[GROUP_ASPIE_SOCIAL].Name = "Aspie social";
	Group[GROUP_NT_SOCIAL].Name = "NT social";
	Group[GROUP_ASPIE_COMM].Name = "Stimming";
	Group[GROUP_NONVERBAL].Name = "NT Kommunikation";
	Group[GROUP_SEX].Name = "Sexualitet";
	Group[GROUP_REPETITION].Name = "Tvång";
	Group[GROUP_MIXED].Name = "Blandat";

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
                            sprintf(str, " $m[%d] = \"", i);
                            file.Write(str);
                            file.Write(quiz->Quiz[q].Text);
                            file.Write("\";\n");                            
                            found = TRUE;
                        }
                    }
                }
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

            case GROUP_ASPIE_TALENT:
                file.Write("GROUP_ASPIE_TALENT");
                break;

            case GROUP_NT_TALENT:
                file.Write("GROUP_NT_TALENT");
                break;

            case GROUP_ASPIE_SOCIAL:
                file.Write("GROUP_ASPIE_SOCIAL");
                break;

            case GROUP_NT_SOCIAL:
                file.Write("GROUP_NT_SOCIAL");
                break;

            case GROUP_ASPIE_COMM:
                file.Write("GROUP_ASPIE_COMM");
                break;

            case GROUP_NONVERBAL:
                file.Write("GROUP_NONVERBAL");
                break;

            case GROUP_REPETITION:
                file.Write("GROUP_REPETITION");
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
                            sprintf(str, "  Quiz[%d].Text = \"", i);
                            file.Write(str);
                            file.Write(quiz->Quiz[q].Text);
                            file.Write("\";\n");                            
                            found = TRUE;
                        }
                    }
                }
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
	int g1, g2;
	int count1;
	int sum1;
	int count2;
	int sum2;

	PopCorr.Correlate(&Aspie, &Nt);

	for (i = 0; i < N; i++)
	{
		Quiz[i].AsCount = Aspie.Count[i];
		Quiz[i].AsMean = Aspie.GetMean(i);
		Quiz[i].AsSd = Aspie.GetSd(i);
		Quiz[i].NtCount = Nt.Count[i];
		Quiz[i].NtMean = Nt.GetMean(i);
		Quiz[i].NtSd = Nt.GetSd(i);
	    Quiz[i].Chi2 = PopCorr.chi2[i];
		Quiz[i].Corr = PopCorr.corr[i];
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
					ival = 3 - ival;
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
							sum += 3 - ival;
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
			            ival = 3 - ival;
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
	    if (Group[g].Count && Group[g].Answers > 1)
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
			                ival = 3 - ival;
			            else
    			            ival--;

    			        Quiz[q].Group[g].Count++;

                        if (Quiz[q].MyGroup == g)
                        {
                            count--;
				    		sum -= ival;
                        }

                        if (count)
                        {
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
    int ival;
	char str[80];
    
    count = pop->Count[Question];

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
		if (val > 2.0 && mean < 2.0)
			val = 2.0;

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
	    		file.Write("Hn loading");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
        	    WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
	    		file.Write("Hs loading");
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
	    		file.Write("ADHD");
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
    		    ival = round(100.0 * Quiz[i].NoAnswer / All.Count[i]);
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
		    	WriteStaple(file, &AddMale, i);
		        WriteStaple(file, &MixMale, i);
		        WriteStaple(file, &NtMale, i);

    		    file.Write("<br>");

	    		WriteStaple(file, &AspieFemale, i);
				WriteStaple(file, &AsFemale, i);
		        WriteStaple(file, &AddFemale, i);
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
       			WriteCI95(file, &AddMale, i);
	    		file.Write("<br>");
		    	WriteCI95(file, &AddFemale, i);
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
    int ival;
	int count;
    char str[80];
            
	mean = Quiz[Question].AsMean;
	sd = Quiz[Question].AsSd;
	count = Quiz[Question].AsCount;

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
		if (val > 2.0)
			val = 2.0;

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
    int ival;
	int count;
    char str[80];
            
	mean = Quiz[Question].NtMean;
	sd = Quiz[Question].NtSd;
	count = Quiz[Question].NtCount;

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
		if (val > 2.0)
			val = 2.0;

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
    long double zij;
    long double za;
    long double low;
    long double high;
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

        WriteCenteredFieldHeader(file, 26);
		file.Write(Group[g].Name);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
        WriteFieldFooter(file);

		for (grp = 0; grp < GROUP_COUNT - 1; grp++)
        {
            WriteFieldHeader(file, 5);
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

			for (j = 0; j < GROUP_COUNT - 1; j++)
			{
				cross = 0;
				TopQuiz->ClearUsed(TopQuestion);
				WriteFieldHeader(file, 5);
				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				while (quiz)
				{
					val = quiz->Quiz[q].Group[j].Corr;
					corrval = val;
					count = quiz->Quiz[q].Group[j].Count;

					if (count > 3)
					{
						if (val < 0.0)
							val = -val;

						if (val == 1)
							zij = 1000;
						else
							zij = 0.5 * logl((1 + val) / (1 - val));

						za = 1.96 / sqrtl(count - 3);
						low = tanhl(zij - za);
						high = tanhl(zij + za);

						if (low <= 0.0 && high >= 0.0)
							file.Write("-----");
						else
						{
							if (val > NormCorr[cross])
								file.Write("<span style='color:#009999'>");

							if (corrval < 0.0)
								file.Write("<span style='color:#990099'>");

#ifdef USE_PERCENT
							ival = round(100.0 * low * low);
							sprintf(str, "%d", ival);
							file.Write(str);

							ival = round(100.0 * high * high);
							sprintf(str, "-%d%", ival);
							file.Write(str);
#else
                            if (low <= 0.0)
                            {
								file.Write("-");
                                low = -low;
                                high = -high;
                            }
                
                            ival = round(100 * low);
            		        sprintf(str, ".%02d", ival);
		                    file.Write(str);

                    		ival = round(100.0 * high);
	                    	sprintf(str, "-.%02d", ival);
            		        file.Write(str);
#endif

							if (val > NormCorr[cross] || corrval < 0.0)
								 file.Write("</span>");
						 }
					}
					else
						file.Write("     ");

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
    long double zij;
    long double za;
    long double low;
    long double high;
    long double corrval;
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
		file.Write(Group[g].Name);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("Hn loading");
        WriteFieldFooter(file);

        if (GetPcaCount() > 1)
        {
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("Hs loading");
            WriteFieldFooter(file);
		}

        if (GetPcaCount() > 2)
        {
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("G loading");
            WriteFieldFooter(file);
        }

        if (GetPcaCount() > 3)
        {
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("Introvert");
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
    long double CorrSum[MAX_GLOBAL_QUESTIONS];
    int CorrCount[MAX_GLOBAL_QUESTIONS];
    TQuiz *CorrQuiz[MAX_GLOBAL_QUESTIONS];
    int CorrQuestion[MAX_GLOBAL_QUESTIONS];
    long double GroupSum[GROUP_COUNT];
    int GroupCount[GROUP_COUNT];
    int GlobalId;
    int i;
	int j;
	int g;
	int grp;
    TQuiz *quiz;
    TQuiz *CurrQuiz;
    TQuiz *TopQuiz;
    int TopQuestion;
    int q;
	char str[80];
	long double NormCorr;
	int cross;
	int ival;
	int count;
	int questions;
	long double val;
	long double corrval;
    long double LowestCorr;
	TFile file(filename, 0);

	ClearUsed();

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

	for (g = 0; g < GROUP_COUNT; g++)
	{
		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
		{
			CorrSum[i] = 0.0;
			CorrCount[i] = 0;
		}

		file.Write("<tr style='height:24.75pt'>");

		WriteCenteredFieldHeader(file, 3);
		sprintf(str, "G:%d", g + 1);
		file.Write(str);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 26);
		file.Write(Group[g].Name);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
		WriteFieldFooter(file);

		for (grp = 0; grp < GROUP_COUNT - 1; grp++)
		{
			WriteFieldHeader(file, 5);
			sprintf(str, "G:%d", grp + 1);
			file.Write(str);
            WriteFieldFooter(file);
		}

		file.Write("</tr>");

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
				file.Write("<tr style='height:24.75pt'>");

				TopQuiz = CorrQuiz[GlobalId];
				TopQuestion = CorrQuestion[GlobalId];

				WriteCenteredFieldHeader(file, 3);
				sprintf(str, "%d", GlobalId + 1);
				file.Write(str);
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 26);
				if (TopQuiz->Quiz[TopQuestion].Reverse)
					file.Write("<span style='color:#990099'>");
				file.Write(TopQuiz->Quiz[TopQuestion].Text);
				if (TopQuiz->Quiz[TopQuestion].Reverse)
					file.Write("</span>");
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 6);

				val = CorrSum[GlobalId] / CorrCount[GlobalId];
				CorrCount[GlobalId] = 0;

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

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					GroupSum[j] = 0.0;
					GroupCount[j] = 0;

					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						val = quiz->Quiz[q].Group[j].Corr;
						corrval = val;
						count = quiz->Quiz[q].Group[j].Count;
						questions = quiz->Group[j].Questions;

						if (count > 3)
						{
							GroupSum[j] += val * questions;
							GroupCount[j] += questions;
						}

						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
				}

				NormCorr = 0.0;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GroupCount[j])
					{
						val = GroupSum[j] / GroupCount[j];
						if (val >= NormCorr)
							NormCorr = val;
					}
				}
				NormCorr = 0.9 * NormCorr;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					WriteCenteredFieldHeader(file, 5);

					if (GroupCount[j])
					{
						val = GroupSum[j] / GroupCount[j];
						CorrCount[GlobalId] = 0;

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
	long double CorrSum[MAX_GLOBAL_QUESTIONS];
	int CorrCount[MAX_GLOBAL_QUESTIONS];
	TQuiz *CorrQuiz[MAX_GLOBAL_QUESTIONS];
	int CorrQuestion[MAX_GLOBAL_QUESTIONS];
	long double PcaSum;
	int PcaCount;
	int GlobalId;
	int i;
	int j;
	int g;
	int grp;
	TQuiz *quiz;
	TQuiz *CurrQuiz;
	TQuiz *TopQuiz;
	int TopQuestion;
	int q;
	char str[80];
	long double NormCorr;
	int cross;
	int ival;
	int count;
	int questions;
	long double val;
	long double corrval;
	long double LowestCorr;
	TFile file(filename, 0);

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

	for (g = 0; g < GROUP_COUNT; g++)
	{
		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
		{
			CorrSum[i] = 0.0;
			CorrCount[i] = 0;
		}

		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 3);
		sprintf(str, "G:%d", g + 1);
		file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 26);
		file.Write(Group[g].Name);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("Hn loading");
        WriteFieldFooter(file);

        if (GetPcaCount() > 1)
        {
            WriteCenteredFieldHeader(file, 3);
			file.Write("Hs loading");
			WriteFieldFooter(file);
        }

        if (GetPcaCount() > 2)
		{
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("G loading");
            WriteFieldFooter(file);
		}

        if (GetPcaCount() > 3)
        {
            WriteCenteredFieldHeader(file, 3);
	    	file.Write("Introvert");
            WriteFieldFooter(file);
        }

		file.Write("</tr>");

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
    			file.Write("<tr style='height:24.75pt'>");
            
                TopQuiz = CorrQuiz[GlobalId];
				TopQuestion = CorrQuestion[GlobalId];

                WriteCenteredFieldHeader(file, 3);
        		sprintf(str, "%d", GlobalId + 1);
		        file.Write(str);
				WriteFieldFooter(file);
                
                WriteCenteredFieldHeader(file, 26);
	    		if (TopQuiz->Quiz[TopQuestion].Reverse)
					file.Write("<span style='color:#990099'>");
    			file.Write(TopQuiz->Quiz[TopQuestion].Text);
	    		if (TopQuiz->Quiz[TopQuestion].Reverse)
		    		file.Write("</span>");
		        WriteFieldFooter(file);
	    		
                WriteCenteredFieldHeader(file, 6);
                
				val = CorrSum[GlobalId] / CorrCount[GlobalId];
                CorrCount[GlobalId] = 0;

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

				PcaCount = 0;
				PcaSum = 0.0;

				cross = 0;
				TopQuiz->ClearUsed(TopQuestion);
				WriteCenteredFieldHeader(file, 6);
				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				while (quiz)
				{
					PcaSum += quiz->Quiz[q].Pca[0];
					PcaCount++;
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				}

				WritePca(file, PcaSum / PcaCount);
				WriteFieldFooter(file);

				PcaCount = 0;
				PcaSum = 0.0;
				WriteCenteredFieldHeader(file, 6);

				if (GetPcaCount() > 1)
				{
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 1)
						{
							PcaSum += quiz->Quiz[q].Pca[1];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
					if (PcaCount)
						WritePca(file, PcaSum / PcaCount);
				}
				WriteFieldFooter(file);

				PcaCount = 0;
				PcaSum = 0.0;
				WriteCenteredFieldHeader(file, 6);

				if (GetPcaCount() > 2)
				{
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 2)
						{
							PcaSum += quiz->Quiz[q].Pca[2];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
					if (PcaCount)
						WritePca(file, PcaSum / PcaCount);
				}
				WriteFieldFooter(file);

				PcaCount = 0;
				PcaSum = 0.0;
				WriteCenteredFieldHeader(file, 6);

				if (GetPcaCount() > 3)
				{
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 3)
						{
							PcaSum += quiz->Quiz[q].Pca[3];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
					if (PcaCount)
						WritePca(file, PcaSum / PcaCount);
				}
				WriteFieldFooter(file);

				file.Write("</tr>");
			}
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
	long double CorrSum[MAX_GLOBAL_QUESTIONS];
	int CorrCount[MAX_GLOBAL_QUESTIONS];
	TQuiz *CorrQuiz[MAX_GLOBAL_QUESTIONS];
	int CorrQuestion[MAX_GLOBAL_QUESTIONS];
	long double PcaSum;
	int PcaCount;
	long double GroupSum[GROUP_COUNT];
	int GroupCount[GROUP_COUNT];
	int AsLoad;
	int NtLoad;
	int GlobalId;
	int i;
	int j;
	int g;
	int grp;
	TQuiz *quiz;
	TQuiz *CurrQuiz;
	TQuiz *TopQuiz;
	int TopQuestion;
	int q;
	char str[80];
	long double NormCorr;
	int cross;
	int ival;
	int count;
	int questions;
	long double val;
	long double corrval;
	long double LowestCorr;
	int ok;
	int first;
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

	for (g = 0; g < GROUP_COUNT; g++)
	{
		file.Write("<table border=3 cellspacing=0 cellpadding=0>");

		for (i = 0; i < MAX_GLOBAL_QUESTIONS; i++)
		{
			CorrSum[i] = 0.0;
			CorrCount[i] = 0;
		}

		file.Write("<tr style='height:24.75pt'>");

		WriteCenteredFieldHeader(file, 3);
		sprintf(str, "#", g + 1);
		file.Write(str);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 45);
		file.Write(Group[g].Name);
		WriteFieldFooter(file);

		WriteCenteredFieldHeader(file, 3);
		file.Write("AS-NT Corr");
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
				file.Write("<tr style='height:24.75pt'>");

				TopQuiz = CorrQuiz[GlobalId];
				TopQuestion = CorrQuestion[GlobalId];

				WriteCenteredFieldHeader(file, 3);
				sprintf(str, "%d", GlobalId + 1);
				file.Write(str);
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 45);
				if (TopQuiz->Quiz[TopQuestion].Reverse)
					file.Write("<span style='color:#990099'>");
				file.Write(TopQuiz->Quiz[TopQuestion].Text);
				if (TopQuiz->Quiz[TopQuestion].Reverse)
					file.Write("</span>");
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 3);

				val = CorrSum[GlobalId] / CorrCount[GlobalId];
				CorrCount[GlobalId] = 0;

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

				PcaCount = 0;
				PcaSum = 0.0;

				cross = 0;
				TopQuiz->ClearUsed(TopQuestion);
				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				while (quiz)
				{
					PcaSum += quiz->Quiz[q].Pca[0];
					PcaCount++;
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				}

				AsLoad = round(100 * PcaSum / PcaCount);

				PcaCount = 0;
				PcaSum = 0.0;

				if (GetPcaCount() > 1)
				{
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 1)
						{
							PcaSum += quiz->Quiz[q].Pca[1];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
					if (PcaCount)
						NtLoad = round(100 * PcaSum / PcaCount);
					else
						NtLoad = 0;
				}

				if (PcaCount)
				{
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
				}

				WriteCenteredFieldHeader(file, 3);
				sprintf(str, "0/%d", AsLoad);
				file.Write(str);
				WriteFieldFooter(file);

				WriteCenteredFieldHeader(file, 3);
				if (PcaCount)
				{
					if (NtLoad >= 0)
						sprintf(str, "0/%d", NtLoad);
					else
						sprintf(str, "%d/0", -NtLoad);
					file.Write(str);
				}
				WriteFieldFooter(file);

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					GroupSum[j] = 0.0;
					GroupCount[j] = 0;

					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						val = quiz->Quiz[q].Group[j].Corr;
						corrval = val;
						count = quiz->Quiz[q].Group[j].Count;
						questions = quiz->Group[j].Questions;

						if (count > 3)
						{
							GroupSum[j] += val * questions;
							GroupCount[j] += questions;
						}

						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
				}

				NormCorr = 0.0;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GroupCount[j])
					{
						val = GroupSum[j] / GroupCount[j];
						if (val >= NormCorr)
							NormCorr = val;
					}
				}
				NormCorr = 0.9 * NormCorr;

				WriteFieldHeader(file, 40);

				first = TRUE;
				ok = TRUE;
				while (ok)
				{
					ok = FALSE;

					for (j = 0; j < GROUP_COUNT - 1; j++)
					{
						if (GroupCount[j])
						{
							val = GroupSum[j] / GroupCount[j];
							if (val >= NormCorr)
							{
								if (ok)
								{
									if (val > corrval)
									{
										grp = j;
										corrval = val;
									}
								}
								else
								{
									ok = TRUE;
									grp = j;
									corrval = val;
								}
							}
						}
					}

					if (ok)
					{
						if (!first)
							file.Write(", ");
						file.Write(Group[grp].Name);
						first = FALSE;
						GroupCount[grp] = 0;
					}

					CorrCount[GlobalId] = 0;
				}
				WriteFieldFooter(file);
				file.Write("</tr>");
			}
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
	            
	    case GROUP_NT_SOCIAL:
	        file->Write("NT_SOCIAL");
	        break;
	            
	    case GROUP_ASPIE_COMM:
	        file->Write("STIMS");
	        break;
	            
	    case GROUP_NONVERBAL:
	        file->Write("NT_COMMUNICATION");
	        break;
	            
	    case GROUP_REPETITION:
	        file->Write("REPETITION");
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
	long double CorrSum[MAX_GLOBAL_QUESTIONS];
	int CorrCount[MAX_GLOBAL_QUESTIONS];
	TQuiz *CorrQuiz[MAX_GLOBAL_QUESTIONS];
	int CorrQuestion[MAX_GLOBAL_QUESTIONS];
	long double PcaSum;
	int PcaCount;
	long double GroupSum[GROUP_COUNT];
	int GroupCount[GROUP_COUNT];
	int AsLoad;
	int NtLoad;
	int GlobalId;
	int i;
	int j;
	int g;
	int grp;
	TQuiz *quiz;
	TQuiz *CurrQuiz;
	TQuiz *TopQuiz;
	int TopQuestion;
	int q;
	char str[80];
	long double NormCorr;
	int cross;
	int ival;
	int count;
	int questions;
	long double val;
	long double corrval;
	long double LowestCorr;
	int ok;
	int first;
	int found;
	TQuiz *cquiz;
	int cq;
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
    file.Write("<a href=\"histo\">Histogram of Aspie-quiz II-III + ND + 5-6</a><br>\n");
    file.Write("<a href=\"groupcorr.htm\">Grouping of Aspie-quiz I-III + ND + 5-8</a><br>\n");
    file.Write("<a href=\"pcaload.htm\">PCA loadings of Aspie-quiz I-III + ND + 5-8</a><br>\n");
    file.Write("<a href=\"pcacorr.htm\">Correlation between PCA loadings and psychiatric diagnosis</a><br>\n");
    file.Write("<a href=\"group.htm\">Correlation between groups</a><br>\n");

	file.Write("<h3>Quiz versions</h3>\n");
#endif

#ifdef SWEDISH
	file.Write("<h3>Summeringar</h3>\n");

    file.Write("<a href=\"avg.htm\">Översiktlig, grupperad rapport</a><br>\n");
    file.Write("<a href=\"avgcorr.htm\">Sammanvägda gruppkorrelationer</a><br>\n");
    file.Write("<a href=\"avgpca.htm\">Sammanvägda PCA-vikter</a><br>\n");
    file.Write("<a href=\"histo\">Histogram för Aspie-quiz I-III + ND + 5-6</a><br>\n");
    file.Write("<a href=\"groupcorr.htm\">Gruppering av Aspie-quiz I-III + ND + 5-8</a><br>\n");
    file.Write("<a href=\"pcaload.htm\">PCA koefficienter för Aspie-quiz I-III + ND + 5-8</a><br>\n");
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
	WriteName(file);
	file.Write("\">");
	file.Write("Version ");
    WriteName(file);
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
		file.Write(Group[g].Name);
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
        found = FALSE;

        for (q = 0; q < N && !found; q++)
        {
            if (Quiz[q].GlobalId == GlobalId)
            {
                found = TRUE;
                WriteLinkQuestion(&file, q, GlobalId);
            }
            else
            {
				cquiz = Quiz[q].CrossQuiz;
				cq = Quiz[q].CrossInd;
				while (cquiz && !found)
                {
                    if (cquiz->Quiz[cq].GlobalId == GlobalId)
                    {
                        found = TRUE;
                        cquiz->WriteLinkQuestion(&file, cq, GlobalId);
                    }
                    i = cquiz->Quiz[cq].CrossInd;
                    cquiz = cquiz->Quiz[cq].CrossQuiz;
                    cq = i;
                }
            }
        }


        for (cross = MAX_CROSS - 1; cross >= 0 && !found; cross--)
        {
            quiz = CrossQuiz[cross];
            if (quiz)
            {
                for (q = 0; q < quiz->N && !found; q++)
                {
                    if (quiz->Quiz[q].GlobalId == GlobalId)
                    {
                        found = TRUE;
                        quiz->WriteLinkQuestion(&file, q, GlobalId);
                    }
                    else
                    {
                        cquiz = quiz->Quiz[q].CrossQuiz;
                        cq = quiz->Quiz[q].CrossInd;
                        while (cquiz && !found)
                        {
							if (cquiz->Quiz[cq].GlobalId == GlobalId)
							{
								found = TRUE;
								cquiz->WriteLinkQuestion(&file, cq, GlobalId);
							}
							i = cquiz->Quiz[cq].CrossInd;
							cquiz = cquiz->Quiz[cq].CrossQuiz;
							cq = i;
						}
					}
                }
            }
        }
    }

	ClearUsed();

	for (g = 0; g < GROUP_COUNT; g++)
	{
	    file.Write("<h3>");
	    file.Write("<a name=\"");
        WriteLinkGroup(&file, g);
        file.Write("\">");
		file.Write(Group[g].Name);
        file.Write("</a>");
        file.Write("</h3>");

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
				TopQuiz = CorrQuiz[GlobalId];
				TopQuestion = CorrQuestion[GlobalId];

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

				val = CorrSum[GlobalId] / CorrCount[GlobalId];
				CorrCount[GlobalId] = 0;

#ifdef ENGLISH
            	file.Write("Aspie-neurotypical correlation: ");
#endif

#ifdef SWEDISH
            	file.Write("Aspie-neurotypisk korrelation: ");
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

				PcaCount = 0;
				PcaSum = 0.0;

				cross = 0;
				TopQuiz->ClearUsed(TopQuestion);
				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				while (quiz)
				{
					PcaSum += quiz->Quiz[q].Pca[0];
					PcaCount++;
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				}

				AsLoad = round(100 * PcaSum / PcaCount);

				PcaCount = 0;
				PcaSum = 0.0;

				if (GetPcaCount() > 1)
				{
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 1)
						{
							PcaSum += quiz->Quiz[q].Pca[1];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
					if (PcaCount)
						NtLoad = round(100 * PcaSum / PcaCount);
					else
						NtLoad = 0;
				}

				if (PcaCount)
				{
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
				}

#ifdef ENGLISH
				sprintf(str, "Aspie score: NO 0, YES %d", AsLoad);
#endif

#ifdef SWEDISH
				sprintf(str, "Aspie poäng: NEJ 0, JA %d", AsLoad);
#endif
				file.Write(str);
				file.Write("<br>");

				if (PcaCount)
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

				PcaCount = 0;
				PcaSum = 0.0;

				cross = 0;
				TopQuiz->ClearUsed(TopQuestion);
				quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				while (quiz)
				{
					PcaSum += quiz->Quiz[q].Pca[0];
					PcaCount++;
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
				}

                if (PcaCount)
                {
       				file.Write("PCA: Hn: ");
	    			WritePca(file, PcaSum / PcaCount);
	    		}

				if (GetPcaCount() > 1)
				{

    				PcaCount = 0;
	    			PcaSum = 0.0;
	    			
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 1)
						{
							PcaSum += quiz->Quiz[q].Pca[1];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}

                    if (PcaCount)
                    {
        				file.Write(", Hs: ");
    	    			WritePca(file, PcaSum / PcaCount);
    	    		}
				}

				if (GetPcaCount() > 2)
				{

    				PcaCount = 0;
	    			PcaSum = 0.0;
	    			
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 2)
						{
							PcaSum += quiz->Quiz[q].Pca[2];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}

					if (PcaCount)
					{
        				file.Write(", g: ");
	        			WritePca(file, PcaSum / PcaCount);
	        		}
				}

				if (GetPcaCount() > 3)
				{

    				PcaCount = 0;
	    			PcaSum = 0.0;
	    			
					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						if (quiz->GetPcaCount() > 3)
						{
							PcaSum += quiz->Quiz[q].Pca[3];
							PcaCount++;
						}
						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}

                    if (PcaCount)
                    {
        				file.Write(", introvert: ");
	        			WritePca(file, PcaSum / PcaCount);
	        		}
				}

                file.Write("<br>");
                
				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					GroupSum[j] = 0.0;
					GroupCount[j] = 0;

					TopQuiz->ClearUsed(TopQuestion);
					quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					while (quiz)
					{
						val = quiz->Quiz[q].Group[j].Corr;
						corrval = val;
						count = quiz->Quiz[q].Group[j].Count;
						questions = quiz->Group[j].Questions;

						if (count > 3)
						{
							GroupSum[j] += val * questions;
							GroupCount[j] += questions;
						}

						quiz = TopQuiz->GetHighestCorr(TopQuestion, &q);
					}
				}

				NormCorr = 0.0;

				for (j = 0; j < GROUP_COUNT - 1; j++)
				{
					if (GroupCount[j])
					{
						val = GroupSum[j] / GroupCount[j];
						if (val >= NormCorr)
							NormCorr = val;
					}
				}
				NormCorr = 0.9 * NormCorr;

#ifdef ENGLISH
                file.Write("Correlates with: ");
#endif

#ifdef SWEDISH
                file.Write("Korrelaterar med: ");
#endif

				first = TRUE;
				ok = TRUE;
				while (ok)
				{
					ok = FALSE;

					for (j = 0; j < GROUP_COUNT - 1; j++)
					{
						if (GroupCount[j])
						{
							val = GroupSum[j] / GroupCount[j];
							if (val >= NormCorr)
							{
								if (ok)
								{
									if (val > corrval)
									{
										grp = j;
										corrval = val;
									}
								}
								else
								{
									ok = TRUE;
									grp = j;
									corrval = val;
								}
							}
						}
					}

					if (ok)
					{
						if (!first)
							file.Write(", ");

                        file.Write("<a href=\"#");
                        WriteLinkGroup(&file, grp);
                        file.Write("\">");
                		file.Write(Group[grp].Name);
                        file.Write("</a>");

        				ival = round(100.0 * corrval);

        				if (TopQuiz->Quiz[TopQuestion].Reverse)
        				{
        				    sprintf(str, " (-.%02d)", ival);
							file.Write(str);
						}
						else
                        {
    						sprintf(str, " (.%02d)", ival);
	    					file.Write(str);
	    				}
                        
						first = FALSE;
						GroupCount[grp] = 0;
					}

					CorrCount[GlobalId] = 0;
				}
				file.Write("<br>");
			}
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
	file.Write("Quiz scoring (Hn - Hs)");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("Hn loading");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("Hs loading");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("G loading");
    WriteFieldFooter(file);

    WriteCenteredFieldHeader(file, 3);
	file.Write("Introvert");
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
		file.Write(Group[g1].Name);
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
					WriteCorr95(file, corrval, count);
				}
			}

			if (insertcr)
				file.Write("<br>");

			corrval = GroupCorr[g1][g2].Corr;
			count = GroupCorr[g1][g2].Count;
			WriteCorr95(file, corrval, count);

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
