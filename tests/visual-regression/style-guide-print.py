"""Inspect actual Chromium PDFs, not CSS declarations or PDF creation success."""
import json
import re
import sys
import hashlib

import fitz


def normalized(text):
    return re.sub(r"\s+", "", text)

def image_identity(pixmap):
    pixels = fitz.Pixmap(fitz.csRGB, pixmap) if pixmap.colorspace.n != 3 else pixmap
    if pixels.alpha:
        pixels = fitz.Pixmap(pixels, 0)
    return {"width": pixels.width, "height": pixels.height,
            "pixelSha256": hashlib.sha256(pixels.samples).hexdigest()}


def inspect(pdf_path, expected_path, paper, preview_path):
    with open(expected_path, encoding="utf-8") as source:
        expected = json.load(source)
    document = fitz.open(pdf_path)
    sizes = {"A4": (595.28, 841.89), "Letter": (612, 792)}
    width, height = sizes[paper]
    lines = []
    for page_index, page in enumerate(document):
        for block in page.get_text("dict")["blocks"]:
            for line in block.get("lines", []):
                text = "".join(span["text"] for span in line["spans"])
                lines.append({"text": normalized(text),
                              "page": page_index, "bounds": line["bbox"]})
    # Match complete extraction lines, consuming each once. A short table cell
    # cannot borrow a substring from a heading, or reuse another identical cell.
    matches = {}
    consumed = set()
    missing = []
    repeated_headers = []
    unordered_list_indices = set(expected.get("unorderedListIndices", []))
    cursor = 0
    for block_index, text in enumerate(expected["blocks"]):
        # Chromium repeats a semantic thead at a physical page boundary. Allow
        # only that exact header, inside its identified table and on a new page.
        table = next((table for table in expected.get("tables", [])
                      if table["headerIndices"] and
                      max(table["headerIndices"]) < block_index <= table["lastBlockIndex"]), None)
        if table and cursor > 0 and cursor < len(lines) and lines[cursor]["page"] > lines[cursor - 1]["page"]:
            header_cursor = cursor
            header_matches = []
            for header_index in table["headerIndices"]:
                target_header = normalized(expected["blocks"][header_index])
                accumulated_header = ""
                start_header = header_cursor
                while header_cursor < len(lines) and lines[header_cursor]["page"] == lines[cursor]["page"]:
                    accumulated_header += lines[header_cursor]["text"]
                    header_cursor += 1
                    if accumulated_header == target_header:
                        header_matches.append((start_header, header_cursor - 1))
                        break
                    if not target_header.startswith(accumulated_header):
                        break
                if accumulated_header != target_header:
                    break
            if len(header_matches) == len(table["headerIndices"]):
                consumed.update(range(cursor, header_cursor))
                repeated_headers.append({"page": lines[cursor]["page"] + 1,
                                         "headerIndices": table["headerIndices"]})
                cursor = header_cursor
        target = normalized(text)
        match = None
        accumulated = ""
        for end in range(cursor, len(lines)):
            line_text = lines[end]["text"]
            if (block_index in unordered_list_indices and end == cursor and
                    not target.startswith(line_text) and
                    target.startswith(line_text.removeprefix("\u2022"))):
                line_text = line_text.removeprefix("\u2022")
            accumulated += line_text
            if accumulated == target:
                match = (cursor, end)
                break
            if not target.startswith(accumulated):
                break
        if match is None:
            missing.append({"blockIndex": block_index, "text": text})
        else:
            matches[block_index] = match
            consumed.update(range(match[0], match[1] + 1))
            cursor = match[1] + 1
    unexpected = [{"lineIndex": index, "page": line["page"] + 1, "text": line["text"]}
                  for index, line in enumerate(lines) if index not in consumed]
    bounds = []
    orphaned = []
    images = 0
    unmatched_images = list(expected["images"])
    for index, page in enumerate(document):
        assert abs(page.rect.width - width) <= 1, f"Wrong {paper} page width"
        assert abs(page.rect.height - height) <= 1, f"Wrong {paper} page height"
        assert page.get_text().strip(), f"Blank page {index + 1}"
        # Chromium's specified 12 mm print margins, with 1 pt rounding allowance.
        printable = fitz.Rect(33, 33, page.rect.width - 33, page.rect.height - 33)
        for word in page.get_text("words"):
            if not printable.contains(fitz.Rect(word[:4])):
                bounds.append({"page": index + 1, "text": word[4], "bounds": word[:4]})
        for image in page.get_image_info(xrefs=True):
            images += 1
            identity = image_identity(fitz.Pixmap(document, image["xref"]))
            match = next((entry for entry in unmatched_images
                          if all(entry.get(key) == value for key, value in identity.items())), None)
            assert match is not None, "Unexpected or duplicated printed image identity"
            unmatched_images.remove(match)
            if not printable.contains(fitz.Rect(image["bbox"])):
                bounds.append({"page": index + 1, "image": image["bbox"]})
    assert "headings" in expected, "Missing DOM heading identity evidence"
    heading_indices = {heading["blockIndex"] for heading in expected["headings"]}
    for heading in expected["headings"]:
        block_index = heading["blockIndex"]
        assert 1 <= heading["level"] <= 6, "Invalid DOM heading level"
        if block_index not in matches:
            continue  # Already fails complete-content validation.
        start, end = matches[block_index]
        following = matches.get(block_index + 1)
        last_line = lines[end]
        next_line = lines[following[0]] if following else None
        if (lines[start]["page"] != last_line["page"] or next_line is None or
                block_index + 1 in heading_indices or
                next_line["page"] != last_line["page"] or
                next_line["bounds"][1] < last_line["bounds"][3] - 1):
            orphaned.append({"page": last_line["page"] + 1,
                             "heading": expected["blocks"][block_index],
                             "level": heading["level"], "id": heading["id"]})
    assert images == len(expected["images"]), "Printed image count differs from delivered guide"
    assert not unmatched_images, "Missing expected printed image identities"
    assert not missing, f"Missing essential text: {missing[:3]}"
    assert not unexpected, f"Unexpected unconsumed printed text: {unexpected[:3]}"
    assert not bounds, f"Clipped/out-of-bounds content: {bounds[:3]}"
    assert not orphaned, f"Orphaned headings: {orphaned[:3]}"
    # Contact sheet of every page, retained for human visual inspection.
    previews = [page.get_pixmap(matrix=fitz.Matrix(0.5, 0.5), alpha=False) for page in document]
    columns = 3
    cell_width = max(preview.width for preview in previews) + 10
    cell_height = max(preview.height for preview in previews) + 10
    sheet = fitz.Pixmap(fitz.csRGB, fitz.IRect(0, 0, columns * cell_width,
                        ((len(previews) + columns - 1) // columns) * cell_height), False)
    sheet.clear_with(225)
    for index, preview in enumerate(previews):
        preview.set_origin((index % columns) * cell_width + 5,
                           (index // columns) * cell_height + 5)
        sheet.copy(preview, preview.irect)
    sheet.save(preview_path)
    return {"pages": len(document), "paper": paper,
            "dimensionsPoints": [document[0].rect.width, document[0].rect.height],
            "expectedBlocks": len(expected["blocks"]), "missingBlocks": missing,
            "extractedLines": len(lines), "consumedLines": len(consumed),
            "unexpectedLines": unexpected,
            "repeatedTableHeaders": repeated_headers,
            "outOfBounds": bounds, "orphanedHeadings": orphaned, "printedImages": images}


if __name__ == "__main__":
    if sys.argv[1] == "--image-identities":
        print(json.dumps([image_identity(fitz.Pixmap(path)) for path in sys.argv[2:]]))
    else:
        print(json.dumps(inspect(*sys.argv[1:])))
