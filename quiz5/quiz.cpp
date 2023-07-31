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

static double r2pi = sqrt(2.0 * 3.14159265358979323846);

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
TQuizItem::TQuizItem(int number)
{
    int i;

    Text = "NO TEXT";
    MyGroup = 0;
    Reverse = false;
    Nr = number;

    NoAnswer = 0;
    Count = 0;
    Sd = 0.0;

    for (i = 0; i < MAX_QUESTIONS; i++)
    {
        Cov[i] = 0.0;
        CountArr[i] = 0;
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
void TQuizItem::Add(int gender, double p, int value)
{
    double dval;
    double p1 = 1.0 - p;

    if (value)
    {
        Count++;
        dval = (double)(value - 1);
        
        switch (gender)
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
void TQuizItem::Update(int gender, double p, char value)
{
    double dval;
    double diff;

    if (value)
    {
        dval = (double)(value - 1);

        switch (gender)
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

        switch (gender)
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
void TQuizItem::Update(int gender, double p, char myval, char value, TQuizItem *item)
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

        switch (gender)
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

        switch (gender)
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
void TQuizItem::Update(int gender, double p, char *value, TQuizItem **item, int count)
{
    int i;

    Update(gender, p, value[Nr]);

    for (i = 0; i < count; i++)
        Update(gender, p, value[Nr], value[i], item[i]);
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
void TQuizItem::InitDone3(TQuizItem **item, int count)
{
    int i;

    for (i = 0; i < count; i++)
    {
        Cov[i] = Cov[i] / (double)(CountArr[i] - 1);
        Corr[i] = Cov[i] / Sd / item[i]->Sd;
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

    ItemArr = new TQuizItem*[N];

    for (i = 0; i < N; i++)
        ItemArr[i] = new TQuizItem(i);

    ValueCount = 0;
    ValueSize = 0;
    ValueArr = 0;

    GroupValArr = 0;
    GroupValCount = 0;

    Init();

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

    for (i = 0; i < ValueCount; i++)
        delete ValueArr[i];

    if (ValueArr)
        delete ValueArr;

    if (GroupValArr)
        delete GroupValArr;
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
    int g1, g2;

    for (g = 0; g < MAX_GROUP_COUNT; g++)
    {
        Group[g].PosName = "NO NAME";
        Group[g].NegName = "NO NAME";
    }

    Group[GROUP_ASPIE_TALENT].PosName = "Aspie ability";
    Group[GROUP_ASPIE_TALENT].NegName = "Aspie ability problem";

    Group[GROUP_NT_TALENT].PosName = "NT ability problem";
    Group[GROUP_NT_TALENT].NegName = "NT ability";

    Group[GROUP_ASPIE_RELATION].PosName = "Aspie relationship";
    Group[GROUP_ASPIE_RELATION].NegName = "Aspie relationship problem";

    Group[GROUP_ASPIE_SOCIAL].PosName = "Aspie social";
    Group[GROUP_ASPIE_SOCIAL].NegName = "Aspie social problem";

    Group[GROUP_NT_SOCIAL].PosName = "NT social problem";
    Group[GROUP_NT_SOCIAL].NegName = "NT social";

    Group[GROUP_ASPIE_NVC].PosName = "Aspie communication";
    Group[GROUP_ASPIE_NVC].NegName = "Aspie communication problem";

    Group[GROUP_NT_NVC].PosName = "NT communication problem";
    Group[GROUP_NT_NVC].NegName = "NT communication";

    Group[GROUP_NT_RELATION].PosName = "NT relationship problem";
    Group[GROUP_NT_RELATION].NegName = "NT relationship";

    Group[GROUP_ASPIE_SENSORY].PosName = "Aspie sensory";
    Group[GROUP_ASPIE_SENSORY].NegName = "Aspie sensory problem";

    Group[GROUP_NT_SENSORY].PosName = "NT sensory problem";
    Group[GROUP_NT_SENSORY].NegName = "NT sensory";

    Group[GROUP_MIXED].PosName = "Aspie mixed";
    Group[GROUP_MIXED].NegName = "NT mixed";

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

    printf("%d Score: %d\r\n", Row->ID, Row->Score);

    if (ValueArr == 0)
    {
        ValueSize = 8;
        ValueArr = new TQuizRow*[ValueSize];
    }

    if (ValueCount >= ValueSize)
    {
        ValueSize = 3 * ValueSize / 2;
        NewArr = new TQuizRow*[ValueSize];

        for (i = 0; i < ValueCount; i++)
            NewArr[i] = ValueArr[i];

        delete ValueArr;
        ValueArr = NewArr;
    }

    Row->P = ProbArr[Row->Score];

    for (i = 0; i < N; i++)
        ItemArr[i]->Add(Row->Gender, Row->P, Row->Quiz[i]);

    ValueArr[ValueCount] = Row;
    ValueCount++;
}

/*##################  LoadDone ##########################
*   Purpose....: Add a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::LoadDone()
{
    int i;
    int j;
    TQuizRow *row;

    for (i = 0; i < N; i++)
        ItemArr[i]->InitDone1();

    for (j = 0; j < ValueCount; j++)
    {
        row = ValueArr[j];
        for (i = 0; i < N; i++)
            ItemArr[i]->Update(row->Gender, row->P, row->Quiz, ItemArr, N);
    }

    for (i = 0; i < N; i++)
        ItemArr[i]->InitDone2();

    for (i = 0; i < N; i++)
        ItemArr[i]->InitDone3(ItemArr, N);
}
