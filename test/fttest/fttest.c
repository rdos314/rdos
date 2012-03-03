/****************************************************************************/
/*                                                                          */
/*  The FreeType project -- a free and portable quality TrueType renderer.  */
/*                                                                          */
/*  Copyright 2002, 2003, 2004, 2005, 2006, 2009 by                         */
/*  D. Turner, R.Wilhelm, and W. Lemberg                                    */
/*                                                                          */
/*  ftbench: bench some common FreeType call paths                          */
/*                                                                          */
/****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <ft2build.h>
#include <freetype.h>
#include <ftglyph.h>
#include <ftcache.h>
#include <ftcache.h>
#include <ftsynth.h>
#include <ftadvanc.h>

#include "rdos.h"

#include "common.h"


FT_Library        lib;
FTC_ImageTypeRec  font_type;
char             *filename;


/*
 * main
 */

FT_Error
get_face( FT_Face*     face )
{
  static unsigned char*  memory_file = NULL;
  static size_t          memory_size;
  int                    face_index = 0;
  FT_Error               error;


  FILE*  file = fopen( filename, "rb" );


  if ( file == NULL )
  {
    fprintf( stderr, "couldn't find or open `%s'\n", filename );

    return 1;
  }

  fseek( file, 0, SEEK_END );
  memory_size = ftell( file );
  fseek( file, 0, SEEK_SET );

  memory_file = (FT_Byte*)malloc( memory_size );
  if ( memory_file == NULL )
  {
    fprintf( stderr, "couldn't allocate memory to pre-load font file\n" );

    return 1;
  }

  if ( fread( memory_file, 1, memory_size, file ) != memory_size )
  {
    fprintf( stderr, "read error\n" );
    free( memory_file );
    memory_file = NULL;

    return 1;
  }
 
  error = FT_New_Memory_Face( lib, memory_file, memory_size, face_index, face );

  if ( error )
    fprintf( stderr, "couldn't load font resource\n");

  return error;
}


int
main(int argc,
     char** argv)
{
  FT_Face     face;
  char*       test_string = NULL;
  int         size = 32;
  int         i, j;
  FT_Glyph    glyph;
  FT_Bitmap  *bitmap;
  int error;
  int bpp;
  int width;
  int height;
  int rowsize;
  char *linear;
  int vbe;
  char *ptr;

  filename = argv[1];

 if ( FT_Init_FreeType( &lib ) )
  {
    fprintf( stderr, "could not initialize font library\n" );

    return 1;
  }
  if ( get_face( &face ) )
    goto Exit;

  if ( FT_IS_SCALABLE( face ) )
  {

    if ( FT_Set_Pixel_Sizes( face, size, size ) )
    {
      fprintf( stderr, "failed to set pixel size to %d\n", size );

      return 1;
    }
  }
  else
    size = face->available_sizes[0].width;

  i = FT_Get_Char_Index( face, 'Ö');

  error = FT_Load_Glyph( face, i, FT_LOAD_DEFAULT );

  error = FT_Render_Glyph( face->glyph, FT_RENDER_MODE_NORMAL );

  bitmap = &face->glyph->bitmap;

  bpp = 24;
  width = 640;
  height = 640;
  
  vbe = RdosSetVideoMode(&bpp, &width, &height, &rowsize, &linear);

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

Exit:
  /* The following is a bit subtle: When we call FTC_Manager_Done, this
   * normally destroys all FT_Face objects that the cache might have created
   * by calling the face requester.
   *
   * However, this little benchmark uses a tricky face requester that
   * doesn't create a new FT_Face through FT_New_Face but simply pass a
   * pointer to the one that was previously created.
   *
   * If the cache manager has been used before, the call to FTC_Manager_Done
   * discards our single FT_Face.
   *
   * In the case where no cache manager is in place, or if no test was run,
   * the call to FT_Done_FreeType releases any remaining FT_Face object
   * anyway.
   */

  FT_Done_FreeType( lib );

  return 0;
}


/* End */
