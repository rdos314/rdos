/*      calc_var.h                                  23.05.96       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for calc_var.c (function prototypes)
/
*/


/************************/
/* structures           */
/************************/

struct CALC_VARS {               /* X = implemented in MBEDIT */
                                 /* - = dummy value */
                                 /* N = new   value */

                  int  bof;      /* X  begin of file */

                  long cntexe;   /* X  macro execution */
                  int  cntfnd;   /* X  no of "(-)Find" */
                  long cntmac;   /* X  macro completed */
                  int  cntrep;   /* X  no of "(?)Replace" */

                  int  col;      /* X  current column (in file) */
                  byte curch;    /* X  current character */
                  long curpos;   /* X  current position in file */
                  word curwd;    /* X  current word */

                  long date;     /* X  (mm*10000 + dd)*100 + yy) */
                  int  eof;      /* X  end of file */
                  int  imargn;   /* -  indent margin */
                  int  inothr;   /* X  MBEDIT: no of file: (0...n) */

                  int  isdel;    /* X  current character is delimiter */
                  int  iswhte;   /* X  current character is white space
                                           = <space>, <tab>, <cr>, <lf> */

                  long linact;   /* N  actual line no    */
                  long lintot;   /* N  total no of lines */

                  int  lmargn;   /* -  left margin */
                  byte lowch;    /* X  = tolower (curch) */

                  int  lstfnd;   /* X  last Find command successful */
                  int  nstlvl;   /* X  macro nesting level */

                  byte nxtch;    /* X  next char */
                  int  nxttab;   /* X  next tab position */
                  word nxtwd;    /* X  next word */
                  int  rmargn;   /* -  right margin */
                  int  row;      /* X  current row (in file) */

                  char *sb;      /* X  string block buffer */
                  char *sd;      /* X  string delimiter */
                  char *se;      /* X  string edit  file */
                  char *sg;      /* X  string get   file */
                  char *si;      /* X  string input file */
                  char *sm;      /* X  string macro file */
                  char *so;      /* X  string other file */
                  char *sp;      /* X  string put   file */
                  char *sr;      /* X  string "Replace"  */
                  char *st;      /* X  string "Find"     */
                  char *sw;      /* X  string write file */
                  char *sy;      /* X  syntax highlighting file */

                  long taga;     /* X  offset of tag A */
                  long tagb;     /* X  offset of tag B */
                  long tagc;     /* X  offset of tag C */
                  long tagd;     /* X  offset of tag D */

                  long time;     /* X  (hh*10000 + mm)*100 + ss) */
                  byte upch;     /* X  = toupper (curch) */
                 };


/************************/
/* often used macros    */
/************************/


/************************/
/* often used defines   */
/************************/


/************************/
/*  forward references  */
/************************/

/* file: calc_var.c */

extern void get_calc_variables (struct CALC_VARS * calc_vars);


/************************/
/*  public variables    */
/************************/


/* Modification History */
/* 24.01.93 - file erzeugt */
/* 12.08.93 - kommentar korrigiert */
/* 23.05.96 - linact, lintot */
/* 19.08.97 - SD (string delimiter) */
