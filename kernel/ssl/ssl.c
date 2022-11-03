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
#   Name       : swap
#
##########################################################################*/

#define MAXDEPTH        (sizeof(long) * 8)

#define SHELL           3       /* Shell constant used in shell sort */

#define W sizeof( int )

#define exch( a, b, t)          ( t = a, a = b, b = t )
#define swap( a, b )    \
    swaptype != 0 ? BYTESWAP( a, b, size ) : \
    ( void ) exch( *( int* )( a ), *( int* )( b ), t )

typedef int qcomp( const void *, const void * );

#define inline_swap BYTESWAP

/*##########################################################################
#
#   Name       : inline_swap
#
#   Purpose....: inline swap
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void BYTESWAP(char *p, char *q, size_t size )
{
    long dword;
    short word;
    char byte;

    while( size > 3 ) 
    {
        dword = *(long *)p;
        *(long *)p = *(long *)q;
        *(long *)q = dword;
        p += 4;
        q += 4;
        size -= 4;
    }

    if( size > 1 ) 
    {
        word = *(short *)p;
        *(short *)p = *(short *)q;
        *(short *)q = word;
        p += 2;
        q += 2;
        size -= 2;
    }

    if( size ) 
    {
        byte = *p;
        *p = *q;
        *q = byte;
  
    }
}

/*##########################################################################
#
#   Name       : med3
#
#   Purpose....: Med 3
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static char *med3( char *a, char *b, char *c, qcomp cmp )
{
    if( cmp( a, b ) > 0 ) {
        if( cmp( a, c ) > 0 ) {
            if( cmp( b, c ) > 0 ) {
                return( b );
            } else {
                return( c );
            }
        } else {
            return( a );
        }
    } else {
        if( cmp( a, c ) >= 0 ) {
            return( a );
        } else {
            if( cmp( b, c ) > 0 ) {
                return( c );
            } else {
                return( b );
            }
        }
    }
}

/*##########################################################################
#
#   Name       : qsort
#
#   Purpose....: Quick sort
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void qsort(
    void *in_base,
    size_t n,
    size_t size,
    int (*compar)(const void *, const void *))
{
    char *      base = (char*) in_base;
    char *      p1;
    char *      p2;
    char *      pa;
    char *      pb;
    char *      pc;
    char *      pd;
    char *      pn;
    char *      pv;
    char *      mid;
    int                 v;              /* used in pivot initialization */
    int                 t;              /* used in exch() macro */
    int                 comparison, swaptype, shell;
    size_t              count, r, s;
    unsigned int        sp;
    char *              base_stack[MAXDEPTH];
    unsigned int        n_stack[MAXDEPTH];
    qcomp *             cmp = (qcomp*) compar;

    /*
        Initialization of the swaptype variable, which determines which
        type of swapping should be performed when swap() is called.
        0 for single-word swaps, 1 for general swapping by words, and
        2 for swapping by bytes.  W (it's a macro) = sizeof(WORD).
    */
    swaptype = ( ( base - (char *)0 ) | size ) % W ? 2 : size > W ? 1 : 0;
    sp = 0;
    for(;;) {
        while( n > 1 ) {
            if( n < 16 ) {      /* 2-shell sort on smallest arrays */
                for( shell = (size * SHELL) ;
                     shell > 0 ;
                     shell -= ((SHELL-1) * size) ) {
                    p1 = base + shell;
                    for( ; p1 < base + n * size; p1 += shell ) {
                        for( p2 = p1;
                             p2 > base && cmp( p2 - shell, p2 ) > 0;
                             p2 -= shell ) {
                            swap( p2, p2 - shell );
                        }
                    }
                }
                break;
            } else {    /* n >= 16 */
                /* Small array (15 < n < 30), mid element */
                mid = base + (n >> 1) * size;
                if( n > 29 ) {
                    p1 = base;
                    p2 = base + ( n - 1 ) * size;
                    if( n > 42 ) {      /* Big array, pseudomedian of 9 */
                        s = (n >> 3) * size;
                        p1  = med3( p1, p1 + s, p1 + (s << 1), cmp );
                        mid = med3( mid - s, mid, mid + s, cmp );
                        p2  = med3( p2 - (s << 1), p2 - s, p2, cmp );
                    }
                    /* Mid-size (29 < n < 43), med of 3 */
                    mid = med3( p1, mid, p2, cmp );
                }
                /*
                    The following sets up the pivot (pv) for partitioning.
                    It's better to store the pivot value out of line
                    instead of swapping it to base. However, it's
                    inconvenient in C unless the element size is fixed.
                    So, only the important special case of word-size
                    objects has utilized it.
                */
                if( swaptype != 0 ) { /* Not word-size objects */
                    pv = base;
                    swap( pv, mid );
                } else {        /* Storing the pivot out of line (at v) */
                    pv = ( char* )&v;
                    v = *( int* )mid;
                }

                pa = pb = base;
                pc = pd = base + ( n - 1 ) * size;
                count = n;
                /*
                    count keeps track of how many entries we have
                    examined.  Once we have looked at all the entries
                    then we know that the partitioning is complete.
                    We use count to terminate the looping, rather than
                    a pointer comparison, to handle 16bit pointer
                    limitations that may lead pb or pc to wrap.
                    i.e. pc  = 0x0000;
                         pc -= 0x0004;
                         pc == 0xfffc;
                         pc is no longer less that 0x0000;
                */
                for(;;) {
                    while(count && (comparison = cmp(pb, pv)) <= 0) {
                        if( comparison == 0 ) {
                            swap( pa, pb );
                            pa += size;
                        }
                        pb += size;
                        count--;
                    }
                    while(count && (comparison = cmp(pc, pv)) >= 0) {
                        if( comparison == 0 ) {
                            swap( pc, pd );
                            pd -= size;
                        }
                        pc -= size;
                        count--;
                    }
                    if( count == 0 )
                        break;
                    swap( pb, pc );
                    pb += size;
                    count--;
                    if( count == 0 )
                        break;
                    pc -= size;
                    count--;
                }
                pn = base + n * size;
                s = min( pa - base, pb - pa );
                if( s > 0 ) {
                    inline_swap( base, pb - s, s );
                }
                s = min( pd - pc, pn - pd - size);
                if( s > 0 ) {
                    inline_swap( pb, pn - s, s );
                }
                /* Now, base to (pb-pa) needs to be sorted             */
                /* Also, pn-(pd-pc) needs to be sorted                 */
                /* The middle 'chunk' contains all elements=pivot value*/
                r = pb - pa;
                s = pd - pc;
                if( s >= r ) {  /* Stack up the larger chunk */
                    base_stack[sp] = pn - s;/* Stack up base       */
                    n_stack[sp] = s / size;     /* Stack up n              */
                    n = r / size;               /* Set up n for next 'call'*/
                                            /* next base is still base */
                } else {
                    if( r <= size )
                        break;
                    base_stack[sp] = base;      /* Stack up base           */
                    n_stack[sp] = r / size;     /* Stack up n              */
                    base = pn - s;              /* Set up base and n for   */
                    n = s / size;               /* next 'call'             */
                }
                ++sp;
            }
        }
        if( sp == 0 )
            break;
        --sp;
        base = base_stack[sp];
        n    = n_stack[sp];
    }
}

/*##########################################################################
#
#   Name       : gettimeofday
#
#   Purpose....: Get time of day
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int gettimeofday( struct timeval *tv, struct timezone *tz )
{
    long long longtime;
    long long basetime;
    unsigned long msb;

    /* unused parameters */ (void)tz;

    msb = RdosCodeMsbTics( 2010, 1, 1, 0 );
    basetime = (long long)msb;
    basetime = basetime << 32;
    longtime = RdosGetLongTime();
    longtime -= basetime;

    tv->tv_sec = (long)(longtime / 1193182);
    longtime = longtime - (long long)(tv->tv_sec) * 1193182;
    longtime = longtime * 1000000 / 1193182;
    tv->tv_usec = (long)longtime;

    while( tv->tv_usec < 0 ) {
        tv->tv_usec += 1000000;
        tv->tv_sec--;
    }

    while( tv->tv_usec >= 1000000 ) {
        tv->tv_usec -= 1000000;
        tv->tv_sec++;
    }

    return( 0 );
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
