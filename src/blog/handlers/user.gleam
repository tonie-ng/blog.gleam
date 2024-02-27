import wisp.{type Request, type Response}
import blog/web.{type Context}
import lib/schemas/user
import lib/errors
import gleam/option.{None, Some}
import gleam/http.{Delete, Get}
import lib/utils

pub fn one(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    Get -> find_user_by_id(ctx, id)
    Delete -> delete_user(ctx, id)
    _ -> wisp.method_not_allowed([Get, Delete])
  }
}

pub fn delete_user(ctx: Context, id: String) -> Response {
  let row = user.delete(id, ctx.db, "id")
  case row {
    Ok(_) -> wisp.no_content()
    Error(err) -> {
      let response = errors.sqlight_err(err)
      wisp.json_response(response, 409)
    }
  }
}

pub fn find_user_by_id(ctx: Context, id: String) -> Response {
  let row = user.find_one(id, ctx.db, "id")

  case row {
    Ok(u) -> {
      case u {
        Some(res) -> {
          let response = user.user_json(res)
          wisp.json_response(response, 200)
        }
        None -> {
          let response =
            utils.failed_to_get("User with " <> id <> " doesn't exist")
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
