module smw.sound;

import derelict.sdl2.mixer, std.string, std.stdio;

class Sound {
  Mix_Chunk* snd;

  this() {
    snd = null;
  }

  this(string filename) {
    loadFromFile(filename);
  }

  ~this() {
    free();
  }

  void free() {
    if (snd is null) Mix_FreeChunk(snd);
  }

  void loadFromFile(string filename) {
    free();
    snd = Mix_LoadWAV(filename.toStringz);
    if (snd is null) {
      writeln("Error: Could not load sound \"", filename, "\"!");
    }
  }

  void play() {
    if (snd !is null) {
      Mix_PlayChannel(-1, snd, 0);
    }
  }
}