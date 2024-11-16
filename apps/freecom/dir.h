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
