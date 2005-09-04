/*  calcevar.c                                        25.10.96
**
**  integer calculator  
**  
**    handle external readonly and string vars
**  
**  
*/


#include "config.h"
#include "standard.h"
#include "microsft.h"

#include "calc.h"
#include "calchlp.h"
#include "calc_var.h"


#undef EOF      /* get rid of exessive includes */

enum RO_VAR_TOKEN {
        SLB, SLD, SLE, SLG, SLI, SLM, SLO, SLP, SLR, SLT, SLW, SLENX,
        BOF, CNTEXE, CNTFND, CNTMAC, CNTREP, COL, CURCH, CURPOS,
        CURWD, DATE, EOF, IMARGN, INOTHR, ISDEL, ISWHTE, LINACT, LINTOT,
        LMARGN, LOWCH, LSTFND, NSTLVL, NXTCH, NXTTAB, NXTWD, RMARGN, ROW,
        TAGA, TAGB, TAGC, TAGD, TIME, UPCH };

enum STRING_TOKEN { SB, SD, SE, SG, SI, SM, SO, SP, SR, ST, SW, STRX };

/*@@info: Obige Liste wurde mit <Set><Margin>"0,8,76",<Paragraph><Fill> 
          erstellt */

struct EXTERN_VARS
{
  char * name;
  enum RO_VAR_TOKEN token;
};

/************************/
/*  public variables    */
/************************/

struct EXTERN_VARS _ro_vars[] =
{
   { "SL0",     SLENX },
   { "SL1",     SLENX },
   { "SL2",     SLENX },
   { "SL3",     SLENX },
   { "SL4",     SLENX },
   { "SL5",     SLENX },
   { "SL6",     SLENX },
   { "SL7",     SLENX },
   { "SL8",     SLENX },
   { "SL9",     SLENX },
   { "SLB",     SLB },
   { "SLD",     SLD },
   { "SLE",     SLE },
   { "SLG",     SLG },
   { "SLI",     SLI },
   { "SLM",     SLM },
   { "SLO",     SLO },
   { "SLP",     SLP },
   { "SLR",     SLR },
   { "SLT",     SLT },
   { "SLW",     SLW },

   { "BOF",    BOF },
   { "CNTEXE", CNTEXE },
   { "CNTFND", CNTFND },
   { "CNTMAC", CNTMAC },
   { "CNTREP", CNTREP },
   { "COL",    COL },
   { "CURCH",  CURCH },
   { "CURPOS", CURPOS },
   { "CURWD",  CURWD },
   { "DATE",   DATE },
   { "EOF",    EOF },
   { "IMARGN", IMARGN },
   { "INOTHR", INOTHR },
   { "ISDEL",  ISDEL },
   { "ISWHTE", ISWHTE },
   { "LINACT", LINACT },
   { "LINTOT", LINTOT },
   { "LMARGN", LMARGN },
   { "LOWCH",  LOWCH },
   { "LSTFND", LSTFND },
   { "NSTLVL", NSTLVL },
   { "NXTCH",  NXTCH },
   { "NXTTAB", NXTTAB },
   { "NXTWD",  NXTWD },
   { "RMARGN", RMARGN },
   { "ROW",    ROW },
   { "TAGA",   TAGA },
   { "TAGB",   TAGB },
   { "TAGC",   TAGC },
   { "TAGD",   TAGD },
   { "TIME",   TIME },
   { "UPCH",   UPCH }
};

struct EXTERN_VARS _string_vars[] =
{
   { "S0",     STRX },
   { "S1",     STRX },
   { "S2",     STRX },
   { "S3",     STRX },
   { "S4",     STRX },
   { "S5",     STRX },
   { "S6",     STRX },
   { "S7",     STRX },
   { "S8",     STRX },
   { "S9",     STRX },
   { "SB",     SB },
   { "SD",     SD },
   { "SE",     SE },
   { "SG",     SG },
   { "SI",     SI },
   { "SM",     SM },
   { "SO",     SO },
   { "SP",     SP },
   { "SR",     SR },
   { "ST",     ST },
   { "SW",     SW }
};

/* Wie das hier funktioniert, weiss auch nur HDS ! */
static char numbered_strings [10][BUF_256];

