module smw.entity.enemy;

import smw.entity, smw.util, smw.game;
import std.typecons, std.conv;

abstract class Enemy : Entity {
  this(float x, float y) {
    super(x, y);

    util.loadSound("hit1", "data/sfx/hit1.wav");
    util.loadSound("hit2", "data/sfx/hit2.wav");
    //util.loadSound("hit3", "data/sfx/hit3.wav");
    //util.loadSound("hit4", "data/sfx/hit4.wav");
    //util.loadSound("hit5", "data/sfx/hit5.wav");
    //util.loadSound("hit6", "data/sfx/hit6.wav");
    util.loadSound("1up", "data/sfx/1up.wav");
    util.loadSound("spinkill", "data/sfx/spinkill.wav");
    util.loadSound("kick", "data/sfx/kick.wav");
  }

  static immutable float SPINKILL_BOOST = -8.0 /16*60/16;

  alias Collided = Flag!"collided";

  protected Collided checkMarioOnTopCommon(Mario m, Direction dir) {
    if (m !is null && dir == Direction.TOP && m.prevY+m.height <= y) {
      if (m.spinjumping) {
        removeFlag = true;
        m.velY = SPINKILL_BOOST;
        util.playSound("spinkill");
      }
      else {
        m.velY = Mario.JUMPVEL_RUN;
        m.newY = y-m.height;
        m.consecutiveEnemyBounces++;
        util.playSound("hit"~m.consecutiveEnemyBounces.to!string); 
      }
      return Collided.yes;
    }
    return Collided.no;
  }

  protected Collided checkMarioSideCommon(Mario m, Direction dir) {
    if (m !is null && (dir == Direction.LEFT || dir == Direction.RIGHT)) {
      //TODO
      return Collided.yes;
    }
    return Collided.no;
  }
}