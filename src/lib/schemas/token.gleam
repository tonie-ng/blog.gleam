import lib/utils
import lib/types
import gleam/dynamic
import sqlight.{type Connection, type Error}
import gleam/option.{type Option, None, Some}

pub fn generate(user_id: String, db: Connection) -> Result(String, Error) {
  let token = "WgMXlgN2zN5nsiZOICgm1"

  let sql =
    "
		INSERT into auth_tokens (id, token, user_id, created_at)
		VALUES (null, ?, ?, datetime('now'));
	"

  let row =
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(token), sqlight.text(user_id)],
      expecting: Ok,
    )
  case row {
    Ok(_) -> Ok(token)
    Error(err) -> Error(err)
  }
}

pub fn delete(field: String, value: String, db: Connection) -> Result(Nil, Nil) {
  let sql = "
		DELETE FROM auth_tokens
		WHERE " <> field <> " = ?;
	"

  let row =
    sqlight.query(sql, on: db, with: [sqlight.text(value)], expecting: Ok)
  case row {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(Nil)
  }
}

pub fn find(
  field: String,
  value: String,
  db: Connection,
) -> Result(Option(types.Token), Error) {
  let sql = "
		SELECT id, user_id, token, created_at
		FROM auth_tokens
		WHERE " <> field <> " = ?;
	"
  let row =
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(value)],
      expecting: decode_token(),
    )

  case row {
    Ok([tok]) | Ok([tok, ..]) -> Ok(Some(tok))
    Ok([]) -> Ok(None)
    Error(err) -> Error(err)
  }
}

pub fn drop(db: Connection) -> Result(Nil, Nil) {
  let sql =
    "
		DELETE FROM auth_tokens
	"

  let row = sqlight.query(sql, on: db, with: [], expecting: Ok)

  case row {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(Nil)
  }
}

fn decode_token() -> dynamic.Decoder(types.Token) {
  dynamic.decode4(
    types.Token,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.string),
    dynamic.element(3, dynamic.string),
  )
}
