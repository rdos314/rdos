/****************************************************************************
*
*                            Open Watcom Project
*
*    Portions Copyright (c) 1983-2002 Sybase, Inc. All Rights Reserved.
*
*  ========================================================================
*
*    This file contains Original Code and/or Modifications of Original
*    Code as defined in and that are subject to the Sybase Open Watcom
*    Public License version 1.0 (the 'License'). You may not use this file
*    except in compliance with the License. BY USING THIS FILE YOU AGREE TO
*    ALL TERMS AND CONDITIONS OF THE LICENSE. A copy of the License is
*    provided with the Original Code and Modifications, and is also
*    available at www.sybase.com/developer/opensource.
*
*    The Original Code and all software distributed under the License are
*    distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
*    EXPRESS OR IMPLIED, AND SYBASE AND ALL CONTRIBUTORS HEREBY DISCLAIM
*    ALL SUCH WARRANTIES, INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF
*    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR
*    NON-INFRINGEMENT. Please see the License for the specific language
*    governing rights and limitations under the License.
*
*  ========================================================================
*
* Description:  Basic trap file types and interface functions.
*
****************************************************************************/


#ifndef TRPTYPES_H

#define FALSE 0
#define TRUE !FALSE
#define bool char
#define unsigned_8	char
#define unsigned_16	short int
#define unsigned_32	int
#define xreal long double
#define BOOL char
#define BYTE unsigned char
#define WORD unsigned short int
#define DWORD unsigned int

typedef struct {
   unsigned_32		offset;
   unsigned_16		segment;
} addr48_ptr;

typedef struct {
   unsigned_32		offset;
   unsigned_16		pad;
} addr48_off;


//#include <digtypes.h>

//#include "digpck.h"

#define TRAP_MAJOR_VERSION      17
#define TRAP_MINOR_VERSION      1
#define OLD_TRAP_MINOR_VERSION      0

#define REQUEST_FAILED ((unsigned)-1)

#define TrapVersionOK( ver )  ((ver).major == TRAP_MAJOR_VERSION)

typedef struct {
    unsigned_8          major;
    unsigned_8          minor;
    unsigned_8          remote;
} trap_version;

typedef unsigned_8      access_req;
typedef unsigned_32     trap_error;
typedef unsigned_32     trap_mhandle;   /* module handle */
typedef unsigned_32     trap_phandle;   /* process handle */
typedef unsigned_32     trap_shandle;   /* supplementary service handle */

typedef struct {
    access_req          core_req;
    trap_shandle        id;
} supp_prefix;

#ifndef TRAPENTRY
#define TRAPENTRY
#endif

typedef struct {
    void                *ptr;
    unsigned            len;
} mx_entry;

/* Client interface routines */
extern char     *LoadDumbTrap( trap_version * );
extern char     *LoadTrap( char *, char *, trap_version * );
extern void     TrapSetFailCallBack( void (*func)(void) );
extern unsigned TrapAccess( unsigned, mx_entry *, unsigned, mx_entry * );
extern unsigned TrapSimpAccess( unsigned, void *, unsigned, void * );
extern void     KillTrap(void);

#define TRPTYPES_H

#endif

