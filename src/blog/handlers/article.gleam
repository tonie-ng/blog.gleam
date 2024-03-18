import wisp.{type Request, type Response}
import gleam/json
import blog/web.{type Context}
import sqlight.{type Error}
import gleam/dynamic
import lib/types
import lib/middleware
import lib/schemas/articles
import lib/errors
import gleam/http.{Post}

pub fn all(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> create(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn create(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  use input <- middleware.decode_input(json, decode_article)
  use user_id <- middleware.check_loggedin(ctx.db, req)

  case articles.new(ctx.db, user_id, input) {
    Ok(id) -> {
      let a =
        json.object([
          #("id", json.string(id)),
          #("title", json.string(input.title)),
          #("body", json.string(input.body)),
        ])
      let response = json.to_string_builder(a)
      wisp.json_response(response, 200)
    }
    Error(err) -> {
      let res = errors.sqlight_err(err)
      wisp.json_response(res, 400)
    }
  }
}

fn decode_article(
  json: dynamic.Dynamic,
) -> Result(types.ArticleInput, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode2(
      types.ArticleInput,
      dynamic.field(named: "title", of: dynamic.string),
      dynamic.field(named: "body", of: dynamic.string),
    )
  decoder(json)
}
