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
La calculadora original no acepta una línea que contenga solo un comentario si el escáner consume también el `\n`. Esto rompe la gramática que espera `'\n'` para finalizar la línea. La solución más limpia es corregirlo en el escáner, devolviendo siempre el salto de línea al parser.

### 2) Conversión hexadecimal
Se agregó en el escáner un patrón `0[xX][0-9a-fA-F]+` y se usa `strtol(yytext, NULL, 0)` para convertir a entero. El parser imprime resultados en decimal y hexadecimal.

### 3) Operadores de nivel de bits
Se agregaron `&`, `|` y `^` con precedencias correctas en Bison. Se decidió usar `abs(expr)` en lugar de `|expr|` para evitar ambigüedad.

### 4) Reconocimiento de tokens
No siempre el escáner manual reconoce los mismos tokens que el generado por Flex. Las diferencias provienen de longest-match, prioridades y manejo de EOF.

### 5) Limitaciones de Flex
Flex no es ideal para lenguajes altamente dependientes de contexto (Python, HTML+JS+CSS, comentarios anidados arbitrarios).

### 6) Programa de conteo de palabras
Se implementó `wc_c.c` que procesa en bloques grandes (`fread` 64KB). Es más rápido que la versión Flex, pero más propenso a errores de puntero.

## Compilación y ejecución

```bash
make
echo "0x1F & 7" | ./calc
./wc_c bigfile.txt
```

## Créditos
David Castellanos
