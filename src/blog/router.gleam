import wisp.{type Request, type Response}
import blog/web.{type Context}
import lib/schemas/users

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["users"] -> users.all(req, ctx)
    _ -> wisp.not_found()
  }
}
