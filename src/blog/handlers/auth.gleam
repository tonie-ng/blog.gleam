import wisp.{type Request, type Response}
import gleam/io
import blog/web.{type Context}
import lib/utils
import sqlight.{type Connection, type Error}
import lib/schemas/user
import gleam/option.{None, Some}
import gleam/dynamic
import lib/types
import lib/errors
import gleam/http.{Post}
import gleam/json
import lib/schemas/token

pub fn signup(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json <- wisp.require_json(req)
  let input = utils.decode_input(json, decode_signup)

  use <- check_user_up(input.email, "email", ctx.db)

  case user.create(input, ctx.db) {
    Ok(id) -> {
      let u =
        json.object([
          #("id", json.string(id)),
          #("email", json.string(input.email)),
          #("username", json.string(input.username)),
        ])
      let response = json.to_string_builder(u)
      wisp.json_response(response, 200)
    }
    Error(err) -> {
      let error = errors.sqlight_err(err)
      wisp.json_response(error, 500)
    }
  }
}

pub fn signin(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json <- wisp.require_json(req)
  let input = utils.decode_input(json, decode_signin)

  use usr <- check_user_in(input.email, "email", input.password, ctx.db)
  case token.generate(usr.id, ctx.db) {
    Ok(tok) -> {
      io.debug(tok)
      let u =
        json.object([
          #("id", json.string(usr.id)),
          #("email", json.string(usr.email)),
          #("username", json.string(usr.username)),
        ])
      let response = json.to_string_builder(u)
      wisp.json_response(response, 200)
      |> wisp.set_cookie(req, "auth_token", tok, wisp.Signed, 60 * 60 * 24 * 3)
    }
    Error(err) -> {
      let res = errors.sqlight_err(err)
      wisp.json_response(res, 500)
    }
  }
}

pub fn signout(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  case wisp.get_cookie(req, "auth_token", wisp.Signed) {
    Ok(tok) -> {
      io.debug(tok)
      case token.delete("token", tok, ctx.db) {
        Ok(_) -> {
          wisp.no_content()
          |> wisp.set_cookie(req, "auth_token", tok, wisp.Signed, 0)
        }
        Error(_) -> {
          let res = utils.not_authorized("You're not logged in")
          wisp.json_response(res, 401)
        }
      }
    }
    Error(_) -> {
      let res = utils.not_authorized("You're not logged in")
      wisp.json_response(res, 401)
    }
  }
}

fn decode_signup(
  json: dynamic.Dynamic,
) -> Result(types.SignUp, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode3(
      types.SignUp,
      dynamic.field(named: "username", of: dynamic.string),
      dynamic.field(named: "email", of: dynamic.string),
      dynamic.field(named: "password", of: dynamic.string),
    )
  decoder(json)
}

fn decode_signin(
  json: dynamic.Dynamic,
) -> Result(types.SignIn, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode2(
      types.SignIn,
      dynamic.field(named: "email", of: dynamic.string),
      dynamic.field(named: "password", of: dynamic.string),
    )
  decoder(json)
}

fn check_user_up(
  value: String,
  field: String,
  db: Connection,
  next: fn() -> Response,
) -> Response {
  case user.find_one(value, db, field) {
    Ok(u) -> {
      case u {
        Some(_) -> {
          let response =
            utils.failed_to_create("User with " <> value <> " already exist")
          wisp.json_response(response, 409)
        }
        None -> {
          next()
        }
      }
    }
    Error(err) -> {
      let error = errors.sqlight_err(err)
      wisp.json_response(error, 500)
    }
  }
}

fn check_user_in(
  value: String,
  field: String,
  password: String,
  db: Connection,
  next: fn(types.User) -> Response,
) -> Response {
  case user.find_one(value, db, field) {
    Ok(u) -> {
      case u {
        Some(usr) -> {
          case compare_password(password, usr.password) {
            True -> next(usr)
            False -> {
              let response = utils.failed_to_get("Incorrect password")
              wisp.json_response(response, 409)
            }
          }
        }
        None -> {
          let response =
            utils.failed_to_get("User with " <> value <> " doesn't exist")
          wisp.json_response(response, 409)
        }
      }
    }
    Error(err) -> {
      let error = errors.sqlight_err(err)
      wisp.json_response(error, 500)
    }
  }
}

@external(erlang, "Elixir.Argon2", "verify_pass")
pub fn compare_password(password: String, hash: String) -> Bool
