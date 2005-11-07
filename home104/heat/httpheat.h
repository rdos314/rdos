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

class TRad;

class THttpHeatPage : public THttpCustomPage
{
public:
	THttpHeatPage(THttpCommand *Cmd, const char *FileName);
	virtual ~THttpHeatPage();

protected:
    void WriteCenteredFieldHeader(TFile &File, int RelWidth);
    void WriteRightFieldHeader(TFile &File, int RelWidth);
    void WriteFieldFooter(TFile &File);
    
	virtual void Get(const char *Name);

};

class THttpHeatPageFactory : public THttpCustomPageFactory
{
public:
	THttpHeatPageFactory(const char *ReqName);
	virtual ~THttpHeatPageFactory();

	virtual THttpCustomPage *Create(THttpCommand *cmd);

protected:
};

void AddHttpRad(TRad *Rad);
void AddHttpWs2300(TWs2300 *ws);
void InitHeatHttp();
void HttpUpdate();

#endif
