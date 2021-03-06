module smw.app;

import std.stdio, std.algorithm, std.string, std.conv, std.bitmanip, std.array, std.datetime;
import derelict.sdl2.sdl, derelict.sdl2.image, derelict.sdl2.mixer, derelict.sdl2.ttf;
import smw.entity, smw.tileobject, smw.input, smw.game, smw.util, smw.texture;

public int SCREEN_WIDTH = 1280;
public int SCREEN_HEIGHT = 720;

public float SCALE = 2;

public SDL_Window* WINDOW = null;
public SDL_Renderer* RENDERER = null;
public SDL_Texture* SCREEN_TEX = null;

public bool MINIMIZED = false;

bool stop = false;

long prevTime;

void main() {
  //Initialize, and quit if it fails
  if (!init()) return;

  Terrain t = new Terrain(1, 13, [
    BitArray([1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0]),
    BitArray([1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0]),
    BitArray([0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1]),
    BitArray([0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1]),
    BitArray([0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1]),
    BitArray([1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1]),
  ]);

  Terrain t2 = new Terrain(0, 20, [ BitArray([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])]);

  Pipe p1 = new Pipe(8, 8, 6, Orientation.UP, PipeColor.LAVENDER);

  util.addTileObjectToWorld(t);
  util.addTileObjectToWorld(p1);
  util.addTileObjectToWorld(t2);

  SDL_Event e;
  
  while (!stop) {
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

    checkForResize();

    //Update delta time (currStdTime is given in hecto-nanoseconds = 1*10^-7 seconds)
    long now = Clock.currStdTime();
    game.deltaTime = (now-prevTime)/10000000.0;
    prevTime = now;
    game.totalTime += game.deltaTime;
    
    if (MINIMIZED) continue;

    game.frame++;

    //Entity logic checks
    foreach (ent; game.entities) {
      ent.logic;
    }

    //Entity collision checks
    foreach (ent; game.entities) {
      ent.updatePositionX;
    }

    foreach (ent; game.entities) {
      ent.checkTerrainCollisionsX;
    }

    util.buildEntitySectors;
    foreach (ent; game.entities) {
      ent.checkEntityCollisionsX;
    }

    foreach (ent; game.entities) {
      ent.updatePositionY;
    }

    foreach (ent; game.entities) {
      ent.checkTerrainCollisionsY;
    }

    util.buildEntitySectors;
    foreach (ent; game.entities) {
      ent.checkEntityCollisionsY;
    }

    //remove entities if they were scheduled to be removed
    game.entities = game.entities.filter!(ent => !ent.removeFlag).array;

    SDL_SetRenderTarget(RENDERER, SCREEN_TEX); 
    SDL_SetRenderDrawColor(RENDERER, 0xFF, 0xFF, 0xFF, 0xFF);
    SDL_RenderClear(RENDERER);

    //Draw shadows
    foreach (obj; game.tileobjs) {
      obj.drawShadow;
    }

    foreach (ent; game.entities) {
      ent.drawShadow;
    }

    //Terrain drawing
    foreach (obj; game.tileobjs) {
      obj.draw;
    }

    //Entity drawing
    foreach (ent; game.entities) {
      ent.draw;
    }

    SDL_SetRenderTarget(RENDERER, null); 
    SDL_Rect renderQuad = {0, 0, SCREEN_WIDTH, SCREEN_HEIGHT};
    SDL_RenderCopy(RENDERER, SCREEN_TEX, null, &renderQuad);
    SDL_RenderPresent(RENDERER);
  }
  
  //Clean up everything before closing out
  quit();
}

void checkForResize() {
  int prevW = SCREEN_WIDTH, prevH = SCREEN_HEIGHT;
  SDL_GetWindowSize(WINDOW, &SCREEN_WIDTH, &SCREEN_HEIGHT);
  if (prevW != SCREEN_WIDTH || prevH != SCREEN_HEIGHT) {
    SDL_DestroyTexture(SCREEN_TEX);
    SCREEN_TEX = SDL_CreateTexture(RENDERER, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    foreach (obj; game.tileobjs) {
      if (obj.renderedTexture !is null) SDL_DestroyTexture(obj.renderedTexture);
      obj.renderedTexture = null;
    }
  }

}

///Initialize all SDL stuff and return false if it fails (this leads to the game quitting immediately)
bool init() {
  //Make Derelict load all SDL libraries
  DerelictSDL2.load();
  DerelictSDL2Image.load();
  DerelictSDL2Mixer.load();
  DerelictSDL2ttf.load();


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
  
  if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 4096) == -1) {
    writeln("Mix_OpenAudio failed");
    return false;
  }


  //Initialize a few game objects
  controller = new Controller;
  game.entities ~= new Mario(0,0);
  //game.entities ~= new Mario(3,0);
  game.entities ~= new Goomba(5, 5);
  game.entities ~= new Mushroom(8, 5);

  TileObject.init();

  prevTime = Clock.currStdTime();

  return true;
}

///Clean up all SDL objects. Called before program quits.
void quit() {
  SDL_DestroyWindow(WINDOW);
  SDL_DestroyRenderer(RENDERER);
  SDL_DestroyTexture(SCREEN_TEX);
  IMG_Quit();
  Mix_CloseAudio();
  SDL_Quit();
}
