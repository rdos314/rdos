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
	 FemaleNonAsRef("", "Female non-AS/HFA/PDD")
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
    }

    for (g = 0; g < MAX_GROUP_COUNT; g++)
		Group[g].Name = "NO NAME";

#ifdef ENGLISH

	Group[GROUP_SENSORY].Name = "SENSORY SYSTEM";
	Group[GROUP_NONVERBAL].Name = "NONVERBAL COMMUNICATION";
	Group[GROUP_SOCIAL].Name = "SOCIAL & EMOTIONS";
	Group[GROUP_NT_RELATION].Name = "NT RELATIONSHIPS";
	Group[GROUP_SEX].Name = "SEXUALITY & GENDER ISSUES";
	Group[GROUP_FOCUS].Name = "HYPERFOCUS, DETAIL & TALENTS";
	Group[GROUP_REPETITION].Name = "NEED FOR REPETITION & PREDICTABILITY";
	Group[GROUP_MOTOR].Name = "MOTOR";
	Group[GROUP_MATH].Name = "MATH";
	Group[GROUP_MIXED].Name = "MIXED";

#endif

#ifdef SWEDISH

	Group[GROUP_SENSORY].Name = "SINNEN";
	Group[GROUP_NONVERBAL].Name = "ICKE-VERBAL KOMMUNIKATION";
	Group[GROUP_SOCIAL].Name = "SOCIALT & KÄNSLOR";
	Group[GROUP_NT_RELATION].Name = "NT RELATIONER";
	Group[GROUP_SEX].Name = "SEXUALITET & KÖNSROLLER";
	Group[GROUP_FOCUS].Name = "HYPERFOKUS, DETALJER & TALANGER";
	Group[GROUP_REPETITION].Name = "UPPREPNING, STRUKTUR OCH FÖRUTSÄGBARTHET";
	Group[GROUP_MOTOR].Name = "MOTOR";
	Group[GROUP_MATH].Name = "MATEMATIK";
	Group[GROUP_MIXED].Name = "OGRUPPERADE";

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

        for (cross = 0; cross < MAX_CROSS; cross++)
            CrossArr[cross] = -1;

        while (quiz)
        {
            for (cross = 0; cross < MAX_CROSS; cross++)
                if (quiz == CrossQuiz[cross])
                    CrossArr[cross] = curr;
        
            if (quiz->Quiz[curr].MyGroup != group)
                printf("Group conflict, question:%d %d should be %d\r\n",
                         q, quiz->Quiz[curr].MyGroup, group);

            if (strcmp(quiz->Quiz[curr].Text, text))
                printf("Text conflict, question:%d <%s> should be <%s>\r\n",
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
	    	NTRef.ResultLowAs += ref->ResultLowAs;
		    NTRef.ResultHighAs += ref->ResultHighAs;
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
    		 AspieRef.ResultLowAs += ref->ResultLowAs;
	    	 AspieRef.ResultHighAs += ref->ResultHighAs;
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

    for (cross = 0; cross < MAX_CROSS; cross++)
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
    	    sprintf(str, "%d%", round(100.0 * ref->ResultLowAs / ref->Count));
	        file.Write(str);
	        WriteFieldFooter(file);

    	    WriteRightFieldHeader(file, 4);
	        sprintf(str, "%d%", round(100.0 * ref->ResultHighAs / ref->Count));
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
        file.Write("AS 0-50");
    	WriteFieldFooter(file);

    	WriteCenteredFieldHeader(file, 4);
        file.Write("AS 100-");
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
	WriteReferer(file, &NTRef);
	WriteReferer(file, &NoRef);

	for (i = 0; i < RefCount; i++)
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
		if (val > 2.0)
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
                ival = round(100.0 * rlow * rlow);
		        sprintf(str, "%d", ival);
		        File.Write(str);

        		ival = round(100.0 * rhigh * rhigh);
	        	sprintf(str, "-%d", ival);
		        File.Write(str);
			
    			File.Write("%");
	    	}
	    }
	    else
            File.Write("100%");
    }
    else
	    File.Write(" ");

    File.Write("</span>\n");
        
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
	    		file.Write("PCA #1");
		    	if (UseGender && !OnlyMixed)
			        file.Write("<br>M/F");
        	    WriteFieldFooter(file);

            	WriteCenteredFieldHeader(file, 6);
	    		file.Write("PCA #2");
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
			    ival = round(100.0 * Quiz[i].MalePca[0]);
    			sprintf(str, "%d%", ival);
	    		file.Write(str);
		    	file.Write("<br>");
			    ival = round(100.0 * Quiz[i].FemalePca[0]);
    			sprintf(str, "%d%", ival);
	    		file.Write(str);
		    	WriteFieldFooter(file);

       			WriteCenteredFieldHeader(file, 6);
	    		ival = round(100.0 * Quiz[i].MalePca[1]);
		    	sprintf(str, "%d%", ival);
			    file.Write(str);
    			file.Write("<br>");
	    		ival = round(100.0 * Quiz[i].FemalePca[1]);
		    	sprintf(str, "%d%", ival);
			    file.Write(str);
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
				    ival = round(100.0 * Quiz[i].MixedPca[0]);
	    		else
		    		ival = round(100.0 * Quiz[i].Pca[0]);

		    	sprintf(str, "%d%", ival);
			    file.Write(str);
		    	WriteFieldFooter(file);
    
	    		WriteCenteredFieldHeader(file, 6);
		    	if (OnlyMixed)
	    			ival = round(100.0 * Quiz[i].MixedPca[1]);
			    else
    				ival = round(100.0 * Quiz[i].Pca[1]);
	    		sprintf(str, "%d%", ival);
		    	file.Write(str);
			    WriteFieldFooter(file);

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

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");
        
    for (g = 0; g < GROUP_COUNT; g++)
    {
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
		file.Write("PCA #1");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
		file.Write("PCA #2");
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
				    
				ival = round(100.0 * quiz->Quiz[q].Corr * quiz->Quiz[q].Corr);
				sprintf(str, "%d%", ival);
				file.Write(str);
				
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
				ival = round(100.0 * quiz->Quiz[q].Pca[0]);
				sprintf(str, "%d%", ival);
				file.Write(str);

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
				ival = round(100.0 * quiz->Quiz[q].Pca[1]);
				sprintf(str, "%d%", ival);
				file.Write(str);

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

							ival = round(100.0 * low * low);
							sprintf(str, "%d", ival);
							file.Write(str);

							ival = round(100.0 * high * high);
							sprintf(str, "-%d%", ival);
							file.Write(str);

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
	}
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
		assum = Quiz[i].Pca[0];
		ntsum = Quiz[i].Pca[1];
		count = 1;

        j = Quiz[i].CrossInd;
        CurrQuiz = Quiz[i].CrossQuiz;
        j = i;

        while (CurrQuiz)
        {
			assum += CurrQuiz->Quiz[j].Pca[0];
			ntsum += CurrQuiz->Quiz[j].Pca[1];
			count++;

			k = CurrQuiz->Quiz[j].CrossInd;
			CurrQuiz = CurrQuiz->Quiz[j].CrossQuiz;
            j = k;
        }

        Asw[i] = assum / (long double)count;
        Ntw[i] = ntsum / (long double)count;        
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

    for (i = 0; i < N; i++)
    {
		assum = Quiz[i].MalePca[0] - Quiz[i].FemalePca[0];
		ntsum = Quiz[i].MalePca[1] - Quiz[i].FemalePca[1];
        count = 1;

        j = Quiz[i].CrossInd;
		CurrQuiz = Quiz[i].CrossQuiz;
        j = i;

        while (CurrQuiz)
        {
			mas0 = CurrQuiz->Quiz[j].MalePca[0];
			fas0 = CurrQuiz->Quiz[j].FemalePca[0];
			mas1 = CurrQuiz->Quiz[j].MalePca[1];
			fas1 = CurrQuiz->Quiz[j].FemalePca[1];

            if (mas0 != 0 || fas0 != 0 || mas1 != 0 || fas1 != 0)
            {
                assum += mas0 - fas0;
                ntsum += mas1 - fas1;
                count++;
            }

            k = CurrQuiz->Quiz[j].CrossInd;
            CurrQuiz = CurrQuiz->Quiz[j].CrossQuiz;
            j = k;
        }

        Asg[i] = assum / (long double)count / 2.0;
        Ntg[i] = ntsum / (long double)count / 2.0;        
    }

    sprintf(str, "    static int Asg[%d] = {", N);
    file.Write(str);
    
	for (i = 0; i < N; i++)
	{
        if ((i % 10) == 0)
    	    file.Write("\r\n          ");
    	        
		ival = round(100.0 * Asg[i]);
		sprintf(str, "%5d", ival);
		file.Write(str);

	    if (i != N - 1)
    	    file.Write(",");		
	}
	file.Write("};\r\n\r\n");

    sprintf(str, "    static int Ntg[%d] = {", N);
    file.Write(str);
    
	for (i = 0; i < N; i++)
	{
        if ((i % 10) == 0)
    	    file.Write("\r\n          ");
    	        
		ival = round(100.0 * Ntg[i]);
		sprintf(str, "%5d", ival);
		file.Write(str);

	    if (i != N - 1)
    	    file.Write(",");		
	}
	file.Write("};\r\n\r\n");

    for (i = 0; i < N; i++)
    {
		assum = Quiz[i].OldPca[0] - Quiz[i].YoungPca[0];
		ntsum = Quiz[i].OldPca[1] - Quiz[i].YoungPca[1];
		count = 1;

        j = Quiz[i].CrossInd;
        CurrQuiz = Quiz[i].CrossQuiz;
        j = i;

        while (CurrQuiz)
        {
			oas0 = CurrQuiz->Quiz[j].OldPca[0];
			yas0 = CurrQuiz->Quiz[j].YoungPca[0];
			oas1 = CurrQuiz->Quiz[j].OldPca[1];
			yas1 = CurrQuiz->Quiz[j].YoungPca[1];

			if (oas0 != 0 || oas0 != 0 || yas1 != 0 || yas1 != 0)
            {
                assum += oas0 - yas0;
                ntsum += oas1 - yas1;
                count++;
            }

            k = CurrQuiz->Quiz[j].CrossInd;
            CurrQuiz = CurrQuiz->Quiz[j].CrossQuiz;
            j = k;
        }

        Asg[i] = assum / (long double)count / 2.0;
        Ntg[i] = ntsum / (long double)count / 2.0;        
    }

    sprintf(str, "    static int Asa[%d] = {", N);
    file.Write(str);
    
	for (i = 0; i < N; i++)
	{
        if ((i % 10) == 0)
    	    file.Write("\r\n          ");
    	        
		ival = round(100.0 * Asg[i]);
		sprintf(str, "%5d", ival);
		file.Write(str);

	    if (i != N - 1)
    	    file.Write(",");		
	}
	file.Write("};\r\n\r\n");

    sprintf(str, "    static int Nta[%d] = {", N);
    file.Write(str);
    
	for (i = 0; i < N; i++)
	{
        if ((i % 10) == 0)
    	    file.Write("\r\n          ");
    	        
		ival = round(100.0 * Ntg[i]);
		sprintf(str, "%5d", ival);
		file.Write(str);

	    if (i != N - 1)
    	    file.Write(",");		
	}
	file.Write("};\r\n\r\n");

}
