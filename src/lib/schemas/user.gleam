import gleam/dynamic
import lib/utils.{generate_nanoid}
import sqlight.{type Connection, type Error}
import gleam/json
import lib/types
import gleam/string_builder.{type StringBuilder}
import gleam/option.{type Option, None, Some}

pub fn create(
  input: types.SignUp,
  db: Connection,
) -> Result(Option(types.User), Error) {
  let id = generate_nanoid()
  let sql =
    "
		INSERT INTO users (id, username, email, password, created_at, updated_at)
		VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))
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
      expecting: decode_user(),
    )

  case row {
    Ok([user]) | Ok([user, ..]) -> Ok(Some(user))
    Ok([]) -> Ok(None)
    Error(err) -> Error(err)
  }
}

pub fn user_json(user: types.User) -> StringBuilder {
  let u =
    json.object([
      #("id", json.string(user.id)),
      #("email", json.string(user.email)),
      #("username", json.string(user.username)),
      #("created_at", json.int(user.created_at)),
      #("updated_at", json.int(user.updated_at)),
    ])

  json.to_string_builder(u)
}

pub fn hash_password(password: String) -> String {
  hash(password, [])
}

fn decode_user() -> dynamic.Decoder(types.User) {
  dynamic.decode6(
    types.User,
    dynamic.field(named: "id", of: dynamic.string),
    dynamic.field(named: "email", of: dynamic.string),
    dynamic.field(named: "username", of: dynamic.string),
    dynamic.field(named: "password", of: dynamic.string),
    dynamic.field(named: "created_at", of: dynamic.int),
    dynamic.field(named: "updated_at", of: dynamic.int),
  )
}

@external(erlang, "Elixir.Argon2", "hash_pwd_salt")
fn hash(password: String, list: List(a)) -> String
