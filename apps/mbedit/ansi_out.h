
/*--------------------------------------------------------------------------*/

#if (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
#define WIN_NT_BASTELVERSION
#endif

#if defined(WIN_NT_BASTELVERSION)

int ansi_printf(char *, ...);
int ansi_putchar(int);
int printd(char *, ...);
void get_screen_lin_col (int *lines, int *columns);

/*--------------------------------------------------------------------------*/

#define   printf       ansi_printf

#undef    putchar
#define   putchar(c)   ansi_putchar(c)

#endif

/*--------------------------------------------------------------------------*/
/* 28.10.03 - comment characters "//" replaced by "/*" */
