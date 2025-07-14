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
# ftplist.h
# Ftp List command class
#
########################################################################*/

#ifndef _FTPLIST_H
#define _FTPLIST_H

#include "ftpcmd.h"
#include "ftpfact.h"
#include "direntry.h"

class TFtpListFactory : public TFtpCommandFactory
{
public:
	TFtpListFactory();
	virtual TFtpCommand *Create(TFtpSocketServer *Server, const char *param);

protected:
};

class TFtpListCommand : public TFtpCommand
{
public:
	TFtpListCommand(TFtpSocketServer *Server, const char *param);
	virtual ~TFtpListCommand();

	virtual void Execute(char *param);

protected:
	void WriteHeader(TString &str);
	void WriteFooter();

	void WriteEntry(const TDirEntryData &entry);
	void WriteEntry();

	TDirList FFileList;
	TDirList FDirList;

	int FFileCount;
	int FDirCount;
	long FTotalSize;
};

#endif
