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
# devfile.cpp
# Memmap support in kernel space
#
########################################################################*/

struct RdosFileInfo
{
    long long DiscSize;
    long long CurrSize;
    long long AccessTime;
    long long ModifyTime;
    int Attrib;
    int Flags;
    int Uid;
    int Gid;
    int ServHandle;
    char Name[1];
};

struct RdosFileMapEntry
{
    long long Pos;
    int Size;
    int BaseOffset;
};

struct RdosFileMap
{
    unsigned char SortedArr[241];
    char Resv[3];
    int Count;
    int HandlePtr;
    int InfoPtr;
    struct RdosFileMapEntry MapArr[240];
};

char *OffsetToPtr(int offset);
#pragma aux OffsetToPtr = \
    "mov dx,1BBh"    \
    __parm [__eax]  \
    __value [__dx __eax]

void memcpy(void *dst, void *src, int count);
#pragma aux memcpy = \
    "rep movs byte ptr es:[edi],fs:[esi]" \
    __parm [es edi] [fs esi] [ecx] 

/*##########################################################################
#
#   Name       : VfsFind
#
#   Purpose....: VFS find
#
#   In params..: pos, size
#   Out params.: *
#   Returns....: Buffer index
#
##########################################################################*/
static int VfsFind(struct RdosFileMap *Map, long long Pos)
{
    int Step = 0x80;
    int Curr = 0;
    unsigned char index;
    long long Diff;

    for (;;)
    {
        index = Map->SortedArr[Curr + Step];
        if (index != 0xFF)
        {
            Diff = Pos - Map->MapArr[index].Pos;
            if (Diff >= 0)
            {
                Curr += Step;

                if (Diff < Map->MapArr[index].Size)
                    return Curr;
            }
        }
        if (Step)
            Step = Step >> 1;
        else
            break;
    }
    return -1;
}

/*##########################################################################
#
#   Name       : VfsReadOne
#
#   Purpose....: Do one read
#
#   In params..:
#   Out params.: *
#   Returns....:
#
##########################################################################*/
static int VfsReadOne(struct RdosFileMap *Map, int index, char *buf, long long pos, int size)
{
    int diff;
    int count = 0;
    char *src;
    struct RdosFileMapEntry *entry;

    index = Map->SortedArr[index];

    if (index >= 0)
    {
        entry = &Map->MapArr[index];
        diff = pos - entry->Pos;

        if (entry->BaseOffset && diff >= 0)
        {
            count = entry->Size - diff;

            if (count > 0)
            {
                src = OffsetToPtr(entry->BaseOffset);
                src += diff;
                if (count > size)
                    count = size;

                memcpy(buf, src, count);
            }
            else
                count = 0;
        }
    }

    return count;
}

/*##########################################################################
#
#   Name       : VfsRead
#
#   Purpose....: VFS read
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes read
#
##########################################################################*/
#pragma aux VfsRead "*" parm routine [ebx] [fs esi] [edx eax] [es edi] [ecx] value [eax]
int VfsRead(int Handle, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int diff;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex = 0;

//    EnterFutex(&Map->Handle->Futex);

    while (Size)
    {
        if (LastIndex >= 0)
        {
            count = VfsReadOne(Map, LastIndex, ptr, Pos, Size);
            ptr += count;
            Size -= count;
            ret += count;
            Pos += count;
        }

        if (Size)
        {
            LastIndex = VfsFind(Map, Pos);

            for (i = 0; i < 10; i++)
            {
//                LeaveFutex(&Map->Handle->Futex);

//                RdosMapVfsFile(FHandle, Pos, Size);

//                EnterFutex(&Map->Handle->Futex);
                LastIndex = VfsFind(Map, Pos);
                if (LastIndex >= 0)
                    break;
            }

            if (LastIndex < 0)
                break;
        }
    }

//    LeaveFutex(&Map->Handle->Futex);

    return ret;
}
