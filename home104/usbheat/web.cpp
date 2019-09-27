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
    switch (FReqType)
    {
        case REQ_WIND:
            obj->AddString("text", "Wind power");
            break;

        case REQ_SOLAR:
            obj->AddString("text", "Solar power");
            break;
    }

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

    item = obj->AddCollection("item");
    item->AddString("fontColor", "#E3E3E5");

    obj->AddString("lineColor", "#E3E3E5");
    obj->AddDateTime("min-Value", time, false);

    if (FUseDay)
        obj->AddString("step", "minute");
    else
    {
        if (FUseMonth)
            obj->AddString("step", "day");
        else
            obj->AddString("step", "month");
    }

    transform = obj->AddCollection("transform");
    transform->AddString("type", "date");
    transform->AddString("all", "%G:%i");
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
    TJsonCollection *label;
    TJsonCollection *guide;
    TJsonCollection *item;
    TJsonCollection *transform;

    label = obj->AddCollection("label");

    guide = obj->AddCollection("guide");
    guide->AddString("lineStyle", "dashed");

    item = obj->AddCollection("item");
    item->AddString("fontColor", "#E3E3E5");

    obj->AddInt("min-value", 0);

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
TFile *THeatJsonPage::GetDayFile(int *col)
{
    char str[80];
    char root[40];

    switch (FReqType)
    {
        case REQ_WIND:
            strcpy(root, "e:/data/power");
            *col = 1;
            break;

       case REQ_SOLAR:
            strcpy(root, "e:/data/power");
            *col = 0;
            break;
    }

    sprintf(str, "%s/%d/%d/%d.csv", root, FYear, FMonth, FDay);
    return new TFile(str);
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
    TJsonDoubleArray *arr;
    TFile *file;
    int i;
    int col;
    int size;
    char *text;
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

    file = GetDayFile(&col);
    if (file->IsOpen())
    {
        size = file->GetSize();
        text = new char[size + 1];
        file->Read(text, size);
        text[size] = 0;

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
                        *rptr = 0;
                        val = strtod(ptr, &end);
                        arr->Add(val);
                        time++;
                    }
                }
            }
            ptr = next;
        }
        delete text;
    }

    delete file;

    obj->AddString("lineColor", "#E3E3E5");    
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

    time.AddHour(-1);

    root->AddString("type", "line");
    root->AddString("backgroundColor", "#2C2C39");

    obj = root->AddCollection("title");
    CreateTitle(obj);    

//    obj = root->AddCollection("legend");
//    CreateLegend(obj);    

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
                    if (FYear < 2019 || FYear > 2100)
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
        if (*ptr == '/' || *ptr == '\\')
        {
            ptr++;
            bptr = ptr;
            ptr = strstr(bptr, "wind");
            if (ptr && ptr == bptr)
            {
                FReqType = REQ_WIND;
                ok = true;
            }
            
            if (!ok)
            {
                ptr = strstr(bptr, "solar");
                if (ptr && ptr == bptr)
                {
                    FReqType = REQ_SOLAR;
                    ok = true;
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
    bool def = true;
    const char *ptr;

    if (Param)
    {
        ptr = Param->GetParam("year");
        if (ptr)
        {
            def = false;
            FYear = atoi(ptr);
            FMonth = 1;
            FDay = 1;
            FUseMonth = false;
            FUseDay = false;

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

    if (def)
    {
        TDateTime time;
        FYear = time.GetYear();
        FMonth = time.GetMonth();
        FDay = time.GetDay();
        FUseMonth = true;
        FUseDay = true;
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
    Write("  height: 100%;\r\n");
    Write("  width: 100%;\r\n");
    Write("  min-height: 150px;\r\n");
    Write(" }\r\n\r\n");
    Write(" .zc-ref {\r\n");
    Write("  display: none;\r\n");
    Write(" }\r\n\r\n");
    Write(" zing-grid[loading] {\r\n");
    Write("  height: 450px;\r\n");
    Write(" }\r\n");
    Write(" </style>\r\n");
    Write("</head>\r\n\r\n");
    Write("<body>\r\n");
    Write(" <!-- CHART CONTAINER -->\r\n");
    Write(" <div id=\"myChart\" class=\"chart--container\">\r\n");
    Write("  <a class=\"zc-ref\" href=\"https://www.zingchart.com\">Heat control system</a>\r\n");
    Write(" </div>\r\n");
    Write(" <script>\r\n");
    Write("  ZC.LICENSE = [\"569d52cefae586f634c54f86dc99e6a9\", \"b55b025e438fa8a98e32482b5f768ff5\"];\r\n");
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
    }

/*
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

*/

    Write("',\r\n");

    Write("    height: 100%,\r\n");
    Write("    width: 100%\r\n");
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
