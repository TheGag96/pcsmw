module smw.game;

import smw.app, smw.entity, smw.tileobject, smw.sound;
import std.variant;

public alias game = smw.game;

public Entity[] entities;
public TileObject[] tileobjs;

TileObject[][long] sectors;
Entity[][long] entitySectors;

public int[string] globals;

public int frame = -1;

Sound[string] sounds;

public float deltaTime;
public float totalTime = 0;