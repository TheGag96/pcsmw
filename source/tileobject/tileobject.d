module smw.tileobject.tileobject;

import std.typetuple, derelict.sdl2.sdl;
import smw.blocks, smw.tileobject, smw.texture, smw.app;

alias allTypes = TypeTuple!(Terrain, Pipe);

abstract class TileObject {
  int x, y, width, height;
  bool flipX, flipY;
  Texture tileset;

  abstract block getBlockAt(int x, int y);
  abstract void renderTiles();

  static void init() {
    foreach (type; allTypes) {
      type.init();
    }
  }

  SDL_Texture* renderedTexture;

  public ~this() {
    if (renderedTexture !is null) SDL_DestroyTexture(renderedTexture);
  }
  
  private void render() {
    if (renderedTexture !is null) SDL_DestroyTexture(renderedTexture);
    
    uint pixelFormat;
    SDL_QueryTexture(tileset.texture, &pixelFormat, null, null, null);
    renderedTexture = SDL_CreateTexture(RENDERER, pixelFormat, SDL_TEXTUREACCESS_TARGET, width*16, height*16);
    SDL_SetTextureBlendMode(renderedTexture, SDL_BLENDMODE_BLEND);

    SDL_SetRenderTarget(RENDERER, renderedTexture); 

    renderTiles();

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