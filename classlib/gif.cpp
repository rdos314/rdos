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
# gif.cpp
# GIF interface
#
########################################################################*/

#include "rdos.h"

#include "gif.h"
#include "file.h"
#include <malloc.h>
#include <string.h>

#define FALSE   0
#define TRUE    !FALSE

#define LZ_MAX_CODE     4095            /* Biggest code possible in 12 bits. */
#define LZ_BITS         12

#define FLUSH_OUTPUT            4096    /* Impossible code, to signal flush. */
#define FIRST_CODE              4097    /* Impossible code, to signal first. */
#define NO_SUCH_CODE            4098    /* Impossible code, to signal empty. */

#define GIF_STAMP "GIFVER"          /* First chars in file - GIF stamp.  */
#define GIF_STAMP_LEN sizeof(GIF_STAMP) - 1
#define GIF_VERSION_POS 3           /* Version first character in stamp. */
#define GIF87_STAMP     "GIF87a"        /* First chars in file - GIF stamp.  */
#define GIF89_STAMP     "GIF89a"        /* First chars in file - GIF stamp.  */

#define MAX(x, y)       (((x) > (y)) ? (x) : (y))

struct GifColorType
{
        unsigned char Red;
        unsigned char Green;
        unsigned char Blue;
};

struct ColorMapObject
{
    int ColorCount;
    int BitsPerPixel;
    GifColorType *Colors;               /* on malloc(3) heap */
};

struct GifImageDesc
{
    int Left, Top, Width, Height, Interlace;
    ColorMapObject *ColorMap;           /* The local color map */
};

struct ExtensionBlock
{
    int         ByteCount;
    char        *Bytes;         /* on malloc(3) heap */
    int Function;       /* Holds the type of the Extension block. */
};

struct SavedImage
{
    GifImageDesc        ImageDesc;
    char                        *RasterBits;            /* on malloc(3) heap */
    int                         Function;
    int                         ExtensionBlockCount;
    ExtensionBlock      *ExtensionBlocks;       /* on malloc(3) heap */
};

struct GifFileType
{
    int SWidth, SHeight;                /* Screen dimensions. */
        int SColorResolution;           /* How many colors can we generate? */
        int SBackGroundColor;           /* I hope you understand this one... */
    ColorMapObject *SColorMap;          /* NULL if not exists. */
    int ImageCount;                     /* Number of current image */
    GifImageDesc Image;                 /* Block describing current image */
    struct SavedImage *SavedImages;     /* Use this to accumulate file state */
    void *UserData;           /* hook to attach user data (TVT) */
    void *Private;                      /* Don't mess with this! */
};

struct GifFilePrivateType
{
        int FileHandle;                      /* Where all this data goes to! */
        int BitsPerPixel;           /* Bits per pixel (Codes uses at least this + 1). */
        int ClearCode;                                 /* The CLEAR LZ code. */
        int EOFCode;                                     /* The EOF LZ code. */
        int RunningCode;                    /* The next code algorithm can generate. */
        int RunningBits;/* The number of bits required to represent RunningCode. */
        int MaxCode1;  /* 1 bigger than max. possible code, in RunningBits bits. */
        int LastCode;                   /* The code before the current code. */
        int CrntCode;                             /* Current algorithm code. */
        int StackPtr;                    /* For character stack (see below). */
        int CrntShiftState;                     /* Number of bits in CrntShiftDWord. */
    unsigned long CrntShiftDWord;     /* For bytes decomposition into codes. */
    unsigned long PixelCount;                  /* Number of pixels in image. */
    unsigned char Buf[256];            /* Compressed input is buffered here. */
    unsigned char Stack[LZ_MAX_CODE];    /* Decoded pixels are stacked here. */
    unsigned char Suffix[LZ_MAX_CODE+1];               /* So we can trace the codes. */
    unsigned int Prefix[LZ_MAX_CODE+1];
};

typedef enum {
    UNDEFINED_RECORD_TYPE,
    SCREEN_DESC_RECORD_TYPE,
    IMAGE_DESC_RECORD_TYPE,             /* Begin with ',' */
    EXTENSION_RECORD_TYPE,              /* Begin with '!' */
    TERMINATE_RECORD_TYPE               /* Begin with ';' */
} GifRecordType;

static int InterlacedOffset[] = { 0, 4, 2, 1 }; /* The way Interlaced image should. */
static int InterlacedJumps[] = { 8, 8, 4, 2 };    /* be read - offsets and jumps... */

/******************************************************************************
* Miscellaneous utility functions                                             *
* return smallest bitfield size n will fit in *
******************************************************************************/
static int BitSize(int n)
{
    register    int i;

    for (i = 1; i <= 8; i++)
                if ((1 << i) >= n)
                    break;
    return(i);
}

/******************************************************************************
* Color map object functions                                                  *
* Allocate a color map of given size; initialize with contents of
* ColorMap if that pointer is non-NULL.
******************************************************************************/
static ColorMapObject *MakeMapObject(int ColorCount, const GifColorType *ColorMap)
{
    ColorMapObject *Object;

    if (ColorCount != (1 << BitSize(ColorCount)))
                return 0;

    Object = (ColorMapObject *)malloc(sizeof(ColorMapObject));
    if (Object == 0)
                return 0;

    Object->Colors = (GifColorType *)calloc(ColorCount, sizeof(GifColorType));
    if (Object->Colors == (GifColorType *)NULL)
                return 0;

    Object->ColorCount = ColorCount;
    Object->BitsPerPixel = BitSize(ColorCount);

    if (ColorMap)
                memcpy(Object->Colors, ColorMap, ColorCount * sizeof(GifColorType));

    return(Object);
}

