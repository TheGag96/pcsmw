import std.stdio, std.algorithm, std.string, std.conv, std.bitmanip, core.memory;
import derelict.sdl2.sdl, derelict.sdl2.image, derelict.sdl2.mixer, derelict.sdl2.ttf;
import texture, entity, mario, input, game, terrain;

public immutable int SCREEN_WIDTH = 1280;
public immutable int SCREEN_HEIGHT = 720;

public float SCALE = 2;

public SDL_Window* WINDOW = null;
public SDL_Renderer* RENDERER = null;
public SDL_Texture* SCREEN_TEX = null;

public bool MINIMIZED = false;

bool stop = false;

void main() {
  //Initialize, and quit if it fails
  if (!init()) return;

  Mario mario = new Mario;

  Terrain t = new Terrain(10, 10, [
    BitArray([1, 0, 1, 1, 1, 0]),
    BitArray([1, 1, 1, 1, 1, 0]),
    BitArray([0, 0, 1, 1, 1, 0]),
    BitArray([0, 0, 1, 1, 1, 0]),
    BitArray([0, 0, 0, 1, 1, 0]),
    BitArray([0, 1, 1, 0, 0, 1]),
  ]);

  game.tileobjs ~= t;

  SDL_Event e;
  
  while (!stop) {
    //GC.disable;

    //pre-event polling
    controller.update;

    //SDL Events
    while (SDL_PollEvent(&e) != 0) {
      if (e.type == SDL_QUIT) {
        stop = true;
      }
      else if (e.type == SDL_KEYDOWN) {
        controller.updateKeyDown(e.key.keysym.sym);
      }
      else if (e.type == SDL_KEYUP) {
        controller.updateKeyUp(e.key.keysym.sym);
      }
      else if (e.type ==SDL_WINDOWEVENT) {
        if (e.window.event == SDL_WINDOWEVENT_MINIMIZED) {
          MINIMIZED = true;
        }
        else if (e.window.event == SDL_WINDOWEVENT_RESTORED) {
          MINIMIZED = false;
        }
      }
    }
    
    if (MINIMIZED) continue;

    game.frame++;

    //Entity logic checks
    foreach (ent; game.entities) {
      ent.logic;
    }

    //Entity collision checks
    foreach (ent; game.entities) {
      ent.updatePositionY;
    }

    foreach (ent; game.entities) {
      ent.updatePositionX;
    }

    foreach (ent; game.entities) {
      ent.checkTerrainCollisionY;
    }

    foreach (ent; game.entities) {
      ent.checkTerrainCollisionX;
    }

    SDL_SetRenderTarget(RENDERER, SCREEN_TEX); 
    SDL_SetRenderDrawColor(RENDERER, 0xFF, 0xFF, 0xFF, 0xFF);
    SDL_RenderClear(RENDERER);


    //Draw shadows
    t.drawShadow;
    foreach (ent; game.entities) {
      ent.drawShadow;
    }

    //Terrain drawing
    t.draw;

    //Entity drawing
    foreach (ent; game.entities) {
      ent.draw;
    }



    SDL_SetRenderTarget(RENDERER, null); 
    static immutable SDL_Rect renderQuad = {0, 0, SCREEN_WIDTH, SCREEN_HEIGHT};
    SDL_RenderCopy(RENDERER, SCREEN_TEX, null, &renderQuad);
    SDL_RenderPresent(RENDERER);

    //Delay for next frame
    //SDL_Delay(16);
    //GC.enable;
    
  }
  
  //Clean up everything before closing out
  quit();
}

///Initialize all SDL stuff and return false if it fails (this leads to the game quitting immediately)
bool init() {
  //Make Derelict load all SDL libraries
  version (Windows) {
    DerelictSDL2.load("dlls\\SDL2.dll");
    DerelictSDL2Image.load("dlls\\SDL2_image.dll");
    DerelictSDL2Mixer.load("dlls\\SDL2_mixer.dll");
    DerelictSDL2ttf.load("dlls\\SDL2_ttf.dll");
  }
  else {
    DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2ttf.load();
  }

  //Load SDL Window and Renderer, checking for errors
  if (SDL_Init( SDL_INIT_VIDEO ) < 0) {
    writeln("SDL could not initialize!");
    return false;
  }

  WINDOW = SDL_CreateWindow("PC Mario Maker", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_RESIZABLE);
  if (WINDOW is null) {
    writeln("Window could not be created! SDL_Error: ", SDL_GetError());
    return false;
  }

  RENDERER = SDL_CreateRenderer(WINDOW, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
  if (RENDERER is null) {
    writeln("Renderer could not be created! SDL Error: ", SDL_GetError());
    return false;
  }

  SDL_SetRenderDrawColor(RENDERER, 0xFF, 0xFF, 0xFF, 0xFF);
  SDL_RenderSetScale(RENDERER, SCALE, SCALE);
  int imgFlags = IMG_INIT_PNG;
  if (!(IMG_Init(imgFlags) & imgFlags)) {
    writeln("SDL_image could not initialize! SDL_image Error: ", IMG_GetError());
    return false;
  }

  SCREEN_TEX = SDL_CreateTexture(RENDERER, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, SCREEN_WIDTH, SCREEN_HEIGHT);
  

  //Initialize a few game objects
  controller = new Controller;
  game.entities ~= new Mario;
  Terrain.init();

  return true;
}

///Clean up all SDL objects. Called before program quits.
void quit() {
  SDL_DestroyWindow(WINDOW);
  SDL_DestroyRenderer(RENDERER);
  SDL_DestroyTexture(SCREEN_TEX);
  IMG_Quit();
  SDL_Quit();
}
