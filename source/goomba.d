import entity, texture, util, game, blocks, mario;
import std.stdio;

class Goomba : Entity {
  int state = 0;

  private static animation DEFAULT = animation(0, 0, 16, 16, 2, 10);

  this(float x, float y) {
    super(x,y);

    texture = util.getTexture("goomba");
    if (texture is null) {
      texture = registerTexture("goomba", new Texture("data/goomba.png"));
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
    if (state == 0 && dir == Direction.TOP && m) {
      state = 1;
      m.velY = Mario.JUMPVEL_RUN;
    }
  }

  //public override void draw() { }
}