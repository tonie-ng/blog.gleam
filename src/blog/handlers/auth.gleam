import wisp.{type Request, type Response}
import blog/web.{type Context}
import lib/utils
import lib/schemas/user
import gleam/dynamic
import lib/types
import lib/errors
import gleam/option.{None, Some}

pub fn signup(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  let input = utils.decode_input(json, decode_signup)

  let result = user.create(input, ctx.db)
  case result {
    Ok(u) -> {
      case u {
        Some(res) -> {
          let response = user.user_json(res)
          wisp.json_response(response, 201)
        }
        None -> {
          let response = utils.failed_to_create()
          wisp.json_response(response, 500)
        }
      }
    }
    Error(err) -> {
      let error = errors.sqlight_err(err)
      wisp.json_response(error, 409)
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
