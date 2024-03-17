module content_gen;

import plant_data;
import dom_utils;

import dxml.writer;
import dxml.util;

import std.stdio;
import std.path;
import std.array;
import std.algorithm;
import std.file;
import std.conv;

void renderHTML(PlantData data) {
    renderSpeciesCards(data);
    renderSpeciesPages(data);
}

private void injectContent(string filename, string startTag, string endTag, string newContent) {
    import std.file;
    string data = std.file.readText(filename);
    ptrdiff_t startIdx = indexOfStr(data, startTag);
    if (startIdx == -1) throw new Exception("Couldn't find start tag " ~ startTag);
    ptrdiff_t endIdx = indexOfStr(data, endTag);
    if (endIdx == -1) throw new Exception("Couldn't find end tag " ~ endTag);
    string prefix = data[0..(startIdx + startTag.length)];
    string suffix = data[endIdx..$];
    string newData = prefix ~ newContent ~ suffix;
    std.file.write(filename, newData);
}

private void renderSpeciesCards(PlantData data) {
    string tpl = std.file.readText(buildPath(
        "garden-data-gen", "templates", "species-card.html"
    ));
    Appender!string htmlApp;
    foreach (s; data.species) {
        string card = replaceAll(tpl, [
            "!NAME!": s.name,
            "!SCIENTIFIC_NAME!": s.scientificName,
            "!DESCRIPTION!": s.description,
            "!LINK!": "garden/species/" ~ s.id ~ ".html",
            "!REF_LINK!": s.referenceLink,
            "!REF_LINK_TEXT!": s.referenceLink
        ]);
        ImageFilePair[] imagePairs = getSpeciesImages(s.id);
        if (imagePairs.length > 0) {
            string imageFile = imagePairs[0].filename;
            string thumbnailFile = imagePairs[0].thumbnailFilename;
            string imgTag = "<img src=\"" ~ (thumbnailFile is null ? imageFile : thumbnailFile) ~ "\"/>";
            card = replaceFirst(card, "!IMAGE!", imgTag);
        } else {
            card = replaceFirst(card, "!IMAGE!", "");
        }
        htmlApp ~= "\n" ~ card;
    }
    injectContent(
		"garden.html",
		"<!--__SPECIES_LIST_START__-->",
		"<!--__SPECIES_LIST_END__-->",
		htmlApp[]
	);
}

private void renderSpeciesPages(PlantData data) {
    string tpl = std.file.readText(buildPath(
        "garden-data-gen", "templates", "species-page.html"
    ));
    string plantCardTpl = std.file.readText(buildPath(
        "garden-data-gen", "templates", "plant-card.html"
    ));
    string speciesPagesDir = buildPath("garden", "species");
    if (!exists(speciesPagesDir)) mkdirRecurse(speciesPagesDir);
    foreach (species; data.species) {
        Appender!string plantDivsApp;
        foreach (plant; data.plantsInSpecies(species)) {
            string card = replaceAll(plantCardTpl, [
                "!IDENTIFIER!": plant.identifier,
                "!GENERATION!": "F" ~ plant.generation.to!string,
                "!DESCRIPTION!": plant.description,
                "!PLANTING_INFO!": plant.plantingInfo
            ]);
            ImageFilePair[] imagePairs = getPlantImages(plant.identifier);
            Appender!string imagesApp;
            foreach (imagePair; imagePairs) {
                imagesApp ~= generatePhotoSwipeElement(imagePair);
            }
            card = replaceFirst(card, "!IMAGES!", imagesApp[]);
            plantDivsApp ~= card;
        }

        string page = replaceAll(tpl, [
            "!HEAD_TITLE!": species.name,
            "!PAGE_TITLE!": species.scientificName,
            "!ABOUT_TITLE!": "About " ~ species.name,
            "!ABOUT_TEXT!": species.description,
            "!REF_LINK!": species.referenceLink,
            "!REF_LINK_TEXT!": species.referenceLink,
            "!PLANTS_DIVS!": plantDivsApp[]
        ]);
        string pagePath = buildPath(speciesPagesDir, species.id ~ ".html");
        std.file.write(pagePath, page);
    }
}

private string generatePhotoSwipeElement(ImageFilePair imagePair) {
    import std.format;
    import std.datetime;
    import std.typecons;
    const linkFormat = "<a href=\"%s\" data-pswp-width=\"%d\" data-pswp-height=\"%d\" target=\"_blank\">";
    const thumbnailFormat = "<img src=\"%s\" alt=\"\" style=\"display: block;\"/>";
    const captionFormat = "<time datetime=\"%04d-%02d-%02d\">%s</time>";
    string linkTag = format!(linkFormat)("../../" ~ imagePair.filename, imagePair.width, imagePair.height);
    string thumbnailTag = format!(thumbnailFormat)("../../" ~ imagePair.thumbnailFilename);
    Appender!string app;
    app ~= linkTag;
    app ~= "\n    ";
    app ~= thumbnailTag;
    Nullable!DateTime imageTimestamp = getImageTimestamp(imagePair.filename);
    if (!imageTimestamp.isNull) {
        DateTime dt = imageTimestamp.get;
        app ~= "\n    ";
        app ~= format!(captionFormat)(dt.year, dt.month, dt.day, dt.date.toSimpleString);
    }
    app ~= "\n</a>\n";
    return app[];
}

ptrdiff_t indexOfStr(string source, string target) {
    for (size_t i = 0; i < source.length - target.length; i++) {
        if (source[i..i+target.length] == target) {
            return i;
        }
    }
    return -1;
}

string replaceFirst(string source, string from, string to) {
    ptrdiff_t idx = indexOfStr(source, from);
    if (idx == -1) return source;
    string pre = idx == 0 ? "" : source[0..idx];
    string post = source[idx+from.length..$];
    return pre ~ to ~ post;
}

unittest {
    assert(replaceFirst("<p>!TEST</p>", "!TEST", "test") == "<p>test</p>");
}

string replaceAll(string source, string[string] values) {
    foreach (k, v; values) {
        source = replaceFirst(source, k, v);
    }
    return source;
}
