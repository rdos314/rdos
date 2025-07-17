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
# section.cpp
# Critical section class
#
########################################################################*/

#include "section.h"
#include <windows.h>

/*##################  TSection::TSection  ####################################
*   Purpose....: Constructor for TSection
*   In params..: *
*   Out params.: *
*   Returns....: *
*   Created....: 96-09-05 le
*##########################################################################*/
TSection::TSection(const char *Name)
{
    InitializeCriticalSection((LPCRITICAL_SECTION)&FData);
}

/*##################  TSection::TSection  ####################################
*   Purpose....: Constructor for TSection
*   In params..: *
*   Out params.: *
*   Returns....: *
*   Created....: 96-09-05 le
*##########################################################################*/
TSection::TSection()
{
    InitializeCriticalSection((LPCRITICAL_SECTION)&FData);
}

/*##################  TSection::~TSection  ####################################
*   Purpose....: Destructor for TSection
*   In params..: *
*   Out params.: *
*   Returns....: *
*   Created....: 96-09-05 le
*##########################################################################*/
TSection::~TSection()
{
    DeleteCriticalSection((LPCRITICAL_SECTION)&FData);
}

/*##################  TSection::Enter  ####################################
*   Purpose....: Enter a critical section
*   In params..: *
*   Out params.: *
*   Returns....: *
*   Created....: 96-09-05 le
*##########################################################################*/
void TSection::Enter() const
{
        LPCRITICAL_SECTION Section = (LPCRITICAL_SECTION)&FData;

        if (Section)
                EnterCriticalSection(Section);
}

/*##################  TSection::Leave  ####################################
*   Purpose....: Leave a critical section
*   In params..: *
*   Out params.: *
*   Returns....: *
*   Created....: 96-09-05 le
*##########################################################################*/
void TSection::Leave() const
{
        LPCRITICAL_SECTION Section = (LPCRITICAL_SECTION)&FData;

        if (Section)
            LeaveCriticalSection(Section);
}

