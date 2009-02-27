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

#include "rdos.h"
#include "stdnt.h"

unsigned ReqFileInfo_getdate( void )
{
	file_info_get_date_req  *req;
	file_info_get_date_ret  *ret;
	char                    *name;
	WORD                    md;
	WORD                    mt;
	int						handle;
	unsigned long	  		msb, lsb;

	req = GetInPtr( 0 );
	name = GetInPtr( sizeof( *req ) );
	ret = GetOutPtr( 0 );

	handle = RdosOpenFile(name, 0);
	if (handle)
	{
		RdosGetFileTime(handle, &msb, &lsb);
		RdosTicsToDosTimeDate(msb, lsb, &md, &mt);
		RdosCloseFile(handle);

		ret->err = 0;
		ret->date = ( md << 16 ) + mt;
	}
	else
		ret->err = 1;

	return( sizeof( *ret ) );
}

unsigned ReqFileInfo_setdate( void )
{
	file_info_set_date_req  *req;
	file_info_set_date_ret  *ret;
	char                    *name;
	WORD                    md;
	WORD                    mt;
	int						handle;
	unsigned long	  		msb, lsb;

	req = GetInPtr( 0 );
	name = GetInPtr( sizeof( *req ) );
	ret = GetOutPtr( 0 );

	md = ( req->date >> 16 ) & 0xffff;
	mt = req->date;
	RdosDosTimeDateToTics(md, mt, &msb, &lsb);

	handle = RdosOpenFile(name, 0);
	if (handle)
	{
		RdosSetFileTime(handle, msb, lsb);
		RdosCloseFile(handle);

		ret->err = 0;
	}
	else
		ret->err = 1;

	return( sizeof( *ret ) );
}

