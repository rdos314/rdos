/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# web.h
# Heat web server class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "web.h"

#define BUF_SIZE	0x4000
#define STACK_SIZE      0x4000

#define REQ_WIND	1
#define REQ_SOLAR	2
#define REQ_SOLAR_WIND	3

#define SUBMIT_NONE	0
#define SUBMIT_MONTH	1
#define SUBMIT_DAY	2
#define SUBMIT_POWER    3
#define SUBMIT_SOLAR    4
#define SUBMIT_WIND     5

/*##########################################################################
#
#   Name       : THeatHttpServerFactory::THeatHttpServerFactory
#
#   Purpose....: server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServerFactory::THeatHttpServerFactory(int Port, int MaxConnections, int BufferSize)
  : THttpSocketServerFactory(Port, MaxConnections, BufferSize)
{
}
/*##########################################################################
#
#   Name       : THeatHttpServerFactory::~THeatHttpServerFactory
#
#   Purpose....: Heat server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServerFactory::~THeatHttpServerFactory()
{
}

/*##########################################################################
#
#   Name       : THeatHttpServerFactory::Create
#
#   Purpose....: Create socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *THeatHttpServerFactory::Create(TTcpSocket *Socket)
{
    THttpSocketServer *server = new THeatHttpServer("Web socket", 0x10000, Socket);
    LinkServer(server);
    return server;
}

/*##########################################################################
#
#   Name       : THeatHttpServer::THeatHttpServer
#
#   Purpose....: server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServer::THeatHttpServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : THttpSocketServer(Name, StackSize, Socket)
{
}

/*##########################################################################
#
#   Name       : THeatHttpServer::~THeatHttpServer
#
#   Purpose....: Heat server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServer::~THeatHttpServer()
{
}

/*##########################################################################
#
#   Name       : THeatJsonDirFactory::THeatJsonDirFactory
#
#   Purpose....: JSON factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonDirFactory::THeatJsonDirFactory(const char *ReqName)
  : THttpCustomDirFactory(ReqName)
{
}

/*##########################################################################
#
#   Name       : THeatJsonDirFactory::~THeatJsonDirFactory
#
#   Purpose....: JSON factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonDirFactory::~THeatJsonDirFactory()
{
}

/*##########################################################################
#
#   Name       : THeatJsonDirFactory::Create
#
#   Purpose....: Create JSON page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THeatJsonDirFactory::Create(THttpCommand *cmd)
{
    return new THeatJsonPage(cmd);
}

/*##########################################################################
#
#   Name       : THeatJsonPage::THeatJsonPage
#
#   Purpose....: JSON page constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonPage::THeatJsonPage(THttpCommand *Cmd)
  : THttpCustomPage(Cmd)
{
}

/*##########################################################################
#
#   Name       : THeatJsonPage::~THeatJsonPage
#
#   Purpose....: JSON page destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonPage::~THeatJsonPage()
{
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateTitle
#
#   Purpose....: Create title
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateTitle(TJsonCollection *obj)
{
    char dstr[60];
    char str[100];

    if (FUseDay)
        sprintf(dstr, "%04d-%02d-%02d", FYear, FMonth, FDay);
    else
    {
        if (FUseMonth)
        {
            switch (FMonth)
            {
                case 1:
                    strcpy(dstr, "Jan");
                    break;
    
                case 2:
                    strcpy(dstr, "Feb");
                    break;
    
                case 3:
                    strcpy(dstr, "Mar");
                    break;
    
                case 4:
                    strcpy(dstr, "Apr");
                    break;
    
                case 5:
                    strcpy(dstr, "May");
                    break;
    
                case 6:
                    strcpy(dstr, "Jun");
                    break;    

                case 7:
                    strcpy(dstr, "Jul");
                    break;
    
                case 8:
                    strcpy(dstr, "Aug");
                    break;
    
                case 9:
                    strcpy(dstr, "Sep");
                    break;
    
                case 10:
                    strcpy(dstr, "Oct");
                    break;
    
                case 11:
                    strcpy(dstr, "Nov");
                    break;
    
                case 12:
                    strcpy(dstr, "Dec");
                    break;
    
                default:
                    dstr[0] = 0;
                    break;
            }
            sprintf(str, " %04d", FYear);
            strcat(dstr, str);
        }
        else
            sprintf(dstr, "%04d", FYear);
    }

    switch (FReqType)
    {
        case REQ_WIND:
            strcpy(str, "Wind power  ");
            break;

        case REQ_SOLAR:
            strcpy(str, "Solar power  ");
            break;

        case REQ_SOLAR_WIND:
            strcpy(str, "Power  ");
            break;

        default:
            str[0] = 0;
            break;
    }

    strcat(str, dstr);
    obj->AddString("text", str);

    obj->AddBoolean("adjustLayout", true);
    obj->AddString("marginTop", "7px");
    obj->AddString("fontColor", "#E3E3E5");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateLegend
#
#   Purpose....: Create legend
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateLegend(TJsonCollection *obj)
{
    TJsonCollection *item;
    TJsonCollection *marker;

    obj->AddString("align", "center");
    obj->AddString("backgroundColor", "none");
    obj->AddString("borderWidth", "0px");

    item = obj->AddCollection("item");
    item->AddString("cursor", "hand");
    item->AddString("fontColor", "#E3E3E5");

    marker = obj->AddCollection("marker");
    marker->AddString("type", "circle");
    marker->AddString("borderWidth", "0px");
    marker->AddString("cursor", "hand");

    obj->AddString("verticalAlign", "top");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreatePlot
#
#   Purpose....: Create plot
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreatePlot(TJsonCollection *obj)
{
    TJsonCollection *marker;

    obj->AddString("aspect", "spline");
    obj->AddString("lineWidth", "2px");

    marker = obj->AddCollection("marker");
    marker->AddString("borderWidth", "0px");
    marker->AddString("size", "5px");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreatePlotArea
#
#   Purpose....: Create plot area
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreatePlotArea(TJsonCollection *obj)
{
    obj->AddString("margin", "dynamic 70");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateScaleX
#
#   Purpose....: Create X scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateScaleX(TJsonCollection *obj, TDateTime &time)
{
    TJsonCollection *item;
    TJsonCollection *transform;
    TJsonStringArray *arr;
    char str[80];
    char month[40];

    item = obj->AddCollection("item");
    item->AddString("fontColor", "#E3E3E5");

    obj->AddString("lineColor", "#E3E3E5");

    if (FUseDay)
    {
        obj->AddDateTime("minValue", time, false);
        obj->AddString("step", "minute");

        transform = obj->AddCollection("transform");
        transform->AddString("type", "date");
        transform->AddString("all", "%G:%i");
    }
    else
    {
        if (FUseMonth)
        {
            obj->AddInt("minValue", 1);
            obj->AddInt("step", 1);

            switch (FMonth)
            {
                case 1:
                    strcpy(month, "Jan");
                    break;

                case 2:
                    strcpy(month, "Feb");
                    break;

                case 3:
                    strcpy(month, "Mar");
                    break;

                case 4:
                    strcpy(month, "Apr");
                    break;

                case 5:
                    strcpy(month, "May");
                    break;

                case 6:
                    strcpy(month, "Jun");
                    break;

                case 7:
                    strcpy(month, "Jul");
                    break;

                case 8:
                    strcpy(month, "Aug");
                    break;

                case 9:
                    strcpy(month, "Sep");
                    break;

                case 10:
                    strcpy(month, "Oct");
                    break;

                case 11:
                    strcpy(month, "Nov");
                    break;

                case 12:
                    strcpy(month, "Dec");
                    break;

                default:
                    month[0] = 0;
                    break;
            }
            sprintf(str, "%s %d", month, FYear);
            obj->AddString("label", str);        
        }
        else
        {
            sprintf(str, "%d", FYear);
            obj->AddString("label", str);        

            arr = obj->AddStringArray("values");
            arr->Add("Jan");
            arr->Add("Feb");
            arr->Add("Mar");
            arr->Add("Apr");
            arr->Add("May");
            arr->Add("Jun");
            arr->Add("Jul");
            arr->Add("Aug");
            arr->Add("Sep");
            arr->Add("Oct");
            arr->Add("Nov");
            arr->Add("Dec");
        }
    }
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateScaleY
#
#   Purpose....: Create Y scale
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateScaleY(TJsonCollection *obj)
{
    TJsonCollection *guide;
    TJsonCollection *item;
    TJsonCollection *transform;

    guide = obj->AddCollection("guide");
    guide->AddString("lineStyle", "dashed");

    item = obj->AddCollection("item");
    item->AddString("fontColor", "#E3E3E5");

    obj->AddInt("minValue", 0);

    if (FUseDay)
        obj->AddString("format", "%vW");
    else
        obj->AddString("format", "%vkWh");

    obj->AddString("lineColor", "#E3E3E5");

}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateCrosshairX
#
#   Purpose....: Create crosshair X
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateCrosshairX(TJsonCollection *obj)
{
    TJsonCollection *marker;
    TJsonCollection *plotlabel;
    TJsonCollection *scalelabel;

    marker = obj->AddCollection("marker");
    marker->AddDouble("alpha", 0.5, 1);
    marker->AddString("size", "7px");

    plotlabel = obj->AddCollection("plotLabel");
    plotlabel->AddString("borderRadius", "3px");
    plotlabel->AddBoolean("multiple", true);

    scalelabel = obj->AddCollection("scaleLabel");
    scalelabel->AddString("backgroundColor", "#53535E");
    scalelabel->AddString("borderRadius", "3px");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateCrosshairY
#
#   Purpose....: Create crosshair y
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateCrosshairY(TJsonCollection *obj)
{
    TJsonCollection *scalelabel;

    obj->AddString("type", "multiple");
    obj->AddString("lineColor", "#E3E3E5");

    scalelabel = obj->AddCollection("scaleLabel");
    scalelabel->AddBoolean("bold", true);
    scalelabel->AddString("borderRadius", "3px");
    scalelabel->AddInt("decimals", 2);
    scalelabel->AddString("fontColor", "#2C2C39");
    scalelabel->AddString("offsetX", "-5px");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateShapes
#
#   Purpose....: Create shapes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateShapes(TJsonCollection *obj)
{
    TJsonCollection *label;

    obj->AddString("type", "rectangle");
    obj->AddString("id", "view_all");
    obj->AddString("backgroundColor", "#53535E");
    obj->AddString("borderColor", "#E3E3E5");
    obj->AddString("borderRadius", "3px");
    obj->AddString("borderWidth", "1px");
    obj->AddString("cursor", "hand");

    label = obj->AddCollection("label");
    label->AddString("text", "View All");
    label->AddBoolean("bold", true);
    label->AddString("fontColor", "#E3E3E5");
    label->AddString("fontSize", "12px");

    obj->AddString("width", "75px");
    obj->AddString("height", "20px");
    obj->AddString("x", "85%");
    obj->AddString("y", "11%");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateToolTip
#
#   Purpose....: Create tool tips
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateToolTip(TJsonCollection *obj)
{
    obj->AddString("borderRadius", "3px");
    obj->AddString("borderWidth", "0px");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::GetDayFile
#
#   Purpose....: Get day file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *THeatJsonPage::GetDayFile()
{
    char str[80];
    char root[40];

    strcpy(root, "e:/data/power");
    sprintf(str, "%s/%d/%d/%d.csv", root, FYear, FMonth, FDay);
    return new TFile(str);
}

/*##########################################################################
#
#   Name       : THeatJsonPage::GetMonthFile
#
#   Purpose....: Get month file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *THeatJsonPage::GetMonthFile()
{
    char str[80];
    char root[40];

    strcpy(root, "e:/data/power");
    sprintf(str, "%s/%d/%d/total.csv", root, FYear, FMonth);
    return new TFile(str);
}

/*##########################################################################
#
#   Name       : THeatJsonPage::AddDayData
#
#   Purpose....: Add day data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::AddDayData(TJsonArrayCollection *obj, char *text, int col)
{
    TJsonDoubleArray *arr;
    int i;
    char *ptr;
    char *next;
    char *rptr;
    double val = 0.0;
    int count;
    int hour = 0;
    int min = 0;
    int ntime;
    int time = 0;
    char *end;

    arr = obj->AddDoubleArray("values", 1);

    ptr = text;
    while (ptr)
    {
        next = strchr(ptr, 0xd);
        if (next)
        {
            *next = 0;
            next++;
        }

        rptr = strchr(ptr, ':');
        if (rptr)
        {
            hour = atoi(ptr);
            ptr = rptr + 1;

            rptr = strchr(ptr, ';');
        }

        if (rptr)
        {
            min = atoi(ptr);
            ptr = rptr + 1;

            rptr = strchr(ptr, ';');
        }

        if (rptr)
        {
            for (i = 0; rptr && i < col; i++)
            {
                ptr = rptr + 1;
                rptr = strchr(ptr, ';');
            }

            if (i == col)
            {
                ntime = 60 * hour + min;

                while (ntime > time)
                {
                    arr->AddNone();
                    time++;
                }

                if (time == ntime)
                {
                    if (rptr)
                        *rptr = 0;
                    val = strtod(ptr, &end);
                    arr->Add(val);
                    time++;
                }
            }
        }
        ptr = next;
    }
}

/*##########################################################################
#
#   Name       : THeatJsonPage::AddMonthData
#
#   Purpose....: Add month data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::AddMonthData(TJsonArrayCollection *obj, char *text, int col)
{
    TJsonDoubleArray *arr;
    int i;
    char *ptr;
    char *next;
    char *rptr;
    double val = 0.0;
    int count;
    int day = 0;
    int currday = 1;
    char *end;

    arr = obj->AddDoubleArray("values", 1);

    ptr = text;
    while (ptr)
    {
        next = strchr(ptr, 0xd);
        if (next)
        {
            *next = 0;
            next++;
        }

        rptr = strchr(ptr, ';');
        if (rptr)
        {
            day = atoi(ptr);
            ptr = rptr + 1;

            rptr = strchr(ptr, ';');
        }

        if (rptr)
        {
            for (i = 0; rptr && i < col; i++)
            {
                ptr = rptr + 1;
                rptr = strchr(ptr, ';');
            }

            if (i == col)
            {
                while (day > currday)
                {
                    arr->AddNone();
                    currday++;
                }

                if (currday == day)
                {
                    if (rptr)
                        *rptr = 0;
                    val = strtod(ptr, &end);
                    arr->Add(val);
                    currday++;
                }
            }
        }
        ptr = next;
    }
}

/*##########################################################################
#
#   Name       : THeatJsonPage::AddYearData
#
#   Purpose....: Add year data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::AddYearData(TJsonArrayCollection *obj, double val[12], bool valid[12])
{
    TJsonDoubleArray *arr;
    int i;

    arr = obj->AddDoubleArray("values", 1);

    for (i = 0; i < 12; i++)
    {
        if (valid[i])
            arr->Add(val[i]);
        else
            arr->AddNone();
    }
}

/*##########################################################################
#
#   Name       : THeatJsonPage::GetMonthTotal
#
#   Purpose....: Get month total
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double THeatJsonPage::GetMonthTotal(char *text, int col)
{
    int i;
    char *ptr;
    char *next;
    char *rptr;
    char *end;
    double val = 0.0;

    ptr = text;
    while (ptr)
    {
        next = strchr(ptr, 0xd);
        if (next)
        {
            *next = 0;
            next++;
        }

        rptr = strchr(ptr, ';');
        if (rptr)
        {
            ptr = rptr + 1;
            rptr = strchr(ptr, ';');
        }

        if (rptr)
        {
            for (i = 0; rptr && i < col; i++)
            {
                ptr = rptr + 1;
                rptr = strchr(ptr, ';');
            }

            if (i == col)
            {
                if (rptr)
                    *rptr = 0;
                val += strtod(ptr, &end);
            }
        }
        ptr = next;
    }
    return val;
}

/*##########################################################################
#
#   Name       : THeatJsonPage::ReadData
#
#   Purpose....: Read data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THeatJsonPage::ReadFile(TFile *file)
{
    int size;
    char *text;

    file->SetPos(0);
    size = file->GetSize();
    text = new char[size + 1];
    file->Read(text, size);
    text[size] = 0;

    return text;
}

/*##########################################################################
#
#   Name       : THeatJsonPage::CreateSeries
#
#   Purpose....: Create data series
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::CreateDataSerie(TJsonArrayCollection *obj)
{
    TFile *file;
    char *text;

    if (FUseDay)
    {
        file = GetDayFile();

        if (file->IsOpen())
        {
            text = ReadFile(file);
            
            switch (FReqType)
            {
                case REQ_SOLAR:
                    obj->AddString("legendText", "solar");
                    AddDayData(obj, text, 0);
                    break;

                case REQ_WIND:
                    obj->AddString("legendText", "wind");
                    AddDayData(obj, text, 1);
                    break;

                case REQ_SOLAR_WIND:
                    obj->AddString("legendText", "solar");
                    AddDayData(obj, text,  0);
                    delete text;

                    obj->AddArray();
                    text = ReadFile(file);
                    obj->AddString("legendText", "wind");
                    AddDayData(obj, text, 1);
                    break;
             }
            delete text;
        }
        delete file;
    }
    else
    {
        if (FUseMonth)
        {
            file = GetMonthFile();

            if (file->IsOpen())
            {
                text = ReadFile(file);
                        
                switch (FReqType)
                {
                    case REQ_SOLAR:
                        obj->AddString("legendText", "solar");
                        AddMonthData(obj, text, 0);
                        break;

                    case REQ_WIND:
                        obj->AddString("legendText", "wind");
                        AddMonthData(obj, text, 1);
                        break;

                    case REQ_SOLAR_WIND:
                        obj->AddString("legendText", "solar");
                        AddMonthData(obj, text, 0);
                        delete text;

                        obj->AddArray();
                        text = ReadFile(file);
                        obj->AddString("legendText", "wind");
                        AddMonthData(obj, text, 1);
                        break;
                }
                delete text;
            }
            delete file;
        }
        else
        {
            double valA[12];
            double valB[12];
            bool Valid[12];

            for (FMonth = 1; FMonth <= 12; FMonth++)
            {
                file = GetMonthFile();

                if (file->IsOpen())
                {
                    Valid[FMonth - 1] = true;

                    text = ReadFile(file);
                        
                    switch (FReqType)
                    {
                        case REQ_SOLAR:
                            valA[FMonth - 1] = GetMonthTotal(text, 0);
                            break;

                        case REQ_WIND:
                            valA[FMonth - 1] = GetMonthTotal(text, 1);
                            break;

                        case REQ_SOLAR_WIND:
                            valA[FMonth - 1] = GetMonthTotal(text, 0);
                            delete text;

                            text = ReadFile(file);
                            valB[FMonth - 1] = GetMonthTotal(text, 1);
                            break;
                    }
                    delete text;
                }
                else
                    Valid[FMonth - 1] = false;
                
                delete file;
            }

            switch (FReqType)
            {
                case REQ_SOLAR:
                    obj->AddString("legendText", "solar");
                    AddYearData(obj, valA, Valid);
                    break;

                case REQ_WIND:
                    obj->AddString("legendText", "wind");
                    AddYearData(obj, valA, Valid);
                    break;

                case REQ_SOLAR_WIND:
                    obj->AddString("legendText", "solar");
                    AddYearData(obj, valA, Valid);

                    obj->AddArray();
                    obj->AddString("legendText", "wind");
                    AddYearData(obj, valB, Valid);
                    break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : THeatJsonPage::SendAnswer
#
#   Purpose....: Send answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::SendAnswer()
{
    TDateTime time (FYear, FMonth, FDay);
    TJsonDocument json;
    TJsonCollection *root = json.CreateRoot();
    TJsonCollection *obj;
    TJsonArrayCollection *arr;
    TString str;

    if (FUseDay)
        root->AddString("type", "line");
    else
        root->AddString("type", "bar");

    root->AddBoolean("utc", true);

    root->AddString("backgroundColor", "#2C2C39");

    obj = root->AddCollection("title");
    CreateTitle(obj);    

    if (FReqType == REQ_SOLAR_WIND)
    {
        obj = root->AddCollection("legend");
        CreateLegend(obj);    
    }

    obj = root->AddCollection("plot");
    CreatePlot(obj);    

    obj = root->AddCollection("plotarea");
    CreatePlotArea(obj);    

    obj = root->AddCollection("scaleX");
    CreateScaleX(obj, time);    

    obj = root->AddCollection("scaleY");
    CreateScaleY(obj);    

    obj = root->AddCollection("crosshairX");
    CreateCrosshairX(obj);    

    obj = root->AddCollection("crosshairY");
    CreateCrosshairY(obj);    

    obj = root->AddCollection("shapes");
    CreateShapes(obj);    

    obj = root->AddCollection("tooltip");
    CreateToolTip(obj);    

    arr = root->AddArrayCollection("series");
    CreateDataSerie(arr);    

    json.Write(str);
    Write(str.GetData());

    SendData("application/json");
}

/*##########################################################################
#
#   Name       : THeatJsonPage::DecodeReq
#
#   Purpose....: Decode req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatJsonPage::DecodeReq(const char *ReqStr)
{
    const char *ptr;
    const char *bptr;
    bool ok = false;

    ptr = strstr(ReqStr, "json");
    if (ptr)
    {
        ptr += 4;
        if (*ptr == '/' || *ptr == '\\')
        {
            ptr++;
            bptr = ptr;
            ptr = strstr(bptr, "wind");
            if (ptr && ptr == bptr)
            {
                FReqType = REQ_WIND;
                ok = true;
                ptr += strlen("wind");
            }
            
            if (!ok)
            {
                ptr = strstr(bptr, "solar");
                if (ptr && ptr == bptr)
                {
                    FReqType = REQ_SOLAR;
                    ok = true;
                    ptr += strlen("solar");
                }
            }

            if (!ok)
            {
                ptr = strstr(bptr, "power");
                if (ptr && ptr == bptr)
                {
                    FReqType = REQ_SOLAR_WIND;
                    ok = true;
                    ptr += strlen("power");
                }
            }

            if (ok)
            {
                if (strlen(ptr) <= 1)
                {
                    TDateTime currtime;
                    FYear = currtime.GetYear();
                    FMonth = currtime.GetMonth();
                    FDay = currtime.GetDay();
                    FUseDay = true;
                    FUseMonth = true;
                }
                else
                {
                    FUseDay = false;
                    FUseMonth = false;

                    ptr++;
                    FYear = atoi(ptr);
                    if (FYear < 2010 || FYear > 2100)
                        ok = false;

                    if (ok)
                    {
                        ptr = strchr(ptr, '/');
                        if (ptr)
                        {
                            ptr++;
                            FMonth = atoi(ptr);
                            FUseMonth = true;

                            if (FMonth < 1 || FMonth > 12)
                                ok = false;

                            if (ok)
                            {
                                ptr = strchr(ptr, '/');
                                if (ptr)
                                {
                                    ptr++;
                                    FDay = atoi(ptr);
                                    FUseDay = true;

                                    if (FDay < 1 || FDay > 31)
                                        ok = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return ok;
}

/*##########################################################################
#
#   Name       : THeatJsonPage::Get
#
#   Purpose....: Get page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::Get(const char *MatchName, const char *UrlName, THttpParam *Param)
{
    if (DecodeReq(MatchName))
        SendAnswer();
    else
        WriteError(400);
}

/*##########################################################################
#
#   Name       : THeatJsonPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::Post(const char *MatchName, const char *UrlName, THttpParam *Param)
{
}

/*##########################################################################
#
#   Name       : THeatJsonPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::Post(const char *Var, const char *Val)
{
}

/*##########################################################################
#
#   Name       : THeatWebDirFactory::THeatWebDirFactory
#
#   Purpose....: Web factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatWebDirFactory::THeatWebDirFactory(const char *ReqName)
  : THttpCustomDirFactory(ReqName)
{
}

/*##########################################################################
#
#   Name       : THeatWebDirFactory::~THeatWebDirFactory
#
#   Purpose....: Web factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatWebDirFactory::~THeatWebDirFactory()
{
}

/*##########################################################################
#
#   Name       : THeatWebDirFactory::Create
#
#   Purpose....: Create web page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THeatWebDirFactory::Create(THttpCommand *cmd)
{
    return new THeatWebPage(cmd);
}

/*##########################################################################
#
#   Name       : THeatWebPage::THeatWebPage
#
#   Purpose....: Web page constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatWebPage::THeatWebPage(THttpCommand *Cmd)
  : THttpCustomPage(Cmd)
{
    TDateTime currtime;

    FSubmitType = SUBMIT_NONE;
    FReqType = REQ_SOLAR_WIND;
    FYear = currtime.GetYear();
    FMonth = currtime.GetMonth();
    FDay = currtime.GetDay();
    FUseDay = true;
    FUseMonth = true;
}

/*##########################################################################
#
#   Name       : THeatWebPage::~THeatWebPage
#
#   Purpose....: Web page destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatWebPage::~THeatWebPage()
{
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasDayFile
#
#   Purpose....: Has day file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasDayFile(TDateTime &time)
{
    char str[80];
    char root[40];
    TFile *file;
    bool ok;

    strcpy(root, "e:/data/power");
    sprintf(str, "%s/%d/%d/%d.csv", root, time.GetYear(), time.GetMonth(), time.GetDay());
    file =  new TFile(str);
    ok = file->IsOpen();
    delete file;
    return ok;
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasNextDay
#
#   Purpose....: Has next day file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasNextDay()
{
    TDateTime time(FYear, FMonth, FDay);

    time.AddDay(1);
    return HasDayFile(time);
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasPrevDay
#
#   Purpose....: Has previous day file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasPrevDay()
{
    TDateTime time(FYear, FMonth, FDay);

    time.AddDay(-1);
    return HasDayFile(time);
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasNextMonth
#
#   Purpose....: Has next month file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasNextMonth()
{
    TDateTime time(FYear, FMonth, 1);

    time.AddMonth(1);
    return HasMonthFile(time);
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasPrevMonth
#
#   Purpose....: Has previous month file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasPrevMonth()
{
    TDateTime time(FYear, FMonth, 1);

    time.AddMonth(-1);
    return HasMonthFile(time);
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasNextYear
#
#   Purpose....: Has next year file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasNextYear()
{
    TDateTime time(FYear, 1, 1);

    time.AddYear(1);
    return HasMonthFile(time);
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasPrevYear
#
#   Purpose....: Has previous year file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasPrevYear()
{
    TDateTime time(FYear, 12, 1);

    time.AddYear(-1);
    return HasMonthFile(time);
}

/*##########################################################################
#
#   Name       : THeatWebPage::HasMonthFile
#
#   Purpose....: Get month file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::HasMonthFile(TDateTime &time)
{
    char str[80];
    char root[40];
    TFile *file;
    bool ok;

    strcpy(root, "e:/data/power");
    sprintf(str, "%s/%d/%d/total.csv", root, time.GetYear(), time.GetMonth());
    file =  new TFile(str);
    ok = file->IsOpen();
    delete file;
    return ok;
}

/*##########################################################################
#
#   Name       : THeatWebPage::GotoPrev
#
#   Purpose....: Goto previous page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::GotoPrev()
{
    if (FUseDay)
    {
        TDateTime time(FYear, FMonth, FDay);
        time.AddDay(-1);
        FYear = time.GetYear();
        FMonth = time.GetMonth();
        FDay = time.GetDay();
    }
    else
    {
        if (FUseMonth)
        {
            TDateTime time(FYear, FMonth, 1);
            time.AddMonth(-1);
            FYear = time.GetYear();
            FMonth = time.GetMonth();
        }
        else
            FYear--;
    }
}

/*##########################################################################
#
#   Name       : THeatWebPage::GotoNext
#
#   Purpose....: Goto next page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::GotoNext()
{
    if (FUseDay)
    {
        TDateTime time(FYear, FMonth, FDay);
        time.AddDay(1);
        FYear = time.GetYear();
        FMonth = time.GetMonth();
        FDay = time.GetDay();
    }
    else
    {
        if (FUseMonth)
        {
            TDateTime time(FYear, FMonth, 1);
            time.AddMonth(1);
            FYear = time.GetYear();
            FMonth = time.GetMonth();
        }
        else
            FYear++;
    }
}

/*##########################################################################
#
#   Name       : THeatWebPage::Fixup
#
#   Purpose....: Fixup date
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::Fixup()
{
    TDateTime currtime;

    if (FUseDay)
    {
        TDateTime time(FYear, FMonth, FDay);

        if (!HasDayFile(time))
        {
            if (time > currtime)
                time = currtime;
            else
            {
                while (!HasDayFile(time) && time < currtime)
                    time.AddDay(1);

                while (!HasDayFile(time))
                    time.AddDay(-1);
            }
        }

        FYear = time.GetYear();
        FMonth = time.GetMonth();
        FDay = time.GetDay();
    }
    else
    {
        if (FUseMonth)
        {
            TDateTime time(FYear, FMonth, 1);

            if (!HasMonthFile(time))
            {
                if (time > currtime)
                {
                    time = currtime;
 
                    if (!HasMonthFile(time))
                        time.AddMonth(-1);
                }
                else
                {
                    while (!HasMonthFile(time) && time < currtime)
                        time.AddMonth(1);

                    while (!HasMonthFile(time))
                        time.AddMonth(-1);
                }
            }

            FYear = time.GetYear();
            FMonth = time.GetMonth();
        }
        else
        {
            TDateTime time(FYear, 12, 1);

            if (!HasMonthFile(time))
            {
                if (time > currtime)
                {
                    time = currtime;
 
                    if (!HasMonthFile(time))
                        time.AddYear(-1);
                }
                else
                {
                    while (!HasMonthFile(time) && time < currtime)
                        time.AddYear(1);

                    while (!HasMonthFile(time))
                        time.AddYear(-1);
                }
            }

            FYear = time.GetYear();
        }
    }
}

/*##########################################################################
#
#   Name       : THeatWebPage::DecodeReq
#
#   Purpose....: Decode req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THeatWebPage::DecodeReq(const char *ReqStr)
{
    const char *ptr;
    const char *bptr;
    bool ok = false;

    ptr = strstr(ReqStr, "web");
    if (ptr)
    {
        ptr += 3;
        if (*ptr == 0)
            ok = true;
        else if (*ptr == '/' || *ptr == '\\')
        {
            ptr++;
            bptr = ptr;
            ptr = strstr(bptr, "wind");
            if (ptr && ptr == bptr)
            {
                FReqType = REQ_WIND;
                ok = true;
                ptr += strlen("wind");
            }
            
            if (!ok)
            {
                ptr = strstr(bptr, "solar");
                if (ptr && ptr == bptr)
                {
                    FReqType = REQ_SOLAR;
                    ok = true;
                    ptr += strlen("solar");
                }
            }

            if (!ok)
            {
                ptr = strstr(bptr, "power");
                if (ptr && ptr == bptr)
                {
                    FReqType = REQ_SOLAR_WIND;
                    ok = true;
                    ptr += strlen("power");
                }
            }

            if (ok)
            {
                if (strlen(ptr) <= 1)
                {
                    TDateTime currtime;

                    FYear = currtime.GetYear();
                    FMonth = currtime.GetMonth();
                    FDay = currtime.GetDay();
                    FUseDay = true;
                    FUseMonth = true;
                }
                else
                {
                    FUseDay = false;
                    FUseMonth = false;

                    ptr++;
                    FYear = atoi(ptr);
                    if (FYear < 2010 || FYear > 2100)
                        ok = false;

                    if (ok)
                    {
                        ptr = strchr(ptr, '/');
                        if (ptr)
                        {
                            ptr++;
                            FMonth = atoi(ptr);
                            FUseMonth = true;

                            if (FMonth < 1 || FMonth > 12)
                                ok = false;

                            if (ok)
                            {
                                ptr = strchr(ptr, '/');

                                if (ptr)
                                {
                                    ptr++;
                                    FDay = atoi(ptr);
                                    FUseDay = true;

                                    if (FDay < 1 || FDay > 31)
                                        ok = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return ok;
}

/*##########################################################################
#
#   Name       : THeatWebPage::DecodeTime
#
#   Purpose....: Decode time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::DecodeTime(THttpParam *Param)
{
    const char *ptr;

    if (Param)
    {
        ptr = Param->GetParam("year");
        if (ptr)
        {
            FYear = atoi(ptr);
            FMonth = 1;
            FDay = 1;

            ptr = Param->GetParam("month");
            if (ptr)
            {
                FMonth = atoi(ptr);
                FUseMonth = true;

                ptr = Param->GetParam("day");
                if (ptr)
                {
                    FDay = atoi(ptr);
                    FUseDay = true;
                }
            }
        }
    }
}

/*##########################################################################
#
#   Name       : THeatWebPage::SendAnswer
#
#   Purpose....: Send answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::SendAnswer()
{
    char str[80];

    Write("<!DOCTYPE html>\r\n");
    Write("<html>\r\n");
    Write("<head>\r\n");
    Write(" <meta charset=\"utf-8\">\r\n");
    Write(" <title>Heat control system</title>\r\n");
    Write(" <script src=\"https://cdn.zingchart.com/zingchart.min.js\"></script>\r\n");
    Write(" <style>\r\n");
    Write("  html,\r\n");
    Write("  body {\r\n");
    Write("  height: 100%;\r\n");
    Write("  width: 100%;\r\n");
    Write("  margin: 0;\r\n");
    Write("  padding: 0;\r\n");
    Write(" }\r\n\r\n");
    Write(" .chart--container {\r\n");
    Write("  height: 90%;\r\n");
    Write("  width: 100%;\r\n");
    Write("  min-height: 150px;\r\n");
    Write(" }\r\n\r\n");
    Write(" .nav {\r\n");
    Write("  height: 10%;\r\n");
    Write("  width: 100%;\r\n");
    Write(" }\r\n\r\n");
    Write(" .zc-ref {\r\n");
    Write("  display: none;\r\n");
    Write(" }\r\n\r\n");
    Write(" zing-grid[loading] {\r\n");
    Write("  height: 450px;\r\n");
    Write(" }\r\n");
    Write(" </style>\r\n");
    Write("</head>\r\n\r\n");
    Write("<body background=\"/blue.jpg\">\r\n");
    Write(" <!-- CHART CONTAINER -->\r\n");
    Write(" <div id=\"myChart\" class=\"chart--container\">\r\n");
    Write("  <a class=\"zc-ref\" href=\"https://www.zingchart.com\">Heat control system</a>\r\n");
    Write(" </div>\r\n");
    Write(" <div id=\"nav\" name=\"nav\">\r\n");

    Write("<form method=\"POST\" action=\"/web\">\r\n");

    if (FUseDay)
        Write("<input type=\"hidden\" name=\"daydia\" value=\"1\">\r\n");
    else
    {
        if (FUseMonth)
            Write("<input type=\"hidden\" name=\"monthdia\" value=\"1\">\r\n");
        else
            Write("<input type=\"hidden\" name=\"yeardia\" value=\"1\">\r\n");
    }

    sprintf(str, "<input type=\"hidden\" name=\"year\" value=\"%d\">\r\n", FYear);
    Write(str);

    sprintf(str, "<input type=\"hidden\" name=\"month\" value=\"%d\">\r\n", FMonth);
    Write(str);

    sprintf(str, "<input type=\"hidden\" name=\"day\" value=\"%d\">\r\n", FDay);
    Write(str);

    switch (FReqType)
    {
        case REQ_SOLAR:
            Write("<input type=\"hidden\" name=\"solar\" value=\"1\">\r\n");
            Write("<input type=\"Submit\" value=\"solar & wind\" name=\"power\">\r\n");
            Write("<input type=\"Submit\" value=\"wind only\" name=\"wind\">\r\n");
            break;

        case REQ_WIND:
            Write("<input type=\"hidden\" name=\"wind\" value=\"1\">\r\n");
            Write("<input type=\"Submit\" value=\"solar & wind\" name=\"power\">\r\n");
            Write("<input type=\"Submit\" value=\"solar only\" name=\"solar\">\r\n");
            break;

        case REQ_SOLAR_WIND:
            Write("<input type=\"hidden\" name=\"power\" value=\"1\">\r\n");
            Write("<input type=\"Submit\" value=\"solar only\" name=\"solar\">\r\n");
            Write("<input type=\"Submit\" value=\"wind only\" name=\"wind\">\r\n");
            break;
    }

    if (FUseDay)
    {
        Write("<br>\r\n");
        Write("<input type=\"Submit\" value=\"month\" name=\"monthdia\">\r\n");
        Write("<input type=\"Submit\" value=\"year\" name=\"yeardia\">\r\n");
        Write("<br>\r\n");

        if (HasPrevDay())
            Write("<input type=\"Submit\" value=\"prev\" name=\"prev\">\r\n");

        if (HasNextDay())
            Write("<input type=\"Submit\" value=\"next\" name=\"next\">\r\n");
    }
    else
    {
        if (FUseMonth)
        {
            Write("<br>\r\n");
            Write("<input type=\"Submit\" value=\"day\" name=\"daydia\">\r\n");
            Write("<input type=\"Submit\" value=\"year\" name=\"yeardia\">\r\n");
            Write("<br>\r\n");

            if (HasPrevMonth())
                Write("<input type=\"Submit\" value=\"prev\" name=\"prev\">\r\n");
   
            if (HasNextMonth())
                Write("<input type=\"Submit\" value=\"next\" name=\"next\">\r\n");
        }
        else
        {
            Write("<br>\r\n");
            Write("<input type=\"Submit\" value=\"day\" name=\"daydia\">\r\n");
            Write("<input type=\"Submit\" value=\"month\" name=\"monthdia\">\r\n");
            Write("<br>\r\n");

            if (HasPrevYear())
                Write("<input type=\"Submit\" value=\"prev\" name=\"prev\">\r\n");
   
            if (HasNextYear())
                Write("<input type=\"Submit\" value=\"next\" name=\"next\">\r\n");
        }
    }

    Write("</form>\r\n");

    Write(" </div>\r\n");
    Write(" <script>\r\n");
//    Write("  ZC.LICENSE = [\"569d52cefae586f634c54f86dc99e6a9\", \"b55b025e438fa8a98e32482b5f768ff5\"];\r\n");
    Write("  window.addEventListener('load', () => {\r\n");
    Write("   zingchart.render({\r\n");
    Write("    id: 'myChart',\r\n");
    Write("    dataurl: '/json/");

    switch (FReqType)
    {
        case REQ_WIND:
            Write("wind");
            break;

        case REQ_SOLAR:
            Write("solar");
            break;

        case REQ_SOLAR_WIND:
            Write("power");
            break;
    }

    sprintf(str, "/%d", FYear);        
    Write(str);

    if (FUseMonth)
    {
        sprintf(str, "/%d", FMonth);        
        Write(str);

        if (FUseDay)
        {
            sprintf(str, "/%d", FDay);        
            Write(str);
        }
    }

    Write("',\r\n");

    Write("    height: '100%',\r\n");
    Write("    width: '100%'\r\n");
    Write("   });\r\n");
    Write("  });\r\n");
    Write(" </script>\r\n");
    Write("</body>\r\n");
    Write("</html>\r\n");

    SendData("text/html");
}

/*##########################################################################
#
#   Name       : THeatWebPage::Get
#
#   Purpose....: Get page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::Get(const char *MatchName, const char *UrlName, THttpParam *Param)
{
    bool ok;

    ok = DecodeReq(MatchName);
    if (ok)
    {
        DecodeTime(Param);
        SendAnswer();
    }
    else
        WriteError(400);
}

/*##########################################################################
#
#   Name       : THeatWebPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::Post(const char *MatchName, const char *UrlName, THttpParam *Param)
{
    bool ok;

    ok = DecodeReq(MatchName);
    if (ok)
    {
        DecodeTime(Param);
        SendAnswer();
    }
    else
        WriteError(400);
}

/*##########################################################################
#
#   Name       : THeatWebPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatWebPage::Post(const char *Var, const char *Val)
{
    if (!strcmp(Var, "yeardia"))
    {
        FUseDay = false;
        FUseMonth = false;
        FDay = 1;
        FMonth = 1;
        Fixup();
    }
    if (!strcmp(Var, "monthdia"))
    {
        FUseDay = false;
        FUseMonth = true;
        FDay = 1;
        Fixup();
    }
    else if (!strcmp(Var, "daydia"))
    {
        FUseDay = true;
        FUseMonth = true;
        Fixup();
    }
    else if (!strcmp(Var, "wind"))
        FReqType = REQ_WIND;
    else if (!strcmp(Var, "solar"))
        FReqType = REQ_SOLAR;
    else if (!strcmp(Var, "power"))
        FReqType = REQ_SOLAR_WIND;
    else if (!strcmp(Var, "year"))
        FYear = atoi(Val);
    else if (!strcmp(Var, "month"))
        FMonth = atoi(Val);
    else if (!strcmp(Var, "day"))
        FDay = atoi(Val);
    else if (!strcmp(Var, "prev"))
        GotoPrev();
    else if (!strcmp(Var, "next"))
        GotoNext();
}

/*##########################################################################
#
#   Name       : WebSocketThread
#
#   Purpose....: Web socket thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void WebSocketThread(void *ptr)
{
    THeatHttpServerFactory fact(80, 10, BUF_SIZE);
    THeatJsonDirFactory jsondir("json");
    THeatWebDirFactory webdir("web");

    fact.AddCustomDir(&jsondir);
    fact.AddCustomDir(&webdir);
    fact.RootDir = "d:/www";

    for (;;)
        fact.WaitForever();
}

/*##########################################################################
#
#   Name       : InitWeb
#
#   Purpose....: Init web
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitWeb()
{
    RdosCreateThread(WebSocketThread, "Web listner", 0, STACK_SIZE);
}
