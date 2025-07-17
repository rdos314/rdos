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
# wdfile.h
# WD supplementary file support class
#
########################################################################*/

#ifndef _WDFILE_H
#define _WDFILE_H

#include "wdsuppl.h"

class TWdFileFactory : public TWdSupplFactory
{
public:
    TWdFileFactory(TWdSocketServerFactory *factory);
	virtual ~TWdFileFactory();
	
	virtual TWdSupplService *Create(TWdSocketServer *server);
};

class TWdFileService : public TWdSupplService
{
public:
    TWdFileService(TWdSocketServer *server);
	virtual ~TWdFileService();

    virtual void NotifyMsg();

protected:

    int GetServer(char *name);

    void ReqGetConfig();
    void ReqOpen();
    void ReqSeek();
    void ReqRead();
    void ReqWrite();
    void ReqWriteConsole();
    void ReqClose();
    void ReqErase();
    void ReqStrToFullPath();
    void ReqRun();
    void ReqError();

};

#endif
