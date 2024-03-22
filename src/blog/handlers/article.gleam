import wisp.{type Request, type Response}
import lib/utils
import gleam/option.{None, Some}
import gleam/json
import blog/web.{type Context}
import sqlight.{type Connection, type Error}
import gleam/dynamic
import lib/types
import lib/middleware
import lib/schemas/articles
import lib/errors
import gleam/http.{Delete, Get, Patch, Post, Put}

pub fn all(req: Request, ctx: Context) -> Response {
  use user_id <- middleware.check_loggedin(ctx.db, req)
  case req.method {
    Post -> create(req, ctx, user_id)
    Get -> get_articles(ctx, user_id)
    _ -> wisp.method_not_allowed([Post, Patch])
  }
}

pub fn one(req: Request, ctx: Context, id: String) -> Response {
  use user_id <- middleware.check_loggedin(ctx.db, req)
  case req.method {
    Put -> update_all(req, ctx, id, user_id)
    Patch -> update_one(req, ctx, id, user_id)
    Delete -> delete(ctx, id, user_id)
    Get -> get_article(ctx, id, user_id)
    _ -> wisp.method_not_allowed([Put, Delete, Patch, Get])
  }
}

fn get_articles(ctx: Context, user_id: String) -> Response {
  let row = articles.all(ctx.db, user_id)
  case row {
    Ok(a) -> {
      let b =
        json.object([
          #("message", json.string("Successfully fetched all articles")),
          #("data", utils.list_to_json(utils.ToJsonArticle(a))),
        ])
      let res = json.to_string_builder(b)
      wisp.json_response(res, 200)
    }
    Error(err) -> {
      let res = errors.sqlight_err(err)
      wisp.json_response(res, 400)
    }
  }
}

fn get_article(ctx: Context, id: String, user_id: String) -> Response {
  use article <- find_article(id, ctx.db)
  use <- middleware.check_authorized(article.user_id, user_id)
  let a =
    json.object([
      #("id", json.string(article.id)),
      #("user_id", json.string(article.user_id)),
      #("title", json.string(article.title)),
      #("body", json.string(article.body)),
      #("created_at", json.string(article.created_at)),
      #("update_at", json.string(article.updated_at)),
    ])
  let response = json.to_string_builder(a)
  wisp.json_response(response, 200)
}

fn delete(ctx: Context, id: String, user_id: String) -> Response {
  use article <- find_article(id, ctx.db)
  use <- middleware.check_authorized(article.user_id, user_id)

  let row = articles.delete(ctx.db, "id", id)
  case row {
    Ok(_) -> wisp.no_content()
    Error(err) -> {
      let response = errors.sqlight_err(err)
      wisp.json_response(response, 500)
    }
  }
}

fn create(req: Request, ctx: Context, user_id: String) -> Response {
  use json <- wisp.require_json(req)
  use input <- middleware.decode_input(json, decode_article)

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

fn update_all(
  req: Request,
  ctx: Context,
  id: String,
  user_id: String,
) -> Response {
  use json <- wisp.require_json(req)
  use input <- middleware.decode_input(json, decode_article)
  use article <- find_article(id, ctx.db)
  use <- middleware.check_authorized(article.user_id, user_id)

  case articles.update(ctx.db, id, input) {
    Ok(_id) -> {
      let u =
        json.to_string_builder(
          json.object([
            #("message", json.string("Article updated Successfully")),
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

fn update_one(
  req: Request,
  ctx: Context,
  id: String,
  user_id: String,
) -> Response {
  use json <- wisp.require_json(req)
  use input <- middleware.decode_input(json, utils.decode_update)
  use article <- find_article(id, ctx.db)
  use <- middleware.check_authorized(article.user_id, user_id)

  case input.field {
    "title" | "body" -> {
      let row = articles.update_one(ctx.db, input.value, input.field, id)
      case row {
        Ok(_id) -> {
          let u =
            json.to_string_builder(
              json.object([
                #("message", json.string("Article updated Successfully")),
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

fn find_article(
  id: String,
  db: Connection,
  next: fn(types.Article) -> Response,
) -> Response {
  case articles.find_one(id, db, "id") {
    Ok(a) -> {
      case a {
        Some(article) -> next(article)
        None -> {
          let res =
            utils.failed_to_get("Article with " <> id <> " doesn't exist.")
          wisp.json_response(res, 400)
        }
      }
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
