import std.typecons, std.stdio;
import game, blocks, terrain, texture;

alias rectangle = Tuple!(float, "x", float, "y", float, "width", float, "height");

private Texture[string] textures;


////
//Helpful functions
////

Texture getTexture(string name) {
  Texture* ptr = name in textures;
  return ptr is null ? null : *ptr;
}

Texture registerTexture(string name, Texture tex) {
  if (name !in textures) {
    textures[name] = tex;
  }
  return tex;
}

bool intersects(rectangle r, rectangle other) {
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

enum SECTOR_SIZE = 16;

void addTileObjectToWorld(Terrain t) {
  long startSectorX = t.x/SECTOR_SIZE,         startSectorY = t.y/SECTOR_SIZE;
  long endSectorX = (t.x+t.width)/SECTOR_SIZE, endSectorY = (t.y+t.height)/SECTOR_SIZE;

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

void buildEntitySectors() {
  foreach (list; game.entitySectors.byValue) {
    list.length = 0;
  }

  foreach (ent; game.entities) {
    ent.occupiedSectors.length = 0;

    long startSectorX = cast(long)ent.x/SECTOR_SIZE,           startSectorY = cast(long)ent.y/SECTOR_SIZE;
    long endSectorX = cast(long)(ent.x+ent.width)/SECTOR_SIZE, endSectorY = cast(long)(ent.y+ent.height)/SECTOR_SIZE;

    foreach (i; startSectorX..endSectorX+1) {
      foreach (j; startSectorY..endSectorY+1) {
        long sectorIndex = j << 32 | i;
        ent.occupiedSectors ~= sectorIndex;
        if (sectorIndex !in game.entitySectors) {
          game.entitySectors[sectorIndex] = [ent];
        } 
        else {
          game.entitySectors[sectorIndex] ~= ent;
        }
      }
    }
  }
}