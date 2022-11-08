/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2012, Leif Ekblad
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
# ssl.c
# SSL device
#
########################################################################*/

#include "e_os.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>
#include <float.h>
#include <time.h>
#include <sys/time.h>
#include <openssl/e_os2.h>
#include <openssl/x509.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/ocsp.h>
#include <openssl/bn.h>
#include <openssl/async.h>
#include <openssl/srp.h>
#include <openssl/ct.h>

#include "rdos.h"
#include "rdosdev.h"

#define BUFSIZZ 1024*8

void InitSecure();

void AssertBreak(char *func, char *fn, int line_num);
#pragma aux AssertBreak parm routine [fs esi] [es edi] [ecx]

/*##########################################################################
#
#   Name       : AllocateMem
#
##########################################################################*/
void *AllocateMem(size_t num, const char *file, int line)
{
    long linear;

    if (num <= 0 || num > 0x100000)
        return 0;

    if (num < 0x1000)
        return RdosAllocateSmallGlobalMem(num);
    else
        return RdosAllocateBigGlobalMem(num);
}

/*##########################################################################
#
#   Name       : FreeMem
#
##########################################################################*/
void FreeMem(void *str, const char *file, int line)
{
    int linear;

    int sel = RdosPointerToSelector(str);

    if (str == 0)
        return;

    if (sel == 0x20)
    {
        linear = RdosPointerToOffset(str);
        RdosFreeLinear(linear, 0);
    }
    else
        RdosFreeMem(sel);
}

/*##########################################################################
#
#   Name       : ReallocateMem
#
##########################################################################*/
void *ReallocateMem(void *str, size_t num, const char *file, int line)
{
    char *newmem;
    int linear;
    long base;
    long limit;
    int size;
    int sel = RdosPointerToSelector(str);

    if (str == 0)
        size = 0;
    else
    {
        if (sel == 0x20)
            size = num;
        else
        {
            RdosGetSelectorBaseSize(sel, &base, &limit);
            size = limit + 1;
        }
    }

    if (num)
    {
        newmem = AllocateMem(num, file, line);
        if (size > num)
            size = num;

        memcpy(newmem, str, size);
    }
    else
        newmem = 0;

    FreeMem(str, file, line);

    return newmem;
}

/*##########################################################################
#
#   Name       : CreateConnection
#
#   Purpose....: Create connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux CreateConnection "*" rdosdev parm routine value [dx eax]
void *CreateConnection()
{
    void *p;
    SSL_CONF_CTX *cctx = NULL;
    SSL_CTX *ctx = NULL;
    char *cbuf = NULL;
    char *sbuf = NULL;

    cctx = SSL_CONF_CTX_new();

    cbuf = (char *)OPENSSL_malloc(BUFSIZZ);
    sbuf = (char *)OPENSSL_malloc(BUFSIZZ);

    SSL_CONF_CTX_set_flags(cctx, SSL_CONF_FLAG_CLIENT | SSL_CONF_FLAG_CMDLINE);

    ctx = SSL_CTX_new(TLS_client_method());

    return 0;
}

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    InitSecure();
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    RdosHookInitTasking(&InitTasking);
}