/******************************************************************************
* Free a color map object
******************************************************************************/
static void FreeMapObject(ColorMapObject *Object)
{
    free(Object->Colors);
    free(Object);
}

/******************************************************************************
 * Compute the union of two given color maps and return it.  If result can't 
 * fit into 256 colors, NULL is returned, the allocated union otherwise.
 * ColorIn1 is copied as is to ColorUnion, while colors from ColorIn2 are
 * copied iff they didn't exist before.  ColorTransIn2 maps the old
 * ColorIn2 into ColorUnion color map table.
******************************************************************************/
static ColorMapObject *UnionColorMap(const ColorMapObject *ColorIn1, const ColorMapObject *ColorIn2, unsigned char ColorTransIn2[])
{
    int i, j, CrntSlot, RoundUpTo, NewBitSize;
    ColorMapObject *ColorUnion;

    /*
     * Allocate table which will hold the result for sure.
     */
    ColorUnion = MakeMapObject(MAX(ColorIn1->ColorCount,ColorIn2->ColorCount)*2,NULL);

    if (ColorUnion == 0)
                return 0;

    /* Copy ColorIn1 to ColorUnionSize; */
    for (i = 0; i < ColorIn1->ColorCount; i++)
                ColorUnion->Colors[i] = ColorIn1->Colors[i];
    CrntSlot = ColorIn1->ColorCount;

    /*
     * Potentially obnoxious hack:
     *
     * Back CrntSlot down past all contiguous {0, 0, 0} slots at the end
     * of table 1.  This is very useful if your display is limited to
     * 16 colors.
     */
    while (ColorIn1->Colors[CrntSlot-1].Red == 0
                           && ColorIn1->Colors[CrntSlot-1].Green == 0
                                && ColorIn1->Colors[CrntSlot-1].Red == 0)
                CrntSlot--;

    /* Copy ColorIn2 to ColorUnionSize (use old colors if they exist): */
    for (i = 0; i < ColorIn2->ColorCount && CrntSlot<=256; i++)
    {
                /* Let's see if this color already exists: */
                for (j = 0; j < ColorIn1->ColorCount; j++)
                if (memcmp(&ColorIn1->Colors[j], &ColorIn2->Colors[i], sizeof(GifColorType)) == 0)
                                break;

                if (j < ColorIn1->ColorCount)
                    ColorTransIn2[i] = j;       /* color exists in Color1 */
                else
                {
                /* Color is new - copy it to a new slot: */
                    ColorUnion->Colors[CrntSlot] = ColorIn2->Colors[i];
                    ColorTransIn2[i] = CrntSlot++;
                }
    }

    if (CrntSlot > 256)
    {
                FreeMapObject(ColorUnion);
                return 0;
    }

    NewBitSize = BitSize(CrntSlot);
    RoundUpTo = (1 << NewBitSize);

    if (RoundUpTo != ColorUnion->ColorCount)
    {
                register GifColorType   *Map = ColorUnion->Colors;

                /*
                 * Zero out slots up to next power of 2.
                 * We know these slots exist because of the way ColorUnion's
                 * start dimension was computed.
                 */
                for (j = CrntSlot; j < RoundUpTo; j++)
                    Map[j].Red = Map[j].Green = Map[j].Blue = 0;

                /* perhaps we can shrink the map? */
                if (RoundUpTo < ColorUnion->ColorCount)
                    ColorUnion->Colors = (GifColorType *)realloc(Map, sizeof(GifColorType)*RoundUpTo);
    }

    ColorUnion->ColorCount = RoundUpTo;
    ColorUnion->BitsPerPixel = NewBitSize;

    return(ColorUnion);
}

/******************************************************************************
 * Apply a given color translation to the raster bits of an image
******************************************************************************/
static void ApplyTranslation(SavedImage *Image, unsigned char Translation[])
{
    register int i;
    register int RasterSize = Image->ImageDesc.Height * Image->ImageDesc.Width;

    for (i = 0; i < RasterSize; i++)
                Image->RasterBits[i] = Translation[Image->RasterBits[i]];
}

/******************************************************************************
* MakeExtension
******************************************************************************/
static void MakeExtension(SavedImage *New, int Function)
{
    New->Function = Function;
    /*
     * Someday we might have to deal with multiple extensions.
     */
}

/******************************************************************************
* AddExtensionBlock
******************************************************************************/
static int AddExtensionBlock(SavedImage *New, int Len, char ExtData[])
{
    ExtensionBlock      *ep;

    if (New->ExtensionBlocks == 0)
                New->ExtensionBlocks = (ExtensionBlock *)malloc(sizeof(ExtensionBlock));
    else
                New->ExtensionBlocks = (ExtensionBlock *)realloc(New->ExtensionBlocks,
                                sizeof(ExtensionBlock) * (New->ExtensionBlockCount + 1));

    if (New->ExtensionBlocks == 0)
                return FALSE;

        ep = &New->ExtensionBlocks[New->ExtensionBlockCount++];

        if ((ep->Bytes = (char *)malloc(ep->ByteCount = Len)) == NULL)
                return FALSE;

        if (ExtData)
        {
                memcpy(ep->Bytes, ExtData, Len);
                ep->Function = New->Function;
        }

        return TRUE;
}

