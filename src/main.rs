use crate::state::AppState;
use aws_config::BehaviorVersion;
use axum::{
    response::Redirect,
    routing::{get, post},
    Router,
};
use dotenvy::dotenv;
use std::future::IntoFuture;

pub mod handlers;
pub mod models;
pub mod services;
pub mod state;
pub mod tests;

struct Environment {
    blog_posts_bucket: String,
    portfolio_entries_bucket: String,
    templates_bucket: String,
}

impl Environment {
    pub fn new() -> Self {
        let blog_posts_bucket = std::env::var("BLOG_POSTS_BUCKET")
            .expect("No environment variable set for blog posts bucket");
        let portfolio_entries_bucket = std::env::var("PORTFOLIO_ENTRIES_BUCKET")
            .expect("No environment variable set for portfolio entries bucket");
        let templates_bucket = std::env::var("TEMPLATES_BUCKET").expect("No environment variable set for portfolio entries bucket");

        Self {
            blog_posts_bucket,
            portfolio_entries_bucket,
            templates_bucket,
        }
    }
}

#[tokio::main]
async fn main() {
    // initialize tracing
    tracing_subscriber::fmt::init();

    // Load environment variables from .env file
    // Fails if no .env file found
    if dotenv().is_err() {
        println!("no .env file found...")
    }

    let config = aws_config::load_defaults(BehaviorVersion::v2025_01_17()).await;
    let client = aws_sdk_s3::Client::new(&config);

    let env = Environment::new();

    let localhost_server_state =
        AppState::from_s3_buckets(&client, &env.blog_posts_bucket, &env.portfolio_entries_bucket, &env.templates_bucket).await;
    let public_server_state = localhost_server_state.clone();

    // build our application with a route
    let app = Router::new()
        // `GET /` goes to `root`
        .route("/", get(Redirect::permanent("/portfolio")))
        .route("/portfolio", get(handlers::get_portfolio))
        .route("/blog", get(handlers::get_blog))
        .route("/blog/{id}", get(handlers::get_blog_post))
        .route("/blog/posts", get(handlers::get_blog_posts))
        .route("/resume", get(handlers::get_resume))
        .with_state(public_server_state);

    let localhost_app = Router::new()
        .route("/", get(Redirect::permanent("/blog/upload")))
        .route("/blog", post(handlers::post_blog))
        .route("/blog/upload", get(handlers::get_blog_upload))
        .route("/blog/preview", get(handlers::get_blog_preview))
        .route("/portfolio", post(handlers::post_portfolio))
        .route("/portfolio/upload", get(handlers::get_portfolio_upload))
        .route("/portfolio/preview", get(handlers::get_portfolio_preview))
        .with_state(localhost_server_state);

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:4000")
        .await
        .unwrap();

    let localhost_listener = tokio::net::TcpListener::bind("0.0.0.0:4001")
        .await
        .unwrap();

    println!(
        "Serving public API: http://{}",
        listener.local_addr().unwrap()
    );
    println!(
        "Serving private API: http://{}",
        localhost_listener.local_addr().unwrap()
    );

    let public_api = axum::serve(listener, app).into_future();
    let localhost_api = axum::serve(localhost_listener, localhost_app).into_future();

    // run both APIs concurrently
    let public_handle = tokio::spawn(public_api);
    let localhost_handle = tokio::spawn(localhost_api);

    // Wait for either API to finish
    tokio::select! {
        _ = public_handle => {},
        _ = localhost_handle => {},
    }

    println!("Shutting down the server...");
}
