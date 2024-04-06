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

#define MAX_IN_ROW 4096

#include "quiz.h"
#include "file.h"
#include "str.h"

static double r2pi = sqrt(2.0 * 3.14159265358979323846);

/*##########################################################################
#
#   Name       : TQuizGroup::TQuizGroup
#
#   Purpose....: Constructor for TQuizGroup
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizGroup::TQuizGroup(int number, const char *pos, const char *neg)
{
    Nr = number;
    PosName = pos;
    NegName = neg;

    Count = 0;
    Sd = 0.0;

    NaMaleCount = 0.0;
    NtMaleCount = 0.0;
    NaFemaleCount = 0.0;
    NtFemaleCount = 0.0;

    NaMaleSum = 0.0;
    NtMaleSum = 0.0;
    NaFemaleSum = 0.0;
    NtFemaleSum = 0.0;
}

/*##########################################################################
#
#   Name       : TQuizGroup::~TQuizGroup
#
#   Purpose....: Destructor for TQuizGroup
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizGroup::~TQuizGroup()
{
}

/*##########################################################################
#
#   Name       : TQuizGroup::Add
#
#   Purpose....: Add data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizGroup::Add(int sex, double p, char *value, TQuizItem **item, int count)
{
    int i;
    char val;
    double dval = 0.0;
    double p1 = 1.0 - p;
    double diff;

    for (i = 0; i < count; i++)
    {
        if (item[i]->MyGroup == Nr)
        {
            val = value[i];

            if (val)
                dval += (double)item[i]->ConvGroupChoice(val);
            else
                return;
        }
    }

    switch (sex)
    {
        case 1:
            NaMaleCount += p;
            NtMaleCount += p1;
            NaMaleSum += p * dval;
            NtMaleSum += p1 * dval;
            break;

        case 2:
            NaFemaleCount += p;
            NtFemaleCount += p1;
            NaFemaleSum += p * dval;
            NtFemaleSum += p1 * dval;
            break;
    }
}

/*##########################################################################
#
#   Name       : TQuizGroup::InitDone1
#
#   Purpose....: Init stage 1 done
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizGroup::InitDone1()
{
    MaleAtypicalMean = NaMaleSum / NaMaleCount;
    FemaleAtypicalMean = NaFemaleSum / NaFemaleCount;
    MaleTypicalMean = NtMaleSum / NtMaleCount;
    FemaleTypicalMean = NtFemaleSum / NtFemaleCount;
}

/*##########################################################################
#
#   Name       : TQuizGroup::Update
#
#   Purpose....: Update data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizGroup::Update(int sex, double p, char *value, TQuizItem **item, int count)
{
    int i;
    char val;
    double dval = 0.0;
    double diff;

    for (i = 0; i < count; i++)
    {
        if (item[i]->MyGroup == Nr)
        {
            val = value[i];

            if (val)
                dval += (double)item[i]->ConvGroupChoice(val);
            else
                return;
        }
    }

    Count++;

    switch (sex)
    {
        case 1:
            diff = dval - MaleAtypicalMean;
            break;

        case 2:
            diff = dval - FemaleAtypicalMean;
            break;
    }

    diff = diff * diff * p;
    Sd += diff;

    switch (sex)
    {
        case 1:
            diff = dval - MaleTypicalMean;
            break;

        case 2:
            diff = dval - FemaleTypicalMean;
            break;
    }

    diff = diff * diff * (1.0 - p);
    Sd += diff;
}

/*##########################################################################
#
#   Name       : TQuizGroup::InitDone2
#
#   Purpose....: Init stage 2 done
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizGroup::InitDone2()
{
    Sd = sqrt(Sd / (double)(Count - 1));
}

/*##########################################################################
#
#   Name       : TQuizItem::TQuizItem
#
#   Purpose....: Constructor for TQuizItem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizItem::TQuizItem(int number, int catcount)
{
    int i;

    Text = "NO TEXT";
    MyGroup = GROUP_MIXED;
    Reverse = false;
    Nr = number;
    CatCount = catcount;

    NoAnswer = 0;
    Count = 0;
    Sd = 0.0;

    for (i = 0; i < MAX_QUESTIONS; i++)
    {
        Cov[i] = 0.0;
        CountArr[i] = 0;
    }

    for (i = 0; i < GROUP_COUNT; i++)
    {
        GroupCov[i] = 0.0;
        GroupCountArr[i] = 0;
    }

    NaMaleCount = 0.0;
    NtMaleCount = 0.0;
    NaFemaleCount = 0.0;
    NtFemaleCount = 0.0;

    NaMaleSum = 0.0;
    NtMaleSum = 0.0;
    NaFemaleSum = 0.0;
    NtFemaleSum = 0.0;
}

/*##########################################################################
#
#   Name       : TQuizItem::~TQuizItem
#
#   Purpose....: Destructor for TQuizItem
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizItem::~TQuizItem()
{
}

/*##########################################################################
#
#   Name       : TQuizItem::Add
#
#   Purpose....: Add data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::Add(int sex, double p, int value)
{
    double dval;
    double p1 = 1.0 - p;

    if (value)
    {
        Count++;
        dval = (double)(value - 1);

        switch (sex)
        {
            case 1:
                NaMaleCount += p;
                NtMaleCount += p1;
                NaMaleSum += p * dval;
                NtMaleSum += p1 * dval;
                break;

            case 2:
                NaFemaleCount += p;
                NtFemaleCount += p1;
                NaFemaleSum += p * dval;
                NtFemaleSum += p1 * dval;
                break;
        }
    }
    else
        NoAnswer++;
}

/*##########################################################################
#
#   Name       : TQuizItem::InitDone1
#
#   Purpose....: Init stage 1 done
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::InitDone1()
{
    MaleAtypicalMean = NaMaleSum / NaMaleCount;
    FemaleAtypicalMean = NaFemaleSum / NaFemaleCount;
    MaleTypicalMean = NtMaleSum / NtMaleCount;
    FemaleTypicalMean = NtFemaleSum / NtFemaleCount;

    if (GetDiff() < 0.0)
        Reverse = true;
    else
        Reverse = false;
}

/*##########################################################################
#
#   Name       : TQuizItem::Update
#
#   Purpose....: Update data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::Update(int sex, double p, char value)
{
    double dval;
    double diff;

    if (value)
    {
        dval = (double)(value - 1);

        switch (sex)
        {
            case 1:
                diff = dval - MaleAtypicalMean;
                break;

            case 2:
                diff = dval - FemaleAtypicalMean;
                break;
        }

        diff = diff * diff * p;
        Sd += diff;

        switch (sex)
        {
            case 1:
                diff = dval - MaleTypicalMean;
                break;

            case 2:
                diff = dval - FemaleTypicalMean;
                break;
        }

        diff = diff * diff * (1.0 - p);
        Sd += diff;
    }
}

/*##########################################################################
#
#   Name       : TQuizItem::Update
#
#   Purpose....: Update data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::Update(int sex, double p, char myval, char value, TQuizItem *item)
{
    int other = item->Nr;
    double mval;
    double oval;
    double mdiff;
    double odiff;

    if (myval && value)
    {
        CountArr[other]++;

        mval = (double)(myval - 1);
        oval = (double)(value - 1);

        switch (sex)
        {
            case 1:
                mdiff = mval - MaleAtypicalMean;
                odiff = oval - item->MaleAtypicalMean;
                break;

            case 2:
                mdiff = mval - FemaleAtypicalMean;
                odiff = oval - item->FemaleAtypicalMean;
                break;
        }

        Cov[other] += mdiff * odiff * p;

        switch (sex)
        {
            case 1:
                mdiff = mval - MaleTypicalMean;
                odiff = oval - item->MaleTypicalMean;
                break;

            case 2:
                mdiff = mval - FemaleTypicalMean;
                odiff = oval - item->FemaleTypicalMean;
                break;
        }

        Cov[other] += mdiff * odiff * (1.0 - p);
    }
}

/*##########################################################################
#
#   Name       : TQuizItem::Update
#
#   Purpose....: Update data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::Update(int sex, double p, char *value, TQuizItem **item, int count)
{
    int i;

    Update(sex, p, value[Nr]);

    for (i = 0; i < count; i++)
        Update(sex, p, value[Nr], value[i], item[i]);
}

/*##########################################################################
#
#   Name       : TQuizItem::IsReversed
#
#   Purpose....: Check if reversed
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TQuizItem::IsReversed()
{
    return Reverse;
}

/*##########################################################################
#
#   Name       : TQuizItem::GetDiff
#
#   Purpose....: Get average neurotype diff
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TQuizItem::GetDiff()
{
    return (MaleAtypicalMean - MaleTypicalMean + FemaleAtypicalMean - FemaleTypicalMean) / 2.0;
}

/*##########################################################################
#
#   Name       : TQuizItem::ConvGroupChoice
#
#   Purpose....: Convert group choice
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TQuizItem::ConvGroupChoice(char val)
{
    if (Reverse)
        return CatCount - val;
    else
        return val - 1;
}

/*##########################################################################
#
#   Name       : TQuizItem::ConvGroupMean
#
#   Purpose....: Convert group mean
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TQuizItem::ConvGroupMean(TQuizGroup *group, double gmean, double imean)
{
    if (MyGroup == group->Nr)
    {
        if (Reverse)
            return gmean - (2.0 - imean);
        else
            return gmean - imean;
    }
    else
        return gmean;
}

/*##########################################################################
#
#   Name       : TQuizItem::Update
#
#   Purpose....: Update data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::Update(int sex, double p, char myval, int gvalue, TQuizGroup *group)
{
    double mval;
    double gval;
    double mdiff;
    double gdiff;
    int grp = group->Nr;

    GroupCountArr[grp]++;

    mval = (double)myval;
    gval = (double)gvalue;

    switch (sex)
    {
        case 1:
            mdiff = mval - MaleAtypicalMean;
            gdiff = gval - ConvGroupMean(group, group->MaleAtypicalMean, MaleAtypicalMean);
            break;

        case 2:
            mdiff = mval - FemaleAtypicalMean;
            gdiff = gval - ConvGroupMean(group, group->FemaleAtypicalMean, FemaleAtypicalMean);
            break;
    }

    GroupCov[grp] += mdiff * gdiff * p;

    switch (sex)
    {
        case 1:
            mdiff = mval - MaleTypicalMean;
            gdiff = gval - ConvGroupMean(group, group->MaleTypicalMean, MaleTypicalMean);
            break;

        case 2:
            mdiff = mval - FemaleTypicalMean;
            gdiff = gval - ConvGroupMean(group, group->FemaleTypicalMean, FemaleTypicalMean);
            break;
    }

    GroupCov[grp] += mdiff * gdiff * (1.0 - p);
}

/*##########################################################################
#
#   Name       : TQuizItem::Update
#
#   Purpose....: Update data point
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::Update(int sex, double p, char *value, TQuizGroup **group, TQuizItem **item, int count)
{
    int i;
    int g;
    char val;
    bool ok;
    char mval;
    int gval;

    if (value[Nr])
    {
        mval = ConvGroupChoice(value[Nr]);

        for (g = 0; g < GROUP_COUNT; g++)
        {
            ok = true;
            gval = 0;

            for (i = 0; i < count && ok; i++)
            {
                if (item[i]->MyGroup == g)
                {
                    val = value[i];

                    if (val)
                    {
                        if (i != Nr)
                            gval += item[i]->ConvGroupChoice(val);
                    }
                    else
                        ok = false;
                }
            }

            if (ok)
                Update(sex, p, mval, gval, group[g]);
        }
    }
}

/*##########################################################################
#
#   Name       : TQuizItem::InitDone2
#
#   Purpose....: Init stage 2 done
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::InitDone2()
{
    Sd = sqrt(Sd / (double)(Count - 1));
}

/*##########################################################################
#
#   Name       : TQuizItem::InitDone3
#
#   Purpose....: Init stage 3 done
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizItem::InitDone3(TQuizGroup **group, TQuizItem **item, int count)
{
    int i;
    int g;

    for (i = 0; i < count; i++)
    {
        Cov[i] = Cov[i] / (double)(CountArr[i] - 1);
        Corr[i] = Cov[i] / Sd / item[i]->Sd;
    }

    for (g = 0; g < GROUP_COUNT; g++)
    {
        GroupCov[g] = GroupCov[g] / (double)(GroupCountArr[g] - 1);
        GroupCorr[g] = GroupCov[g] / Sd / group[g]->Sd;
    }
}

/*##########################################################################
#
#   Name       : TQuizItem::GetNoAnswer
#
#   Purpose....: Get no answer proportion
#
#   In params..:
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TQuizItem::GetNoAnswer()
{
    return (double)NoAnswer / (double)(NoAnswer + Count);
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
TQuiz::TQuiz(int Questions)
{
    int i;

    N = Questions;

    CalcProbArr(28.4, 28.0);
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

    for (i = 0; i < N; i++)
        delete ItemArr[i];

    delete ItemArr;

    for (i = 0; i < GROUP_COUNT; i++)
        delete GroupArr[i];

    delete GroupArr;
}

/*##################  TQuiz::Init ##########################
*   Purpose....: Init quiz                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::Init()
{
    int i;

    ItemArr = new TQuizItem*[N];

    for (i = 0; i < N; i++)
        ItemArr[i] = new TQuizItem(i, GetCatCount(i));

    GroupArr = new TQuizGroup*[GROUP_COUNT];

    GroupArr[GROUP_ASPIE_TALENT] = new TQuizGroup(GROUP_ASPIE_TALENT,  "Atypical ability", "Atypical ability problem");
    GroupArr[GROUP_NT_TALENT] = new TQuizGroup(GROUP_NT_TALENT,  "Typical ability problem", "Typical ability");

    GroupArr[GROUP_ASPIE_SENSORY] = new TQuizGroup(GROUP_ASPIE_SENSORY,  "Atypical sensory", "Atypical sensory problem");
    GroupArr[GROUP_NT_SENSORY] = new TQuizGroup(GROUP_NT_SENSORY,  "Typical sensory problem", "Typical sensory");

    GroupArr[GROUP_ASPIE_NVC] = new TQuizGroup(GROUP_ASPIE_NVC,  "Atypical communication", "Atypical communication problem");
    GroupArr[GROUP_NT_NVC] = new TQuizGroup(GROUP_NT_NVC,  "Typical communication problem", "Typical communication");

    GroupArr[GROUP_ASPIE_RELATION] = new TQuizGroup(GROUP_ASPIE_RELATION,  "Atypical relationship", "Atypical relationship problem");
    GroupArr[GROUP_NT_RELATION] = new TQuizGroup(GROUP_NT_RELATION,  "Typical relationship problem", "Typical relationship");

    GroupArr[GROUP_ASPIE_SOCIAL] = new TQuizGroup(GROUP_ASPIE_SOCIAL,  "Atypical social", "Atypical social problem");
    GroupArr[GROUP_NT_SOCIAL] = new TQuizGroup(GROUP_NT_SOCIAL,  "Typical social problem", "Typical social");

    GroupArr[GROUP_MIXED] = new TQuizGroup(GROUP_MIXED,  "Atypical mixed", "Typical mixed");

    SetupTexts();
}

/*##################  TQuiz::CalcNorm ##########################
*   Purpose....: Calculate normal distribution                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
double TQuiz::CalcNorm(double x, double u, double sd, double scale)
{
    double temp;

    temp = (x - u) / sd;
    temp = -0.5 * temp * temp;
    temp = exp(temp);
    temp = temp * scale;

    return temp;
}

/*##################  TQuiz::CalcProbArr ##########################
*   Purpose....: Calculate ND & NT probability                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::CalcProbArr(double u, double sd)
{
    int i;
    double ndp[201];
    double ntp[201];
    double sum;
    double val;
    double x;
    double scale = 1.0 / sd / r2pi;

    sum = 0.0;
    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, 100 + u, sd, scale);
        sum += val;
        ndp[i] = sum;
    }

    sum = 0.0;
    for (i = 200; i >= 0; i--)
    {
        x = (double)i;
        val = CalcNorm(x, 100 - u, sd, scale);
        sum += val;
        ntp[i] = sum;
    }

    for (i = 0; i < 201; i++)
    {
        sum = ndp[i] + ntp[i];
        ProbArr[i] = ndp[i] / sum;
    }
}

/*##################  TQuiz::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::GetCatCount(int Question)
{
    return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive questions)                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::GetQuizN()
{
    return N;
}

/*##################  TQuiz::WriteNoAnswerStats ##########################
*   Purpose....: Write unanswered item stats                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteNoAnswerStats(const char *filename)
{
}

/*##################  TQuiz::WriteFieldHeader ##########################
*   Purpose....: Write field header for table                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

    File.Write("<p>\n");
    File.Write("<b>\n");
}

/*##################  TQuiz::WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

    File.Write("<p align=\"center\">\n");
    File.Write("<b>\n");
}

/*##################  TQuiz::WriteRightFieldHeader ##########################
*   Purpose....: Write right-aligned field header for table                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteRightFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

    File.Write("<p align=\"right\">\n");
    File.Write("<b>\n");
}

/*##################  TQuiz::WriteFieldFooter ##########################
*   Purpose....: Write field footer for table                                           #
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

/*##################  TQuiz::WriteSumaryTable ##########################
*   Purpose....: Write sumary table                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteSumaryTable(const char *filename)
{
    int i;
    int j;
    char str[80];
    int ival;
    TFile file(filename, 0);

    file.Write("<table border=3 cellspacing=0 cellpadding=0>");

    j = 0;

    for (i = 0; i < N; i++)
    {
        if (j % 10 == 0)
        {
            file.Write("<tr style='height:24.75pt'>");

            WriteCenteredFieldHeader(file, 5);
            file.Write("#");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 60);
            file.Write(" ");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
            file.Write("?");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
            file.Write("Atypical male");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
            file.Write("Atypical female");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
            file.Write("Typical male");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
            file.Write("Typical female");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
            file.Write("Male");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 5);
            file.Write("Female");
            WriteFieldFooter(file);

            file.Write("</tr>");
        }

        j++;

        file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%d", i + 1);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 60);
        file.Write(ItemArr[i]->Text);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%5.1Lf%%", 100.0 * ItemArr[i]->GetNoAnswer());
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%5.3Lf", ItemArr[i]->MaleAtypicalMean);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%5.3Lf", ItemArr[i]->FemaleAtypicalMean);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%5.3Lf", ItemArr[i]->MaleTypicalMean);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%5.3Lf", ItemArr[i]->FemaleTypicalMean);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%5.3Lf", ItemArr[i]->MaleAtypicalMean - ItemArr[i]->MaleTypicalMean);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%5.3Lf", ItemArr[i]->FemaleAtypicalMean - ItemArr[i]->FemaleTypicalMean);
        file.Write(str);
        WriteFieldFooter(file);

        file.Write("</tr>");
    }

    file.Write("</table>");
}

/*##################  TQuiz::WriteGroupCorrTable ##########################
*   Purpose....: Write group correlation table                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteGroupCorrTable(const char *filename)
{
    int i;
    int g;
    int q;
    double Max;
    double Val;
    bool Used[MAX_QUESTIONS];
    double *CorrArr;
    char str[80];
    TFile file(filename, 0);

    file.Write("<h2>Grouped results</h2>\n");
    file.Write("<span style='color:#990099'>");
    file.Write("Reversed score questions are showed in red color");
    file.Write("</span><br>");

    file.Write("<span style='color:#009999'>");
    file.Write("High correlation is light blue");
    file.Write("</span><br>");

    file.Write("Correlations are calculated against other questions in the group, not including the current question<br>");
    file.Write("Each group is sorted so the highest neurotype diff comes first<br><br>");

    for (g = 0; g < GROUP_COUNT; g++)
    {
        file.Write("<table border=3 cellspacing=0 cellpadding=0>");

        file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 3);
        sprintf(str, "G:%d", g + 1);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 24);
        file.Write(GroupArr[g]->PosName);
        file.Write(" / ");
        file.Write(GroupArr[g]->NegName);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
        file.Write("Male");
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 3);
        file.Write("Female");
        WriteFieldFooter(file);

        for (i = 0; i < GROUP_COUNT - 1; i++)
        {
            WriteFieldHeader(file, 4);
            sprintf(str, "G:%d", i + 1);
            file.Write(str);
            WriteFieldFooter(file);
        }

        file.Write("</tr>");

        Max = 0.0;
        q = -1;

        for (i = 0; i < N; i++)
        {
            if (ItemArr[i]->MyGroup == g)
            {
                Val = ItemArr[i]->GetDiff();
                Val = Val * Val;
                if (Val > Max)
                {
                    Max = Val;
                    q = i;
                }
                Used[i] = false;
            }
            else
                Used[i] = true;
        }

        while (q >= 0)
        {
            Used[q] = true;

            file.Write("<tr style='height:24.75pt'>");

            WriteCenteredFieldHeader(file, 3);
            sprintf(str, "%d", q + 1);
            file.Write(str);

            WriteCenteredFieldHeader(file, 24);
            if (ItemArr[q]->IsReversed())
                file.Write("<span style='color:#990099'>");
            file.Write(ItemArr[q]->Text);
            if (ItemArr[q]->IsReversed())
                file.Write("</span>");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 3);
            sprintf(str, "%5.3Lf", ItemArr[q]->MaleAtypicalMean - ItemArr[q]->MaleTypicalMean);
            file.Write(str);
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 3);
            sprintf(str, "%5.3Lf", ItemArr[q]->FemaleAtypicalMean - ItemArr[q]->FemaleTypicalMean);
            file.Write(str);
            WriteFieldFooter(file);

            Max = 0.0;

            CorrArr = ItemArr[q]->GroupCorr;
            for (i = 0; i < GROUP_COUNT - 1; i++)
                if (CorrArr[i] > Max)
                    Max = CorrArr[i];

            for (i = 0; i < GROUP_COUNT - 1; i++)
            {
                Val = CorrArr[i];

                WriteCenteredFieldHeader(file, 4);

                if (Val >= 0.15)
                {
                    if (Val > 0.9 * Max)
                        file.Write("<span style='color:#009999'>");

                    sprintf(str, "%4.2Lf", Val);
                    file.Write(str);

                    if (Val > 0.9 * Max)
                        file.Write("</span>");
                }
                else
                    file.Write(" ");

                WriteFieldFooter(file);
            }

            file.Write("</tr>");

            Max = 0.0;
            q = -1;

            for (i = 0; i < N; i++)
            {
                if (!Used[i])
                {
                    Val = ItemArr[i]->GetDiff();
                    Val = Val * Val;
                    if (Val > Max)
                    {
                        Max = Val;
                        q = i;
                    }
                }
            }
        }
    }
    file.Write("</table>");
    file.Write("<br><br>");
}

/*##################  TQuiz::WriteIntercorr ##########################
*   Purpose....: Write intercorrelation report for quiz                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteIntercorr(const char *filename)
{
    int i;
    int j;
    double *CorrArr;
    double MaxCorr;
    double Val;
    int MaxInd;
    int count;
    int missing;
    bool Used[MAX_QUESTIONS];
    char str[80];
    TFile file(filename, 0);

    file.Write("<h2>Between question correlations</h2>\n");

    for (i = 0; i < N; i++)
    {
        count = 0;
        missing = 0;

        file.Write("<b>");
        sprintf(str, "%d. ", i + 1);
        file.Write(str);
        file.Write(ItemArr[i]->Text);

        file.Write(" (Diff: ");

        sprintf(str, "%4.2Lf/", ItemArr[i]->MaleAtypicalMean - ItemArr[i]->MaleTypicalMean);
        file.Write(str);
        sprintf(str, "%4.2Lf,", ItemArr[i]->FemaleAtypicalMean - ItemArr[i]->FemaleTypicalMean);
        file.Write(str);

        sprintf(str, " Missing: %5.1Lf%%)", 100.0 * ItemArr[i]->GetNoAnswer());
        file.Write(str);

        file.Write("</b><ul>\r\n");

        CorrArr = ItemArr[i]->Corr;

        MaxCorr = 0.0;
        MaxInd = -1;

        for (j = 0; j < N; j++)
        {
            Val = CorrArr[j];
            if (Val < 0.0)
                Val = -Val;

            if (Val > MaxCorr)
            {
                MaxCorr = Val;
                MaxInd = j;
            }
            Used[j] = false;
        }

        while (MaxCorr >= 0.3)
        {
            if (count < 50)
            {
                count++;

                file.Write("<li>");
                sprintf(str, "%d. ", MaxInd + 1);
                file.Write(str);
                file.Write(ItemArr[MaxInd]->Text);

                file.Write(" (Diff: ");

                sprintf(str, "%4.2Lf/", ItemArr[MaxInd]->MaleAtypicalMean - ItemArr[MaxInd]->MaleTypicalMean);
                file.Write(str);
                sprintf(str, "%4.2Lf,", ItemArr[MaxInd]->FemaleAtypicalMean - ItemArr[MaxInd]->FemaleTypicalMean);
                file.Write(str);

                sprintf(str, " Missing: %5.1Lf%%)", 100.0 * ItemArr[MaxInd]->GetNoAnswer());
                file.Write(str);

                file.Write(" correlation: ");

                sprintf(str, "%5.2Lf", CorrArr[MaxInd]);
                file.Write(str);
                file.Write("</li>\r\n");
            }
            else
                missing++;

            Used[MaxInd] = true;

            MaxCorr = 0.0;
            MaxInd = -1;

            for (j = 0; j < N; j++)
            {
                if (!Used[j])
                {
                    Val = CorrArr[j];
                    if (Val < 0.0)
                        Val = -Val;

                    if (Val > MaxCorr)
                    {
                        MaxCorr = Val;
                        MaxInd = j;
                    }
                }
            }
        }

        if (missing)
        {
            sprintf(str, "<br><b>%d questions not listed</b>", missing);
            file.Write(str);
        }

        file.Write("</ul><br>\r\n\r\n");
    }
}

/*##################  TQuiz::ExportToPhp ##########################
*   Purpose....: Export items for new version                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::ExportToPhp(const char *filename)
{
    int nr = 0;
    int i;
    int g;
    int q;
    int w;
    double Max;
    double Val;
    bool Used[MAX_QUESTIONS];
    double *CorrArr;
    char str[80];
    TFile file(filename, 0);
    TString itemstr;
    TString malestr;
    TString femalestr;

    malestr += "\r\n";
    femalestr += "\r\n";

    for (g = 0; g < GROUP_COUNT; g++)
    {
        itemstr += "\r\n";

        switch (g)
        {
            case GROUP_ASPIE_TALENT:
                sprintf(str, " $h[%d] = \"Atypical talent\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 1;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_NT_TALENT:
                sprintf(str, " $h[%d] = \"Typical talent\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 2;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_ASPIE_SENSORY:
                sprintf(str, " $h[%d] = \"Atypical perception\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 3;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_NT_SENSORY:
                sprintf(str, " $h[%d] = \"Typical preception\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 4;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_ASPIE_NVC:
                sprintf(str, " $h[%d] = \"Atypical communication\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 5;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_NT_NVC:
                sprintf(str, " $h[%d] = \"Typical communication\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 6;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_ASPIE_RELATION:
                sprintf(str, " $h[%d] = \"Atypical relationships\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 7;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_NT_RELATION:
                sprintf(str, " $h[%d] = \"Typical relationships\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 8;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_ASPIE_SOCIAL:
                sprintf(str, " $h[%d] = \"Atypical social\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 9;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_NT_SOCIAL:
                sprintf(str, " $h[%d] = \"Typical social\";\r\n", nr);
                itemstr += str;

                sprintf(str, " $hg[%d] = 10;\r\n", nr);
                itemstr += str;
                break;

            case GROUP_MIXED:
                sprintf(str, " $h[%d] = \"Control\";\r\n", nr);
                itemstr += str;
                break;
        }

        itemstr += "\r\n";

        Max = 0.0;
        q = -1;

        for (i = 0; i < N; i++)
        {
            if (ItemArr[i]->MyGroup == g)
            {
                Val = ItemArr[i]->GetDiff();
                Val = Val * Val;
                if (Val > Max)
                {
                    Max = Val;
                    q = i;
                }
                Used[i] = false;
            }
            else
                Used[i] = true;
        }

        while (q >= 0)
        {
            Used[q] = true;

            sprintf(str, " $m[%d] = \"", nr);
            itemstr += str;
            itemstr += ItemArr[q]->Text;
            itemstr += "\";\r\n";

            Val = ItemArr[q]->MaleAtypicalMean - ItemArr[q]->MaleTypicalMean;
            w = (int)(1000.0 * Val);
            sprintf(str, " $mw[%d] = %d;\r\n", nr, w);
            malestr += str;

            Val = ItemArr[q]->FemaleAtypicalMean - ItemArr[q]->FemaleTypicalMean;
            w = (int)(1000.0 * Val);
            sprintf(str, " $fw[%d] = %d;\r\n", nr, w);
            femalestr += str;

            nr++;

            Max = 0.0;
            q = -1;

            for (i = 0; i < N; i++)
            {
                if (!Used[i])
                {
                    Val = ItemArr[i]->GetDiff();
                    Val = Val * Val;
                    if (Val > Max)
                    {
                        Max = Val;
                        q = i;
                    }
                }
            }
        }
    }

    file.Write(itemstr.GetData());
    file.Write(malestr.GetData());
    file.Write(femalestr.GetData());
}

/*##################  AddRow ##########################
*   Purpose....: Add a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::AddRow(TQuizRow *Row)
{
    int val;
    int i;
    TQuizRow **NewArr;

    Row->P = ProbArr[Row->Score];
    printf("%d: ID: %d Score: %d\r\n", Stage, Row->ID, Row->Score);

    switch (Stage)
    {
        case 1:
            for (i = 0; i < N; i++)
                ItemArr[i]->Add(Row->Sex, Row->P, Row->Quiz[i]);

            break;

        case 2:
            for (i = 0; i < N; i++)
                ItemArr[i]->Update(Row->Sex, Row->P, Row->Quiz, ItemArr, i);

            for (i = 0; i < GROUP_COUNT; i++)
                GroupArr[i]->Add(Row->Sex, Row->P, Row->Quiz, ItemArr, N);

            break;

        case 3:
            for (i = 0; i < N; i++)
                ItemArr[i]->Update(Row->Sex, Row->P, Row->Quiz, GroupArr, ItemArr, N);

            for (i = 0; i < GROUP_COUNT; i++)
                GroupArr[i]->Update(Row->Sex, Row->P, Row->Quiz, ItemArr, N);

            break;
    }
}

/*##################  Analyse ##########################
*   Purpose....: Analyse                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::Analyse()
{
    int i;
    int j;

    Init();

    Stage = 1;
    Load();

    for (i = 0; i < N; i++)
        ItemArr[i]->InitDone1();

    for (i = 0; i < N; i++)
    {
        j = ItemArr[i]->MyGroup;
        if (j >= 0)
            GroupArr[j]->Questions++;
    }

    Stage = 2;
    Load();

    for (i = 0; i < N; i++)
        ItemArr[i]->InitDone2();

    for (i = 0; i < GROUP_COUNT; i++)
        GroupArr[i]->InitDone1();

    Stage = 3;
    Load();

    for (i = 0; i < GROUP_COUNT; i++)
        GroupArr[i]->InitDone2();

    for (i = 0; i < N; i++)
        ItemArr[i]->InitDone3(GroupArr, ItemArr, i);

    for (i = 0; i < N; i++)
    {
        ItemArr[i]->Corr[i] = 0.0;
        for (j = i + 1; j < N; j++)
           ItemArr[i]->Corr[j] = ItemArr[j]->Corr[i];
    }
}
