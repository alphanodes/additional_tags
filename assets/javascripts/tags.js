/* global mostUsedTags:writable, sanitizeHTML, AdditionalsSelect */
$(() => {
  $('body').on('click', '.most-used-tags .most-used-tag', (e) => {
    const $tagsSelect = $('select#issue_tag_list');
    const tag = e.target.textContent;
    if ($tagsSelect.find('option').filter((_, opt) => opt.value === tag).length === 0) {
      const newOption = new Option(tag, tag, true, true);
      $tagsSelect.append(newOption);
      // the select field shows a value set here only this way
      AdditionalsSelect.refresh($tagsSelect[0]);
    }

    mostUsedTags = mostUsedTags.filter((t) => t !== tag);
    const tagsHtml = mostUsedTags.map((t) => `<span class="most-used-tag">${sanitizeHTML(t)}</span>`).join(', ');

    $(e.target).parent('.most-used-tags').html(tagsHtml);
  });
});

/* Colors and labels of tags as the server gives them (AdditionalTag#tag_bg_color,
   #tag_fg_color, #tag_name, #group_value), for select fields (renderer "tag").
   test/fixtures/tag_colors.json holds examples the browser and the server are
   both tested against. SHA-256 is computed here: crypto.subtle of the browser
   is missing on pages served over plain HTTP. */
window.AdditionalTagColors = (() => {
  // first 32 bits of the fractional parts of the cube and square roots of the
  // first primes (FIPS 180-4), written out: Math.cbrt is not exact everywhere
  const K = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];
  const H = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
  const rotr = (x, n) => (x >>> n) | (x << (32 - n));

  // SHA-256 of the UTF-8 bytes of +text+ as hex, like Digest::SHA256.hexdigest
  function sha256(text) {
    const bytes = new TextEncoder().encode(text);
    const size = ((bytes.length + 72) >> 6) << 6;
    const data = new Uint8Array(size);
    data.set(bytes);
    data[bytes.length] = 0x80;
    const view = new DataView(data.buffer);
    view.setUint32(size - 8, Math.floor(bytes.length / 0x20000000));
    view.setUint32(size - 4, bytes.length * 8);
    const hash = H.slice();
    const w = new Uint32Array(64);
    for (let offset = 0; offset < size; offset += 64) {
      for (let i = 0; i < 16; i += 1) { w[i] = view.getUint32(offset + (i * 4)); }
      for (let i = 16; i < 64; i += 1) {
        const s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
        const s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
      }
      let [a, b, c, d, e, f, g, h] = hash;
      for (let i = 0; i < 64; i += 1) {
        const t1 = (h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[i] + w[i]) | 0;
        const t2 = ((rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
        h = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
      }
      [a, b, c, d, e, f, g, h].forEach((value, i) => { hash[i] = (hash[i] + value) | 0; });
    }
    return hash.map((value) => (value >>> 0).toString(16).padStart(8, '0')).join('');
  }

  // String#strip and String#split of Ruby: only null and whitespace of ASCII,
  // empty parts at the end dropped
  const strip = (text) => text.replace(/^[\0\t\n\v\f\r ]+|[\0\t\n\v\f\r ]+$/g, '');
  function split(text, separator) {
    const parts = text.split(separator);
    while (parts.length && parts[parts.length - 1] === '') { parts.pop(); }
    return parts.map(strip);
  }

  // AdditionalTags.use_colors?: every color theme but '0'
  const useColors = (theme) => String(theme ?? '') !== '0';

  // labels, scoped? and grouped? of AdditionalTag; grouping needs colors
  function partsOf(name, theme) {
    const grouping = useColors(theme);
    const scopeLabels = split(name, '::');
    const groupLabels = split(name, ':');
    const scoped = grouping && scopeLabels.length > 1;
    const grouped = grouping && groupLabels.length > 1;
    const labels = scoped ? scopeLabels : groupLabels;
    const separator = scoped ? '::' : ':';
    const groupName = labels.length > 2 ? labels.slice(0, -1).join(separator) : (labels[0] ?? '');

    return { scoped, grouped, separator, groupName, groupValue: labels[labels.length - 1] };
  }

  // the text of the tag and, for a scoped tag, its value
  function labelOf(tagName, theme) {
    const name = strip(tagName);
    const parts = partsOf(name, theme);

    return { label: parts.scoped ? parts.groupName : name, value: parts.scoped ? parts.groupValue : null };
  }

  // background and text color, null without colors
  function colorOf(tagName, theme) {
    if (!useColors(theme)) { return null; }

    const name = strip(tagName);
    const parts = partsOf(name, theme);
    let nameForColor = parts.scoped || parts.grouped ? `${parts.groupName}${parts.separator}` : name;
    if (/\S/.test(String(theme ?? '')) && theme !== '1') { nameForColor += theme; }
    const bg = `#${sha256(nameForColor).slice(0, 6)}`;
    const [r, g, b] = [1, 3, 5].map((index) => parseInt(bg.slice(index, index + 2), 16));

    return { bg, fg: (r * 299) + (g * 587) + (b * 114) >= 128000 ? 'black' : 'white' };
  }

  // the group of a scoped or grouped tag as AdditionalTag#title_group, null
  // for other tags and for a group without name
  function groupOf(tagName, theme) {
    const parts = partsOf(strip(tagName), theme);
    if (!(parts.scoped || parts.grouped) || parts.groupName === '') { return null; }

    return { scoped: parts.scoped, name: parts.groupName };
  }

  return { sha256, labelOf, colorOf, groupOf, useColors };
})();

// A tag in a select field as in tag lists: a pill in its color, a scoped tag
// with its value, a scoped or grouped tag with its title
// (ADDITIONAL_TAGS_TITLES, AdditionalTagsHelper#additional_tag_title); without
// colors only its name
window.additionalsSelectRenderers = window.additionalsSelectRenderers || {};
window.additionalsSelectRenderers.tag = (() => {
  function tagPill(item) {
    const theme = window.ADDITIONAL_TAGS_COLOR_THEME;
    const name = String(item.text ?? '');
    if (!window.AdditionalTagColors.useColors(theme)) { return name; }

    const { label, value } = window.AdditionalTagColors.labelOf(name, theme);
    const color = window.AdditionalTagColors.colorOf(name, theme);
    const pill = document.createElement('span');
    pill.className = 'additional-tag-label-color additionals-select-pill';
    pill.style.backgroundColor = color.bg;
    pill.style.color = color.fg;
    pill.append(label);
    if (value !== null) {
      const valueSpan = document.createElement('span');
      valueSpan.className = 'tag-group-value tag-group-nocount';
      valueSpan.textContent = value;
      pill.append(valueSpan);
    }
    const group = window.AdditionalTagColors.groupOf(name, theme);
    const titles = window.ADDITIONAL_TAGS_TITLES;
    // the name comes first: the select field cuts long names and otherwise
    // shows them in full as title of the entry, which this title covers
    if (group !== null && titles) {
      pill.title = `${name}\n${titles[group.scoped ? 'scoped' : 'grouped'].replace('%{name}', () => group.name)}`;
    }
    return pill;
  }

  return { result: tagPill, selection: tagPill };
})();
