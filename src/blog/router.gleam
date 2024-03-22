import wisp.{type Request, type Response}
import blog/web.{type Context}
import blog/handlers/auth
import blog/handlers/user
import blog/handlers/article

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["signup"] -> auth.signup(req, ctx)
    ["signin"] -> auth.signin(req, ctx)
    ["signout"] -> auth.signout(req, ctx)
    ["users"] -> user.get_users(req, ctx)
    ["users", id] -> user.one(req, ctx, id)
    ["articles"] -> article.all(req, ctx)
    ["articles", id] -> article.one(req, ctx, id)
    _ -> wisp.not_found()
  }
}
