/*      memo_hnd.c                           19.10.93       */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/  memory handler 
/
/  (dyn. allocation with malloc / free 
/                     or halloc / hfree)
/
*/

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME (C LIBRARY)                          *
*                                                               *
****************************************************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "memo_hnd.h"


/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME / GLOBALE VARIABLEN                  *
*                                                               *
****************************************************************/

/* selection of copy mode */

#if (ACT_OP_SYSTEM == MS_DOS) 
#define COPY_WITH_BUFFER 1    /* <== select here !! */
                              /* 1 = high speed */
                              /* 0 = save memory space (but very slow !!) */
#define COPY_SIZE   0x1000    /* compromise */
#else
#define COPY_WITH_BUFFER 1    /* always 1 */
#define COPY_SIZE   0xffff
#endif



/* test malloc() und halloc() */
#define TEST_MALLOC 0


/****************************************************************
*                                                               *
*  ENDE DER DEKLARATIONEN                                       *
*                                                               *
****************************************************************/


/* -FF-  */

/***************************************************************/
/* lokale speicher-verwaltung                                  */
/***************************************************************/


#if (BUFF_MALLOC == BUFF_DYNAMIC)

void FA_HU * loc_malloc (size_t length)
{
void FA_HU *addr;

   addr = (void FA_HU *) malloc (length);

#if TEST_MALLOC
   fprintf (stdout,
            "\n >>> loc_malloc (0x%06x), addr = 0x%08lx...0x%08lx <<< \n",
                               length, addr, ((char *)addr+length-1));
#endif

   return addr;
}


int loc_free (void FA_HU *buffer)
{
   free (buffer);

#if TEST_MALLOC
   fprintf (stdout,
            "\n >>> loc_free , buffer = 0x%08lx <<< \n",
                              buffer);
#endif

   return 0;
}

#endif

/* -FF-  */

#if (BUFF_MALLOC == BUFF_HUGE)

void FA_HU * loc_malloc (long length)
{
void FA_HU *addr;

   addr = halloc (length, sizeof(char));

#if TEST_MALLOC
   fprintf (stdout,
            "\n >>> loc_halloc (0x%06lx), addr = 0x%08lx...0x%08lx <<< \n",
                               length, addr, ((char *)addr+length-1));
#endif

   return addr;
}


int loc_free (void FA_HU * buffer)
{
   hfree (buffer);

#if TEST_MALLOC
   fprintf (stdout,
            "\n >>> loc_hfree, buffer = 0x%08lx <<< \n",
                              buffer);
#endif

   return 0;
}

#endif

/* -FF-  */

void *mac_malloc (size_t length)
{
void *addr;

   addr = malloc (length);

#if TEST_MALLOC
   fprintf (stdout,
            "\n >>> mac_malloc (0x%06x), addr = 0x%08lx...0x%08lx <<< \n",
                               length, addr, ((char *)addr+length-1));
#endif

   return addr;
}


int mac_free (void *buffer)
{
   free (buffer);

#if TEST_MALLOC
   fprintf (stdout,
            "\n >>> mac_free , buffer = 0x%08lx <<< \n",
                              buffer);
#endif

   return 0;
}

/* -FF-  */

#if COPY_WITH_BUFFER

char *memcpy_rev (char FA_HU *dest, const char FA_HU *src, long length)
{
/* funktioniert unabhaengig von der schieberichtung (bei overlap), */
/* und ausserdem auch mit buffer length > 64 kByte                 */

long ii;
static char copy_buff [COPY_SIZE];
size_t temp_len;
char FA_HU *save_dest;


/* save return value */
   save_dest = dest;


/* ist was zu kopieren ? */
   if ((src != dest) && (length != 0))
   {                                       /* ja */

   /* copy direction ? */
      if (src >= dest)     /* normal */
      {
         while (length > 0)
         {
            temp_len = (size_t) min (length, sizeof (copy_buff));

            memcpy (dest, src, temp_len);
            length -= temp_len;
            src    += temp_len;
            dest   += temp_len;
         }
      }
      else                 /* reverse */
      {
         ii = ((length-1) / sizeof(copy_buff)) * sizeof(copy_buff);
         src  += ii;
         dest += ii;
         temp_len = (size_t) (length - ii);

         while (length > 0)
         {                 /* 2-mal memcpy ueber hilfsbuffer */
            memcpy (copy_buff, src , temp_len);
            memcpy (dest, copy_buff, temp_len);
            length -= temp_len;

            temp_len = sizeof (copy_buff);
            src    -= temp_len;
            dest   -= temp_len;
         }
      }
   }

   return save_dest;
}  /* memcpy_rev */

#else

/* -FF-  */

char *memcpy_rev (char FA_HU *dest, const char FA_HU *src, long length)
{
/* funktioniert unabhaengig von der schieberichtung (bei overlap), */
/* und ausserdem auch mit buffer length > 64 kByte                 */

char FA_HU *save_dest;


/* save return value */
   save_dest = dest;


/* ist was zu kopieren ? */
   if ((src != dest) && (length != 0))
   {                                       /* ja */

   /* copy direction ? */
      if (src >= dest)     /* normal */
      {
         while (length > 0)
         {
            *dest++ = *src++;
            length--;
         }
      }
      else                 /* reverse */
      {
         src  += length-1;
         dest += length-1;

         while (length > 0)
         {                 /* 2-mal memcpy ueber hilfsbuffer */
            *dest-- = *src--;
            length--;
         }
      }
   }

   return save_dest;
}  /* memcpy_rev */

#endif

/* -FF-  */

/* Modification History */
/* 03.12.92 - file erzeugt */
/* 15.01.93 - file aufgeteilt in memo_hnd.c, microsft.c, mb_ctype.c */
/* 13.09.93 - TEST_MALLOC */
