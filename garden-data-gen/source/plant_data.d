module plant_data;

import dom_utils;

import std.stdio;
import std.array;
import std.algorithm;
import std.path;
import std.file;
import std.datetime;
import std.typecons;

import dxml.dom;

struct Species {
    string id;
    string name;
    string scientificName;
    string description;
    string referenceLink;
}

struct Plant {
    string speciesScientificName;
    string identifier;
    uint generation;
    string plantingInfo;
    string description;
}

string speciesId(string scientificName) {
    import std.string;
    import std.regex;
    return scientificName
        .replaceAll(ctRegex!(`\s+`), "-")
        .replaceAll(ctRegex!(`ñ`), "n")
        .replaceAll(ctRegex!(`["“”\.]`), "")
        .toLower;
}

struct PlantData {
    Species[] species;
    Plant[] plants;

    Plant[] plantsInSpecies(Species speciesItem) {
        Appender!(Plant[]) app;
        foreach (plant; plants) {
            if (plant.speciesScientificName == speciesItem.scientificName) {
                app ~= plant;
            }
        }
        Plant[] results = app[];
        sort!((a, b) => a.identifier < b.identifier)(results);
        return results;
    }

    Species getSpecies(string name) {
        foreach (s; species) {
            if (s.scientificName == name) return s;
        }
        throw new Exception("No species with name " ~ name);
    }

    Plant getPlant(string identifier) {
        foreach (p; plants) {
            if (p.identifier == identifier) return p;
        }
        throw new Exception("No plant with identifier " ~ identifier);
    }
}

struct ImageFilePair {
    string filename;
    uint width, height;
    string thumbnailFilename;
    uint thumbnailWidth, thumbnailHeight;
}

PlantData parsePlantData(string filename) {
    import archive.zip;
    ZipArchive zip = new ZipArchive(std.file.read(filename));
    auto contentZipEntry = zip.getFile("content.xml");
    if (contentZipEntry is null) throw new Exception("Couldn't find content.xml in " ~ filename);
    DOMEntity!string dom = parseDOM(cast(string) contentZipEntry.data());
    DOMEntity!string spreadsheet = dom.findDOMChild("office:document-content")
        .findDOMChild("office:body")
        .findDOMChild("office:spreadsheet");
    DOMEntity!string speciesTable = spreadsheet.findDOMChild("table:table", ["table:name": "Species"]);
    DOMEntity!string[] speciesRows = speciesTable.findDOMChildren("table:table-row")[1..$];
    DOMEntity!string plantsTable = spreadsheet.findDOMChild("table:table", ["table:name": "Plants"]);
    DOMEntity!string[] plantRows = plantsTable.findDOMChildren("table:table-row")[1..$];

    PlantData result;
    auto speciesAppender = appender(&result.species);
    foreach (row; speciesRows) {
        if (row.children.length < 4) continue;
        Species species;
        species.name = readTableCellText(row.children[0]);
        species.scientificName = readTableCellText(row.children[1]);
        species.description = readTableCellText(row.children[2]);
        species.referenceLink = readTableCellText(row.children[3]);
        species.id = speciesId(species.scientificName);
        speciesAppender ~= species;
    }
    sort!((a, b) => a.name < b.name)(result.species);
    
    auto plantAppender = appender(&result.plants);
    foreach (row; plantRows) {
        if (row.children.length < 4) continue;
        Plant plant;
        plant.speciesScientificName = readTableCellText(row.children[0]);
        plant.identifier = readTableCellText(row.children[1]);
        string fGenStr = readTableCellText(row.children[2]);
        import std.conv : to;
        plant.generation = fGenStr[1..$].to!uint;
        plant.plantingInfo = readTableCellText(row.children[3]);
        if (row.children.length > 4) {
            plant.description = readTableCellText(row.children[4]);
        }
        plantAppender ~= plant;
    }
    sort!((a, b) => a.identifier < b.identifier)(result.plants);

    return result;
}

void ensureDirectories(PlantData data) {
	string basePath = buildPath("images", "garden");
	if (!exists(basePath)) mkdirRecurse(basePath);
	string speciesDir = buildPath(basePath, "species");
	if (!exists(speciesDir)) mkdir(speciesDir);
	foreach (s; data.species) {
		string thisSpeciesDir = buildPath(speciesDir, s.id);
		if (!exists(thisSpeciesDir)) mkdir(thisSpeciesDir);
	}
	string plantsDir = buildPath(basePath, "plants");
	if (!exists(plantsDir)) mkdir(plantsDir);
	foreach (p; data.plants) {
		string thisPlantDir = buildPath(plantsDir, p.identifier);
		if (!exists(thisPlantDir)) mkdir(thisPlantDir);
	}
}

