import std.typetuple;
import blocks, terrain, pipe;

alias allTypes = TypeTuple!(Terrain, Pipe);

abstract class TileObject {
  int x, y, width, height;

  abstract void draw();
  abstract void drawShadow();
  abstract block getBlockAt(int x, int y);

  static void init() {
    foreach (type; allTypes) {
      type.init();
    }
  }
}
