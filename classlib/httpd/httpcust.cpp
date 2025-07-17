/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
THttpCustomPage::THttpCustomPage(THttpCommand *Cmd)
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
}

/*##########################################################################
#
#   Name       : THttpCustomPage::GetUser
#
#   Purpose....: Get logged-in user
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *THttpCustomPage::GetUser()
{
    if (FCmd->FAuthOk)
        return FCmd->FUser.GetData();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : THttpCustomPage::WriteError
#
#   Purpose....: Write error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::WriteError(int ErrorCode)
{
    FCmd->WriteError(ErrorCode);
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
#   Name       : THttpCustomPage::Write
#
#   Purpose....: Write string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::Write(const char *str)
{
    FData += str;
}

/*##########################################################################
#
#   Name       : THttpCustomPage::SendData
#
#   Purpose....: Send data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPage::SendData(const char *ContentType)
{
    FCmd->SendData(FData.GetData(), ContentType);
    FData = "";
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
void THttpCustomPage::Get(const char *MatchName, const char *ReqName, THttpParam *Param)
{
        FCmd->GetFile(ReqName);
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
void THttpCustomPage::Post(const char *MatchName, const char *ReqName, THttpParam *Param)
{
    Get(MatchName, ReqName, Param);
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
{
    FReqNameList.AddLast(TString(ReqName));
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
    return new THttpCustomPage(Cmd);
}

/*##########################################################################
#
#   Name       : THttpCustomPageFactory::AddName
#
#   Purpose....: Add another request name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomPageFactory::AddName(const char *ReqName)
{
    FReqNameList.AddLast(TString(ReqName));
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
{
    FReqNameList.AddLast(TString(ReqName));
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
#   Name       : THttpCustomDirFactory::Create
#
#   Purpose....: Create custom page instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THttpCustomDirFactory::Create(THttpCommand *Cmd)
{
        return new THttpCustomPage(Cmd);
}

/*##########################################################################
#
#   Name       : THttpCustomDirFactory::AddName
#
#   Purpose....: Add another request name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCustomDirFactory::AddName(const char *ReqName)
{
    FReqNameList.AddLast(TString(ReqName));
}
