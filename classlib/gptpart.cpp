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
# gptpart.cpp
# GPT partition handling classes
#
########################################################################*/

#ifdef __GNUC__
#include <string.h>
#else
#include <mem.h>
#endif
#include <stdio.h>

#include "gptpart.h"
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

static int crc32_tab[] =
{
        0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
        0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
        0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
        0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
        0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
        0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
        0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b, 0x35b5a8fa, 0x42b2986c,
        0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
        0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
        0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
        0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190, 0x01db7106,
        0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
        0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d,
        0x91646c97, 0xe6635c01, 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
        0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
        0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
        0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7,
        0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
        0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa,
        0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
        0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
        0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
        0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683, 0xe3630b12, 0x94643b84,
        0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
        0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
        0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
        0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
        0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
        0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55,
        0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
        0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28,
        0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
        0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
        0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
        0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
        0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
        0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69,
        0x616bffd3, 0x166ccf45, 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
        0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
        0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
        0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693,
        0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
        0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
};

/*##################  CalcCrc32  #############
*   Purpose....: Calc CRC32                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
static unsigned int CalcCrc32(const char *buf, int size)
{
    const unsigned char *p;
    unsigned int crc;

    p = (const unsigned char *)buf;
    crc = ~0;

    while (size--)
    {
        crc = crc32_tab[(crc ^ *p) & 0xFF] ^ (crc >> 8);
        p++;
    }

    return crc ^ ~0;
}


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

    FPrimaryEntry = 0;
    FSecondaryEntry = 0;

    Read();
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
    if (FPrimaryEntry)
        delete FPrimaryEntry;
        
    if (FSecondaryEntry)
        delete FSecondaryEntry;
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
        ThisCrc32 = CalcCrc32(HeaderBuf, PartHeader->HeaderSize);

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
                                
                Crc32 = CalcCrc32(EntryBuf, size);
                if (PartHeader->EntryCrc32 == Crc32)
                    return EntryData;
                
                delete EntryBuf;
            }
        }        
    }

    return 0;
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
    struct TPartHeader *PartHeader;
    TGptPartition *part;
    long long Lba;
    int i;
    struct TPartEntry *EntryData;

    PartCount = 0;

    Lba = 1;
    FPrimaryEntry = ReadGpt(Lba, FPrimaryHeader);
    
    Lba = FDisc->GetTotalSectors() - 1;
    FSecondaryEntry = ReadGpt(Lba, FSecondaryHeader);

    PartHeader = (struct TPartHeader *)FPrimaryHeader;

    if (!PartHeader)
        PartHeader = (struct TPartHeader *)FPrimaryHeader;

    if (PartHeader)
    {
        EntryData = FPrimaryEntry;

        for (i = 0; i < PartHeader->EntryCount; i++)
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
void TGptDiscPartition::WriteGpt(char *HeaderBuf, struct TPartEntry *Entry)
{
    struct TPartHeader *PartHeader;
    char *EntryBuf = (char *)Entry;
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
    
    PartHeader->EntryCrc32 = CalcCrc32(EntryBuf, size);
    PartHeader->Crc32 = CalcCrc32(HeaderBuf, PartHeader->HeaderSize);
    
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
struct TPartEntry *TGptDiscPartition::InitGpt(long long HeaderLba, char *HeaderBuf)
{
    int count;
    int size;
    int sectors;
    struct TPartHeader *PartHeader;
    char *EntryBuf;

    count = PartHeader->EntryCount;                
    sectors = count * sizeof(struct TPartEntry) / 512;
    size = sectors * 512;

    EntryBuf = new char[size];
    memset(EntryBuf, 0, size);

    PartHeader = (struct TPartHeader *)HeaderBuf;

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

    PartHeader->FirstLba = 34;
    PartHeader->LastLba = FDisc->GetTotalSectors() - 34;
    RdosCreateUuid(PartHeader->Guid);

    if (HeaderLba == 1)
        PartHeader->EntryLba = 2;
    else
        PartHeader->EntryLba = FDisc->GetTotalSectors() - 33;
    
    PartHeader->EntryCount = 128;
    PartHeader->EntrySize = 128;

    return (struct TPartEntry *)EntryBuf;
};

/*##################  TGptDiscPartition::Write  #############
*   Purpose....: Write partition table
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptDiscPartition::Write()
{
    if (FPrimaryEntry)
    {
        WriteGpt(FPrimaryHeader, FPrimaryEntry);
        WriteGpt(FSecondaryHeader, FPrimaryEntry);
    }
    else
    {
        if (FSecondaryEntry)
        {
            WriteGpt(FPrimaryHeader, FSecondaryEntry);
            WriteGpt(FSecondaryHeader, FSecondaryEntry);
        }
    }
}
