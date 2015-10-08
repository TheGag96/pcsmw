import std.typecons, std.stdio;
import game, blocks, terrain;

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
  auto sector = cast(long)(y/16) << 32 | cast(long)(x/16);
  if (sector in game.sectors) {
    foreach (t; game.sectors[sector]) {
      block b = t.getBlockAt(x, y);
      if (b.type != BlockType.EMPTY) return b;
    }
  }
  return block(BlockType.EMPTY, rectangle(0,0,0,0));
}

void addTileObjectToWorld(Terrain t) {
  long startSectorX = t.x/16, startSectorY = t.y/16;
  long endSectorX = (t.x+t.width)/16, endSectorY = (t.y+t.height)/16;

  foreach (i; startSectorX..endSectorX+1) {
    foreach (j; startSectorY..endSectorY+1) {
      long sectorIndex = j << 32 | i;
      if (sectorIndex !in game.sectors) {
        game.sectors[sectorIndex] = [t];
      } 
      else {
        game.sectors[sectorIndex] ~= t;
      }
    }
  }

  game.tileobjs ~= t;
}