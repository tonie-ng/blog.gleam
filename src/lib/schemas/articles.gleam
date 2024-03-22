import lib/utils.{generate_nanoid}
import gleam/option.{type Option, None, Some}
import gleam/json
import gleam/string_builder.{type StringBuilder}
import sqlight.{type Connection, type Error}
import lib/types
import gleam/dynamic

pub fn update_one(
  db: Connection,
  value: String,
  field: String,
  id: String,
) -> Result(String, Error) {
  let sql = "
		UPDATE articles
		SET " <> field <> " = ?, updated_at = datetime('now')
		WHERE id = ?;
	"
  let row =
    sqlight.query(
      sql,
      db,
      with: [sqlight.text(value), sqlight.text(id)],
      expecting: Ok,
    )

  case row {
    Ok(_) -> Ok(id)
    Error(err) -> Error(err)
  }
}

pub fn update(
  db: Connection,
  id: String,
  input: types.ArticleInput,
) -> Result(String, Error) {
  let sql =
    "
		UPDATE articles
		SET title = ?, body = ?, updated_at = datetime('now')
		WHERE id = ?;
	"
  let row =
    sqlight.query(
      sql,
      db,
      with: [
        sqlight.text(input.title),
        sqlight.text(input.body),
        sqlight.text(id),
      ],
      expecting: Ok,
    )

  case row {
    Ok(_) -> Ok(id)
    Error(err) -> Error(err)
  }
}

pub fn new(
  db: Connection,
  user_id: String,
  content: types.ArticleInput,
) -> Result(String, Error) {
  let id = generate_nanoid()
  let sql =
    "
		INSERT INTO articles (id, user_id, title, body, created_at, updated_at)
		VALUES (?, ?, ?, ?, datetime('now'), datetime('now'));
	"
  let row =
    sqlight.query(
      sql,
      on: db,
      with: [
        sqlight.text(id),
        sqlight.text(user_id),
        sqlight.text(content.title),
        sqlight.text(content.body),
      ],
      expecting: Ok,
    )

  case row {
    Ok(_) -> Ok(id)
    Error(err) -> Error(err)
  }
}

pub fn delete(
  db: Connection,
  field: String,
  value: String,
) -> Result(Nil, Error) {
  let sql = "
		DELETE FROM articles
		WHERE " <> field <> " = ?;
	"

  let row =
    sqlight.query(sql, on: db, with: [sqlight.text(value)], expecting: Ok)
  case row {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

pub fn find_one(
  value: String,
  db: Connection,
  field: String,
) -> Result(Option(types.Article), Error) {
  let sql = "
		SELECT * FROM articles
		WHERE " <> field <> " = ?;
	"

  let row =
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(value)],
      expecting: decode_article(),
    )
  case row {
    Ok([article]) | Ok([article, ..]) -> Ok(Some(article))
    Ok([]) -> Ok(None)
    Error(err) -> {
      Error(err)
    }
  }
}

pub fn all(db: Connection, id: String) -> Result(List(types.Article), Error) {
  let sql =
    "
		SELECT * FROM articles
		WHERE user_id = ?;
	"

  let row =
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(id)],
      expecting: decode_article(),
    )

  case row {
    Ok(articles) -> Ok(articles)
    Error(err) -> Error(err)
  }
}

pub fn article_json(id: String, article: types.Article) -> StringBuilder {
  let a =
    json.object([
      #("id", json.string(id)),
      #("title", json.string(article.title)),
      #("body", json.string(article.body)),
      #("created_at", json.string(article.created_at)),
      #("updated_at", json.string(article.updated_at)),
    ])

  json.to_string_builder(a)
}

fn decode_article() -> dynamic.Decoder(types.Article) {
  dynamic.decode6(
    types.Article,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.string),
    dynamic.element(3, dynamic.string),
    dynamic.element(4, dynamic.string),
    dynamic.element(5, dynamic.string),
  )
}
