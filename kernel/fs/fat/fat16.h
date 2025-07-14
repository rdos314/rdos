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
# fat16.h
# Fat16 class
#
########################################################################*/

#ifndef _FAT16_H
#define _FAT16_H

#include "fatfs.h"
#include "tab16.h"
#include "dir.h"

class TFat16 : public TFat
{
public:
    TFat16(TPartServer *server, struct TBootSector12_16 *boot, bool format);
    ~TFat16();

    static bool InitFs(TPartServer *Server, struct TBootSector12_16 *boot);

    virtual TDir *CacheRootDir();

protected:
    static unsigned int Adjust(TPartServer *Server);
    static unsigned int CalcClusterSize(unsigned int TotalSectors);
    static unsigned short int CalcClusterCount(unsigned int TotalSectors, unsigned int ClusterSize);
    static unsigned short int CalcFatSectors(unsigned int Clusters);

    void WriteBootSector(struct TBootSector12_16 *BootSector);

    int RootDirEntries;
    long long RootSector;

private:
    TPartServer *FServer;

    TFatTable16 Tab1;
    TFatTable16 Tab2;
};

#endif

