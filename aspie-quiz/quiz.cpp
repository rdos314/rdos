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
TQuiz::TQuiz()
  : NoRef("", "No referrer"),
    NTRef("", "NT control group"),
    AspieRef("", "Aspie control group"),
    DxAsRef("", "Diagnosed AS/HFA/PDD"),
    DxTsRef("", "Diagnosed Tourette"),
    DxAddRef("", "Diagnosed ADD/ADHD"),
    SelfAsRef("", "Self-diagnosed AS/HFA/PDD"),
    SelfTsRef("", "Self-diagnosed Tourette"),
    SelfAddRef("", "Self-diagnosed ADD/ADHD"),
    MaleAsRef("", "Male AS/HFA/PDD"),
    FemaleAsRef("", "Female AS/HFA/PDD")	
{
    int i;
    int g;
    int g1, g2;

    RefCount = 0;

    for (i = 0; i < MAX_REFERERS; i++)
        RefArr[i] = 0;

    for (i = 0; i < 100; i++)
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


    for (i = 0; i < 100; i++)
    {
        Quiz[i].Text = "NO TEXT";
        Quiz[i].Reverse = FALSE;
    }

    for (g = 0; g < MAX_GROUP_COUNT; g++)
        Group[g].Name = "NO NAME";

#ifdef ENGLISH

	Group[GROUP_SENSORY].Name = "SENSORY SYSTEM";
	Group[GROUP_BIOLOGY].Name = "BIOLOGY";
	Group[GROUP_NONVERBAL].Name = "NONVERBAL COMMUNICATION";
	Group[GROUP_LANGUAGE].Name = "LANGUAGE AND SPEECH";
	Group[GROUP_SOCIAL].Name = "SOCIAL & EMOTIONS";
	Group[GROUP_NT_RELATION].Name = "NT RELATIONSHIPS";
	Group[GROUP_SEX].Name = "SEXUALITY & GENDER ISSUES";
	Group[GROUP_FOCUS].Name = "HYPERFOCUS, DETAIL & TALENTS";
	Group[GROUP_REPETITION].Name = "NEED FOR REPETITION & PREDICTABILITY";
	Group[GROUP_PHYSICAL].Name = "PHYSICAL TRAITS";
	Group[GROUP_MIXED].Name = "MIXED";

#endif

#ifdef SWEDISH

	Group[GROUP_SENSORY].Name = "SINNEN";
	Group[GROUP_BIOLOGY].Name = "BIOLOGI";
	Group[GROUP_NONVERBAL].Name = "ICKE-VERBAL KOMMUNIKATION";
	Group[GROUP_LANGUAGE].Name = "TAL & SPRÅK";
	Group[GROUP_SOCIAL].Name = "SOCIALT & KÄNSLOR";
	Group[GROUP_NT_RELATION].Name = "NT RELATIONER";
	Group[GROUP_SEX].Name = "SEXUALITET & KÖNSROLLER";
	Group[GROUP_FOCUS].Name = "HYPERFOKUS, DETALJER & TALANGER";
	Group[GROUP_REPETITION].Name = "UPPREPNING, STRUKTUR OCH FÖRUTSÄGBARTHET";
	Group[GROUP_PHYSICAL].Name = "FYSISKA DRAG";
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
		NTRef.Result += ref->Result;
		NTRef.Count += ref->Count;
		NTRef.Result0_59 += ref->Result0_59;
		NTRef.Result60_99 += ref->Result60_99;
		NTRef.Result100_139 += ref->Result100_139;
		NTRef.Result140_200 += ref->Result140_200;
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
		 AspieRef.Result += ref->Result;
		 AspieRef.Count += ref->Count;
		 AspieRef.Result0_59 += ref->Result0_59;
		 AspieRef.Result60_99 += ref->Result60_99;
		 AspieRef.Result100_139 += ref->Result100_139;
		 AspieRef.Result140_200 += ref->Result140_200;
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

    for (i = 0; i < MAX_QUESTIONS; i++)
        ClearUsed(i);
}

