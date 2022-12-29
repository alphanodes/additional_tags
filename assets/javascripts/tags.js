/* global mostUsedTags:writable */
$(function() {
  $('body').on('click', '.most-used-tags .most-used-tag', function(e) {
    var $tagsSelect = $('select#issue_tag_list');
    var tag = e.target.innerText;
    if ($tagsSelect.find('option[value=\'' + tag + '\']').length === 0) {
      var newOption = new Option(tag, tag, true, true);
      $tagsSelect.append(newOption).trigger('change');
    }

    mostUsedTags = $.grep(mostUsedTags, function(t) { return t != tag; });
    var tagsHtml = mostUsedTags.map(function(tag) {
      return '<span class="most-used-tag">' + tag + '</span>';
    }).join(', ');

    var $mostUsedTagsContainer = $(e.target).parent('.most-used-tags');
    $mostUsedTagsContainer.empty();
    $mostUsedTagsContainer.append(tagsHtml);
  });
});
