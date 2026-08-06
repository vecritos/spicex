use std::io::SeekFrom;
use std::io::Seek;
use std::fs::File;
use std::io::{Read};
use std::result::Result;
use std::env;

mod examples;

use crate::examples::examples::{bytes};
use colored::{Colorize, ColoredString};

#[derive(Debug)]
struct Seeker {
    start: u64,
    count: usize
}

fn main() -> std::io::Result<()> {
    bytes();
    let files = args();
    let config = Seeker {
        start: 0, count: 33
    };

    match tester(config, files) {
        Ok(x) => println!("{}", x),
        Err(x) => println!("{}", x)
    }

    Ok(())
}

fn tester(config: Seeker, files: Vec<String>) -> Result<usize, std::io::Error> {
    if files.len() == 0 {
        println!("{}", "not exactly going to do anything");

        return Ok(0);
    }

    let mut f = File::options().read(true).open(&files[0])?;
    let metadata = f.metadata()?;
    let mut permissions = metadata.permissions();

    let mut buf: Vec<u8> = vec![0; config.count];

    f.seek(SeekFrom::Start(config.start))?;
    f.read_exact(&mut buf)?;

    println!("{:?}", buf);

    let colorized_buf = buf.iter()
        .map(|b: &u8| format!("{b:08b}"))
        .map(|s: String| {
            s.chars().map(|c: char| match c {
                '1' => String::from(c).purple(),
                '0' => String::from(c).red(),
                _ => String::from("oh shit").green()
            }).collect::<Vec::<ColoredString>>()
        })
        .collect::<Vec::<Vec<ColoredString>>>();
        //.map(|s: String| match s.chars().nth(0) {
        //    Some('1') => s.purple(),
        //    Some('0') => s.red(),
        //    _ => String::from("shit").green()
        //})
        //.collect::<Vec::<ColoredString>>();

    for line in colorized_buf.iter() {
        for value in line.iter() {
            print!("{}", value);
        }
        println!("");
    }

    Ok(0)
}

fn args() -> Vec<String> {
    let args: Vec<_> = env::args().collect();

    if args.len() > 1 {
        println!("The first argument is {}", args[1]);
    }

    args
}

