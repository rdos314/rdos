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
# httpserv.h
# Http socket server class
#
########################################################################*/

#ifndef _HTTPSERV_H
#define _HTTPSERV_H

#include "str.h"
#include "sockobj.h"
#include "httpcust.h"

enum InternalErrorCodes
{
        E_None = 0,
        E_Useage = 1,
        E_Other = 2,
        E_CBreak = 3,
        E_NoMem,
        E_CorruptMemory,
        E_NoOption,
        E_Exit,
        E_Ignore,                       /* Error that can be ignored */
        E_Empty,
        E_Syntax,
        E_Range,                                /* Numbers out of range */
        E_NoItems,
        E_Help,         /* Help screen */
        E_User          /* MUST be the last one */
};

class THttpSocketServer : public TSocketServer
{
public:
    THttpSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~THttpSocketServer();

    virtual void HandleSocket();

    void Write(char ch);
    void Write(const char *str);
    void Write(const char *buf, int size);
    void Push();

    int IsOpen();
    int IsEmpty();
        
    int Read(char *buf, int size);
    char *ReadLine();

    THttpCustomPageFactory *FindPage(const char *FileName);
    THttpCustomDirFactory *FindDir(const char *FileName);
    TString CreateUniqueFile();

    virtual void HandleUpgrade(const char *Name, THttpCommand *Cmd, const char *prot);

    void (*OnCommand)(THttpSocketServer *server, const char *str);
    int (*OnAuthorize)(THttpSocketServer *server, const char *user, const char *passw);

    static int IsEmpty(const char *s);
    static int IsArgDelim(char ch);
    static int IsFileNameChar(char c);
    static const char *LTrimsp(const char *str);
    static const char *LTrim(const char *str);
    static void RTrim(char *str);
    static char *Unquote(const char *str, const char *end);
    static int MatchToken(char **Xp, const char *word, int len);

    TString RootDir;
    int KeepAlive;
    THttpCustomPageFactory *FPageList;
    THttpCustomDirFactory *FDirList;

protected:
    int IsMatch(const char *Search, const char *FileName);
    THttpCommand *Parse(const char *line);

    TString FMethod;
    char *FSocketBuf;
    int FBufCount;
    int FBufPos;
    
};

#endif
