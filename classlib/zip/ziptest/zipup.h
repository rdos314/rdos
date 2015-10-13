/*
  win32/zipup.h - Zip 3

  Copyright (c) 1990-2007 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2007-Mar-4 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, all these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
#  include <share.h>

#define fhow         (O_RDONLY|O_BINARY)
#define fbad         (-1)
typedef int          ftype;

#define zopen(n,p) sopen(n,p,SH_DENYNO)
#define zwopen(n,p) _wsopen(n,p,_SH_DENYNO)

#define zread(f,b,n) read(f,b,n)
#define zclose(f)    close(f)
#define zerr(f)      (k == (extent)(-1L))
#define zstdin       0