/*##################  TQuiz::iGetHighestCorr ##########################
*   Purpose....: Get highest correlated in non-used quizes            	    #
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

	PopCorr.Correlate(&Aspie, &Nt);

	for (i = 0; i < MAX_QUESTIONS; i++)
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

	    WriteRightFieldHeader(file, 4);
	    sprintf(str, "%d", ref->Result / ref->Count);
	    file.Write(str);
	    WriteFieldFooter(file);

	    WriteRightFieldHeader(file, 4);
	    sprintf(str, "%d", round(100.0 * ref->Result0_59 / ref->Count));
	    file.Write(str);
	    WriteFieldFooter(file);

	    WriteRightFieldHeader(file, 4);
    	sprintf(str, "%d", round(100.0 * ref->Result60_99 / ref->Count));
	    file.Write(str);
	    WriteFieldFooter(file);

	    WriteRightFieldHeader(file, 4);
	    sprintf(str, "%d", round(100.0 * ref->Result100_139 / ref->Count));
	    file.Write(str);
	    WriteFieldFooter(file);
	      
	    WriteRightFieldHeader(file, 4);
        sprintf(str, "%d", round(100.0 * ref->Result140_200 / ref->Count));
        file.Write(str);
	    WriteFieldFooter(file);
    
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
            ival = round(100.0 * rlow);
		    sprintf(str, "%d", ival);
		    File.Write(str);

    		ival = round(100.0 * rhigh);
	    	sprintf(str, "-%d", ival);
		    File.Write(str);
			
			File.Write("%");
		}

    }
    else
        File.Write("100%");

    File.Write("</span>\n");
        
}

/*##################  TQuiz::WriteSumaryTable ##########################
*   Purpose....: Write sumary table	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteSumaryTable(const char *filename)
{
	int i;
	char str[80];
	int ival;
	TFile file(filename, 0);
	int UseGender;

	if (AspieMale.ValueCount && NtMale.ValueCount && AspieFemale.ValueCount && NtFemale.ValueCount)
	    UseGender = TRUE;
	else
	    UseGender = FALSE;

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	for (i = 0; i < 100; i++)
	{
		if (i % 10 == 0)
		{
			file.Write("<tr style='height:24.75pt'>");

        	WriteCenteredFieldHeader(file, 5);
			file.Write("#");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 42);
			file.Write(" ");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 5);
			file.Write("?");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 5);
			file.Write("Trend");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 8);
			file.Write("Aspie");
			if (UseGender)
			    file.Write("<br>M/F");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 8);
			file.Write("AS");
			if (UseGender)
			    file.Write("<br>M/F");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 8);
			file.Write("ADHD");
			if (UseGender)
			    file.Write("<br>M/F");
			WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 8);
			file.Write("Mixed");
			if (UseGender)
			    file.Write("<br>M/F");
        	WriteFieldFooter(file);

        	WriteCenteredFieldHeader(file, 8);
			file.Write("NT");
			if (UseGender)
			    file.Write("<br>M/F");
        	WriteFieldFooter(file);

			file.Write("</tr>");
		}

		file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 5);
		sprintf(str, "%d", i + 1);
		file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 42);
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
		if (UseGender)
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

		if (UseGender)
		{
            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &AspieMale, i);
		    file.Write("<br>");
		    WriteCI95(file, &AspieFemale, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
			WriteCI95(file, &AsMale, i);
		    file.Write("<br>");
		    WriteCI95(file, &AsFemale, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &AddMale, i);
		    file.Write("<br>");
		    WriteCI95(file, &AddFemale, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &MixMale, i);
		    file.Write("<br>");
		    WriteCI95(file, &MixFemale, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &NtMale, i);
		    file.Write("<br>");
		    WriteCI95(file, &NtFemale, i);
            WriteFieldFooter(file);
	    }
	    else
	    {
            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &Aspie, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &As, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &Add, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &Mix, i);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 8);
		    WriteCI95(file, &Nt, i);
            WriteFieldFooter(file);
	    }
	    
		file.Write("</tr>");
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

	for (i = 0; i < 100; i++)
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

/*##################  TQuiz::WriteRefererNtCorrelation ##########################
*   Purpose....: Write referer vs NT correlation	   			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteRefererNtCorrelation(const char *filename, const char *header, const char *referer)
{
	TPopulation pop;

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
    TPopulation pop;

    GetReferer(referer, &pop);

    if (pop.ValueCount >= 5 && Aspie.ValueCount >= 5)
    	WriteCorrTable(filename, header, "Aspie control", &pop, &Nt, 6.0);
}
