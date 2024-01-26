import gleam/dynamic
import gleam/json
import wisp.{type Request, type Response}
import blog/web.{type Context}
import gleam/http.{Get, Post}
import sqlight
import gleam/io

pub type User {
  User(
    id: Int,
    email: String,
    password: String,
    created_at: Int,
    updated_at: Int,
  )
}

pub fn all(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> find_all(ctx)
    _ -> wisp.method_not_allowed(allowed: [Get, Post])
  }
}

fn find_all(ctx: Context) -> Response {
  let sql =
    "SELECT id, username, email, password, UNIXEPOCH(created_at), UNIXEPOCH(updated_at) FROM users;"

  todo
}

fn decode_user() -> dynamic.Decoder(User) {
  dynamic.decode5(
    User,
    dynamic.field(named: "id", of: dynamic.int),
    dynamic.field(named: "email", of: dynamic.string),
    dynamic.field(named: "password", of: dynamic.string),
    dynamic.field(named: "created_at", of: dynamic.int),
    dynamic.field(named: "updated_at", of: dynamic.int),
  )
}
