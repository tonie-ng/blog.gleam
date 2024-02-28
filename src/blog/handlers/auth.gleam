import wisp.{type Request, type Response}
import blog/web.{type Context}
import gleam/string
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

  use <- check_user(input.email, "email", ctx.db)
  wisp.ok()

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

pub fn signout(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)

  case wisp.get_cookie(req, "auth_token", wisp.Signed) {
    Ok(value) -> {
      case string.is_empty(value) {
        True -> {
          let res = utils.not_authorized("You're not logged in")
          wisp.json_response(res, 401)
        }
        False -> {
          case token.delete("token", value, ctx.db) {
            Ok(_) -> {
              wisp.no_content()
              |> wisp.set_cookie(req, "auth_token", value, wisp.Signed, 0)
            }
            Error(_) -> wisp.internal_server_error()
          }
        }
      }
    }
    Error(_) -> {
      let res = utils.not_authorized("You are not logged in")
      wisp.json_response(res, 401)
    }
  }
}

pub fn signin(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json <- wisp.require_json(req)
  let input = utils.decode_input(json, decode_signin)
  let row = user.find_one(input.email, ctx.db, "email")

  case row {
    Ok(u) -> {
      case u {
        Some(usr) -> {
          use <- cleanup(usr.id, "user_id", req, ctx.db)
          case token.generate(usr.id, ctx.db) {
            Ok(tok) -> {
              wisp.accepted()
              |> wisp.set_cookie(
                req,
                "auth_token",
                tok,
                wisp.Signed,
                60 * 60 * 24,
              )
            }
            Error(_) -> wisp.bad_request()
          }
        }
        None -> {
          let response =
            utils.failed_to_get("User with" <> input.email <> " doesn't exist")
          wisp.json_response(response, 404)
        }
      }
    }
    Error(err) -> {
      let error = errors.sqlight_err(err)
      wisp.json_response(error, 500)
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

fn check_user(
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

fn cleanup(
  value: String,
  field: String,
  req: Request,
  db: Connection,
  next: fn() -> Response,
) -> Response {
  let tok = wisp.get_cookie(req, "auth_token", wisp.Signed)
  case tok {
    Ok(t) -> {
      case string.is_empty(t) {
        True -> next()
        False -> {
          case token.delete(field, value, db) {
            Ok(_) -> next()
            Error(_) -> {
              wisp.internal_server_error()
            }
          }
        }
      }
    }
    Error(_) -> next()
  }
}
