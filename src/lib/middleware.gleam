import wisp.{type Request, type Response}
import lib/errors
import lib/schemas/token
import sqlight.{type Connection, type Error}
import gleam/option.{None, Some}
import lib/utils
import gleam/dynamic

pub fn decode_input(
  input: dynamic.Dynamic,
  decoder: fn(dynamic.Dynamic) -> Result(a, dynamic.DecodeErrors),
  next: fn(a) -> Response,
) -> Response {
  case decoder(input) {
    Ok(validinput) -> next(validinput)
    Error(_err) -> {
      let res = errors.generic_err("Invalid input parameters")
      wisp.json_response(res, 400)
    }
  }
}

pub fn check_loggedin(
  db: Connection,
  req: Request,
  next: fn(String) -> Response,
) -> Response {
  case wisp.get_cookie(req, "auth_token", wisp.Signed) {
    Ok(t) -> {
      case token.find("token", t, db) {
        Ok(tok) -> {
          case tok {
            Some(t) -> {
              next(t.user_id)
            }
            None -> {
              let res = utils.not_authorized("Invalid session token")
              wisp.json_response(res, 401)
            }
          }
        }
        Error(err) -> {
          let res = errors.sqlight_err(err)
          wisp.json_response(res, 500)
        }
      }
    }
    Error(_) -> {
      let res = utils.not_authorized("You are not logged in")
      wisp.json_response(res, 401)
    }
  }
}

pub fn check_authorized(
  resource_userid: String,
  token_userid: String,
  next: fn() -> Response,
) -> Response {
  case resource_userid == token_userid {
    True -> next()
    False -> {
      let res = utils.not_authorized("You can't access this resource")
      wisp.json_response(res, 401)
    }
  }
}
