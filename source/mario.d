import entity, texture, input, app;
import std.stdio, std.algorithm, std.math;

class Mario : Entity {
  int state = 0;
  static Texture marioTexture = null;

  bool jumping = false, spinjumping = false, runJumping = false;
  bool direction = false; //false for left, right for true

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

    if (blocked.down && (controller.pressed("down") || (!controller.pressed("right") && !controller.pressed("left")))) {
      float prev = sgn(velX);
      if (velX != 0) {
        velX -= sgn(velX)*FRICTION;
      }
      if (prev != sgn(velX)) velX = 0;
    }
    else if (controller.pressed("left")) {
      if (velX <= 0) {
        if (velX < -targetVel-HORIZ_ACCEL) velX += FRICTION;
        else if (velX < -targetVel) velX = -targetVel-SPEED_CYCLE[game.frame % 5];
        else velX -= HORIZ_ACCEL;
      }
      else {
        if (controller.pressed("run")) velX -= TURNAROUND_RUN;
        else velX -= TURNAROUND_WALK;
      }
      direction = false;
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
      direction = true;
    }


    if (controller.pressed("run") && abs(velX) >= MAX_JOG) {
      if (runTimer < RUN_TIMER_MAX) runTimer++;
    }
    else {
      if (runTimer > 0 && blocked.down) runTimer--;
    }

    if (spinjumping) {
      direction = true;
    }

    ////
    //Jumping (velocity depends on player speed)
    ////

    if (blocked.down) {
      float jumpCoeff = 0;

      if (controller.pressedOneFrame("jump")) {
        jumpCoeff = 1;
        jumping = true;
        if (abs(velX) >= MAX_RUN) runJumping = true;
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
        runJumping = false;
        if (spinjumping) {
          //TODO: fix
          //direction = cast(bool)((1-((game.frame - animStart) % (SPINNING.frames*SPINNING.delay))) / SPINNING.delay / 2);
        }
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
    int frameIndex = ((game.frame - animStart) % (chosenAnim.frames*chosenAnim.delay)) / chosenAnim.delay;
    texture.render(x + chosenAnim.offsetX/16.0, 
                   y + 1.0/16+chosenAnim.offsetY/16.0, 
                   rect(chosenAnim.x + chosenAnim.width*frameIndex, chosenAnim.y, chosenAnim.width, chosenAnim.height),
                   !direction);
  }

  public override void drawShadow() {
    updateAnimation();
    int frameIndex = ((game.frame - animStart) % (chosenAnim.frames*chosenAnim.delay)) / chosenAnim.delay;
    texture.renderShadow(x + chosenAnim.offsetX/16.0, y + 1.0/16+chosenAnim.offsetY/16.0, rect(chosenAnim.x + chosenAnim.width*frameIndex, chosenAnim.y, chosenAnim.width, chosenAnim.height), !direction);
  }

  struct animation {
    int x, y, width, height;
    int frames;
    int delay;
    int offsetX = 0, offsetY = 0;
  }

  static animation STANDING = animation(0,  0,   16, 32, 1, 1);
  static animation LOOK_UP  = animation(64,  0,   16, 32, 1, 1);
  static animation WALKING  = animation(0,  0,   16, 32, 3, 8);
  static animation DUCKING  = animation(0,  64,  16, 16, 1, 1, 0, 16);
  static animation JUMPING  = animation(0,  32,  16, 32, 1, 1);
  static animation FALLING  = animation(16, 32,  16, 32, 1, 1);
  static animation RUNNING  = animation(0,  80,  32, 32, 3, 2, -8, 0);
  static animation RUN_JUMP = animation(0,  112, 32, 32, 1, 1, -8, 0);
  static animation TURNING  = animation(48, 0, 16, 32, 1, 1);
  static animation SPINNING = animation(96, 0, 16, 32, 4, 3);

  animation* chosenAnim;
  int animStart = 0;

  public void updateAnimation() {
    animation* prev = chosenAnim;
    if (state == 0) {
      if (blocked.down) {
        if (controller.pressed("down")) {
          chosenAnim = &DUCKING;
        }
        else if (controller.pressed("left")) {
          if (velX <= -MAX_RUN) {
            chosenAnim = &RUNNING;
          }
          else if (velX <= 0) {
            chosenAnim = &WALKING;
          }
          else {
            chosenAnim = &TURNING;
          }
        }
        else if (controller.pressed("right")) {
          if (velX >= MAX_RUN) {
            chosenAnim = &RUNNING;
          }
          else if (velX >= 0) {
            chosenAnim = &WALKING;
          }
          else {
            chosenAnim = &TURNING;
          } 
        }
        else if (controller.pressed("up") && velX == 0) {
          chosenAnim = &LOOK_UP;
        }
        else {
          if (velX == 0) chosenAnim = &STANDING;
          else chosenAnim = &WALKING;
        }
      }
      else if (spinjumping) {
        chosenAnim = &SPINNING;
      }
      else if (runJumping) {
        chosenAnim = &RUN_JUMP;
      }
      else if (jumping && velY <= 0) {
        chosenAnim = &JUMPING;
      } 
      else {
        chosenAnim = &FALLING;
      }
    }
    
    if (prev != chosenAnim) {
      animStart = game.frame;
    }
  }
}