/******************************************************************************
* FreeExtensionBlock
******************************************************************************/
static void FreeExtension(SavedImage *Image)
{
    ExtensionBlock      *ep;

    for (ep = Image->ExtensionBlocks;
                         ep < Image->ExtensionBlocks + Image->ExtensionBlockCount;
                         ep++)
                (void) free((char *)ep->Bytes);
    free((char *)Image->ExtensionBlocks);
    Image->ExtensionBlocks = NULL;
}

/******************************************************************************
* Append an image block to the SavedImages array  
******************************************************************************/
static SavedImage *MakeSavedImage(GifFileType *GifFile, const SavedImage *CopyFrom)
{
    SavedImage  *sp;

    if (GifFile->SavedImages == NULL)
                GifFile->SavedImages = (SavedImage *)malloc(sizeof(SavedImage));
    else
                GifFile->SavedImages = (SavedImage *)realloc(GifFile->SavedImages,
                                                        sizeof(SavedImage) * (GifFile->ImageCount+1));

    if (GifFile->SavedImages == NULL)
                return 0;
    else
    {
                sp = &GifFile->SavedImages[GifFile->ImageCount++];
                memset((char *)sp, '\0', sizeof(SavedImage));

                if (CopyFrom)
                {
                    memcpy((char *)sp, CopyFrom, sizeof(SavedImage));

                    /*
                     * Make our own allocated copies of the heap fields in the
                 * copied record.  This guards against potential aliasing
                     * problems.
                     */

                /* first, the local color map */
                    if (sp->ImageDesc.ColorMap)
                                sp->ImageDesc.ColorMap =
                                        MakeMapObject(CopyFrom->ImageDesc.ColorMap->ColorCount,
                                CopyFrom->ImageDesc.ColorMap->Colors);

                            /* next, the raster */
                        sp->RasterBits = (char *)malloc(sizeof(unsigned char)
                                                        * CopyFrom->ImageDesc.Height
                                                        * CopyFrom->ImageDesc.Width);

                            memcpy(sp->RasterBits,
                                                        CopyFrom->RasterBits,
                                                        sizeof(unsigned char)
                                                        * CopyFrom->ImageDesc.Height
                                                        * CopyFrom->ImageDesc.Width);

                            /* finally, the extension blocks */
                        if (sp->ExtensionBlocks)
                            {
                                        sp->ExtensionBlocks
                                                    = (ExtensionBlock*)malloc(sizeof(ExtensionBlock)
                                                    * CopyFrom->ExtensionBlockCount);

                                        memcpy(sp->ExtensionBlocks,
                                                        CopyFrom->ExtensionBlocks,
                                                        sizeof(ExtensionBlock)
                                                        * CopyFrom->ExtensionBlockCount);

                                        /*
                                         * For the moment, the actual blocks can take their
                                         * chances with free().  We'll fix this later. 
                                         */
                            }
                }

                return sp;
    }
}

/******************************************************************************
* FreeSavedImages
******************************************************************************/
static void FreeSavedImages(GifFileType *GifFile)
{
    SavedImage  *sp;

    for (sp = GifFile->SavedImages;
                                 sp < GifFile->SavedImages + GifFile->ImageCount;
                                 sp++)
    {
                if (sp->ImageDesc.ColorMap)
                FreeMapObject(sp->ImageDesc.ColorMap);

                if (sp->RasterBits)
                    free((char *)sp->RasterBits);

                if (sp->ExtensionBlocks)
                    FreeExtension(sp);
    }
    free((char *) GifFile->SavedImages);
}

/******************************************************************************
*   This routines read one gif data block at a time and buffers it internally *
* so that the decompression routine could access it.                          *
*   The routine returns the next byte from its internal buffer (or read next  *
* block in if buffer empty) and returns GIF_OK if succesful.                  *
******************************************************************************/
static int DGifBufferedInput(GifFileType *GifFile, unsigned char *Buf, unsigned char *NextByte)
{
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

    if (Buf[0] == 0)
        {
                if (RdosReadHandle(Private->FileHandle, Buf, 1) != 1)
                        return FALSE;

                if (RdosReadHandle(Private->FileHandle, &Buf[1], Buf[0]) != Buf[0])
                        return FALSE;

                *NextByte = Buf[1];
                Buf[1] = 2;        /* We use now the second place as last char read! */
                Buf[0]--;
        }
        else
        {
                *NextByte = Buf[Buf[1]++];
                Buf[0]--;
        }

        return TRUE;
}

/******************************************************************************
*   Get 2 bytes (word) from the given file:                                   *
******************************************************************************/
static int DGifGetWord(GifFileType *GifFile, int *Word)
{
    unsigned char c[2];
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

    if (RdosReadHandle(Private->FileHandle,c, 2) != 2)
                return FALSE;

        *Word = (((unsigned int) c[1]) << 8) + c[0];
    return TRUE;
}

