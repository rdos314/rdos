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
#include "popcorr.h"
#include "refer.h"
#include "file.h"

#if !defined(SWEDISH) && !defined(ENGLISH)
#define ENGLISH
#endif

//#define USE_PERCENT     1     // write correlations in % variance explained

#define MAX_GROUP_COUNT         15
#define MAX_REFERERS            1024
#define MAX_CROSS               30
#define MAX_PCA_AXIS            8

#define PCA_TYPE_ALL            0
#define PCA_TYPE_MALE           1
#define PCA_TYPE_FEMALE         2
#define PCA_TYPE_YOUNG          3
#define PCA_TYPE_OLD            4
#define PCA_TYPE_AS             5
#define PCA_TYPE_MIXED          6

#define GROUP_COUNT             11

#define GROUP_SENSORY           0
#define GROUP_MOTOR             1
#define GROUP_NONVERBAL         2
#define GROUP_ABILITY           3
#define GROUP_DISABILITY        4
#define GROUP_REPETITION        5
#define GROUP_SOCIAL            6
#define GROUP_NT_RELATION       7
#define GROUP_SEX               8
#define GROUP_INTROVERT         9
#define GROUP_MIXED             10

class TQuiz;

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
	int Count;
	long double Sum;
    int Used;
    int NoAnswer;
    int MyGroup;
    int Reverse;
    TQuiz *CrossQuiz;
    int CrossInd;
    TQuizGroup Group[MAX_GROUP_COUNT];
    long double Pca[MAX_PCA_AXIS];
    long double MalePca[MAX_PCA_AXIS];
	long double FemalePca[MAX_PCA_AXIS];
	long double YoungPca[MAX_PCA_AXIS];
    long double OldPca[MAX_PCA_AXIS];
	long double AsPca[MAX_PCA_AXIS];
    long double MixedPca[MAX_PCA_AXIS];
};

struct TGroupCorr
{
    long double Corr;
	int Count;
};

struct TGroupVal
{
    int Count;
    int Sum;
};

struct TGroupValArr
{
    TGroupVal Group[MAX_GROUP_COUNT];    
};

struct TGroup
{
    const char *Name;
	long double Mean;
	long double Sd;
	int Answers;
	int Count;
	int Sum;
};

class TQuiz
{
public:
    TQuiz(int questions);
    ~TQuiz();

    void WriteReferers(const char *filename);
    void WriteSumaryTable(const char *filename, int OnlyMixed);
    void WriteAsNtCorrelation(const char *filename);
    void WriteAspieAsCorrelation(const char *filename);
    void WriteAddAsCorrelation(const char *filename);
    void WriteGenderAsCorrelation(const char *filename);
    void WriteAddNtCorrelation(const char *filename);
    void WriteLowAsNtCorrelation(const char *filename);
    void WriteLowAsAsCorrelation(const char *filename);
    void WriteRefererAsCorrelation(const char *filename, const char *header, const char *referer);
    void WriteRefererNtCorrelation(const char *filename, const char *header, const char *referer);
    void WriteAsNtAll(const char *filename);
	void WriteGroupCorrTable(const char *filename);
	void WritePcaLoadTable(const char *filename);
	void WriteGroupTable(const char *filename, int Cross);
	void WritePca(const char *filename);
	void WriteWeighting(const char *filename);
	void WritePhpWeighting(const char *filename);

	void OptimizeAsWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);

	virtual void ImportMvsp(const char *filename, int PcaType) = 0;
	virtual void ExportExcelCase(const char *filename, int PcaType) = 0;

	virtual void WriteIQ(const char *filename);
	virtual void WriteHair(const char *filename);
	virtual void WriteEye(const char *filename);
    virtual void WriteRace(const char *filename);

	void CheckCross();

protected:
	void Init();
	int round(long double val);
    int CalcAsNtDiff(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS], int *AsDiff, int *NtDiff);
    int OptimizeAsOne(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);
    void WriteAsWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);
    void WriteWikiWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);

	virtual void GetReferer(const char *referer, TPopulation *pop) = 0;
	virtual void WriteName(TFile &File) = 0;
	virtual int GetPcaCount();

    void DefineCross(int id, TQuiz *quiz);
    TReferer *FindReferer(char *Referer);
    TReferer *AddReferer(char *Search, char *Ref);
    void SortReferers();
    void CalcAspieNtCorr();
    void Calculate();
    void DefineCross(TQuiz *quiz, int MyQuestion, int CrossQuestion);
    
    void ClearUsed();
    void ClearUsed(int Question);
    TQuiz *GetTopQuizCorr(int *Question);
    TQuiz *GetTopGroupCorr(int Group, int *Question);
    TQuiz *GetHighestCorr(int MyQuestion, int *Question);

    void DefineNt(char *Referer);
    void DefineAspie(char *Referer);

    void WriteFieldHeader(TFile &File, int RelWidth);
    void WriteCenteredFieldHeader(TFile &File, int RelWidth);
    void WriteRightFieldHeader(TFile &File, int RelWidth);
    void WriteFieldFooter(TFile &File);

    void WriteStaple(TFile &File, TPopulation *pop, int Question);
    void WriteCI95(TFile &File, TPopulation *pop, int Question);
	void WriteCorr95(TFile &File, long double corr, int count);
    void WritePca(TFile &File, long double pca);
	void WriteReferer(TFile &file, TReferer *ref);
    void WriteCorrTable(const char *filename, const char *name1, const char *name2, TPopulation *pop1, TPopulation *pop2, long double mincorr);

    void WriteAsCI95(TFile &File, int Question);
    void WriteNtCI95(TFile &File, int Question);
    void WriteAsNtChi2(TFile &File, int Question);
    void WriteAsNtCorr95(TFile &File, int Question);

	TPopulationCorrelation PopCorr;

    TPopulation All;
    TPopulation LowAs;
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

    int UseNtResult;
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
    TReferer MaleNonAsRef;
    TReferer FemaleNonAsRef;
    TReferer HyperlexiaRef;
    TReferer DyspraxiaRef;
    TReferer DyslexiaRef;
    TReferer DyscalculiaRef;
    TReferer OCDRef;
    TReferer ODDRef;
    TReferer SynaesthesiaRef;
    TReferer PARef;
    TReferer DysgraphiaRef;
    TReferer BipolarRef;
    TReferer AmerindianRef;
    TReferer BlackRef;
    TReferer HispanicRef;
    TReferer WhiteRef;
    TReferer ArabRef;
    TReferer AsianRef;

    TQuiz *CrossQuiz[MAX_CROSS];

    int N;    
    int GroupValCount;
    TGroupValArr *GroupValArr;    
	TGroup Group[MAX_GROUP_COUNT];
	TGroupCorr GroupCorr[MAX_GROUP_COUNT][MAX_GROUP_COUNT];
	TQuizQuestion Quiz[MAX_QUESTIONS];

};

#endif
