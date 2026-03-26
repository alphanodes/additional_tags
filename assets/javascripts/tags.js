/* global mostUsedTags:writable, sanitizeHTML */
$(() => {
  $('body').on('click', '.most-used-tags .most-used-tag', (e) => {
    const $tagsSelect = $('select#issue_tag_list');
    const tag = e.target.textContent;
    if ($tagsSelect.find('option').filter((_, opt) => opt.value === tag).length === 0) {
      const newOption = new Option(tag, tag, true, true);
      $tagsSelect.append(newOption).trigger('change');
    }

    mostUsedTags = mostUsedTags.filter((t) => t !== tag);
    const tagsHtml = mostUsedTags.map((t) => `<span class="most-used-tag">${sanitizeHTML(t)}</span>`).join(', ');

    $(e.target).parent('.most-used-tags').html(tagsHtml);
  });
});