/******************************************************************************
*   Continue to get the image code in compressed form. This routine should be *
* called until NULL block is returned.                                        *
*   The block should NOT be freed by the user (not dynamically allocated).    *
******************************************************************************/
static int DGifGetCodeNext(GifFileType *GifFile, unsigned char **CodeBlock)
{
    unsigned char Buf;
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

        if (RdosReadHandle(Private->FileHandle, &Buf, 1) != 1)
                return FALSE;

        if (Buf > 0)
        {
                *CodeBlock = Private->Buf;             /* Use private unused buffer. */
                (*CodeBlock)[0] = Buf;  /* Pascal strings notation (pos. 0 is len.). */

                if (RdosReadHandle(Private->FileHandle, &((*CodeBlock)[1]), Buf) != Buf)
                        return FALSE;
        }
        else
        {
                *CodeBlock = NULL;
                Private->Buf[0] = 0;               /* Make sure the buffer is empty! */
                Private->PixelCount = 0;   /* And local info. indicate image read. */
        }

        return TRUE;
}

/******************************************************************************
*   Get the image code in compressed form.  his routine can be called if the  *
* information needed to be piped out as is. Obviously this is much faster     *
* than decoding and encoding again. This routine should be followed by calls  *
* to DGifGetCodeNext, until NULL block is returned.                           *
*   The block should NOT be freed by the user (not dynamically allocated).    *
******************************************************************************/
static int DGifGetCode(GifFileType *GifFile, int *CodeSize, unsigned char **CodeBlock)
{
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

    *CodeSize = Private->BitsPerPixel;

    return DGifGetCodeNext(GifFile, CodeBlock);
}

/******************************************************************************
* Routine to trace the Prefixes linked list until we get a prefix which is    *
* not code, but a pixel value (less than ClearCode). Returns that pixel value.*
* If image is defective, we might loop here forever, so we limit the loops to *
* the maximum possible if image O.k. - LZ_MAX_CODE times.                     *
******************************************************************************/
static int DGifGetPrefixChar(unsigned int *Prefix, int Code, int ClearCode)
{
    int i = 0;

    while (Code > ClearCode && i++ <= LZ_MAX_CODE)
                Code = Prefix[Code];
    return Code;
}

/******************************************************************************
*   The LZ decompression input routine:                                       *
*   This routine is responsable for the decompression of the bit stream from  *
* 8 bits (bytes) packets, into the real codes.                                *
*   Returns GIF_OK if read succesfully.                                       *
******************************************************************************/
static int DGifDecompressInput(GifFileType *GifFile, int *Code)
{
    GifFilePrivateType *Private = (GifFilePrivateType *)GifFile->Private;

    unsigned char NextByte;
    static unsigned int CodeMasks[] = 
                {
                        0x0000, 0x0001, 0x0003, 0x0007,
                        0x000f, 0x001f, 0x003f, 0x007f,
                        0x00ff, 0x01ff, 0x03ff, 0x07ff,
                        0x0fff
            };

    while (Private->CrntShiftState < Private->RunningBits)
        {
                /* Needs to get more bytes from input stream for next code: */
                if (!DGifBufferedInput(GifFile, Private->Buf, &NextByte))
                        return FALSE;

                Private->CrntShiftDWord |= ((unsigned long) NextByte) << Private->CrntShiftState;
                Private->CrntShiftState += 8;
    }
    *Code = Private->CrntShiftDWord & CodeMasks[Private->RunningBits];

    Private->CrntShiftDWord >>= Private->RunningBits;
    Private->CrntShiftState -= Private->RunningBits;

        /* If code cannt fit into RunningBits bits, must raise its size. Note */
    /* however that codes above 4095 are used for special signaling.      */
    if (++Private->RunningCode > Private->MaxCode1 && Private->RunningBits < LZ_BITS)
        {
                Private->MaxCode1 <<= 1;
                Private->RunningBits++;
    }
    return TRUE;
}

/******************************************************************************
*   Setup the LZ decompression for this image:                                *
******************************************************************************/
static int DGifSetupDecompress(GifFileType *GifFile)
{
    int i, BitsPerPixel;
    unsigned char CodeSize;
    unsigned int *Prefix;
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

        RdosReadHandle(Private->FileHandle,&CodeSize, 1);    /* Read Code size from file. */
        BitsPerPixel = CodeSize;

        Private->Buf[0] = 0;                          /* Input Buffer empty. */
        Private->BitsPerPixel = BitsPerPixel;
        Private->ClearCode = (1 << BitsPerPixel);
        Private->EOFCode = Private->ClearCode + 1;
        Private->RunningCode = Private->EOFCode + 1;
        Private->RunningBits = BitsPerPixel + 1;         /* Number of bits per code. */
    Private->MaxCode1 = 1 << Private->RunningBits;     /* Max. code + 1. */
    Private->StackPtr = 0;                  /* No pixels on the pixel stack. */
    Private->LastCode = NO_SUCH_CODE;
    Private->CrntShiftState = 0;        /* No information in CrntShiftDWord. */
    Private->CrntShiftDWord = 0;

    Prefix = Private->Prefix;
    for (i = 0; i <= LZ_MAX_CODE; i++)
                Prefix[i] = NO_SUCH_CODE;

    return TRUE;
}

