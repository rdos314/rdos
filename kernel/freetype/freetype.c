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
# freetype.c
# FreeType device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

#include <ft2build.h>
#include <freetype.h>

// #define DEBUG       1

#define MAX_FACES       32


/* this structure is shared with asm (typebase.asm) */

typedef struct  FT_CacheEntry
{
    int CellX;
    int CellY;
    int OrigX;
    int OrigY;
    int BitmapX;
    int BitmapY;
    char BitmapData[1];
} FT_CacheEntry;

void InitFonts();
int CreateSizeCacheEntry();

#pragma aux GetGlyphEntry parm routine [gs esi] [eax] [es edi] value [eax]
int GetGlyphEntry(FT_Face face, int CacheEntry, const char *str);

FT_Library      lib;
int             face_count = 0;
FT_Face         face_arr[MAX_FACES];

/*##########################################################################
#
#   Name       : rdos_alloc
#
##########################################################################*/
void *rdos_alloc(int Size)
{
    long linear;

    if (Size <= 0 || Size > 0x100000)
        return 0;

#ifndef DEBUG    
    if (Size < 0x1000)
    {
        linear = RdosAllocateSmallGlobalLinear(Size);
        return RdosLinearToPointer(linear);
    }
    else
#endif    
        return RdosAllocateBigGlobalMem(Size);
}

/*##########################################################################
#
#   Name       : rdos_free
#
##########################################################################*/
void rdos_free(void *Memory)
{
    int linear;

    int sel = RdosPointerToSelector(Memory);    

    if (Memory == 0)
        return;
    
    if (sel == 0x20)
    {
        linear = RdosPointerToOffset(Memory);
        RdosFreeLinear(linear, 0);  // small linear won't require a size!
    }
    else
        RdosFreeMem(sel);
}

/*##########################################################################
#
#   Name       : GetFace
#
#   Purpose....: Convert between font ID and face
#
#   In params..: ID
#   Out params.: *
#   Returns....: Face
#
##########################################################################*/
#pragma aux GetFace "*" rdosdev parm routine [edx] value [dx eax]
FT_Face GetFace(int ID)
{   
    if (ID >= 0 && ID < MAX_FACES)
        return face_arr[ID];
    else
        return 0;
}
    
/*##########################################################################
#
#   Name       : LoadGlyph
#
#   Purpose....: Load glyph for caching
#
#   In params..: Unicode value
#   Out params.: *
#   Returns....: Linear address of glyph buffer
#
##########################################################################*/
#pragma aux LoadGlyph "*" rdosdev parm routine [gs esi] [edx] value [eax]
int LoadGlyph(FT_Face face, int unicode)
{   
    int error;
    int i;
    int entry_size;
    int linear = 0;
    FT_Bitmap  *bitmap;
    FT_CacheEntry *entry = 0;
    
    if ( FT_IS_SCALABLE( face) )
        FT_Set_Pixel_Sizes( face, face->curr_size, face->curr_size );

    i = FT_Get_Char_Index( face, unicode);
    error = FT_Load_Glyph( face, i, FT_LOAD_DEFAULT );

    if (error == 0)
        error = FT_Render_Glyph( face->glyph, FT_RENDER_MODE_NORMAL );

    if (error == 0)
    {
        bitmap = &face->glyph->bitmap;
        entry_size = sizeof(FT_CacheEntry) + bitmap->rows * bitmap->width - 1;

#ifdef DEBUG
        entry = RdosAllocateSmallGlobalMem(entry_size);
        linear = RdosPointerToSelector(entry);
#else
        linear = RdosAllocateSmallGlobalLinear(entry_size);
        entry = (FT_CacheEntry *)RdosLinearToPointer(linear);
#endif
        
        memcpy(entry->BitmapData, bitmap->buffer, bitmap->rows * bitmap->width);

        entry->CellX = face->glyph->metrics.horiAdvance >> 6;
        entry->CellY = face->glyph->metrics.vertAdvance >> 6;
        entry->OrigX = face->glyph->bitmap_left;
        entry->OrigY = entry->CellY - face->glyph->bitmap_top;
        entry->OrigY += face->descender * entry->CellY / face->height;
        entry->BitmapX = bitmap->width;
        entry->BitmapY = bitmap->rows;
    }
    return linear;
}

/*##########################################################################
#
#   Name       : GetGlyph
#
#   Purpose....: Get a glyph
#
#   In params..: face, size, unicode
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
FT_CacheEntry *GetGlyph(FT_Face face, int size, const char *str)
{
    FT_CacheEntry *entry = 0;
    int linear;

#ifdef DEBUG
    if (face != face_arr[0])
    {
        _asm int 3
    }
#endif

    RdosEnterKernelSection(&face->cache_section);

    face->curr_size = size * face->height / (face->height - face->descender);
    
    linear = face->size_cache_arr[size];
    if (linear == 0)
    {
        linear = CreateSizeCacheEntry();
        face->size_cache_arr[size] = linear;
    }

    linear = GetGlyphEntry(face, linear, str);

    if (linear)

#ifdef DEBUG
        entry = (FT_CacheEntry *)RdosSelectorToPointer(linear);
#else            
        entry = (FT_CacheEntry *)RdosLinearToPointer(linear);
#endif        
        
    RdosLeaveKernelSection(&face->cache_section);

    return entry;
}
    
/*##########################################################################
#
#   Name       : GetMetrics
#
#   Purpose....: Get size of string
#
#   In params..: face, size, string
#   Out params.: *
#   Returns....: Width (low word) and height (high word)
#
##########################################################################*/
#pragma aux GetMetrics "*" rdosdev parm routine [dx eax] [ecx] [es edi] value [eax]
int GetMetrics(FT_Face face, int size, const char *str)
{   
    FT_CacheEntry *entry;
    const char *ptr;
    int width = 0;
    int height = 0;

    ptr = str;
    
    while (*ptr)
    {
        entry = GetGlyph( face, size, ptr);

        if (entry)
        {
            if (entry->CellY > height)
                height = entry->CellY;

            width += entry->CellX;
        }
        ptr += RdosGetCharSize(ptr);
    }        

    if (height == 0)
    {
        entry = GetGlyph( face, size, " ");
        if (entry)
            height = entry->CellY;
    }
    
    return width + (height << 16);
}
    
/*##########################################################################
#
#   Name       : GetCacheEntry
#
#   Purpose....: Get raw cache entry
#
#   In params..: face, size, string
#   Out params.: *
#   Returns....: cache entry
#
##########################################################################*/
#pragma aux GetCacheEntry "*" rdosdev parm routine [dx eax] [ecx] [es edi] value [dx eax]
FT_CacheEntry *GetCacheEntry(FT_Face face, int size, const char *str)
{   
    return GetGlyph( face, size, str );
}

/*##########################################################################
#
#   Name       : InstallFont
#
#   Purpose....: Install font
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InstallFont "*" rdosdev parm routine [es edi] [ecx]
void InstallFont(void *base, int size)
{   
    int error;
    
    error = FT_New_Memory_Face( lib, base, size, 0, &face_arr[face_count] );
    if (error == 0)
    {
        if (face_arr[face_count]->charmap)
        {
            if (face_arr[face_count]->charmap->encoding == FT_ENCODING_UNICODE)
                face_count++;
        }
    }
} 

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    FT_Init_FreeType( &lib );
    InitFonts();
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    RdosHookInitTasking(&InitTasking);
    return 0;
}
