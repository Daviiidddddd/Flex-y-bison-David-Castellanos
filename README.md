# Flex & Bison - Capítulo 1 (Ejercicios y Soluciones)

Este proyecto implementa los ejercicios solicitados para el Capítulo 1 del libro *Flex & Bison* (O'Reilly), incluyendo ejemplos, modificaciones y programas adicionales.

## Contenido
- `calc.l` → Escáner (lexer) con soporte para:
  - Comentarios `//` y `/* */` preservando saltos de línea.
  - Números hexadecimales (`0x...`) y decimales.
  - Operadores de nivel de bits: `&`, `|`, `^`.
- `calc.y` → Analizador sintáctico (parser) con:
  - Precedencias correctas para operadores aritméticos y bitwise.
  - Función `abs(expr)` para valor absoluto.
  - Salida decimal y hexadecimal.
- `Makefile` → Compilación automática con `make`.
- `wc_c.c` → Programa de conteo de palabras en C optimizado.
- `examples/` → Ejemplos 1-1 a 1-5.

## Respuestas a las Preguntas de Ejercicio

### 1) Manejo de comentarios
Por defecto, la calculadora NO aceptará una línea que contenga solo un comentario si el scanner consume también el \n sin devolverlo al parser. La solución correcta y más limpia es arreglarlo en el scanner (Flex): los comentarios son léxicos y el scanner debe ignorar su texto pero preservar saltos de línea (o devolver '\n') para que el parser pueda ver líneas vacías.

Por qué: la gramática de la calculadora espera '\n' como terminador de línea:
```
line:
  '\n'
| expr '\n' { printf(...); }
;
```
Si el scanner se traga el \n dentro de la regla de comentario, el parser no recibe el terminador y la línea “vacía” no es reconocida.

Implementación recomendada (scanner):

Soporte // linea única: consumir comentario pero devolver \n (o dejar que la regla \n capture el salto).

Soporte /* ... */ multilínea: contar \n dentro del bloque y reinyectarlos (o devolverlos) para que el parser los vea.

Reglas Flex (snippet):
```
%{
#include "calc.tab.h"
#include <stdlib.h>
%}

/* start condition for block comments (optional) */
%x COMMENT

%%
"//"[^\n]*\n       { return '\n'; }   /* comentario de línea: devuelve newline */
"//"[^\n]*$        { return '\n'; }   /* comentario al EOF sin \n -> emulamos \n */

"/*"               { BEGIN(COMMENT); comment_newlines = 0; }
<COMMENT>[^*\n]+   { /* skip content */ }
<COMMENT>\n        { comment_newlines++; }
<COMMENT>\*+[^*/]  { /* skip */ }
<COMMENT>\*+/      { /* fin de comentario */
                      BEGIN(INITIAL);
                      /* reinsertar newlines contados para que el parser los vea */
                      while (comment_newlines-- > 0) unput('\n');
                    }

\n                 { return '\n'; }
... otras reglas ...
%%
```
Cómo probar:

Línea sólo comentario: echo "// esto es comentario" | ./calc debe comportarse como echo "" | ./calc — el parser debe reconocer la línea vacía.

Comentario al EOF (sin \n): printf "//millos" | ./calc — debería funcionar igual.

### 2) Conversión hexadecimal
Objetivo: aceptar números hex (0x... / 0X...) y decimales, y que el parser reciba token NUMBER con yylval cargado.

Decisión técnica: añadir en el scanner un patrón que capture hexadecimales y usar strtol(yytext, NULL, 0) para convertir (base 0 detecta 0x).
Regla Flex (snippet):
```
0[xX][0-9a-fA-F]+   {
                       yylval.ival = (int) strtol(yytext, NULL, 0);
                       return NUMBER;
                    }
[0-9]+               {
                       yylval.ival = atoi(yytext);
                       return NUMBER;
                    }
```
strtol(..., 0) detecta 0x e interpreta correctamente. Si quieres manejar -0x... como número negativo, el parser puede tratar el - como operador unario.

Cambios en Bison (calc.y):

Asegúrate de que NUMBER tenga tipo en %union, por ejemplo:
```
%union { int ival; }
%token <ival> NUMBER
%type <ival> expr
```
Ajusta la impresión del resultado (decimal y hex):
```
line:
  '\n'
| expr '\n' { printf("dec: %d\t hex: 0x%x\n", $1, $1); }
;
```
Pruebas:
```
echo "0x1a + 10" | ./calc
# Esperado: dec: 36    hex: 0x24
echo "255" | ./calc
# Esperado: dec: 255   hex: 0xff
```

### 3) Operadores de nivel de bits
Requerimiento: añadir & (AND), | (OR), ^ (XOR).

Lexer (Flex):
```
lex

"&"    { return '&'; }
"^"    { return '^'; }
"|"    { return '|'; }
```
Parser (Bison) — precedencias:
Define precedencias para que la evaluación siga lo esperado (estilo C):


```
%left '|'       /* bitwise OR (baja precedencia entre bitwise) */
%left '^'       /* XOR */
%left '&'       /* AND */
%left '+' '-'
%left '*' '/'
```
Producciones (snippet):
```


expr:
    NUMBER             { $$ = $1; }
  | expr '|' expr      { $$ = $1 | $3; }
  | expr '^' expr      { $$ = $1 ^ $3; }
  | expr '&' expr      { $$ = $1 & $3; }
  | expr '+' expr      { $$ = $1 + $3; }
  | expr '-' expr      { $$ = $1 - $3; }
  | expr '*' expr      { $$ = $1 * $3; }
  | expr '/' expr      { if ($3 == 0) { yyerror("div by zero"); $$ = 0; } else $$ = $1 / $3; }
  | '-' expr %prec UMINUS { $$ = -$2; }
  | '(' expr ')'       { $$ = $2; }
  ;
```
Ambigüedad | como OR vs |expr| valor absoluto

| se usa tanto como operador binario OR como para el valor absoluto notación |x|.

El lexer no puede decidir; la distinción es sintáctica (parser).

Para soportar |expr| como absoluto hay dos enfoques:

a) Preferir abs(expr) y evitar |expr|. Es lo más simple y sin ambigüedad.

