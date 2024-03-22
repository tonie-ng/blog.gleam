import wisp.{type Request, type Response}
import gleam/dynamic
import gleam/json
import lib/types
import blog/web.{type Context}
import lib/schemas/user
import lib/errors
import sqlight.{type Connection}
import gleam/option.{None, Some}
import gleam/http.{Delete, Get, Patch, Put}
import lib/utils
import lib/middleware

pub fn one(req: Request, ctx: Context, id: String) -> Response {
  use user_id <- middleware.check_loggedin(ctx.db, req)
  use <- middleware.check_authorized(id, user_id)
  case req.method {
    Get -> get_user(ctx, id)
    Delete -> delete_user(ctx, id)
    Patch -> update_one(req, ctx, id)
    Put -> update_all(req, ctx, id)
    _ -> wisp.method_not_allowed([Get, Delete, Patch, Put])
  }
}

pub fn get_users(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Get)
  use _ <- middleware.check_loggedin(ctx.db, req)

  case user.all(ctx.db) {
    Ok(u) -> {
      let b =
        json.object([
          #("message", json.string("Successfully fetched all users")),
          #("data", utils.list_to_json(utils.ToJsonUser(u))),
        ])
      let res = json.to_string_builder(b)
      wisp.json_response(res, 200)
    }
    Error(_) -> {
      wisp.internal_server_error()
    }
  }
}

fn update_all(req: Request, ctx: Context, id: String) -> Response {
  use json <- wisp.require_json(req)
  use input <- middleware.decode_input(json, decode_updateuser)

  case user.update(ctx.db, id, input) {
    Ok(_id) -> {
      let u =
        json.to_string_builder(
          json.object([
            #("message", json.string("User's details updated Successfully")),
          ]),
        )
      wisp.json_response(u, 200)
    }
    Error(err) -> {
      let res = errors.sqlight_err(err)
      wisp.json_response(res, 400)
    }
  }
}

fn update_one(req: Request, ctx: Context, id: String) -> Response {
  use json <- wisp.require_json(req)
  use input <- middleware.decode_input(json, utils.decode_update)
  case input.field {
    "username" | "email" -> {
      let row = user.update_one(ctx.db, input.value, input.field, id)
      case row {
        Ok(_id) -> {
          let u =
            json.to_string_builder(
              json.object([
                #("message", json.string("User's details updated Successfully")),
              ]),
            )
          wisp.json_response(u, 200)
        }
        Error(err) -> {
          let error = errors.sqlight_err(err)
          wisp.json_response(error, 400)
        }
      }
    }
    "password" -> {
      let value = user.hash(input.value, [])
      let row = user.update_one(ctx.db, value, input.field, id)
      case row {
        Ok(_id) -> {
          let u =
            json.to_string_builder(
              json.object([
                #("message", json.string("User's details updated Successfully")),
              ]),
            )
          wisp.json_response(u, 200)
        }
        Error(err) -> {
          let error = errors.sqlight_err(err)
          wisp.json_response(error, 400)
        }
      }
    }
    _ -> {
      let u =
        json.to_string_builder(
          json.object([
            #("event", json.string("Invalid input parameters")),
            #(
              "message",
              json.string(
                "User does not have an/a " <> input.field <> " attribute",
              ),
            ),
          ]),
        )
      wisp.json_response(u, 422)
    }
  }
}

fn delete_user(ctx: Context, id: String) -> Response {
  let row = user.delete(id, ctx.db, "id")
  case row {
    Ok(_) -> wisp.no_content()
    Error(err) -> {
      let response = errors.sqlight_err(err)
      wisp.json_response(response, 400)
    }
  }
}

fn get_user(ctx: Context, id: String) -> Response {
  use u <- find_user(ctx.db, id)
  let response = user.user_json(id, u)
  wisp.json_response(response, 200)
}

fn find_user(
  db: Connection,
  id: String,
  next: fn(types.User) -> Response,
) -> Response {
  let row = user.find_one(id, db, "id")
  case row {
    Ok(u) -> {
      case u {
        Some(res) -> next(res)
        None -> {
          let response = utils.failed_to_get("User with " <> id <> " not found")
          wisp.json_response(response, 404)
        }
      }
    }
    Error(err) -> {
      let error = errors.sqlight_err(err)
      wisp.json_response(error, 400)
    }
  }
}

fn decode_updateuser(
  json: dynamic.Dynamic,
) -> Result(types.UpdateUser, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode3(
      types.UpdateUser,
      dynamic.field(named: "email", of: dynamic.string),
      dynamic.field(named: "password", of: dynamic.string),
      dynamic.field(named: "username", of: dynamic.string),
    )
  decoder(json)
}
