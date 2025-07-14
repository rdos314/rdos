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
# ftpserv.cpp
# FTP socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "file.h"
#include "strlist.h"
#include "sockobj.h"
#include "ftpserv.h"
#include "ftplang.h"
#include "ftpcmd.h"
#include "ftpfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpSocketServer::IsEmpty
#
#   Purpose....: Return true if string is 0 or contains only spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsEmpty(const char *s)
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
#   Name       : TFtpSocketServer::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsArgDelim(char ch)
{
        return isspace(ch) || iscntrl(ch) || strchr(",;=", ch);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::IsFileNameChar
#
#   Purpose....: Is filename char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsFileNameChar(char c)
{
        return !(c <= ' ' || c == 0x7f || strchr(".\"/\\[]:|<>+=;,", c));
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::LTrimsp
#
#   Purpose....: Trim of leading spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TFtpSocketServer::LTrimsp(const char *str)
{
        while (*str && isspace(*str))
                str++;
        return str;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TFtpSocketServer::LTrim(const char *str)
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
#   Name       : TFtpSocketServer::RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::RTrim(char *str)
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
#   Name       : TFtpSocketServer::Unquote
#
#   Purpose....: Unquote to new string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TFtpSocketServer::Unquote(const char *str, const char *end)
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
#   Name       : TFtpSocketServer::MatchToken
#
#   Purpose....: Match token at begining of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::MatchToken(char **Xp, const char *word, int len)
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
#   Name       : TFtpSocketServer::TFtpSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServer::TFtpSocketServer(TFtpUser *UserList, const char *Name, int StackSize, TTcpSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
        FUserList = UserList;
        CurrDir = "/";
        FDataSocket = 0;
        OnCommand = 0;
        FMyIp = 0;
        FLocalPort = 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::~TFtpSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServer::~TFtpSocketServer()
{
    if (FDataSocket)
        delete FDataSocket;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Reply
#
#   Purpose....: Reply to socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Reply(TFtpLangString *msg)
{
         msg->Write(FSocket);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::VerifyUser
#
#   Purpose....: Verify a valid user is logged in
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::VerifyUser()
{
        TFtpUser *user;

        user = FUserList;

        while (user)
        {
                if (user->UserName == User && user->Password == Pass)
                {
                        RootDir = user->RootDir;
                        return TRUE;
                }
                user = user->FNext;
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::OpenDataConnection
#
#   Purpose....: Open data connection to client
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::OpenDataConnection(long IP, int port)
{
        if (IP == FSocket->GetRemoteIP())
        {
                if (FDataSocket)
                        delete FDataSocket;

                FDataSocket = new TTcpSocket(IP, port, 6000, 0x2000);

                if (FDataSocket->WaitForConnection(6000))
                        return TRUE;
                else
                {
                        delete FDataSocket;
                        FDataSocket = 0;
                }
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::GetListenPort
#
#   Purpose....: Get port to listen for
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::ListenForDataConnection(long *IP, int *port)
{
    *IP = FMyIp;

    if (FDataSocket)
        delete FDataSocket;

    if (FLocalPort)
        FDataSocket = new TTcpSocket(FSocket->GetRemoteIP(), FLocalPort, 0, 6000, 0x2000);
    else
    {
        FDataSocket = new TTcpSocket(FSocket->GetRemoteIP(), 0, 6000, 0x2000);
        FLocalPort = FDataSocket->GetLocalPort();
    }
    *port = FLocalPort;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write character to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(char ch)
{
        char str[2];

        str[0] = ch;
        str[1] = 0;

        if (FDataSocket && FDataSocket->IsOpen())
                FDataSocket->Write(str, 1);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write string to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(const char *str)
{
        int size = strlen(str);

        if (FDataSocket && FDataSocket->IsOpen())
                FDataSocket->Write(str, size);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write buffer to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(const char *buf, int size)
{
        if (FDataSocket && FDataSocket->IsOpen())
                FDataSocket->Write(buf, size);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::WriteLong
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::WriteLong(long value)
{
        char str[4];
        int tmp;
        int use = FALSE;

        tmp = value / 1000000000;
        if (tmp)
        {
                use = TRUE;
                sprintf(str, "%2d", tmp);
        }
        else
                strcpy(str, "  ");
        Write(str);
        Write(" ");
        value = value % 1000000000;

        tmp = value / 1000000;
        if (use)
                sprintf(str, "%03d", tmp);
        else
        {
                if (tmp)
                {
                        use = TRUE;
                        sprintf(str, "%3d", tmp);
                }
                else
                        strcpy(str, "   ");
        }
        Write(str);
        Write(" ");
        value = value % 1000000;

        tmp = value / 1000;
        if (use)
                sprintf(str, "%03d", tmp);
        else
        {
                if (tmp)
                {
                        use = TRUE;
                        sprintf(str, "%3d", tmp);
                }
                else
                        strcpy(str, "   ");
        }
        Write(str);
        Write(" ");
        value = value % 1000;

        tmp = value;
        if (use)
                sprintf(str, "%03d", tmp);
        else
                sprintf(str, "%3d", tmp);
        Write(str);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Push
#
#   Purpose....: Push data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Push()
{
    if (FDataSocket)
    {
        while (FSocket->IsOpen() && FDataSocket->IsOpen() && !FDataSocket->IsIdle())
        {
            FDataSocket->Push();
            RdosWaitMilli(5);
        }
        
        delete FDataSocket;
        FDataSocket = 0;
    }
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::IsOpen
#
#   Purpose....: Check if data socket is open
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsOpen()
{
        return FDataSocket && FDataSocket->IsOpen();
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Read
#
#   Purpose....: Read buffer from data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::Read(char *buf, int size)
{
        if (FDataSocket)
                return FDataSocket->Read(buf, size);
        else
                return 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Quit
#
#   Purpose....: Quit session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Quit()
{
    FSocket->Close();
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::HandleSocket()
{
    int Major;
    int Minor;
    int Release;
    TFtpLangString msg;
    TFtpCommand *cmd;
    char Buf[512];
    int count;

    RdosGetVersion(&Major, &Minor, &Release);
    msg.printf(220, Major, Minor, Release);
    msg.Write(FSocket);

    if (!FMyIp)
        FMyIp = FSocket->GetLocalIP();

    while (FSocket->IsOpen())
    {
        count = FSocket->Read(Buf, 32);
        Buf[count] = 0;

        if (count == 0)
            break;

        if (OnCommand)
            (*OnCommand)(this, Buf);

        cmd = TFtpCommandFactory::Parse(this, Buf);

        if (cmd)
        {
            cmd->Run();
            delete cmd;
        }
        else
        {
            msg.Load(502);
            msg.Write(FSocket);
        }
    }
}
