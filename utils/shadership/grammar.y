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
        std::cout << "preproc include: " << d_scanner.matched() << '\n';
    }
|
    define
    {
        std::cout << "define : " << d_scanner.matched() << '\n';
    }
|
    undef
    {
        std::cout << "undef : " << d_scanner.matched() << '\n';
    }
| 
    content
    {
        std::cout << "pass: " << d_scanner.matched() << '\n';
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

content:
    COMMENT
|
    STRING
|
    PP_IFDEF
|
    PP_IFNDEF
|
    PP_ENDIF
|
    PP_OTHER
|
    WS
|
    NL
|
    CHAR
;
