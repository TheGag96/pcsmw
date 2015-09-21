import entity, texture, input, app;

class Mario : Entity {
  int state = 0;

  public this() {
    texture = new Texture("data/mario.png");
    x = 0; y = 0;
    velX = 0; velY = 0;
    drawWidth = 16; drawHeight = 32;
    texture.scaleX = 2; texture.scaleY = 2;
  }
  
  public override void logic() {
    if (controller.pressed("left")) {
      velX = -5;
    }
    else if (controller.pressed("right")) {
      velX = 5;
    }

    if (controller.pressed("up")) {
      velY = 5;
    }
    else if (controller.pressed("down")) {
      velY = -5;
    }

  }
  
  public override void draw() {
    texture.render(x, y, rect(0, 0, drawWidth, drawHeight));
  }

  public override void drawShadow() {
    texture.renderShadow(x, y, rect(0, 0, drawWidth, drawHeight));
  }
}
