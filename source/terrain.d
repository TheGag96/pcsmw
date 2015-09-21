import texture, app;
import std.bitmanip, std.stdio;
import derelict.sdl2.sdl;

class Terrain {
  static Texture tileset;
  //BitArray[] bits;
  int x, y;
  int width, height;

  //clipping types
  static rect TOP_LEFT     = rect(0, 0, 16, 16);
  static rect TOP          = rect(16, 0, 16, 16);
  static rect TOP_RIGHT    = rect(32, 0, 16, 16);
  static rect LEFT         = rect(0, 16, 16, 16);
  static rect CENTER       = rect(16, 16, 16, 16);
  static rect RIGHT        = rect(32, 16, 16, 16);
  static rect BOTTOM_LEFT  = rect(0, 32, 16, 16);
  static rect BOTTOM       = rect(16, 32, 16, 16);
  static rect BOTTOM_RIGHT = rect(32, 32, 16, 16);
  static rect SINGLE       = rect(48, 0, 16, 16);
  static rect COLUMN       = rect(48, 16, 16, 16);
  static rect ROW          = rect(48, 32, 16, 16);
  static rect LOW_COL      = rect(48, 48, 16, 16);
  static rect HIGH_COL     = rect(16, 48, 16, 16);
  static rect LEFT_ROW     = rect(0, 48, 16, 16);
  static rect RIGHT_ROW    = rect(32, 48, 16, 16);

  static rect CORNER_DL       = rect(16, 64, 16, 16);
  static rect CORNER_DR       = rect(0, 64, 16, 16);
  static rect CORNER_UL       = rect(16, 80, 16, 16);
  static rect CORNER_UR       = rect(0, 80, 16, 16);
  static rect CORNER_UL_DL    = rect(32, 64, 16, 16);
  static rect CORNER_UL_UR    = rect(48, 64, 16, 16);
  static rect CORNER_DL_DR    = rect(32, 80, 16, 16);
  static rect CORNER_UR_DR    = rect(48, 80, 16, 16);
  static rect CORNER_UR_DL    = rect(0, 112, 16, 16);
  static rect CORNER_UL_DR    = rect(16, 112, 16, 16);
  static rect CORNER_UR_DL_DR = rect(0, 96, 16, 16);
  static rect CORNER_UL_UR_DR = rect(16, 96, 16, 16);
  static rect CORNER_UL_UR_DL = rect(32, 96, 16, 16);
  static rect CORNER_UL_DL_DR = rect(48, 96, 16, 16);
  static rect CORNER_ALL      = rect(48, 112, 16, 16);

  //stores bit combinations of what tile image to use based on which sides
  //a block has adjacent neighboring tiles.
  //Format for pic_map: UDLR
  //Format for corner_map: (UL)(UR)(DL)(DR)
  //Ex: A tile with neighbors on the left, right, and bottom will have the combination
  //    0111, which is 7, so it will have the "TOP" tile picture.
  static rect*[] pic_map, corner_map;

  private struct tile {
    int x, y;
    rect* pic, corner;
  }

  //tile[] tiles;
  tile[long] tiles;

  //Stores rendered image of whole terrain
  private SDL_Texture* bigTex = null;


  public static void init() {
    tileset = new Texture("data/grassy.png");

    pic_map = 
    [&SINGLE,   &LEFT_ROW,    &RIGHT_ROW,    &ROW,
     &HIGH_COL, &TOP_LEFT,    &TOP_RIGHT,    &TOP,
     &LOW_COL,  &BOTTOM_LEFT, &BOTTOM_RIGHT, &BOTTOM,
     &COLUMN,   &LEFT,        &RIGHT,        &CENTER];

    corner_map = 
    [null,          &CORNER_DR,       &CORNER_DL,       &CORNER_DL_DR,
     &CORNER_UR,    &CORNER_UR_DR,    &CORNER_UR_DL,    &CORNER_UR_DL_DR,
     &CORNER_UL,    &CORNER_UL_DR,    &CORNER_UL_DL,    &CORNER_UL_DL_DR,
     &CORNER_UL_UR, &CORNER_UL_UR_DR, &CORNER_UL_UR_DL, &CORNER_ALL];
  }

