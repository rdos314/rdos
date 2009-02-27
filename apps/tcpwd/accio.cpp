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
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include "rdos.h"
#include "stdnt.h"

unsigned ReqFile_get_config( void )
{
    file_get_config_ret *ret;

    ret = (file_get_config_ret *)GetOutPtr( 0 );

    ret->file.ext_separator = '.';
    ret->file.path_separator[0] = '\\';
    ret->file.path_separator[1] = '/';
    ret->file.path_separator[2] = ':';
    ret->file.newline[0] = '\r';
    ret->file.newline[1] = '\n';
    return( sizeof( *ret ) );
}

unsigned ReqRead_user_keyboard( void )
{
    read_user_keyboard_req  *acc;
	read_user_keyboard_ret  *ret;

	acc = (read_user_keyboard_req *)GetInPtr( 0 );
    ret = (read_user_keyboard_ret *)GetOutPtr( 0 );

	if (RdosPollKeyboard())
		ret->key = (char)RdosReadKeyboard();
	else
	{
		RdosWaitMilli(acc->wait);
		if (RdosPollKeyboard())
			ret->key = (char)RdosReadKeyboard();
		else
			ret->key = 0;
	}

	return( sizeof( *ret ) );
}

unsigned ReqFile_open( void )
{
	file_open_req           *acc;
	file_open_ret           *ret;
	void                    *buff;

	acc = GetInPtr( 0 );
	buff = GetInPtr( sizeof( *acc ) );

	ret = GetOutPtr( 0 );

	ret->err = 0;
	ret->handle = RdosOpenFile(buff, 0);

	if (ret->handle == 0)
		ret->err = 1;

	return( sizeof( *ret ) );
}

unsigned ReqFile_seek( void )
{
	DWORD           rc;
	file_seek_req   *acc;
	file_seek_ret   *ret;

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );

	switch (acc->mode)
	{
		case 0:
			rc = acc->pos;
			RdosSetFilePos(acc->handle, rc);
			ret->err = 0;
			break;

		case 1:
			rc = RdosGetFilePos(acc->handle);
			rc += acc->pos;
			RdosSetFilePos(acc->handle, rc);
			ret->err = 0;
			break;

		case 2:
			rc = RdosGetFileSize(acc->handle);
			rc += acc->pos;
			RdosSetFilePos(acc->handle, rc);
			ret->err = 0;
			break;

		default:
			ret->err = 1;
	}
	ret->pos = RdosGetFilePos(acc->handle);

	return( sizeof( *ret ) );
}

unsigned ReqFile_write( void )
{
	file_write_req  *acc;
    file_write_ret  *ret;
    DWORD           len;
    void            *buff;

    acc = GetInPtr( 0 );
    buff = GetInPtr( sizeof( *acc ) );
    ret = GetOutPtr( 0 );

    len = GetTotalSize() - sizeof( *acc );

	ret->len = RdosWriteFile(acc->handle, buff, len);

	if (ret->len)
		ret->err = 0;
	else
		ret->err = 1;

	return( sizeof( *ret ) );
}

unsigned ReqFile_write_console( void )
{
	file_write_console_req  *acc;
	file_write_console_ret  *ret;
	DWORD                   len;
	void                    *buff;

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );
	buff = GetInPtr( sizeof( *acc ) );
	len = GetTotalSize() - sizeof( *acc );

	RdosWriteSizeString(buff, len);

	ret->err = 0;
	ret->len = len;

	return( sizeof( *ret ) );
}

unsigned ReqFile_read( void )
{
    DWORD           bytes;
	file_read_req   *acc;
	file_read_ret   *ret;
	void            *buff;

	acc = GetInPtr( 0 );
	ret = GetOutPtr( 0 );
	buff = GetOutPtr( sizeof( *ret ) );

	bytes = RdosReadFile(acc->handle, buff, acc->len);

	if (bytes)
		ret->err = 0;
	else
		ret->err = 1;

	return( sizeof( *ret ) + bytes );
}

unsigned ReqFile_close( void )
{
    file_close_req  *acc;
    file_close_ret  *ret;

    acc = GetInPtr( 0 );
    ret = GetOutPtr( 0 );

	ret->err = 0;
	RdosCloseFile(acc->handle);

	return( sizeof( *ret ) );
}

unsigned ReqFile_erase( void )
{
    file_erase_ret  *ret;
    char            *buff;

    buff = GetInPtr( sizeof( file_erase_req ) );
	ret = GetOutPtr( 0 );

	if (RdosDeleteFile(buff))
		ret->err = 0;
	else
		ret->err = 1;

	return( sizeof( *ret ) );

}

unsigned ReqFile_run_cmd( void )
{
	file_run_cmd_ret    *ret;

	//NYI: to do
	ret = GetOutPtr( 0 );
	ret->err = 0;
	return( sizeof( *ret ) );
}

unsigned ReqFile_string_to_fullpath( void )
{
	file_string_to_fullpath_req *acc;
	file_string_to_fullpath_ret *ret;
	char                        *name;
	char                        *fullname;

	acc = GetInPtr( 0 );
	name = GetInPtr( sizeof( *acc ) );
	ret = GetOutPtr( 0 );
	fullname = GetOutPtr( sizeof( *ret ) );

	ret->err = 0;

	return( sizeof( *ret ) + strlen( fullname ) + 1 );
}

