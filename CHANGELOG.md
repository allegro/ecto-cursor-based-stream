## [Unreleased]
### Changed
- add option to fetch records and process them in parallel, `parallel: true`
- allow to iterate over multiple fields in cursor, e.g. `cursor_field: [:id_1, :id_2]`
- allow multiple fields in starting cursor, e.g. `after_cursor: %{id_1: id1, id_2: id2}`
- allow ordering or results, e.g. `order: :desc`
- pass Ecto options to `Ecto.Repo.all/2`
- raise errors with friendly message on invalid cursor_field, invalid after_cursor and invalid custom select in Ecto query

## [1.1.0] - 2024-05-16
### Changed
- update dependencies
- improve typespecs

## [1.0.2] - 2023-03-16
### Changed
- Fix link to examples in hex docs

## [1.0.1] - 2023-02-16
### Changed
- fix: Use correct option param names in docs and type specs

## [1.0.0] - 2023-02-01
### Changed
- initial release
