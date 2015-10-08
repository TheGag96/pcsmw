import util, entity;
import std.stdio;

enum BlockType {
  EMPTY,
  SOLID
}

enum Direction {
  LEFT, RIGHT, TOP, BOTTOM
}

void function(ref block, Entity, Direction)[] collisionFuncs = [null, &solidCollision];

struct block {
  BlockType type;
  rectangle bounds;
  int extraData = 0;

  float top()    { return bounds.y;               }
  float bottom() { return bounds.y+bounds.height; }
  float left()   { return bounds.x;               }
  float right()  { return bounds.x+bounds.width;  }

  void performCollision(Entity ent, Direction dir) {
    void function(ref block, Entity, Direction) func = collisionFuncs[type];
    if (func !is null) func(this, ent, dir);
  }

  bool collidesWith(Entity ent) {
    return type != BlockType.EMPTY && bounds.intersects(rectangle(ent.x, ent.y, ent.width, ent.height)); //from util
  }
}

void solidCollision(ref block b, Entity ent, Direction dir) {
  switch (dir) {
    case Direction.LEFT:
      ent.newX = b.left - ent.width;
      ent.blocked.right = true;
      ent.velX = 0;
    break;

    case Direction.RIGHT:
      ent.newX = b.right;
      ent.blocked.left = true;
      ent.velX = 0;
    break;

    case Direction.TOP:
      ent.newY = b.top - ent.height;
      ent.blocked.down = true;
      ent.velY = 0;
    break;

    case Direction.BOTTOM:
      //give leeway to jump around the block 
      if (ent.x+ent.width-b.left <= 0.375) {
        block possibleBlock = util.getBlockAt(cast(int)b.bounds.x-1, cast(int)b.bounds.y);
        if (possibleBlock.type == BlockType.EMPTY) {
          ent.x = b.left-ent.width;
        }
      }
      else if (b.right - ent.x <= 0.375) {
        block possibleBlock = util.getBlockAt(cast(int)b.bounds.x+1, cast(int)b.bounds.y);
        if (possibleBlock.type == BlockType.EMPTY) {
          ent.x = b.right;
        }
      }
      else {
        ent.newY = b.bottom;
        ent.blocked.up = true;
        ent.velY = 0;
      }
    break;

    default: break;
  }
}


