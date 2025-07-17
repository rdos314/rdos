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
# inithd.h
# Init harddrive command class
#
########################################################################*/

#ifndef _INITHD_H
#define _INITHD_H

#include "cmd.h"
#include "cmdfact.h"
#include "disc.h"

class TInitHdFactory : public TCommandFactory
{
public:
    TInitHdFactory();
    virtual TCommand *Create(TSession *session, const char *param);

protected:
};

class TInitHdCommand : public TCommand
{
public:
    TInitHdCommand(TSession *session, const char *param);
    virtual ~TInitHdCommand();

    virtual int Execute(char *param);	

protected:
    void InitOptions();
    virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);

    void LoadBootLoader(TDisc *Disc);
    void WriteBootSector(TDisc *Disc, int IdeDisc);
    void UpdateBootSector(TDisc *Disc, int IdeDisc);
    void WriteBootLoader(TDisc *Disc);

    void LoadGptLoader(TDisc *Disc);
    void WriteGptSector(TDisc *Disc, int IdeDisc);
    void WriteGptLoader(TDisc *Disc);
    void InitGpt(TDisc *Disc, int IdeDisc);
    void InitUefi(TDisc *Disc, int IdeDisc);

    void InitVfs(int DiscNr, const char *Cmd);

    int FLoaderSectors;
    int FOptR;
    int FOptI;
    int FOptD;
    int FOptG;
    int FOptU;
    char *FBootLoader;
    int FLoaderSize;
};

#endif
