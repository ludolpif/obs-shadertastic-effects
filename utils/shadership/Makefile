.PHONY: all clean demo

all: shadership demo

clean:
	rm -f scanner/lex.cc scanner/Scannerbase.h
	rm -f parser/parse.cc parser/Parserbase.h scanner/tokens.h

demo: shadership
	./shadership ./effects/filters/shadership_demo

shadership: main.cpp scanner/lex.cc parser/parse.cc
	g++ -Wall -o $@ $^

scanner/lex.cc scanner/Scannerbase.h &: lexer.l scanner/Scanner.h scanner/Scanner.ih parser/Parserbase.h
	cd scanner && flexc++ ../lexer.l

parser/parse.cc parser/Parserbase.h scanner/tokens.h &: grammar.y parser/Parser.h parser/Parser.ih
	cd parser && bisonc++ ../grammar.y
