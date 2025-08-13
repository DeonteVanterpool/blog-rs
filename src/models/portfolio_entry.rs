use serde::{Serialize, Deserialize};
use yaml_front_matter::{Document, YamlFrontMatter};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PortfolioEntry {
    pub github_link: Option<String>,
    pub demo_link: Option<String>,
    pub title: String,
    pub id: usize,
    pub content: String,
    pub summary: String,
    pub image_src: Option<String>,
}

#[derive(Deserialize)]
struct Metadata {
    pub title: String,
    pub github_link: Option<String>,
    pub demo_link: Option<String>,
    pub summary: String,
    pub id: usize,
    pub image_src: Option<String>,
}

// Typical Sections: Overview, Features, Screenshots / Demos, Architecture and Implementation, Takeaways, Tech Stack

impl PortfolioEntry {
    pub fn from_markdown(markdown: &str) -> Self {
        let document: Document<Metadata> = YamlFrontMatter::parse::<Metadata>(&markdown).unwrap();

        let Metadata {
            title,
            github_link,
            demo_link,
            summary,
            id,
            image_src,
        } = document.metadata;

        let content = markdown::to_html(&document.content);

        return PortfolioEntry {
            title,
            github_link,
            demo_link,
            summary,
            id,
            content,
            image_src,
        }
    }
}
