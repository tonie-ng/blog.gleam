import gleam/dynamic
import sqlight.{type Error as SqlightError}
import gleam/list
import gleam/json

pub fn generic_err(list: dynamic.DecodeErrors, message: String) {
  let assert Ok(err) = list.first(list)
  let assert Ok(path) = list.first(err.path)
  let res = {
    let object =
      json.object([
        #("message:", json.string(message)),
        #("expected", json.string(err.expected)),
        #("found", json.string(err.found)),
        #("field", json.string(path)),
      ])
    Ok(json.to_string_builder(object))
  }

  case res {
    Ok(result) -> result
    Error(err) -> err
  }
}

pub fn sqlight_err(err: SqlightError) {
  let res = {
    let object = json.object([#("message", json.string(err.message))])
    Ok(json.to_string_builder(object))
  }

  case res {
    Ok(result) -> result
    Error(err) -> err
  }
}
