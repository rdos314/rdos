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
# httpcust.cpp
# HTTP Custom page class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "path.h"
#include "httpcust.h"
#include "httpcmd.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : THttpCustomPage::THttpCustomPage
#
#   Purpose....: Constructor for THttpCustomPage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage::THttpCustomPage(THttpCommand *Cmd, const char *FileName)
  : FFileName(FileName)
{
    FCmd = Cmd;
}

/*##########################################################################
#
#   Name       : THttpCustomPage::~THttpCustomPage
#
#   Purpose....: Destructor for THttpArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage::~THttpCustomPage()
{
	TPathName path(FFileName);

    path.DeleteFile();
}

/*##########################################################################
#
#   Name       : THttpCustomPage::Execute
#
#   Purpose....: Execute page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::Execute()
{
    int count;
    char *Buf = new char[256];
    TFile File(FFileName.GetData(), 0);
    
    File.Write("<html><body><h2>RDOS Webserver</h2>\r\n");
    File.Write("Default page for (");
    File.Write(FFileName.GetData());
    File.Write(")<br>\r\n");
    File.Write("</body></html>\r\n");

    FCmd->WriteStartHeader(200);
    FCmd->WriteOption("Accept-Ranges", "bytes");
    FCmd->WriteOption("Content-Type", "text/html");
	FCmd->WriteLongOption("Content-Length", File.GetSize());

    File.SetPos(0);

    count = File.Read(Buf, 256);
    while (count)
	{
        FCmd->FServer->Write(Buf, count);
        count = File.Read(Buf, 256);
    }
    delete Buf;
}

/*##########################################################################
#
#   Name       : THttpCustomPageFactory::THttpCuustomPageFactory
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPageFactory::THttpCustomPageFactory(const char *ReqName)
  : FReqName(ReqName)
{
}

/*##########################################################################
#
#   Name       : THttpCustomPageFactory::~THttpCustomPageFactory
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPageFactory::~THttpCustomPageFactory()
{
}

/*##########################################################################
#
#   Name       : THttpCustomPageFactory::Create
#
#   Purpose....: Create custom page instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THttpCustomPageFactory::Create(THttpCommand *Cmd)
{
    TString tempname = Cmd->FServer->CreateUniqueFile();
	THttpCustomPage *page = new THttpCustomPage(Cmd, tempname.GetData());

    return page;
}
