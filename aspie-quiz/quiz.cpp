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
	    return NoRef;

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

	    sprintf(str, "%d", ref->Result / ref->Count);
	    file.Write(str);

	    file.Write("</b>");
	    file.Write("</p>");

	    file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	    file.Write("<p align=\"right\">");
	    file.Write("<b>");

	    sprintf(str, "%d", round(100.0 * ref->Result0_59 / ref->Count));
	    file.Write(str);

		file.Write("%</b>");
	    file.Write("</p>");

	    file.Write("</td>");

	    file.Write("<td width=\"4%\" valign=middle align='center'>\n");

    	file.Write("<p align=\"right\">");
	    file.Write("<b>");

    	sprintf(str, "%d", round(100.0 * ref->Result60_99 / ref->Count));
	    file.Write(str);

	    file.Write("%</b>");
	    file.Write("</p>");

	    file.Write("</td>");

	    file.Write("<td width=\"4%\" valign=middle align='center'>\n");

	    file.Write("<p align=\"right\">");
	    file.Write("<b>");

	    sprintf(str, "%d", round(100.0 * ref->Result100_139 / ref->Count));
	    file.Write(str);

	    file.Write("%</b>");
        file.Write("</p>");

        file.Write("</td>");
	      
	    file.Write("<td width=\"4%\" valign=middle align='center'>\n");

        file.Write("<p align=\"right\">");
	    file.Write("<b>");

        sprintf(str, "%d", round(100.0 * ref->Result140_200 / ref->Count));
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

	file.Write("<td width=\"4%\" valign=middle align='center'>\n");

    file.Write("<p align=\"center\">");
	file.Write("<b>Answers");
    file.Write("</b>");
    file.Write("</p>");

	file.Write("</td>");

	file.Write("<td width=\"4%\" valign=middle align='center'>\n");

    file.Write("<p align=\"center\">");
    file.Write("<b>Score");
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
