use crate::state::AppState;

use crate::services::filesystem::FileSystemInterface;
use std::path::PathBuf;

struct MockFileSystem {
    files: Vec<(PathBuf, String)>,
}

impl MockFileSystem {
    fn new(files: Vec<(PathBuf, String)>) -> Self {
        Self { files }
    }
}

impl FileSystemInterface for MockFileSystem {
    fn read_dir(&self, _path: &str) -> Result<Vec<PathBuf>, Box<dyn std::error::Error>> {
        Ok(self.files.iter().map(|(p, _)| p.clone()).collect())
    }

    fn read_to_string(&self, path: &PathBuf) -> Result<String, Box<dyn std::error::Error>> {
        self.files
            .iter()
            .find(|(p, _)| p == path)
            .map(|(_, content)| content.clone())
            .ok_or_else(|| "File not found".into())
    }
}

