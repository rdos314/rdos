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
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz::TQuiz(const char *FileName)
{
	TFile file(FileName);
	
	file.Read(&Group, sizeof(Group));
	file.Read(&GroupCorr, sizeof(GroupCorr));
	file.Read(&Quiz, sizeof(Quiz));    

	Init();
}

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
{
    int i;
    int g;
    int g1, g2;

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
