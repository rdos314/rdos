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
#   Name       : THttpCustomPage::Write
#
#   Purpose....: Write header & file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::Write(TFile &File, int ErrorCode, const char *ContentType)
{
	char *Buf = new char[256];
	int count;

	FCmd->WriteStartHeader(ErrorCode);
	FCmd->WriteOption("Accept-Ranges", "bytes");
	FCmd->WriteOption("Content-Type", ContentType);
	FCmd->WriteLongOption("Content-Length", File.GetSize());
	FCmd->WriteEndHeader();

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
	TFile File(FFileName.GetData(), 0);

	File.Write("<html><body><h2>RDOS Webserver</h2>\r\n");
	File.Write("Default page for (");
	File.Write(FFileName.GetData());
	File.Write(")<br>\r\n");
	File.Write("</body></html>\r\n");

	Write(File, 200, "text/html");
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
