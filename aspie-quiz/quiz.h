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
#include "dsmpop.h"
#include "refer.h"
#include "file.h"

#if !defined(SWEDISH) && !defined(ENGLISH)
#define ENGLISH
#endif

//#define USE_PERCENT     1     // write correlations in % variance explained

#define MAX_GROUP_COUNT         18
#define MAX_REFERERS            1024
#define MAX_CROSS               30
#define MAX_PCA_AXIS            8
#define MAX_ASPIE_PCA_AXIS      32      // must change in Import method as well!

#define MAX_USERS               2048

#define PCA_TYPE_ALL            0
#define PCA_TYPE_MALE           1
#define PCA_TYPE_FEMALE         2
#define PCA_TYPE_YOUNG          3
#define PCA_TYPE_OLD            4
#define PCA_TYPE_AS             5
#define PCA_TYPE_MIXED          6

#define GROUP_COUNT             18

#define GROUP_ASPIE_TALENT      0
#define GROUP_NT_TALENT         1
#define GROUP_ASPIE_OBSESSION   2
#define GROUP_NT_OBSESSION      3
#define GROUP_ASPIE_SOCIAL      4
#define GROUP_NT_SOCIAL         5
#define GROUP_ASPIE_NVC         6
#define GROUP_NT_NVC            7
#define GROUP_ASPIE_HUNTING     8
#define GROUP_NT_HUNTING        9
#define GROUP_ASPIE_SENSORY     10
#define GROUP_NT_SENSORY        11

#define GROUP_ASPIE_BIOLOGY     12
#define GROUP_PARANOID          13
#define GROUP_ENVIRONMENT       14
#define GROUP_RELIGION          15
#define GROUP_SEX               16
#define GROUP_MIXED             17

#define POP_TYPE_ALL            0
#define POP_TYPE_AS             1
#define POP_TYPE_ASPIE          2
#define POP_TYPE_ADD            3
#define POP_TYPE_NT             4
#define POP_TYPE_HYPERLEXIA     5
#define POP_TYPE_DYSPRAXIA      6
#define POP_TYPE_DYSLEXIA       7
#define POP_TYPE_DYSCALCULIA    8
#define POP_TYPE_OCD            9
#define POP_TYPE_ODD            10
#define POP_TYPE_SYNAESTHESIA   11
#define POP_TYPE_PA             12
#define POP_TYPE_DYSGRAPHIA     13
#define POP_TYPE_BIPOLAR        14
#define POP_TYPE_TS             15
#define POP_TYPE_SCHIZOPHRENIA  16
#define POP_TYPE_LOW_IQ         17
#define POP_TYPE_HIGH_IQ        18
#define POP_TYPE_SOCIAL_PHOBIA  19
#define POP_TYPE_NT_CONTROL     20
#define POP_TYPE_AUTISM         21
#define POP_TYPE_ASPIE_CONTROL  22

class TBirthMonth
{
public:
	TBirthMonth();
	void Add(int AsResult, int NtResult, int BirthMonth);
	int GetFactor(int index);
	void ExportHistogram(const char *filename);

	int AsCount[15];
	int NtCount[15];
};

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
    int ChiArr[2][16];
    int ChiCount[2];
	long double Corr;
	int Count;
	long double Sum;
    int Used;
    int NoAnswer;
    int MyGroup;
    int Reverse;
    TQuiz *CrossQuiz;
    int CrossInd;
    int GlobalId;
    int Changed;
    int Cats;
    TQuizGroup Group[MAX_GROUP_COUNT];
    long double Pca[MAX_PCA_AXIS];
    long double MalePca[MAX_PCA_AXIS];
	long double FemalePca[MAX_PCA_AXIS];
	long double YoungPca[MAX_PCA_AXIS];
    long double OldPca[MAX_PCA_AXIS];
	long double AsPca[MAX_PCA_AXIS];
    long double MixedPca[MAX_PCA_AXIS];
    long double AspiePca[MAX_ASPIE_PCA_AXIS];
    long double GroupPca[MAX_GROUP_COUNT];
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
    const char *PosName;
    const char *NegName;
	long double Mean;
	long double Sd;
	int Answers;
	int Count;
	int Sum;
	int Questions;
};

struct TAxis
{
    long double MaxCorr;
	long double PcaCorr[2];
	long double GroupCorr[MAX_GROUP_COUNT];
};

struct TUserInfo
{
    int BirthYear;
    int BirthMonth;
    int Count;
    int AsSum;
    int NtSum;
};

struct TUserVersionQuiz
{
    int Count;
    long double AsScore;
    long double NtScore;
};

struct TUserVersionInfo
{
    TUserVersionQuiz *ScoreArr[MAX_CROSS];
};

class TQuiz
{
public:
    TQuiz(int questions);
    ~TQuiz();

