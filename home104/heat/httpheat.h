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
# httpheat
# Http for heat class
#
########################################################################*/

#ifndef _HTTPHEAT_H
#define _HTTPHEAT_H

#include "httpfact.h"
#include "httpcust.h"
#include "ws2300.h"
#include "circ.h"
#include "vp.h"
#include "log.h"
#include "linxaxis.h"
#include "linyaxis.h"
#include "timeaxis.h"
#include "chart.h"
#include "jpeg.h"

class TRad;

class THttpTablePage : public THttpCustomPage
{
public:
	THttpTablePage(THttpCommand *Cmd, const char *FileName);
	virtual ~THttpTablePage();

protected:
    void WriteCenteredFieldHeader(TFile &File, int RelWidth);
    void WriteRightFieldHeader(TFile &File, int RelWidth);
    void WriteLeftFieldHeader(TFile &File, int RelWidth);
    void WriteFieldFooter(TFile &File);

    void WriteFloat1(TFile &File, long double val);

};

class THttpHeatPage : public THttpTablePage
{
public:
	THttpHeatPage(THttpCommand *Cmd, const char *FileName);
	virtual ~THttpHeatPage();

protected:
	virtual void Get(const char *Name);
};

class THttpHeatPageFactory : public THttpCustomPageFactory
{
public:
	THttpHeatPageFactory(const char *ReqName);
	virtual ~THttpHeatPageFactory();

	virtual THttpCustomPage *Create(THttpCommand *cmd, const char *Param);

protected:
};

class THttpWs2300Page : public THttpTablePage
{
public:
	THttpWs2300Page(THttpCommand *Cmd, const char *FileName);
	virtual ~THttpWs2300Page();

protected:
	virtual void Get(const char *Name);

};

class THttpWs2300PageFactory : public THttpCustomPageFactory
{
public:
	THttpWs2300PageFactory(const char *ReqName);
	virtual ~THttpWs2300PageFactory();

	virtual THttpCustomPage *Create(THttpCommand *cmd, const char *Param);

protected:
};

class THttpRadPage : public THttpCustomPage
{
public:
	THttpRadPage(THttpCommand *Cmd, const char *FileName, const char *Param);
	virtual ~THttpRadPage();

protected:
	virtual void Get(const char *Name);

    void CreateTempJpeg(int address, TDateTime &from, TDateTime &to);
    void DeleteTempJpeg();
    void WriteHistoryTemp(int address, int year, int month, int day);
    int CreateHistoryTempJpeg(int address, int year, int month, int day);
    void WriteTemp(int address);

	TJpegBitmapDevice *FJpeg;
	TFont *FFont;
	TLinYAxis *FTempAxis;
	TTimeXAxis *FTimeScaleAxis;
	TTimeXAxis *FTimeAxis;
	TChart *FTempChart;


};

class THttpRadPageFactory : public THttpCustomDirFactory
{
public:
	THttpRadPageFactory(const char *ReqName);
	virtual ~THttpRadPageFactory();

	virtual THttpCustomPage *Create(THttpCommand *cmd, const char *Param);

protected:
};

void AddHttpRad(TRad *Rad);
void AddHttpWs2300(TWs2300 *ws);
void AddHttpCirc(TCirc *circ);
void AddHttpVp(TVp *vp);
void AddHttpLog(TLog *log);
void InitHeatHttp();
void HttpUpdate();
void HttpSetVpOn();
void HttpSetVpOff();
void HttpSetLightOn();
void HttpSetLightOff();

#endif
