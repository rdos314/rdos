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
# helper.h
# Global lib tom macros
#
########################################################################*/

#include <rdos.h>

#define CONST64(n) n ## ULL
typedef unsigned long long ulong64;
typedef unsigned int ulong32;

void RdosStore32L(unsigned char *buf, unsigned int val);
unsigned int RdosLoad32L(const unsigned char *buf);

void RdosStore64L(unsigned char *buf, unsigned long long val);
unsigned long long RdosLoad64L(const unsigned char *buf);

void RdosStore32H(unsigned char *buf, unsigned int val);
unsigned int RdosLoad32H(const unsigned char *buf);

void RdosStore64H(unsigned char *buf, unsigned long long val);
unsigned long long RdosLoad64H(const unsigned char *buf);

unsigned int ROL(unsigned int val, int i);
unsigned int ROLc(unsigned int val, int i);
unsigned int ROR(unsigned int val, int i);
unsigned int RORc(unsigned int val, int i);

unsigned long long ROL64(unsigned long long val, int i);
unsigned long long ROL64c(unsigned long long val, int i);
unsigned long long ROR64(unsigned long long val, int i);
unsigned long long ROR64c(unsigned long long val, int i);

#pragma aux RdosLoad32L = \
    "mov eax,[esi]" \
    parm [esi]   \
    value [eax];

#pragma aux RdosStore32L = \
    "mov [esi],eax" \
    parm [esi] [eax];

#pragma aux RdosLoad64L = \
    "mov eax,[esi]" \
    "mov edx,[esi+4]" \
    parm [esi]   \
    value [edx eax];

#pragma aux RdosStore64L = \
    "mov [esi],eax" \
    "mov [esi+4],edx" \
    parm [esi] [edx eax];

#pragma aux RdosLoad32H = \
    "mov eax,[esi]" \
    "xchg al,ah" \
    "rol eax,16" \
    "xchg al,ah" \
    parm [esi]   \
    value [eax];

#pragma aux RdosStore32H = \
    "xchg al,ah" \
    "rol eax,16" \
    "xchg al,ah" \
    "mov [esi],eax" \
    parm [esi] [eax] \
    modify [eax];

#pragma aux RdosLoad64H = \
    "mov eax,[esi+4]" \
    "xchg al,ah" \
    "rol eax,16" \
    "xchg al,ah" \
    "mov edx,[esi]" \
    "xchg dl,dh" \
    "rol edx,16" \
    "xchg dl,dh" \
    parm [esi]   \
    value [edx eax];

#pragma aux RdosStore64H = \
    "xchg al,ah" \
    "rol eax,16" \
    "xchg al,ah" \
    "mov [esi+4],eax" \
    "xchg dl,dh" \
    "rol edx,16" \
    "xchg dl,dh" \
    "mov [esi],edx" \
    parm [esi] [edx eax] \
    modify [eax edx];

#pragma aux ROL = \
    "rol eax,cl" \
    parm [eax] [ecx] \
    value [eax];

#pragma aux ROLc = \
    "rol eax,cl" \
    parm [eax] [ecx] \
    value [eax];

#pragma aux ROR = \
    "ror eax,cl" \
    parm [eax] [ecx] \
    value [eax];

#pragma aux RORc = \
    "ror eax,cl" \
    parm [eax] [ecx] \
    value [eax];

#pragma aux ROL64 = \
    "or ecx,ecx" \
    "jz done" \
    "rotate: " \
    "rol eax,1" \
    "rcl edx,1" \
    "loop rotate" \
    "done: "\
    parm [edx eax] [ecx] \
    value [edx eax];

#pragma aux ROL64c = \
    "or ecx,ecx" \
    "jz done" \
    "rotate: " \
    "rol eax,1" \
    "rcl edx,1" \
    "loop rotate" \
    "done: "\
    parm [edx eax] [ecx] \
    value [edx eax];

#pragma aux ROR64 = \
    "or ecx,ecx" \
    "jz done" \
    "rotate: " \
    "ror edx,1" \
    "rcr eax,1" \
    "loop rotate" \
    "done: "\
    parm [edx eax] [ecx] \
    value [edx eax];

#pragma aux ROR64c = \
    "or ecx,ecx" \
    "jz done" \
    "rotate: " \
    "ror edx,1" \
    "rcr eax,1" \
    "loop rotate" \
    "done: "\
    parm [edx eax] [ecx] \
    value [edx eax];

#define STORE32L(x, y) RdosStore32L(x, y);

#define LOAD32L(x, y) x = RdosLoad32L(y);

#define STORE64L(x, y) RdosStore64L(x, y);

#define LOAD64L(x, y) x = RdosLoad64L(y);

#define STORE32H(x, y) RdosStore32H(x, y);

#define LOAD32H(x, y) x = RdosLoad32H(y);

#define STORE64H(x, y) RdosStore64H(x, y);

#define LOAD64H(x, y) x = RdosLoad64H(y);

#define BSWAP(x) RdosSwapLong(x)

#ifndef MAX
   #define MAX(x, y) ( ((x)>(y))?(x):(y) )
#endif

#ifndef MIN
   #define MIN(x, y) ( ((x)<(y))?(x):(y) )
#endif

#define byte(x, n) (((x) >> (8 * (n))) & 255)
