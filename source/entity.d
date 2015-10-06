import texture;
import std.bitmanip;

abstract class Entity {
  struct BlockedFlags {
    mixin(bitfields!(
      bool, "up", 1,
      bool, "left", 1,
      bool, "down", 1,
      bool, "right", 1,
      int, "", 4));
  } 

  public float x = 0, y = 0, velX = 0, velY = 0;
  public int drawWidth, drawHeight;
  public Texture texture;
  public BlockedFlags blocked;

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
  
  public void updatePositionX() {
    blocked.right = false;
    blocked.left = false;
    x += velX/60.0;
  }

  public void updatePositionY() {
    blocked.up = false;
    blocked.down = false;
    y += velY/60.0;
  }

  public void checkTerrainCollisionX() {
    
  }

  public void checkTerrainCollisionY() {
    if (y > 20) {
      y = 20;
      blocked.down = true;
    }
  }

}
