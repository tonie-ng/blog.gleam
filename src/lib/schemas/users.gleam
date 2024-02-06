import gleam/dynamic
import gleam/string_builder.{type StringBuilder}
import gleam/list
import lib/utils.{generate_nanoid}
import wisp.{type Response}
import sqlight.{type Connection}
import gleam/json
import lib/errors
import gleam/io

pub type User {
  User(
    id: String,
    username: String,
    email: String,
    password: String,
    created_at: Int,
    updated_at: Int,
  )
}

pub type UserInput {
  UserInput(username: String, email: String, password: String)
}

pub fn get_user(id: String, db: Connection) -> Response {
  let sql =
    "
		SELECT id, username, email, created_at, updated_at FROM users
		WHERE id = ?;
	"
  let args = [sqlight.text(id)]
  let user = sqlight.query(sql, on: db, with: args, expecting: decode_user)
  case user {
    Ok(res) -> {
      case list.length(of: res) {
        0 -> wisp.not_found()
        _ -> {
          let response = user_res(res, "User with " <> id <> "found")
          wisp.json_response(response, 200)
        }
      }
    }
    Error(_) -> {
      wisp.not_found()
    }
  }
}

pub fn create_user(input: dynamic.Dynamic, db: Connection) -> Response {
  let user_input = decode_userinput(input)
  case user_input {
    Ok(user_json) -> {
      let id = generate_nanoid()
      io.println(id)
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
      let user = sqlight.query(sql, on: db, with: args, expecting: decode_user)
      io.debug(user)
      case user {
        Ok(res) -> {
          case list.length(of: res) {
            0 -> wisp.not_found()
            _ -> {
              let result = user_res(res, "User has been created")
              wisp.json_response(result, 201)
            }
          }
        }
        Error(err) -> {
          let err = errors.sqlight_err(err)
          wisp.json_response(err, 409)
        }
      }
    }
    Error(err) -> {
      let res = errors.generic_err(err, "Invalid json input")
      wisp.json_response(res, 400)
    }
  }
}

fn user_res(list: List(User), message: String) -> StringBuilder {
  let assert Ok(user) = list.first(list)
  let res = {
    let object =
      json.object([
        #("message", json.string(message)),
        #("id", json.string(user.id)),
        #("email", json.string(user.email)),
        #("username", json.string(user.username)),
        #("created_at", json.int(user.created_at)),
        #("updated_at", json.int(user.updated_at)),
      ])
    Ok(json.to_string_builder(object))
  }

  case res {
    Ok(result) -> result
    Error(err) -> err
  }
}

fn decode_user(json: dynamic.Dynamic) -> Result(User, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode6(
      User,
      dynamic.field(named: "id", of: dynamic.string),
      dynamic.field(named: "email", of: dynamic.string),
      dynamic.field(named: "username", of: dynamic.string),
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
