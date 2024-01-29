import wisp.{type Request, type Response}
import blog/web.{type Context}
import lib/schemas/users

pub fn signup(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  users.create_user(json, ctx.db)
}
