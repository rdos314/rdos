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
# kfile.cpp
# Memmap support for kernel files
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
    unsigned short int Resv1;
    char Update;
    int Count;
    struct RdosFileInfo *Info;
    unsigned short int Resv2;
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

extern void MapKernelFile(int handle, long long pos, int size);
#pragma aux MapKernelFile parm routine [__esi] [__edx __eax] [__ecx]

extern void UpdateKernelFile(int handle);
#pragma aux UpdateKernelFile parm routine [__esi]

extern void GrowKernelFile(int handle, long long csize, int incr);
#pragma aux GrowKernelFile parm routine [__esi] [__edx __eax] [__ecx]

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
static int VfsFind(int Handle, struct RdosFileMap *Map, long long Pos)
{
    int Step = 0x80;
    int Curr = 0;
    unsigned char index;
    long long Diff;

    for (;;)
    {
        if (Map->Update)
            UpdateKernelFile(Handle);

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

        if (entry->Linear && diff >= 0)
        {
            count = entry->Size - diff;

            if (count > 0)
            {
                src = LinearToPtr(entry->Linear);
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
    struct RdosFileInfo *info = Map->Info;
    struct RdosFileMapEntry *entry;
    long long FileSize;

    index = Map->SortedArr[index];

    if (index >= 0)
    {
        entry = &Map->MapArr[index];
        diff = pos - entry->Pos;

        if (entry->Linear && diff >= 0)
        {
            count = entry->Size - diff;

            if (count > 0)
            {
                dst = LinearToPtr(entry->Linear);
                dst += diff;
                if (count > size)
                    count = size;

                memcpy(dst, buf, count);

                FileSize = pos + count;

                if (info->CurrSize < FileSize)
                    info->CurrSize = FileSize;
            }
            else
                count = 0;
        }
    }

    return count;
}

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
int KernelRead(int Handle, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex;
    struct RdosFileInfo *info = Map->Info;
    long long TotalSize = info->CurrSize;

    if (Map->Update)
        UpdateKernelFile(Handle);

    if (Pos + Size > TotalSize)
        Size = TotalSize - Pos;

    if (Size < 0)
        Size = 0;

    LastIndex = VfsFind(Handle, Map, Pos);

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
                MapKernelFile(Handle, Pos, Size);

                LastIndex = VfsFind(Handle, Map, Pos);
                if (LastIndex >= 0)
                    break;
            }

            if (LastIndex < 0)
                break;
        }
    }

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
#pragma aux KernelWrite "*" parm routine [ebx] [fs esi] [edx eax] [es edi] [ecx] value [ecx]
int KernelWrite(int Handle, struct RdosFileMap *Map, long long Pos, void *Buf, int Size)
{
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    int LastIndex = 0;
    struct RdosFileInfo *info = Map->Info;
    long long Grow;

    if (Map->Update)
        UpdateKernelFile(Handle);

    Grow = Pos + Size - info->DiscSize;

    if (Grow > 0)
        GrowKernelFile(Handle, info->DiscSize, Grow);

    LastIndex = VfsFind(Handle, Map, Pos);

    while (Size)
    {
        if (LastIndex >= 0)
        {
            count = VfsWriteOne(Map, LastIndex, ptr, Pos, Size);

            if (count)
            {
                UpdateKernelFile(Handle);

                ptr += count;
                Size -= count;
                ret += count;
                Pos += count;
            }
        }

        if (Size)
        {
            LastIndex = VfsFind(Handle, Map, Pos);

            for (i = 0; i < 10; i++)
            {
                Grow = Pos + Size - info->DiscSize;

                if (Grow > 0)
                    GrowKernelFile(Handle, info->DiscSize, Grow);
                else
                    MapKernelFile(Handle, Pos, Size);

                LastIndex = VfsFind(Handle, Map, Pos);
                if (LastIndex >= 0)
                    break;
            }

            if (LastIndex < 0)
                break;
        }
    }

    return ret;
}
