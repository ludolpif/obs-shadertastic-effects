%scanner        ../scanner/Scanner.h
%token-path     ../scanner/tokens.h

%token COMMENT STRING IDENTIFIER PP_INCLUDE PP_DEFINE PP_UNDEF PP_IFDEF PP_IFNDEF PP_ENDIF PP_OTHER WS NL CHAR

%%

startrule:
    startrule section
|
    section
;

section:
    include
    {
        //std::cout << " include: " << d_scanner.matched() << std::endl;
        d_scanner.include(d_scanner.decode_string());
    }
|
    define
    {
        //std::cout << "define : " << d_scanner.matched() << std::endl;
        d_scanner.pp_defined_symbols.insert(d_scanner.matched());
    }
|
    undef
    {
        //std::cout << "undef : " << d_scanner.matched() << std::endl;
        d_scanner.pp_defined_symbols.erase(d_scanner.matched());
    }
| 
    ifdef
    {
        //std::cout << "ifdef : " << d_scanner.matched() << std::endl;
    }
| 
    ifndef
    {
        //std::cout << "ifndef : " << d_scanner.matched() << std::endl;
    }
| 
    PP_ENDIF
    {
        //std::cout << "endif" << std::endl;
    }
| 
    content
    {
        std::cout << d_scanner.matched();
    }
;

include:
    PP_INCLUDE STRING
|
    PP_INCLUDE WS STRING
;

define:
    PP_DEFINE IDENTIFIER
|
    PP_DEFINE WS IDENTIFIER
;

undef:
    PP_UNDEF IDENTIFIER
|
    PP_UNDEF WS IDENTIFIER
;

ifdef:
    PP_IFDEF IDENTIFIER
|
    PP_IFDEF WS IDENTIFIER
;

ifndef:
    PP_IFNDEF IDENTIFIER
|
    PP_IFNDEF WS IDENTIFIER
;

content:
    COMMENT
|
    STRING
|
    IDENTIFIER
|
    PP_OTHER
|
    WS
|
    NL
|
    CHAR
;
