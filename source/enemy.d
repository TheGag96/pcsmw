import entity, util, game, mario;
import std.typecons;

abstract class Enemy : Entity {
  this(float x, float y) {
    super(x,y);
  }

  static immutable float SPINKILL_BOOST = -8.0 /16*60/16;

  alias Collided = Flag!"collided";

  protected Collided checkMarioOnTopCommon(Mario m, Direction dir) {
    if (m !is null && dir == Direction.TOP && m && m.prevY+m.height <= y) {
      if (m.spinjumping) {
        removeFlag = true;
        m.velY = SPINKILL_BOOST;
        util.playSound("spikill");
      }
      else {
        m.velY = Mario.JUMPVEL_RUN;
        m.newY = y-m.height;
        util.playSound("kick");
      }
      return Collided.yes;
    }
    return Collided.no;
  }
}