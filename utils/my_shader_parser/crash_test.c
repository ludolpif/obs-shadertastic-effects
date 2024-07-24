#include <fcntl.h> // open()
#include <unistd.h> // lseek()
#include <sys/mman.h> // mmap()
#include <stdio.h> //fprintf()
#include <stdlib.h> //setenv()
#include <SDL2/SDL.h> // SDL_*()
#include <SDL2/SDL_syswm.h> // SDL_GetWindowWMInfo()
#include <obs/obs.h> // obs_{startup,shutdown}() obs_{enter,leave}_graphics()
#include <obs/util/base.h> // blog()
#include <obs/graphics/graphics.h> // gs_*()
#include <obs/graphics/effect.h> // struct gs_effect
#include <obs/graphics/effect-parser.h> // ep_*()
#include <obs/obs-nix-platform.h> // obs_set_nix_platform_display()
#include <obs/util/lexer.h> // error_data_add(), error_data_item()
#include <obs/util/bmem.h> // bstrdup(), bfree()

// Also defined in obs/graphics/effect.c (but not .h)
#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))

#define sdl_abort(funcname, code, label) do { \
	fprintf(stderr, "error: %s: %s\n", #funcname, SDL_GetError()); \
	exitcode = code; \
	goto label; } while(0)

#define obs_abort(funcname, msg, code, label) do { \
	fprintf(stderr, "error: %s: %s\n", #funcname, msg); \
	exitcode = code; \
	goto label; } while(0)

void usage(char *progname, int exitval) {
    fprintf(stderr, "%s <path-to-hlsl>\n", progname);
    exit(exitval);
}