b) Soportar |expr| en la gramática:
```


factor:
   '|' expr '|'   { $$ = abs($2); }
 | NUMBER
 | '(' expr ')'
;
```
Esto puede crear conflictos shift/reduce porque la misma | puede iniciar un operador binario o un absoluto. Bison puede reportar conflictos; a veces se solucionan por precedencias o reestructuración de la gramática. En la práctica, recomiendo usar abs(expr) para evitar estas complicaciones, salvo que el requisito sea explícito.

Pruebas:

```

echo "0xFF & 0x0F" | ./calc   # dec: 240 hex: 0xf0
echo "5 | 2" | ./calc         # dec: 7   hex: 0x7
echo "0x10 ^ 0x01" | ./calc   # dec: 17  hex: 0x11
```

### 4) Reconocimiento de tokens
Pregunta: ¿la versión manuscrita reconoce exactamente los mismos tokens que flex?

Respuesta y guía de comparación:

No necesariamente; aunque ambos pueden diseñarse para reconocer la misma clase de tokens, suelen surgir discrepancias prácticas:

Diferencias comunes:

Longest-match: Flex implementa “maximal munch” (coincidencia más larga). Un scanner manual puede equivocarse en casos de subcadenas (por ejemplo <= vs < y =).

Orden e prioridad: Flex resuelve empates por orden de reglas. En un scanner manual puede que la lógica de chequeo cambie prioridades.

Manejo de EOF y errores: un scanner manual puede tener bugs en EOF dentro de strings o comentarios.

Espacios y newlines: Flex puede fácilmente ignorarlos con reglas; el manual puede fallar en algunos combos CRLF.

Estado y start-conditions: Flex ofrece BEGIN/%x; en versión manuscrita necesitas implementar estados manualmente (más propenso a errores).

Unicode / multibyte: flex por defecto opera en bytes; un scanner manual podría (o no) soportar UTF-8 de forma distinta.

Cómo comparar prácticamente (procedimiento):

Haz que ambos scanners impriman la secuencia de tokens (por ejemplo TOKEN_NAME value).

