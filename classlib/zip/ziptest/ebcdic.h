/*
  ebcdic.h

  Copyright (c) 1990-2005 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2005-Feb-10 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, both of these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/licen
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

#endif /* __ebcdic_h  */
