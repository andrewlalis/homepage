import std.stdio;

import plant_data;
import content_gen;

import std.algorithm;
import std.array;
import std.path;
import std.file;

const PLANT_DATA_FILE = "garden-plant-data.ods";

void main() {
	// Navigate to the project root for all tasks, for simplicity.
	while (!exists("index.html") && !exists("upload.sh")) {
		string prev = getcwd();
		chdir("..");
		if (getcwd == prev) throw new Exception("Couldn't navigate to the project root.");
	}

	writeln("Parsing plant data from " ~ PLANT_DATA_FILE ~ "...");
	PlantData data = parsePlantData(PLANT_DATA_FILE);
	writefln!"Read %d species and %d plants."(data.species.length, data.plants.length);
	ensureDirectories(data);
	writeln("Generating thumbnails for all images...");
	generateAllThumbnails(false);
	writeln("Rendering HTML components...");
	renderHTML(data);
}
