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
* Description:  WHEN YOU FIGURE OUT WHAT THIS FILE DOES, PLEASE
*               DESCRIBE IT HERE!
*
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <direct.h>
#include "rdos.h"
#include "stdnt.h"

#define MAX_WP  32


typedef struct {
	addr48_ptr      loc;
	DWORD           value;
	DWORD           value_high; /* Extended for 8 byte breakpoints */
	DWORD           linear;
	unsigned short  len;
	unsigned short  dregs;
}                   watch_point;

static watch_point  wpList[MAX_WP];

typedef struct break_point {
	struct break_point  *next;
	addr48_ptr          addr;
	BYTE                byte;
}                       break_point;

static break_point      *Breaks = NULL;

unsigned ReqSet_break( void )
{
	char		     ch;
	set_break_req   *acc;
	set_break_ret   *ret;
	break_point     *new;

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );

	RdosReadThreadMem(CurrThread, acc->break_addr.segment, acc->break_addr.offset, &ch,
		sizeof( ch ) );
	ret->old = ch;
	new = RdosAllocateMem( sizeof( *new ) );
	new->byte = ch;
	new->addr = acc->break_addr;
	new->next = Breaks;
	Breaks = new;
	ch = 0xCC;
	RdosWriteThreadMem(CurrThread, acc->break_addr.segment, acc->break_addr.offset, &ch,
		sizeof( ch ) );
	return( sizeof( *ret ) );
}

unsigned ReqClear_break( void )
{
	char		     ch;
	clear_break_req *acc;
	break_point     *brk;
	break_point     *next;

	// we can assume all breaks are cleared at once

	for( brk = Breaks; brk != NULL; brk = next ) {
		next = brk->next;
		RdosFreeMem( brk );
	}
	Breaks = NULL;
	acc = GetInPtr( 0 );
	ch = acc->old;
	RdosWriteThreadMem(CurrThread, acc->break_addr.segment, acc->break_addr.offset, &ch,
		sizeof( ch ) );
	return( 0 );
}

BOOL FindBreak( WORD segment, DWORD offset, BYTE *ch )
{
	break_point *brk;

	for( brk = Breaks; brk != NULL; brk = brk->next ) {
		if( brk->addr.segment != segment ) {
			continue;
		}
		if( brk->addr.offset != offset ) {
            continue;
        }
        *ch = brk->byte;
        return( TRUE );
    }
    return( FALSE );
}

/*
 * setDR6 - set value of debug register 6
 */
static void setDR6( DWORD tmp )
{
}

/*
 * SetDR7 - set value of debug register 7
 */
void SetDR7( DWORD tmp )
{
	Tss con;

	RdosGetThreadTss(CurrThread, &con);
	con.dr7 = tmp;
	RdosSetThreadTss(CurrThread, &con);
}

/*
 * GetDR6 - get value of debug register 6
 */
DWORD GetDR6( void )
{
	return( 0 );
}

static DWORD setDRn( int i, DWORD linear, long type )
{
	Tss con;

	RdosGetThreadTss(CurrThread, &con);
	con.dr[i] = linear;
	RdosSetThreadTss(CurrThread, &con);

    return( ( type << DR7_RWLSHIFT( i ) )
//        | ( DR7_GEMASK << DR7_GLSHIFT(i) ) | DR7_GE
          | ( DR7_LEMASK << DR7_GLSHIFT( i ) ) | DR7_LE );
}

/*
 * ClearDebugRegs - set for no watch points
 */
void ClearDebugRegs( void )
{
	int i;

	for( i = 0; i < 4; i++ ) {
		setDRn( i, 0L, 0L );
	}
	SetDR7( 0 );
}

/*
 * SetDebugRegs - set debug registers for watch points
 */
