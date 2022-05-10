use anyhow::{bail, Context};
use std::fs;
use vibe_spam::schema;

fn main() -> anyhow::Result<()> {
    let args: Vec<_> = std::env::args().collect();
    if args.len() != 2 {
        bail!("must pass a single path argument");
    }

    let path = &args[1];
    let path = std::path::Path::new(path);

    let sdl = schema::sdl();

    fs::write(path, sdl).context("failed to write schema file")?;

    Ok(())
}
