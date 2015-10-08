import app, entity, terrain;
import std.variant;

public Entity[] entities;
public Terrain[] tileobjs;

Terrain[][long] sectors;

public int[string] variables;

public int frame = -1;