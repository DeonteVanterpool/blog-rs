use std::fs;
use std::error::Error;
use std::path::PathBuf;

pub trait FileSystemInterface {
    fn read_dir(&self, path: &str) -> Result<Vec<PathBuf>, Box<dyn Error>>;
    fn read_to_string(&self, path: &PathBuf) -> Result<String, Box<dyn Error>>;
}

pub struct FileSystem {}

impl FileSystemInterface for FileSystem {
    fn read_dir(&self, path: &str) -> Result<Vec<PathBuf>, Box<dyn Error>> {
        Ok(fs::read_dir(path)?
            .filter_map(Result::ok)
            .map(|e| e.path())
            .collect())
    }

     fn read_to_string(&self, path: &PathBuf) -> Result<String, Box<dyn Error>> {
        Ok(fs::read_to_string(path)?)
        }
}

impl FileSystem {
    pub fn new() -> Self {
        Self {}
    }
}
