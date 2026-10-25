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

## Rules

- Inside a sentence, the term follows the normal capitalization and inflection of the language. Only German writes it in capitals.
- Field labels and headings start with a capital letter as usual (`Étiquettes`, `Etykiety`, `Метки`).
- A locale that is added later gets its term in this table first, checked against the same references.

## Common mistakes

- `TAG` or `TAGs` in any locale other than German.
- The English loanword `tag`/`tags` in locales with their own term (all except en, de and the CJK scripts above).
- Synonyms instead of the term above, for example `маркер` (bg), `značka` (cs), `balise` (fr), `znacznik` (pl), `теги` (ru) or `тег` (uk).
