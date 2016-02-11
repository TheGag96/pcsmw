module smw.entity.mushroom;

import smw.entity, smw.texture, smw.util;

class Mushroom : Entity {
  private static animation DEFAULT = animation(0, 0, 16, 16, 1, 10.0/60);


  this(float x, float y) {
    super(x, y);

    this.velX = 1;

    texture = util.getTexture("mushroom");
    if (texture is null) {
      texture = registerTexture("mushroom", new Texture("data/mushroom.png"));
    }

    width = 15.0/16; height = 15.0/16;
    drawWidth = 16; drawHeight = 16;
    drawOffsetX = -1; drawOffsetY = -1;
    chosenAnim = &DEFAULT;
  }

  static immutable float TERMINAL_VELOCITY = 70.0 /16*60/16;

  public override void logic() {
    this.velX = 1;
    velY += GRAVITY_NORMAL;
    if (velY > TERMINAL_VELOCITY) velY = TERMINAL_VELOCITY;
  }

  public override void onEntityColliding(Entity ent, Direction dir) {
    Mario m = cast(Mario)ent;
    if (m) {
      removeFlag = true;
      if (m.powerup == Mario.Powerup.SMALL) {
        m.powerup = Mario.Powerup.BIG;
      }
    }
  }
}