ImageFilePair[] getPlantImages(string identifier) {
    string plantDir = buildPath("images", "garden", "plants", identifier);
    if (!exists(plantDir)) return [];
    Appender!(ImageFilePair[]) app;
    foreach (entry; dirEntries(plantDir, SpanMode.shallow, false)) {
        if (entry.name.endsWith(".jpg") && !entry.name.endsWith(".thumb.jpg")) {
            ImageFilePair pair;
            pair.filename = entry.name;
            getImageSize(entry.name, pair.width, pair.height);
            string thumbnailFilename = buildPath(plantDir, baseName(entry.name, ".jpg") ~ ".thumb.jpg");
            if (exists(thumbnailFilename)) {
                pair.thumbnailFilename = thumbnailFilename;
                getImageSize(thumbnailFilename, pair.thumbnailWidth, pair.thumbnailHeight);
            }
            app ~= pair;
        }
    }
    ImageFilePair[] images = app[];
    sort!((a, b) {
        Nullable!DateTime tsA = getImageTimestamp(a.filename);
        Nullable!DateTime tsB = getImageTimestamp(b.filename);
        if (tsA.isNull && tsB.isNull) return a.filename < b.filename;
        if (tsA.isNull) return true;
        if (tsB.isNull) return false;
        return tsA.get < tsB.get;
    })(images);
    return images;
}

ImageFilePair[] getSpeciesImages(string speciesId) {
    string speciesDir = buildPath("images", "garden", "species", speciesId);
    if (!exists(speciesDir)) return [];
    Appender!(ImageFilePair[]) app;
    foreach (entry; dirEntries(speciesDir, SpanMode.shallow, false)) {
        if (entry.name.endsWith(".jpg") && !entry.name.endsWith(".thumb.jpg")) {
            ImageFilePair pair;
            pair.filename = entry.name;
            getImageSize(entry.name, pair.width, pair.height);
            string thumbnailFilename = buildPath(speciesDir, baseName(entry.name, ".jpg") ~ ".thumb.jpg");
            if (exists(thumbnailFilename)) {
                pair.thumbnailFilename = thumbnailFilename;
                getImageSize(thumbnailFilename, pair.thumbnailWidth, pair.thumbnailHeight);
            }
            app ~= pair;
        }
    }
    ImageFilePair[] images = app[];
    sort!((a, b) {
        Nullable!DateTime tsA = getImageTimestamp(a.filename);
        Nullable!DateTime tsB = getImageTimestamp(b.filename);
        if (tsA.isNull && tsB.isNull) return a.filename < b.filename;
        if (tsA.isNull) return true;
        if (tsB.isNull) return false;
        return tsA.get < tsB.get;
    })(images);
    return images;
}

void getImageSize(string filePath, out uint width, out uint height) {
    import std.process;
    import std.format;
    auto result = execute(["identify", "-ping", "-format", "'%w %h'", filePath]);
    if (result.status != 0) throw new Exception("Failed to get image size of " ~ filePath);
    formattedRead!"'%d %d'"(result.output, width, height);
}

Nullable!DateTime getImageTimestamp(string filePath) {
    import std.regex;
    import std.conv;
    auto r = ctRegex!(`\d{8}_\d{6}`);
    auto cap = matchFirst(baseName(filePath), r);
    if (cap.empty) return Nullable!DateTime.init;
    string text = cap[0];
    return nullable(DateTime(
        text[0..4].to!int,
        text[4..6].to!int,
        text[6..8].to!int,
        text[9..11].to!int,
        text[11..13].to!int,
        text[13..15].to!int
    ));
}

void generateAllThumbnails(bool regen = false) {
    string plantsDir = buildPath("images", "garden", "plants");
    foreach (entry; dirEntries(plantsDir, SpanMode.shallow, false)) {
        generateThumbnails(entry.name, regen);
    }
    string speciesDir = buildPath("images", "garden", "species");
    foreach (entry; dirEntries(speciesDir, SpanMode.shallow, false)) {
        generateThumbnails(entry.name, regen);
    }
}

void generateThumbnails(string dir, bool regen) {
    import std.process;
    if (regen) {
        // Remove all thumbnails first.
        foreach (entry; dirEntries(dir, SpanMode.shallow, false)) {
            if (entry.name.endsWith(".thumb.jpg")) {
                std.file.remove(entry.name);
            }
        }
    }
    foreach (entry; dirEntries(dir, SpanMode.shallow, false)) {
        if (entry.name.endsWith(".jpg") && !entry.name.endsWith(".thumb.jpg")) {
            string filenameWithoutExt = baseName(entry.name, ".jpg");
            string outputFilePath = buildPath(dir, filenameWithoutExt ~ ".thumb.jpg");
            if (exists(outputFilePath)) continue;
            Pid pid = spawnProcess(
                [
                    "convert",
                    entry.name,
                    "-strip",
                    "-interlace", "JPEG",
                    "-sampling-factor", "4:2:0",
                    "-colorspace", "RGB",
                    "-quality", "85%",
                    "-geometry", "x200",
                    outputFilePath
                ]
            );
            int exitCode = wait(pid);
            if (exitCode != 0) throw new Exception("Thumbnail generation process failed.");
        }
    }
}