  this(int x, int y, in BitArray[] bits) {
    //tiles = [];

    this.x = x*16;
    this.y = y*16;

    this.width = 16*bits[0].length;
    this.height = 16*bits.length;

    foreach (row; 0..bits.length) {  
      foreach (col; 0..bits[0].length) { 
        if (!bits[row][col]) continue;

        //Index pic_map based on
        int index = 0;
        index |= (col < bits[0].length-1 ? bits[row][col+1] : 0);    
        index |= (col > 0                ? bits[row][col-1] : 0) << 1;    
        index |= (row < bits.length-1    ? bits[row+1][col] : 0) << 2;    
        index |= (row > 0                ? bits[row-1][col] : 0) << 3;     

        int filledDiag = 0;
        filledDiag |= (row < bits.length-1 && col < bits[0].length-1 ? bits[row+1][col+1] : 0);    
        filledDiag |= (row < bits.length-1 && col > 0                ? bits[row+1][col-1] : 0) << 1;    
        filledDiag |= (row > 0 && col < bits[0].length-1             ? bits[row-1][col+1] : 0) << 2;    
        filledDiag |= (row > 0 && col > 0                            ? bits[row-1][col-1] : 0) << 3;    

        int corners = 0;
        if ((index & 0b1010) == 0b1010 && (~filledDiag & 0b1000)) corners |= 0b1000;
        if ((index & 0b1001) == 0b1001 && (~filledDiag & 0b0100)) corners |= 0b0100;
        if ((index & 0b0110) == 0b0110 && (~filledDiag & 0b0010)) corners |= 0b0010;
        if ((index & 0b0101) == 0b0101 && (~filledDiag & 0b0001)) corners |= 0b0001;

        //tiles ~= tile(col, row, pic_map[index], corner_map[corners]);
        tiles[cast(long)row << 32 | cast(long)col] = tile(col, row, pic_map[index], corner_map[corners]);
      }
    }
  }

  public ~this() {
    if (bigTex !is null) SDL_DestroyTexture(bigTex);
  }

  public void render() {
    uint pixelFormat;
    SDL_QueryTexture(tileset.texture, &pixelFormat, null, null, null);
    bigTex = SDL_CreateTexture(RENDERER, pixelFormat, SDL_TEXTUREACCESS_TARGET, width, height);
    SDL_SetTextureBlendMode(bigTex, SDL_BLENDMODE_BLEND);

    SDL_SetRenderTarget(RENDERER, bigTex); 
    foreach (a; tiles.byValue) {
      tileset.render(a.x, a.y, *(a.pic));
      if (a.corner !is null)
        tileset.render(a.x, a.y, *(a.corner));
    }

    SDL_SetRenderTarget(RENDERER, SCREEN_TEX);
  }

  public void draw() {
    //Render to big texture before drawing to screen and cache it
    //This is far, FAR faster. Thanks SO user gnidmoo    
    if (bigTex is null) render();

    if (!MINIMIZED) { 
      SDL_Rect renderQuad = {x, y, width, height};
      SDL_SetTextureColorMod(bigTex, 255, 255, 255);
      SDL_SetTextureAlphaMod(bigTex, 255);
      
      SDL_RenderCopy(RENDERER, bigTex, null, &renderQuad);
    }
  }

  public void drawShadow() {
    if (bigTex is null) render();
    if (!MINIMIZED) {
      SDL_SetTextureColorMod(bigTex, 0, 0, 0);
      SDL_SetTextureAlphaMod(bigTex, 64);

      SDL_Rect shadowQuad = {x+3, y+3, width, height};
      SDL_RenderCopy(RENDERER, bigTex, null, &shadowQuad);
    }
  }

}