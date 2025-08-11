all: calc

calc: calc.tab.c lex.yy.c
	gcc -o calc calc.tab.c lex.yy.c -lfl -O2

calc.tab.c calc.tab.h: calc.y
	bison -d calc.y

lex.yy.c: calc.l calc.tab.h
	flex calc.l

clean:
	rm -f calc calc.tab.c calc.tab.h calc.output lex.yy.c