/******************************************************************************
*   The LZ decompression routine:                                             *
*   This version decompress the given gif file into Line of length LineLen.   *
*   This routine can be called few times (one per scan line, for example), in *
* order the complete the whole image.                                         *
******************************************************************************/
static int DGifDecompressLine(GifFileType *GifFile, unsigned char *Line, int LineLen)
{
    int i = 0, j, CrntCode, EOFCode, ClearCode, CrntPrefix, LastCode, StackPtr;
    unsigned char *Stack, *Suffix;
    unsigned int *Prefix;
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

    StackPtr = Private->StackPtr;
    Prefix = Private->Prefix;
    Suffix = Private->Suffix;
    Stack = Private->Stack;
    EOFCode = Private->EOFCode;
    ClearCode = Private->ClearCode;
    LastCode = Private->LastCode;

    if (StackPtr != 0)
        {
                /* Let pop the stack off before continueing to read the gif file: */
                while (StackPtr != 0 && i < LineLen) 
                        Line[i++] = Stack[--StackPtr];
    }

        while (i < LineLen)
        {                           /* Decode LineLen items. */
                if (!DGifDecompressInput(GifFile, &CrntCode))
                        return FALSE;

                if (CrntCode == EOFCode)
                {
                        /* Note however that usually we will not be here as we will stop */
                        /* decoding as soon as we got all the pixel, or EOF code will    */
                        /* not be read at all, and DGifGetLine/Pixel clean everything.   */
                        if (i != LineLen - 1 || Private->PixelCount != 0)
                                return FALSE;

                        i++;
                }
                else
                        if (CrntCode == ClearCode)
                        {
                                /* We need to start over again: */
                                for (j = 0; j <= LZ_MAX_CODE; j++)
                                        Prefix[j] = NO_SUCH_CODE;
                                Private->RunningCode = Private->EOFCode + 1;
                                Private->RunningBits = Private->BitsPerPixel + 1;
                                Private->MaxCode1 = 1 << Private->RunningBits;
                                LastCode = Private->LastCode = NO_SUCH_CODE;
                        }
                        else
                        {
                                /* Its regular code - if in pixel range simply add it to output  */
                                /* stream, otherwise trace to codes linked list until the prefix */
                                /* is in pixel range:                                        */
                                if (CrntCode < ClearCode)
                                {
                                        /* This is simple - its pixel scalar, so add it to output:   */
                                        Line[i++] = CrntCode;
                                }
                                else
                                {
                                        /* Its a code to needed to be traced: trace the linked list  */
                                        /* until the prefix is a pixel, while pushing the suffix     */
                                        /* pixels on our stack. If we done, pop the stack in reverse */
                                        /* (thats what stack is good for!) order to output.          */
                                        if (Prefix[CrntCode] == NO_SUCH_CODE)
                                        {
                                                /* Only allowed if CrntCode is exactly the running code: */
                                                /* In that case CrntCode = XXXCode, CrntCode or the          */
                                                /* prefix code is last code and the suffix char is           */
                                                /* exactly the prefix of last code!                          */
                                                if (CrntCode == Private->RunningCode - 2)
                                                {
                                                        CrntPrefix = LastCode;
                                                        Suffix[Private->RunningCode - 2] =
                                                                        Stack[StackPtr++] = DGifGetPrefixChar(Prefix,
                                                                        LastCode, ClearCode);
                                                }
                                                else
                                                        return FALSE;
                                        }
                                        else
                                                CrntPrefix = CrntCode;

                                        /* Now (if image is O.K.) we should not get an NO_SUCH_CODE  */
                                        /* During the trace. As we might loop forever, in case of    */
                                        /* defective image, we count the number of loops we trace    */
                                        /* and stop if we got LZ_MAX_CODE. obviously we can not      */
                                        /* loop more than that.                                      */
                                        j = 0;
                                        while (j++ <= LZ_MAX_CODE &&
                                                           CrntPrefix > ClearCode &&
                                                           CrntPrefix <= LZ_MAX_CODE)
                                        {
                                                Stack[StackPtr++] = Suffix[CrntPrefix];
                                                CrntPrefix = Prefix[CrntPrefix];
                                        }
                                        if (j >= LZ_MAX_CODE || CrntPrefix > LZ_MAX_CODE)
                                                return FALSE;

                                        /* Push the last character on stack: */
                                        Stack[StackPtr++] = CrntPrefix;

                                        /* Now lets pop all the stack into output: */
                                        while (StackPtr != 0 && i < LineLen)
                                                Line[i++] = Stack[--StackPtr];
                                }
                                if (LastCode != NO_SUCH_CODE)
                                {
                                        Prefix[Private->RunningCode - 2] = LastCode;

                                        if (CrntCode == Private->RunningCode - 2)
                                        {
                                                /* Only allowed if CrntCode is exactly the running code: */
                                                /* In that case CrntCode = XXXCode, CrntCode or the          */
                                                /* prefix code is last code and the suffix char is           */
                                                /* exactly the prefix of last code!                          */
                                                Suffix[Private->RunningCode - 2] =
                                                DGifGetPrefixChar(Prefix, LastCode, ClearCode);
                                        }
                                        else
                                        {
                                                Suffix[Private->RunningCode - 2] =
                                                                DGifGetPrefixChar(Prefix, CrntCode, ClearCode);
                                        }
                                }
                                LastCode = CrntCode;
                        }
        }

        Private->LastCode = LastCode;
        Private->StackPtr = StackPtr;

        return TRUE;
}

