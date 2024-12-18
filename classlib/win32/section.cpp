/*####################################  SECTION.CPP                      #################################################
##    Description: Critical section class. Very fast semaphore implementation                                               ##
##                                                                                                                  ##
##    Created....: 96-09-05 le                                                        Printed...: 90-10-25 an      ##
####################################################################################################################*/

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

