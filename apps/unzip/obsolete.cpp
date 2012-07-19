
/*****************************/
/* Function UzpMessagePrnt() */
/*****************************/

int  UzpMessagePrnt(void *pG, unsigned char *buf, unsigned long size, int flag)
{
    /* IMPORTANT NOTE:
     *    The name of the first parameter of UzpMessagePrnt(), which passes
     *    the "Uz_Globs" address, >>> MUST <<< be identical to the string
     *    expansion of the __G__ macro in the REENTRANT case (see globals.h).
     *    This name identity is mandatory for the LoadFarString() macro
     *    (in the SMALL_MEM case) !!!
     */
    int error;
    unsigned char *q=buf, *endbuf=buf+(unsigned)size;
    unsigned char *p=buf;
    int islinefeed = FALSE;


/*---------------------------------------------------------------------------
    These tests are here to allow fine-tuning of UnZip's output messages,
    but none of them will do anything without setting the appropriate bit
    in the flag argument of every Info() statement which is to be turned
    *off*.  That is, all messages are currently turned on for all ports.
    To turn off *all* messages, use the UzpMessageNull() function instead
    of this one.
  ---------------------------------------------------------------------------*/


    if (MSG_TNEWLN(flag)) {   /* again assumes writable buffer:  fragile... */
        if ((!size && !((Uz_Globs *)pG)->sol) ||
            (size && (endbuf[-1] != '\n')))
        {
            *endbuf++ = '\r';
            *endbuf++ = '\n';
            ++size;
        }
    }

    /* room for --More-- and one line of overlap: */
    SCREENSIZE(&((Uz_Globs *)pG)->height, &((Uz_Globs *)pG)->width);
    ((Uz_Globs *)pG)->height -= 2;

    if (MSG_LNEWLN(flag) && !((Uz_Globs *)pG)->sol) {
        /* not at start of line:  want newline */
            RdosWriteChar(0xd);
            RdosWriteChar(0xa);
            if (((Uz_Globs *)pG)->M_flag)
            {
                ((Uz_Globs *)pG)->chars = 0;
                ++((Uz_Globs *)pG)->numlines;
                ++((Uz_Globs *)pG)->lines;
                if (((Uz_Globs *)pG)->lines >= ((Uz_Globs *)pG)->height)
                    (*((Uz_Globs *)pG)->mpause)((void *)pG,
                      MorePrompt, 1);
            }
            if (MSG_STDERR(flag) && ((Uz_Globs *)pG)->UzO.tflag &&
                !isatty(1) && isatty(2))
            {
                /* error output from testing redirected:  also send to stderr */
                putc('\n', stderr);
                fflush(stderr);
            }
        ((Uz_Globs *)pG)->sol = TRUE;
    }

    /* put zipfile name, filename and/or error/warning keywords here */

    if (((Uz_Globs *)pG)->M_flag)
    {
        while (p < endbuf) {
            if (*p == '\n') {
                islinefeed = TRUE;
            } else if (SCREENLWRAP) {
                if (*p == '\r') {
                    ((Uz_Globs *)pG)->chars = 0;
                } else {
                    if (*p == '\t')
                        ((Uz_Globs *)pG)->chars +=
                            (TABSIZE - (((Uz_Globs *)pG)->chars % TABSIZE));
                    else
                        ++((Uz_Globs *)pG)->chars;

                    if (((Uz_Globs *)pG)->chars >= ((Uz_Globs *)pG)->width)
                        islinefeed = TRUE;
                }
            }
            if (islinefeed) {
                islinefeed = FALSE;
                ((Uz_Globs *)pG)->chars = 0;
                ++((Uz_Globs *)pG)->numlines;
                ++((Uz_Globs *)pG)->lines;
                if (((Uz_Globs *)pG)->lines >= ((Uz_Globs *)pG)->height)
                {
                    WriteScreen((char *)q, p-q+1);
                    ((Uz_Globs *)pG)->sol = TRUE;
                    q = p + 1;
                    (*((Uz_Globs *)pG)->mpause)((void *)pG,
                      MorePrompt, 1);
                }
            }
            p++;
        } /* end while */
        size = (unsigned long)(p - q);   /* remaining text */
    }

    if (size) {
            WriteScreen((char *)q, size);
        ((Uz_Globs *)pG)->sol = (endbuf[-1] == '\n');
    }
    return 0;

} /* end function UzpMessagePrnt() */





/***************************/
/* Function UzpMorePause() */
/***************************/

void  UzpMorePause(void *pG, const char *prompt, int flag)
{
    unsigned char c;

/*---------------------------------------------------------------------------
    Print a prompt and wait for the user to press a key, then erase prompt
    if possible.
  ---------------------------------------------------------------------------*/

    if (!((Uz_Globs *)pG)->sol)
        fprintf(stderr, "\n");
    /* numlines may or may not be used: */
    fprintf(stderr, prompt, ((Uz_Globs *)pG)->numlines);
    fflush(stderr);
    if (flag & 1) {
        do {
            c = (unsigned char)RdosReadKeyboard();
        } while (
                 c != '\r' && c != '\n' && c != ' ' && c != 'q' && c != 'Q');
    } else
        c = (unsigned char)RdosReadKeyboard();

    /* newline was not echoed, so cover up prompt line */
    fprintf(stderr, HidePrompt);
    fflush(stderr);

    if (
        (tolower(c) == 'q')) {
        exit(PK_COOL);
    }

    ((Uz_Globs *)pG)->sol = TRUE;

    /* space for another screen, enter for another line. */
    if ((flag & 1) && c == ' ')
        ((Uz_Globs *)pG)->lines = 0;

} /* end function UzpMorePause() */

