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

#include "rdos.h"
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
#   Name       : THttpCustomPage::WriteFile
#
#   Purpose....: Write header & file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::WriteFile(TPathName &path, const char *ContentType)
{
    FCmd->WriteFile(path, ContentType);
}

/*##########################################################################
#
#   Name       : THttpCustomPage::StartPush
#
#   Purpose....: Start server push
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::StartPush()
{
    FCmd->StartPush();
}

/*##########################################################################
#
#   Name       : THttpCustomPage::PushFile
#
#   Purpose....: Push header & file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCustomPage::PushFile(TPathName &path, const char *ContentType)
{
    return FCmd->PushFile(path, ContentType);
}

/*##########################################################################
#
#   Name       : THttpCustomPage::Get
#
#   Purpose....: Get page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::Get(const char *Name)
{
	int i = 0;
	char str[50];

	StartPush();

	TFile File(FFileName.GetData(), 0);

	while (FCmd->IsOpen())
	{
		File.SetSize(0);
		File.SetPos(0);

		File.Write("<html><body><h2>RDOS Webserver</h2>\r\n");
		File.Write("Default page for (");
		File.Write(FFileName.GetData());
		File.Write(")<br>\r\n");

		sprintf(str, "%d", i);
		i++;

		File.Write(str);
		File.Write("<br>\r\n");

		File.Write("</body></html>\r\n");

		if (!PushFile(FFileName.GetData(), "text/html"))
		    break;

		RdosWaitMilli(1000);
	}
}

/*##########################################################################
#
#   Name       : THttpCustomPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::Post(const char *Name)
{
    Get(Name);
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
#   Name       : THttpCustomPageFactory::CreateUniqueFile
#
#   Purpose....: Create an unique filename
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString THttpCustomPageFactory::CreateUniqueFile(THttpCommand *Cmd)
{
    return Cmd->FServer->CreateUniqueFile();
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
	TString tempname = CreateUniqueFile(Cmd);
	return new THttpCustomPage(Cmd, tempname.GetData());
}
