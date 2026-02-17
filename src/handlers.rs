use axum::extract::{Path, Query, State};
use axum::response::Html;
use std::collections::HashMap;
use crate::AppState;
use tera::Tera;

// Our root handler
// This handler responds to `GET /` requests
pub async fn get_root() -> &'static str {
    "Hello, World!"
}

pub async fn get_portfolio(State(state): State<AppState>) -> Html<String> {
    let tera = state.get_templater();
    let mut context = tera::Context::new();
    context.insert("portfolio_entries", &state.get_portfolio_entries());

    return match tera.render("portfolio.tera.html", &context) {
        Ok(rendered) => Html(rendered),
        Err(e) => {
            eprintln!("Error rendering template: {}", e);
            Html("Error rendering portfolio".to_string())
        }
    };
}

pub async fn get_blog(State(state): State<AppState>) -> Html<String> {
    let tera = state.get_templater();
    let mut context = tera::Context::new();
    context.insert("blog_posts", &state.get_blog_posts());

    return match tera.render("blog_posts.tera.html", &context) {
        Ok(rendered) => Html(rendered),
        Err(e) => {
            eprintln!("Error rendering template: {}", e);
            Html("Error rendering blog posts".to_string())
        }
    };
}

pub async fn get_resume(State(state): State<AppState>) -> Html<String> {
    let tera = state.get_templater();
    let context = tera::Context::new();

    return match tera.render("resume.tera.html", &context) {
        Ok(rendered) => Html(rendered),
        Err(e) => {
            eprintln!("Error rendering template: {}", e);
            Html("Error rendering blog posts".to_string())
        }
    };
}

pub async fn get_blog_post(State(state): State<AppState>, Path(id): Path<usize>) -> Html<String> {
    let tera = state.get_templater();
    let mut context = tera::Context::new();
    let post = state.get_blog_posts().into_iter().find(|post| post.id == id).unwrap();

    context.insert("post", post);

    return match tera.render("blog_post.tera.html", &context) {
        Ok(rendered) => Html(rendered),
        Err(e) => {
            eprintln!("Error rendering template: {}", e);
            Html("Error rendering blog posts".to_string())
        }
    };
}

pub async fn get_blog_posts(State(state): State<AppState>, Query(params): Query<HashMap<String, String>>) -> Html<String> {
    let tag: Option<String> = params.get("tag").and_then(|s| s.parse().ok());
    let tera = state.get_templater();
    let mut context = tera::Context::new();
    let posts: Vec<_> = state.get_blog_posts().into_iter().filter(|post| post.tags.contains(&tag.clone().unwrap_or(String::new()))).collect();

    context.insert("posts", &posts);
    context.insert("tag", &tag);

    return match tera.render("blog_posts_by_tag.tera.html", &context) {
        Ok(rendered) => Html(rendered),
        Err(e) => {
            eprintln!("Error rendering template: {}", e);
            Html("Error rendering blog posts".to_string())
        }
    };
}

/*
pub async fn post_subscription(State(state)) -> &'static str {

}
*/

// private handlers
// These handlers are not exposed to the public

pub async fn get_blog_upload() -> &'static str {
    unimplemented!()
}

pub async fn get_blog_preview() -> &'static str {
    unimplemented!()
}

pub async fn get_portfolio_upload() -> &'static str {
    unimplemented!()
}

pub async fn get_portfolio_preview() -> &'static str {
    unimplemented!()
}

pub async fn post_blog() -> &'static str {
    unimplemented!()
}

pub async fn portfolio_upload(State(state): State<AppState>) -> &'static str {
    unimplemented!()
}

pub async fn post_portfolio() -> &'static str {
    unimplemented!()
}
