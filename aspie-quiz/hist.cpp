/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# hist.cpp
# Generate histograms for aspie-quiz (only for RDOS)
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"
#include "chart.h"
#include "videodev.h"
#include "linxaxis.h"
#include "linyaxis.h"
#include "jpeg.h"

struct THistData
{
    int Index;
    long double Val;
};

#define MAX_IN_ROW  1024

#define FALSE	0
#define TRUE	!FALSE

long double MaxVal = 0.0;

/*################## ImportData ##########################
*   Purpose....: Import data	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int ImportData(const char *filename, THistData HistArr[100])
{
    char buf[MAX_IN_ROW];
    char *ptr;
	long pos = 0;
    int size;
    THistData *HistPtr = HistArr;
    TFile infile(filename);
    long double val;

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		ptr = strstr(buf, "\r");
		if (ptr)
			*ptr = 0;
		else
		    break;

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (sscanf(buf, "%d %Lf", &HistPtr->Index, &val) != 2)
		    return FALSE;

		if (val < 0.0)
		    val = 0.0;

        if (val > MaxVal)
            MaxVal = val;

        HistPtr->Val = val;
		HistPtr++;
	}
    return TRUE;
}

/*################## WriteHeading ##########################
*   Purpose....: Write heading     	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteHeading(TBitmapGraphicDevice *dev, int x, int y, const char *text)
{
    TFont Font(10);
    TFont TextFont(15);

	dev->ClearClipRect();
	dev->SetLgopNone();
	dev->SetFont(&TextFont);

    dev->SetDrawColor(0, 0, 0);
    dev->DrawString(x + 10, y + 3, text);
}

/*################## WriteAsNtHist ##########################
*   Purpose....: Write Aspie/NT histogram	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteAsNtHist(TBitmapGraphicDevice *dev, int x, int y, THistData As[100], THistData Nt[100])
{
	int ok;
	int i;
    char *name;
    TFont Font(10);
    TFont TextFont(15);
	TLinXAxis LinXAxis(&Font);
	TLinYAxis LinYAxis;
    TChart *chart;

    chart = new TChart(dev, &LinXAxis, &LinYAxis);

    chart->SetWindow(x, y, x + 249, y + 149);
    chart->SetBackColor(128, 128, 128);

    chart->SetLineColor(100, 128, 255, 0);
    
    for (i = 0; i < 100; i++)
		chart->Add(100, (long double)As[i].Index, As[i].Val);

	chart->SetLineColor(101, 128, 0, 255);

	for (i = 0; i < 100; i++)
		chart->Add(101, (long double)Nt[i].Index, Nt[i].Val);

	for (i = 0; i < 20; i++)
	{
		chart->SetLineColor(i, 120, 120, 120);

		chart->Add(i, (long double)(10 * i), 0.0);
		chart->Add(i, (long double)(10 * i), 1.2 * MaxVal);
	}

	chart->Draw();

	dev->ClearClipRect();
	dev->SetLgopNone();
	dev->SetFont(&TextFont);

    for (i = 0; i < 2; i++)
    {
        switch (i)
        {
            case 0:
                name = "Aspie";
                dev->SetDrawColor(128, 255, 0);
                break;

            case 1:
                name = "Neurotypical";
                dev->SetDrawColor(128, 0, 255);
                break;
        } 
        dev->DrawString(x + 100 * i + 20, y + 3, name);
                
    }

	delete chart;
}

/*################## CreateAll ##########################
*   Purpose....: Create all.jpg 	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateAll()
{

	THistData AsArr[100];
	THistData NtArr[100];
	int ok;
	TJpegBitmapDevice jpeg(24, 520, 550);

	jpeg.SetDrawColor(255, 255, 255);
	jpeg.SetLgopNone();
	jpeg.SetFilledStyle();
	jpeg.DrawRect(0, 0, 519, 549);

	WriteHeading(&jpeg, 0, 0, "Quiz II");

	MaxVal = 0.0;
	ok = ImportData("as2.dat", AsArr);

	if (ok)
		ok = ImportData("nt2.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 0, 20, AsArr, NtArr);

	WriteHeading(&jpeg, 260, 0, "Quiz III");

	MaxVal = 0.0;
	ok = ImportData("as3.dat", AsArr);

	if (ok)
		ok = ImportData("nt3.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 260, 20, AsArr, NtArr);

	WriteHeading(&jpeg, 0, 180, "Neurodiversity");

	MaxVal = 0.0;
	ok = ImportData("as4.dat", AsArr);

	if (ok)
		ok = ImportData("nt4.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 0, 200, AsArr, NtArr);

	WriteHeading(&jpeg, 260, 180, "Quiz 5");

	MaxVal = 0.0;
	ok = ImportData("as5.dat", AsArr);

	if (ok)
		ok = ImportData("nt5.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 260, 200, AsArr, NtArr);

	WriteHeading(&jpeg, 0, 360, "Quiz 6");

	MaxVal = 0.0;
	ok = ImportData("as6.dat", AsArr);

	if (ok)
		ok = ImportData("nt6.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 0, 380, AsArr, NtArr);

	WriteHeading(&jpeg, 260, 360, "Quiz 7");

	MaxVal = 0.0;
	ok = ImportData("as7.dat", AsArr);

	if (ok)
		ok = ImportData("nt7.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 260, 380, AsArr, NtArr);

	jpeg.Save("all.jpg");
}

/*################## CreateDx ##########################
*   Purpose....: Create dx.jpg 	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateDx()
{
	THistData AsArr[100];
	THistData NtArr[100];
	int ok;
	TJpegBitmapDevice jpeg(24, 520, 550);

	jpeg.SetDrawColor(255, 255, 255);
	jpeg.SetLgopNone();
	jpeg.SetFilledStyle();
	jpeg.DrawRect(0, 0, 519, 549);

	WriteHeading(&jpeg, 0, 0, "AS/HFA/PDD");

	MaxVal = 0.0;
	ok = ImportData("asas.dat", AsArr);

	if (ok)
		ok = ImportData("asnt.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 0, 20, AsArr, NtArr);

	WriteHeading(&jpeg, 260, 0, "Control group");

	MaxVal = 0.0;
	ok = ImportData("ntas.dat", AsArr);

	if (ok)
		ok = ImportData("ntnt.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 260, 20, AsArr, NtArr);

	WriteHeading(&jpeg, 0, 180, "Social phobia");

	MaxVal = 0.0;
	ok = ImportData("socas.dat", AsArr);

	if (ok)
		ok = ImportData("socnt.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 0, 200, AsArr, NtArr);

	WriteHeading(&jpeg, 260, 180, "ADD/ADHD");

	MaxVal = 0.0;
	ok = ImportData("addas.dat", AsArr);

	if (ok)
		ok = ImportData("addnt.dat", NtArr);

	if (ok)
		WriteAsNtHist(&jpeg, 260, 200, AsArr, NtArr);


	jpeg.Save("dx.jpg");
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    CreateAll();
    CreateDx();
}
