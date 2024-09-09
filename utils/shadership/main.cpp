#include <iostream>
#include <fstream>
#include <string.h>
#include "scanner/Scanner.h"
#include "parser/Parser.h"

void usage(char* progname) {
    std::cerr << "Usage: " << progname << "<effect_path> [transition|filter]" << std::endl;
    std::cerr << "Example: " << progname << " ./effects/filters/shadership_demo" << std::endl;
    std::cerr << "Specifying effect type is optonnal/autodetected if parent folder of effect_path" << std::endl;
    std::cerr << " follows shadertastic foldertree rules" << std::endl;
}

int scan_stdin_until_eof() {
    Scanner scanner;
    while (int token = scanner.lex())   // get all tokens
    {
        std::string const &text = scanner.matched();
        switch (token)
        {
            case Scanner::COMMENT:
                std::cout << "comment: " << text << std::endl;
                break;
            case Scanner::STRING:
                std::cout << "string: " << text << std::endl;
                break;
            case Scanner::IDENTIFIER:
                std::cout << "identifier: " << text << std::endl;
                break;
            case Scanner::PP_INCLUDE:
                std::cout << "include: " << text << std::endl;
                break;
            case Scanner::PP_DEFINE:
                std::cout << "define: " << text << std::endl;
                break;
            case Scanner::PP_UNDEF:
                std::cout << "undef: " << text << std::endl;
                break;
            case Scanner::PP_IFDEF:
            case Scanner::PP_IFNDEF:
            case Scanner::PP_ENDIF:
            case Scanner::PP_OTHER:
                std::cout << "preproc: " << text << std::endl;
                break;
            case Scanner::WS:
                std::cout << "WS: " << text << std::endl;
                break;
            case Scanner::NL:
                std::cout << "NL: " << text << std::endl;
                break;
            default:
                std::cout << "char. token: '" << text << "'" << std::endl;
                break;
        }
    }
    return 0;
}

int parse_stdin_until_eof() {
    Parser parser;
    return parser.parse();
}

enum FilterType {
    UNKNOWN = 0,
    FILTER,
    TRANSITION
};

int main(int argc, char* argv[]) {
    std::string FilterTypeNames[] = {
        "unknown",
        "filter",
        "transition"
    };

    if (argc != 2 && argc != 3) {
        usage(argv[0]);
        return 1;
    }

    // lexer/parser dummy test from stdin to stdout
    //return scan_stdin_until_eof();
    //return parse_stdin_until_eof();

    // use given filter type or guessing it
    FilterType t = FilterType::UNKNOWN;
    const char *to_be_matched = NULL;
    if ( argc == 3 ) {
        to_be_matched = argv[2];
    } else {
        to_be_matched = "filters"; //FIXME get great-parent folder name of argv[1] as char *
    }
    if ( strncmp("filter", to_be_matched, 6 ) == 0 ) t = FilterType::FILTER;
    if ( strncmp("transition", to_be_matched, 10 ) == 0 ) t = FilterType::TRANSITION;

    // extract effect_name from effect_path
    to_be_matched = "shadership_demo"; //FIXME get parent folder name of argv[1] as char *

    // extract output_folder from effect_path
    std::string output_folder = "/tmp"; // FIXME get great-great-parent folder name of argv[1]

    // early open write output file, before parsing
    std::string output_filename = to_be_matched;
    output_filename.append(".");
    output_filename.append(FilterTypeNames[t]);
    output_filename.append(".shadertastic");

    // TODO use libzip to really output things on disk
    std::cout << "Dummy output path code result: " << output_folder << " and " << output_filename << std::endl;

    std::string input_file = argv[1];
    input_file.append("/"); // TODO use a path classes (OBS-style ones)
    input_file.append("main.hlsl");

    std::cout << "Dummy input path code result: " << input_file << std::endl;

    std::ifstream input_stream;
    input_stream.open(input_file);
    int res = 2;
    if (!input_stream.is_open()) {
        std::cerr << "Can't open " << input_file << std::endl;
        return res;
    }
    // XXX output to stdout for now (waiting libzip integration)
    Scanner scanner(input_stream, std::cout);
    Parser parser/*(scanner)*/; //FIXME deleted copy constructors ?
    res = parser.parse();

    input_stream.close();

    return res;
}