/******************************************************************************
*   This routine should be called before any other DGif calls. Note that      *
* this routine is called automatically from DGif file open routines.          *
******************************************************************************/
static int DGifGetScreenDesc(GifFileType *GifFile)
{
    int i, BitsPerPixel;
    unsigned char Buf[3];
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

    /* Put the screen descriptor into the file: */
        if (            !DGifGetWord(GifFile, &GifFile->SWidth) ||
                                !DGifGetWord(GifFile, &GifFile->SHeight))
                return FALSE;

        if (RdosReadHandle(Private->FileHandle, Buf, 3) != 3)
                return FALSE;

        GifFile->SColorResolution = (((Buf[0] & 0x70) + 1) >> 4) + 1;
        BitsPerPixel = (Buf[0] & 0x07) + 1;
        GifFile->SBackGroundColor = Buf[1];
        if (Buf[0] & 0x80)
        {                    /* Do we have global color map? */

                GifFile->SColorMap = MakeMapObject(1 << BitsPerPixel, NULL);

                /* Get the global color map: */
                for (i = 0; i < GifFile->SColorMap->ColorCount; i++)
                {
                        if (RdosReadHandle(Private->FileHandle, Buf, 3) != 3)
                                return FALSE;

                        GifFile->SColorMap->Colors[i].Red = Buf[0];
                        GifFile->SColorMap->Colors[i].Green = Buf[1];
                        GifFile->SColorMap->Colors[i].Blue = Buf[2];
                }
        }

        return TRUE;
}

/******************************************************************************
*   This routine should be called before any attemp to read an image.         *
******************************************************************************/
int DGifGetRecordType(GifFileType *GifFile, GifRecordType *Type)
{
        unsigned char Buf;
        GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

        if (RdosReadHandle(Private->FileHandle, &Buf, 1) != 1)
                return FALSE;

        switch (Buf)
        {
                case ',':
                        *Type = IMAGE_DESC_RECORD_TYPE;
                        break;

                case '!':
                        *Type = EXTENSION_RECORD_TYPE;
                        break;

                case ';':
                        *Type = TERMINATE_RECORD_TYPE;
                        break;

                default:
                        *Type = UNDEFINED_RECORD_TYPE;
                        return FALSE;
        }

        return TRUE;
}

/******************************************************************************
*   This routine should be called before any attemp to read an image.         *
*   Note it is assumed the Image desc. header (',') has been read.            *
******************************************************************************/
static int DGifGetImageDesc(GifFileType *GifFile)
{
        int i, BitsPerPixel;
        unsigned char Buf[3];
        GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;
        SavedImage      *sp;

        if (            !DGifGetWord(GifFile, &GifFile->Image.Left) ||
                                !DGifGetWord(GifFile, &GifFile->Image.Top) ||
                                !DGifGetWord(GifFile, &GifFile->Image.Width) ||
                                !DGifGetWord(GifFile, &GifFile->Image.Height))
                return FALSE;

        if (RdosReadHandle(Private->FileHandle, Buf, 1) != 1)
                return FALSE;

        BitsPerPixel = (Buf[0] & 0x07) + 1;
        GifFile->Image.Interlace = (Buf[0] & 0x40);
        if (Buf[0] & 0x80)
        {           /* Does this image have local color map? */

                if (GifFile->Image.ColorMap && GifFile->SavedImages == NULL)
                        FreeMapObject(GifFile->Image.ColorMap);

                GifFile->Image.ColorMap = MakeMapObject(1 << BitsPerPixel, NULL);

                /* Get the image local color map: */
                for (i = 0; i < GifFile->Image.ColorMap->ColorCount; i++)
                {
                        if (RdosReadHandle(Private->FileHandle,Buf, 3) != 3)
                                return FALSE;

                        GifFile->Image.ColorMap->Colors[i].Red = Buf[0];
                        GifFile->Image.ColorMap->Colors[i].Green = Buf[1];
                        GifFile->Image.ColorMap->Colors[i].Blue = Buf[2];
                }
        }

        if (GifFile->SavedImages)
        {
                if ((GifFile->SavedImages = (SavedImage *)realloc(GifFile->SavedImages,
                                 sizeof(SavedImage) * (GifFile->ImageCount + 1))) == NULL)
                        return FALSE;
        }
        else
        {
                if ((GifFile->SavedImages = (SavedImage *)malloc(sizeof(SavedImage))) == NULL)
                        return FALSE;
        }

        sp = &GifFile->SavedImages[GifFile->ImageCount];
        memcpy(&sp->ImageDesc, &GifFile->Image, sizeof(GifImageDesc));
        if (GifFile->Image.ColorMap != NULL)
        {
                sp->ImageDesc.ColorMap = MakeMapObject(
                                GifFile->Image.ColorMap->ColorCount,
                                GifFile->Image.ColorMap->Colors);
        }
        sp->RasterBits = 0;
        sp->ExtensionBlockCount = 0;
        sp->ExtensionBlocks = 0;

        GifFile->ImageCount++;

        Private->PixelCount = (long) GifFile->Image.Width *
                                (long) GifFile->Image.Height;

        DGifSetupDecompress(GifFile);  /* Reset decompress algorithm parameters. */

        return TRUE;
}

