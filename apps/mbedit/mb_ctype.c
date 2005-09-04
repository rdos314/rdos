/*      mb_ctype.c                           05.07.94       */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/  My private functions toupper, tolower, ... work also with 
/  negative arguments. Therefore, they are used instead of the 
/  lib functions or the macros respectively.
/
*/

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME (C LIBRARY)                          *
*                                                               *
****************************************************************/

#include "config.h"
#include "standard.h"
#include "mb_ctype.h"


/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME / GLOBALE VARIABLEN                  *
*                                                               *
****************************************************************/


/****************************************************************
*                                                               *
*  ENDE DER DEKLARATIONEN                                       *
*                                                               *
****************************************************************/


/* -FF-  */

int mb_toupper (int arg)
{
   if ((arg >= 'a') && (arg <= 'z'))
      return (arg -'a'+'A');
   else
      return arg;

}  /* mb_toupper */


int mb_tolower (int arg)
{
   if ((arg >= 'A') && (arg <= 'Z'))
      return (arg -'A'+'a');
   else
      return arg;

}  /* mb_tolower */

/* -FF-  */

/* Aus dem gleichen Grund wie oben (moegliche neg. Argumente), */
/* hier einige weitere Funktionen */

int mb_isdigit (int arg)
{
   if ((arg >= '0') && (arg <= '9'))
      return 1;
   else
      return 0;

}  /* mb_isdigit */


int mb_isxdigit (int arg)
{
   if (((arg >= '0') && (arg <= '9')) ||
       ((arg >= 'A') && (arg <= 'F')) ||
       ((arg >= 'a') && (arg <= 'f')))
      return 1;
   else
      return 0;

}  /* mb_isxdigit */


int mb_isprint (int arg)
{
   if ((arg >= 0x20) && (arg <= 0x7e))
      return 1;
   else
      return 0;

}  /* mb_isprint */


int mb_isspace (int arg)
{
   if ((arg == ' ' ) ||    /* <space> */
       (arg == 0x09) ||    /* <tab> */
       (arg == 0x0a) ||    /* <lf>  */
       (arg == 0x0b) ||    /* <vt>  */
       (arg == 0x0c) ||    /* <ff>  */
       (arg == 0x0d))      /* <cr>  */
      return 1;
   else
      return 0;

}  /* mb_isspace */

/* -FF-  */


/* Modification History */
/* 15.01.93 - file erzeugt */
/* 04.07.94 - mb_isspace */
/* 05.07.94 - mb_isspace (): 0x0b + 0x0c */