BOOL SetDebugRegs( void )
{
	int         needed;
	int         i;
	int         dr;
	DWORD       dr7;
	watch_point *wp;


	/*
	 *  Carl. I really don't like this code, but the DR count check is done above
	 *  so there's not much harm that can happen. We can't get here needing more than 4
	 *  debug registers. Just ugly!
	 *
	 *  the linear address is adjusted by size so a short across a dword boundary will screw
	 *  up I think!
	 */

		needed = 0;
		for( i = 0; i < WPCount; i++ ) {
			needed += wpList[i].dregs;
		}
		if( needed > 4 ) {
			return( FALSE );
		}

		dr  = 0;
		dr7 = 0;
		for( i = 0, wp = wpList; i < WPCount; i++, wp++ ) {

			DWORD   boundary_check = wp->linear & 0x3;

			switch( wp->dregs ) {
			case 1: /* If we only need one register, then we are 1 byte anywhere, 2 bytes on word boundary, or 4 bytes on dword boundary */
				{
					dr7 |= setDRn( dr+0, wp->linear, DRLen( wp->len ) | DR7_BWR );
					dr++;
				}
				break;
			case 2: /* If we need 2 registers, then ... */
				{
					if( wp->len == 2 ) {        /* For a 2 byte write, this is two 1's at any address */
						dr7 |= setDRn( dr+0, wp->linear+0, DRLen( 1 ) | DR7_BWR );
						dr7 |= setDRn( dr+1, wp->linear+1, DRLen( 1 ) | DR7_BWR );
					} else if( wp->len == 4 ) { /* For a 4 byte write, this must be two 2's at a word boundary */
						dr7 |= setDRn( dr+0, wp->linear+0, DRLen( 2 ) | DR7_BWR );
						dr7 |= setDRn( dr+1, wp->linear+2, DRLen( 2 ) | DR7_BWR );
					} else if( wp->len == 8 ) { /* For an 8 byte write, this must be two 4's at a dword boundary */
						dr7 |= setDRn( dr+0, wp->linear+0, DRLen( 4 ) | DR7_BWR );
						dr7 |= setDRn( dr+1, wp->linear+4, DRLen( 4 ) | DR7_BWR );
					}
					dr += 2;
				}
				break;
			case 3: /* If we need 3 registers, then must be 4 bytes or larger, and ... */
				{
					if( wp->len == 4 ) {        /* For a 4 byte write, this must be 1,2,1 at a odd boundary */
						dr7 |= setDRn( dr+0, wp->linear+0, DRLen( 1 ) | DR7_BWR );
						dr7 |= setDRn( dr+1, wp->linear+1, DRLen( 2 ) | DR7_BWR );
						dr7 |= setDRn( dr+2, wp->linear+3, DRLen( 1 ) | DR7_BWR );
					} else if( wp->len == 8 ) { /* For an 8 byte write, this must be 2,4,2 at a word boundary */
						dr7 |= setDRn( dr+0, wp->linear+0, DRLen( 2 ) | DR7_BWR );
						dr7 |= setDRn( dr+1, wp->linear+2, DRLen( 4 ) | DR7_BWR );
						dr7 |= setDRn( dr+2, wp->linear+6, DRLen( 2 ) | DR7_BWR );
					}
					dr += 3;
				}
				break;
			case 4: /* If we need 4 registers, then must be 8 bytes and ... */
				{
					if( boundary_check == 1 ) { /* Need 1, 2, 4, 1 */
						dr7 |= setDRn( dr+0, wp->linear+0, DRLen( 1 ) | DR7_BWR );
						dr7 |= setDRn( dr+1, wp->linear+1, DRLen( 2 ) | DR7_BWR );
						dr7 |= setDRn( dr+2, wp->linear+3, DRLen( 4 ) | DR7_BWR );
						dr7 |= setDRn( dr+3, wp->linear+7, DRLen( 1 ) | DR7_BWR );
					} else { /* boundary check = 3 - Need 1, 4, 2, 1 */
						dr7 |= setDRn( dr+0, wp->linear+0, DRLen( 1 ) | DR7_BWR );
						dr7 |= setDRn( dr+1, wp->linear+1, DRLen( 4 ) | DR7_BWR );
						dr7 |= setDRn( dr+2, wp->linear+5, DRLen( 2 ) | DR7_BWR );
						dr7 |= setDRn( dr+3, wp->linear+7, DRLen( 1 ) | DR7_BWR );
					}
					dr += 4;
				}
				break;
			default:
				return FALSE;
			}
		}

	SetDR7( dr7 );
	return( TRUE );
}

/*
 * CheckWatchPoints - check if a watchpoint was hit
 */
BOOL CheckWatchPoints( void )
{
	DWORD   value;
	int     i;

	for( i = 0; i < WPCount; i++ ) {
		RdosReadThreadMem( CurrThread, wpList[i].loc.segment, wpList[i].loc.offset, &value, sizeof( value ) );
		if( value != wpList[i].value ) {
			return( TRUE );
		}
		if( wpList[i].len == 8 ) {
			RdosReadThreadMem( CurrThread, wpList[i].loc.segment, wpList[i].loc.offset + sizeof( value ), &value, sizeof( value ) );
			if( value != wpList[i].value_high ) {
				return( TRUE );
			}
		}
	}
	return( FALSE );
}


