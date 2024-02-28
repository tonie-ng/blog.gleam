import lib/utils
import sqlight.{type Connection}
import gleam/io

pub fn generate(user_id: String, db: Connection) -> Result(String, Nil) {
  let token = utils.generate_nanoid()

  let sql =
    "
		INSERT into auth_tokens (id, token, user_id, created_at, updated_at)
		VALUES (null, ?, ?, datetime('now'), datetime('now'));
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
    Error(err) -> {
      io.debug(err)
      Error(Nil)
    }
  }
}

pub fn delete(field: String, value: String, db: Connection) {
  let sql = "
		DELETE FROM auth_tokens
		WHERE " <> field <> " = ?;
	"

  let row =
    sqlight.query(sql, on: db, with: [sqlight.text(value)], expecting: Ok)

  case row {
    Ok(_) -> Ok(Nil)
    Error(_) -> {
      Error(Nil)
    }
  }
}

pub fn drop(db: Connection) {
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
