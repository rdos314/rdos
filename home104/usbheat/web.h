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
# web.h
# Heat pump class
#
########################################################################*/

#ifndef WEB_H
#define WEB_H

#include "httpfact.h"
#include "json.h"
#include "file.h"

void InitWeb();

class TPowerHttpServerFactory : public THttpSocketServerFactory
{
public:
    TPowerHttpServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TPowerHttpServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);

protected:
};

class TPowerHttpServer : public THttpSocketServer
{
public:
    TPowerHttpServer(const char *Name, int StackSize, TTcpSocket *Socket);
    ~TPowerHttpServer();
};

class TPowerJsonDirFactory : public THttpCustomDirFactory
{
public:
    TPowerJsonDirFactory(const char *ReqName);
    virtual ~TPowerJsonDirFactory();

    virtual THttpCustomPage *Create(THttpCommand *cmd);
};

class TPowerJsonPage : public THttpCustomPage
{
public:
    TPowerJsonPage(THttpCommand *Cmd);
    virtual ~TPowerJsonPage();

protected:
    void CreateTitle(TJsonCollection *obj);
    void CreateLegend(TJsonCollection *obj);
    void CreatePlot(TJsonCollection *obj);
    void CreatePlotArea(TJsonCollection *obj);
    void CreateScaleX(TJsonCollection *obj, TDateTime &time);
    void CreateScaleY(TJsonCollection *obj);
    void CreateCrosshairX(TJsonCollection *obj);
    void CreateCrosshairY(TJsonCollection *obj);
    void CreateShapes(TJsonCollection *obj);
    void CreateToolTip(TJsonCollection *obj);
    void CreateDataSerie(TJsonArrayCollection *obj);

    bool DecodeReq(const char *ReqStr);
    void SendAnswer();
    TFile *GetDayFile();
    TFile *GetMonthFile();
    char *ReadFile(TFile *file);

    void AddDayData(TJsonArrayCollection *obj, char *text, int col);
    void AddMonthData(TJsonArrayCollection *obj, char *text, int col);
    void AddYearData(TJsonArrayCollection *obj, double val[12], bool valid[12]);
    double GetMonthTotal(char *text, int col);

    virtual void Get(const char *MatchName, const char *UrlName, THttpParam *Param);
    virtual void Post(const char *MatchName, const char *UrlName, THttpParam *Param);
    virtual void Post(const char *Var, const char *Val);

    int FReqType;
    int FYear;
    int FMonth;
    int FDay;
    bool FUseDay;
    bool FUseMonth;
};

class TPowerWebDirFactory : public THttpCustomDirFactory
{
public:
    TPowerWebDirFactory(const char *ReqName);
    virtual ~TPowerWebDirFactory();

    virtual THttpCustomPage *Create(THttpCommand *cmd);
};

class TPowerWebPage : public THttpCustomPage
{
public:
    TPowerWebPage(THttpCommand *Cmd);
    virtual ~TPowerWebPage();

protected:
    bool DecodeReq(const char *ReqStr);
    void DecodeTime(THttpParam *Param);
    void SendAnswer();

    bool HasDayFile(TDateTime &time);
    bool HasMonthFile(TDateTime &time);

    bool HasNextDay();
    bool HasPrevDay();
    bool HasPrevMonth();
    bool HasNextMonth();
    bool HasPrevYear();
    bool HasNextYear();

    void GotoPrev();
    void GotoNext();
    void Fixup();

    virtual void Get(const char *MatchName, const char *UrlName, THttpParam *Param);
    virtual void Post(const char *MatchName, const char *UrlName, THttpParam *Param);
    virtual void Post(const char *Var, const char *Val);

    int FSubmitType;
    int FReqType;
    int FYear;
    int FMonth;
    int FDay;
    bool FUseDay;
    bool FUseMonth;
};

#endif
