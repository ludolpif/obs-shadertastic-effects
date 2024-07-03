#include <stdio.h> //fprintf
#include <stdlib.h> //setenv
#include <SDL2/SDL.h>
#include <SDL2/SDL_syswm.h>

#define sdl_abort(funcname, code, label) { \
    fprintf(stderr, "%s: %s", #funcname, SDL_GetError()); \
    exitcode = code; \
    goto label; }

int main(int, char**){
    int exitcode = 0;
#if defined(SDL_VIDEO_DRIVER_X11)
    setenv("SDL_VIDEODRIVER", "x11", 1);
#else
#error "This program has been tried only for X11 for now. Feel free to improve it"
#endif
	if (SDL_Init(SDL_INIT_VIDEO) != 0) sdl_abort(SDL_Init, 2, mainexit);

    SDL_Window *win = SDL_CreateWindow("OBS tester", 100, 100, 640, 480, SDL_WINDOW_SHOWN);
	if (!win) sdl_abort(SDL_CreateWindow, 3, sdlquit);

    SDL_Renderer *ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
	if (!ren) sdl_abort(SDL_CreateRenderer, 4, sdldestroywin);

    SDL_SysWMinfo info;
    SDL_VERSION(&info.version);
    if (!SDL_GetWindowWMInfo(win, &info)) sdl_abort(SDL_GetWindowWMInfo, 6, sdldestroyren);
    Display *display = info.info.x11.display;

    printf("Display: %p\n", display);
    /*
    SDL_Surface *bmp = SDL_LoadBMP("hello.bmp");
	if (!bmp) sdl_abort(SDL_LoadBMP, 5, sdldestroyren);

    SDL_Texture *tex = SDL_CreateTextureFromSurface(ren, bmp);
	SDL_FreeSurface(bmp);
	if (!tex) sdl_abort(SDL_CreateTextureFromSurface, 6, sdldestroyren);

    for (int i = 0; i < 3; ++i){
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, NULL, NULL);
        SDL_RenderPresent(ren);
        SDL_Delay(100);
    }


sdldestroytex:
    SDL_DestroyTexture(tex);
*/
sdldestroyren:
    SDL_DestroyRenderer(ren);
sdldestroywin:
    SDL_DestroyWindow(win);
sdlquit:
	SDL_Quit();
mainexit:
	return exitcode;
}

