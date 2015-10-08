import app, entity, terrain;
import std.variant;

public Entity[] entities;
public Terrain[] tileobjs;

Terrain[][long] sectors;
Entity[][long] entitySectors;

public int[string] variables;

public int frame = -1;