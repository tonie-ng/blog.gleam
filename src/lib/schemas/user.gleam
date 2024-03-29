import gleam/dynamic
import lib/utils.{generate_nanoid}
import sqlight.{type Connection, type Error}
import gleam/json
import lib/types
import gleam/string_builder.{type StringBuilder}
import gleam/option.{type Option, None, Some}

pub fn update(
  db: Connection,
  id: String,
  input: types.UpdateUser,
) -> Result(String, Error) {
  let sql =
    "
		UPDATE users
		SET email = ?, username = ?, password = ?, updated_at = datetime('now')
		WHERE id = ?;
	"
  let password = hash(input.password, [])
  let row =
    sqlight.query(
      sql,
      db,
      with: [
        sqlight.text(input.email),
        sqlight.text(input.username),
        sqlight.text(password),
        sqlight.text(id),
      ],
      expecting: Ok,
    )

  case row {
    Ok(_) -> Ok(id)
    Error(err) -> Error(err)
  }
}

pub fn update_one(
  db: Connection,
  value: String,
  field: String,
  id: String,
) -> Result(String, Error) {
  let sql = "
		UPDATE users
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

pub fn find_one(
  value: String,
  db: Connection,
  field: String,
) -> Result(Option(types.User), Error) {
  let sql = "
		SELECT * FROM users
		WHERE " <> field <> " = ?;
	"

  let row =
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(value)],
      expecting: decode_user(),
    )
  case row {
    Ok([user]) | Ok([user, ..]) -> Ok(Some(user))
    Ok([]) -> Ok(None)
    Error(err) -> Error(err)
  }
}

pub fn all(db: Connection) -> Result(List(types.User), Error) {
  let sql = "SELECT * FROM users;"

  let row = sqlight.query(sql, on: db, with: [], expecting: decode_user())
  case row {
    Ok(users) -> Ok(users)
    Error(err) -> Error(err)
  }
}

pub fn delete(
  value: String,
  db: Connection,
  field: String,
) -> Result(Nil, Error) {
  let sql = "
		DELETE FROM users
		WHERE " <> field <> " = ?;
	"

  let row =
    sqlight.query(sql, on: db, with: [sqlight.text(value)], expecting: Ok)
  case row {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

pub fn create(input: types.SignUp, db: Connection) -> Result(String, Error) {
  let id = generate_nanoid()
  let sql =
    "
		INSERT INTO users (id, username, email, password, created_at, updated_at)
		VALUES (?, ?, ?, ?, datetime('now'), datetime('now'));
	"
  let password = hash(input.password, [])

  let row =
    sqlight.query(
      sql,
      on: db,
      with: [
        sqlight.text(id),
        sqlight.text(input.username),
        sqlight.text(input.email),
        sqlight.text(password),
      ],
      expecting: Ok,
    )

  case row {
    Ok(_) -> Ok(id)
    Error(err) -> Error(err)
  }
}

pub fn user_json(id: String, user: types.User) -> StringBuilder {
  let u =
    json.object([
      #("id", json.string(id)),
      #("email", json.string(user.email)),
      #("username", json.string(user.username)),
      #("created_at", json.string(user.created_at)),
      #("updated_at", json.string(user.updated_at)),
    ])

  json.to_string_builder(u)
}

fn decode_user() -> dynamic.Decoder(types.User) {
  dynamic.decode6(
    types.User,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.string),
    dynamic.element(3, dynamic.string),
    dynamic.element(4, dynamic.string),
    dynamic.element(5, dynamic.string),
  )
}

@external(erlang, "Elixir.Argon2", "hash_pwd_salt")
pub fn hash(password: String, list: List(a)) -> String
