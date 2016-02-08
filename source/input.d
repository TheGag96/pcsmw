module smw.input;

import derelict.sdl2.sdl;

public static Controller controller;

class Controller {
  private string[int] keyMap;
  private bool[string] pressedList;
  private bool[string] wasPressedList;

  this() {
    keyMap[SDLK_UP]    = "up";
    keyMap[SDLK_DOWN]  = "down";
    keyMap[SDLK_LEFT]  = "left";
    keyMap[SDLK_RIGHT] = "right";
    keyMap[SDLK_z]     = "jump";
    keyMap[SDLK_x]     = "spinjump";
    keyMap[SDLK_a]     = "run";
    keyMap[SDLK_q]     = "debug";
    //keyMap[SDLK_s]     = "run";

    foreach (code; keyMap.byValue) {
      pressedList[code] = false;
      wasPressedList[code] = false;
    }
  }

  public bool pressed(string key) {
    return pressedList[key];
  }

  public bool wasPressed(string key) {
    return wasPressedList[key];
  }

  public bool pressedOneFrame(string key) {
    return (pressedList[key] && !wasPressedList[key]);
  }

  public void updateKeyDown(int key) {
    if (key in keyMap) 
      pressedList[keyMap[key]] = true;
  }

  public void updateKeyUp(int key) {
    if (key in keyMap)
      pressedList[keyMap[key]] = false;
  }

  public void update() {
    foreach (code; pressedList.byKey) {
      wasPressedList[code] = pressedList[code];
    }
  }
}