/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2012, Leif Ekblad
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
# freetype.c
# FreeType device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

#include <ft2build.h>
#include <freetype.h>

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
    
    if (Size < 0x1000)
    {
        linear = RdosAllocateSmallGlobalLinear(Size);
        return RdosLinearToPointer(linear);
    }
    else
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
    int linear;
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
        linear = RdosAllocateSmallGlobalLinear(entry_size);
        entry = (FT_CacheEntry *)RdosLinearToPointer(linear);
        memcpy(entry->BitmapData, bitmap->buffer, bitmap->rows * bitmap->width);

        entry->CellX = face->glyph->metrics.horiAdvance >> 6;
        entry->CellY = face->glyph->metrics.vertAdvance >> 6;
        entry->OrigX = face->glyph->bitmap_left;
        entry->OrigY = entry->CellY - face->glyph->bitmap_top;
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

    RdosEnterKernelSection(&face->cache_section);

    face->curr_size = size;
    
    linear = face->size_cache_arr[size];
    if (linear == 0)
    {
        linear = CreateSizeCacheEntry();
        face->size_cache_arr[size] = linear;
    }

    linear = GetGlyphEntry(face, linear, str);

    if (linear)
        entry = (FT_CacheEntry *)RdosLinearToPointer(linear);
        
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

#pragma aux ImplTestGate "*" rdosdev parm routine [eax]
void __far ImplTestGate(int vbe)
{
    int i;
    int j;
    int size = 32;
    int x = 0;
    int y = 0;
    char test_str[] = "ÖstersjÖn";
    char *str_ptr;
    char *ptr;
    FT_CacheEntry *entry;

    str_ptr = test_str;
    
    while (*str_ptr)
    {
        entry = GetGlyph( face_arr[0], size, str_ptr);

        if (entry)
        {
            ptr = &entry->BitmapData[0];
  
            for (i = 0; i < entry->BitmapY; i++)
            {
                for (j = 0; j < entry->BitmapX; j++)
                {
                    RdosSetDrawColor(vbe, *ptr);
                    RdosSetPixel(vbe, x + entry->OrigX + j, y + entry->OrigY + i);
                    ptr++;
                }
            }
        }
        x += entry->CellX;
        str_ptr += RdosGetCharSize(str_ptr);
    }        
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
    FT_Init_FreeType( &lib );
    InitFonts();

    RdosRegisterBimodalUserGate(usergate_test_gate, &ImplTestGate, "Test Gate"); 
}
