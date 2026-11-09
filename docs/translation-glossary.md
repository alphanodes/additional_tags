# Translation glossary

Tags appear in many Redmine plugins. To keep the user interface consistent, every locale uses exactly one term for "tag", in this plugin and in every plugin that shows tags. Read this glossary before translating any text that mentions tags.

## Terms

Each term follows the majority of four translation projects with the same concept: Nextcloud (tags app), Discourse, the WordPress locale glossaries and Firefox (bookmark tags). German is a deliberate exception.

| Locale | Singular | Plural | Notes | References |
| ------ | -------- | ------ | ----- | ---------- |
| bg | етикет | етикети | | Nextcloud, Discourse, WordPress, Firefox |
| cs | štítek | štítky | genitive plural: štítků | Nextcloud, Discourse, WordPress, Firefox |
| de | TAG | TAGs | always in capitals | deliberate choice |
| en | tag | tags | | source language |
| es | etiqueta | etiquetas | | Nextcloud, Discourse, WordPress, Firefox |
| fa | برچسب | برچسب‌ها | | Nextcloud, Discourse, WordPress, Firefox |
| fr | étiquette | étiquettes | feminine | Nextcloud, Discourse, WordPress, Firefox |
| it | etichetta | etichette | feminine | Nextcloud, Discourse, Firefox (WordPress: tag) |
| ja | タグ | タグ | | Nextcloud, Discourse, WordPress, Firefox |
| ko | 태그 | 태그 | | Nextcloud, Discourse, WordPress, Firefox |
| pl | etykieta | etykiety | genitive plural: etykiet | Nextcloud, Firefox (Discourse: tagi, WordPress: none) |
| pt-BR | etiqueta | etiquetas | | Nextcloud, Discourse, Firefox (WordPress: tag) |
| ru | метка | метки | | Nextcloud, WordPress, Firefox (Discourse: теги) |
| uk | мітка | мітки | | Nextcloud, Firefox (Discourse: теґи, WordPress: позначка, тег) |
| zh | 标签 | 标签 | | Nextcloud, Discourse, WordPress, Firefox |
| zh-TW | 標籤 | 標籤 | | Nextcloud, WordPress, Firefox (Discourse: 標記) |

## Scoped and grouped tags

A tag named `name::value` is a scoped tag: an object takes only one value per name. A tag named `name:value` is a grouped tag: all tags with the same name share one color.

English keeps "scoped tag", the term of GitLab and of the README. Every other locale uses its word for "exclusive", because it names what the user notices. The references are Gitea and Forgejo, which call the same concept "Exclusive" (labels named `scope/item`); GitLab leaves the term untranslated in most locales or translates it inconsistently (German "gescoptes Label"). No product has grouped tags, their term is derived from the tag term above.

| Locale | Scoped tag | Grouped tag | References for scoped tag |
| ------ | ---------- | ----------- | ------------------------- |
| bg | ексклузивен етикет | групиран етикет | none, derived from cs and ru |
| cs | exkluzivní štítek | seskupený štítek | Gitea, Forgejo |
| de | exklusiver TAG | gruppierter TAG | Gitea, Forgejo |
| en | scoped tag | grouped tag | GitLab |
| es | etiqueta exclusiva | etiqueta agrupada | Gitea, Forgejo |
| fa | برچسب انحصاری | برچسب گروهی | none, derived |
| fr | étiquette exclusive | étiquette groupée | Gitea, Forgejo |
| it | etichetta esclusiva | etichetta raggruppata | Forgejo |
| ja | 排他タグ | グループ化タグ | Gitea, Forgejo |
| ko | 배타적 태그 | 그룹 태그 | description of Gitea and Forgejo (상호 배타적); their label 독점 means monopoly |
| pl | etykieta wykluczająca | etykieta grupowana | Forgejo |
| pt-BR | etiqueta exclusiva | etiqueta agrupada | Gitea, Forgejo |
| ru | эксклюзивная метка | сгруппированная метка | Gitea, Forgejo |
| uk | ексклюзивна мітка | згрупована мітка | Gitea, Forgejo |
| zh | 互斥标签 | 分组标签 | Gitea, Forgejo |
| zh-TW | 互斥標籤 | 分組標籤 | Gitea, Forgejo |

## Rules

- Inside a sentence, the term follows the normal capitalization and inflection of the language. Only German writes it in capitals.
- Field labels and headings start with a capital letter as usual (`Étiquettes`, `Etykiety`, `Метки`).
- A locale that is added later gets its term in this table first, checked against the same references.
- Tags of an external product that a plugin shows or filters by (for example the host tags of a monitoring system) use the term of that product's user interface in the respective locale, because users look up the values there. The table above applies to Redmine tags.

## Common mistakes

- `TAG` or `TAGs` in any locale other than German.
- The English loanword `tag`/`tags` in locales with their own term (all except en, de and the CJK scripts above).
- Synonyms instead of the term above, for example `маркер` (bg), `značka` (cs), `balise` (fr), `znacznik` (pl), `теги` (ru) or `тег` (uk).
