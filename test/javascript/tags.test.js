import { describe, it, expect, beforeAll, afterEach } from 'vitest';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { createHash } from 'crypto';

const table = JSON.parse(readFileSync(resolve('test/fixtures/tag_colors.json'), 'utf8'));

// tags.js is a classic script, executed in global scope like in the browser,
// with a stand-in for jQuery, which it only uses for a click handler
const globalEval = eval; // eslint-disable-line no-eval
beforeAll(() => {
  window.$ = () => {};
  globalEval(readFileSync(resolve('assets/javascripts/tags.js'), 'utf8'));
});

afterEach(() => { delete window.ADDITIONAL_TAGS_COLOR_THEME; });

describe('colors of tags', () => {
  // The same table the colors of the server are tested against
  // (test/unit/additional_tag_test.rb)
  it('are the colors and labels of the server', () => {
    const computed = table.map((example) => {
      const { label, value } = window.AdditionalTagColors.labelOf(example.name, example.theme);
      const color = window.AdditionalTagColors.colorOf(example.name, example.theme);

      return { ...example, bg: color?.bg ?? null, fg: color?.fg ?? null, label, value };
    });

    expect(computed).toEqual(table);
  });

  it('take the SHA-256 of any text', () => {
    const texts = ['', 'abc', 'Größe', '😀', 'x'.repeat(55), 'x'.repeat(56), 'x'.repeat(64), 'x'.repeat(1000)];
    for (let i = 0; i < 200; i += 1) {
      texts.push(Array.from({ length: i }, (_, index) => String.fromCodePoint(32 + (((index * 7919) + i) % 0x2fff))).join(''));
    }

    expect(texts.map((text) => window.AdditionalTagColors.sha256(text)))
      .toEqual(texts.map((text) => createHash('sha256').update(text, 'utf8').digest('hex')));
  });
});

describe('select fields of tags', () => {
  const renderer = () => window.additionalsSelectRenderers.tag;

  it('show a tag as a pill in its color, a scoped one with its value', () => {
    window.ADDITIONAL_TAGS_COLOR_THEME = '1';
    const plain = renderer().result({ text: 'Bug' });
    const scoped = renderer().selection({ text: 'Prio::High' });
    const expected = (name) => table.find((example) => example.name === name && example.theme === '1');

    expect([plain.className, plain.textContent, plain.style.backgroundColor, plain.style.color,
      scoped.firstChild.textContent, scoped.querySelector('.tag-group-value').textContent])
      .toEqual(['additional-tag-label-color additionals-select-pill', 'Bug', hexToRgb(expected('Bug').bg),
        expected('Bug').fg, 'Prio', 'High']);
  });

  it('show tags without colors as text, as before', () => {
    window.ADDITIONAL_TAGS_COLOR_THEME = '0';

    expect([renderer().result({ text: 'Prio::High' }), renderer().selection({ text: '<b>Bug</b>' })])
      .toEqual(['Prio::High', '<b>Bug</b>']);
  });

  it('show names as text', () => {
    window.ADDITIONAL_TAGS_COLOR_THEME = '1';

    expect(renderer().result({ text: '<img src=x onerror=alert(1)>' }).innerHTML).not.toContain('<img');
  });
});

function hexToRgb(hex) {
  const [r, g, b] = [1, 3, 5].map((index) => parseInt(hex.slice(index, index + 2), 16));
  return `rgb(${r}, ${g}, ${b})`;
}
