import std.typecons, std.stdio;
import game, blocks;

alias rectangle = Tuple!(float, "x", float, "y", float, "width", float, "height");

protected bool intersects(rectangle r, rectangle other) {
  if (r.x < other.x+other.width && r.x+r.width > other.x) {
    if (r.y < other.y+other.height && r.y+r.height > other.y) {
      return true;
    }
  }
  return false;
}

//TODO: change
block getBlockAt(int x, int y) {
  foreach (t; game.tileobjs) {
    block b = t.getBlockAt(x, y);
    if (b.type != BlockType.EMPTY) return b;
  }
  return block(BlockType.EMPTY, rectangle(0,0,0,0));
}