module smw.tileobject.terrain;

import smw.texture, smw.app, smw.blocks, smw.util, smw.tileobject;
import std.bitmanip, std.stdio;
import derelict.sdl2.sdl;

class Terrain : TileObject {
  static Texture terrainSet;

  //BitArray[] bits;
  //int x, y;
  //int width, height;

  //clipping types
  static intrect TOP_LEFT     = intrect(0, 0, 16, 16);
  static intrect TOP          = intrect(16, 0, 16, 16);
  static intrect TOP_RIGHT    = intrect(32, 0, 16, 16);
  static intrect LEFT         = intrect(0, 16, 16, 16);
  static intrect CENTER       = intrect(16, 16, 16, 16);
  static intrect RIGHT        = intrect(32, 16, 16, 16);
  static intrect BOTTOM_LEFT  = intrect(0, 32, 16, 16);
  static intrect BOTTOM       = intrect(16, 32, 16, 16);
  static intrect BOTTOM_RIGHT = intrect(32, 32, 16, 16);
  static intrect SINGLE       = intrect(48, 0, 16, 16);
  static intrect COLUMN       = intrect(48, 16, 16, 16);
  static intrect ROW          = intrect(48, 32, 16, 16);
  static intrect LOW_COL      = intrect(48, 48, 16, 16);
  static intrect HIGH_COL     = intrect(16, 48, 16, 16);
  static intrect LEFT_ROW     = intrect(0, 48, 16, 16);
  static intrect RIGHT_ROW    = intrect(32, 48, 16, 16);

  static intrect CORNER_DL       = intrect(16, 64, 16, 16);
  static intrect CORNER_DR       = intrect(0, 64, 16, 16);
  static intrect CORNER_UL       = intrect(16, 80, 16, 16);
  static intrect CORNER_UR       = intrect(0, 80, 16, 16);
  static intrect CORNER_UL_DL    = intrect(32, 64, 16, 16);
  static intrect CORNER_UL_UR    = intrect(48, 64, 16, 16);
  static intrect CORNER_DL_DR    = intrect(32, 80, 16, 16);
  static intrect CORNER_UR_DR    = intrect(48, 80, 16, 16);
  static intrect CORNER_UR_DL    = intrect(0, 112, 16, 16);
  static intrect CORNER_UL_DR    = intrect(16, 112, 16, 16);
  static intrect CORNER_UR_DL_DR = intrect(0, 96, 16, 16);
  static intrect CORNER_UL_UR_DR = intrect(16, 96, 16, 16);
  static intrect CORNER_UL_UR_DL = intrect(32, 96, 16, 16);
  static intrect CORNER_UL_DL_DR = intrect(48, 96, 16, 16);
  static intrect CORNER_ALL      = intrect(48, 112, 16, 16);

  //stores bit combinations of what tile image to use based on which sides
  //a block has adjacent neighboring tiles.
  //Format for pic_map: UDLR
  //Format for corner_map: (UL)(UR)(DL)(DR)
  //Ex: A tile with neighbors on the left, right, and bottom will have the combination
  //    0111, which is 7, so it will have the "TOP" tile picture.
  static intrect*[] pic_map, corner_map;

  private struct tile {
    int x, y;
    intrect* pic, corner;
  }

  //tile[] tiles;
  tile[long] tiles;

  //Stores rendered image of whole terrain
  private SDL_Texture* bigTex = null;


  public static void init() {
    terrainSet = util.getTexture("grassy");
    if (terrainSet is null) {
      terrainSet = util.registerTexture("grassy", new Texture("data/grassy.png"));
    }

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

    this.x = x;
    this.y = y;

    this.width = cast(int)bits[0].length;
    this.height = cast(int)bits.length;

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
        tiles[cast(long)(row+y) << 32 | cast(long)(col+x)] = tile(cast(int)(col+x), cast(int)(row+y), pic_map[index], corner_map[corners]);
      }
    }

    tileset = terrainSet;
  }

  public block getBlockAt(int x, int y) {
    if ((cast(long)y << 32 | cast(long)x) in tiles) {
      return block(BlockType.SOLID, rectangle(x, y, 1, 1));
    }
    return block(BlockType.EMPTY, rectangle(0,0,0,0));
  }

  protected void renderTiles() {
    foreach (a; tiles.byValue) {
      this.tileset.render(a.x-x, a.y-y, *(a.pic));
      if (a.corner !is null)
        this.tileset.render(a.x-x, a.y-y, *(a.corner));
    }
  }
}