module dom_utils;

import dxml.dom;
import dxml.writer;
import dxml.util;

import std.array;
import std.algorithm;

DOMEntity!string findDOMChild(
    DOMEntity!string parent,
    string elementName,
    string[string] attributes = string[string].init
) {
    foreach (child; parent.children) {
        if (child.type == EntityType.elementStart && child.name == elementName) {
            if (attributes.length == 0) return child;
            bool attributesMatch = true;
            foreach (attrName, attrValue; attributes) {
                bool hasValue = false;
                foreach (attr; child.attributes) {
                    if (attr.name == attrName && attr.value == attrValue) {
                        hasValue = true;
                        break;
                    }
                }
                if (!hasValue) {
                    attributesMatch = false;
                    break;
                }
            }
            if (attributesMatch) return child;
        }
    }
    throw new Exception("Could not find child element " ~ elementName ~ " in " ~ parent.name);
}

DOMEntity!string[] findDOMChildren(DOMEntity!string parent, string name) {
    DOMEntity!string[] matches;
    auto app = appender(&matches);
    foreach (child; parent.children) {
        if (child.type == EntityType.elementStart && child.name == name) {
            app ~= child;
        }
    }
    return matches;
}

string readTableCellText(DOMEntity!string cell) {
    if (
        cell.type == EntityType.elementStart &&
        cell.children.length > 0 &&
        cell.children[0].type == EntityType.elementStart &&
        cell.children[0].children.length == 1 &&
        cell.children[0].children[0].type == EntityType.text
    ) {
        return cell.children[0].children[0].text.decodeXML;
    }
    return null;
}

void writeStartTagWithAttrs(O)(
    ref XMLWriter!O writer,
    string tag,
    string[string] attributes,
    EmptyTag emptyTag = EmptyTag.no
) {
    writer.openStartTag(tag);
    foreach (k, v; attributes) {
        writer.writeAttr(k, v);
    }
    writer.closeStartTag(emptyTag);
}

void writeStartTagWithClass(O)(ref XMLWriter!O writer, string tag, string classValue) {
    writer.writeStartTagWithAttrs(tag, ["class": classValue]);
}
