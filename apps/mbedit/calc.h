/*  calc.h                                            31.01.93
**  
**  usage header to integer calculator
**
*/
#define DEBUG 1               /* compile w/ debug messages */

#undef PUBEXT
#ifdef __CALC__
#define PUBEXT
#else
#define PUBEXT extern
#endif

PUBEXT int trace;             /* flag for evaluation trace */

enum CALC_ERRORS              /* error codes */
{
  INVAL_SYMBOL, INVAL_EXPR, UNBAL_PAREN, NOT_CONST, NOT_NUMBER, NUM_OVERFL,
  ID_LENGTH, VAR_OVERFL, NOT_LVALUE, DIV_BY_ZERO, NUM_ERR
};

/*
**  defining NUM_VARS global variables
**
**    name of VARNAME_LEN defined dynamically
**
*/
#define VAR_T     long
#define MAX_VAL   MAX_LONG

#define STR_T     char *

#define NUM_VARS      10
#define NUM_STRS      10
#define VARNAME_LEN   6         /* AEDIT default */

PUBEXT char _var_name [NUM_VARS][VARNAME_LEN+1];
PUBEXT VAR_T _var [NUM_VARS];

PUBEXT char _str_var_name [NUM_STRS][VARNAME_LEN+1];
PUBEXT STR_T _str_var [NUM_STRS];

enum RESULT_TYPE { ERROR = -1, VALUE, STRING };

typedef struct 
{
  enum RESULT_TYPE type; 
  union RESULT
  {
    VAR_T val;
    STR_T str;
  } 
  item;
}
 CALC_RESULT;

/*
**  error messages
*/
PUBEXT char *calc_errors[NUM_ERR]
#ifdef __CALC__
  = {
      "Invalid symbol in expression",
      "Invalid expression",
      "Unbalanced parentheses",
      "Not a constant",
      "Not a number",
      "Numeric constant too large",
      "Identifier too long",
      "Too many variables",
      "Assignment to constant",
      "Divide by zero"
    }
#endif
  ;

extern CALC_RESULT * evaluate (char * expr, CALC_RESULT * result,
                               void (*error)(char * str, int err));
  /*  evaluate expression                                                 */
  /*  on entry: pointer to expression string, pointer to result struct    */
  /*            pointer to error handler                                  */
  /*  on exit:  if error occured calls error handler                      */
  /*  returns:  pointer to result of expression                           */

