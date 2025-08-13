use crate::{
    models::{self, BlogPost},
};
use std::fs;

pub struct BlogPostService {}

impl BlogPostService {
    pub fn parse_many(file_contents: Vec<String>) -> Vec<BlogPost> {
        return file_contents
            .into_iter()
            .map(|content| {
                return models::BlogPost::from_markdown(
                    &content
                );
            })
            .collect();
    }
}
