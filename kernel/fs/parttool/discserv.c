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
# discserv.c
# Disc server interface
#
########################################################################*/

void RunCmd(int handle, char *msg);
int ReadSector(long long sector, char *buf, int size);
int WriteSector(long long sector, char *buf, int size);

/*##########################################################################
#
#   Name       : LowCmd
#
##########################################################################*/
#pragma aux LowCmd "*" parm routine [ebx] [edi] value [eax]
void LowCmd(int handle, char *msg)
{
    RunCmd(handle, msg);
}

/*##########################################################################
#
#   Name       : LowReadSector
#
##########################################################################*/
#pragma aux LowReadSector "*" parm routine [edx eax] [ebx] [ecx] value [eax]
int LowReadSector(long long sector, char *buf, int size)
{
    return ReadSector(sector, buf, size);
}

/*##########################################################################
#
#   Name       : LowWriteSector
#
##########################################################################*/
#pragma aux LowWriteSector "*" parm routine [edx eax] [ebx] [ecx] value [eax]
int LowWriteSector(long long sector, char *buf, int size)
{
    return WriteSector(sector, buf, size);
}
