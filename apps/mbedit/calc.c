/*  calc.c                                              06.08.02
**
**  integer calculator  
**  
**    library module v2.0
**  
**  
*/


#include "config.h"
#include "standard.h"
#include "microsft.h"
#include "mb_ctype.h"

#undef toupper
#undef tolower
#undef isdigit
#undef isxdigit
#undef isprint
#undef isspace

#include <ctype.h>

#define  __CALC__

#include "calc.h"
#include "calchlp.h"
#include "ansi_out.h"


/**************************************************************
*                                                             *
*                  DEBUG SECTION                              *
*                                                             *
**************************************************************/

#if DEBUG
#define ON_DEB(c)   c
#define D_MSG(f,a)  if (trace) printf("%2d %2d%*s ", nest, level, nest, ""), printf(f,a,a)
#else
#define ON_DEB(c)
#define D_MSG(f,a)
#endif

static char eval_msg[]       = "Evaluate : ";
#if DEBUG
static char fmt_term[]       = "";
static char fmt_expression[] = "Expression \"%s\"\n";
static char fmt_operand[]    = "Operand    \"%s\"\n";
static char fmt_token[]      = "  Token  => \"%s\"\n";
static char fmt_number[]     = "  Number => %ld %lXh\n";
static int  nest;
#endif


/**************************************************************
*                                                             *
*                  DATA SECTION                               *
*                                                             *
**************************************************************/

/*
**  operand delimiters
*/
char delimiter [] = " \t(){}[]!~*/%+-<>=&^|;:,\\\"?@#$";

/*
**  error handling
**
**    1.  remember error number and position
**    2.  avoid multible error outputs
**    3.  call user's error handler
**
*/
struct ERROR {
  char * ptr;                       /* pointer to error position in expr */
  int    no;                        /* error number */
};

static  enum RESULT_TYPE expr_type; /* type of expression  */
static  int expr_err;               /* boolean expression error */
static  struct ERROR error_report;  /* error to report */

static  int level;                  /* parenthese nesting level */

enum TOKEN                          /* symbolic token is index in array(s) */
{
  PAREN,  NOT,    CMPL,   PWR,    MUL,    DIV,    MOD,    MODULO,
  PLUS,   MINUS,
  SL,     SR,     SAL,    SAR,    SHL,    SHR,    ROL,    ROR,    
  LE,     LEQ,    GT,     GEQ,    EQ,     UNEQ,   UNEQU,  AND,    XOR,    OR,
  LAND,   LOR,    ASSIGN, MULASS, DIVASS, MODASS, ADDASS, SUBASS, SALASS,
  SARASS, ANDASS, XORASS, ORASS,  CLPAR,  EOEXPR, INVAL,  OP_NUM
};

/*
**  unary operators
**
**    precedence:     equal
**    associativity:  right to left
**
**  operators
**
**    precedence:     table
**    accociativity:  left to right
**
*/
#define UNARY   0x01
#define NORM    0x02
#define ALL     (NORM | UNARY)

#define OP_MAXL 3

struct OPERATORS
{
  char  lexeme [OP_MAXL+1];
  char  use;
  char  precedence;
}
operators [OP_NUM] =
{
/*lexeme use    p    lexeme use    p    lexeme use    p    lexeme use    p */
  "(",   UNARY, 0,
  "!",   UNARY, 1,   "~",   UNARY, 1,
  "**",  NORM,  2,
  "*",   NORM,  3,   "/",   NORM,  3,   "%",   NORM,  3,   "\\",  NORM,  3,
  "+",   ALL,   4,   "-",   ALL,   4,
  "<<",  NORM,  5,   ">>",  NORM,  5,   "SAL", NORM,  5,   "SAR", NORM,  5,
  "SHL", NORM,  5,   "SHR", NORM,  5,   "ROL", NORM,  5,   "ROR", NORM,  5,   
  "<",   NORM,  6,   "<=",  NORM,  6,   ">",   NORM,  6,   ">=",  NORM,  6,
  "==",  NORM,  7,   "!=",  NORM,  7,   "<>",  NORM,  7,
  "&",   NORM,  8,
  "^",   NORM,  9,
  "|",   NORM,  10,
  "&&",  NORM,  11,
  "||",  NORM,  12,
  "=",   NORM,  13,  "*=",  NORM,  13,  "/=",  NORM,  13,  "%=",  NORM,  13,
  "+=",  NORM,  13,  "-=",  NORM,  13,  "<<=", NORM,  13,  ">>=", NORM,  13,
  "&=",  NORM,  13,  "^=",  NORM,  13,  "|=",  NORM,  13,
  ")",   ALL,   14,
  ";",   NORM,  15,
  "",    ALL,   16
};


