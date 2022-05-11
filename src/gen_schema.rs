use std::fs;
use std::path::Path;

use anyhow::{bail, Context};
use vibe_spam::schema;

fn main() -> anyhow::Result<()> {
    let args: Vec<_> = std::env::args().collect();
    if args.len() != 2 {
        bail!("must pass a single path argument");
    }

    let path = Path::new(&args[1]);
    let sdl = schema::sdl();
    fs::write(path, sdl).context("failed to write schema file")?;

    Ok(())
}
