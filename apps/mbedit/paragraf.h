/*      paragraf.h                                    06.10.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    ausgelagerte functions von mbedit.c
/
/     header file for paragraf.c
/
*/


/************************/
/* function prototypes  */
/************************/

extern long search_slope (int slope_type, int direction);
extern int  para_boundaries (void);
extern void para_set_spaces (void);
extern void para_shift_line (int delta);
extern int  para_fill (void);
extern int  para_justify (void);


/************************/
/* local structures     */
/************************/

/* -FF-  */

/* Modification History */
/* 06.10.93 - file erzeugt */
