%{
#include "calc.tab.h"
#include <stdlib.h>
#include <ctype.h>

int comment_newlines = 0;
%x COMMENT
%}

%%
// Comentarios de línea
"//"[^\n]*\n        { return '\n'; }
"//"[^\n]*$         { return '\n'; }

// Comentarios multilínea
"/*"                { comment_newlines = 0; BEGIN(COMMENT); }
<COMMENT>[^*\n]+    { /* skip */ }
<COMMENT>\n         { comment_newlines++; }
<COMMENT>\*+[^*/]   { /* skip */ }
<COMMENT>\*+/       { BEGIN(INITIAL);
                      while (comment_newlines-- > 0) unput('\n');
                    }

[ \t\r]+            { /* ignorar espacios */ }

// Hexadecimal
0[xX][0-9a-fA-F]+   { yylval.ival = (int) strtol(yytext, NULL, 0); return NUMBER; }
// Decimal
[0-9]+              { yylval.ival = atoi(yytext); return NUMBER; }

"abs"               { return ABS; }

"&"                 { return '&'; }
"^"                 { return '^'; }
"|"                 { return '|'; }

"("                 { return '('; }
")"                 { return ')'; }
"+"                 { return '+'; }
"-"                 { return '-'; }
"*"                 { return '*'; }
"/"                 { return '/'; }

\n                  { return '\n'; }
.                   { return yytext[0]; }
%%

int yywrap(void) { return 1; }
