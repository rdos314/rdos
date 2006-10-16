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
THttpCustomPage::THttpCustomPage(THttpCommand *Cmd, const char *FileName, const char *Param)
  : FFileName(FileName),
    FParam(Param)
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
int THttpCustomPage::PushFile(TPathName &path, const char *ContentType, int ReloadTimeout)
{
	return FCmd->PushFile(path, ContentType, ReloadTimeout);
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
	FCmd->GetFile(Name);
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
#   Name       : THttpCustomPage::Post
#
#   Purpose....: Post callback for var & value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::Post(const char *Var, const char *Val)
{
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
	return new THttpCustomPage(Cmd, tempname.GetData(), "");
}

/*##########################################################################
#
#   Name       : THttpCustomDirFactory::THttpCuustomDirFactory
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomDirFactory::THttpCustomDirFactory(const char *ReqName)
  : FReqName(ReqName)
{
}

/*##########################################################################
#
#   Name       : THttpCustomDirFactory::~THttpCustomDirFactory
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomDirFactory::~THttpCustomDirFactory()
{
}

/*##########################################################################
#
#   Name       : THttpCustomDirFactory::CreateUniqueFile
#
#   Purpose....: Create an unique filename
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString THttpCustomDirFactory::CreateUniqueFile(THttpCommand *Cmd)
{
    return Cmd->FServer->CreateUniqueFile();
}

/*##########################################################################
#
#   Name       : THttpCustomDirFactory::Create
#
#   Purpose....: Create custom page instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THttpCustomDirFactory::Create(THttpCommand *Cmd, const char *Param)
{
	TString tempname = CreateUniqueFile(Cmd);
	return new THttpCustomPage(Cmd, tempname.GetData(), Param);
}