/**************************************************************
*                                                             *
*                  ERRORS                                     *
*                                                             *
**************************************************************/

static void error(int err)
{
  if (!expr_err)
  {
    error_report.no = err;
    error_report.ptr = expr_ptr;
    expr_err = TRUE;
  }
}


/**************************************************************
*                                                             *
*                  EVALUATE                                   *
*                                                             *
**************************************************************/

static VAR_T eval_term(enum TOKEN token, VAR_T op1, VAR_T op2)
{
  D_MSG(fmt_term, 0);
  if (trace)
    prints(eval_msg),
      printld(op1), prints(operators[token].lexeme), printld(op2);

  switch (token)
  {
    case NOT:     op1 = !op2;
                  break;

    case CMPL:    op1 = ~op2;
                  break;

    case PWR   :  {
                    VAR_T help = 1;
                    if(op2 < 0)
                      while(op2++) help /= op1;
                    else
                      while(op2--) help *= op1;
                    op1 = help;
                  }
                  break;

    case MUL   :  op1 *= op2;
                  break;

    case DIV   :  if (op2 == 0L)
                    op1 = MAX_VAL, error(DIV_BY_ZERO);
                  else
                    op1 /= op2;
                  break;

    case MODULO:  
    case MOD   :  if (op2 == 0L)
                    op1 = 0;
                  else
                    op1 %= op2;
                  break;

    case PLUS  :  op1 += op2;
                  break;

    case MINUS :  op1 -= op2;
                  break;

    case SL    :
    case SAL   :  op1 <<= op2;
                  break;

    case SR    :
    case SAR   :  op1 >>= op2;
                  break;

    case ROL   :  op1 = _lrotl((unsigned long)op1,(int)op2);
                  break;

    case ROR   :  op1 = _lrotr((unsigned long)op1,(int)op2);
                  break;

    case SHL   :  op1 = (unsigned long)op1 << op2;
                  break;

    case SHR   :  op1 = (unsigned long)op1 >> op2;
                  break;

    case LE    :  op1 = op1 < op2;
                  break;

    case LEQ   :  op1 = op1 <= op2;
                  break;
                  
    case GT    :  op1 = op1 > op2;
                  break;

    case GEQ   :  op1 = op1 >= op2;
                  break;

    case EQ    :  op1 = op1 == op2;
                  break;

    case UNEQU :
    case UNEQ  :  op1 = op1 != op2;
                  break;

    case AND   :  op1 &= op2;
                  break;

    case XOR   :  op1 ^= op2;
                  break;

    case OR    :  op1 |= op2;
                  break;

    case LAND  :  op1 = op1 && op2;
                  break;

    case LOR   :  op1 = op1 || op2;
                  break;

    case ASSIGN:  op1 = op2;
                  break;

    case MULASS:  op1 *= op2;
                  break;

    case DIVASS:  if (op2 == 0L)
                    op1 = MAX_VAL, error(DIV_BY_ZERO);
                  else
                    op1 /= op2;
                  break;

    case MODASS:  if (op2 == 0L)
                    op1 = 0;
                  else
                    op1 %= op2;
                  break;

    case ADDASS:  op1 += op2;
                  break;

    case SUBASS:  op1 -= op2;
                  break;

    case SALASS:  op1 <<= op2;
                  break;

    case SARASS:  op1 >>= op2;
                  break;

    case ANDASS:  op1 &= op2;
                  break;

    case XORASS:  op1 ^= op2;
                  break;

    case ORASS:   op1 |= op2;
                  break;

    case EOEXPR:  
    case CLPAR :  op2 = 0;
                  break;
  }               
  if (trace)
    prints(" = "), printld(op1), putchar('\n');
  return (op1);
}


/**************************************************************
*                                                             *
*                  OPERATOR / TOKEN                           *
*                                                             *
**************************************************************/

