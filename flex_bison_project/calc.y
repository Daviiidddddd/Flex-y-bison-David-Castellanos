%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
void yyerror(const char *s);
int yylex(void);
%}

%union {
    int ival;
}

%token <ival> NUMBER
%token ABS

%left '|'     /* bitwise OR */
%left '^'     /* XOR */
%left '&'     /* AND */
%left '+' '-'
%left '*' '/'
%right UMINUS

%type <ival> expr

%%
input:
    /* empty */
  | input line
  ;

line:
    '\n'
  | expr '\n'   { printf("dec: %d\t hex: 0x%x\n", $1, $1); }
  ;

expr:
    NUMBER                  { $$ = $1; }
  | expr '|' expr           { $$ = $1 | $3; }
  | expr '^' expr           { $$ = $1 ^ $3; }
  | expr '&' expr           { $$ = $1 & $3; }
  | expr '+' expr           { $$ = $1 + $3; }
  | expr '-' expr           { $$ = $1 - $3; }
  | expr '*' expr           { $$ = $1 * $3; }
  | expr '/' expr           {
                               if ($3 == 0) { yyerror("division by zero"); $$ = 0; }
                               else $$ = $1 / $3;
                             }
  | '-' expr %prec UMINUS   { $$ = -$2; }
  | ABS '(' expr ')'        { $$ = abs($3); }
  | '(' expr ')'            { $$ = $2; }
  ;
%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    printf("Calc - soporte hex (0x...), comentarios // y /* */; operadores bitwise &,|,^\n");
    yyparse();
    return 0;
}
