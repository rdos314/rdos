/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# rdos.cpp
# Non-inlined functions for Watcom
#
########################################################################*/

#include <memory.h>
#include <process.h>
#include "rdos.h"

#define FALSE 0

int RdosCarryToBool();

#pragma aux RdosCarryToBool = \
    CarryToBool \
    value [eax];

void RdosBlitBase();

#pragma aux RdosBlitBase = \
    CallGate_blit;

void RdosDrawMaskBase();

#pragma aux RdosDrawMaskBase = \
    CallGate_draw_mask;

void RdosGetBitmapInfoBase();

#pragma aux RdosGetBitmapInfoBase = \
    CallGate_get_bitmap_info;

void RdosReadDirBase();

#pragma aux RdosReadDirBase = \
    CallGate_read_dir;

void RdosGetModuleResourceBase();

#pragma aux RdosGetModuleResourceBase = \
    CallGate_get_module_resource;

/*##########################################################################
#
#   Name       : RdosCreateThread
#
#   Purpose....: Create a new thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RdosCreateThread(void (*Startup)(void *Param), const char *Name, void *Param, int StackSize)
{
    _beginthread(Startup, Name, StackSize, Param);
}

/*##########################################################################
#
#   Name       : RdosCreatePrioThread
#
#   Purpose....: Create a new thread, with priority
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RdosCreatePrioThread(void (*Start)(void *Param), int Prio, const char *Name, void *Param, int StackSize)
{
    _beginthread(Start, Name, StackSize, Param);
}

/*##########################################################################
#
#   Name       : RdosBlit
#
#   Purpose....: Blit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RdosBlit(int SrcHandle, int DestHandle, int width, int height, int SrcX, int SrcY, int DestX, int DestY)
{
    _asm
    {
        mov esi,SrcX
        mov eax,SrcY
        shl eax,16
        or esi,eax
        mov edi,DestX
        mov eax,DestY
        shl eax,16
        or edi,eax
        mov eax,SrcHandle
            mov ebx,DestHandle
        mov ecx,width
        mov edx,height
    }
    RdosBlitBase();
}

/*##########################################################################
#
#   Name       : RdosDrawMask
#
#   Purpose....: Draw mask
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RdosDrawMask(int handle, void *mask, int RowSize, int width, int height, int SrcX, int SrcY, int DestX, int DestY)
{
    _asm
    {
        mov ebx,handle
        mov edi,mask
        mov eax,RowSize
        mov esi,height
        mov eax,width
        shl eax,16
        or esi,eax
        mov ecx,SrcX
        mov eax,SrcY
        shl eax,16
        or ecx,eax
        mov edx,DestX
        mov eax,DestY
        shl eax,16
        or edx,eax
    }
    RdosDrawMaskBase();
}

/*##########################################################################
#
#   Name       : RdosGetBitmapInfo
#
#   Purpose....: Get bitmap info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RdosGetBitmapInfo(int handle, int *BitPerPixel, int *width, int *height, int *linesize, void **buffer)
{
    _asm
    {
        mov ebx,handle
    }
    RdosGetBitmapInfoBase();
    _asm
    {
        mov ebx,BitPerPixel
        movzx eax,al
        mov [ebx],eax
        mov ebx,width
        movzx ecx,cx
        mov [ebx],ecx
        mov ebx,height
        movzx edx,dx
        mov [ebx],edx
        mov ebx,linesize
        movzx esi,si
        mov [ebx],esi
        mov ebx,buffer
        mov [ebx],edi
    }
}

/*##########################################################################
#
#   Name       : RdosReadDir
#
#   Purpose....: Read directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int RdosReadDir(int Handle, int EntryNr, int MaxNameSize, char *PathName, long *FileSize, int *Attribute, unsigned long *MsbTime, unsigned long *LsbTime)
{
    int val;
    
    _asm
    {
        mov ebx,Handle
        mov edx,EntryNr
        mov ecx,MaxNameSize
        mov edi,PathName
    }
    RdosReadDirBase();
    _asm
    {
        mov esi,FileSize
        mov [esi],ecx
        movzx ebx,bx
        mov esi,Attribute
        mov [esi],ebx
        mov esi,MsbTime
        mov [esi],edx
        mov esi,LsbTime
        mov [esi],eax
    }
    val = RdosCarryToBool();
    return val;
}

/*##########################################################################
#
#   Name       : RdosResource
#
#   Purpose....: Read resource
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int RdosReadResource(int handle, int ID, char *Buf, int Size)
{
    char *RcPtr;
    int RcSize;
    int ok;
    
    if (handle == 0)
    {
        _asm
        {
            mov eax,fs:[0x24]
            mov handle,eax
        }
    }

    _asm
    {
        mov eax,ID
        mov edx,6
    }
    RdosGetModuleResourceBase();
    _asm
    {
        mov RcSize,ecx
        mov RcPtr,edi
    }
    ok = RdosCarryToBool();

    if (!ok)
        RcSize = 0;

    if (RcSize)
    {
        if (RcSize > Size)
            RcSize = Size;
        memcpy(Buf, RcPtr, RcSize);            
    }    

    return RcSize;
}

/*##########################################################################
#
#   Name       : RdosBinaryResource
#
#   Purpose....: Read binary resource
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int RdosReadBinaryResource(int handle, int ID, char *Buf, int Size)
{
    char *RcPtr;
    int RcSize;
    int ok;
    
    if (handle == 0)
    {
        _asm
        {
            mov eax,fs:[0x24]
            mov handle,eax
        }
    }

    _asm
    {
        mov eax,ID
        mov edx,10
    }
    RdosGetModuleResourceBase();
    _asm
    {
        mov RcSize,ecx
        mov RcPtr,edi
    }
    ok = RdosCarryToBool();
    if (!ok)
        RcSize = 0;

    if (RcSize)
    {
        if (RcSize > Size)
            RcSize = Size;
        memcpy(Buf, RcPtr, RcSize);            
    }    

    return RcSize;
}
