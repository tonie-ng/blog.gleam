import wisp.{type Request, type Response}
import blog/web.{type Context}
import lib/utils
import lib/schemas/user
import gleam/dynamic
import lib/types
import lib/errors
import gleam/json

pub fn signup(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  let input = utils.decode_input(json, decode_signup)

  let result = user.create(input, ctx.db)
  case result {
    Ok(id) -> {
			let u =
				json.object([
					#("id", json.string(id)),
					#("email", json.string(input.email)),
					#("username", json.string(input.username))
			])
			let response = json.to_string_builder(u)
			wisp.json_response(response, 200)
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
