import gleam/dynamic
import gleam/list
import lib/utils.{generate_nanoid}
import wisp.{type Response}
import sqlight.{type Connection}
import gleam/json

pub type User {
  User(
    id: String,
    email: String,
    password: String,
    created_at: Int,
    updated_at: Int,
  )
}

pub type UserInput {
  UserInput(username: String, email: String, password: String)
}

pub fn create_user(input: dynamic.Dynamic, db: Connection) -> Response {
  let user_input = decode_userinput(input)
  case user_input {
    Ok(user_json) -> {
      let id = generate_nanoid()
      let sql =
        "
				INSERT INTO users (id, username, email, password, created_at, updated_at)
				VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))
				"
      let args = [
        sqlight.text(id),
        sqlight.text(user_json.username),
        sqlight.text(user_json.email),
        sqlight.text(user_json.password),
      ]
      let user = {
				use query_res <- sqlight.query(sql, on: db, with: args)
				decode_user(query_res)
			}

			case user {
				Ok(res) -> {	
					let result = created(res)
					wisp.json_response(result, 201)
				}
				Error(_err) -> wisp.unprocessable_entity()
			}
    }
    Error(err) -> {
			let res = invalid_input(err)
			wisp.json_response(res, 500)
		}
  }
}

fn created(list: List(User)) {
	let assert Ok(user) =  list.first(list)
	let res = {
		let object = json.object([
			#("message", json.string("User has been created")),
			#("id", json.string(user.id)),
			#("username", json.string(user.email)),
		])

		Ok(json.to_string_builder(object))
	}

	case res {
		Ok(result) -> result
		Error(err) -> err
	}	
}

fn invalid_input(list: dynamic.DecodeErrors) {
	let assert Ok(err) = list.first(list)
	let assert Ok(path) = list.first(err.path)
	let res = {
		let object = json.object([
			#("message:", json.string("Invalid req parameters")),
			#("expected", json.string(err.expected)),
			#("found", json.string(err.found)),
			#("path", json.string(path))
		])
		Ok(json.to_string_builder(object))
	}

	case res {
		Ok(result) -> result
		Error(err) -> err
	}
}

fn decode_user(
	json: dynamic.Dynamic
) -> Result(User, dynamic.DecodeErrors) {
  let decoder = 
		dynamic.decode5(
			User,
			dynamic.field(named: "id", of: dynamic.string),
			dynamic.field(named: "email", of: dynamic.string),
			dynamic.field(named: "password", of: dynamic.string),
			dynamic.field(named: "created_at", of: dynamic.int),
			dynamic.field(named: "updated_at", of: dynamic.int),
		)
	decoder(json)
}

fn decode_userinput(
  json: dynamic.Dynamic,
) -> Result(UserInput, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode3(
      UserInput,
      dynamic.field(named: "username", of: dynamic.string),
      dynamic.field(named: "email", of: dynamic.string),
      dynamic.field(named: "password", of: dynamic.string),
    )
  decoder(json)
}
