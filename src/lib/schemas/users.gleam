import gleam/dynamic
import lib/utils.{generate_nanoid}
import wisp.{type Request, type Response}
import blog/web.{type Context}
import gleam/http.{Get, Post}
import sqlight

pub type User {
  User(
    id: String,
    email: String,
    password: String,
    created_at: Int,
    updated_at: Int,
  )
}

pub type UserInput {
  UserInput(username: String, email: String, password: String)
}

pub fn all(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> create_user(req, ctx)
    _ -> wisp.method_not_allowed(allowed: [Get, Post])
  }
}

fn create_user(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  let user_input = decode_userinput(json)
  case user_input {
    Ok(user) -> {
      let id = generate_nanoid()
      let sql =
        "
				INSERT INTO users (id, username, email, password, created_at, updated_at)
				VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))
			"
      let args = [
        sqlight.text(id),
        sqlight.text(user.username),
        sqlight.text(user.email),
        sqlight.text(user.password),
      ]
      let assert Ok(_user) =
        sqlight.query(sql, on: ctx.db, with: args, expecting: decode_user())
      wisp.ok()
    }
    Error(_) -> wisp.unprocessable_entity()
  }
}

fn decode_user() -> dynamic.Decoder(User) {
  dynamic.decode5(
    User,
    dynamic.field(named: "id", of: dynamic.string),
    dynamic.field(named: "email", of: dynamic.string),
    dynamic.field(named: "password", of: dynamic.string),
    dynamic.field(named: "created_at", of: dynamic.int),
    dynamic.field(named: "updated_at", of: dynamic.int),
  )
}

fn decode_userinput(
  json: dynamic.Dynamic,
) -> Result(UserInput, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode3(
      UserInput,
      dynamic.field(named: "username", of: dynamic.string),
      dynamic.field(named: "email", of: dynamic.string),
      dynamic.field(named: "password", of: dynamic.string),
    )
  decoder(json)
}