/*
**  find operator
**
**    returns:
**      token of matching operator
*/
static int find_operator(char * s, int mask)
{
  int ll, token = 0, lmatch = 0, match = INVAL;
      
  while (token < OP_NUM)
  {
    if (operators[token].use & mask)
      if ((ll = strlcmp(s, operators[token].lexeme)) > lmatch)
      {
        lmatch = ll, match = token;
      }
    token++;
  }
  return (match);
}

/*
**  report if end of expression
*/
static int end_of_expr(int token)
{
  return ((token == EOEXPR) || (token == INVAL));
}

/*
**  report if end of parenthesed expression
*/
static int end_of_paren(int token)
{
  return ((token == CLPAR) || (token == EOEXPR) || (token == INVAL));
}

/*
**  report precedence of operators
**
**    returns:
**      -1  oper1 < oper2
**       0  oper1 = oper2
**       1  oper1 > oper2
*/
static int precedence(int tk1, int tk2)
{
  /* --  special cases: */
  if (end_of_paren(tk1))
    /* --  evaluate unconditionally */
    return (1);

  if ((tk1 == PWR) && (tk2 == PWR))
    /* --  evaluate right to left */
    return (-1);
  
  /* --  return precedence difference */
  return (operators[tk2].precedence - operators[tk1].precedence);
}


/**************************************************************
*                                                             *
*                  PARSING OPERATORS                          *
*                                                             *
**************************************************************/

/*
**  report next token in string
*/
static int look_token(int * token, int mask)
{
  char str [OP_MAXL+1];
  int ll;

  if (!*(expr_ptr = skipwhites(expr_ptr)))
    *token = EOEXPR; /* end of expression string */
  else
  {
    for (ll=0; (ll < OP_MAXL); ll++)
      str[ll] = (char)toupper(expr_ptr[ll]);
    str[ll] = '\0';

    *token = find_operator(str, mask);
  }
  ON_DEB( if (*operators[*token].lexeme)
            D_MSG(fmt_token, operators[*token].lexeme));
  
  return (strlen(operators[*token].lexeme));
}

/*
**  parse token from string
**
**    returns:
**      token,
**      pointer behind operator in expr
*/
static int get_token(int * token, int mask)
{
  int ll = look_token(token, mask);
  if (*expr_ptr)
    advance(ll);
  return (ll);
}


/**************************************************************
*                                                             *
*                  PARSING NUMBERS                            *
*                                                             *
**************************************************************/

/*
**  read decimal constant
*/
long get_decimal(int length)
{
  long val = 0;

  while(length-- && isdigit(*expr_ptr))
    if ((val = 10*val + digit(*expr_ptr++)) > MAX_VAL)
      error(NUM_OVERFL), length = 0;
                    
  if (length >= 0)
    error(NOT_NUMBER);

  return (val);
}

/*
**  read hexadecimal constant
*/
unsigned long get_hex(int length, int type)
{
  unsigned long val = 0;

  while ((length > 1) && (*expr_ptr == '0')) expr_ptr++, length--;
  if (length <= 8)
    while (length-- && isxdigit(*expr_ptr))
      val = 16*val + xdigit(*expr_ptr++);
  else
    error(NUM_OVERFL);

  if (length >= 0)
    error(NOT_NUMBER);
  else
    advance(type); /* --  skip 'h' if appended */

  return (val);
}

/*
**  read variable's name
*/
VAR_T get_var(int length)
{
  char var_name[VARNAME_LEN+1];
  int ii;

  strncpy(var_name, expr_ptr, length), var_name[length]='\0';
  advance(length);

  /* --  scan if name exists */
  for (ii = 0; ii < NUM_VARS; ii++)
    if (stricmp(var_name, _var_name[ii]) == 0)
      break; /* -- found it */

  if (ii >= NUM_VARS)
  {
    /* --  scan if any var unassigned */
    for (ii = 0; ii < NUM_VARS; ii++)
      if (!*_var_name[ii])
      {
        /* --  assign variable */
        strcpy(_var_name[ii],strupr(var_name));
        _var[ii] = 0L;
        break; /* -- exit loop */
      }
  }
  if (ii >= NUM_VARS)
    error (VAR_OVERFL);
  
  return((VAR_T)ii);
}

static void var_cleanup(void)
{
  int ii;

  for (ii = 0; ii < NUM_VARS; ii++)
  {
    if (!_var[ii])
      /* --  assigning zero kills variable */
      *_var_name[ii] = '\0';
  }
}

