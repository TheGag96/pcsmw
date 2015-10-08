import texture, blocks, util;
import std.bitmanip, std.typecons, std.math, std.stdio, std.algorithm;

abstract class Entity {
  struct BlockedFlags {
    mixin(bitfields!(
      bool, "up", 1,
      bool, "left", 1,
      bool, "down", 1,
      bool, "right", 1,
      int, "", 4));
  } 

  public float x = 0, y = 0, velX = 0, velY = 0, width, height;
  public int drawWidth, drawHeight, drawOffsetX, drawOffsetY;
  public Texture texture;
  public BlockedFlags blocked;
  public long[] occupiedSectors= [];

  public this() {
    
  }
  
  
  ///Called once per frame. All game-related entity logic goes here.
  public abstract void logic();
  
  ///Called once per frame, after logic checks. Draw graphics in this method.
  public void draw() {
    texture.render(cast(int)x, cast(int)y);
  }

  public void drawShadow() {
    texture.renderShadow(cast(int)x, cast(int)y);
  }

  public void onBlockCollision(block b, Direction dir) { }
  public void onEntityColliding(Entity other, Direction dir) { }
  public void onCollisionWithEntity(Entity other, Direction dir) { }

  ////
  //Begin collision code
  ////

  float prevX, prevY;
  float newX, newY;
  int xDirection = 0; //-1 = left, 0 = not moving, 1 = right
  int yDirection = 0; //1 = down, 0 = not moving, -1 = up

  alias rectangle = Tuple!(float, "x", float, "y", float, "width", float, "height");
  
  public void updatePositionX() {
    blocked.right = false;
    blocked.left = false;

    prevX = x;
    newX = x;

    newX += velX/60.0;

  }

  public void updatePositionY() {
    blocked.up = false;
    blocked.down = false;

    prevY = y;
    newY = y;

    newY += velY/60.0;
  }

  public void checkTerrainCollisionsX() {
    //make some new bounds, essentially a longer rectangle in the y depending on how fast the entity is going that way
    //this way, entities aren't skipped over when they're going fast!
    rectangle collisionBounds = newX > x ? rectangle(x, y, newX-x+width, height)
                                         : rectangle(newX, y, x-newX+width, height);

    //if (!collidesWithBlocks) return;

    int secondTime = 0;
    rectangle neighborBounds = boundingRectangle();
    int offset = 0;

    //Because doing both x and y updates at the same time is suicide with collisions,
    //doing them one at a time is a very simple, easy, and WORKING way to go about it.
    //first do one, check collisions in that dimension, then do the same for the other one afterward.

    //determine what the new x position will be at first

    //determine what direction the player is going
    if (newX<x) {                 //going left
      offset = -1;
      xDirection = -1;
    }
    else if (newX>x) {                //going right
      xDirection = 1;
      if (width <= .5)
        offset = 0;
      else
        offset = cast(int) round(width);
    }
    else {
      return;
    }

    //get all blocks to the left or right (depending on x Vel) of the player one block
    //away and one block up/down to get the corners
    //if it collides at all with a block, determine which way it's going and collide that way
    float deltaX = newX-x;

    //set up loop variables for high speed collision fixer loop
    int initial = -xDirection;
    int condition = cast(int)round(deltaX);

    for (int j = initial; (xDirection == 1 && j <= condition) || (xDirection == -1 && j >= condition); j+=xDirection) {    //fixes high speed collision issues
      float l = newX;
      for (int i = -1; i <= ceil(height); i++) {
        block currentBlock = util.getBlockAt(cast(int) (neighborBounds.x + offset + j), cast(int) (neighborBounds.y + i));
        if (currentBlock.type != BlockType.EMPTY && collisionBounds.intersects(currentBlock.bounds)){
          if (xDirection == 1) {
            currentBlock.performCollision(this, Direction.LEFT);
            onBlockCollision(currentBlock, Direction.RIGHT);
          }
          else {
            currentBlock.performCollision(this, Direction.RIGHT);
            onBlockCollision(currentBlock, Direction.LEFT);
          }
        }

      }
      if (newX != l)                  //if the entity's position after colliding is different from before colliding, there's no need to check anymore
          break;
    }

    x = newX;
  }

