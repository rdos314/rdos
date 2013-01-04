/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; either version 2.1 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
#
# The author of this program may be contacted at leif@rdos.net
#
# crt0.S                                                               
# GCC startupcode for RDOS
#
##########################################################################*/
  
#include "user.def"

    KEY_ENTRIES = 256
  
    .macro UserGate nr 
    .byte 0x9A
    .long \nr
    .word 2
    .endm 

    .data
    .align  8

_key_section:
    .word 0

_key_ref_arr:
    .long 0

_key_dtor_arr:
    .long 0

	.text
	.align 4

	.global __deregister_frame_info

__deregister_frame_info:
    ret

    .global __register_frame_info

__register_frame_info:
    ret

    .global free

free:
    ret

					  					    
/*##########################################################################
#
#   Name       : _start
#
#   Purpose....: GCC startup-code
#
##########################################################################*/

	.global _start

_start:
	call main
	call	exit
					    
/*##########################################################################
#
#   Name       : _exit
#
#   Purpose....: GCC exit-code
#
##########################################################################*/

	.global _exit

_exit:
					    					    
/*##########################################################################
#
#   Name       : __getreent
#
#   Purpose....: ?
#
##########################################################################*/

	.global __getreent

__getreent:
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_key_create
#
#   Purpose....: Emulate GCC pthread_key_create
#
#   Parameters.: dtor
#
#   Returns....: Key index
#
##########################################################################*/

	.global __rdos_thread_key_create
	
__rdos_thread_key_create:
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_key_delete
#
#   Purpose....: Emulate GCC pthread_key_delete
#
#   Parameters.: index
#
#   Returns....: result
#
##########################################################################*/

	.global __rdos_thread_key_delete
	
__rdos_thread_key_delete:
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_getspecific
#
#   Purpose....: Emulate GCC pthread_getspecific
#
#   Parameters.: index
#
#   Returns....: value
#
##########################################################################*/

	.global __rdos_thread_getspecific
	
__rdos_thread_getspecific:
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_setspecific
#
#   Purpose....: Emulate GCC pthread_setspecific
#
#   Parameters.: index
#                value
#
##########################################################################*/

	.global __rdos_thread_setspecific
	
__rdos_thread_setspecific:
	ret
