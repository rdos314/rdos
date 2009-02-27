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
* Description:  Routines to keep track of loaded modules and address maps.
*
****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "stdnt.h"


unsigned ReqMap_addr( void )
{
	int             i;
	HANDLE          handle;
	DWORD           bytes;
	pe_object       obj;
	WORD            seg;
	map_addr_req    *acc;
	map_addr_ret    *ret;
	header_info     hi;
	lib_load_info   *lli;
	WORD            stack;

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );

	seg = acc->in_addr.segment;
	switch( seg ) {
	case MAP_FLAT_CODE_SELECTOR:
	case MAP_FLAT_DATA_SELECTOR:
		seg = 0;
		break;
	default:
		--seg;
		break;
	}

	lli = &moduleInfo[acc->handle];

#ifdef WOW
	if( lli->is_16 ) {
		LDT_ENTRY   ldt;
		WORD        sel;
		thread_info *ti;
		/*
		 * much simpler for a WOW app.  We just ask for the selector that
		 * maps to the given segment number.
		 */
		ti = FindThread( DebugeeTid );
		pVDMGetModuleSelector( ProcessInfo.process_handle,
						ti->thread_handle, seg, lli->modname, &sel );
		pVDMGetThreadSelectorEntry( ProcessInfo.process_handle,
						ti->thread_handle, sel, &ldt );
		if( !ldt.HighWord.Bits.Pres ) {
			/*
			 * if the segment is not present, then we make the app load it
			 */
			force16SegmentLoad( ti, sel );
		}
		ret->out_addr.segment = sel;
		ret->out_addr.offset = 0;
	} else
#endif
 {
		/*
		 * for a 32-bit app, we get the PE header. We can look the up the
		 * object in the header and determine if it is code or data, and
		 * use that to assign the appropriate selector (either FlatCS
		 * or FlatDS).
		 */
		handle = lli->file_handle;

		if( !GetEXEHeader( handle, &hi, &stack ) ) {
			return( 0 );
		}
		if( hi.sig == EXE_PE ) {
			for( i = 0; i < hi.peh.num_objects; i++ ) {
				ReadFile( handle, &obj, sizeof( obj ), &bytes, NULL );
				if( i == seg ) {
					break;
				}
			}
			if( i == hi.peh.num_objects ) {
				return( 0 );
			}
			if( obj.flags & ( PE_OBJ_CODE | PE_OBJ_EXECUTABLE ) ) {
				ret->out_addr.segment = FlatCS;
			} else {
				ret->out_addr.segment = FlatDS;
			}
			ret->out_addr.offset = ( DWORD ) lli->base + obj.rva;
		} else {
			return( 0 );
		}
	}
	addSegmentToLibList( acc->handle, ret->out_addr.segment,
		 ret->out_addr.offset );
	ret->out_addr.offset += acc->in_addr.offset;
	ret->lo_bound = 0;
	ret->hi_bound = ~( addr48_off ) 0;
	return( sizeof( *ret ) );
}

/*
 * AccGetLibName - get lib name of current module
 */
unsigned ReqGet_lib_name( void )
{
	get_lib_name_req    *acc;
	get_lib_name_ret    *ret;
	char                *name;
	unsigned            i;

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );
	name = GetOutPtr( sizeof( *ret ) );

	ret->handle = 0;

	for( i = 0; i < ModuleTop; ++i ) {
		if( moduleInfo[i].newly_unloaded ) {
			ret->handle = i;
			name[0] = '\0';
			moduleInfo[i].newly_unloaded = FALSE;
			return( sizeof( *ret ) );
		} else if( moduleInfo[i].newly_loaded ) {
			ret->handle = i;
			strcpy( name, moduleInfo[i].filename );
			moduleInfo[i].newly_loaded = FALSE;
			/*
			 * once the debugger asks for a lib name, we also add it to our lib
			 * list.  This list is used to dump the list of all DLL's, and their
			 * selectors
			 */
			addModuleToLibList( i );
			return( sizeof( *ret ) + strlen( name ) + 1 );
		}
	}
	return( sizeof( *ret ) );
}


