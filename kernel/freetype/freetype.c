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

void InitFonts();

FT_Library        lib;

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

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

void __far ImplTestGate(const char *msg)
{
    FT_Init_FreeType( &lib );
    InitFonts();
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
    FT_Face* face;

    FT_New_Memory_Face( lib, base, size, 0, face );
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

    RdosRegisterBimodalUserGate(usergate_test_gate, &ImplTestGate, "Test Gate"); 
}
