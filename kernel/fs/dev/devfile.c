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
    int HandleOffset;
    int InfoOffset;
    struct RdosFileMapEntry MapArr[240];
};

struct RdosFileHandleInfo
{
    long long ReqSize;
    long long PosArr[480];
    int Bitmap[15];
};

short int GetSel(void *ptr);
#pragma aux GetSel = \
    __parm [__dx __eax]  \
    __value [__dx]

char *OffsetToPtr(short int sel, int offset);
#pragma aux OffsetToPtr = \
    __parm [__dx] [__eax]  \
    __value [__dx __eax]

void memcpy(void *dst, void *src, int count);
#pragma aux memcpy = \
    "rep movs byte ptr es:[edi],fs:[esi]" \
    __parm [es edi] [fs esi] [ecx]

extern void LockMod(struct RdosFileMap *Map);
#pragma aux LockMod parm routine [fs esi]

extern void UnlockMod(struct RdosFileMap *Map);
#pragma aux UnlockMod parm routine [fs esi]

extern void VfsMapHandle(int handle, long long pos, int size);
#pragma aux VfsMapHandle parm routine [__ebx] [__edx __eax] [__ecx]

extern void VfsGrowHandle(int handle, long long csize, int incr);
#pragma aux VfsGrowHandle parm routine [__ebx] [__edx __eax] [__ecx]

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
    short int sel = GetSel(Map);
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
                src = OffsetToPtr(sel, entry->BaseOffset);
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
#   Name       : VfsWriteOne
#
#   Purpose....: Do one write
#
#   In params..:
#   Out params.: *
#   Returns....:
#
##########################################################################*/
static int VfsWriteOne(struct RdosFileMap *Map, int index, char *buf, long long pos, int size)
{
    int diff;
    int count = 0;
    char *dst;
    short int sel = GetSel(Map);
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
                dst = OffsetToPtr(sel, entry->BaseOffset);
                dst += diff;
                if (count > size)
                    count = size;

                memcpy(dst, buf, count);
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
#pragma aux VfsRead "*" parm routine [ebx] [fs esi] [edx eax] [es edi] [ecx] value [ecx]
int VfsRead(int Handle, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex = 0;
    short int sel = GetSel(Map);
    struct RdosFileInfo *info = (struct RdosFileInfo *)OffsetToPtr(sel, Map->InfoOffset);
    struct RdosFileHandleInfo *hinfo = (struct RdosFileHandleInfo *)OffsetToPtr(sel, Map->HandleOffset);
    long long TotalSize = info->CurrSize;

    if (hinfo->ReqSize > TotalSize)
        TotalSize = hinfo->ReqSize;

    if (Pos > TotalSize)
        Pos = TotalSize;

    if (Pos + Size > TotalSize)
        Size = TotalSize - Pos;

    LockMod(Map);

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
                UnlockMod(Map);

                VfsMapHandle(Handle, Pos, Size);

                LockMod(Map);
                LastIndex = VfsFind(Map, Pos);
                if (LastIndex >= 0)
                    break;
            }

            if (LastIndex < 0)
                break;
        }
    }

    UnlockMod(Map);

    return ret;
}

/*##########################################################################
#
#   Name       : VfsWrite
#
#   Purpose....: VFS write
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes written
#
##########################################################################*/
#pragma aux VfsWrite "*" parm routine [ebx] [fs esi] [edx eax] [es edi] [ecx] value [ecx]
int VfsWrite(int Handle, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex = 0;
    short int sel = GetSel(Map);
    struct RdosFileInfo *info = (struct RdosFileInfo *)OffsetToPtr(sel, Map->InfoOffset);
    struct RdosFileHandleInfo *hinfo = (struct RdosFileHandleInfo *)OffsetToPtr(sel, Map->HandleOffset);
    long long Grow;

    Grow = Pos + Size - info->DiscSize;

    if (Grow > 0)
        VfsGrowHandle(Handle, info->DiscSize, Grow);

    LockMod(Map);

    while (Size)
    {
        if (LastIndex >= 0)
        {
            count = VfsWriteOne(Map, LastIndex, ptr, Pos, Size);
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
                UnlockMod(Map);

                Grow = Pos + Size - info->DiscSize;

                if (Grow > 0)
                    VfsGrowHandle(Handle, info->DiscSize, Grow);
                else
                    VfsMapHandle(Handle, Pos, Size);

                LockMod(Map);
                LastIndex = VfsFind(Map, Pos);
                if (LastIndex >= 0)
                    break;
            }

            if (LastIndex < 0)
                break;
        }
    }

    UnlockMod(Map);

    return ret;
}
