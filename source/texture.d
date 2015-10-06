import std.stdio, std.string, std.typecons;
import derelict.sdl2.sdl, derelict.sdl2.image;
import app;

alias color = Tuple!(ubyte, "r", ubyte, "g", ubyte, "b");
alias rect = Tuple!(int, "x", int, "y", int, "w", int, "h");

class Texture {
  public int width, height;
  public float scaleX, scaleY;
  public SDL_Texture* texture;
  public SDL_Texture* shadowTex;
  
  public this() {
    texture = null;
    shadowTex = null;
    width = 0;
    height = 0;
  }

  public this(string path, color c = color(0, 0xFF, 0xFF), bool hasShadow = true) {
    this();
    loadFromFile(path, c);
    if (hasShadow) generateShadow;
  }

  public ~this() {
    free();
  }



  public bool loadFromFile(string path, color c = color(0, 0xFF, 0xFF)) {
    free();

    SDL_Texture* newTexture = null;
    SDL_Surface* loadedSurface = IMG_Load(path.toStringz);

    if (loadedSurface == null) {
      writeln("Can't load image ", path, "! SDL_image Error: ", IMG_GetError());
      return false;
    }

    SDL_SetColorKey(loadedSurface, SDL_TRUE, SDL_MapRGB(loadedSurface.format, c.r, c.g, c.b));
    newTexture = SDL_CreateTextureFromSurface(RENDERER, loadedSurface);

    if (newTexture is null) {
      writeln("Unable to create texture from ", path, "! SDL Error: ", SDL_GetError());
      return false;
    }

    width = loadedSurface.w;
    height = loadedSurface.h;

    SDL_FreeSurface(loadedSurface);

    texture = newTexture;
    return texture !is null;
  }

  private void generateShadow() {

  }

  public void free() {
    if (texture !is null) {
      SDL_DestroyTexture(texture);
      texture = null;
      width = 0;
      height = 0;
    }
  }

  public void render(int x, int y) {
    if (texture is null) { 
      writeln("Can't render null texture!");
      return;
    }

    SDL_Rect renderQuad = {x, y, width, height};
    if (!MINIMIZED) SDL_RenderCopy(RENDERER, texture, null, &renderQuad);
  }

  public void render(float x, float y, in rect r, bool flip = false) {

    SDL_Rect clip = {r.x, r.y, r.w, r.h};
    SDL_Rect renderQuad = {cast(int)(x*16), cast(int)(y*16), r.w, r.h};

    SDL_SetTextureColorMod(texture, 255, 255, 255);
    SDL_SetTextureAlphaMod(texture, 255);

    renderQuad.w = r.w;
    renderQuad.h = r.h;

    if (!MINIMIZED)
      SDL_RenderCopyEx(RENDERER,
                       texture,
                       &clip,
                       &renderQuad,
                       0,
                       null,
                       flip);
  }

  public void renderShadow(int x, int y) {
    if (texture is null) { 
      writeln("Can't render null texture!");
      return;
    }

    SDL_Rect renderQuad = {x+3, y+3, width, height};
    if (!MINIMIZED) SDL_RenderCopy(RENDERER, texture, null, &renderQuad);
  }

  public void renderShadow(float x, float y, in rect r, bool flip = false) {

    SDL_Rect clip = {r.x, r.y, r.w, r.h};
    SDL_Rect renderQuad = {cast(int)(x*16+3), cast(int)(y*16+3), r.w, r.h};

    SDL_SetTextureColorMod(texture, 0, 0, 0);
    SDL_SetTextureAlphaMod(texture, 64);

    renderQuad.w = r.w;
    renderQuad.h = r.h;

    if (!MINIMIZED)
      SDL_RenderCopyEx(RENDERER,
                       texture,
                       &clip,
                       &renderQuad,
                       0,
                       null,
                       flip);
  }
}