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

/*################## CreateAsHist ##########################
*   Purpose....: Create Aspie histogram	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateAsHist(TBitmapGraphicDevice *dev, int x, int y)
{
	 int ok;
	 int i;
    char *name;
    THistData HistArr[100];
    TFont Font(10);
    TFont TextFont(25);
	TLinXAxis LinXAxis(&Font);
	TLinYAxis LinYAxis;
    TChart *chart;

    chart = new TChart(dev, &LinXAxis, &LinYAxis);

    chart->SetWindow(x, y, x + 249, y + 149);
    chart->SetBackColor(128, 128, 128);

    ok = ImportData("as2.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(100, 192, 0, 192);
    
        for (i = 0; i < 100; i++)
            chart->Add(100, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("as3.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(101, 0, 0, 255);
    
        for (i = 0; i < 100; i++)
            chart->Add(101, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("as4.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(102, 0, 192, 192);
    
        for (i = 0; i < 100; i++)
            chart->Add(102, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("as5.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(103, 0, 255, 0);
    
        for (i = 0; i < 100; i++)
            chart->Add(103, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("as6.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(104, 192, 192, 0);
    
        for (i = 0; i < 100; i++)
            chart->Add(104, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("as7.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(105, 255, 0, 0);
    
		  for (i = 0; i < 100; i++)
            chart->Add(105, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    for (i = 0; i < 20; i++)
    {
        chart->SetLineColor(i, 120, 120, 120);

        chart->Add(i, (long double)(10 * i), 0.0);
        chart->Add(i, (long double)(10 * i), MaxVal + 25.0);
    }

    chart->Draw();    

    dev->ClearClipRect();
    dev->SetLgopNone();
    dev->SetFont(&TextFont);

    for (i = 2; i <= 7; i++)
    {
        switch (i)
        {
            case 2:
                name = "II";
                dev->SetDrawColor(192, 0, 192);
                break;

            case 3:
                name = "III";
                dev->SetDrawColor(0, 0, 255);
                break;

            case 4:
                name = "ND";
                dev->SetDrawColor(0, 192, 192);
					 break;

            case 5:
                name = "5";
                dev->SetDrawColor(0, 255, 0);
                break;

            case 6:
                name = "6";
                dev->SetDrawColor(192, 192, 0);
                break;

            case 7:
                name = "7";
                dev->SetDrawColor(255, 0, 0);
                break;
        } 
        dev->DrawString(x + 40 * (i - 2) + 20, y + 3, name);
                
    }

    delete chart;
}

/*################## CreateNtHist ##########################
*   Purpose....: Create NT histogram	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateNtHist(TBitmapGraphicDevice *dev, int x, int y)
{
	 int ok;
	 int i;
    char *name;
    THistData HistArr[100];
    TFont Font(10);
    TFont TextFont(25);
	TLinXAxis LinXAxis(&Font);
	TLinYAxis LinYAxis;
    TChart *chart;

    chart = new TChart(dev, &LinXAxis, &LinYAxis);

    chart->SetWindow(x, y, x + 249, y + 149);
    chart->SetBackColor(128, 128, 128);

    ok = ImportData("nt2.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(100, 192, 0, 192);
    
        for (i = 0; i < 100; i++)
            chart->Add(100, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("nt3.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(101, 0, 0, 255);
    
        for (i = 0; i < 100; i++)
            chart->Add(101, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("nt4.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(102, 0, 192, 192);
    
        for (i = 0; i < 100; i++)
            chart->Add(102, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("nt5.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(103, 0, 255, 0);
    
        for (i = 0; i < 100; i++)
            chart->Add(103, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("nt6.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(104, 192, 192, 0);
    
        for (i = 0; i < 100; i++)
            chart->Add(104, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    ok = ImportData("nt7.dat", HistArr);    

    if (ok)
    {
        chart->SetLineColor(105, 255, 0, 0);
    
		  for (i = 0; i < 100; i++)
            chart->Add(105, (long double)HistArr[i].Index, HistArr[i].Val);
    }

    for (i = 0; i < 20; i++)
    {
        chart->SetLineColor(i, 120, 120, 120);

        chart->Add(i, (long double)(10 * i), 0.0);
        chart->Add(i, (long double)(10 * i), MaxVal + 25.0);
    }

    chart->Draw();    

    dev->ClearClipRect();
    dev->SetLgopNone();
    dev->SetFont(&TextFont);

    for (i = 2; i <= 7; i++)
    {
        switch (i)
        {
            case 2:
                name = "II";
                dev->SetDrawColor(192, 0, 192);
                break;

            case 3:
                name = "III";
                dev->SetDrawColor(0, 0, 255);
                break;

            case 4:
                name = "ND";
                dev->SetDrawColor(0, 192, 192);
					 break;

            case 5:
                name = "5";
                dev->SetDrawColor(0, 255, 0);
                break;

            case 6:
                name = "6";
                dev->SetDrawColor(192, 192, 0);
                break;

            case 7:
                name = "7";
                dev->SetDrawColor(255, 0, 0);
                break;
        } 
        dev->DrawString(x + 40 * (i - 2) + 20, y + 3, name);
                
    }

    delete chart;
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
    TJpegBitmapDevice jpeg(24, 520, 150);
    
	 CreateAsHist(&jpeg, 0, 0);
	 CreateNtHist(&jpeg, 260, 0);

	 jpeg.Save("all.jpg");
}
