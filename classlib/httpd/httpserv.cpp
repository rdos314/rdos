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
# httpserv.cpp
# HTTP socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "file.h"
#include "strlist.h"
#include "sockobj.h"
#include "httpserv.h"
#include "httpcmd.h"
#include "httpfact.h"

#define FALSE 0
#define TRUE !FALSE

#define BUF_SIZE        513

/*##########################################################################
#
#   Name       : THttpSocketServer::IsEmpty
#
#   Purpose....: Return true if string is 0 or contains only spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::IsEmpty(const char *s)
{
    if (s)
    {
        while(*s)
        {
            s++;
            if (!isspace(*s))
                return FALSE;
        }
    }
    return TRUE;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::IsArgDelim(char ch)
{
    return isspace(ch) || iscntrl(ch) || strchr(",;=", ch);
}

/*##########################################################################
#
#   Name       : THttpSocketServer::IsFileNameChar
#
#   Purpose....: Is filename char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::IsFileNameChar(char c)
{
    return !(c <= ' ' || c == 0x7f || strchr(".\"/\\[]:|<>+=;,", c));
}

/*##########################################################################
#
#   Name       : THttpSocketServer::LTrimsp
#
#   Purpose....: Trim of leading spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *THttpSocketServer::LTrimsp(const char *str)
{
    while (*str && isspace(*str))
        str++;
    return str;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *THttpSocketServer::LTrim(const char *str)
{
    while (*str)
    {
        if (IsArgDelim(*str))
            str++;
        else
            break;
    }
    return str;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServer::RTrim(char *str)
{
    char *p;

    p = strchr(str, 0);
    p--;

    while (p >= str && IsArgDelim(*p))
        p--;

    p[1] = 0;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::Unquote
#
#   Purpose....: Unquote to new string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpSocketServer::Unquote(const char *str, const char *end)
{
    char *h, *newStr;
    const char *q;
    int len;

    newStr = new char[end - str + 1];
    h = newStr;

    while ((q = strpbrk(str, "\"")) != 0 && q < end)
    {
        memcpy(h, str, len = q++ - str);
        h += len;
        if ((str = strchr(q, q[-1])) == 0 || str >= end)
        {
            str = q;
            break;
        }

        memcpy(h, q, len = str++ - q);
        h += len;
    }

    memcpy(h, str, len = end - str);
    h[len] = 0;
    return newStr;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::MatchToken
#
#   Purpose....: Match token at begining of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::MatchToken(char **Xp, const char *word, int len)
{
    char *p;
    char *q;

    p = *Xp;
    if (strnicmp(p, word, len) == 0)
    {
        p += len;
        if (*p)
        {
            q = (char *)LTrim(p);
            if (q == p)
                return FALSE;
            p = q;
        }
        *Xp = p;
        return TRUE;
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::THttpSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpSocketServer::THttpSocketServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
    OnCommand = 0;
    OnAuthorize = 0;
    FSocketBuf = 0;
    FPageList = 0;
    FDirList = 0;
    KeepAlive = 15;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::~THttpSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpSocketServer::~THttpSocketServer()
{
    if (FSocketBuf)
        delete FSocketBuf;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::IsMatch
#
#   Purpose....: Check if file matches search criteria
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::IsMatch(const char *Search, const char *FileName)
{
	TString FileStr(FileName);
	TString SearchStr(Search);
	const char *FilePtr;
	const char *SearchPtr;
	char ch;
	const char *LastFilePtr = 0;
	const char *LastSearchPtr = 0;

	FileStr.Upper();
	SearchStr.Upper();

	if (SearchStr.GetSize() == 0)
		return TRUE;

	FilePtr = FileStr.GetData();
	SearchPtr = SearchStr.GetData();

	if (!strcmp(SearchPtr, "*.*"))
		return TRUE;

	if (!strcmp(SearchPtr, "*."))
	{
		if (strchr(FilePtr, '.'))
			return FALSE;
		else
			return TRUE;
	}

	for (;;)
	{
		while (*SearchPtr && *FilePtr)
		{
			switch (*SearchPtr)
			{
				case '*':
					ch = *(SearchPtr + 1);
					if (ch)
					{
						if (ch == *FilePtr)
						{
							LastSearchPtr = SearchPtr;
							SearchPtr += 2;
							FilePtr++;
							LastFilePtr = FilePtr;
						}
						else
							FilePtr++;
					}
					else
						FilePtr++;
					break;
	
				case '?':
					SearchPtr++;
					FilePtr++;
					break;

				default:
					if (*SearchPtr == *FilePtr)
					{
						SearchPtr++;
						FilePtr++;
					}
					else
					{
						if (LastFilePtr)
						{
							FilePtr = LastFilePtr;
							SearchPtr = LastSearchPtr;
							LastFilePtr = 0;
							LastSearchPtr = 0;
						}
						else
							return FALSE;
					}
					break;
			}
		}

		if (*SearchPtr == 0 && *FilePtr == 0)
			return TRUE;
		else
		{
			if (*SearchPtr == '*' && *(SearchPtr+1) == 0)
				return TRUE;

			if (LastFilePtr)
			{
				FilePtr = LastFilePtr;
				SearchPtr = LastSearchPtr;
				LastFilePtr = 0;
				LastSearchPtr = 0;
			}
			else
				return FALSE;
		}
	}
}

/*##########################################################################
#
#   Name       : THttpSocketServer::FindPage
#
#   Purpose....: Find custom page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPageFactory *THttpSocketServer::FindPage(const char *FileName)
{
    TString Name(FileName);
    THttpCustomPageFactory *page = FPageList;
       
    while (page)
    {
        if (page->FReqNameList.Find(Name))
            return page;
        else
            page = page->FList;
    }

    return 0;    
}

/*##########################################################################
#
#   Name       : THttpSocketServer::FindDir
#
#   Purpose....: Find custom dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomDirFactory *THttpSocketServer::FindDir(const char *FileName)
{
    int i;
    int count;
    const char *str;
    const char *ptr;
    THttpCustomDirFactory *dir = FDirList;

    while (dir)
    {
        count = dir->FReqNameList.GetSize();

        for (i = 0; i < count; i++)
        {
            str = dir->FReqNameList[i].GetData();
            ptr = strstr(FileName, str);
            if (ptr == FileName)
                return dir;
        }
        dir = dir->FList;
    }
    
    return 0;    
}

/*##########################################################################
#
#   Name       : THttpSocketServer::CreateUniqueFile
#
#   Purpose....: Create an unique file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString THttpSocketServer::CreateUniqueFile()
{
    char str[50];

    sprintf(str, "z:\\HTTP%ld%d", FSocket->GetRemoteIP(), FSocket->GetRemotePort());

    return TString(str);
}

/*##########################################################################
#
#   Name       : THttpSocketServer::Write
#
#   Purpose....: Write character to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServer::Write(char ch)
{
    char str[2];

    str[0] = ch;
    str[1] = 0;

    if (FSocket->IsOpen())
        FSocket->Write(str, 1);
}

/*##########################################################################
#
#   Name       : THttpSocketServer::Write
#
#   Purpose....: Write string to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServer::Write(const char *str)
{
    int size = strlen(str);

    if (FSocket->IsOpen())
        FSocket->Write(str, size);
}

/*##########################################################################
#
#   Name       : THttpSocketServer::Write
#
#   Purpose....: Write buffer to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServer::Write(const char *buf, int size)
{
    if (FSocket->IsOpen())
        FSocket->Write(buf, size);
}

/*##########################################################################
#
#   Name       : THttpSocketServer::Push
#
#   Purpose....: Push data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServer::Push()
{
    FSocket->Push();
}

/*##########################################################################
#
#   Name       : THttpSocketServer::IsOpen
#
#   Purpose....: Check if data socket is open
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::IsOpen()
{
    return FSocket->IsOpen();
}

/*##########################################################################
#
#   Name       : THttpSocketServer::IsEmpty
#
#   Purpose....: Check if data socket is empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::IsEmpty()
{
    if (FBufCount == FBufPos)
    {
        if (FSocket->GetSize() == 0)
            return TRUE;
        else
            return FALSE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::Read
#
#   Purpose....: Read a number of data-bytes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServer::Read(char *buf, int size)
{
    int pos;
    int count;

    if (FSocketBuf == 0)
    {
        FSocketBuf = new char[BUF_SIZE + 1];
        FBufCount = 0;
        FBufPos = 0;
    }

    if (FBufCount <= FBufPos)
    {
        FBufPos -= FBufCount;

        if (FSocket->WaitForData(5000))
        {
            FBufCount = FSocket->Read(FSocketBuf, BUF_SIZE);
            FSocketBuf[FBufCount] = 0;

            if (OnCommand)
                (*OnCommand)(this, FSocketBuf);
        }
        else
            return 0;
    }

    while (FBufCount - FBufPos < size)
    {
        if (FBufPos == 0)
        {
            FBufCount = 0;
            return 0;
        }

        if (!FSocket->WaitForData(5000))
        {
            count = FBufCount - FBufPos;
            memcpy(buf, &FSocketBuf[FBufPos], count);
            FBufPos = 0;
            FBufCount = 0;
            return count;
        }

        memcpy(FSocketBuf, &FSocketBuf[FBufPos], FBufCount - FBufPos);
        FBufCount -= FBufPos;
        FBufPos = 0;
        pos = FBufCount;
        FBufCount += FSocket->Read(&FSocketBuf[pos], BUF_SIZE - FBufCount);
        FSocketBuf[FBufCount] = 0;

        if (OnCommand)
            (*OnCommand)(this, &FSocketBuf[pos]);
    }

    memcpy(buf, &FSocketBuf[FBufPos], size);
    FBufPos += size;
    return size;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::ReadLine
#
#   Purpose....: Read a single line from socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpSocketServer::ReadLine()
{
#define BUF_SIZE        513
    char *ptr;
    char *result;
    int pos;

    if (FSocketBuf == 0)
    {
        FSocketBuf = new char[BUF_SIZE + 1];
        FBufCount = 0;
        FBufPos = 0;
    }

    if (FBufCount <= FBufPos)
    {
        FBufPos -= FBufCount;

        if (FSocket->WaitForData(5000))
        {
            FBufCount = FSocket->Read(FSocketBuf, BUF_SIZE);
            FSocketBuf[FBufCount] = 0;

            if (OnCommand)
                (*OnCommand)(this, FSocketBuf);
        }
        else
            return 0;
    }

    ptr = strchr(&FSocketBuf[FBufPos], 0xd);

    while (!ptr)
    {
        if (FBufPos == 0)
        {
            FBufCount = 0;
            return 0;
        }

        if (!FSocket->WaitForData(5000))
        {
            result = &FSocketBuf[FBufPos];
            FBufPos = 0;
            FBufCount = 0;
            return result;
        }

        memcpy(FSocketBuf, &FSocketBuf[FBufPos], FBufCount - FBufPos);
        FBufCount -= FBufPos;
        FBufPos = 0;
        pos = FBufCount;
        FBufCount += FSocket->Read(&FSocketBuf[pos], BUF_SIZE - FBufCount);
        FSocketBuf[FBufCount] = 0;

        if (OnCommand)
            (*OnCommand)(this, &FSocketBuf[pos]);

        ptr = strchr(&FSocketBuf[pos], 0xd);
    }

    *ptr = 0;
    result = &FSocketBuf[FBufPos];
    FBufPos = ptr - FSocketBuf + 2;

    return result;
}

/*##################  THttpSocketServer::Parse  ##########################
*   Purpose....: Parse a command line and return a command class                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
THttpCommand *THttpSocketServer::Parse(const char *line)
{
    const char *rest;
    int size;
    int i;
    char *com;
    char *ptr;
    int done;
    TString Line;
    TString Method;

    Line = TString(LTrim(line));

    rest = Line.GetData();

    Method = TString("");

    if (*rest)
    {
        size = 0;
        while (*rest && IsFileNameChar(*rest) && !strchr("\"", *rest))
        {
            size++;
            rest++;
        }

        if (*rest && strchr("\"", *rest))
            size = 0;

        if (size)
        {
            com = new char[size + 1];

            rest = Line.GetData();
            ptr = com;

            for (i = 0; i < size; i++)
            {
                *ptr = toupper(*rest);
                ptr++;
                rest++;
            }
            *ptr = 0;

            Method = TString(com);
            delete com;
        }
    }

    if (Method.GetSize())
    {
        done = *rest == 0 || *rest == '/' || *rest == '.' || *rest == ':';
        if (!done)
            if (IsArgDelim(*rest))
                rest = LTrim(rest);

        return new THttpCommand(this, Method, TString(rest));
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : THttpSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServer::HandleSocket()
{
    THttpCommand *cmd;
    char *ptr;

    while (FSocket->IsOpen() || !IsEmpty())
    {
        ptr = ReadLine();
        if (ptr)
        {
            cmd = Parse(ptr);
            if (cmd)
            {
                cmd->Run();
                delete cmd;
            }
        }
        else
        {
            if (KeepAlive == 0 || !FSocket->WaitForData(KeepAlive * 1000))
                break;
        }
    }
}

/*##########################################################################
#
#   Name       : THttpSocketServer::HandleUpgrade
#
#   Purpose....: Handle upgrade
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServer::HandleUpgrade(const char *Name, THttpCommand *Cmd, const char *prot)
{
    Cmd->WriteError(404);
}
