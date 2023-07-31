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

#define MAX_QUESTIONS           250

class TQuiz;

struct TQuizGroup
{
    long double Corr;
    int Count;
};

struct TQuizRow
{
    long ID;
    long UserID;
    long LsbTime;
    long MsbTime;
    long FilloutTime;
    int  BirthYear;
    int  BirthMonth;
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

struct TQuizQuestion
{
    const char *Text;
    int AsCount;
    long double AsMean;
    long double AsSd;
    int NtCount;
    long double NtMean;
    long double NtSd;

    int Count;
    long double Sum;
    int Used;
    int NoAnswer;
    int MyGroup;
    bool Reverse;

    TQuizGroup Group[MAX_GROUP_COUNT];
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

class TQuiz
{
public:
    TQuiz(int questions);
    ~TQuiz();

    virtual void Load() = 0;

    void WriteNoAnswerStats(const char *filename);
    void WriteSumaryTable(const char *filename, int OnlyMixed);
    void WriteIntercorr(const char *filename);
    void WriteGroupCorrTable(const char *filename);

protected:
    void DefineText(int Question, const char *Text, int Group);
    void AddRow(TQuizRow *Row);

    void Init();
    virtual void WriteName(TFile &File) = 0;
    virtual void WriteLongName(TFile &File) = 0;
    virtual int GetCatCount(int Question);
    virtual int GetQuizN();

    void WriteFieldHeader(TFile &File, int RelWidth);
    void WriteCenteredFieldHeader(TFile &File, int RelWidth);
    void WriteRightFieldHeader(TFile &File, int RelWidth);
    void WriteFieldFooter(TFile &File);

    int N;
    int GroupValCount;
    TGroupValArr *GroupValArr;
    TGroup Group[MAX_GROUP_COUNT];
    TGroupCorr GroupCorr[MAX_GROUP_COUNT][MAX_GROUP_COUNT];
    TQuizQuestion Quiz[MAX_QUESTIONS];

    int ValueCount;
    int ValueSize;
    TQuizRow **ValueArr;
};

#endif
