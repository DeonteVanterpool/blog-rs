use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use yaml_front_matter::{Document, YamlFrontMatter};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlogPost {
    pub id: usize,
    pub title: String,
    pub published: NaiveDate,
    pub tags: Vec<String>,
    pub content: String,
}

#[derive(Deserialize)]
struct Metadata {
    pub id: usize,
    pub title: String,
    pub published: NaiveDate,
    pub tags: Vec<String>,
}

impl BlogPost {
    pub fn from_markdown(markdown: &str) -> Self {
        let document: Document<Metadata> = YamlFrontMatter::parse::<Metadata>(&markdown).unwrap();

        let Metadata {
            id,
            title,
            published,
            tags,
        } = document.metadata;

        let content = markdown::to_html(&document.content);

        return BlogPost {
            id,
            title,
            published,
            tags,
            content,
        };
    }
}
