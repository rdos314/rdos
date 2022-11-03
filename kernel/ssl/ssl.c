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

#pragma aux __8087cw "*";
unsigned short __8087cw = IC_AFFINE | RC_NEAR | PC_53  | 0x007F;

void InitSecure();

void AssertBreak(char *func, char *fn, int line_num);
#pragma aux AssertBreak parm routine [fs esi] [es edi] [ecx]

/*##########################################################################
#
#   Name       : rdos_alloc
#
##########################################################################*/
void *rdos_alloc(int Size)
{
    long linear;

    if (Size <= 0 || Size > 0x100000)
        return 0;

    if (Size < 0x1000)
        return RdosAllocateSmallGlobalMem(Size);
    else
        return RdosAllocateBigGlobalMem(Size);
}

/*##########################################################################
#
#   Name       : rdos_free
#
##########################################################################*/
void rdos_free(void *Memory)
{
    int linear;

    int sel = RdosPointerToSelector(Memory);    

    if (Memory == 0)
        return;
    
    if (sel == 0x20)
    {
        linear = RdosPointerToOffset(Memory);
        RdosFreeLinear(linear, 0);  // small linear won't require a size!
    }
    else
        RdosFreeMem(sel);
}

/*##########################################################################
#
#   Name       : assert99
#
##########################################################################*/
void _assert99(char *expr, char *func, char *fn, int line_num)
{
    AssertBreak(func, fn, line_num);
}

void __assert99(int value, char *expr, char *func, char *fn, int line_num)
{
    if (!value) 
        _assert99(expr, func, fn, line_num);
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
    SSL_CONF_CTX *cctx = NULL;

    void *p = rdos_alloc(10);

    cctx = SSL_CONF_CTX_new();

    return p;
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
