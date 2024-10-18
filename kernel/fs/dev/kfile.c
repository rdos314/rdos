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
# kfile.cpp
# Memmap support in kernel files
#
########################################################################*/

struct RdosFileInfo
{
    long long SectorCount;
    long long DiscSize;
    long long CurrSize;
    long long AccessTime;
    long long ModifyTime;
    int Attrib;
    int Flags;
    int Uid;
    int Gid;
    int ServHandle;
    int BytesPerSector;
    char Name[1];
};

struct RdosFileMapEntry
{
    long long Pos;
    int Size;
    int Linear;
};

struct RdosFileMap
{
    unsigned char SortedArr[241];
    unsigned short int Resv;
    char Update;
    int Count;
    struct RdosFileInfo *Info;
    struct RdosFileMapEntry MapArr[240];
};

char *LinearToPtr(int linear);
#pragma aux LinearToPtr = \
    "mov dx,20h" \
    __parm [__eax]  \
    __value [__dx __eax]

void memcpy(void *dst, void *src, int count);
#pragma aux memcpy = \
    "rep movs byte ptr es:[edi],fs:[esi]" \
    __parm [es edi] [fs esi] [ecx]

/*##########################################################################
#
#   Name       : KernelRead
#
#   Purpose....: Kernel read
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes read
#
##########################################################################*/
#pragma aux KernelRead "*" parm routine [ebx] [fs esi] [edx eax] [es edi] [ecx] value [ecx]
int KernelRead(int HandleMod, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex;
    struct RdosFileInfo *info = Map->Info;
    long long TotalSize = info->CurrSize;

//    if (Map->Update)
//        UpdateVfsFile(HandleMod);

    if (Pos + Size > TotalSize)
        Size = TotalSize - Pos;

    if (Size < 0)
        Size = 0;


    return ret;
}
