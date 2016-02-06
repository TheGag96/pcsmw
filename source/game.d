import app, entity, tileobject, sound;
import std.variant;

public Entity[] entities;
public TileObject[] tileobjs;

TileObject[][long] sectors;
Entity[][long] entitySectors;

public int[string] variables;

public int frame = -1;

Sound[string] sounds;

public float deltaTime;
public float totalTime = 0;