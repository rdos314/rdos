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
# fatpart.cpp
# FAT partition class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "fatpart.h"

#define FALSE   0
#define TRUE    !FALSE

/*##################  TIdeFatPartition::TIdeFatPartition  #############
*   Purpose....: Partition IDE FAT constructor                                                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFatPartition::TIdeFatPartition(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size)
 : TIdeFsPartition(Disc, Type, Parent, Entry, Start, Size)
{
}

/*##################  TIdeFatPartition::~TIdeFatPartition  #############
*   Purpose....: Partition IDE FAT destructor                                                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFatPartition::~TIdeFatPartition()
{
}

/*##################  TIdeFat12Partition::WriteBootSector  #############
*   Purpose....: Write boot sector                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TIdeFatPartition::WriteBootSector(const char *BootCode, int BootSize)
{
    char *BootSector;
    TBootParam bootp;
    TDisc *Disc = GetDisc();

    bootp.BytesPerSector = Disc->GetBytesPerSector();
    bootp.Resv1 = 0;
    bootp.MappingSectors = 0;
    bootp.Resv3 = 0;
    bootp.Resv4 = 0;
    bootp.SmallSectors = 0;
    bootp.Media = 0xF8;
    bootp.Resv6 = 0;
    bootp.SectorsPerCyl = Disc->GetSectorsPerCyl();
    bootp.Heads = Disc->GetHeads();
    bootp.HiddenSectors = 0;
    bootp.Sectors = Size - 1;
    bootp.Drive = 0x80 + Disc->GetDiscNr();
    bootp.Resv7 = 0;
    bootp.Signature = 0;
    bootp.Serial = 0;
    memset(bootp.Volume, 0, 11);
    memcpy(bootp.Fs, "RDOS    ", 8);

    BootSector = new char[512];

    Read(0, BootSector, 512);

    memset(BootSector, 0, 0x1FE);
    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    memcpy(BootSector, BootCode, BootSize);
    memcpy(BootSector + 11, &bootp, sizeof(bootp));

    Write(0, BootSector, 512);

    delete BootSector;
}

/*##################  TIdeFat12Partition::TFat12Partition  #############
*   Purpose....: Partition IDE FAT12 constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat12Partition::TIdeFat12Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size)
 : TIdeFatPartition(Disc, 1, Parent, Entry, Start, Size)
{
}

/*##################  TIdeFat12Partition::~TFat12Partition  #############
*   Purpose....: Partition IDE FAT12 destructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat12Partition::~TIdeFat12Partition()
{
}

/*##################  TIdeFat12Partition::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TIdeFat12Partition::GetPartName()
{
        return "FAT12";
}

/*##################  TIdeFat12Partition::Format  #############
*   Purpose....: Format IDE FAT12 partition                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdeFat12Partition::Format(const char *BootCode, int BootSize)
{
    WriteBootSector(BootCode, BootSize);
    return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "FAT12");
}

/*##################  TIdeFat16Partition::TIdeFat16Partition  #############
*   Purpose....: Partition IDE FAT16 constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat16Partition::TIdeFat16Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size)
 : TIdeFatPartition(Disc, 6, Parent, Entry, Start, Size)
{
}

/*##################  TIdeFat16Partition::~TIdeFat16Partition  #############
*   Purpose....: Partition IDE FAT16 destructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat16Partition::~TIdeFat16Partition()
{
}

/*##################  TIdeFat16Partition::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TIdeFat16Partition::GetPartName()
{
    return "FAT16";
}

/*##################  TIdeFat16Partition::Format  #############
*   Purpose....: Format IDE FAT16 partition                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdeFat16Partition::Format(const char *BootCode, int BootSize)
{
    WriteBootSector(BootCode, BootSize);
    return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "FAT16");
}

/*##################  TIdeFat32Partition::TIdeFat32Partition  #############
*   Purpose....: Partition IDE FAT32 constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat32Partition::TIdeFat32Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size)
 : TIdeFatPartition(Disc, 11, Parent, Entry, Start, Size)
{
}

/*##################  TIdeFat32Partition::~TIdeFat32Partition  #############
*   Purpose....: Partition IDE FAT32 destructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat32Partition::~TIdeFat32Partition()
{
}

/*##################  TIdeFat32Partition::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TIdeFat32Partition::GetPartName()
{
    return "FAT32";
}

/*##################  TIdeFat32Partition::Format  #############
*   Purpose....: Format IDE FAT32 partition                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TIdeFat32Partition::Format(const char *BootCode, int BootSize)
{
    WriteBootSector(BootCode, BootSize);
    return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "FAT32");
}

/*##################  TIdeFat12PartitionFactory::TIdeFat12PartitionFactory  #############
*   Purpose....: IDE FAT12 partition factory constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat12PartitionFactory::TIdeFat12PartitionFactory()
  : TIdeFsPartitionFactory(1, "FAT12")
{
}

/*##################  TIdeFat12PartitionFactory::~TIdeFat12PartitionFactory  #############
*   Purpose....: IDE FAT12 partition factory destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat12PartitionFactory::~TIdeFat12PartitionFactory()
{
}

/*##################  TIdeFat12PartitionFactory::Open  #############
*   Purpose....: Open IDE FAT12 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFat12PartitionFactory::Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size)
{
    return new TIdeFat12Partition(Disc, Parent, Entry, Start, Size);
}

/*##################  TIdeFat12PartitionFactory::Create  #############
*   Purpose....: Create IDE FAT12 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFat12PartitionFactory::Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize)
{
    TIdeFat12Partition *FatPart;

    FatPart = new TIdeFat12Partition(Disc, Parent, Entry, Start, Size);
    if (FatPart->Format(BootCode, BootSize))
        return FatPart;
    else
    {
        delete FatPart;
        return 0;
    }
}

/*##################  TIdeFat16PartitionFactory::TIdeFat16PartitionFactory  #############
*   Purpose....: IDE FAT16 partition factory constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat16PartitionFactory::TIdeFat16PartitionFactory()
  : TIdeFsPartitionFactory(6, "FAT16")
{
}

/*##################  TIdeFat16PartitionFactory::~TIdeFat16PartitionFactory  #############
*   Purpose....: IDE FAT16 partition factory destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat16PartitionFactory::~TIdeFat16PartitionFactory()
{
}

/*##################  TIdeFat16PartitionFactory::Open  #############
*   Purpose....: Open IDE FAT16 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFat16PartitionFactory::Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size)
{
    return new TIdeFat16Partition(Disc, Parent, Entry, Start, Size);
}

/*##################  TIdeFat16PartitionFactory::Create  #############
*   Purpose....: Create IDE FAT16 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFat16PartitionFactory::Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize)
{
    TIdeFat16Partition *FatPart;

    FatPart = new TIdeFat16Partition(Disc, Parent, Entry, Start, Size);
    if (FatPart->Format(BootCode, BootSize))
        return FatPart;
    else
    {
        delete FatPart;
        return 0;
    }
}

/*##################  TIdeFat32PartitionFactory::TIdeFat32PartitionFactory  #############
*   Purpose....: IDE FAT32 partition factory constructor                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat32PartitionFactory::TIdeFat32PartitionFactory()
  : TIdeFsPartitionFactory(11, "FAT32")
{
}

/*##################  TIdeFat32PartitionFactory::~TIdeFat32PartitionFactory  #############
*   Purpose....: IDE FAT32 partition factory destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFat32PartitionFactory::~TIdeFat32PartitionFactory()
{
}

/*##################  TIdeFat32PartitionFactory::Open  #############
*   Purpose....: Open IDE FAT32 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFat32PartitionFactory::Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size)
{
    return new TIdeFat32Partition(Disc, Parent, Entry, Start, Size);
}

/*##################  TIdeFat32PartitionFactory::Create  #############
*   Purpose....: Create IDE FAT32 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TIdeFsPartition *TIdeFat32PartitionFactory::Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize)
{
    TIdeFat32Partition *FatPart;

    FatPart = new TIdeFat32Partition(Disc, Parent, Entry, Start, Size);
    if (FatPart->Format(BootCode, BootSize))
        return FatPart;
    else
    {
        delete FatPart;
        return 0;
    }
}
