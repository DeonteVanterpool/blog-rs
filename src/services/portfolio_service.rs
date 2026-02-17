use crate::{
    models::{self, PortfolioEntry},
    services::filesystem::FileSystemInterface,
};

pub struct PortfolioService {}

impl PortfolioService {
    pub fn parse_many(file_contents: impl IntoIterator<Item = String>) -> Vec<PortfolioEntry> {
        return file_contents
            .into_iter()
            .map(|content| {
                return models::PortfolioEntry::from_markdown(
                    &content
                );
            })
            .collect();
    }
}
