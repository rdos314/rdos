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
# quiz.h
# Basic quiz class
#
########################################################################*/

#ifndef _QUIZ_H
#define _QUIZ_H

#include "pop.h"
#include "refer.h"
#include "file.h"

#define MAX_GROUP_COUNT         15
#define MAX_REFERERS            1024

#define GROUP_COUNT             11

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
    int NoAnswer;
    int MyGroup;
    int Reverse;
    TQuizGroup Group[MAX_GROUP_COUNT];
};

struct TGroupCorr
{
    long double Corr;
	int Count;
};

struct TGroup
{
    const char *Name;
	long double Mean;
	long double Sd;
};

class TQuiz
{
public:
    TQuiz();
    ~TQuiz();

    void WriteReferers(const char *filename);

protected:
    void Init();

    TReferer *FindReferer(char *Referer);
    TReferer *AddReferer(char *Search, char *Ref);
    void SortReferers();
    void WriteReferer(TFile &file, TReferer *ref);

    void DefineNt(char *Referer);
    void DefineAspie(char *Referer);
    
	TGroup Group[MAX_GROUP_COUNT];
	TGroupCorr GroupCorr[MAX_GROUP_COUNT][MAX_GROUP_COUNT];
	TQuizQuestion Quiz[MAX_QUESTIONS];

    TPopulation All;
    TPopulation As;
    TPopulation AsMale;
    TPopulation AsFemale;
    TPopulation Add;
    TPopulation AddMale;
    TPopulation AddFemale;
    TPopulation Aspie;
    TPopulation AspieMale;
    TPopulation AspieFemale;    
    TPopulation Mix;
    TPopulation MixMale;
    TPopulation MixFemale;
    TPopulation Nt;
    TPopulation NtMale;
    TPopulation NtFemale;    

    int RefCount;
    TReferer *RefArr[MAX_REFERERS];
    TReferer NoRef;
    TReferer NTRef;
    TReferer AspieRef;
    TReferer DxAsRef;
    TReferer DxTsRef;
    TReferer DxAddRef;
    TReferer SelfAsRef;
    TReferer SelfTsRef;
    TReferer SelfAddRef;
    TReferer MaleAsRef;
    TReferer FemaleAsRef;

};

#endif
