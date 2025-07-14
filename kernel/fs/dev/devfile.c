/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# devfile.cpp
# Memmap support in kernel space
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
    int BaseOffset;
};

struct RdosFileMap
{
    unsigned char SortedArr[241];
    unsigned short int Resv;
    char Update;
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

extern void LockMap(struct RdosFileMap *Map);
#pragma aux LockMap parm routine [fs esi]

extern void UnlockMap(struct RdosFileMap *Map);
#pragma aux UnlockMap parm routine [fs esi]

extern void MapVfsFile(int handlemod, long long pos, int size);
#pragma aux MapVfsFile parm routine [__esi] [__edx __eax] [__ecx]

extern void GrowVfsFile(int handle, long long csize, int incr);
#pragma aux GrowVfsFile parm routine [__esi] [__edx __eax] [__ecx]

extern void UpdateVfsFile(int handle);
#pragma aux UpdateVfsFile parm routine [__esi]

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
static int VfsFind(int HandleMod, struct RdosFileMap *Map, long long Pos)
{
    int Step = 0x80;
    int Curr = 0;
    unsigned char index;
    long long Diff;

    for (;;)
    {
        if (Map->Update)
            UpdateVfsFile(HandleMod);

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
    struct RdosFileHandleInfo *hinfo = (struct RdosFileHandleInfo *)OffsetToPtr(sel, Map->HandleOffset);
    long long FileSize;

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

                FileSize = pos + count;
                if (FileSize > hinfo->ReqSize)
                    hinfo->ReqSize = FileSize;
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
int VfsRead(int HandleMod, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex;
    short int sel = GetSel(Map);
    struct RdosFileInfo *info = (struct RdosFileInfo *)OffsetToPtr(sel, Map->InfoOffset);
    long long TotalSize = info->CurrSize;

    if (Map->Update)
        UpdateVfsFile(HandleMod);

    if (Pos + Size > TotalSize)
        Size = TotalSize - Pos;

    if (Size < 0)
        Size = 0;

    LockMap(Map);

    LastIndex = VfsFind(HandleMod, Map, Pos);

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
            for (i = 0; i < 10; i++)
            {
                UnlockMap(Map);

                MapVfsFile(HandleMod, Pos, Size);

                LockMap(Map);
                LastIndex = VfsFind(HandleMod, Map, Pos);
                if (LastIndex >= 0)
                    break;
            }

            if (LastIndex < 0)
                break;
        }
    }

    UnlockMap(Map);

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
int VfsWrite(int HandleMod, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex = 0;
    short int sel = GetSel(Map);
    struct RdosFileInfo *info = (struct RdosFileInfo *)OffsetToPtr(sel, Map->InfoOffset);
    long long Grow;

    if (Map->Update)
        UpdateVfsFile(HandleMod);

    Grow = Pos + Size - info->DiscSize;

    if (Grow > 0)
        GrowVfsFile(HandleMod, info->DiscSize, Grow);

    LockMap(Map);

    LastIndex = VfsFind(HandleMod, Map, Pos);

    while (Size)
    {
        if (LastIndex >= 0)
        {
            count = VfsWriteOne(Map, LastIndex, ptr, Pos, Size);

            if (count)
            {
                UpdateVfsFile(HandleMod);

                ptr += count;
                Size -= count;
                ret += count;
                Pos += count;
            }
        }

        if (Size)
        {
            LastIndex = VfsFind(HandleMod, Map, Pos);

            for (i = 0; i < 10; i++)
            {
                UnlockMap(Map);

                Grow = Pos + Size - info->DiscSize;

                if (Grow > 0)
                    GrowVfsFile(HandleMod, info->DiscSize, Grow);
                else
                    MapVfsFile(HandleMod, Pos, Size);

                LockMap(Map);
                LastIndex = VfsFind(HandleMod, Map, Pos);
                if (LastIndex >= 0)
                    break;
            }

            if (LastIndex < 0)
                break;
        }
    }

    UnlockMap(Map);

    return ret;
}
