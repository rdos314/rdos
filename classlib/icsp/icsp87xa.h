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
# icsp.h
# In-circuit programming base class
#
########################################################################*/

#ifndef _ICSP87XA_H
#define _ICSP87XA_H

#include "file.h"
#include "icsp.h"

class TIcsp87Xa : public TIcsp
{
public:
    TIcsp87Xa();
    ~TIcsp87Xa();

protected:
    int ReadRecord(int *op, int *offset, char *buf);
    void SendCmd(int cmd);
    void SendCmd(int cmd, int data);
    int ReadCmd(int cmd);
    void Erase();
    void LoadConfig(int data);
    void GotoNextAddress();
    void WriteData(int data);

    virtual int DoProgram();
    virtual int DoVerify();
    virtual int DoChipErase();

    int FInConfig;
};

#endif
