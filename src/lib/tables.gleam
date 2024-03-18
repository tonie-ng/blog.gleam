pub fn create() -> String {
  user() <> articles() <> auth_token()
}

fn user() -> String {
  "
	CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY NOT NULL UNIQUE,
		username TEXT NOT NULL UNIQUE,
		email TEXT NOT NULL UNIQUE,
		password TEXT NOT NULL,
		created_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,
		updated_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP
	);
	"
}

fn articles() -> String {
  "
	CREATE TABLE IF NOT EXISTS articles (
		id TEXT PRIMARY KEY NOT NULL UNIQUE,
		title TEXT NOT NULL DEFAULT 'Untitled',
		body TEXT NOT NULL DEFAULT '',
		user_id INTEGER NOT NULL,
		created_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,
		updated_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (user_id) REFERENCES users (id)
	);
	"
}

fn auth_token() -> String {
  "
	CREATE TABLE IF NOT EXISTS auth_tokens (
		id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
		token TEXT NOT NULL UNIQUE,
		user_id INTEGER NOT NULL,
		created_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (user_id) REFERENCES users (id)
	)
	"
}
