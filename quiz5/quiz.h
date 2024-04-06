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

#include "file.h"

#define M_PI   3.141592653589793

#define MAX_GROUP_COUNT         15

#define GROUP_COUNT             11

#define GROUP_NOT_USED          -1
#define GROUP_ASPIE_TALENT      0
#define GROUP_NT_TALENT         1
#define GROUP_ASPIE_SENSORY     2
#define GROUP_NT_SENSORY        3
#define GROUP_ASPIE_NVC         4
#define GROUP_NT_NVC            5
#define GROUP_ASPIE_RELATION    6
#define GROUP_NT_RELATION       7
#define GROUP_ASPIE_SOCIAL      8
#define GROUP_NT_SOCIAL         9
#define GROUP_MIXED             10

#define MAX_QUESTIONS           300

class TQuiz;
class TQuizItem;
class TQuizGroup;

struct TQuizRow
{
    long ID;
    long UserID;
    long LsbTime;
    long MsbTime;
    long FilloutTime;
    int  BirthYear;
    int  BirthMonth;
    char Sex;
    char Gender;
    int Country;
    int Ancestry;
    char Aspie;
    char ADHD;
    char OCD;
    char Social;
    long Score;
    long double P;
    char Quiz[MAX_QUESTIONS];
};

class TQuizGroup
{
public:
    TQuizGroup(int number, const char *pos, const char *neg);
    ~TQuizGroup();

    void Add(int sex, double p, char *value, TQuizItem **item, int count);
    void InitDone1();

    void Update(int sex, double p, char *value, TQuizItem **item, int count);
    void InitDone2();

    const char *PosName;
    const char *NegName;

    int Questions;
    int Nr;

    double MaleAtypicalMean;
    double MaleTypicalMean;
    double FemaleAtypicalMean;
    double FemaleTypicalMean;

    double Sd;

protected:
    int Count;

    double NaMaleCount;
    double NtMaleCount;
    double NaFemaleCount;
    double NtFemaleCount;

    double NaMaleSum;
    double NtMaleSum;
    double NaFemaleSum;
    double NtFemaleSum;
};

class TQuizItem
{
public:
    TQuizItem(int number, int catcount);
    ~TQuizItem();

    void Add(int sex, double p, int value);
    void InitDone1();

    void Update(int sex, double p, char *value, TQuizItem **item, int count);
    void InitDone2();

    void Update(int sex, double p, char *value, TQuizGroup **group, TQuizItem **item, int count);
    void InitDone3(TQuizGroup **group, TQuizItem **item, int count);

    double GetNoAnswer();

    bool IsReversed();
    char ConvGroupChoice(char val);
    double GetDiff();

    const char *Text;
    int MyGroup;

    int Nr;
    int CatCount;

    double MaleAtypicalMean;
    double MaleTypicalMean;
    double FemaleAtypicalMean;
    double FemaleTypicalMean;

    double Sd;
    double Corr[MAX_QUESTIONS];
    double GroupCorr[GROUP_COUNT];

protected:
    double ConvGroupMean(TQuizGroup *group, double gmean, double imean);

    void Update(int sex, double p, char value);
    void Update(int sex, double p, char myval, char value, TQuizItem *item);
    void Update(int sex, double p, char myval, int gval, TQuizGroup *group);

    int NoAnswer;
    int Count;
    bool Reverse;

    int CountArr[MAX_QUESTIONS];
    double Cov[MAX_QUESTIONS];
    int GroupCountArr[GROUP_COUNT];
    double GroupCov[GROUP_COUNT];

    double NaMaleCount;
    double NtMaleCount;
    double NaFemaleCount;
    double NtFemaleCount;

    double NaMaleSum;
    double NtMaleSum;
    double NaFemaleSum;
    double NtFemaleSum;
};

class TQuiz
{
public:
    TQuiz(int questions);
    ~TQuiz();

    void Analyse();

    void WriteNoAnswerStats(const char *filename);
    void WriteSumaryTable(const char *filename);
    void WriteIntercorr(const char *filename);
    void WriteGroupCorrTable(const char *filename);

    void ExportToPhp(const char *filename);

protected:
    double CalcNorm(double x, double u, double sd, double scale);
    void CalcProbArr(double u, double sd);
    void AddRow(TQuizRow *Row);

    virtual void Load() = 0;
    virtual void WriteName(TFile &File) = 0;
    virtual void WriteLongName(TFile &File) = 0;
    virtual int GetCatCount(int Question);
    virtual int GetQuizN();

    void WriteFieldHeader(TFile &File, int RelWidth);
    void WriteCenteredFieldHeader(TFile &File, int RelWidth);
    void WriteRightFieldHeader(TFile &File, int RelWidth);
    void WriteFieldFooter(TFile &File);

    int N;

    TQuizGroup **GroupArr;
    TQuizItem **ItemArr;

    double ProbArr[201];

    int Stage;
};

#endif
