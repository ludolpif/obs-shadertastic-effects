.PHONY: all clean
all: crash_test sdl_helloworld

clean:
	rm crash_test sdl_helloworld

crash_test: crash_test.c
	$(CC) -Wall -g crash_test.c -lSDL2 -lobs -o $@

sdl_helloworld: sdl_helloworld.c
	$(CC) -Wall -g sdl_helloworld.c -lSDL2 -o $@
