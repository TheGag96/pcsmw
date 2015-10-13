import app, entity, terrain, sound;
import std.variant;

public Entity[] entities;
public Terrain[] tileobjs;

Terrain[][long] sectors;
Entity[][long] entitySectors;

public int[string] variables;

public int frame = -1;

Sound[string] sounds;

public float deltaTime;
public float totalTime = 0;