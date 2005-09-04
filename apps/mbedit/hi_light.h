/*      disp_hnd.h                          13.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2003: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for disp_hnd.c (structs for syntax highlighting)
/    include only by disp_hnd.c !!
/
*/


/* -------------------------------------------------------------------------- */

/* this is the general structure */
typedef struct    /* one struct for each file type, e.g.: C, C++, HTML, Java, Ada, ... */
{
    int  num_file_ext;          /* number of file extensions        */
    char ***file_ext;           /* n file extensions                */
    int  case_sensitive;        /* 0=false, 1=true                  */
    char *comment_sl;           /* single   line : start            */
	char *comment_fc;           /* first column (Fortran)           */
    char *comment_ml1;          /* multiple lines: start            */
    char *comment_ml2;          /* multiple lines: stop             */
    int  num_keywords;          /* no of entries                    */
    char ***keywords;           /* n keywords + directives          */
    size_t *key_len;            /* strlen of each keyword           */
    char e_delimit [BUF_256];	/* delimiter set for each file type */
} HiLight;

/* -------------------------------------------------------------------------- */

/* this section contains the particular language tables */

/* ANSI-C */
static const char *file_ext_ansi_c [] = {"c"};
static const char *keywords_ansi_c [] =
   {
   /* directives */
      "#define",  "#elif",    "#else",    "#endif",    "#error",
      "#if",      "#ifdef",   "#ifndef",  "#include",  "#line",
      "#pragma",  "#undef",

   /* keywords */
      "auto",     "break",    "case",     "cdecl",     "char",     "const",
      "continue", "default",  "do",       "double",    "else",     "enum",
      "extern",   "far",      "float",    "for",       "fortran",  "goto",
      "huge",     "if",       "int",      "interrupt", "long",     "near",
      "pascal",   "register", "return",   "short",     "signed",   "sizeof",
      "static",   "struct",   "switch",   "typedef",   "union",    "unsigned",
      "void",     "volatile", "while",
   };
static size_t key_lens_ansi_c [lengthof(keywords_ansi_c)];


/* C++ */
static const char *file_ext_cpp [] = {"cpp", "h", "hpp", "hh", "bak"};
static const char *keywords_cpp [] =
   {
   /* directives */
      "#define",  "#elif",    "#else",    "#endif",    "#error",
      "#if",      "#ifdef",   "#ifndef",  "#include",  "#line",
      "#pragma",  "#undef",

   /* keywords */
      "asm",      "auto",     "break",    "case",     "catch",     "char",
      "class",    "const",    "continue", "default",  "delete",    "do",
      "double",   "else",     "enum",     "extern",   "float",     "for",
      "friend",   "goto",     "if",       "inline",   "int",       "long",
      "new",      "operator", "private",  "protected","public",    "register",
      "return",   "short",    "signed",   "sizeof",   "static",    "struct",
      "switch",   "template", "this",     "throw",    "try",       "typedef",
      "union",    "unsigned", "virtual",  "void",     "volatile",  "while",
   };
static size_t key_lens_cpp [lengthof(keywords_cpp)];


/* Ada */
static const char *file_ext_ada [] = {"ads", "adb"};
static const char *keywords_ada [] =
   {
   /* directives */

   /* keywords */
    "abort",     "abs",       "abstract",  "accept",    "access",    "aliased",
    "all",       "and",       "array",     "at",        "begin",     "body",
    "case",      "constant",  "declare",   "delay",     "delta",     "digits",
    "do",        "else",      "elsif",     "end",       "entry",     "exception",
    "exit",      "for",       "function",  "generic",   "goto",      "if",
    "in",        "is",        "limited",   "loop",      "mod",       "new",
    "not",       "null",      "of",        "or",        "others",    "out",
    "package",   "pragma",    "private",   "procedure", "protected", "raise",
    "range",     "record",    "rem",       "renames",   "requeue",   "return",
    "reverse",   "select",    "separate",  "subtype",   "tagged",    "task",
    "terminate", "then",      "type",      "until",     "use",       "when",
    "while",     "with",      "xor",
   };
static size_t key_lens_ada [lengthof(keywords_ada)];


/* HTML, XML, Java */
static const char *file_ext_htm [] = {"html", "htm", "xml", "js"};
static const char *keywords_htm [] =
   {
   /* directives */

   /* keywords */
      "a",        "abbr",     "acronym",  "address",  "applet",   "area",     
      "b",        "base",     "basefont", "bdo",      "big",      "blockquote",
      "body",     "br",       "button",   "caption",  "center",   "cite",     
      "code",     "col",      "colgroup", "dd",       "del",      "dfn",      
      "dir",      "div",      "dl",       "dt",       "em",       "fieldset", 
      "font",     "form",     "frame",    "frameset", "h1",       "h2",       
      "h3",       "h4",       "h5",       "h6",
      "head",     "hr",       "href",     "html",
      "i",        "iframe",   "img",      "input",    "ins",      
      "isindex",  "kbd",      "label",    "legend",   "li",       "link",     
      "map",      "menu",     "meta",     "noframes", "noscript", "object",   
      "ol",       "optgroup", "option",   "p",        "param",    "pre",      
      "q",        "s",        "samp",     "script",   "select",   "small",    
      "span",     "strike",   "strong",   "style",    "sub",      "sup",      
      "table",    "tbody",    "td",       "textarea", "tfoot",    "th",       
      "thead",    "title",    "tr",       "tt",       "u",        "ul",       
      "var",
      "name",     "bgcolor",  "target",   "type",     "height",   "width",
   };
static size_t key_lens_htm [lengthof(keywords_htm)];

/* -------------------------------------------------------------------------- */

/* this is the implementation of the syntaxhighlighting table */

static HiLight hi_light_default[] =
{
/* unknown: no syntax highlighting */
    {
        0,
        NULL,
        0,
        NULL,
        NULL,
        NULL, NULL,
        0,
        NULL,
        0,
		TOKEN_DELIMITERS
    },


/* ANSI-C */
    {
        lengthof (file_ext_ansi_c),
        (char ***)file_ext_ansi_c,
        1,
        NULL,
        NULL,
        "/*", "*/",
        lengthof (keywords_ansi_c),
        (char ***)keywords_ansi_c,
        (size_t *)key_lens_ansi_c,
		TOKEN_DELIMITERS
    },


/* C++ */
    {
        lengthof (file_ext_cpp),
        (char ***)file_ext_cpp,
        1,
        "//",
        NULL,
        "/*", "*/",
        lengthof (keywords_cpp),
        (char ***)keywords_cpp,
        (size_t *)key_lens_cpp,
		TOKEN_DELIMITERS
    },


/* Ada */
    {
        lengthof (file_ext_ada),
        (char ***)file_ext_ada,
        0,
        "--",
        NULL,
        NULL, NULL,
        lengthof (keywords_ada),
        (char ***)keywords_ada,
        (size_t *)key_lens_ada,
		TOKEN_DELIMITERS
    },


/* HTML, XML, Java */
    {
        lengthof (file_ext_htm),
        (char ***)file_ext_htm,
        0,
        NULL,
        NULL,
        "<!--", "-->",
        lengthof (keywords_htm),
        (char ***)keywords_htm,
        (size_t *)key_lens_htm,
		TOKEN_DELIMITERS
    },

};

/* -------------------------------------------------------------------------- */

/* Modification History */
/* 29.03.03 - file erzeugt */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
