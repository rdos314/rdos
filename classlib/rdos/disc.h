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
# disc.h
# Direct disc access classes
#
########################################################################*/

#ifndef _DISC_H
#define _DISC_H

#include "str.h"

class TDisc
{
public:
    TDisc(int Disc);
    ~TDisc();

    int IsValid();
    int IsGpt();
    int GetDiscNr();
    int GetBytesPerSector();
    long long GetTotalSectors();
    int GetSectorsPerCyl();
    int GetHeads();
    long long GetCached();
    long long GetLocked();

    int Read(long long Sector, char *buf, int size);
    int Write(long long Sector, const char *buf, int size);
    int GetDrive(long long Start, long long Size);
    void Reset();

    void WaitForIdle();

    long ChsToLba(const char *Data);
    void LbaToChs(long Sector, char *Data);

protected:
    TDisc();
    void Define(int Disc);

    int FDisc;
    int FBytesPerSector;
    long long FSectors;
    int FSectorsPerCyl;
    int FHeads;
    int FValid;
};

#endif

