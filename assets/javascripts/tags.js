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
