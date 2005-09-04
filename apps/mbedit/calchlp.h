/*  calchlp.h                                         24.08.90
**  
**  conversion header
**    for calculator
**
*/

#undef PUBEXT
#ifdef __CALC__
#define PUBEXT
#else
#define PUBEXT extern
#endif

#undef FALSE
#undef TRUE

#define FALSE   0
#define TRUE    (!FALSE)

#define MAX_LONG  0x7FFFFFFF

#define iswhite(c)      (((c)==' ')||((c)=='\t'))

/* pointer to actual pos in expression */
PUBEXT  char * expr_ptr; 
#define advance(amt)  (expr_ptr+=(amt))  

PUBEXT  char str_expr[BUF_256]; /* temporary buffer for string expressions */

enum OPERAND_TYPE { NONE = 0, DEC, HEX, VAR, CHAR, STR };


/* MODULE CALCROV:
*/

extern VAR_T ro_var_val(VAR_T idx);
  /* --  return value of readonly variable */

extern VAR_T get_ro_var(int length);
  /* --  read readonly variable's name */

extern STR_T str_var_ptr(VAR_T idx);
  /* --  return pointer to string variable */

extern VAR_T get_str_var(int length);
  /* --  read string variable's name */


/* MODULE CALCHLP: 
*/

extern void prints(char * s);
  /*  print string w/o newline */

extern void printld(long val);
  /*  print long decimal */

extern void printlx(unsigned long val);
  /*  print long hex */

extern char * rtrim(char * s);
  /*  kill trailing white spaces */

extern char * skipwhites(char * s);
  /*  skip leading white spaces */

extern int wordlen(char * s, char * delimiter);
  /*  report distance to delimiter */

extern int strlcmp(char * s, char * op);
  /*  compare strings (returns: matching length)*/

extern int digit(int d);
  /*  convert decimal ascii to binary */

extern int xdigit(int x);
  /*  convert hex ascii to binary */