Ejecuta ambos con el mismo conjunto de entradas de prueba (casos límite: <=, 0x1f, //comment\n, /*...*/, strings con \", EOF dentro de comentario).

Guarda salidas y usa diff:

```
./scanner_flex < tests.txt > flex.tokens
./scanner_manual < tests.txt > manual.tokens
diff -u flex.tokens manual.tokens
```
Investiga cada discrepancia y documenta la causa.

### 5) Limitaciones de Flex
¿Qué idiomas no son buenos para Flex?
Flex es un generador de scanners basado en expresiones regulares y DFA — por tanto es menos adecuado para lenguajes cuya tokenización depende fuertemente de contexto o que requieren memoria no regular.

Ejemplos concretos:

Lenguajes con indentación-significant (Python): el lexer debe producir tokens INDENT/DEDENT basados en la pila de indentación — posible pero engorroso en Flex (requiere lógica adicional).

Lenguajes con tokenización dependiente del contexto semántico: por ejemplo, en C algunas palabras reservadas pueden tratarse como identificadores o keywords según definiciones en tiempo de compilación (poco común, pero ocurre en DSLs).

Comentarios anidados arbitrarios: registrar profundidad de anidamiento requiere contar niveles, posible pero no natural en regex (aunque con start conditions se implementa).

Lenguajes que mezclan múltiples sublenguajes (HTML + Javascript + CSS): el lexer debe cambiar completamente de conjunto de reglas según el contexto <script>/<style> — posible, pero puede volverse complejo.

Lenguajes con gramáticas sensibles a Unicode/normalización: Flex opera por bytes y no aplica NFC/NFD por defecto.

Conclusión: Flex funciona bien para la mayoría de lenguajes imperativos clásicos y para muchos DSLs; no es tan conveniente para indent-sensitive, altamente context-sensitive, o con anidamientos arbitrarios que exigen pilas complejas en el lexer.

### 6) Programa de conteo de palabras
Objetivo: reescribir el ejemplo wc (word count) en C puro y comparar rendimiento con la versión Flex.

Implementación eficiente (usa fread y procesamiento por bloques):

wc_c.c

```
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    FILE *f = stdin;
    if (argc > 1) {
        f = fopen(argv[1], "rb");
        if (!f) { perror("fopen"); return 1; }
    }
    const size_t BUF = 1<<16; /* 64KB */
    char *buf = malloc(BUF);
    if (!buf) { perror("malloc"); return 1; }
    long lines=0, words=0, chars=0;
    int in_word = 0;
    size_t n;
    while ((n = fread(buf, 1, BUF, f)) > 0) {
        chars += n;
        for (size_t i=0;i<n;i++) {
            char c = buf[i];
            if (c == '\n') lines++;
            if (c==' ' || c=='\n' || c=='\t' || c=='\r' || c=='\v' || c=='\f') {
                if (in_word) { words++; in_word = 0; }
            } else {
                in_word = 1;
            }
        }
    }
    if (in_word) words++;
    printf("%ld %ld %ld\n", lines, words, chars);
    free(buf);
    if (f != stdin) fclose(f);
    return 0;
}
```
Compilación:

```
gcc -O2 -o wc_c wc_c.c
```
Medición y comparación:

Prepara un archivo grande de prueba (por ejemplo big.txt).

Ejecuta:

```
time ./wc_c big.txt > /dev/null
time ./ex1-1 big.txt > /dev/null   # versión flex que hiciste
time /usr/bin/time -v ./wc_c big.txt  # info detallada
time /usr/bin/time -v ./ex1-1 big.txt
```
Observaciones esperadas:

Una versión en C bien optimizada (lectura por bloques fread, -O2) suele ser tan rápida o más que la versión generada por Flex (que hace matching regex y llamada a acciones), especialmente en archivos muy grandes.

La diferencia puede ser moderada; Flex está bien optimizado, pero la versión C permite micro-optimización (memcpy, SIMD, pthreads) que Flex no hace por defecto.

Depuración: la versión en C puede ser más propensa a bugs de punteros, pero las fallas son claras y se depuran con gdb/valgrind. La versión Flex es más declarativa y fácil de modificar, pero inspeccionar el flujo de reglas puede ser menos directo.

### 7) CALCULADORA
Código listo: calculadora completa con comentarios, hex y bitwise
A continuación tienes los ficheros listos. Pégalos a calc.l, calc.y y Makefile.

calc.l

```
%{
#include "calc.tab.h"
#include <stdlib.h>
#include <ctype.h>

int comment_newlines = 0;
%x COMMENT
%}

%%
"//"[^\n]*\n        { return '\n'; }
"//"[^\n]*$         { return '\n'; }

"/*"                { comment_newlines = 0; BEGIN(COMMENT); }

<COMMENT>[^*\n]+    { /* skip */ }
<COMMENT>\n         { comment_newlines++; }
<COMMENT>\*+[^*/]   { /* skip */ }
<COMMENT>\*+/       { BEGIN(INITIAL);
                      while (comment_newlines-- > 0) unput('\n');
                    }

[ \t\r]+            { /* ignore spaces */ }

/* Hexadecimal (0x...) */
0[xX][0-9a-fA-F]+   { yylval.ival = (int) strtol(yytext, NULL, 0); return NUMBER; }

/* Decimal */
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
```
calc.y

```
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
  | ABS '(' expr ')'        { $$ = abs($3); } /* abs(x) */
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
Makefile
```
```

all: calc

calc: calc.tab.c lex.yy.c
	gcc -o calc calc.tab.c lex.yy.c -lfl -O2

calc.tab.c calc.tab.h: calc.y
	bison -d calc.y

lex.yy.c: calc.l calc.tab.h
	flex calc.l

clean:
	rm -f calc calc.tab.c calc.tab.h calc.output lex.yy.c
Cómo compilar y probar:

```

# pruebas
```
echo "0x1F & 7" | ./calc
echo "abs(-12)" | ./calc
echo "// solo comentario" | ./calc   # no imprime nada pero no da error
printf "/* comentario \n que contiene nueva linea */\n" | ./calc
```
## FinaL
David Castellanos
