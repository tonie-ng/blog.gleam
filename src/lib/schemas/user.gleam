import gleam/dynamic
import lib/utils.{generate_nanoid}
import sqlight.{type Connection, type Error}
import gleam/json
import lib/types
import gleam/string_builder.{type StringBuilder}
import gleam/option.{type Option, None, Some}

pub fn find_one(
  value: String,
  db: Connection,
  field: String,
) -> Result(Option(types.User), Error) {
  let sql = "
		SELECT id, username, email, created_at, updated_at
		FROM users
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
  let password = hash_password(input.password)

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

pub fn user_json(user: types.User) -> StringBuilder {
  let u =
    json.object([
      #("id", json.string(user.id)),
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
    dynamic.element(4, dynamic.string),
  )
}

fn hash_password(password: String) -> String {
  hash(password, [])
}

@external(erlang, "Elixir.Argon2", "hash_pwd_salt")
fn hash(password: String, list: List(a)) -> String
