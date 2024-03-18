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

pub type Article {
  Article(
    id: String,
    title: String,
    body: String,
    user_id: String,
    created_at: String,
    updated_at: String,
  )
}

pub type Token {
  Token(id: Int, user_id: String, token: String, created_at: String)
}

pub type ArticleInput {
  ArticleInput(title: String, body: String)
}

pub type SignUp {
  SignUp(username: String, email: String, password: String)
}

pub type SignIn {
  SignIn(email: String, password: String)
}
