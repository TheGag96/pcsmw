module smw.entity.goomba;

import smw.entity, smw.texture, smw.util, smw.game, smw.blocks, smw.sound;
import std.stdio;

class Goomba : Enemy {
  int state = 0;

  private static animation DEFAULT = animation(0, 0, 16, 16, 2, 10.0/60);

  this(float x, float y) {
    super(x,y);

    texture = util.getTexture("goomba");
    if (texture is null) {
      texture = registerTexture("goomba", new Texture("data/goomba.png"));
    }

    if (util.getSound("kick") is null) {
      util.registerSound("kick", new Sound("data/sfx/kick.wav"));
    }

    width = 1; height = 1;
    drawWidth = 16; drawHeight = 16;
    drawOffsetX = 0; drawOffsetY = 0;
    chosenAnim = &DEFAULT;
  }

  static immutable float TERMINAL_VELOCITY = 70.0 /16*60/16;

  public override void logic() {
    switch (state) {
      case 0:
        if (direction) {
          velX = -2;
        }
        else {
          velX = 2;
        }
        velY += GRAVITY_NORMAL;
        if (velY > TERMINAL_VELOCITY) velY = TERMINAL_VELOCITY;
        flipY = false;
      break;

      case 1:
        flipY = true;
        velX = 0;
      break;

      default: break;
    }
  }

  public override void updateAnimation() {

  }

  public override void onBlockCollision(block b, Direction dir) {
    if (dir == Direction.LEFT || dir == Direction.RIGHT) {
      direction = !direction;
    }
  }

  

  public override void onEntityColliding(Entity ent, Direction dir) {
    Mario m = cast(Mario)ent;
    if (state == 0) {
      auto result = checkMarioOnTopCommon(m, dir);

      if (result == Collided.yes && !removeFlag) {
        state = 1;
      }
    }
  }

  //public override void draw() { }
}