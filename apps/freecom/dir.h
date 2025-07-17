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
# dir.h
# Dir command class
#
########################################################################*/

#ifndef _DIR_H
#define _DIR_H

#include "cmd.h"
#include "cmdfact.h"
#include "direntry.h"

class TDirFactory : public TCommandFactory
{
public:
        TDirFactory();
        virtual TCommand *Create(TSession *session, const char *param);

protected:
};

class TDirCommand : public TCommand
{
public:
        TDirCommand(TSession *session, const char *param);
        virtual ~TDirCommand();

        virtual int Execute(char *param);

protected:
        int ScanAttr(const char *p);
        int ScanOrder(const char *p);
        virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);
    void InitOptions();

        void WriteHeader(TString &str);
        void WriteFooter();

        void Add(TString &path);
        void WriteDetailed(const TDirEntryData &entry);
        void WriteDetailed();
        void WriteWide(const TDirEntryData &entry);
        void WriteWide();

        TDirList FFileList;
        TDirList FDirList;

        int FCurrentRow;
        int FCurrentCol;
    int FWidth;

        int FRequired;
    int FIgnored;
        int FOptS;
        int FOptP;
        int FOptW;
        int FOptB;
        int FOptL;
    int FOptDirFirst;
    int FOptDirLast;

        int FFileCount;
        int FDirCount;
        long long FTotalSize;
        int FDrive;
};

#endif