unsigned ReqSet_watch( void )
{
	set_watch_req   *acc;
	set_watch_ret   *ret;
	DWORD           value, value_high;
	watch_point     *curr;
	DWORD           linear;
	DWORD           lencalc;

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );
	ret->multiplier = 100000;
	ret->err = 1;
	if( WPCount < MAX_WP && acc->size <= 8 ) {
		ret->err = 0;
		curr = wpList + WPCount;
		curr->loc.segment = acc->watch_addr.segment;
		curr->loc.offset = acc->watch_addr.offset;

		/*
		 *  This always reads 4 bytes. I think it should read min(4, acc->size) and ensure
		 *  the rest is NULed out for comparison purposes. Could read past a segment end
		 *  otherwise
		 */
		RdosReadThreadMem( CurrThread, acc->watch_addr.segment, acc->watch_addr.offset, &value, sizeof ( value ));
		curr->value = value;
		curr->len = acc->size;

		/*
		 *  Carl: The debugger main has been extended to request 8 byte breakpoints. This code was originally
		 *  only storing the bytes from above - which is probably wrong as well!
		 *  Nevertheless, I store the next 4 bytes if the watchpoint is larger than 4 bytes
		 */
		if( curr->len > 4 ) {
			RdosReadThreadMem( CurrThread, acc->watch_addr.segment, acc->watch_addr.offset + 4, &value_high, sizeof( value_high ) );
			curr->value_high = value_high;
		}

		WPCount++;
		linear = RdosGetThreadLinear( CurrThread, acc->watch_addr.segment, acc->watch_addr.offset );
		lencalc = min(curr->len, 4);

		/* Calculate where the breakpoint should be */
		/* 1 byte breakpoint starts at where it says on the tin -   OK */
		/* 2 byte breakpoint starts at previous word offset -       OK */
		/* 4 byte breakpoint starts at previous dword offset -      not sure */
		/* 8 byte breakpoint starts at previous dword offset -      not sure */
		curr->linear = linear;

		/* If we are supporting exact break on write, then don't adjust the linear address */
		if (1)
		{
			DWORD   boundary_check = linear & 0x3;

			if( 1 == curr->len ) {
				curr->dregs = 1;
			} else if ( 2 == curr->len ) {
				curr->dregs = 1;
				if(boundary_check & 1)
					curr->dregs++;      /* Need two 1 byte watches */
			} else if ( 4 == curr->len ) {
				switch( boundary_check ) {
					case 0:
						curr->dregs = 1;    /* 0x00-0x03:   4B@0x00 */
						break;
					case 1:
						curr->dregs = 3;    /* 0x01-0x04:   1B@0x01, 2B@0x02, 1@0x04 */
						break;
					case 2:
						curr->dregs = 2;    /* 0x02-0x05:   2B@0x02, 2B@0x04 */
						break;
					case 3:
						curr->dregs = 3;    /* 0x03-0x06L   1B@0x03, 2B@0x04, 1@0x06 */
						break;
				}
			} else if ( 8 == curr->len ) {
				switch( boundary_check ) {
					case 0:
						curr->dregs = 2;    /* 0x00-0x07:   4B@0x00, 4B@0x04 */
						break;
					case 1:
						curr->dregs = 4;    /* 0x01-0x08:   1B@0x01, 2B@0x02, 4B@0x04, 1B@0x08 */
						break;
					case 2:
						curr->dregs = 3;    /* 0x02-0x09:   2B@0x02, 4B@0x04, 2B@0x08 */
						break;
					case 3:
						curr->dregs = 4;    /* 0x03-0x0A:   1B@0x03, 4B@0x04, 2B@0x08, 1B@0x0A */
						break;
				}
			} else {
				return 0;   /* Error!!! */
			}
		}

		if(1) /* New scope */
		{
			unsigned    i;
			unsigned    needed;

			needed = 0;
			for( i = 0; i < WPCount; ++i ) {
				needed += wpList[i].dregs;
			}
			if( needed <= 4 ) {
				ret->multiplier |= USING_DEBUG_REG;
			}
		}
	}
	return( sizeof( *ret ) );
}

unsigned ReqClear_watch( void )
{
	clear_watch_req *acc;
	watch_point     *dst;
	watch_point     *src;
	int             i;

	acc = GetInPtr( 0 );
	dst = src = wpList;
	for( i = 0; i < WPCount; i++ ) {
		if( src->loc.segment != acc->watch_addr.segment
		||  src->loc.offset != acc->watch_addr.offset ) {
			dst->loc.offset = src->loc.offset;
			dst->loc.segment = src->loc.segment;
			dst->value = src->value;
			dst->value_high = src->value_high;
			dst++;
		}
		src++;
	}
	WPCount--;
	return( 0 );
}

