/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# serv.c
# server interface
#
########################################################################*/

long long GetFreeSectors();
int GetDirHeaderSize();
int GetDir(int rel, char *path, int *count);
int GetDirEntryAttrib(int rel, char *path);
int LockRelDir(int rel, char *path);
void CloneRelDir(int rel);
void UnlockRelDir(int rel);
int GetRelDir(int rel, char *path);
void ReadDirLink(void *dir, int index);
int OpenFile(int rel, char *path);
int GetFileAttrib(int handle);
int GetFileHandle(int handle);
int ReqFile(int handle, long long pos, int size, int src);
void UpdateFile(int handle);
void CloseFile(int handle);

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
struct TShareHeader *LowGetDirEntryAttrib(int rel, char *path)
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
#   Name       : LowReadDirLink
#
##########################################################################*/
#pragma aux LowReadDirLink "*" parm routine [esi] [edx]
void LowReadDirLink(void *dir, int index)
{
    ReadDirLink(dir, index);
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
#   Name       : LowReqFile
#
##########################################################################*/
#pragma aux LowReqFile "*" parm routine [ebx] [edx eax] [ecx] [esi] value [eax]
int LowReqFile(int handle, long long pos, int size, int src)
{
    return ReqFile(handle, pos, size, src);
}

/*##########################################################################
#
#   Name       : LowUpdateFile
#
##########################################################################*/
#pragma aux LowUpdateFile "*" parm routine [ebx]
void LowUpdateFile(int handle)
{
    UpdateFile(handle);
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