/******************************************************************************
*  Get one full scanned line (Line) of length LineLen from GIF file.          *
******************************************************************************/
static int DGifGetLine(GifFileType *GifFile, unsigned char *Line, int LineLen)
{
    unsigned char *Dummy;
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

    if (!LineLen)
                LineLen = GifFile->Image.Width;

    if ((Private->PixelCount -= LineLen) > 0xffff0000UL)
                return FALSE;

        if (DGifDecompressLine(GifFile, Line, LineLen))
        {
                if (Private->PixelCount == 0)
                {
                        /* We probably would not be called any more, so lets clean           */
                        /* everything before we return: need to flush out all rest of    */
                        /* image until empty block (size 0) detected. We use GetCodeNext.*/
                        do
                                if (!DGifGetCodeNext(GifFile, &Dummy))
                                        return FALSE;
                        while (Dummy != NULL);
                }
                return TRUE;
        }
        else
                return FALSE;
}

/******************************************************************************
*   Get a following extension block (see GIF manual) from gif file. This      *
* routine should be called until NULL Extension is returned.                  *
*   The Extension should NOT be freed by the user (not dynamically allocated).*
******************************************************************************/
static int DGifGetExtensionNext(GifFileType *GifFile, unsigned char **Extension)
{
    unsigned char Buf;
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

    if (Buf > 0)
        {
                *Extension = Private->Buf;           /* Use private unused buffer. */
                (*Extension)[0] = Buf;  /* Pascal strings notation (pos. 0 is len.). */

                if (RdosReadHandle(Private->FileHandle,&((*Extension)[1]), Buf) != Buf)
                        return FALSE;
        }
        else
                *Extension = NULL;

    return TRUE;
}

/******************************************************************************
*   Get an extension block (see GIF manual) from gif file. This routine only  *
* returns the first data block, and DGifGetExtensionNext shouldbe called      *
* after this one until NULL extension is returned.                            *
*   The Extension should NOT be freed by the user (not dynamically allocated).*
*   Note it is assumed the Extension desc. header ('!') has been read.        *
******************************************************************************/
static int DGifGetExtension(GifFileType *GifFile, int *ExtCode, unsigned char **Extension)
{
    unsigned char Buf;
    GifFilePrivateType *Private = (GifFilePrivateType *) GifFile->Private;

        if (RdosReadHandle(Private->FileHandle,&Buf, 1) != 1)
                return FALSE;

        *ExtCode = Buf;

        return DGifGetExtensionNext(GifFile, Extension);
}

/******************************************************************************
*   Update a new gif file, given its file handle.                             *
*   Returns GifFileType pointer dynamically allocated which serves as the gif *
*   info record. _GifError is cleared if succesfull.                          *
******************************************************************************/
static GifFileType *DGifOpenFileHandle(int FileHandle)
{
        char Buf[GIF_STAMP_LEN+1];
        GifFileType *GifFile;
        GifFilePrivateType *Private;

        if ((GifFile = (GifFileType *) malloc(sizeof(GifFileType))) == NULL)
                return 0;

        memset(GifFile, '\0', sizeof(GifFileType));

        if ((Private = (GifFilePrivateType *) malloc(sizeof(GifFilePrivateType))) == NULL)
        {
                free((char *) GifFile);
                return 0;
        }

        GifFile->Private = Private;
        Private->FileHandle = FileHandle;
        GifFile->UserData = 0;  /* TVT */

        /* Lets see if this is a GIF file: */
        if (RdosReadHandle(Private->FileHandle, Buf, GIF_STAMP_LEN) != GIF_STAMP_LEN)
        {
                free((char *) Private);
                free((char *) GifFile);
                return 0;
        }

        /* The GIF Version number is ignored at this time. Maybe we should do    */
        /* something more useful with it.                         */
        Buf[GIF_STAMP_LEN] = 0;
        if (strncmp(GIF_STAMP, Buf, GIF_VERSION_POS) != 0)
        {
                free((char *) Private);
                free((char *) GifFile);
                return 0;
        }

        if (!DGifGetScreenDesc(GifFile))
        {
                free((char *) Private);
                free((char *) GifFile);
                return 0;
        }

        return GifFile;
}

/******************************************************************************
*   This routine should be called last, to close the GIF file.                *
******************************************************************************/
static int DGifCloseFile(GifFileType *GifFile)
{
    GifFilePrivateType *Private;

        if (GifFile == 0)
                return FALSE;

        Private = (GifFilePrivateType *) GifFile->Private;

        if (GifFile->Image.ColorMap)
        {
                FreeMapObject(GifFile->Image.ColorMap);
                GifFile->Image.ColorMap = NULL;
        }

        if (GifFile->SColorMap)
        {
                FreeMapObject(GifFile->SColorMap);
                GifFile->SColorMap = NULL;
        }

        RdosCloseHandle(Private->FileHandle);

        if (Private)
        {
                free((char *) Private);
                Private = NULL;
        }

        if (GifFile->SavedImages)
        {
                FreeSavedImages(GifFile);
                GifFile->SavedImages= NULL; //RGL+: Correct code
        }

        free(GifFile);
        return TRUE;
}

