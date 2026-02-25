/* global mostUsedTags:writable */
$(() => {
  $('body').on('click', '.most-used-tags .most-used-tag', (e) => {
    const $tagsSelect = $('select#issue_tag_list');
    const tag = e.target.innerText;
    if ($tagsSelect.find(`option[value='${  tag  }']`).length === 0) {
      const newOption = new Option(tag, tag, true, true);
      $tagsSelect.append(newOption).trigger('change');
    }

    mostUsedTags = $.grep(mostUsedTags, (t) => { return t !== tag; });
    const tagsHtml = mostUsedTags.map((tag) => {
      return `<span class="most-used-tag">${  tag  }</span>`;
    }).join(', ');

    const $mostUsedTagsContainer = $(e.target).parent('.most-used-tags');
    $mostUsedTagsContainer.empty();
    $mostUsedTagsContainer.append(tagsHtml);
  });
});
