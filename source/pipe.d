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
  int length;
  Orientation orientation;
  PipeColor color;

  static Texture pipeSet;

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

    tileset = pipeSet;
  }


  public static void init() {
    pipeSet = util.getTexture("pipes");
    if (pipeSet is null) {
      pipeSet = util.registerTexture("pipes", new Texture("data/pipes.png"));
    }
  }

  public block getBlockAt(int x, int y) {
    if (x >= this.x && x < this.x+this.width && y >= this.y && y < this.y+this.height) {
      return block(BlockType.SOLID, rectangle(x, y, 1, 1));
    }
    return block(BlockType.EMPTY, rectangle(0,0,0,0));
  }

  protected void preRenderTiles() {
    intrect front;
    intrect longway;  

    if (this.orientation <= Orientation.RIGHT) {
      front = intrect(this.color * 32, 32, 16, 32);
      longway = intrect(this.color * 32, 48, 16, 32);
    }
    else {
      front = intrect(this.color * 32, 0, 32, 16);
      longway = intrect(this.color * 32, 16, 32, 16);
    }
    
    pipeSet.render(0, 0, front);

    if (this.orientation <= Orientation.RIGHT) {
      foreach (i; 1..this.length) {
        tileset.render(i, 0, longway);
      }
    }
    else {
      foreach (i; 1..this.length) {
        tileset.render(0, i, longway);
      }
    }
  }
}