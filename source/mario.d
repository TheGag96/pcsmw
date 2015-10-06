import entity, texture, input, app;
import std.stdio, std.algorithm, std.math;

class Mario : Entity {
  int state = 0;
  static Texture marioTexture = null;

  bool jumping = false, spinjumping = false;

  //SMW velocities are in pixels per 16 frames; must convert each to blocks per second



  public this() {
    if (marioTexture is null) marioTexture = new Texture("data/mario.png");
    texture = marioTexture;
    x = 0; y = 0;
    velX = 0; velY = 0;
    drawWidth = 16; drawHeight = 32;
    texture.scaleX = 2; texture.scaleY = 2;
  }
  
  static immutable float GRAVITY       = 6.0 /16*60/16;
  static immutable float GRAVITY_HOLDA = 3.0 /16*60/16;

  static immutable float JUMPVEL_WALK = -80.0 /16*60/16;
  static immutable float JUMPVEL_JOG  = -90.0 /16*60/16;
  static immutable float JUMPVEL_RUN  = -95.0 /16*60/16;

  static immutable float HORIZ_ACCEL      = 15.0 /16/10*60/16;
  static immutable float FRICTION         = 1.0  /16*60/16;
  static immutable float TURNAROUND_WALK  = 3.0  /16*60/16;
  static immutable float TURNAROUND_RUN   = 5.0  /16*60/16;

  static immutable float MAX_WALK = 19.0 /16*60/16;
  static immutable float MAX_JOG  = 35.0 /16*60/16;
  static immutable float MAX_RUN  = 47.0 /16*60/16;

  static immutable float SPINJUMP_COEFF = 0.925;

  static immutable float[] SPEED_CYCLE = [0, 2 /16.0*60/16, 1 /16.0*60/16, 0, 1 /16.0*60/16];
  
  int runTimer = 0;
  static immutable int RUN_TIMER_MAX = 56;
  
  public override void logic() {
    ////
    //Handle horizontal movement
    ////

    float targetVel = MAX_WALK;
    if (controller.pressed("run")) {
      if (runTimer == RUN_TIMER_MAX) targetVel = MAX_RUN;
      else targetVel = MAX_JOG;
    }

    if (controller.pressed("left")) {
      if (velX <= 0) {
        if (velX < -targetVel-HORIZ_ACCEL) velX += FRICTION;
        else if (velX < -targetVel) velX = -targetVel-SPEED_CYCLE[game.frame % 5];
        else velX -= HORIZ_ACCEL;
      }
      else {
        if (controller.pressed("run")) velX -= TURNAROUND_RUN;
        else velX -= TURNAROUND_WALK;
      }
    }
    else if (controller.pressed("right")) {
      if (velX >= 0) {
        if (velX > targetVel+HORIZ_ACCEL) velX -= FRICTION;
        else if (velX > targetVel) velX = targetVel+SPEED_CYCLE[game.frame % 5];
        else velX += HORIZ_ACCEL;
      }
      else {
        if (controller.pressed("run")) velX += TURNAROUND_RUN;
        else velX += TURNAROUND_WALK;
      }
    }

    else if (!controller.pressed("right") && !controller.pressed("left") && blocked.down) {
      float prev = sgn(velX);
      if (velX != 0) {
        velX -= sgn(velX)*FRICTION;
      }
      if (prev != sgn(velX)) velX = 0;
    }

    if (controller.pressed("run") && abs(velX) >= MAX_JOG) {
      if (runTimer < RUN_TIMER_MAX) runTimer++;
    }
    else {
      if (runTimer > 0) runTimer--;
    }

    ////
    //Jumping (velocity depends on player speed)
    ////

    if (blocked.down) {
      float jumpCoeff = 0;

      if (controller.pressedOneFrame("jump")) {
        jumpCoeff = 1;
        jumping = true;
      }
      else if (controller.pressedOneFrame("spinjump")) {
        jumpCoeff = SPINJUMP_COEFF;
        jumping = true;
        spinjumping = true;
      }

      if (jumpCoeff != 0) {
        if      (abs(velX) >= MAX_RUN) velY = JUMPVEL_RUN*jumpCoeff;
        else if (abs(velX) >= MAX_JOG) velY = JUMPVEL_JOG*jumpCoeff;
        else                           velY = JUMPVEL_WALK*jumpCoeff;
      }
      else {
        jumping = false;
        spinjumping = false;
      }
    }

    ////
    //Gravity (amount applied depends on whether or not player is holding a jump button)
    ////

    if (controller.pressed("jump") || controller.pressed("spinjump")) velY += GRAVITY_HOLDA;
    else velY += GRAVITY;

    if (jumping) writeln(velY);
  }
  
  public override void draw() {
    texture.render(x+1/16, y+1/16, rect(0, 0, drawWidth, drawHeight));
  }

  public override void drawShadow() {
    updateAnimation();
    texture.renderShadow(x+1/16, y+1/16, rect(0, 0, drawWidth, drawHeight));
  }

  public void updateAnimation() {

  }
}
