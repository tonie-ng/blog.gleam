import wisp
import mist
import gleam/erlang/process
import lib/database
import blog/web
import blog/router
import lib/schemas/token

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let db = database.init()
  let assert Ok(_) = database.with_connection(db, database.migrate_db)
  let assert Ok(_) = token.drop(db)

  let ctx = web.Context(db: db)
  let handler = router.handle_request(_, ctx)
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
