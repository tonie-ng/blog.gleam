import wisp.{type Request, type Response}
import lib/schemas/token
import sqlight.{type Connection, type Error}
import gleam/option.{None, Some}
import lib/utils

pub fn check_loggedin(
  token: String,
  db: Connection,
  req: Request,
  next: fn(String) -> Response,
) -> Response {
  case wisp.get_cookie(req, "auth_token", wisp.Signed) {
    Ok(_) -> {
      case token.find("auth_token", token, db) {
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
        Error(_) -> {
					wisp.internal_server_error()
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
	id: String,
	user_id: String,
	next: fn() -> Response
) -> Response {
	case id == user_id {
		True -> next()
		False -> {
			let res = utils.not_authorized("You can't access this resource")
			wisp.json_response(res, 401)
		}
	}
}
