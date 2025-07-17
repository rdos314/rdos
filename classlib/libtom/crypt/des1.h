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
# LibTomCrypt, modular cryptographic library -- Tom St Denis was ported to
# a C++ class-interface
# Tom St Denis, tomstdenis@gmail.com, http://libtom.org
#
# The C++ porter of this program may be contacted at leif@rdos.net
#
# des1.h
# Single pass DES class
#
########################################################################*/

#ifndef _DES1_H
#define _DES1_H

#include "desbase.h"

class TDes1 : public TDesBase
{
public:
    TDes1();
    virtual ~TDes1();

    virtual int GetKeySize();
    virtual void SetupKey(const char *Key);
    virtual void Encrypt(char *buf, int size);
    virtual void Decrypt(char *buf, int size);

    int Test();

protected:
    void Setup(const unsigned char *Key);
    void EncryptBlock(const unsigned char *Pt, unsigned char *Ct);
    void DecryptBlock(const unsigned char *Ct, unsigned char *Pt);
    
    unsigned long ek[32];
    unsigned long dk[32];
};

#endif