    void WriteReferers(const char *filename);
    void WriteSumaryTable(const char *filename, int OnlyMixed);
    void WriteIntercorr(const char *filename);
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
    void WritePcaCorrTable(const char *filename);
	void WriteGroupTable(const char *filename, int Cross);
    void WriteAverageGroupCorrTable(const char *filename);
    void WriteAveragePcaTable(const char *filename);
	void WriteAveragePcaCorrTable(const char *filename);
	void WriteLinkReport(const char *filename);
    void WritePcaGroupCorr(const char *filename);
    void WriteAxisLoadTable(const char *filename);
    void WriteAverageAxisTable(const char *filename);
    void WriteVersionRetest(const char *filename);
    void WriteWiki(const char *filename, long double threshold, long double intercorr);
    void WriteQuizWiki(const char *filename);
    void MoveWiki(const char *fromwiki, const char *towiki, long double threshold);
	void WritePca(const char *filename);
	void WriteWeighting(const char *filename);
	void WriteGroupWeighting(const char *filename);
	void WritePhpWeighting(const char *filename);
	void WritePhpGroupWeighting(const char *filename);

	void WriteGlobalCorrelation(const char *filename, int count);
    void WriteWikiCorrelation(const char *wiki, const char *filename, int count);
    void WriteWikiNoncorrelated(const char *wiki, const char *filename, int count);

    static void PrintGlobalCorrelation(int q1, int q2);
        
    static void WikiToQuiz(const char *wikifile, const char *quizfile);

    static void WriteDsmReport(const char *filename, int PopType);

    static void ExportBirthMonthHistogram(const char *filename);

    void ExportHistogram(const char *filename, int PopType, int Width, int All);
    void ExportDiffHistogram(const char *filename, int PopType);

	void OptimizeAsWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);

    virtual int IsSubQuiz();

	virtual void ImportMvsp(const char *filename, int PcaType) = 0;
	virtual void ImportMvspAspie(const char *filename);
	virtual void ExportExcelCase(const char *filename, int PcaType) = 0;
	virtual void ExportExcelAspie(const char *filename) = 0;

	virtual void WriteIQ(const char *filename);
	virtual void WriteHair(const char *filename);
	virtual void WriteEye(const char *filename);
    virtual void WriteRace(const char *filename);
    virtual void WriteStim(const char *filename);
    virtual void WriteABO(const char *filename);
    virtual void WriteParkinson(const char *filename);
    virtual void WriteAlzheimer(const char *filename);
    virtual void WriteCFTR(const char *filename);
    virtual void WriteHFE(const char *filename);
    virtual void WriteLeiden(const char *filename);
    virtual void WriteRetest(const char *filename);
    virtual void WriteAQ(const char *filename);
    virtual void WriteSPQ(const char *filename);
    virtual void WriteLSAS(const char *filename);
    virtual void WriteMDQ(const char *filename);
    virtual void WritePictureRating(const char *filename);

    void WritePhpGlobalQuestions(const char *filename);

	void CheckCross();

	void WritePhpQuestions(const char *filename); 
	void WriteSetupTexts(const char *filename); 
	void WriteSetupCross(const char *filename); 

    void CalcGlobal();

    void ExportGlobalSql(const char *filename);
    void ExportQuizVerSql(const char *filename);
    void ExportGroupSql(const char *filename);
    void ExportPopTypeSql(const char *filename);
	void ExportGlobalCorrSql(const char *filename);
    void ExportGlobalAxisSql(const char *filename);
    void ExportQuizCatPopSql(const char *filename);
    void ExportQuizGlobalSql(const char *filename);

