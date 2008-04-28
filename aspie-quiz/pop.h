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
# pop.h
# Basic population class
#
########################################################################*/

#ifndef _POP_H
#define _POP_H

#define MAX_CATS        16
#define MAX_QUESTIONS   300

#define ACTIVE_GROUP_COUNT      14

#define DX_COUNT				16

#define DX_AUTISM          		0
#define DX_AS             		1
#define DX_ADD            		2
#define DX_HYPERLEXIA     		3
#define DX_DYSPRAXIA      		4
#define DX_DYSLEXIA       		5
#define DX_DYSCALCULIA    		6
#define DX_OCD		            7
#define DX_ODD            		8
#define DX_SYNAESTHESIA   		9
#define DX_PA             		10
#define DX_DYSGRAPHIA     		11
#define DX_BIPOLAR        		12
#define DX_TS             		13
#define DX_SCHIZOPHRENIA  		14
#define DX_SOCIAL_PHOBIA  		15

#define DX_STATE_UNKNOWN		0
#define DX_STATE_NO				1
#define DX_STATE_YES			2
#define DX_STATE_SELF			3

struct TValArr
{
	int AsScore;
	int NtScore;
	char DxArr[DX_COUNT];
	char Quiz[MAX_QUESTIONS];
	char GroupResult[ACTIVE_GROUP_COUNT];
	char DxResult[DX_COUNT];
};

class TPopulation
{
public:
	TPopulation(int questions);
	~TPopulation();

	void Add(int AsScore, int NtScore, char DxArr[DX_COUNT], int Gender, char Arr[MAX_QUESTIONS], char GroupScore[ACTIVE_GROUP_COUNT], char DxScore[DX_COUNT]);
	void Add(int Score, char DxArr[DX_COUNT], int Gender, char Arr[MAX_QUESTIONS], char GroupScore[ACTIVE_GROUP_COUNT], char DxScore[DX_COUNT]);

	long double GetMean(int QuestionNr);
	long double GetSd(int QuestionNr);

	int N;

	int Count[MAX_QUESTIONS];
	int Sum[MAX_QUESTIONS];
	int ChiArr[MAX_QUESTIONS][MAX_CATS];
	int MaleChiArr[MAX_QUESTIONS][MAX_CATS];
	int FemaleChiArr[MAX_QUESTIONS][MAX_CATS];

	int Increment;
	int ValueCount;
	int MaxSize;
	TValArr *ValArr;
};

#endif

