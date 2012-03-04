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

void InitFonts();

FT_Library      lib;
int             face_count = 0;
FT_Face         face_arr[MAX_FACES];

#pragma aux ImplTestGate "*" rdosdev parm routine [eax]
void __far ImplTestGate(int vbe)
{
    int i;
    int j;
    int error;
    int size = 32;
    FT_Bitmap  *bitmap;
    char *ptr;

    if ( FT_IS_SCALABLE( face_arr[0] ) )
        FT_Set_Pixel_Sizes( face_arr[0], size, size );

    i = FT_Get_Char_Index( face_arr[0], 'Ö');
    error = FT_Load_Glyph( face_arr[0], i, FT_LOAD_DEFAULT );

    if (error == 0)
        error = FT_Render_Glyph( face_arr[0]->glyph, FT_RENDER_MODE_NORMAL );

    if (error == 0)
    {
        bitmap = &face_arr[0]->glyph->bitmap;

        ptr = bitmap->buffer;
  
        for (i = 0; i < bitmap->rows; i++)
        {
            for (j = 0; j < bitmap->width; j++)
            {
                RdosSetDrawColor(vbe, *ptr);
                RdosSetPixel(vbe, j, i);
                ptr++;
            }
        }
    }
}

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
void __far InstallFont(void *base, int size)
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