/******************************************************************************
*   DGifHandleScanLine
******************************************************************************/
void DGifHandleScanLine(GifFileType *GifFile, char *RgbData, char *GifData)
{
    int i;
        ColorMapObject *ColorMap;
    GifColorType *ColorMapEntry;

    ColorMap = (GifFile->Image.ColorMap
                ? GifFile->Image.ColorMap
                : GifFile->SColorMap);

        for (i = 0; i < GifFile->Image.Width; i++)
        {
                ColorMapEntry = &ColorMap->Colors[*GifData];

                *RgbData = ColorMapEntry->Blue;
                RgbData++;

                *RgbData = ColorMapEntry->Green;
                RgbData++;

                *RgbData = ColorMapEntry->Red;
                RgbData++;

                GifData++;
        }
}

/******************************************************************************
*   DGifCreateBitmap
******************************************************************************/
static TGifBitmapDevice *DGifCreateBitmap(GifFileType *GifFile)
{
        int Row;
        int Col;
        int Width;
        int Height;
        char *buf;
        int i, j;
        int Count;
    GifRecordType RecordType;
        unsigned char *Extension;
    int ExtCode;
        TGifBitmapDevice *dev;
        int FileLineSize;
    char *bits;
        int LineSize;
    char *ptr;

    do
        {
                if (!DGifGetRecordType(GifFile, &RecordType))
                        return 0;

                switch (RecordType)
                {
                    case IMAGE_DESC_RECORD_TYPE:
                                if (!DGifGetImageDesc(GifFile))
                                        return 0;

                                Row = GifFile->Image.Top; /* Image Position relative to Screen. */
                                Col = GifFile->Image.Left;
                                Width = GifFile->Image.Width;
                                Height = GifFile->Image.Height;

                                if (GifFile->Image.Left + GifFile->Image.Width > GifFile->SWidth ||
                                                   GifFile->Image.Top + GifFile->Image.Height > GifFile->SHeight)
                                        return 0;

                                buf = new char[Width];

                                dev = new TGifBitmapDevice(24, Width, Height);
                                bits = (char *)dev->GetLinear();
                                LineSize = dev->GetLineSize();
                
                                if (GifFile->Image.Interlace)
                                {
                                    /* Need to perform 4 passes on the images: */
                                    for (Count = i = 0; i < 4; i++)
                                                for (j = Row + InterlacedOffset[i]; j < Row + Height; j += InterlacedJumps[i])
                                                {
                                                        ptr = bits + j * LineSize;
                                                    if (DGifGetLine(GifFile, (unsigned char *)buf, Width))
                                                                DGifHandleScanLine(GifFile, ptr, buf);
                                                        else
                                                                break;
                                                }
                                }
                                else
                                {
                                        for (i = 0; i < Height; i++)
                                        {
                                                ptr = bits + Row * LineSize;
                                                if (DGifGetLine(GifFile, (unsigned char *)buf, Width))
                                                {
                                                        DGifHandleScanLine(GifFile, ptr, buf);
                                                        Row++;
                                                }
                                                else
                                                        break;
                                    }
                                }

                                delete buf;
                                return dev;

                    case EXTENSION_RECORD_TYPE:
                        /* Skip any extension blocks in file: */
                                if (!DGifGetExtension(GifFile, &ExtCode, &Extension)) 
                                        return 0;

                                while (Extension != NULL)
                                {
                                    if (!DGifGetExtensionNext(GifFile, &Extension)) 
                                                return 0;
                                }
                                break;

                    case TERMINATE_RECORD_TYPE:
                                break;
            
                        default:                    /* Should be traps by DGifGetRecordType. */
                                return 0;
                }
    }
    while (RecordType != TERMINATE_RECORD_TYPE);

        return 0;
}

/*##########################################################################
#
#   Name       : TGifBitmapDevice::TGifBitmapDevice
#
#   Purpose....: Constructor for TGifBitmapDevice
#
#   In params..: bpp            bits per pixel
#                                width
#                                height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGifBitmapDevice::TGifBitmapDevice(int bpp, int width, int height)
  : TBitmapGraphicDevice(bpp, width, height)
{
}

/*##########################################################################
#
#   Name       : TGifBitmapDevice::Create
#
#   Purpose....: Create a bitmap from a GIF file
#
#   In params..: FileName               File to read
#   Out params.: *
#   Returns....: bitmap handle
#
##########################################################################*/
TGifBitmapDevice *TGifBitmapDevice::Create(const char *FileName)
{
    int FileHandle;
    GifFileType *GifFile;
        TGifBitmapDevice *dev;

        FileHandle = RdosOpenHandle(FileName, O_RDWR);
        if (FileHandle > 0)
        {
            GifFile = DGifOpenFileHandle(FileHandle);
                if (GifFile)
                        dev = DGifCreateBitmap(GifFile);
                DGifCloseFile(GifFile);
                return dev;
        }

        return 0;
}
