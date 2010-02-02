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
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "rdos.h"
#include "stdnt.h"


/*
 * AccLoadProg - create a new process for debugging
 */
unsigned ReqProg_load( void )
{
	prog_load_req   *acc;
    prog_load_ret   *ret;
	char            *parm;
	char            argstr[256];
    char            *src;
    char            *dst;
	char            exe_name[256];
	int				drive;
	char			start_dir[256];

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );
	parm = GetInPtr( sizeof( *acc ) );

	ret->flags = 0;

	if( FindFilePath( parm, exe_name, "exe" ) == 0 )
	{
		ret->err = 0;
		drive = RdosGetCurDrive();
		start_dir[0] = (char)drive + 'a';
		start_dir[1] = ':';
		start_dir[2] = '\\';
		RdosGetCurDir(drive, &start_dir[3]);

        dst = argstr;
        src = parm;
        while( *src != 0 )
            src++;
        src++;

        // parm layout
        // <--parameters-->0<--program_name-->0<--arguments-->0
        //

        while( *src != 0 )
        {
            *dst = *src;
            src++;
            dst++;
        }
        *dst = 0;

		ret->mod_handle = RdosSpawnDebug(exe_name, argstr, start_dir, &CurrThread);
		if (ret->mod_handle == 0)
			ret->err = 1;
		else
			ret->task_id = CurrThread;

		ret->flags |= LD_FLAG_HAVE_RUNTIME_DLLS;
		ret->flags |= LD_FLAG_IS_STARTED;
	}
	else
		ret->err = 1;

	return( sizeof( *ret ) );

}

unsigned ReqProg_kill( void )
{
	prog_kill_ret   *ret;

	ret = GetOutPtr( 0 );
	ret->err = 0;

// TODO: process termination

	return( sizeof( *ret ) );
}