int main(int argc, char *argv[]) {
#if defined(SDL_VIDEO_DRIVER_X11)
	setenv("SDL_VIDEODRIVER", "x11", 1);
#else
#error "This program has been tried only for X11 for now. Feel free to improve it !"
#endif
	int exitcode = 0;
    if ( argc < 2 ) usage(argv[0], 1);
	/*
	// Init SDL, get X11 display pointer
	if (SDL_Init(SDL_INIT_VIDEO) != 0) sdl_abort(SDL_Init, 2, mainexit);

	SDL_Window *win = SDL_CreateWindow("OBS tester", 100, 100, 640, 480, SDL_WINDOW_SHOWN);
	if (!win) sdl_abort(SDL_CreateWindow, 3, sdlquit);

	SDL_SysWMinfo info;
	SDL_VERSION(&info.version);
	if (!SDL_GetWindowWMInfo(win, &info)) sdl_abort(SDL_GetWindowWMInfo, 6, sdldestroywin);
	Display *display = info.info.x11.display;

	printf("SDL X11 Display: %p\n", display);

	// OBS Startup display X11 version if we provide it a pointer
	obs_set_nix_platform_display(display);
	*/
	if ( ! obs_startup("en-US", NULL, NULL) ) obs_abort(obs_startup, "!true", 20, sdldestroywin);

	// Initialize OBS graphics without compiling OBS defaults shaders like obs_init_graphics(struct obs_video_info *ovi) do
	graphics_t *graphics = NULL;
	// https://docs.obsproject.com/reference-libobs-graphics-graphics#c.gs_create
	int adapter = 0;
	switch ( gs_create(&graphics, "libobs-opengl", adapter) ) {
		case GS_SUCCESS: blog(LOG_INFO, "gs_create: success on adapter %d", adapter); break;
		case GS_ERROR_FAIL: obs_abort(gs_create, "GS_ERROR_FAIL", 21, obsshutdown); break;
		case GS_ERROR_MODULE_NOT_FOUND: obs_abort(gs_create, "GS_ERROR_MODULE_NOT_FOUND:", 22, obsshutdown); break;
		case GS_ERROR_NOT_SUPPORTED: obs_abort(gs_create, "GS_ERROR_NOT_SUPPORTED", 23, obsshutdown); break;
		default: obs_abort(gs_create, "(unknown error)", 24, obsshutdown); break;
	}


	// Load shader file as effect_string
	char *effect_file = argv[1];
	int fd = open(effect_file, O_RDONLY);
    if ( fd == -1 ) {
        perror("open(effect_file, O_RDONLY)");
        usage(argv[0], 1);
    }
	off_t len = lseek(fd, 0, SEEK_END);
    if ( len == (off_t) -1 ) {
        perror("lseek(<effect_file>, 0, SEEK_END)");
        usage(argv[0], 1);
    }
	const char *effect_string = mmap(0, len, PROT_READ, MAP_PRIVATE, fd, 0);
    if ( effect_string == MAP_FAILED ) {
        perror("mmap(0, len, PROT_READ, MAP_PRIVATE, <effect_file>, 0)");
        usage(argv[0], 1);
    }

	// fprintf(stdout, effect_string);

	gs_enter_context(graphics);
	blog(LOG_INFO, "gs_enter_context(graphics) done");

	blog(LOG_INFO, "Parsing Shader '%s'...", effect_file);
	struct effect_parser parser;
	ep_init(&parser);
	blog(LOG_INFO, "ep_init(&parser) done");
	//char dummy_error[] = "dummy error to prevent ep_compile() call from ep_parse() in first pass";
	//error_data_add(&parser.cfp.error_list, effect_file, 0, 0, dummy_error, LEX_ERROR);

	struct gs_effect *effect = bzalloc(sizeof(struct gs_effect));
	effect->graphics = graphics;
	effect->effect_path = bstrdup(effect_file);
	bool ep_parse_result = ep_parse(&parser, effect, effect_string, effect_file);
	blog(LOG_INFO, "ep_parse(...) returns %s", ep_parse_result?"true":"false");

	// FIXME avec le hlsl ayant un if (true ) { pas fermé, crash dans ep_compile()
	// En ajoutant une lex_error avant ep_parse pour ne pas appeler ep_compile, crash aussi !
	// Avec valgrind et une stack size modifiée, pas de crash ?!? Stack smashing plausible !
	// Segfault initial dans :
	//	 da_resize(ep->effect->params, ep->params.num);
/*
gs_effect_t *gs_effect_create(const char *effect_string, const char *filename,
		char **error_string)
		{
*/
	//blog(LOG_DEBUG, "Effect Parser reformatted shader '%s'", effect_file);
	//debug_print_string("", parser.cfp.lex.reformatted);

	// TODO should make a copy of the text to add the '\0'
	DARRAY(const char *) cfp_lex_reformatted_lines_idx;
	da_init(cfp_lex_reformatted_lines_idx);
	const char *bof_hint = "(Begin of File)";
	const char *eof_hint = "(End of File)";
	da_push_back(cfp_lex_reformatted_lines_idx, &bof_hint); // Line 0

	char *effect_string_reformated_copy = bstrdup(parser.cfp.lex.reformatted);
	char *begin = effect_string_reformated_copy;
	int line = 1;
	for (char *here = begin; here[0] != '\0'; here++) {
		char const *str = begin;
		//int len = here - begin;
		bool is_line = false;

		if (here[0] == '\r') {
			is_line = true;
			here[0] = '\0';
			if (here[1] == '\n') {
				here += 1;
			}
			begin = here + 1;
		} else if (here[0] == '\n') {
			is_line = true;
			here[0] = '\0';
			begin = here + 1;
		}

		if (is_line) {
			//if (len>1) blog(LOG_DEBUG, "[%4d] %.*s", line, len, str);
			da_push_back(cfp_lex_reformatted_lines_idx, &str);
			line++;
		}
	}
	if (begin[0] != '\0') {
		// Final line was not written.
		//if (len>1) blog(LOG_DEBUG, "[%4d] %s", line, begin);
		da_push_back(cfp_lex_reformatted_lines_idx, &begin);
	}

	da_push_back(cfp_lex_reformatted_lines_idx, &eof_hint); // Last line + 1

    blog(LOG_INFO, "parser.cfp.error_list.errors.num == %lu", parser.cfp.error_list.errors.num);

	for (int i=0; i < parser.cfp.error_list.errors.num; i++) {

		blog(LOG_ERROR, "-----8<----- Shader compilation error %2i -----8<-----", i+1);
		const struct error_item *ei = error_data_item(&parser.cfp.error_list, i);
		if ( ei->row > 0 && ei->row < cfp_lex_reformatted_lines_idx.num ) {
			const char **line;
			int context_start = max(0, ei->row - 6);

			for (int r = context_start; r < ei->row; r++ ) {
				line = (const char **) darray_item(sizeof(const char *), &cfp_lex_reformatted_lines_idx.da, r);
				blog(LOG_ERROR, "%s", *line);
			}
			line = (const char **) darray_item(sizeof(const char *), &cfp_lex_reformatted_lines_idx.da, ei->row);
			blog(LOG_ERROR, "%s", *line);

			char ascii_hint[] = "-----------------------------------------------------------------------------------------------------------------------^";
			if ( ei->column < 120 ) blog(LOG_ERROR, "%s", ascii_hint + 120 - ei->column );
		}
		blog(LOG_ERROR, "%s: %s: %s",
				ei->file, /*ei->row, ei->column,*/
				ei->level==LEX_ERROR?"lex_error"
				:ei->level==LEX_WARNING?"lex_warn"
				:"(unknown)",
				ei->error);

		if ( ei->row > 0 && ei->row < cfp_lex_reformatted_lines_idx.num ) {
			const char **line;
			int context_end = min(ei->row + 4, cfp_lex_reformatted_lines_idx.num);
			for (int r = ei->row+1; r < context_end; r++ ) {
				line = (const char **) darray_item(sizeof(const char *), &cfp_lex_reformatted_lines_idx.da, r);
				blog(LOG_ERROR, "%s", *line);
			}
		}
		blog(LOG_ERROR, "----->8--------------------------------------->8-----");
	}
	if ( !ep_parse_result && parser.cfp.error_list.errors.num == 0 ) {

		blog(LOG_ERROR, "-----8<----- Shader lex reformatted lines -----8<-----");
        const char **line;
        for (int r = 0; r < cfp_lex_reformatted_lines_idx.num; r++ ) {
            line = (const char **) darray_item(sizeof(const char *), &cfp_lex_reformatted_lines_idx.da, r);
            blog(LOG_ERROR, "[%4i] %s", r, *line);
        }
		blog(LOG_ERROR, "----->8---------------------------------------->8-----");
	}


	da_free(cfp_lex_reformatted_lines_idx);
	bfree(effect_string_reformated_copy);

	if ( !ep_parse_result ) obs_abort(ep_parse, "false", 21, obsepfree);

	blog(LOG_INFO, "Shader '%s' has %zu parameters", effect_file, parser.params.num);
	for (int i = 0; i < parser.params.num; i++) {
		struct ep_param *p = darray_item(sizeof(struct ep_param), &parser.params.da, i);
		blog(LOG_DEBUG, "\t%s %s %s;",
				p->is_const?"const":
				p->is_property?"property":
				p->is_uniform?"uniform":
				"",
				p->type, p->name);
	}
	blog(LOG_INFO, "Shader '%s' has %zu struct(s)", effect_file, parser.structs.num);
	for (int i = 0; i < parser.structs.num; i++) {
		struct ep_struct *s = darray_item(sizeof(struct ep_struct), &parser.structs.da, i);
		blog(LOG_DEBUG, "\tstruct %s {", s->name);
		for (int j = 0; j < s->vars.num; j++) {
			struct ep_var *v = darray_item(sizeof(struct ep_var), &s->vars.da, j);
			blog(LOG_DEBUG, "\t\t%s %s;", v->type, v->name);
		}
		blog(LOG_DEBUG, "\t}");
	}
	blog(LOG_INFO, "Shader '%s' has %zu funcs(s)", effect_file, parser.funcs.num);
	for (int i = 0; i < parser.structs.num; i++) {
		struct ep_func *f = darray_item(sizeof(struct ep_func), &parser.funcs.da, i);
		blog(LOG_DEBUG, "\t%s %s(", f->ret_type, f->name);
		for (int j = 0; j < f->param_vars.num; j++) {
			struct ep_var *v = darray_item(sizeof(struct ep_var), &f->param_vars.da, j);
			blog(LOG_DEBUG, "\t\t%s %s,", v->type, v->name);
		}
		blog(LOG_DEBUG, "\t) {...}");
	}
	blog(LOG_INFO, "Shader '%s' has %zu samplers(s)", effect_file, parser.samplers.num);
	blog(LOG_INFO, "Shader '%s' has %zu technique(s)", effect_file, parser.techniques.num);

obsepfree:
	ep_free(&parser);
	gs_leave_context();
	gs_destroy(graphics);
obsshutdown:
	obs_shutdown();
sdldestroywin:
/*
	SDL_DestroyWindow(win);
sdlquit:
	SDL_Quit();
mainexit:
	*/
	return exitcode;
}
