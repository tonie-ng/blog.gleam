pub type User {
  User(
    id: String,
    username: String,
    email: String,
    password: String,
    created_at: String,
    updated_at: String,
  )
}

pub type SignUp {
  SignUp(username: String, email: String, password: String)
}

pub type SignIn {
  SignIn(email: String, password: String)
}