/*
**  parse number from string
**
**    returns:
**      type of operand,
**      number,
**      increments expression pointer 
*/
static enum OPERAND_TYPE get_operand(union RESULT * operand)
{
  int length;
  enum OPERAND_TYPE type = NONE;
  long val = 0;

  if (!*(expr_ptr = skipwhites(expr_ptr)))
    return (type);
  
  if ((length = wordlen(expr_ptr, delimiter)) != 0)
  {
    /* --  analyse operand */

    if (isdigit(*expr_ptr))
    {
      if ((length > 2) &&
          (expr_ptr[0] == '0') && (expr_ptr[1] == 'x') && isxdigit(expr_ptr[2]))
      {
        /* --  c-like hex "0x..." */
        type = HEX;
        advance(2);
        val = get_hex(length-2, 0);
      }
      else if ((length > 1) &&
               (tolower(expr_ptr[length-1]) == 'h'))
      {
        /* --  plm-like hex "[0-9]...h" */
        type = HEX;
        val = get_hex(length-1, 1);
      }
      else
      {
        /* --  decimal "[0-9]..." */
        type = DEC;
        val = get_decimal(length);
      }
    }
    else
    {
      if ((expr_ptr[0] == '\"') && (expr_ptr[length-1] == '\"'))
      {
        /* --  string ""<string>"" */
        type = STR, val = -1;
        advance(1);
        strncpy(str_expr, expr_ptr, length-2);
        str_expr[length-2] = '\0';
        advance(length-1);
      }
      else if ((length == 3) &&
               (expr_ptr[0] == '\'') && (expr_ptr[length-1] == '\''))
      {
        /* --  character "'<char>'" */
        type = CHAR;
        advance(1);
        val = *expr_ptr;
        advance(2);
      }
      else if (isalpha(expr_ptr[0]) || (expr_ptr[0] == '_'))
      {
        /* --  variables "[<alpha>,'_']..." */
        if (length <= VARNAME_LEN)
        {
          /* 1. try string variable */
          val = get_str_var(length); 
  
          if (val >= 0) type = STR; 
          else
          {
            /* 2. try readonly variable */
            val = get_ro_var(length);
  
            if (val >= 0) type = DEC, val = ro_var_val(val);
            else 
            {
              /* 3. try dynamic variable */
              type = VAR, val = get_var(length);
            }
          }
        }
        else
          error(ID_LENGTH), advance(length);
      }
      else
        error(INVAL_SYMBOL);
    }
  	/* --  overwrite type if error */
    if (expr_err)
      type = NONE;
  }
  else
    error(INVAL_EXPR);

  /* --  if ok return value */
  if (type != NONE)
  {
    operand->val = val;
    D_MSG(fmt_number, val);
  }
  return (type);
}


/**************************************************************
*                                                             *
*                  EVALUATE EXPRESSION                        *
*                                                             *
**************************************************************/

static int eval_operand(union RESULT * operand);
static int eval_expr(union RESULT * operand);