protected:
	void Init();
	static int round(long double val);
    static long double GetCutoffChi2(int cats, long double p);

    const char *GetGlobalQuestionText(int GlobalId);
	
    int CalcAsNtDiff(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS], int *AsDiff, int *NtDiff);
    int OptimizeAsOne(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);
    void WriteAsWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);
    void WriteWikiWeights(int Asw[MAX_QUESTIONS], int Ntw[MAX_QUESTIONS]);

    static void WriteDsmReport(TFile &File, TDsmPopulation &DsmPop);

	virtual void GetReferer(const char *referer, TPopulation *pop) = 0;
	virtual void WriteName(TFile &File) = 0;
	virtual void WriteLongName(TFile &File) = 0;
	virtual int GetPcaCount();
	virtual int GetCatCount(int Question);
	virtual int GetQuizN();

    int GetQuizId(TQuiz *quiz);

    TPopulation *GetPop(int PopType);
    void DefineCross(int id, TQuiz *quiz);
    void DefineGlobalId(int Id, int GlobalId);
    TReferer *FindReferer(char *Referer);
    TReferer *AddReferer(char *Search, char *Ref);
    void SortReferers();
    void CalcAspieNtCorr();
    void Calculate();
    void DefineCross(TQuiz *quiz, int MyQuestion, int CrossQuestion);

    int GetGlobalId(int question);
    
    void DefineID(int Question, int GlobalID);
    void DefineText(int Question, const char *Text, int Group);
    void RedefineText(int Question, int GlobalId, const char *Text);
    
    void ClearUsed();
    void ClearUsed(int Question);
    TQuiz *GetTopQuizCorr(int *Question);
    TQuiz *GetTopGroupCorr(int Group, int *Question);
    TQuiz *GetHighestCorr(int MyQuestion, int *Question);

    void DefineNt(char *Referer);
    void DefineAspie(char *Referer);

    void UpdateReferer(TReferer *ref, int AsResult, int NtResult, int GroupResult[12]);
    void UpdateReferer(TReferer *ref, int Result);

    void WriteFieldHeader(TFile &File, int RelWidth);
    void WriteCenteredFieldHeader(TFile &File, int RelWidth);
    void WriteRightFieldHeader(TFile &File, int RelWidth);
    void WriteFieldFooter(TFile &File);

    void WriteStaple(TFile &File, TPopulation *pop, int Question);
    void WriteCI95(TFile &File, TPopulation *pop, int Question);
	void WriteCorr95(TFile &File, long double corr, int count);
	void WriteCorrVal(TFile &File, long double corr, int count);
    void WriteChi2(TFile &File, long double chi2);
    void WriteP(TFile &File, int cats, long double chi2);
    void WritePca(TFile &File, long double pca);
    static void WritePcaPopCorr(TFile &File, TQuiz *quiz, int PopType, int PcaNr);
    void WritePcaCorrRow(TFile &File, const char *comment, int PopType);
	void WriteReferer(TFile &file, TReferer *ref);
    void WriteCorrTable(const char *filename, const char *name1, const char *name2, TPopulation *pop1, TPopulation *pop2, long double p);

    void WriteLinkQuestion(TFile *file, int Question, int GlobalId);
    void WriteLinkGroup(TFile *file, int Group);

    void WriteAsCI95(TFile &File, int Question);
    void WriteNtCI95(TFile &File, int Question);
    void WriteAsNtChi2(TFile &File, int Question);
    void WriteAsNtCorr95(TFile &File, int Question);

    void ExportOneCatPopSql(TFile &file, TQuiz *quiz, int id, int q, int poptype);
    void ExportOneQuizCatPopSql(TFile &file, TQuiz *quiz, int id);

	TPopulationCorrelation PopCorr;

    TPopulation All;
    TPopulation Autism;
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
    TPopulation AspieControl;
    TPopulation YoungMale;
    TPopulation YoungFemale;
    TPopulation Mix;
    TPopulation MixMale;
    TPopulation MixFemale;
	TPopulation Nt;
	TPopulation NtMale;
    TPopulation NtFemale;    
    TPopulation NtControl;
    TPopulation Ts;
    TPopulation Hyperlexia;
    TPopulation Dyspraxia;
    TPopulation Dyslexia;
    TPopulation Dyscalculia;
    TPopulation OCD;
    TPopulation ODD;
    TPopulation Synaesthesia;
    TPopulation PA;
    TPopulation Dysgraphia;
    TPopulation Bipolar;
    TPopulation Schizophrenia;
    TPopulation SocialPhobia;
    TPopulation LowIQ;
    TPopulation HighIQ;

    static TBirthMonth BirthMonth;
    
    static TDsmPopulation DsmAutism;
    static TDsmPopulation DsmAs;
    static TDsmPopulation DsmAdd;
    static TDsmPopulation DsmTs;
    static TDsmPopulation DsmHyperlexia;
    static TDsmPopulation DsmDyspraxia;
    static TDsmPopulation DsmDyslexia;
    static TDsmPopulation DsmDyscalculia;
    static TDsmPopulation DsmOCD;
    static TDsmPopulation DsmODD;
    static TDsmPopulation DsmSynaesthesia;
    static TDsmPopulation DsmPA;
    static TDsmPopulation DsmDysgraphia;
    static TDsmPopulation DsmBipolar;
    static TDsmPopulation DsmSchizophrenia;
    static TDsmPopulation DsmSocialPhobia;
    
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
    TReferer SocialPhobiaRef;
    TReferer DyscalculiaRef;
    TReferer OCDRef;
    TReferer ODDRef;
    TReferer SynaesthesiaRef;
    TReferer PARef;
    TReferer DysgraphiaRef;
    TReferer BipolarRef;
    TReferer SchizophreniaRef;
    TReferer AmerindianRef;
    TReferer MixedAfroAmericanRef;
    TReferer AfroAmericanRef;
    TReferer AfricanRef;
    TReferer MixedAfricanRef;
    TReferer HispanicRef;
    TReferer WhiteRef;
    TReferer ArabRef;
    TReferer AsianRef;

    int FFirst;

    TQuiz *CrossQuiz[MAX_CROSS];

    int AspiePcaCount;
    int N;    
    int GroupValCount;
    TGroupValArr *GroupValArr;    
	TGroup Group[MAX_GROUP_COUNT];
	TGroupCorr GroupCorr[MAX_GROUP_COUNT][MAX_GROUP_COUNT];
	TAxis Axis[MAX_ASPIE_PCA_AXIS];
	TQuizQuestion Quiz[MAX_QUESTIONS];
    TUserInfo *UserInfo[MAX_USERS];

};

#endif
