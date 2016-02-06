import texture, app, blocks, util, tileobject;
import std.bitmanip, std.stdio;
import derelict.sdl2.sdl;

enum Orientation {
  LEFT = 0, RIGHT, UP, DOWN
}

enum PipeColor {
  GREEN = 0,
  YELLOW,
  BLUE,
  GRAY,
  PEACH,
  ORANGE,
  DARK_GRAY,
  LAVENDER,
  LIGHT_BLUE
}

class Pipe : TileObject {
  private SDL_Texture* renderedTexture = null;

  int length;
  Orientation orientation;
  PipeColor color;

  bool flipX, flipY;


  this(int x, int y, int length, Orientation orientation, PipeColor pipeColor = PipeColor.GREEN) {
    this.x = x;
    this.y = y;
    this.length = length;
    this.orientation = orientation;
    this.color = color;

    flipX = (orientation == Orientation.RIGHT);
    flipY = (orientation == Orientation.DOWN);

    if (orientation <= Orientation.RIGHT) {
      width = length;
      height = 2;
    }
    else {
      width = 2;
      height = length;
    }
  }

  public ~this() {
    if (renderedTexture !is null) SDL_DestroyTexture(renderedTexture);
  }

  static Texture tileset;

  public static void init() {
    tileset = util.getTexture("pipes");
    if (tileset is null) {
      tileset = util.registerTexture("pipes", new Texture("data/pipes.png"));
    }
  }

  public block getBlockAt(int x, int y) {
    if (x >= this.x && x < this.x+this.width && y >= this.y && y < this.y+this.height) {
      return block(BlockType.SOLID, rectangle(x, y, 1, 1));
    }
    return block(BlockType.EMPTY, rectangle(0,0,0,0));
  }

  private void render() {
    intrect front;
    intrect longway;  

    if (orientation <= Orientation.RIGHT) {
      front = intrect(color * 32, 32, 16, 32);
      longway = intrect(color * 32, 48, 16, 32);
    }
    else {
      front = intrect(color * 32, 0, 32, 16);
      longway = intrect(color * 32, 16, 32, 16);
    }

    uint pixelFormat;
    SDL_QueryTexture(tileset.texture, &pixelFormat, null, null, null);
    renderedTexture = SDL_CreateTexture(RENDERER, pixelFormat, SDL_TEXTUREACCESS_TARGET, width*16, height*16);
    SDL_SetTextureBlendMode(renderedTexture, SDL_BLENDMODE_BLEND);

    SDL_SetRenderTarget(RENDERER, renderedTexture); 

    tileset.render(0, 0, front);

    if (orientation <= Orientation.RIGHT) {
      foreach (i; 1..length) {
        tileset.render(i, 0, longway);
      }
    }
    else {
      foreach (i; 1..length) {
        tileset.render(0, i, longway);
      }
    }

    SDL_SetRenderTarget(RENDERER, SCREEN_TEX);
  }

  public void draw() {
    if (renderedTexture is null) render();

    SDL_Rect shadowQuad = {x*16, y*16, width*16, height*16};
    SDL_SetTextureColorMod(renderedTexture, 255, 255, 255);
    SDL_SetTextureAlphaMod(renderedTexture, 255);

    SDL_RenderCopyEx(RENDERER, renderedTexture, null, &shadowQuad,
                     0, null, (flipX ? SDL_FLIP_HORIZONTAL : 0) | (flipY ? SDL_FLIP_VERTICAL : 0));
  }

  public void drawShadow() {
    if (renderedTexture is null) render();
    SDL_SetTextureColorMod(renderedTexture, 0, 0, 0);
    SDL_SetTextureAlphaMod(renderedTexture, 64);

    SDL_Rect shadowQuad = {x*16+3, y*16+3, width*16, height*16};
    SDL_RenderCopyEx(RENDERER, renderedTexture, null, &shadowQuad,
                   0, null, (flipX ? SDL_FLIP_HORIZONTAL : 0) | (flipY ? SDL_FLIP_VERTICAL : 0));
    
  }
}