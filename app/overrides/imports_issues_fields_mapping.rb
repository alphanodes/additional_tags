# frozen_string_literal: true

module ImportsIssuesFieldsMapping
  Deface::Override.new virtual_path: 'imports/_issues_fields_mapping',
                       name: 'imports-issues-fields-mapping-tag-list',
                       insert_bottom: 'div.splitcontentright',
                       original: '075c56a4bd1c609829c9d4f60969d383ad124d00',
                       partial: 'imports/tag_list_field_mapping'
end
