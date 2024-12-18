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
# httpcmd.cpp
# HTTP Command base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include "base64.h"

#include "httpcmd.h"
#include "httpserv.h"

#define FALSE 0
#define TRUE !FALSE

int THttpCommand::ErrorLevel = 0;

static char MonthNames[12][4] = {
                                    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                                };                                    

/*##########################################################################
#
#   Name       : THttpArg::THttpParam
#
#   Purpose....: Constructor for THttpParam
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpParam::THttpParam(const char *name, const char *value)
  : FName(name),
    FValue(value)
{
    FList = 0;
}

/*##########################################################################
#
#   Name       : THttpParam::~THttpParam
#
#   Purpose....: Destructor for THttpParam
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpParam::~THttpParam()
{
}

/*##########################################################################
#
#   Name       : THttpParam::GetParam
#
#   Purpose....: Get param name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *THttpParam::GetParam(const char *Name)
{
    if (FName == Name)
        return FValue.GetData();
    else
    {
        if (FList)
            return FList->GetParam(Name);
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : THttpArg::THttpArg
#
#   Purpose....: Constructor for THttpArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpArg::THttpArg(const char *name)
  : FName(name)
{
    ptr = (char *)FName.GetData();
    
    FList = 0;
}

/*##########################################################################
#
#   Name       : THttpArg::~THttpArg
#
#   Purpose....: Destructor for THttpArg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpArg::~THttpArg()
{
}

/*##########################################################################
#
#   Name       : THttpCommand::THttpCommand
#
#   Purpose....: Constructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCommand::THttpCommand(THttpSocketServer *Server, TString Method, TString Param)
  : FMethod(Method),
        FCmdLine(Param)
{
    FServer = Server;
    FArgList = 0;
    FParamList = 0;
    FOptCount = 0;
    FOptList = 0;
    FContentData = 0;
    FContentSize = 0;
    FAuthOk = FALSE;
}

/*##########################################################################
#
#   Name       : THttpCommand::~THttpCommand
#
#   Purpose....: Destructor for command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCommand::~THttpCommand()
{
    THttpParam *param;
    THttpArg *arg;
    THttpOption *opt;

    arg = FArgList;
    while (arg)
    {
        FArgList = arg->FList;
        delete arg;
        arg = FArgList;
    }

    param = FParamList;
    while (param)
    {
        FParamList = param->FList;
        delete param;
        param = FParamList;
    }

    opt = FOptList;
    while (opt)
    {
        FOptList = opt->FList;
        delete opt;
        opt = FOptList;
    }

    if (FContentData)
        delete FContentData;
}

/*##########################################################################
#
#   Name       : THttpParser::SkipOptDelim
#
#   Purpose....: Skip to next option delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpCommand::SkipOptDelim(char *p)
{
    int ch, quote;
    int more;

    quote = 0;
    for (;;)
    {
        ch = *p;

        if (!ch)
            break;

        more = !(iscntrl(ch) || ch == ':');

        if (!quote && !more)
            break;

        if (quote == ch)
            quote = 0;
        else
            if (strchr("\"", ch))
                quote = ch;
        p++;
    }
    return p;
}

/*##########################################################################
#
#   Name       : THttpCommand::DecodeTime
#
#   Purpose....: Decode a time option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime THttpCommand::DecodeTime(THttpOption *opt)
{
    char str[40];
    const char *ptr;
    int year, month, day;
    int hour, min, sec;
    int ok;

    if (opt->FArgList && opt->FArgList->FList)
        ptr = opt->FArgList->FList->FName.GetData();
    else
        ptr = 0;

    if (ptr)
    {
        ok = (sscanf(ptr, "%d", &day) == 1);
        if (ok)
        {
            while (*ptr && (isdigit(*ptr) || *ptr == ' '))
                ptr++;

            memcpy(str, ptr, 3);
            str[3] = 0;

            for (month = 1; month <= 12; month++)
                if (!strcmp(str, MonthNames[month - 1]))
                    break;

            if (month > 12)
                ok = FALSE;
        }

        if (ok)
        {
            ptr += 3;
            ok = (sscanf(ptr, "%04d %02d:%02d:%02d", 
                                &year, &hour, &min, &sec) == 4);
        }
    }    
    else
        ok = FALSE;

    if (ok)
        return TDateTime(year, month, day, hour, min, sec, 0, 0);
    else
        return TDateTime();
}

/*##########################################################################
#
#   Name       : THttpCommand::FindOption
#
#   Purpose....: Find an option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpOption *THttpCommand::FindOption(const char *name)
{
    THttpOption *curr;
    TString Name(name);

    curr = FOptList;

    while (curr)
    {
        if (curr->FName == Name)
            return curr;
        else
            curr = curr->FList;
    }

    return 0;
}

/*##########################################################################
#
#   Name       : THttpCommand::GetModifedSince
#
#   Purpose....: Get modified since date
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime THttpCommand::GetModifiedSince()
{
    THttpOption *opt = FindOption("If-Modified-Since");

    if (opt)
        return DecodeTime(opt);
    else
        return TDateTime();
}

/*##########################################################################
#
#   Name       : THttpCommand::CheckAuthorization
#
#   Purpose....: Check authorization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::CheckAuthorization(const char *param)
{
    int len;
    char *str;
    char *passw;

    if (strstr(param, "Basic"))
    {
        len = strlen(param);
        str = new char[len];
        
        DecodeBase64(param + 6, str);
        passw = strchr(str, ':');
        if (passw)
        {
            *passw = 0;
            passw++;
            
            if (FServer->OnAuthorize)
            {
                FUser = TString(str);
                FAuthOk = (*FServer->OnAuthorize)(FServer, str, passw);
            }
        }
                    
        delete str;
    }
}

/*##########################################################################
#
#   Name       : THttpCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::AddArg(const char *name)
{
    THttpArg *arg = new THttpArg(name);
    THttpArg *curr;

    arg->FList = 0;
    curr = FArgList;
   
    if (curr)
    {
        while (curr->FList)
            curr = curr->FList;

        curr->FList = arg;
    }
    else
        FArgList = arg;    
}

/*##########################################################################
#
#   Name       : THttpCommand::AddArg
#
#   Purpose....: Add an argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::AddArg(char *sBeg, char **sEnd)
{ 
    char *arg;

    *sEnd = SkipWord(sBeg);
    arg = THttpSocketServer::Unquote(sBeg, *sEnd);
    AddArg(arg);
    delete arg;
}

/*##########################################################################
#
#   Name       : THttpCommand::AddOpt
#
#   Purpose....: Add an option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::AddOpt(char *name, char *param)
{
    THttpOption *opt = new THttpOption(name, param);
    THttpOption *curr;

    if (!strcmp(name, "User-Agent"))
        FUserAgent = param;

    if (!strcmp(name, "Content-Length"))
        sscanf(param, "%d", &FContentSize);

    if (!strcmp(name, "Authorization"))
        CheckAuthorization(param);
            
    opt->FList = 0;
    curr = FOptList;
   
    if (curr)
    {
        while (curr->FList)
            curr = curr->FList;

        curr->FList = opt;
    }
    else
        FOptList = opt;    
}

/*##########################################################################
#
#   Name       : THttpCommand::AddParam
#
#   Purpose....: Add a parameter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpCommand::AddParam(char *p)
{
    THttpParam *param;
    THttpParam *curr;
    char *pstr = p;
    char *vstr = 0;
    char ch;

    while (*p)
    {
        if (*p == '=')
        {
            *p = 0;
            vstr = p + 1;
            break;
        }
        else
            p++;
    }

    if (vstr)
    {
        p = vstr;
        while (*p)
        {
            if (isalnum(*p))
                p++;
            else
            {
                ch = *p;
                *p = 0;

                param = new THttpParam(pstr, vstr);
                param->FList = 0;
                curr = FParamList;
   
                if (curr)
                {
                    while (curr->FList)
                        curr = curr->FList;

                    curr->FList = param;
                }
                else
                    FParamList = param;    

                *p = ch;
                return p;
            }
        }        
    }                           
    return p;
}

/*##########################################################################
#
#   Name       : THttpCommand::Split
#
#   Purpose....: Split line into arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::Split(char *s)
{
    char *start;
    char *pstart;

    if (s)
    {
        start = strchr(s, '?');
        if (start)
        {
            *start = 0;
            pstart = start + 1;
        
            start = SkipDelim(s);
            while (*start)
            {
                AddArg(start, &s);
                start = SkipDelim(s);
            }

            start = pstart;
                    
            while (start)
            {
                s = AddParam(pstart);
                start = strchr(s, '&');
                if (start)
                    pstart = start + 1;
            }               
        } 
        
        start = SkipDelim(s);
        while (*start)
        {
            AddArg(start, &s);
            start = SkipDelim(s);
        }
    }
}

/*##########################################################################
#
#   Name       : THttpCommand::Parse
#
#   Purpose....: Parse arguments
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::Parse(void *arg)
{
    THttpArg *argv;

    FArgCount = 0;

    argv = FArgList;    
    while (argv)
    {
        FArgCount++;    
        argv = argv->FList;
    }

    return E_None;
}

/*##########################################################################
#
#   Name       : THttpCommand::ScanCmdLine
#
#   Purpose....: Scan cmd line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::ScanCmdLine(char *line, void *arg)
{
    Split(line);

    if (Parse(arg) != E_None)
        return FALSE;
    else
        return TRUE;
}

/*##########################################################################
#
#   Name       : THttpCommand::IsOpen
#
#   Purpose....: Check if socket is open
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::IsOpen()
{
    return FServer->IsOpen();
}

/*##########################################################################
#
#   Name       : THttpCommand::IsEmpty
#
#   Purpose....: Check if socket is open
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::IsEmpty()
{
    return FServer->IsEmpty();
}

/*##########################################################################
#
#   Name       : THttpCommand::IsMSIE
#
#   Purpose....: Check if browser is Internet Explorer (doesn't handle
#                server push!)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::IsMSIE()
{
    const char *ptr = FUserAgent.GetData();

    if (strstr(ptr, "Opera"))
        return FALSE;

    if (strstr(ptr, "MSIE"))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteOption
#
#   Purpose....: Write option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteOption(const char *option, const char *val)
{
    FServer->Write(option);
    FServer->Write(": ");
    FServer->Write(val);
    FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteLongOption
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteLongOption(const char *option, long value)
{
    char str[40];

    FServer->Write(option);
    FServer->Write(": ");

    sprintf(str, "%ld", value);
    FServer->Write(str);
    FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteTimeOption
#
#   Purpose....: Write a time option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteTimeOption(const char *option, TDateTime &time)
{
    char str[40];

    FServer->Write(option);
    FServer->Write(": ");

    switch (time.GetDayOfWeek())
    {
        case 0:
            FServer->Write("Sun");
            break;

        case 1:
            FServer->Write("Mon");
            break;

        case 2:
            FServer->Write("Tue");
            break;

        case 3:
            FServer->Write("Wed");
            break;

        case 4:
            FServer->Write("Thu");
            break;

        case 5:
            FServer->Write("Fri");
            break;

        case 6:
            FServer->Write("Sat");
            break;
    }

    sprintf(str, ", %d ", time.GetDay());
    FServer->Write(str);

    FServer->Write(MonthNames[time.GetMonth() - 1]);

    sprintf(str, " %04d %02d:%02d:%02d GMT",
                            time.GetYear(),
                            time.GetHour(),
                            time.GetMin(),
                            time.GetSec());

    FServer->Write(str);
    FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::GetErrorText
#
#   Purpose....: Get error text for error code
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *THttpCommand::GetErrorText(int ErrorCode)
{
    switch (ErrorCode)
    {
        case 101:
            return "Switching Protocols";

        case 200:
            return "OK";

        case 304:
            return "NOT MODIFIED";

        case 401:
            return "UNATHORIZED";
                
        case 404:
            return "NOT FOUND";
            
        default:
            return "UNKNOWN ERROR";
    }
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteStartHeader
#
#   Purpose....: Write start of header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteStartHeader(int ErrorCode)
{
    char str[80];
    TDateTime CurrTime;

    if (FMajor)
    {
        sprintf(str, "HTTP/%d.%d %d ", FMajor, FMinor, ErrorCode);
        FServer->Write(str);
        FServer->Write(GetErrorText(ErrorCode));
        FServer->Write("\r\n");

        if (ErrorCode != 101)
        {
            WriteTimeOption("Date", CurrTime);
            WriteOption("Server", "RDOS");
        }
    }
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteEndHeader
#
#   Purpose....: Write end of header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteEndHeader()
{
    FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteError
#
#   Purpose....: Write error msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteError(int ErrorCode)
{
    char str[256];

    sprintf(str, "<html><body><h2>RDOS Webserver</h2>%s (%d)</body></html>",
    GetErrorText(ErrorCode), ErrorCode);

    WriteStartHeader(ErrorCode);

    if (ErrorCode == 401)
        WriteOption("WWW-Authenticate", "Basic");
    
    WriteOption("Content-Type", "text/html");
    WriteLongOption("Content-Length", strlen(str));
    WriteEndHeader();
    FServer->Write(str);
}

/*##########################################################################
#
#   Name       : THttpCommand::WriteFile
#
#   Purpose....: Write a file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::WriteFile(TPathName &path, const char *ContentType)
{
    int count;

    TFile file = path.OpenFile();
    TDateTime time(file.GetTime());

    if (time == GetModifiedSince())
    {
        WriteStartHeader(304);
        WriteEndHeader();
    }
    else
    {
        char *Buf = new char[512];

        WriteStartHeader(200);
        WriteTimeOption("Last-Modified", time);
        WriteOption("Accept-Ranges", "bytes");
        WriteOption("Content-Type", ContentType);
        WriteLongOption("Content-Length", (int)file.GetSize());
        WriteEndHeader();

        count = file.Read(Buf, 512);
        while (count)
        {
            FServer->Write(Buf, count);
            count = file.Read(Buf, 512);
        }
        delete Buf;

        FServer->Push();

    }
}

/*##########################################################################
#
#   Name       : THttpCommand::SendData
#
#   Purpose....: Send data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::SendData(const char *Data, const char *ContentType)
{
    int Size = strlen(Data);
    
    WriteStartHeader(200);
    WriteOption("Accept-Ranges", "bytes");
    WriteOption("Content-Type", ContentType);
    WriteLongOption("Content-Length", Size);
    WriteEndHeader();

    FServer->Write(Data, Size);
    FServer->Push();
}

/*##########################################################################
#
#   Name       : THttpCommand::StartPush
#
#   Purpose....: Start server push
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::StartPush()
{
    int MSIE = IsMSIE();

    WriteStartHeader(200);

    if (!MSIE)
    {
        WriteOption("Content-type", "multipart/x-mixed-replace;boundary=ThisRandomString");
        WriteEndHeader();
        FServer->Write("--ThisRandomString\r\n");
    }
}

/*##########################################################################
#
#   Name       : THttpCommand::PushFile
#
#   Purpose....: Push a file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::PushFile(TPathName &path, const char *ContentType, int ReloadTime)
{
    int count;
    char *Buf = new char[512];
    int MSIE = IsMSIE();

    TFile file = path.OpenFile();
    TDateTime time(file.GetTime());

    WriteOption("Content-Type", ContentType);
    WriteLongOption("Content-Length", (int)file.GetSize());
    WriteEndHeader();

    count = file.Read(Buf, 512);
    while (count)
    {
        FServer->Write(Buf, count);
        count = file.Read(Buf, 512);
    }

    if (MSIE)
    {
        sprintf(Buf, "<META HTTP-EQUIV=\"Refresh\" CONTENT=%d>\r\n", ReloadTime);
        FServer->Write(Buf);
    }
    else
        FServer->Write("--ThisRandomString\r\n");

    delete Buf;

    FServer->Push();

    return !MSIE;
}

/*##########################################################################
#
#   Name       : THttpCommand::GetFile
#
#   Purpose....: Get file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::GetFile(const char *Name)
{
    TPathName path;

    path = TPathName(FServer->RootDir);

    if (*Name)
        path += TString(Name);

    if (path.IsDir())
        path += TString("index.htm");

    if (path.IsFile())
        WriteFile(path, "text/html");
    else
        WriteError(404);
}

/*##########################################################################
#
#   Name       : THttpCommand::Get
#
#   Purpose....: Get command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::Get(const char *Name)
{
    THttpCustomPageFactory *pagefact; 
    THttpCustomDirFactory *dirfact; 

    if (FServer->OnAuthorize && !FAuthOk)
        WriteError(401);
    else
    {
        pagefact = FServer->FindPage(Name);

        if (pagefact)
        {
            THttpCustomPage *page = pagefact->Create(this);
            page->Get(Name, Name, FParamList);
            delete page;
        }
        else
        {
            dirfact = FServer->FindDir(Name);

            if (dirfact)
            {
                THttpCustomPage *page = dirfact->Create(this);
                page->Get(Name, Name, FParamList);
                delete page;
            }
            else
                GetFile(Name);
        }
    }
    FServer->Push();
}

/*##########################################################################
#
#   Name       : THttpCommand::HandlePost
#
#   Purpose....: Handle post command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::HandlePost(THttpCustomPage *page, const char *name)
{
    char *ptr;
    char *nextptr;
    char *valptr;
    
    if (FContentData)
    {
        ptr = FContentData;

        while (ptr && *ptr)
        {
            while (*ptr == 0xd || *ptr == 0xa)
                ptr++;
        
            nextptr = ptr;

            while (*nextptr && *nextptr != '&' && *nextptr != 0xd && *nextptr != 0xa)
                nextptr++;                

            if (*nextptr)
            {
                *nextptr = 0;
                nextptr++;
            }

            valptr = strchr(ptr, '=');
            if (valptr)
            {
                *valptr = 0;
                valptr++;
                page->Post(ptr, valptr);
            }

            ptr = nextptr;
        }
    }

    page->Post(name, name, FParamList);
}

/*##########################################################################
#
#   Name       : THttpCommand::Post
#
#   Purpose....: Post command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::Post(const char *Name)
{
    THttpCustomPageFactory *pagefact; 
    THttpCustomDirFactory *dirfact; 

    pagefact = FServer->FindPage(Name);

    if (pagefact)
    {
        THttpCustomPage *page = pagefact->Create(this);
        HandlePost(page, Name);
        delete page;
    }
    else
    {
        dirfact = FServer->FindDir(Name);

        if (dirfact)
        {
            THttpCustomPage *page = dirfact->Create(this);
            HandlePost(page, Name);
            delete page;
        }
        else
            GetFile(Name);
    }
    FServer->Push();
}

/*##########################################################################
#
#   Name       : THttpCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::Execute(const char *Name)
{
    THttpOption *opt;
    TString param;

    if (FMethod == "GET")
    {
        opt = FindOption("Upgrade");
        if (opt)
        {
            param = opt->GetArg(0);
            FServer->HandleUpgrade(Name, this, param.GetData());
        }
        else
            Get(Name);
    }
    else
    {
        if (FMethod == "POST")
            Post(Name);
    }
}


/*##########################################################################
#
#   Name       : THttpCommand::IsOptDelim
#
#   Purpose....: Check for option delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpCommand::IsOptDelim(char ch)
{
    return isspace(ch) || iscntrl(ch) || strchr(",;", ch);
}

/*##########################################################################
#
#   Name       : THttpCommand::LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *THttpCommand::LTrim(const char *str)
{
    while (*str)
    {
        if (IsOptDelim(*str))
            str++;
        else
            break;
    }
    return str;
}

/*##########################################################################
#
#   Name       : THttpCommand::RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::RTrim(char *str)
{
    char *p;

    p = strchr(str, 0);
    p--;

    while (p >= str && IsOptDelim(*p))
        p--;

    p[1] = 0;
}

/*##########################################################################
#
#   Name       : THttpCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpCommand::Run()
{
    char *param;
    char *ptr;
    int size;
    THttpArg *arg;
    int ArgCount;
    char *start;    

    ptr = FServer->ReadLine();
    while (ptr && *ptr != 0)
    {
        start = SkipOptDelim(ptr);
        if (*start == ':')
        {
            *start = 0;
            start++;
            start = (char *)LTrim(start);
            RTrim(start);

            ptr = (char *)LTrim(ptr);
            RTrim(ptr);

            AddOpt(ptr, start);
        }

        ptr = FServer->ReadLine();
    }

    if (FContentSize)
    {
        FContentData = new char[FContentSize + 1];
        size = FServer->Read(FContentData, FContentSize);
        *(FContentData + FContentSize) = 0;
    }

    size = FCmdLine.GetSize();
    param = new char[size + 1];
    memcpy(param, FCmdLine.GetData(), size + 1);

    if (ScanCmdLine(param, 0))
    {
        ArgCount = 0;
        arg = FArgList;
        while (arg)
        {
            ArgCount++;
            arg = arg->FList;
        }

        if (ArgCount == 2)
        {
            ptr = (char *)FArgList->FList->FName.GetData();

            FMajor = 0;
            FMinor = 0;

            if (!strcmp(ptr, "HTTP/1.0"))
            {
                FMajor = 1;
                FMinor = 0;
            }

            if (!strcmp(ptr, "HTTP/1.1"))
            {
                FMajor = 1;
                FMinor = 1;
            }

            ptr = (char *)FArgList->FName.GetData();
            while (*ptr == '/')
                ptr++;

            Execute(ptr);
        }
    }

    delete param;
}

