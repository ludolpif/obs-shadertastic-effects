#include <fcntl.h> // open
#include <unistd.h> // lseek
#include <sys/mman.h> // mmap
#include <stdio.h> //fprintf
#include <stdlib.h> //setenv
#include <SDL2/SDL.h>
#include <SDL2/SDL_syswm.h> // SDL_GetWindowWMInfo
#include <obs/obs.h> // obs_{startup,shutdown} obs_{enter,leave}_graphics
#include <obs/graphics/graphics.h> // gs_*
#include <obs/graphics/effect.h> // struct gs_effect
#include <obs/graphics/effect-parser.h> // ep_*
#include <obs/obs-nix-platform.h> // obs_set_nix_platform_display

#define sdl_abort(funcname, code, label) do { \
	fprintf(stderr, "%s: %s", #funcname, SDL_GetError()); \
	exitcode = code; \
	goto label; } while(0)

#define obs_abort(funcname, msg, code, label) do { \
	fprintf(stderr, "%s: %s", #funcname, msg); \
	exitcode = code; \
	goto label; } while(0)

int main(void) {
#if defined(SDL_VIDEO_DRIVER_X11)
	setenv("SDL_VIDEODRIVER", "x11", 1);
#else
#error "This program has been tried only for X11 for now. Feel free to improve it"
#endif
	int exitcode = 0;

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
		case GS_SUCCESS: fprintf(stderr, "gs_create success on adapter %d\n", adapter); break;
		case GS_ERROR_FAIL: obs_abort(gs_create, "GS_ERROR_FAIL", 21, obsshutdown); break;
		case GS_ERROR_MODULE_NOT_FOUND: obs_abort(gs_create, "GS_ERROR_MODULE_NOT_FOUND:", 22, obsshutdown); break;
	       	case GS_ERROR_NOT_SUPPORTED: obs_abort(gs_create, "GS_ERROR_NOT_SUPPORTED", 23, obsshutdown); break;
	       	default: obs_abort(gs_create, "(unknown error)", 24, obsshutdown); break;
	}


	// Load shader file as effect_string
	char *effect_file = "crash_test.hlsl";
	int fd = open(effect_file, O_RDONLY);
	int len = lseek(fd, 0, SEEK_END);
	const char *effect_string = mmap(0, len, PROT_READ, MAP_PRIVATE, fd, 0);

	// fprintf(stdout, effect_string);

	gs_enter_context(graphics);
	fprintf(stderr, "gs_enter_context(graphics) done\n");

	struct effect_parser parser;
	ep_init(&parser);
	fprintf(stderr, "ep_init(&parser) done\n");

	struct gs_effect *effect = bzalloc(sizeof(struct gs_effect));
	effect->graphics = graphics;
	effect->effect_path = bstrdup(effect_file);
	if ( ! ep_parse(&parser, effect, effect_string, effect_file) ) obs_abort(ep_parse, "!true", 21, obsepfree);
	fprintf(stderr, "ep_parse(...) done\n");
/*
	if (!success) {
		if (error_string)
			*error_string =
				error_data_buildstring(&parser.cfp.error_list);
*/

	// crash dans ep_compile()
	//         da_resize(ep->effect->params, ep->params.num);
/*
gs_effect_t *gs_effect_create(const char *effect_string, const char *filename,
                  char **error_string)
		  {   
*/
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
