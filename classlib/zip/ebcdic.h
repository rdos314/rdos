/*
  Copyright (c) 1990-2008 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2000-Apr-09 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/*---------------------------------------------------------------------------

  ebcdic.h

  The CECP 1047 (Extended de-facto EBCDIC) <-> ISO 8859-1 conversion tables,
  from ftp://aix1.segi.ulg.ac.be/pub/docs/iso8859/iso8859.networking

  NOTES:
  <Paul_von_Behren@stortek.com> (OS/390 port 12/97)
   These table no longer represent the standard mappings (for example in the
   OS/390 iconv utility).  In order to follow current standards I remapped
     ebcdic x0a to ascii x15    and
     ebcdic x85 to ascii x25    (and vice-versa)
   Without these changes, newlines in auto-convert text files appeared
   as literal \045.
   I'm not sure what effect this remap would have on the MVS and CMS ports, so
   I ifdef'd these changes.  Hopefully these ifdef's can be removed when the
   MVS/CMS folks test the new mappings.

  Christian Spieler <spieler@ikp.tu-darmstadt.de>, 27-Apr-1998
   The problem mentioned by Paul von Behren was already observed previously
   on VM/CMS, during the preparation of the CMS&MVS port of UnZip 5.20 in
   1996. At that point, the ebcdic tables were not changed since they seemed
   to be an adopted standard (to my knowledge, these tables are still used
   as presented in mainfraime KERMIT). Instead, the "end-of-line" conversion
   feature of Zip's and UnZip's "text-translation" mode was used to force
   correct mappings between ASCII and EBCDIC newline markers.
   Before interchanging the ASCII mappings of the EBCDIC control characters
   "NL" 0x25 and "LF" 0x15 according to the OS/390 setting, we have to
   make sure that EBCDIC 0x15 is never used as line termination.

  ---------------------------------------------------------------------------*/

#ifndef __ebcdic_h      /* prevent multiple inclusions */
#define __ebcdic_h


/*---------------------------------------------------------------------------

  The following conversion tables translate between IBM PC CP 850
  (OEM codepage) and the "Western Europe & America" Windows codepage 1252.
  The Windows codepage 1252 contains the ISO 8859-1 "Latin 1" codepage,
  with some additional printable characters in the range (0x80 - 0x9F),
  that is reserved to control codes in the ISO 8859-1 character table.

  The ISO <--> OEM conversion tables were constructed with the help
  of the WIN32 (Win16?) API's OemToAnsi() and AnsiToOem() conversion
  functions and have been checked against the CP850 and LATIN1 tables
  provided in the MS-Kermit 3.14 distribution.

  ---------------------------------------------------------------------------*/

/* The following pointers to the OEM<-->ISO translation tables are used
   by the translation code portions.  They may get initialized at program
   startup to point to the matching static translation tables, or to NULL
   to disable OEM-ISO translation.
   The compile-time initialization used here provides the backward compatible
   setting, as can be found in UnZip 5.52 and earlier.
   In case this mechanism will ever get used on a multithreading system that
   allows different codepage setups for concurrently running threads, these
   pointers should get moved into UnZip's thread-safe global data structure.
 */

#endif /* __ebcdic_h  */
