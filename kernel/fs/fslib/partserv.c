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
# partserv.c
# Partition server interface
#
########################################################################*/

void Start();
void Stop();
int Format();
long long GetFreeSectors();
int GetDirHeaderSize();
struct TShareHeader *GetDir(int rel, char *path, int *count);
int GetDirEntryAttrib(int rel, char *path);
int LockRelDir(int rel, char *path);
void CloneRelDir(int rel);
void UnlockRelDir(int rel);
int GetRelDir(int rel, char *path);
void LockDirLink(void *dir, int index);
void UnlockDirLink(void *dir, int index);
int OpenFile(int rel, char *path);
int CreateFile(int rel, char *path, int attrib);
int GetFileAttrib(int handle);
int GetFileHandle(int handle);
void DerefFile(int handle);
void CloseFile(int handle);
int CreateDir(int rel, char *path);

/*##########################################################################
#
#   Name       : LowStart
#
##########################################################################*/
#pragma aux LowStart "*"
void LowStart()
{
    Start();
}

/*##########################################################################
#
#   Name       : LowStop
#
##########################################################################*/
#pragma aux LowStop "*"
void LowStop()
{
    Stop();
}

/*##########################################################################
#
#   Name       : LowFormat
#
##########################################################################*/
#pragma aux LowFormat "*" parm routine value [eax]
int LowFormat()
{
    return Format();
}

/*##########################################################################
#
#   Name       : LowGetFreeSectors
#
##########################################################################*/
#pragma aux LowGetFreeSectors "*" parm routine value [edx eax]
long long LowGetFreeSectors()
{
    return GetFreeSectors();
}

/*##########################################################################
#
#   Name       : LowGetDirHeaderSize
#
##########################################################################*/
#pragma aux LowGetDirHeaderSize "*" parm routine value [eax]
int LowGetDirHeaderSize()
{
    return GetDirHeaderSize();
}

/*##########################################################################
#
#   Name       : LowGetDir
#
##########################################################################*/
#pragma aux LowGetDir "*" parm routine [eax] [edi] [esi] value [edx]
struct TShareHeader *LowGetDir(int rel, char *path, int *count)
{
    return GetDir(rel, path, count);
}

/*##########################################################################
#
#   Name       : LowGetDirEntryAttrib
#
##########################################################################*/
#pragma aux LowGetDirEntryAttrib "*" parm routine [eax] [edi] value [eax]
int LowGetDirEntryAttrib(int rel, char *path)
{
    return GetDirEntryAttrib(rel, path);
}

/*##########################################################################
#
#   Name       : LowLockRelDir
#
##########################################################################*/
#pragma aux LowLockRelDir "*" parm routine [eax] [edi] value [eax]
int LowLockRelDir(int rel, char *path)
{
    return LockRelDir(rel, path);
}

/*##########################################################################
#
#   Name       : LowCloneRelDir
#
##########################################################################*/
#pragma aux LowCloneRelDir "*" parm routine [eax]
void LowCloneRelDir(int rel)
{
    CloneRelDir(rel);
}

/*##########################################################################
#
#   Name       : LowUnlockRelDir
#
##########################################################################*/
#pragma aux LowUnlockRelDir "*" parm routine [eax]
void LowUnlockRelDir(int rel)
{
    UnlockRelDir(rel);
}

/*##########################################################################
#
#   Name       : LowGetRelDir
#
##########################################################################*/
#pragma aux LowGetRelDir "*" parm routine [eax] [edi] value [eax]
int LowGetRelDir(int rel, char *path)
{
    return GetRelDir(rel, path);
}

/*##########################################################################
#
#   Name       : LowLockDirLink
#
##########################################################################*/
#pragma aux LowLockDirLink "*" parm routine [esi] [edx]
void LowLockDirLink(void *dir, int index)
{
    LockDirLink(dir, index);
}

/*##########################################################################
#
#   Name       : LowUnlockDirLink
#
##########################################################################*/
#pragma aux LowUnlockDirLink "*" parm routine [esi] [edx]
void LowUnlockDirLink(void *dir, int index)
{
    UnlockDirLink(dir, index);
}

/*##########################################################################
#
#   Name       : LowOpenFile
#
##########################################################################*/
#pragma aux LowOpenFile "*" parm routine [eax] [edi] value [eax]
int LowOpenFile(int rel, char *path)
{
    return OpenFile(rel, path);
}

/*##########################################################################
#
#   Name       : LowCreateFile
#
##########################################################################*/
#pragma aux LowCreateFile "*" parm routine [eax] [edi] [ecx] value [eax]
int LowCreateFile(int rel, char *path, int attrib)
{
    return CreateFile(rel, path, attrib);
}

/*##########################################################################
#
#   Name       : LowDerefFile
#
##########################################################################*/
#pragma aux LowDerefFile "*" parm routine [ebx]
void LowDerefFile(int handle)
{
    DerefFile(handle);
}

/*##########################################################################
#
#   Name       : LowCloseFile
#
##########################################################################*/
#pragma aux LowCloseFile "*" parm routine [ebx]
void LowCloseFile(int handle)
{
    CloseFile(handle);
}

/*##########################################################################
#
#   Name       : LowGetFileAttrib
#
##########################################################################*/
#pragma aux LowGetFileAttrib "*" parm routine [eax] value [eax]
int LowGetFileAttrib(int handle)
{
    return GetFileAttrib(handle);
}

/*##########################################################################
#
#   Name       : LowGetFileHandle
#
##########################################################################*/
#pragma aux LowGetFileHandle "*" parm routine [eax] value [eax]
int LowGetFileHandle(int handle)
{
    return GetFileHandle(handle);
}

/*##########################################################################
#
#   Name       : LowCreateDir
#
##########################################################################*/
#pragma aux LowCreateDir "*" parm routine [eax] [edi] value [eax]
int LowCreateDir(int rel, char *path)
{
    return CreateDir(rel, path);
}