/*
**  evaluate operand
**
**    Evaluates one operand term regarding unary operators
**      and parentheses, also does assigments to lvalues
**
**    returns:
**      TRUE if operand available,
**      increments expression pointer 
*/
static int eval_operand(union RESULT * operand)
{
  int token;
  int success = FALSE;

  ON_DEB(++nest);
  D_MSG(fmt_operand, expr_ptr);

  if (get_token(&token, UNARY))
  {
    /* --  not a number */ 
    if (token == PAREN)
    {
      /* --  evaluate expression in parentheses */
      ++level;
      if (eval_operand(operand))
      {
        look_token(&token, UNARY);
        /* --  test for simply operand in parentheses */
        if (token != CLPAR)
          /* --  evaluate expression */
          while (!end_of_paren(token = eval_expr(operand))) ;
        if (token == CLPAR)
        {
          /* --  advance behind closing parenthese */
          advance(1);
          --level;
          success = TRUE;
        }
        else
          error(UNBAL_PAREN);
      }
      else
        error(INVAL_EXPR);
    }
    else if (!end_of_expr(token) && eval_operand(operand))
    {
      /* --  evaluate unary expession */
      operand->val = eval_term(token, 0L, operand->val);
      success = TRUE;
    }
    else
      error(NOT_CONST);
  }
  else
  {
    switch (get_operand(operand))
    {
      case NONE:
        /* --  error (already set) */
        break;

      case VAR:
        /* --  look next operator */
        look_token(&token, NORM);
        {
          int var_index = (int)operand->val;

          if (precedence(token, ASSIGN) == 0)
          {
            /* --  is an assignment to variable */
            operand->val = _var[var_index];
            if (eval_expr(operand) != INVAL)
            {
              /* --  assign rvalue to lvalue */
              _var[var_index] = operand->val, success = TRUE;
            }
          }
          else
            /* --  return rvalue */
            operand->val = _var[var_index], success = TRUE;
        }
        break;

      case STR :
        /* --  look next operator */
        look_token(&token, NORM);
        {
          int var_index = (int)operand->val;

          if (precedence(token, ASSIGN) == 0)
          {
            /* --  is an assignment to variable */
            if ((eval_expr(operand) != INVAL) && (expr_type == STRING))
            {
              /* --  assign rvalue to lvalue */
              strcpy(str_var_ptr((VAR_T)var_index), operand->str), success = TRUE;
            }
            else
              error(INVAL_EXPR);
          }
          else
            /* --  return rvalue */
            operand->str = str_var_ptr((VAR_T)var_index), success = TRUE;
        }
        expr_type = STRING;
        break;

      default:
        /* --  look next operator */
        look_token(&token, NORM);

        if (token == ASSIGN)
          error(NOT_LVALUE);
        else 
          success = TRUE;
        break;
    }
  }
  ON_DEB(--nest);
  return (success);
}


/*
**  evaluate expression
**
**    Evaluates all terms of equal and higher precedence
**
*/
static int eval_expr(union RESULT * operand)
{
  int token, next_token = 0;
  union RESULT next_operand;
  int preced = 0;

  next_operand.val = 0L;

  ON_DEB(++nest);
  do
  {
    D_MSG(fmt_expression, expr_ptr);

    /* --  get actual operator */
    if (get_token(&token, NORM))
    {
      /* --  end of expression (also closing parenthese) breaks loop */
      if (!end_of_paren(token))
      {
        /* --  get second operand */
        if (eval_operand(&next_operand))
        {
          /* --  look next operator */
          look_token(&next_token, NORM);
          if (next_token == INVAL)
            error(INVAL_SYMBOL);
        }
        else
          error(INVAL_EXPR);
      }
      else if (token == CLPAR)
        /* --  unbalanced parentheses */
        advance(-1), error(UNBAL_PAREN);
      else
        /* -- set value to return */
        next_token = token;

      if (!expr_err)
      {
         while ((preced = precedence(token, next_token)) < 0)
           /* --  next operator preceds actual: evaluate next expression */
           next_token = eval_expr(&next_operand);
   
         /* --  evaluate actual term */
         operand->val = eval_term(token, operand->val, next_operand.val);
      }
    }
    else
      error(INVAL_SYMBOL);
  }
  /* --  for all terms w/ equal or higher precedence */
  while (!expr_err && (preced <= 0));

  ON_DEB(--nest);
  if (expr_err)
    return (INVAL);
  else
    return(next_token);
}


/**************************************************************
*                                                             *
*                  GLOBAL ROUTINE                             *
*                                                             *
**************************************************************/

/*
**  evaluate total expression
**
**    on entry: pointer to expression string,
**                pointer to error handler
**    on exit:  if error occured
**                calls error handler
**
**    returns:
**      result of expression
**
*/
CALC_RESULT * evaluate (char * expr, CALC_RESULT * result,
                        void (*error)(char * errpos, int err))
{
  expr_err = FALSE;
  expr_type = VALUE;
  level = 0;

  /* --  set expression pointer and kill trailing spaces */
  rtrim(expr_ptr = expr);

  /* --  evaluate first operand */
  if (eval_operand(&result->item))
    /* --  and expand till end of expression */
    while (!end_of_expr(eval_expr(&result->item))) ;

  D_MSG("End of expression  %s\n", expr_ptr);
  
  var_cleanup();

  if (expr_err)
  {
    (*error)(error_report.ptr, error_report.no);
    result->type = ERROR;
  }
  else
  {
    result->type = expr_type;
  }
  return (result);
}

/* Modification History */
/* 23.06.93 - fixed: divide by 0 / modulo by 0 */
/* 05.07.94 - #undef isspace */
/* 06.08.02 - macro D_MSG in one single line (without \) */
