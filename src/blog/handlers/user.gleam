import lib/schemas/users
import wisp.{type Request, type Response}
import blog/web.{type Context}
import gleam/http.{Get}

pub fn one(req: Request, id: String, ctx: Context) -> Response {
	case req.method {
		Get -> users.get_user(id, ctx.db)
		_ -> wisp.method_not_allowed(allowed: [Get])
	}
}
