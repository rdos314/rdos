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
# ftpcmd.h
# Ftp command base class
#
########################################################################*/

#ifndef _FTPCMD_H
#define _FTPCMD_H

#include "file.h"
#include "path.h"
#include "ftpparse.h"
#include "ftpserv.h"

class TFtpArg
{
public:
    TFtpArg(const char *name);
    ~TFtpArg();

    char *ptr;

    TString FName;
	 TFtpArg *FList;
};

class TFtpCommand : public TFtpParser
{
public:
    TFtpCommand(TFtpSocketServer *Server);
    TFtpCommand(TFtpSocketServer *Server, const char *param);
	virtual ~TFtpCommand();
	
	void Run();
	virtual void Execute(char *param) = 0;

	static int ErrorLevel;

protected:
    void AddArg(const char *name);
    void AddArg(char *sBeg, char **sEnd);
    void Split(char *s);
    int Parse(void *arg);
    int ScanCmdLine(char *line, void *arg);

	TString FCmdLine;
	TFtpCommand *FList;
	
	TFtpArg *FArgList;
	int FArgCount;

	TFtpSocketServer *FServer;
};

#endif
