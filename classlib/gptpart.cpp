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
# gptpart.cpp
# GPT partition handling classes
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "gptpart.h"
#include "part.h"
#include "rdos.h"

#define FALSE   0
#define TRUE    !FALSE

struct TPartHeader
{
    char Sign[8];
    char Revision[4];
    int HeaderSize;
    unsigned int Crc32;
    int Resv;
    long long CurrLba;
    long long OtherLba;
    long long FirstLba;
    long long LastLba;
    char Guid[16];
    long long EntryLba;
    int EntryCount;
    int EntrySize;
    int EntryCrc32;
};

struct TPartEntry
{
    char PartGuid[16];
    char UniqueGuid[16];
    long long FirstLba;
    long long LastLba;
    long long Attrib;
    short int Name[36];
};

/*##################  UuidToStr  #############
*   Purpose....: Convert UUID to string                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
static void UuidToStr(const char *uuid, char *str)
{
    int ival;
    int *ip;
    short int sval;
    short int *sp;

    ip = (int *)uuid;
    ival = *ip;
    sprintf(str, "%08lX-", ival);

    sp = (short int *)(uuid + 4); 
    sval = *sp;
    sprintf(str+9, "%04hX-", sval);
    
    sp = (short int *)(uuid + 6); 
    sval = *sp;
    sprintf(str+14, "%04hX-", sval);

    sp = (short int *)(uuid + 8); 
    sval = RdosSwapShort(*sp);
    sprintf(str+19, "%04hX-", sval);

    sp = (short int *)(uuid + 10); 
    sval = RdosSwapShort(*sp);
    sprintf(str+24, "%04hX", sval);

    sp = (short int *)(uuid + 12); 
    sval = RdosSwapShort(*sp);
    sprintf(str+28, "%04hX", sval);

    sp = (short int *)(uuid + 14); 
    sval = RdosSwapShort(*sp);
    sprintf(str+32, "%04hX", sval);
}

/*##################  TGptPartition::TDiscPartition  #############
*   Purpose....: Partition constructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TGptPartition::TGptPartition(TDisc *Disc, const char *Guid, long long StartSector, long long EndSector, const short int *Name16)
{
    int i;
    const short int *sptr;
    char *ptr;
    int mspart;
    
    if (StartSector > 0)
    {
        Usable = TRUE;
        Start = StartSector;
        Size = (EndSector - StartSector) + 1;
        FDisc = Disc;
        UuidToStr(Guid, GuidStr);

        sptr = Name16;
        ptr = Name;

        for (i = 0; i < 40; i++)
        {
            *ptr = (char)(*sptr);

            if (*ptr == 0)
                break;
                
            ptr++;
            sptr++;
        }
        *ptr = 0;

        mspart = FALSE;

        if (!strcmp(GuidStr, "E3C9E316-0B5C-4DB8-817D-F92DF00215AE"))
        {
            strcpy(GuidStr, "Microsoft Reserved");
        }

        if (!strcmp(GuidStr, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"))
        {
            strcpy(GuidStr, "Basic Data");
            mspart = TRUE;
        }

        if (!strcmp(GuidStr, "DE94BBA4-06D1-4D40-A16A-BFD50179D6AC"))
            strcpy(GuidStr, "Windows Recovery");

        if (!strcmp(GuidStr, "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"))
        {
            strcpy(GuidStr, "EFI System");
            mspart = TRUE;
        }
        
        if (!strcmp(GuidStr, "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"))
            strcpy(GuidStr, "Linux Swap");

        if (!strcmp(GuidStr, "0FC63DAF-8483-4772-8E79-3D69D8477DE4"))
            strcpy(GuidStr, "Linux Ext");

        if (mspart)
            GetMsFsName();
        else
            strcpy(Name, "UNKNOWN");
        
    }
    else
        Usable = FALSE;
}

/*##################  TGptPartition::GetMsFsName  #############
*   Purpose....: Get partition Microsoft FS name                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptPartition::GetMsFsName()
{
    char Buf[512];
    int i;

    if (Start < FDisc->GetTotalSectors())
    {
        FDisc->Read(Start, Buf, 512);

        switch (Buf[3])
        {
            case 'M':
                memcpy(Name, &Buf[0x52], 8);
                Name[8] = 0;
                break;

            case 'm':
            case 'R':
                memcpy(Name, &Buf[0x36], 8);
                Name[8] = 0;
                break;
                
            default:
                memcpy(Name, &Buf[3], 8);
                Name[8] = 0;
                break;
        }

        for (i = 7; i; i--)
            if (Name[i] == ' ')
                Name[i] = 0;
            else
                break;
    }
}

/*##################  TGptPartition::GetTotalSpace  #############
*   Purpose....: Get total space in MB                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
double TGptPartition::GetTotalSpace()
{
    return (double)Size * (double)512 / (double)0x100000;
}

/*##################  TGptDiscPartition::TGptDiscPartition  #############
*   Purpose....: Disc partition constructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TGptDiscPartition::TGptDiscPartition(TDisc *Disc)
{
    FDisc = Disc;
    PartCount = 0;

    FPartHeader = 0;
    FPartEntry = 0;
}

/*##################  TGptDiscPartition::~TGptDiscPartition  #############
*   Purpose....: Disc partition destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TGptDiscPartition::~TGptDiscPartition()
{
    if (FPartEntry)
        delete FPartEntry;
}

/*##################  TGptDiscPartition::GetDisc  #############
*   Purpose....: Get disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc *TGptDiscPartition::GetDisc()
{
    return FDisc;
}

/*##################  TGptDiscPartition::GetStart  #############
*   Purpose....: Get start of disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TGptDiscPartition::GetStart()
{
    return FPartHeader->FirstLba;
}

/*##################  TGptDiscPartition::GetEnd  #############
*   Purpose....: Get end of disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TGptDiscPartition::GetEnd()
{
    return FPartHeader->LastLba;
}

/*##################  TGptDiscPartition::ReadGpt  #############
*   Purpose....: Read GPT table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
struct TPartEntry *TGptDiscPartition::ReadGpt(long long StartLba, char *HeaderBuf)
{
    struct TPartHeader *PartHeader;
    char *EntryBuf;
    char *ptr;
    unsigned int Crc32;
    unsigned int ThisCrc32;
    int count;
    int size;
    int i;
    int sectors;
    long long Lba;
    struct TPartEntry *EntryData;

    Lba = StartLba;
    FDisc->Read(Lba, HeaderBuf, 512);

    PartHeader = (struct TPartHeader *)HeaderBuf;

    if (!strcmp(PartHeader->Sign, "EFI PART"))
    {
        Crc32 = PartHeader->Crc32;
        PartHeader->Crc32 = 0;
        ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, HeaderBuf, PartHeader->HeaderSize);

        if (Crc32 == ThisCrc32)
        {
            if (PartHeader->EntrySize == sizeof(struct TPartEntry))
            {
                count = PartHeader->EntryCount;                
                sectors = count * sizeof(struct TPartEntry) / 512;
                size = sectors * 512;
                EntryBuf = new char[size];
                ptr = EntryBuf;
                EntryData = (struct TPartEntry *)EntryBuf;

                for (i = 0; i < sectors; i++)
                {
                    Lba = i + PartHeader->EntryLba;
                    FDisc->Read(Lba, ptr, 512);
                    ptr += 512;
                }
                                
                Crc32 = RdosCalcCrc32(0xFFFFFFFF, EntryBuf, size);
                if (PartHeader->EntryCrc32 == Crc32)
                    return EntryData;
                
                delete EntryBuf;
            }
        }        
    }

    return 0;
}

/*##################  TGptDiscPartition::ReadOtherGpt  #############
*   Purpose....: Read other GPT table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::ReadOtherGpt()
{
    struct TPartHeader *PartHeader;
    unsigned int Crc32;
    unsigned int ThisCrc32;
    int Valid = FALSE;
    long long Lba = FPartHeader->OtherLba;

    if (Lba >= FDisc->GetTotalSectors())
    {
        Lba = FDisc->GetTotalSectors() - 1;
        FPartHeader->OtherLba = Lba;
    }        

    FDisc->Read(Lba, FSecondaryHeader, 512);

    PartHeader = (struct TPartHeader *)FSecondaryHeader;

    if (!strcmp(PartHeader->Sign, "EFI PART"))
    {
        Crc32 = PartHeader->Crc32;
        PartHeader->Crc32 = 0;
        ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, FSecondaryHeader, PartHeader->HeaderSize);

        if (Crc32 == ThisCrc32)
            Valid = TRUE;
    }

    if (!Valid)
    {
        strcpy(PartHeader->Sign, "EFI PART");
        PartHeader->Revision[0] = 0;
        PartHeader->Revision[1] = 0;
        PartHeader->Revision[2] = 1;
        PartHeader->Revision[3] = 0;

        PartHeader->HeaderSize = sizeof(struct TPartHeader);
        PartHeader->Crc32 = 0;    
        PartHeader->Resv = 0;

        PartHeader->CurrLba = Lba;
        PartHeader->OtherLba = 1;

        PartHeader->FirstLba = FPartHeader->FirstLba;
        PartHeader->LastLba = FPartHeader->LastLba;
        RdosCreateUuid(PartHeader->Guid);
        PartHeader->EntryLba = Lba - 32;    
        PartHeader->EntrySize = FPartHeader->EntrySize;
        PartHeader->EntryCount = FPartHeader->EntryCount;
        PartHeader->EntryCrc32 = FPartHeader->EntryCrc32;
    }
}

/*##################  TGptDiscPartition::RecreatePrimaryGpt  #############
*   Purpose....: Recreate primary GPT header
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::RecreatePrimaryGpt()
{
    struct TPartHeader *PartHeader = (struct TPartHeader *)FPrimaryHeader;

    strcpy(PartHeader->Sign, "EFI PART");
    PartHeader->Revision[0] = 0;
    PartHeader->Revision[1] = 0;
    PartHeader->Revision[2] = 1;
    PartHeader->Revision[3] = 0;

    PartHeader->HeaderSize = sizeof(struct TPartHeader);
    PartHeader->Crc32 = 0;    
    PartHeader->Resv = 0;

    PartHeader->CurrLba = 1;
    PartHeader->OtherLba = FPartHeader->CurrLba;

    PartHeader->FirstLba = FPartHeader->FirstLba;
    PartHeader->LastLba = FPartHeader->LastLba;
    RdosCreateUuid(PartHeader->Guid);
    PartHeader->EntryLba = 2;    
    PartHeader->EntrySize = FPartHeader->EntrySize;
    PartHeader->EntryCount = FPartHeader->EntryCount;
    PartHeader->EntryCrc32 = FPartHeader->EntryCrc32;
}

/*##################  TGptDiscPartition::Read  #############
*   Purpose....: Read partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::Read()
{
    TGptPartition *part;
    long long Lba;
    int i;
    struct TPartEntry *EntryData;

    PartCount = 0;

    Lba = 1;
    FPartEntry = ReadGpt(Lba, FPrimaryHeader);

    if (FPartEntry)
    {
        FPartHeader = (struct TPartHeader *)FPrimaryHeader;
        ReadOtherGpt();
    }    
    else
    {
        Lba = FDisc->GetTotalSectors() - 1;
        FPartEntry = ReadGpt(Lba, FSecondaryHeader);

        if (FPartEntry)
        {
            FPartHeader = (struct TPartHeader *)FSecondaryHeader;
            RecreatePrimaryGpt();
        }
    }

    if (FPartEntry)
    {
        Sort();

        EntryData = FPartEntry;

        for (i = 0; i < FPartHeader->EntryCount; i++)
        {
            part = new TGptPartition(   FDisc, 
                                        EntryData->PartGuid,
                                        EntryData->FirstLba,
                                        EntryData->LastLba,
                                        EntryData->Name);

            if (part->Usable)
            {
                PartArr[PartCount] = part;
                PartCount++;
            }
            else
                delete part;                        

            EntryData++;                      
        }  
    }
}

/*##################  TGptDiscPartition::WriteGpt  #############
*   Purpose....: Write GPT table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::WriteGpt(char *HeaderBuf)
{
    struct TPartHeader *PartHeader;
    char *EntryBuf = (char *)FPartEntry;
    char *ptr;
    int count;
    int size;
    int i;
    int sectors;
    long long Lba;

    PartHeader = (struct TPartHeader *)HeaderBuf;

    PartHeader->Crc32 = 0;    

    count = PartHeader->EntryCount;                
    sectors = count * sizeof(struct TPartEntry) / 512;
    size = sectors * 512;
    
    PartHeader->EntryCrc32 = RdosCalcCrc32(0xFFFFFFFF, EntryBuf, size);
    PartHeader->Crc32 = RdosCalcCrc32(0xFFFFFFFF, HeaderBuf, PartHeader->HeaderSize);
    
    Lba = PartHeader->CurrLba;
    FDisc->Write(Lba, HeaderBuf, 512);

    ptr = EntryBuf;

    for (i = 0; i < sectors; i++)
    {
        Lba = i + PartHeader->EntryLba;
        FDisc->Write(Lba, ptr, 512);
        ptr += 512;
    }
}

/*##################  TGptDiscPartition::InitGpt  #############
*   Purpose....: Init GPT
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::InitGpt(long long HeaderLba, char *HeaderBuf, int Resv)
{
    struct TPartHeader *PartHeader;

    PartHeader = (struct TPartHeader *)HeaderBuf;

    PartHeader->EntryCount = 128;

    strcpy(PartHeader->Sign, "EFI PART");
    PartHeader->Revision[0] = 0;
    PartHeader->Revision[1] = 0;
    PartHeader->Revision[2] = 1;
    PartHeader->Revision[3] = 0;

    PartHeader->HeaderSize = sizeof(struct TPartHeader);
    PartHeader->Crc32 = 0;    
    PartHeader->Resv = 0;

    PartHeader->CurrLba = HeaderLba;

    if (HeaderLba == 1)
        PartHeader->OtherLba = FDisc->GetTotalSectors() - 1;
    else
        PartHeader->OtherLba = 1;

    PartHeader->FirstLba = 34 + Resv;
    PartHeader->LastLba = FDisc->GetTotalSectors() - 34;
    RdosCreateUuid(PartHeader->Guid);

    if (HeaderLba == 1)
        PartHeader->EntryLba = 2;
    else
        PartHeader->EntryLba = FDisc->GetTotalSectors() - 33;
    
    PartHeader->EntrySize = 128;
};

/*##################  TGptDiscPartition::Write  #############
*   Purpose....: Write partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::Write(int resv)
{
    int count;
    int size;
    int sectors;
    char *EntryBuf;

    if (!FPartEntry)
    {
        InitGpt(1, FPrimaryHeader, resv);
        InitGpt(FDisc->GetTotalSectors() - 1, FSecondaryHeader, resv);

        FPartHeader = (struct TPartHeader *)FPrimaryHeader;
                
        count = FPartHeader->EntryCount;                
        sectors = count * sizeof(struct TPartEntry) / 512;
        size = sectors * 512;

        EntryBuf = new char[size];
        memset(EntryBuf, 0, size);

        FPartEntry = (struct TPartEntry *)EntryBuf;

    }

    WriteGpt(FPrimaryHeader);
    WriteGpt(FSecondaryHeader);
}

/*##################  TGptDiscPartition::Write  #############
*   Purpose....: Write partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::Write()
{
    Write(0);
}

/*##################  TGptDiscPartition::WriteBootSector  #############
*   Purpose....: Write boot sector                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::WriteBootSector(long long Sector, int Count, const char *BootCode, int BootSize)
{
    char *BootSector;
    TBootParam bootp;

    bootp.BytesPerSector = FDisc->GetBytesPerSector();
    bootp.Resv1 = 0;
    bootp.MappingSectors = 0;
    bootp.Resv3 = 0;
    bootp.Resv4 = 0;
    bootp.SmallSectors = 0;
    bootp.Media = 0xF8;
    bootp.Resv6 = 0;
    bootp.SectorsPerCyl = FDisc->GetSectorsPerCyl();
    bootp.Heads = FDisc->GetHeads();
    bootp.HiddenSectors = 0;
    bootp.Sectors = Count - 1;
    bootp.Drive = 0x80 + FDisc->GetDiscNr();
    bootp.Resv7 = 0;
    bootp.Signature = 0;
    bootp.Serial = 0;
    memset(bootp.Volume, 0, 11);
    memcpy(bootp.Fs, "RDOS    ", 8);

    BootSector = new char[512];

    FDisc->Read(Sector, BootSector, 512);

    memset(BootSector, 0, 0x1FE);
    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    memcpy(BootSector, BootCode, BootSize);
    memcpy(BootSector + 11, &bootp, sizeof(bootp));

    FDisc->Write(Sector, BootSector, 512);

    delete BootSector;
}

/*##################  TGptDiscPartition::Sort  #############
*   Purpose....: Sort partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::Sort()
{
    int i;
    int Exchange;
    int Changed;
    struct TPartEntry *PrevEntry;
    struct TPartEntry *CurrEntry;
    struct TPartEntry Temp;

    Changed = TRUE;

    while (Changed)
    {
        Changed = FALSE;

        PrevEntry = FPartEntry;

        if (PrevEntry)
        {            
            CurrEntry = PrevEntry;
            CurrEntry++;
        
            for (i = 1; i < FPartHeader->EntryCount; i++)
            {
                Exchange = FALSE;
                
                if (CurrEntry->FirstLba)
                {
                    if (PrevEntry->FirstLba == 0)
                        Exchange = TRUE;
                    else
                    {
                        if (CurrEntry->FirstLba < PrevEntry->FirstLba)
                            Exchange = TRUE;
                    }
                }

                if (Exchange)
                {
                    Temp = *CurrEntry;
                    *CurrEntry = *PrevEntry;
                    *PrevEntry = Temp;
                    Changed = TRUE;
                }

                CurrEntry++;
                PrevEntry++;
            }
        }
    }
}

/*##################  TGptDiscPartition::GetGuid  #############
*   Purpose....: Get GUID
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TGptDiscPartition::GetGuid(const char *FsName)
{
    static char EfiGuid[] =  {0x28, 0x73, 0x2A, 0xC1, 0x1F, 0xF8, 0xD2, 0x11, 0xBA, 0x4B, 0x00, 0xA0, 0xC9, 0x3E, 0xC9, 0x3B};
    static char DataGuid[] = {0xA2, 0xA0, 0xD0, 0xEB, 0xE5, 0xB9, 0x33, 0x44, 0x87, 0xC0, 0x68, 0xB6, 0xB7, 0x26, 0x99, 0xC7};
    static char Ext4Guid[] = {0xAF, 0x3D, 0xC6, 0x0F, 0x83, 0x84, 0x72, 0x47, 0x8E, 0x79, 0x3D, 0x69, 0xD8, 0x47, 0x7D, 0xE4};    

    if (!strcmp(FsName, "EFI"))
        return EfiGuid;
    else if (!strcmp(FsName, "EXT4"))
        return Ext4Guid;
    else
        return DataGuid;
}

/*##################  TGptDiscPartition::GetEntry  #############
*   Purpose....: Get entry to insert new partition into
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TGptDiscPartition::GetFreeLba(long long Size)
{
    int i;
    long long Lba = FPartHeader->FirstLba;
    struct TPartEntry *CurrEntry;

    CurrEntry = FPartEntry;
        
    for (i = 0; i < FPartHeader->EntryCount; i++)
    {
        if (CurrEntry->FirstLba)
        {
            if (CurrEntry->FirstLba - Lba >= Size)
                return Lba;

            Lba = CurrEntry->LastLba + 1;
        }
        else
        {
            if (FPartHeader->LastLba - Lba > Size)
                return Lba;
            else
                return 0;
        }
        
        CurrEntry++;
    }
    return 0;
}

/*##################  TGptDiscPartition::InsertEntry  #############
*   Purpose....: Insert entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
struct TPartEntry *TGptDiscPartition::InsertEntry(long long Lba)
{
    int pos = 0;
    int i;
    struct TPartEntry *CurrEntry;

    CurrEntry = FPartEntry;

    if (Lba != FPartHeader->FirstLba)
    {
        for (pos = 0; pos < FPartHeader->EntryCount; pos++)
        {
            if (CurrEntry->FirstLba)             
            {
                if (Lba < CurrEntry->FirstLba)
                    break;
            }
            else
                break;
            CurrEntry++;
        }
    }

    for (i = FPartHeader->EntryCount - 1; i > pos; i--)
        FPartEntry[i] = FPartEntry[i - 1];

    return CurrEntry;
}

/*##################  TGptDiscPartition::Add  #############
*   Purpose....: Add partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TGptDiscPartition::Add(const char *FsName, long Size, const char *BootCode, int BootSize)
{
    long long Lba;
    const char *Guid;
    struct TPartEntry *Entry;
    long ReqSize = Size + 1;

    Guid = GetGuid(FsName);

    if (Guid)
    {
        Lba = GetFreeLba(ReqSize);
        if (Lba)
        {
            Entry = InsertEntry(Lba);

            memcpy(Entry->PartGuid, Guid, 16);
            RdosCreateUuid(Entry->UniqueGuid);
            Entry->FirstLba = Lba;
            Entry->LastLba = Lba + ReqSize - 1;
            Entry->Attrib = 0;
            memset(Entry->Name, 0, 2 * 36);

            if (!strcmp(FsName, "EXT4"))
                return TRUE;
            else
            {
                WriteBootSector(Lba, ReqSize, BootCode, BootSize);

                if (!strcmp(FsName, "EFI"))
                    return RdosFormatDrive(FDisc->GetDiscNr(), (int)Lba, ReqSize, "FAT32");
                else
                    return RdosFormatDrive(FDisc->GetDiscNr(), (int)Lba, ReqSize, FsName);
            }
        }
    }
    return FALSE;
}

/*##################  TGptDiscPartition::Remove  #############
*   Purpose....: Remove entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TGptDiscPartition::Remove(long long Lba)
{
    int pos = 0;
    int i;
    struct TPartEntry *CurrEntry;

    CurrEntry = FPartEntry;

    for (pos = 0; pos < FPartHeader->EntryCount; pos++)
    {
        if (CurrEntry->FirstLba)             
        {
            if (Lba == CurrEntry->FirstLba)
            {
                for (i = pos + 1; i < FPartHeader->EntryCount; i++)
                    FPartEntry[i - 1] = FPartEntry[i];

                memset(&FPartEntry[FPartHeader->EntryCount - 1], 0, sizeof(struct TPartEntry));
                return TRUE;
            }
        }
        else
            break;

        CurrEntry++;
    }
    return FALSE;
}