/*
**  return value of readonly variable 
*/
VAR_T ro_var_val(VAR_T idx)
{
  static struct CALC_VARS ext_vars;
  union RESULT result = {0};

  get_calc_variables (&ext_vars);
  
  switch (_ro_vars[idx].token)
  {
    case SLB :
      result.val = strlen (ext_vars.sb);
      break;
    case SLD :
      result.val = strlen (ext_vars.sd);
      break;
    case SLE :
      result.val = strlen (ext_vars.se);
      break;
    case SLG :
      result.val = strlen (ext_vars.sg);
      break;
    case SLI :
      result.val = strlen (ext_vars.si);
      break;
    case SLM :
      result.val = strlen (ext_vars.sm);
      break;
    case SLO :
      result.val = strlen (ext_vars.so);
      break;
    case SLP :
      result.val = strlen (ext_vars.sp);
      break;
    case SLR :
      result.val = strlen (ext_vars.sr);
      break;
    case SLT :
      result.val = strlen (ext_vars.st);
      break;
    case SLW :
      result.val = strlen (ext_vars.sw);
      break;
    case SLENX :
        /*@@ more intelligent will be dynamic allocation */
      result.val = strlen (numbered_strings[idx]);
      break;

    case BOF :
      result.val = ext_vars.bof;   
      break;
    case CNTEXE :
      result.val = ext_vars.cntexe;
      break;
    case CNTFND :
      result.val = ext_vars.cntfnd;
      break;
    case CNTMAC :
      result.val = ext_vars.cntmac;
      break;
    case CNTREP :
      result.val = ext_vars.cntrep;
      break;
    case COL :
      result.val = ext_vars.col;   
      break;
    case CURCH :
      result.val = ext_vars.curch; 
      break;
    case CURPOS :
      result.val = ext_vars.curpos;
      break;
    case CURWD :
      result.val = ext_vars.curwd; 
      break;
    case DATE :
      result.val = ext_vars.date;  
      break;
    case EOF :
      result.val = ext_vars.eof;   
      break;
    case IMARGN :
      result.val = ext_vars.imargn;
      break;
    case INOTHR :
      result.val = ext_vars.inothr;
      break;
    case ISDEL :
      result.val = ext_vars.isdel; 
      break;
    case ISWHTE :
      result.val = ext_vars.iswhte;
      break;
    case LINACT :
      result.val = ext_vars.linact + 1;
      break;
    case LINTOT :
      result.val = ext_vars.lintot + 1;
      break;
    case LMARGN :
      result.val = ext_vars.lmargn;
      break;
    case LOWCH :
      result.val = ext_vars.lowch; 
      break;
    case LSTFND :
      result.val = ext_vars.lstfnd;
      break;
    case NSTLVL :
      result.val = ext_vars.nstlvl;
      break;
    case NXTCH :
      result.val = ext_vars.nxtch; 
      break;
    case NXTTAB :
      result.val = ext_vars.nxttab;
      break;
    case NXTWD :
      result.val = ext_vars.nxtwd; 
      break;
    case RMARGN :
      result.val = ext_vars.rmargn;
      break;
    case ROW :
      result.val = ext_vars.row;   
      break;
    case TAGA :
      result.val = ext_vars.taga;  
      break;
    case TAGB :
      result.val = ext_vars.tagb;  
      break;
    case TAGC :
      result.val = ext_vars.tagc;  
      break;
    case TAGD :
      result.val = ext_vars.tagd;  
      break;
    case TIME :
      result.val = ext_vars.time;  
      break;
    case UPCH  :
      result.val = ext_vars.upch;  
      break;
  }
  return (result.val);
  
} /* ro_var_val */

/*
**  read readonly variable's name
*/
VAR_T get_ro_var(int length)
{
   int ii;

   for (ii = 0; ii < lengthof(_ro_vars); ii++)
     if (length == (int)strlen(_ro_vars[ii].name))
       if (strnicmp(expr_ptr, _ro_vars[ii].name, length) == 0)
       { /* --  found it */
         advance(length); /* and eat it */
         return ((VAR_T)ii);
       }
       
   return((VAR_T)-1);
} /* get_ro_var */


/*
**  return pointer to string variable 
*/
STR_T str_var_ptr(VAR_T idx)
{
  static struct CALC_VARS ext_vars;
  union RESULT result;

  result.str = str_expr;
  if ((idx > -1) && (idx < lengthof(_string_vars)))
  {
    get_calc_variables (&ext_vars);
    
    switch (_string_vars[idx].token)
    {
      case SB :
        result.str = ext_vars.sb;
        break;
      case SD :
        result.str = ext_vars.sd;
        break;
      case SE :
        result.str = ext_vars.se;
        break;
      case SG :
        result.str = ext_vars.sg;
        break;
      case SI :
        result.str = ext_vars.si;
        break;
      case SM :
        result.str = ext_vars.sm;
        break;
      case SO :
        result.str = ext_vars.so;
        break;
      case SP :
        result.str = ext_vars.sp;
        break;
      case SR :
        result.str = ext_vars.sr;
        break;
      case ST :
        result.str = ext_vars.st;
        break;
      case SW :
        result.str = ext_vars.sw;
        break;
      case STRX :
        /*@@ more intelligent will be dynamic allocation */
        result.str = numbered_strings[idx];
        break;
    }
  }
  return (result.str);
  
} /* str_var_ptr */

/*
**  read string variable's name
*/
VAR_T get_str_var(int length)
{
   int ii;

   for (ii = 0; ii < lengthof(_string_vars); ii++)
     if (length == (int)strlen(_string_vars[ii].name))
       if (strnicmp(expr_ptr, _string_vars[ii].name, length) == 0)
       { /* --  found it */
         advance(length); /* and eat it */
         return ((VAR_T)ii);
       }
       
   return((VAR_T)-1);
   
} /* get_str_var */


/* Modification History */
/* 02.01.94 - bugfix: "UPCH" anstatt "UPCH " */
/* 23.05.96 - linact, lintot */
/* 25.10.96 - SLx (string length x, with x = 0...9, or second letter of */
/*                                           read only string variable) */
/* 19.08.97 - SD (string delimiter) */
