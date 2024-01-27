import sqlight.{type Error}
import lib/tables

pub fn init() -> sqlight.Connection {
  let assert Ok(db) = sqlight.open("blog.db")
  let assert Ok(_) = sqlight.exec("pragma foreign_keys = on;", on: db)
  db
}

pub fn with_connection(
  db: sqlight.Connection,
  next: fn(sqlight.Connection) -> a,
) -> a {
  next(db)
}

pub fn migrate_db(db: sqlight.Connection) -> Result(Nil, Error) {
  sqlight.exec(tables.create(), db)
}