  public void checkTerrainCollisionsY() {
    //make some new bounds, essentially a longer rectangle in the y depending on how fast the entity is going that way
    //this way, entities aren't skipped over when they're going fast!
    rectangle collisionBounds = newY > y ? rectangle(x, y, width, newY-y+height)
                                         : rectangle(x, newY, width, y-newY+height);

    //if (!collidesWithBlocks) return;

    int secondTime = 0;
    rectangle neighborBounds = boundingRectangle();
    int offset = 0;

    //Because doing both x and y updates at the same time is suicide with collisions,
    //doing them one at a time is a very simple, easy, and WORKING way to go about it.
    //first do one, check collisions in that dimension, then do the same for the other one afterward.

    //determine what the new x position will be at first

    //determine what direction the player is going
    if (newY<y) {                 //going left
      offset = -1;
      yDirection = -1;
    }
    else if (newY>y) {                //going right
      yDirection = 1;
      if (height <= .5)
        offset = 0;
      else
        offset = cast(int) round(height);
    }
    else {
      return;
    }

    //get all blocks to the left or right (depending on x Vel) of the player one block
    //away and one block up/down to get the corners
    //if it collides at all with a block, determine which way it's going and collide that way
    float deltaY = newY-y;

    //set up loop variables for high speed collision fixer loop
    int initial = -yDirection;
    int condition = cast(int)round(deltaY);

    for (int j = initial; (yDirection == 1 && j <= condition) || (yDirection == -1 && j >= condition); j+=yDirection) {
      float l = newY;
      for (int i = -1; i <= ceil(width); i++) {
        block currentBlock = util.getBlockAt(cast(int) (neighborBounds.x + i),cast(int) (neighborBounds.y + offset + j));
        if (currentBlock.type != BlockType.EMPTY && collisionBounds.intersects(currentBlock.bounds)){
          if (yDirection == -1) {
            currentBlock.performCollision(this, Direction.BOTTOM);
            onBlockCollision(currentBlock, Direction.TOP);
          }
          else {
            currentBlock.performCollision(this, Direction.TOP);
            onBlockCollision(currentBlock, Direction.BOTTOM);
          }
        }

      }
      if (newY != l)                  //if the entity's position after colliding is different from before colliding, there's no need to check anymore
          break;
    }

    y = newY;
  }

  public void checkEntityCollisionsX() {
    Entity[] checkedEntities = [];

    foreach (sector; occupiedSectors) {
      foreach (ent; game.entitySectors[sector]) {
        if (ent !is this && !checkedEntities.canFind(ent) && boundingRectangle.intersects(ent.boundingRectangle)) {
          checkedEntities ~= ent;
          if (velX - ent.velX < 0) {
            onCollisionWithEntity(ent, Direction.LEFT);
            ent.onEntityColliding(ent, Direction.RIGHT);
          }
          else {
            onCollisionWithEntity(ent, Direction.RIGHT);
            ent.onEntityColliding(ent, Direction.LEFT);
          }
        }
      }
    }

    x = newX;
  }

  public void checkEntityCollisionsY() {
    Entity[] checkedEntities = [];

    foreach (sector; occupiedSectors) {
      foreach (ent; game.entitySectors[sector]) {
        if (ent !is this && !checkedEntities.canFind(ent) && boundingRectangle.intersects(ent.boundingRectangle)) {
          checkedEntities ~= ent;
          if (velY - ent.velY < 0) {
            onCollisionWithEntity(ent, Direction.BOTTOM);
            ent.onEntityColliding(ent, Direction.TOP);
          }
          else {
            onCollisionWithEntity(ent, Direction.TOP);
            ent.onEntityColliding(ent, Direction.BOTTOM);
          }
        }
      }
    }

    y = newY;
  }

  protected rectangle boundingRectangle() {
    return rectangle(cast(int)round(x), cast(int)round(y), width, height);
  }

  protected bool intersects(rectangle other) {
    if (newX < other.x+other.width && newX+width > other.x) {
      if (newY < other.y+other.height && newY+height > other.y) {
        return true;
      }
    }
    return false;
  }

}
